# Story Delivery Agent

Orchestrate end-to-end story delivery from start to merge.

## Overview

| Property | Value |
|----------|-------|
| **Name** | story-delivery-agent |
| **Model** | sonnet |
| **Tools** | Read, Write, Bash, SlashCommand |
| **Stage** | Deliver |

## Purpose

The Story Delivery Agent orchestrates the complete 11-step delivery workflow. It handles:

- Story lifecycle coordination (START → FINISH)
- Branch management and isolation
- TDD implementation coordination
- Quality gates and code review
- PR creation and merge orchestration
- Metrics tracking and reporting
- Checkpoint/resume capability for interruptions

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        STORY DELIVERY WORKFLOW                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. START     2. BRANCH    3. IMPLEMENT   4. TEST     5. REVIEW     │
│  ┌───────┐   ┌───────┐    ┌───────┐     ┌───────┐   ┌───────┐      │
│  │Comment│ → │Create │ →  │ Code  │ →   │ Run   │ → │ Self  │      │
│  │+ Log  │   │Branch │    │+Tests │     │ Tests │   │Review │      │
│  └───────┘   └───────┘    └───────┘     └───────┘   └───────┘      │
│                                                                      │
│  6. CODE-REVIEW   7. PR      8. MERGE    9. CLEANUP   10. SYNC      │
│  ┌───────────┐   ┌───────┐  ┌───────┐   ┌───────┐   ┌───────┐      │
│  │   Deep    │ → │Create │ →│ Merge │ → │Delete │ → │ Pull  │      │
│  │  Review   │   │  PR   │  │  PR   │   │Branch │   │ Main  │      │
│  └───────────┘   └───────┘  └───────┘   └───────┘   └───────┘      │
│                                                                      │
│  11. FINISH                                                          │
│  ┌───────────┐                                                       │
│  │ Comment   │                                                       │
│  │ + Log     │                                                       │
│  └───────────┘                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## Input

Expects a story specification:

```json
{
  "story": {
    "id": "1.1.1",
    "title": "Fetch from Stax Bill",
    "taskId": "26262388",
    "acceptanceCriteria": [
      "API client can fetch subscription by ID",
      "Retry logic with exponential backoff"
    ]
  },
  "context": {
    "repository": "SubscriptionsMicroservice",
    "project": "Atlas",
    "baseBranch": "main",
    "branchSlug": "fetch-from-staxbill"
  },
  "resume": {
    "enabled": false,
    "fromStep": null
  }
}
```

## Output

Returns delivery results with metrics:

```json
{
  "deliveryResult": {
    "story": {
      "id": "1.1.1",
      "status": "completed",
      "branch": "feature/1.1.1-fetch-from-staxbill",
      "pr": { "id": "1045", "url": "...", "status": "completed" }
    },
    "metrics": {
      "startedAt": "2025-12-12T10:00:00Z",
      "completedAt": "2025-12-12T14:30:00Z",
      "cycleTimeHours": 4.5,
      "testsAdded": 5,
      "commits": 3
    },
    "steps": {
      "completed": [
        {"step": 1, "name": "START", "duration": "2m"},
        {"step": 2, "name": "BRANCH", "duration": "30s"},
        ...
      ]
    },
    "quality": {
      "allTestsPassed": true,
      "codeReviewPassed": true,
      "architectureCompliant": true
    }
  }
}
```

## Workflow Steps

### Step 1: START - Log Story Start

**Purpose:** Signal story start, record lead time start

**Actions:**
1. Validate story input
2. Execute `/delivery:log-start`
3. Verify CSV logging and Teamwork comment

### Step 2: BRANCH - Create Feature Branch

**Purpose:** Isolate work, enable clean PR

**Actions:**
1. Execute `/git:git-sync`
2. Execute `/git:git-create-branch feature/{storyId}-{slug}`

**Branch Naming:** `feature/{story_id}-{slug}`

### Step 3: IMPLEMENT - Code and Tests

**Purpose:** Deliver story functionality with TDD

**Actions:**
1. Load architecture context
2. Invoke dev-agent with story
3. Monitor TDD cycles (Red-Green-Refactor)
4. Ensure atomic commits

### Step 4: TEST - Run All Tests

**Purpose:** Ensure quality, prevent regressions

**Actions:**
1. Execute `/dotnet:build`
2. Execute `/dotnet:test`
3. Verify all tests pass
4. Capture coverage

### Step 5: REVIEW - Self-Review

**Purpose:** Catch issues before PR

**Checklist:**
- Code follows conventions
- No security vulnerabilities
- No hardcoded secrets
- Error handling comprehensive
- Tests are meaningful

### Step 6: CODE-REVIEW - Deep Code Review

**Purpose:** AI-assisted review for Clean Architecture compliance

**Actions:**
1. Execute `/quality:code-review`
2. Fix critical violations
3. Document accepted technical debt

### Step 7: PR - Create Pull Request

**Purpose:** Document changes, enable review

**Actions:**
1. Push branch
2. Build PR description
3. Execute `/azuredevops:ado-create-pr`

**Human-in-the-Loop:** Pauses for user to review PR before merge.

### Step 8: MERGE - Merge Pull Request

**Purpose:** Integrate changes to main

**Actions:**
1. Verify PR approved and CI passed
2. Execute `/azuredevops:ado-merge-pr --squash`

**Human-in-the-Loop:** Waits for user confirmation.

### Step 9: CLEANUP - Delete Branch

**Purpose:** Keep repository clean

**Actions:**
1. Delete remote branch
2. Delete local branch

### Step 10: SYNC - Update Local Main

**Purpose:** Prepare for next story

**Actions:**
1. Checkout main
2. Execute `/git:git-sync`

### Step 11: FINISH - Log Story Completion

**Purpose:** Signal completion, record metrics

**Actions:**
1. Calculate metrics (cycle time, lead time)
2. Execute `/delivery:log-complete`
3. Generate delivery report

## Checkpoint and Resume

After each step, saves checkpoint to `.claude/session/story-checkpoint.json`:

```json
{
  "storyId": "1.1.1",
  "currentStep": 3,
  "status": "in_progress",
  "startedAt": "2025-12-12T10:00:00Z",
  "context": {
    "branch": "feature/1.1.1-fetch-from-staxbill",
    "commits": ["abc123", "def456"]
  }
}
```

### Resume Capability

When invoked with `resume: true`:
1. Load checkpoint
2. Verify current state matches
3. Resume from `currentStep + 1`

## Error Handling

### Recoverable Errors

Retry with exponential backoff (1s, 2s, 4s):
- Network timeouts
- API rate limits
- Temporary file locks

### Non-Recoverable Errors

Save checkpoint and return with recommendations:
- Merge conflicts
- Test failures
- Build errors

```json
{
  "error": {
    "step": 4,
    "type": "test_failure",
    "description": "Integration tests failing",
    "recommendation": "Check database configuration",
    "resumeFrom": 3
  }
}
```

## Metrics Tracking

### Per-Step Metrics

```json
{
  "1_START": "2m",
  "2_BRANCH": "30s",
  "3_IMPLEMENT": "3h",
  "4_TEST": "15m",
  ...
}
```

### Quality Metrics

```json
{
  "allTestsPassed": true,
  "testCoverage": 94,
  "codeReviewPassed": true,
  "architectureCompliant": true
}
```

## Configuration

```json
{
  "delivery": {
    "autoMerge": false,
    "requireApproval": true,
    "deleteSourceBranch": true,
    "squashMerge": true,
    "runCodeReview": true,
    "pauseBeforeMerge": true
  }
}
```

## Focus Areas

- **Orchestration** - Coordinate all 11 steps smoothly
- **Checkpoint/Resume** - Enable interruption and resumption
- **Metrics Tracking** - Capture comprehensive delivery metrics
- **Quality Gates** - Enforce testing and code review
- **Human-in-the-Loop** - Pause at PR creation and merge
- **Error Handling** - Graceful recovery from failures
- **Audit Trail** - Complete record of actions

## Integration Points

| Agent | Direction | Data |
|-------|-----------|------|
| dev-agent | Delegates to | TDD implementation (Step 3) |
| qa-agent | Optionally calls | Advanced testing (Step 4) |
| Teamwork | Integrates with | Status updates (Steps 1, 11) |
| Azure DevOps | Integrates with | PR lifecycle (Steps 7, 8) |

## Related

- [dev-agent](dev-agent.md) - Handles implementation
- [qa-agent](qa-agent.md) - Handles testing
- [index](index.md) - Agent overview
