# Quality Commands

Code review and architecture analysis for maintaining code quality.

## Commands

| Command | Description |
|---------|-------------|
| `/quality:code-review` | Deep code review for .NET microservices |
| `/quality:architecture-review` | Analyze codebase and generate playbook |
| `/quality:extract-review-patterns` | Extract patterns from PR feedback |

## /quality:code-review

Reviews code against architecture guardrails, hygiene rules, and learned patterns.

```bash
/quality:code-review
/quality:code-review --strict
/quality:code-review --files src/**/*.cs
```

Checks:
- Clean Architecture validation
- SOLID principles
- Layer boundaries
- Security vulnerabilities
- Performance patterns

## /quality:architecture-review

Generates architecture documentation and agent playbook.

```bash
/quality:architecture-review
/quality:architecture-review --refresh
```

Outputs:
- `.claude/architecture.yaml`
- `.claude/agent-playbook.yaml`

## /quality:extract-review-patterns

Learns from PR feedback to improve future reviews.

```bash
/quality:extract-review-patterns
/quality:extract-review-patterns --pr 123
```

See source commands in [commands/quality/](../../../commands/quality/) for full documentation.
