# Getting Started: Delivering Stories

A practical tutorial for the most common workflow - delivering stories for product features as part of an epic release.

## Prerequisites

Before starting, ensure:

1. **Work system installed**:
   ```bash
   cd ~/projects/work-system
   ./install.sh --check
   ```

2. **Repository initialized** (in your target repo):
   ```bash
   /work:init
   ```
   This generates `.claude/architecture.yaml` and `.claude/agent-playbook.yaml`.

3. **Teamwork configured** (if using Teamwork):
   - `~/.claude/teamwork.json` - Your user identity
   - `<repo>/.claude/settings.json` - Project settings

---

## The Big Picture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        EPIC RELEASE                                  │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ Feature A                                                    │    │
│  │  ├── Story 1 ← YOU ARE HERE                                 │    │
│  │  ├── Story 2                                                 │    │
│  │  └── Story 3                                                 │    │
│  └─────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ Feature B                                                    │    │
│  │  ├── Story 4                                                 │    │
│  │  └── Story 5                                                 │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

**Your job**: Pick up a story, understand the context, implement it, and deliver it.

---

## End-to-End Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   SELECT     │────▶│    DESIGN    │────▶│   DELIVER    │────▶│   COMPLETE   │
│              │     │  (if needed) │     │              │     │              │
│ /select-task │     │ /design      │     │ /deliver     │     │ /log-complete│
│ /resume      │     │              │     │              │     │              │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
       │                    │                    │                    │
       ▼                    ▼                    ▼                    ▼
  Pick story          Explore options      Implement code       Log metrics
  from queue          Create ADR           Run tests            Post comment
  Load context        Generate plan        Code review          Update status
```

**Most stories skip Design** and go directly from Select → Deliver.

---

## Step 1: Select Your Work

### Option A: Pick New Work

```bash
/workflow:select-task
```

This shows your assigned tasks grouped by task list and sorted by priority:

```
📋 Task Selection

┌─ Production Support ────────────────────────────────────────┐
│ TW-26789  [high] Update payment validation rules            │
│ TW-26790  [med]  Add retry logic to email service          │
└─────────────────────────────────────────────────────────────┘

┌─ Q1 Feature Release ────────────────────────────────────────┐
│ TW-26801  [high] Implement dark mode toggle                 │
│ TW-26802  [med]  Add user preference persistence           │
│ TW-26803  [low]  Update settings page layout               │
└─────────────────────────────────────────────────────────────┘

Select a task by ID:
```

### Option B: Resume In-Progress Work

```bash
/workflow:resume
```

If you have active work from a previous session, this loads it and continues.

---

## Step 2: Understand the Context

After selecting a story, the system loads:

1. **Story details** - Name, description, acceptance criteria
2. **Parent context** - Feature and Epic it belongs to
3. **Sibling stories** - Related work in the same feature
4. **Process template** - What's expected for this type of work

**Example output:**

```
📖 Story Context

Story: TW-26801 - Implement dark mode toggle
Status: ready_for_dev
Priority: high
Estimate: 4 hours

┌─ Hierarchy ─────────────────────────────────────────────────┐
│ Epic: TW-26700 - Q1 UI Refresh                              │
│ └── Feature: TW-26800 - Dark Mode Support                   │
│     └── Story: TW-26801 - Implement dark mode toggle ← YOU  │
│     └── Story: TW-26802 - Add user preference persistence   │
│     └── Story: TW-26803 - Update settings page layout       │
└─────────────────────────────────────────────────────────────┘

┌─ Acceptance Criteria ───────────────────────────────────────┐
│ Given user is on the settings page                          │
│ When user clicks the dark mode toggle                       │
│ Then the UI switches to dark theme                          │
│ And the toggle state is visually indicated                  │
└─────────────────────────────────────────────────────────────┘

Template: product/story
Stage: ready_for_dev → Can proceed to /workflow:deliver
```

### Key Questions to Ask Yourself

- **Do I understand what to build?** → If not, read the parent Feature/Epic
- **Is this technically complex?** → If yes, run `/workflow:design` first
- **Are there dependencies?** → Check sibling stories for blockers

---

## Step 3: Design (If Needed)

**Skip this step** for straightforward stories where the implementation is obvious.

**Run `/workflow:design`** when:
- Multiple valid implementation approaches exist
- Architectural decisions are needed
- You need to create an ADR

```bash
/workflow:design TW-26801
```

The design agent will:
1. Research the problem space (reads codebase, related files)
2. Generate 2-4 solution options
3. Evaluate trade-offs
4. Recommend an approach
5. Create an ADR (if architectural decision)
6. Generate an implementation plan

**Example output:**

```
🎨 Design Complete

┌─ Recommendation ────────────────────────────────────────────┐
│ Option 2: CSS Custom Properties with Theme Context          │
│                                                             │
│ Rationale:                                                  │
│ - Leverages existing React context patterns                 │
│ - Minimal bundle size impact                                │
│ - Easy to extend with more themes later                     │
└─────────────────────────────────────────────────────────────┘

Created: docs/adrs/0015-dark-mode-implementation.md
Created: docs/plans/impl-dark-mode-toggle.md

Ready for: /workflow:deliver TW-26801
```

---

## Step 4: Deliver

This is where the work happens.

```bash
/workflow:deliver TW-26801
```

### What Happens

The deliver command orchestrates multiple agents:

```
┌─────────────────────────────────────────────────────────────┐
│                    /workflow:deliver                         │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  dev-agent  │─▶│  qa-agent   │─▶│ eval-agent  │         │
│  │             │  │             │  │             │         │
│  │ Implement   │  │ Run tests   │  │ Evaluate    │         │
│  │ TDD cycle   │  │ Check quality│  │ vs criteria │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│         │                │                │                 │
│         ▼                ▼                ▼                 │
│     Code changes    Test results    Quality score          │
│     Git commits     Coverage %      Pass/Fail              │
└─────────────────────────────────────────────────────────────┘
```

### The TDD Cycle (dev-agent)

1. **Spec** - Expand acceptance criteria into test cases
2. **Red** - Write failing tests
3. **Green** - Implement minimum code to pass
4. **Refactor** - Clean up while tests stay green
5. **Commit** - Save progress with proper attribution

### Quality Validation (qa-agent)

```
┌─ Quality Report ────────────────────────────────────────────┐
│ Tests:     12 passed, 0 failed                              │
│ Coverage:  87% (target: 80%)                                │
│ Lint:      0 errors, 2 warnings                             │
│                                                             │
│ Quality Score: 91/100 ✓ PASS                                │
└─────────────────────────────────────────────────────────────┘
```

### Evaluation (eval-agent)

```
┌─ Acceptance Criteria ───────────────────────────────────────┐
│ ✓ User can toggle dark mode from settings                   │
│ ✓ UI switches to dark theme                                 │
│ ✓ Toggle state is visually indicated                        │
│                                                             │
│ Criteria Met: 3/3 (100%)                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Step 5: Code Review

Before completing, review your changes:

```bash
/quality:code-review
```

This reviews your code against:
- Clean Architecture patterns
- Project-specific playbook rules
- Security best practices
- Performance considerations

**Example output:**

```
🔍 Code Review Complete

Files reviewed: 4
Issues found: 1

┌─ Issues ────────────────────────────────────────────────────┐
│ [medium] src/components/ThemeToggle.tsx:24                  │
│ Consider memoizing the theme context value to prevent       │
│ unnecessary re-renders.                                     │
│                                                             │
│ Suggestion: Wrap value in useMemo()                         │
└─────────────────────────────────────────────────────────────┘

Recommendations applied: Check architecture-recommendations.json
```

Fix any issues and re-run tests:

```bash
/dotnet:test    # For .NET projects
# or
npm test        # For JS/TS projects
```

---

## Step 6: Complete the Story

### Log Story Start (if not already done)

```bash
/delivery:log-start
```

Records the start time for lead/cycle time metrics.

### Log Story Completion

```bash
/delivery:log-complete
```

This:
1. Records completion metrics (cycle time, actual vs estimate)
2. Posts a completion comment to Teamwork
3. Updates delivery-log.csv for analytics

**Example comment posted:**

```
✅ Story Completed

Implementation: Dark mode toggle added to settings page

Changes:
- Added ThemeContext and ThemeProvider
- Created ThemeToggle component
- Updated App.tsx to wrap with ThemeProvider
- Added CSS custom properties for theming

Quality: 91/100
Tests: 12 passed (87% coverage)
Cycle Time: 3.5 hours (estimate: 4 hours)

🤖 Submitted by George with love ♥
```

---

## Step 7: Create PR and Merge

### Git Operations

```bash
/git:status                    # Check what's staged
/git:commit                    # Commit with conventional message
/git:push                      # Push to remote
```

### Create Pull Request

```bash
# GitHub
/github:gh-create-pr

# Azure DevOps
/azuredevops:ado-create-pr
```

### After PR Approval

```bash
# GitHub
/github:gh-merge-pr

# Azure DevOps
/azuredevops:ado-merge-pr
```

---

## Common Variations

### Support Ticket (Simpler Flow)

Support tickets often skip Design entirely:

```bash
/workflow:select-task          # Pick support ticket
/workflow:deliver TW-12345     # Execute support workflow
/delivery:log-complete         # Record metrics
```

### Complex Feature (Full Flow)

For architecturally significant work:

```bash
/workflow:select-task          # Pick story
/workflow:design TW-26801      # Explore options, create ADR
/workflow:deliver TW-26801     # Implement with TDD
/quality:code-review           # Review changes
/quality:architecture-review   # Check against guardrails
/delivery:log-complete         # Record metrics
```

### Blocked? Return to Design

If implementation reveals issues:

```bash
# During /workflow:deliver, if you discover the approach won't work:
/workflow:design TW-26801      # Re-explore options
/workflow:deliver TW-26801     # Try again with new approach
```

---

## Quick Reference

| Stage | Command | When to Use |
|-------|---------|-------------|
| Select | `/workflow:select-task` | Pick new work from queue |
| Select | `/workflow:resume` | Continue previous work |
| Design | `/workflow:design <id>` | Complex/architectural work |
| Deliver | `/workflow:deliver <id>` | Implement and test |
| Review | `/quality:code-review` | Before PR |
| Complete | `/delivery:log-complete` | After PR merged |

---

## Troubleshooting

### "No tasks found"

```bash
# Check your user config
cat ~/.claude/teamwork.json

# Check project config
cat .claude/settings.json

# Verify Teamwork connection
/teamwork:tw-get-tasks
```

### "Template not found"

Story needs to be triaged first:

```bash
/workflow:triage TW-26801
/workflow:deliver TW-26801
```

### Tests Failing

```bash
/dotnet:test                   # See detailed output
# Fix issues
/workflow:deliver TW-26801     # Re-run delivery
```

### Quality Score Too Low

Review the issues:

```bash
/quality:code-review           # See specific issues
# Address feedback
/dotnet:test                   # Verify fixes
```

---

## Next Steps

After completing your first story:

1. **Review the quick reference**: `docs/reference/quick-reference.md`
2. **Understand the agents**: `agents/README.md`
3. **Learn the full system**: `docs/core/work-system-guide.md`

---

*Last Updated: 2025-12-12*
