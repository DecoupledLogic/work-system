# AgenticOps Work System

An intelligent, stage-based, AgenticOps work management system that leverages AI agents to guide work from intake through delivery with consistent quality and process adherence.

## Overview

This work system transforms how you manage tasks, features, bugs, and support requests by providing:

- **AI-Powered Agents**: Specialized agents for triage, planning, design, and delivery
- **Process Templates**: Reusable templates that ensure consistent quality across work types
- **Stage-Based Workflow**: Structured progression through Triage → Plan → Design → Deliver
- **Backend Agnostic**: Works with Teamwork, GitHub Issues, Linear, Jira, or local-only
- **Queue Management**: Priority-based queues with local-first storage
- **Analytics Ready**: Structured logging for process improvement

## Quick Start

### Installation

1. **Prerequisites**:
   - [Claude Code](https://code.claude.com) installed and configured
   - (Optional) External work tracking account (Teamwork, GitHub, etc.)

2. **Clone and install**:

   ```bash
   git clone https://github.com/yourname/work-system.git ~/projects/work-system
   cd ~/projects/work-system
   ./install.sh
   ```

3. **Configure** (if using external system):

   ```bash
   cat > ~/.claude/work-manager.yaml <<EOF
   manager: teamwork
   teamwork:
     projectId: YOUR_PROJECT_ID
   queues:
     storage: local
   EOF
   ```

4. **Verify installation**:

   ```bash
   # In Claude Code
   /work-status
   ```

### Your First Workflow

```bash
# 1. Select work from queue
/select-task

# 2. Triage incoming work
/triage TW-12345

# 3. Plan features (decompose into stories)
/plan TW-12345

# 4. Design solution (explore options, create ADR)
/design TW-12345

# 5. Deliver (implement, test, evaluate)
/deliver TW-12345
```

## Features

### Stage-Based Workflow

```markdown
Intake → Triage → Plan → Design → Deliver
         ↓        ↓       ↓        ↓
      Categorize  Size  Decide   Build & Test
```

Each stage has:

- Dedicated AI agents
- Clear entry/exit criteria
- Template-driven validation
- Structured outputs

### Specialized AI Agents

| Agent | Purpose | Model |
|-------|---------|-------|
| work-item-mapper | Normalize external tasks | haiku |
| triage-agent | Categorize and route work | sonnet |
| plan-agent | Decompose and size work | sonnet |
| design-agent | Explore solutions, create ADRs | sonnet |
| dev-agent | Implement with TDD | sonnet |
| qa-agent | Validate quality and coverage | haiku |
| eval-agent | Evaluate outcomes | sonnet |
| session-logger | Capture activity logs | haiku |

### Process Templates

9 built-in templates covering:

**Support**:

- Generic support request
- Profile removal (GDPR/CCPA)
- Subscription changes

**Product**:

- Product Requirements Document (PRD)
- Feature specifications
- User stories (versioned)

**Delivery**:

- Architecture Decision Records (ADR)
- Bug fixes
- Implementation plans

### Backend Integrations

Works with your existing tools:

- **Teamwork**: Full integration with tasks, comments, time tracking
- **GitHub**: Issues, labels, PRs, commit linking
- **Linear**: Issues, status, priorities
- **Jira**: Issues, workflows, custom fields
- **Local**: No external system required

### Queue Management

Four priority queues:

- **Immediate** (critical): Same-day action required
- **Todo** (now): Current work queue
- **Backlog** (next): Next cycle planning
- **Icebox** (future): Long-term ideas

## Documentation

- **[work-system-guide.md](docs/work-system-guide.md)**: Complete user guide
- **[work-system.md](docs/work-system.md)**: Core specification
- **[sub-agents-guide.md](docs/sub-agents-guide.md)**: Agent development guide
- **[templates/README.md](templates/README.md)**: Template system documentation
- **[docs/adrs/](docs/adrs/)**: Architecture Decision Records

## Directory Structure

```markdown
~/projects/work-system/
├── agents/              # AI agents
├── commands/            # Slash commands
├── templates/           # Process templates
├── session/             # Session state (ephemeral files gitignored)
├── work-managers/       # Backend abstraction
├── docs/                # Documentation & ADRs
├── install.sh           # Create symlinks to ~/.claude
└── uninstall.sh         # Remove symlinks
```

After installation, symlinks in `~/.claude/` point to this repository:

```markdown
~/.claude/agents/  →  ~/projects/work-system/agents/
~/.claude/commands/  →  ~/projects/work-system/commands/
...
```

Edit files in either location - changes appear in both.

## Contributing

1. Fork and clone
2. Run `./install.sh` to set up symlinks
3. Make changes
4. Test with `/work-status`
5. Submit PR

---

🤖 Submitted by George with love ♥
