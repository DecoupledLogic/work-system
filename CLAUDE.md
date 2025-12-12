# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AgenticOps Work System - An AI-powered, stage-based work management framework that guides work items from intake through delivery using specialized sub-agents, process templates, and queue-based prioritization. Backend agnostic (Teamwork, GitHub, Linear, Jira, or local-only).

## Installation

```bash
./install.sh          # Create symlinks from ~/.claude to this repo
./install.sh --check  # Verify installation status
```

## Core Architecture

### Stage-Based Workflow

```
Select → Triage → Plan → Design → Deliver
```

- **Select**: `/workflow:select-task`, `/workflow:resume`
- **Triage**: `/workflow:triage` - Categorize, assign template, route to queue
- **Plan**: `/workflow:plan` - Decompose epics→features→stories→tasks
- **Design**: `/workflow:design` - Explore solutions, create ADRs
- **Deliver**: `/workflow:deliver` - Implement (TDD), test, evaluate

### Agent System

Agents are markdown files in `agents/` with YAML frontmatter (name, description, tools, model). Each agent runs in isolated context with restricted tool access.

| Agent | Model | Purpose |
|-------|-------|---------|
| work-item-mapper | haiku | Normalize external tasks to WorkItem schema |
| triage-agent | sonnet | Categorize and route work |
| plan-agent | sonnet | Decompose and size work |
| design-agent | sonnet | Solution exploration, ADRs |
| dev-agent | sonnet | TDD implementation |
| qa-agent | haiku | Test execution and quality |
| eval-agent | sonnet | Evaluate against criteria |
| task-fetcher | haiku | Teamwork API orchestration |
| session-logger | haiku | Activity logging |

### Command Namespaces

```
workflow:*       - Stage orchestration
quality:*        - Code review and analysis
work:*           - System initialization
delivery:*       - Story metrics logging
dotnet:*         - .NET build/test automation
playbook:*       - Pattern management
git:*            - Git operations
teamwork:*       - Teamwork API helpers
azuredevops:*    - Azure DevOps API
github:*         - GitHub CLI helpers
domain:*         - Work item queries
recommendations:* - Architecture rules
docs:*           - Documentation generation
```

### Data Flow

1. External task → `work-item-mapper` → normalized WorkItem
2. WorkItem → stage agents process through stages
3. Agents follow assigned ProcessTemplate requirements
4. Session logger captures activity
5. Changes sync back to external system

### Key Schemas (`schema/`)

- **WorkItem**: Fundamental work unit (epic, feature, story, task, bug)
- **Project**: Container for related work items
- **Queue**: Urgency-based containers (immediate, todo, backlog, icebox)
- **ProcessTemplate**: Workflow definitions with stage requirements
- **Agent**: Entities that perform work (human, AI, automation)

### Directory Structure

```
agents/          - AI sub-agents (markdown + YAML frontmatter)
commands/        - Slash commands organized by namespace
templates/       - Process templates (JSON with validation rules)
schema/          - Domain schemas (WorkItem, Project, Queue, etc.)
work-managers/   - Backend abstraction layer
session/         - Ephemeral session state (gitignored)
docs/            - Documentation, ADRs, guides
```

## Configuration Files

- `~/.claude/teamwork.json` - User identity for task filtering
- `<repo>/.claude/settings.json` - Project-specific settings (projectId, etc.)
- `<repo>/.claude/architecture.yaml` - Generated architecture documentation
- `<repo>/.claude/agent-playbook.yaml` - Generated coding patterns

## Learning the System

**Start here**: `docs/getting-started.md` - End-to-end story delivery tutorial

Then: `docs/reference/quick-reference.md` for command cheat sheet

## Common Workflows

### Initialize Work System in a Repository
```bash
/work:init
```

### Start New Work
```bash
/workflow:select-task
/workflow:triage
/workflow:plan
/workflow:design
/workflow:deliver
```

### Code Quality
```bash
/quality:code-review
/quality:architecture-review
/playbook:validate
```

### Git Operations
```bash
/git:status
/git:commit
/git:push
/git:create-branch
```

## Creating New Agents

1. Create `agents/<name>.md` with YAML frontmatter:
   ```yaml
   ---
   name: agent-name
   description: When to invoke this agent
   tools: Read, Grep, Glob
   model: haiku
   ---
   ```
2. Write system prompt with role, process steps, output format
3. Register in `commands/index.yaml` if needed

## Creating New Commands

1. Create `commands/<namespace>/<name>.md`
2. Use YAML frontmatter for description
3. Reference agents via Task tool invocations
4. Follow namespace conventions

## Template System

Templates in `templates/` define:
- Required/recommended sections
- Expected outputs
- Validation rules
- Stage requirements

Templates are assigned during triage and enforced throughout the workflow.

## Commit Attribution

Always use:
```
🤖 Submitted by George with love ♥
```
