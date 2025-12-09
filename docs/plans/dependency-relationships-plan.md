# Plan: Add Dependency Relationships to Work System

## Objective

Add blocked-by/blocking dependency relationships to the work item schema (source of truth) and synchronize across GitHub and Teamwork command systems.

## Design Principles

1. **Work item is source of truth** - update work-item.md first, then sync to external systems
2. **Bidirectional tracking** - store both `blockedBy` and `blocking` explicitly
3. **Graceful degradation** - use description text when API doesn't support dependencies
4. **Cross-system support** - work items can depend on items in different external systems

## Schema Changes

### Add to Work Item Schema

```yaml
# Dependency Fields (NEW)
blockedBy: Dependency[]         # Work items that must complete before this one
blocking: Dependency[]          # Work items waiting on this one

# Dependency Type
Dependency:
  workItemId: string            # Internal ID (e.g., "WI-002")
  externalId: string | null     # External ID (e.g., "26134585")
  externalSystem: string | null # Source (teamwork | github | linear | jira)
  type: enum                    # complete | start (for Teamwork compatibility)
  addedAt: datetime
  addedBy: string | null
```

## New Commands

### 1. Work Item Commands (add to `/commands/domain/work-item.md`)

```bash
# Add dependencies
/work-item depend WI-001 --blocked-by WI-002
/work-item depend WI-001 --blocking WI-003
/work-item depend WI-001 --blocked-by WI-002 --blocked-by WI-003

# Remove dependencies
/work-item depend WI-001 --remove-blocked-by WI-002

# View dependencies
/work-item show-dependencies WI-001
```

### 2. Teamwork Command (create `/commands/teamwork/tw-task-dependency.md`)

```bash
# Use Teamwork's predecessor API
/tw-task-dependency 26134585 --predecessor 26134580
/tw-task-dependency 26134585 --predecessor 26134580 --type start
/tw-task-dependency 26134585 --successor 26134590
/tw-task-dependency 26134585 --remove-predecessor 26134580
```

**Note**: Uses `--predecessor`/`--successor` to match Teamwork's terminology.

### 3. GitHub Command (already exists - `/commands/github/gh-issue-dependency.md`)

```bash
# Already implemented
/gh-issue-dependency 3 --blocked-by 2
/gh-issue-dependency 2 --blocking 3
```

## Sync Strategy

### When Adding Dependency via Work Item

```
/work-item depend WI-001 --blocked-by WI-002
         │
         ├─→ Update local work item (source of truth)
         │     - Add WI-002 to WI-001.blockedBy
         │     - Add WI-001 to WI-002.blocking (inverse)
         │
         └─→ Sync to external systems
               │
               ├─→ If both in GitHub → use GraphQL addBlockedBy
               ├─→ If both in Teamwork → use predecessors API
               └─→ If cross-system → append to description as fallback
```

### Description Fallback Format

When dependencies can't be represented natively in external system:

```markdown
---
## Dependencies

**Blocked by:** TW-456: Setup database schema (Teamwork)
**Blocking:** GH-#123: Deploy to staging (GitHub)
```

## Files to Modify/Create

| File | Action | Changes |
|------|--------|---------|
| `commands/domain/work-item.md` | **Modify** | Add `depend` and `show-dependencies` actions |
| `commands/teamwork/tw-task-dependency.md` | **Create** | New Teamwork dependency command |
| `commands/teamwork/README.md` | **Modify** | Document new command |

## Implementation Sequence

### Step 1: Update Work Item Schema & Commands

1. Add `blockedBy[]` and `blocking[]` fields to work-item.md
2. Add `depend` action with options: `--blocked-by`, `--blocking`, `--remove-blocked-by`, `--remove-blocking`
3. Add `show-dependencies` action

### Step 2: Create Teamwork Dependency Command

1. Create `tw-task-dependency.md` using Teamwork's predecessor API
2. Use naming: `--predecessor`, `--successor` (matches Teamwork terminology)
3. Support `--type start|complete` for Teamwork's dependency types
4. Update README.md

### Step 3: Verify GitHub Command Alignment

1. Ensure `/gh-issue-dependency` aligns with work-item schema pattern
2. Both use `--blocked-by`/`--blocking` terminology

## Command Terminology Alignment

| Concept | Work Item | GitHub | Teamwork |
|---------|-----------|--------|----------|
| This depends on X | `--blocked-by` | `--blocked-by` | `--predecessor` |
| X depends on this | `--blocking` | `--blocking` | `--successor` |
| Remove dependency | `--remove-blocked-by` | `--remove-blocked-by` | `--remove-predecessor` |

**Rationale**: GitHub and work-item use same terms. Teamwork uses its native "predecessor/successor" terminology for API clarity.

## Error Handling

- **Circular dependency**: Detect and reject with clear error message
- **External sync failure**: Record locally, mark sync as "pending", allow retry
- **Missing external link**: Record locally, suggest linking work item

## Related

- ADR-0005: Work Item Dependencies
- `/commands/github/gh-issue-dependency.md` - Existing GitHub implementation
- `/commands/domain/work-item.md` - Work item aggregate
