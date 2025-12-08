# Domain Commands

Domain commands provide a natural language interface to aggregate operations. Each aggregate encapsulates business logic and maintains consistency for its entity cluster.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        User / Agent                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Domain Commands (DSL)                        │
│  /work-item  /project  /agent  /queue                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Aggregate Functions                          │
│  create, update, transition, route, assign, comment...         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Domain Schemas                               │
│  WorkItem, Project, Agent, Queue, ProcessTemplate              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    External Adapters                            │
│  Teamwork, GitHub, Linear, JIRA, Internal                      │
└─────────────────────────────────────────────────────────────────┘
```

## Available Aggregates

| Command | Aggregate | Description |
|---------|-----------|-------------|
| `/work-item` | WorkItem | Create, manage, and track units of work |
| `/project` | Project | Organize work into projects with teams |
| `/agent` | Agent | Manage humans, AI, and automation |
| `/queue` | Queue | View urgency queues and SLA status |

## Command Syntax

All domain commands follow a consistent pattern:

```
/<aggregate> <action> [id] [--options]
```

### Examples

```bash
# Work Items
/work-item get WI-001
/work-item list --queue urgent --assignee @cbryant
/work-item create --name "Fix login bug" --type bug --priority high
/work-item transition WI-001 deliver
/work-item route WI-001 urgent "Customer escalation"
/work-item assign WI-001 @claude
/work-item comment WI-001 "Starting implementation"
/work-item log-time WI-001 2h "Completed OAuth flow"

# Projects
/project get PRJ-001
/project list --active
/project stats PRJ-001
/project add-member PRJ-001 @jane

# Agents
/agent get @cbryant
/agent list --available
/agent workload @cbryant
/agent my-work

# Queues
/queue list
/queue show urgent
/queue stats
```

## Natural Language Interface

These commands read like natural English:

```bash
# "Show me work item 42"
/work-item get WI-042

# "List urgent items assigned to me"
/work-item list --queue urgent --assignee @me

# "Move this to the deliver stage"
/work-item transition WI-042 deliver

# "Route to urgent queue because customer escalated"
/work-item route WI-042 urgent "Customer escalation"

# "Assign this to Claude"
/work-item assign WI-042 @claude

# "Add a comment saying we're starting work"
/work-item comment WI-042 "Starting implementation"

# "Log 2 hours for coding work"
/work-item log-time WI-042 2h "Implementation complete"
```

## Integration with Workflow Commands

Workflow commands (`/triage`, `/plan`, `/design`, `/deliver`, `/route`) use domain commands internally:

```
/triage WI-001
  └─▶ /work-item get WI-001
  └─▶ /work-item update WI-001 --type bug --priority high
  └─▶ /work-item route WI-001 urgent "Production issue"
  └─▶ /work-item transition WI-001 plan

/deliver WI-001
  └─▶ /work-item get WI-001
  └─▶ /work-item transition WI-001 deliver
  └─▶ /work-item assign WI-001 @claude
  └─▶ /work-item comment WI-001 "Implementation started"
  └─▶ /work-item log-time WI-001 45m "coding"
```

## External System Sync

Domain commands abstract external systems. The adapter layer handles translation:

```bash
# This syncs to Teamwork, GitHub, or Linear based on project config
/work-item sync WI-001

# This links to any external system
/work-item link WI-001 github "company/repo#123"
/work-item link WI-001 teamwork "789456"
```

## File Index

| File | Description |
|------|-------------|
| [work-item.md](work-item.md) | Work item aggregate commands |
| [project.md](project.md) | Project aggregate commands |
| [agent.md](agent.md) | Agent aggregate commands |
| [queue.md](queue.md) | Queue aggregate commands |

## Related Documentation

- [Schema Directory](../../schema/) - Domain object schemas
- [Aggregates Guide](../../schema/aggregates.md) - Aggregate design patterns
- [Workflow Commands](../) - Higher-level workflow orchestration
