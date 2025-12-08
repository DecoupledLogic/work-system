# Work System Agents

Specialized Claude Code sub-agents that handle specific stages and functions within the work system. Each agent runs in isolated context and returns structured output.

## Overview

Agents are the "workers" of the work system. They receive structured input, perform specific tasks, and return structured output. This isolation keeps the main conversation context lean while enabling complex workflows.

## Directory Structure

```
agents/
├── README.md                 # This file
├── design-agent.md           # Solution exploration and architecture decisions
├── dev-agent.md              # TDD implementation agent
├── eval-agent.md             # Delivery evaluation against acceptance criteria
├── plan-agent.md             # Work decomposition and sizing
├── qa-agent.md               # Test generation and quality validation
├── session-logger.md         # Activity logging and metrics capture
├── task-fetcher.md           # Teamwork API orchestration
├── task-selector.md          # Task display and selection
├── template-validator.md     # Template compliance validation
├── triage-agent.md           # Work categorization and routing
└── work-item-mapper.md       # External data normalization
```

## Agent Categories

### Stage Agents

Core agents that implement work system stages:

| Agent | Stage | Purpose |
|-------|-------|---------|
| `triage-agent` | Triage | Categorize work, assign templates, route to queues |
| `plan-agent` | Plan | Decompose work, size tasks, elaborate criteria |
| `design-agent` | Design | Explore solutions, make architecture decisions |
| `dev-agent` | Deliver | Implement code following TDD practices |
| `qa-agent` | Deliver | Generate tests, validate quality |
| `eval-agent` | Eval | Compare plan vs actual, capture learnings |

### Utility Agents

Supporting agents for common operations:

| Agent | Purpose |
|-------|---------|
| `task-fetcher` | Fetch and enrich tasks from Teamwork API |
| `task-selector` | Display and select from task lists |
| `work-item-mapper` | Transform external data to WorkItem schema |
| `template-validator` | Validate work items against templates |
| `session-logger` | Log activity with timestamps and metrics |

## Agent Structure

Each agent markdown file contains:

1. **Purpose** - What the agent does
2. **Input** - Expected input format (usually JSON)
3. **Output** - Returned data format
4. **Process** - Step-by-step logic
5. **Tools** - Which tools the agent can use
6. **Examples** - Sample inputs and outputs

## Using Agents

### From Commands

Commands invoke agents via the Task tool:

```markdown
Task tool → agent
  Input: { structured input }
  Output: { structured output }
```

### From Other Agents

Agents can invoke other agents for sub-tasks:

```markdown
design-agent
  → Task tool → plan-agent (for decomposition)
  → Task tool → template-validator (for validation)
```

### Model Selection

Agents specify appropriate models:
- **Haiku** - Simple tasks, API calls, formatting
- **Sonnet** - Complex reasoning, code generation
- **Opus** - Deep analysis, architecture decisions

## Agent Development

### Creating New Agents

1. Define clear purpose and boundaries
2. Specify input/output contracts
3. Document the process steps
4. List required tools
5. Include examples
6. Register in work system

### Best Practices

- Keep agents focused (single responsibility)
- Use structured JSON for input/output
- Document edge cases and error handling
- Include validation examples
- Prefer composition over complexity

## Integration with Work System

Agents connect to:
- **Commands** - Slash commands invoke agents
- **Templates** - Agents follow template requirements
- **Queues** - Triage agent routes to queues
- **Session** - Session logger tracks activity
- **Teamwork** - Task agents interact with external API

## Related Files

- [work-system.md](../docs/work-system.md) - Full specification
- [sub-agents-guide.md](../docs/sub-agents-guide.md) - Agent patterns
- [commands/](../commands/) - Commands that use agents

---

*Last Updated: 2024-12-07*
