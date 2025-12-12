# Work System Commands

This directory contains slash commands for the work-system - a comprehensive framework for managing work items across platforms with AI-powered automation.

## Command Categories

| Category | Description | Documentation |
|----------|-------------|---------------|
| **Workflow** | Work system stage commands | [workflow/README.md](workflow/README.md) |
| **Quality** | Code review and analysis | [quality/README.md](quality/README.md) |
| **Recommendations** | Architecture recommendation management | [recommendations/README.md](recommendations/README.md) |
| **Work** | Work system management | [work/README.md](work/README.md) |
| **Docs** | Documentation generation | [docs/README.md](docs/README.md) |
| **Delivery** | Story delivery automation | [delivery/README.md](delivery/README.md) |
| **.NET** | Build, test, restore automation | [dotnet/README.md](dotnet/README.md) |
| **Playbook** | Agent playbook management | [playbook/README.md](playbook/README.md) |
| **Git** | Git operations | [git/README.md](git/README.md) |
| **Teamwork** | Teamwork API commands | [teamwork/README.md](teamwork/README.md) |
| **Azure DevOps** | Azure DevOps commands (20 total, 3 new PR thread commands) | [azuredevops/README.md](azuredevops/README.md) |
| **GitHub** | GitHub CLI helpers (18 total, 5 new PR commands) | [github/README.md](github/README.md) |
| **Domain** | Work item queries | [domain/README.md](domain/README.md) |

## Quick Start

### 1. Initialize Work System

Before using workflow commands, initialize the work system in your repository:

```bash
/work:init
```

This will:
- Run architecture analysis
- Generate `.claude/architecture.yaml`
- Generate `.claude/agent-playbook.yaml`
- Set up work item configuration

### 2. Select Work

Choose new work to start:

```bash
/workflow:select-task
```

Or resume in-progress work:

```bash
/workflow:resume
```

### 3. Execute Workflow

Follow the work system stages:

```bash
/workflow:triage     # Categorize and route work
/workflow:plan       # Break down and estimate
/workflow:design     # Create solution architecture
/workflow:deliver    # Implement and test
```

## Work System Stages

The work-system follows a structured workflow:

```
Select → Triage → Plan → Design → Deliver → Eval
```

**Select**: Choose work from your assigned tasks or queues
- `/workflow:select-task` - Select new work
- `/workflow:resume` - Resume in-progress work

**Triage**: Categorize, assess, and route work items
- `/workflow:triage` - Categorize and assign process template
- `/workflow:route` - Move between urgency queues

**Plan**: Decompose work into implementable pieces
- `/workflow:plan` - Break down work, size estimates

**Design**: Create solution architecture and decisions
- `/workflow:design` - Explore options, make decisions, generate plans

**Deliver**: Implement, test, and evaluate the solution
- `/workflow:deliver` - Coordinate implementation pipeline
- `/quality:code-review` - Deep code review
- `/delivery:log-start` - Log story start
- `/delivery:log-complete` - Log story completion with metrics

## Command Namespaces

All commands use a `category:command` namespace format for organization:

| Namespace | Purpose | Examples |
|-----------|---------|----------|
| `workflow:*` | Stage orchestration | `/workflow:deliver`, `/workflow:plan` |
| `quality:*` | Code quality | `/quality:code-review`, `/quality:architecture-review` |
| `recommendations:*` | Architecture rules | `/recommendations:list`, `/recommendations:disable` |
| `work:*` | System setup | `/work:init`, `/work:status` |
| `docs:*` | Documentation | `/docs:write` |
| `delivery:*` | Story metrics | `/delivery:log-start`, `/delivery:log-complete` |
| `dotnet:*` | .NET automation | `/dotnet:test`, `/dotnet:build` |
| `playbook:*` | Pattern management | `/playbook:validate`, `/playbook:stats` |
| `git:*` | Git operations | `/git:status`, `/git:commit` |
| `teamwork:*` | Teamwork API | `/teamwork:tw-get-task` |
| `azuredevops:*` | Azure DevOps | `/azuredevops:ado-get-pr` |
| `github:*` | GitHub | `/github:gh-create-pr` |
| `domain:*` | Work item abstraction | `/domain:work-item`, `/domain:agent` |

## Architecture

### Context-Efficient Agent-Based Design

Commands use specialized sub-agents to minimize context overhead:

**Benefits:**
- ✅ **Context Efficiency**: Main session sees only orchestration + output (~500 bytes)
- ✅ **Reusability**: Agents can be called by multiple commands
- ✅ **Maintainability**: Single source of truth for business logic
- ✅ **Composability**: Easy to create new commands
- ✅ **Testability**: Clear input/output contracts

**Example Flow:**
```
/workflow:deliver → dev-agent → qa-agent → eval-agent
                      ↓            ↓           ↓
                    Code       Tests      Results
```

### Domain Aggregates

Work items are managed through domain aggregates for consistent state:

```bash
/domain:work-item get <id>           # Fetch work item
/domain:work-item update <id>        # Update work item
/domain:work-item transition <id>    # Move to next stage
/domain:work-item comment <id>       # Add comment (auto-syncs)
```

All workflow commands use these aggregates to ensure:
- Consistent state management
- Cross-platform sync (Teamwork ↔ Azure DevOps ↔ GitHub)
- Audit trail and history
- Validation and business rules

## Configuration

### Global Configuration

**`~/.claude/teamwork.json`** - User identity for task filtering
```json
{
  "user": {
    "email": "your.email@company.com",
    "name": "Your Name",
    "id": "123456"
  }
}
```

### Repository Configuration

**`<repo>/.claude/settings.json`** - Project-specific settings
```json
{
  "teamwork": {
    "projectId": "999999",
    "projectName": "Production Support",
    "clientName": "ACME Corp"
  }
}
```

**`<repo>/.claude/architecture.yaml`** - Architecture documentation (generated by `/work:init`)
**`<repo>/.claude/agent-playbook.yaml`** - Coding patterns (generated by `/work:init`)

## Key Features

### Code Quality

- **Architecture Review** - Analyze codebase and generate guardrails
- **Code Review** - Deep review against Clean Architecture patterns
- **Pattern Learning** - Extract patterns from PR feedback
- **Recommendation Management** - Enable/disable architecture rules

### Delivery Automation

- **Delivery Logging** - Track story metrics (lead time, cycle time)
- **.NET Integration** - Automated build, test, restore
- **Git Operations** - Streamlined git workflow
- **PR Management** - Azure DevOps and GitHub PR automation

### Work Management

- **Cross-Platform** - Unified interface for Teamwork, Azure DevOps, GitHub
- **Queue-Based** - Urgency queues (immediate, todo, backlog, icebox)
- **Stage-Based** - Clear workflow progression
- **Agent-Powered** - AI agents for each stage

## Common Workflows

### Start New Work
```bash
/workflow:select-task        # Choose task
/workflow:triage             # Categorize if needed
/workflow:plan               # Break down work
/workflow:design             # Create solution
/workflow:deliver            # Implement
```

### Code Review Before PR
```bash
/quality:code-review         # Review your changes
/quality:architecture-review # Check against guardrails
/playbook:validate           # Validate against playbook
```

### Complete Story
```bash
/delivery:log-start          # Log story start
# ... do work ...
/dotnet:test                 # Run tests
/dotnet:build                # Build solution
/delivery:log-complete       # Log completion with metrics
```

### Manage Recommendations
```bash
/recommendations:list        # View all recommendations
/recommendations:view ARCH-G001  # View specific recommendation
/recommendations:disable ARCH-G001 --reason "Legacy migration"
/recommendations:stats       # View effectiveness metrics
```

## Integration

### Teamwork
- Fetch tasks and subtasks
- Update task status
- Post comments and time logs
- Auto-sync work item state

### Azure DevOps
- Create and manage PRs
- Comment on threads
- Update work items
- Query work item states

### GitHub
- Create and manage PRs
- Review and comment
- Manage issues
- Track dependencies

## Documentation

Each command category has detailed documentation:

- **[Workflow Commands](workflow/README.md)** - Stage orchestration
- **[Quality Commands](quality/README.md)** - Code review and analysis
- **[Recommendation Commands](recommendations/README.md)** - Architecture rules
- **[Work System Commands](work/README.md)** - System setup
- **[Documentation Commands](docs/README.md)** - Doc generation
- **[Delivery Commands](delivery/README.md)** - Story metrics
- **[.NET Commands](dotnet/README.md)** - Build/test automation
- **[Playbook Commands](playbook/README.md)** - Pattern management
- **[Git Commands](git/README.md)** - Git operations
- **[Teamwork Commands](teamwork/README.md)** - Teamwork API
- **[Azure DevOps Commands](azuredevops/README.md)** - Azure DevOps API
- **[GitHub Commands](github/README.md)** - GitHub CLI
- **[Domain Commands](domain/README.md)** - Work item queries

## Getting Help

### Check System Status
```bash
/work:status                 # View work system health
```

### View Recommendations
```bash
/recommendations:list        # List all architecture rules
/playbook:stats              # View playbook metrics
```

### Command Documentation
See the README.md file in each category directory for detailed command documentation.

## License

Part of the work-system framework. Customize to fit your team's workflow needs.
