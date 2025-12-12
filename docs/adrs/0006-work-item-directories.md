# ADR-0006: Work Item Directories

## Status

Accepted

## Date

2025-12-09

## Context

The work system generates multiple documents during the lifecycle of a work item: PRDs, specs, implementation plans, test plans, bug reports, and research notes. Currently, these documents are organized by **type** into category folders:

```text
docs/
├── prd/TW-12345-feature.md
├── specs/TW-12345-feature.md
├── plans/TW-12345-impl.md
└── bugs/TW-12345-bug.md
```

This organization creates several problems:

1. **Scattered context**: All artifacts for a work item are spread across multiple directories
2. **No cross-session history**: When resuming work, there's no record of what was done in previous sessions
3. **Lost decisions**: Design decisions and research are disconnected from the work item
4. **Difficult handoffs**: Another developer can't easily see all context for a work item

Additionally, session logging (ADR-0002) captures Claude session activity but is:

- Global (all work items in one log)
- Ephemeral (can be cleared without data loss)
- Session-scoped (not work-item-scoped)

We need a way to maintain **persistent, work-item-specific context** across multiple Claude sessions.

### Inspiration

The pattern at `/home/cbryant/projects/link/atlas/dev-support/tasks/tw-26253606/` demonstrates a "structured home" for a work item containing delivery plans, estimates, specs, and research all in one directory. This provides complete context for anyone working on that task.

## Decision

Create a `work-items/` directory at the repository root with subdirectories for each active work item. Each subdirectory is named using the format `{prefix}-{id}` and contains all artifacts related to that work item.

### Directory Structure

```text
work-items/
├── tw-26253606/
│   ├── work-item.yaml      # Metadata snapshot
│   ├── activity-log.md     # Cross-session history
│   ├── prd.md              # Product requirements
│   ├── spec.md             # Technical specification
│   ├── impl-plan.md        # Implementation plan
│   ├── test-plan.md        # Test strategy
│   ├── adr/                # Work-item-specific ADRs
│   └── research/           # Supporting research
├── gh-456/
└── ado-123/
```

### Naming Convention

| Prefix | External System |
|--------|-----------------|
| `tw` | Teamwork |
| `gh` | GitHub |
| `ado` | Azure DevOps |
| `wi` | Internal (no external system) |

### Key Components

**`work-item.yaml`**: Metadata snapshot including external system reference, type, status, stage, and timestamps.

**`activity-log.md`** (tracked): High-level, team-facing history of significant events. Captures stage transitions, artifacts created, and key decisions. Written in a summary style suitable for team review.

**`session-notes.md`** (gitignored): Personal scratch notes for the current developer. Captures detailed thinking, questions, and verbose session-specific notes. Not shared with the team.

### Relationship to Session Logging

| Aspect | Session Log (ADR-0002) | Activity Log | Session Notes |
|--------|------------------------|--------------|---------------|
| Scope | Claude session | Work item | Work item |
| Lifespan | Ephemeral | Persistent | Ephemeral |
| Git | Ignored | Tracked | Ignored |
| Location | `~/.claude/session/` | `work-items/{id}/` | `work-items/{id}/` |
| Content | Tool calls, tokens | Stage events, artifacts | Personal notes |
| Audience | Developer (debug) | Team (history) | Developer (scratch) |

The session logger writes to the activity log at significant moments (stage start/complete, artifact creation). Developers can optionally use session-notes.md for detailed personal notes.

### Initialization

Work item directories are created during the **triage stage** - the first formal entry point into the work system. The triage agent:

1. Creates `work-items/{prefix}-{id}/` directory
2. Writes initial `work-item.yaml` with metadata
3. Creates `activity-log.md` with initialization entry

### Git Tracking

Work item directories **are tracked in git**. This preserves history, enables collaboration, and allows code review of artifacts alongside implementation.

## Consequences

### Positive

- **Complete context**: All artifacts for a work item in one place
- **Cross-session continuity**: Activity log survives Claude session resets
- **Easy handoffs**: Another developer can read activity log to understand history
- **Better `/workflow:resume`**: Can load activity log to reconstruct context
- **Cleaner repo**: No more scattered `TW-12345-*.md` files across category folders
- **Local ADRs**: Work-item-specific decisions stay with the work item

### Negative

- **Directory proliferation**: Many work items = many directories
- **Potential staleness**: Old directories may accumulate
- **Migration needed**: Existing documents need to be reorganized
- **Path changes**: Document writer needs updated output logic

### Mitigations

- **Archival pattern**: Move completed work items to `work-items/.archive/` after delivery
- **Cleanup command**: `work-item archive` to move completed items
- **Gradual migration**: New work items use new pattern; existing documents stay in place

## Alternatives Considered

### 1. Keep Category-Based Organization

Continue using `docs/prd/`, `docs/specs/`, etc.

**Rejected because**:

- Context remains scattered
- No cross-session history
- Difficult to see complete picture of a work item

### 2. Hybrid Organization (Both Locations)

Store documents in both work-items/ and docs/{category}/ (symlinks or copies).

**Rejected because**:

- Dual maintenance burden
- Potential sync issues
- Unnecessary complexity

### 3. Global Activity Log Per Work Item

Store activity in `~/.claude/work-items/` (global, not repo-local).

**Rejected because**:

- Not shareable with team
- Not versioned with code
- Disconnected from implementation

### 4. Database Storage

Use SQLite or JSON file for activity tracking.

**Rejected because**:

- Markdown more readable in conversation
- Easier to inspect/debug
- Matches existing patterns (session-log.md)

## Related Decisions

- [ADR-0002: Local-First Session State](0002-local-first-session-state.md) - Session logging foundation
- [ADR-0003: Stage-Based Workflow](0003-stage-based-workflow.md) - Stage transitions logged in activity

## References

- Implementation plan: [work-item-directories-plan.md](../plans/work-item-directories-plan.md)
- Inspiration: `/home/cbryant/projects/link/atlas/dev-support/tasks/tw-26253606/`
- Session logger: [session-logger.md](../../agents/session-logger.md)
- Document writer: [document-writer-agent.md](../agents/document-writer-agent.md)
