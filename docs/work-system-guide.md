# Work System Guide

A comprehensive guide to the AI-powered work management system built on Claude Code.

## Table of Contents

- [Overview](#overview)
- [Core Concepts](#core-concepts)
- [Architecture](#architecture)
- [Setup & Installation](#setup--installation)
- [Directory Structure](#directory-structure)
- [Getting Started](#getting-started)
- [Common Workflows](#common-workflows)
- [Configuration](#configuration)
- [Agent Reference](#agent-reference)
- [Template System](#template-system)
- [Integration with External Systems](#integration-with-external-systems)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## Overview

The Work System is an AI-powered framework for managing work items (tasks, features, bugs, support requests) through a structured lifecycle. It provides:

- **Stage-based workflow**: Triage → Plan → Design → Deliver
- **Specialized AI agents**: Each stage has dedicated agents with specific capabilities
- **Process templates**: Reusable templates that drive agent behavior and ensure quality
- **Backend agnostic**: Works with Teamwork, GitHub Issues, Linear, Jira, or local-only
- **Local-first queues**: Priority-based queue management without external system dependencies
- **Session logging**: Structured activity logs for analysis and improvement

### Key Benefits

1. **Consistent process**: Templates ensure work follows proven patterns
2. **Automated categorization**: AI agents triage and classify work items
3. **Quality gates**: Validation at each stage prevents incomplete work from advancing
4. **Flexible integration**: Adapts to your existing tools (Teamwork, GitHub, etc.)
5. **Analytics-ready**: Session logs enable process improvement over time

---

## Core Concepts

### Work Item

The fundamental unit of work. Every task, bug, feature, or support request becomes a normalized WorkItem with:

- **Type**: epic, feature, story, task, bug, support request
- **WorkType**: product_delivery, support, maintenance, bug_fix, research
- **Urgency**: critical, now, next, future
- **Impact**: high, medium, low
- **Queue**: immediate, todo, backlog, icebox
- **Stage**: triage, plan, design, deliver
- **Template**: Assigned process template that defines expected outputs

Work items are normalized from external systems (Teamwork tasks, GitHub issues, etc.) using the `work-item-mapper` agent.

### Stages

Work flows through four stages:

1. **Triage**: Categorize and prioritize incoming work
   - Assign type, urgency, impact
   - Map to process template
   - Route to appropriate queue
   - Create epic/feature hierarchy

2. **Plan**: Decompose and size work
   - Break epics into features
   - Break features into stories
   - Break stories into tasks
   - Add acceptance criteria and estimates

3. **Design**: Explore solutions and make decisions
   - Research problem space
   - Generate solution options
   - Select approach with rationale
   - Create ADRs and implementation plans

4. **Deliver**: Build, test, and ship
   - Implement (TDD approach)
   - Run tests and validate quality
   - Evaluate against acceptance criteria
   - Record plan vs. actual metrics

### Queues

Work items are organized by urgency:

- **Immediate** (critical): Must be handled today, jumps to the top
- **Todo** (now): Current work queue for active cycle
- **Backlog** (next): Near-term work for next cycle
- **Icebox** (future): Long-term planning, no immediate action

Queues are tracked locally in `~/.claude/session/queues.json` and optionally synced to external systems via labels/tags.

### Agents

Specialized AI sub-agents that perform specific tasks:

- **work-item-mapper**: Normalizes external tasks to WorkItem schema
- **triage-agent**: Categorizes and routes work
- **plan-agent**: Decomposes and sizes work
- **design-agent**: Explores solutions and makes decisions
- **dev-agent**: Implements code using TDD
- **qa-agent**: Validates quality and coverage
- **eval-agent**: Evaluates outcomes against criteria
- **session-logger**: Captures structured activity logs
- **template-validator**: Validates work against templates

### Templates

Process templates define:

- **What must exist**: Required sections and fields
- **What metadata must be filled**: Type-specific requirements
- **What the output structure looks like**: Document format
- **What steps agents should perform**: Stage-specific guidance
- **What success criteria are attached**: Validation rules

Templates are versioned like code and evolve based on real system feedback.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User (via Claude Code)                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Slash Commands Layer                      │
│   /select-task  /triage  /plan  /design  /deliver           │
│   /queue  /route  /resume  /work-status                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Specialized Agents                        │
│  work-item-mapper  triage-agent  plan-agent  design-agent   │
│  dev-agent  qa-agent  eval-agent  session-logger            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 Work Manager Abstraction                     │
│        (Normalizes to common WorkItem schema)                │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Teamwork   │     │    GitHub    │     │    Linear    │
│   Adapter    │     │    Adapter   │     │    Adapter   │
└──────────────┘     └──────────────┘     └──────────────┘
```

### Data Flow

1. **Intake**: Work enters via external system (Teamwork, GitHub, etc.)
2. **Normalization**: work-item-mapper converts to WorkItem schema
3. **Stage Processing**: Specialized agents process through stages
4. **Session Logging**: session-logger captures all activity
5. **Template Validation**: template-validator ensures quality
6. **Queue Management**: Work routed to appropriate queues
7. **External Sync**: Changes pushed back to external system

---

## Setup & Installation

### Prerequisites

- Claude Code installed and configured
- (Optional) External work tracking system account:
  - Teamwork
  - GitHub
  - Linear
  - Jira
  - Or use local-only mode

### Installation Steps

1. **Clone the work system repository**:
   ```bash
   cd ~/.claude
   git clone <work-system-repo-url> work-system-temp
   ```

2. **Copy work system files** to your `.claude` directory:
   ```bash
   # Agents
   cp -r work-system-temp/agents/* ~/.claude/agents/

   # Commands
   cp -r work-system-temp/commands/* ~/.claude/commands/

   # Templates
   cp -r work-system-temp/templates/* ~/.claude/templates/

   # Documentation
   cp -r work-system-temp/docs/* ~/.claude/docs/
   cp work-system-temp/*.md ~/.claude/

   # Session templates
   cp work-system-temp/session/.gitignore ~/.claude/session/
   ```

3. **Create session directory** (if not exists):
   ```bash
   mkdir -p ~/.claude/session
   ```

4. **Configure work manager** (if using external system):
   ```bash
   # For Teamwork
   cp templates/config/work-manager.teamwork.yaml ~/.claude/work-manager.yaml
   # Edit with your project details

   # For GitHub
   cp templates/config/work-manager.github.yaml ~/.claude/work-manager.yaml
   # Edit with your org/repo details
   ```

5. **Verify installation**:
   ```bash
   # In Claude Code
   /work-status
   ```

### First-Time Configuration

1. **Set up credentials** (if using external system):
   - Teamwork: Add API token to `~/.claude/.credentials.json`
   - GitHub: Configure gh CLI or add token
   - Linear: Add API key

2. **Initialize session state**:
   ```bash
   # In Claude Code
   /select-task
   ```
   This initializes session tracking.

3. **Test with a sample task**:
   ```bash
   # If using Teamwork
   /triage TW-12345

   # If using GitHub
   /triage GH-owner/repo#123
   ```

---

## Directory Structure

```
~/.claude/
├── agents/                           # Specialized AI agents
│   ├── work-item-mapper.md          # Normalizes external tasks
│   ├── triage-agent.md               # Categorizes and routes
│   ├── plan-agent.md                 # Decomposes and sizes
│   ├── design-agent.md               # Explores solutions
│   ├── dev-agent.md                  # Implements code
│   ├── qa-agent.md                   # Validates quality
│   ├── eval-agent.md                 # Evaluates outcomes
│   ├── session-logger.md             # Logs activity
│   ├── template-validator.md         # Validates templates
│   ├── task-selector.md              # Selects work from queues
│   └── task-fetcher.md               # Fetches from external systems
│
├── commands/                         # Slash commands
│   ├── select-task.md                # Pick next work item
│   ├── resume.md                     # Resume active work
│   ├── triage.md                     # Triage work item
│   ├── plan.md                       # Plan work item
│   ├── design.md                     # Design solution
│   ├── deliver.md                    # Execute delivery pipeline
│   ├── queue.md                      # View queue contents
│   ├── route.md                      # Move between queues
│   ├── work-status.md                # View implementation status
│   └── teamwork/                     # Teamwork helper commands
│       ├── tw-get-task.md
│       ├── tw-get-tasks.md
│       ├── tw-create-task.md
│       └── ...
│
├── templates/                        # Process templates
│   ├── README.md                     # Template system docs
│   ├── versioning.md                 # Versioning guide
│   ├── registry.json                 # Template index
│   ├── _schema.json                  # JSON schema
│   ├── support/                      # Support templates
│   │   ├── generic.json
│   │   ├── remove-profile.json
│   │   └── subscription-change.json
│   ├── product/                      # Product templates
│   │   ├── prd.json
│   │   ├── feature.json
│   │   └── story/                    # Versioned template
│   │       ├── v1.0.0.json
│   │       └── latest.json → v1.0.0.json
│   └── delivery/                     # Delivery templates
│       ├── adr.md                    # ADR template
│       ├── adr.json
│       ├── bug-fix.json
│       └── implementation-plan.json
│
├── session/                          # Session state (ephemeral)
│   ├── .gitignore                    # Ignore session files
│   ├── active-work.md                # Current work context
│   ├── session-log.md                # Activity log
│   ├── logging-guide.md              # How to integrate logging
│   └── queues.json                   # Local queue storage
│
├── work-managers/                    # Work manager abstraction
│   ├── README.md                     # Architecture overview
│   └── queue-store.md                # Local queue storage spec
│
├── docs/                             # Documentation
│   └── adrs/                         # Architecture Decision Records
│       ├── README.md
│       ├── 0001-work-manager-abstraction.md
│       ├── 0002-local-first-session-state.md
│       └── 0003-stage-based-workflow.md
│
├── work-system.md                    # Core specification
├── work-system-implementation-plan.md # Implementation history
├── work-system-guide.md              # This guide
└── sub-agents-guide.md               # Agent development guide
```

### Files to Include in Git Repo

**Include**:
- `agents/`
- `commands/`
- `templates/`
- `docs/`
- `work-managers/`
- `session/.gitignore`
- `session/logging-guide.md`
- `*.md` (documentation files)

**Exclude** (Claude Code core files):
- `.credentials.json`
- `settings.json`
- `teamwork.json`
- `debug/`
- `file-history/`
- `history.jsonl`
- `ide/`
- `plans/`
- `plugins/`
- `projects/`
- `session-env/`
- `shell-snapshots/`
- `statsig/`
- `todos/`
- `CLAUDE.md` (user-specific)
- `session/active-work.md` (user-specific)
- `session/session-log.md` (user-specific)
- `session/queues.json` (user-specific)

---

## Getting Started

### Workflow Overview

```
1. Select Work    → 2. Triage      → 3. Plan        → 4. Design       → 5. Deliver
   (/select-task)    (/triage)        (/plan)          (/design)         (/deliver)
        │                 │                │                │                 │
        ▼                 ▼                ▼                ▼                 ▼
   Pick from queue   Categorize &     Decompose &      Explore &         Build, test,
   by priority       route to queue   create children  create ADR        evaluate
```

### Quick Start: Process a Task

**Step 1: Select work**
```bash
/select-task
```
Shows prioritized work items from all queues. Pick one to work on.

**Step 2: Triage (if not already triaged)**
```bash
/triage TW-12345
```
- Categorizes type, urgency, impact
- Assigns process template
- Routes to appropriate queue

**Step 3: Plan (if feature/epic)**
```bash
/plan TW-12345
```
- Decomposes into smaller items
- Adds acceptance criteria
- Creates child tasks

**Step 4: Design (if needs solution exploration)**
```bash
/design TW-12345
```
- Explores 2-4 solution options
- Creates ADR with decision rationale
- Generates implementation plan

**Step 5: Deliver**
```bash
/deliver TW-12345
```
- Implements code (TDD)
- Runs tests
- Evaluates against criteria
- Creates PR

### Quick Start: View Queues

```bash
# View all queues
/queue

# View specific queue
/queue immediate
/queue todo
/queue backlog
/queue icebox
```

### Quick Start: Move Work Between Queues

```bash
# Promote to current work
/route TW-12345 todo

# Defer to backlog
/route TW-12345 backlog
```

### Quick Start: Resume Active Work

```bash
/resume
```
Shows current work item and continues from last stage.

---

## Common Workflows

### Workflow 1: New Support Request

**Scenario**: Customer requests profile deletion

1. **Intake**: Support ticket created in Teamwork (TW-45678)

2. **Triage**:
   ```bash
   /triage TW-45678
   ```
   - Agent detects: type=support, workType=support
   - Matches template: `support/remove-profile`
   - Sets urgency=now, impact=medium
   - Routes to: `todo` queue

3. **Deliver** (support items skip plan/design):
   ```bash
   /deliver TW-45678
   ```
   - Follows template: verify identity, check dependencies, execute removal
   - Validates completion against template criteria
   - Posts resolution to customer

### Workflow 2: New Feature Request

**Scenario**: Product team requests "Dark mode for dashboard"

1. **Intake**: Feature request in Teamwork (TW-99001)

2. **Triage**:
   ```bash
   /triage TW-99001
   ```
   - Agent detects: type=feature, workType=product_delivery
   - Matches template: `product/feature`
   - Sets urgency=next, impact=high
   - Creates Epic if needed
   - Routes to: `backlog` queue

3. **Plan**:
   ```bash
   /plan TW-99001
   ```
   - Decomposes into stories:
     - "User can toggle dark mode in settings"
     - "Dashboard adapts to dark mode"
     - "Dark mode preference persists"
   - Creates child tasks in Teamwork
   - Adds Gherkin acceptance criteria

4. **Design** (for each story):
   ```bash
   /design TW-99002  # First story
   ```
   - Explores options: CSS variables vs. theme library
   - Creates ADR documenting decision
   - Generates implementation plan with tasks

5. **Deliver** (for each task):
   ```bash
   /deliver TW-99010  # First task
   ```
   - Implements feature (TDD)
   - Runs tests
   - Creates PR
   - Evaluates against criteria

### Workflow 3: Critical Bug

**Scenario**: Production bug affecting payments

1. **Intake**: Bug report in Teamwork (TW-CRITICAL-1)

2. **Triage**:
   ```bash
   /triage TW-CRITICAL-1
   ```
   - Agent detects: type=bug, workType=bug_fix
   - Matches template: `delivery/bug-fix`
   - Sets urgency=critical, impact=high
   - Routes to: `immediate` queue

3. **Design** (quick solution exploration):
   ```bash
   /design TW-CRITICAL-1
   ```
   - Identifies root cause
   - Explores quick fix vs. proper fix
   - Creates minimal ADR

4. **Deliver**:
   ```bash
   /deliver TW-CRITICAL-1
   ```
   - Writes failing test to reproduce
   - Implements fix
   - Verifies fix resolves issue
   - Creates emergency PR

### Workflow 4: Planning a Sprint

**Scenario**: Select work for 2-week sprint

1. **View work by priority**:
   ```bash
   /queue todo
   ```

2. **Adjust priorities**:
   ```bash
   # Move critical items up
   /route TW-12345 immediate

   # Defer lower priority items
   /route TW-67890 backlog
   ```

3. **Review capacity**:
   Check total estimates for todo queue

4. **Begin work**:
   ```bash
   /select-task
   ```
   Picks highest priority item

5. **Track progress**:
   ```bash
   /work-status
   ```
   Shows completion by stage

---

## Configuration

### Work Manager Configuration

Create `~/.claude/work-manager.yaml` (or per-project: `.claude/work-manager.yaml`):

**Teamwork Example**:
```yaml
manager: teamwork

teamwork:
  projectId: 123456
  tasklistId: 789012  # optional default

queues:
  storage: local  # local | native
```

**GitHub Example**:
```yaml
manager: github

github:
  owner: myorg
  repo: myrepo

queues:
  storage: native
  mapping:
    immediate: "priority: critical"
    todo: "priority: high"
    backlog: "priority: medium"
    icebox: "priority: low"
```

**Local-Only Example**:
```yaml
manager: local

queues:
  storage: local
```

### Template Configuration

Templates are auto-discovered from `~/.claude/templates/registry.json`.

To add a custom template:

1. Create template JSON in appropriate directory:
   ```bash
   vim ~/.claude/templates/product/my-template.json
   ```

2. Add to registry:
   ```json
   {
     "product/my-template": {
       "name": "My Custom Template",
       "path": "product/my-template.json",
       "version": "1.0.0"
     }
   }
   ```

3. Reference in work items via triage

### Session Configuration

Session state is stored in `~/.claude/session/`:

- `active-work.md`: Current work context (auto-created)
- `session-log.md`: Activity log (auto-created)
- `queues.json`: Queue assignments (auto-created)

These files are `.gitignore`d and local to each machine.

---

## Agent Reference

### work-item-mapper

**Purpose**: Normalize external tasks to WorkItem schema

**Input**: Raw task data from external system (Teamwork, GitHub, etc.)

**Output**: Normalized WorkItem JSON

**Model**: haiku (simple transformation)

**Usage**:
```bash
# Called automatically by /triage and other commands
# Or invoke directly via Task tool
```

### triage-agent

**Purpose**: Categorize and route incoming work

**Responsibilities**:
- Categorize work item type (bug, support, feature, etc.)
- Align with parent work item (Epic/Feature hierarchy)
- Categorize type of work (map to process template)
- Categorize impact (high/medium/low)
- Categorize urgency (critical/now/next/future)

**Input**: Normalized WorkItem

**Output**: Enriched WorkItem with Type, WorkType, Urgency, Impact, ProcessTemplate

**Model**: sonnet (requires reasoning)

**Usage**: Via `/triage` command

### plan-agent

**Purpose**: Decompose and size work

**Responsibilities**:
- Infer size (Appetite) based on type bounds
- Split if too large
- Break down (Epic→Features→Stories→Tasks)
- Elaborate (fill in type-specific fields)
- Add acceptance criteria

**Input**: Triaged WorkItem

**Output**: Updated WorkItem + child WorkItems + PlanDocument

**Model**: sonnet (requires reasoning)

**Usage**: Via `/plan` command

### design-agent

**Purpose**: Explore solutions and make decisions

**Responsibilities**:
- Research problem space
- Generate 2-4 solution options
- Evaluate options against constraints
- Select preferred option with rationale
- Create ADR
- Generate implementation plan

**Input**: Planned WorkItem (Feature or Story)

**Output**: ADR, Implementation Plan, Test Plan

**Model**: sonnet (requires reasoning)

**Usage**: Via `/design` command

### dev-agent

**Purpose**: Implement code using TDD

**Responsibilities**:
- Spec: Expand acceptance criteria to tests
- Red: Write failing tests
- Green: Minimum implementation to pass
- Refactor: Clean up while tests green
- Commit with proper attribution

**Input**: Designed WorkItem with implementation plan

**Output**: Commits, branches, code changes

**Model**: sonnet (code generation)

**Usage**: Via `/deliver` command (dev phase)

### qa-agent

**Purpose**: Validate quality and coverage

**Responsibilities**:
- Map acceptance criteria to tests
- Execute tests (unit, integration, e2e)
- Analyze coverage
- Calculate quality score
- Identify issues with severity

**Input**: Implemented WorkItem

**Output**: Test results, coverage report, quality score

**Model**: haiku (straightforward execution)

**Usage**: Via `/deliver` command (qa phase)

### eval-agent

**Purpose**: Evaluate outcomes against criteria

**Responsibilities**:
- Verify acceptance criteria met
- Check alignment with feature vision
- Compare plan vs. actual (time, scope)
- Record metrics
- Generate implementation document
- Identify follow-up items

**Input**: Delivered WorkItem

**Output**: Evaluation report, implementation document

**Model**: sonnet (requires reasoning)

**Usage**: Via `/deliver` command (eval phase)

### session-logger

**Purpose**: Capture structured activity logs

**Responsibilities**:
- Generate Session ID and Run ID
- Log run start/end
- Log actions with timestamps
- Capture metrics (duration, tokens, tool calls)
- Write to session log

**Input**: Action events from commands

**Output**: Structured log entries in session-log.md

**Model**: haiku (lightweight operations)

**Usage**: Called by all commands (integrated via guidance)

### template-validator

**Purpose**: Validate work against templates

**Responsibilities**:
- Validate required sections present
- Validate outputs created
- Check validation rules
- Calculate quality score
- Format error messages

**Input**: WorkItem + Template + Artifacts

**Output**: Validation report with score

**Model**: haiku (rule checking)

**Usage**: Called by stage commands before transition

---

## Template System

### Template Structure

Templates are JSON files that define process expectations:

```json
{
  "templateId": "product/feature",
  "name": "Feature Specification",
  "description": "Defines a product feature with stories and acceptance criteria",
  "appliesTo": ["feature"],
  "workType": "product_delivery",
  "requiredSections": [
    "vision",
    "user_stories",
    "acceptance_criteria"
  ],
  "recommendedSections": [
    "analytics",
    "rollout_plan"
  ],
  "validationRules": [
    "vision must not be empty",
    "at least one user story",
    "acceptance criteria in Gherkin format"
  ],
  "outputs": [
    {
      "type": "document",
      "extension": "md",
      "path": "docs/features/{workItemId}.md"
    }
  ],
  "stages": {
    "plan": {
      "required": true,
      "tasks": ["decompose", "elaborate"]
    },
    "design": {
      "required": true,
      "tasks": ["research", "options", "decide"]
    },
    "deliver": {
      "required": true,
      "tasks": ["implement", "test", "evaluate"]
    }
  }
}
```

### Template Categories

**Support Templates** (`templates/support/`):
- `generic.json`: Basic support request
- `remove-profile.json`: GDPR/CCPA profile deletion
- `subscription-change.json`: Subscription upgrade/downgrade

**Product Templates** (`templates/product/`):
- `prd.json`: Product Requirements Document (epic-level)
- `feature.json`: Feature specification with stories
- `story/`: User story with Gherkin criteria (versioned)

**Delivery Templates** (`templates/delivery/`):
- `adr.json`: Architecture Decision Record
- `bug-fix.json`: Bug investigation and fix
- `implementation-plan.json`: Task breakdown with estimates

### Template Versioning

Templates can be versioned for evolution:

```
templates/product/story/
├── v1.0.0.json
├── v1.1.0.json
└── latest.json → v1.1.0.json
```

Work items can pin to specific version:
```json
{
  "processTemplate": "product/story/v1.0.0"
}
```

Or use latest:
```json
{
  "processTemplate": "product/story/latest"
}
```

See `templates/versioning.md` for full details.

### Creating Custom Templates

1. **Define template JSON**:
   ```bash
   vim ~/.claude/templates/custom/my-template.json
   ```

2. **Follow schema** (validate against `_schema.json`)

3. **Add to registry**:
   ```bash
   vim ~/.claude/templates/registry.json
   ```

4. **Test with work item**:
   ```bash
   /triage TW-12345  # Should match your template
   ```

---

## Integration with External Systems

### Teamwork

**Setup**:
1. Add API token to `~/.claude/.credentials.json`
2. Configure project in `work-manager.yaml`
3. Map queues to tags or custom fields

**Features**:
- Fetch tasks with full subtask tree
- Create child tasks during planning
- Post comments with triage/design results
- Track time logs
- Update task status

**Commands Available**:
- `/teamwork:tw-get-task`
- `/teamwork:tw-get-tasks`
- `/teamwork:tw-create-task`
- `/teamwork:tw-update-task`
- `/teamwork:tw-create-comment`
- And more... (see `commands/teamwork/`)

### GitHub

**Setup**:
1. Configure gh CLI or add GitHub token
2. Configure repo in `work-manager.yaml`
3. Map queues to labels

**Features**:
- Fetch issues with comments
- Create child issues during planning
- Add labels for stage/queue
- Create PRs during delivery
- Link commits to issues

### Linear

**Setup**:
1. Add Linear API key
2. Configure team in `work-manager.yaml`
3. Map queues to statuses or priorities

**Features**:
- Fetch issues with parent/child relationships
- Create sub-issues during planning
- Update status based on stage
- Link branches and commits

### Local-Only Mode

**Setup**:
```yaml
manager: local
```

**Features**:
- No external system required
- Work items stored in `~/.claude/session/local-work-items.json`
- All work system features available
- Great for testing or personal projects

---

## Troubleshooting

### Common Issues

**Issue**: `/triage` says "Template not found"

**Solution**: Check that template exists in registry:
```bash
cat ~/.claude/templates/registry.json | grep <template-name>
```

---

**Issue**: Queue commands show empty results

**Solution**: Check queue storage file:
```bash
cat ~/.claude/session/queues.json
```
If missing, queues haven't been initialized. Run `/triage` on a task first.

---

**Issue**: Agent not loading

**Solution**: Verify agent file exists:
```bash
ls ~/.claude/agents/<agent-name>.md
```
Check Claude Code can find it via Task tool.

---

**Issue**: Session log not updating

**Solution**: Verify session directory exists:
```bash
ls ~/.claude/session/
```
Session logger writes to `session-log.md`.

---

**Issue**: External system integration failing

**Solution**:
1. Check credentials in `~/.claude/.credentials.json`
2. Verify `work-manager.yaml` configuration
3. Test with helper commands (e.g., `/teamwork:tw-get-task`)

---

### Debug Mode

To see detailed agent activity:

1. Check session log:
   ```bash
   tail -f ~/.claude/session/session-log.md
   ```

2. Review last agent output in Claude Code conversation

3. Check work system status:
   ```bash
   /work-status
   ```

---

## Contributing

### Adding a New Agent

1. Create agent file in `~/.claude/agents/<agent-name>.md`
2. Follow structure from existing agents
3. Document: purpose, responsibilities, input/output, model
4. Add to stage workflow if applicable
5. Test with sample work items
6. Update this guide with new agent reference

### Adding a New Template

1. Create template JSON in appropriate category
2. Validate against `_schema.json`
3. Add to `registry.json`
4. Test with work items that should match
5. Document in template system section

### Adding a New Stage

1. Define stage in `work-system.md`
2. Create specialized agent for stage
3. Create slash command for stage
4. Add to workflow documentation
5. Create ADR documenting decision

### Adding a New Work Manager

1. Create adapter file in `work-managers/adapters/<name>.md`
2. Define field mappings to WorkItem schema
3. Implement operations (fetch, list, update, create, comment)
4. Add to configuration schema
5. Test with existing commands
6. Update integration documentation

---

## Additional Resources

- [work-system.md](work-system.md): Core specification
- [work-system-implementation-plan.md](work-system-implementation-plan.md): Implementation history and status
- [sub-agents-guide.md](sub-agents-guide.md): Guide to creating and using sub-agents
- [session/logging-guide.md](session/logging-guide.md): Session logging integration
- [templates/README.md](templates/README.md): Template system documentation
- [templates/versioning.md](templates/versioning.md): Template versioning guide
- [work-managers/README.md](work-managers/README.md): Work manager abstraction
- [docs/adrs/](docs/adrs/): Architecture Decision Records

---

## License

[Specify your license here]

## Support

[Specify how users can get help]

---

*Last Updated: 2024-12-07*
*Version: 1.0.0*
