# Teamwork Slash Commands Reference

Direct API commands for Teamwork project management and time tracking.

## Why These Commands?

These commands provide direct access to the Teamwork API without the overhead of the Teamwork MCP server. Benefits include:
- **96% context reduction** (~50KB → ~2KB per operation)
- Faster response times
- Better error messages and debugging
- Full control over API requests
- No MCP server dependency

---

## Configuration

### Required Files

**1. API Credentials**: `~/.teamwork/credentials.json`
```json
{
  "apiKey": "twp_YOUR_API_KEY_HERE",
  "domain": "yourcompany.teamwork.com"
}
```

**Get your API key:**
1. Log into Teamwork → Profile → Edit My Details → API & Mobile tab
2. Copy your API key (starts with "twp_")

**2. User Configuration**: `~/.claude/teamwork.json`
```json
{
  "user": {
    "email": "your.email@company.com",
    "name": "Your Name",
    "id": "123456"
  }
}
```

**Note:** This is the same file used by `/select-task` and `/resume` commands.

---

## Task & Project Data Commands

### `/tw-get-projects`
List all projects in your Teamwork account.

```bash
/tw-get-projects              # All projects
/tw-get-projects active       # Only active projects
/tw-get-projects archived     # Only archived projects
```

**Returns:** JSON with projects array and metadata.

---

### `/tw-get-tasklists`
Get all task lists for a specific project.

```bash
/tw-get-tasklists 388711
```

**Parameters:**
- `projectId` (required) - Teamwork project ID

**Returns:** JSON with tasklists array (id, name, status, etc.)

---

### `/tw-get-tasks`
Get tasks from a task list with pagination support.

```bash
/tw-get-tasks 1300158              # First page, 100 items
/tw-get-tasks 1300158 2            # Page 2, 100 items
/tw-get-tasks 1300158 1 50         # Page 1, 50 items
```

**Parameters:**
- `tasklistId` (required) - Task list ID
- `page` (optional) - Page number (default: 1)
- `pageSize` (optional) - Results per page (default: 100, max: 250)

**Returns:** JSON with tasks array and pagination metadata.

---

### `/tw-get-subtasks`
Get all subtasks (child tasks) of a parent task.

```bash
/tw-get-subtasks 26134585
```

**Parameters:**
- `taskId` (required) - Parent task ID (numeric, no "TW-" prefix)

**Returns:** JSON with subtasks array and count.

---

### `/tw-get-task`
Get detailed information for a single task.

```bash
/tw-get-task 26134585
```

**Parameters:**
- `taskId` (required) - Task ID (numeric, no "TW-" prefix)

**Returns:** JSON with complete task details (assignees, dates, progress, etc.)

---

## Time Logging Commands

### `/tw-create-task-timelog`
Create a new timelog entry for a task.

```bash
/tw-create-task-timelog 26134585 "2025-12-03" 2 10 "Implemented schema migration"
/tw-create-task-timelog 26134585 "2025-12-03" 1 0 "Code review"
```

**Parameters:**
- `taskId` (required) - Task ID (numeric)
- `date` (required) - Date in YYYY-MM-DD format
- `hours` (required) - Hours worked (0-23)
- `minutes` (required) - Minutes worked (0-59)
- `description` (required) - Brief one-line description (use quotes)

**Features:**
- **Automatic 15-minute rounding**: Time is rounded UP to nearest 15-minute interval
  - 1h 7m → 1h 15m
  - 2h 13m → 2h 15m
  - 0h 42m → 0h 45m
  - 1h 46m → 2h 0m
- **Automatic user detection**: Uses `user.id` from `~/.claude/teamwork.json`

**Returns:** JSON with created timelog details.

---

### `/tw-get-task-timelogs`
Get all timelog entries for a specific task.

```bash
/tw-get-task-timelogs 26134585                                    # All timelogs
/tw-get-task-timelogs 26134585 "2025-12-01"                      # From date onward
/tw-get-task-timelogs 26134585 "2025-12-01" "2025-12-03"         # Date range
/tw-get-task-timelogs 26134585 "" "" "123456,789012"             # Filter by users
/tw-get-task-timelogs 26134585 "2025-12-01" "2025-12-03" "123456" # Combined filters
```

**Parameters:**
- `taskId` (required) - Task ID
- `fromDate` (optional) - Start date in YYYY-MM-DD format (use "" to skip)
- `toDate` (optional) - End date in YYYY-MM-DD format (use "" to skip)
- `userIds` (optional) - Comma-separated user IDs (use "" to skip)

**Returns:** JSON with timelogs array + `totalSummary` object:
```json
{
  "timelogs": [...],
  "totalSummary": {
    "totalMinutes": 225,
    "totalHours": 3.75,
    "formatted": "3h 45m",
    "entryCount": 2,
    "breakdown": { "hours": 3, "minutes": 45 }
  }
}
```

---

### `/tw-get-subtasks-timelogs`
Get all timelog entries for all subtasks of a parent task.

```bash
/tw-get-subtasks-timelogs 26134585                                    # All subtask timelogs
/tw-get-subtasks-timelogs 26134585 "2025-12-01"                      # From date onward
/tw-get-subtasks-timelogs 26134585 "2025-12-01" "2025-12-03"         # Date range
/tw-get-subtasks-timelogs 26134585 "" "" "123456,789012"             # Filter by users
```

**Parameters:**
- `parentTaskId` (required) - Parent task ID
- `fromDate` (optional) - Start date (YYYY-MM-DD)
- `toDate` (optional) - End date (YYYY-MM-DD)
- `userIds` (optional) - Comma-separated user IDs

**Returns:** JSON with aggregated timelogs + `totalSummary` including `bySubtask` breakdown:
```json
{
  "timelogs": [...],
  "totalSummary": {
    "totalMinutes": 225,
    "formatted": "3h 45m",
    "bySubtask": [
      {
        "subtaskId": "26134586",
        "subtaskName": "Design database schema",
        "totalMinutes": 90,
        "formatted": "1h 30m"
      }
    ]
  }
}
```

---

### `/tw-get-project-timelogs`
Get all timelog entries for an entire project.

```bash
/tw-get-project-timelogs 388711                                    # All project timelogs
/tw-get-project-timelogs 388711 "2025-12-01"                      # From date onward
/tw-get-project-timelogs 388711 "2025-12-01" "2025-12-03"         # Date range
/tw-get-project-timelogs 388711 "" "" "123456,789012"             # Filter by users
```

**Parameters:**
- `projectId` (required) - Project ID
- `fromDate` (optional) - Start date (YYYY-MM-DD)
- `toDate` (optional) - End date (YYYY-MM-DD)
- `userIds` (optional) - Comma-separated user IDs

**Returns:** JSON with timelogs + `totalSummary` including `byTask` and `byUser` breakdowns:
```json
{
  "timelogs": [...],
  "totalSummary": {
    "totalMinutes": 255,
    "formatted": "4h 15m",
    "byTask": [...],
    "byUser": [
      {
        "userId": "123456",
        "userName": "John Doe",
        "totalMinutes": 150,
        "formatted": "2h 30m"
      }
    ]
  }
}
```

---

## Task Dependency Commands

### `/tw-task-dependency`
Set predecessor/successor relationships between Teamwork tasks.

```bash
/tw-task-dependency 26134585 --predecessor 26134580           # Add predecessor
/tw-task-dependency 26134585 --predecessor 26134580 --type start  # Start dependency
/tw-task-dependency 26134585 --successor 26134590             # Add successor
/tw-task-dependency 26134585 --remove-predecessor 26134580    # Remove predecessor
/tw-task-dependency 26134585 --remove-successor 26134590      # Remove successor
```

**Parameters:**
- `taskId` (required) - The Teamwork task ID to modify
- `--predecessor` (optional, repeatable) - Task ID that must complete/start first
- `--successor` (optional, repeatable) - Task ID that depends on this one
- `--type` (optional) - Dependency type: `complete` (default) or `start`
- `--remove-predecessor` (optional) - Remove predecessor relationship
- `--remove-successor` (optional) - Remove successor relationship

**Dependency Types:**
| Type | Description |
|------|-------------|
| `complete` | This task can complete when the predecessor completes (default) |
| `start` | This task can complete when the predecessor starts |

**Notes:**
- Uses Teamwork's native predecessor API
- Accepts both numeric IDs and TW-prefixed IDs (prefix is auto-stripped)
- Successors are implemented by adding this task as a predecessor to the target task

---

## Common Use Cases

### Agent Time Logging
When an agent completes work on a task:
```bash
/tw-create-task-timelog 26134585 "2025-12-03" 2 10 "Fixed authentication bug"
```

### Task Time Analysis
See total time spent on a task and its subtasks:
```bash
/tw-get-task-timelogs 26134585
/tw-get-subtasks-timelogs 26134585
```

### Project Time Analysis
Analyze time across entire project for a date range:
```bash
/tw-get-project-timelogs 388711 "2025-12-01" "2025-12-31"
```

### User Time Tracking
See specific user's time on a project:
```bash
/tw-get-project-timelogs 388711 "" "" "123456"
```

---

## Error Handling

All commands return consistent error JSON:
```json
{
  "error": true,
  "message": "Description of error",
  "statusCode": 404
}
```

**Common errors:**
- 401 Unauthorized: Invalid API key in `~/.teamwork/credentials.json`
- 404 Not Found: Project/task/list doesn't exist or no access
- 422 Unprocessable: Invalid data (check parameters)

---

## Notes

- **Task IDs**: Use numeric IDs only (no "TW-" prefix)
- **Date format**: Always YYYY-MM-DD
- **Empty parameters**: Use `""` to skip optional parameters
- **Total summaries**: All get timelog commands include totals (no separate -total commands)
- **Pagination**: Handled automatically where applicable
- **User config**: Time logging uses same config as `/select-task` for consistency
