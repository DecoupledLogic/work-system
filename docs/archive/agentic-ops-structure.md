# AgenticOps Agents

These agents work collaboratively to iteratively define, refine, and detail the understanding of a product. They engage users and stakeholders to ensure a clear alignment between vision and delivery.

## Conductor Agent

### Mission

Run the system to target outcomes. Keep flow healthy, keep WIP within limits, keep promises on scope, schedule, and cost. Detect anomalies early and fix them before they turn into fires.

### Scope of control

-   Release control. Decide what enters the system and when. Enforce entry criteria. Gate new work on WIP and risk.
-   Flow control. Set per stage WIP limits, service classes, and explicit policies. Balance load across milestone agents.
-   Sensing and telemetry. Collect events from every agent. Maintain real time views of throughput, cycle time, queue sizes, aging WIP, and flow efficiency.
-   Anomaly detection. Identify blocked work, starving queues, breached SLOs, cost drift, and quality regressions.
-   Optimization. Suggest and, when allowed, implement changes to WIP, assignments, batching, and priorities. Trigger experiments and evaluate outcomes.
-   Governance. Enforce safety, approvals, and audit trails. Every action is traceable.

### Control loop

Sense → Analyze → Decide → Act → Learn

-   Sense. Subscribe to the event bus. Ingest work item state changes, deploy events, eval scores, cost ticks.
-   Analyze. Compute rolling metrics and control charts. Use SPC, EWMA, and simple change point tests. Compare to SLOs and guardrails.
-   Decide. Pick an action from a policy table. Prefer small reversible moves first.
-   Act. Call milestone or functional agents with work orders. Some actions are advisory, some are automatic based on policy.
-   Learn. Record effect size. Update policy weights.

### Policies that keep it deterministic

Use a small rules engine first. Fall back to an LLM only for ambiguous cases. All decisions log their rule and evidence.

```yaml
policies:
  release:
    rule: "Do not pull new work if WIP(stage) >= limit OR critical bottleneck open"
    on_true: "queue work with reason"
    on_false: "pull next by priority, due, and class_of_service"
  aging_wip:
    rule: "if item_age > p90_age(stage) then escalate"
    actions: ["request split", "swap assignee", "raise priority", "unblock dependency"]
  bottleneck:
    rule: "if arrival_rate(stage) > service_rate(stage) for 3 intervals then reduce upstream WIP"
    actions: ["lower WIP upstream", "add capacity via reassignment", "rebalance scope"]
  quality_regression:
    rule: "if eval_score_7d < target and trending down then gate release"
    actions: ["route to Evaluator", "open defect", "trigger rollback"]
  cost_drift:
    rule: "if run_rate > budget_band then notify Bookkeeper and throttle expensive jobs"
    actions: ["schedule cheaper runs", "batch tasks", "pause non critical experiments"]
```

### Work item model

Conductor reasons over a standard work item. Keep it simple and visible.

```yaml
work_item:
  id: WR-1427
  milestone: Inception
  deliverable: Technical Blueprint
  state: InProgress
  class_of_service: Standard
  priority: 3
  due: 2025-09-05
  wip_slot: inception.writer
  owner_operator: cbryant
  owner_agent: WriterAgent
  age_days: 6
  blocked: false
  metrics:
    cycle_time_d: 0
    touch_time_h: 3.5
    queue_time_h: 18.0
    eval_score: 0.0
```

### Signals and KPIs the Conductor watches

-   Throughput per week and per stage
-   Cycle time distribution and 85th percentile
-   Aging WIP list, with SLA timers
-   Flow efficiency touch time over total time
-   Bottleneck location arrival rate vs service rate
-   Quality eval scores, PR failure rate, escaped defects
-   Cost run rate vs budget, cost per deliverable
-   Predictability due date hit rate and variance

### Example actions

-   Release. Admit two Discovery items, hold third due to WIP. Reason logged.
-   Rebalance. Technical Blueprint aging above p90. Split into two tasks and reassign one to a second Writer Agent instance.
-   Bottleneck. Construction queue growing. Lower upstream WIP and move one Engineer Agent from Elaboration to Construction for 3 days.
-   Quality gate. Baseline model eval below target. Block Prod Deploy and open a remediation work item with steps.
-   Cost control. Training jobs exceeding budget band. Shift nightly schedule, reduce parallelism, and notify Bookkeeper.

### Rights and guardrails

-   Advisory by default. Conductor proposes, humans approve inside the Kanban or roadmap view.
-   Automatic within bounds. Conductor can auto act inside policy bands such as small WIP nudges or safe reassignments.
-   Escalate on risk. Any action that changes scope, deadlines, or budget requires human approval or a signed policy.

### Implementation sketch in your stack

-   State and events. Postgres with event tables and materialized views. Event schema is append only with operator_id, agent_id, item_id, from_state, to_state, timestamps.
-   Metrics. Background workers compute windows and control charts. Store derivatives for quick dashboards.
-   Routing. Deterministic routing table. Conductor calls milestone agents or functional agents with typed work orders.
-   Reasoning. Rules first. Small model for text classification and anomaly notes when needed.
-   Evaluation. Send actions and outcomes to Nucleus so you can score policy effectiveness.
-   UI. Value Train board with two extras: Bottleneck strip and Aging WIP strip. Each item shows reason for its current state and last Conductor decision.

### Sample work order

```yaml
work_order:
  id: WO-311
  from: Conductor
  to: InceptionAgent
  objective: Reduce aging WIP in writer lane
  reason: item WR-1427 age 6d exceeds p90 4d
  actions:
    - type: split
      item: WR-1427
      new_items:
        - "TB Blueprint Sections 1 to 4"
        - "TB Blueprint Sections 5 to 8"
    - type: reassign
      target_lane: inception.writer
      capacity_add: 1
  due: 2025-08-30
```

### Where this leaves the other agents

-   Milestone agents remain the milestone owners.
-   Functional agents remain the doers.
-   Conductor coordinates the whole line, protects flow, and proves it with logs.

## Milestone Agents

These are the milestone orchestrators. They plan work, assign it, and accept it. They do not write, design, or deploy. They route.

### Opportunity Agent

Purpose

Shepherds opportunity summaries and SWAG. Opens the loop and frames scope.

### Discovery Agent

Purpose

Establishes the foundational understanding of the product's purpose and strategic objectives. Manages research reports, briefs, and draft SOW. Produces the inputs the rest of the system depends on.

Activities

-   Conduct user interviews to capture pain points and desired outcomes.
-   Facilitate workshops to align stakeholder expectations.
-   Prioritize epics and features based on strategic value and feasibility.

Persona

You are the visionary. Your goal is to establish the foundational understanding of the product's purpose, target users, and strategic objectives. You focus on the high-level "why" and "what" of the product.

Tone

Inspirational, strategic, and user-focused.

### Inception Agent

Purpose

Coordinates UX and technical blueprints, FinOps and GTM work. Translates high-level vision into actionable product requirements. Turns intent into a delivery plan.

Activities

-   Work with the Discovery Agent to decompose features into user stories.
-   Collaborate with the Research Agent to ensure stories align with validated user needs.
-   Define acceptance criteria for each story.

Persona

You are the translator. Your role is to convert strategic direction into actionable product requirements and user stories. You answer "how" at a high level, bridging the gap between vision and execution.

Tone

Pragmatic, structured, and collaborative.

### Elaboration Agent

Purpose

Drives requirements, change requests, and task specs. Keeps the backlog healthy and testable. Refines user stories into detailed specifications and tasks for execution.

Activities

-   Collaborate with product teams to ensure stories are technically feasible and aligned with design principles.
-   Break down stories into tasks, estimating effort and dependencies.
-   Define test cases and criteria for validating story completion.

Persona

You are the executor. Your purpose is to refine user stories into detailed specifications and actionable tasks. You answer "how" at a granular level to guide development teams.

Tone

Precise, technical, and execution-focused.

### Construction Agent

Purpose

Runs repo setup, coding, evaluation, and deploys. Owns build and release readiness.

### Transition Agent

Purpose

Prepares handover and training artifacts. Closes the loop with clean cutover.

### Maintenance Agent

Purpose

Watches reliability and keeps the system alive. Records fixes, patches, and service notes.

## Functional Agents

Cut the sprawl by function, not by document. Most deliverables are templates plus content. Let these roles do the doing.

### Analyst Agent

Extracts, compares, and forecasts. Covers CAC, ROI, cost optimizations, and unit economics.

### Bookkeeper Agent

Specializes in FinOps and accounting views. Owns budget risk, cost per transaction, and financial reporting.

### Communicator Agent

Creates outward facing collateral such as emails, press release, investor teaser, pitch deck, and positioning statements.

### Designer Agent

Produces UX flows, screens, components, and Figma prototypes.

### DevOps Agent

Owns CI and CD, GitHub Actions, infrastructure, environment configs, monitoring and logging.

### Engineer Agent

Writes code, database scripts, sets up repositories, and scaffolds services. Can author Infrastructure as Code modules handed to DevOps.

### Evaluator Agent

Handles unit tests, integration tests, end-to-end tests, dataset evaluation, baseline model scoring, PR checks, UAT, and acceptance gates.

### Research Agent

Purpose

Provides data-driven insights to validate and inform the product direction. Turns raw interviews, surveys, and market data into personas, JTBD, journeys, competitive analysis, pricing inputs, and success metrics.

Activities

-   Perform user interviews and surveys.
-   Analyze competitor strengths, weaknesses, opportunities, and threats (SWOT).
-   Conduct market analysis to align product development with market demands.

Persona

You are the investigator. Your mission is to gather and synthesize insights from user research, competitor analysis, and market trends. You focus on answering "who" and "where" to ensure the product meets real-world needs.

Tone

Analytical, data-driven, and detail-oriented.

### Writer Agent

Purpose

Given a template and content data, produces any document in your catalog such as Opportunity Summary, Research Report, Technical Blueprint, Go to Market brief, or SOW.

## Deterministic Routing

Make selection simple and traceable. Tag each deliverable with two fields: `type` and `capability`. The Conductor agent reads those tags and routes to one sub agent.

-   type: document routes to Writer
-   type: analysis routes to Analyst or Bookkeeper
-   type: design routes to Designer
-   type: code routes to Engineer
-   type: infra routes to DevOps
-   type: evaluation routes to Evaluator
-   type: communication routes to Communicator
-   type: research routes to Research

You can keep a short alias map for common deliverables so routing never guesses.

## Deliverables

Store deliverable definitions in a small YAML so milestone agents can plan and route without custom glue.

```yaml
deliverables:
  - name: Technical Blueprint
    milestone: Inception
    type: document
    capability: writer
    template: templates/technical-blueprint.md
    inputs:
      - discovery/discovery-summary.md
      - discovery/product-brief.md
      - research/research-report.md
    accepts:
      - inception/architecture-diagram.png
    outputs:
      - inception/technical-blueprint.md

  - name: GitHub Actions
    milestone: Construction
    type: infra
    capability: devops
    template: templates/github-actions.yml
    inputs:
      - construction/repo-config.json
    outputs:
      - .github/workflows/ci.yml

  - name: ROI Calculator
    milestone: Inception
    type: analysis
    capability: analyst
    template: templates/roi-calculator.xlsx
    inputs:
      - finops/cost-forecast.csv
      - finops/revenue-forecast.csv
    outputs:
      - finops/roi-calculator.xlsx
```

This produces an auditable path:

`Conductor Agent > Milestone Agent > Deliverable > Sub Agent > Template > Output`

Log the chain with a single line per step. For example:

```
[route] Inception > Technical Blueprint > Writer
[run] writer using templates/technical-blueprint.md
[input] discovery-summary.md, product-brief.md, research-report.md
[output] technical-blueprint.md v1.3
```

### Opportunity

```Code
deliverables:
  - name: Opportunity Summary 
    milestone: Opportunity 
    type: document 
    capability: writer 
    template: templates/opportunity/opportunity-summary.md
    inputs:
      - 
    outputs:
      - opportunity/opportunity-summary.md

  - name: SWAG 
    milestone: Opportunity 
    type: analysis 
    capability: analyst 
    template: templates/opportunity/swag-estimate.xlsx
    inputs:
      - 
    outputs:
      -
```

### Discovery

```Code
-   name: Discovery Summary

    milestone: Discovery
    type: document
    capability: writer
    template: templates/discovery-summary.md

-   name: Product Brief
    milestone: Discovery
    type: document
    capability: writer
    template: templates/product-brief.md

-   name: Research Report  
    milestone: Discovery  
    type: research  
    capability: research  
    template: templates/research-report.md

-   name: SWAG  
    milestone: Discovery  
    type: analysis  
    capability: analyst  
    template: templates/swag-estimate.xlsx

-   name: SOW  
    milestone: Discovery  
    type: document  
    capability: writer  
    template: templates/sow.md

-   name: Team Onboarding Deck  
    milestone: Discovery  
    type: communication  
    capability: communicator  
    template: templates/team-onboarding-deck.pptxdsa
```

### Inception

```Code
-   name: UX Blueprint  
    milestone: Inception  
    type: design  
    capability: designer  
    template: templates/ux-blueprint.fig

-   name: Personas  
    milestone: Inception  
    type: research  
    capability: research  
    template: templates/personas.md

-   name: Jobs-to-Be-Done  
    milestone: Inception  
    type: research  
    capability: research  
    template: templates/jobs-to-be-done.md

-   name: User Journeys  
    milestone: Inception  
    type: design  
    capability: designer  
    template: templates/user-journeys.md

-   name: Features  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/features.md

-   name: Use Case Canvas  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/use-case-canvas.md

-   name: Screens  
    milestone: Inception  
    type: design  
    capability: designer  
    template: templates/screens.fig

-   name: Components  
    milestone: Inception  
    type: design  
    capability: designer  
    template: templates/components.md

-   name: Figma Prototype  
    milestone: Inception  
    type: design  
    capability: designer  
    template: templates/figma-prototype.fig

-   name: AI Prototype  
    milestone: Inception  
    type: code  
    capability: engineer  
    template: templates/ai-prototype-plan.md

-   name: Technical Blueprint  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/technical-blueprint.md

-   name: Purpose and Scope  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/purpose-and-scope.md

-   name: Tech Stack  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/tech-stack.md

-   name: Domain Model  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/domain-model.md

-   name: Roles and Permissions  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/roles-and-permissions.md

-   name: Contracts  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/contracts.md

-   name: Invariants  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/invariants.md

-   name: Commands  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/commands.md

-   name: Queries  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/queries.md

-   name: Events  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/events.md

-   name: State  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/state.md

-   name: Data Flow  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/data-flow.md

-   name: Error Handling  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/error-handling.md

-   name: App  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/app.md

-   name: Backend  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/backend.md

-   name: AI Model  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/ai-model.md

-   name: IoT  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/iot.md

-   name: Infrastructure and Deployment  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/infrastructure-and-deployment.md

-   name: Monitoring and Logging  
    milestone: Inception  
    type: document  
    capability: devops  
    template: templates/monitoring-and-logging.md

-   name: Performance  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/performance.md

-   name: Runbook  
    milestone: Inception  
    type: document  
    capability: devops  
    template: templates/runbook.md

-   name: Architecture Diagram  
    milestone: Inception  
    type: design  
    capability: designer  
    template: templates/architecture-diagram.drawio

-   name: Resource Inventory  
    milestone: Inception  
    type: document  
    capability: devops  
    template: templates/resource-inventory.md

-   name: FinOps Blueprint  
    milestone: Inception  
    type: analysis  
    capability: bookkeeper  
    template: templates/finops-blueprint.xlsx

-   name: CAC Forecasts  
    milestone: Inception  
    type: analysis  
    capability: analyst  
    template: templates/cac-forecasts.xlsx

-   name: Revenue Forecasts  
    milestone: Inception  
    type: analysis  
    capability: analyst  
    template: templates/revenue-forecasts.xlsx

-   name: Cost Forecast  
    milestone: Inception  
    type: analysis  
    capability: bookkeeper  
    template: templates/cost-forecast.xlsx

-   name: Cost Per Transaction  
    milestone: Inception  
    type: analysis  
    capability: bookkeeper  
    template: templates/cost-per-transaction.xlsx

-   name: Cost Tags  
    milestone: Inception  
    type: analysis  
    capability: bookkeeper  
    template: templates/cost-tags.md

-   name: ROI  
    milestone: Inception  
    type: analysis  
    capability: analyst  
    template: templates/roi.md

-   name: ROI Calculator  
    milestone: Inception  
    type: analysis  
    capability: analyst  
    template: templates/roi-calculator.xlsx

-   name: Unit Economics  
    milestone: Inception  
    type: analysis  
    capability: analyst  
    template: templates/unit-economics.xlsx

-   name: Scaling Plan  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/scaling-plan.md

-   name: Budget Risk  
    milestone: Inception  
    type: analysis  
    capability: bookkeeper  
    template: templates/budget-risk.xlsx

-   name: Cost Optimizations  
    milestone: Inception  
    type: analysis  
    capability: analyst  
    template: templates/cost-optimizations.md

-   name: Go-to-Market Blueprint  
    milestone: Inception  
    type: communication  
    capability: communicator  
    template: templates/go-to-market-blueprint.md

-   name: Positioning  
    milestone: Inception  
    type: communication  
    capability: communicator  
    template: templates/positioning.md

-   name: Target  
    milestone: Inception  
    type: research  
    capability: research  
    template: templates/target-market.md

-   name: ICP  
    milestone: Inception  
    type: research  
    capability: research  
    template: templates/icp.md

-   name: Value Proposition  
    milestone: Inception  
    type: communication  
    capability: communicator  
    template: templates/value-proposition.md

-   name: Channels  
    milestone: Inception  
    type: communication  
    capability: communicator  
    template: templates/channels.md

-   name: Business Model  
    milestone: Inception  
    type: communication  
    capability: communicator  
    template: templates/business-model.md

-   name: Pricing Strategy  
    milestone: Inception  
    type: communication  
    capability: communicator  
    template: templates/pricing-strategy.md

-   name: Strategic Business Analysis  
    milestone: Inception  
    type: analysis  
    capability: analyst  
    template: templates/strategic-business-analysis.md

-   name: Roadmap  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/roadmap.md

-   name: Success Metrics  
    milestone: Inception  
    type: research  
    capability: research  
    template: templates/success-metrics.md

-   name: Press Release  
    milestone: Inception  
    type: communication  
    capability: communicator  
    template: templates/press-release.md

# Science + Engineering Deliverables
-   name: Data Inventory
    milestone: Discovery
    type: data
    capability: engineer
    template: templates/discovery/data-inventory.md

-   name: Feature Catalog
    milestone: Discovery
    type: analysis
    capability: analyst
    template: templates/discovery/feature-catalog.md

-   name: Observation Log
    milestone: Discovery
    type: analysis
    capability: analyst
    template: templates/discovery/observation-log.md

-   name: Intuition Notes
    milestone: Discovery
    type: document
    capability: writer
    template: templates/discovery/intuition-notes.md

-   name: Theory Note
    milestone: Discovery
    type: research
    capability: research
    template: templates/discovery/theory-note.md

-   name: Thesis Note
    milestone: Discovery
    type: document
    capability: writer
    template: templates/discovery/thesis-note.md

-   name: Use Case Brief
    milestone: Discovery
    type: document
    capability: writer
    template: templates/discovery/use-case-brief.md

-   name: Hypothesis Note
    milestone: Discovery
    type: document
    capability: writer
    template: templates/discovery/hypothesis-note.md

-   name: Baseline Report
    milestone: Inception
    type: analysis
    capability: analyst
    template: templates/inception/baseline-report.md

-   name: Experiment Design
    milestone: Inception
    type: document
    capability: writer
    template: templates/inception/experiment-design.md

-   name: Design Review Notes
    milestone: Inception
    type: document
    capability: writer
    template: templates/inception/workflow:design-review-notes.md

-   name: Investor Teaser  
    milestone: Inception  
    type: communication  
    capability: communicator  
    template: templates/investor-teaser.pptx

-   name: Delivery Plan  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/delivery-plan.md

-   name: Vision  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/vision.md

-   name: Scope  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/scope.md

-   name: Workstreams  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/workstreams.md

-   name: Schedule  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/schedule.md

-   name: Constraints  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/constraints.md

-   name: Risks and Mitigations  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/risks-and-mitigations.md

-   name: Budget  
    milestone: Inception  
    type: analysis  
    capability: bookkeeper  
    template: templates/budget.xlsx

-   name: Pitch Deck  
    milestone: Inception  
    type: communication  
    capability: communicator  
    template: templates/pitch-deck.pptx

-   name: SOW  
    milestone: Inception  
    type: document  
    capability: writer  
    template: templates/sow.md

-   name: Kickoff Deck  
    milestone: Inception  
    type: communication  
    capability: communicator  
    template: templates/kickoff-deck.pptx
```

### Elaboration

```Code
-   name: Executive Summary Deck  
    milestone: Elaboration  
    type: communication  
    capability: communicator  
    template: templates/executive-summary-deck.pptx

-   name: Roadmap  
    milestone: Elaboration  
    type: document  
    capability: writer  
    template: templates/roadmap.md

-   name: Kanban Board  
    milestone: Elaboration  
    type: infra  
    capability: devops  
    template: templates/kanban-board.json

-   name: Product Requirements Document  
    milestone: Elaboration  
    type: document  
    capability: writer  
    template: templates/prd.md

-   name: Change Request Document  
    milestone: Elaboration  
    type: document  
    capability: writer  
    template: templates/change-request.md

-   name: Problem Analysis  
    milestone: Elaboration  
    type: analysis  
    capability: analyst  
    template: templates/problem-analysis.md

-   name: Decision Record  
    milestone: Elaboration  
    type: document  
    capability: writer  
    template: templates/decision-record.md

-   name: Task Specification  
    milestone: Elaboration  
    type: document  
    capability: writer  
    template: templates/task-specification.md

-   name: Model Card
    milestone: Elaboration
    type: evaluation
    capability: evaluator
    template: templates/elaboration/model-card.md

-   name: Data Sheet
    milestone: Elaboration
    type: evaluation
    capability: evaluator
    template: templates/elaboration/data-sheet.md

-   name: Monitoring Rubric
    milestone: Elaboration
    type: evaluation
    capability: evaluator
    template: templates/elaboration/monitoring-rubric.md

-   name: Production Readiness Checklist
    milestone: Elaboration
    type: evaluation
    capability: devops
    template: templates/elaboration/production-readiness.md
```

### Construction

```Code
-   name: Coding Agents  
    milestone: Construction  
    type: code  
    capability: engineer  
    template: templates/coding-agents.md
-   name: GitHub Repository  
    milestone: Construction  
    type: code  
    capability: engineer  
    template: templates/repo-init.json
-   name: Code Initialization  
    milestone: Construction  
    type: code  
    capability: engineer  
    template: templates/code-initialization.md
-   name: GitHub Actions  
    milestone: Construction  
    type: infra  
    capability: devops  
    template: templates/github-actions.yml

-   name: Infrastructure as Code  
    milestone: Construction  
    type: infra  
    capability: devops  
    template: templates/iac.tf

-   name: Branch  
    milestone: Construction  
    type: code  
    capability: engineer  
    template: templates/branching-strategy.md

-   name: PR  
    milestone: Construction  
    type: code  
    capability: engineer  
    template: templates/pull-request.md

-   name: Dev Deploy  
    milestone: Construction  
    type: infra  
    capability: devops  
    template: templates/dev-deploy.md

-   name: PR/QA Deploy  
    milestone: Construction  
    type: infra  
    capability: devops  
    template: templates/pr-qa-deploy.md

-   name: UAT/Beta Deploy  
    milestone: Construction  
    type: infra  
    capability: devops  
    template: templates/uat-beta-deploy.md

-   name: Prod Deploy  
    milestone: Construction  
    type: infra  
    capability: devops  
    template: templates/prod-deploy.md

-   name: Eval Service  
    milestone: Construction  
    type: evaluation  
    capability: evaluator  
    template: templates/eval-service.md

-   name: Baseline Model  
    milestone: Construction  
    type: code  
    capability: engineer  
    template: templates/baseline-model.md

-   name: Data Collection Ruberick  
    milestone: Construction  
    type: evaluation  
    capability: evaluator  
    template: templates/data-collection-ruberick.md

-   name: Data Collection Protocol  
    milestone: Construction  
    type: document  
    capability: writer  
    template: templates/data-collection-protocol.md

-   name: Data Collection Specification  
    milestone: Construction  
    type: document  
    capability: writer  
    template: templates/data-collection-specification.md

-   name: Dataset Evaluation  
    milestone: Construction  
    type: evaluation  
    capability: evaluator  
    template: templates/dataset-evaluation.md

-   name: Experiment Results
    milestone: Construction
    type: evaluation
    capability: evaluator
    template: templates/construction/experiment-results.md
```

### Transition

### Maintenance
