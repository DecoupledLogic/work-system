# Conductor Agent

## Mission

Run the system to target outcomes. Keep flow healthy, keep WIP within limits, keep promises on scope, schedule, and cost. Detect anomalies early and fix them before they turn into fires.

## Scope of control

-   Release control. Decide what enters the system and when. Enforce entry criteria. Gate new work on WIP and risk.
-   Flow control. Set per stage WIP limits, service classes, and explicit policies. Balance load across milestone agents.
-   Sensing and telemetry. Collect events from every agent. Maintain real time views of throughput, cycle time, queue sizes, aging WIP, and flow efficiency.
-   Anomaly detection. Identify blocked work, starving queues, breached SLOs, cost drift, and quality regressions.
-   Optimization. Suggest and, when allowed, implement changes to WIP, assignments, batching, and priorities. Trigger experiments and evaluate outcomes.
-   Governance. Enforce safety, approvals, and audit trails. Every action is traceable.

## Control loop

Sense → Analyze → Decide → Act → Learn

-   Sense. Subscribe to the event bus. Ingest work item state changes, deploy events, eval scores, cost ticks.
-   Analyze. Compute rolling metrics and control charts. Use SPC, EWMA, and simple change point tests. Compare to SLOs and guardrails.
-   Decide. Pick an action from a policy table. Prefer small reversible moves first.
-   Act. Call milestone or functional agents with work orders. Some actions are advisory, some are automatic based on policy.
-   Learn. Record effect size. Update policy weights.

## Policies that keep it deterministic

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

## Work item model

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

## Signals and KPIs the Conductor watches

-   Throughput per week and per stage
-   Cycle time distribution and 85th percentile
-   Aging WIP list, with SLA timers
-   Flow efficiency touch time over total time
-   Bottleneck location arrival rate vs service rate
-   Quality eval scores, PR failure rate, escaped defects
-   Cost run rate vs budget, cost per deliverable
-   Predictability due date hit rate and variance

## Example actions

-   Release. Admit two Discovery items, hold third due to WIP. Reason logged.
-   Rebalance. Technical Blueprint aging above p90. Split into two tasks and reassign one to a second Writer Agent instance.
-   Bottleneck. Construction queue growing. Lower upstream WIP and move one Engineer Agent from Elaboration to Construction for 3 days.
-   Quality gate. Baseline model eval below target. Block Prod Deploy and open a remediation work item with steps.
-   Cost control. Training jobs exceeding budget band. Shift nightly schedule, reduce parallelism, and notify Bookkeeper.

## Rights and guardrails

-   Advisory by default. Conductor proposes, humans approve inside the Kanban or roadmap view.
-   Automatic within bounds. Conductor can auto act inside policy bands such as small WIP nudges or safe reassignments.
-   Escalate on risk. Any action that changes scope, deadlines, or budget requires human approval or a signed policy.

## Implementation sketch in your stack

-   State and events. Postgres with event tables and materialized views. Event schema is append only with operator_id, agent_id, item_id, from_state, to_state, timestamps.
-   Metrics. Background workers compute windows and control charts. Store derivatives for quick dashboards.
-   Routing. Deterministic routing table. Conductor calls milestone agents or functional agents with typed work orders.
-   Reasoning. Rules first. Small model for text classification and anomaly notes when needed.
-   Evaluation. Send actions and outcomes to Nucleus so you can score policy effectiveness.
-   UI. Value Train board with two extras: Bottleneck strip and Aging WIP strip. Each item shows reason for its current state and last Conductor decision.

## Sample work order

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

## Where this leaves the other agents

-   Milestone agents remain the milestone owners.
-   Functional agents remain the doers.
-   Conductor coordinates the whole line, protects flow, and proves it with logs.
