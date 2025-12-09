# Delivery Plan Guide

## Purpose

A delivery plan is a comprehensive, implementation-focused document that bridges architecture design and actual development work. It translates high-level architectural principles into concrete stories, tasks, and acceptance criteria that developers can execute. The delivery plan is the single source of truth for what will be built, in what order, and how success is measured.

## When to Create a Delivery Plan

Create a delivery plan when:

- **Multi-epic initiative**: Work spans multiple features or system components
- **Architectural changes**: New patterns, service boundaries, or integration approaches
- **Team coordination**: Multiple developers or teams working in parallel
- **Staged rollout**: Phased deployment with dependencies between stages
- **Significant scope**: More than 40 hours of development effort

Use simpler artifacts for:

- Single-story tasks (< 8 hours)
- Standard CRUD features with established patterns
- Quick bug fixes or hotfixes

## Relationship to Other Artifacts

### Delivery Plan Position in Workflow

```text
Architecture Blueprint (Design)
  ↓ (translates to)
Delivery Plan (Implementation)
  ↓ (summarizes to)
Estimate CSV (Hours)
  ↓ (communicates to)
Presentation Deck (Alignment)
```

### Alignment Requirements

**From Architecture Blueprint**:

- **Principles** → Strategy section in delivery plan
- **Components** → Epics/Features in delivery plan
- **Event Contracts** → Code examples in delivery plan
- **Domain Models** → Entity definitions in delivery plan

**To Estimate CSV**:

- **Epics** → Epic rows in CSV
- **Features** → Feature rows in CSV
- **Stories** → Story rows in CSV with hour estimates
- **Total Hours** → Sum of all story hours

**To Presentation Deck**:

- **Epic Goals** → Epic breakdown slides
- **Success Metrics** → KPI slides
- **Deployment Strategy** → Phased rollout slides
- **Code Examples** → Technical deep dive slides (optional)

## Core Structure

### Header and Metadata

```markdown
# [Initiative Name] Delivery Plan

**Task**: [Teamwork Task URL]
**Blueprint**: [Link to architecture design doc]
**Estimate**: [Link to estimate.csv]

## Strategy

[One paragraph: Iterative delivery approach from immediate fix to full architecture alignment]

## Problem

[Bulleted list describing current broken behavior and why it matters]
```

**Example**:

```markdown
# Subscription Renewal Sync Fix Delivery Plan

**Task**: <https://discovertec.teamwork.com/app/tasks/26253606>
**Blueprint**: /atlas-support/subscription-and-entitlement-architecture-design.md
**Estimate**: /atlas-support/tasks/tw-26253606/estimate.csv

## Strategy

Iterative delivery from immediate renewal fix to full architecture alignment

## Problem

- Link uses Stax Bill to manage subscriptions.
- The app starts users on a trial, displays upgrade banner when trial ends.
- When user converts to paid plan, Stax Bill sends "subscription created" webhook.
- What is missing:
  - Reliable signal when existing subscription renews for next billing period.
  - Reliable way to know when user successfully pays next invoice.
```

### Implementation Plan Structure

```markdown
## Implementation Plan

### Epic 1: [Epic Name]

**Goal:** [One sentence describing epic purpose]

**Task:** [Teamwork task URL for this epic]

#### Feature 1.1: [Feature Name]

Purpose: [One sentence describing feature purpose]

##### Story 1.1.1: [Story Name]

- GIVEN [precondition]
- WHEN [action]
- THEN [expected outcome]
- AND [additional expectation]

[Optional: Implementation details, code examples, edge cases]

##### Story 1.1.2: [Next Story Name]

[Repeat structure...]

#### Feature 1.2: [Next Feature Name]

[Repeat structure...]

#### Epic 1 Deployment

**Prerequisites:**
- [Prerequisite 1]
- [Prerequisite 2]

**Deploy:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Rollback:**
- [Rollback procedure]

**Risk:** [Low/Medium/High] - [Brief explanation]

#### Epic 1 Success Metrics

- [Metric 1]: [Target value]
- [Metric 2]: [Target value]
- [Metric 3]: [Target value]

### Epic 2: [Next Epic Name]

[Repeat structure...]
```

## Heading Hierarchy

**Critical for Markdown Linting and Readability**:

```markdown
# Delivery Plan Title (H1)
## Major Sections (H2): Strategy, Problem, Implementation Plan, Release Plan
### Epic N: Epic Name (H3)
#### Feature N.M: Feature Name (H4)
##### Story N.M.P: Story Name (H5)
###### Sub-sections if needed (H6): Edge Cases, Error Handling
```

**Never use bold text as headings**: `**Epic 1: Renewal Fix**` ❌
**Always use proper heading syntax**: `### Epic 1: Renewal Fix` ✅
**Never use numbered headings**: `### 1. Epic 1: Renewal Fix` ❌
**Never use icons in headings**: `### 🚀 Epic 1: Renewal Fix` ❌

## Epic Structure Best Practices

### Epic Naming

Format: `Epic [Number]: [Name]`

**Examples**:

- `Epic 1: Renewal Fix`
- `Epic 2: Schema Enhancement`
- `Epic 0: Cross Cutting Concerns`

**Why Epic 0 exists**: Cross-cutting concerns (testing, monitoring, rollback) that apply to all other epics

### Epic Components

Every epic must have:

1. **Goal**: One sentence describing the epic's purpose
2. **Task Link**: URL to Teamwork task (or similar tracking system)
3. **Features**: 2-5 features that compose the epic
4. **Deployment Section**: Prerequisites, steps, rollback, risk level
5. **Success Metrics**: 3-5 measurable KPIs for the epic

### Feature Naming

Format: `Feature [Epic].[Feature]: [Name]`

**Examples**:

- `Feature 1.1: Core Sync Service`
- `Feature 1.2: Invoice Webhook Handler`
- `Feature 2.1: Database Schema Enhancement`

### Story Naming and Acceptance Criteria

Format: `Story [Epic].[Feature].[Story]: [Name]`

**Examples**:

- `Story 1.1.1: Fetch from Stax Bill`
- `Story 1.1.2: Update Local Database`
- `Story 2.1.1: Migrate Database`

**Acceptance Criteria Structure** (Gherkin-style):

```markdown
##### Story 1.1.1: Fetch from Stax Bill

- GIVEN a valid Stax Bill subscription ID
- WHEN `SyncSubscriptionFromStaxBillAsync(staxbillSubId)` is called
- THEN subscription data is fetched from Stax Bill API
- AND returned DTO includes `customerId`, `status`, `currentPeriodEnd`, `currentPeriodStart`
```

**Why Gherkin**:

- Clear, testable acceptance criteria
- Maps directly to integration tests
- Product and engineering alignment on "done"

## Story Implementation Details

### When to Include Code Examples

**Include code examples when**:

- Pattern is non-obvious (webhook signature validation, grace period logic)
- Integration point with external system (Stax Bill API client)
- Event contract definition (SubscriptionStateChanged schema)
- Complex business logic (IsEntitled computed property)

**Skip code examples when**:

- Standard CRUD operations (simple repository methods)
- Obvious implementations (basic DTOs, simple endpoints)
- Well-established patterns (FastEndpoints structure, EF migrations)

### Code Example Format

````markdown
##### Story 1.2.1: Receive Invoice Events

- GIVEN Stax Bill sends `invoice.statusChanged` webhook
- WHEN webhook is received at `/webhooks/staxbill`
- THEN signature is validated
- AND event is processed idempotently

**Implementation**:

```csharp
public class StaxbillWebhookEndpoint : Ep.Req<StaxbillWebhookRequest>.Res<Ok>
{
    public override void Configure()
    {
        Post("/webhooks/staxbill");
        AllowAnonymous(); // Signature validation in handler
    }

    public override async Task<Ok> ExecuteAsync(
        StaxbillWebhookRequest req, CancellationToken ct)
    {
        // Validate signature
        var isValid = ValidateSignature(req.Signature, req.Body);
        if (!isValid) throw new UnauthorizedException();

        // Idempotency check
        var eventId = $"{req.EventType}:{req.ObjectId}";
        if (await eventLog.ExistsAsync(eventId, ct))
            return TypedResults.Ok(); // Already processed

        // Process event
        if (req.EventType == "invoice.statusChanged" && req.Data.Status == "paid")
        {
            await syncService.SyncSubscriptionFromStaxBillAsync(
                req.Data.SubscriptionId, ct);
        }

        await eventLog.RecordAsync(eventId, ct);
        return TypedResults.Ok();
    }
}
```
````

### Edge Cases and Error Handling

When describing stories with complex failure modes, include an "Edge Cases" subsection:

````markdown
##### Story 1.1.4: Handle Edge Cases

- GIVEN sync service encounters an error
- WHEN Stax Bill API returns 5xx error
- THEN operation is retried with exponential backoff (3 attempts)
- AND if all retries fail, error is logged and reconciliation will catch it

**Edge Cases**:
- Subscription not found in Stax Bill → Log warning, skip update
- Stax Bill API timeout → Retry with circuit breaker pattern
- Invalid subscription data from API → Log error, do not update local DB
- Concurrent sync requests for same subscription → Lock by subscriptionId
````

## Deployment Section Guidelines

### Prerequisites

List all requirements before deployment can proceed:

```markdown
**Prerequisites:**
- Stax Bill webhook configured to point to `/webhooks/staxbill`
- EntitlementsServiceAddress configured in appsettings
- Database migration applied in staging and validated
```

### Deploy Steps

Number the deployment steps in order:

```markdown
**Deploy:**
1. Deploy EntitlementsMicroservice with new endpoint
2. Deploy SubscriptionsMicroservice with webhook and sync service
3. Verify webhook signature validation works
4. Test with Stax Bill test webhook
5. Monitor production renewals for 1 hour
```

### Rollback Procedure

Describe how to undo the deployment:

```markdown
**Rollback:**
- Remove webhook endpoint registration in Stax Bill
- Redeploy previous SubscriptionsMicroservice version
- Previous behavior resumes (no schema changes in this epic)
- Max rollback time: 15 minutes
```

### Risk Assessment

Assign risk level with justification:

```markdown
**Risk:** Low - minimal changes, no schema migrations, additive feature

**Risk:** Medium - primary feature activation, schema migration required

**Risk:** High - event-driven architecture migration, dual-write complexity
```

## Success Metrics Guidelines

### Metric Types

**Availability Metrics**:

- Webhook success rate: >99% within 1 minute
- API error rate: <0.1%
- Reconciliation job uptime: >99.9%

**Performance Metrics**:

- Sync latency: <5 seconds p95
- Drift detection processing: <30 seconds per subscription
- Event publish latency: <1 second p99

**Business Metrics**:

- Zero lockout incidents after renewals
- Support ticket reduction: >80% within 30 days
- User satisfaction: No billing-related complaints

**Operational Metrics**:

- All new renewals have `TermEnd`, `StaxbillStatus` populated
- Drift detection rate <1% (most webhooks work)
- Zero data loss during migration

### Metric Format

```markdown
- [Metric name]: [Comparison operator] [Target value] [Optional: time window or percentile]

Examples:
- Webhook success rate: >99% within 1 minute
- Sync latency: <5 seconds p95
- Zero lockout incidents
- All subscriptions have `LastSyncedAt` populated
```

## Release Plan Section

After all epics, include a release plan section:

```markdown
## Release Plan

### Emergency Fix
- Deploy Epic 1 immediately
- Solve the lockout problem
- Monitor for 1 week

### Add Resilience
- Deploy Epic 2 (schema and grace period)
- Backfill existing data

### Safety Net
- Deploy Epic 3 (reconciliation)
- System is now self-healing

### Future Enhancements
- Epics 4-6 as priority and capacity allows
- Non-critical, additive features
- Aligns with architecture design vision
```

**Purpose**: Communicate deployment sequencing and dependencies

## Estimate Summary Section

Include a summary table matching estimate.csv exactly:

```markdown
## Estimate Summary

| Epic | Description               | Hours   |
|------|---------------------------|---------|
| 1    | Renewal Fix               | 34      |
| 2    | Schema Enhancement        | 8       |
| 3    | Reconciliation Safety Net | 24      |
| 4    | Invoice Projection        | 12      |
| 5    | Event-Driven Migration    | 18      |
| 6    | Full Entitlements         | 20      |
| 0    | Cross Cutting Concerns    | 22      |
|      | **TOTAL**                 | **138** |

Total estimate: 138 hours (~17 working days for one developer)
```

**Validation**: Hours must exactly match estimate.csv (source of truth)

## Appendix Section (Optional)

For complex patterns that need additional explanation:

```markdown
## Appendix

### Grace Period Logic Explained

The Problem Without Grace Period:
- User's credit card expires on renewal day (Day 30)
- Charge fails → Subscription status = `past_due`
- Link checks: `expiresAt < now` → User locked out immediately
- User can't access app to update payment method

The Solution With Grace Period:
- Charge fails → Subscription status = `past_due`
- Link calculates: `gracePeriodEndsAt = termEnd + 7 days = Day 37`
- `IsEntitled` checks: `(termEnd >= now) OR (status == "past_due" AND gracePeriodEndsAt >= now)`
- User keeps access until Day 37
```

**When to use appendix**:

- Complex algorithms (reconciliation, grace period calculation)
- Design decisions that need justification (why webhooks as triggers, not truth)
- Patterns that span multiple stories (idempotency, event sourcing)

## Markdown Linting Requirements

All delivery plans must comply with the markdown standards defined in [markdown-standards.md](../markdown-standards.md).

### Delivery Plan-Specific Rules

In addition to the common rules, delivery plans should pay attention to:

- **MD024 (Duplicate Headings)**: Prefix repeated section names with epic context (e.g., `#### Epic 1 Deployment` instead of `#### Deployment`)
- **MD036 (No Emphasis as Heading)**: Use proper heading syntax for epic/feature/story titles, not bold text

### Quick Validation

```bash
markdownlint delivery-plan.md
```

See [markdown-standards.md](../markdown-standards.md) for complete linting rules, IDE setup, and enforcement policies.

## Alignment Verification Checklist

Before finalizing a delivery plan:

### Structure Alignment

- [ ] Epic structure matches estimate.csv (same epic numbers, names)
- [ ] Feature structure matches estimate.csv (same feature numbers, names)
- [ ] Story structure matches estimate.csv (same story numbers, names)
- [ ] Epic 0 (Cross Cutting Concerns) is included

### Content Alignment

- [ ] Estimate summary table totals match estimate.csv exactly
- [ ] All architecture principles from blueprint are referenced
- [ ] Code examples align with event contracts in blueprint
- [ ] Deployment sections include rollback procedures

### Markdown Quality

- [ ] **Linting passes**: Run `markdownlint delivery-plan.md` with zero errors
- [ ] No markdown linting errors (MD036, MD030, MD007, MD024, MD031/MD032)
- [ ] Nested code blocks use proper fence lengths (4+ backticks for outer)
- [ ] No hours in headings (e.g., no "(12 hours)" or "(3h)")
- [ ] All stories have Gherkin-style acceptance criteria
- [ ] All epics have deployment and success metrics sections

### Links and References

- [ ] Task URLs are valid and accessible
- [ ] Blueprint document link is correct
- [ ] Estimate CSV link is correct
- [ ] All code examples reference actual project structure

## Common Pitfalls

### ❌ Avoid These Mistakes

1. **Estimate mismatch**: Delivery plan shows 88 hours, CSV shows 138 hours
   - **Fix**: Estimate CSV is source of truth, delivery plan must match

2. **Missing epic deployment sections**: Epic has features/stories but no deployment plan
   - **Fix**: Every epic needs deployment, rollback, and success metrics

3. **Vague acceptance criteria**: "Make it work" instead of Gherkin GIVEN/WHEN/THEN
   - **Fix**: Use Gherkin format for all stories

4. **Duplicate heading names**: Multiple "Deployment" headings across epics
   - **Fix**: Prefix with epic number: "Epic 1 Deployment", "Epic 2 Deployment"

5. **Hours in headings**: "Epic 1: Renewal Fix (34 hours)"
   - **Fix**: Remove hours from headings, keep them only in estimate table

6. **Architecture divergence**: Delivery plan uses different patterns than blueprint
   - **Fix**: Cross-reference blueprint for principles, event contracts, component boundaries

7. **Missing rollback**: Deployment section has no rollback procedure
   - **Fix**: Every deployment must have a rollback plan (even if it's "redeploy previous version")

8. **Code examples for trivial patterns**: Standard CRUD operations shown in detail
   - **Fix**: Only include code for non-obvious patterns

## Maintenance and Updates

### When to Update the Delivery Plan

**Triggers for updates**:

- Estimate hours change in CSV (story hours adjusted)
- New stories discovered during development (add to appropriate feature/epic)
- Architecture blueprint updated (new patterns, event contracts)
- Deployment strategy changes (phased → emergency)
- Acceptance criteria refined (after story kickoff discussions)

### Update Process

1. **Identify trigger**: What changed and why?
2. **Update affected sections**: Stories, epics, deployment, metrics
3. **Verify alignment**: Cross-check estimate.csv, blueprint
4. **Run markdown linting**: Fix all linting errors (zero tolerance)
5. **Update estimate summary table**: Ensure totals match CSV
6. **Verify linting passes**: Re-run linter to confirm all fixes
7. **Commit with clear message**: Describe what changed and why

### Version Control Best Practices

- Commit delivery plan and estimate CSV together when hours change
- Use descriptive commit messages: "Add Epic 4 stories for invoice projection"
- Tag stable versions: `git tag v1.0-delivery-plan` before development starts
- Create pull requests for major changes (epic additions, scope reductions)

## Template Usage

When creating a new delivery plan:

1. **Start with structure** from this guide (Header → Problem → Implementation Plan → Release Plan → Estimate Summary)
2. **Reference blueprint** for architecture principles, event contracts, components
3. **Create estimate CSV first** (source of truth for hours and structure)
4. **Write delivery plan second** (expands CSV with acceptance criteria and code examples)
5. **Validate alignment** using checklist in this guide
6. **Run markdown linting** and fix all errors before committing
7. **Verify linting passes** with zero errors (mandatory gate)

## Examples by Initiative Type

### Emergency Fix Initiative

- **Structure**: Minimal - Epic 1 (fix), Epic 0 (testing/rollback)
- **Detail Level**: High for Epic 1 (detailed acceptance criteria, code examples)
- **Code Examples**: Include (non-standard patterns likely)
- **Appendix**: Skip (focus on execution)

### Greenfield Architecture Initiative

- **Structure**: Complete - Epics 0-N covering all layers
- **Detail Level**: High for all epics (new patterns need clarity)
- **Code Examples**: Include extensively (establishing patterns)
- **Appendix**: Include (explain design decisions)

### Incremental Enhancement

- **Structure**: Moderate - 2-3 epics
- **Detail Level**: Medium (reference existing patterns)
- **Code Examples**: Include selectively (new patterns only)
- **Appendix**: Optional (only if complex algorithms involved)

## Summary

A well-crafted delivery plan:

- **Aligns** with architecture blueprint (principles, patterns, contracts)
- **Drives** from estimate.csv (hours, epic/feature/story structure)
- **Guides** development with clear acceptance criteria and code examples
- **Enables** deployment with rollback procedures and success metrics
- **Evolves** with the initiative (updated when requirements or design changes)

Use this guide as a checklist when creating or reviewing delivery plans for any initiative.
