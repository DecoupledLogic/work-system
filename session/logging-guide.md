# Session Logging Integration Guide

This document describes how to integrate session logging into stage commands.

## Overview

The session-logger agent captures structured activity logs for:
- Performance analysis
- Process improvement
- Debugging issues
- Usage metrics

## Quick Reference

### Start of Command

```
At command start:
1. Call session-logger: start_run
2. Store returned runId
3. Continue with command logic
```

### During Execution

```
After each significant step:
1. Call session-logger: log_action
2. Include action type and description
3. Add relevant metadata
```

### End of Command

```
At command completion:
1. Call session-logger: end_run
2. Include final status (success/failed/cancelled)
3. Include metrics (duration, tokens, tool calls)
```

## Integration by Stage

### /triage Integration

```markdown
## At start:
→ start_run(stage: "triage", workItems: [TW-12345])

## Key actions to log:
→ log_action(action: "fetch", description: "Retrieved task from Teamwork")
→ log_action(action: "map", description: "Normalized to WorkItem schema")
→ log_action(action: "categorize", description: "Support request", metadata: {workType, urgency, impact})
→ log_action(action: "assign_template", description: "Matched template", metadata: {templateId})
→ log_action(action: "route", description: "Added to queue", metadata: {queue})
→ log_action(action: "update", description: "Posted to Teamwork")

## At end:
→ end_run(status: "success", metrics: {duration, tokensIn, tokensOut, toolCalls})
```

### /plan Integration

```markdown
## At start:
→ start_run(stage: "plan", workItems: [TW-12345])

## Key actions to log:
→ log_action(action: "load", description: "Loaded triaged work item")
→ log_action(action: "size", description: "Inferred size", metadata: {appetite, bound})
→ log_action(action: "split", description: "Split work item", metadata: {splitReason, newItems}) [if applicable]
→ log_action(action: "decompose", description: "Created children", metadata: {childCount, childTypes})
→ log_action(action: "elaborate", description: "Filled required fields")
→ log_action(action: "prioritize", description: "Calculated priority", metadata: {score})
→ log_action(action: "save", description: "Created tasks in Teamwork", metadata: {taskIds})

## At end:
→ end_run(status: "success", metrics: {duration, childrenCreated, sizeInferred})
```

### /design Integration

```markdown
## At start:
→ start_run(stage: "design", workItems: [TW-12345])

## Key actions to log:
→ log_action(action: "load", description: "Loaded planned work item")
→ log_action(action: "research", description: "Explored problem space")
→ log_action(action: "generate_options", description: "Created options", metadata: {optionCount})
→ log_action(action: "evaluate", description: "Assessed options")
→ log_action(action: "select", description: "Chose option", metadata: {selectedOption, rationale})
→ log_action(action: "create_adr", description: "Generated ADR", metadata: {adrPath})
→ log_action(action: "create_plan", description: "Generated implementation plan", metadata: {taskCount})
→ log_action(action: "update", description: "Updated work item with design artifacts")

## At end:
→ end_run(status: "success", metrics: {duration, optionsGenerated, adrCreated, tasksPlanned})
```

### /deliver Integration

```markdown
## At start:
→ start_run(stage: "deliver", workItems: [TW-12345])

## Dev phase actions:
→ log_action(action: "spec", description: "Expanded acceptance criteria")
→ log_action(action: "test_red", description: "Wrote failing test", metadata: {testFile})
→ log_action(action: "implement", description: "Wrote implementation", metadata: {files})
→ log_action(action: "test_green", description: "Tests passing", metadata: {passed, failed})
→ log_action(action: "refactor", description: "Refactored code")
→ log_action(action: "commit", description: "Created commit", metadata: {commitHash, message})

## QA phase actions:
→ log_action(action: "run_tests", description: "Executed test suite", metadata: {unit, integration})
→ log_action(action: "check_coverage", description: "Analyzed coverage", metadata: {coverage})
→ log_action(action: "verify_criteria", description: "Validated criteria", metadata: {met, partiallyMet, notMet})

## Eval phase actions:
→ log_action(action: "evaluate", description: "Compared plan vs actual", metadata: {timeVariance, scopeVariance})
→ log_action(action: "pr_create", description: "Created pull request", metadata: {prNumber})

## At end:
→ end_run(status: "success", metrics: {duration, commits, testsPassed, coverage, qualityScore})
```

## Action Type Reference

### Universal Actions

| Action | When to Use |
|--------|-------------|
| `fetch` | Retrieved external data (Teamwork, Git, API) |
| `load` | Loaded local context or state |
| `map` | Transformed data format |
| `validate` | Checked preconditions |
| `save` | Persisted data locally |
| `update` | Updated external system |
| `route` | Made routing decision |
| `delegate` | Called sub-agent |
| `error` | Error occurred |

### Stage-Specific Actions

See `~/.claude/agents/session-logger.md` for complete action type reference.

## Metrics to Capture

### Always Required

- **duration**: Time in seconds
- **tokensIn**: Input tokens used
- **tokensOut**: Output tokens generated
- **toolCalls**: Number of tool invocations

### Stage-Specific

| Stage | Required Metrics |
|-------|-----------------|
| triage | itemsCategorized, templatesMatched, queueRouted |
| plan | childrenCreated, sizeInferred, splitRequired |
| design | optionsGenerated, adrCreated, tasksPlanned |
| deliver | commits, testsWritten, testsPassed, coverage, qualityScore |

## Error Logging

When errors occur, log with:

```json
{
  "action": "error",
  "description": "Descriptive error message",
  "metadata": {
    "errorType": "api_error|validation_error|timeout|etc",
    "errorCode": 404,
    "errorMessage": "Original error message",
    "recoverable": true|false
  }
}
```

## Implementation Notes

### Where to Call Logger

The session-logger is called via the Task tool:

```
Use Task tool with subagent_type=general-purpose:
"Call session-logger to log: start_run for stage triage with workItems [TW-12345]"
```

Or integrate directly in command markdown:

```markdown
## Step 1: Start Logging

Before processing, log run start:
- Stage: {current_stage}
- Work Items: {work_item_ids}

## Step N: Log Action

After completing step, log:
- Action: {action_type}
- Description: {what_happened}
- Metadata: {relevant_data}

## Final Step: End Logging

Log run completion:
- Status: {success|failed}
- Metrics: {collected_metrics}
```

### Log File Location

Logs are written to: `~/.claude/session/session-log.md`

### Session Continuity

- Session ID persists in log file
- New runs append to existing session
- Context reset creates new run within same session
- `/clear` or new conversation starts new session

## Analysis Patterns

The structured logs enable queries like:

**Average duration by stage:**
```
Group runs by stage → calculate mean duration
```

**Success rate:**
```
Count status values → calculate success percentage
```

**Token usage:**
```
Sum tokensIn + tokensOut → trend over time
```

**Most common errors:**
```
Filter action=error → group by errorType → count
```

---

*Last Updated: 2024-12-07*
*See also: ~/.claude/agents/session-logger.md*
