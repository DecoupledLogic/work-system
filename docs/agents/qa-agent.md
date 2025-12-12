# QA Agent

Generate test cases from acceptance criteria, execute tests, and validate quality.

## Overview

| Property | Value |
|----------|-------|
| **Name** | qa-agent |
| **Model** | haiku |
| **Tools** | Read, Bash, Glob, Grep |
| **Stage** | Deliver |

## Purpose

The QA Agent validates implemented work against acceptance criteria and quality standards. It handles:

- Generating test cases from Gherkin acceptance criteria
- Executing automated tests
- Validating acceptance criteria are met
- Reviewing test coverage
- Reporting quality metrics

## Input

Expects an implemented WorkItem:

```json
{
  "workItem": {
    "id": "TW-26134586",
    "name": "Create JWT token service",
    "type": "task",
    "status": "implemented",
    "acceptanceCriteria": [
      "Token generation with configurable expiry",
      "Token validation returns decoded payload",
      "Unit tests cover all token operations"
    ]
  },
  "testPlan": {
    "unit": { "framework": "jest", "location": "src/__tests__/" },
    "integration": { "framework": "supertest", "location": "test/integration/" }
  },
  "devResult": {
    "testResults": { "passed": 12, "failed": 0 },
    "filesChanged": ["src/services/tokenService.ts"]
  }
}
```

## Output

Returns QA validation results:

```json
{
  "qaResult": {
    "workItem": {
      "id": "TW-26134586",
      "status": "validated",
      "qualityScore": 92
    },
    "criteriaValidation": [
      {
        "criterion": "Token generation with configurable expiry",
        "status": "pass",
        "evidence": "Test 'should generate token with custom expiry' passes",
        "testFile": "src/__tests__/tokenService.test.ts:15"
      }
    ],
    "testExecution": {
      "unit": { "ran": true, "passed": 12, "failed": 0 },
      "integration": { "ran": true, "passed": 5, "failed": 0 },
      "e2e": { "ran": false, "reason": "No e2e tests defined" }
    },
    "coverageReport": {
      "statements": 94,
      "branches": 88,
      "functions": 100,
      "threshold": { "statements": 80, "met": true }
    },
    "routing": {
      "nextStep": "eval",
      "reason": "All acceptance criteria validated"
    }
  }
}
```

## QA Process

### 1. Criteria Mapping

Map each acceptance criterion to tests:

| # | Criterion | Test Type | Test Location | Status |
|---|-----------|-----------|---------------|--------|
| 1 | Token generation | Unit | tokenService.test.ts:15 | Pass |
| 2 | Token validation | Unit | tokenService.test.ts:32 | Pass |

### 2. Test Execution

Run tests by level:

**Unit Tests:**
```bash
npm test -- --coverage
```

**Integration Tests:**
```bash
npm run test:integration
```

**E2E Tests (if applicable):**
```bash
npm run test:e2e
```

### 3. Coverage Analysis

Check coverage meets thresholds:

| Metric | Minimum | Target |
|--------|---------|--------|
| Statements | 80% | 90% |
| Branches | 75% | 85% |
| Functions | 80% | 90% |
| Lines | 80% | 90% |

### 4. Criteria Verification

For each acceptance criterion:

1. Find related tests
2. Verify test passes
3. Document evidence (test name, location, result)

### 5. Quality Checks

**Code Quality:**
```bash
npm run lint
npm run typecheck
```

**Security Scan:**
```bash
npm audit
```

**Build Verification:**
```bash
npm run build
```

### 6. Issue Identification

Document issues found:

```json
{
  "issues": [
    {
      "type": "coverage_gap",
      "severity": "low",
      "description": "Branch coverage for error handling at 75%",
      "location": "src/services/tokenService.ts:42",
      "recommendation": "Add test for network timeout"
    }
  ]
}
```

**Issue Severity:**
| Severity | Meaning |
|----------|---------|
| `critical` | Blocks release, must fix |
| `high` | Should fix before release |
| `medium` | Fix in next iteration |
| `low` | Nice to have |

## Gherkin Test Generation

For acceptance criteria in Gherkin format:

**Input:**
```gherkin
Given a registered user with valid credentials
When they request an access token
Then they receive a JWT with 15-minute expiry
```

**Generated Test:**
```typescript
describe('Access Token Generation', () => {
  it('should return JWT with 15-minute expiry', async () => {
    // Given
    const user = await createTestUser();

    // When
    const response = await request(app)
      .post('/auth/token')
      .send({ email: user.email, password: 'valid' });

    // Then
    expect(response.status).toBe(200);
    const decoded = jwt.decode(response.body.accessToken);
    expect(decoded.exp - decoded.iat).toBe(15 * 60);
  });
});
```

## Quality Score Calculation

```
Quality Score = (
  (CriteriaPassed / TotalCriteria) * 40 +
  (TestsPassed / TotalTests) * 30 +
  (CoveragePercent / 100) * 20 +
  (NoLintErrors ? 10 : 0)
)
```

**Score Interpretation:**

| Score | Rating | Action |
|-------|--------|--------|
| 90-100 | Excellent | Proceed to eval |
| 80-89 | Good | Proceed with recommendations |
| 70-79 | Acceptable | Consider improvements |
| <70 | Needs Work | Return to dev |

## Validation Outcomes

### All Criteria Pass

```json
{
  "workItem": { "status": "validated" },
  "routing": { "nextStep": "eval" }
}
```

### Some Criteria Fail

```json
{
  "workItem": { "status": "needs_fix" },
  "routing": { "nextStep": "dev", "reason": "Fix failing tests" }
}
```

### Missing Tests

```json
{
  "workItem": { "status": "incomplete" },
  "routing": { "nextStep": "dev", "reason": "Add missing tests" }
}
```

## Manual Testing Notes

For criteria requiring manual verification:

```json
{
  "manualTests": [
    {
      "criterion": "UI displays error message",
      "steps": ["Navigate to login", "Enter invalid credentials", "Click submit"],
      "expected": "Red error banner displays",
      "status": "not_executed",
      "assignee": "human"
    }
  ]
}
```

## Focus Areas

- **Criteria Coverage** - Every criterion has a test
- **Test Quality** - Tests actually verify behavior
- **Coverage** - Meet or exceed thresholds
- **Regression** - No existing tests broken
- **Documentation** - Clear validation evidence

## Integration Points

| Agent | Direction | Data |
|-------|-----------|------|
| dev-agent | Receives from | Test results, coverage |
| eval-agent | Provides to | Quality metrics, validation |

## Related

- [dev-agent](dev-agent.md) - Previous step
- [eval-agent](eval-agent.md) - Next step
- [index](index.md) - Agent overview
