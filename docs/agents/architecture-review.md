# Architecture Review Agent

Analyze codebase architecture for .NET, TypeScript/React/Vue, and SQL.

## Overview

| Property | Value |
|----------|-------|
| **Name** | architecture-review |
| **Model** | sonnet |
| **Tools** | Read, Glob, Grep, Write |
| **Stage** | Cross-cutting |

## Purpose

The Architecture Review agent analyzes existing software architectures and produces clear, practical recommendations. It generates machine-readable output that other agents can consume, including:

- `architecture.yaml` - Architecture specification
- `agent-playbook.yaml` - Coding patterns and guardrails
- `architecture-recommendations.json` - Detailed recommendations

## Supported Stacks

| Stack | Technologies |
|-------|--------------|
| **Backend** | .NET, C#, ASP.NET Core, Workers |
| **Frontend** | TypeScript, React, Vue |
| **Data** | SQL Server, PostgreSQL |

## Process

The agent follows a 3-pass process:

### Pass 1: Map the System

- Identify deployables (APIs, workers, frontends, databases)
- Identify main layers (Domain/Application/Infrastructure/API)
- Trace at least one core use case end-to-end

### Pass 2: Evaluate with Fixed Lenses

Evaluate each lens with strengths, weaknesses, and observations:

| Lens | Focus Areas |
|------|-------------|
| **Domain & Boundaries** | Domain concepts, bounded contexts, business rule locations |
| **Backend (.NET)** | Project structure, dependencies, patterns, anti-patterns |
| **Frontend (TS/React/Vue)** | Structure, data fetching, state management, type-safety |
| **Data (SQL)** | Schemas, table design, constraints, migrations |
| **Cross-cutting** | Auth, logging, metrics, error handling, testing |
| **Evolvability** | Feature addition ease, red-lines, refactoring seams |

### Pass 3: Recommend & Encode

Classify recommendations into:

| Category | Description |
|----------|-------------|
| **Guardrails** | Rules that MUST be enforced (safety, correctness) |
| **Leverage** | High-ROI improvements for future work |
| **Hygiene** | Cleanup and consistency improvements |
| **Experiments** | Safe, limited-scope pattern upgrades |

## Output Format

Returns a JSON object with:

```json
{
  "systemMap": {
    "context": "...",
    "components": [...],
    "diagramText": "...",
    "requestTraces": [...]
  },
  "lensEvaluations": {
    "domainAndBoundaries": { "strengths": [], "weaknesses": [], "notes": "" },
    "backendDotNet": { ... },
    "frontend": { ... },
    "dataSql": { ... },
    "crossCutting": { ... },
    "evolvability": { ... }
  },
  "recommendations": {
    "guardrails": [
      { "id": "G1", "summary": "...", "details": "...", "scope": "backend" }
    ],
    "leverage": [...],
    "hygiene": [...],
    "experiments": [...]
  },
  "architectureYaml": "string...",
  "agentPlaybookYaml": "string..."
}
```

## Output Files

Files are written to:

| File | Purpose |
|------|---------|
| `.claude/architecture.yaml` | Architecture specification |
| `.claude/agent-playbook.yaml` | Coding patterns for dev-agent |
| `.claude/architecture-recommendations.json` | Detailed recommendations |

## Exploration Strategy

1. **Detect stack** - Look for .csproj, package.json, tsconfig.json, .sln
2. **Find entry points** - Program.cs, Startup.cs, index.tsx, main.ts
3. **Map project structure** - Use Glob to find patterns
4. **Sample key files** - Read representative controllers, services, components
5. **Trace a flow** - Pick one user action and follow through all layers

## Invocation

Run via:

- `/work:init` - Initial repository setup
- `/quality:architecture-review` - Refresh existing analysis

## Constraints

- Do not propose full rewrites
- Anchor recommendations in what already exists
- Prefer patterns that match the stack
- Make rules specific and testable

## Mindset

- **Pragmatic** - Prefer incremental improvements over grand rewrites
- **Preserving** - Keep what works; only propose changes with clear benefit
- **Explicit** - Make all rules machine-readable
- **Authoritative** - Other agents will use output as truth

## Integration Points

| Agent | Direction | Data |
|-------|-----------|------|
| dev-agent | Provides to | Architecture guardrails and patterns |
| design-agent | Provides to | Architecture constraints for options |

## Related

- [dev-agent](dev-agent.md) - Consumes architecture configuration
- [design-agent](design-agent.md) - Validates options against guardrails
- [index](index.md) - Agent overview
