---
description: Update a GitHub issue properties (helper)
allowedTools:
  - Bash
---

# GitHub CLI: Update Issue

Updates properties of an existing GitHub issue (title, body, labels, assignees, state, milestone).

## Usage

```bash
/gh-update-issue 123 --title "New title"
/gh-update-issue 123 --add-label bug --add-label urgent
/gh-update-issue 123 --remove-label "in-progress" --add-label "done"
/gh-update-issue 123 --assignee @developer
/gh-update-issue 123 --state closed
/gh-update-issue 123 --state open --add-label "reopened"
```

## Input Parameters

- **issueNumber** (required): The GitHub issue number
- **--title** (optional): New issue title
- **--body** (optional): New issue body
- **--add-label** (optional, repeatable): Add label to issue
- **--remove-label** (optional, repeatable): Remove label from issue
- **--assignee** (optional): Set assignee (use `@me` for self, empty to clear)
- **--add-assignee** (optional, repeatable): Add assignee
- **--remove-assignee** (optional, repeatable): Remove assignee
- **--milestone** (optional): Set milestone (name or number, empty to clear)
- **--state** (optional): Set state (`open` or `closed`)

## Implementation

1. **Parse input parameters:**
   ```bash
   issueNumber=""
   title=""
   body=""
   addLabels=()
   removeLabels=()
   assignee=""
   addAssignees=()
   removeAssignees=()
   milestone=""
   state=""

   while [[ $# -gt 0 ]]; do
     case $1 in
       --title)
         title="$2"
         shift 2
         ;;
       --body)
         body="$2"
         shift 2
         ;;
       --add-label)
         addLabels+=("$2")
         shift 2
         ;;
       --remove-label)
         removeLabels+=("$2")
         shift 2
         ;;
       --assignee)
         assignee="$2"
         shift 2
         ;;
       --add-assignee)
         addAssignees+=("$2")
         shift 2
         ;;
       --remove-assignee)
         removeAssignees+=("$2")
         shift 2
         ;;
       --milestone)
         milestone="$2"
         shift 2
         ;;
       --state)
         state="$2"
         shift 2
         ;;
       *)
         if [[ "$1" =~ ^[0-9]+$ ]]; then
           issueNumber="$1"
         fi
         shift
         ;;
     esac
   done

   # Validate required parameters
   if [ -z "$issueNumber" ]; then
     echo "❌ Missing required parameter: issueNumber"
     echo ""
     echo "Usage: /gh-update-issue <number> [options]"
     echo ""
     echo "Options:"
     echo "  --title <text>          Set issue title"
     echo "  --body <text>           Set issue body"
     echo "  --add-label <name>      Add label (repeatable)"
     echo "  --remove-label <name>   Remove label (repeatable)"
     echo "  --assignee <user>       Set assignee (@me for self)"
     echo "  --add-assignee <user>   Add assignee (repeatable)"
     echo "  --remove-assignee <user> Remove assignee (repeatable)"
     echo "  --milestone <name>      Set milestone"
     echo "  --state <open|closed>   Set issue state"
     echo ""
     echo "Examples:"
     echo "  /gh-update-issue 123 --title \"Updated title\""
     echo "  /gh-update-issue 123 --add-label bug --state closed"
     exit 1
   fi

   # Validate state if provided
   if [ -n "$state" ] && [ "$state" != "open" ] && [ "$state" != "closed" ]; then
     echo "❌ Invalid state: $state"
     echo "   Valid states: open, closed"
     exit 1
   fi
   ```

2. **Verify issue exists:**
   ```bash
   echo "🔍 Fetching issue #$issueNumber..."

   issueInfo=$(gh issue view "$issueNumber" --json number,title,state 2>/dev/null)

   if [ -z "$issueInfo" ]; then
     echo "❌ Issue #$issueNumber not found"
     exit 1
   fi

   currentTitle=$(echo "$issueInfo" | jq -r '.title')
   currentState=$(echo "$issueInfo" | jq -r '.state')
   echo "   #$issueNumber: $currentTitle"
   echo "   State: $currentState"
   echo ""
   ```

3. **Build and execute update commands:**
   ```bash
   changes=0

   # Update title
   if [ -n "$title" ]; then
     echo "📝 Updating title..."
     gh issue edit "$issueNumber" --title "$title"
     echo "   ✅ Title updated"
     ((changes++))
   fi

   # Update body
   if [ -n "$body" ]; then
     echo "📝 Updating body..."
     gh issue edit "$issueNumber" --body "$body"
     echo "   ✅ Body updated"
     ((changes++))
   fi

   # Add labels
   for label in "${addLabels[@]}"; do
     echo "🏷️  Adding label: $label..."
     if gh issue edit "$issueNumber" --add-label "$label" 2>/dev/null; then
       echo "   ✅ Label added"
       ((changes++))
     else
       echo "   ⚠️  Label '$label' not found or already applied"
     fi
   done

   # Remove labels
   for label in "${removeLabels[@]}"; do
     echo "🏷️  Removing label: $label..."
     if gh issue edit "$issueNumber" --remove-label "$label" 2>/dev/null; then
       echo "   ✅ Label removed"
       ((changes++))
     else
       echo "   ⚠️  Label '$label' not found or not applied"
     fi
   done

   # Set assignee (replaces all)
   if [ -n "$assignee" ]; then
     echo "👤 Setting assignee: $assignee..."
     gh issue edit "$issueNumber" --assignee "$assignee"
     echo "   ✅ Assignee set"
     ((changes++))
   fi

   # Add assignees
   for user in "${addAssignees[@]}"; do
     echo "👤 Adding assignee: $user..."
     if gh issue edit "$issueNumber" --add-assignee "$user" 2>/dev/null; then
       echo "   ✅ Assignee added"
       ((changes++))
     else
       echo "   ⚠️  User '$user' not found"
     fi
   done

   # Remove assignees
   for user in "${removeAssignees[@]}"; do
     echo "👤 Removing assignee: $user..."
     if gh issue edit "$issueNumber" --remove-assignee "$user" 2>/dev/null; then
       echo "   ✅ Assignee removed"
       ((changes++))
     else
       echo "   ⚠️  User '$user' not assigned"
     fi
   done

   # Set milestone
   if [ -n "$milestone" ]; then
     echo "🎯 Setting milestone: $milestone..."
     if gh issue edit "$issueNumber" --milestone "$milestone" 2>/dev/null; then
       echo "   ✅ Milestone set"
       ((changes++))
     else
       echo "   ⚠️  Milestone '$milestone' not found"
     fi
   fi

   # Update state (open/close)
   if [ -n "$state" ]; then
     if [ "$state" == "closed" ] && [ "$currentState" == "OPEN" ]; then
       echo "🔒 Closing issue..."
       gh issue close "$issueNumber"
       echo "   ✅ Issue closed"
       ((changes++))
     elif [ "$state" == "open" ] && [ "$currentState" == "CLOSED" ]; then
       echo "🔓 Reopening issue..."
       gh issue reopen "$issueNumber"
       echo "   ✅ Issue reopened"
       ((changes++))
     else
       echo "ℹ️  Issue already $state"
     fi
   fi
   ```

4. **Output summary:**
   ```bash
   echo ""
   if [ $changes -gt 0 ]; then
     echo "✅ Issue #$issueNumber updated ($changes changes)"
   else
     echo "ℹ️  No changes made to issue #$issueNumber"
   fi
   ```

**Success response:**
```text
🔍 Fetching issue #123...
   #123: Implement user authentication
   State: OPEN

🏷️  Adding label: bug...
   ✅ Label added
🏷️  Adding label: urgent...
   ✅ Label added
🔒 Closing issue...
   ✅ Issue closed

✅ Issue #123 updated (3 changes)
```

## Error Handling

**If issue not found:**
```text
❌ Issue #999 not found

Verify the issue exists:
  gh issue view 999
```

**If label doesn't exist:**
```text
🏷️  Adding label: nonexistent...
   ⚠️  Label 'nonexistent' not found or already applied
```

**If invalid state:**
```text
❌ Invalid state: pending
   Valid states: open, closed
```

**If not authenticated:**
```text
❌ Issue #123 not found

You may need to authenticate:
  gh auth login
```

## Notes

- **Authentication**: Requires `gh auth login` with write access
- **Permissions**: User must have write access to the repository
- **Labels**: Must exist in the repository before use
- **Assignees**: Must be valid GitHub users with repo access
- **State changes**: Only `open` and `closed` supported
- **Partial updates**: Only specified fields are updated

## Use Cases

### Update Labels During Workflow

```bash
# Move from triage to in-progress
/gh-update-issue 123 --remove-label "status:triage" --add-label "status:in-progress"

# Mark as done
/gh-update-issue 123 --remove-label "status:in-progress" --add-label "status:done" --state closed
```

### Assign and Prioritize

```bash
# Assign to developer with priority label
/gh-update-issue 123 --assignee @developer --add-label "priority:high"
```

### Close with Resolution

```bash
# Close as completed
/gh-update-issue 123 --state closed --add-label "resolution:fixed"

# Close as won't fix
/gh-update-issue 123 --state closed --add-label "resolution:wontfix"
```

### Reopen Issue

```bash
# Reopen with explanation label
/gh-update-issue 123 --state open --add-label "reopened" --remove-label "resolution:fixed"
```

### Integration with Work System

```bash
# When work item transitions
/work-item transition WI-001 deliver

# Sync state to GitHub
/gh-update-issue 123 --remove-label "status:planned" --add-label "status:in-progress"
```

## Related Commands

- `/gh-get-issue` - Get issue details
- `/gh-create-issue` - Create new issue
- `/gh-list-issues` - List issues with filters
- `/gh-issue-comment` - Add comment to issue
- `/gh-issue-dependency` - Set dependencies
