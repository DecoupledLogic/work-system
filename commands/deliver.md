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
  - mcp__Teamwork__twprojects-get_task
  - mcp__Teamwork__twprojects-update_task
  - mcp__Teamwork__twprojects-create_task
  - mcp__Teamwork__twprojects-create_comment
---

You are the Deliver Orchestrator. Your job is to coordinate the delivery pipeline by calling specialized agents (dev, qa, eval) and managing the full lifecycle of turning designed work into completed features.

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

### Step 1: Identify Input

Determine what to deliver:

**If Teamwork ID provided:**
- Extract numeric ID (strip "TW-" or "#" prefix)
- Fetch task details using `mcp__Teamwork__twprojects-get_task`
- Check current status and phase

**If no input provided:**
- Read `~/.claude/session/active-work.md`
- Use the current work item
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

### Step 3: Create/Switch to Branch

Ensure correct branch:

```bash
# Check if on correct branch
git branch --show-current

# If not, create or switch
git checkout feature/TW-{id}-{slug} || git checkout -b feature/TW-{id}-{slug}

# Ensure up to date with main
git pull origin main --rebase
```

### Step 4: Development Phase

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
- Next step routing

Input WorkItem:
[WorkItem JSON]

Implementation Plan:
[Implementation plan from design]

Context:
- Repo path: [path]
- Branch: [branch name]
- Test framework: [framework]
```

**Development Checkpoints:**
1. After each TDD cycle, verify tests pass
2. Check for linting errors
3. Ensure no security issues introduced

### Step 5: QA Phase

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

### Step 6: Evaluation Phase

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

### Step 7: Create Pull Request

If not already created:

```bash
# Push branch
git push -u origin feature/TW-{id}-{slug}

# Create PR
gh pr create --title "feat(auth): {story.name}" --body "$(cat <<'EOF'
## Summary
{Brief description of changes}

## Work Item
TW-{id}: {name}

## Changes
- {change1}
- {change2}

## Test Plan
- [ ] Unit tests pass ({count} tests)
- [ ] Integration tests pass
- [ ] Coverage at {percent}%
- [ ] Manual verification of acceptance criteria

## Acceptance Criteria Verification
| Criterion | Verified |
|-----------|----------|
| {criterion1} | ✓ |
| {criterion2} | ✓ |

🤖 Submitted by George with love ♥
EOF
)"
```

### Step 8: Update Teamwork

Post completion summary:

```
Delivery Complete

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

🤖 Submitted by George with love ♥
```

Update task progress to 80-90%.

### Step 9: Update Session State

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

### Step 10: Complete or Route

Based on evaluation results:

**If ready for review:**
```
Delivery complete. PR created for review.

PR: #{pr_number}
Branch: feature/TW-{id}-{slug}

Awaiting review approval. After merge:
1. Delete feature branch
2. Update work item to complete
3. Close TW-{id}
```

**If needs fixes:**
```
Evaluation found issues requiring fixes:

- {issue1}
- {issue2}

Returning to development phase.
```

**If needs design revision:**
```
Delivery revealed design issues:

- {issue}

Run `/design TW-{id}` to revise approach.
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
