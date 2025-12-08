# Work Manager Abstraction

This directory contains the abstraction layer for different work/issue tracking systems.

## Overview

The work system is designed to be **backend-agnostic**. Work items can come from:
- Teamwork (projects, tasks)
- GitHub Issues
- Linear
- Jira
- Local-only (no external system)

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Work System Commands               │
│         /triage  /plan  /design  /deliver           │
│              /queue  /route  /select-task           │
└─────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│              Work Manager Interface                 │
│                                                     │
│  Operations:                                        │
│  - fetchTask(id) → WorkItem                        │
│  - listTasks(filter) → WorkItem[]                  │
│  - updateTask(id, changes) → WorkItem              │
│  - createTask(data) → WorkItem                     │
│  - addComment(taskId, comment) → Comment           │
│  - getQueue(queue) → WorkItem[]                    │
│  - setQueue(taskId, queue) → void                  │
└─────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  Teamwork   │   │   GitHub    │   │   Linear    │
│   Adapter   │   │   Adapter   │   │   Adapter   │
└─────────────┘   └─────────────┘   └─────────────┘
```

## Configuration

Work manager is configured per-project in `.claude/work-manager.yaml`:

```yaml
# .claude/work-manager.yaml
manager: teamwork  # or: github, linear, jira, local

teamwork:
  projectId: 123456
  tasklistId: 789012  # optional default

github:
  owner: myorg
  repo: myrepo

linear:
  teamId: TEAM-123

# Queue tracking (applies to all managers)
queues:
  storage: local  # local | native
  # native: use manager's labels/tags/fields
  # local: track in ~/.claude/session/queues.json
```

## Work Item Schema

All adapters normalize to the common WorkItem schema:

```typescript
interface WorkItem {
  // Identity
  id: string;              // Unique ID (e.g., "TW-12345", "GH-123", "LIN-ABC")
  externalId: string;      // Raw ID in external system
  manager: string;         // "teamwork" | "github" | "linear" | "local"
  url?: string;            // Link to item in external system

  // Core fields
  title: string;
  description: string;
  status: string;          // Normalized: open, in_progress, done, cancelled

  // Work system fields
  type: Type;              // epic, feature, story, task, bug, support
  workType: WorkType;      // product, support, delivery
  urgency: Urgency;        // critical, now, next, future
  impact: Impact;          // high, medium, low
  queue: Queue;            // immediate, todo, backlog, icebox

  // Hierarchy
  parentId?: string;
  childIds?: string[];

  // Metadata
  createdAt: string;
  updatedAt: string;
  assignee?: string;
  labels?: string[];

  // Work system state
  stage?: Stage;           // triage, plan, design, deliver
  templateId?: string;
}
```

## Adapters

### Teamwork Adapter

Maps Teamwork tasks to WorkItem schema:

| Teamwork Field | WorkItem Field |
|----------------|----------------|
| `id` | `externalId` |
| `name` | `title` |
| `description` | `description` |
| `status` | `status` (mapped) |
| `parentTaskId` | `parentId` |
| `subTasks` | `childIds` |
| `tags` | `labels` |

### GitHub Adapter

Maps GitHub Issues to WorkItem schema:

| GitHub Field | WorkItem Field |
|--------------|----------------|
| `number` | `externalId` |
| `title` | `title` |
| `body` | `description` |
| `state` | `status` (open/closed) |
| `labels` | `labels`, `type`, `urgency` |
| `milestone` | `parentId` (if epic) |

### Linear Adapter

Maps Linear Issues to WorkItem schema:

| Linear Field | WorkItem Field |
|--------------|----------------|
| `identifier` | `externalId` |
| `title` | `title` |
| `description` | `description` |
| `state.name` | `status` |
| `parent` | `parentId` |
| `children` | `childIds` |
| `labels` | `labels`, `type` |
| `priority` | `urgency` |

### Local Adapter

For projects without external tracking:

- Work items stored in `~/.claude/session/local-work-items.json`
- Full WorkItem schema supported
- No sync to external system

## Queue Storage

Queues can be stored in two ways:

### Local Storage (Default)

Queue assignments stored in `~/.claude/session/queues.json`:

```json
{
  "assignments": {
    "TW-12345": { "queue": "todo", "assignedAt": "2024-12-07T10:30:00Z" },
    "GH-123": { "queue": "backlog", "assignedAt": "2024-12-07T11:00:00Z" }
  },
  "history": [
    { "id": "TW-12345", "from": "backlog", "to": "todo", "at": "2024-12-07T10:30:00Z", "reason": "Prioritized for sprint" }
  ]
}
```

Benefits:
- Works with any manager
- No API/permission requirements
- Fast local access
- Full history tracking

Limitations:
- Not visible in external system
- Not shared with team members
- Lost if session cleared

### Native Storage (Optional)

Some managers support native queue tracking:

| Manager | Native Queue Support |
|---------|---------------------|
| Teamwork | Tags or custom fields |
| GitHub | Labels |
| Linear | Status/Priority |
| Jira | Status or custom field |

Enable with:
```yaml
queues:
  storage: native
  mapping:
    immediate: "Priority: Critical"  # Label name
    todo: "Priority: High"
    backlog: "Priority: Medium"
    icebox: "Priority: Low"
```

## Adding a New Adapter

1. Create adapter file: `~/.claude/work-managers/adapters/<name>.md`
2. Define field mappings
3. Implement operations (fetch, list, update, create, comment)
4. Add to configuration schema
5. Test with existing commands

## Usage in Commands

Commands access work items through the abstraction:

```markdown
## In /triage command:

1. Detect manager from project config
2. Call appropriate adapter to fetch task
3. Process using common WorkItem schema
4. Update via adapter
5. Track queue locally (or native if configured)
```

---

*Created: 2024-12-07*
*Part of: Work System Phase 6 - Queue Management*
