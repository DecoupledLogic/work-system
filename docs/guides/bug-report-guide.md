# Bug Report Guide

## Purpose

A bug report documents a defect, its symptoms, root cause analysis, and proposed fix approach. It serves as the planning document for bug fixes, providing the same structure as a PRD but focused on correcting behavior rather than adding features.

## When to Create a Bug Report

Create a bug report when:

- **Production incident**: Users experiencing broken functionality
- **Regression**: Previously working feature now fails
- **Data integrity issue**: Incorrect data being stored or displayed
- **Performance degradation**: System slower than acceptable thresholds
- **Security vulnerability**: Exploitable weakness discovered

Use simpler artifacts for:

- Cosmetic issues (typos, minor UI tweaks)
- Single-line fixes with obvious cause
- Issues already documented in error tracking systems

## Relationship to Other Artifacts

### Bug Report Position in Workflow

```text
Bug Identified (Symptom reported)
  ↓ (investigation)
Bug Report (Root cause documented) ← You are here
  ↓ (informs)
Implementation Plan (Fix tasks)
  ↓ (produces)
Release Notes (Fix documented)
```

### What Flows from Bug Report

**To Implementation**:

- **Root cause** → Where to fix
- **Fix approach** → How to fix
- **Test plan** → How to verify fix

**To Release Notes**:

- **Symptoms** → What was broken
- **Fix approach** → What was fixed

## Core Structure

### 1. Header and Metadata

```markdown
# Bug Report: [Title]

**Work Item**: [TW-12345 or WI-xxx]
**Severity**: [Critical | High | Medium | Low]
**Status**: [Investigating | Root Cause Identified | Fix In Progress | Resolved]
**Reported**: [Date]
**Environment**: [Production | Staging | Development]
```

### 2. Symptoms

```markdown
## Symptoms

[Observable behavior that indicates the bug. What users see or experience.]

- [Symptom 1]
- [Symptom 2]
```

**Example**:

```markdown
## Symptoms

- Users report being locked out of the app after their subscription renews
- Dashboard shows "Subscription expired" despite successful payment
- Support tickets spike on the 1st of each month (billing date)
```

### 3. Steps to Reproduce

```markdown
## Steps to Reproduce

[Exact steps to trigger the bug. Should be repeatable.]

1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected**: [What should happen]
**Actual**: [What actually happens]
```

**Example**:

```markdown
## Steps to Reproduce

1. Create a subscription with billing date on the 1st
2. Wait for automatic renewal (or simulate in staging)
3. Log into the app after renewal processes

**Expected**: User sees active subscription, can access all features
**Actual**: User sees "Subscription expired" banner, features locked
```

### 4. Impact

```markdown
## Impact

[Business and user impact of this bug]

- **Users affected**: [Number or percentage]
- **Functionality affected**: [What doesn't work]
- **Business impact**: [Revenue, reputation, etc.]
```

**Example**:

```markdown
## Impact

- **Users affected**: ~500 users per month (all renewals)
- **Functionality affected**: All premium features locked
- **Business impact**: Support tickets, churn risk, refund requests
```

### 5. Root Cause

```markdown
## Root Cause

[Technical explanation of why the bug occurs. Include relevant code paths,
data flows, or system interactions.]
```

**Example**:

```markdown
## Root Cause

The subscription sync service only listens for `subscription.created` webhooks from Stax Bill. When a subscription renews, Stax Bill does NOT emit `subscription.created` - it emits `invoice.paid` instead.

Our system never receives a signal that the subscription renewed, so the local `TermEnd` date is never updated. When `TermEnd` passes, the entitlement check fails.

Relevant code:

- `SubscriptionWebhookHandler.cs` - only handles `subscription.created`
- `EntitlementService.IsEntitled()` - checks `TermEnd >= DateTime.UtcNow`
```

### 6. Fix Approach

```markdown
## Fix Approach

[Proposed solution at a high level. Include alternatives considered if relevant.]

### Recommended Fix

[Description of the fix]

### Alternatives Considered

- **[Alternative 1]**: [Why not chosen]
- **[Alternative 2]**: [Why not chosen]
```

**Example**:

```markdown
## Fix Approach

### Recommended Fix

1. Add webhook handler for `invoice.paid` events
2. When `invoice.paid` received, fetch subscription details from Stax Bill API
3. Update local `TermEnd` to new billing period end date
4. Add reconciliation job as safety net for missed webhooks

### Alternatives Considered

- **Poll Stax Bill API daily**: Rejected - adds latency, users locked out for up to 24 hours
- **Extend grace period**: Rejected - treats symptom not cause, still shows wrong date
```

### 7. Test Plan

```markdown
## Test Plan

[How to verify the fix works and doesn't introduce regressions]

### Verification

- [Test case 1]
- [Test case 2]

### Regression Testing

- [Regression check 1]
- [Regression check 2]
```

**Example**:

```markdown
## Test Plan

### Verification

- Trigger renewal in Stax Bill staging environment
- Verify `invoice.paid` webhook received and processed
- Verify local `TermEnd` updated correctly
- Verify user can access premium features after renewal

### Regression Testing

- Verify new subscription flow still works (subscription.created)
- Verify cancellation flow unaffected
- Verify manual extension flow unaffected
- Load test webhook handler with 100 concurrent events
```

### 8. Acceptance Criteria

```markdown
## Acceptance Criteria

[Gherkin-format criteria for when the fix is complete]

- GIVEN [precondition]
  WHEN [action]
  THEN [expected outcome]
```

**Example**:

```markdown
## Acceptance Criteria

- GIVEN a user with an active subscription approaching renewal
  WHEN Stax Bill processes the renewal payment
  THEN our system receives the invoice.paid webhook within 30 seconds

- GIVEN our system receives an invoice.paid webhook
  WHEN the invoice is for a subscription renewal
  THEN the local TermEnd is updated to the new period end date

- GIVEN a user whose subscription just renewed
  WHEN they log into the app
  THEN they see "Active" subscription status and can access all features
```

### 9. Timeline (Optional)

```markdown
## Timeline

[Important dates related to this bug]

- **Reported**: [Date]
- **Root cause identified**: [Date]
- **Fix deployed**: [Date or target]
- **Verified in production**: [Date or target]
```

## Template

When creating a new bug report, use this template:

```markdown
# Bug Report: [Title]

**Work Item**: [ID]
**Severity**: [Critical | High | Medium | Low]
**Status**: Investigating
**Reported**: [Date]
**Environment**: [Environment]

## Symptoms

- [Symptom 1]
- [Symptom 2]

## Steps to Reproduce

1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected**: [Expected behavior]
**Actual**: [Actual behavior]

## Impact

- **Users affected**: [Number]
- **Functionality affected**: [What's broken]
- **Business impact**: [Impact]

## Root Cause

[Technical explanation of why the bug occurs]

## Fix Approach

### Recommended Fix

[Description of the fix]

### Alternatives Considered

- **[Alternative]**: [Why not chosen]

## Test Plan

### Verification

- [Test case]

### Regression Testing

- [Regression check]

## Acceptance Criteria

- GIVEN [precondition]
  WHEN [action]
  THEN [expected outcome]
```

## Severity Guidelines

### Critical

- System unusable for all/most users
- Data loss or corruption occurring
- Security breach in progress
- Revenue impact immediate and significant

**Response**: Drop everything, fix immediately

### High

- Major feature broken for significant users
- Workaround exists but painful
- Data integrity at risk
- Significant user complaints

**Response**: Fix in current sprint, prioritize over features

### Medium

- Feature partially broken
- Workaround exists and acceptable
- Limited user impact
- Cosmetic issues affecting professionalism

**Response**: Fix in next sprint or two

### Low

- Minor inconvenience
- Edge case only
- No workaround needed
- Nice to fix when convenient

**Response**: Add to backlog, fix when capacity allows

## Common Pitfalls

### Avoid These Mistakes

1. **Vague symptoms**: "App is broken"
   - **Fix**: Describe specific observable behavior

2. **Missing reproduction steps**: "Sometimes users get locked out"
   - **Fix**: Document exact steps to reliably reproduce

3. **Guessing root cause**: Proposing fix without understanding why
   - **Fix**: Investigate thoroughly before proposing solution

4. **Incomplete test plan**: "Test that it works"
   - **Fix**: Include specific test cases and regression checks

5. **Missing impact assessment**: No urgency context
   - **Fix**: Quantify users affected and business impact

6. **Fix without acceptance criteria**: No definition of done
   - **Fix**: Include Gherkin-format criteria for verification

## Maintenance

Bug reports are generally static once resolved. Update to track:

- Status changes (Investigating → Root Cause Identified → Resolved)
- Timeline updates (deployment dates)
- Post-mortem findings if incident review conducted

## Markdown Linting Requirements

All bug reports must comply with the markdown standards defined in [markdown-standards.md](../markdown-standards.md).

### Quick Validation

```bash
markdownlint bug-report.md
```

## Summary

A well-crafted bug report:

- **Describes** observable symptoms clearly
- **Provides** reliable reproduction steps
- **Quantifies** user and business impact
- **Identifies** root cause with evidence
- **Proposes** fix approach with alternatives
- **Defines** test plan for verification
- **Specifies** acceptance criteria for completion

Use this guide when documenting bugs that require investigation and planning.
