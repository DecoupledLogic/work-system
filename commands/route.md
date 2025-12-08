---
name: route
description: Move work items between urgency queues. Updates local queue store with history tracking.
---

# Route Command

Move work items between urgency queues.

## Usage

```
/route <work-item-id> <target-queue>
/route TW-12345 backlog
/route GH-acme/api#42 immediate --reason "Customer escalation"
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `work-item-id` | Yes | Work item ID with manager prefix (e.g., TW-12345, GH-owner/repo#123) |
| `target-queue` | Yes | Target queue: `immediate`, `todo`, `backlog`, `icebox` |
| `--reason` | No | Reason for routing (stored in history) |

## Target Queues

| Queue | When to Route Here |
|-------|-------------------|
| `immediate` | Critical issues, customer escalations, production problems |
| `todo` | Ready for current cycle, next up for work |
| `backlog` | Planned but not yet prioritized for this cycle |
| `icebox` | Deprioritized, may revisit later |

## Architecture

Queue assignments are stored **locally** in `~/.claude/session/queues.json`:

```
┌─────────────────────────────────────────┐
│            /route command               │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│         Queue Store (local)             │
│   ~/.claude/session/queues.json         │
│                                         │
│   - Update assignments                  │
│   - Append to history                   │
│   - Track reason                        │
└─────────────────────────────────────────┘
                    │
                    ▼ (optional)
┌─────────────────────────────────────────┐
│        Add Comment to External          │
│   (if routing to/from Immediate)        │
└─────────────────────────────────────────┘
```

## Implementation

### Step 1: Parse Arguments

Extract work item ID and target queue from command arguments.

Validate:
- Work item ID matches known format (TW-*, GH-*, LIN-*, JIRA-*, LOCAL-*)
- Target queue is one of: immediate, todo, backlog, icebox

### Step 2: Read Current Queue State

Load `~/.claude/session/queues.json`:

```json
{
  "assignments": {
    "TW-12345": { "queue": "todo", "assignedAt": "2024-12-06T10:00:00Z" }
  },
  "history": []
}
```

### Step 3: Update Queue Assignment

Update the assignments and append to history:

```json
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

### Step 4: Optional External Comment

If routing to/from Immediate, add a comment to the external system for audit trail:

**Teamwork:**

```
mcp__Teamwork__twprojects-create_comment(
  object: { type: "tasks", id: <task_id> },
  body: "Routed to {queue}: {reason}",
  content_type: "TEXT"
)
```

**GitHub:**

```bash
/gh-issue-comment <number> "Routed to {queue}: {reason}"
```

### Step 5: Log the Action

Log the routing for session analytics:

```
log_action(
  action: "route",
  description: "Moved to {queue} queue",
  metadata: {
    workItemId: "TW-12345",
    fromQueue: "todo",
    toQueue: "backlog",
    reason: "Waiting on design"
  }
)
```

### Step 6: Display Confirmation

Show the routing result:

```
✅ Routed TW-12345 to Backlog

Work Item: Fix login timeout issue
From: Todo → To: Backlog
Reason: Waiting on design

Queue updated locally.

Next actions:
  /queue backlog           # View Backlog queue
  /route TW-12345 todo     # Move back to Todo
```

## Work Item ID Formats

| Manager | Format | Example |
|---------|--------|---------|
| Teamwork | `TW-<id>` | `TW-12345` |
| GitHub | `GH-<owner>/<repo>#<number>` | `GH-acme/app#123` |
| Linear | `LIN-<identifier>` | `LIN-ENG-123` |
| Jira | `JIRA-<key>` | `JIRA-PROJ-456` |
| Local | `LOCAL-<uuid>` | `LOCAL-abc123` |

## Examples

### Basic routing

```
> /route TW-12345 backlog

✅ Routed TW-12345 to Backlog

Work Item: Fix login timeout issue
From: Todo → To: Backlog

Queue updated locally.
```

### Routing with reason

```
> /route GH-acme/api#42 immediate --reason "Customer escalation from Acme Corp"

✅ Routed GH-acme/api#42 to Immediate

Work Item: API timeout on large requests
From: Backlog → To: Immediate
Reason: Customer escalation from Acme Corp

Queue updated locally.
Comment added to GitHub issue.
```

### Routing to icebox

```
> /route LIN-ENG-123 icebox --reason "Waiting on upstream dependency"

✅ Routed LIN-ENG-123 to Icebox

Work Item: Add new payment provider
From: Backlog → To: Icebox
Reason: Waiting on upstream dependency

Queue updated locally.

⚠️ Note: Icebox items have no SLA. Use /route to move back when ready.
```

### First-time routing (new item)

```
> /route TW-99999 todo

✅ Routed TW-99999 to Todo

Work Item: New feature request
From: (none) → To: Todo

Queue updated locally.

💡 Tip: Run /triage TW-99999 to properly categorize this item.
```

## Validation Rules

### Queue Transitions

All transitions are allowed - the system trusts your judgment:

| From | To | Notes |
|------|----|-------|
| Any | immediate | Escalation |
| immediate | Any | De-escalation |
| todo | backlog/icebox | Deprioritization |
| backlog | todo | Prioritization |
| icebox | Any | Reactivation |
| (none) | Any | First assignment |

### Warnings

Show warnings for potentially problematic routes:

- **Immediate → Icebox:** "⚠️ Moving critical item to Icebox. Include a reason."
- **Item not found in manager:** "⚠️ Could not verify item exists. Routing anyway."

## Error Handling

### Invalid Work Item ID

```
❌ Invalid work item ID format: "12345"

Expected formats:
  TW-12345            (Teamwork)
  GH-owner/repo#123   (GitHub)
  LIN-ABC-123         (Linear)
  JIRA-PROJ-456       (Jira)
  LOCAL-uuid          (Local)
```

### Invalid Queue

```
❌ Invalid queue: "urgent"

Valid queues:
  immediate  (critical, same-day SLA)
  todo       (current cycle)
  backlog    (next cycle)
  icebox     (not scheduled)
```

### Queue File Error

```
❌ Could not update queue store

Check: ~/.claude/session/queues.json exists and is writable
```

## Batch Routing

For routing multiple items, use repeated commands:

```
> /route TW-12345 backlog
> /route TW-12346 backlog
> /route TW-12347 backlog
```

Or describe the batch operation:
```
> Route TW-12345, TW-12346, and TW-12347 to backlog

I'll route each item:
- TW-12345 → Backlog ✅
- TW-12346 → Backlog ✅
- TW-12347 → Backlog ✅

All 3 items moved to Backlog queue.
```

## Queue History

All routing changes are tracked in history:

```json
{
  "history": [
    { "id": "TW-12345", "from": null, "to": "todo", "at": "2024-12-06T10:00:00Z" },
    { "id": "TW-12345", "from": "todo", "to": "immediate", "at": "2024-12-07T09:00:00Z", "reason": "Customer escalation" },
    { "id": "TW-12345", "from": "immediate", "to": "backlog", "at": "2024-12-07T15:00:00Z", "reason": "Resolved" }
  ]
}
```

This enables analytics like:
- Average time in each queue
- Escalation frequency
- Queue throughput

## Integration

### With /queue

After routing, `/queue` reflects the change:

```
> /route TW-12345 backlog
✅ Routed TW-12345 to Backlog

> /queue backlog
📋 Backlog Queue (9 items)
...
9. TW-12345 - Fix login timeout (0d)  ← newly added
```

### With /triage

Triage automatically routes based on urgency:
- Triage sets initial queue based on detected urgency
- `/route` allows manual override

### With Session Logging

All routes logged for analytics:
```
log_action(action: "route", ...)
```

---

*Created: 2024-12-07*
*Updated: 2024-12-07 - Changed to local queue storage, removed Teamwork tag dependency*
*Part of: Work System Phase 6 - Queue Management*
