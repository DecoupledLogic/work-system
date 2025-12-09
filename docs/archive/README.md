# Archived Documentation

This directory contains historical documentation that has been superseded by the consolidated work-system documentation.

## Why These Documents Were Archived

On 2025-12-09, a comprehensive review of the `docs/core/` directory identified significant redundancy, contradictions, and fragmentation across 14 documents. The consolidation effort reduced the documentation to 4 core canonical documents while preserving historical context.

## Archived Documents

### Vision & Strategy Documents

| Document | Reason for Archive | Key Patterns Preserved |
|----------|-------------------|----------------------|
| `agenticops-product-plan.md` | Describes a separate SaaS commercial product, not the work-system dev tool | AMU pattern, SaaS identity concepts |
| `agenticops-kernel.md` | Strategic planning document, not implementation spec | Strategy/playbook framework |
| `agenticops-value-train.md` | Rich vision document with overlapping concepts | Auto-Pilot, ticket.yml, modes, CI gates |
| `pipeline.md` | Discovery pipeline superseded by 4-stage workflow | Discovery templates extracted to `docs/templates/` |
| `llm-solutions-in-product-engineering.md` | Reference material, not core spec | 5-layer LLM solution hierarchy |

### Future Merge Candidates

These documents contain valuable patterns to be incrementally incorporated into work-system.md:

| Document | Reason for Archive | Key Patterns to Extract |
|----------|-------------------|------------------------|
| `agentic-ops-structure.md` | Agent taxonomy conflicts with work-system agents | Conductor control loop, milestone agents, deterministic routing |
| `work-processing.md` | Detailed state machine for future implementation | 11-state workflow, event model, storage patterns |
| `conductor-agent.md` | Conductor spec for autonomous operation | Control loop (Sense→Analyze→Decide→Act→Learn), WIP policies |
| `context-management.md` | Memory architecture patterns | Vector DB integration, file store patterns |

## Valuable Patterns to Reference

These archived documents contain patterns that may be useful for future enhancements:

### From agenticops-value-train.md
- **Auto-Pilot Agent**: Autonomous task execution with issue selection, branching, CI gates
- **ticket.yml Schema**: Phase-based ticket tracking with checklists and artifacts
- **Mode System**: Operating contexts (/intake, /discover, /scope, /design, /build, /evaluate, /deliver, /operate, /improve)
- **Guard-Rails**: Path protection, single-writer rules, monotonic diff checks

### From pipeline.md
- **Discovery Pipeline**: Capture → Measurement → Observation → Intuition → Theory → Thesis → Use Case → Hypothesis → Baseline → Experiment Design → Discovery Review
- **Artifact Templates**: YAML front-matter with owner, date, version, tags
- **Debt Smells**: Readiness indicators for each stage

### From agenticops-product-plan.md
- **AMU Pattern**: Adapter-Metadata-Usecases architecture
- **SaaS Identity**: JWT-based tenant isolation
- **Credit System**: Usage-based billing model

### From agenticops-kernel.md
- **Strategy Document Structure**: Philosophy, market positioning, value propositions
- **Playbook Pattern**: Step-by-step processes with PDCA feedback
- **Measurement System**: KPIs with planned vs actual tracking

### From agentic-ops-structure.md

- **Conductor Control Loop**: Sense → Analyze → Decide → Act → Learn
- **Milestone Agents**: Opportunity, Discovery, Inception, Elaboration, Construction, Transition, Maintenance
- **Functional Agents**: Analyst, Bookkeeper, Communicator, Designer, DevOps, Engineer, Evaluator, Research, Writer
- **Deterministic Routing**: type+capability based routing table
- **Deliverables Catalog**: Comprehensive list per milestone with owners

### From work-processing.md

- **11-State Workflow**: Created → Ready → Validated → Routed → InProgress → Completed → Reviewed → Evaluated → Approved → Done → Closed
- **Work Order Schema**: JSON schema with actions (produce, evaluate, approve, release, close)
- **Work Item Schema**: Detailed identity, lifecycle, routing, IO, WIP, metrics fields
- **Event Model**: 20+ typed events with policies and actors
- **Storage Layout**: `clients/{client}/{product}/{project}/{funnel}/...` pattern

### From conductor-agent.md

- **Flow Control Policies**: WIP limits, aging WIP detection, bottleneck detection
- **Quality Gates**: Eval score monitoring, quality regression detection
- **Cost Control**: Budget band monitoring, throttling expensive jobs
- **Work Order Format**: Structured YAML format for agent communication

### From context-management.md

- **Vector Database Integration**: Embedding storage, similarity search, metadata filtering
- **File Store Pattern**: Structured directory with YAML front-matter
- **Combined Workflow**: Dynamic context construction with feedback loops

## Migration Reference

See [agenticops-alignment.md](../core/agenticops-alignment.md) for the full analysis that led to this consolidation.

## Restoration

If you need to restore any of these documents to active status:

1. Move the file back to `docs/core/`
2. Update references in other documents
3. Remove from this archive
4. Update the alignment document

---

*Archived: 2025-12-09*
