# Work Item Schema

The normalized work item is the core domain object in the work system. It abstracts work from any external system (Teamwork, GitHub, Linear, JIRA) into a consistent structure.

## Schema Definition

```yaml
WorkItem:
  # Identity
  id: string                    # Internal work system ID (e.g., "WI-001")
  externalId: string | null     # ID in external system (e.g., "26134585")
  externalSystem: string | null # Source system (teamwork | github | linear | jira | internal)
  externalUrl: string | null    # Direct link to external system

  # Classification
  type: enum                    # epic | feature | story | task | bug | spike
  status: enum                  # draft | triaged | planned | designed | in_progress | review | done | blocked
  priority: enum                # critical | high | medium | low
  queue: enum                   # immediate | urgent | standard | deferred

  # Content
  name: string                  # Short title
  description: string | null    # Detailed description (markdown)
  acceptanceCriteria: string[]  # List of acceptance criteria

  # Hierarchy
  parentId: string | null       # Parent work item ID
  childIds: string[]            # Child work item IDs
  projectId: string | null      # Containing project ID

  # Assignment
  assigneeId: string | null     # Assigned agent ID
  reporterId: string | null     # Who created/reported it

  # Process
  templateId: string | null     # Process template ID
  stage: enum | null            # triage | plan | design | deliver | eval
  estimatedMinutes: number | null
  actualMinutes: number | null

  # Tracking
  tags: string[]                # Labels/tags
  createdAt: datetime
  updatedAt: datetime
  dueDate: date | null
  startDate: date | null

  # Metadata
  metadata: object              # Flexible key-value for system-specific data
```

## Type Hierarchy

```
epic
├── feature
│   ├── story
│   │   └── task
│   └── task
└── story
    └── task

bug (standalone or child of any level)
spike (standalone or child of any level)
```

### Type Definitions

| Type | Description | Typical Size | Contains |
|------|-------------|--------------|----------|
| `epic` | Large initiative spanning multiple features | Weeks-months | Features, stories |
| `feature` | Deliverable capability | Days-weeks | Stories, tasks |
| `story` | User-facing functionality | Hours-days | Tasks |
| `task` | Atomic unit of work | Minutes-hours | Nothing |
| `bug` | Defect to fix | Varies | Tasks (optional) |
| `spike` | Research/investigation | Hours-days | Tasks (optional) |

## Status Flow

```
draft → triaged → planned → designed → in_progress → review → done
                                            ↓
                                         blocked
```

| Status | Description |
|--------|-------------|
| `draft` | Newly created, not yet processed |
| `triaged` | Categorized and assigned to queue |
| `planned` | Broken down and estimated |
| `designed` | Solution designed, ready for implementation |
| `in_progress` | Actively being worked on |
| `review` | Work complete, awaiting review/approval |
| `done` | Completed and accepted |
| `blocked` | Cannot proceed (document reason in metadata) |

## Queue Assignment

| Queue | SLA | Description |
|-------|-----|-------------|
| `immediate` | < 4 hours | Production down, security breach |
| `urgent` | < 24 hours | High-impact customer issues |
| `standard` | 3-5 days | Normal priority work |
| `deferred` | Backlog | Low priority, do when capacity allows |

## Examples

### Task from Teamwork

```yaml
id: "WI-2024-001"
externalId: "26134585"
externalSystem: "teamwork"
externalUrl: "https://company.teamwork.com/app/tasks/26134585"
type: "task"
status: "in_progress"
priority: "high"
queue: "standard"
name: "Implement user authentication"
description: "Add OAuth2 authentication flow..."
acceptanceCriteria:
  - "User can log in with Google"
  - "User can log in with GitHub"
  - "Session persists across browser refresh"
parentId: "WI-2024-000"
projectId: "PRJ-001"
assigneeId: "AGT-001"
templateId: "TPL-standard"
stage: "deliver"
estimatedMinutes: 240
tags: ["auth", "security"]
createdAt: "2024-12-07T10:00:00Z"
updatedAt: "2024-12-08T14:30:00Z"
dueDate: "2024-12-15"
metadata:
  teamwork:
    tasklistId: "12345"
    tasklistName: "Sprint 42"
```

### Bug from GitHub Issue

```yaml
id: "WI-2024-042"
externalId: "123"
externalSystem: "github"
externalUrl: "https://github.com/org/repo/issues/123"
type: "bug"
status: "triaged"
priority: "critical"
queue: "immediate"
name: "Login fails on Safari"
description: "Users report 500 error when..."
acceptanceCriteria:
  - "Login works on Safari 17+"
  - "No console errors"
parentId: null
projectId: "PRJ-001"
assigneeId: null
templateId: "TPL-bugfix"
stage: "triage"
tags: ["bug", "safari", "auth"]
metadata:
  github:
    repo: "org/repo"
    labels: ["bug", "priority:critical"]
    milestone: "v2.1"
```

### Internal Work Item (No External System)

```yaml
id: "WI-2024-100"
externalId: null
externalSystem: "internal"
externalUrl: null
type: "spike"
status: "planned"
priority: "medium"
queue: "standard"
name: "Evaluate caching strategies"
description: "Research Redis vs Memcached..."
acceptanceCriteria:
  - "Document pros/cons of each approach"
  - "Recommendation with rationale"
parentId: "WI-2024-050"
projectId: "PRJ-001"
assigneeId: "AGT-002"
templateId: "TPL-spike"
stage: "plan"
estimatedMinutes: 120
tags: ["research", "performance"]
```

## Validation Rules

1. **Required fields**: `id`, `type`, `status`, `name`
2. **Type constraints**:
   - `epic` cannot have a parent of type `story` or `task`
   - `task` cannot have children
3. **Status transitions**: Must follow valid flow (see Status Flow)
4. **Queue assignment**: Only triaged items can have a queue
5. **Stage assignment**: Only items with a template can have a stage

## Related Schemas

- [project.schema.md](project.schema.md) - Project container
- [agent.schema.md](agent.schema.md) - Assignee/reporter
- [process-template.schema.md](process-template.schema.md) - Workflow template
- [queue.schema.md](queue.schema.md) - Queue definitions
