# Agent Reference

This directory contains documentation for all AI sub-agents in the AgenticOps Work System.

## Agent Overview

| Agent | Model | Stage | Purpose |
|-------|-------|-------|---------|
| [triage-agent](triage-agent.md) | sonnet | Triage | Categorize work items, assign templates, route to queues |
| [plan-agent](plan-agent.md) | sonnet | Plan | Decompose, size, and elaborate work items |
| [design-agent](design-agent.md) | sonnet | Design | Explore solutions, make architecture decisions |
| [dev-agent](dev-agent.md) | sonnet | Deliver | Implement code changes following TDD |
| [qa-agent](qa-agent.md) | haiku | Deliver | Generate and execute tests, validate quality |
| [eval-agent](eval-agent.md) | sonnet | Deliver | Evaluate delivered work, capture learnings |
| [story-delivery-agent](story-delivery-agent.md) | sonnet | Deliver | Orchestrate end-to-end story delivery |

## Supporting Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| [task-fetcher](task-fetcher.md) | haiku | Fetch tasks from Teamwork with pagination |
| [task-selector](task-selector.md) | haiku | Display and facilitate task selection |
| [work-item-mapper](work-item-mapper.md) | haiku | Transform external data to WorkItem schema |
| [template-validator](template-validator.md) | haiku | Validate work items against templates |
| [session-logger](session-logger.md) | haiku | Capture structured activity logs |
| [document-writer](document-writer.md) | sonnet | Generate lint-safe markdown documents |
| [architecture-review](architecture-review.md) | sonnet | Analyze codebase architecture |

## Agent Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        WORKFLOW STAGES                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  SELECT        TRIAGE        PLAN          DESIGN        DELIVER    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐ │
│  │ task-    │  │ triage-  │  │ plan-    │  │ design-  │  │ dev-   │ │
│  │ fetcher  │→ │ agent    │→ │ agent    │→ │ agent    │→ │ agent  │ │
│  │          │  │          │  │          │  │          │  │        │ │
│  │ task-    │  │ work-    │  │          │  │          │  │ qa-    │ │
│  │ selector │  │ item-    │  │          │  │          │  │ agent  │ │
│  │          │  │ mapper   │  │          │  │          │  │        │ │
│  │          │  │          │  │          │  │          │  │ eval-  │ │
│  │          │  │ template-│  │          │  │          │  │ agent  │ │
│  │          │  │ validator│  │          │  │          │  │        │ │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └────────┘ │
│                                                                      │
├─────────────────────────────────────────────────────────────────────┤
│                     CROSS-CUTTING AGENTS                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐   │
│  │ session-     │  │ document-    │  │ architecture-review      │   │
│  │ logger       │  │ writer       │  │                          │   │
│  └──────────────┘  └──────────────┘  └──────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                   story-delivery-agent                        │   │
│  │         (Orchestrates full delivery workflow)                 │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Model Selection

Agents use different models based on task complexity:

| Model | Use Case | Agents |
|-------|----------|--------|
| **haiku** | Fast, rule-based tasks | task-fetcher, task-selector, work-item-mapper, template-validator, session-logger, qa-agent |
| **sonnet** | Complex reasoning, code generation | triage-agent, plan-agent, design-agent, dev-agent, eval-agent, document-writer, architecture-review, story-delivery-agent |

## Tool Access

Agents have restricted tool access based on their purpose:

| Tools | Agents |
|-------|--------|
| Read only | triage-agent, plan-agent, design-agent, eval-agent, work-item-mapper |
| Read, Write | session-logger |
| Read, Write, Edit | document-writer |
| Read, Glob, Grep | qa-agent |
| Read, Glob, Grep, Write | architecture-review |
| Full (Read, Edit, Write, Bash, Glob, Grep) | dev-agent |
| SlashCommand, Read | task-fetcher |
| Read, Write, Bash, SlashCommand | story-delivery-agent |

## Creating New Agents

See the [Sub-Agents Guide](sub-agents-guide.md) for detailed instructions on creating new agents.

Basic steps:

1. Create `agents/<name>.md` with YAML frontmatter
2. Define name, description, tools, and model
3. Write the system prompt with role, process, and output format
4. Register in commands if needed

## Related Documentation

- [Sub-Agents Guide](sub-agents-guide.md) - Detailed agent creation guide
- [Architecture Agents Prompts](architecture-agents-prompts.md) - Agent prompt patterns
- [Work System Overview](../reference/work-system.md) - Stage-based workflow
