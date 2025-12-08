# Documentation

Comprehensive documentation for the Claude Code Work System, including guides, specifications, and architectural decision records.

## Overview

This directory contains all documentation needed to understand, configure, and extend the work system.

## Directory Structure

```
docs/
├── README.md                           # This file
├── adrs/                               # Architecture Decision Records
├── documentation-summary.md            # Overview of all documentation
├── domain-commands-guide.md            # Comprehensive domain command reference
├── programming-in-natural-language.md  # Philosophy and design principles
├── quick-reference.md                  # Command and workflow cheat sheet
├── repo-setup-guide.md                 # Repository configuration guide
├── sub-agents-guide.md                 # Guide to creating sub-agents
├── work-system.md                      # Core specification
├── work-system-guide.md                # User guide and tutorials
├── work-system-implementation-plan.md  # Phased implementation roadmap
└── work-system-readme.md               # Work system overview
```

## Documentation Categories

### Domain Architecture

| Document | Purpose |
|----------|---------|
| [programming-in-natural-language.md](programming-in-natural-language.md) | Philosophy and design principles |
| [domain-commands-guide.md](domain-commands-guide.md) | Comprehensive domain command reference |
| [Schema Directory](../schema/) | Domain object schemas and aggregates |
| [Domain Commands](../commands/domain/) | Aggregate command implementations |

### Core Specification

| Document | Purpose |
|----------|---------|
| [work-system.md](work-system.md) | Authoritative specification for the work system |
| [work-system-readme.md](work-system-readme.md) | High-level overview and concepts |
| [work-system-guide.md](work-system-guide.md) | Detailed user guide with examples |

### Implementation

| Document | Purpose |
|----------|---------|
| [work-system-implementation-plan.md](work-system-implementation-plan.md) | Phased rollout plan |
| [repo-setup-guide.md](repo-setup-guide.md) | How to configure repositories |
| [sub-agents-guide.md](sub-agents-guide.md) | Creating and using sub-agents |

### Reference

| Document | Purpose |
|----------|---------|
| [quick-reference.md](quick-reference.md) | Commands, schemas, workflows |
| [documentation-summary.md](documentation-summary.md) | Index of all documentation |

### Architecture Decision Records

The `adrs/` subdirectory contains records of significant architecture decisions:

```
adrs/
├── 001-queue-based-prioritization.md
├── 002-template-driven-workflows.md
└── ...
```

## Reading Order

For new users:

1. [programming-in-natural-language.md](programming-in-natural-language.md) - Understand the philosophy
2. [domain-commands-guide.md](domain-commands-guide.md) - Learn the commands
3. [quick-reference.md](quick-reference.md) - Quick command lookup

For developers:

1. [Schema Directory](../schema/) - Domain model and aggregates
2. [work-system.md](work-system.md) - Full specification
3. [sub-agents-guide.md](sub-agents-guide.md) - Agent development

For architects:

1. [programming-in-natural-language.md](programming-in-natural-language.md) - Design principles
2. [Schema Directory](../schema/aggregates.md) - Aggregate patterns
3. [work-system-implementation-plan.md](work-system-implementation-plan.md) - Roadmap

## Document Conventions

### Version Tracking

Documents include version info at the bottom:
```markdown
---
*Last Updated: 2024-12-07*
```

### Cross-References

Documents link to related files:
```markdown
## Related Files
- [agents/](../agents/) - Agent definitions
- [templates/](../templates/) - Process templates
```

### Code Examples

Examples use fenced code blocks with language:
```json
{
  "example": "configuration"
}
```

## Contributing

When updating documentation:
1. Keep documents focused and concise
2. Update cross-references when moving files
3. Update the last modified date
4. Add entries to documentation-summary.md for new docs

## Related Directories

- [agents/](../agents/) - Sub-agent definitions
- [commands/](../commands/) - Slash command implementations
- [templates/](../templates/) - Process templates
- [session/](../session/) - Session state and logs

---

*Last Updated: 2024-12-07*
