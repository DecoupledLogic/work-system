# Processing

## Requests

Requests can arrive as an unstructured plain English request from an operator or as a structured event, work order, or work item from an up-stream agent.

## Routing

Agents possess a router, which is used to direct requests.

1.  The router has a deterministic rules engine that maps tags and task spec (domain, artifact, and verb) to an agent.
2.  The router has a probabilistic classifier model that accepts text and infers the agent with a confidence score.
3.  The router takes the request and the destination agent and generates a work order.
4.  The router uses function/tool calling to invoke the agent and handoff the work order.

See OpenAI Function Calling (patterns generalize; any SDK), and similar API guides. ([*OpenAI Platform*](https://platform.openai.com/docs/guides/function-calling?utm_source=chatgpt.com), [*OpenAI Cookbook*](https://cookbook.openai.com/examples/reasoning_function_calls?utm_source=chatgpt.com), [*Together.ai Docs*](https://docs.together.ai/docs/function-calling?utm_source=chatgpt.com))

Routing rules require using the deterministic rules engine first then the classifier model:

-   If task has an agent tag, then invoke the tagged agent.
-   Else if task domain, artifact, and verb exactly matches an agent, then invoke the matched agent.
-   Else call a small LLM “Router” that returns {agent, confidence}; require confidence ≥ 0.7 to auto route to agent, else escalate to operator.

Handoff contract:

-   Router attaches a work order.
-   Receiving agent must reply with a one-shot plan and ask for missing input *before* doing work.

## Pipeline

Created → Ready → Validated → Routed → InProgress → Completed → Reviewed → Evaluated → Approved → Done → Closed

## Create

1.  Conductor
    1.  Receives a request from an operator or generates work order from an upstream event.
    2.  Routes the work order to the appropriate Milestone Agent.
2.  Milestone Agent
    1.  Receives work order from Conductor.
    2.  Analyzes the work order for deliverables.
    3.  For each deliverable,
        1.  Creates the necessary work item from the deliverable templates.
        2.  Fills required work item fields (deliverable, type, capability, io, owners).
        3.  Sets work item state to Created.
        4.  Emit WorkItemCreated event.
        5.  When stage entry criteria are met,
            1.  Set work item state to Ready.
            2.  Emit WorkItemReady event.

## Validate

1.  Conductor
    1.  Runs pre-admission checks on Ready work items.
    2.  If stage WIP ≥ limit or owner operator WIP ≥ limit,
        1.  Emit WorkItemBlockedByWip event.
    3.  If io.inputs or io.outputs path do not start with clients/{client}/,
        1.  Emit WorkItemIoPathInvalidated event.
        2.  This should go back to Milestone Agent for correction and after 3 tries escalated to operator.
    4.  If any io.inputs data do not exist,
        1.  Emit WorkItemIoInputDoesNotExist event.
    5.  If owner agent is not authorized for client and capability,
        1.  Emit WorkItemAgentUnauthorized event.
    6.  If class of service is FixedDate and due date is null or empty.
        1.  Emit WorkItemFixedDateInvalidated
    7.  Set state to Validated.
    8.  Emit WorkItemValidated.

## Route

1.  Conductor
    1.  Resolves work item type, capability, milestone, and stage.
    2.  Assigns wip slot (e.g., inception.writer) and hands the item to owner agent.
    3.  Logs routing rule and decision.
    4.  Set state to Routed.
    5.  Emit WorkItemRouted event.

## Execute

1.  Functional Agent
    1.  Set state to InProgress.
    2.  Emit WorkItemInProgress event.
    3.  Reads data from io.inputs.
    4.  Writes draft artifacts under versions/\* for this work item’s tenant namespace.
    5.  On success, finalizes artifacts for this version (do not write directly to latest/\*).
    6.  On failure,
    7.  Set state to Completed.
    8.  Emit WorkItemCompleted.

## Review

1.  Conductor
    1.  Reviews the Completed work item for completeness and non-gated checks.
    2.  If a quality gate applies, routes to Evaluator and emits WorkItemPullRequest.
    3.  Else, sets state → Reviewed and emits WorkItemReviewed.

## Evaluate

1.  Evaluator Agent
    1.  Runs quality gates on the version produced in Execute.
    2.  Records metrics.eval_score.
    3.  Sets state → Evaluated.
    4.  Emits WorkItemEvaluated.

## Approve

1.  Conductor (or Policy engine)
    1.  Applies approval policies/thresholds using Evaluated outputs and score(s).
    2.  If passed: sets state → Approved and emits WorkItemApproved.
    3.  If failed: returns item to InProgress with reason and emits WorkItemReturned (include from_state=Approved, to_state=InProgress, reason).

## Release / Deliver

1.  Conductor / DevOps
    1.  When Approved and deliverable is accepted for release or delivery, update latest/\* pointers and any env pointers per promotion policy.
    2.  Sets state → Done.
    3.  Emits WorkItemDone.

## Close

1.  Conductor
    1.  Verifies all io.outputs are under the correct client prefix and that pointers reference only approved versions.
    2.  Archives the work item with final metrics and immutable audit trail.
    3.  Sets state → Closed.
    4.  Emits WorkItemClosed.

## Background Metrics Job

No state changes.

-   Consumes lifecycle events to compute: touch_time_h, queue_time_h, cycle_time_d, blocked_time_h, lead_time_d.
-   Calculates age_days from audit.created_at.
-   Updates work_item.metrics and age_days.
-   Emits WorkItemMetricsUpdated.

Note

-   Blocked is an overlay at any active state (e.g., InProgress); use WorkItemBlocked/WorkItemUnblocked without changing the backbone state.
-   Only explicit actors (Conductor, Functional Agent, Evaluator, DevOps) transition states; background jobs never flip states.

# Work Order

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

## Definitions

### Identity

| Field | Type   | Required | Description                            |
|-------|--------|----------|----------------------------------------|
| id    | string | true     | Unique work order id (e.g., `WO-311`). |

### Participants

| Field | Type   | Required | Description                                          |
|-------|--------|----------|------------------------------------------------------|
| from  | string | true     | Issuer/actor (e.g., `Conductor`).                    |
| to    | string | true     | Target agent or agent role (e.g., `InceptionAgent`). |

### Intent

| Field     | Type   | Required | Description                                             |
|-----------|--------|----------|---------------------------------------------------------|
| objective | string | true     | Clear, human-readable goal of the order.                |
| reason    | string | false    | Why the order exists (signal, KPI breach, event cause). |
| due       | date   | false    | ISO date for order completion SLA.                      |

### Actions

Work orders consist of a sequence of deliverable-focused actions.

| Field          | Type  | Required | Description                                                   |
|----------------|-------|----------|---------------------------------------------------------------|
| actions        | array | true     | Ordered list of deliverable actions.                          |
| actions[].type | enum  | true     | `Produce` \| `Evaluate` \| `Approve` \| `Release` \| `Close`. |

#### Action Types

###### produce

Generate a deliverable from inputs.

| Field       | Type         | Required | Description                                                     |
|-------------|--------------|----------|-----------------------------------------------------------------|
| deliverable | string       | true     | Path of deliverable (e.g., `inception/technical-blueprint.md`). |
| inputs      | string array | false    | Source paths.                                                   |
| outputs     | string array | false    | Target paths (usually the deliverable itself).                  |

###### evaluate

Assess deliverable quality, compute metrics.

| Field       | Type         | Required | Description                               |
|-------------|--------------|----------|-------------------------------------------|
| deliverable | string       | true     | Deliverable under evaluation.             |
| criteria    | object array | false    | Quality gates (e.g., completeness ≥ 0.8). |

###### approve

Apply policy check and mark deliverable as releasable.

| Field       | Type   | Required | Description              |
|-------------|--------|----------|--------------------------|
| deliverable | string | true     | Deliverable to approve.  |
| approver    | string | false    | Actor granting approval. |

###### release

Promote deliverable to environment pointer.

| Field       | Type   | Required | Description                                  |
|-------------|--------|----------|----------------------------------------------|
| deliverable | string | true     | Deliverable to release.                      |
| env         | enum   | true     | `Dev` \| `QA` \| `UAT` \| `Stage` \| `Prod`. |

###### close

Archive deliverable and finalize metrics.

| Field       | Type   | Required | Description           |
|-------------|--------|----------|-----------------------|
| deliverable | string | true     | Deliverable to close. |

### Audit

| Field         | Type     | Required | Description                     |
|---------------|----------|----------|---------------------------------|
| created_at    | datetime | false    | When created.                   |
| created_by    | string   | false    | Who created it.                 |
| updated_at    | datetime | false    | Last update time.               |
| updated_by    | string   | false    | Who last updated it.            |
| last_event_id | string   | false    | Last applied event id.          |
| version       | integer  | false    | Optimistic concurrency version. |
| etag          | string   | false    | Strong/weak ETag for writes.    |

## Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://agenticops.dev/schemas/work_order.schema.json",
  "title": "Work Order",
  "type": "object",
  "required": ["id", "from", "to", "objective", "actions"],
  "additionalProperties": false,
  "properties": {
    "id": {
      "type": "string",
      "pattern": "^WO-[0-9]+$"
    },
    "from": { "type": "string" },
    "to": { "type": "string" },
    "objective": { "type": "string" },
    "reason": { "type": "string" },
    "due": { "type": "string", "format": "date" },
    "actions": {
      "type": "array",
      "items": { "$ref": "#/$defs/action" },
      "minItems": 1
    },
    "audit": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "created_at": { "type": "string", "format": "date-time" },
        "created_by": { "type": "string" },
        "updated_at": { "type": "string", "format": "date-time" },
        "updated_by": { "type": "string" },
        "last_event_id": { "type": "string" },
        "version": { "type": "integer", "minimum": 0 },
        "etag": { "type": "string" }
      }
    }
  },
  "$defs": {
    "action": {
      "oneOf": [
        { "$ref": "#/$defs/produceAction" },
        { "$ref": "#/$defs/evaluateAction" },
        { "$ref": "#/$defs/approveAction" },
        { "$ref": "#/$defs/releaseAction" },
        { "$ref": "#/$defs/closeAction" }
      ],
      "discriminator": {
        "propertyName": "type",
        "mapping": {
          "produce": "#/$defs/produceAction",
          "evaluate": "#/$defs/evaluateAction",
          "approve": "#/$defs/approveAction",
          "release": "#/$defs/releaseAction",
          "close": "#/$defs/closeAction"
        }
      }
    },
    "produceAction": {
      "type": "object",
      "required": ["type", "deliverable"],
      "properties": {
        "type": { "const": "produce" },
        "deliverable": { "type": "string" },
        "inputs": { "type": "array", "items": { "type": "string" } },
        "outputs": { "type": "array", "items": { "type": "string" } }
      }
    },
    "evaluateAction": {
      "type": "object",
      "required": ["type", "deliverable"],
      "properties": {
        "type": { "const": "evaluate" },
        "deliverable": { "type": "string" },
        "criteria": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "quality_gate": { "type": "string" },
              "threshold": { "type": "number", "minimum": 0, "maximum": 1 }
            }
          }
        }
      }
    },
    "approveAction": {
      "type": "object",
      "required": ["type", "deliverable"],
      "properties": {
        "type": { "const": "approve" },
        "deliverable": { "type": "string" },
        "approver": { "type": "string" }
      }
    },
    "releaseAction": {
      "type": "object",
      "required": ["type", "deliverable", "env"],
      "properties": {
        "type": { "const": "release" },
        "deliverable": { "type": "string" },
        "env": { "type": "string", "enum": ["dev", "qa", "uat", "stage", "prod"] }
      }
    },
    "closeAction": {
      "type": "object",
      "required": ["type", "deliverable"],
      "properties": {
        "type": { "const": "close" },
        "deliverable": { "type": "string" }
      }
    }
  }
}
```

## Storage

Stable path per client/product/project, keyed by work order id. Work orders are small and auditable, so we store the order, its action results, and a pointer to the current status.

```
clients/{client}/{product}/{project}/work-orders/{id}/
  latest.json                 # pointer to the active version
  versions/{iso_datetime}/
    work_order.yaml           # the submitted order (immutable)
    result.json               # optional action-by-action outcomes
    manifest.json             # digests, refs to related work items/events
```

-   `latest.json` is a small pointer: `{ "version": "2025-09-01T17:42:09Z", "etag": "...", "by": "Conductor" }`.
-   All writes go to a new `versions/*`; never edit `latest.json` in place—replace it atomically.

## Example

```yaml
work_order:
  id: WO-412
  from: Conductor
  to: WriterAgent
  objective: Draft technical blueprint
  reason: Epic kickoff, inception stage requires deliverable
  actions:
    - type: produce
      deliverable: inception/technical-blueprint.md
      inputs:
        - clients/DiscoverTec/.../discovery/discovery-summary.md
        - clients/DiscoverTec/.../research/research-report.md
      outputs:
        - clients/DiscoverTec/.../inception/technical-blueprint.md
    - type: evaluate
      deliverable: inception/technical-blueprint.md
      criteria:
        - quality_gate: completeness
          threshold: 0.8
    - type: approve
      deliverable: inception/technical-blueprint.md
    - type: release
      deliverable: inception/technical-blueprint.md
      env: dev
    - type: close
      deliverable: inception/technical-blueprint.md
  due: 2025-09-10
```

## Policies

-   Release policy uses funnel, milestone, and WIP limits per wip_slot.
-   Aging policy uses stage specific p90 thresholds.
-   Cost policy can roll up by `client` and `project` since metrics carry those keys.

### Admission and Validation

-   **Required fields**: `id, from, to, objective, actions`.
-   **Action checks**:
    -   `type` must be one of: `produce, evaluate, approve, release, close`.
    -   `deliverable` paths must belong to the same `(client, product, project)` as the Work Order context.
-   **Issuer/Target**: `from` must be an authorized system role (e.g., Conductor, Operator); `to` must resolve to a valid agent.
-   **Due date**: if `due` present, enforce ISO date format.

### Execution and Routing

-   **Router**:
    -   Deterministic first (tags, domain+artifact+verb).
    -   Classifier fallback must meet confidence ≥ 0.7; else escalate to operator.
-   **Handoff**:
    -   Router attaches the Work Order and invokes the target agent.
    -   Receiving agent must acknowledge with a one-shot plan and request missing inputs before starting.

### Action Processing

-   **Action sequencing**: `actions` are executed in order.
-   **Success**: emit `work_order.action.succeeded`; continue to next action.
-   **Failure**: emit `work_order.action.failed` with `{code, category, retryable, attempt}`; retry/block per policy.
-   **Idempotency**: repeating a Work Order with the same `id` must not cause duplicate deliverables; agents must ensure safe re-execution.

### Error and Retry Policy

-   **No error state**: errors are overlays + events (`work_order.action.failed`).
-   **Retryable categories**: `io, compute, external, concurrency`.
-   **Non-retryable**: `validation, policy, security, integrity`.
-   Default: 3 attempts with exponential backoff + jitter; exhausted retries → escalate to operator.

### Completion

-   **All actions succeeded** → emit `work_order.completed`.
-   **Any action blocked or escalated** → Work Order remains open until operator intervention.
-   Work Orders are immutable once completed; changes require issuing a new order.

### Storage and Audit

-   **Storage layout**: `clients/{client}/{product}/{project}/work-orders/{id}/…`.
-   **Immutability**: every submission written under `versions/*`; `latest.json` is a pointer only.
-   **Audit trail**: include issuer, timestamp, action results, and linked event ids.

# Work Item

## Definitions

### Identity

Identity fields identify the tenant, the product inside that tenant, and the funded engagement. Routing, storage, and access checks use these to partition and isolate client work.

| Field   | Type   | Required | Description                                  |
|---------|--------|----------|----------------------------------------------|
| id      | string | true     | Unique identifier for the work item          |
| title   | string | true     | Short human friendly label                   |
| client  | string | true     | Identifier for the client tenant             |
| product | string | true     | Identifier for the product inside the client |
| project | string | true     | Identifier for the funded engagement         |

### Lifecycle

Where the work item is in its lifecycle. Conductor reports and policies filter by any of these.

| Field     | Type   | Required | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
|-----------|--------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| funnel    | enum   | true     | Intake \| Engage \| Execute \| Deliver \| Monetize \| Retain \| Reactivate                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| milestone | enum   | true     | Attract \| Acquire \| Activate \| Discovery \| Research \| Inception \| Elaboration \| Construction \| Transition \| Monetization \| Maintenance \| Evaluation                                                                                                                                                                                                                                                                                                                                                 |
| stage     | string | true     | Campaign \| Qualify \| Onboard \| Plan \| Research \| UX \| Design \| Marketing \| Web \| Dev \| Hosting \| Managed Services \| Analyze \| Implement \| Validate \| Demo \| Acceptance \| Bill \| Production \| Operate \| Improve                                                                                                                                                                                                                                                                             |
| state     | enum   | true     | Uses a finite state set with allowed transitions.  Created \| Ready \| Validated \| Routed \| InProgress \| Completed \| Reviewed \| Evaluated \| Approved \| Done \| Closed Completed = functional work finished by the acting agent (outputs exist). Reviewed = human PM/Conductor review complete (non-quality gates). Evaluated = quality gates executed, score recorded. Approved = releasable (passes all gates/policies). Done = delivered/accepted (business acceptance). Closed = archived/immutable. |

### Routing

| Field       | Type   | Required | Description                                                                                                          |
|-------------|--------|----------|----------------------------------------------------------------------------------------------------------------------|
| deliverable | string | false    | Canonical name from routing table                                                                                    |
| type        | enum   | false    | Document \| Analysis \| Design \| Code \| Infra \| Evaluation \| Communication \| Research                           |
| capability  | enum   | false    | From the routing file.  Writer \| Analyst \| Designer \| Engineer \| Devops \| Evaluator \| Communicator \| Research |

### IO

All IO paths must be fully qualified and live within the client namespace to prevent cross-tenant reads/writes.

| Field      | Type         | Required | Description                                                               |
|------------|--------------|----------|---------------------------------------------------------------------------|
| io.inputs  | string array | false    | Fully qualified absolute paths or URIs that include the client namespace. |
| io.outputs | string array | false    | Fully qualified absolute paths or URIs that include the client namespace. |

### WIP and Ownership

Conductor limits WIP by class of service, priority, due, slot, and assigned owner.

| Field            | Type    | Required | Description                                                  |
|------------------|---------|----------|--------------------------------------------------------------|
| class_of_service | enum    | false    | Standard \| Expedite \| FixedDate \| Intangible              |
| priority         | integer | false    | 1 is highest priority                                        |
| due              | date    | false    | The ISO date when the work item is expected to be delivered. |
| wip_slot         | string  | true     | The lane key (e.g., inception.writer).                       |
| owner_operator   | string  | true     | The accountable human.                                       |
| owner_agent      | string  | true     | The acting sub agent.                                        |

### Blocked State Overlay

The blocked overlay can be applied over any active state.

| Field          | Type     | Required | Description                                                  |
|----------------|----------|----------|--------------------------------------------------------------|
| Is_blocked     | boolean  | false    | Is currently blocked.                                        |
| blocked_since  | datetime | false    | When the blocked overlay began.                              |
| blocked_reason | string   | false    | Short code, e.g., io.write_denied, eval.service_unavailable. |

### Error State Overlay

The event log is authoritative. This view summarizes the last error for dashboards/ops.

| Field        | Type     | Required | Description                                                                                                        |
|--------------|----------|----------|--------------------------------------------------------------------------------------------------------------------|
| has_error    | boolean  | false    | Whether a recent error exists.                                                                                     |
| at           | datetime | false    | When the last error occurred.                                                                                      |
| actor        | string   | false    | Which agent/service raised it.                                                                                     |
| stage        | string   | false    | Create \| Validate \| Route \| Execute \| Review \| Evaluate \| Approve \| Release                                 |
| code         | string   | false    | Stable error code, snake_case.                                                                                     |
| message      | string   | false    | Truncated, user-safe text.                                                                                         |
| category     | enum     | false    | Validation \| Policy \| Routing \| Io \| Compute \| External \| Security \| Concurrency \| Integrity \| Deployment |
| severity     | enum     | false    | Info \| Warn \| Error \| Critical                                                                                  |
| Is_retryable | boolean  | false    | Whether the system will retry.                                                                                     |
| attempt      | integer  | false    | Consecutive attempt count.                                                                                         |

### Metrics

Computed from lifecycle and overlay events. Do not hand edit metrics.

| Field                   | Type     | Required | Definition                               |
|-------------------------|----------|----------|------------------------------------------|
| age_days                | integer  | false    | Derived from audit.created_at            |
| lead_time_d             | number   | false    | Days from Created → Done                 |
| cycle_time_d            | number   | false    | Days from Ready → Done                   |
| touch_time_h            | number   | false    | Hours of active work while InProgress    |
| queue_time_h            | number   | false    | cycle_time_d \* 24 − touch_time_h        |
| blocked_time_h          | number   | false    | Hours where blocked=true                 |
| eval_score              | number   | false    | Quality/evaluation score (e.g., 0.0–1.0) |
| error_count_total       | integer  | false    | Total error events for this item         |
| error_count_consecutive | integer  | false    | Current consecutive error streak         |
| last_error_at           | datetime | false    | Timestamp of last error                  |

### Audit

Append-only metadata for traceability and concurrency.

| Field         | Type     | Required | Description                    |
|---------------|----------|----------|--------------------------------|
| created_at    | datetime | false    | When the item was created      |
| created_by    | string   | false    | Who created it                 |
| updated_at    | datetime | false    | Last update time               |
| updated_by    | string   | false    | Who last updated it            |
| last_event_id | string   | false    | The last applied event id      |
| version       | integer  | false    | Optimistic concurrency version |
| etag          | string   | false    | Strong/weak ETag for writes    |

## Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://agenticops.dev/schemas/work_item.schema.json",
  "title": "Work Item",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "title",
    "client",
    "product",
    "project",
    "funnel",
    "milestone",
    "stage",
    "state",
    "wip_slot",
    "owner_operator",
    "owner_agent"
  ],
  "properties": {
    "id": { "type": "string", "description": "Unique identifier for the work item" },
    "title": { "type": "string", "description": "Short human friendly label" },
    "client": { "type": "string", "description": "Tenant identifier" },
    "product": { "type": "string", "description": "Product inside the tenant" },
    "project": { "type": "string", "description": "Funded engagement identifier" },
    "funnel": { "$ref": "#/$defs/funnelEnum" },
    "milestone": { "$ref": "#/$defs/milestoneEnum" },
    "stage": { "$ref": "#/$defs/stageEnum" },
    "state": { "$ref": "#/$defs/stateEnum", "description": "Created → Ready → Validated → Routed → InProgress → Completed → Reviewed → Evaluated → Approved → Done → Closed" },
    "deliverable": { "type": "string", "description": "Canonical name from routing table" },
    "type": { "$ref": "#/$defs/typeEnum" },
    "capability": { "$ref": "#/$defs/capabilityEnum" },
    "io": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "inputs": {
          "type": "array",
          "items": { "$ref": "#/$defs/ioPath" },
          "description": "Fully qualified paths/URIs inside client namespace"
        },
        "outputs": {
          "type": "array",
          "items": { "$ref": "#/$defs/ioPath" },
          "description": "Fully qualified paths/URIs inside client namespace"
        }
      }
    },
    "class_of_service": { "$ref": "#/$defs/classOfServiceEnum" },
    "priority": { "type": "integer", "minimum": 1, "description": "1 is highest priority" },
    "due": { "type": "string", "format": "date", "description": "Expected delivery date (ISO)" },
    "wip_slot": { "type": "string", "description": "Lane key (e.g., inception.writer)" },
    "owner_operator": { "type": "string", "description": "Accountable human" },
    "owner_agent": { "type": "string", "description": "Acting sub-agent" },
    "is_blocked": { "type": "boolean", "default": false, "description": "Blocked overlay flag" },
    "blocked_since": { "type": "string", "format": "date-time" },
    "blocked_reason": { "type": "string", "description": "Short code (e.g., io.write_denied)" },
    "error": {
      "type": "object",
      "description": "Last-known error view (event log is source of truth)",
      "additionalProperties": false,
      "properties": {
        "has_error": { "type": "boolean", "default": false },
        "at": { "type": "string", "format": "date-time" },
        "actor": { "type": "string" },
        "stage": { "$ref": "#/$defs/errorStageEnum" },
        "code": { "type": "string" },
        "message": { "type": "string" },
        "category": { "$ref": "#/$defs/errorCategoryEnum" },
        "severity": { "$ref": "#/$defs/errorSeverityEnum" },
        "is_retryable": { "type": "boolean" },
        "attempt": { "type": "integer", "minimum": 0 }
      }
    },
    "metrics": {
      "type": "object",
      "description": "Computed from events; do not hand edit",
      "readOnly": true,
      "additionalProperties": false,
      "properties": {
        "age_days": { "type": "integer", "minimum": 0 },
        "lead_time_d": { "type": "number", "minimum": 0 },
        "cycle_time_d": { "type": "number", "minimum": 0 },
        "touch_time_h": { "type": "number", "minimum": 0 },
        "queue_time_h": { "type": "number", "minimum": 0 },
        "blocked_time_h": { "type": "number", "minimum": 0 },
        "eval_score": { "type": "number", "minimum": 0, "maximum": 1 },
        "error_count_total": { "type": "integer", "minimum": 0 },
        "error_count_consecutive": { "type": "integer", "minimum": 0 },
        "last_error_at": { "type": "string", "format": "date-time" }
      }
    },
    "audit": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "created_at": { "type": "string", "format": "date-time" },
        "created_by": { "type": "string" },
        "updated_at": { "type": "string", "format": "date-time" },
        "updated_by": { "type": "string" },
        "last_event_id": { "type": "string" },
        "version": { "type": "integer", "minimum": 0 },
        "etag": { "type": "string" }
      }
    }
  },
  "$defs": {
    "ioPath": {
      "type": "string",
      "description": "Fully qualified path or URI within client namespace",
      "pattern": "^(file:\\/\\/|s3:\\/\\/|az:\\/\\/|gs:\\/\\/)?clients\\/"
    },
    "funnelEnum": { "type": "string", "enum": ["Intake", "Engage", "Execute", "Deliver", "Monetize", "Retain", "Reactivate"] },
    "milestoneEnum": { "type": "string", "enum": ["Attract", "Acquire", "Activate", "Discovery", "Research", "Inception", "Elaboration", "Construction", "Transition", "Monetization", "Maintenance", "Evaluation"] },
    "stageEnum": {
      "type": "string",
      "enum": [
        "Campaign","Qualify","Onboard","Plan","Research","UX","Design","Marketing","Web","Dev","Hosting","Managed Services","Analyze","Implement","Validate","Demo","Acceptance","Bill","Production","Operate","Improve"
      ]
    },
    "stateEnum": {
      "type": "string",
      "enum": ["Created","Ready","Validated","Routed","InProgress","Completed","Reviewed","Evaluated","Approved","Done","Closed"]
    },
    "typeEnum": { "type": "string", "enum": ["Document","Analysis","Design","Code","Infra","Evaluation","Communication","Research"] },
    "capabilityEnum": { "type": "string", "enum": ["Writer","Analyst","Designer","Engineer","Devops","Evaluator","Communicator","Research"] },
    "classOfServiceEnum": { "type": "string", "enum": ["Standard","Expedite","FixedDate","Intangible"] },
    "errorStageEnum": { "type": "string", "enum": ["Create","Validate","Route","Execute","Review","Evaluate","Approve","Release"] },
    "errorCategoryEnum": { "type": "string", "enum": ["validation","policy","routing","io","compute","external","security","concurrency","integrity","deployment"] },
    "errorSeverityEnum": { "type": "string", "enum": ["info","warn","error","critical"] }
  }
}
```

## Storage

Repository layout for docs and code mirrors the same keys to keep local work and storage consistent.

All agents receive the resolved base path for the work item so they cannot escape the tenant namespace.

### Layout

Stable base path for every work item:

```
clients/{client}/{product}/{project}/{funnel}/{milestone}/{stage}/{deliverable}
  /versions/{iso_datetime or semver}/ 
    artifacts/...                 # the actual deliverable files
    manifest.yaml                 # content digests, inputs, generator, licenses
  /latest/                        # pointer objects or small manifests
    draft.json                    # points to a draft version
    reviewed.json                 # points to the reviewed version
    approved.json                 # points to the approved version
    /env/env/{dev|qa|uat|stage|prod[-blue|-green]}.json  # if deployed, holds pointers to released environment
```

-   `draft.json points to artifacts that are ready for review.`
-   `reviewed.json points to artifacts that have been reviewed.`
-   `approved.json points to artifact that have passed release gates and are approved for delivery and release.`
-   `env/{env}.json` point to the latest released version that is active in each environment.
-   Promotions update the env pointer, not the version folder.

### Segregation Controls

-   Storage paths follow clients/{client}/{product}/{project}/....
-   Queries and retrieval include a where client = :client and product = :product and project = :project clause.
-   Cross client reads are denied unless an explicit cross client work order is approved and logged.

### Manifest

```yaml
manifest:
  work_item: WR-1427
  client: KoalaHealth
  version: 2025-08-21T23:17:05Z
  inputs:
    - sha256:...
    - sha256:...
  outputs:
    - file: inception/technical-blueprint.md
      sha256:...
  generator: WriterAgent
  state_at_write: Draft
```

This keeps paths stable, makes state changes cheap, and preserves a clean audit trail.

### Pointer

```json
{
  "work_item": "WR-1427",
  "env": "uat",
  "version": "2025-08-21T23:17:05Z",
  "by": "Conductor",
  "at": "2025-08-22T10:14:03Z",
  "source_state": "Release",
  "checks": ["smoke:pass", "perf:p95<250ms"],
  "hash": "sha256:...",
  "notes": "canary 10 percent"
}
```

### Promotion

1.  Functional agent
    1.  Publishes a new `versions/*` folder
    2.  Sets latest/draft.json to the new version
    3.  Publishes an event.
2.  Evaluator moves `latest/reviewed.json` to that version after checks.
3.  Conductor sets `latest/approved.json` when gates pass.
4.  DevOps updates `latest/env/*.json` to the released version.
5.  Promote by updating `qa.json`, then `uat.json`, then `prod.json`.
6.  Rollback by repointing the env pointer to an earlier released version.
-   Blue green or canary: keep `prod-blue.json` and `prod-green.json`, or add percentage fields in the pointer payload.
-   Cross artifact pins: use a release bundle that maps multiple pointers for code, model, and dataset in one file.

```yaml
bundle:
  id: BND-019
  env: stage
  components:
    app: version: 1.14.0
    model: version: 2025-08-21T23:17:05Z
    dataset: version: ds-2025-08-18
```

-   Database link: keep a `deployments` table keyed by `(client, product, project, env)` that stores the pointer digest and rollout status.

This approach lets you ship one released artifact to many environments with clear promotions, fast rollbacks, and a clean audit trail.

### Rules

-   Only versions referenced by `approved.json` may be targeted by env pointers.
-   Each env pointer is immutable once written unless you create a new pointer with a higher `at` timestamp. The old pointer stays for audit.
-   Sign the pointer or store its hash in the database to prevent tampering.
-   RBAC can restrict who may update `prod.json`.
-   Store deployment metadata alongside the pointer, not in path names.
-   Conductor Rules
-   Writes always go to a new version under `versions/`.
-   Moving between states updates the pointer in `latest/` and the work item row.
-   Evaluator reads the version referenced by `latest/reviewed.json`.
-   Release flips `latest/approved.json` to the approved version and emits an event.
-   Garbage collection keeps the last N versions and anything referenced by a pointer or audit event.

### Persistence

-   Database fields on the work item: `state`, `from_state`, `to_state`, timestamps.
-   Object tags or metadata on each artifact: `state`, `version`, `hash`, `generated_by`.
-   Pointer manifests under `latest/` map a state to a version:

```json
{ "state": "Review", "version": "2025-08-21T23:17:05Z", "by": "WriterAgent", "hash": "sha256:..." }
```

## Example

```yaml
work_item:
  id: WR-1427
  title: "Inception: Technical Blueprint"
  client: KoalaHealth
  product: Automated Refill Prediction
  project: Pharmacy Refill AI
  funnel: Execute
  milestone: Inception
  stage: Plan
  state: Ready
  deliverable: inception/technical-blueprint.md
  type: Document
  capability: Writer
  io:
    inputs:
      - s3://clients/KoalaHealth/Automated Refill Prediction/Pharmacy Refill AI/research/research-report.md
      - s3://clients/KoalaHealth/Automated Refill Prediction/Pharmacy Refill AI/discovery/discovery-summary.md
    outputs:
      - s3://clients/KoalaHealth/Automated Refill Prediction/Pharmacy Refill AI/inception/technical-blueprint.md
  class_of_service: Standard
  priority: 2
  due: 2025-09-05
  wip_slot: inception.writer
  owner_operator: pm-alex
  owner_agent: WriterAgent
  is_blocked: false
  metrics:
    age_days: 2
    lead_time_d: 0
    cycle_time_d: 0
    touch_time_h: 0
    queue_time_h: 0
    blocked_time_h: 0
    eval_score: 0.0
    error_count_total: 0
    error_count_consecutive: 0
  audit:
    created_at: 2025-08-30T14:02:41Z
    created_by: Conductor
    last_event_id: EVT-83001
    version: 1
    etag: "W/\"wr-1427-v1\""
```

## Policies

### Admission and Validation

-   **Gate**: A Work Item may enter **Validated** only if all checks pass.
-   **Required fields**: `id, title, client, product, project, funnel, milestone, stage, state, wip_slot, owner_operator, owner_agent`.
-   **WIP guard**: Reject admission when `wip(stage) ≥ limit` or `wip(owner_operator) ≥ limit`.
    -   Emit `work_item.error` (category: `policy`, code: `wip_limit_exceeded`), set `is_blocked=true` with `blocked_reason=wip_limit`.
-   **Namespace guard**: Every path in `io.inputs` and `io.outputs` must match `^.../clients/{client}/{product}/{project}/…`.
    -   Violations: emit `work_item.error` (category: `validation`, code: `io_namespace_violation`); return to Milestone Agent; block after 3 failed corrections.
-   **Existence guard**: All `io.inputs` must exist (or have a declared upstream producing them).
    -   Missing inputs: `work_item.error` (category: `io`, code: `input_missing`); retry if expected soon, else block.
-   **Access guard**: `owner_agent` must be authorized for `(client, capability)`; `owner_operator` must have access to client/project.
    -   Failures: `work_item.error` (category: `security`, code: `agent_unauthorized`); block.
-   **FixedDate guard**: If `class_of_service = FixedDate`, `due` is required.
    -   Missing: `work_item.error` (category: `validation`, code: `due_required_for_fixed_date`).
-   **On success**: set state → **Validated**; emit `work_item.state.changed` and (optionally) `work_item.validated`.

### Routing

-   **Deterministic first**: If agent tag or exact `(domain, artifact, verb)` match exists, route deterministically; else use classifier (confidence ≥ 0.7), else escalate.
-   **Assignment**: Set `wip_slot` (e.g., `inception.writer`) and `owner_agent`. Log rule id and rationale.
-   **Events**: emit `work_item.routed` (and `router.routed`/`router.classified` where applicable).

### Execution

-   **Read from** `io.inputs` only; **write to** `versions/*` only (never `latest/*`).
-   **Success**: artifacts and `manifest.yaml` written under the same tenant path; emit `work_item.outputs.produced`; set state → **Completed**; emit `work_item.completed`.
-   **Failure**: remain **InProgress**; emit `work_item.error` with `{code, category, retryable, attempt}`; apply retry policy; block when non-retryable or after retry budget.
-   **Idempotency**: repeated execution attempts for the same version must not corrupt outputs; write new version folders for new attempts when content changes.

### Review

-   **Non-gated checks** only (format, completeness, path hygiene).
-   **If gated**: route to Evaluator; emit `work_item.pull_request`.
-   **If pass (no gates)**: set state → **Reviewed**; emit `work_item.reviewed`.

### Evaluation

-   **Quality gates** run against the produced version; record `metrics.eval_score` and gate results.
-   **Pass**: set state → **Evaluated**; emit `work_item.evaluated`.
-   **Operational failure** (tool outage): do not change state; emit `work_item.error`; retry/block per policy.
-   **Quality fail**: not an error; emit `work_item.returned` and move **Evaluated → InProgress** with reason.

### Approval

-   **Policy engine** applies thresholds and compliance checks (e.g., `eval_score ≥ threshold`, license, security scans).
-   **Pass**: set state → **Approved**; emit `work_item.approved`.
-   **Fail**: return to **InProgress** with reason; emit `work_item.returned`.

### Release / Delivery

\* **Pointers**: only versions referenced by `latest/approved.json` may be promoted to env pointers `latest/env/{dev|qa|uat|stage|prod[-blue|-green]}.json`.

-   **Success**: set state → **Done**; emit `work_item.done`.

\* **Failure** (pointer write denied, checks fail): do not change state; emit `work_item.error` (category: `deployment|io`); retry/block per policy.

### Close and Archival

-   Preconditions: outputs exist, env pointers (if any) are valid, policies passed.
-   Actions: archive item with final metrics + immutable audit trail; set state → **Closed**; emit `work_item.closed`.
-   **Immutability**: closed items are read-only; reopen requires a new Work Item.

### Error and Blocked Overlays

-   **No “Error” state.** Errors are overlays + events.
-   Set `is_blocked=true` when: non-retryable category, retry budget exhausted, human action required, or security/integrity issues.
-   Clear via explicit operator/agent action; emit `work_item.unblocked`.

### Retry Policy

Defaults; override per `wip_slot`

-   Attempts: **3**; Backoff: exponential with jitter.
-   **Retryable** categories: `io`, `compute`, `external`, `concurrency`.
-   **Non-retryable**: `validation`, `policy`, `security`, `integrity`.
-   After exhaustion → `is_blocked=true`, `blocked_reason=retry_exhausted`.

### Metrics and Observability

-   Metrics (`lead_time_d`, `cycle_time_d`, `touch_time_h`, `queue_time_h`, `blocked_time_h`, `eval_score`, error counters) are **derived from events** by a background job; never hand-edited.
-   Emit `work_item.metrics.updated` after recomputation.
-   Logs must carry `correlation_id` and `causation_id` for each transition.

### Concurrency and Consistency

-   **Optimistic concurrency** on the Work Item row using `audit.version` or `audit.etag`.
-   **Pointer writes** are atomic; write a new pointer file with a higher `at` timestamp; never mutate in place.
-   **Event ordering**: maintain per-item monotonic `sequence`.

### Security and Segregation

-   **Tenant boundary**: agents may only read/write under `clients/{client}/{product}/{project}/…`.
-   **RBAC**: restrict who may update `prod` pointers; MFA required for `prod`.
-   **Cross-tenant**: denied unless an explicit cross-client Work Order is approved and logged.

### Aging and SLAs

-   **Aging policy**: stage-specific p90 thresholds drive alerts and auto-work-orders (e.g., nudge/produce/evaluate).
-   **FixedDate** items get priority bias; late items auto-escalate.

### Garbage Collection an Retention

-   Keep the last **N** versions per item plus **all** versions referenced by any pointer or event.
-   Event retention: hot 90 days, cold archive 7 years (configurable).
-   Do not delete artifacts while any pointer references them.

If you want, I can integrate these as a formatted “Policies” section right under Work Item in your doc and ensure all event names line up with your Event Model list.

# Event Model

## Definitions

Events provide the authoritative, append-only audit and the substrate for metrics, routing, retries, and dashboards.

### Identity and Routing

| Field          | Type     | Required | Description                                                   |
|----------------|----------|----------|---------------------------------------------------------------|
| id             | string   | true     | Unique event id (e.g., `EVT-83901`).                          |
| at             | datetime | true     | Event time (UTC).                                             |
| type           | enum     | true     | See **Event Types** below.                                    |
| work_item_id   | string   | false    | If event pertains to a specific work item (`WR-####`).        |
| work_order_id  | string   | false    | If event pertains to a specific work order (`WO-####`).       |
| client         | string   | true     | Tenant key.                                                   |
| product        | string   | true     | Product key.                                                  |
| project        | string   | true     | Project key.                                                  |
| actor          | string   | true     | Emitter (Conductor, WriterAgent, Evaluator, DevOps, Router…). |
| correlation_id | string   | false    | Correlates a chain (e.g., a Work Order run).                  |
| causation_id   | string   | false    | Event that triggered this one.                                |
| sequence       | integer  | false    | Monotonic per work item/order for ordering.                   |

### Common Payload Shapes

-   **State change**: `{ from_state, to_state, reason? }`
-   **Route**: `{ wip_slot, rule_id, decision_info }`
-   **Production**: `{ version, artifacts: [{file, sha256}], manifest_sha256 }`
-   **Evaluation**: `{ eval_score, gates: [{name, passed, score, threshold}] }`
-   **Blocked**: `{ blocked_reason, blocked_by }`
-   **Error/failure**: `{ code, message, category, severity, retryable, attempt, context }`
-   **Release**: `{ env, pointer_sha256, checks }`
-   **Metrics updated**: `{ metrics: {...} }`

### Event Types

| Event type                  | Emitted by             | Purpose / Notes                                              |
|-----------------------------|------------------------|--------------------------------------------------------------|
| router.routed               | Router (deterministic) | Deterministic route chosen.                                  |
| router.classified           | Router (classifier)    | Probabilistic route + confidence.                            |
| work_order.issued           | Conductor/Router       | Work Order created and handed off.                           |
| work_order.action.started   | Target Agent           | A specific action begins.                                    |
| work_order.action.succeeded | Target Agent           | Action finished successfully.                                |
| work_order.action.failed    | Target Agent           | Action failed (with `{code, category, retryable, attempt}`). |
| work_order.completed        | Conductor              | All actions succeeded.                                       |
| work_item.state.changed     | Any actor moving state | Backbone transition (authoritative).                         |
| work_item.validated         | Conductor              | Convenience signal after Validate.                           |
| work_item.routed            | Conductor              | Routed to wip_slot/owner_agent.                              |
| work_item.in_progress       | Functional Agent       | Convenience signal at start of Execute.                      |
| work_item.outputs.produced  | Functional Agent       | Artifacts/manifest written to `versions/*`.                  |
| work_item.completed         | Functional Agent       | Convenience for Completed.                                   |
| work_item.reviewed          | Conductor              | Convenience for Reviewed.                                    |
| work_item.pull_request      | Conductor              | Sent to Evaluator (quality gates).                           |
| work_item.evaluated         | Evaluator              | Gates run; score recorded.                                   |
| work_item.approved          | Conductor/Policy       | Approved for release.                                        |
| work_item.returned          | Conductor/Policy       | Sent back to InProgress (quality or policy fail).            |
| work_item.done              | Conductor/DevOps       | Released/delivered.                                          |
| work_item.closed            | Conductor              | Archived/immutable.                                          |
| work_item.error             | Any actor              | Error overlay (no state advance).                            |
| work_item.blocked           | Any actor              | Human attention required; overlay on current state.          |
| work_item.unblocked         | Operator/Conductor     | Overlay cleared.                                             |
| work_item.retry.scheduled   | Agent/Orchestrator     | Retry planned (attempt + backoff).                           |
| work_item.retry.aborted     | Agent/Orchestrator     | Retry canceled.                                              |
| work_item.metrics.updated   | Metrics Job            | Derived metrics refreshed.                                   |

### States

| State          | Meaning (succinct)                                                         |
|----------------|----------------------------------------------------------------------------|
| **Created**    | Work Item record created from template; required fields populated.         |
| **Ready**      | Entry criteria met; admissible to lane guards.                             |
| **Validated**  | All guards passed (WIP, namespace, existence, RBAC, FixedDate).            |
| **Routed**     | wip_slot and owner_agent assigned by Conductor.                            |
| **InProgress** | Functional Agent actively working; reads from inputs, writes `versions/*`. |
| **Completed**  | Functional work finished; outputs exist in `versions/*`.                   |
| **Reviewed**   | PM/Conductor checks passed (non-gated).                                    |
| **Evaluated**  | Quality gates executed; eval score recorded.                               |
| **Approved**   | Releasable (all gates/policies passed).                                    |
| **Done**       | Delivered/released; env pointers updated.                                  |
| **Closed**     | Archived with immutable audit trail.                                       |

Blocked is an overlay (is_blocked=true) applicable to any active state; Error is represented by work_item.error events and the error overlay view.

### State Transitions & State Machine

#### Allowed Transitions (who + guard + emitted events)

| From → To              | Actor            | Preconditions / Guards                                        | Side effects (minimum)                                                            |
|------------------------|------------------|---------------------------------------------------------------|-----------------------------------------------------------------------------------|
| Created → Ready        | Milestone Agent  | Entry criteria met (template filled, IO declared, owners set) | `work_item.state.changed`                                                         |
| Ready → Validated      | Conductor        | All validation guards pass                                    | `work_item.state.changed` (+ `work_item.validated`)                               |
| Validated → Routed     | Conductor        | Routing rule resolved (deterministic or classifier≥0.7)       | `work_item.state.changed`, `work_item.routed`                                     |
| Routed → InProgress    | Functional Agent | Agent accepts work, one-shot plan acked                       | `work_item.state.changed` (+ `work_item.in_progress`)                             |
| InProgress → Completed | Functional Agent | Outputs + manifest written under `versions/*`                 | `work_item.outputs.produced`, `work_item.state.changed` (+ `work_item.completed`) |
| Completed → Reviewed   | Conductor        | Non-gated checks pass; else route to Evaluator                | `work_item.state.changed` (+ `work_item.reviewed`)                                |
| Reviewed → Evaluated   | Evaluator        | Gates executed; score recorded                                | `work_item.state.changed` (+ `work_item.evaluated`)                               |
| Evaluated → Approved   | Conductor/Policy | Policies/thresholds passed                                    | `work_item.state.changed` (+ `work_item.approved`)                                |
| Approved → Done        | Conductor/DevOps | Pointers updated; release checks pass                         | `work_item.state.changed` (+ `work_item.done`)                                    |
| Done → Closed          | Conductor        | Archive final metrics; audit sealed                           | `work_item.state.changed` (+ `work_item.closed`)                                  |

#### Return / Rework Transitions

| From → To                             | Actor              | Condition                                                    | Event(s)                                        |
|---------------------------------------|--------------------|--------------------------------------------------------------|-------------------------------------------------|
| Evaluated → InProgress                | Conductor/Policy   | Quality or policy fail (not an outage)                       | `work_item.returned`, `work_item.state.changed` |
| Any active → (same)                   | Any                | Operational failure (retryable)                              | `work_item.error`, `work_item.retry.scheduled`  |
| Any active → (same, blocked overlay)  | Any                | Non-retryable or retries exhausted, or human action required | `work_item.error`, `work_item.blocked`          |
| (blocked overlay) → (same, unblocked) | Operator/Conductor | Resolution applied                                           | `work_item.unblocked`                           |

Never advance state on error. Errors are events + overlays. Rework is an explicit transition (usually to InProgress).

#### Rules

-   Determinism: Only the listed transitions are allowed; attempts to skip states or regress without a return event are rejected.
-   Idempotency: Re-emitting a transition to the same state with identical payload should be harmless (no duplicate side effects).
-   Sequencing: Every Work Item has a monotonic `sequence`; consumers must process in order.
-   Guards as code: WIP, namespace, existence, RBAC, and FixedDate guards run before `Validated`. Release guards run before `Done`.
-   Storage invariants: agents never write to `latest/*`; only pointers move during Review/Approve/Release.
-   Metrics: derived asynchronously; the metrics job never flips states.

## Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://agenticops.dev/schemas/event.schema.json",
  "title": "AgenticOps Event",
  "type": "object",
  "additionalProperties": false,
  "required": ["id", "at", "type", "client", "product", "project", "actor"],
  "properties": {
    "id": { "type": "string", "pattern": "^EVT-[0-9]+$" },
    "at": { "type": "string", "format": "date-time" },
    "type": { "$ref": "#/$defs/eventTypeEnum" },
    "work_item_id": { "type": "string", "pattern": "^WR-[0-9]+$" },
    "work_order_id": { "type": "string", "pattern": "^WO-[0-9]+$" },
    "client": { "type": "string" },
    "product": { "type": "string" },
    "project": { "type": "string" },
    "actor": { "type": "string" },
    "correlation_id": { "type": "string" },
    "causation_id": { "type": "string" },
    "sequence": { "type": "integer", "minimum": 0 },
    "payload": {
      "type": "object",
      "description": "Type-specific fields",
      "additionalProperties": true
    }
  },
  "$defs": {
    "eventTypeEnum": {
      "type": "string",
      "enum": [
        "work_item.state.changed",
        "work_item.routed",
        "work_item.outputs.produced",
        "work_item.evaluated",
        "work_item.approved",
        "work_item.done",
        "work_item.closed",
        "work_item.blocked",
        "work_item.unblocked",
        "work_item.error",
        "work_item.metrics.updated",
        "work_order.issued",
        "work_order.action.started",
        "work_order.action.succeeded",
        "work_order.action.failed",
        "work_order.completed"
      ]
    }
  }
}
```

If you want stricter payload typing, split into per-type schemas and use `oneOf` + `discriminator` on `type`.

## Storage

Immutable, append-only. Partition by time and by tenant keys for efficient queries.

```
events/
  y=2025/m=09/d=01/h=18/
    EVT-83901.json
    EVT-83902.json
clients/{client}/{product}/{project}/events/
  y=2025/m=09/d=01/
    EVT-83901.ptr.json   # pointer with blob key, hash, quick index
```

-   Event files are content-addressed (e.g., include `sha256` in object metadata).
-   Index tables (db) carry: `(id, at, type, client, product, project, work_item_id, work_order_id, correlation_id, sequence, blob_uri, sha256)`.

## Example

### State Change

```json
{
  "id": "EVT-83901",
  "at": "2025-09-01T18:33:10Z",
  "type": "work_item.state.changed",
  "work_item_id": "WR-1427",
  "client": "KoalaHealth",
  "product": "Automated Refill Prediction",
  "project": "Pharmacy Refill AI",
  "actor": "Conductor",
  "sequence": 14,
  "payload": {
    "from_state": "Ready",
    "to_state": "InProgress",
    "reason": "Admitted to inception.writer lane"
  }
}
```

### Outputs Produced

```json
{
  "id": "EVT-83912",
  "at": "2025-09-01T19:05:48Z",
  "type": "work_item.outputs.produced",
  "work_item_id": "WR-1427",
  "client": "KoalaHealth",
  "product": "Automated Refill Prediction",
  "project": "Pharmacy Refill AI",
  "actor": "WriterAgent",
  "sequence": 17,
  "payload": {
    "version": "2025-09-01T19:05:30Z",
    "artifacts": [
      {"file": "inception/technical-blueprint.md", "sha256": "abc123..."}
    ],
    "manifest_sha256": "def456..."
  }
}
```

### Evaluation

```json
{
  "id": "EVT-83918",
  "at": "2025-09-01T19:22:10Z",
  "type": "work_item.evaluated",
  "work_item_id": "WR-1427",
  "client": "KoalaHealth",
  "product": "Automated Refill Prediction",
  "project": "Pharmacy Refill AI",
  "actor": "Evaluator",
  "sequence": 21,
  "payload": {
    "eval_score": 0.87,
    "gates": [
      {"name": "completeness", "passed": true, "score": 0.88, "threshold": 0.8}
    ]
  }
}
```

### Work Order Action Started/Finished

```json
{
  "id": "EVT-84001",
  "at": "2025-09-01T20:01:05Z",
  "type": "work_order.action.started",
  "work_order_id": "WO-412",
  "client": "KoalaHealth",
  "product": "Automated Refill Prediction",
  "project": "Pharmacy Refill AI",
  "actor": "Conductor",
  "correlation_id": "corr-4d0b",
  "payload": { "index": 0, "action": "produce", "deliverable": "inception/technical-blueprint.md" }
}

{
  "id": "EVT-84002",
  "at": "2025-09-01T20:06:40Z",
  "type": "work_order.action.succeeded",
  "work_order_id": "WO-412",
  "client": "KoalaHealth",
  "product": "Automated Refill Prediction",
  "project": "Pharmacy Refill AI",
  "actor": "WriterAgent",
  "correlation_id": "corr-4d0b",
  "payload": { "index": 0, "action": "produce", "version": "2025-09-01T20:06:35Z" }
}
```

## Policies

-   Immutability: events are write-once; corrections require compensating events.
-   Ordering: enforce monotonic `sequence` per `(work_item_id|work_order_id)`; reject duplicates.
-   Redaction: `payload.message` must be redaction-safe; PII guarded by policy; large payloads \>64KB stored as blob refs.
-   Authorization: only allowed actors may emit certain types (e.g., only Evaluator can emit `work_item.evaluated`).
-   Retention: hot store 90 days; cold archive 7 years; indexes retained for the archive window.

### Immutability

-   Events are append-only; once written, they cannot be modified or deleted.
-   Corrections use compensating events (e.g., work_item.returned, work_item.corrected).

### Ordering and Sequencing

-   Each (work_item_id \| work_order_id) maintains a monotonic sequence number.
-   Event consumers must process in sequence order per entity.

### Type Restrictions

-   Only authorized actors may emit certain event types:
    -   `Evaluator` → `work_item.evaluated`
    -   `DevOps` → `work_item.done`, `work_item.closed`
    -   `Conductor` → `work_item.routed`, `work_item.approved`
    -   `Router` → `router.routed`, `router.classified`
-   Unauthorized emissions are rejected and logged.

### Payload Standards

-   Every event must carry:
    -   `id, at, type, client, product, project, actor`
    -   At least one of `work_item_id` or `work_order_id`
-   Payload fields must match the schema for the given type.
-   Sensitive data (e.g., PII) is forbidden; large payloads \>64KB must be stored in blob storage with digests referenced.

### Error Handling

-   Failures in processing do not mutate backbone states; instead:
    -   Emit `work_item.error` or `work_order.action.failed`.
    -   Retry/block based on category.

### Retention and Archival

-   Hot store: minimum 90 days.
-   Cold archive: minimum 7 years (configurable).
-   Index records must remain queryable for the archive window.

### Integrity and Security

-   Events must include a `sha256` hash of payload + metadata.
-   Optionally sign events (JWS/JWT) for non-repudiation.
-   RBAC and tenant isolation enforced in event broker and storage paths.

### Observability

-   Every event must include `correlation_id` (ties together a Work Order run or workflow) and `causation_id` (points to prior triggering event).
-   Emit `work_item.metrics.updated` after background recomputations.
-   Block/unblock transitions must always emit `work_item.blocked` / `work_item.unblocked`.

# Processing Flow

## Requests, Routing, Handoff

1.  Request intake
    1.  Requests arrive as plain English (operator) or structured payloads (event, work order, work item).
2.  Routing (deterministic, then probabilistic)
    1.  If an agent tag is present, route to that agent.
    2.  Else if (domain, artifact, verb) exactly match an agent, route deterministically.
    3.  Else call LLM Router, returns `{ agent, confidence }`. Auto-route when `confidence ≥ 0.7`; otherwise escalate to operator.
3.  Routing events
    1.  Agent tag route emit `router.tagrouted`.
    2.  Agent match route emit router.matchrouted.
    3.  Classifier route emit `router.classifierrouted` (with `confidence`).
    4.  Emit `work_order.issued` when a work order is created for the handoff.
4.  Handoff contract
    1.  Router attaches a Work Order and invokes the agent (function/tool call).
    2.  Receiving agent replies with a one-shot plan and requests any missing inputs before starting work.

## Pipeline

Created → Ready → Validated → Routed → InProgress → Completed → Reviewed → Evaluated → Approved → Done → Closed

>   Blocked and Error are overlays and events, not states.

## Create

Actors: Conductor, Milestone Agent

1.  Conductor receives request (or upstream event) and issues a Work Order to the relevant Milestone Agent.
2.  Milestone Agent analyzes deliverables and, for each deliverable:
    1.  Creates a Work Item from template
    2.  Fills required fields (deliverable, type, capability, IO, owners)
    3.  Set state to Created
    4.  Emit `work_item.state.changed and work_item.created`
    5.  When entry criteria met,
        1.  Set state to Ready
        2.  Emit `work_item.state.changed and work_item.ready`

## Validate

Actor: Conductor

-   Run pre-admission checks on Ready Work Items.
-   Any guard fails (WIP, namespace, existence, access/RBAC, FixedDate without due),
    -   Do not advance state.
    -   Emit `work_item.error` (typed `{code, category, retryable}`)
        -   Apply policy: retry or set `is_blocked=true`
        -   Emit `work_item.blocked`
-   All guards pass,
    -   Set state to Validated
    -   Emit `work_item.state.changed and` `work_item.validated`

## Route

Actor: Conductor

-   Resolve type, capability, milestone, stage;
-   Assign wip_slot and owner_agent; log rule
-   Set state to Routed
-   Emit `work_item.state.changed` and `work_item.routed`.

## Execute

Actor: Functional Agent (Writer/Engineer/Designer/etc.)

-   Set state to InProgress
-   Emit `work_item.state.changed` and `work_item.in_progress`
-   Read only from `io.inputs`
-   Write only to `versions/*` (never `latest/*`)
-   On success:
    -   Write `artifacts` and `manifest.yaml`
    -   `E`mit `work_item.outputs.produced`
    -   Set state to Completed
    -   Emit `work_item.state.changed` and `work_item.completed`
-   On failure (IO/compute/external/concurrency):
    -   Remain InProgress
    -   Emit `work_item.error`
    -   If retryable and attempts remain
        -   Emit `work_item.retry.scheduled`
    -   Else
        -   Set `is_blocked=true`
        -   Emit `work_item.blocked`

## Review

Actor: Conductor

-   Non-gated checks (format, completeness, path hygiene)
-   If quality gates apply
    -   Route to Evaluator
    -   Emit `work_item.pull_request`
-   Else
    -   Set state to Reviewed
    -   Emit `work_item.state.changed` and `work_item.reviewed`

## Evaluate

Actor: Evaluator Agent

-   Run quality gates against the Completed version; record `metrics.eval_score`.
-   Operational failure (tool/outage): do not change state; emit `work_item.error`; retry/block per policy.
-   Set state to Evaluated.
-   Emit `work_item.state.changed` and `work_item.evaluated`.
-   Quality fail is not an error:
    -   Emit `work_item.returned.`
    -   `M`ove Evaluated to InProgress with `reason`.

## Approve

Actor: Conductor / Policy Engine

-   Apply thresholds & compliance (score, license, security scans…).
-   Pass
    -   Set state to Approved.
    -   Emit `work_item.state.changed` and `work_item.approved`.
-   Fail
    -   Return to InProgress with reason.
    -   Emit `work_item.returned`.

## Release / Deliver

Actors: Conductor / DevOps

-   Update latest/approved.json to env pointers latest/env/{dev\|qa\|uat\|stage\|prod[-blue\|-green]}.json.
-   Pointer write/checks fail
    -   Do not change state.
-   Emit `work_item.error` (category `deployment|io`)
-   Retry/block per policy.
-   On success
    -   Set state to Done.
    -   Emit `work_item.state.changed` and `work_item.done`.

## Close

Actor: Conductor

-   Verify outputs under correct client prefix; env pointers valid; policies passed.
-   Archive final metrics + immutable audit trail.
-   Set State to Closed.
-   Emit `work_item.state.changed` and `work_item.closed`.
-   Closed items are read-only; reopening requires a new Work Item.

## Background Metrics Job

-   No state changes.
-   Consumes events to compute: touch_time_h, queue_time_h, cycle_time_d, blocked_time_h, lead_time_d, age_days, error counters.
-   Writes metrics.
-   Emit work_item.metrics.updated.
