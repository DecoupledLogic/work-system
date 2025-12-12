# Session Logger Agent

Lightweight agent for capturing structured logs of agent activity.

## Overview

| Property | Value |
|----------|-------|
| **Name** | session-logger |
| **Model** | haiku |
| **Tools** | Read, Write, Edit |
| **Stage** | Cross-cutting |

## Purpose

Provide lightweight logging infrastructure for analysis and improvement. Handles:

- Generating unique RunId and SessionId values
- Logging actions with timestamps
- Capturing metrics (duration, tokens, tool calls)
- Writing structured logs to session files
- Maintaining session continuity
- Writing to work item activity logs (cross-session history)

## Input

Expects a logging request:

```json
{
  "action": "start_run" | "log_action" | "end_run" | "start_session" | "end_session" | "log_to_work_item",
  "context": {
    "sessionId": "ses-20241207-143022",
    "runId": "run-20241207-143025-triage",
    "stage": "triage",
    "workItems": ["TW-12345"]
  },
  "data": {
    "action": "categorize",
    "description": "Detected support request",
    "metadata": { "workType": "support" }
  }
}
```

## Output

Returns logging confirmation:

```json
{
  "logged": true,
  "sessionId": "ses-20241207-143022",
  "runId": "run-20241207-143025-triage",
  "logPath": "~/.claude/session/session-log.md",
  "entry": {
    "timestamp": "2024-12-07T14:30:25Z",
    "action": "categorize",
    "description": "Detected support request"
  }
}
```

## ID Generation

### Session ID Format

```
ses-{YYYYMMDD}-{HHMMSS}
```

Example: `ses-20241207-143022`

A session starts when the user begins a Claude conversation and ends when they close it or context is cleared.

### Run ID Format

```
run-{YYYYMMDD}-{HHMMSS}-{stage}
```

Example: `run-20241207-143025-triage`

A run represents execution of a single stage (triage, plan, design, deliver).

## Logging Actions

### start_session

Initialize new session log:

```json
{ "action": "start_session", "data": { "user": "cbryant" } }
```

### start_run

Begin logging a new run:

```json
{
  "action": "start_run",
  "context": { "stage": "triage", "workItems": ["TW-12345"] }
}
```

Generates runId and creates run entry.

### log_action

Record a single action:

```json
{
  "action": "log_action",
  "context": { "runId": "run-20241207-143025-triage" },
  "data": {
    "action": "categorize",
    "description": "Detected support request",
    "metadata": { "workType": "support", "confidence": 0.95 }
  }
}
```

### end_run

Complete a run with metrics:

```json
{
  "action": "end_run",
  "context": { "runId": "run-20241207-143025-triage" },
  "data": {
    "status": "success",
    "metrics": {
      "duration": 53,
      "tokensIn": 2850,
      "tokensOut": 1200,
      "toolCalls": 8
    }
  }
}
```

### log_to_work_item

Write to work item activity log:

```json
{
  "action": "log_to_work_item",
  "context": { "workItemId": "tw-26253606" },
  "data": {
    "event": "stage_complete",
    "stage": "plan",
    "summary": "Decomposed into 3 features",
    "artifacts": ["delivery-plan.md"]
  }
}
```

## Log Format

### Session Log Structure

```markdown
# Session: ses-20241207-143022

**Started:** 2024-12-07 14:30:22
**User:** cbryant
**Status:** active

---

## Runs

### Run: run-20241207-143025-triage

**Stage:** triage
**Work Items:** TW-12345
**Duration:** 53s

#### Actions

| Timestamp | Action | Description |
|-----------|--------|-------------|
| 14:30:26 | fetch | Retrieved task TW-12345 |
| 14:30:28 | map | Normalized work item |
| 14:30:32 | categorize | Detected support request |

#### Metrics

| Metric | Value |
|--------|-------|
| Duration | 53s |
| Tokens In | 2,850 |
| Tool Calls | 8 |
```

## Work Item Events

| Event | When | Required Fields |
|-------|------|-----------------|
| `init` | Directory created | stage, type, queue |
| `stage_start` | Stage begins | stage |
| `stage_complete` | Stage ends | stage, summary, artifacts |
| `artifact_created` | Document generated | artifact, template |
| `decision` | Key decision made | decision, rationale |
| `status_change` | Status updated | fromStatus, toStatus |

## Standard Action Types

### Common Actions

| Action | Description |
|--------|-------------|
| `fetch` | Retrieved external data |
| `load` | Loaded context or previous state |
| `map` | Transformed data to schema |
| `validate` | Checked preconditions |
| `save` | Persisted state or data |
| `update` | Updated external system |
| `route` | Made routing decision |
| `delegate` | Called sub-agent |
| `error` | Error occurred |

### Stage-Specific Actions

**Triage:** `categorize`, `align`, `assign_template`

**Plan:** `size`, `split`, `decompose`, `elaborate`, `prioritize`

**Design:** `research`, `generate_options`, `evaluate`, `select`, `create_adr`

**Deliver:** `spec`, `test_red`, `implement`, `test_green`, `refactor`, `commit`

## Metrics Capture

### Run-Level Metrics

```json
{
  "duration": 53,
  "tokensIn": 2850,
  "tokensOut": 1200,
  "toolCalls": 8,
  "workItems": 1
}
```

### Stage-Specific Metrics

**Triage:** itemsCategorized, templatesMatched, queueRouted

**Plan:** childrenCreated, sizeInferred, splitRequired

**Design:** optionsGenerated, adrCreated, tasksPlanned

**Deliver:** commits, testsWritten, testsPassed, coverage

## Session vs Activity Log

| Aspect | Session Log | Activity Log |
|--------|-------------|--------------|
| Location | `~/.claude/session/session-log.md` | `work-items/{id}/activity-log.md` |
| Scope | All work items in session | Single work item |
| Git | Ignored | Tracked |
| Content | Tool calls, tokens, metrics | Stage events, artifacts |
| Audience | Developer (debug) | Team (history) |

Stage agents should call both:
1. `log_action` for detailed steps (session log)
2. `log_to_work_item` at stage start/complete (activity log)

## Integration Pattern

```markdown
At stage start:
  → log: start_run (stage, workItems)

During execution:
  → log: log_action (action, description, metadata)

At stage complete:
  → log: end_run (status, metrics)
  → log: log_to_work_item (stage_complete)
```

## Session Continuity

When context window resets:
1. Session ID persists (written to file)
2. New run starts within same session
3. Run links back to session via sessionId

## Focus Areas

- **Lightweight** - Minimal overhead on main operations
- **Consistent** - Same format across all stages
- **Queryable** - Structured for analysis
- **Durable** - Persisted to file, survives context resets
- **Actionable** - Enables improvement insights
- **Team-facing** - Activity logs provide handoff context

## Integration Points

| Agent | Direction | Data |
|-------|-----------|------|
| All stage agents | Called by | Action logs, metrics |
| Main session | Provides to | Session/run IDs |

## Related

- [triage-agent](triage-agent.md) - Uses for triage logging
- [dev-agent](dev-agent.md) - Uses for delivery logging
- [index](index.md) - Agent overview
