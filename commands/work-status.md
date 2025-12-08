---
description: Display work system implementation progress and status
allowedTools:
  - Read
---

# Work System Status

Display the current progress on the work system implementation plan.

## Instructions

1. **Read the implementation plan:**
   - Read `~/.claude/work-system-implementation-plan.md`

2. **Extract and display status summary:**

### Output Format

```markdown
# Work System Implementation Status

**Last Updated:** {date from plan}
**Overall Status:** {status from plan}

## Phase Progress

| Phase | Status | Progress |
|-------|--------|----------|
| 0 - Foundation | {status} | {X/10 items} |
| 1 - Triage | {status} | {X/5 items} |
| 2 - Plan | {status} | {X/4 items} |
| 3 - Design | {status} | {X/4 items} |
| 4 - Deliver | {status} | {X/5 items} |
| 5 - Logging | {status} | {X/3 items} |
| 6 - Queues | {status} | {X/3 items} |
| 7 - Templates | {status} | {X/10 items} |

**Total Progress:** {total checked}/{total items} ({percentage}%)

## Current Phase Details

### Phase {N}: {Name}
**Status:** {In Progress / Not Started / Complete}
**Started:** {date or -}

#### Remaining Items:
- [ ] {unchecked item 1}
- [ ] {unchecked item 2}
...

#### Completed Items:
- [x] {checked item 1}
...

## Recent Activity

{Last 5 changelog entries}

## Next Actions

{From "Next Actions" section of plan}

## Blockers

{From most recent session notes, or "None"}
```

3. **Calculate progress:**
   - Count `- [x]` (checked) vs `- [ ]` (unchecked) in each phase section
   - Calculate percentage: (checked / total) * 100
   - Determine current phase (first phase with status "In Progress" or first "Not Started")

4. **Identify next actions:**
   - Pull from the "Next Actions" section
   - If current phase has unchecked items, list first 3 as immediate next steps

5. **Show blockers:**
   - Check most recent session notes for "Blockers" section
   - Display any non-"None" blockers prominently

## Example Output

```markdown
# Work System Implementation Status

**Last Updated:** 2024-12-07
**Overall Status:** Draft - Ready for Review

## Phase Progress

| Phase | Status | Progress |
|-------|--------|----------|
| 0 - Foundation | In Progress | 3/10 items |
| 1 - Triage | Not Started | 0/5 items |
| 2 - Plan | Not Started | 0/4 items |
| 3 - Design | Not Started | 0/4 items |
| 4 - Deliver | Not Started | 0/5 items |
| 5 - Logging | Not Started | 0/3 items |
| 6 - Queues | Not Started | 0/3 items |
| 7 - Templates | Not Started | 0/10 items |

**Total Progress:** 3/44 (7%)

## Current Phase Details

### Phase 0: Foundation
**Status:** In Progress
**Started:** 2024-12-08

#### Remaining Items:
- [ ] `~/.claude/templates/_schema.json`
- [ ] `~/.claude/templates/support/` directory
- [ ] `~/.claude/templates/product/` directory
- [ ] `~/.claude/templates/delivery/` directory
- [ ] `~/.claude/commands/index.yaml`
- [ ] `~/.claude/session/active-work.md`
- [ ] `~/.claude/session/session-log.md`

#### Completed Items:
- [x] `~/.claude/agents/work-item-mapper.md`
- [x] `~/.claude/templates/README.md`
- [x] `~/.claude/session/.gitignore`

## Recent Activity

| Date | Phase | What Was Done |
|------|-------|---------------|
| 2024-12-08 | 0 | Created work-item-mapper agent |
| 2024-12-07 | - | Created implementation plan |

## Next Actions

1. Create `~/.claude/templates/_schema.json`
2. Create template directory structure
3. Create `~/.claude/commands/index.yaml`

## Blockers

None
```

## Notes

- This command is read-only - it only displays status
- To update progress, edit `~/.claude/work-system-implementation-plan.md` directly
- Run this at the start of each session to see where you left off
- Run after completing work to verify progress was recorded
