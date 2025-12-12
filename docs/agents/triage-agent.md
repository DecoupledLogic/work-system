# Triage Agent

Categorize work items, assign process templates, and route to appropriate queues.

## Overview

| Property | Value |
|----------|-------|
| **Name** | triage-agent |
| **Model** | sonnet |
| **Tools** | Read |
| **Stage** | Triage |

## Purpose

The Triage Agent turns raw or normalized work items into fully categorized, template-assigned, queue-routed work. It bridges the gap between intake and planning by ensuring every work item has:

- Correct Type classification
- WorkType assignment
- Urgency categorization
- Impact assessment
- ProcessTemplate assignment
- Queue routing decision

## Input

Expects a normalized WorkItem or raw context:

```json
{
  "workItem": {
    "id": "TW-26134585",
    "name": "Update database schema",
    "description": "Customer requests schema update...",
    "type": "story",
    "workType": "support",
    "urgency": "now",
    "impact": "medium",
    "status": "triage",
    "parentId": "TW-26134584",
    "source": {
      "system": "teamwork",
      "projectId": "545123"
    }
  }
}
```

Or raw context: email content, ticket description, customer request, bug report.

## Output

Returns triaged WorkItem with template and routing:

```json
{
  "triageResult": {
    "workItem": {
      "id": "TW-26134585",
      "type": "story",
      "workType": "support",
      "urgency": "now",
      "impact": "medium",
      "status": "planned",
      "processTemplate": "support/generic"
    },
    "routing": {
      "queue": "todo",
      "nextStage": "plan",
      "skipToDeliver": false,
      "reason": "Support request requires planning"
    },
    "templateMatch": {
      "templateId": "support/generic",
      "confidence": "high",
      "matchReason": "WorkType=support, no specific pattern"
    },
    "triageNotes": {
      "typeRationale": "Story - has parent, small scope",
      "workTypeRationale": "Support - task list is Production Support",
      "urgencyRationale": "Now - new status, due within 7 days"
    }
  }
}
```

## Triage Process

### 1. Categorize Work Item Type

| Type | Indicators |
|------|------------|
| `epic` | Large initiative, multiple features, months of work |
| `feature` | Distinct capability, multiple stories, weeks of work |
| `story` | User-facing value, testable, days of work |
| `task` | Atomic implementation unit, hours of work |

**Type Decision Tree:**

1. Has children, no parent → `epic`
2. Parent is epic-level, has children → `feature`
3. Parent is feature-level, deliverable → `story`
4. Parent is story-level, atomic → `task`
5. Standalone, size > 2 weeks → `epic`
6. Standalone, size 1-2 weeks → `feature`
7. Standalone, size < 1 week → `story`

### 2. Align with Parent Work Item

| Condition | Action |
|-----------|--------|
| Belongs to existing epic/feature | Link as child |
| Matches epic but not feature | Create feature under epic |
| Doesn't match any epic | Create new epic if scope warrants |
| Standalone and small | Accept without parent |

### 3. Categorize Work Type

| WorkType | Indicators | Template Category |
|----------|------------|-------------------|
| `support` | Customer request, account issue | `support/*` |
| `bug_fix` | Defect, error, regression | `delivery/bug-fix` |
| `product_delivery` | New feature, enhancement | `product/*` |
| `maintenance` | Tech debt, refactor | `delivery/maintenance` |
| `research` | Spike, investigation, POC | `delivery/research` |

### 4. Categorize Impact

| Impact | Indicators |
|--------|------------|
| `high` | Revenue-affecting, security, SLA breach, many users |
| `medium` | Noticeable improvement, subset of users |
| `low` | Nice to have, minor polish, few users |

### 5. Categorize Urgency

| Urgency | Criteria | Queue |
|---------|----------|-------|
| `critical` | Must handle today, interrupts work | immediate |
| `now` | Current cycle, active work | todo |
| `next` | Next cycle, near-term backlog | backlog |
| `future` | Long-term, someday/maybe | icebox |

**Urgency Decision:**

1. Tags contain "critical", "urgent" → `critical`
2. Due date is past → `critical`
3. Due date within 3 days → `now`
4. Due date within 14 days → `next`
5. Due date > 14 days → `future`
6. Status is "reopened" → `now`
7. No due date, status = "new" → `next`

### 6. Assign Process Template

**Resolution Order:**

1. Check for exact pattern match (e.g., "remove profile" → `support/remove-profile`)
2. Check for work type match (e.g., support → `support/generic`)
3. Check for type match (e.g., story → `product/story`)
4. Fall back to generic (`delivery/generic`)

### 7. Route to Queue

**Queue Mapping:**

| Urgency | Queue |
|---------|-------|
| critical | immediate |
| now | todo |
| next | backlog |
| future | icebox |

**Next Stage Decision:**

| Condition | Next Stage |
|-----------|------------|
| Needs decomposition (epic, feature, complex story) | plan |
| Needs design (technical decisions) | design |
| Ready to implement (simple task, known solution) | deliver |
| Needs more information | triage (stay) |

**Skip-to-Deliver Criteria:**

- Type is `task`
- Has clear acceptance criteria
- Solution is known/obvious
- Estimate < 4 hours
- No dependencies

## Template Matching Patterns

### Support Templates

| Pattern | Template | Indicators |
|---------|----------|------------|
| Remove profile | `support/remove-profile` | "delete", "remove", "close account" |
| Subscription change | `support/subscription-change` | "plan change", "upgrade" |
| Account issue | `support/account-issue` | "can't login", "access" |
| Data correction | `support/data-correction` | "fix", "incorrect", "wrong" |
| Generic | `support/generic` | Other support requests |

### Product Templates

| Pattern | Template |
|---------|----------|
| PRD | `product/prd` |
| Story | `product/story` |
| Feature | `product/feature` |

### Delivery Templates

| Pattern | Template |
|---------|----------|
| Bug fix | `delivery/bug-fix` |
| ADR | `delivery/adr` |
| Maintenance | `delivery/maintenance` |
| Research | `delivery/research` |

## Edge Cases

### Ambiguous Type

Prefer `story` over `task` - easier to decompose than merge.

### Conflicting Signals

Precedence (highest to lowest):

1. Explicit tags
2. Customer communication
3. Due date
4. Priority field
5. Defaults

### No Template Match

```json
{
  "templateMatch": {
    "templateId": null,
    "confidence": "none",
    "suggestedTemplate": {
      "category": "support",
      "name": "new-pattern-name"
    }
  }
}
```

## Output Validation

Before returning, verify:

1. `type` is one of: epic, feature, story, task, client_request
2. `workType` is one of: product_delivery, support, maintenance, bug_fix, research
3. `urgency` is one of: critical, now, next, future
4. `impact` is one of: high, medium, low
5. `routing.queue` is one of: immediate, todo, backlog, icebox
6. `routing.nextStage` is one of: triage, plan, design, deliver

## Focus Areas

- **Accuracy** - Correct categorization reduces rework
- **Consistency** - Same patterns yield same results
- **Transparency** - Document all reasoning in triageNotes
- **Actionability** - Every item has a clear next step
- **Templates** - Actively match to drive consistent processes

## Integration Points

| Agent | Direction | Data |
|-------|-----------|------|
| work-item-mapper | Receives from | Normalized WorkItem |
| plan-agent | Provides to | Triaged WorkItem |
| template-validator | Uses | Template validation |

## Related

- [work-item-mapper](work-item-mapper.md) - Provides normalized input
- [plan-agent](plan-agent.md) - Next stage
- [template-validator](template-validator.md) - Validates templates
- [index](index.md) - Agent overview
