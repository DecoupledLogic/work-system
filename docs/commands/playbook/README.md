# Playbook Commands

Manage and validate the agent playbook (`.claude/agent-playbook.yaml`).

## Commands

| Command | Description |
|---------|-------------|
| `/playbook:validate-playbook` | Validate against schema, check for issues |
| `/playbook:check-playbook-conflicts` | Detect contradictions between rules |
| `/playbook:playbook-stats` | View usage statistics and effectiveness |
| `/playbook:pattern-report` | Pattern effectiveness dashboard |
| `/playbook:pattern-evolve` | Suggest automated improvements |
| `/playbook:pattern-merge` | Detect and merge similar patterns |
| `/playbook:import-patterns` | Import patterns from external sources |
| `/playbook:export-patterns` | Export patterns for sharing |
| `/playbook:track-pattern-detection` | Record pattern detection events |

## Quick Examples

```bash
# Validate playbook
/playbook:validate-playbook
/playbook:validate-playbook --fix

# Check for issues
/playbook:check-playbook-conflicts

# View statistics
/playbook:playbook-stats
/playbook:playbook-stats --layer backend --sort effectiveness
```

## Typical Workflow

```bash
# After extracting PR feedback
/quality:extract-review-patterns
/playbook:validate-playbook
/playbook:check-playbook-conflicts

# Periodic review
/playbook:playbook-stats --period 30d
```

See source commands in [commands/playbook/](../../../commands/playbook/) for full documentation.
