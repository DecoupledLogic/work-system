# Plan Agent

Decompose, size, and elaborate work items.

## Overview

| Property | Value |
|----------|-------|
| **Name** | plan-agent |
| **Model** | sonnet |
| **Tools** | Read |
| **Stage** | Plan |

## Purpose

The Plan Agent shapes triaged work items into right-sized, well-defined chunks ready for design or delivery. It bridges the gap between triage and implementation by ensuring every work item:

- Is sized within type bounds
- Has clear parent/child relationships
- Has appropriate acceptance criteria
- Is assigned to the correct next stage

## Input

Expects a triaged WorkItem:

```json
{
  "workItem": {
    "id": "TW-26134585",
    "name": "User authentication system",
    "type": "feature",
    "workType": "product_delivery",
    "urgency": "now",
    "impact": "high",
    "status": "planned",
    "processTemplate": "product/feature"
  }
}
```

## Output

Returns a planned WorkItem with decomposition:

```json
{
  "planResult": {
    "workItem": {
      "id": "TW-26134585",
      "type": "feature",
      "appetite": { "unit": "weeks", "value": 2 },
      "childrenIds": ["TW-26134586", "TW-26134587"]
    },
    "children": [
      {
        "id": "TW-26134586",
        "name": "Basic login",
        "type": "story",
        "appetite": { "unit": "days", "value": 2 },
        "acceptanceCriteria": [...]
      }
    ],
    "routing": {
      "parentNextStage": "design",
      "childrenNextStage": "design"
    },
    "planDocument": {
      "created": true,
      "path": "docs/plans/TW-26134585-auth.md"
    }
  }
}
```

## Sizing Bounds

| Type | Unit | Maximum | Typical |
|------|------|---------|---------|
| Epic | cycles (2-week) | 3 cycles | 1-2 cycles |
| Feature | weeks | 2 weeks | 1 week |
| Story | days | 3 days | 1-2 days |
| Task | hours | 8 hours | 2-4 hours |

## Plan Process

### 1. Infer Size (Appetite)

Estimate based on type bounds:

**Epics:** Count expected features, add 20% coordination overhead

**Features:** Count expected stories, add 10% integration overhead

**Stories:** Assess complexity (simple 1d, medium 2d, complex 3d)

**Tasks:** Break into atomic units, each completable in one session

### 2. Split If Too Large

When work exceeds bounds:

**Epic Splitting:** Identify distinct value streams
**Feature Splitting:** Separate core from enhancements
**Story Splitting:** Use INVEST criteria, split by:
- User type (admin vs regular)
- Operation (CRUD)
- Scenario (happy path, error handling)
- Interface (API, UI, CLI)

### 3. Break Down (Decomposition)

Create child work items:

```
Epic: Customer Portal
├── Feature: User Dashboard
│   ├── Story: View account summary
│   │   ├── Task: Create summary API endpoint
│   │   ├── Task: Implement summary widget
│   │   └── Task: Write unit tests
│   └── Story: See recent activity
└── Feature: Order Management
```

### 4. Elaborate (Add Details)

Fill in type-specific fields:

| Type | Required Fields |
|------|-----------------|
| Epic | value, risk, vision statement |
| Feature | vision, boundaries, integration points |
| Story | acceptanceCriteria (Gherkin format) |
| Task | effortEstimateHours, definition of done |

### 5. Route to Next Stage

| Condition | Next Stage |
|-----------|------------|
| Epic/Feature with technical decisions | design |
| Feature with known solution | deliver |
| Story needing architecture | design |
| Story with clear implementation | deliver |
| Task ready to implement | deliver |

## Priority Scoring

```
Score = (Urgency × 4) + (Impact × 2) + (ParentValue × 1) - (ParentRisk × 0.5)

Urgency: critical=4, now=3, next=2, future=1
Impact: high=3, medium=2, low=1
```

## Acceptance Criteria Format

Use Gherkin format for stories:

```gherkin
Given a registered user with valid credentials
When they enter their password correctly
Then they see the dashboard
And their session is active
```

## Plan Document Generation

For epics and complex features:

```markdown
# Plan: {workItem.name}

## Overview
- ID, Type, Appetite, Status

## Vision
{feature vision or epic value statement}

## Scope
- In Scope / Out of Scope

## Breakdown
{list of children with estimates}

## Dependencies
## Risks
## Success Criteria
## Timeline
```

## Edge Cases

### Unclear Scope

- Note uncertainty in planNotes
- Create placeholder children with "TBD" prefixes
- Recommend staying in plan stage

### Missing Parent Context

- Infer context from description
- Flag for parent alignment review
- Continue with best-effort planning

### No Clear Decomposition

- Confirm item is atomic (task or simple story)
- Add acceptance criteria
- Route directly to deliver

## Focus Areas

- **Right-sizing** - Items must fit type bounds
- **Clarity** - Each item has clear scope and criteria
- **Completeness** - Decomposition covers full scope
- **Actionability** - Every output has a clear next step
- **Traceability** - Parent-child relationships maintained

## Integration Points

| Agent | Direction | Data |
|-------|-----------|------|
| triage-agent | Receives from | Triaged WorkItem |
| design-agent | Provides to | Planned WorkItem |
| dev-agent | Provides to | Ready-to-implement tasks |

## Related

- [triage-agent](triage-agent.md) - Previous stage
- [design-agent](design-agent.md) - Next stage (if design needed)
- [index](index.md) - Agent overview
