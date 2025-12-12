# Design Agent

Explore solution options, make architecture decisions, and generate implementation plans.

## Overview

| Property | Value |
|----------|-------|
| **Name** | design-agent |
| **Model** | sonnet |
| **Tools** | Read |
| **Stage** | Design |

## Purpose

The Design Agent moves work from "what we are doing" (Plan) to "how we will do it" (Design). It bridges planning and delivery by:

- Researching problem space and constraints
- Producing solution options with tradeoffs
- Selecting preferred options with rationale
- Creating architecture decision records (ADRs)
- Generating implementation and test plans

## Architecture Awareness

Before designing, the agent checks for and loads:

| File | Purpose |
|------|---------|
| `.claude/architecture.yaml` | Architecture spec and guardrails |
| `.claude/agent-playbook.yaml` | Coding patterns and rules |

All options are validated against defined guardrails.

## Input

Expects a planned WorkItem:

```json
{
  "workItem": {
    "id": "TW-26134585",
    "name": "User authentication system",
    "type": "feature",
    "appetite": { "unit": "weeks", "value": 2 },
    "acceptanceCriteria": [...]
  },
  "context": {
    "project": "MyApp",
    "existingPatterns": ["JWT tokens"],
    "constraints": ["Must support mobile"]
  }
}
```

## Output

Returns designed WorkItem with artifacts:

```json
{
  "designResult": {
    "workItem": {
      "id": "TW-26134585",
      "status": "designed",
      "designBranch": "design/TW-26134585-auth"
    },
    "solutionOptions": [
      {
        "id": "option-1",
        "name": "JWT with refresh tokens",
        "pros": [...],
        "cons": [...],
        "effort": "medium",
        "risk": "low"
      }
    ],
    "selectedOption": {
      "id": "option-1",
      "rationale": "Fits microservices architecture..."
    },
    "adr": {
      "created": true,
      "path": "docs/architecture/adr/ADR-0042.md"
    },
    "implementationPlan": {
      "created": true,
      "tasks": [...]
    },
    "testPlan": {
      "created": true,
      "strategy": { "unit": "...", "integration": "..." }
    }
  }
}
```

## Design Process

### 1. Initialize Workspace

Create design workspace:

```
design/TW-{id}/
├── research/       # Research notes
├── options/        # Solution options
├── diagrams/       # Architecture diagrams
└── decisions/      # ADR drafts
```

### 2. Research Problem Space

- **Codebase Analysis:** Existing patterns, similar implementations, impacted components
- **External Research:** Documentation, best practices, security implications
- **Constraint Identification:** Technical, business, operational constraints

### 3. Generate Solution Options

Produce 2-4 meaningfully different options:

```markdown
## Option 1: JWT with refresh tokens

### Description
Stateless authentication using JWT...

### Pros
- Scalable - no session storage

### Cons
- Token revocation requires blocklist

### Effort: Medium
### Risk: Low
```

**Rules:**
- At least 2 options required
- One should be "simplest thing that works"
- Options must be meaningfully different

### 4. Evaluate and Select

Compare against criteria:

| Criterion | Weight | Option 1 | Option 2 |
|-----------|--------|----------|----------|
| Fits appetite | High | ✓ | ✗ |
| Meets criteria | Required | ✓ | ✓ |
| Follows patterns | Medium | ✓ | ✗ |

**Selection Rules:**
- Must fit within appetite
- Must meet all acceptance criteria
- Prefer existing patterns
- Choose simplest when equivalent

### 5. Create ADR

Generate Architecture Decision Record when:

- Introducing new technology or pattern
- Making breaking changes
- Deviating from established patterns
- Making irreversible decisions

```markdown
# ADR-{number}: {Title}

## Status
Proposed

## Context
{Why we need this decision}

## Decision
{What we decided}

## Consequences
### Positive / Negative / Neutral

## Alternatives Considered
```

### 6. Generate Implementation Plan

```markdown
# Implementation Plan: {Name}

## Task Breakdown

### Phase 1: Foundation
| Task | Estimate | Dependencies |
|------|----------|--------------|
| Task 1 | 2h | None |

## Task Details
### Task 1: {Name}
**Acceptance Criteria:**
- Criterion 1
```

### 7. Generate Test Plan

```markdown
# Test Plan: {Name}

## Test Levels
### Unit Tests
- Scope, Framework, Key cases

### Integration Tests
### End-to-End Tests
### Security Testing
### Performance Testing
```

### 8. Route to Next Stage

| Condition | Next Stage |
|-----------|------------|
| Design complete, ADR approved | deliver |
| Needs stakeholder review | design (stay) |
| Scope changed significantly | plan |
| Cannot fit in appetite | plan (split) |

## Architecture Compliance

Each option includes compliance check:

```json
{
  "architectureCompliance": {
    "guardrailsChecked": ["BE-G01", "BE-G02"],
    "status": "compliant",
    "notes": "Follows Application layer patterns"
  }
}
```

Non-compliant options are marked:

```json
{
  "architectureCompliance": {
    "status": "non-compliant",
    "violations": ["BE-G01: Would require Api to reference Infrastructure"],
    "mitigation": "Recommend Option 2"
  }
}
```

## Decision Escalation

Escalate to human review when:

- **High-Risk:** Security-critical, data model changes, breaking API changes
- **Scope Changes:** Larger than appetite, new requirements discovered
- **Uncertainty:** No clear best option, unfamiliar technology

## Edge Cases

### No Design Needed

For simple stories following established patterns:

```json
{
  "adr": { "created": false, "reason": "Follows ADR-0025" },
  "routing": { "nextStep": "deliver" }
}
```

### Design Reveals Larger Scope

```json
{
  "routing": {
    "nextStage": "plan",
    "splitRecommendation": [
      { "name": "Core auth (MVP)", "estimate": "2 weeks" },
      { "name": "Advanced features", "estimate": "2 weeks" }
    ]
  }
}
```

## Focus Areas

- **Thoroughness** - Research before deciding
- **Options** - Always explore alternatives
- **Rationale** - Document why, not just what
- **Testability** - Every decision should be verifiable
- **Simplicity** - Prefer simpler solutions when outcomes equal
- **Traceability** - Link decisions to requirements

## Integration Points

| Agent | Direction | Data |
|-------|-----------|------|
| plan-agent | Receives from | Planned WorkItem |
| dev-agent | Provides to | Implementation plan, ADR |
| architecture-review | Loads from | Architecture configuration |

## Related

- [plan-agent](plan-agent.md) - Previous stage
- [dev-agent](dev-agent.md) - Next stage
- [architecture-review](architecture-review.md) - Provides constraints
- [index](index.md) - Agent overview
