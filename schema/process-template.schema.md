# Process Template Schema

A process template defines the workflow stages and transitions for a category of work items.

## Schema Definition

```yaml
ProcessTemplate:
  # Identity
  id: string                    # Internal ID (e.g., "TPL-standard")
  name: string                  # Display name
  description: string | null    # Template description

  # Classification
  category: enum                # standard | bugfix | spike | hotfix | maintenance
  applicableTo: string[]        # Work item types this applies to

  # Stages
  stages: Stage[]               # Ordered list of stages
    - id: string                # Stage ID (e.g., "triage")
      name: string              # Display name
      description: string | null
      required: boolean         # Must complete this stage?
      allowedTransitions: string[]  # Stage IDs can transition to
      entryConditions: string[] # Conditions to enter stage
      exitConditions: string[]  # Conditions to exit stage
      defaultAssigneeRole: string | null  # Role to auto-assign
      estimatedDuration: string | null    # ISO 8601 duration (e.g., "PT2H")
      artifacts: string[]       # Expected outputs from this stage

  # Automation
  hooks: Hook[]                 # Automation hooks
    - event: string             # Event trigger
      action: string            # Action to perform
      config: object            # Action configuration

  # Tracking
  createdAt: datetime
  updatedAt: datetime

  # Metadata
  metadata: object
```

## Standard Stages

The work system defines five core stages:

| Stage | Purpose | Key Activities |
|-------|---------|----------------|
| `triage` | Categorize and prioritize | Assess, categorize, assign queue |
| `plan` | Break down and estimate | Decompose, estimate, create subtasks |
| `design` | Solution design | Explore options, make decisions, document |
| `deliver` | Implementation | Code, test, review, merge |
| `eval` | Evaluation and learning | Compare plan vs actual, capture learnings |

## Categories

| Category | Description | Typical Stages |
|----------|-------------|----------------|
| `standard` | Normal feature/story work | All 5 stages |
| `bugfix` | Bug fixes | triage → deliver → eval |
| `spike` | Research/investigation | triage → plan → design → eval |
| `hotfix` | Emergency production fix | triage → deliver |
| `maintenance` | Routine maintenance | triage → deliver |

## Examples

### Standard Template

```yaml
id: "TPL-standard"
name: "Standard Development"
description: "Full development lifecycle for features and stories"
category: "standard"
applicableTo: ["epic", "feature", "story", "task"]

stages:
  - id: "triage"
    name: "Triage"
    description: "Categorize, prioritize, and route the work item"
    required: true
    allowedTransitions: ["plan", "deliver"]
    entryConditions:
      - "Work item has name and description"
    exitConditions:
      - "Queue assigned"
      - "Priority set"
      - "Type confirmed"
    defaultAssigneeRole: "manager"
    estimatedDuration: "PT30M"
    artifacts:
      - "Queue assignment"
      - "Priority assignment"
      - "Initial categorization"

  - id: "plan"
    name: "Plan"
    description: "Break down work and create estimates"
    required: true
    allowedTransitions: ["design", "deliver"]
    entryConditions:
      - "Triage complete"
    exitConditions:
      - "Acceptance criteria defined"
      - "Subtasks created (if applicable)"
      - "Estimate provided"
    defaultAssigneeRole: "developer"
    estimatedDuration: "PT1H"
    artifacts:
      - "Acceptance criteria"
      - "Subtask breakdown"
      - "Time estimate"

  - id: "design"
    name: "Design"
    description: "Create solution design and implementation plan"
    required: false
    allowedTransitions: ["deliver"]
    entryConditions:
      - "Planning complete"
      - "Complexity warrants design"
    exitConditions:
      - "Design document created"
      - "Implementation approach decided"
    defaultAssigneeRole: "developer"
    estimatedDuration: "PT2H"
    artifacts:
      - "Design document"
      - "Architecture decisions"
      - "Implementation plan"

  - id: "deliver"
    name: "Deliver"
    description: "Implement, test, and ship the work"
    required: true
    allowedTransitions: ["eval"]
    entryConditions:
      - "Acceptance criteria defined"
    exitConditions:
      - "Code complete"
      - "Tests passing"
      - "PR merged"
    defaultAssigneeRole: "developer"
    estimatedDuration: null  # Varies by item
    artifacts:
      - "Code changes"
      - "Tests"
      - "Documentation updates"

  - id: "eval"
    name: "Evaluate"
    description: "Review outcomes and capture learnings"
    required: true
    allowedTransitions: []
    entryConditions:
      - "Delivery complete"
    exitConditions:
      - "Actual time logged"
      - "Learnings captured"
    defaultAssigneeRole: "developer"
    estimatedDuration: "PT15M"
    artifacts:
      - "Time comparison"
      - "Learnings document"

hooks:
  - event: "stage.enter.deliver"
    action: "create_branch"
    config:
      branchPattern: "feature/{workItemPrefix}-{externalId}-{slug}"

  - event: "stage.exit.deliver"
    action: "log_time"
    config:
      promptForDescription: true

createdAt: "2024-01-01T00:00:00Z"
updatedAt: "2024-12-08T00:00:00Z"
```

### Bugfix Template

```yaml
id: "TPL-bugfix"
name: "Bug Fix"
description: "Streamlined process for bug fixes"
category: "bugfix"
applicableTo: ["bug", "task"]

stages:
  - id: "triage"
    name: "Triage"
    description: "Assess severity and impact"
    required: true
    allowedTransitions: ["deliver"]
    entryConditions:
      - "Bug report received"
    exitConditions:
      - "Severity assessed"
      - "Priority set"
      - "Reproducible"
    defaultAssigneeRole: "developer"
    estimatedDuration: "PT30M"
    artifacts:
      - "Reproduction steps"
      - "Severity assessment"

  - id: "deliver"
    name: "Fix & Verify"
    description: "Implement fix and verify resolution"
    required: true
    allowedTransitions: ["eval"]
    entryConditions:
      - "Bug is reproducible"
    exitConditions:
      - "Fix implemented"
      - "Tests added"
      - "Bug no longer reproducible"
    defaultAssigneeRole: "developer"
    estimatedDuration: null
    artifacts:
      - "Code fix"
      - "Regression test"

  - id: "eval"
    name: "Evaluate"
    description: "Capture root cause and prevention"
    required: false
    allowedTransitions: []
    entryConditions:
      - "Fix deployed"
    exitConditions:
      - "Root cause documented"
    defaultAssigneeRole: "developer"
    estimatedDuration: "PT15M"
    artifacts:
      - "Root cause analysis"
      - "Prevention recommendations"

hooks:
  - event: "stage.enter.deliver"
    action: "create_branch"
    config:
      branchPattern: "bugfix/{workItemPrefix}-{externalId}-{slug}"
```

### Spike Template

```yaml
id: "TPL-spike"
name: "Research Spike"
description: "Time-boxed investigation"
category: "spike"
applicableTo: ["spike"]

stages:
  - id: "triage"
    name: "Define"
    description: "Define the research question"
    required: true
    allowedTransitions: ["plan"]
    exitConditions:
      - "Research question defined"
      - "Time box set"
    estimatedDuration: "PT15M"
    artifacts:
      - "Research question"
      - "Success criteria"

  - id: "plan"
    name: "Plan Research"
    description: "Identify areas to explore"
    required: true
    allowedTransitions: ["design"]
    exitConditions:
      - "Research areas identified"
    estimatedDuration: "PT30M"
    artifacts:
      - "Research plan"

  - id: "design"
    name: "Investigate"
    description: "Conduct the investigation"
    required: true
    allowedTransitions: ["eval"]
    exitConditions:
      - "Investigation complete"
      - "Findings documented"
    estimatedDuration: null  # Time-boxed
    artifacts:
      - "Research findings"
      - "Prototypes (if applicable)"

  - id: "eval"
    name: "Conclude"
    description: "Summarize findings and recommendations"
    required: true
    allowedTransitions: []
    exitConditions:
      - "Recommendation provided"
    estimatedDuration: "PT30M"
    artifacts:
      - "Summary document"
      - "Recommendations"
```

## Hook Events

| Event | Trigger |
|-------|---------|
| `stage.enter.{stageId}` | Work item enters a stage |
| `stage.exit.{stageId}` | Work item exits a stage |
| `workitem.created` | New work item created |
| `workitem.assigned` | Work item assigned |
| `workitem.completed` | Work item marked done |

## Hook Actions

| Action | Description |
|--------|-------------|
| `create_branch` | Create git branch |
| `create_pr` | Create pull request |
| `log_time` | Prompt for time logging |
| `notify` | Send notification |
| `sync_external` | Sync to external system |

## Validation Rules

1. **Required fields**: `id`, `name`, `category`, `stages`
2. **At least one stage**: Must have at least one stage
3. **Valid transitions**: `allowedTransitions` must reference valid stage IDs
4. **No cycles**: Stage transitions must not create infinite loops

## Related Schemas

- [work-item.schema.md](work-item.schema.md) - Uses templates
- [agent.schema.md](agent.schema.md) - Stage assignees
