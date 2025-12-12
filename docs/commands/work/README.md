# Work System Commands

Initialize and monitor the work system infrastructure.

## Commands

| Command | Description |
|---------|-------------|
| `/work:work-init` | Initialize work system for a repository |
| `/work:work-status` | Display system status and health |

## /work:work-init

Initialize or refresh work system configuration.

```bash
/work:init
/work:init --refresh
```

What it does:
1. Runs architecture review
2. Generates `.claude/architecture.yaml`
3. Generates `.claude/agent-playbook.yaml`
4. Sets up work item configuration
5. Initializes queue system

When to run:
- First time setup in a repo
- After significant architecture changes
- Periodic refresh (monthly)

## /work:work-status

Display system health and configuration status.

```bash
/work:status
/work:status --verbose
```

Shows:
- Configuration files status
- Architecture review date
- Playbook metrics
- Queue statistics
- Integration health

See source commands in [commands/work/](../../../commands/work/) for full documentation.
