# Playbook Commands

This directory contains commands for managing and validating the agent playbook (`.claude/agent-playbook.yaml`).

## Purpose

The agent playbook defines how AI coding agents should implement code changes while following architecture patterns and learned best practices from PR feedback. These commands help ensure playbook quality and track effectiveness.

## Commands

### `/validate-playbook`
Validates the agent-playbook.yaml file against its JSON schema and checks for common issues:
- Schema validation
- ID format and uniqueness
- Required field presence
- PR source reference validation
- Metadata coverage tracking
- Auto-fix mode with `--fix` flag

**Usage:**
```bash
/validate-playbook                    # Validate default playbook
/validate-playbook --file <path>      # Validate specific file
/validate-playbook --strict           # Enable strict validation
/validate-playbook --fix              # Auto-fix common issues
```

### `/check-playbook-conflicts`
Detects conflicts and contradictions between playbook rules:
- Contradictory guardrails
- Overlapping patterns
- Conflicting hygiene rules
- Layer boundary violations
- Source conflicts (architecture-review vs pr-feedback)

**Usage:**
```bash
/check-playbook-conflicts                 # Check default playbook
/check-playbook-conflicts --file <path>   # Check specific playbook
/check-playbook-conflicts --verbose       # Show detailed analysis
```

### `/playbook-stats`
Analyzes usage patterns and effectiveness metrics:
- Rule application frequency
- Effectiveness ratings
- False positive rates
- Source distribution
- Confidence level tracking
- Top/underutilized rules

**Usage:**
```bash
/playbook-stats                          # Show all statistics
/playbook-stats --layer backend          # Filter by layer
/playbook-stats --type guardrails        # Filter by type
/playbook-stats --source pr-feedback     # Filter by source
/playbook-stats --sort effectiveness     # Sort by effectiveness
/playbook-stats --period 30d             # Stats for last 30 days
```

## Workflow Integration

### After Extracting PR Feedback
```bash
/extract-review-patterns <pr-url>
/validate-playbook
/check-playbook-conflicts
```

### Before Delivery
```bash
/validate-playbook
/deliver WI-12345
```

### Periodic Review
```bash
/playbook-stats --period 30d
/check-playbook-conflicts
```

## Related Files

- **Schema:** `/home/cbryant/projects/work-system/docs/schemas/agent-playbook.schema.json`
- **Template:** `/home/cbryant/projects/work-system/docs/templates/agent-playbook.yaml`
- **Dev Agent:** `/home/cbryant/projects/work-system/agents/dev-agent.md`

## PR Feedback Learning Loop

These commands are part of the PR Feedback Learning Loop system that:
1. Extracts patterns from PR code reviews
2. Classifies them as guardrails/leverage/hygiene
3. Stores them in the playbook with source attribution
4. Tracks effectiveness through metadata
5. Evolves rules based on actual usage

See `/home/cbryant/projects/work-system/docs/plans/pr-feedback-learning-implementation.md` for the full implementation plan.
