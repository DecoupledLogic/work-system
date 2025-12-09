# ADR-0005: Work Item Dependencies

## Status

Accepted

## Date

2024-12-09

## Context

Work items often have dependencies on other work items. For example:

- A feature implementation is **blocked by** the API design being completed
- A database schema task **blocks** multiple downstream implementation tasks
- A GitHub issue depends on a Teamwork task being finished first

Currently, the work system handles blocking through:

1. **Status-based blocking**: `/work-item block WI-001 "reason"` sets status to "blocked" with a reason in metadata
2. **GitHub dependencies**: `/gh-issue-dependency` uses GitHub's native GraphQL API for issue dependencies
3. **No Teamwork support**: No command exists for Teamwork's predecessor/successor relationships

This approach has several problems:

1. **No structured dependencies**: The `block` command is for ad-hoc blocking, not dependency chains
2. **System fragmentation**: GitHub has dependencies, Teamwork doesn't have a command
3. **No cross-system**: Can't express that a GitHub issue depends on a Teamwork task
4. **Work item not source of truth**: Dependencies exist only in external systems

## Decision

Implement **work item dependencies** as a first-class concept with the following design:

### 1. Add Dependency Fields to Work Item Schema

```yaml
blockedBy: Dependency[]         # Work items that must complete before this one
blocking: Dependency[]          # Work items waiting on this one

Dependency:
  workItemId: string            # Internal ID (e.g., "WI-002")
  externalId: string | null     # External ID (e.g., "26134585")
  externalSystem: string | null # Source (teamwork | github | linear | jira)
  type: enum                    # complete | start
  addedAt: datetime
  addedBy: string | null
```

### 2. Work Item as Source of Truth

Dependencies are stored in the work item aggregate. When a dependency is added:

1. Update local work item with dependency
2. Update inverse relationship on the other work item
3. Sync to external systems if both items are linked to same system
4. Fall back to description text for cross-system dependencies

### 3. Unified Command Pattern with System-Specific Terminology

| System | Command | Add Dependency | Remove Dependency |
|--------|---------|----------------|-------------------|
| Work Item | `/work-item depend` | `--blocked-by`, `--blocking` | `--remove-blocked-by` |
| GitHub | `/gh-issue-dependency` | `--blocked-by`, `--blocking` | `--remove-blocked-by` |
| Teamwork | `/tw-task-dependency` | `--predecessor`, `--successor` | `--remove-predecessor` |

Work item and GitHub use "blocked-by/blocking" terminology. Teamwork uses "predecessor/successor" to match its native API terminology.

### 4. Dependency Types

Supporting Teamwork's distinction:

- `complete`: This item can complete when the dependency completes (default)
- `start`: This item can complete when the dependency starts

GitHub only supports `complete` semantics.

### 5. Cross-System Dependencies

When work items are in different external systems:

```
WI-001 (GitHub #123) blocked by WI-002 (Teamwork 456)

- Work item store: Full dependency recorded
- GitHub #123: Description note "Blocked by TW-456"
- Teamwork 456: Description note "Blocking GH-#123"
```

## Consequences

### Positive

- **Unified dependency model**: Same concept works across all external systems
- **Cross-system support**: Can express dependencies between GitHub and Teamwork items
- **Work item as source of truth**: Dependencies survive external system changes
- **Bidirectional tracking**: Query both "what blocks this" and "what does this block"
- **Consistent with existing patterns**: Follows queue-store local-first pattern

### Negative

- **Eventual consistency**: External systems may be temporarily out of sync
- **Description pollution**: Cross-system dependencies add text to descriptions
- **Maintenance burden**: Must maintain inverse relationships

### Neutral

- **Type complexity**: Supporting `start` vs `complete` adds complexity but enables Teamwork parity
- **Terminology variation**: Different terms per system (blocked-by vs predecessor) requires translation

## Alternatives Considered

### 1. External System Native Only

Use each system's native dependency features exclusively.

**Rejected because**: No cross-system dependencies possible; work item not source of truth.

### 2. Single Terminology Everywhere

Use "blocked-by/blocking" for all systems including Teamwork.

**Rejected because**: Teamwork API uses "predecessor/successor"; matching native terms improves clarity.

### 3. Status-Based Blocking Only

Keep current `block`/`unblock` commands for all blocking needs.

**Rejected because**: Doesn't support dependency chains, graphs, or cross-references.

### 4. Separate Dependency Store

Create a dedicated `~/.claude/session/dependencies.json` file.

**Rejected because**: Dependencies are intrinsic to work items; should be in work item schema.

## Related Decisions

- ADR-0001: Work Manager Abstraction Layer
- ADR-0002: Local-First Session State

## References

- `docs/plans/dependency-relationships-plan.md` - Implementation plan
- `commands/github/gh-issue-dependency.md` - GitHub implementation
- `commands/domain/work-item.md` - Work item aggregate
- [GitHub Issue Dependencies](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/creating-issue-dependencies)
- [Teamwork Task Dependencies](https://developer.teamwork.com/projects/api-v1/ref/tasks)
