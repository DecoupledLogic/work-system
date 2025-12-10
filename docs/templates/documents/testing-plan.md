# [Initiative Name] - Testing Plan

**Work Item**: [TW-XXXXX or WI-xxx]
**Delivery Plan**: [delivery-plan.md](delivery-plan.md)
**Repository**: [Repository Name](repository-url)

## Test Coverage Summary

| Level | Tests | Passing | Coverage |
|-------|-------|---------|----------|
| Unit | X | X | X% |
| Integration | X | X | N/A |
| E2E | X | X | N/A |

---

## Unit Tests

### Purpose

Verify individual components work correctly in isolation with all dependencies mocked.

### Test Classes

| Class | File | Tests | Status |
|-------|------|-------|--------|
| ExampleServiceTests | Tests/ExampleServiceTests.cs | X | Passing |

### Test Cases

#### [Feature Name] Tests

| Test | Description | Status |
|------|-------------|--------|
| `MethodName_Scenario_ExpectedResult` | Description | Pass/Fail/Planned |

### Mocking Strategy

| Dependency | Mock Type | Reason |
|------------|-----------|--------|
| IExternalService | Moq | Avoid network calls |
| IRepository | Moq | Avoid database |

### Running Unit Tests

```bash
dotnet test
dotnet test --filter "FullyQualifiedName~ClassName"
```

---

## Integration Tests

### Purpose

Verify components work together with real databases but mocked external services.

### Environment Requirements

| Dependency | Type | Configuration |
|------------|------|---------------|
| SQL Server | Real | LocalDB or Docker |
| External API | Mock | Test mode or WireMock |

### Test Scenarios

| Scenario | Description | Verification |
|----------|-------------|--------------|
| Database CRUD | Create, read, update, delete | Data persisted |
| Migration | Schema changes apply | No errors |

### Running Integration Tests

```bash
dotnet test --filter "Category=Integration"
```

---

## End-to-End Tests

### Purpose

Verify complete user journeys from UI through all services to database.

### Test Environment

| Component | Environment | URL |
|-----------|-------------|-----|
| UI | Staging | https://staging.example.com |
| API | Staging | https://api-staging.example.com |
| Database | Staging | Connection in secrets |

### User Journeys

#### Journey 1: [Name]

**Preconditions:**

- [Required state]

**Steps:**

1. [Action]
2. [Action]
3. [Verification]

**Verification:**

| Checkpoint | Expected | Actual |
|------------|----------|--------|
| Step 1 | Result | |

### Manual Testing Checklist

- [ ] Happy path works
- [ ] Error states handled
- [ ] Edge cases tested

---

## Test Data

### Seed Data Requirements

| Entity | Count | States | Purpose |
|--------|-------|--------|---------|
| User | X | Various | Test scenarios |

### Test Accounts

| User | State | ID |
|------|-------|-----|
| test-user@example.com | Active | 12345 |

### Data Cleanup

```sql
-- Reset test data
DELETE FROM TableName WHERE Id IN (test IDs);
```

---

## External Service Testing

### Mock Services

| Service | Mock Type | Configuration |
|---------|-----------|---------------|
| External API | WireMock | /mocks/service/ |

### Sandbox Environments

| Service | URL | Notes |
|---------|-----|-------|
| External API | https://sandbox.example.com | Test credentials |

---

## Regression Testing

### Critical Paths

| Path | Description | Test Type |
|------|-------------|-----------|
| Core function | Description | Unit/Integration/E2E |

### Automated Suite

```bash
# Run full regression
dotnet test
```

---

## Pre-Release Testing Checklist

### Development

- [ ] Unit tests passing
- [ ] Coverage > 80%
- [ ] Integration tests passing
- [ ] Manual testing complete

### Staging

- [ ] Deployment successful
- [ ] Smoke tests pass
- [ ] E2E tests pass
- [ ] Performance acceptable

### Production (Post-Deploy)

- [ ] Health checks pass
- [ ] No new errors
- [ ] Key flows working

---

## Change Log

| Date | Author | Change |
|------|--------|--------|
| YYYY-MM-DD | username | Initial testing plan |
