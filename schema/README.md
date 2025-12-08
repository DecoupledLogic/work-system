# Work System Schema

This directory contains the normalized domain schemas for the work system. These schemas define a consistent data model that abstracts work from any external system (Teamwork, GitHub, Linear, JIRA, etc.).

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Work System                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                   Domain Layer                            │   │
│  │  ┌──────────┐ ┌─────────┐ ┌───────┐ ┌─────────────────┐  │   │
│  │  │WorkItem  │ │ Project │ │ Agent │ │ProcessTemplate  │  │   │
│  │  └──────────┘ └─────────┘ └───────┘ └─────────────────┘  │   │
│  │  ┌──────────┐                                             │   │
│  │  │  Queue   │                                             │   │
│  │  └──────────┘                                             │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                   Adapter Layer                           │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐    │   │
│  │  │ Teamwork │ │  GitHub  │ │  Linear  │ │   JIRA   │    │   │
│  │  │ Adapter  │ │ Adapter  │ │ Adapter  │ │ Adapter  │    │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘    │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌──────────────┐     ┌──────────────┐      ┌──────────────┐
│   Teamwork   │     │    GitHub    │      │    Linear    │
│     API      │     │     API      │      │     API      │
└──────────────┘     └──────────────┘      └──────────────┘
```

## Core Schemas

| Schema | Description | File |
|--------|-------------|------|
| **WorkItem** | The fundamental unit of work | [work-item.schema.md](work-item.schema.md) |
| **Project** | Container for related work items | [project.schema.md](project.schema.md) |
| **Agent** | Entity that performs work (human, AI, automation) | [agent.schema.md](agent.schema.md) |
| **ProcessTemplate** | Workflow definition with stages | [process-template.schema.md](process-template.schema.md) |
| **Queue** | Urgency-based work container | [queue.schema.md](queue.schema.md) |
| **ExternalSystem** | Integration with third-party services | [external-system.schema.md](external-system.schema.md) |

## Work Item Hierarchy

```
epic
├── feature
│   ├── story
│   │   └── task
│   └── task
└── story
    └── task
```

## Key Design Principles

### 1. External System Agnostic

Work items, projects, and agents are normalized into a common schema. The external system is just metadata:

```yaml
# Instead of "Teamwork Task" or "GitHub Issue"
WorkItem:
  id: "WI-001"
  externalId: "26134585"      # Teamwork task ID
  externalSystem: "teamwork"  # Source system
  # ... normalized fields
```

### 2. Adapters Handle Translation

External systems connect via adapters that transform data:

```
Teamwork Task → Teamwork Adapter → WorkItem
GitHub Issue  → GitHub Adapter   → WorkItem
Linear Issue  → Linear Adapter   → WorkItem
```

### 3. Commands Operate on Domain Objects

Slash commands work with domain objects, not external APIs:

```bash
# Domain-level commands
/work-item get WI-001
/work-item update WI-001 --status in_progress
/work-item comment WI-001 "Starting implementation"

# Sync commands (when needed)
/sync teamwork --project PRJ-001
/sync github --repo company/app
```

### 4. Process Templates Define Flow

Work items follow process templates that define stages:

```yaml
Standard Template:
  triage → plan → design → deliver → eval

Bugfix Template:
  triage → deliver → eval

Spike Template:
  triage → plan → design → eval
```

## Status Flow

```
draft → triaged → planned → designed → in_progress → review → done
                                            ↓
                                         blocked
```

## Urgency Queues

| Queue | SLA | Use Case |
|-------|-----|----------|
| `immediate` | < 4 hours | Production down |
| `urgent` | < 24 hours | Customer impact |
| `standard` | 3-5 days | Normal work |
| `deferred` | Backlog | Low priority |

## Usage in Commands

### Reading Work Items

```bash
# Get by internal ID
/work-item get WI-001

# Get by external reference
/work-item get --external teamwork:26134585

# List with filters
/work-item list --status in_progress --assignee @cbryant
```

### Creating Work Items

```bash
# Create internally (no external system)
/work-item create --type task --name "Implement feature" --project PRJ-001

# Create and sync to external
/work-item create --type task --name "Fix bug" --sync teamwork
```

### Updating Work Items

```bash
# Update status
/work-item update WI-001 --status in_progress

# Update and sync
/work-item update WI-001 --status done --sync
```

### Comments

```bash
# Add comment (syncs to external if configured)
/work-item comment WI-001 "Implementation complete"
```

## Sync Operations

### Manual Sync

```bash
# Sync from external system
/sync teamwork --project 789456 --direction inbound

# Sync to external system
/sync github --work-items WI-001,WI-002 --direction outbound
```

### Automatic Sync

External systems can be configured for automatic sync via webhooks or polling:

```yaml
syncConfig:
  enabled: true
  interval: "PT5M"  # Poll every 5 minutes
  webhooks: true    # Also receive real-time updates
```

## Migration from MCP

Old approach (direct MCP calls):
```
mcp__Teamwork__twprojects-get_task(id: 26134585)
mcp__Teamwork__twprojects-create_comment(...)
```

New approach (domain commands):
```bash
/work-item get --external teamwork:26134585
/work-item comment WI-001 "Comment text"
```

The adapter layer handles the translation to/from Teamwork, GitHub, etc.

## File Structure

```
schema/
├── README.md                    # This file
├── work-item.schema.md          # Core work item schema
├── project.schema.md            # Project container schema
├── agent.schema.md              # Agent (user/AI) schema
├── process-template.schema.md   # Workflow template schema
├── queue.schema.md              # Urgency queue schema
└── external-system.schema.md    # External system adapter schema
```

## Related Documentation

- [Work System Overview](../docs/work-system.md) - System architecture
- [Commands](../commands/README.md) - Available slash commands
- [Agents](../agents/README.md) - Agent definitions
