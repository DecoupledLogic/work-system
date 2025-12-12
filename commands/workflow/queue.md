---
name: queue
description: Display work items by urgency queue. Shows queue contents sorted by priority with age and status.
---

# Queue Command

Display work items organized by urgency queue.

## Usage

```
/queue                    # Show all queues summary
/queue immediate          # Show only Immediate queue
/queue todo               # Show only Todo queue
/queue backlog            # Show only Backlog queue
/queue icebox             # Show only Icebox queue
/queue --manager <name>   # Filter by work manager (teamwork, github, linear)
```

## Queues

The work system uses four urgency-based queues:

| Queue | Urgency | Description | SLA |
|-------|---------|-------------|-----|
| **Immediate** | critical | Drop everything | Same day |
| **Todo** | now | Current cycle | This cycle |
| **Backlog** | next | Planned work | Next cycle |
| **Icebox** | future | Not yet scheduled | No SLA |

## Architecture

Queue assignments are stored **locally** in `~/.claude/session/queues.json`, independent of any external work manager. This allows:

- Consistent queue tracking across different managers (Teamwork, GitHub, Linear)
- No API/permission requirements for queue operations
- Full history of queue changes
- Works even when external system unavailable

```
┌─────────────────────────────────────────┐
│            /queue command               │
└─────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
┌───────────────┐      ┌───────────────┐
│ Queue Store   │      │ Work Manager  │
│ (local JSON)  │      │  (external)   │
│               │      │               │
│ - assignments │      │ - Teamwork    │
│ - history     │      │ - GitHub      │
└───────────────┘      │ - Linear      │
                       │ - Local       │
                       └───────────────┘
```

## Implementation

### Step 1: Parse Arguments

Determine which queue(s) to display:
- No args: Show summary of all queues
- Queue name: Show detailed view of that queue
- `--manager`: Filter to specific work manager

### Step 2: Load Queue Data

Read local queue assignments from `~/.claude/session/queues.json`:

```json
{
  "assignments": {
    "TW-12345": { "queue": "todo", "assignedAt": "2024-12-07T10:00:00Z" },
    "GH-acme/api#42": { "queue": "immediate", "assignedAt": "2024-12-07T11:00:00Z" }
  }
}
```

### Step 3: Enrich with Work Item Details

For each queued item, fetch details from the appropriate work manager:

**Teamwork items (TW-*):**
```
mcp__Teamwork__twprojects-get_task(id: <task_id>)
```

**GitHub items (GH-*):**
```
Use GitHub CLI or API to fetch issue details
```

**Linear items (LIN-*):**
```
Use Linear API to fetch issue details
```

### Step 4: Calculate Metrics

For each work item in the queue, calculate:
- **Age:** Days since added to queue (from assignedAt)
- **Priority Score:** Based on impact + urgency + age
- **Status:** Current workflow status (from external manager)
- **Blocked:** Whether item has blocking dependencies

### Step 5: Display Queue View

#### Summary View (no args)

```
📋 Work Queues

🔴 IMMEDIATE (2 items)
   TW-12345   Critical bug in checkout
   GH-acme/api#42   Production API failure

🟠 TODO (5 items)
   TW-12340   Add payment retry logic
   TW-12342   Update user dashboard
   LIN-ENG-45   Refactor auth module
   ...

🟡 BACKLOG (12 items)
   (use /queue backlog for details)

⚪ ICEBOX (28 items)
   (use /queue icebox for details)

Total: 47 items across 4 queues
```

#### Detailed View (queue name)

```
📋 TODO Queue (5 items)

Pri │ ID                  │ Title                    │ Age │ Status
────┼─────────────────────┼──────────────────────────┼─────┼────────────
 1  │ TW-12348            │ Fix login timeout        │ 3d  │ in_progress
 2  │ GH-acme/api#55      │ Add retry logic          │ 5d  │ open
 3  │ TW-12342            │ Update user dashboard    │ 2d  │ planned
 4  │ LIN-ENG-45          │ Refactor auth module     │ 1d  │ in_progress
 5  │ TW-12360            │ Add logging middleware   │ 1d  │ triaged

Legend: 🔴 Blocked  ⏳ Aging (>7d)  ✅ Ready

Actions:
  /route TW-12360 backlog    # Move to Backlog
  /triage TW-12355           # Review triage
  /plan TW-12342             # Continue planning
```

### Step 6: Identify Issues

Flag items that need attention:
- **Blocked:** Has unmet dependencies
- **Aging:** In queue longer than SLA
- **Stale:** No activity in 7+ days
- **Ready:** Can be started immediately

## Work Item ID Formats

Items from different managers use prefixed IDs:

| Manager | Format | Example |
|---------|--------|---------|
| Teamwork | `TW-<id>` | `TW-12345` |
| GitHub | `GH-<owner>/<repo>#<number>` | `GH-acme/app#123` |
| Linear | `LIN-<identifier>` | `LIN-ENG-123` |
| Jira | `JIRA-<key>` | `JIRA-PROJ-456` |
| Local | `LOCAL-<uuid>` | `LOCAL-abc123` |

## Priority Scoring

Items are sorted by priority score:

```
score = (impact_weight * impact) +
        (urgency_weight * urgency) +
        (age_weight * age_factor)

Where:
- impact: high=3, medium=2, low=1
- urgency: critical=4, now=3, next=2, future=1
- age_factor: min(days_in_queue / 7, 2)  # caps at 2x

Weights:
- impact_weight = 0.4
- urgency_weight = 0.4
- age_weight = 0.2
```

## Examples

### Show all queues

```
> /queue

📋 Work Queues

🔴 IMMEDIATE: 0 items
🟠 TODO: 3 items
🟡 BACKLOG: 8 items
⚪ ICEBOX: 15 items

Total: 26 items across 4 queues
```

### Show specific queue

```
> /queue todo

📋 TODO Queue (3 items)

1. TW-12345 - Fix login timeout (3d, in_progress)
2. GH-acme/api#55 - Add payment retry (5d, open)
3. TW-12342 - Update dashboard (2d, planned)

⏳ 1 item aging (>7 days expected for Todo)
```

### Filter by manager

```
> /queue todo --manager github

📋 TODO Queue - GitHub only (1 item)

1. GH-acme/api#55 - Add payment retry (5d, open)
```

## Error Handling

- **No queue data:** Show empty state with onboarding message
- **Manager unavailable:** Show cached data with warning
- **Empty queue:** Show empty state with suggestions

## Integration

### With Session State

Update `~/.claude/session/active-work.md` when viewing queues to track what was reviewed.

### With Logging

Log queue views for analytics:
```
log_action(action: "view_queue", description: "Viewed Todo queue", metadata: {queue: "todo", count: 5})
```

### With /select-task

The `/select-task` command uses queue data to present work selection. `/queue` provides the underlying visibility.

### With /route

Use `/route` to move items between queues. Changes are tracked in queue history.

---

*Created: 2024-12-07*
*Updated: 2024-12-07 - Changed to local queue storage with work manager abstraction*
*Part of: Work System Phase 6 - Queue Management*
