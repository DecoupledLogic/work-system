---
description: Deliver a work item - implement, test, evaluate, and complete
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

You are the Deliver Orchestrator. Your job is to coordinate the delivery pipeline by calling specialized agents (dev, qa, eval) and using **domain aggregates** to manage work items.

## Domain Integration

This command uses the WorkItem aggregate (`/domain/work-item`) as the abstraction layer for all work item operations.

**Key Aggregate Commands Used:**

- `/work-item get <id>` - Fetch work item (by internal ID or `--external`)
- `/work-item update <id>` - Update with delivery results (status, metadata)
- `/work-item transition <id> eval` - Move to evaluation stage
- `/work-item comment <id> "message"` - Add delivery comment (auto-syncs)
- `/work-item log-time <id> <duration>` - Log time spent (auto-syncs)

## Purpose

Deliver turns designed work items into working software and proven value. This involves:
- Development (spec → implement → review)
- Quality assurance (test → validate → report)
- Evaluation (verify criteria → compare plan/actual → capture learnings)
- Completion (close → create follow-up → update metrics)

## Usage

```
/deliver <input>
```

**Input formats:**
- Teamwork task ID: `/deliver TW-26134585` or `/deliver 26134585`
- Work item JSON: `/deliver {"id": "...", "type": "story", ...}`
- Current work: `/deliver` (uses active work from session)

**Options:**
- `/deliver TW-12345 --phase=dev` - Start at development phase
- `/deliver TW-12345 --phase=qa` - Start at QA phase
- `/deliver TW-12345 --phase=eval` - Start at evaluation phase

## Process

### Step 1: Identify Input (via Domain Aggregate)

Determine what to deliver:

**If work item ID provided (WI-xxx or external reference):**

```bash
# Internal ID
/work-item get WI-2024-042

# External reference
/work-item get --external teamwork:26134585
```

- Check current status and phase (status = designed)
- If not designed, run `/design` first

**If no input provided:**

- Read `~/.claude/session/active-work.md`
- Use the current work item from session
- Verify it's in "design" complete or "deliver" stage

### Step 2: Verify Ready for Delivery

Before delivering, confirm prerequisites:

**For Stories/Tasks:**
```
Required for delivery:
- status: designed (or in_progress if resuming)
- acceptanceCriteria: defined
- implementationPlan: exists (for stories from features)
```

**For Features:**
```
Deliver feature by delivering its child stories.
Feature is complete when all children complete.
```

If not ready:
```
Work item TW-12345 needs design before delivery.
Run `/design TW-12345` first.
```

### Step 3: Load Architecture Context

Check for and load architecture configuration:

```bash
# Check for architecture files
if [ -f ".claude/architecture.yaml" ]; then
  # Load architecture spec
  ARCHITECTURE=$(cat .claude/architecture.yaml)
fi

if [ -f ".claude/agent-playbook.yaml" ]; then
  # Load playbook rules
  PLAYBOOK=$(cat .claude/agent-playbook.yaml)
fi
```

**If architecture files exist:**

- Include architecture context in all agent prompts
- Agents will validate changes against guardrails
- Compliance status will be reported in delivery summary

**If no architecture files:**

- Proceed without architecture constraints
- Consider running `/work-init` to generate architecture config

### Step 4: Create/Switch to Branch

Ensure correct branch:

```bash
# Check if on correct branch
git branch --show-current

# If not, create or switch
git checkout feature/TW-{id}-{slug} || git checkout -b feature/TW-{id}-{slug}

# Ensure up to date with main
git pull origin main --rebase
```

### Step 5: Development Phase

Call dev-agent for implementation:

```
Prompt for dev-agent:
You are the dev-agent. Read ~/.claude/agents/dev-agent.md for your instructions.

Implement this work item following TDD practices.
Return the full devResult JSON including:
- Updated workItem status
- Commits created
- Test results
- Files changed
- Implementation notes
- Architecture compliance
- Next step routing

Input WorkItem:
[WorkItem JSON]

Implementation Plan:
[Implementation plan from design]

Context:
- Repo path: [path]
- Branch: [branch name]
- Test framework: [framework]

Architecture Context (if available):
- Architecture: [contents of .claude/architecture.yaml]
- Playbook: [contents of .claude/agent-playbook.yaml]
- Guardrails to follow: [relevant guardrails for affected layers]
```

**Development Checkpoints:**
1. After each TDD cycle, verify tests pass
2. Check for linting errors
3. Ensure no security issues introduced

### Step 6: QA Phase

Call qa-agent for validation:

```
Prompt for qa-agent:
You are the qa-agent. Read ~/.claude/agents/qa-agent.md for your instructions.

Validate this implementation against acceptance criteria.
Return the full qaResult JSON including:
- Criteria validation for each criterion
- Test execution results
- Coverage report
- Issues found
- Quality score
- Next step routing

Input WorkItem:
[WorkItem JSON with devResult]

Test Plan:
[Test plan from design]
```

**QA Checkpoints:**
1. All acceptance criteria mapped to tests
2. Test coverage meets thresholds
3. No regressions in existing tests

**If QA Fails:**
```
QA validation found issues:

| Criterion | Status | Issue |
|-----------|--------|-------|
| {criterion} | ✗ Fail | {issue} |

Returning to development to fix.
```

Route back to dev phase.

### Step 7: Evaluation Phase

Call eval-agent for final evaluation:

```
Prompt for eval-agent:
You are the eval-agent. Read ~/.claude/agents/eval-agent.md for your instructions.

Evaluate this completed work item.
Return the full evalResult JSON including:
- Criteria evaluation
- Vision alignment assessment
- Plan vs actual comparison
- Metrics captured
- Follow-up items
- Learnings

Input WorkItem:
[WorkItem with devResult and qaResult]

Plan Context:
- Original appetite: [appetite]
- Design decisions: [ADRs]
- Vision: [feature vision]

Delivery Context:
- Actual duration: [duration]
- Commits: [count]
- Lines changed: [added/removed]
```

### Step 8: Create Pull Request

If not already created:

```bash
# Push branch and create PR using slash commands
/gh-push-remote "feat(auth): {story.name}" --set-upstream
/gh-create-pr "feat(auth): {story.name}"
```

The `/gh-create-pr` command automatically generates a PR body with:

- Summary from commit messages
- Task reference (TW-{id})
- Test plan checklist
- Proper attribution

### Step 9: Update Work Item (via Aggregate)

Post completion summary using aggregate commands:

1. **Update work item status:**

   ```bash
   /work-item update WI-2024-042 --status review
   ```

2. **Log time spent (auto-syncs to external system):**

   ```bash
   /work-item log-time WI-2024-042 6h30m "Implementation and testing"
   ```

3. **Post delivery comment (auto-syncs to external system):**

   ```bash
   /work-item comment WI-2024-042 "Delivery Complete

   **Status:** Ready for Review
   **PR:** #{pr_number}

   **Development:**
   - Commits: {count}
   - Files changed: {count}
   - Lines: +{added} / -{removed}

   **Quality:**
   - Tests: {passed} passed, {failed} failed
   - Coverage: {percent}%
   - Quality Score: {score}

   **Plan vs Actual:**
   - Estimated: {planned}
   - Actual: {actual}
   - Variance: {variance}

   **Acceptance Criteria:**
   - ✓ {criterion1}
   - ✓ {criterion2}

   🤖 Submitted by George with love ♥"
   ```

The aggregate commands automatically sync to the external system (Teamwork, GitHub, etc.).

### Step 10: Update Session State

Update active work context:

```markdown
## Current Work Item

**Work Item ID:** TW-26134585
**Name:** User authentication system
**Type:** story
**Stage:** deliver
**Status:** awaiting_review

### Delivery Summary
- **PR:** #234
- **Branch:** feature/TW-26134585-auth
- **Commits:** 12
- **Quality Score:** 92

### Metrics
| Metric | Value |
|--------|-------|
| Planned | 2 days |
| Actual | 1.5 days |
| Coverage | 94% |
| Tests | 45 passed |
```

### Step 11: Complete or Route (via Aggregate)

Based on evaluation results, transition using the aggregate:

**If ready for review:**

```bash
/work-item transition WI-2024-042 eval
```

Output:
```
Delivery complete. PR created for review.

PR: #{pr_number}
Branch: feature/WI-2024-042-{slug}

Awaiting review approval. After merge:
1. Delete feature branch
2. Update work item to complete: /work-item update WI-2024-042 --status done
```

**If needs fixes:**

```bash
/work-item comment WI-2024-042 "Issues found, returning to development"
```

Output:
```
Evaluation found issues requiring fixes:

- {issue1}
- {issue2}

Returning to development phase.
```

**If needs design revision:**

```bash
/work-item transition WI-2024-042 design
/work-item comment WI-2024-042 "Design revision needed"
```

Output:
```
Delivery revealed design issues:

- {issue}

Run `/design WI-2024-042` to revise approach.
```

## Output Format

After delivery phase completes:

```
## Delivery Complete: TW-26134585

### Work Item
| Field | Value |
|-------|-------|
| Name | Basic login implementation |
| Type | story |
| Status | awaiting_review |
| PR | #234 |

### Development Summary
| Metric | Value |
|--------|-------|
| Commits | 12 |
| Files Changed | 8 |
| Lines Added | 450 |
| Lines Removed | 23 |

### Quality Summary
| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Tests Passed | 45 | - | ✓ |
| Tests Failed | 0 | 0 | ✓ |
| Coverage | 94% | 80% | ✓ |
| Quality Score | 92 | 80 | ✓ |

### Architecture Compliance
| Check | Status |
|-------|--------|
| Guardrails Checked | BE-G01, BE-G02, FE-G03 |
| Compliance Status | ✓ Compliant |
| Layers Affected | Application, Api |
| Patterns Followed | Repository, CQRS |

### Plan vs Actual
| Aspect | Planned | Actual | Variance |
|--------|---------|--------|----------|
| Time | 2 days | 1.5 days | -25% |
| Scope | 4 tasks | 4 tasks | 0% |

### Acceptance Criteria
| Criterion | Status |
|-----------|--------|
| Valid credentials → logged in | ✓ Met |
| Invalid credentials → error | ✓ Met |
| Token expires → re-auth | ✓ Met |

### Next Steps
1. Await PR review and approval
2. After merge, delete branch and close task

---
*Session: ~/.claude/session/active-work.md updated*
*Teamwork: Progress updated, comment posted*
```

## Delivery Modes

### Full Delivery

Default mode - runs all phases:
```
/deliver TW-12345
```
Dev → QA → Eval → PR → Complete

### Resume from Phase

Start from specific phase:
```
/deliver TW-12345 --phase=qa
```
Useful when resuming interrupted delivery.

### Quick Delivery

For simple tasks with minimal ceremony:
```
/deliver TW-12345 --quick
```
Skips detailed evaluation, creates implementation doc.

## Error Handling

### Test Failures

```
Development blocked by test failures.

Failed Tests:
- src/__tests__/auth.test.ts:45 - Expected token to be valid
- src/__tests__/auth.test.ts:67 - Timeout in async operation

Action: Fix tests or investigate test environment.
```

### Coverage Gaps

```
QA validation failed: Coverage below threshold.

| Metric | Actual | Required |
|--------|--------|----------|
| Statements | 72% | 80% |
| Branches | 65% | 75% |

Action: Add tests for uncovered code paths.

Uncovered files:
- src/services/tokenService.ts:42-55
- src/middleware/auth.ts:23-30
```

### Merge Conflicts

```
Cannot push branch: Conflicts with main.

Conflicting files:
- src/config/auth.ts

Action:
1. git pull origin main
2. Resolve conflicts
3. Run tests
4. Resume delivery
```

### Blocked by Dependency

```
Delivery blocked by dependency.

Waiting for: TW-26134500 (User model updates)
Status: In Progress
Estimated: 1 day

Options:
1. Wait for dependency to complete
2. Mock dependency for testing
3. Discuss priority with team
```

## Integration with Project Workflows

### CMDS Integration

CMDS uses mode-based workflow:

**Global /deliver provides:**
- dev-agent orchestration
- qa-agent validation
- eval-agent evaluation
- Metrics capture

**CMDS preserves:**
- Mode headers: `🤖 [Dev Mode]`, `🤖 [Delivery Mode]`, `🤖 [QA Mode]`
- Checklist-driven workflow
- Session context updates
- Mode transitions

**Integration approach:**
```
/deliver (in CMDS project)
  ├─> Check current mode
  ├─> If Dev Mode: Call dev-agent, maintain mode context
  ├─> If Deliver Mode: Call PR creation, maintain mode context
  ├─> If QA Mode: Call qa-agent, maintain mode context
  ├─> Update session context files (CMDS-specific)
  └─> Route to next mode (CMDS-specific)
```

### Support Workflow Integration

For support tickets:

```
/deliver TW-12345  (support ticket)
```

Support delivery is typically:
1. Execute resolution (SQL script, config change)
2. Validate fix in production
3. Document resolution
4. Close ticket

## Pipeline Visualization

```
/deliver TW-12345

┌─────────────────────────────────────────────────────────────┐
│                     DELIVERY PIPELINE                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [Designed]                                                  │
│      │                                                       │
│      ▼                                                       │
│  ┌─────────┐   TDD Cycle   ┌─────────┐                      │
│  │   DEV   │ ────────────► │  Tests  │                      │
│  │  Agent  │               │  Pass?  │                      │
│  └─────────┘               └────┬────┘                      │
│                                 │                            │
│                    ┌────────────┴────────────┐              │
│                    │                         │              │
│                   Yes                        No             │
│                    │                         │              │
│                    ▼                         ▼              │
│              ┌─────────┐              [Fix & Retry]         │
│              │   QA    │                                    │
│              │  Agent  │                                    │
│              └────┬────┘                                    │
│                   │                                         │
│         ┌────────┴────────┐                                 │
│         │                 │                                 │
│       Pass              Fail                                │
│         │                 │                                 │
│         ▼                 ▼                                 │
│   ┌─────────┐      [Return to Dev]                         │
│   │  EVAL   │                                              │
│   │  Agent  │                                              │
│   └────┬────┘                                              │
│        │                                                    │
│        ▼                                                    │
│   ┌─────────┐                                              │
│   │ Create  │                                              │
│   │   PR    │                                              │
│   └────┬────┘                                              │
│        │                                                    │
│        ▼                                                    │
│  [Awaiting Review]                                          │
│        │                                                    │
│        ▼                                                    │
│  [Complete] ──► Follow-up Items                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Configuration

The deliver process uses these configuration files:

- `~/.claude/commands/index.yaml` - Stage definitions
- `~/.claude/agents/dev-agent.md` - Development agent
- `~/.claude/agents/qa-agent.md` - QA agent
- `~/.claude/agents/eval-agent.md` - Evaluation agent
- `~/.claude/session/active-work.md` - Current work context

## Domain Aggregate Reference

| Operation | Aggregate Command |
|-----------|-------------------|
| Fetch work item | `/work-item get <id>` or `--external <system>:<id>` |
| Update delivery results | `/work-item update <id> --status review\|done` |
| Log time | `/work-item log-time <id> <duration> "description"` |
| Add comment | `/work-item comment <id> "message"` |
| Transition stage | `/work-item transition <id> eval\|design` |
| Mark complete | `/work-item update <id> --status done` |

See [/domain/work-item](domain/work-item.md) for full aggregate documentation.
