# Work System

## Work Item

The work item model allows us to normalize the work so every agent is talking about the same thing.

### Work Item Types

-   Client Request
-   Epic
-   Feature
-   Story
    -   User Story
    -   Bug
    -   Support
    -   Maintenance
-   Task

### Work Item Shared Fields

-   Id
-   Name
-   Description
-   Type
    -   epic
    -   feature
    -   story
    -   task
    -   client_request
-   WorkType
    -   product_delivery
    -   support
    -   maintenance
    -   bug_fix
    -   research
    -   other
-   ProcessTemplate
    -   File or document reference that defines the standard process and artifacts
-   Urgency
    -   critical
    -   now
    -   next
    -   future
-   Impact
    -   high
    -   medium
    -   low
-   Appetite
    -   Unit depends on type
        -   Epic: cycles
        -   Feature: weeks
        -   Story: days
        -   Task: hours
    -   Value: numeric size in that unit
-   Capability
    -   Epic: strategic_planning
    -   Feature / Story: product_planning
    -   Task: specific deliverable
        -   accessibility
        -   development
        -   design
        -   marketing
        -   qa
        -   ux
        -   other
-   Dependencies
    -   List of blocking work item Ids
-   ParentId
    -   For hierarchy
-   ChildrenIds
    -   Optional, or derived
-   Status
    -   triage
    -   planned
    -   designed
    -   ready_for_dev
    -   in_progress
    -   in_review
    -   in_test
    -   done
-   CreatedAt
-   UpdatedAt

### Work Item Fields By Type

#### Epic

-   Value
    -   high
    -   medium
    -   low
-   Risk
    -   high
    -   medium
    -   low

#### Feature

-   Vision
    -   Definition of success when delivered

#### Story

-   AcceptanceCriteria
    -   List of Gherkin scenarios
        -   Given, When, Then

#### Task

-   EffortEstimateHours
-   Status
    -   todo
    -   in_progress
    -   review
    -   done

This is the shared work item schema in the DB, board, and prompts.

## Agent

Agents are autonomous workers that pull work from queues, apply process templates, and update work items. Each agent must:

-   Accept input as structured JSON (work items, queues, context).
-   Log what it did in a structured way.
-   Emit updated work items and events.

An agent’s work is captured as:

-   Run
-   Session
-   Action log
-   Plan doc
-   Implementation doc

### Agent Run

One run is one continuous engagement of an agent on one or more work items.

Fields:

-   RunId
-   AgentName
-   AgentVersion
-   Stage
    -   triage
    -   plan
    -   design
    -   deliver
-   WorkItemIds
    -   List of work items touched in this run
-   Trigger
    -   Type
        -   manual
        -   scheduled
        -   event
    -   Source
        -   user
        -   system
        -   webhook
    -   EventId
        -   Optional reference to upstream event
-   InputContext
    -   SnapshotAt
    -   Additional context
        -   rawClientRequest
        -   queueSnapshotId
-   StartedAt
-   FinishedAt
-   Status
    -   success
    -   partial
    -   failed
-   Summary
    -   Description
        -   One line summary of what the run did
    -   KeyDecisions
        -   List of short decision statements
-   Metrics
    -   DurationMs
    -   TokensInput
    -   TokensOutput
    -   ToolCalls
-   ActionIds
    -   List of AgentAction ids in this run

### Agent Session

A session groups multiple runs that belong to the same human request or higher order workflow.

Fields:

-   SessionId
-   CreatedBy
    -   user id or system id
-   CorrelationId
    -   Ties to external system or ticket
-   RunIds
    -   List of RunId values
-   StartedAt
-   FinishedAt
-   Summary

Sessions let you analyze, for example, everything that happened for one client request across triage, plan, design, and deliver.

### Agent Action Log

Agent actions are the atomic steps inside a run. Each significant step must emit an action record.

Fields:

-   ActionId
-   RunId
-   AgentName
-   Timestamp
-   Stage
    -   triage
    -   plan
    -   design
    -   deliver
-   Phase
    -   select
    -   categorize
    -   decompose
    -   design_options
    -   spec
    -   implement
    -   test
    -   deliver
    -   evaluate
    -   improve
-   ActionType
    -   analysis
    -   classification
    -   planning
    -   decomposition
    -   code_change
    -   test_run
    -   decision
    -   write_document
-   Status
    -   success
    -   skipped
    -   failed
-   WorkItemIds
-   ParentActionId
    -   Optional, to group substeps
-   Input
    -   WorkItemSnapshot
    -   ExtraContext
-   Output
    -   UpdatedWorkItems
    -   CreatedArtifacts
        -   Documents
        -   Branches
        -   PRs
        -   ADRs
    -   Decision
        -   Summary
        -   Reasons
-   Metrics
    -   LatencyMs
    -   TokensInput
    -   TokensOutput
-   Error
    -   Code
    -   Message

This lets you inspect the flow of actions, detect waste, and build evals over behavior.

### Plan Document

The plan doc describes the intended path from current state to desired state for a work item, usually at feature or epic level.

Fields:

-   PlanId
-   WorkItemId
-   CreatedByRunId
-   CreatedAt
-   Assumptions
-   Constraints
-   Milestones
    -   Id
    -   Name
    -   TargetDate
-   Steps
    -   StepId
    -   Description
    -   OwnerCapability
    -   RelatedWorkItemIds
    -   EstimateHours
    -   Status
        -   planned
        -   in_progress
        -   done
        -   skipped

### Implementation Document

The implementation doc captures what actually happened versus the plan.

Fields:

-   ImplementationId
-   WorkItemId
-   RelatedPlanId
-   Actuals
    -   TotalTimeLoggedHours
    -   PerCapability
    -   LeadTimeHours
    -   CycleTimeHours
-   PlanVsActual
    -   PerStep
        -   StepId
        -   EstimateHours
        -   ActualHours
        -   Status
-   Quality
    -   TestsPlanned
    -   TestsPassed
    -   BugsFoundWithinWindow
-   Evaluation
    -   MeetsAcceptanceCriteria
    -   MeetsFeatureVision
        -   none
        -   partial
        -   full
    -   Notes

Agents in the plan and deliver stages are responsible for updating plan and implementation docs as they learn more.

## Process Template

A Template is a structured artifact that defines:

1.  What must exist
2.  What metadata must be filled
3.  What the output structure looks like
4.  What steps agents should perform
5.  What success criteria are attached

### Fields

```json
{
  "templateId": "product/prd",
  "name": "Product Requirements Document",
  "description": "Defines the high-level goals, constraints, acceptance criteria, and success metrics for a product or feature.",
  "appliesTo": ["feature", "epic"],
  "requiredSections": [
    "vision",
    "problem_statement",
    "target_users",
    "use_cases",
    "requirements",
    "constraints",
    "non_goals",
    "acceptance_criteria",
    "open_questions"
  ],
  "recommendedSections": [
    "experiments",
    "analytics",
    "rollout_plan"
  ],
  "outputs": [
    {
      "type": "decision_record",
      "location": "repo://docs/prd/{workItemId}.md"
    }
  ],
  "validationRules": [
    "vision must not be empty",
    "requirements must be listed",
    "target_users must be described"
  ]
}
```

Output is file paths + schema expectations.

#### Example Templates

##### Template: Product North Star

File: `/templates/product/north_star.json`

```json
{
  "templateId": "product/north_star",
  "appliesTo": ["feature", "epic"],
  "requiredSections": [
    "mission",
    "target_audience",
    "problem_we_solve",
    "value_proposition",
    "north_star_metric",
    "supporting_metrics"
  ],
  "validationRules": [
    "mission must be present",
    "north_star_metric must be defined"
  ],
  "outputs": [
    {
      "type": "document",
      "extension": "md",
      "path": "repo://docs/product/north_star/{workItemId}.md"
    }
  ]
}
```

##### Template: OKRs

`/templates/product/okrs.json`

```json
{
  "templateId": "product/okrs",
  "appliesTo": ["feature"],
  "requiredSections": [
    "objectives",
    "key_results",
    "measurement_plan",
    "instrumentation",
    "dashboard_plan"
  ],
  "validationRules": [
    "okrs must include at least one objective",
    "each objective must have at least two key results"
  ],
  "outputs": [
    {
      "type": "document",
      "extension": "md",
      "path": "repo://docs/product/okrs/{workItemId}.md"
    }
  ]
}
```

##### Template: PRD (example Markdown skeleton)

`/templates/product/prd.md`

```
# {workItem.name} – PRD

## Vision
{vision}

## Problem Statement
{problem_statement}

## Users and Segments
{target_users}

## Use Cases and Jobs To Be Done
{use_cases}

## Requirements
{requirements}

## Constraints
{constraints}

## Non-Goals
{non_goals}

## Acceptance Criteria
{acceptance_criteria}

## Open Questions
{open_questions}

## Dependencies
{dependencies}
```

##### Template: Go-To-Market (GTM)

`/templates/product/gtm.json`

```json
{
  "templateId": "product/gtm",
  "appliesTo": ["feature"],
  "requiredSections": [
    "target_segments",
    "positioning",
    "messaging",
    "channels",
    "pricing_strategy",
    "campaign_plan",
    "launch_readiness",
    "success_metrics"
  ],
  "outputs": [
    {
      "type": "document",
      "extension": "md",
      "path": "repo://docs/product/gtm/{workItemId}.md"
    }
  ]
}
```

### Location

Templates live in a structured repo location, for example:

```
/templates
    /product
        new_product_strategy_stack.json
        prd.json
        okrs.json
        north_star.json
        gtm.json
    /delivery
        launch_playbook.json
        technical_architecture.json
    /support
        remove_profile.json
```

Each template is:

-   a JSON definition (machine-readable; input for agents)
-   AND a Markdown skeleton (human-readable; output for docs)

For example:

```
/templates/product/prd.md
/templates/product/prd.json
```

### Reference from WorkItem

WorkItem has the field:

```
ProcessTemplate
```

So, a WorkItem for PRD feature looks like:

```json
{
  "id": "WI-2001",
  "type": "feature",
  "workType": "product_strategy",
  "processTemplate": "product/prd",
  "capability": "product_planning",
  "urgency": "now",
  "impact": "high"
}
```

This activates the template logic for all Agents touching this WorkItem.

### Agent Usage

Agents read templates and use them as contract and generation spec.

##### Triage Agent

-   Assigns ProcessTemplate based on categorize
-   Checks template exists in repository
-   If not, it errors → "Template not found"

##### Planning Agent

-   Uses template to:
    -   understand expected outputs
    -   size the work item
    -   structure decomposition strategy
-   If WorkItem is missing required fields → planning fails

##### Design Agent

-   Generates the artifact in template format
-   Validates output against `requiredSections`
-   Writes to repo as PR

##### Deliver/Eval Agents

-   Validate implementation against template’s required outputs
-   Example: OKR template requires metrics, dashboards, owners
-   Eval Agent checks metric results and records them

Templates drive agent behavior like code, because:

-   Agents treat the template file as a spec
-   Templates enforce required structure
-   Templates dictate output validation
-   Templates define links in the dependency graph
-   Templates determine auditability (plan vs implementation vs evaluation)

Because:

-   They are files
-   Used machine-to-machine
-   Ensuring repeatable behavior

### Versioning

Now that templates are code, they must version like code.

```
/templates/product/prd/v1.0.0.json
/templates/product/prd/v1.1.0.json
/templates/product/prd/v2.0.0.json
```

A WorkItem references the versioned template:

```json
"processTemplate": "product/prd/v1.1.0"
```

This makes:

-   historical accuracy
-   reproducible audit trails
-   templates improvable over time

### Improving Templates

Because plan vs actual is captured in structured ImplementationDocs, the system will have insight like:

-   Certain template steps are always skipped then template is wrong
-   Certain outputs are always incomplete then template missing guidance
-   Certain decisions are reworked often then template should enforce better constraints

Meaning: Templates evolve via real system performance feedback.

That is how product maturity compounds.

## Lifecycle and Queues

Agents work in a pull-based system of stages and queues where agents pull work items from a queue, do work in stages, and deliver to a queue.

### Stages

1.  Triage
2.  Plan
3.  Design
4.  Deliver

### Stage Components

Each stage has:

-   WIP limit
-   Input queue
-   Work queue
-   Done condition
-   Output queue

### Queues

-   Intake
    -   Raw client requests
-   Triage queues
    -   Immediate (critical)
    -   Todo (now)
    -   Backlog (next)
    -   Icebox (future)
-   Plan queue
    -   Items that passed triage and need decomposition
-   Design queue
    -   Planned items needing solution options
-   Deliver queue
    -   Ready-for-dev items (stories and tasks)

### Queue Routing

Urgency classes define queue routing:

-   Critical goes to Immediate
-   Now goes to Todo (current cycle)
-   Next goes to Backlog
-   Future goes to Icebox

## Triage Stage

### Goal

Turn client requests into structured work items.

### Triggers

-   ClientRequest event
-   Manual pull by a Triage agent

### Inputs

-   ClientRequest
    -   Raw message, email, ticket, or call notes

### Rules

Output conditions:

-   Work item has
    -   Type
    -   WorkType
    -   Urgency
    -   Impact
    -   Mapped Epic or Feature
        -   Or new Epic and Feature created
    -   Name and Description
    -   Initial Appetite SWAG
-   Work item is placed in the correct queue based on urgency

### Process

#### Categorize Work Item Type

1.  Decide if this is a bug, support request, new feature, enhancement, maintenance, research, or other.

#### Align with Parent Work Item

1.  If the request clearly belongs to an existing epic and feature
    1.  Create a Story under that Feature.
    2.  Only reject if it is a duplicate of an existing story or already accepted work.
2.  If the request matches an existing epic but not a feature
    1.  Create a Feature under that Epic.
3.  If the request does not match any existing epic
    1.  Create a new Epic.
    2.  Create a Feature under that Epic.
    3.  Create the Story if appropriate.

#### Categorize Type of Work

1.  Map to a process template.
    1.  Examples
        1.  Support request such as remove profile maps to a remove profile support template.
        2.  User Story for product delivery maps to the product delivery template.

#### Categorize Impact

1.  Infer impact on users and business.
    1.  High
        1.  Revenue, safety, SLA, or major UX friction.
    2.  Medium
        1.  Noticeable improvement, non-critical.
    3.  Low
        1.  Nice to have, minor polish.

#### Categorize Urgency

1.  Critical
    1.  Must be handled today and jumps to the top.
2.  Now
    1.  Enters current work queue.
3.  Next
    1.  Goes into near-term backlog.
4.  Future
    1.  Goes into long-term planning.

### Outputs

-   New or updated WorkItem
-   WorkItemTriaged event
-   AgentRun and AgentAction records for the triage session

## Plan Stage

### Goal

Shape work items into right-sized chunks and place them in a prioritized plan.

Two parts: Select and Plan, then Prioritize.

### Triggers

-   WorkItemTriaged event
-   Manual pull by Planning agent

### Inputs

-   TriagedWorkItemQueue

### Rules

Output conditions:

-   Work item and its children are sized within bounds.
-   Relationships (parent and child) are defined.
-   At least rough estimates exist.
-   Work items are linked to the correct process template.
-   Items are moved into
    -   Design queue for items needing solution design
    -   Deliver queue if design is trivial or already known

### Process

#### Select

Goal

-   Decide what to plan.

Inputs

-   TriagedWorkItemQueue
-   Planning WIP limits

Process

1.  For each work item type, group by urgency lanes
    1.  critical
    2.  now
    3.  next
    4.  future
2.  Within each lane
    1.  Order by Impact from high to low.
    2.  Then by parent Epic Value from high to low.
    3.  Then by parent Epic Risk from low to high.
3.  If no work items are available, stop.
4.  Check planning WIP limit for that type.
5.  If there is capacity, pick
    1.  The top-ranked item, or
    2.  The top item matching the current capability if planning is capability-aware.

Outputs

-   Next WorkItemId to plan
-   AgentRun and AgentAction records capturing the selection decision

#### Plan

Goal

-   Decompose, elaborate, and shape work items.

Rules

-   Decomposition and sizing must respect type bounds.
-   Child items must reference their parent and inherit context where appropriate.

Process

1.  Infer size (Appetite)
    1.  Epic: cycles, based on 2-week cycles, maximum 3 cycles.
    2.  Feature: weeks, maximum 2 weeks.
    3.  Story: days, maximum 3 days.
    4.  Task: hours, maximum 8 hours.
2.  If size is too large
    1.  Split into multiple items of the same type.
        1.  Epic can become multiple epics.
        2.  Feature can become multiple features.
        3.  Story can become multiple stories.
3.  Break down
    1.  Epic into Features.
    2.  Feature into Stories.
    3.  Story into Tasks.
    4.  Tasks are atomic and not broken down further.
4.  Elaborate
    1.  Ensure all shared fields are set.
    2.  Epic
        1.  Value and risk.
    3.  Feature
        1.  Vision.
    4.  Story
        1.  Gherkin acceptance criteria.
    5.  Tasks
        1.  Effort estimate hours.

Outputs

-   Planned WorkItemId
-   Updated or created WorkItems for children
-   PlanDocument for epics and features where needed
-   WorkItemPlanned event
-   AgentRun and AgentAction records for planning

#### Prioritize

Goal

-   Rank the plan.

Inputs

-   Planned work items
-   Epic value and risk
-   WIP limits

Rules

-   Global ordering algorithm
    -   Urgency
    -   Impact
    -   Parent epic value
    -   Parent epic risk

Process

-   Compute priority score per work item using the ordering rules.
-   Sort items into a list for the next cycle.
-   Optionally suggest WIP limit adjustments if queues are overloaded.

Outputs

-   Sorted lists for the next cycle
-   Priority scores for each item
-   Suggested WIP limit adjustments
-   AgentRun and AgentAction records for prioritization

### Outputs

-   Planned WorkItem
-   WorkItemPlanned event

## Design Stage

### Goal

Move from what we are doing to how we will do it for features and stories.

### Triggers

-   WorkItemPlanned event
-   Manual pull by Design agent

### Inputs

-   Planned WorkItems
    -   Features
    -   Stories

### Rules

Output conditions:

-   Decision record created and linked to the work item.
-   Selected solution option recorded with rationale.
-   Architecture notes or diagrams produced.
-   Estimates updated if design changes scope.
-   Implementable Stories and Tasks created with clear acceptance criteria.

### Process

#### Select

-   Use the same selection pattern as planning: lanes by urgency, then impact, then epic value and risk, gated by design WIP limit.

#### Initialize

-   Create design branch and workspace.
-   Link to work item and repo.

#### Research

-   Understand problem space, constraints, and current system behavior.
-   Review existing ADRs and documentation.

#### Design

-   Produce solution options with tradeoffs.
-   Compare options against constraints, appetite, and impact.
-   Pick the preferred option.
-   Capture rationale in a decision record.
-   Generate initial tasks as the implementation plan.

### Outputs

-   ArchitectureDecisionRecord
-   WorkItemImplementationPlan
-   WorkItemTestPlan
-   Designed WorkItem
-   WorkItemDesigned event
-   AgentRun and AgentAction records for design

## Deliver Stage

### Goal

Turn designed work items into working software and proven value.

### Triggers

-   WorkItemDesigned event
-   Manual pull by delivery agents

### Inputs

-   Designed WorkItems
    -   Stories and Tasks in the Deliver queue
-   ImplementationPlan
-   TestPlan

### Rules

Output conditions:

-   Code, config, and content implemented according to spec.
-   Tests implemented and executed.
-   Deployments performed or handoffs completed.
-   Acceptance criteria evaluated.
-   ImplementationDocument updated with plan versus actual.
-   Follow-up work items created for any gaps.

### Process

#### Select

1.  Pull the next ready Story or Task using the same queue logic but now filtered by capability such as csharp, ux, qa, devops.

Outputs

-   Selected WorkItemId
-   AgentRun and AgentAction records capturing the selection

#### Dev

##### Spec

1.  Expand story into a precise implementation spec if needed.
2.  For bugs, reproduce the issue and write a failing test.

##### Implement

1.  Write code, configuration, or content.

##### Review

1.  Submit changes for peer review or run an automated review agent.

Outputs

-   Commits and branches
-   Pull requests
-   Updated WorkItems
-   AgentRun and AgentAction records for development

#### QA

##### Spec

1.  Use the test plan and Gherkin criteria to define automated and manual tests.

##### Run

1.  Run automated tests.
2.  Perform manual checks where needed.

##### Review

1.  Review test coverage and results.

Outputs

-   Test results
-   Updated quality metrics
-   WorkItem status updates
-   AgentRun and AgentAction records for QA

#### Deliver

Process

1.  Deploy to the appropriate environment or hand off the artifact to operations or the client.
2.  Notify relevant stakeholders.

Outputs

-   Deployment status
-   Release notes or change log entry
-   AgentRun and AgentAction records for delivery

#### Evaluate

Process

1.  Check if acceptance criteria are met.
2.  Check alignment with feature vision.
3.  Record metrics such as time to value, defects, and usage signals if available.

Outputs

-   Evaluation notes
-   Updated ImplementationDocument
-   AgentRun and AgentAction records for evaluation

#### Improve

Process

1.  Create follow-up work if gaps or improvement opportunities are found.
2.  Feed learnings back into process templates and plan documents.

Outputs

-   New or updated WorkItems
-   Updated process templates
-   AgentRun and AgentAction records for improvement

### Agent Hooks

-   Dev Agent
    -   Spec, implement, and write tests.
-   QA Agent
    -   Generate test cases from Gherkin and evaluate outcomes.
-   Release Agent
    -   Package, deploy, and notify.
-   Eval Agent
    -   Compare outcome against acceptance criteria and feature vision.
    -   Update ImplementationDocument.
