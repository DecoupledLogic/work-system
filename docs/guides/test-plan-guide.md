# Test Plan Guide

## Purpose

A test plan defines the testing strategy for a work item, mapping acceptance criteria to specific test types and expected outcomes. It ensures adequate coverage and provides a checklist for verifying that implementation meets requirements.

## When to Create a Test Plan

Create a test plan when:

- **Feature implementation**: New functionality with multiple acceptance criteria
- **Critical path changes**: Modifications to core business logic
- **Integration work**: Connecting with external systems or services
- **Complex logic**: Business rules with multiple branches and edge cases
- **Compliance requirements**: Features requiring documented test evidence

Use simpler artifacts for:

- Simple bug fixes with obvious verification
- Trivial changes (typos, style updates)
- Spikes and research tasks

## Relationship to Other Artifacts

### Test Plan Position in Workflow

```text
Design Stage (Requirements understood)
  ↓ (test strategy defined)
Test Plan (Coverage documented) ← You are here
  ↓ (guides)
Implementation (Tests written)
  ↓ (verifies)
Delivery (Tests pass)
```

### What Flows from Test Plan

**To Implementation**:

- **Test cases** → Actual test code
- **Coverage matrix** → Test priorities
- **Expected outcomes** → Assertions

**To QA**:

- **Manual test cases** → QA verification steps
- **Edge cases** → Exploratory testing focus

## Core Structure

### 1. Header and Metadata

```markdown
# Test Plan: [Work Item Name]

**Work Item**: [TW-12345 or WI-xxx]
**Feature/Story**: [Name]
**Created**: [Date]
**Test Approach**: [TDD | Test-After | Hybrid]
```

### 2. Test Strategy Overview

```markdown
## Test Strategy

[Brief description of overall testing approach]

### Coverage Goals

- **Unit tests**: [Target coverage %]
- **Integration tests**: [Scope]
- **E2E tests**: [Critical paths]
```

**Example**:

```markdown
## Test Strategy

Focus on contract testing for webhook integration and unit tests for business logic. E2E tests for the critical renewal flow only.

### Coverage Goals

- **Unit tests**: 90% coverage for SubscriptionService
- **Integration tests**: All webhook handlers, API clients
- **E2E tests**: Renewal flow, grace period flow
```

### 3. Coverage Matrix

```markdown
## Coverage Matrix

| Acceptance Criterion | Unit | Integration | E2E | Manual |
|---------------------|------|-------------|-----|--------|
| [Criterion 1] | [x] | [x] | [ ] | [ ] |
| [Criterion 2] | [x] | [ ] | [x] | [ ] |
```

**Example**:

```markdown
## Coverage Matrix

| Acceptance Criterion | Unit | Integration | E2E | Manual |
|---------------------|------|-------------|-----|--------|
| Invoice.paid webhook updates TermEnd | x | x | | |
| Grace period calculated correctly | x | | | |
| User sees active status after renewal | | | x | |
| Failed payment triggers dunning state | x | x | | |
| Reconciliation job detects drift | x | x | | x |
```

### 4. Test Cases by Type

```markdown
## Unit Tests

### [Component/Class Name]

#### [Test Case Name]

- **Given**: [Setup/precondition]
- **When**: [Action]
- **Then**: [Assertion]

### Integration Tests

### [Integration Point Name]

#### [Test Case Name]

- **Given**: [Setup/precondition]
- **When**: [Action]
- **Then**: [Assertion]

## E2E Tests

### [Flow Name]

#### [Test Case Name]

- **Given**: [Setup/precondition]
- **When**: [Action]
- **Then**: [Assertion]
```

**Example**:

```markdown
## Unit Tests

### SubscriptionService

#### UpdateTermFromInvoice_ValidPaidInvoice_UpdatesTermEnd

- **Given**: Subscription with TermEnd = 2024-01-01
- **When**: UpdateTermFromInvoice called with paid invoice for 2024-02-01 period
- **Then**: TermEnd updated to 2024-02-01

#### UpdateTermFromInvoice_UnpaidInvoice_NoChange

- **Given**: Subscription with TermEnd = 2024-01-01
- **When**: UpdateTermFromInvoice called with unpaid invoice
- **Then**: TermEnd remains 2024-01-01

### GracePeriodCalculator

#### Calculate_PastDueSubscription_Returns7Days

- **Given**: Subscription with status = past_due, TermEnd = 2024-01-01
- **When**: Calculate(subscription) called
- **Then**: Returns 2024-01-08 (TermEnd + 7 days)

## Integration Tests

### StaxBillWebhookHandler

#### HandleInvoicePaid_ValidSignature_ProcessesEvent

- **Given**: Valid webhook payload with correct signature
- **When**: POST /webhooks/staxbill with invoice.paid event
- **Then**: Returns 200 OK, subscription updated in database

#### HandleInvoicePaid_InvalidSignature_Rejects

- **Given**: Webhook payload with incorrect signature
- **When**: POST /webhooks/staxbill
- **Then**: Returns 401 Unauthorized, no database changes

### StaxBillApiClient

#### GetSubscription_ValidId_ReturnsSubscription

- **Given**: Stax Bill API stub configured with subscription data
- **When**: GetSubscription("sub-123") called
- **Then**: Returns SubscriptionDto with expected fields

## E2E Tests

### Renewal Flow

#### SuccessfulRenewal_UserStaysActive

- **Given**: User with subscription ending today
- **When**: Stax Bill processes renewal, sends webhook
- **Then**: User logs in and sees "Active" status, can access premium features
```

### 5. Edge Cases and Error Scenarios

```markdown
## Edge Cases

### [Category]

| Scenario | Expected Behavior | Test Type |
|----------|-------------------|-----------|
| [Edge case 1] | [Expected] | [Unit/Integration] |
| [Edge case 2] | [Expected] | [Unit/Integration] |
```

**Example**:

```markdown
## Edge Cases

### Webhook Processing

| Scenario | Expected Behavior | Test Type |
|----------|-------------------|-----------|
| Duplicate webhook (same eventId) | Idempotent - process once | Integration |
| Webhook for unknown subscription | Log warning, return 200 | Integration |
| Stax Bill API timeout during enrichment | Retry 3x, then queue for reconciliation | Integration |
| Invoice with zero amount (free trial) | Skip term update, log info | Unit |

### Grace Period

| Scenario | Expected Behavior | Test Type |
|----------|-------------------|-----------|
| Grace period already expired | Return false for IsEntitled | Unit |
| Exactly at grace period boundary | Return true (inclusive) | Unit |
| Subscription reinstated during grace | Clear grace period, restore normal | Unit |
```

### 6. Test Data Requirements

```markdown
## Test Data

### Fixtures Required

- [Fixture 1]: [Description]
- [Fixture 2]: [Description]

### Mocks/Stubs Required

- [Mock 1]: [Description]
- [Mock 2]: [Description]
```

**Example**:

```markdown
## Test Data

### Fixtures Required

- `active-subscription.json`: Subscription in active state, term ending in 30 days
- `past-due-subscription.json`: Subscription in past_due state, term ended yesterday
- `paid-invoice.json`: Invoice with status=paid, matching subscription

### Mocks/Stubs Required

- `StaxBillApiStub`: Mock Stax Bill API responses for subscription and invoice endpoints
- `WebhookSignatureValidator`: Stub to control signature validation in tests
- `DateTimeProvider`: Mockable clock for testing time-dependent logic
```

### 7. Manual Test Cases (Optional)

```markdown
## Manual Tests

### [Test Name]

**Prerequisites**: [Setup required]

**Steps**:

1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Result**: [What should happen]
```

**Example**:

```markdown
## Manual Tests

### Verify Reconciliation Job UI

**Prerequisites**: Access to admin dashboard, staging environment

**Steps**:

1. Navigate to Admin > Reconciliation Jobs
2. Trigger manual reconciliation run
3. Observe job progress indicator
4. Wait for completion

**Expected Result**: Job shows success status, last run timestamp updated, drift count displayed if any found
```

## Template

When creating a new test plan, use this template:

```markdown
# Test Plan: [Work Item Name]

**Work Item**: [ID]
**Feature/Story**: [Name]
**Created**: [Date]
**Test Approach**: TDD

## Test Strategy

[Brief description of approach]

### Coverage Goals

- **Unit tests**: [Target %]
- **Integration tests**: [Scope]
- **E2E tests**: [Critical paths]

## Coverage Matrix

| Acceptance Criterion | Unit | Integration | E2E | Manual |
|---------------------|------|-------------|-----|--------|
| [Criterion] | [ ] | [ ] | [ ] | [ ] |

## Unit Tests

### [Component]

#### [Test Case]

- **Given**: [Setup]
- **When**: [Action]
- **Then**: [Assertion]

## Integration Tests

### [Integration Point]

#### [Test Case]

- **Given**: [Setup]
- **When**: [Action]
- **Then**: [Assertion]

## E2E Tests

### [Flow]

#### [Test Case]

- **Given**: [Setup]
- **When**: [Action]
- **Then**: [Assertion]

## Edge Cases

| Scenario | Expected Behavior | Test Type |
|----------|-------------------|-----------|
| [Edge case] | [Expected] | [Type] |

## Test Data

### Fixtures Required

- [Fixture]: [Description]

### Mocks/Stubs Required

- [Mock]: [Description]
```

## Test Naming Conventions

### Unit Test Names

Format: `[Method]_[Scenario]_[ExpectedResult]`

Examples:

- `Calculate_ValidInput_ReturnsExpectedValue`
- `Process_NullInput_ThrowsArgumentException`
- `IsEntitled_ExpiredSubscription_ReturnsFalse`

### Integration Test Names

Format: `[Operation]_[Condition]_[ExpectedBehavior]`

Examples:

- `HandleWebhook_ValidSignature_ProcessesEvent`
- `FetchSubscription_ApiTimeout_RetriesThreeTimes`
- `SaveSubscription_DuplicateId_UpdatesExisting`

### E2E Test Names

Format: `[Flow]_[Scenario]_[ExpectedOutcome]`

Examples:

- `RenewalFlow_SuccessfulPayment_UserStaysActive`
- `LoginFlow_ExpiredSession_RedirectsToLogin`
- `CheckoutFlow_InvalidCard_ShowsErrorMessage`

## Common Pitfalls

### Avoid These Mistakes

1. **Testing implementation, not behavior**: Coupling tests to internal structure
   - **Fix**: Test public interfaces and observable outcomes

2. **Missing edge cases**: Only testing happy path
   - **Fix**: Enumerate boundary conditions and error scenarios

3. **No coverage matrix**: Uncertain what's tested
   - **Fix**: Map every acceptance criterion to test types

4. **Over-mocking**: Mocking everything loses integration value
   - **Fix**: Use real implementations where practical

5. **Flaky tests**: Tests that sometimes fail
   - **Fix**: Avoid time-dependent logic, use proper test isolation

6. **Missing test data documentation**: Tests need magic data
   - **Fix**: Document fixtures and why they exist

## Maintenance

Update test plan when:

- Acceptance criteria change
- New edge cases discovered during implementation
- Test strategy refined based on findings
- Coverage goals adjusted

## Markdown Linting Requirements

All test plans must comply with the markdown standards defined in [markdown-standards.md](../markdown-standards.md).

### Quick Validation

```bash
markdownlint test-plan.md
```

## Summary

A well-crafted test plan:

- **Maps** acceptance criteria to test types
- **Defines** specific test cases with given/when/then
- **Identifies** edge cases and error scenarios
- **Documents** test data and mock requirements
- **Provides** clear naming conventions
- **Guides** implementation and verification

Use this guide when creating test plans for features and stories.
