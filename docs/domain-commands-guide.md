# Domain Commands Guide

A comprehensive guide to using domain aggregate commands in the Work System.

---

## Overview

Domain commands provide a **natural language interface** to work management operations. Rather than calling APIs directly, you express intent through structured commands that read like English.

```bash
# Instead of API calls...
/work-item create --name "Fix login bug" --type bug --priority high
/work-item assign WI-042 @cbryant
/work-item transition WI-042 deliver
```

---

## Quick Reference

### Work Items

```bash
# Queries
/work-item get <id>                     # Get by ID
/work-item list [--filters]             # List with filters
/work-item history <id>                 # View history

# Lifecycle
/work-item create --type <type> --name "..."
/work-item update <id> --priority high
/work-item delete <id>

# Assignment
/work-item assign <id> @agent
/work-item unassign <id>

# Workflow
/work-item transition <id> <stage>      # triage|plan|design|deliver|eval
/work-item route <id> <queue> [reason]  # immediate|urgent|standard|deferred
/work-item block <id> [reason]
/work-item unblock <id>

# Collaboration
/work-item comment <id> "message"
/work-item log-time <id> <duration> [description]

# Hierarchy
/work-item add-child <id> --type <type> --name "..."
/work-item move <id> --parent <new-parent-id>

# External Systems
/work-item sync <id>
/work-item link <id> <system> <external-id>
```

### Projects

```bash
/project get <id>
/project list [--active]
/project stats <id>
/project create --name "..."
/project update <id> --status active|archived|on_hold
/project add-member <id> @agent
/project remove-member <id> @agent
/project sync <id>
/project link <id> <system> <external-id>
```

### Agents

```bash
/agent get <id>
/agent list [--available] [--type human|ai|automation]
/agent workload <id>
/agent status [--active|--away|--offline]
/agent my-work [--status in_progress]
```

### Queues

```bash
/queue list
/queue show <queue-name>
/queue stats
```

---

## Common Workflows

### Start a New Bug Fix

```bash
# 1. Create the bug
/work-item create --type bug --name "Login fails on Safari" --priority high

# 2. Triage and route
/work-item route WI-042 urgent "Affecting enterprise customers"

# 3. Assign and start work
/work-item assign WI-042 @cbryant
/work-item transition WI-042 deliver

# 4. Add context
/work-item comment WI-042 "Investigating WebKit cookie handling"
```

### Complete a Task

```bash
# 1. Log your time
/work-item log-time WI-042 2h "Debugging and implementing fix"

# 2. Add completion note
/work-item comment WI-042 "Fix deployed. Safari cookie SameSite attribute corrected."

# 3. Move to evaluation
/work-item transition WI-042 eval

# 4. Capture learnings
/work-item comment WI-042 "Root cause: Safari strict cookie policy. Added regression test."
```

### Plan a Feature

```bash
# 1. Create the feature
/work-item create --type feature --name "User Authentication" --project PRJ-001

# 2. Break down into stories
/work-item add-child WI-010 --type story --name "Login flow"
/work-item add-child WI-010 --type story --name "Password reset"
/work-item add-child WI-010 --type story --name "OAuth integration"

# 3. Add tasks to a story
/work-item add-child WI-011 --type task --name "Design login form"
/work-item add-child WI-011 --type task --name "Implement validation"
/work-item add-child WI-011 --type task --name "Add session management"

# 4. Estimate and transition
/work-item update WI-011 --estimate 8h
/work-item transition WI-010 plan
```

### Escalate an Issue

```bash
# 1. Get current status
/work-item get WI-042

# 2. Route to higher priority queue
/work-item route WI-042 immediate "Production outage - database unreachable"

# 3. Notify via comment
/work-item comment WI-042 "ESCALATED: Routing to immediate queue due to production impact"
```

### Check Your Workload

```bash
# See what you're working on
/agent my-work

# See all work in a queue
/queue show urgent

# Check a team member's capacity
/agent workload @jane
```

---

## Filter Syntax

### Work Item Filters

```bash
# By status
/work-item list --status in_progress
/work-item list --status triaged,planned,designed  # Multiple

# By type
/work-item list --type bug
/work-item list --type story,task

# By priority
/work-item list --priority critical
/work-item list --priority high,critical

# By queue
/work-item list --queue urgent
/work-item list --queue immediate,urgent

# By assignee
/work-item list --assignee @cbryant
/work-item list --assignee @me  # Current agent

# By project
/work-item list --project PRJ-001

# Combinations
/work-item list --queue urgent --assignee @me --type bug
```

### Project Filters

```bash
/project list --status active
/project list --status active,on_hold
```

### Agent Filters

```bash
/agent list --type human
/agent list --available
/agent list --type ai --available
```

---

## Duration Syntax

Time durations use human-readable format:

```bash
# Minutes
/work-item log-time WI-042 30m "Quick fix"

# Hours
/work-item log-time WI-042 2h "Implementation"

# Hours and minutes
/work-item log-time WI-042 2h30m "Full feature"

# Also supported
/work-item log-time WI-042 1.5h "Implementation"
```

---

## External System References

Link work items to external systems:

```bash
# Link to Teamwork task
/work-item link WI-042 teamwork 26134585

# Link to GitHub issue
/work-item link WI-042 github "company/repo#123"

# Link to Linear issue
/work-item link WI-042 linear "ABC-123"

# Link to JIRA
/work-item link WI-042 jira "PROJ-456"
```

Query by external reference:

```bash
/work-item get --external teamwork:26134585
/work-item get --external github:company/repo#123
```

---

## Work Item Types

| Type | Description | Can Contain |
|------|-------------|-------------|
| `epic` | Large initiative | features, stories |
| `feature` | Deliverable capability | stories, tasks |
| `story` | User-facing requirement | tasks |
| `task` | Atomic unit of work | nothing (leaf) |
| `bug` | Defect to fix | tasks (optional) |
| `spike` | Research/investigation | tasks (optional) |

---

## Workflow Stages

| Stage | Purpose | Entry Conditions |
|-------|---------|------------------|
| `triage` | Categorize and prioritize | Item created |
| `plan` | Break down and estimate | Triage complete |
| `design` | Solution design | Plan complete |
| `deliver` | Implementation | Acceptance criteria defined |
| `eval` | Review outcomes | Delivery complete |

---

## Queue Urgency Levels

| Queue | SLA Response | SLA Resolution | Use For |
|-------|--------------|----------------|---------|
| `immediate` | 15 min | 4 hours | Production down |
| `urgent` | 1 hour | 24 hours | High-impact issues |
| `standard` | 4 hours | 5 days | Normal work |
| `deferred` | None | None | Backlog |

---

## Error Handling

Commands return clear errors:

```bash
# Invalid transition
> /work-item transition WI-042 deliver
❌ Invalid transition: Cannot move from 'draft' to 'deliver'
   Allowed transitions: triaged

# Not found
> /work-item get WI-999
❌ Work item WI-999 not found

# Missing required field
> /work-item create --type bug
❌ Missing required field: --name

# Invalid assignment
> /work-item assign WI-042 @unknown
❌ Agent @unknown not found
```

---

## Tips

### Use Tab Completion
Commands support tab completion for IDs, types, queues, and agent handles.

### Chain Related Operations
Group related commands logically:

```bash
# Bad: scattered updates
/work-item update WI-042 --priority high
/work-item comment WI-050 "unrelated"
/work-item assign WI-042 @cbryant

# Good: focused sequence
/work-item update WI-042 --priority high
/work-item assign WI-042 @cbryant
/work-item comment WI-042 "Taking ownership, will start today"
```

### Use Comments for Context
Comments sync to external systems and provide audit trail:

```bash
/work-item comment WI-042 "Escalated per customer request - Jane on vacation"
```

### Log Time as You Work
Don't batch time logging - log as you go:

```bash
/work-item log-time WI-042 45m "Initial investigation"
# ...work more...
/work-item log-time WI-042 1h30m "Implementation and testing"
```

---

## Related Documentation

- [Programming in Natural Language](programming-in-natural-language.md) - Philosophy
- [Aggregates Reference](../schema/aggregates.md) - Technical details
- [Schema Directory](../schema/) - Data models
- [Workflow Commands](../commands/) - Higher-level workflows
