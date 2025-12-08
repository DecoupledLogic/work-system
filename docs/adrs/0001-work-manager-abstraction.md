# ADR-0001: Work Manager Abstraction Layer

## Status

Accepted

## Date

2024-12-07

## Context

The work system needs to track work items (tasks, issues, stories) across different projects. Different projects use different work management systems:

- **Teamwork**: Used for client projects and production support
- **GitHub Issues**: Used for open source and some internal projects
- **Linear**: Used by some teams for product development
- **Jira**: Used by enterprise clients
- **Local-only**: Some projects have no external tracking

Initially, the queue management commands (`/queue`, `/route`) were designed specifically for Teamwork, using Teamwork tags to track queue assignments. This approach had several problems:

1. **Not portable**: Commands wouldn't work with GitHub, Linear, or other systems
2. **Permission issues**: Teamwork tag creation/modification requires specific permissions
3. **API limitations**: Not all work managers support the same features (tags, custom fields, etc.)
4. **Tight coupling**: Business logic was intertwined with Teamwork-specific API calls

## Decision

Implement a **work manager abstraction layer** with the following components:

### 1. Common WorkItem Schema

All work items, regardless of source, are normalized to a common schema:

```typescript
interface WorkItem {
  id: string;              // Prefixed ID (TW-123, GH-owner/repo#45)
  externalId: string;      // Raw ID in external system
  manager: string;         // "teamwork" | "github" | "linear" | "jira" | "local"
  title: string;
  description: string;
  status: string;
  type: Type;
  workType: WorkType;
  urgency: Urgency;
  impact: Impact;
  queue: Queue;
  // ... other fields
}
```

### 2. Work Item ID Prefixes

Each manager uses a unique prefix for identification:

| Manager | Format | Example |
|---------|--------|---------|
| Teamwork | `TW-<id>` | `TW-12345` |
| GitHub | `GH-<owner>/<repo>#<number>` | `GH-acme/app#123` |
| Linear | `LIN-<identifier>` | `LIN-ENG-123` |
| Jira | `JIRA-<key>` | `JIRA-PROJ-456` |
| Local | `LOCAL-<uuid>` | `LOCAL-abc123` |

### 3. Local-First Queue Storage

Queue assignments are stored locally in `~/.claude/session/queues.json`, independent of external systems:

```json
{
  "assignments": {
    "TW-12345": { "queue": "todo", "assignedAt": "2024-12-07T10:00:00Z" },
    "GH-acme/api#42": { "queue": "immediate", "assignedAt": "2024-12-07T11:00:00Z" }
  },
  "history": [...]
}
```

### 4. Per-Project Configuration

Each project specifies its work manager in `.claude/work-manager.yaml`:

```yaml
manager: github
github:
  owner: acme
  repo: my-app
queues:
  storage: local
```

### 5. Optional External Sync

Queue changes can optionally sync to external systems via labels/tags:

```yaml
queues:
  storage: local
  sync:
    enabled: true
    mapping:
      immediate: "priority: critical"
      todo: "priority: high"
```

## Consequences

### Positive

- **Portability**: Same commands work across all work managers
- **No permissions required**: Local queue storage needs no external API access
- **Offline support**: Queue operations work without network
- **Full history**: All queue changes tracked locally with reasons
- **Flexibility**: Projects can use any work manager, or none
- **Gradual adoption**: Can add new manager adapters without changing commands

### Negative

- **Not shared**: Queue assignments visible only to local user, not team
- **Session-bound**: Queue data lost if session files cleared
- **Sync complexity**: Optional sync to external systems adds complexity
- **ID parsing**: Must handle different ID formats in commands

### Neutral

- **Two sources of truth**: External system has its own state; local queue is supplementary
- **Enrichment required**: Must fetch from external system to get full work item details

## Alternatives Considered

### 1. Teamwork Tags Only

Use Teamwork tags (`Queue:Immediate`, `Queue:Todo`, etc.) for queue tracking.

**Rejected because**: Not portable to other systems, requires tag permissions.

### 2. External System Native Features

Use each system's native priority/status fields for queue tracking.

**Rejected because**: Features vary significantly across systems; would require different logic per manager.

### 3. Centralized Queue Service

Build a separate service to track queues across all systems.

**Rejected because**: Over-engineering for current needs; adds infrastructure complexity.

## Related Decisions

- ADR-0002: Session State Management (pending)
- ADR-0003: Work Item Schema (pending)

## References

- `~/.claude/work-managers/README.md` - Implementation documentation
- `~/.claude/work-managers/queue-store.md` - Queue storage specification
- `~/.claude/work-managers/work-manager.schema.yaml` - Configuration schema
