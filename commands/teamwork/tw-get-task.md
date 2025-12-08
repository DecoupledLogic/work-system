---
description: Fetch details of a single Teamwork task (helper)
allowedTools:
  - Bash
  - Read
---

# Teamwork API: Get Task

Fetches complete details of a single task by ID.

## Usage

```bash
/tw-get-task 26134585
```

## Input Parameters

- **taskId** (required): Task ID (numeric only, no "TW-" prefix)

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
     "https://${domain}/tasks/${taskId}.json?include=assignees"
   ```

4. **Parse response and format output:**
   - Extract task object
   - Return JSON in this format:

```json
{
  "task": {
    "id": "26134585",
    "name": "Update database schema",
    "description": "Migrate to new schema version for better performance",
    "status": "new",
    "priority": "high",
    "dueDate": "2025-12-05",
    "startDate": null,
    "estimateMinutes": 120,
    "progress": 0,
    "hasSubtasks": true,
    "parentTaskId": "26134584",
    "createdAt": "2025-12-01T10:00:00Z",
    "updatedAt": "2025-12-02T15:30:00Z",
    "completedAt": null,
    "assignees": [
      {
        "id": "123456",
        "firstName": "John",
        "lastName": "Doe",
        "email": "john.doe@company.com",
        "avatar": "https://..."
      }
    ],
    "creator": {
      "id": "789012",
      "firstName": "Jane",
      "lastName": "Manager",
      "email": "jane.manager@company.com"
    },
    "taskListId": "1300158",
    "taskListName": "Production Support",
    "projectId": "388711",
    "projectName": "BVI Modernization Plan - Phase 1 Project",
    "companyId": "123456",
    "companyName": "BVI"
  }
}
```

## Error Handling

**If taskId not provided:**
```text
❌ Missing required parameter: taskId

Usage: /tw-get-task <taskId>
Example: /tw-get-task 26134585

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

## Notes

- **Full task details:** Returns complete task object with all properties
- **Assignee information:** Includes all users assigned to the task
- **Parent context:** If task is a subtask, includes `parentTaskId`
- **Subtask indicator:** `hasSubtasks` field shows if task has children
- **Automatic prefix handling:** Strips "TW-" if provided
- **Rich metadata:** Includes creator, dates, progress, estimates, etc.

## Use Cases

This endpoint is used by task-fetcher agent to:
1. **Enrich subtasks** with parent task information when parent is not assigned to user
2. **Fetch single task details** for display or processing
3. **Verify task existence** before operations
