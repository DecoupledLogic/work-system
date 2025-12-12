# ADR-0004: Architecture-Aware Agent System

## Status

Accepted

## Date

2024-12-08

## Context

When AI agents implement code changes, they need guidance on architectural constraints, patterns, and standards. Without this context, agents may:

1. **Violate layer boundaries**: Call infrastructure from API layer, bypass application services
2. **Introduce inconsistency**: Use different patterns for similar problems
3. **Create technical debt**: Ignore established conventions, skip logging/error handling
4. **Miss improvement opportunities**: Not leverage sanctioned refactoring patterns
5. **Require manual review overhead**: Reviewers catch issues that could be prevented

The challenge is providing architectural guidance that is:

- **Machine-readable**: Agents can parse and follow rules programmatically
- **Project-specific**: Tailored to each codebase, not generic advice
- **Maintainable**: Updated as architecture evolves
- **Actionable**: Clear enough to enforce or validate

## Decision

Implement an **Architecture-Aware Agent System** with three components:

### 1. Architecture Review Agent

A specialized agent that analyzes codebases and produces architecture artifacts:

```text
┌─────────────────────────────────────────────────────────┐
│              ARCHITECTURE REVIEW AGENT                    │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Input: Codebase (via /work:init)                       │
│                                                          │
│  Pass 1: MAP                                             │
│    - Identify layers, modules, components               │
│    - Trace dependencies                                  │
│    - Catalog technologies                                │
│                                                          │
│  Pass 2: EVALUATE                                        │
│    - Apply 6 lenses (domain, BE, FE, data, cross, evolve)│
│    - Identify patterns and anti-patterns                 │
│    - Score architecture health                           │
│                                                          │
│  Pass 3: RECOMMEND                                       │
│    - Guardrails (must enforce)                          │
│    - Leverage (sanctioned improvements)                  │
│    - Hygiene (touch-rule fixes)                         │
│    - Experiments (proposed changes)                      │
│                                                          │
│  Output:                                                 │
│    - .claude/architecture.yaml                           │
│    - .claude/agent-playbook.yaml                         │
│    - docs/architecture-recommendations.json              │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### 2. Machine-Readable Architecture Artifacts

Two YAML files that encode architecture decisions:

**architecture.yaml** - What the architecture IS:

```yaml
version: 1
system:
  name: MyApp
  style: modular-monolith
  language:
    backend: csharp
    frontend: typescript-react
    database: sql-relational

backend:
  projects:
    - name: MyApp.Domain
      layer: domain
      allowedDependencies: []
      forbiddenDependencies: ["Microsoft.AspNetCore.*"]
    - name: MyApp.Application
      layer: application
      allowedDependencies: ["MyApp.Domain"]
      forbiddenDependencies: ["MyApp.Infrastructure"]

evolvability:
  redLines:
    - "Never bypass Application layer from Api"
    - "Never add business logic to controllers"
```

**agent-playbook.yaml** - What agents SHOULD DO:

```yaml
backend:
  guardrails:
    - id: BE-G01
      rule: "Api controllers must only call Application services"
      enforcement: always

  leverage:
    - id: BE-L01
      pattern: "When adding new entity, follow Repository+CQRS pattern"

  hygiene:
    - id: BE-H01
      trigger: "When touching a file"
      action: "Add missing XML doc comments to public members"
```

### 3. Architecture-Aware Workflow Integration

Existing agents (design, dev) read architecture files and validate compliance:

```text
┌────────────────────────────────────────────────────────┐
│                  DELIVERY PIPELINE                      │
├────────────────────────────────────────────────────────┤
│                                                         │
│  /workflow:deliver TW-12345                                     │
│       │                                                 │
│       ▼                                                 │
│  ┌─────────────┐                                       │
│  │ Load Arch   │◄─── .claude/architecture.yaml         │
│  │ Context     │◄─── .claude/agent-playbook.yaml       │
│  └──────┬──────┘                                       │
│         │                                               │
│         ▼                                               │
│  ┌─────────────┐     ┌───────────────────────────┐    │
│  │ design-agent │────►│ Validate options against  │    │
│  │             │     │ guardrails before selecting │    │
│  └──────┬──────┘     └───────────────────────────┘    │
│         │                                               │
│         ▼                                               │
│  ┌─────────────┐     ┌───────────────────────────┐    │
│  │  dev-agent  │────►│ Follow layer boundaries,   │    │
│  │             │     │ patterns, leverage rules   │    │
│  └──────┬──────┘     └───────────────────────────┘    │
│         │                                               │
│         ▼                                               │
│  ┌─────────────┐                                       │
│  │ Compliance  │ ◄─── Report: guardrails checked,      │
│  │ Report      │      status, violations (if any)      │
│  └─────────────┘                                       │
│                                                         │
└────────────────────────────────────────────────────────┘
```

### Compliance Reporting

Every design option and implementation includes compliance status:

```json
{
  "architectureCompliance": {
    "guardrailsChecked": ["BE-G01", "BE-G02", "FE-G03"],
    "status": "compliant",
    "layersAffected": ["Application", "Api"],
    "patternsFollowed": ["Repository", "CQRS"]
  }
}
```

Or if violations are detected:

```json
{
  "architectureCompliance": {
    "status": "non-compliant",
    "violations": ["BE-G01: Api layer calling Infrastructure directly"],
    "action": "Refactored to use Application layer abstraction"
  }
}
```

## Consequences

### Positive

- **Consistency**: Agents follow the same rules across all changes
- **Guardrails**: Architectural violations caught before human review
- **Knowledge Transfer**: Architecture decisions encoded and accessible
- **Incremental Improvement**: Leverage patterns enable sanctioned refactoring
- **Reduced Review Burden**: Reviewers can focus on logic, not patterns
- **Auditability**: Compliance status tracked in delivery output

### Negative

- **Initial Setup**: Requires /work:init run for each repo
- **Maintenance**: Architecture files need updating as codebase evolves
- **Overhead**: Additional context for agents to process
- **False Positives**: Overly strict guardrails may block valid approaches

### Mitigations

- **Incremental adoption**: Can run /work:init anytime, files are additive
- **Human override**: Agents report violations but humans decide action
- **Periodic review**: Re-run architecture review to update artifacts
- **Guardrail tuning**: Adjust enforcement level per guardrail

## Implementation

### Files Added

| File | Purpose |
|------|---------|
| `agents/quality:architecture-review-agent.md` | Agent that analyzes codebases |
| `commands/work:init.md` | Per-repo initialization command |
| `commands/quality:architecture-review.md` | On-demand architecture review |
| `docs/templates/architecture.yaml` | Template for architecture spec |
| `docs/templates/agent-playbook.yaml` | Template for agent playbook |

### Agent Updates

| Agent | Changes |
|-------|---------|
| `design-agent.md` | Added Architecture Awareness section |
| `dev-agent.md` | Added Architecture Awareness section |
| `deliver.md` | Added Step 3: Load Architecture Context |

### Workflow

1. **Initial setup**: Run `/work:init` in project root
2. **Architecture review**: Agent analyzes codebase
3. **Artifact generation**: Creates `.claude/architecture.yaml` and `.claude/agent-playbook.yaml`
4. **Development**: Agents read artifacts and follow rules
5. **Compliance reporting**: Delivery includes architecture compliance status
6. **Maintenance**: Re-run `/quality:architecture-review` as codebase evolves

## Alternatives Considered

### 1. Static Linting Rules Only

Use existing linters (ESLint, StyleCop) for enforcement.

**Rejected because**:

- Linters catch syntax, not architecture
- Can't express layer boundaries
- No project-specific patterns

### 2. ADRs as Source of Truth

Have agents read ADRs directly.

**Rejected because**:

- ADRs are prose, not machine-readable
- Inconsistent format
- Hard to extract actionable rules

### 3. Inline Code Comments

Document patterns via code comments.

**Rejected because**:

- Scattered across codebase
- Easy to miss
- No single source of truth

### 4. External Architecture Tools

Use tools like ArchUnit, NDepend.

**Complementary, not replacement**:

- Good for CI enforcement
- We reference these in tooling section
- Agent system provides AI-specific guidance

## Related Decisions

- ADR-0003: Stage-Based Workflow with Sub-Agents
- ADR-0001: Work Manager Abstraction Layer

## References

- [Architecture Review Methodology](../quality:architecture-review-agent.md) - Full 3-pass review process with 6 evaluation lenses and 4 recommendation buckets
- [Architecture Agent Prompts](../architecture-agents-prompts.md) - System prompts for Architecture Review Agent and Architecture-Aware Builder Agent, including orchestrator message formats
- [Architecture Templates](../templates/) - YAML templates for `architecture.yaml` and `agent-playbook.yaml`
