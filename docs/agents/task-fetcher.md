# Task Fetcher Agent

Fetch and enrich tasks from Teamwork projects with comprehensive pagination.

## Overview

| Property | Value |
|----------|-------|
| **Name** | task-fetcher |
| **Model** | haiku |
| **Tools** | SlashCommand, Read |
| **Stage** | Select |

## Purpose

The Task Fetcher is a task data orchestrator specialized in Teamwork API integration. It fetches, paginates, enriches, and filters tasks with maximum efficiency and completeness.

## Input Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| projectId | Yes | Teamwork project ID (numeric) |
| statusFilters | Yes | Array of statuses (e.g., ["new", "reopened"]) |
| userEmail | Yes | User email for assignee filtering |
| userName | No | User name for fallback matching |
| userId | No | User ID for exact matching |
| projectName | No | For progress display |
| clientName | No | For context display |

## Output

Returns structured JSON:

```json
{
  "tasks": [
    {
      "id": "26134585",
      "name": "Update database schema",
      "status": "new",
      "priority": "high",
      "dueDate": "2025-12-05",
      "estimateMinutes": 120,
      "progress": 0,
      "assignees": [...],
      "taskListId": "1300158",
      "taskListName": "Production Support",
      "parentTask": {
        "id": "26134584",
        "name": "Service Plan Management",
        "assignees": [...]
      },
      "parentTaskId": "26134584",
      "projectId": "545123"
    }
  ],
  "metadata": {
    "totalTasks": 42,
    "taskListCount": 5,
    "projectId": "545123",
    "projectName": "Production Support",
    "statusFilters": ["new", "reopened"],
    "userEmail": "user@company.com",
    "fetchedAt": "2025-12-03T10:30:00Z"
  }
}
```

## Process

### Step 1: Fetch All Task Lists

```
/tw-get-tasklists {projectId}
```

Extract `id` and `name` from each tasklist.

### Step 2: Fetch All Tasks with Pagination

**Critical:** Implements robust pagination to ensure no tasks are missed.

```
For each task list:
  page = 1
  hasMore = true
  maxPages = 20  // Safety limit: 2,000 tasks max per list
  pageSize = 100

  While hasMore AND page <= maxPages:
    /tw-get-tasks {tasklistId} {page} 100

    Enrich each task with:
      - taskListId
      - taskListName

    Append to allTasks

    Update hasMore from response
    page++
```

### Step 3: Fetch Subtasks (2 Levels Deep)

For each top-level assigned task:

```
/tw-get-subtasks {taskId}

Enrich each subtask with:
  - taskListId (from parent)
  - taskListName (from parent)
  - parentTask object
```

Only fetches 1 level (no recursive subtask fetching).

### Step 4: Enrich Subtasks with Parent Context

For subtasks where parent is NOT assigned to user:

```
/tw-get-task {parentTaskId}

Add parentTask object:
  - id
  - name
  - assignees
```

### Step 5: Filter Tasks

1. **Status filter:** Include only tasks matching statusFilters
2. **Assignee filter:** Include only tasks assigned to user

## Error Handling

### API Unavailable

```json
{
  "error": true,
  "message": "Teamwork API unavailable",
  "details": "Unable to connect. Check credentials..."
}
```

### Invalid Project ID

```json
{
  "error": true,
  "message": "Invalid project ID",
  "details": "Project not found or access denied"
}
```

### No Tasks Found

Returns success with empty array:

```json
{
  "tasks": [],
  "metadata": {
    "totalTasks": 0,
    "message": "No tasks match filters"
  }
}
```

## Teamwork ID Handling

**Critical:** All Teamwork IDs must be numeric only.

| Correct | Incorrect |
|---------|-----------|
| `id: 26162664` | `id: "TW-26162664"` |

Slash commands automatically strip "TW-" prefix if provided.

## Performance

| Project Size | API Calls | Duration |
|--------------|-----------|----------|
| Typical (3 lists, 150 tasks) | ~10-20 | 3-5 seconds |
| Large (10 lists, 500 tasks) | ~50-100 | 10-20 seconds |
| Very large (10+ lists, 2000+ tasks) | ~200+ | 30-60 seconds |

Shows progress indicators for large projects.

## SlashCommand Usage

All Teamwork API calls use SlashCommand tool:

```
/tw-get-tasklists 388711
/tw-get-tasks 1300158 1 100
/tw-get-subtasks 26134585
/tw-get-task 26134585
```

## Context Efficiency

Handles all heavy API work in isolated context. Main session only receives structured JSON output (~1-5KB), not full procedural instructions (~20KB).

## Focus Areas

- **Completeness** - Never miss tasks due to pagination limits
- **Enrichment** - Always include parent and task list context
- **Performance** - Show progress for long operations
- **Reliability** - Graceful error handling with partial results
- **Structure** - Return clean JSON for downstream processing

## Integration Points

| Agent | Direction | Data |
|-------|-----------|------|
| task-selector | Provides to | Task data with metadata |
| Main session | Returns to | Structured task JSON |

## Related

- [task-selector](task-selector.md) - Receives task data
- [index](index.md) - Agent overview
