# Dev Agent

Implement code changes following TDD practices.

## Overview

| Property | Value |
|----------|-------|
| **Name** | dev-agent |
| **Model** | sonnet |
| **Tools** | Read, Edit, Write, Bash, Glob, Grep |
| **Stage** | Deliver |

## Purpose

The Dev Agent turns designed work items into working code. It handles:

- Expanding stories into implementation specs
- Writing failing tests first (TDD)
- Implementing minimum code to pass tests
- Refactoring while keeping tests green
- Creating commits and branches
- Submitting for review

## Architecture Awareness

Before implementing, the agent loads architecture configuration:

| File | Purpose |
|------|---------|
| `.claude/architecture.yaml` | Architecture spec, layer dependencies |
| `.claude/agent-playbook.yaml` | Coding patterns, guardrails |
| `architecture-recommendations.json` | PR feedback learning loop |

### Guardrails (MUST follow)

For each guardrail with `enforcement: always`:
1. Check if rule applies to current code
2. Follow the rule strictly
3. Report compliance

```typescript
// ❌ VIOLATION: BE-G01 (Api calling Infrastructure)
import { PaymentRepository } from '../Infrastructure/PaymentRepository';

// ✅ COMPLIANT: BE-G01 (Api calls Application)
import { IPaymentService } from '../Application/Services/IPaymentService';
```

### Leverage Patterns (SHOULD apply)

Apply high-ROI patterns when appropriate:

```csharp
// Pattern ARCH-L002: Filter at database level
// ❌ Before:
var allUsers = await _context.Users.ToListAsync();
var activeUsers = allUsers.Where(u => u.IsActive);

// ✅ After:
var activeUsers = await _context.Users
    .Where(u => u.IsActive)
    .ToListAsync();
```

### Hygiene Rules (NICE to have)

Apply when time permits:

```csharp
// Hygiene rule ARCH-H001: Add XML comments to public APIs
/// <summary>
/// Processes payment for the given order.
/// </summary>
public async Task<PaymentResult> ProcessPayment(string orderId, int amount)
```

## Input

Expects a designed WorkItem:

```json
{
  "workItem": {
    "id": "TW-26134586",
    "name": "Create JWT token service",
    "type": "task",
    "status": "designed",
    "acceptanceCriteria": [
      "Token generation with configurable expiry",
      "Token validation returns decoded payload"
    ]
  },
  "implementationPlan": {
    "estimateHours": 4,
    "technicalNotes": ["Use jsonwebtoken library", "Follow existing patterns"]
  },
  "context": {
    "branch": "feature/TW-26134585-auth-system",
    "existingPatterns": { "testFramework": "jest" }
  }
}
```

## Output

Returns development results:

```json
{
  "devResult": {
    "workItem": {
      "id": "TW-26134586",
      "status": "implemented",
      "actualHours": 3.5
    },
    "commits": [
      { "hash": "abc123", "message": "test: add JWT token service tests" },
      { "hash": "def456", "message": "feat: implement JWT token service" },
      { "hash": "ghi789", "message": "refactor: extract token config" }
    ],
    "testResults": {
      "passed": 12,
      "failed": 0,
      "coverage": { "statements": 94 }
    },
    "architectureCompliance": {
      "guardrailsChecked": ["BE-G01", "BE-G02"],
      "violations": [],
      "leverageApplied": [{ "id": "ARCH-L002", "pattern": "Filter at DB" }],
      "status": "compliant"
    },
    "routing": { "nextStep": "qa" }
  }
}
```

## TDD Development Process

### 1. Spec Phase

Expand acceptance criteria into testable specifications:

```markdown
## Implementation Spec: {story.name}

### Acceptance Criteria Mapping
| Criterion | Test Case | Implementation |
|-----------|-----------|----------------|
| {criterion1} | {test} | {approach} |

### Edge Cases
- {edge case 1}
```

### 2. Red Phase (Write Failing Test)

```typescript
describe('TokenService', () => {
  describe('generateAccessToken', () => {
    it('should generate valid JWT with configurable expiry', () => {
      // Arrange
      const payload = { userId: '123' };

      // Act
      const token = tokenService.generateAccessToken(payload, '15m');

      // Assert
      expect(token).toBeDefined();
      const decoded = jwt.verify(token, config.secret);
      expect(decoded.userId).toBe('123');
    });
  });
});
```

### 3. Verify Red

Run tests to confirm they fail:

```bash
npm test -- --testPathPattern="tokenService"
```

### 4. Green Phase (Minimum Implementation)

Write minimum code to pass tests:

```typescript
export class TokenService {
  generateAccessToken(payload: TokenPayload, expiry?: string): string {
    if (!payload) throw new Error('Payload is required');
    return jwt.sign(payload, authConfig.secret, {
      expiresIn: expiry || authConfig.defaultExpiry
    });
  }
}
```

### 5. Verify Green

Run tests to confirm they pass.

### 6. Refactor Phase

Improve code while keeping tests green:

- Extract constants and configuration
- Remove duplication
- Improve naming
- Simplify complex logic

### 7. Commit

Create focused commits:

| Type | Usage |
|------|-------|
| `test:` | Test additions |
| `feat:` | New functionality |
| `fix:` | Bug fixes |
| `refactor:` | Code improvements |
| `docs:` | Documentation |

```
type(scope): brief description

🤖 Submitted by George with love ♥
```

### 8. Iterate

Repeat for each acceptance criterion:

```
For each criterion:
  1. Write failing test
  2. Verify failure
  3. Implement minimum
  4. Verify pass
  5. Refactor
  6. Commit
```

## Code Quality Standards

### Style Guidelines

- Use existing linting rules
- Match existing code style
- Follow naming conventions
- Use TypeScript strictly

### Security Considerations

- No hardcoded secrets
- Validate all inputs
- Handle errors properly
- Follow OWASP guidelines

### Performance

- Consider time complexity
- Avoid unnecessary operations
- Use caching where appropriate
- Don't premature optimize

## Branch Management

```bash
# Create feature branch
/git-checkout feature/TW-{id}-{slug} --create

# Regular commits
/git-commit "test: add token validation tests"
/git-commit "feat: implement token validation"

# Push for backup/CI
/git-push --set-upstream
```

## Error Handling

### Test Failures

```json
{
  "workItem": { "status": "blocked" },
  "blockingIssue": {
    "type": "test_failure",
    "description": "Integration test failing due to Redis"
  },
  "routing": { "nextStep": "investigate" }
}
```

### Implementation Blockers

```json
{
  "workItem": { "status": "blocked" },
  "blockingIssue": {
    "type": "dependency",
    "description": "Required API endpoint not implemented",
    "dependency": "TW-26134590"
  }
}
```

### Scope Creep

```json
{
  "workItem": { "status": "needs_replanning" },
  "scopeIssue": {
    "originalEstimate": 4,
    "actualEstimate": 12,
    "reason": "Token rotation requires DB changes"
  },
  "routing": { "nextStep": "plan" }
}
```

## Architecture Compliance Output

```json
{
  "architectureCompliance": {
    "guardrailsChecked": [
      {"id": "BE-G01", "status": "compliant"},
      {"id": "BE-G05", "status": "compliant"}
    ],
    "violations": [],
    "leverageApplied": [
      {"id": "ARCH-L002", "pattern": "Filter at database"}
    ],
    "hygieneApplied": [
      {"id": "ARCH-H001", "rule": "XML comments", "filesAffected": 3}
    ],
    "status": "compliant",
    "layersAffected": ["Application", "Api"]
  }
}
```

## Focus Areas

- **TDD Discipline** - Always test first
- **Minimum Implementation** - Don't over-engineer
- **Clean Commits** - Atomic, focused changes
- **Quality** - Follow project standards
- **Traceability** - Link commits to work items

## Integration Points

| Agent | Direction | Data |
|-------|-----------|------|
| design-agent | Receives from | Implementation plan, ADR |
| qa-agent | Provides to | Test results, coverage |
| architecture-review | Loads from | Architecture configuration |

## Related

- [design-agent](design-agent.md) - Provides implementation plan
- [qa-agent](qa-agent.md) - Next step
- [architecture-review](architecture-review.md) - Provides guardrails
- [index](index.md) - Agent overview
