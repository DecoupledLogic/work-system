---
description: Plan a work item - decompose, size, and elaborate with acceptance criteria
allowedTools:
  - Read
  - Write
  - Edit
  - Task
  - SlashCommand
---

You are the Plan Orchestrator. Your job is to coordinate the planning process by calling specialized agents and updating work tracking systems.

## Purpose

Plan transforms triaged work items into right-sized, well-defined chunks ready for design or delivery. This involves:
- Sizing within type bounds (epic: cycles, feature: weeks, story: days, task: hours)
- Decomposition (epic→features, feature→stories, story→tasks)
- Elaboration (acceptance criteria, estimates, dependencies)
- Routing to the next stage (design or deliver)

## Usage

```
/plan <input>
```

**Input formats:**
- Teamwork task ID: `/plan TW-26134585` or `/plan 26134585`
- Work item JSON: `/plan {"id": "...", "type": "feature", ...}`
- Current work: `/plan` (uses active work from session)

## Process

### Step 1: Identify Input

Determine what to plan:

**If Teamwork ID provided:**
- Extract numeric ID (strip "TW-" or "#" prefix)
- Fetch task details using `/teamwork:tw-get-task <taskId>`
- Check if already triaged (has type, workType assigned)
- If not triaged, run `/triage` first

**If no input provided:**
- Read `~/.claude/session/active-work.md`
- Use the current work item
- Verify it's in "triage" complete or "plan" stage

**If JSON provided:**
- Parse directly
- Validate required fields (id, name, type)

### Step 2: Verify Triage Status

Before planning, confirm triage is complete:

```
Required for planning:
- type: epic | feature | story | task
- workType: product_delivery | support | bug_fix | maintenance | research
- urgency: critical | now | next | future
- processTemplate: assigned (or null with reason)
```

If triage incomplete:
```
Work item TW-12345 needs triage before planning.
Run `/triage TW-12345` first.
```

### Step 3: Determine Planning Scope

Based on work item type, determine planning approach:

| Type | Planning Action |
|------|-----------------|
| Epic | Decompose into features, create PlanDocument |
| Feature | Decompose into stories, define vision |
| Story | Add acceptance criteria, decompose into tasks |
| Task | Validate estimate, ensure definition of done |

### Step 4: Call Plan Agent

Use Task tool to invoke plan-agent:

```
Prompt for plan-agent:
You are the plan-agent. Read ~/.claude/agents/plan-agent.md for your instructions.

Plan this work item following the process defined in the agent definition.
Return the full planResult JSON including:
- Updated workItem with appetite and status
- children array with decomposed work items
- routing decisions for next stage
- planDocument info if generated
- planNotes with rationale

Input WorkItem:
[WorkItem JSON]

Context:
- Project: [project name if known]
- Process Template: [template id if assigned]
- Parent Context: [parent work item if exists]
```

### Step 5: Generate Plan Document (if Epic/Feature)

For epics and features, create a plan document:

1. **Determine document location:**
   - Project-specific: `docs/plans/{workItemId}.md`
   - Global: `~/.claude/plans/{workItemId}.md`
   - Or use template-specified location

2. **Write plan document:**
   ```markdown
   # Plan: {workItem.name}

   ## Overview
   - **ID:** TW-26134585
   - **Type:** feature
   - **Appetite:** 2 weeks
   - **Template:** product/feature

   ## Vision
   {vision statement}

   ## Breakdown

   ### Stories
   1. **{story1.name}** (2 days)
      - {brief description}
   2. **{story2.name}** (1 day)
      - {brief description}
   ...

   ## Dependencies
   - {dependency list}

   ## Risks
   - {risk list}

   ---
   *Planned: {timestamp}*
   ```

### Step 6: Create Child Work Items in Teamwork

For each child work item from plan-agent:

1. **Create subtask in Teamwork:**
   - Use `/teamwork:tw-create-task <parentTaskId> <name> [description] [estimateMinutes]`
   - Parent task ID ensures proper hierarchy
   - Include description with acceptance criteria for stories
   - Set estimate in minutes if available

2. **For stories, include acceptance criteria in description:**
   ```markdown
   ## Description
   {story description}

   ## Acceptance Criteria

   **Scenario: {scenario name}**
   - Given {context}
   - When {action}
   - Then {outcome}

   **Scenario: {scenario2 name}**
   ...
   ```

3. **Example creation:**

   ```bash
   # Create story subtask under feature
   /teamwork:tw-create-task 26134585 "User can login with email" "Story description with acceptance criteria" 480

   # Create task subtask under story
   /teamwork:tw-create-task 26134586 "Create login component" "Build React login form" 120
   ```

### Step 7: Update Session State

Update active work context:

1. **Write to active-work.md:**
   ```markdown
   ## Current Work Item

   **Work Item ID:** TW-26134585
   **Name:** User authentication system
   **Type:** feature
   **Stage:** plan
   **Status:** completed

   ### Plan Summary
   - **Appetite:** 2 weeks
   - **Children:** 3 stories
   - **Next Stage:** design

   ### Children
   | ID | Name | Type | Estimate |
   |----|------|------|----------|
   | TW-26134586 | Basic login | story | 2 days |
   | TW-26134587 | OAuth integration | story | 3 days |
   | TW-26134588 | Password reset | story | 1 day |
   ```

2. **Update stage progress:**
   - Mark "plan" stage as completed
   - Set next stage (design or deliver)

### Step 8: Post Teamwork Comment

Document planning decisions in Teamwork using `/teamwork:tw-create-comment`:

```
Planning Complete

**Appetite:** 2 weeks
**Decomposition:** 3 stories created

**Stories:**
1. TW-26134586: Basic login (2 days)
2. TW-26134587: OAuth integration (3 days)
3. TW-26134588: Password reset (1 day)

**Next Stage:** Design
**Plan Document:** docs/plans/TW-26134585.md

🤖 Submitted by George with love ♥
```

Update task progress using `/teamwork:tw-update-task <taskId> --progress 15`

### Step 9: Route to Next Stage

Based on plan results, indicate next action:

**If nextStage = "design":**
```
Planning complete. Feature requires design decisions.
Run `/design TW-26134585` to explore solution options.
```

**If nextStage = "deliver":**
```
Planning complete. Work items ready for implementation.
Run `/deliver TW-26134585` to begin development.
```

**If children need individual planning:**
```
Feature planned. Stories need acceptance criteria:
- Run `/plan TW-26134586` for Basic login
- Run `/plan TW-26134587` for OAuth integration
```

## Output Format

After planning completes, provide summary:

```
## Planning Complete: TW-26134585

### Work Item
| Field | Value |
|-------|-------|
| Name | User authentication system |
| Type | feature |
| Appetite | 2 weeks |
| Status | planned |

### Decomposition
Created 3 stories:

| ID | Name | Estimate | Next |
|----|------|----------|------|
| TW-26134586 | Basic login | 2 days | design |
| TW-26134587 | OAuth integration | 3 days | design |
| TW-26134588 | Password reset | 1 day | design |

### Plan Document
Created: `docs/plans/TW-26134585.md`

### Routing
- **Feature:** → Design stage
- **Stories:** → Design stage (after feature design)

### Next Steps
Run `/design TW-26134585` to create solution architecture.

---
*Session: ~/.claude/session/active-work.md updated*
*Teamwork: 3 subtasks created, comment posted*
```

## Planning Different Types

### Planning an Epic

```
/plan TW-12345  (where TW-12345 is an epic)
```

**Process:**
1. Identify major features (capabilities)
2. Size epic in cycles (1-3)
3. Create features as subtasks
4. Generate comprehensive PlanDocument
5. Route features to plan stage

### Planning a Feature

```
/plan TW-12345  (where TW-12345 is a feature)
```

**Process:**
1. Define vision statement
2. Map user journey
3. Identify stories
4. Size feature in weeks (1-2)
5. Create stories as subtasks
6. Route to design or deliver

### Planning a Story

```
/plan TW-12345  (where TW-12345 is a story)
```

**Process:**
1. Write Gherkin acceptance criteria
2. Identify implementation tasks
3. Size story in days (1-3)
4. Create tasks as subtasks
5. Route to design or deliver

### Planning a Task

```
/plan TW-12345  (where TW-12345 is a task)
```

**Process:**
1. Validate hour estimate (1-8)
2. Ensure clear definition of done
3. Confirm no further breakdown needed
4. Route to deliver

## Error Handling

### Triage Not Complete
```
Work item TW-12345 needs triage before planning.

Missing:
- type: not set
- workType: not set

Run `/triage TW-12345` first.
```

### Size Exceeds Bounds
```
Warning: Feature sized at 4 weeks exceeds 2-week maximum.

Recommendation: Split into two features:
1. Core Auth (2 weeks) - basic login and session
2. Advanced Auth (2 weeks) - OAuth and 2FA

Would you like me to split this feature?
```

### Cannot Decompose
```
Cannot identify clear decomposition for this work item.

Possible reasons:
- Scope too vague
- Missing context
- Already atomic

Recommendations:
1. Add more detail to description
2. Check if this should be a task (not story)
3. Consult with stakeholders for scope clarity
```

### Teamwork API Error
```
Could not create subtasks in Teamwork.

Planning complete locally. Manual steps needed:
1. Create stories manually in Teamwork
2. Link to parent TW-12345
3. Copy acceptance criteria from plan document

Plan document: docs/plans/TW-12345.md
```

## Integration with Project Workflows

This global plan command provides core decomposition logic. Projects can extend it:

### CMDS Integration
CMDS uses PRDs and CRDs for product work:
- `/plan` can process PRD-referenced work items
- Creates GitHub issues in addition to Teamwork tasks
- Follows CMDS-specific session context patterns

### Support Workflow Integration
Support items typically skip detailed planning:
- Simple support → triage straight to deliver
- Complex support → minimal planning (investigation tasks)

## Configuration

The plan process uses these configuration files:
- `~/.claude/commands/index.yaml` - Stage definitions
- `~/.claude/templates/product/` - Product templates
- `~/.claude/session/active-work.md` - Current work context
- `~/.claude/agents/plan-agent.md` - Planning agent
