---
description: Get all timelog entries for a Teamwork project with total summary (helper)
allowedTools:
  - Bash
  - Read
---

# Teamwork API: Get Project Timelogs

Fetches all timelog entries for an entire project with optional filtering and total summary.

## Usage

```bash
/tw-get-project-timelogs 388711                                    # All project timelogs
/tw-get-project-timelogs 388711 "2025-12-01"                      # From date onward
/tw-get-project-timelogs 388711 "2025-12-01" "2025-12-03"         # Date range
/tw-get-project-timelogs 388711 "" "" "123456,789012"             # Filter by users
/tw-get-project-timelogs 388711 "2025-12-01" "2025-12-03" "123456" # Combined filters
```

## Input Parameters

- **projectId** (required): Project ID (numeric)
- **fromDate** (optional): Start date in YYYY-MM-DD format (use "" to skip)
- **toDate** (optional): End date in YYYY-MM-DD format (use "" to skip)
- **userIds** (optional): Comma-separated list of user IDs (use "" to skip)

## Implementation

1. **Validate and parse input:**
   ```bash
   projectId=$1
   fromDate=$2
   toDate=$3
   userIds=$4

   # Validate projectId
   if [ -z "$projectId" ]; then
     echo "Error: projectId required"
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
     queryParams="${queryParams}userId=${userIds}&"
   fi

   # Add pagination
   queryParams="${queryParams}pageSize=250"
   ```

4. **Make API request with pagination:**
   ```bash
   # Fetch all pages of timelogs
   page=1
   hasMore=true
   allTimelogs=[]

   while [ "$hasMore" = true ]; do
     response=$(curl -s -u "${apiKey}:xxx" \
       "https://${domain}/projects/${projectId}/time.json${queryParams}&page=${page}")

     # Parse timelogs from response
     # Check if more pages exist
     # Append to allTimelogs

     page=$((page + 1))
   done
   ```

5. **Parse response, calculate totals, and format output:**
   - Extract all timelogs from paginated responses
   - Calculate total minutes across all entries
   - Format as hours and minutes
   - Group by task for easier analysis
   - Return structured JSON

## Output Format

```json
{
  "timelogs": [
    {
      "id": "987654",
      "taskId": "26134585",
      "taskName": "Update database schema",
      "taskListId": "1300158",
      "taskListName": "Production Support",
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
      "taskId": "26134587",
      "taskName": "Write migration scripts",
      "taskListId": "1300158",
      "taskListName": "Production Support",
      "description": "Migration script v1",
      "date": "2025-12-03",
      "hours": 1,
      "minutes": 45,
      "totalMinutes": 105,
      "userId": "789012",
      "userName": "Jane Smith",
      "userEmail": "jane.smith@company.com",
      "createdAt": "2025-12-03T14:00:00Z"
    }
  ],
  "totalSummary": {
    "totalMinutes": 255,
    "totalHours": 4.25,
    "formatted": "4h 15m",
    "entryCount": 2,
    "breakdown": {
      "hours": 4,
      "minutes": 15
    },
    "byTask": [
      {
        "taskId": "26134585",
        "taskName": "Update database schema",
        "totalMinutes": 150,
        "formatted": "2h 30m",
        "entryCount": 1
      },
      {
        "taskId": "26134587",
        "taskName": "Write migration scripts",
        "totalMinutes": 105,
        "formatted": "1h 45m",
        "entryCount": 1
      }
    ],
    "byUser": [
      {
        "userId": "123456",
        "userName": "John Doe",
        "totalMinutes": 150,
        "formatted": "2h 30m",
        "entryCount": 1
      },
      {
        "userId": "789012",
        "userName": "Jane Smith",
        "totalMinutes": 105,
        "formatted": "1h 45m",
        "entryCount": 1
      }
    ]
  },
  "meta": {
    "projectId": "388711",
    "projectName": "BVI Modernization Plan - Phase 1 Project",
    "fromDate": "2025-12-01",
    "toDate": "2025-12-03",
    "userIds": [],
    "appliedFilters": {
      "dateRange": true,
      "users": false
    },
    "pagesProcessed": 1
  }
}
```

## Error Handling

**If projectId not provided:**
```text
❌ Missing required parameter: projectId

Usage: /tw-get-project-timelogs <projectId> [fromDate] [toDate] [userIds]

Examples:
  /tw-get-project-timelogs 388711
  /tw-get-project-timelogs 388711 "2025-12-01" "2025-12-03"
  /tw-get-project-timelogs 388711 "" "" "123456,789012"

Parameters:
  projectId - Project ID (numeric)
  fromDate  - Optional: Start date (YYYY-MM-DD), use "" to skip
  toDate    - Optional: End date (YYYY-MM-DD), use "" to skip
  userIds   - Optional: Comma-separated user IDs, use "" to skip
```

**If credentials missing:**
```text
❌ Teamwork Credentials Required

Please create ~/.teamwork/credentials.json
```

**If API request fails:**
- 401 Unauthorized: "Invalid API key"
- 404 Not Found: "Project '${projectId}' not found or access denied"

Return error JSON:
```json
{
  "error": true,
  "message": "Project '388711' not found or access denied",
  "statusCode": 404,
  "projectId": "388711"
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
    },
    "byTask": [],
    "byUser": []
  },
  "meta": {
    "projectId": "388711",
    "message": "No timelogs found for this project"
  }
}
```

## Notes

- **Automatic aggregation**: Total summary is always included in response
- **Pagination**: Automatically fetches all pages (handles large projects)
- **Multi-level breakdown**: Provides totals by task AND by user
- **Date format**: Input YYYY-MM-DD is converted to YYYYMMDD for API
- **User filtering**: Accepts comma-separated user IDs
- **Flexible parameters**: Use empty strings ("") to skip optional params
- **Progress indication**: Shows page numbers for large datasets

## Use Cases

- **Project time analysis**: See total time spent across entire project
- **Team productivity**: Compare time logged by different team members
- **Task distribution**: Understand which tasks consumed most time
- **Date range reporting**: Generate time summaries for specific periods
- **Budget tracking**: Monitor time against project estimates
- **Invoice preparation**: Gather billable hours for client invoicing
- **Sprint analysis**: Review time logged during specific sprint dates
