---
description: Fetch tasks from a Teamwork task list with pagination (helper)
allowedTools:
  - Bash
  - Read
---

# Teamwork API: Get Tasks

Fetches tasks from a task list with pagination support.

## Usage

```bash
/tw-get-tasks 1300158              # First page, 100 items
/tw-get-tasks 1300158 2            # Page 2, 100 items
/tw-get-tasks 1300158 1 50         # Page 1, 50 items
```

## Input Parameters

- **tasklistId** (required): Task list ID
- **page** (optional): Page number (default: 1)
- **pageSize** (optional): Results per page (default: 100, max: 250)

## Implementation

1. **Validate and parse input:**
   ```bash
   tasklistId=$1
   page=${2:-1}
   pageSize=${3:-100}

   if [ -z "$tasklistId" ]; then
     echo "Error: tasklistId required"
     exit 1
   fi
   ```

2. **Read credentials:**
   - Read `~/.teamwork/credentials.json`
   - Extract `apiKey` and `domain`

3. **Make API request:**
   ```bash
   curl -s -u "${apiKey}:xxx" \
     "https://${domain}/tasklists/${tasklistId}/tasks.json?page=${page}&pageSize=${pageSize}&includeCompletedTasks=false&includeArchivedProjects=false"
   ```

4. **Parse response and format output:**
   - Extract tasks array
   - Extract pagination metadata
   - Return JSON in this format:

```json
{
  "tasks": [
    {
      "id": "26134585",
      "name": "Update database schema",
      "description": "Migrate to new schema version",
      "status": "new",
      "priority": "high",
      "dueDate": "2025-12-05",
      "startDate": null,
      "estimateMinutes": 120,
      "progress": 0,
      "hasSubtasks": false,
      "parentTaskId": null,
      "createdAt": "2025-12-01T10:00:00Z",
      "assignees": [
        {
          "id": "123456",
          "firstName": "John",
          "lastName": "Doe",
          "email": "john.doe@company.com"
        }
      ],
      "projectId": "388711",
      "taskListId": "1300158"
    }
  ],
  "meta": {
    "page": {
      "count": 100,
      "hasMore": true,
      "pageSize": 100,
      "page": 1,
      "totalCount": 250
    },
    "taskListId": "1300158"
  }
}
```

## Error Handling

**If tasklistId not provided:**
```text
❌ Missing required parameter: tasklistId

Usage: /tw-get-tasks <tasklistId> [page] [pageSize]
Example: /tw-get-tasks 1300158 1 100
```

**If credentials missing:**
```text
❌ Teamwork Credentials Required

Please create ~/.teamwork/credentials.json
```

**If API request fails:**
- 401 Unauthorized: "Invalid API key"
- 404 Not Found: "Task list '${tasklistId}' not found"
- Network error: "Cannot connect to Teamwork API"

Return error JSON:
```json
{
  "error": true,
  "message": "Task list '1300158' not found or access denied",
  "statusCode": 404,
  "taskListId": "1300158"
}
```

## Notes

- **Pagination:** Use `meta.page.hasMore` to determine if more pages exist
- **Default pageSize:** 100 (recommended for performance)
- **Max pageSize:** 250 (Teamwork API limit)
- **Completed tasks:** Excluded by default (add param to include)
- **Task properties:** Includes all standard fields (assignees, dates, priority, etc.)
- **Subtask indicator:** `hasSubtasks` field shows if task has children
