---
description: Set predecessor/successor relationships between Teamwork tasks (helper)
allowedTools:
  - Bash
  - Read
---

# Teamwork API: Task Dependency

Creates or removes predecessor/successor relationships between Teamwork tasks using Teamwork's native dependency API.

## Usage

```bash
/tw-task-dependency 26134585 --predecessor 26134580
/tw-task-dependency 26134585 --predecessor 26134580 --type start
/tw-task-dependency 26134585 --successor 26134590
/tw-task-dependency 26134585 --remove-predecessor 26134580
/tw-task-dependency 26134585 --remove-successor 26134590
```

## Input Parameters

- **taskId** (required): The Teamwork task ID to modify
- **--predecessor** (optional, repeatable): Task ID that must complete/start first
- **--successor** (optional, repeatable): Task ID that depends on this one
- **--type** (optional): Dependency type - `complete` (default) or `start`
- **--remove-predecessor** (optional): Remove predecessor relationship
- **--remove-successor** (optional): Remove successor relationship

## Dependency Types

| Type | Description |
|------|-------------|
| `complete` | This task can complete when the predecessor completes (default) |
| `start` | This task can complete when the predecessor starts |

## Implementation

### 1. Parse input parameters

```bash
taskId=$1
shift
taskId=${taskId#TW-}  # Strip TW- prefix if present

predecessors=()
successors=()
removePredecessors=()
removeSuccessors=()
depType="complete"

while [[ $# -gt 0 ]]; do
  case $1 in
    --predecessor)
      predecessors+=("${2#TW-}")
      shift 2
      ;;
    --successor)
      successors+=("${2#TW-}")
      shift 2
      ;;
    --remove-predecessor)
      removePredecessors+=("${2#TW-}")
      shift 2
      ;;
    --remove-successor)
      removeSuccessors+=("${2#TW-}")
      shift 2
      ;;
    --type)
      depType="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Validate required parameters
if [ -z "$taskId" ]; then
  echo "❌ Missing required parameter: taskId"
  echo ""
  echo "Usage: /tw-task-dependency <taskId> [options]"
  echo ""
  echo "Options:"
  echo "  --predecessor <id>        Add predecessor task (repeatable)"
  echo "  --successor <id>          Add successor task (repeatable)"
  echo "  --type <complete|start>   Dependency type (default: complete)"
  echo "  --remove-predecessor <id> Remove predecessor relationship"
  echo "  --remove-successor <id>   Remove successor relationship"
  echo ""
  echo "Examples:"
  echo "  /tw-task-dependency 26134585 --predecessor 26134580"
  echo "  /tw-task-dependency 26134585 --successor 26134590"
  echo "  /tw-task-dependency 26134585 --predecessor 26134580 --type start"
  exit 1
fi

# Validate at least one relationship specified
if [ ${#predecessors[@]} -eq 0 ] && [ ${#successors[@]} -eq 0 ] && \
   [ ${#removePredecessors[@]} -eq 0 ] && [ ${#removeSuccessors[@]} -eq 0 ]; then
  echo "❌ No relationship specified"
  echo ""
  echo "Specify at least one of:"
  echo "  --predecessor <id>"
  echo "  --successor <id>"
  echo "  --remove-predecessor <id>"
  echo "  --remove-successor <id>"
  exit 1
fi

# Validate dependency type
if [ "$depType" != "complete" ] && [ "$depType" != "start" ]; then
  echo "❌ Invalid dependency type: $depType"
  echo "   Valid types: complete, start"
  exit 1
fi
```

### 2. Load credentials

```bash
credFile="$HOME/.teamwork/credentials.json"
if [ ! -f "$credFile" ]; then
  echo "❌ Credentials not found: $credFile"
  exit 1
fi

apiKey=$(jq -r '.apiKey' "$credFile")
domain=$(jq -r '.domain' "$credFile")
```

### 3. Get current task with predecessors

```bash
echo "🔍 Fetching task #$taskId..."

taskResponse=$(curl -s -u "${apiKey}:xxx" \
  "https://${domain}/tasks/${taskId}.json")

if [ "$(echo "$taskResponse" | jq -r '.STATUS')" == "Error" ]; then
  echo "❌ Task not found: $taskId"
  exit 1
fi

taskName=$(echo "$taskResponse" | jq -r '.["todo-item"].content')
echo "   Task: $taskName"
echo ""

# Get existing predecessors
existingPreds=$(echo "$taskResponse" | jq -r '.["todo-item"].predecessors // []')
```

### 4. Build new predecessor list

```bash
# Start with existing predecessors
newPreds="$existingPreds"

# Add new predecessors
for pred in "${predecessors[@]}"; do
  echo "🔗 Adding predecessor #$pred..."

  # Check if already exists
  exists=$(echo "$newPreds" | jq --arg id "$pred" 'any(.[]; .id == ($id | tonumber))')
  if [ "$exists" == "true" ]; then
    echo "   ⚠️  Already a predecessor, skipping"
    continue
  fi

  # Add to list
  newPreds=$(echo "$newPreds" | jq --arg id "$pred" --arg type "$depType" \
    '. + [{"id": ($id | tonumber), "type": $type}]')
  echo "   ✅ Added with type: $depType"
done

# Remove specified predecessors
for pred in "${removePredecessors[@]}"; do
  echo "🔓 Removing predecessor #$pred..."
  newPreds=$(echo "$newPreds" | jq --arg id "$pred" \
    'map(select(.id != ($id | tonumber)))')
  echo "   ✅ Removed"
done
```

### 5. Update task with new predecessors

```bash
if [ "$existingPreds" != "$newPreds" ]; then
  echo ""
  echo "📤 Updating task predecessors..."

  payload=$(jq -n --argjson preds "$newPreds" '{
    "todo-item": {
      "predecessors": $preds
    }
  }')

  updateResponse=$(curl -s -X PUT \
    -u "${apiKey}:xxx" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "https://${domain}/tasks/${taskId}.json")

  if [ "$(echo "$updateResponse" | jq -r '.STATUS')" == "Error" ]; then
    echo "❌ Failed to update task"
    echo "   $(echo "$updateResponse" | jq -r '.MESSAGE')"
    exit 1
  fi

  echo "   ✅ Task updated"
fi
```

### 6. Handle successors (inverse operation)

```bash
# For successors, we add this task as a predecessor to the successor task
for succ in "${successors[@]}"; do
  echo ""
  echo "🔗 Adding as predecessor to successor #$succ..."

  # Get successor's current predecessors
  succResponse=$(curl -s -u "${apiKey}:xxx" \
    "https://${domain}/tasks/${succ}.json")

  if [ "$(echo "$succResponse" | jq -r '.STATUS')" == "Error" ]; then
    echo "   ❌ Successor task not found: $succ"
    continue
  fi

  succName=$(echo "$succResponse" | jq -r '.["todo-item"].content')
  succPreds=$(echo "$succResponse" | jq -r '.["todo-item"].predecessors // []')

  # Check if already exists
  exists=$(echo "$succPreds" | jq --arg id "$taskId" 'any(.[]; .id == ($id | tonumber))')
  if [ "$exists" == "true" ]; then
    echo "   ⚠️  Already a predecessor of $succ, skipping"
    continue
  fi

  # Add this task as predecessor
  succPreds=$(echo "$succPreds" | jq --arg id "$taskId" --arg type "$depType" \
    '. + [{"id": ($id | tonumber), "type": $type}]')

  payload=$(jq -n --argjson preds "$succPreds" '{
    "todo-item": {
      "predecessors": $preds
    }
  }')

  updateResponse=$(curl -s -X PUT \
    -u "${apiKey}:xxx" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "https://${domain}/tasks/${succ}.json")

  if [ "$(echo "$updateResponse" | jq -r '.STATUS')" == "Error" ]; then
    echo "   ❌ Failed to update successor"
  else
    echo "   ✅ Now predecessor of: $succName"
  fi
done

# Remove as predecessor from successors
for succ in "${removeSuccessors[@]}"; do
  echo ""
  echo "🔓 Removing as predecessor from successor #$succ..."

  succResponse=$(curl -s -u "${apiKey}:xxx" \
    "https://${domain}/tasks/${succ}.json")

  if [ "$(echo "$succResponse" | jq -r '.STATUS')" == "Error" ]; then
    echo "   ❌ Successor task not found: $succ"
    continue
  fi

  succPreds=$(echo "$succResponse" | jq -r '.["todo-item"].predecessors // []')
  succPreds=$(echo "$succPreds" | jq --arg id "$taskId" \
    'map(select(.id != ($id | tonumber)))')

  payload=$(jq -n --argjson preds "$succPreds" '{
    "todo-item": {
      "predecessors": $preds
    }
  }')

  curl -s -X PUT \
    -u "${apiKey}:xxx" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "https://${domain}/tasks/${succ}.json" > /dev/null

  echo "   ✅ Removed"
done
```

### 7. Output summary

```bash
echo ""
echo "📋 Summary for task #$taskId:"
echo "   Predecessors added: ${#predecessors[@]}"
echo "   Predecessors removed: ${#removePredecessors[@]}"
echo "   Successors added: ${#successors[@]}"
echo "   Successors removed: ${#removeSuccessors[@]}"
```

## Response Format

**Success response:**

```json
{
  "task": {
    "id": "26134585",
    "name": "Implement user authentication",
    "predecessors": [
      { "id": 26134580, "type": "complete", "name": "Setup database" }
    ],
    "successors": [
      { "id": 26134590, "name": "Deploy to staging" }
    ]
  },
  "success": true
}
```

## Error Handling

**If task not found:**

```text
❌ Task not found: 99999999

Verify the task exists:
  /tw-get-task 99999999
```

**If no relationship specified:**

```text
❌ No relationship specified

Specify at least one of:
  --predecessor <id>
  --successor <id>
  --remove-predecessor <id>
  --remove-successor <id>
```

**If invalid dependency type:**

```text
❌ Invalid dependency type: invalid
   Valid types: complete, start
```

**If credentials missing:**

```text
❌ Credentials not found: ~/.teamwork/credentials.json

Setup credentials:
  mkdir -p ~/.teamwork
  echo '{"apiKey": "twp_...", "domain": "company.teamwork.com"}' > ~/.teamwork/credentials.json
```

## Notes

- **Full replacement**: Teamwork API replaces all predecessors on PUT
- **Inverse tracking**: Successors are set by adding this task as a predecessor to the successor
- **ID format**: Accepts both numeric IDs and TW-prefixed IDs (prefix is auto-stripped)
- **Type meanings**:
  - `complete`: This task can complete when predecessor completes (default)
  - `start`: This task can complete when predecessor starts

## Use Cases

### Establish Dependency Chain

```bash
# Task C depends on Task B, which depends on Task A
/tw-task-dependency 26134585 --predecessor 26134580  # B depends on A
/tw-task-dependency 26134590 --predecessor 26134585  # C depends on B
```

### Mark Foundation Task as Blocking Others

```bash
# Database setup blocks multiple tasks
/tw-task-dependency 26134580 --successor 26134585 --successor 26134586 --successor 26134587
```

### Remove Completed Dependency

```bash
# Remove dependency after prerequisite is complete
/tw-task-dependency 26134585 --remove-predecessor 26134580
```

### Start-Type Dependency

```bash
# Task can proceed once another task starts (not waits for completion)
/tw-task-dependency 26134585 --predecessor 26134580 --type start
```

## Integration with Work System

Dependency management workflow:

```bash
# 1. Add dependency via work item (source of truth)
/work-item depend WI-001 --blocked-by WI-002

# 2. If both are Teamwork tasks, auto-syncs via:
/tw-task-dependency 26134585 --predecessor 26134580

# 3. Or set directly on Teamwork task
/tw-task-dependency 26134585 --predecessor 26134580
```

## Related Commands

- `/tw-get-task` - Get task details including predecessors
- `/tw-update-task` - Update other task properties
- `/tw-create-task` - Create task with initial predecessors
- `/work-item depend` - Set dependencies on work item (source of truth)
- `/gh-issue-dependency` - Set dependencies on GitHub issues
