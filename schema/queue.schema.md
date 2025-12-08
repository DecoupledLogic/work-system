# Queue Schema

A queue represents an urgency-based container for work items awaiting processing.

## Schema Definition

```yaml
Queue:
  # Identity
  id: string                    # Queue ID (e.g., "immediate", "urgent")
  name: string                  # Display name
  description: string | null    # Queue description

  # Configuration
  priority: number              # Sort order (lower = higher priority)
  sla: object | null            # Service level agreement
    responseTime: string        # ISO 8601 duration (e.g., "PT4H")
    resolutionTime: string      # ISO 8601 duration (e.g., "P1D")

  # Capacity
  maxItems: number | null       # Maximum items allowed (null = unlimited)
  warnThreshold: number | null  # Warn when items exceed this count

  # Routing
  defaultAssigneeId: string | null   # Default agent to assign
  escalationQueueId: string | null   # Queue to escalate to on SLA breach
  autoAssign: boolean           # Automatically assign from pool?

  # Filtering
  allowedTypes: string[] | null # Work item types allowed (null = all)
  allowedPriorities: string[] | null  # Priorities allowed (null = all)

  # Display
  color: string | null          # Display color (hex)
  icon: string | null           # Icon identifier

  # Tracking
  createdAt: datetime
  updatedAt: datetime

  # Metadata
  metadata: object
```

## Standard Queues

The work system defines four standard urgency queues:

| Queue | Priority | SLA Response | SLA Resolution | Use Case |
|-------|----------|--------------|----------------|----------|
| `immediate` | 1 | 15 min | 4 hours | Production down, security breach |
| `urgent` | 2 | 1 hour | 24 hours | High-impact customer issues |
| `standard` | 3 | 4 hours | 3-5 days | Normal priority work |
| `deferred` | 4 | None | None | Backlog, do when capacity allows |

## Examples

### Immediate Queue

```yaml
id: "immediate"
name: "Immediate"
description: "Critical issues requiring immediate attention"
priority: 1
sla:
  responseTime: "PT15M"
  resolutionTime: "PT4H"
maxItems: 5
warnThreshold: 3
defaultAssigneeId: null
escalationQueueId: null  # Cannot escalate further
autoAssign: false  # Manual assignment for critical items
allowedTypes: null  # Any type
allowedPriorities: ["critical"]
color: "#DC2626"
icon: "alert-triangle"
createdAt: "2024-01-01T00:00:00Z"
updatedAt: "2024-12-08T00:00:00Z"
metadata:
  notifications:
    slack: "#incidents"
    pagerduty: true
```

### Urgent Queue

```yaml
id: "urgent"
name: "Urgent"
description: "High-priority items requiring same-day attention"
priority: 2
sla:
  responseTime: "PT1H"
  resolutionTime: "P1D"
maxItems: 10
warnThreshold: 7
defaultAssigneeId: null
escalationQueueId: "immediate"
autoAssign: true
allowedTypes: null
allowedPriorities: ["critical", "high"]
color: "#F59E0B"
icon: "clock"
createdAt: "2024-01-01T00:00:00Z"
updatedAt: "2024-12-08T00:00:00Z"
metadata:
  notifications:
    slack: "#urgent"
```

### Standard Queue

```yaml
id: "standard"
name: "Standard"
description: "Normal priority work"
priority: 3
sla:
  responseTime: "PT4H"
  resolutionTime: "P5D"
maxItems: null  # Unlimited
warnThreshold: 50
defaultAssigneeId: null
escalationQueueId: "urgent"
autoAssign: true
allowedTypes: null
allowedPriorities: ["high", "medium", "low"]
color: "#3B82F6"
icon: "inbox"
createdAt: "2024-01-01T00:00:00Z"
updatedAt: "2024-12-08T00:00:00Z"
```

### Deferred Queue

```yaml
id: "deferred"
name: "Deferred"
description: "Low priority backlog items"
priority: 4
sla: null  # No SLA
maxItems: null
warnThreshold: 100
defaultAssigneeId: null
escalationQueueId: "standard"  # Can be promoted
autoAssign: false
allowedTypes: null
allowedPriorities: ["low"]
color: "#6B7280"
icon: "archive"
createdAt: "2024-01-01T00:00:00Z"
updatedAt: "2024-12-08T00:00:00Z"
```

## Queue Operations

### Routing Work Items

```yaml
# Route to queue
RouteToQueue:
  workItemId: string
  queueId: string
  reason: string | null
  routedBy: string          # Agent ID
  routedAt: datetime
```

### Queue Statistics

```yaml
QueueStats:
  queueId: string
  itemCount: number
  oldestItemAge: string     # ISO 8601 duration
  averageAge: string
  slaBreachCount: number
  itemsByPriority:
    critical: number
    high: number
    medium: number
    low: number
  itemsByType:
    epic: number
    feature: number
    story: number
    task: number
    bug: number
    spike: number
```

## SLA Breach Handling

When an item breaches its SLA:

1. **Warning** - 75% of SLA time elapsed
2. **Breach** - 100% of SLA time elapsed
3. **Escalation** - Item moved to `escalationQueueId` (if configured)

```yaml
SLAStatus:
  workItemId: string
  queueId: string
  responseDeadline: datetime | null
  resolutionDeadline: datetime | null
  responseStatus: enum      # on_track | warning | breached
  resolutionStatus: enum    # on_track | warning | breached
  escalatedAt: datetime | null
```

## Validation Rules

1. **Required fields**: `id`, `name`, `priority`
2. **Unique priority**: Each queue must have a unique priority number
3. **Valid escalation**: `escalationQueueId` must reference a valid queue with lower priority number
4. **SLA consistency**: `resolutionTime` must be greater than `responseTime`

## Relationships

```
Queue
├── WorkItem[] (items in queue via queue field)
├── Agent (default assignee via defaultAssigneeId)
└── Queue (escalation target via escalationQueueId)
```

## Related Schemas

- [work-item.schema.md](work-item.schema.md) - Items in queues
- [agent.schema.md](agent.schema.md) - Default assignees
