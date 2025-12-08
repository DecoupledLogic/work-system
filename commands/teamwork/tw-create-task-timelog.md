---
description: Create a timelog entry for a Teamwork task (helper)
allowedTools:
  - Bash
  - Read
---

# Teamwork API: Create Task Timelog

Creates a new timelog entry for a task. Used by agents to record time spent on tasks.

## Usage

```bash
/tw-create-task-timelog 26134585 "2025-12-03" 2 30 "Implemented schema migration"
/tw-create-task-timelog 26134585 "2025-12-03" 1 0 "Code review"
```

## Input Parameters

- **taskId** (required): Task ID (numeric)
- **date** (required): Date in YYYY-MM-DD format
- **hours** (required): Hours worked (0-23)
- **minutes** (required): Minutes worked (0-59)
- **description** (required): Brief one-line description of work done

**Note:** User is automatically determined from `~/.claude/teamwork.json` configuration

## Implementation

1. **Validate and parse input:**
   ```bash
   taskId=$1
   date=$2
   hours=$3
   minutes=$4
   description=$5

   # Strip "TW-" prefix if present
   taskId=${taskId#TW-}

   # Validate required parameters
   if [ -z "$taskId" ] || [ -z "$date" ] || [ -z "$hours" ] || [ -z "$minutes" ] || [ -z "$description" ]; then
     echo "Error: Missing required parameters"
     exit 1
   fi

   # Validate date format (YYYY-MM-DD)
   if ! [[ "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
     echo "Error: Invalid date format. Use YYYY-MM-DD"
     exit 1
   fi

   # Validate hours (0-23)
   if [ "$hours" -lt 0 ] || [ "$hours" -gt 23 ]; then
     echo "Error: Hours must be between 0 and 23"
     exit 1
   fi

   # Validate minutes (0-59)
   if [ "$minutes" -lt 0 ] || [ "$minutes" -gt 59 ]; then
     echo "Error: Minutes must be between 0 and 59"
     exit 1
   fi

   # Round up to nearest 15-minute interval
   totalMinutes=$((hours * 60 + minutes))

   # Calculate rounded minutes (ceiling division to nearest 15)
   remainder=$((totalMinutes % 15))
   if [ $remainder -ne 0 ]; then
     totalMinutes=$((totalMinutes + 15 - remainder))
   fi

   # Convert back to hours and minutes
   hours=$((totalMinutes / 60))
   minutes=$((totalMinutes % 60))
   ```

2. **Read credentials and user configuration:**
   - Read `~/.teamwork/credentials.json` and extract `apiKey` and `domain`
   - Read `~/.claude/teamwork.json` and extract `user.id`
   - If user.id not found, display error (timelog requires user ID)

3. **Build request payload:**
   ```json
   {
     "timelog": {
       "description": "Implemented schema migration",
       "date": "20251203",
       "time": "00:00",
       "hours": 2,
       "minutes": 30,
       "userId": "123456"
     }
   }
   ```

   **Note:** Teamwork API expects:
   - Date in YYYYMMDD format (convert from YYYY-MM-DD)
   - Time in HH:MM format (use "00:00" as default)
   - Both hours and minutes fields
   - userId from `~/.claude/teamwork.json` configuration

4. **Make API request:**
   ```bash
   curl -s -X POST \
     -u "${apiKey}:xxx" \
     -H "Content-Type: application/json" \
     -d '{JSON_PAYLOAD}' \
     "https://${domain}/tasks/${taskId}/time.json"
   ```

5. **Parse response and format output:**

```json
{
  "timelog": {
    "id": "987654",
    "taskId": "26134585",
    "description": "Implemented schema migration",
    "date": "2025-12-03",
    "hours": 2,
    "minutes": 30,
    "totalMinutes": 150,
    "userId": "123456",
    "userName": "John Doe",
    "createdAt": "2025-12-03T15:30:00Z"
  },
  "success": true
}
```

## Error Handling

**If required parameters missing:**
```text
❌ Missing required parameters

Usage: /tw-create-task-timelog <taskId> <date> <hours> <minutes> <description>

Example: /tw-create-task-timelog 26134585 "2025-12-03" 2 30 "Implemented schema migration"

Parameters:
  taskId       - Task ID (numeric, no "TW-" prefix)
  date         - Date in YYYY-MM-DD format
  hours        - Hours worked (0-23)
  minutes      - Minutes worked (0-59)
  description  - Brief description (use quotes)

Note: User ID is automatically read from ~/.claude/teamwork.json
```

**If invalid date format:**
```text
❌ Invalid date format

Date must be in YYYY-MM-DD format
Example: 2025-12-03
```

**If invalid hours/minutes:**
```text
❌ Invalid time values

Hours must be between 0 and 23
Minutes must be between 0 and 59
```

**If credentials missing:**
```text
❌ Teamwork Credentials Required

Please create ~/.teamwork/credentials.json
```

**If user configuration missing:**
```text
❌ User Configuration Required

Please create ~/.claude/teamwork.json:

{
  "user": {
    "email": "your.email@company.com",
    "name": "Your Name",
    "id": "123456"
  }
}

The user.id field is required to create timelogs.
To find your user ID, log into Teamwork and check your profile settings.
```

**If API request fails:**
- 401 Unauthorized: "Invalid API key"
- 404 Not Found: "Task '${taskId}' not found"
- 422 Unprocessable: "Invalid timelog data. Check date, hours, and minutes."

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

- **Automatic user detection**: User ID is read from `~/.claude/teamwork.json` configuration
- **15-minute rounding**: Time is automatically rounded UP to nearest 15-minute interval
  - 1h 7m → 1h 15m
  - 2h 13m → 2h 15m
  - 0h 42m → 0h 45m
  - 1h 46m → 2h 0m
- **Date format conversion**: Input YYYY-MM-DD is converted to YYYYMMDD for API
- **Time field**: Always set to "00:00" (Teamwork requires it but uses hours/minutes for actual duration)
- **Description**: Keep it brief and one-line for clarity
- **Automatic prefix handling**: Strips "TW-" if provided in taskId
- **Same config as /select-task**: Uses the same user configuration file for consistency

## Use Cases

- **Agent time logging**: When an agent completes work on a task
- **Automated tracking**: Record time from task completion events
- **Batch logging**: Log multiple time entries programmatically
- **Integration**: Connect external tools to Teamwork time tracking
