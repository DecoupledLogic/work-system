# Workflow Commands

Stage orchestration for moving work items through the work system.

## Stage Flow

```
Select → Triage → Plan → Design → Deliver
```

## Commands

| Command | Description |
|---------|-------------|
| `/workflow:select-task` | Select new work from assigned tasks |
| `/workflow:resume` | Resume in-progress tasks |
| `/workflow:triage` | Categorize, assign template, route to queue |
| `/workflow:plan` | Decompose, size, add acceptance criteria |
| `/workflow:design` | Explore solutions, create ADRs, implementation plans |
| `/workflow:deliver` | Implement (TDD), test, evaluate, complete |
| `/workflow:queue` | View work items by urgency queue |
| `/workflow:route` | Move items between queues |

## Quick Examples

```bash
# Start new work
/workflow:select-task
/workflow:triage TW-12345

# Move through stages
/workflow:plan WI-001
/workflow:design WI-001
/workflow:deliver WI-001

# Queue management
/workflow:queue todo
/workflow:route TW-12345 immediate --reason "Customer escalation"
```

## Configuration

Requires:
- `~/.claude/teamwork.json` - User identity
- `.claude/settings.json` - Project settings

See source commands in [commands/workflow/](../../../commands/workflow/) for full documentation.
