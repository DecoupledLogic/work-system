# ADR-0002: Local-First Session State

## Status

Accepted

## Date

2024-12-07

## Context

The work system needs to maintain state across several dimensions:

1. **Active work item**: What the user is currently working on
2. **Queue assignments**: Which queue each work item belongs to
3. **Session logs**: Actions taken during this Claude session
4. **Run history**: Metrics from stage executions

This state must persist across:
- Multiple tool calls within a conversation
- Context window resets (when conversation gets too long)
- Potentially across Claude sessions (for longer tasks)

Options for storing this state:
1. External systems only (Teamwork, GitHub, etc.)
2. Local files in `~/.claude/session/`
3. Hybrid approach

## Decision

Use **local-first session state** stored in `~/.claude/session/`:

```
~/.claude/session/
├── active-work.md      # Current work item context
├── session-log.md      # Run and action log
├── queues.json         # Queue assignments
└── .gitignore          # Don't version session state
```

### Key Principles

1. **Local is authoritative for session state**: Queue assignments, active work, and logs are stored locally
2. **External systems are authoritative for work item data**: Task details, status, comments come from Teamwork/GitHub/etc.
3. **Session files are ephemeral**: Not versioned, can be cleared without data loss
4. **External sync is optional**: Can push certain changes back to external systems

### State Categories

| State | Location | Authoritative Source |
|-------|----------|---------------------|
| Work item details | External system | External |
| Queue assignment | `queues.json` | Local |
| Active work context | `active-work.md` | Local |
| Session/run logs | `session-log.md` | Local |
| Triage results | External (comment) | External |
| Design artifacts | Git repo | Git |

## Consequences

### Positive

- **Fast access**: No API calls for session state
- **Works offline**: Queue and active work available without network
- **No permissions needed**: Local files, no external API requirements
- **Simple implementation**: JSON/Markdown files, no database
- **Context survives resets**: Files persist when conversation context clears

### Negative

- **Not shared**: Team members can't see each other's queue assignments
- **Machine-specific**: State doesn't follow user across machines
- **Manual sync**: Must explicitly push changes to external systems
- **Cleanup needed**: Old session data accumulates

### Mitigations

- **Important state pushed to external**: Triage results, comments, status changes go to Teamwork/GitHub
- **Log rotation**: session-log.md rotates at 10,000 lines
- **Clear command**: Can clear session state intentionally

## Implementation

### Session Directory Structure

```
~/.claude/session/
├── active-work.md      # Markdown with current work item
├── session-log.md      # Structured log of runs/actions
├── queues.json         # JSON queue assignments
├── local-work-items.json  # For local-only projects
└── .gitignore          # Contains: *
```

### Active Work Format

```markdown
# Active Work

**Work Item:** TW-12345
**Title:** Fix login timeout issue
**Stage:** deliver
**Queue:** todo

## Context
...

## Progress
...
```

### Queue Store Format

```json
{
  "version": "1.0",
  "assignments": {
    "TW-12345": {
      "queue": "todo",
      "assignedAt": "2024-12-07T10:00:00Z",
      "reason": "Prioritized for sprint"
    }
  },
  "history": [...]
}
```

## Alternatives Considered

### 1. External Systems Only

Store all state in Teamwork/GitHub/Linear.

**Rejected because**:
- Different systems have different capabilities
- API calls for every state access is slow
- Permission issues with some operations

### 2. SQLite Database

Use local SQLite for structured storage.

**Rejected because**:
- Overkill for current needs
- Harder to inspect/debug
- Markdown/JSON more readable in conversation

### 3. Redis/In-Memory Store

Use in-memory store with optional persistence.

**Rejected because**:
- Adds infrastructure dependency
- Session already provides persistence via files

## Related Decisions

- ADR-0001: Work Manager Abstraction Layer
- ADR-0003: Session Logging Format (pending)

## References

- `~/.claude/session/active-work.md` - Active work template
- `~/.claude/session/session-log.md` - Log format
- `~/.claude/agents/session-logger.md` - Logging agent
