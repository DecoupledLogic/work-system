---
description: Design a work item - explore solutions, make decisions, generate implementation plans
allowedTools:
  - Read
  - Write
  - Edit
  - Task
  - Bash
  - Glob
  - Grep
  - SlashCommand
---

You are the Design Orchestrator. Your job is to coordinate the design process by calling specialized agents and using **domain aggregates** to manage work items.

## Domain Integration

This command uses the WorkItem aggregate (`/domain/work-item`) as the abstraction layer for all work item operations.

**Key Aggregate Commands Used:**

- `/work-item get <id>` - Fetch work item (by internal ID or `--external`)
- `/work-item update <id>` - Update with design results (status, metadata)
- `/work-item transition <id> deliver` - Move to delivery stage
- `/work-item comment <id> "message"` - Add design comment (auto-syncs)

## Purpose

Design moves work items from "what we are doing" (planned) to "how we will do it" (designed). This involves:
- Researching problem space and constraints
- Exploring solution options with tradeoffs
- Making and documenting architecture decisions
- Generating implementation and test plans
- Routing to delivery stage

## Usage

```
/design <input>
```

**Input formats:**
- Teamwork task ID: `/design TW-26134585` or `/design 26134585`
- Work item JSON: `/design {"id": "...", "type": "feature", ...}`
- Current work: `/design` (uses active work from session)

## Process

### Step 1: Identify Input (via Domain Aggregate)

Determine what to design:

**If work item ID provided (WI-xxx or external reference):**

```bash
# Internal ID
/work-item get WI-2024-042

# External reference
/work-item get --external teamwork:26134585
```

- Check if already planned (status = planned, has appetite)
- If not planned, run `/plan` first

**If no input provided:**

- Read `~/.claude/session/active-work.md`
- Use the current work item from session
- Verify it's in "plan" complete or "design" stage

**If JSON provided:**

- Parse directly
- Validate required fields (id, name, type, appetite)

### Step 2: Verify Plan Status

Before designing, confirm planning is complete:

```
Required for design:
- type: feature | story (epics don't need design, tasks go straight to deliver)
- appetite: set with unit and value
- acceptanceCriteria: at least 2 for stories
- children: defined if feature
```

If planning incomplete:
```
Work item TW-12345 needs planning before design.
Run `/plan TW-12345` first.
```

### Step 3: Determine Design Scope

Based on work item type:

| Type | Design Action |
|------|---------------|
| Epic | Route children to design (epic itself doesn't need design) |
| Feature | Full design: options, ADR, implementation plan |
| Story | Light design: approach, tasks, test plan (skip ADR if following existing pattern) |
| Task | No design needed - route to deliver |

### Step 4: Create Design Branch

Initialize design workspace:

```bash
# Create design branch
/git-checkout design/TW-{id}-{slug} --create

# Create workspace directory (if project uses docs/)
mkdir -p docs/design/TW-{id}
```

### Step 5: Call Design Agent

Use Task tool to invoke design-agent:

```
Prompt for design-agent:
You are the design-agent. Read ~/.claude/agents/design-agent.md for your instructions.

Design this work item following the process defined in the agent definition.
Return the full designResult JSON including:
- Updated workItem with status
- solutionOptions array with pros/cons
- selectedOption with rationale
- adr info (created, path, title)
- implementationPlan with tasks
- testPlan with strategy
- routing decisions

Input WorkItem:
[WorkItem JSON]

Context:
- Project: [project name]
- Repo path: [repo root]
- Existing patterns: [detected patterns from codebase]
- Constraints: [known constraints]
```

### Step 6: Generate Design Documents

Based on work item type, generate appropriate documents using `/doc-write`:

**For Stories:**

```bash
/doc-write spec --work-item {workItemId}
```

This generates:

- User story format
- Technical approach
- API changes
- Data changes
- Testing notes

**For Features with Significant Architecture:**

```bash
/doc-write architecture-blueprint --work-item {workItemId}
```

This generates:

- System overview and goals
- Component breakdown
- Core design principles
- Integration design
- Event contracts and APIs
- Migration strategy

**For All Features/Stories - Implementation Plan:**

```bash
/doc-write impl-plan --work-item {workItemId}
```

This generates:

- Work item overview and ADR reference
- Task breakdown with estimates
- Dependencies between tasks
- Technical notes per task

**For All Features/Stories - Test Plan:**

```bash
/doc-write test-plan --work-item {workItemId}
```

This generates:

- Coverage matrix (unit, integration, E2E)
- Test cases from acceptance criteria
- Expected outcomes per criterion

### Step 7: Generate ADR (if architectural decision made)

When the design involves a significant architectural decision, generate an ADR:

```bash
/doc-write adr --work-item {workItemId} --title "Use JWT for authentication"
```

This generates:

- Context explaining why decision was needed
- The decision made
- Positive and negative consequences
- Alternatives considered

**ADR triggers:**

- New technology or framework choice
- Significant pattern change
- Integration approach decision
- Data model restructuring
- Security or performance tradeoff

**Skip ADR when:**

- Following existing established patterns
- Simple CRUD operations
- Minor refactoring within existing architecture

### Step 8: Update Work Item (via Aggregate)

Post design summary using aggregate commands:

1. **Update work item with design results:**

   ```bash
   /work-item update WI-2024-042 --status designed
   ```

2. **Post design comment (auto-syncs to external system):**

   ```bash
   /work-item comment WI-2024-042 "Design Complete

   **Selected Approach:** {selectedOption.name}
   **ADR:** ADR-{number} - {adr.title}

   **Implementation Plan:**
   {taskCount} tasks, {totalHours} hours estimated

   **Key Decisions:**
   - {decision1}
   - {decision2}

   **Test Strategy:**
   - Unit: {unit approach}
   - Integration: {integration approach}
   - E2E: {e2e approach}

   **Design Branch:** design/WI-2024-042-{slug}

   🤖 Submitted by George with love ♥"
   ```

The `/work-item comment` command automatically syncs to the external system (Teamwork, GitHub, etc.).

### Step 9: Update Session State

Update active work context:

1. **Write to active-work.md:**
   ```markdown
   ## Current Work Item

   **Work Item ID:** TW-26134585
   **Name:** User authentication system
   **Type:** feature
   **Stage:** design
   **Status:** completed

   ### Design Summary
   - **Selected Option:** JWT with refresh tokens
   - **ADR:** ADR-0042
   - **Branch:** design/TW-26134585-auth-system

   ### Artifacts
   - ADR: docs/architecture/adr/ADR-0042-authentication-approach.md
   - Implementation Plan: docs/plans/TW-26134585-implementation.md
   - Test Plan: docs/plans/TW-26134585-test-plan.md
   ```

### Step 10: Transition to Next Stage (via Aggregate)

Based on design results, transition using the aggregate:

**If design complete:**

```bash
/work-item transition WI-2024-042 deliver
```

Output:
```
Design complete. Ready for implementation.
Run `/deliver WI-2024-042` to begin development.
```

**If design reveals scope issue:**

```bash
/work-item transition WI-2024-042 plan
/work-item comment WI-2024-042 "Design reveals scope exceeds appetite. Re-planning required."
```

Output:
```
Design reveals scope larger than appetite.

Original estimate: 2 weeks
Design estimate: 4+ weeks

Recommendation: Split into:
1. Core Auth (MVP) - 2 weeks
2. Advanced Auth Features - 2 weeks

Run `/plan WI-2024-042` to re-plan with split.
```

**If awaiting stakeholder input:**
```
Design requires stakeholder decision.

Options presented:
1. JWT with refresh tokens (recommended)
2. Session-based with Redis

Awaiting input on:
- Redis infrastructure availability
- Team expertise preferences

Reply with selected option to continue.
```

## Output Format

After design completes, provide summary:

```
## Design Complete: TW-26134585

### Work Item
| Field | Value |
|-------|-------|
| Name | User authentication system |
| Type | feature |
| Selected Approach | JWT with refresh tokens |
| Status | designed |

### Artifacts Created
| Artifact | Location |
|----------|----------|
| ADR | docs/architecture/adr/ADR-0042-authentication-approach.md |
| Implementation Plan | docs/plans/TW-26134585-implementation.md |
| Test Plan | docs/plans/TW-26134585-test-plan.md |
| Design Branch | design/TW-26134585-auth-system |

### Options Evaluated
| Option | Effort | Risk | Selected |
|--------|--------|------|----------|
| JWT with refresh tokens | Medium | Low | ✓ |
| Session-based with Redis | Medium | Low | |

### Implementation Tasks
| # | Task | Estimate |
|---|------|----------|
| 1 | Create JWT token service | 4h |
| 2 | Implement login endpoint | 3h |
| 3 | Add OAuth providers | 6h |

**Total Estimate:** 13 hours

### Next Steps
Run `/deliver TW-26134585` to begin implementation.

---
*Session: ~/.claude/session/active-work.md updated*
*Teamwork: Comment posted, progress updated*
```

## Error Handling

### Planning Not Complete
```
Work item TW-12345 needs planning before design.

Missing:
- appetite: not set
- acceptance criteria: none defined

Run `/plan TW-12345` first.
```

### Scope Exceeds Appetite
```
Design reveals work exceeds appetite.

Appetite: 2 weeks
Estimated: 4 weeks

Options:
1. Split into smaller features (recommended)
2. Increase appetite (requires re-planning)
3. Reduce scope (cut features)

Run `/plan TW-12345 --split` to decompose.
```

### No Clear Solution
```
Design could not identify clear solution.

Challenges:
- {challenge1}
- {challenge2}

Recommendations:
1. Consult with domain expert
2. Time-boxed spike to explore options
3. Defer pending more information

Creating spike task for exploration...
```

### Git Branch Error
```
Could not create design branch.

Error: Branch design/TW-12345-auth already exists

Options:
1. Continue on existing branch: git checkout design/TW-12345-auth
2. Reset branch: git branch -D design/TW-12345-auth && /design TW-12345
3. Use different branch name
```

## Integration with Project Workflows

### CMDS Integration

CMDS uses a mode-based design workflow:

**Global /design provides:**
- Solution options generation
- ADR creation
- Implementation plan generation

**CMDS /design preserves:**
- Mode header: `🤖 [Design Mode]`
- Checklist-driven workflow
- Session context file updates
- Mode transition rules

**Integration approach:**
```
/design (in CMDS project)
  ├─> Show mode header (CMDS-specific)
  ├─> Read mode context files (CMDS-specific)
  ├─> Call design-agent (global - for options/ADR)
  ├─> Create design artifacts (global)
  ├─> Update session context (CMDS-specific)
  └─> Route to /dev mode (CMDS-specific)
```

### Skip-to-Deliver Cases

Some work items don't need design:

| Condition | Action |
|-----------|--------|
| Task | Route directly to deliver |
| Bug fix with known cause | Route to deliver (fix is the design) |
| Story following exact existing pattern | Light design, quick ADR reference |
| Spike/research | Route to deliver (research is the work) |

## Configuration

The design process uses these configuration files:

- `~/.claude/commands/index.yaml` - Stage definitions
- `docs/templates/documents/adr-skeleton.md` - ADR template
- `~/.claude/templates/delivery/implementation-plan.json` - Plan template
- `~/.claude/session/active-work.md` - Current work context
- `~/.claude/agents/design-agent.md` - Design agent

## Domain Aggregate Reference

| Operation | Aggregate Command |
|-----------|-------------------|
| Fetch work item | `/work-item get <id>` or `--external <system>:<id>` |
| Update design results | `/work-item update <id> --status designed` |
| Add comment | `/work-item comment <id> "message"` |
| Transition stage | `/work-item transition <id> deliver\|plan` |

See [/domain/work-item](domain/work-item.md) for full aggregate documentation.
