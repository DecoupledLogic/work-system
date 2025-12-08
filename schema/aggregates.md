# Domain Aggregates

Slash commands serve as the interface to domain aggregates. Each aggregate encapsulates business logic and maintains consistency boundaries.

## Command Pattern

```
/<aggregate> <action> [id] [--options]
```

## Aggregates

### WorkItem Aggregate

The **WorkItem** is the primary aggregate root, containing:
- Comments (entity)
- Time logs (entity)
- Attachments (entity)
- History (value object)

```bash
# Queries
/work-item get <id>                    # Get by internal ID
/work-item get --external tw:26134585  # Get by external reference
/work-item list [--filters]            # List with filters
/work-item history <id>                # View change history

# Commands - Lifecycle
/work-item create --type <type> --name "..." [--project <id>] [--parent <id>]
/work-item update <id> [--name "..."] [--description "..."] [--priority <p>]
/work-item delete <id>                 # Soft delete

# Commands - Assignment
/work-item assign <id> <agent>         # Assign to agent
/work-item unassign <id>               # Remove assignment

# Commands - Workflow
/work-item transition <id> <stage>     # Move to stage (triage|plan|design|deliver|eval)
/work-item route <id> <queue> [reason] # Route to queue (immediate|urgent|standard|deferred)
/work-item block <id> [reason]         # Mark as blocked
/work-item unblock <id>                # Remove block

# Commands - Collaboration
/work-item comment <id> "message"      # Add comment
/work-item log-time <id> <duration> [description]  # Log time (e.g., "2h30m")

# Commands - Hierarchy
/work-item add-child <id> --type <type> --name "..."  # Create child
/work-item move <id> --parent <new-parent-id>         # Reparent

# Commands - Sync
/work-item sync <id>                   # Sync with external system
/work-item link <id> --external <system>:<external-id>  # Link to external
```

**Aggregate Invariants:**
- Tasks cannot have children
- Status transitions must follow valid flow
- Only triaged items can be routed to queues
- Blocked items cannot transition stages

---

### Project Aggregate

The **Project** aggregate contains:
- Work items (reference)
- Team members (reference)
- Configuration (value object)

```bash
# Queries
/project get <id>
/project list [--status active|archived|on_hold]
/project stats <id>                    # Work item counts, velocity

# Commands
/project create --name "..." [--template <id>] [--repo <url>]
/project update <id> [--name "..."] [--status <status>]
/project archive <id>
/project activate <id>

# Team Management
/project add-member <id> <agent-id> [--role <role>]
/project remove-member <id> <agent-id>

# Sync
/project sync <id>                     # Sync all work items
/project link <id> --external <system>:<external-id>
```

---

### Agent Aggregate

The **Agent** aggregate represents workers:

```bash
# Queries
/agent get <id>
/agent list [--type human|ai|automation] [--available]
/agent workload <id>                   # Current assignments

# Commands
/agent create --type <type> --name "..." [--email "..."]
/agent update <id> [--status active|away|offline]
/agent set-capacity <id> <max-items>

# For current agent (self)
/agent status [--away|--active|--offline]
/agent my-work                         # List my assignments
```

---

### Queue Aggregate

The **Queue** aggregate manages urgency:

```bash
# Queries
/queue list                            # All queues with counts
/queue show <id>                       # Items in queue
/queue stats [<id>]                    # SLA metrics

# Commands (admin)
/queue create --name "..." --priority <n> --sla <duration>
/queue update <id> [--sla <duration>]

# Operations happen through work-item
# /work-item route <id> <queue> [reason]
```

---

### ProcessTemplate Aggregate

The **ProcessTemplate** defines workflows:

```bash
# Queries
/template get <id>
/template list [--category standard|bugfix|spike|hotfix]

# Commands (admin)
/template create --name "..." --category <cat> --stages [...]
/template update <id> [--stages [...]]
```

---

## Aggregate Functions

Each aggregate exposes domain functions that enforce business rules:

### WorkItem Functions

```yaml
WorkItemAggregate:
  # Lifecycle
  create(props): WorkItem
  update(id, changes): WorkItem
  delete(id): void

  # Assignment
  assign(id, agentId): WorkItem
  unassign(id): WorkItem

  # Workflow
  transition(id, stage): WorkItem
    # Validates: stage is allowed from current stage
    # Validates: entry conditions met
    # Triggers: stage hooks

  route(id, queue, reason?): WorkItem
    # Validates: item is triaged
    # Validates: queue accepts item type/priority
    # Records: routing history

  block(id, reason?): WorkItem
  unblock(id): WorkItem

  # Collaboration
  addComment(id, body): Comment
    # Syncs: to external system if configured

  logTime(id, duration, description?): TimeLog
    # Validates: duration > 0
    # Syncs: to external system if configured

  # Hierarchy
  addChild(id, props): WorkItem
    # Validates: parent can have children (not a task)
    # Inherits: project, template from parent

  move(id, newParentId): WorkItem
    # Validates: no circular references
    # Updates: project if parent's project differs
```

### Validation & Business Rules

```yaml
# Status transition rules
statusTransitions:
  draft: [triaged]
  triaged: [planned, blocked]
  planned: [designed, in_progress, blocked]
  designed: [in_progress, blocked]
  in_progress: [review, blocked]
  review: [done, in_progress, blocked]
  blocked: [triaged, planned, designed, in_progress, review]
  done: []  # Terminal state

# Stage transition rules (per template)
stageTransitions:
  triage: [plan, deliver]
  plan: [design, deliver]
  design: [deliver]
  deliver: [eval]
  eval: []  # Terminal stage

# Type hierarchy rules
typeHierarchy:
  epic: [feature, story]      # Can contain
  feature: [story, task]
  story: [task]
  task: []                    # Leaf node
  bug: [task]                 # Optional subtasks
  spike: [task]               # Optional subtasks
```

---

## Command Response Pattern

All aggregate commands return consistent responses:

```yaml
# Success
{
  success: true
  aggregate: "work-item"
  action: "transition"
  id: "WI-001"
  result: { ... }  # Updated aggregate state
  synced: ["teamwork"]  # External systems synced
}

# Validation Error
{
  success: false
  aggregate: "work-item"
  action: "transition"
  id: "WI-001"
  error: "INVALID_TRANSITION"
  message: "Cannot transition from 'draft' to 'deliver'"
  allowed: ["triaged"]
}

# Not Found
{
  success: false
  aggregate: "work-item"
  action: "get"
  id: "WI-999"
  error: "NOT_FOUND"
  message: "Work item WI-999 not found"
}
```

---

## Event Sourcing (Optional)

Aggregates can emit domain events for audit and integration:

```yaml
WorkItemCreated:
  workItemId: "WI-001"
  type: "task"
  name: "Implement feature"
  createdBy: "AGT-001"
  timestamp: "2024-12-08T15:00:00Z"

WorkItemTransitioned:
  workItemId: "WI-001"
  fromStage: "plan"
  toStage: "deliver"
  triggeredBy: "AGT-001"
  timestamp: "2024-12-08T16:00:00Z"

WorkItemRouted:
  workItemId: "WI-001"
  fromQueue: "standard"
  toQueue: "urgent"
  reason: "Customer escalation"
  routedBy: "AGT-001"
  timestamp: "2024-12-08T16:30:00Z"

CommentAdded:
  workItemId: "WI-001"
  commentId: "CMT-001"
  body: "Starting implementation"
  author: "AGT-001"
  syncedTo: ["teamwork"]
  timestamp: "2024-12-08T17:00:00Z"
```

---

## Integration with External Systems

Aggregates interact with external systems through adapters:

```
┌─────────────────────────────────────────────────────────────┐
│                     Slash Command                           │
│              /work-item comment WI-001 "msg"                │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                  WorkItem Aggregate                         │
│  addComment(id, body)                                       │
│    1. Validate work item exists                             │
│    2. Create comment entity                                 │
│    3. Trigger sync to external systems                      │
└─────────────────────────┬───────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
┌─────────────────┐ ┌──────────────┐ ┌──────────────┐
│Teamwork Adapter │ │GitHub Adapter│ │Linear Adapter│
│ createComment() │ │createComment│ │createComment │
└─────────────────┘ └──────────────┘ └──────────────┘
```

The aggregate doesn't know about specific systems - it calls the adapter interface, and the configured adapter handles translation.

---

## Summary

| Aggregate | Root Entity | Contains | Key Actions |
|-----------|-------------|----------|-------------|
| WorkItem | WorkItem | Comments, TimeLogs, History | transition, route, comment, log-time |
| Project | Project | WorkItems (ref), Members (ref) | add-member, sync |
| Agent | Agent | Assignments (ref) | set-capacity, status |
| Queue | Queue | WorkItems (ref) | (managed via work-item route) |
| ProcessTemplate | Template | Stages, Hooks | (admin only) |
