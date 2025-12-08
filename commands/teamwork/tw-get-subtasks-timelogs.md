---
description: Get all timelog entries for all subtasks of a parent task with total summary (helper)
allowedTools:
  - Bash
  - Read
  - SlashCommand
---

# Teamwork API: Get Subtasks Timelogs

Fetches all timelog entries for all subtasks of a parent task with optional filtering and aggregated total summary.

## Usage

```bash
/tw-get-subtasks-timelogs 26134585                                    # All subtask timelogs
/tw-get-subtasks-timelogs 26134585 "2025-12-01"                      # From date onward
/tw-get-subtasks-timelogs 26134585 "2025-12-01" "2025-12-03"         # Date range
/tw-get-subtasks-timelogs 26134585 "" "" "123456,789012"             # Filter by users
/tw-get-subtasks-timelogs 26134585 "2025-12-01" "2025-12-03" "123456" # Combined filters
```

## Input Parameters

- **parentTaskId** (required): Parent task ID (numeric)
- **fromDate** (optional): Start date in YYYY-MM-DD format (use "" to skip)
- **toDate** (optional): End date in YYYY-MM-DD format (use "" to skip)
- **userIds** (optional): Comma-separated list of user IDs (use "" to skip)

## Implementation

This command orchestrates multiple API calls to fetch timelogs for all subtasks:

1. **Validate and parse input:**
   ```bash
   parentTaskId=$1
   fromDate=$2
   toDate=$3
   userIds=$4

   # Strip "TW-" prefix if present
   parentTaskId=${parentTaskId#TW-}

   # Validate parentTaskId
   if [ -z "$parentTaskId" ]; then
     echo "Error: parentTaskId required"
     exit 1
   fi
   ```

2. **Fetch all subtasks:**
   ```
   Use SlashCommand tool with: "/tw-get-subtasks {parentTaskId}"

   Parse response to extract subtasks array
   Extract subtask IDs
   ```

3. **For each subtask, fetch timelogs:**
   ```
   For each subtaskId in subtasks:
     Use SlashCommand tool with: "/tw-get-task-timelogs {subtaskId} {fromDate} {toDate} {userIds}"

     Parse response to extract timelogs and totalSummary
     Add subtask context (id, name) to each timelog
     Append to aggregated timelogs array
     Add totalSummary.totalMinutes to grand total
   ```

4. **Calculate aggregated totals:**
   ```
   Sum all totalMinutes from each subtask
   Calculate total hours (totalMinutes / 60)
   Format as "Xh Ym"
   Count total entries across all subtasks
   ```

5. **Format output with grouping:**

## Output Format

```json
{
  "timelogs": [
    {
      "id": "987654",
      "taskId": "26134586",
      "taskName": "Design database schema",
      "parentTaskId": "26134585",
      "parentTaskName": "Update database schema",
      "description": "Created ER diagram",
      "date": "2025-12-02",
      "hours": 1,
      "minutes": 30,
      "totalMinutes": 90,
      "userId": "123456",
      "userName": "John Doe",
      "userEmail": "john.doe@company.com",
      "createdAt": "2025-12-02T15:30:00Z"
    },
    {
      "id": "987655",
      "taskId": "26134587",
      "taskName": "Write migration scripts",
      "parentTaskId": "26134585",
      "parentTaskName": "Update database schema",
      "description": "Migration script v1",
      "date": "2025-12-03",
      "hours": 2,
      "minutes": 15,
      "totalMinutes": 135,
      "userId": "789012",
      "userName": "Jane Smith",
      "userEmail": "jane.smith@company.com",
      "createdAt": "2025-12-03T10:00:00Z"
    }
  ],
  "totalSummary": {
    "totalMinutes": 225,
    "totalHours": 3.75,
    "formatted": "3h 45m",
    "entryCount": 2,
    "breakdown": {
      "hours": 3,
      "minutes": 45
    },
    "bySubtask": [
      {
        "subtaskId": "26134586",
        "subtaskName": "Design database schema",
        "totalMinutes": 90,
        "formatted": "1h 30m",
        "entryCount": 1
      },
      {
        "subtaskId": "26134587",
        "subtaskName": "Write migration scripts",
        "totalMinutes": 135,
        "formatted": "2h 15m",
        "entryCount": 1
      }
    ]
  },
  "meta": {
    "parentTaskId": "26134585",
    "subtaskCount": 2,
    "fromDate": "2025-12-01",
    "toDate": "2025-12-03",
    "userIds": [],
    "appliedFilters": {
      "dateRange": true,
      "users": false
    }
  }
}
```

## Error Handling

**If parentTaskId not provided:**
```text
❌ Missing required parameter: parentTaskId

Usage: /tw-get-subtasks-timelogs <parentTaskId> [fromDate] [toDate] [userIds]

Examples:
  /tw-get-subtasks-timelogs 26134585
  /tw-get-subtasks-timelogs 26134585 "2025-12-01" "2025-12-03"
  /tw-get-subtasks-timelogs 26134585 "" "" "123456,789012"

Parameters:
  parentTaskId - Parent task ID (numeric, no "TW-" prefix)
  fromDate     - Optional: Start date (YYYY-MM-DD), use "" to skip
  toDate       - Optional: End date (YYYY-MM-DD), use "" to skip
  userIds      - Optional: Comma-separated user IDs, use "" to skip
```

**If credentials missing:**
```text
❌ Teamwork Credentials Required

Please create ~/.teamwork/credentials.json
```

**If API request fails:**
- 401 Unauthorized: "Invalid API key"
- 404 Not Found: "Parent task '${parentTaskId}' not found"

Return error JSON:
```json
{
  "error": true,
  "message": "Parent task '26134585' not found or access denied",
  "statusCode": 404,
  "parentTaskId": "26134585"
}
```

## Special Cases

**No subtasks found:**
```json
{
  "timelogs": [],
  "totalSummary": {
    "totalMinutes": 0,
    "totalHours": 0,
    "formatted": "0h 0m",
    "entryCount": 0,
    "breakdown": { "hours": 0, "minutes": 0 },
    "bySubtask": []
  },
  "meta": {
    "parentTaskId": "26134585",
    "subtaskCount": 0,
    "message": "No subtasks found for this parent task"
  }
}
```

**Subtasks exist but no timelogs:**
```json
{
  "timelogs": [],
  "totalSummary": {
    "totalMinutes": 0,
    "totalHours": 0,
    "formatted": "0h 0m",
    "entryCount": 0,
    "breakdown": { "hours": 0, "minutes": 0 },
    "bySubtask": [
      {
        "subtaskId": "26134586",
        "subtaskName": "Design database schema",
        "totalMinutes": 0,
        "formatted": "0h 0m",
        "entryCount": 0
      }
    ]
  },
  "meta": {
    "parentTaskId": "26134585",
    "subtaskCount": 1,
    "message": "No timelogs found for subtasks"
  }
}
```

## Notes

- **Aggregated totals**: Sums time across ALL subtasks
- **Subtask breakdown**: Includes per-subtask totals in `bySubtask` array
- **Hierarchical context**: Each timelog includes both task and parent task info
- **Efficient fetching**: Uses SlashCommand to call existing helper commands
- **Flexible filtering**: Date range and user filters apply to all subtasks
- **Two-level aggregation**: Both grand total and per-subtask totals

## Use Cases

- **Parent task analysis**: See total time across all work breakdown
- **Subtask comparison**: Compare time spent on different subtasks
- **Team coordination**: Understand work distribution across subtasks
- **Progress tracking**: Monitor completion of complex multi-part tasks
- **Reporting**: Generate comprehensive time summaries for parent tasks
