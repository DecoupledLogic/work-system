---
description: Generate lint-safe markdown documents from templates
allowedTools:
  - Read
  - Write
  - Task
  - Glob
  - SlashCommand
---

You are the Document Write Orchestrator. Your job is to coordinate document generation by calling the Document Writer Agent with structured input.

## Usage

```text
/doc-write <template> [options]
```

**Templates** (in workflow order):

- `product-strategy` - Product Strategy (vision, north star, OKRs, initiatives, risks) - optional consulting engagement
- `spike-report` - Research/Investigation Report (pre-plan research)
- `delivery-plan` - Delivery Plan (epic-level planning with features and stories)
- `prd` - Product Requirements Document (single feature requirements)
- `bug-report` - Bug Documentation (in lieu of PRD for bugs/incidents)
- `architecture-blueprint` - Architecture Blueprint (system/service architecture)
- `adr` - Architecture Decision Record (major architectural decisions)
- `test-plan` - Test Plan (test strategy for product or features)
- `spec` - Technical Specification (story-level details)
- `impl-plan` - Implementation Plan (task breakdown from story)
- `release-notes` - Release Notes (after feature is ready to deploy)
- `retro` - Retrospective/Learnings (post-delivery learnings and improvement)

**Options:**

- `--work-item <id>` - Generate from work item (TW-12345 or WI-xxx)
- `--interactive` - Prompt for each field
- `--output <path>` - Custom output path
- `--no-save` - Return document without saving

## Examples

```text
/doc-write prd --work-item TW-26134585
/doc-write spec --work-item TW-26134586
/doc-write adr --title "Use JWT for authentication"
/doc-write spike-report --work-item TW-26134590
/doc-write prd --interactive
```

## Process

### Step 1: Parse Request

Identify template and context source:

**From command:**

- Extract template name
- Extract work item ID (if provided)
- Extract options (interactive, output path)

**Validate template:**

```text
Available templates (workflow order):
product-strategy, spike-report, delivery-plan, prd, bug-report,
architecture-blueprint, adr, test-plan, spec, impl-plan, release-notes, retro
```

### Step 2: Gather Context

**If work item provided:**

```bash
/work-item get <id>
```

Map work item fields to template context:

| Work Item Field | PRD Context | Spec Context |
|-----------------|-------------|--------------|
| name | featureName | storyName |
| id | - | workItemId |
| description | vision | - |
| acceptanceCriteria | acceptanceCriteria | acceptanceCriteria |
| parent.name | - | parentFeature |

**If interactive mode:**

Prompt for each required field:

```text
Template: prd

Required fields:
1. Feature name: [user input]
2. Vision statement: [user input]
3. Actors (comma-separated): [user input]
4. Acceptance criteria (one per line, empty to finish):
   - [user input]
   - [user input]
```

**If direct context:**

Parse JSON context from command or previous step:

```json
{
  "template": "prd",
  "context": {
    "featureName": "Link Contacts",
    "vision": "...",
    "actors": ["Pet Owner", "Clinic Tech"],
    "acceptanceCriteria": ["..."]
  }
}
```

### Step 3: Validate Context

Check required fields for template (in workflow order):

| Template | Required Fields |
|----------|-----------------|
| product-strategy | productName, vision, northStar, okrs, initiatives |
| spike-report | title, workItemId, question, findings |
| delivery-plan | initiativeName, strategy, problem, epics |
| prd | featureName, vision, actors, acceptanceCriteria |
| bug-report | title, workItemId, symptoms, stepsToReproduce |
| architecture-blueprint | systemName, overview, goals, components, corePrinciples |
| adr | title, context, decision, consequences |
| test-plan | workItemName, workItemId, testStrategy |
| spec | storyName, workItemId, userStory, acceptanceCriteria |
| impl-plan | workItemName, workItemId, tasks |
| release-notes | version, releaseDate, features |
| retro | workItemId, whatWentWell, whatCouldImprove |

If missing required fields:

```text
Missing required fields for PRD template:
- vision
- actors

Please provide:
1. Vision statement for the feature
2. List of actors/personas involved

Use --interactive to be prompted for each field.
```

### Step 4: Call Document Writer Agent

```text
Prompt for document-writer-agent:
You are the document-writer-agent. Read ~/.claude/agents/document-writer-agent.md for your instructions.

Generate a document using this template and context.

Template: {template}

Context:
{context as JSON}

Format Options:
{formatOptions as JSON}

Return the full result JSON including:
- status
- document
- lintReport
- structureReport
- metadata
```

### Step 5: Validate Output

Check the returned result:

**If status = "ok":**

- Verify lintReport is empty
- Check for warnings in structureReport
- Proceed to save

**If status = "error":**

- Display error message
- Suggest corrective action
- Exit

### Step 6: Save Document

Documents are stored in two locations based on their purpose:

**Repo-local documents** (`docs/...`) - Tied to specific code changes:

- Specs, implementation plans, test plans
- Bug reports, spike reports
- PRDs, release notes, architecture blueprints

**Global documents** (`~/.claude/docs/...`) - Cross-project learnings and decisions:

- ADRs (architecture decisions apply across projects)
- Retros (learnings inform future work)
- Delivery plans (initiative-level planning)

#### Default Paths (in workflow order)

| Template | Location | Default Path |
|----------|----------|--------------|
| product-strategy | global | ~/.claude/docs/strategy/{slug}-strategy.md |
| spike-report | repo | docs/spikes/{prefix}-{id}-{slug}.md |
| delivery-plan | global | ~/.claude/docs/plans/{prefix}-{id}-delivery-plan.md |
| prd | repo | docs/prd/{prefix}-{id}-{slug}.md |
| bug-report | repo | docs/bugs/{prefix}-{id}-{slug}.md |
| architecture-blueprint | repo | docs/architecture/blueprints/{slug}-blueprint.md |
| adr | global | ~/.claude/docs/adr/ADR-{number}-{slug}.md |
| test-plan | repo | docs/plans/{prefix}-{id}-test-plan.md |
| spec | repo | docs/specs/{prefix}-{id}-{slug}.md |
| impl-plan | repo | docs/plans/{prefix}-{id}-implementation.md |
| release-notes | repo | docs/releases/v{version}-notes.md |
| retro | global | ~/.claude/docs/retros/{prefix}-{id}-retro.md |

#### Path Variables

| Variable | Source | Example |
|----------|--------|---------|
| `{prefix}` | Work manager type | TW (Teamwork), ADO (Azure DevOps), GH (GitHub), WI (internal) |
| `{id}` | Work item ID (numeric) | 26134585 |
| `{slug}` | Slugified work item name | user-authentication |
| `{number}` | Auto-incremented (ADRs only) | 0042 |
| `{version}` | Release version | 1.2.0 |

**Create directories if needed:**

```bash
# Repo-local directories
mkdir -p docs/{prd,specs,spikes,bugs,releases,plans,architecture/blueprints}

# Global directories
mkdir -p ~/.claude/docs/{strategy,adr,retros,plans}
```

**Write document:**

```bash
# Write to file
Write document to {output_path}
```

### Step 7: Report Results

**Success (repo-local):**

```text
Document created: docs/prd/TW-26134585-link-contacts.md

Template: prd
Location: repo
Word count: 245
Headings: 6
Lint status: ✓ Clean

Next steps:
1. Review the generated document
2. Add any missing details
3. Commit when ready: git add docs/prd/TW-26134585-link-contacts.md
```

**Success (global):**

```text
Document created: ~/.claude/docs/adr/ADR-0042-jwt-authentication.md

Template: adr
Location: global
Word count: 312
Headings: 5
Lint status: ✓ Clean

Next steps:
1. Review the generated document
2. Add any missing details
3. Document is in global location (cross-project)
```

**With warnings:**

```text
Document created: docs/prd/ADO-12345-link-contacts.md

Template: prd
Location: repo
Word count: 245
Headings: 6
Lint status: ✓ Clean

Warnings:
- Optional field 'constraints' was empty
- Optional field 'risks' was empty

Consider adding these sections for a more complete PRD.
```

## Template-Specific Guidance

### PRD (Product Requirements Document)

Best for: Features, Epics

```text
/doc-write prd --work-item TW-12345
```

If work item description is sparse, use interactive mode to gather:

- Clear vision statement
- All user personas (actors)
- Complete acceptance criteria
- Known constraints
- Items explicitly out of scope

### Spec (Technical Specification)

Best for: Stories

```text
/doc-write spec --work-item TW-12345
```

Auto-extracts from story:

- Story name and ID
- User story format (if available)
- Acceptance criteria
- Parent feature context

May need to add:

- Technical approach
- API changes
- Data changes

### ADR (Architecture Decision Record)

Best for: Design decisions

```text
/doc-write adr --title "Use JWT for authentication"
```

Interactive mode recommended to capture:

- Full context (why this decision is needed)
- The decision made
- Positive and negative consequences
- Alternatives considered

ADR number auto-assigned based on existing ADRs.

### Implementation Plan

Best for: Design output

```text
/doc-write impl-plan --work-item TW-12345
```

Usually generated from design stage output.

### Test Plan

Best for: Design output

```text
/doc-write test-plan --work-item TW-12345
```

Usually generated from design stage output.

## Integration with Work System

### Pre-Engagement (Optional)

For consulting engagements:

```text
/doc-write product-strategy --interactive → vision, north star, OKRs, initiatives
```

### Pre-Plan (Research)

When research is needed before planning:

```text
/doc-write spike-report --work-item TW-12345 → research findings
```

### From /plan

Document generation varies by work item type:

```text
/plan epic → /doc-write delivery-plan → epics, features, stories
/plan feature → /doc-write prd → vision, actors, acceptance criteria
/plan bug → /doc-write bug-report → symptoms, root cause, fix approach
```

### From /design

When designing, generate multiple documents:

```text
/design feature → auto-generates:
  - architecture-blueprint (if system/service architecture)
  - adr (if major architectural decision)
  - test-plan (test strategy)

/design story → auto-generates:
  - spec (story details, technical approach)
  - impl-plan (task breakdown)
```

### From /deliver

After delivery:

```text
/deliver TW-12345 complete → auto-generates:
  - release-notes (version, features, fixes)
  - retro (if learnings exist)
```

## Error Handling

### Unknown Template

```text
Unknown template: xyz

Available templates:
- product-strategy: Product Strategy
- spike-report: Spike/Research Report
- delivery-plan: Delivery Plan
- prd: Product Requirements Document
- bug-report: Bug Documentation
- architecture-blueprint: Architecture Blueprint
- adr: Architecture Decision Record
- test-plan: Test Plan
- spec: Technical Specification
- impl-plan: Implementation Plan
- release-notes: Release Notes
- retro: Retrospective
```

### Work Item Not Found

```text
Work item TW-99999 not found.

Check:
1. Work item ID is correct
2. You have access to this work item
3. External system is accessible
```

### Validation Failed

```text
Document generation failed validation.

Lint errors:
- MD032 line 45: Lists should be surrounded by blank lines

This should not happen. Please report this issue.
```

## Configuration

Documents use project-level templates if available:

```text
.claude/
└── templates/
    └── documents/
        └── prd.yaml  # Project-specific PRD template
```

Project templates override system defaults.
