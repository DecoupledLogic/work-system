# ADR-0003: Stage-Based Workflow with Sub-Agents

## Status

Accepted

## Date

2024-12-07

## Context

Work items (tasks, stories, features) need to flow through a consistent process regardless of their source or type. The process should:

1. Be predictable and repeatable
2. Capture learnings for improvement
3. Work across different project types (support, product, delivery)
4. Scale from small tasks to large features
5. Support automation while allowing human judgment

Traditional approaches:
- **Ad-hoc**: No structure, inconsistent results
- **Rigid waterfall**: Too inflexible for varied work types
- **Kanban columns**: Good for visibility, but no built-in process logic

## Decision

Implement a **stage-based workflow** with four primary stages, each handled by specialized sub-agents:

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ TRIAGE  │ ─► │  PLAN   │ ─► │ DESIGN  │ ─► │ DELIVER │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
     │              │              │              │
     ▼              ▼              ▼              ▼
  triage-       plan-          design-        dev-agent
  agent         agent          agent          qa-agent
                                              eval-agent
```

### Stage Definitions

| Stage | Purpose | Agent | Output |
|-------|---------|-------|--------|
| **Triage** | Categorize, prioritize, route | triage-agent | Enriched WorkItem with type, urgency, queue |
| **Plan** | Size, decompose, elaborate | plan-agent | Child work items, acceptance criteria |
| **Design** | Research, options, decide | design-agent | ADR, implementation plan, test plan |
| **Deliver** | Implement, test, evaluate | dev/qa/eval-agents | Code, tests, PR, metrics |

### Stage Transitions

```yaml
transitions:
  triage:
    success: plan
    needs_info: triage  # Loop back
    blocked: icebox

  plan:
    ready_for_design: design
    ready_for_delivery: deliver  # Skip design for small items
    needs_split: plan  # Decompose further

  design:
    design_complete: deliver
    scope_issue: plan  # Revisit sizing

  deliver:
    complete: done
    blocked: design  # Need design revision
    failed: triage  # Re-evaluate
```

### Sub-Agent Pattern

Each stage has a dedicated agent with:
- **Single responsibility**: One stage, one agent
- **Defined inputs/outputs**: Structured JSON schemas
- **Model selection**: Haiku for simple, Sonnet for reasoning
- **Stateless execution**: All context passed in, no side effects

```markdown
# Example: triage-agent.md

Input: Raw work item (task JSON, issue, or text)
Output: {
  workItem: EnrichedWorkItem,
  template: TemplateId,
  queue: Queue,
  nextStage: "plan"
}

Model: sonnet (requires reasoning)
```

### Commands as Orchestrators

Slash commands are thin orchestrators that:
1. Parse user input
2. Load context (session state, work item)
3. Call appropriate agent(s)
4. Update external systems
5. Update session state
6. Display results

```markdown
# /workflow:triage command flow

1. Parse task ID from input
2. Fetch task from work manager
3. Call triage-agent with task data
4. Update Teamwork with triage results
5. Route to queue based on urgency
6. Update active-work.md
7. Display summary and next steps
```

## Consequences

### Positive

- **Consistency**: Every work item follows the same stages
- **Traceability**: Can track what stage each item is in
- **Specialization**: Agents optimized for their stage
- **Flexibility**: Stages can be skipped or repeated
- **Testability**: Each agent can be tested in isolation
- **Metrics**: Can measure time/quality per stage

### Negative

- **Overhead for small tasks**: Four stages may be excessive for "fix typo"
- **Learning curve**: Users must understand stage model
- **Agent proliferation**: Multiple agents to maintain

### Mitigations

- **Stage skipping**: Small items can skip Design, go Triage → Plan → Deliver
- **Templates**: Templates encode which stages are required per work type
- **Documentation**: Clear docs on when to use each stage

## Stage Details

### Triage Stage

**Responsibilities:**
- Categorize type (bug, feature, support, etc.)
- Determine work type (product, support, delivery)
- Assess urgency (critical, now, next, future)
- Assess impact (high, medium, low)
- Assign template
- Route to queue

**Agent:** triage-agent (Sonnet)

### Plan Stage

**Responsibilities:**
- Infer size/appetite
- Split if too large
- Decompose (Epic → Features → Stories → Tasks)
- Elaborate (fill in required fields)
- Generate acceptance criteria (Gherkin)

**Agent:** plan-agent (Sonnet)

### Design Stage

**Responsibilities:**
- Research problem space
- Generate solution options
- Evaluate tradeoffs
- Select approach
- Create ADR
- Generate implementation plan

**Agent:** design-agent (Sonnet)

**When to skip:** Small stories, bug fixes, well-understood changes

### Deliver Stage

**Responsibilities:**
- **Dev**: Write code (TDD: red → green → refactor)
- **QA**: Run tests, check coverage, validate criteria
- **Eval**: Compare plan vs actual, capture learnings

**Agents:** dev-agent (Sonnet), qa-agent (Haiku), eval-agent (Sonnet)

## Alternatives Considered

### 1. Single Monolithic Agent

One agent handles all stages.

**Rejected because**:
- Too complex for a single prompt
- Can't optimize model per stage
- Harder to test and debug

### 2. Pure Kanban (Status-Based)

Use status columns without explicit stage logic.

**Rejected because**:
- No built-in process guidance
- Relies on human discipline
- Harder to automate

### 3. Microservices Pattern

Each operation is a separate service.

**Rejected because**:
- Over-engineering for current needs
- Adds infrastructure complexity
- Agents already provide isolation

## Related Decisions

- ADR-0001: Work Manager Abstraction Layer
- ADR-0002: Local-First Session State
- ADR-0004: Template System (pending)

## References

- `~/.claude/work-system.md` - Full work system specification
- `~/.claude/agents/*.md` - Individual agent definitions
- `~/.claude/commands/*.md` - Stage commands
