# Spike Report Guide

## Purpose

A spike report documents the findings from a time-boxed research or investigation effort. Spikes answer specific questions that must be resolved before planning or implementation can proceed. They reduce uncertainty and inform technical decisions.

## When to Create a Spike Report

Create a spike report when:

- **Unknown technology**: Evaluating a new framework, library, or service
- **Feasibility question**: Determining if an approach is viable
- **Integration research**: Understanding external API capabilities and limitations
- **Performance investigation**: Measuring baseline performance or identifying bottlenecks
- **Security assessment**: Evaluating security implications of an approach
- **Proof of concept**: Building minimal implementation to validate approach

Use simpler artifacts for:

- Questions answerable through documentation review
- Well-understood patterns with existing examples
- Decisions that don't require technical validation

## Relationship to Other Artifacts

### Spike Report Position in Workflow

```text
Work Item (Uncertainty identified)
  ↓ (time-boxed investigation)
Spike Report (Findings)
  ↓ (informs)
Plan Stage (Reduced uncertainty)
  ↓ (or)
Design Stage (Technical decisions)
```

### What Flows from Spike Report

**To Planning**:

- **Findings** → Acceptance criteria refinement
- **Recommendations** → Scope decisions
- **Constraints discovered** → Story constraints

**To Design**:

- **Technical evaluation** → Architecture decisions (ADRs)
- **Performance findings** → Non-functional requirements
- **Integration details** → API contracts

## Core Structure

### 1. Header and Metadata

```markdown
# Spike Report: [Title]

**Work Item**: [TW-12345 or WI-xxx]
**Time Box**: [X hours/days]
**Date**: [Investigation date]
**Status**: [Complete | In Progress | Abandoned]
```

### 2. Question

```markdown
## Question

[The specific question(s) this spike aims to answer. Should be concrete
and answerable with yes/no or specific findings.]
```

**Example**:

```markdown
## Question

Can we use Stax Bill webhooks to reliably detect subscription renewals, or do we need to poll the API?

Specifically:

1. Does Stax Bill emit a webhook when a subscription renews?
2. What fields are included in renewal-related events?
3. What is the typical latency between renewal and webhook delivery?
```

### 3. Background

```markdown
## Background

[Context that led to this spike. Why is this question important?
What decision depends on the answer?]
```

**Example**:

```markdown
## Background

Users are being locked out of the app after their subscription renews because our system doesn't detect the renewal. We need to understand how Stax Bill communicates renewal events so we can implement proper sync.

The answer will determine whether we:

- Implement webhook handlers (preferred, real-time)
- Implement polling jobs (fallback, delayed)
- Use a combination approach (resilient)
```

### 4. Approach

```markdown
## Approach

[What you did to investigate. Include methods, tools, and scope.]

- [Investigation step 1]
- [Investigation step 2]
- [Investigation step 3]
```

**Example**:

```markdown
## Approach

1. Reviewed Stax Bill API documentation for webhook events
2. Examined Stax Bill webhook logs from last 30 days in staging
3. Created test subscription and triggered manual renewal in sandbox
4. Analyzed webhook payload structure for InvoiceStatusChanged events
5. Measured delivery latency for 10 test events
```

### 5. Findings

```markdown
## Findings

### [Finding Category 1]

[Detailed findings with evidence]

### [Finding Category 2]

[Detailed findings with evidence]
```

**Example**:

```markdown
## Findings

### Webhook Events for Renewals

Stax Bill does NOT emit a dedicated "subscription renewed" event. However, it does emit:

- `InvoiceStatusChanged` when invoice moves to `paid` status
- `InvoiceCreated` when renewal invoice is generated

The `InvoiceStatusChanged` event with `status: paid` is the reliable signal for renewal.

### Payload Contents

```json
{
  "eventType": "InvoiceStatusChanged",
  "data": {
    "invoiceId": "inv-123",
    "subscriptionId": "sub-456",
    "status": "paid",
    "periodStart": "2024-01-01",
    "periodEnd": "2024-02-01"
  }
}
```

### Delivery Latency

- Average: 2.3 seconds
- P95: 8 seconds
- P99: 15 seconds
- No events lost in 100 test deliveries
```

### 6. Constraints Discovered

```markdown
## Constraints Discovered

[Limitations, gotchas, or unexpected behaviors found during investigation]

- [Constraint 1]
- [Constraint 2]
```

**Example**:

```markdown
## Constraints Discovered

- `SubscriptionUpdated` webhook does NOT fire for automatic renewals (only manual changes)
- Invoice events do not include customer email (must fetch separately)
- Webhook retry policy is 3 attempts over 24 hours (can miss events if endpoint down)
- No webhook for failed payment retries (only final failure after dunning)
```

### 7. Recommendations

```markdown
## Recommendations

[Clear recommendations based on findings. Include rationale.]

1. **[Recommendation 1]**: [Rationale]
2. **[Recommendation 2]**: [Rationale]
```

**Example**:

```markdown
## Recommendations

1. **Use InvoiceStatusChanged as primary renewal signal**: This is the only reliable event that fires for automatic renewals.

2. **Implement reconciliation job as safety net**: Given webhook retry policy, run nightly job to catch any missed events.

3. **Fetch subscription details via API on webhook receipt**: Since webhook payload lacks customer context, call GET /subscriptions/{id} for full data.

4. **Add idempotency by invoiceId**: Prevent duplicate processing if webhook retries occur.
```

### 8. Open Questions

```markdown
## Open Questions

[Questions that remain unanswered or require further investigation]

- [Question 1]
- [Question 2]
```

**Example**:

```markdown
## Open Questions

- What happens if webhook endpoint returns 5xx? Does Stax Bill retry immediately or backoff?
- Can we configure webhook retry behavior through Stax Bill admin portal?
- Are there rate limits on the GET /subscriptions API we'd use for enrichment?
```

### 9. Artifacts (Optional)

```markdown
## Artifacts

[Links to code, documents, or resources produced during the spike]

- [Artifact 1]: [Link or path]
- [Artifact 2]: [Link or path]
```

**Example**:

```markdown
## Artifacts

- Webhook payload samples: `/spikes/tw-12345/webhook-samples/`
- Test script: `/spikes/tw-12345/test-renewal.sh`
- API response examples: `/spikes/tw-12345/api-responses.json`
```

## Template

When creating a new spike report, use this template:

```markdown
# Spike Report: [Title]

**Work Item**: [ID]
**Time Box**: [Duration]
**Date**: [Date]
**Status**: Complete

## Question

[Specific question(s) to answer]

## Background

[Context and why this matters]

## Approach

- [Step 1]
- [Step 2]
- [Step 3]

## Findings

### [Category 1]

[Findings with evidence]

### [Category 2]

[Findings with evidence]

## Constraints Discovered

- [Constraint 1]
- [Constraint 2]

## Recommendations

1. **[Recommendation]**: [Rationale]
2. **[Recommendation]**: [Rationale]

## Open Questions

- [Question 1]
- [Question 2]

## Artifacts

- [Artifact]: [Link]
```

## Spike Types and Focus Areas

### Technology Evaluation Spike

**Focus**: Can we use X technology for Y purpose?

**Key sections**:

- Findings: Feature comparison, performance benchmarks
- Constraints: Limitations, licensing, support
- Recommendations: Adopt, reject, or evaluate further

### Integration Spike

**Focus**: How do we integrate with X external system?

**Key sections**:

- Findings: API capabilities, authentication, data formats
- Constraints: Rate limits, data gaps, latency
- Recommendations: Integration approach, fallback strategies

### Performance Spike

**Focus**: What are the performance characteristics of X?

**Key sections**:

- Findings: Baseline metrics, bottleneck identification
- Constraints: Hardware limits, scaling boundaries
- Recommendations: Optimization priorities, target metrics

### Feasibility Spike

**Focus**: Is X approach technically possible?

**Key sections**:

- Findings: Proof of concept results, technical viability
- Constraints: Blockers, workarounds needed
- Recommendations: Proceed, pivot, or abandon

## Common Pitfalls

### Avoid These Mistakes

1. **Vague questions**: "Investigate webhooks" instead of specific question
   - **Fix**: Frame as answerable question with clear success criteria

2. **Scope creep**: Spike expands beyond original question
   - **Fix**: Time-box strictly, document new questions for future spikes

3. **No recommendations**: Findings without actionable guidance
   - **Fix**: Always include clear recommendations based on findings

4. **Missing constraints**: Only happy path documented
   - **Fix**: Actively look for limitations, edge cases, and gotchas

5. **No artifacts**: Code/samples discarded after spike
   - **Fix**: Preserve useful artifacts for implementation reference

6. **Endless spike**: Investigation continues indefinitely
   - **Fix**: Set and enforce time box, report findings even if incomplete

## Maintenance

Spike reports are generally static documents. Update only if:

- Follow-up investigation adds significant findings
- Recommendations need revision based on new information
- Referenced artifacts move or become unavailable

## Markdown Linting Requirements

All spike reports must comply with the markdown standards defined in [markdown-standards.md](../markdown-standards.md).

### Quick Validation

```bash
markdownlint spike-report.md
```

## Summary

A well-crafted spike report:

- **Answers** specific questions with evidence
- **Documents** approach and methodology
- **Reveals** constraints and limitations
- **Provides** actionable recommendations
- **Preserves** artifacts for future reference
- **Respects** time box while delivering value

Use this guide when creating spike reports for research or investigation work items.
