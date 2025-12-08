---
description: Update task properties in Teamwork (helper)
allowedTools:
  - Bash
  - Read
---

# Teamwork API: Update Task

Updates properties of a Teamwork task (progress, estimates, status, priority, etc.). Used by workflow commands to track progress through resolution phases.

## Usage

```bash
/tw-update-task 26134585 --progress 10                    # Set progress to 10%
/tw-update-task 26134585 --progress 30 --estimate 120    # Progress + estimate
/tw-update-task TW-26134585 --progress 99 --estimate 135 # With TW- prefix
/tw-update-task 26134585 --status 123456                  # Update status only
```

## Input Parameters

- **taskId** (required): Task ID (numeric or with "TW-" prefix)
- **--progress** (optional): Progress percentage (0-100)
- **--estimate** (optional): Time estimate in minutes
- **--status** (optional): Status ID
- **--priority** (optional): Priority ID

**Note:** At least one optional parameter must be provided.

## Implementation

1. **Validate and parse input:**
   ```bash
   taskId=$1
   shift  # Remove taskId from arguments

   # Strip "TW-" prefix if present
   taskId=${taskId#TW-}

   # Validate taskId
   if [ -z "$taskId" ]; then
     echo "Error: taskId required"
     exit 1
   fi

   # Parse optional parameters
   progress=""
   estimate=""
   statusId=""
   priorityId=""

   while [[ $# -gt 0 ]]; do
     case $1 in
       --progress)
         progress="$2"
         shift 2
         ;;
       --estimate)
         estimate="$2"
         shift 2
         ;;
       --status)
         statusId="$2"
         shift 2
         ;;
       --priority)
         priorityId="$2"
         shift 2
         ;;
       *)
         echo "Unknown parameter: $1"
         exit 1
         ;;
     esac
   done

   # Validate at least one parameter provided
   if [ -z "$progress" ] && [ -z "$estimate" ] && [ -z "$statusId" ] && [ -z "$priorityId" ]; then
     echo "Error: At least one update parameter required"
     exit 1
   fi

   # Validate progress range if provided
   if [ -n "$progress" ]; then
     if [ "$progress" -lt 0 ] || [ "$progress" -gt 100 ]; then
       echo "Error: Progress must be between 0 and 100"
       exit 1
     fi
   fi
   ```

2. **Read credentials:**
   - Read `~/.teamwork/credentials.json`
   - Extract `apiKey` and `domain`

3. **Build request payload dynamically:**
   ```json
   {
     "todo-item": {
       "progress": 30,
       "estimateMinutes": 120,
       "statusId": "123456",
       "priorityId": "789012"
     }
   }
   ```

   **Note:** Teamwork API expects:
   - Only include fields that are being updated
   - `progress` field for percentage (0-100)
   - `estimateMinutes` for time estimates
   - `statusId` and `priorityId` are numeric strings

4. **Make API request:**
   ```bash
   curl -s -X PUT \
     -u "${apiKey}:xxx" \
     -H "Content-Type: application/json" \
     -d '{JSON_PAYLOAD}' \
     "https://${domain}/tasks/${taskId}.json"
   ```

5. **Parse response and format output:**

```json
{
  "task": {
    "id": "26134585",
    "progress": 30,
    "estimateMinutes": 120,
    "statusId": "123456",
    "priorityId": "789012",
    "updatedAt": "2025-12-03T15:30:00Z"
  },
  "success": true
}
```

## Error Handling

**If required parameters missing:**
```text
❌ Missing required parameters

Usage: /tw-update-task <taskId> [--progress N] [--estimate N] [--status ID] [--priority ID]

Examples:
  /tw-update-task 26134585 --progress 10
  /tw-update-task 26134585 --progress 30 --estimate 120
  /tw-update-task TW-26134585 --progress 99 --estimate 135
  /tw-update-task 26134585 --status 123456 --priority 789012

Parameters:
  taskId     - Task ID (numeric or with "TW-" prefix)
  --progress - Progress percentage (0-100)
  --estimate - Time estimate in minutes
  --status   - Status ID
  --priority - Priority ID

Note: At least one update parameter required
```

**If invalid progress value:**
```text
❌ Invalid progress value

Progress must be between 0 and 100
Example: --progress 30
```

**If no update parameters provided:**
```text
❌ No update parameters provided

You must provide at least one of:
  --progress N  (0-100)
  --estimate N  (minutes)
  --status ID
  --priority ID
```

**If credentials missing:**
```text
❌ Teamwork Credentials Required

Please create ~/.teamwork/credentials.json
```

**If API request fails:**
- 401 Unauthorized: "Invalid API key"
- 404 Not Found: "Task '${taskId}' not found or access denied"
- 422 Unprocessable: "Invalid task data. Check status/priority IDs are valid."

Return error JSON:
```json
{
  "error": true,
  "message": "Task '26134585' not found or access denied",
  "statusCode": 404,
  "taskId": "26134585"
}
```

## Notes

- **Automatic prefix handling**: Strips "TW-" if provided in taskId
- **Partial updates**: Only specified fields are updated
- **Progress tracking**: Use 99% instead of 100% to prevent auto-closing tasks
- **Estimate visibility**: Setting estimate makes time visible in Teamwork UI
- **Status/Priority IDs**: Must be valid IDs from your Teamwork configuration
- **Flexible parameters**: Provide only the fields you want to update

## Workflow Phase Progress Values

Common progress values used in production support workflow:

| Phase | Progress | Command |
|-------|----------|---------|
| Triage Complete | 10% | `/tw-update-task {id} --progress 10` |
| Investigation Complete | 30% | `/tw-update-task {id} --progress 30` |
| Validation Complete | 50% | `/tw-update-task {id} --progress 50` |
| Execution Complete | 60% | `/tw-update-task {id} --progress 60` |
| Verification Complete | 80% | `/tw-update-task {id} --progress 80` |
| Ready for Closure | 99% | `/tw-update-task {id} --progress 99 --estimate {ttr}` |

**Note:** Use 99% (not 100%) to keep task open for manual time logging.

## Use Cases

### Update Progress Only
```bash
# After triage phase completes
/tw-update-task 26134585 --progress 10
```

### Update Progress and Estimate
```bash
# After closure, set final TTR
/tw-update-task 26134585 --progress 99 --estimate 135
```

### Reset Progress
```bash
# When reopening issue for new resolution attempt
/tw-update-task 26134585 --progress 10
```

### Change Status
```bash
# Move to different status
/tw-update-task 26134585 --status 123456
```

### Update Multiple Fields
```bash
# Complete package update
/tw-update-task 26134585 --progress 80 --estimate 120 --priority 789012
```

## Examples

### Triage Phase Complete
```bash
/tw-update-task TW-26162664 --progress 10
```

### Investigation Phase Complete
```bash
/tw-update-task 26162664 --progress 30
```

### Validation Phase Complete
```bash
/tw-update-task 26162664 --progress 50
```

### Verification Phase Complete (Passed)
```bash
/tw-update-task 26162664 --progress 80
```

### Verification Phase (Execution Errors)
```bash
# Keep at 60% if execution failed
/tw-update-task 26162664 --progress 60
```

### Closure Phase (Ready for Manual Time Logging)
```bash
# Set to 99% with final TTR estimate
/tw-update-task 26162664 --progress 99 --estimate 135
```
