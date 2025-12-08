---
description: Get all timelog entries for a Teamwork task with total summary (helper)
allowedTools:
  - Bash
  - Read
---

# Teamwork API: Get Task Timelogs

Fetches all timelog entries for a specific task with optional filtering and total summary.

## Usage

```bash
/tw-get-task-timelogs 26134585                                    # All timelogs
/tw-get-task-timelogs 26134585 "2025-12-01"                      # From date onward
/tw-get-task-timelogs 26134585 "2025-12-01" "2025-12-03"         # Date range
/tw-get-task-timelogs 26134585 "" "" "123456,789012"             # Filter by users
/tw-get-task-timelogs 26134585 "2025-12-01" "2025-12-03" "123456" # Combined filters
```

## Input Parameters

- **taskId** (required): Task ID (numeric)
- **fromDate** (optional): Start date in YYYY-MM-DD format (use "" to skip)
- **toDate** (optional): End date in YYYY-MM-DD format (use "" to skip)
- **userIds** (optional): Comma-separated list of user IDs (use "" to skip)

## Implementation

1. **Validate and parse input:**
   ```bash
   taskId=$1
   fromDate=$2
   toDate=$3
   userIds=$4

   # Strip "TW-" prefix if present
   taskId=${taskId#TW-}

   # Validate taskId
   if [ -z "$taskId" ]; then
     echo "Error: taskId required"
     exit 1
   fi
   ```

2. **Read credentials:**
   - Read `~/.teamwork/credentials.json`
   - Extract `apiKey` and `domain`

3. **Build query parameters:**
   ```bash
   queryParams="?"

   # Add date range if provided
   if [ -n "$fromDate" ]; then
     # Convert YYYY-MM-DD to YYYYMMDD
     fromDateFormatted=$(echo $fromDate | tr -d '-')
     queryParams="${queryParams}fromDate=${fromDateFormatted}&"
   fi

   if [ -n "$toDate" ]; then
     toDateFormatted=$(echo $toDate | tr -d '-')
     queryParams="${queryParams}toDate=${toDateFormatted}&"
   fi

   # Add user filter if provided
   if [ -n "$userIds" ]; then
     # Convert comma-separated to Teamwork format
     queryParams="${queryParams}userId=${userIds}&"
   fi

   # Add pagination
   queryParams="${queryParams}pageSize=250"
   ```

4. **Make API request:**
   ```bash
   curl -s -u "${apiKey}:xxx" \
     "https://${domain}/tasks/${taskId}/time.json${queryParams}"
   ```

5. **Parse response, calculate totals, and format output:**
   - Extract timelogs array
   - Calculate total minutes across all entries
   - Format as hours and minutes
   - Return structured JSON

## Output Format

```json
{
  "timelogs": [
    {
      "id": "987654",
      "taskId": "26134585",
      "taskName": "Update database schema",
      "description": "Implemented schema migration",
      "date": "2025-12-03",
      "hours": 2,
      "minutes": 30,
      "totalMinutes": 150,
      "userId": "123456",
      "userName": "John Doe",
      "userEmail": "john.doe@company.com",
      "createdAt": "2025-12-03T15:30:00Z"
    },
    {
      "id": "987655",
      "taskId": "26134585",
      "taskName": "Update database schema",
      "description": "Testing and validation",
      "date": "2025-12-03",
      "hours": 1,
      "minutes": 15,
      "totalMinutes": 75,
      "userId": "123456",
      "userName": "John Doe",
      "userEmail": "john.doe@company.com",
      "createdAt": "2025-12-03T17:00:00Z"
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
    }
  },
  "meta": {
    "taskId": "26134585",
    "fromDate": "2025-12-01",
    "toDate": "2025-12-03",
    "userIds": ["123456"],
    "appliedFilters": {
      "dateRange": true,
      "users": false
    }
  }
}
```

## Error Handling

**If taskId not provided:**
```text
❌ Missing required parameter: taskId

Usage: /tw-get-task-timelogs <taskId> [fromDate] [toDate] [userIds]

Examples:
  /tw-get-task-timelogs 26134585
  /tw-get-task-timelogs 26134585 "2025-12-01" "2025-12-03"
  /tw-get-task-timelogs 26134585 "" "" "123456,789012"

Parameters:
  taskId   - Task ID (numeric, no "TW-" prefix)
  fromDate - Optional: Start date (YYYY-MM-DD), use "" to skip
  toDate   - Optional: End date (YYYY-MM-DD), use "" to skip
  userIds  - Optional: Comma-separated user IDs, use "" to skip
```

**If credentials missing:**
```text
❌ Teamwork Credentials Required

Please create ~/.teamwork/credentials.json
```

**If API request fails:**
- 401 Unauthorized: "Invalid API key"
- 404 Not Found: "Task '${taskId}' not found"

Return error JSON:
```json
{
  "error": true,
  "message": "Task '26134585' not found or access denied",
  "statusCode": 404,
  "taskId": "26134585"
}
```

## Special Cases

**No timelogs found:**
```json
{
  "timelogs": [],
  "totalSummary": {
    "totalMinutes": 0,
    "totalHours": 0,
    "formatted": "0h 0m",
    "entryCount": 0,
    "breakdown": {
      "hours": 0,
      "minutes": 0
    }
  },
  "meta": {
    "taskId": "26134585",
    "message": "No timelogs found for this task"
  }
}
```

## Notes

- **Automatic aggregation**: Total summary is always included in response
- **Date format**: Input YYYY-MM-DD is converted to YYYYMMDD for API
- **Pagination**: Uses pageSize=250 (Teamwork max) to minimize requests
- **User filtering**: Accepts comma-separated user IDs
- **Flexible parameters**: Use empty strings ("") to skip optional params
- **Total calculation**: Sums all timelog minutes and formats as hours/minutes

## Use Cases

- **Task time analysis**: See total time spent on a specific task
- **User time tracking**: Filter to see specific user's contributions
- **Date range analysis**: Analyze time within specific periods
- **Progress tracking**: Monitor time logged against estimates
- **Reporting**: Generate time summaries for stakeholders
