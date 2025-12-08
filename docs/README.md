# Documentation

Comprehensive documentation for the Claude Code Work System, including guides, specifications, and architectural decision records.

## Directory Structure

```text
docs/
├── README.md                    # This file
├── adrs/                        # Architecture Decision Records
│   ├── 0001-work-manager-abstraction.md
│   ├── 0002-local-first-session-state.md
│   ├── 0003-stage-based-workflow.md
│   └── 0004-architecture-aware-agents.md
├── agents/                      # Agent methodology and prompts
│   ├── architecture-review-agent.md
│   ├── architecture-agents-prompts.md
│   ├── document-writer-agent.md
│   ├── document-writer-prompts.md
│   └── sub-agents-guide.md
├── core/                        # Core work system documentation
│   ├── work-system.md           # Authoritative specification
│   ├── work-system-guide.md     # User guide and tutorials
│   └── work-system-readme.md    # High-level overview
├── reference/                   # Reference and standards
│   ├── markdown-standards.md    # Markdown linting rules
│   ├── quick-reference.md       # Command cheat sheet
│   └── domain-commands-guide.md # Domain command reference
├── plans/                       # Implementation plans
│   └── work-system-implementation-plan.md
├── concepts/                    # Conceptual documentation
│   ├── programming-in-natural-language.md
│   └── documentation-summary.md
└── templates/                   # Templates for agents
    ├── architecture.yaml
    ├── agent-playbook.yaml
    ├── README.md
    └── documents/               # Document templates (PRD, Spec, etc.)
```

## Documentation Categories

### Core Specification

| Document | Purpose |
|----------|---------|
| [work-system.md](core/work-system.md) | Authoritative specification |
| [work-system-readme.md](core/work-system-readme.md) | High-level overview |
| [work-system-guide.md](core/work-system-guide.md) | Detailed user guide |

### Agent Documentation

| Document | Purpose |
|----------|---------|
| [architecture-review-agent.md](agents/architecture-review-agent.md) | 3-pass codebase analysis methodology |
| [architecture-agents-prompts.md](agents/architecture-agents-prompts.md) | System prompts for architecture agents |
| [document-writer-agent.md](agents/document-writer-agent.md) | Template-driven document generation |
| [document-writer-prompts.md](agents/document-writer-prompts.md) | System prompts for document writer |
| [sub-agents-guide.md](agents/sub-agents-guide.md) | Guide to creating sub-agents |

### Reference

| Document | Purpose |
|----------|---------|
| [quick-reference.md](reference/quick-reference.md) | Command and workflow cheat sheet |
| [markdown-standards.md](reference/markdown-standards.md) | Linting rules for documentation |
| [domain-commands-guide.md](reference/domain-commands-guide.md) | Domain command reference |

### Concepts

| Document | Purpose |
|----------|---------|
| [programming-in-natural-language.md](concepts/programming-in-natural-language.md) | Philosophy and design principles |
| [documentation-summary.md](concepts/documentation-summary.md) | Index of all documentation |

### Plans

| Document | Purpose |
|----------|---------|
| [work-system-implementation-plan.md](plans/work-system-implementation-plan.md) | Phased rollout plan |

### Architecture Decision Records

| ADR | Title |
|-----|-------|
| [0001](adrs/0001-work-manager-abstraction.md) | Work Manager Abstraction Layer |
| [0002](adrs/0002-local-first-session-state.md) | Local-First Session State |
| [0003](adrs/0003-stage-based-workflow.md) | Stage-Based Workflow with Sub-Agents |
| [0004](adrs/0004-architecture-aware-agents.md) | Architecture-Aware Agent System |

## Reading Order

### For New Users

1. [core/work-system-readme.md](core/work-system-readme.md) - Overview
2. [reference/quick-reference.md](reference/quick-reference.md) - Commands
3. [core/work-system-guide.md](core/work-system-guide.md) - Tutorials

### For Developers

1. [Schema Directory](../schema/) - Domain models
2. [core/work-system.md](core/work-system.md) - Full specification
3. [agents/sub-agents-guide.md](agents/sub-agents-guide.md) - Agent development

### For Architects

1. [concepts/programming-in-natural-language.md](concepts/programming-in-natural-language.md) - Design philosophy
2. [adrs/](adrs/) - Decision records
3. [agents/architecture-review-agent.md](agents/architecture-review-agent.md) - Architecture methodology

## Related Directories

- [agents/](../agents/) - Agent definitions (executable)
- [commands/](../commands/) - Slash command implementations
- [schema/](../schema/) - Domain object schemas
- [templates/](../templates/) - Process templates

---

*Last Updated: 2024-12-08*
