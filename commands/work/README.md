# Work System Commands

This directory contains commands for initializing and managing the work system infrastructure.

## Purpose

Work system commands set up and monitor the foundational components that power the work-system: architecture analysis, playbook configuration, queue management, and integration settings.

## Commands

### `/work:init`
Initialize or update the work system for a repository. Runs architecture analysis, sets up agent playbook, and configures work item tracking.

**Usage:**
```bash
/work:init
/work:init --refresh
```

**What it does:**
1. Runs architecture review (`/quality:architecture-review`)
2. Generates `.claude/architecture.yaml`
3. Generates `.claude/agent-playbook.yaml`
4. Sets up work item configuration
5. Initializes queue system
6. Validates configuration files

**When to run:**
- First time setting up work-system in a repo
- After significant architecture changes
- When playbook becomes stale
- Periodic refresh (monthly recommended)

### `/work:status`
Display work system implementation progress and status. Shows configuration state, recent activity, and system health.

**Usage:**
```bash
/work:status
/work:status --verbose
```

**Information shown:**
- Work system version
- Configuration files status
- Architecture review date
- Playbook metrics (rules, patterns, effectiveness)
- Queue statistics
- Recent work item activity
- Integration health (Teamwork, Azure DevOps, GitHub)

## Work System Configuration

The work system uses these configuration files:

```
.claude/
├── architecture.yaml        # Architecture documentation and guardrails
├── agent-playbook.yaml      # Coding patterns and best practices
└── work-system.yaml         # Work item tracking configuration
```

### architecture.yaml

Contains:
- Tech stack information
- Architecture patterns
- Layer definitions
- Guardrails and rules
- Recommendations

### agent-playbook.yaml

Contains:
- Coding patterns from PR feedback
- Best practices
- Common mistakes to avoid
- Pattern effectiveness metrics

### work-system.yaml

Contains:
- Work item platform configuration (Teamwork, ADO, GitHub)
- Queue definitions
- Stage templates
- Integration settings

## Best Practices

1. **Run /work:init first** - Before using any workflow commands
2. **Refresh periodically** - Architecture changes require playbook updates
3. **Monitor /work:status** - Check system health regularly
4. **Keep playbooks current** - Use `/playbook:*` commands to maintain accuracy

## Integration

Work system commands integrate with:
- **Architecture Review** (`/quality:architecture-review`) - Core analysis engine
- **Playbook** (`/playbook:*`) - Pattern management
- **Domain** (`/domain:*`) - Work item abstractions
- **Workflow** (`/workflow:*`) - Depend on work system initialization
