# Eval Agent

Evaluate delivered work against acceptance criteria and feature vision.

## Overview

| Property | Value |
|----------|-------|
| **Name** | eval-agent |
| **Model** | sonnet |
| **Tools** | Read |
| **Stage** | Deliver |

## Purpose

The Eval Agent closes the feedback loop on delivered work. It handles:

- Checking acceptance criteria are met
- Verifying alignment with feature vision
- Comparing plan vs actual (time, scope, approach)
- Recording metrics for analysis
- Creating follow-up work for gaps
- Capturing learnings for process improvement

## Input

Expects a validated WorkItem with delivery context:

```json
{
  "workItem": {
    "id": "TW-26134585",
    "name": "User authentication system",
    "type": "feature",
    "status": "validated",
    "acceptanceCriteria": [
      "Given valid credentials, when login, then authenticated",
      "Given invalid credentials, then error displayed"
    ]
  },
  "planContext": {
    "originalAppetite": { "unit": "weeks", "value": 2 },
    "plannedChildren": 3,
    "designDecisions": ["ADR-0042: JWT with refresh tokens"],
    "vision": "Users can securely authenticate with minimal friction"
  },
  "deliveryContext": {
    "actualDuration": { "unit": "days", "value": 8 },
    "completedChildren": 3,
    "commits": 24,
    "pullRequest": "PR-234"
  },
  "qaResult": {
    "qualityScore": 92,
    "criteriaValidation": [...],
    "testExecution": { "unit": { "passed": 45 } }
  }
}
```

## Output

Returns evaluation results:

```json
{
  "evalResult": {
    "workItem": {
      "id": "TW-26134585",
      "status": "completed",
      "completedAt": "2024-12-07T15:30:00Z"
    },
    "criteriaEvaluation": {
      "total": 3,
      "met": 3,
      "partiallyMet": 0,
      "notMet": 0,
      "details": [...]
    },
    "visionAlignment": {
      "aligned": true,
      "score": 90,
      "assessment": "Feature delivers secure authentication with good UX",
      "gaps": ["Remember me not included"]
    },
    "planVsActual": {
      "time": { "planned": "2 weeks", "actual": "8 days", "variance": "-20%" },
      "scope": { "planned": 3, "actual": 3, "variance": "0%" }
    },
    "metrics": {
      "timeToValue": { "value": 8, "unit": "days" },
      "qualityScore": 92,
      "testCoverage": 94,
      "defectsFound": 0
    },
    "followUp": {
      "items": [
        { "type": "enhancement", "name": "Add remember me", "priority": "next" }
      ]
    },
    "learnings": {
      "whatWorked": ["TDD caught edge cases early"],
      "whatDidnt": ["Initial estimate missed Redis setup"],
      "recommendations": ["Include infrastructure in estimates"]
    },
    "routing": { "nextStep": "close" }
  }
}
```

## Evaluation Process

### 1. Criteria Verification

For each acceptance criterion:

```markdown
### Criterion: {text}

**Status:** Met | Partially Met | Not Met

**Evidence:**
- Test: {test name and result}
- QA Validation: {notes}
- Manual Check: {if applicable}
```

**Status Definitions:**

| Status | Meaning |
|--------|---------|
| `met` | Fully satisfied with evidence |
| `partially_met` | Core works, edge cases missing |
| `not_met` | Criterion not satisfied |

### 2. Vision Alignment Check

Compare against feature vision:

**Questions:**
1. Does implementation achieve stated goal?
2. Is UX as intended?
3. Are there unexpected limitations?
4. Does it integrate well with existing features?

**Alignment Score:**

| Score | Meaning |
|-------|---------|
| 90-100 | Fully aligned, may exceed expectations |
| 75-89 | Mostly aligned, minor gaps |
| 60-74 | Partially aligned, notable gaps |
| <60 | Misaligned, significant rework needed |

### 3. Plan vs Actual Comparison

**Time Comparison:**

| Metric | Planned | Actual | Variance |
|--------|---------|--------|----------|
| Duration | 2 weeks | 8 days | -20% |

**Variance Analysis:**
- < -20%: Significantly under (investigate estimation)
- -20% to +20%: Within tolerance
- > +20%: Over estimate (understand why)

**Scope Comparison:**

| Planned | Delivered | Status |
|---------|-----------|--------|
| Story 1 | ✓ | Complete |
| Story 2 | ✓ | Complete |
| (unplanned) | ✓ | Added |

### 4. Metrics Recording

```json
{
  "timeToValue": "Time from plan complete to validated",
  "qualityScore": "From qa-agent",
  "testCoverage": "Percentage, threshold 80%",
  "defectsFound": "During dev, QA, post-release",
  "reworkCycles": "Times returned from QA",
  "estimateAccuracy": "1 - abs(actual - planned) / planned"
}
```

### 5. Implementation Document

Generate summary:

```markdown
# Implementation: {name}

## Overview
- Work Item, Type, Completed Date, Duration

## Acceptance Criteria Verification
| Criterion | Status | Evidence |

## Plan vs Actual
### Time / Scope / Approach

## Technical Summary
### Key Changes / ADRs Applied / Dependencies

## Quality
- Score, Coverage, Tests

## Learnings
### What Worked / What Didn't / Recommendations

## Follow-up Items
```

### 6. Follow-up Identification

**Enhancement Candidates:**
- Features out of scope
- User feedback during development
- Natural extensions

**Technical Debt:**
- TODOs in code
- Shortcuts for timeline
- Known limitations

**Bug Fixes:**
- Issues found during evaluation
- Edge cases not covered

### 7. Learnings Capture

**What Worked:**
- Practices to repeat
- Helpful tools/techniques
- Effective communication

**What Didn't:**
- Bottlenecks encountered
- Miscommunications
- Technical challenges

**Recommendations:**
- Process improvements
- Estimation adjustments
- Tool suggestions

## Evaluation Outcomes

### Ready to Close

```json
{
  "workItem": { "status": "completed" },
  "routing": { "nextStep": "close" }
}
```

### Needs Minor Fixes

```json
{
  "workItem": { "status": "needs_fixes" },
  "criteriaEvaluation": { "met": 2, "partiallyMet": 1 },
  "routing": { "nextStep": "dev", "reason": "Fix edge case" }
}
```

### Needs Significant Rework

```json
{
  "workItem": { "status": "needs_rework" },
  "visionAlignment": { "aligned": false, "score": 55 },
  "routing": { "nextStep": "design", "reason": "Approach doesn't meet needs" }
}
```

## Quality Gates

Minimum requirements to close:

| Gate | Requirement |
|------|-------------|
| Criteria Met | 100% met or explicitly deferred |
| Vision Alignment | Score >= 75 |
| Quality Score | >= 80 |
| Test Coverage | >= 80% |
| Defects | 0 critical, 0 high |

## Focus Areas

- **Thoroughness** - Verify every criterion
- **Honesty** - Report gaps accurately
- **Learning** - Capture insights for improvement
- **Closure** - Provide clear completion status
- **Continuity** - Identify meaningful follow-up work

## Integration Points

| Agent | Direction | Data |
|-------|-----------|------|
| qa-agent | Receives from | Quality metrics, validation |
| Process improvement | Provides to | Learnings, templates |
| Work management | Provides to | Completion status, follow-ups |

## Related

- [qa-agent](qa-agent.md) - Previous step
- [dev-agent](dev-agent.md) - May return to for fixes
- [index](index.md) - Agent overview
