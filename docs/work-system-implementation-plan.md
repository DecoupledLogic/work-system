# Work System Implementation Plan

This document defines the phased implementation plan to evolve our current Claude Code setup into the target work system defined in `work-system.md`.

## Current State Summary

### What We Have

| Component | Location | Status |
|-----------|----------|--------|
| Task fetching/selection | `~/.claude/agents/task-fetcher.md`, `task-selector.md` | Working |
| Work selection commands | `~/.claude/commands/select-task.md`, `resume.md` | Working |
| Domain-specific workflow | `link-prodsupport/.claude/commands/` (triage, investigate, validate, verify, close) | Working |
| Mode-based dev workflow | `cmds/.claude/commands/` (kick, begin, plan, design, dev, deliver, qa) | Working |
| Target specification | `~/.claude/work-system.md` | Complete |
| Sub-agent guide | `~/.claude/sub-agents-guide.md` | Complete |

### What We Need

| Component | Priority | Complexity |
|-----------|----------|------------|
| Work item normalization layer | High | Medium |
| Stage-based sub-agents | High | High |
| Template system | Medium | Medium |
| Queue management | Medium | Low |
| Session/run logging | Low | Medium |
| Metrics and evaluation | Low | High |

---

## Implementation Phases

### Phase 0: Foundation (Pre-requisite)

**Goal:** Establish shared infrastructure and patterns before building stages.

**Duration:** 1-2 days

#### Deliverables

1. **`~/.claude/agents/work-item-mapper.md`**
   - Maps external task data (Teamwork) to work-system schema
   - Infers Type, WorkType, Urgency, Impact from task fields
   - Returns normalized WorkItem JSON
   - Model: haiku (simple transformation)

2. **`~/.claude/templates/` directory structure**
   ```
   templates/
   ├── README.md              # Template system documentation
   ├── _schema.json           # JSON schema for template validation
   ├── support/               # Support workflow templates
   ├── product/               # Product delivery templates
   └── delivery/              # Technical delivery templates
   ```

3. **`~/.claude/commands/index.yaml`**
   - Stage definitions with transitions
   - Agent mappings per stage
   - Context file requirements

4. **`~/.claude/session/` directory**
   ```
   session/
   ├── active-work.md         # Current work item context
   ├── session-log.md         # Run/action log for current session
   └── .gitignore             # Don't version session state
   ```

#### Acceptance Criteria

- [ ] work-item-mapper agent can transform Teamwork task JSON to WorkItem schema
- [ ] Template directory structure exists with README
- [ ] index.yaml defines at least select, triage, plan stages
- [ ] Session directory exists with initial templates

---

### Phase 1: Triage Stage

**Goal:** Implement the Triage stage from work-system.md as reusable components.

**Duration:** 3-4 days

**Dependencies:** Phase 0 complete

#### Deliverables

1. **`~/.claude/agents/triage-agent.md`**

   Responsibilities (from work-system.md):
   - Categorize work item type (bug, support, feature, etc.)
   - Align with parent work item (Epic/Feature hierarchy)
   - Categorize type of work (map to process template)
   - Categorize impact (high/medium/low)
   - Categorize urgency (critical/now/next/future)

   Input: Normalized WorkItem from work-item-mapper
   Output: Enriched WorkItem with Type, WorkType, Urgency, Impact, ProcessTemplate

   Model: sonnet (requires reasoning about categorization)

2. **`~/.claude/commands/triage.md`** (generalized)

   Thin orchestrator that:
   1. Accepts task ID or raw context
   2. Calls work-item-mapper (if Teamwork task)
   3. Calls triage-agent with normalized work item
   4. Updates Teamwork task with triage results
   5. Routes to appropriate queue

   Should work for both Link support AND general product work.

3. **`~/.claude/templates/support/generic.json`**

   First template implementation:
   ```json
   {
     "templateId": "support/generic",
     "name": "Generic Support Request",
     "appliesTo": ["story"],
     "workType": "support",
     "requiredSections": ["problem", "customer", "resolution"],
     "outputs": [{ "type": "comment", "location": "teamwork" }]
   }
   ```

4. **Migration: Link `/triage` command**

   - Extract domain-specific logic to `link-prodsupport/.claude/agents/link-triage-agent.md`
   - Update `/triage` to call global triage-agent first, then link-specific agent
   - Preserve all existing functionality

#### Acceptance Criteria

- [ ] `/triage TW-12345` works with any Teamwork task
- [ ] Triage-agent correctly categorizes work type and urgency
- [ ] Template is assigned based on detected work type
- [ ] Link-specific triage still works (SQL scripts, schema validation)
- [ ] Teamwork task updated with triage metadata

---

### Phase 2: Plan Stage

**Goal:** Implement the Plan stage for decomposition and sizing.

**Duration:** 3-4 days

**Dependencies:** Phase 1 complete

#### Deliverables

1. **`~/.claude/agents/plan-agent.md`**

   Responsibilities (from work-system.md):
   - Select work item from queue
   - Infer size (Appetite) based on type bounds
   - Split if too large
   - Break down (Epic→Features→Stories→Tasks)
   - Elaborate (fill in type-specific fields)

   Input: Triaged WorkItem
   Output: Updated WorkItem + child WorkItems + PlanDocument (for epics/features)

   Model: sonnet (requires decomposition reasoning)

2. **`~/.claude/commands/plan.md`** (generalized)

   Thin orchestrator that:
   1. Reads triaged work items from queue (via Teamwork)
   2. Calls plan-agent for decomposition
   3. Creates child tasks in Teamwork
   4. Updates parent with children links
   5. Generates PlanDocument for complex items

3. **`~/.claude/templates/product/story.json`**

   Story template with:
   - AcceptanceCriteria (Gherkin format)
   - EstimatedEffort bounds
   - Required breakdown to tasks

4. **Migration: CMDS `/plan` command**

   - Extract reusable logic to global plan-agent
   - Keep CMDS-specific GitHub integration
   - Ensure both Teamwork and GitHub work as task backends

#### Acceptance Criteria

- [ ] `/plan` decomposes a feature into stories
- [ ] Stories have Gherkin acceptance criteria
- [ ] Size bounds enforced (story max 3 days)
- [ ] Child tasks created in Teamwork
- [ ] CMDS workflow still functions with GitHub issues

---

### Phase 3: Design Stage

**Goal:** Implement the Design stage for solution options and architecture decisions.

**Duration:** 3-4 days

**Dependencies:** Phase 2 complete

#### Deliverables

1. **`~/.claude/agents/design-agent.md`**

   Responsibilities (from work-system.md):
   - Initialize design workspace (branch, docs)
   - Research problem space and constraints
   - Produce solution options with tradeoffs
   - Select preferred option with rationale
   - Generate ADR and implementation tasks

   Input: Planned WorkItem (Feature or Story)
   Output: ADR, WorkItemImplementationPlan, WorkItemTestPlan

   Model: sonnet (requires technical reasoning)

2. **`~/.claude/commands/design.md`** (generalized)

   Thin orchestrator that:
   1. Reads planned work item
   2. Creates design branch
   3. Calls design-agent for solution exploration
   4. Creates ADR document
   5. Updates work item with design artifacts

3. **`~/.claude/templates/delivery/adr.md`**

   ADR template skeleton:
   ```markdown
   # ADR-{number}: {title}

   ## Status
   {proposed|accepted|deprecated|superseded}

   ## Context
   {problem_statement}

   ## Decision
   {chosen_option}

   ## Consequences
   {tradeoffs}
   ```

4. **`~/.claude/templates/delivery/implementation-plan.json`**

   Implementation plan template with:
   - Tasks breakdown
   - Dependencies
   - Estimated hours per task

#### Acceptance Criteria

- [ ] `/design` creates design branch
- [ ] Design-agent produces solution options
- [ ] ADR created with decision rationale
- [ ] Implementation tasks generated
- [ ] Test plan generated

---

### Phase 4: Deliver Stage

**Goal:** Implement the Deliver stage for implementation, testing, and deployment.

**Duration:** 4-5 days

**Dependencies:** Phase 3 complete

#### Deliverables

1. **`~/.claude/agents/dev-agent.md`**

   Responsibilities (from work-system.md):
   - Spec: Expand story to implementation spec
   - Implement: Write code/config/content
   - Review: Submit for peer/automated review

   Input: Designed WorkItem with implementation plan
   Output: Commits, branches, PRs

   Model: sonnet (code generation)

2. **`~/.claude/agents/qa-agent.md`**

   Responsibilities:
   - Spec: Define tests from Gherkin criteria
   - Run: Execute automated/manual tests
   - Review: Assess coverage and results

   Input: Implemented WorkItem
   Output: Test results, quality metrics

   Model: haiku (test execution orchestration)

3. **`~/.claude/agents/eval-agent.md`**

   Responsibilities (from work-system.md):
   - Check acceptance criteria met
   - Check alignment with feature vision
   - Record metrics (time to value, defects)
   - Create follow-up work for gaps

   Input: Delivered WorkItem
   Output: ImplementationDocument with plan vs actual

   Model: sonnet (evaluation reasoning)

4. **`~/.claude/commands/deliver.md`** (generalized)

   Orchestrates: dev-agent → qa-agent → eval-agent

5. **Migration: CMDS `/dev`, `/deliver`, `/qa`**

   - Extract reusable patterns to global agents
   - Keep CMDS-specific workflow (TDD, session context)

#### Acceptance Criteria

- [ ] `/deliver` orchestrates full delivery pipeline
- [ ] Dev-agent produces working code
- [ ] QA-agent runs tests and reports results
- [ ] Eval-agent compares plan vs actual
- [ ] ImplementationDocument generated

---

### Phase 5: Session and Run Logging

**Goal:** Capture structured logs of agent activity for analysis and improvement.

**Duration:** 2-3 days

**Dependencies:** Phases 1-4 complete (can run in parallel with Phase 4)

#### Deliverables

1. **`~/.claude/agents/session-logger.md`**

   Lightweight agent that:
   - Generates RunId, SessionId
   - Logs actions with timestamps
   - Captures metrics (duration, tokens, tool calls)
   - Writes to session log file

   Model: haiku

2. **`~/.claude/session/session-log.md` format**

   ```markdown
   # Session: {SessionId}
   Started: {timestamp}
   User: {userId}

   ## Runs

   ### Run: {RunId}
   - Stage: triage
   - WorkItems: [TW-12345]
   - Started: {timestamp}
   - Status: success
   - Actions:
     - [10:30:01] categorize: Detected support request
     - [10:30:05] assign_template: support/generic
     - [10:30:08] route: Added to Now queue
   - Metrics:
     - Duration: 12s
     - TokensIn: 2500
     - TokensOut: 800
   ```

3. **Integration with all stage commands**

   Each command calls session-logger at:
   - Start of run
   - Each significant action
   - End of run

#### Acceptance Criteria

- [ ] Session log captures all runs in a session
- [ ] Actions logged with timestamps
- [ ] Metrics captured (duration, tokens)
- [ ] Log format parseable for analysis

---

### Phase 6: Queue Management

**Goal:** Implement explicit queue visualization and management.

**Duration:** 2-3 days

**Dependencies:** Phase 1 complete (can run in parallel with Phases 2-4)

#### Deliverables

1. **`~/.claude/commands/queue.md`**

   Displays work items by queue:
   ```
   /queue [immediate|todo|backlog|icebox]
   ```

   Shows:
   - Queue contents sorted by priority
   - Work item summaries
   - Age in queue
   - Blocked items

2. **`~/.claude/commands/route.md`**

   Moves work item between queues:
   ```
   /route TW-12345 backlog
   ```

3. **Queue mapping to Teamwork**

   Map urgency to Teamwork tags or custom fields:
   - critical → "Immediate" tag
   - now → "Todo" tag
   - next → "Backlog" tag
   - future → "Icebox" tag

#### Acceptance Criteria

- [ ] `/queue` shows items by urgency lane
- [ ] `/route` moves items between queues
- [ ] Queue state persists in Teamwork

---

### Phase 7: Template Evolution

**Goal:** Implement full template system with versioning and validation.

**Duration:** 3-4 days

**Dependencies:** Phase 1-3 complete

#### Deliverables

1. **Template registry**

   `~/.claude/templates/registry.json`:
   ```json
   {
     "templates": {
       "support/generic": { "version": "1.0.0", "path": "support/generic.json" },
       "product/prd": { "version": "1.1.0", "path": "product/prd/v1.1.0.json" }
     }
   }
   ```

2. **Template validation agent**

   `~/.claude/agents/template-validator.md`:
   - Validates work item outputs against template requirements
   - Reports missing sections
   - Enforces validation rules

3. **Core templates**

   Priority templates to implement:
   - `support/remove-profile.json` (from Link patterns)
   - `support/subscription-change.json`
   - `product/prd.json`
   - `product/feature.json`
   - `product/story.json`
   - `delivery/adr.json`
   - `delivery/bug-fix.json`

4. **Template versioning**

   Directory structure:
   ```
   templates/product/prd/
   ├── v1.0.0.json
   ├── v1.1.0.json
   └── latest -> v1.1.0.json
   ```

#### Acceptance Criteria

- [ ] Templates stored with version numbers
- [ ] Registry tracks available templates
- [ ] Validator checks outputs against templates
- [ ] Work items reference specific template versions

---

## Implementation Order

```
Phase 0 (Foundation)
    │
    ▼
Phase 1 (Triage) ────────────────┐
    │                            │
    ▼                            ▼
Phase 2 (Plan)              Phase 6 (Queues)
    │                            │
    ▼                            │
Phase 3 (Design)                 │
    │                            │
    ▼                            │
Phase 4 (Deliver) ◄──────────────┘
    │
    ├──────────────┐
    ▼              ▼
Phase 5        Phase 7
(Logging)     (Templates)
```

**Critical Path:** 0 → 1 → 2 → 3 → 4

**Parallel Work:**
- Phase 5 (Logging) can start after Phase 1
- Phase 6 (Queues) can start after Phase 1
- Phase 7 (Templates) can start after Phase 3

---

## Migration Strategy

### Principle: Evolve, Don't Replace

1. **Keep existing commands working** throughout migration
2. **Extract reusable logic** to global agents
3. **Thin out commands** to orchestration layers
4. **Add new capabilities** without breaking old ones

### Link Production Support Migration

| Current | Migration | Final State |
|---------|-----------|-------------|
| `/triage` (391 lines) | Extract to triage-agent + link-triage-agent | Thin orchestrator calling agents |
| `/investigate` | Keep domain-specific (SQL focus) | Add session logging |
| `/validate` | Keep domain-specific | Add template validation |
| `/verify` | Keep domain-specific | Add eval-agent integration |
| `/close` | Keep domain-specific | Add metrics capture |

### CMDS Migration

| Current | Migration | Final State |
|---------|-----------|-------------|
| `/kick` | Keep as-is (project setup) | Add template initialization |
| `/begin` | Merge with global `/select-task` | Thin orchestrator |
| `/plan` | Extract to plan-agent | Thin orchestrator |
| `/design` | Extract to design-agent | Thin orchestrator |
| `/dev` | Extract to dev-agent | Thin orchestrator |
| `/deliver` | Extract to delivery pipeline | Thin orchestrator |
| `/qa` | Extract to qa-agent | Thin orchestrator |

---

## Success Metrics

### Phase Completion Criteria

| Phase | Success Metric |
|-------|---------------|
| 0 | All foundation files exist, work-item-mapper transforms sample task |
| 1 | `/triage` works for both Link and general tasks |
| 2 | Feature can be decomposed into sized stories |
| 3 | Design produces ADR and implementation plan |
| 4 | Full delivery pipeline executes end-to-end |
| 5 | Session log captures 100% of runs and actions |
| 6 | Queue commands show accurate work distribution |
| 7 | 5+ templates in use with validation |

### Overall Success

The work system is complete when:

1. **Any work item** can flow through Triage → Plan → Design → Deliver
2. **Templates drive behavior** for different work types
3. **Agents are reusable** across projects and domains
4. **Session state persists** across context boundaries
5. **Metrics captured** for plan vs actual analysis

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Breaking existing workflows | Parallel implementation, feature flags |
| Agent context limits | Keep agents focused, use haiku for simple tasks |
| Teamwork API rate limits | Caching in task-fetcher, pagination safety limits |
| Template complexity | Start simple, iterate based on usage |
| Session state corruption | Validation on read, backup before write |

---

## Next Actions

1. **Create Phase 0 deliverables** (this week)
   - [ ] `~/.claude/agents/work-item-mapper.md`
   - [ ] `~/.claude/templates/README.md` and directory structure
   - [ ] `~/.claude/commands/index.yaml`
   - [ ] `~/.claude/session/` directory with templates

2. **Review with stakeholders** (before Phase 1)
   - Validate triage-agent design
   - Confirm template structure
   - Agree on Teamwork field mappings

3. **Begin Phase 1** (after Phase 0 acceptance)
   - Start with triage-agent
   - Migrate Link /triage incrementally

---

## Progress Tracking

### Changelog

Track what was completed and when. Update this section after each work session.

| Date | Phase | What Was Done | Artifacts Created |
|------|-------|---------------|-------------------|
| 2024-12-07 | - | Created implementation plan | `work-system-implementation-plan.md` |
| 2024-12-07 | 0 | Completed Phase 0 Foundation | See Phase 0 deliverables below |
| 2024-12-07 | 1 | Completed Phase 1 Triage Stage | See Phase 1 deliverables below |
| 2024-12-07 | 2 | Completed Phase 2 Plan Stage | See Phase 2 deliverables below |
| 2024-12-07 | 3 | Completed Phase 3 Design Stage | See Phase 3 deliverables below |
| 2024-12-07 | 4 | Completed Phase 4 Deliver Stage | See Phase 4 deliverables below |
| 2024-12-07 | 5 | Completed Phase 5 Session Logging | See Phase 5 deliverables below |
| 2024-12-07 | 6 | Completed Phase 6 Queue Management | See Phase 6 deliverables below |
| 2024-12-07 | 7 | Completed Phase 7 Template Evolution | See Phase 7 deliverables below |
| 2024-12-08 | 8 | Completed Phase 8 Domain Architecture | See Phase 8 deliverables below |
| 2024-12-08 | 9 | Workflow-Aggregate Integration | Updated /triage, /plan, /design, /deliver |
| | | | |

### Phase Status

| Phase | Status | Started | Completed | Notes |
|-------|--------|---------|-----------|-------|
| 0 - Foundation | Complete | 2024-12-07 | 2024-12-07 | All deliverables created |
| 1 - Triage | Complete | 2024-12-07 | 2024-12-07 | Agents and templates created, Link migration documented |
| 2 - Plan | Complete | 2024-12-07 | 2024-12-07 | Agent, command, template created, CMDS migration documented |
| 3 - Design | Complete | 2024-12-07 | 2024-12-07 | Agent, command, templates created |
| 4 - Deliver | Complete | 2024-12-07 | 2024-12-07 | 3 agents, command, migration doc created |
| 5 - Logging | Complete | 2024-12-07 | 2024-12-07 | Agent, log format, integration guide created |
| 6 - Queues | Complete | 2024-12-07 | 2024-12-07 | /queue, /route commands, tag mapping documented |
| 7 - Templates | Complete | 2024-12-07 | 2024-12-07 | Registry, validator, 9 templates, versioning |
| 8 - Domain Architecture | Complete | 2024-12-08 | 2024-12-08 | Schemas, aggregates, natural language docs |

### Deliverables Checklist

#### Phase 0: Foundation
- [x] `~/.claude/agents/work-item-mapper.md`
- [x] `~/.claude/templates/README.md`
- [x] `~/.claude/templates/_schema.json`
- [x] `~/.claude/templates/support/` directory
- [x] `~/.claude/templates/product/` directory
- [x] `~/.claude/templates/delivery/` directory
- [x] `~/.claude/commands/index.yaml`
- [x] `~/.claude/session/active-work.md`
- [x] `~/.claude/session/session-log.md`
- [x] `~/.claude/session/.gitignore`

#### Phase 1: Triage
- [x] `~/.claude/agents/triage-agent.md`
- [x] `~/.claude/commands/triage.md` (generalized)
- [x] `~/.claude/templates/support/generic.json`
- [x] `link-prodsupport/.claude/agents/link-triage-agent.md`
- [x] Link `/triage` migration documented (TRIAGE-MIGRATION.md)

#### Phase 2: Plan
- [x] `~/.claude/agents/plan-agent.md`
- [x] `~/.claude/commands/plan.md` (generalized)
- [x] `~/.claude/templates/product/story.json`
- [x] CMDS `/plan` migration documented (PLAN-MIGRATION.md)

#### Phase 3: Design
- [x] `~/.claude/agents/design-agent.md`
- [x] `~/.claude/commands/design.md` (generalized)
- [x] `~/.claude/templates/delivery/adr.md`
- [x] `~/.claude/templates/delivery/implementation-plan.json`

#### Phase 4: Deliver
- [x] `~/.claude/agents/dev-agent.md`
- [x] `~/.claude/agents/qa-agent.md`
- [x] `~/.claude/agents/eval-agent.md`
- [x] `~/.claude/commands/deliver.md` (generalized)
- [x] CMDS `/dev`, `/deliver`, `/qa` migration documented (DELIVER-MIGRATION.md)

#### Phase 5: Logging
- [x] `~/.claude/agents/session-logger.md`
- [x] Session log format documented (`~/.claude/session/session-log.md`)
- [x] Integration guide created (`~/.claude/session/logging-guide.md`)

#### Phase 6: Queues
- [x] `~/.claude/commands/queue.md`
- [x] `~/.claude/commands/route.md`
- [x] `~/.claude/work-managers/README.md` (work manager abstraction)
- [x] `~/.claude/work-managers/queue-store.md` (local queue storage spec)
- [x] `~/.claude/work-managers/work-manager.schema.yaml` (configuration schema)
- [x] `~/.claude/session/queues.json` (queue data store)

#### Phase 7: Templates
- [x] `~/.claude/templates/registry.json`
- [x] `~/.claude/agents/template-validator.md`
- [x] `support/remove-profile.json`
- [x] `support/subscription-change.json`
- [x] `product/prd.json`
- [x] `product/feature.json`
- [x] `product/story/v1.0.0.json` (versioned)
- [x] `delivery/adr.json`
- [x] `delivery/bug-fix.json`
- [x] Template versioning implemented (`versioning.md`)

#### Phase 8: Domain Architecture

- [x] `schema/README.md`
- [x] `schema/aggregates.md`
- [x] `schema/work-item.schema.md`
- [x] `schema/project.schema.md`
- [x] `schema/agent.schema.md`
- [x] `schema/queue.schema.md`
- [x] `schema/process-template.schema.md`
- [x] `schema/external-system.schema.md`
- [x] `commands/domain/README.md`
- [x] `commands/domain/work-item.md`
- [x] `commands/domain/project.md`
- [x] `commands/domain/agent.md`
- [x] `commands/domain/queue.md`
- [x] `docs/programming-in-natural-language.md`
- [x] `docs/domain-commands-guide.md`

---

## Session Notes

Use this section to capture notes, decisions, and blockers during implementation sessions.

### Session: 2024-12-07

**Focus:** Initial planning and documentation

**Decisions Made:**
- Implementation plan structure finalized
- Phase 0 prioritized as foundation
- Parallel tracks identified (Phases 5, 6, 7)

**Blockers:** None

**Next Session:**
- Begin Phase 0 deliverables
- Create work-item-mapper agent

### Session: 2024-12-07 (continued)

**Focus:** Phase 0 Foundation implementation

**Completed:**
- Created `work-item-mapper.md` agent with full mapping rules
- Created templates directory structure (support/, product/, delivery/)
- Created `templates/README.md` with documentation
- Created `templates/_schema.json` with JSON schema for validation
- Created `commands/index.yaml` with stage/agent definitions
- Created `session/` directory with active-work.md, session-log.md, .gitignore
- Created `/work-status` command for progress tracking

**Decisions Made:**
- work-item-mapper uses haiku (simple transformation)
- Templates use JSON schema for validation
- index.yaml defines stages, queues, agents, and transitions
- Session files are gitignored (ephemeral per-user state)

**Blockers:** None

**Next Session:**
- Begin Phase 1: Triage Stage
- Create triage-agent.md
- Create generalized /triage command

### Session: 2024-12-07 (Phase 1)

**Focus:** Phase 1 Triage Stage implementation

**Completed:**
- Created `triage-agent.md` with full categorization logic
  - Type, WorkType, Urgency, Impact inference
  - Template matching patterns
  - Queue routing decisions
  - Parent alignment logic
- Created generalized `/triage` command
  - Input parsing (Teamwork ID, raw context, JSON)
  - Work-item-mapper integration
  - Triage-agent orchestration
  - Session state updates
  - Teamwork comment posting
  - Domain-specific agent delegation
- Created `templates/support/generic.json`
  - Schema-compliant template
  - Required/recommended sections
  - Validation rules
  - Stage configuration
- Created `link-prodsupport/.claude/agents/link-triage-agent.md`
  - Link-specific issue type detection
  - Entity extraction patterns
  - SQL script generation patterns
  - Schema validation integration
- Created `link-prodsupport/.claude/TRIAGE-MIGRATION.md`
  - Documents migration path from current to global system
  - Phase 1: Parallel operation (current)
  - Phase 2: Gradual integration (future)
  - Phase 3: Full integration (future)

**Decisions Made:**
- triage-agent uses sonnet (requires reasoning for categorization)
- Link migration is gradual - existing /triage continues working
- link-triage-agent handles SQL generation, delegates categorization to global
- Template matching follows priority: exact pattern > category > type > generic
- Queue routing maps directly from urgency (critical→immediate, now→todo, etc.)

**Blockers:** None

**Next Session:**
- Begin Phase 2: Plan Stage
- Create plan-agent.md
- Create generalized /plan command

### Session: 2024-12-07 (Phase 2)

**Focus:** Phase 2 Plan Stage implementation

**Completed:**
- Created `plan-agent.md` with full planning logic
  - Size inference with type bounds (epic: cycles, feature: weeks, story: days, task: hours)
  - Splitting rules when work exceeds bounds
  - Decomposition patterns (epic→features→stories→tasks)
  - Elaboration requirements (Gherkin acceptance criteria, estimates)
  - Priority scoring algorithm
  - PlanDocument generation for epics/features
- Created generalized `/plan` command
  - Input parsing (Teamwork ID, JSON, session context)
  - Triage verification before planning
  - Plan-agent orchestration
  - Child work item creation in Teamwork
  - Session state updates
  - Routing to next stage (design or deliver)
- Created `templates/product/story.json`
  - INVEST criteria encoded
  - Gherkin acceptance criteria format
  - Task breakdown structure
  - Sizing guidance (1-3 days)
  - Split triggers defined
- Created `cmds/.claude/PLAN-MIGRATION.md`
  - Maps CMDS concepts to work system (PRD→Epic, CRD→Story)
  - Documents mode-based workflow preservation
  - Outlines GitHub integration approach
  - Defines migration phases

**Decisions Made:**
- plan-agent uses sonnet (requires reasoning for decomposition)
- Acceptance criteria must use Gherkin format (Given/When/Then)
- Stories max 3 days, tasks max 8 hours (enforced bounds)
- PlanDocument generated for epics and features (not stories/tasks)
- CMDS migration is gradual - mode-based workflow preserved

**Blockers:** None

**Next Session:**
- Begin Phase 3: Design Stage
- Create design-agent.md
- Create generalized /design command
- Create delivery/adr.md template

---

### Session: 2024-12-07 (Phase 3)

**Focus:** Phase 3 Design Stage implementation

**Completed:**
- Created `design-agent.md` with full design logic
  - Solution options generation (2-4 options required)
  - Option evaluation criteria and selection
  - ADR creation for architectural decisions
  - Implementation plan generation with task breakdown
  - Test plan generation with coverage strategy
  - Routing logic (design complete → deliver, scope issue → plan)
- Created generalized `/design` command
  - Input parsing (Teamwork ID, JSON, session context)
  - Plan verification before designing
  - Branch creation for design workspace
  - Design-agent orchestration
  - ADR document creation
  - Implementation and test plan generation
  - Session state updates
  - Teamwork comment posting
  - CMDS integration approach documented
- Created `templates/delivery/adr.md`
  - Standard ADR format (Status, Context, Decision, Consequences)
  - Alternatives considered section
  - Template usage notes
  - Naming conventions
- Created `templates/delivery/implementation-plan.json`
  - Schema-compliant template
  - Task breakdown with acceptance criteria
  - Dependencies tracking
  - Risks and rollout strategy sections
  - Success metrics definition

**Decisions Made:**
- design-agent uses sonnet (requires reasoning for solution evaluation)
- At least 2 solution options required (never single option)
- ADR created for architectural decisions (can skip if following existing pattern)
- Implementation plan tasks max 8 hours each
- Test plan covers unit, integration, e2e, and security levels

**Blockers:** None

**Next Session:**
- Begin Phase 4: Deliver Stage
- Create dev-agent.md, qa-agent.md, eval-agent.md
- Create generalized /deliver command

---

### Session: 2024-12-07 (Phase 4)

**Focus:** Phase 4 Deliver Stage implementation

**Completed:**
- Created `dev-agent.md` with TDD implementation logic
  - Spec phase: Expand acceptance criteria to tests
  - Red phase: Write failing tests first
  - Green phase: Minimum implementation to pass
  - Refactor phase: Clean up while tests green
  - Commit management with proper attribution
  - Branch management patterns
  - Error handling for blockers
- Created `qa-agent.md` with validation logic
  - Criteria mapping to tests
  - Test execution at all levels (unit, integration, e2e)
  - Coverage analysis with thresholds
  - Quality score calculation
  - Issue identification and severity
  - Gherkin test generation
- Created `eval-agent.md` with evaluation logic
  - Criteria verification with evidence
  - Vision alignment assessment
  - Plan vs actual comparison (time, scope, approach)
  - Metrics recording
  - Implementation document generation
  - Follow-up item identification
  - Learnings capture for improvement
- Created generalized `/deliver` command
  - Full pipeline orchestration (dev → qa → eval)
  - Branch and PR management
  - Phase resumption support
  - CMDS integration approach
  - Pipeline visualization
- Created `cmds/.claude/DELIVER-MIGRATION.md`
  - Maps CMDS modes to global agents
  - Documents checklist integration approach
  - Preserves mode-based UX
  - Outlines phased migration

**Decisions Made:**
- dev-agent uses sonnet (requires reasoning for implementation)
- qa-agent uses haiku (test execution is straightforward)
- eval-agent uses sonnet (requires reasoning for evaluation)
- Quality score: 40% criteria + 30% tests + 20% coverage + 10% lint
- Quality gate: ≥80 score, 100% criteria, ≥80% coverage

**Blockers:** None

**Next Session:**
- Phase 6: Queue Management (optional)
- Phase 7: Template Evolution (optional)

---

### Session: 2024-12-07 (Phase 5)

**Focus:** Phase 5 Session and Run Logging implementation

**Completed:**
- Created `session-logger.md` agent with full logging logic
  - Session ID and Run ID generation formats
  - Start/end run logging actions
  - Action logging with timestamps
  - Metrics capture (duration, tokens, tool calls)
  - Standard action types by stage
  - Error logging format
  - Log rotation guidelines
- Updated `session-log.md` format
  - Run entry template
  - Metrics table structure
  - Session summary section
  - Version tracking
- Created `logging-guide.md` integration documentation
  - Integration patterns for each stage command
  - Action type reference
  - Metrics requirements by stage
  - Error logging guidelines
  - Analysis query patterns

**Decisions Made:**
- session-logger uses haiku (lightweight operations)
- Session ID format: `ses-{YYYYMMDD}-{HHMMSS}`
- Run ID format: `run-{YYYYMMDD}-{HHMMSS}-{stage}`
- Standard action types defined for consistency
- Log rotation at 10,000 lines
- Integration via guidance rather than modifying commands directly

**Blockers:** None

**Next Session:**
- Phase 6: Queue Management (optional)
- Phase 7: Template Evolution (optional)

---

### Session: 2024-12-07 (Phase 6)

**Focus:** Phase 6 Queue Management implementation

**Completed:**
- Created work manager abstraction layer (`~/.claude/work-managers/`)
  - README.md with architecture overview
  - Adapter pattern for Teamwork, GitHub, Linear, Jira, Local
  - Common WorkItem schema across all managers
  - Work item ID format: `TW-*`, `GH-owner/repo#*`, `LIN-*`, `JIRA-*`, `LOCAL-*`
- Created local queue storage (`~/.claude/work-managers/queue-store.md`)
  - JSON-based storage in `~/.claude/session/queues.json`
  - Assignment tracking with timestamps
  - Full history of queue changes
  - Works independently of external systems
- Created configuration schema (`work-manager.schema.yaml`)
  - Per-project `.claude/work-manager.yaml` configuration
  - Support for all manager types
  - Queue sync options (local or native)
  - Label/tag mapping for native sync
- Updated `/queue` command for local tracking
  - Reads from local queue store
  - Enriches with data from appropriate manager
  - Supports `--manager` filter
- Updated `/route` command for local tracking
  - Updates local queue store
  - Tracks history with reasons
  - Optional comment to external system

**Decisions Made:**
- **Local-first queues**: Queue assignments stored locally, not in external systems
  - Works across any manager (Teamwork, GitHub, Linear, etc.)
  - No API/permission requirements
  - Optional sync to external labels/tags
- **Work item ID prefixes**: Each manager has a unique prefix for identification
- **Priority score formula**: 40% impact + 40% urgency + 20% age
- **Queue SLAs**: Immediate=same day, Todo=current cycle, Backlog=next cycle, Icebox=none
- **Configuration per-project**: Each repo can specify its work manager in `.claude/work-manager.yaml`

**Blockers:** None

**ADRs Created:**
- ADR-0001: Work Manager Abstraction Layer
- ADR-0002: Local-First Session State
- ADR-0003: Stage-Based Workflow with Sub-Agents

See: `~/.claude/docs/adrs/` for all architecture decision records.

**Next Session:**
- Phase 7: Template Evolution (optional)

---

### Session: 2024-12-07 (Phase 7)

**Focus:** Phase 7 Template Evolution implementation

**Completed:**
- Created `templates/registry.json`
  - Index of all 9 templates
  - Category groupings (support, product, delivery)
  - Default template mapping by work type
  - Pattern matching rules for template selection
- Created `agents/template-validator.md`
  - Section validation (required/recommended)
  - Output validation
  - Rule engine with natural language patterns
  - Quality scoring algorithm (base 100, deductions)
  - Stage-specific validation
  - Error message formatting
- Created support templates:
  - `support/remove-profile.json` - GDPR/CCPA compliance, data inventory, removal verification
  - `support/subscription-change.json` - Upgrade/downgrade, billing, proration
- Created product templates:
  - `product/prd.json` - Epic-level PRD with goals, scope, requirements, user stories
  - `product/feature.json` - Feature spec with story breakdown, acceptance criteria
- Created delivery templates:
  - `delivery/adr.json` - ADR with alternatives, consequences, status tracking
  - `delivery/bug-fix.json` - Bug investigation, root cause, fix, verification
- Implemented template versioning:
  - Created `versioning.md` documentation
  - Set up versioned directory structure for story template
  - Created `product/story/v1.0.0.json` and `latest.json` symlink
  - Updated registry with version tracking

**Decisions Made:**
- template-validator uses haiku (rule checking is straightforward)
- Semantic versioning for templates (MAJOR.MINOR.PATCH)
- Flat structure for simple templates, versioned for complex
- Work items can pin versions or use latest
- Registry tracks available versions per template
- Quality score: Base 100 with deductions for missing/failed items

**Template Summary:**
| Template | Work Type | Complexity | Versioned |
|----------|-----------|------------|-----------|
| support/generic | support | low | no |
| support/remove-profile | support | medium | no |
| support/subscription-change | support | medium | no |
| product/prd | product_delivery | high | no |
| product/feature | product_delivery | medium | no |
| product/story | product_delivery | low | yes |
| delivery/adr | product_delivery | medium | no |
| delivery/bug-fix | bug_fix | medium | no |
| delivery/implementation-plan | product_delivery | medium | no |

**Blockers:** None

**Work System Complete:**
All 7 phases (0-7) are now complete. The work system includes:
- Stage-based workflow (Triage → Plan → Design → Deliver)
- 7 specialized agents
- 9 process templates with validation
- Local-first queue management with work manager abstraction
- Session logging for analytics
- Template versioning for evolution

---

### Session: 2024-12-08 (Domain Architecture)

**Focus:** Domain-Driven Design, Schema Layer, Natural Language Interface

**Completed:**

**Schema Layer (`schema/`):**

- Created `work-item.schema.md` - Normalized work item with type hierarchy (epic→feature→story→task)
- Created `project.schema.md` - Project container with team membership
- Created `agent.schema.md` - Human, AI, and automation agents
- Created `queue.schema.md` - Urgency queues with SLA tracking
- Created `process-template.schema.md` - Workflow stage definitions
- Created `external-system.schema.md` - Adapter layer for Teamwork, GitHub, Linear, JIRA
- Created `aggregates.md` - DDD aggregate patterns and command response format
- Created `schema/README.md` - Architecture overview and migration path

**Domain Commands (`commands/domain/`):**

- Created `/work-item` aggregate command - Full CRUD, assignment, workflow, collaboration
- Created `/project` aggregate command - Project management and team membership
- Created `/agent` aggregate command - Agent queries and status management
- Created `/queue` aggregate command - Queue visualization and statistics
- Created `commands/domain/README.md` - Natural language interface documentation

**Documentation (`docs/`):**

- Created `programming-in-natural-language.md` - True natural language vs DSL
- Created `domain-commands-guide.md` - Comprehensive command reference
- Updated `docs/README.md` with new domain architecture section

#### Key Insight: True Natural Language

We realized the difference between DSL and natural language:

```bash
# This is DSL (readable, but still programmer syntax)
/work-item assign WI-042 @cbryant

# This is natural language (what humans actually say)
give the login bug to charles, it's urgent
```

True natural language means:

- **Your vocabulary** - "issue" not "work-item", "charles" not "@cbryant"
- **Your context** - "the login bug" not "WI-042"
- **Your flow** - conversation, not commands
- **Your intent** - "it's urgent" not "--queue urgent"

The AI acts as translator between human language and system operations.

**Architecture Evolved:**

```text
┌─────────────────────────────────────────────────────────────────┐
│                     Human Language                              │
│        "give the login bug to charles, it's urgent"            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     AI Understanding                            │
│  Resolves: "login bug" → #42, "charles" → Charles Bryant       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Domain Aggregates                           │
│  /work-item  /project  /agent  /queue                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Domain Schemas                              │
│  WorkItem, Project, Agent, Queue, ProcessTemplate              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     External Adapters                           │
│  Teamwork, GitHub, Linear, JIRA, Internal                      │
└─────────────────────────────────────────────────────────────────┘
```

**Decisions Made:**

- Domain schemas abstract all external systems (Teamwork, GitHub, Linear, JIRA)
- Aggregate commands provide structured interface (DSL layer)
- Natural language interface sits above aggregates (AI translates)
- External system adapters handle bidirectional sync
- Work item types: epic, feature, story, task, bug, spike
- Urgency queues: immediate, urgent, standard, deferred

**Files Created:**

```text
schema/
├── README.md
├── aggregates.md
├── work-item.schema.md
├── project.schema.md
├── agent.schema.md
├── queue.schema.md
├── process-template.schema.md
└── external-system.schema.md

commands/domain/
├── README.md
├── work-item.md
├── project.md
├── agent.md
└── queue.md

docs/
├── programming-in-natural-language.md
└── domain-commands-guide.md
```

**Blockers:** None

**Next Steps:**

- Update workflow commands (/triage, /plan, /design, /deliver) to use domain aggregates
- Consider implementing natural language resolution layer
- Define ubiquitous language for the team (issue vs work-item, etc.)

---

## Phase 8: Domain Architecture (New)

**Goal:** Establish domain-driven design with normalized schemas and aggregate commands.

**Status:** Complete

**Duration:** 1 day

### Phase 8 Deliverables

1. **Schema Layer** - Normalized domain objects
   - WorkItem schema with type hierarchy
   - Project schema with team membership
   - Agent schema for humans, AI, automation
   - Queue schema with SLA configuration
   - ProcessTemplate schema for workflows
   - ExternalSystem schema for adapters

2. **Aggregate Commands** - Domain operations
   - `/work-item` - Full work item management
   - `/project` - Project management
   - `/agent` - Agent queries and status
   - `/queue` - Queue visualization

3. **Natural Language Documentation**
   - Philosophy document explaining true natural language
   - Comprehensive command guide

### Phase 8 Acceptance Criteria

- [x] All core schemas documented with YAML definitions
- [x] Aggregate commands cover all domain operations
- [x] External system abstraction supports multiple backends
- [x] Documentation distinguishes DSL from natural language

---

*Last Updated: 2024-12-08*
*Status: Phase 8 Complete - Domain Architecture Established*
