# ADR (Architecture Decision Record) Guide

## Purpose

An Architecture Decision Record documents a significant architectural decision along with its context, rationale, and consequences. ADRs create an immutable record of why decisions were made, helping future team members understand the reasoning behind the current architecture.

## When to Create an ADR

Create an ADR when:

- **Technology choice**: Selecting a framework, library, database, or cloud service
- **Pattern adoption**: Choosing an architectural pattern (event sourcing, CQRS, microservices)
- **Integration approach**: Deciding how systems will communicate
- **Data modeling**: Significant changes to data structures or storage
- **Security decisions**: Authentication, authorization, or encryption approaches
- **Performance tradeoffs**: Choices that prioritize one quality attribute over another

Skip ADR for:

- Implementation details within an established pattern
- Bug fixes that don't change architecture
- Temporary solutions with known expiration
- Reversible decisions with minimal impact

## Relationship to Other Artifacts

### ADR Position in Workflow

```text
Design Stage (Options explored)
  ↓ (decision made)
ADR (Decision documented) ← You are here
  ↓ (informs)
Implementation Plan (Tasks to execute)
  ↓ (guides)
Development (Decision applied)
```

### What Flows from ADR

**To Implementation Plan**:

- **Decision** → Implementation approach
- **Consequences** → Risk mitigation tasks

**To Architecture Blueprint**:

- **Decision** → Core principles
- **Context** → System constraints

**To Future ADRs**:

- **Decision** → Supersedes relationship
- **Consequences** → Follow-on decisions

## Core Structure

### 1. Header and Status

```markdown
# ADR-[Number]: [Title]

**Status**: [Proposed | Accepted | Deprecated | Superseded]
**Date**: [Decision date]
**Deciders**: [Who made this decision]
```

**Status definitions**:

- **Proposed**: Under discussion, not yet decided
- **Accepted**: Decision made and in effect
- **Deprecated**: No longer recommended but still in use
- **Superseded**: Replaced by another ADR (link to replacement)

### 2. Context

```markdown
## Context

[Describe the situation that requires a decision. Include:
- What problem are we solving?
- What constraints exist?
- What forces are at play?]
```

**Example**:

```markdown
## Context

Our application needs to authenticate users across multiple services. Currently, each service manages its own sessions, leading to:

- Users logging in multiple times across services
- Inconsistent session timeouts
- Difficulty implementing single sign-out
- Security audit findings about session management

We need a centralized authentication approach that works across all services while supporting our existing user base.
```

### 3. Decision

```markdown
## Decision

[State the decision clearly and concisely. Use active voice.
"We will..." or "We have decided to..."]
```

**Example**:

```markdown
## Decision

We will use JWT (JSON Web Tokens) with short-lived access tokens (15 minutes) and long-lived refresh tokens (7 days) for authentication across all services.

The authentication flow will be:

1. User authenticates with Auth Service
2. Auth Service issues access token and refresh token
3. Services validate access tokens locally using shared public key
4. Clients refresh tokens before expiration
```

### 4. Consequences

```markdown
## Consequences

### Positive

- [Benefit 1]
- [Benefit 2]
- [Benefit 3]

### Negative

- [Drawback 1]
- [Drawback 2]
- [Drawback 3]
```

**Example**:

```markdown
## Consequences

### Positive

- Single sign-on across all services
- Stateless authentication - services don't need session storage
- Reduced latency - no auth service call on every request
- Easy to scale horizontally
- Standard approach with good library support

### Negative

- Cannot immediately revoke access (must wait for token expiration)
- Token size larger than session ID (bandwidth consideration)
- Key rotation complexity
- Refresh token storage requires secure implementation
- Team needs to learn JWT best practices
```

### 5. Alternatives Considered

```markdown
## Alternatives Considered

### [Alternative 1]

[Brief description]

**Rejected because**: [Reason]

### [Alternative 2]

[Brief description]

**Rejected because**: [Reason]
```

**Example**:

```markdown
## Alternatives Considered

### Session-based with Redis

Centralized session store shared across all services.

**Rejected because**: Adds Redis as critical dependency, single point of failure, latency on every request to validate session.

### OAuth 2.0 with external provider

Use Auth0 or Okta for authentication.

**Rejected because**: Cost at our scale ($15K+/year), vendor lock-in, latency to external service, existing users would need migration.

### SAML 2.0

Enterprise SSO standard.

**Rejected because**: Complex implementation, XML-based (not REST-friendly), overkill for our use case, poor mobile support.
```

### 6. Related Decisions (Optional)

```markdown
## Related Decisions

- [ADR-XXX](ADR-XXX-title.md): [Relationship description]
- [ADR-YYY](ADR-YYY-title.md): [Relationship description]
```

**Example**:

```markdown
## Related Decisions

- [ADR-012](ADR-012-api-gateway.md): API Gateway will handle JWT validation at the edge
- [ADR-008](ADR-008-user-storage.md): User data model this authentication builds on
- Supersedes [ADR-003](ADR-003-session-auth.md): Original session-based approach
```

### 7. References (Optional)

```markdown
## References

- [Reference 1](URL)
- [Reference 2](URL)
```

**Example**:

```markdown
## References

- [JWT Best Practices](https://datatracker.ietf.org/doc/html/rfc8725)
- [OWASP JWT Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html)
- [Auth0 JWT Handbook](https://auth0.com/resources/ebooks/jwt-handbook)
```

## Template

When creating a new ADR, use this template:

```markdown
# ADR-[Number]: [Title]

**Status**: Proposed
**Date**: [Date]
**Deciders**: [Names]

## Context

[Describe the situation requiring a decision]

## Decision

[State the decision]

## Consequences

### Positive

- [Benefit 1]
- [Benefit 2]

### Negative

- [Drawback 1]
- [Drawback 2]

## Alternatives Considered

### [Alternative 1]

[Description]

**Rejected because**: [Reason]

### [Alternative 2]

[Description]

**Rejected because**: [Reason]

## Related Decisions

- [Links to related ADRs]

## References

- [Links to supporting materials]
```

## ADR Numbering

ADRs are numbered sequentially:

- `ADR-0001-initial-tech-stack.md`
- `ADR-0002-database-selection.md`
- `ADR-0003-authentication-approach.md`

**Numbering rules**:

- Never reuse numbers (even if ADR is deleted)
- Use 4-digit padding for sorting (0001, not 1)
- Superseded ADRs keep their number

## Writing Effective ADRs

### Context Section Tips

- Describe the problem, not the solution
- Include relevant constraints (budget, timeline, team skills)
- Mention what triggered this decision
- Be specific about forces at play

### Decision Section Tips

- Use active voice ("We will...")
- Be specific enough to act on
- Include key implementation details
- Avoid ambiguity

### Consequences Section Tips

- Be honest about negatives
- Include operational implications
- Consider team learning curve
- Think about reversibility

### Alternatives Section Tips

- Include seriously considered options
- Explain why each was rejected
- Be fair to alternatives (don't strawman)
- Document "do nothing" if considered

## ADR Lifecycle

### Proposed → Accepted

1. Write initial ADR with status "Proposed"
2. Share with stakeholders for review
3. Discuss and refine
4. Change status to "Accepted" when consensus reached
5. Update date to decision date

### Accepted → Deprecated

When a decision is no longer recommended but still exists:

1. Change status to "Deprecated"
2. Add note explaining why deprecated
3. Link to recommended alternative if exists

### Accepted → Superseded

When a decision is replaced by a new decision:

1. Change status to "Superseded by [ADR-XXX]"
2. Link to new ADR
3. New ADR should reference "Supersedes [ADR-YYY]"

## Common Pitfalls

### Avoid These Mistakes

1. **Too much detail**: Including implementation specifics
   - **Fix**: Focus on the decision and rationale, not how to implement

2. **Missing context**: Jumping straight to decision
   - **Fix**: Explain why this decision is needed

3. **No alternatives**: Only documenting the chosen option
   - **Fix**: Include at least 2 seriously considered alternatives

4. **Dishonest consequences**: Only listing positives
   - **Fix**: Be honest about tradeoffs and risks

5. **Vague decision**: "We will improve authentication"
   - **Fix**: Be specific enough that someone could implement it

6. **No status tracking**: ADRs never updated
   - **Fix**: Maintain status as decisions evolve

7. **Too many ADRs**: Recording trivial decisions
   - **Fix**: Only document architecturally significant decisions

## Storage Location

ADRs are stored globally since architecture decisions typically apply across projects:

```text
~/.claude/docs/adr/
├── ADR-0001-initial-tech-stack.md
├── ADR-0002-database-selection.md
└── ADR-0003-authentication-approach.md
```

For project-specific ADRs (rare), store in:

```text
docs/architecture/adr/
└── ADR-0001-project-specific.md
```

## Markdown Linting Requirements

All ADRs must comply with the markdown standards defined in [markdown-standards.md](../markdown-standards.md).

### Quick Validation

```bash
markdownlint adr.md
```

## Summary

A well-crafted ADR:

- **Captures** the context that led to the decision
- **States** the decision clearly and specifically
- **Acknowledges** both positive and negative consequences
- **Documents** alternatives that were considered
- **Links** to related decisions and references
- **Maintains** status as the decision evolves

Use this guide when documenting significant architectural decisions.
