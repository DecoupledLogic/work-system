# Work Item Mapper Agent

Map external task data to the normalized WorkItem schema.

## Overview

| Property | Value |
|----------|-------|
| **Name** | work-item-mapper |
| **Model** | haiku |
| **Tools** | Read |
| **Stage** | Triage |

## Purpose

The Work Item Mapper transforms external task management data (Teamwork) into the normalized WorkItem schema. This normalization layer ensures all downstream agents work with consistent data structures.

## Input

Expects Teamwork task JSON:

```json
{
  "id": "26134585",
  "name": "Update database schema",
  "description": "Customer requests schema update...",
  "status": "new",
  "priority": "high",
  "dueDate": "2025-12-05",
  "estimateMinutes": 120,
  "progress": 0,
  "tags": ["support", "database"],
  "parentTask": { "id": "26134584", "name": "Service Plan Management" },
  "taskListId": "1300158",
  "taskListName": "Production Support",
  "projectId": "545123",
  "projectName": "Link Production Support"
}
```

## Output

Returns normalized WorkItem JSON:

```json
{
  "workItem": {
    "id": "TW-26134585",
    "name": "Update database schema",
    "type": "story",
    "workType": "support",
    "urgency": "now",
    "impact": "medium",
    "appetite": { "unit": "hours", "value": 2 },
    "capability": "database",
    "status": "triage",
    "parentId": "TW-26134584",
    "source": {
      "system": "teamwork",
      "projectId": "545123",
      "originalStatus": "new",
      "url": "https://..."
    }
  },
  "mappingNotes": {
    "typeInference": "Detected 'story' from...",
    "workTypeInference": "Detected 'support' from...",
    "unmappedFields": []
  }
}
```

## Mapping Rules

### Type Inference

| Condition | Type |
|-----------|------|
| Has children, no parent | `epic` |
| Has parent (epic-level), has children | `feature` |
| Has parent (feature-level), may have children | `story` |
| Has parent (story-level), no children | `task` |
| Standalone, estimateMinutes > 480 | `feature` |
| Standalone, estimateMinutes <= 480 | `story` |

### WorkType Inference

| Indicators | WorkType |
|------------|----------|
| Tags: bug, defect, fix, error | `bug_fix` |
| Tags: support, customer, request | `support` |
| Tags: maintenance, tech-debt, refactor | `maintenance` |
| Tags: research, spike, investigate | `research` |
| Task list: "Production Support", "Customer" | `support` |
| None of above | `product_delivery` |

### Urgency Inference

| Condition | Urgency |
|-----------|---------|
| Tags contain: critical, urgent | `critical` |
| Due date is past | `critical` |
| Due date within 3 days | `now` |
| Due date within 14 days | `next` |
| Due date > 14 days | `future` |
| Status = "reopened" | `now` |
| No due date, status = "new" | `next` |

### Impact Inference

| Condition | Impact |
|-----------|--------|
| Priority = "high" | `high` |
| Priority = "medium" | `medium` |
| Priority = "low" | `low` |
| Tags: critical, revenue, security | `high` |
| No priority set | `medium` |

### Appetite Mapping

| Type | Unit | Conversion |
|------|------|------------|
| epic | cycles | estimateMinutes / (40 * 60), max 3 |
| feature | weeks | estimateMinutes / (40 * 60), max 2 |
| story | days | estimateMinutes / (8 * 60), max 3 |
| task | hours | estimateMinutes / 60, max 8 |

### Status Mapping

| Teamwork Status | WorkItem Status |
|-----------------|-----------------|
| new | `triage` |
| reopened | `triage` |
| in_progress | `in_progress` |
| completed | `done` |

### ID Formatting

- Prefix Teamwork IDs with "TW-": `26134585` → `TW-26134585`
- Parent IDs also get prefix

## Edge Cases

### Missing Data

| Field | Default |
|-------|---------|
| No due date | urgency = `next` |
| No priority | impact = `medium` |
| No estimate | appetite = `null` |
| No tags | workType = `product_delivery` |
| No parent | parentId = `null` |

### Conflicting Signals

Precedence (highest to lowest):

1. Explicit tags
2. Task list name
3. Priority field
4. Description keywords
5. Defaults

### Batch Processing

For arrays of tasks, returns:

```json
{
  "workItems": [...],
  "summary": {
    "total": 15,
    "byType": { "story": 12, "task": 3 },
    "byWorkType": { "support": 10, "bug_fix": 5 },
    "byUrgency": { "now": 8, "next": 7 }
  }
}
```

## Focus Areas

- **Consistency** - Same input always produces same output
- **Transparency** - Document all inferences in mappingNotes
- **Completeness** - Map all available fields
- **Defaults** - Use sensible defaults for missing data
- **Reversibility** - Preserve source data for round-trip

## Integration Points

| Agent | Direction | Data |
|-------|-----------|------|
| task-fetcher | Receives from | Raw Teamwork task data |
| triage-agent | Provides to | Normalized WorkItem |

## Related

- [task-fetcher](task-fetcher.md) - Provides raw task data
- [triage-agent](triage-agent.md) - Consumes normalized WorkItems
- [index](index.md) - Agent overview
