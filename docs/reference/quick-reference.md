# Work System Quick Reference

Fast lookup for common operations and commands.

## Commands

### Work Selection

```bash
/workflow:select-task              # Pick next work item from queues
/workflow:resume                   # Continue active work item
/work:status              # View system implementation status
```

### Workflow Stages

```bash
/workflow:triage <id>              # Categorize and route work
/workflow:plan <id>                # Decompose and size work
/workflow:design <id>              # Explore solutions, create ADR
/workflow:deliver <id>             # Implement, test, evaluate
```

### Queue Management

```bash
/workflow:queue                    # View all queues
/workflow:queue immediate          # View critical queue
/workflow:queue todo               # View current work queue
/workflow:queue backlog            # View next cycle queue
/workflow:queue icebox             # View future queue

/workflow:route <id> <queue>       # Move work between queues
/workflow:route TW-123 immediate   # Promote to critical
/workflow:route TW-456 backlog     # Defer to next cycle
```

## Work Item IDs

Format: `<SYSTEM>-<ID>`

```
TW-12345                  # Teamwork task
GH-owner/repo#123         # GitHub issue
LIN-ABC-123               # Linear issue
JIRA-PROJ-456             # Jira issue
LOCAL-1                   # Local work item
```

## Work Item Fields

### Type
```
epic                      # Strategic initiative (6-12 weeks)
feature                   # Product capability (1-4 weeks)
story                     # User-facing change (1-3 days)
task                      # Technical work (2-8 hours)
bug                       # Defect to fix
support                   # Customer support request
```

### WorkType
```
product_delivery          # New features
support                   # Customer support
maintenance               # Technical debt
bug_fix                   # Bug fixes
research                  # Investigation
other                     # Miscellaneous
```

### Urgency
```
critical                  # Same-day action required → immediate queue
now                       # Current cycle → todo queue
next                      # Next cycle → backlog queue
future                    # Long-term → icebox queue
```

### Impact
```
high                      # Revenue, safety, SLA, major UX
medium                    # Noticeable improvement, non-critical
low                       # Nice to have, minor polish
```

### Stage
```
triage                    # Being categorized
planned                   # Decomposed and sized
designed                  # Solution decided
ready_for_dev             # Ready to implement
in_progress               # Being built
in_review                 # Under review
in_test                   # Being tested
done                      # Completed
```

## Agents

```
work-item-mapper          # Normalize external tasks (haiku)
triage-agent              # Categorize and route (sonnet)
plan-agent                # Decompose and size (sonnet)
design-agent              # Explore solutions (sonnet)
dev-agent                 # Implement code (sonnet)
qa-agent                  # Validate quality (haiku)
eval-agent                # Evaluate outcomes (sonnet)
session-logger            # Log activity (haiku)
template-validator        # Validate templates (haiku)
task-selector             # Select work (haiku)
task-fetcher              # Fetch tasks (haiku)
```

## Templates

### Support Templates
```
support/generic                      # Basic support request
support/remove-profile               # GDPR/CCPA profile deletion
support/subscription-change          # Subscription upgrade/downgrade
```

### Product Templates
```
product/prd                          # Product Requirements Document (epic)
product/feature                      # Feature specification
product/story                        # User story (versioned)
```

### Delivery Templates
```
delivery/adr                         # Architecture Decision Record
delivery/bug-fix                     # Bug investigation and fix
delivery/implementation-plan         # Task breakdown with estimates
```

## Common Workflows

### New Support Request
```bash
/workflow:triage TW-12345          # Categorize → routes to queue
/workflow:deliver TW-12345         # Execute support workflow
```

### New Feature Request
```bash
/workflow:triage TW-99001          # Categorize → creates epic/feature
/workflow:plan TW-99001            # Decompose → creates stories
/workflow:design TW-99002          # Design first story → creates ADR
/workflow:deliver TW-99002         # Build, test, evaluate
```

### Critical Bug
```bash
/workflow:triage TW-CRIT-1         # Categorize → immediate queue
/workflow:design TW-CRIT-1         # Quick solution exploration
/workflow:deliver TW-CRIT-1        # Fix, test, ship
```

### Cycle Planning
```bash
/workflow:queue todo               # Review current work
/workflow:queue backlog            # Review next items
/workflow:route TW-123 todo        # Promote to current cycle
/workflow:select-task              # Start working
```

## File Locations

### Configuration
```
~/.claude/work-manager.yaml          # Work system config
~/.claude/.credentials.json          # API credentials (gitignored)
```

### Session State (gitignored)
```
~/.claude/session/active-work.md     # Current work context
~/.claude/session/session-log.md     # Activity log
~/.claude/session/queues.json        # Queue assignments
```

### Documentation
```
~/.claude/docs/work-system-guide.md  # Complete guide
~/.claude/docs/work-system.md        # Core spec
~/.claude/docs/sub-agents-guide.md   # Agent development
~/.claude/docs/quick-reference.md    # This file
```

## Configuration Examples

### Teamwork
```yaml
manager: teamwork
teamwork:
  projectId: 123456
queues:
  storage: local
```

### GitHub
```yaml
manager: github
github:
  owner: myorg
  repo: myrepo
queues:
  storage: native
  mapping:
    immediate: "priority: critical"
    todo: "priority: high"
    backlog: "priority: medium"
    icebox: "priority: low"
```

### Local-Only
```yaml
manager: local
queues:
  storage: local
```

## Sizing Bounds

```
Epic:     Max 3 cycles (6 weeks)
Feature:  Max 2 weeks
Story:    Max 3 days
Task:     Max 8 hours
```

If work exceeds bounds, agent will split it.

## Acceptance Criteria Format

Use Gherkin format:

```gherkin
Given [context]
When [action]
Then [outcome]
```

Example:
```gherkin
Given user is logged in
When user clicks "Dark Mode" toggle in settings
Then dashboard switches to dark theme
And preference is saved to user profile
```

## Quality Gates

### Triage → Plan
```
✅ Type assigned
✅ WorkType assigned
✅ Urgency assigned
✅ Impact assigned
✅ Template matched
✅ Queue assigned
```

### Plan → Design
```
✅ Sized within bounds
✅ Acceptance criteria added (stories)
✅ Effort estimates added (tasks)
✅ Parent/child relationships set
```

### Design → Deliver
```
✅ ADR created (if architectural decision)
✅ Implementation plan created
✅ Test plan created
✅ Solution option selected with rationale
```

### Deliver → Done
```
✅ Code implemented
✅ Tests written and passing
✅ Coverage ≥80%
✅ Acceptance criteria met 100%
✅ Quality score ≥80
✅ Implementation doc created
```

## Quality Score Formula

```
Score = (40% × Criteria Met) +
        (30% × Tests Passing) +
        (20% × Coverage) +
        (10% × Lint Pass)
```

Must achieve ≥80 to pass quality gate.

## Priority Score Formula

```
Score = (40% × Impact) +
        (40% × Urgency) +
        (20% × Age)
```

Higher score = higher priority.

## Session Log Format

```markdown
# Session: ses-20241207-103000

## Run: run-20241207-103015-triage

- Stage: triage
- WorkItems: [TW-12345]
- Status: success
- Actions:
  - [10:30:15] fetch: Retrieved task from Teamwork
  - [10:30:18] categorize: Detected support request
  - [10:30:20] assign_template: support/generic
  - [10:30:22] route: Added to todo queue
- Metrics:
  - Duration: 7s
  - TokensIn: 2500
  - TokensOut: 800
  - ToolCalls: 4
```

## Troubleshooting

### Template not found
```bash
cat ~/.claude/templates/registry.json | grep <template-name>
```

### Queue empty
```bash
cat ~/.claude/session/queues.json
# If missing, run /workflow:triage on a task first
```

### Agent not loading
```bash
ls ~/.claude/agents/<agent-name>.md
# Verify file exists
```

### Session log not updating
```bash
ls ~/.claude/session/session-log.md
# Verify session directory exists
```

## Tips

### Keyboard Shortcuts in Claude Code
```
/                         # Open command palette (type command name)
Ctrl+L                    # Clear conversation
Ctrl+K                    # Search files
```

### Batch Operations
```bash
# Triage multiple items
/workflow:triage TW-1, TW-2, TW-3

# Plan multiple items
/workflow:plan TW-10, TW-11, TW-12
```

### Template Versioning
```json
{
  "processTemplate": "product/story/v1.0.0"  // Pin to version
}
```
or
```json
{
  "processTemplate": "product/story/latest"  // Use latest
}
```

### Custom Templates
1. Create JSON in `~/.claude/templates/<category>/<name>.json`
2. Add to `~/.claude/templates/registry.json`
3. Reference in work items

### Session Continuity
- Session ID persists across commands
- `/clear` starts new session
- Active work saved in `active-work.md`

---

## Legend

```
<id>                      # Work item identifier (TW-123, GH-owner/repo#45, etc.)
<queue>                   # Queue name (immediate, todo, backlog, icebox)
✅                        # Required
[...]                     # Optional
→                         # Results in
```

---

*Last Updated: 2024-12-07*

**Quick Links**:
- [Full Guide](work-system-guide.md)
- [Core Spec](work-system.md)
- [Agent Development](sub-agents-guide.md)
- [Repo Setup](repo-setup-guide.md)
