# Quality Commands

This directory contains commands for code review, architecture analysis, and quality assurance.

## Purpose

Quality commands ensure that code changes follow best practices, architectural patterns, and maintain high standards. They integrate with the agent playbook to learn from PR feedback and continuously improve code quality.

## Commands

### `/quality:code-review`
Deep code review for .NET microservices focusing on Clean Architecture best practices. Reviews code against architecture guardrails, hygiene rules, and learned patterns from the agent playbook.

**Usage:**
```bash
/quality:code-review
/quality:code-review --strict
/quality:code-review --files src/**/*.cs
```

**Features:**
- Clean Architecture validation
- SOLID principles enforcement
- Layer boundary checks
- Pattern detection
- Security vulnerability scanning
- Performance optimization suggestions

### `/quality:architecture-review`
Analyze codebase architecture for .NET, TypeScript/React/Vue, and SQL. Produces architecture.yaml and agent-playbook.yaml with guardrails, patterns, and recommendations.

**Usage:**
```bash
/quality:architecture-review
/quality:architecture-review --refresh
```

**Outputs:**
- `.claude/architecture.yaml` - Architecture documentation and guardrails
- `.claude/agent-playbook.yaml` - Coding patterns and best practices

### `/quality:extract-review-patterns`
Extract patterns from PR feedback and code review comments. Updates the agent playbook with learned patterns for future reviews.

**Usage:**
```bash
/quality:extract-review-patterns
/quality:extract-review-patterns --pr 123
```

**Purpose:**
- Learn from code review feedback
- Identify recurring issues
- Build institutional knowledge
- Improve future reviews

## Code Review Philosophy

The quality commands follow these principles:

1. **Proactive Prevention** - Catch issues before they reach PR review
2. **Learning Loop** - Continuously improve from feedback
3. **Context-Aware** - Understand project architecture and constraints
4. **Actionable Feedback** - Provide specific, implementable suggestions
5. **Consistent Standards** - Apply same rules across all reviews

## Integration

Quality commands integrate with:
- **Agent Playbook** (`/playbook:*`) - Pattern storage and validation
- **Recommendations** (`/recommendations:*`) - Architecture guidelines
- **Deliver** (`/workflow:deliver`) - Integrated into delivery pipeline
