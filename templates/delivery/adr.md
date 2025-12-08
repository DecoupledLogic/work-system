# ADR-{number}: {title}

## Status

{Proposed | Accepted | Deprecated | Superseded by ADR-XXX}

## Context

{Describe the situation that requires a decision. Include:
- The problem or challenge being addressed
- The forces at play (technical, business, team)
- Why the current state is insufficient
- Any constraints that must be respected}

## Decision

{State the decision clearly and concisely. Include:
- What approach was chosen
- Key implementation details
- Any standards or patterns to follow}

## Consequences

### Positive

- {Benefit 1}
- {Benefit 2}
- {Benefit 3}

### Negative

- {Tradeoff or cost 1}
- {Tradeoff or cost 2}

### Neutral

- {Implication that is neither clearly positive nor negative}

## Alternatives Considered

### {Alternative 1 Name}

{Brief description of the alternative}

**Why rejected:** {Reason this option was not chosen}

### {Alternative 2 Name}

{Brief description of the alternative}

**Why rejected:** {Reason this option was not chosen}

## Implementation Notes

{Optional: Any specific implementation guidance, migration steps, or rollout considerations}

## Related Decisions

- ADR-XXX: {Related decision title}
- ADR-YYY: {Another related decision}

---

**Date:** {YYYY-MM-DD}
**Decision makers:** {Names or roles involved}
**Work Item:** TW-{id}

---

## Template Usage Notes

This template follows the standard ADR format. Key guidelines:

1. **Status progression:** Proposed → Accepted → (Deprecated | Superseded)
2. **Context:** Focus on the "why" - what problem are we solving?
3. **Decision:** Be specific and actionable
4. **Consequences:** Be honest about tradeoffs
5. **Alternatives:** Document what else was considered

### When to Create an ADR

- Introducing new technology or framework
- Changing established patterns
- Making irreversible decisions
- High-risk implementations
- Decisions affecting multiple teams or systems

### ADR Numbering

Use sequential numbering: ADR-0001, ADR-0002, etc.
Find the next number with: `ls docs/architecture/adr/ | grep -oP 'ADR-\K\d+' | sort -n | tail -1`

### File Naming

`ADR-{number}-{kebab-case-title}.md`
Example: `ADR-0042-use-jwt-for-authentication.md`
