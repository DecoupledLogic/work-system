---
description: Triage a work item - categorize, assign template, and route to queue
allowedTools:
  - Read
  - Write
  - Edit
  - Task
  - SlashCommand
---

You are the Triage Orchestrator. Your job is to coordinate the triage process by calling specialized agents and using **domain aggregates** to manage work items.

## Domain Integration

This command uses the WorkItem aggregate (`/domain/work-item`) as the abstraction layer for all work item operations. External systems (Teamwork, GitHub, etc.) are accessed through the aggregate's sync capabilities.

**Key Aggregate Commands Used:**

- `/work-item get --external teamwork:<id>` - Fetch and normalize external task
- `/work-item create` - Create new work item from raw context
- `/work-item update` - Update work item with triage results
- `/work-item transition <id> plan|design|deliver` - Move to next stage
- `/work-item route <id> <queue>` - Route to urgency queue
- `/work-item comment <id> "message"` - Add triage comment (auto-syncs to external)

## Purpose

Triage turns raw or partially-categorized work items into fully-classified, template-assigned, queue-routed work ready for the next stage (Plan, Design, or Deliver).

## Usage

```
/triage <input>
```

**Input formats:**
- Teamwork task ID: `/triage TW-26134585` or `/triage 26134585`
- Raw context: `/triage [paste email or ticket content]`
- Work item JSON: `/triage {"id": "...", "name": "..."}`

## Process

### Step 1: Identify Input Type

Determine what kind of input was provided:

**Teamwork Task ID Pattern:**
- `TW-######` (e.g., TW-26134585)
- `######` (bare numeric ID)
- `#######` (with hash prefix)

If Teamwork ID detected, extract numeric ID:
- Strip "TW-" or "#" prefix
- Use numeric ID for API calls

**Raw Context Pattern:**
- Email content (from/to/subject/body)
- Ticket description text
- Customer request text

**JSON Pattern:**
- Object with `id` and `name` fields
- Already structured work item

### Step 2: Fetch and Normalize (via Domain Aggregate)

If input is a Teamwork task ID:

1. **Fetch and normalize via WorkItem aggregate:**

   ```bash
   /work-item get --external teamwork:<id>
   ```

   This command:
   - Fetches task details from Teamwork
   - Normalizes to WorkItem schema (via work-item-mapper)
   - Returns a unified work item regardless of source system

2. **If work item doesn't exist locally, create it:**

   ```bash
   /work-item create --type <inferred> --name "<name>" --external teamwork:<id>
   ```

   The aggregate handles:
   - ID generation (WI-xxx format)
   - External system linking
   - Initial status (draft)

**Note:** The aggregate abstracts the external system. The same flow works for:

- Teamwork: `--external teamwork:26134585`
- GitHub: `--external github:owner/repo#123`
- Linear: `--external linear:LIN-123`

### Step 3: Check for Project-Specific Triage

Before running global triage, check if there's a project-specific triage agent or command:

1. **Check working directory for local triage:**
   - Look for `.claude/agents/*-triage-agent.md`
   - Look for `.claude/commands/triage.md` (local override)

2. **If local triage exists:**
   - The local triage command should handle domain-specific logic
   - This global command may delegate to local after normalization
   - Example: Link production support has SQL script generation

3. **If no local triage:**
   - Continue with global triage process

### Step 4: Run Triage Agent

Call the triage-agent to categorize the work item:

Use Task tool with `subagent_type: "general-purpose"` (until triage-agent is registered):

```
Prompt for triage-agent:
You are the triage-agent. Read ~/.claude/agents/triage-agent.md for your instructions.

Triage this work item following the process defined in the agent definition.
Return the full triageResult JSON including:
- Enriched workItem with type, workType, urgency, impact, processTemplate
- routing decision (queue, nextStage, skipToDeliver)
- templateMatch information
- parentAlignment status
- triageNotes with rationale

Input WorkItem:
[Normalized WorkItem JSON or raw context]
```

### Step 5: Load and Validate Template

If triage-agent assigned a processTemplate:

1. **Check template exists:**
   - Read `~/.claude/templates/{templateId}.json`
   - If template file doesn't exist, note in output

2. **Validate template applies:**
   - Check `appliesTo` includes the work item type
   - If mismatch, flag but continue

3. **Extract template requirements:**
   - `requiredSections` for later validation
   - `outputs` for expected deliverables

### Step 6: Update Work Item via Aggregate

Apply triage results using domain aggregate commands:

1. **Update work item with triage results:**

   ```bash
   /work-item update <id> \
     --type story \
     --priority medium \
     --status triaged \
     --template support/generic
   ```

2. **Route to appropriate queue:**

   ```bash
   /work-item route <id> standard "Triaged: support request, medium impact"
   ```

   Queue mapping from urgency:
   - `critical` → `immediate`
   - `now` → `urgent`
   - `next` → `standard`
   - `future` → `deferred`

3. **Update session state:**

   The aggregate automatically updates `~/.claude/session/active-work.md` with:

   ```markdown
   ## Current Work Item

   **Work Item ID:** WI-2024-042
   **External:** teamwork:26134585
   **Name:** Update database schema
   **Type:** story
   **Status:** triaged
   **Template:** support/generic
   **Stage:** triage
   **Queue:** standard

   ### External Link
   - **System:** Teamwork
   - **URL:** https://discovertec.teamwork.com/app/tasks/26134585
   ```

### Step 7: Post Triage Comment (via Aggregate)

Add comment through the aggregate (auto-syncs to external system):

```bash
/work-item comment <id> "Triage Complete

**Type:** story
**Priority:** medium
**Template:** support/generic
**Queue:** standard
**Next Stage:** plan

Rationale:
- [Brief explanation of categorization]

🤖 Submitted by George with love ♥"
```

The `/work-item comment` command automatically:

- Adds comment to local work item history
- Syncs to external system (Teamwork, GitHub, etc.)
- Includes timestamp and author

### Step 8: Transition to Next Stage

Based on triage results, transition using the aggregate:

**If nextStage = "plan":**

```bash
/work-item transition <id> plan
```

Output:
```
Ready for planning. Run `/plan WI-2024-042` to decompose and size.
```

**If nextStage = "design":**

```bash
/work-item transition <id> design
```

Output:
```
Ready for design. Run `/design WI-2024-042` to create solution options.
```

**If nextStage = "deliver" (skipToDeliver = true):**

```bash
/work-item transition <id> deliver
```

Output:
```
Ready for delivery. Simple task with known solution.
Run `/deliver WI-2024-042` to implement.
```

**If needs more information:**
```
Triage incomplete. Missing:
- [What's needed]

Please provide additional context or run triage again with more details.
```

**Note:** Use the internal work item ID (WI-xxx) for subsequent commands. The aggregate maintains the external system link internally.

## Output Format

After triage completes, provide summary:

```
## Triage Complete: WI-2024-042

### Work Item
| Field | Value |
|-------|-------|
| Internal ID | WI-2024-042 |
| External | teamwork:26134585 |
| Name | Update database schema |

### Classification
| Field | Value | Rationale |
|-------|-------|-----------|
| Type | story | Has parent, deliverable scope |
| Priority | medium | Single customer, non-critical |
| Status | triaged | Ready for planning |

### Template & Routing
- **Template:** support/generic
- **Queue:** standard
- **Next Stage:** plan

### Triage Notes
[Key observations and decisions]

### Next Steps
Run `/plan WI-2024-042` to decompose into tasks.

---
*Domain: WorkItem WI-2024-042 updated via aggregate*
*Synced: teamwork (comment posted)*
```

## Error Handling

### Teamwork API Unavailable
```
Teamwork API unavailable - could not fetch task TW-26134585

Please provide the task context manually:
/triage [paste task description here]
```

### No Template Match
```
Warning: No template matches this work item.

Suggested template: support/new-pattern
Reason: [Pattern description]

Continuing with null template. Consider creating the template.
```

### Missing Required Information
```
Cannot complete triage. Missing:
- [ ] Clear description of what's needed
- [ ] Customer/requester information
- [ ] Scope indication

Please provide more context.
```

## Domain-Specific Extensions

This global triage command handles the core categorization workflow. Domain-specific projects can extend it by:

1. **Creating local triage agent:**
   - `.claude/agents/[project]-triage-agent.md`
   - Handles domain-specific patterns (e.g., SQL script generation)

2. **Overriding local triage command:**
   - `.claude/commands/triage.md` in project
   - Calls global triage first, then adds domain logic

3. **Custom templates:**
   - `~/.claude/templates/[domain]/*.json`
   - Project-specific process templates

Example flow for domain-specific triage:
```
/triage TW-12345
  └─> Global triage (this command)
       ├─> Normalize (work-item-mapper)
       ├─> Categorize (triage-agent)
       ├─> Update session state
       └─> Check for local triage
            └─> Call local triage agent (if exists)
                 └─> Domain-specific actions (SQL, files, etc.)
```

## Configuration

The triage process uses these configuration files:

- `~/.claude/commands/index.yaml` - Stage and agent definitions
- `~/.claude/templates/` - Process templates
- `~/.claude/session/active-work.md` - Current work context
- `~/.claude/agents/work-item-mapper.md` - Normalization agent
- `~/.claude/agents/triage-agent.md` - Categorization agent

## Domain Aggregate Reference

| Operation | Aggregate Command |
|-----------|-------------------|
| Fetch external task | `/work-item get --external <system>:<id>` |
| Create work item | `/work-item create --type <t> --name "..."` |
| Update triage results | `/work-item update <id> --type --priority --status --template` |
| Route to queue | `/work-item route <id> <queue> [reason]` |
| Add comment | `/work-item comment <id> "message"` |
| Transition stage | `/work-item transition <id> <stage>` |

See [/domain/work-item](domain/work-item.md) for full aggregate documentation.
