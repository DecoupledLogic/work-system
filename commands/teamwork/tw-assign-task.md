---
description: Assign or unassign users from a Teamwork task (helper)
allowedTools:
  - Bash
  - Read
---

# Teamwork API: Assign Task

Assigns or unassigns users from a Teamwork task. Can set, add, or remove assignees.

## Usage

```bash
/tw-assign-task 26134585 --user 123456
/tw-assign-task 26134585 --user 123456 --user 789012
/tw-assign-task 26134585 --add 123456
/tw-assign-task 26134585 --remove 123456
/tw-assign-task 26134585 --clear
/tw-assign-task TW-26134585 --me
```

## Input Parameters

- **taskId** (required): Task ID (numeric or with "TW-" prefix)
- **--user** (optional, repeatable): Set assignee(s) - replaces all existing
- **--add** (optional, repeatable): Add assignee without removing existing
- **--remove** (optional, repeatable): Remove specific assignee
- **--clear** (optional): Remove all assignees
- **--me** (optional): Assign to self (uses user.id from config)

## Implementation

1. **Parse input parameters:**
   ```bash
   taskId=$1
   shift

   # Strip "TW-" prefix if present
   taskId=${taskId#TW-}

   users=()
   addUsers=()
   removeUsers=()
   clearAssignees=false
   assignMe=false

   while [[ $# -gt 0 ]]; do
     case $1 in
       --user)
         users+=("$2")
         shift 2
         ;;
       --add)
         addUsers+=("$2")
         shift 2
         ;;
       --remove)
         removeUsers+=("$2")
         shift 2
         ;;
       --clear)
         clearAssignees=true
         shift
         ;;
       --me)
         assignMe=true
         shift
         ;;
       *)
         shift
         ;;
     esac
   done

   # Validate taskId
   if [ -z "$taskId" ]; then
     echo "❌ Missing required parameter: taskId"
     echo ""
     echo "Usage: /tw-assign-task <taskId> [options]"
     echo ""
     echo "Options:"
     echo "  --user <id>    Set assignee(s) - replaces all (repeatable)"
     echo "  --add <id>     Add assignee (repeatable)"
     echo "  --remove <id>  Remove assignee (repeatable)"
     echo "  --clear        Remove all assignees"
     echo "  --me           Assign to self"
     echo ""
     echo "Examples:"
     echo "  /tw-assign-task 26134585 --user 123456"
     echo "  /tw-assign-task 26134585 --add 123456 --add 789012"
     echo "  /tw-assign-task 26134585 --remove 123456"
     echo "  /tw-assign-task 26134585 --me"
     echo "  /tw-assign-task 26134585 --clear"
     exit 1
   fi

   # Validate at least one action specified
   if [ ${#users[@]} -eq 0 ] && [ ${#addUsers[@]} -eq 0 ] && \
      [ ${#removeUsers[@]} -eq 0 ] && [ "$clearAssignees" = false ] && \
      [ "$assignMe" = false ]; then
     echo "❌ No assignment action specified"
     echo ""
     echo "Specify at least one of:"
     echo "  --user <id>    Set assignee(s)"
     echo "  --add <id>     Add assignee"
     echo "  --remove <id>  Remove assignee"
     echo "  --clear        Remove all assignees"
     echo "  --me           Assign to self"
     exit 1
   fi
   ```

2. **Read credentials and user config:**
   ```bash
   CREDS_FILE="$HOME/.teamwork/credentials.json"
   USER_FILE="$HOME/.claude/teamwork.json"

   if [ ! -f "$CREDS_FILE" ]; then
     echo "❌ Teamwork credentials not found"
     echo ""
     echo "Please create ~/.teamwork/credentials.json"
     exit 1
   fi

   apiKey=$(jq -r '.apiKey' "$CREDS_FILE")
   domain=$(jq -r '.domain' "$CREDS_FILE")

   # Get current user ID if --me specified
   if [ "$assignMe" = true ]; then
     if [ ! -f "$USER_FILE" ]; then
       echo "❌ User configuration not found"
       echo ""
       echo "Please create ~/.claude/teamwork.json with user.id"
       exit 1
     fi

     myUserId=$(jq -r '.user.id' "$USER_FILE")
     if [ -z "$myUserId" ] || [ "$myUserId" == "null" ]; then
       echo "❌ User ID not found in configuration"
       exit 1
     fi

     # Add self to users array
     if [ ${#users[@]} -eq 0 ]; then
       addUsers+=("$myUserId")
     else
       users+=("$myUserId")
     fi
   fi
   ```

3. **Fetch current task and assignees:**
   ```bash
   echo "🔍 Fetching task #$taskId..."

   response=$(curl -s -u "${apiKey}:xxx" \
     "https://${domain}/tasks/${taskId}.json?include=assignees")

   if echo "$response" | jq -e '.STATUS == "Error"' > /dev/null 2>&1; then
     echo "❌ Task not found: $taskId"
     exit 1
   fi

   taskName=$(echo "$response" | jq -r '."todo-item".content')
   currentAssignees=$(echo "$response" | jq -r '."todo-item"."responsible-party-ids" // ""')

   echo "   Task: $taskName"
   echo "   Current assignees: ${currentAssignees:-none}"
   echo ""
   ```

4. **Build new assignee list:**
   ```bash
   newAssignees=""

   if [ "$clearAssignees" = true ]; then
     # Clear all assignees
     newAssignees=""
     echo "🔓 Clearing all assignees..."

   elif [ ${#users[@]} -gt 0 ]; then
     # Replace with specified users
     newAssignees=$(IFS=,; echo "${users[*]}")
     echo "👤 Setting assignees: $newAssignees..."

   else
     # Start with current assignees
     newAssignees="$currentAssignees"

     # Add new users
     for userId in "${addUsers[@]}"; do
       if [[ ! ",$newAssignees," == *",$userId,"* ]]; then
         if [ -n "$newAssignees" ]; then
           newAssignees="$newAssignees,$userId"
         else
           newAssignees="$userId"
         fi
         echo "👤 Adding assignee: $userId..."
       else
         echo "ℹ️  User $userId already assigned"
       fi
     done

     # Remove users
     for userId in "${removeUsers[@]}"; do
       if [[ ",$newAssignees," == *",$userId,"* ]]; then
         newAssignees=$(echo "$newAssignees" | sed "s/,$userId,/,/g" | sed "s/^$userId,//" | sed "s/,$userId$//" | sed "s/^$userId$//")
         echo "👤 Removing assignee: $userId..."
       else
         echo "ℹ️  User $userId not currently assigned"
       fi
     done
   fi
   ```

5. **Update task assignees:**
   ```bash
   echo ""
   echo "📤 Updating task assignees..."

   payload=$(jq -n --arg assignees "$newAssignees" '{
     "todo-item": {
       "responsible-party-ids": $assignees
     }
   }')

   updateResponse=$(curl -s -X PUT \
     -u "${apiKey}:xxx" \
     -H "Content-Type: application/json" \
     -d "$payload" \
     "https://${domain}/tasks/${taskId}.json")

   if echo "$updateResponse" | jq -e '.STATUS == "Error"' > /dev/null 2>&1; then
     echo "❌ Failed to update task"
     echo "   $(echo "$updateResponse" | jq -r '.MESSAGE')"
     exit 1
   fi

   echo "✅ Task assignees updated"
   echo ""
   echo "📋 Summary:"
   echo "   Task: #$taskId"
   echo "   Previous: ${currentAssignees:-none}"
   echo "   Current:  ${newAssignees:-none}"
   ```

**Success response:**
```text
🔍 Fetching task #26134585...
   Task: Implement user authentication
   Current assignees: 123456

👤 Adding assignee: 789012...

📤 Updating task assignees...
✅ Task assignees updated

📋 Summary:
   Task: #26134585
   Previous: 123456
   Current:  123456,789012
```

## Error Handling

**If task not found:**
```text
❌ Task not found: 99999999

Verify the task exists:
  /tw-get-task 99999999
```

**If no action specified:**
```text
❌ No assignment action specified

Specify at least one of:
  --user <id>    Set assignee(s)
  --add <id>     Add assignee
  --remove <id>  Remove assignee
  --clear        Remove all assignees
  --me           Assign to self
```

**If credentials missing:**
```text
❌ Teamwork credentials not found

Please create ~/.teamwork/credentials.json
```

**If user config missing for --me:**
```text
❌ User configuration not found

Please create ~/.claude/teamwork.json with user.id
```

## Notes

- **User IDs**: Use numeric Teamwork user IDs (find in Teamwork profile or API)
- **Replace vs Add**: `--user` replaces all assignees; `--add` preserves existing
- **Multiple assignees**: Tasks can have multiple assignees in Teamwork
- **Self-assignment**: `--me` uses user.id from `~/.claude/teamwork.json`
- **Automatic prefix handling**: Strips "TW-" if provided in taskId

## Use Cases

### Assign to Self

```bash
# Take ownership of a task
/tw-assign-task 26134585 --me
```

### Assign to Team Member

```bash
# Assign to specific user
/tw-assign-task 26134585 --user 123456

# Assign to multiple users
/tw-assign-task 26134585 --user 123456 --user 789012
```

### Add Collaborator

```bash
# Add reviewer without removing current assignee
/tw-assign-task 26134585 --add 789012
```

### Transfer Ownership

```bash
# Remove self, add new owner
/tw-assign-task 26134585 --remove 123456 --add 789012
```

### Unassign

```bash
# Remove all assignees
/tw-assign-task 26134585 --clear

# Remove specific assignee
/tw-assign-task 26134585 --remove 123456
```

### Integration with Work System

```bash
# When assigning work item
/work-item assign WI-001 @cbryant

# Sync to Teamwork
/tw-assign-task 26134585 --user 123456
```

## Related Commands

- `/tw-get-task` - Get task details including current assignees
- `/tw-update-task` - Update other task properties
- `/tw-create-task` - Create new subtask
- `/tw-create-comment` - Add comment when assigning
