# Task Selector Agent

Display, group, sort, and facilitate interactive selection of tasks.

## Overview

| Property | Value |
|----------|-------|
| **Name** | task-selector |
| **Model** | haiku |
| **Tools** | Read |
| **Stage** | Select |

## Purpose

The Task Selector agent handles all presentation logic and user interaction for task selection workflows. It receives task data from the task-fetcher agent and presents it in an organized, prioritized format for user selection.

## Input

Expects a JSON object with task data from task-fetcher:

```json
{
  "tasks": [...],
  "metadata": {
    "projectName": "Production Support",
    "clientName": "ACME Corp",
    "statusFilters": ["new", "reopened"],
    "userEmail": "user@company.com",
    "totalTasks": 42
  },
  "displayMode": "select" | "resume"
}
```

### Display Modes

| Mode | Header | Progress Display |
|------|--------|------------------|
| `select` | "New Work" | Omits progress percentage |
| `resume` | "In Progress" | Includes progress and time tracking |

## Output

Returns structured JSON with the selected task:

```json
{
  "selectedTask": {
    "id": "26134585",
    "name": "Update database schema",
    "status": "new",
    "priority": "high",
    "dueDate": "2025-12-05",
    "estimateMinutes": 120,
    "taskListId": "1300158",
    "taskListName": "Production Support",
    "parentTask": {
      "id": "26134584",
      "name": "Service Plan Management"
    },
    "projectId": "545123"
  },
  "selectionIndex": 5,
  "displayedCount": 42,
  "cancelled": false
}
```

## Key Features

### Urgency Calculation

Tasks are categorized by urgency based on due date:

| Urgency | Condition |
|---------|-----------|
| `overdue` | Due date < today |
| `today` | Due date == today |
| `week` | Due date within 7 days |
| `future` | Due date > 7 days |

### Priority Weighting

| Priority | Weight |
|----------|--------|
| High | 3 |
| Medium | 2 |
| Low | 1 |
| None | 0 |

### Sorting Order

Tasks are sorted by (in order of precedence):

1. Urgency rank (overdue > today > week > future)
2. Priority weight (high > medium > low > none)
3. Due date (earliest first)
4. Created date (oldest first)

### Grouping

Tasks are grouped by urgency + priority combination:

- Overdue - High/Medium/Low Priority
- Due Today - High/Medium/Low Priority
- Due This Week - High/Medium/Low Priority
- Future (all priorities combined)

### Display Icons

| Icon | Meaning |
|------|---------|
| 🚨 | Overdue |
| ⚡ | High priority |
| ⏰ | Due today |
| 📅 | Due this week |
| 📋 | Future |

## Process Flow

1. **Enrich Tasks** - Calculate urgency, priority weight, and date info
2. **Sort Tasks** - Apply multi-level sort algorithm
3. **Group Tasks** - Organize by urgency/priority combination
4. **Display Tasks** - Render formatted output with numbering
5. **Interactive Selection** - Accept user input and validate
6. **Return Result** - Output selected task as structured JSON

## Context Efficiency

This agent handles all presentation logic in isolated context, returning only the selected task object (~500 bytes) to the main session instead of the full task list (~20-50KB).

## Integration Points

| Agent | Direction | Data |
|-------|-----------|------|
| task-fetcher | Receives from | Task data with metadata |
| Main session | Returns to | Selected task object |

## Special Cases

### No Tasks Available

Returns a friendly message based on mode:

**Select mode:**
```
✅ No New Work Available
No pending tasks found...
```

**Resume mode:**
```
✅ No Tasks In Progress
No in-progress tasks found...
```

### User Cancellation

```json
{
  "cancelled": true,
  "message": "Selection cancelled by user"
}
```

## Related

- [task-fetcher](task-fetcher.md) - Provides task data
- [index](index.md) - Agent overview
