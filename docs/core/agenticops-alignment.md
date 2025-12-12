# AgenticOps Alignment Analysis

A comprehensive analysis of the work-system documentation ecosystem with a consolidation strategy to create a cohesive AgenticOps framework.

## Executive Summary

This analysis reviews 14 documents in `docs/core/` totaling approximately 9,000+ lines of documentation. The documents represent multiple evolution phases of thinking about agentic work systems, resulting in significant overlap, contradictions, and fragmentation.

**Key Findings:**
- 4 distinct workflow models competing for authority
- 3 different agent taxonomies with overlapping responsibilities
- 3 separate work item schemas with incompatible fields
- 2 competing product visions (developer tool vs SaaS platform)
- Significant redundancy in Conductor agent definitions

**Recommendation:** Consolidate to 4 canonical documents (from 14), archive the rest, and establish a single authoritative source for each core concept.

---

## Migration Status (Completed 2025-12-09)

### Final Structure

**docs/core/** (4 files - canonical)

- `work-system.md` - Core specification
- `work-system-readme.md` - High-level overview
- `work-system-guide.md` - Comprehensive user guide
- `agenticops-alignment.md` - This analysis document

**docs/archive/** (10 files - preserved for reference)

- Vision docs: `agenticops-product-plan.md`, `agenticops-kernel.md`, `agenticops-value-train.md`, `pipeline.md`, `llm-solutions-in-product-engineering.md`
- Future merge candidates: `agentic-ops-structure.md`, `work-processing.md`, `conductor-agent.md`, `context-management.md`
- `README.md` - Archive documentation with pattern extraction guide

**docs/guides/** (2 files - extracted practices)

- `slash-command-best-practices.md` (from agenticops-practices.md)
- `agent-prompt-patterns.md` (from improving-agent-prompts.md)

### Migration Approach

Rather than a risky full merge of ~130KB of content into work-system.md, the merge candidates were archived with detailed pattern documentation. This enables incremental incorporation of valuable patterns while maintaining system stability.

---

## Document Inventory (Pre-Migration)

| Document | Lines | Purpose | Keep/Archive |
|----------|-------|---------|--------------|
| work-system.md | ~1100 | Core specification | **KEEP (Refactor)** |
| work-system-readme.md | 326 | High-level overview | **KEEP (Update)** |
| work-system-guide.md | 1161 | User guide | **KEEP (Update)** |
| work-processing.md | 1498 | State machine & events | **MERGE into work-system.md** |
| pipeline.md | 1690 | Discovery pipeline | **ARCHIVE** (extract templates) |
| agentic-ops-structure.md | 1095 | Agent taxonomy | **MERGE into work-system.md** |
| conductor-agent.md | 135 | Conductor spec | **MERGE into work-system.md** |
| agenticops-value-train.md | 799 | Operational framework | **ARCHIVE** (vision doc) |
| agenticops-product-plan.md | 742 | SaaS product plan | **ARCHIVE** (separate product) |
| agenticops-kernel.md | 112 | Strategy framework | **ARCHIVE** |
| agenticops-practices.md | ~900+ | Slash command best practices | **EXTRACT** (move to guides/) |
| improving-agent-prompts.md | 130 | Agent prompt patterns | **EXTRACT** (move to guides/) |
| llm-solutions-in-product-engineering.md | 53 | LLM solution layers | **ARCHIVE** (reference only) |
| context-management.md | 97 | Memory architecture | **MERGE into work-system.md** |

---

## Conceptual Conflicts Analysis

### 1. Workflow Models (4 Competing Versions)

#### Version A: work-system.md (4 stages)
```
Triage → Plan → Design → Deliver
```
- Simple, implementable
- Currently used by slash commands
- Maps to existing agents

#### Version B: work-processing.md (11 states)
```
Created → Ready → Validated → Routed → InProgress →
Completed → Reviewed → Evaluated → Approved → Done → Closed
```
- More granular state machine
- Event-driven architecture
- Blocked/Error as overlays

#### Version C: pipeline.md (13+ stages)
```
Discovery: Capture → Measurement → Observation → Intuition →
           Theory → Thesis → Use Case → Hypothesis →
           Baseline → Experiment Design → Discovery Review
Inception: Product Requirement → Feature Request → Decision (ADR)
Elaboration: Task
```
- Research-oriented pipeline
- Heavy artifact production
- Academic/thorough approach

#### Version D: agenticops-value-train.md (Modes)
```
/intake → /discover → /scope → /workflow:design → /build →
/evaluate → /workflow:deliver → /operate → /improve
```
- Mode-based operating contexts
- CI/CD integration (Auto-Pilot)
- Phase-ticket folder structure

**Recommendation:** Adopt Version A as the primary workflow for work-system, with Version B's state machine as the internal implementation. Archive Versions C and D as reference material for future features.

---

### 2. Agent Taxonomies (3 Competing Versions)

#### Version A: work-system.md Agents
| Agent | Purpose |
|-------|---------|
| work-item-mapper | Normalize external tasks |
| triage-agent | Categorize and route |
| plan-agent | Decompose and size |
| design-agent | Explore solutions, ADRs |
| dev-agent | Implement with TDD |
| qa-agent | Validate quality |
| eval-agent | Evaluate outcomes |
| session-logger | Capture activity |

#### Version B: agentic-ops-structure.md Agents
**Control Layer:**
- Conductor (control loop, flow management)

**Milestone Agents:**
- Opportunity, Discovery, Inception, Elaboration, Construction, Transition, Maintenance

**Functional Agents:**
- Analyst, Bookkeeper, Communicator, Designer, DevOps, Engineer, Evaluator, Research, Writer

#### Version C: agenticops-value-train.md Agents
| Agent | Purpose |
|-------|---------|
| Conductor | Coordinates pipeline, merges PRs |
| Onboarder | Pre-engagement success |
| Lab | Data profiling, extraction, modeling |
| Studio | Model design, architecture |
| Ops | Cloud provisioning, monitoring |
| Evaluator | Quality validation |
| Improver | Optimization, retraining |

**Recommendation:** Adopt Version A as the canonical agent set for work-system. Extract the Conductor concept from Versions B/C as a future enhancement for autonomous operation.

---

### 3. Work Item Schemas (3 Versions)

#### Version A: work-system.md WorkItem
```yaml
WorkItem:
  type: epic|feature|story|task|bug|support
  workType: product_delivery|support|maintenance|bug_fix|research
  urgency: critical|now|next|future
  impact: high|medium|low
  queue: immediate|todo|backlog|icebox
  stage: triage|plan|design|deliver
  processTemplate: string
```

#### Version B: work-processing.md WorkItem (Detailed)
```yaml
WorkItem:
  identity: {id, name, version, type, workType}
  lifecycle: {funnel, milestone, stage, state}
  routing: {deliverable, type, capability, urgency, impact, queue}
  io: {inputs, context, criteria, outputs, artifacts}
  wip: {assigned_to, started_at, completed_at, blocked, error}
  metrics: {estimates, actuals, scores}
  audit: {created, modified, events}
```

#### Version C: agenticops-value-train.md ticket.yml
```yaml
ticket:
  ticket: train_142
  issue_id: 142
  phase: train
  stage: HPO
  mode: /drive
  status: InProgress
  checklist: [...]
  artifacts: [...]
  evaluation: {...}
```

**Recommendation:** Use Version A for the public API, Version B concepts for internal implementation, archive Version C as mode-specific.

---

### 4. Product Vision Conflicts

#### Vision A: Developer Tool (work-system)
- Claude Code extension
- Slash commands for developers
- Local-first, backend-agnostic
- Free/open source

#### Vision B: SaaS Platform (agenticops-product-plan)
- Credit-based system ($249/quarter)
- Consumer-facing agents
- Order processing architecture
- AWS microservices

**Recommendation:** These are separate products. work-system is the developer tool. agenticops-product-plan describes a different commercial offering. Archive the product plan in a separate location.

---

## Redundancy Map

### Conductor Agent (Defined 3 Times)

| Source | Lines | Unique Content |
|--------|-------|----------------|
| agentic-ops-structure.md | ~200 | Control loop, policies, routing |
| conductor-agent.md | 135 | Work orders, KPIs, guardrails |
| agenticops-value-train.md | ~50 | Pipeline coordination, PR merging |

**Action:** Merge into single authoritative `conductor-agent.md` in agents/ directory.

### Memory/Context Architecture (Defined 2 Times)

| Source | Content |
|--------|---------|
| context-management.md | Vector DB + file store |
| improving-agent-prompts.md | Facts/Logs/Plans tiers |

**Action:** Merge into work-system.md section on memory architecture.

### Routing Patterns (Defined 3 Times)

| Source | Pattern |
|--------|---------|
| work-system.md | Template-based routing |
| agentic-ops-structure.md | type+capability deterministic |
| improving-agent-prompts.md | domain/artifact/verb tags |

**Action:** Standardize on template-based routing with type+capability as internal implementation.

---

## Consolidation Strategy

### Phase 1: Immediate Archive (Week 1)

Move to `docs/archive/` with README explaining historical context:

1. **agenticops-product-plan.md** - Separate commercial product vision
2. **agenticops-kernel.md** - Strategic planning doc, not implementation
3. **llm-solutions-in-product-engineering.md** - Reference material only
4. **agenticops-value-train.md** - Rich vision doc, extract useful patterns first

### Phase 2: Extract & Relocate (Week 1-2)

1. **agenticops-practices.md** → `docs/guides/slash-command-best-practices.md`
2. **improving-agent-prompts.md** → `docs/guides/agent-prompt-patterns.md`
3. **pipeline.md** Discovery templates → `docs/templates/discovery/`

### Phase 3: Merge & Consolidate (Week 2-3)

Create unified work-system.md with sections from:

1. **work-system.md** (base)
2. **work-processing.md** (state machine, events)
3. **agentic-ops-structure.md** (agent taxonomy, routing)
4. **conductor-agent.md** (Conductor spec)
5. **context-management.md** (memory architecture)

### Phase 4: Update References (Week 3)

1. Update work-system-readme.md to reflect consolidated structure
2. Update work-system-guide.md with accurate references
3. Remove dead links from all documents
4. Create migration guide for any breaking changes

---

## Unified Architecture Proposal

### Canonical Document Structure

```
docs/
├── core/
│   ├── work-system.md           # Single source of truth
│   ├── work-system-readme.md    # Overview & quick start
│   └── work-system-guide.md     # Comprehensive user guide
├── guides/
│   ├── slash-command-best-practices.md
│   ├── agent-prompt-patterns.md
│   └── template-authoring.md
├── templates/
│   ├── discovery/               # Discovery phase templates
│   └── delivery/                # Delivery templates
├── archive/
│   ├── README.md                # Why these were archived
│   ├── agenticops-product-plan.md
│   ├── agenticops-kernel.md
│   ├── agenticops-value-train.md
│   └── llm-solutions-in-product-engineering.md
└── adrs/
    └── (Architecture Decision Records)
```

### Unified Work System Model

```yaml
# Canonical WorkItem Schema
WorkItem:
  # Identity
  id: string
  name: string
  type: epic|feature|story|task|bug|support
  workType: product_delivery|support|maintenance|bug_fix|research

  # Lifecycle
  stage: triage|plan|design|deliver
  state: created|ready|in_progress|blocked|completed|closed
  queue: immediate|todo|backlog|icebox

  # Routing
  urgency: critical|now|next|future
  impact: high|medium|low
  processTemplate: string

  # Assignment
  owner: string
  assignedTo: string[]

  # Content
  description: string
  acceptanceCriteria: string[]

  # Metrics
  estimate: duration
  actual: duration

  # Audit
  createdAt: datetime
  modifiedAt: datetime
  events: Event[]
```

### Canonical Agent Taxonomy

```yaml
# Stage Agents (primary workflow)
StageAgents:
  - triage-agent: Categorize, template-match, queue-route
  - plan-agent: Decompose, size, elaborate
  - design-agent: Research, options, decide, ADR
  - dev-agent: TDD implementation
  - qa-agent: Validation, coverage
  - eval-agent: Outcomes assessment

# Support Agents
SupportAgents:
  - work-item-mapper: External system normalization
  - session-logger: Activity capture
  - template-validator: Quality gates

# Future: Orchestration (from Conductor concept)
OrchestratorAgent:
  - conductor: Flow control, WIP limits, anomaly detection
```

### Canonical Workflow

```
                    ┌─────────────────────────────────────┐
                    │         External Systems            │
                    │  (Teamwork, GitHub, Linear, Jira)   │
                    └──────────────┬──────────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────────┐
                    │        work-item-mapper             │
                    │      (Normalize to WorkItem)        │
                    └──────────────┬──────────────────────┘
                                   │
    ┌──────────────────────────────┼──────────────────────────────┐
    │                              │                              │
    ▼                              ▼                              ▼
┌─────────┐                  ┌─────────┐                    ┌─────────┐
│ TRIAGE  │ ───────────────▶ │  PLAN   │ ────────────────▶ │ DESIGN  │
│  Stage  │                  │  Stage  │                    │  Stage  │
└─────────┘                  └─────────┘                    └─────────┘
    │                              │                              │
    ▼                              ▼                              ▼
- Categorize type            - Decompose                   - Research options
- Match template             - Size (appetite)             - Create ADR
- Set urgency/impact         - Add criteria                - Implementation plan
- Route to queue             - Create children
                                                                  │
                                   ┌──────────────────────────────┘
                                   │
                                   ▼
                             ┌─────────┐
                             │ DELIVER │
                             │  Stage  │
                             └─────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    ▼              ▼              ▼
                ┌───────┐    ┌─────────┐    ┌────────┐
                │  DEV  │    │   QA    │    │  EVAL  │
                │ Agent │    │  Agent  │    │ Agent  │
                └───────┘    └─────────┘    └────────┘
                    │              │              │
                    ▼              ▼              ▼
                Implement      Validate      Evaluate
                (TDD)         (Quality)     (Outcomes)
```

---

## Migration Checklist

### Pre-Migration
- [ ] Create `docs/archive/` directory
- [ ] Create `docs/archive/README.md` explaining archive purpose
- [ ] Back up current docs/core/ directory

### Phase 1: Archive
- [ ] Move agenticops-product-plan.md to archive/
- [ ] Move agenticops-kernel.md to archive/
- [ ] Move llm-solutions-in-product-engineering.md to archive/
- [ ] Move agenticops-value-train.md to archive/
- [ ] Move pipeline.md to archive/ (after template extraction)

### Phase 2: Extract
- [ ] Extract agenticops-practices.md content to guides/
- [ ] Extract improving-agent-prompts.md content to guides/
- [ ] Extract pipeline.md templates to templates/discovery/

### Phase 3: Merge
- [ ] Merge work-processing.md state machine into work-system.md
- [ ] Merge agentic-ops-structure.md routing into work-system.md
- [ ] Merge conductor-agent.md into work-system.md (future section)
- [ ] Merge context-management.md into work-system.md

### Phase 4: Update
- [ ] Update work-system-readme.md
- [ ] Update work-system-guide.md
- [ ] Verify all internal links
- [ ] Update slash command references
- [ ] Test all commands still work

### Post-Migration
- [ ] Delete merged source files from core/
- [ ] Commit with clear message explaining consolidation
- [ ] Tag release as v2.0.0 (breaking documentation change)

---

## Appendix: Key Patterns to Preserve

### From agenticops-value-train.md
- Auto-Pilot concept for autonomous task execution
- ticket.yml structure for CI/CD integration
- Mode-based operating contexts
- Pre-commit hooks and CI gates

### From pipeline.md
- Discovery pipeline for research-heavy work
- Artifact templates with YAML front-matter
- SonoSensei example as reference implementation

### From agentic-ops-structure.md
- Conductor control loop (Sense → Analyze → Decide → Act → Learn)
- Deterministic routing with type+capability
- WIP limits and flow policies

### From improving-agent-prompts.md
- Agent contract YAML front-matter pattern
- Three-tier memory (Facts, Logs, Plans)
- Router pattern with confidence thresholds

---

## Next Steps

1. **Review this document** with stakeholders
2. **Decide on migration timeline** (recommend 3 weeks)
3. **Create archive directory** and move documents
4. **Perform merges** incrementally with commits
5. **Update slash commands** if any references change
6. **Tag and release** consolidated v2.0.0

---

*Analysis completed: 2025-12-09*
*Documents reviewed: 14*
*Recommended final count: 4 core + 3 guides + archive*
