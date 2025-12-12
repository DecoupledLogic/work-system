# Domain Commands

Natural language interface to aggregate operations for work items, projects, agents, and queues.

## Commands

| Command | Description |
|---------|-------------|
| `/domain:work-item` | Create, manage, and track work items |
| `/domain:project` | Organize work into projects |
| `/domain:agent` | Manage humans, AI, and automation |
| `/domain:queue` | View urgency queues and SLA status |

## Command Syntax

```bash
/<aggregate> <action> [id] [--options]
```

## Quick Examples

```bash
# Work items
/domain:work-item get WI-001
/domain:work-item list --queue urgent --assignee @me
/domain:work-item create --name "Fix bug" --type bug
/domain:work-item transition WI-001 deliver
/domain:work-item route WI-001 urgent "Customer escalation"
/domain:work-item comment WI-001 "Starting work"
/domain:work-item log-time WI-001 2h "coding"

# Projects
/domain:project get PRJ-001
/domain:project list --active
/domain:project stats PRJ-001

# Agents
/domain:agent my-work
/domain:agent workload @cbryant

# Queues
/domain:queue list
/domain:queue show urgent
```

## Integration

Workflow commands (`/workflow:*`) use domain commands internally. Domain commands abstract external systems (Teamwork, GitHub, Linear, JIRA).

See source commands in [commands/domain/](../../../commands/domain/) for full documentation.
