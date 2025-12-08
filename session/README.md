# Session State

Runtime state for the work system including active work tracking, urgency queues, and session logs.

## Overview

This directory contains ephemeral state that tracks current work context. Files here are typically not committed to git (see `.gitignore`) as they represent per-user, per-session state.

## Directory Structure

```
session/
├── README.md           # This file
├── .gitignore          # Excludes runtime state from git
├── active-work.md      # Currently active work item
├── queues.json         # Urgency queue assignments
├── session-log.md      # Activity log for current session
└── logging-guide.md    # Guide to session logging
```

## Files

### active-work.md

Tracks the currently selected work item:

```markdown
# Active Work Item

**Task ID**: TW-26134585
**Title**: Update database schema
**Status**: in_progress
**Started**: 2024-12-07T10:30:00Z

## Context
- Parent: Service Plan Management
- Template: delivery/bug-fix
- Queue: now
```

### queues.json

Urgency queue assignments for routing work:

```json
{
  "now": [],
  "today": ["TW-26134585"],
  "week": ["TW-26142100"],
  "later": []
}
```

### session-log.md

Timestamped activity log:

```markdown
# Session Log

## 2024-12-07

### 10:30:00 - Task Selected
- Task: TW-26134585
- Action: Started work

### 11:45:00 - Checkpoint
- Progress: 50%
- Notes: Schema migration complete
```

### logging-guide.md

Documentation for the session logging system, including:
- Log format specification
- Metrics captured
- Integration with session-logger agent

## Git Behavior

The `.gitignore` excludes runtime state:

```gitignore
# Session state (user-specific)
active-work.md
queues.json
session-log.md

# Keep documentation
!README.md
!logging-guide.md
!.gitignore
```

## Usage

### Starting Work

When selecting a task via `/select-task` or `/resume`:
1. Task details written to `active-work.md`
2. Session-logger records the selection
3. Queue state updated if needed

### During Work

The session-logger agent captures:
- Stage transitions (triage → plan → design → deliver)
- Tool usage and file changes
- Time spent per activity
- Decisions and outcomes

### Completing Work

When work is completed:
1. Final log entry recorded
2. Metrics summarized
3. Active work cleared
4. Queue state updated

## Integration with Agents

### session-logger Agent

The primary agent for session management:
- Generates unique IDs
- Records timestamped actions
- Captures metrics
- Maintains log consistency

### Other Agents

Agents interact with session state:
- **triage-agent** - Updates queue assignments
- **eval-agent** - Reads session logs for retrospective
- **task-fetcher** - May reference active work context

## State Persistence

Session state is:
- **Local only** - Not synced across machines
- **Per-user** - Each developer has own state
- **Ephemeral** - Can be safely deleted
- **Recoverable** - Can be rebuilt from Teamwork

## Related Files

- [logging-guide.md](logging-guide.md) - Detailed logging documentation
- [../agents/session-logger.md](../agents/session-logger.md) - Logger agent
- [../docs/work-system.md](../docs/work-system.md) - Full specification

---

*Last Updated: 2024-12-07*
