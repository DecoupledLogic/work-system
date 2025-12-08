# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for the Claude Code work system.

## What is an ADR?

An ADR is a document that captures an important architectural decision made along with its context and consequences. ADRs help:

- **Document decisions**: Record why we chose a particular approach
- **Share knowledge**: Help others understand the system
- **Avoid rehashing**: Prevent revisiting decided issues without new information
- **Track evolution**: Show how the architecture has changed over time

## ADR Format

Each ADR follows this structure:

```markdown
# ADR-NNNN: Title

## Status
Proposed | Accepted | Deprecated | Superseded

## Date
YYYY-MM-DD

## Context
What is the issue we're addressing?

## Decision
What did we decide to do?

## Consequences
What are the positive, negative, and neutral effects?

## Alternatives Considered
What other options were evaluated?

## Related Decisions
Links to related ADRs

## References
Links to implementation files
```

## Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [0001](0001-work-manager-abstraction.md) | Work Manager Abstraction Layer | Accepted | 2024-12-07 |
| [0002](0002-local-first-session-state.md) | Local-First Session State | Accepted | 2024-12-07 |
| [0003](0003-stage-based-workflow.md) | Stage-Based Workflow with Sub-Agents | Accepted | 2024-12-07 |

## Pending ADRs

The following decisions are documented in implementation files but should be formalized as ADRs:

- **Template System**: How templates drive work item behavior
- **Model Selection**: When to use Haiku vs Sonnet
- **Session Logging Format**: Structured log format for analytics

## Creating a New ADR

1. Copy the template above
2. Use the next number in sequence (e.g., `0004-*.md`)
3. Fill in all sections
4. Add to the index in this README
5. Link from relevant implementation files

## When to Write an ADR

Write an ADR when making decisions about:

- **Architecture**: System structure, component boundaries
- **Integration**: How systems connect (APIs, data formats)
- **Data**: Storage formats, schemas, persistence strategies
- **Process**: Workflow stages, automation rules
- **Technology**: Tool/library choices with significant impact

Don't write an ADR for:

- Implementation details that can easily change
- Bug fixes or minor enhancements
- Temporary workarounds (document differently)

---

*Created: 2024-12-07*
