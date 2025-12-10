# Testing Plan Guide

## Purpose

A testing plan is a living document that defines how changes will be validated at each level of the testing pyramid - from unit tests in isolation to end-to-end tests that verify the complete user journey. The testing plan ensures adequate coverage, documents test data requirements, and provides a checklist for pre-release verification.

**Note**: This is different from a [Test Plan](test-plan-guide.md), which maps acceptance criteria to test types at design time. A Testing Plan tracks actual test implementation and verification status.

## When to Create a Testing Plan

Create a testing plan when:

- **Multiple integration points**: Changes touch APIs, databases, and external services
- **Business-critical functionality**: Changes affect user access, billing, or data integrity
- **Complex data flows**: Data moves through multiple services or transformations
- **New feature rollout**: Feature requires verification across multiple environments
- **Regression risk**: Changes could affect existing functionality

Skip for:

- Trivial bug fixes with existing test coverage
- Documentation-only changes
- Test-only changes (the tests are the plan)
- Refactoring with no behavior changes (existing tests suffice)

## Testing Pyramid

```text
                    /\
                   /  \
                  / E2E \        (Few, slow, high confidence)
                 /______\
                /        \
               /Integration\    (Some, medium speed)
              /______________\
             /                \
            /    Unit Tests    \  (Many, fast, isolated)
           /____________________\
```

### Level Definitions

| Level | Scope | Dependencies | Speed | Confidence |
|-------|-------|--------------|-------|------------|
| Unit | Single class/method | All mocked | Fast (<1s) | Logic correctness |
| Integration | Service + real DB | Real DB, mocked external | Medium (1-10s) | Data layer |
| E2E | Full system | All real | Slow (10s-minutes) | User flows |

## Core Structure

### Header and Metadata

```markdown
# [Initiative Name] Testing Plan

**Work Item**: [TW-XXXXX or WI-xxx]
**Delivery Plan**: [Relative path to delivery-plan.md]
**Repository**: [Repository name]

## Test Coverage Summary

| Level | Tests | Passing | Coverage |
|-------|-------|---------|----------|
| Unit | 57 | 57 | 85% |
| Integration | 12 | 12 | N/A |
| E2E | 5 | 5 | N/A |
```

### Unit Testing Section

```markdown
## Unit Tests

### Purpose

Verify individual components work correctly in isolation with all dependencies mocked.

### Test Classes

| Class | File | Tests | Status |
|-------|------|-------|--------|
| ServiceTests | Tests/ServiceTests.cs | 8 | Passing |
| EntityTests | Tests/EntityTests.cs | 7 | Passing |

### Test Cases

#### [Feature Name] Tests

| Test | Description | Status |
|------|-------------|--------|
| `MethodName_Scenario_ExpectedResult` | Brief description | Pass/Fail |

### Mocking Strategy

- External APIs: Mocked to avoid network calls
- Database: In-memory or mocked repository
- Time: Mocked for deterministic tests
```

### Integration Testing Section

```markdown
## Integration Tests

### Purpose

Verify components work together with real databases but mocked external services.

### Environment Requirements

| Dependency | Type | Configuration |
|------------|------|---------------|
| SQL Server | Real | LocalDB or Docker |
| Redis | Real/Mock | Docker or in-memory |
| External API | Mock | WireMock or test server |

### Test Scenarios

#### Database Integration

| Scenario | Description | Verification |
|----------|-------------|--------------|
| CRUD operations | Create, read, update, delete | Data persisted correctly |
| Migration verification | Schema changes apply | No data loss |
| Concurrent access | Multiple writers | No deadlocks |

### Test Data Management

[Describe how test data is seeded and cleaned up]
```

### End-to-End Testing Section

```markdown
## End-to-End Tests

### Purpose

Verify complete user journeys from UI through all services to database and back.

### Test Environment

| Component | Environment | URL |
|-----------|-------------|-----|
| UI | Staging | https://staging.example.com |
| API | Staging | https://api-staging.example.com |
| Database | Staging | (connection string in secrets) |

### User Journeys

#### Journey 1: [Name]

**Preconditions:**

- User exists with specific state
- Data seeded in specific way

**Steps:**

1. Navigate to [page]
2. Perform [action]
3. Verify [result]

**Verification:**

- UI shows expected state
- API returns expected response
- Database contains expected records

### Manual Testing Checklist

- [ ] Happy path works
- [ ] Error states display correctly
- [ ] Edge cases handled
- [ ] Performance acceptable
```

### Test Data Section

```markdown
## Test Data

### Seed Data Requirements

| Entity | Count | State | Purpose |
|--------|-------|-------|---------|
| User | 5 | Various | Test different user states |
| Subscription | 10 | Active, Expired, Trial | Test subscription logic |

### Test Data Scripts

| Script | Purpose | Location |
|--------|---------|----------|
| seed-test-users.sql | Create test users | /scripts/seed-test-users.sql |

### Data Cleanup

[Describe how test data is cleaned up between runs]
```

### External Service Testing

```markdown
## External Service Testing

### Mock Services

| Service | Mock Type | Configuration |
|---------|-----------|---------------|
| External API | WireMock | /mocks/service/ |
| Email Service | In-memory | N/A |

### Sandbox Environments

| Service | Sandbox URL | Credentials |
|---------|-------------|-------------|
| Payment Provider | https://sandbox.example.com | In Key Vault |

### Contract Testing

[Describe how API contracts are verified]
```

### Regression Testing

```markdown
## Regression Testing

### Critical Paths to Verify

| Path | Description | Test Type |
|------|-------------|-----------|
| User login | Authentication flow | E2E |
| Data sync | Synchronization verification | Integration |

### Automated Regression Suite

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Smoke tests pass in staging
- [ ] Performance benchmarks within threshold
```

### Pre-Release Checklist

```markdown
## Pre-Release Testing Checklist

### Development Environment

- [ ] All unit tests passing locally
- [ ] Code coverage meets threshold (80%+)
- [ ] Integration tests pass with local database
- [ ] Manual testing of new features complete

### Staging Environment

- [ ] Deployment successful
- [ ] Smoke tests pass
- [ ] E2E test suite passes
- [ ] Performance tests within SLA
- [ ] External service integration verified

### Production Verification

- [ ] Health checks pass
- [ ] Key metrics normal
- [ ] No new errors in logs
- [ ] Sample transactions successful
```

## Living Document Practices

### When to Update

Update the testing plan when:

1. **New test added**: Add to test case tables
2. **Test environment changes**: Update environment section
3. **New external service**: Add to mock/sandbox section
4. **Coverage changes**: Update summary metrics
5. **Pre-release**: Complete checklists

### Update Workflow

```text
Story Started
  -> Review required test coverage
  -> Add planned tests to tables (Status: Planned)

Tests Written
  -> Update status to Implemented
  -> Update coverage metrics

Tests Passing
  -> Update status to Passing
  -> Update test counts

Pre-Release
  -> Complete all checklists
  -> Document any skipped tests with reason
```

## Test Naming Conventions

### Unit Test Names

```text
MethodName_Scenario_ExpectedResult
```

Examples:

- `SyncAsync_ValidId_ReturnsSuccess`
- `SyncAsync_NotFound_ReturnsFailure`
- `IsEntitled_PastDueWithGracePeriod_ReturnsTrue`

### Integration Test Names

```text
[Component]_[Operation]_[Verification]
```

Examples:

- `Repository_SaveEntity_PersistsToDatabase`
- `ApiClient_GetResource_ReturnsDeserializedData`

### E2E Test Names

```text
[UserJourney]_[Scenario]
```

Examples:

- `SubscriptionRenewal_UserRemainsEntitled`
- `PaymentFailed_GracePeriodApplied`

## Anti-Patterns

**Avoid these common mistakes**:

1. **Testing implementation not behavior**: Test what the code does, not how
2. **Excessive mocking**: If everything is mocked, you're testing mocks
3. **Flaky tests**: Fix or delete tests that randomly fail
4. **Missing edge cases**: Test boundaries, nulls, and errors
5. **No cleanup**: Tests should leave environment clean
6. **Hard-coded data**: Use factories or builders for test data
7. **Skipping integration tests**: Unit tests alone miss integration bugs

## Template

A blank testing plan template is available at:
`/docs/templates/documents/testing-plan.md`

## Related Guides

- [Test Plan Guide](test-plan-guide.md) - Design-time acceptance criteria mapping
- [Release Plan Guide](release-plan-guide.md) - Deployment readiness and rollback
