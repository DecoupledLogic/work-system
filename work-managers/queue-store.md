# Queue Store

Local storage for queue assignments that works with any work manager.

## Storage Location

`~/.claude/session/queues.json`

## Schema

```json
{
  "version": "1.0",
  "assignments": {
    "<work-item-id>": {
      "queue": "immediate|todo|backlog|icebox",
      "assignedAt": "ISO-8601 timestamp",
      "assignedBy": "user or system",
      "reason": "optional reason for assignment"
    }
  },
  "history": [
    {
      "id": "<work-item-id>",
      "from": "previous-queue|null",
      "to": "new-queue",
      "at": "ISO-8601 timestamp",
      "reason": "reason for change"
    }
  ]
}
```

## Work Item ID Format

Work item IDs include a prefix indicating the manager:

| Manager | Format | Example |
|---------|--------|---------|
| Teamwork | `TW-<id>` | `TW-12345` |
| GitHub | `GH-<owner>/<repo>#<number>` | `GH-acme/app#123` |
| Linear | `LIN-<identifier>` | `LIN-ABC-123` |
| Jira | `JIRA-<key>` | `JIRA-PROJ-456` |
| Local | `LOCAL-<uuid>` | `LOCAL-abc123` |

## Operations

### Get Queue for Item

```
Input: workItemId
Output: queue name or null

1. Read queues.json
2. Look up assignments[workItemId]
3. Return queue or null if not assigned
```

### Set Queue for Item

```
Input: workItemId, queue, reason (optional)
Output: updated assignment

1. Read queues.json
2. Get current assignment (if any)
3. Add to history: { id, from: current, to: queue, at: now, reason }
4. Update assignments[workItemId] = { queue, assignedAt: now, reason }
5. Write queues.json
```

### List Items in Queue

```
Input: queue name
Output: list of workItemIds

1. Read queues.json
2. Filter assignments where queue matches
3. Return list of IDs
```

### Get Queue History for Item

```
Input: workItemId
Output: list of queue changes

1. Read queues.json
2. Filter history where id matches
3. Return sorted by timestamp
```

### Clear Item from Queues

```
Input: workItemId
Output: void

1. Read queues.json
2. Delete assignments[workItemId]
3. Add to history: { id, from: current, to: null, at: now, reason: "cleared" }
4. Write queues.json
```

## Integration with Work Managers

The queue store is **independent** of work managers. This means:

1. Queue assignments persist even if external system changes
2. Can track queues for items from multiple managers
3. Queue state survives manager switching
4. No API calls needed for queue operations

### Syncing with External Systems

If a project wants to sync queue to external system (labels, tags, etc.):

```yaml
# .claude/work-manager.yaml
queues:
  storage: local
  sync:
    enabled: true
    manager: github
    mapping:
      immediate: "priority: critical"
      todo: "priority: high"
      backlog: "priority: medium"
      icebox: "priority: low"
```

When sync is enabled:
1. Queue changes update local store first
2. Then attempt to update external system
3. If external update fails, local still reflects truth
4. Log warning about sync failure

## Queue Definitions

| Queue | Urgency | SLA | Description |
|-------|---------|-----|-------------|
| `immediate` | critical | Same day | Drop everything, production issues |
| `todo` | now | Current cycle | Active work for this sprint/cycle |
| `backlog` | next | Next cycle | Prioritized but not yet started |
| `icebox` | future | None | Parked, may never be done |

## Default Queue Assignment

When a work item is first triaged:

| Detected Urgency | Assigned Queue |
|------------------|----------------|
| critical | immediate |
| now | todo |
| next | backlog |
| future | icebox |

## Queue Metrics

The history enables analytics:

```
Time in queue:
  For each item, calculate time from assignment to completion

Queue throughput:
  Count items moved out of queue per time period

Queue growth:
  Count items added vs removed per time period

Escalation rate:
  Count moves from lower to higher priority queues
```

## Example Usage

### Route item to backlog

```json
// Before
{
  "assignments": {
    "TW-12345": { "queue": "todo", "assignedAt": "2024-12-06T10:00:00Z" }
  },
  "history": []
}

// After /route TW-12345 backlog --reason "Waiting on design"
{
  "assignments": {
    "TW-12345": {
      "queue": "backlog",
      "assignedAt": "2024-12-07T14:30:00Z",
      "reason": "Waiting on design"
    }
  },
  "history": [
    {
      "id": "TW-12345",
      "from": "todo",
      "to": "backlog",
      "at": "2024-12-07T14:30:00Z",
      "reason": "Waiting on design"
    }
  ]
}
```

### Multiple managers

```json
{
  "assignments": {
    "TW-12345": { "queue": "todo", "assignedAt": "2024-12-07T10:00:00Z" },
    "GH-acme/api#42": { "queue": "immediate", "assignedAt": "2024-12-07T11:00:00Z" },
    "LIN-ENG-123": { "queue": "backlog", "assignedAt": "2024-12-07T12:00:00Z" }
  }
}
```

---

*Created: 2024-12-07*
*Part of: Work System Phase 6 - Queue Management*
