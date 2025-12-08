---
description: Fetch subtasks of a Teamwork task (helper)
allowedTools:
  - Bash
  - Read
---

# Teamwork API: Get Subtasks

Fetches all subtasks (child tasks) for a given parent task.

## Usage

```bash
/tw-get-subtasks 26134585
```

## Input Parameters

- **taskId** (required): Parent task ID (numeric only, no "TW-" prefix)

## Implementation

1. **Validate input:**
   ```bash
   taskId=$1

   if [ -z "$taskId" ]; then
     echo "Error: taskId required"
     exit 1
   fi

   # Strip "TW-" prefix if present
   taskId=${taskId#TW-}
   ```

2. **Read credentials:**
   - Read `~/.teamwork/credentials.json`
   - Extract `apiKey` and `domain`

3. **Make API request:**
   ```bash
   curl -s -u "${apiKey}:xxx" \
     "https://${domain}/tasks/${taskId}.json?include=subtasks"
   ```

4. **Parse response and extract subtasks:**
   - The response includes task + subtasks
   - Extract the `subtasks` array from the task object
   - Return JSON in this format:

```json
{
  "subtasks": [
    {
      "id": "26134586",
      "name": "Design database schema",
      "description": "",
      "status": "new",
      "priority": "medium",
      "dueDate": "2025-12-04",
      "estimateMinutes": 60,
      "progress": 0,
      "parentTaskId": "26134585",
      "assignees": [
        {
          "id": "123456",
          "firstName": "Jane",
          "lastName": "Smith",
          "email": "jane.smith@company.com"
        }
      ],
      "taskListId": "1300158",
      "projectId": "388711"
    },
    {
      "id": "26134587",
      "name": "Write migration scripts",
      "description": "",
      "status": "new",
      "priority": "high",
      "dueDate": "2025-12-05",
      "estimateMinutes": 90,
      "progress": 0,
      "parentTaskId": "26134585",
      "assignees": [],
      "taskListId": "1300158",
      "projectId": "388711"
    }
  ],
  "meta": {
    "parentTaskId": "26134585",
    "count": 2
  }
}
```

## Error Handling

**If taskId not provided:**
```text
❌ Missing required parameter: taskId

Usage: /tw-get-subtasks <taskId>
Example: /tw-get-subtasks 26134585

Note: Use numeric ID only, not "TW-26134585"
```

**If credentials missing:**
```text
❌ Teamwork Credentials Required

Please create ~/.teamwork/credentials.json
```

**If API request fails:**
- 401 Unauthorized: "Invalid API key"
- 404 Not Found: "Task '${taskId}' not found or access denied"
- Network error: "Cannot connect to Teamwork API"

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

**Task has no subtasks:**
```json
{
  "subtasks": [],
  "meta": {
    "parentTaskId": "26134585",
    "count": 0
  }
}
```

## Notes

- **Only direct children:** Returns 1 level deep (immediate subtasks only)
- **No recursive fetch:** Does not fetch subtasks of subtasks
- **Automatic prefix handling:** Strips "TW-" if provided
- **All assignees:** Includes all users assigned to each subtask
- **Inherits context:** Subtasks belong to same project/tasklist as parent
