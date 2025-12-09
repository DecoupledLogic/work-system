# AI-Powered Work System

An intelligent, stage-based work management system that leverages AI agents to guide work from intake through delivery with consistent quality and process adherence.

## Overview

This work system transforms how you manage tasks, features, bugs, and support requests by providing:

-   **AI-Powered Agents**: Specialized agents for triage, planning, design, and delivery
-   **Process Templates**: Reusable templates that ensure consistent quality across work types
-   **Stage-Based Workflow**: Structured progression through Triage → Plan → Design → Deliver
-   **Backend Agnostic**: Works with Teamwork, GitHub Issues, Linear, Jira, or local-only
-   **Queue Management**: Priority-based queues with local-first storage
-   **Analytics Ready**: Structured logging for process improvement

## Quick Start

### Installation

1.  **Prerequisites**:
    1.  [Claude Code](https://code.claude.com) installed and configured
    2.  (Optional) External work tracking account (Teamwork, GitHub, etc.)
2.  **Install the work system**:

```bash
cd ~/.claude
git clone <this-repo-url> work-system-temp

# Copy work system files
cp -r work-system-temp/agents/* ~/.claude/agents/
cp -r work-system-temp/commands/* ~/.claude/commands/
cp -r work-system-temp/templates/* ~/.claude/templates/
cp -r work-system-temp/docs/* ~/.claude/docs/
cp -r work-system-temp/work-managers/* ~/.claude/work-managers/
cp work-system-temp/*.md ~/.claude/
cp work-system-temp/session/.gitignore ~/.claude/session/

# Create session directory
mkdir -p ~/.claude/session
```

1.  **Configure** (if using external system):

```bash
# For Teamwork
cat > ~/.claude/work-manager.yaml <<EOF
manager: teamwork
teamwork:
  projectId: YOUR_PROJECT_ID
queues:
  storage: local
EOF
```

1.  **Verify installation**:

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

```
Intake → Triage → Plan → Design → Deliver
         ↓        ↓       ↓        ↓
      Categorize  Size  Decide   Build & Test
```

Each stage has:

-   Dedicated AI agents
-   Clear entry/exit criteria
-   Template-driven validation
-   Structured outputs

### Specialized AI Agents

| Agent            | Purpose                        | Model  |
|------------------|--------------------------------|--------|
| work-item-mapper | Normalize external tasks       | haiku  |
| triage-agent     | Categorize and route work      | sonnet |
| plan-agent       | Decompose and size work        | sonnet |
| design-agent     | Explore solutions, create ADRs | sonnet |
| dev-agent        | Implement with TDD             | sonnet |
| qa-agent         | Validate quality and coverage  | haiku  |
| eval-agent       | Evaluate outcomes              | sonnet |
| session-logger   | Capture activity logs          | haiku  |

### Process Templates

9 built-in templates covering:

**Support**:

-   Generic support request
-   Profile removal (GDPR/CCPA)
-   Subscription changes

**Product**:

-   Product Requirements Document (PRD)
-   Feature specifications
-   User stories (versioned)

**Delivery**:

-   Architecture Decision Records (ADR)
-   Bug fixes
-   Implementation plans

Create custom templates to fit your process.

### Backend Integrations

Works with your existing tools:

-   **Teamwork**: Full integration with tasks, comments, time tracking
-   **GitHub**: Issues, labels, PRs, commit linking
-   **Linear**: Issues, status, priorities
-   **Jira**: Issues, workflows, custom fields
-   **Local**: No external system required

### Queue Management

Four priority queues:

-   **Immediate** (critical): Same-day action required
-   **Todo** (now): Current work queue
-   **Backlog** (next): Next cycle planning
-   **Icebox** (future): Long-term ideas

Queues stored locally (no external system dependencies) with optional sync to labels/tags.

## Documentation

-   [work-system-guide.md](work-system-guide.md): Complete user guide
-   [work-system.md](work-system.md): Core specification
-   [work-system-implementation-plan.md](../plans/work-system-implementation-plan.md): Implementation history
-   [sub-agents-guide.md](../agents/sub-agents-guide.md): Agent development guide
-   [logging-guide.md](../../session/logging-guide.md): Session logging integration
-   [templates/README.md](../templates/README.md): Template system documentation
-   [adrs/](../adrs/): Architecture Decision Records

## Architecture

```
┌─────────────────────────────────────────┐
│          Slash Commands                 │
│  /triage /plan /design /deliver         │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│       Specialized AI Agents             │
│  triage  plan  design  dev  qa  eval    │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│     Work Manager Abstraction            │
│    (Normalizes to WorkItem schema)      │
└─────────────────────────────────────────┘
                  │
        ┌─────────┼─────────┐
        ▼         ▼         ▼
   Teamwork   GitHub    Linear
```

## Directory Structure

```
~/.claude/
├── agents/              # AI agents
├── commands/            # Slash commands
├── templates/           # Process templates
├── session/             # Session state (gitignored)
├── work-managers/       # Backend abstraction
└── docs/                # Documentation & ADRs
```

## Use Cases

### Product Development

-   Triage feature requests
-   Decompose epics into implementable stories
-   Design solutions with architectural decisions
-   Deliver with TDD and quality gates

### Support Operations

-   Standardize support workflows
-   Track GDPR/data removal requests
-   Ensure consistent resolution quality
-   Measure response times and outcomes

### Bug Management

-   Triage bugs by severity and impact
-   Root cause analysis with structured investigation
-   Track fixes with plan vs. actual metrics
-   Prevent regression with comprehensive testing

### Project Planning

-   Organize work by priority queues
-   Size and estimate work items
-   Track dependencies and blockers
-   Analyze velocity and throughput

## Contributing

We welcome contributions! See [work-system-guide.md](work-system-guide.md#contributing) for:

-   Adding new agents
-   Creating custom templates
-   Adding new stages
-   Integrating new work managers

## Examples

### Example 1: Triage Support Request

```bash
/triage TW-45678
```

**Agent analyzes**:

-   Detects: Support request for profile deletion
-   Matches template: `support/remove-profile`
-   Sets urgency: now, impact: medium
-   Routes to: `todo` queue

**Result**: Structured work item ready for delivery

### Example 2: Plan Feature

```bash
/plan TW-99001  # "Dark mode for dashboard"
```

**Agent decomposes**:

-   Creates stories:
    -   Toggle dark mode in settings
    -   Dashboard adapts to dark mode
    -   Preference persists across sessions
-   Adds Gherkin acceptance criteria
-   Creates child tasks in Teamwork

**Result**: Implementable stories with clear acceptance criteria

### Example 3: Design Solution

```bash
/design TW-99002  # "Toggle dark mode in settings"
```

**Agent explores**:

-   Option 1: CSS variables approach
-   Option 2: Theme library (styled-components)
-   Option 3: Tailwind dark mode utilities

**Agent decides**:

-   Selects Option 3 with rationale
-   Creates ADR documenting decision
-   Generates implementation tasks

**Result**: Clear path forward with documented reasoning

## Architecture Decision Records

Key architectural decisions are documented in <docs/adrs/>:

-   **ADR-0001**: Work Manager Abstraction
-   **ADR-0002**: Local-First Session State
-   **ADR-0003**: Stage-Based Workflow

## Version History

-   **v1.0.0** (2024-12-07): Initial release
    -   9 AI agents
    -   4-stage workflow
    -   9 process templates
    -   Multi-backend support
    -   Session logging

## Support

-   **Documentation**: See <work-system-guide.md>
-   **Issues**: [Create an issue](../../issues)
-   **Discussions**: [Join the discussion](../../discussions)

## License

[Specify your license]

**Built with ❤️ using** [Claude Code](https://code.claude.com)

🤖 Submitted by George with love ♥
