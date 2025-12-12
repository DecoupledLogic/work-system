# PR Comment Management & Code Review Pattern Learning

**Date:** 2025-12-11
**Status:** Planning
**Priority:** High

## Overview

This plan addresses the need for comprehensive PR comment management across GitHub and Azure DevOps, plus a self-improving code review system that learns patterns from PR feedback.

## Problem Statement

### Current Gaps

1. **GitHub PR Comments:** Can create PRs but cannot interact with PR comments/reviews
2. **Azure DevOps PR Comments:** Can create comment threads but cannot read, reply, or resolve them
3. **Code Review Learning:** Patterns are manually added to code-review.md; no automated learning from actual PR feedback

### Business Value

- **Faster PR Resolution:** Review and respond to PR comments without leaving the CLI
- **Better Code Quality:** Learn from team feedback patterns to catch issues before PR creation
- **Reduced Context Switching:** Handle entire PR workflow from command line
- **Self-Improvement:** Code review command improves based on actual team feedback

---

## Part 1: GitHub PR Comment Commands

### 1.1 gh-get-pr-comments

**Purpose:** List all comments and review threads on a PR

**Command:** `/gh-get-pr-comments [pr-number]`

**Implementation:**
```bash
# Uses: gh pr view <number> --json comments,reviews
# Returns: All comment threads with replies, status, author, timestamps
```

**Output Format:**
```json
{
  "pr": {
    "number": 123,
    "title": "feat: Add subscription sync"
  },
  "comments": [
    {
      "id": "C_123",
      "author": "ali-bijanfar",
      "body": "Use Transient here, not Scoped",
      "createdAt": "2025-01-15T10:30:00Z",
      "path": "ServiceCollectionExtensions.cs",
      "line": 42,
      "status": "unresolved"
    }
  ],
  "reviewThreads": [...],
  "summary": {
    "total": 15,
    "unresolved": 3,
    "resolved": 12
  }
}
```

**Priority:** High
**Dependencies:** None
**Effort:** Small

---

### 1.2 gh-comment-pr

**Purpose:** Add a general comment to a PR (not inline code review)

**Command:** `/gh-comment-pr [pr-number] "comment text"`

**Implementation:**
```bash
# Uses: gh pr comment <number> --body "text"
```

**Use Cases:**
- General feedback not tied to specific code
- Status updates
- Questions about approach
- Approval/LGTM messages

**Priority:** High
**Dependencies:** None
**Effort:** Small

---

### 1.3 gh-reply-pr-comment

**Purpose:** Reply to an existing comment thread

**Command:** `/gh-reply-pr-comment [pr-number] [comment-id] "reply text"`

**Implementation:**
```bash
# Uses: gh api to POST reply to specific comment thread
# Endpoint: POST /repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}/replies
```

**Note:** GitHub API required since gh CLI doesn't have direct reply support

**Priority:** Medium
**Dependencies:** gh-get-pr-comments (to find comment IDs)
**Effort:** Medium

---

### 1.4 gh-resolve-pr-comment

**Purpose:** Mark a review comment thread as resolved

**Command:** `/gh-resolve-pr-comment [pr-number] [comment-id]`

**Implementation:**
```bash
# Uses: gh api to PATCH review thread
# Endpoint: PATCH /repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}
# With: "resolved": true
```

**Priority:** Medium
**Dependencies:** gh-get-pr-comments
**Effort:** Medium

---

### 1.5 gh-review-pr

**Purpose:** Submit a formal PR review (approve, request changes, comment)

**Command:** `/gh-review-pr [pr-number] --action [approve|request-changes|comment] --body "review text"`

**Implementation:**
```bash
# Uses: gh pr review <number> --approve/--request-changes/--comment --body "text"
```

**Use Cases:**
- Formal approval after review
- Request changes with summary
- Add review without approval/rejection

**Priority:** High
**Dependencies:** None
**Effort:** Small

---

## Part 2: Azure DevOps PR Comment Commands

### 2.1 ado-get-pr-threads

**Purpose:** List all comment threads on a PR with their status

**Command:** `/ado-get-pr-threads <project> <repo> <pr-id>`

**Implementation:**
```bash
# API: GET {serverUrl}/{collection}/{project}/_apis/git/repositories/{repo}/pullrequests/{pr-id}/threads
# Returns all threads with comments, status, file context
```

**Output Format:**
```json
{
  "pullRequest": {
    "id": 123,
    "title": "Add subscription sync",
    "status": "active"
  },
  "threads": [
    {
      "id": 4269,
      "status": "active",
      "publishedDate": "2025-01-15T10:30:00Z",
      "lastUpdatedDate": "2025-01-15T14:00:00Z",
      "threadContext": {
        "filePath": "/ServiceCollectionExtensions.cs",
        "rightFileStart": {"line": 42}
      },
      "comments": [
        {
          "id": 1,
          "author": {"displayName": "Ali Bijanfar"},
          "content": "Use Transient here, not Scoped",
          "commentType": "text"
        },
        {
          "id": 2,
          "author": {"displayName": "Claude Agent"},
          "content": "Fixed - changed to Transient",
          "parentCommentId": 1
        }
      ],
      "properties": {
        "CodeReviewThreadType": "VoteUpdate"
      }
    }
  ],
  "summary": {
    "total": 15,
    "active": 3,
    "fixed": 10,
    "closed": 2
  }
}
```

**Priority:** Critical
**Dependencies:** None
**Effort:** Medium

---

### 2.2 ado-reply-pr-thread

**Purpose:** Reply to an existing comment thread

**Command:** `/ado-reply-pr-thread <project> <repo> <pr-id> <thread-id> "reply text"`

**Implementation:**
```bash
# API: POST {serverUrl}/{collection}/{project}/_apis/git/repositories/{repo}/pullrequests/{pr-id}/threads/{thread-id}/comments
# Body: {"content": "reply text", "commentType": "text", "parentCommentId": <parent-id>}
```

**Priority:** High
**Dependencies:** ado-get-pr-threads (to find thread IDs)
**Effort:** Small

---

### 2.3 ado-resolve-pr-thread

**Purpose:** Update thread status (active → fixed, closed, wontFix, etc.)

**Command:** `/ado-resolve-pr-thread <project> <repo> <pr-id> <thread-id> --status [fixed|wontFix|closed]`

**Implementation:**
```bash
# API: PATCH {serverUrl}/{collection}/{project}/_apis/git/repositories/{repo}/pullrequests/{pr-id}/threads/{thread-id}
# Body: {"status": "fixed"}
```

**Status Options:**
- `fixed` - Issue addressed
- `wontFix` - Won't be addressed
- `closed` - Discussion closed
- `byDesign` - Intentional behavior
- `pending` - Awaiting response

**Priority:** High
**Dependencies:** ado-get-pr-threads
**Effort:** Small

---

### 2.4 ado-get-pr-comments-structured

**Purpose:** Enhanced version that groups and analyzes comments

**Command:** `/ado-get-pr-comments-structured <project> <repo> <pr-id> [--format summary|detailed]`

**Features:**
- Group threads by file
- Identify unresolved threads
- Extract patterns (e.g., "Use X instead of Y")
- Categorize by type (code quality, security, architecture)

**Priority:** Medium (after basic commands)
**Dependencies:** ado-get-pr-threads
**Effort:** Medium

---

## Part 3: Code Review Pattern Learning System

### 3.1 Architecture

```
PR Comment → Pattern Extraction → Pattern Storage → Code Review Integration
```

**Components:**

1. **Pattern Extractor** (Agent/Service)
   - Analyzes PR comment threads
   - Identifies recurring feedback patterns
   - Categorizes by type (DI, architecture, security, etc.)
   - Extracts rule, anti-pattern, correct pattern

2. **Pattern Store** (File-based initially)
   - Location: `.claude/quality:code-review-patterns.yaml`
   - Structured YAML with metadata
   - Version controlled with project

3. **Code Review Integrator**
   - Loads patterns from store
   - Enhances code-review command
   - Dynamically adds checks

---

### 3.2 Pattern Store Schema

**File:** `.claude/quality:code-review-patterns.yaml`

```yaml
patterns:
  - id: DI-LIFETIME-001
    category: DependencyInjection
    priority: High
    title: Use Transient for stateless services
    source:
      system: azuredevops  # or github
      pr: 1045
      thread: 4269
      reviewer: Ali Bijanfar
      date: 2025-01-15
    rule: >
      Use Transient lifetime for stateless services. Only use Scoped
      if the service maintains per-request state.
    antiPattern: |
      services.AddScoped<ISubscriptionQuery, SubscriptionQuery>();
    correctPattern: |
      services.AddTransient<ISubscriptionQuery, SubscriptionQuery>();
    detection:
      files: ["**/ServiceCollectionExtensions.cs", "**/Program.cs"]
      pattern: "AddScoped<(\\w+), (\\w+)>"
      validation: "Check if service is stateless"
    remediation: >
      Change AddScoped to AddTransient for stateless services
    relatedPatterns:
      - DI-LIFETIME-002

  - id: VENDOR-DECOUPLING-001
    category: Architecture
    priority: High
    title: Keep vendor names out of Abstractions layer
    source:
      system: azuredevops
      pr: 1045
      thread: 4267
      reviewer: Ali Bijanfar
      date: 2025-01-15
    rule: >
      Abstractions layer should use generic names, not vendor-specific ones.
      Vendor implementations belong in Infrastructure layer.
    antiPattern: |
      // In Abstractions
      public interface IStaxbillService
      {
          Task SyncFromStaxBillAsync();
      }
    correctPattern: |
      // In Abstractions
      public interface ISubscriptionSyncService
      {
          Task SyncAsync();
      }
      // In Infrastructure
      public class StaxbillSubscriptionProvider : ISubscriptionProvider { }
    detection:
      files: ["**/*.Abstractions/**/*.cs"]
      pattern: "(?i)(staxbill|stripe|paypal|\\w+bill)"
      validation: "Check for vendor names in interface/class names"
    remediation: >
      Rename interfaces/methods to generic names, move vendor-specific
      implementations to Infrastructure layer
```

---

### 3.3 Pattern Extraction Command

**Command:** `/quality:extract-review-patterns [--source github|ado] [--pr <id>]`

**Purpose:** Extract learnable patterns from PR comments

**Implementation:**
```bash
# 1. Fetch PR comments using ado-get-pr-threads or gh-get-pr-comments
# 2. Analyze comments for pattern indicators:
#    - "should be" / "should not be"
#    - "use X instead of Y"
#    - "don't" / "avoid"
#    - Code block comparisons
# 3. Use LLM to structure pattern
# 4. Append to .claude/quality:code-review-patterns.yaml
# 5. Generate pattern ID
```

**Pattern Indicators:**
- Comparison words: "instead", "not", "don't", "avoid"
- Directive language: "should", "must", "need to"
- Code examples (backticks or fenced blocks)
- References to layers/files

**Priority:** High (enables self-improvement)
**Dependencies:** ado-get-pr-threads, gh-get-pr-comments
**Effort:** Large

---

### 3.4 Code Review Integration

**Enhancement to `/quality:code-review` command:**

```markdown
## Step 1.5: Load Custom Patterns

After discovering project structure, load patterns from:
- `.claude/quality:code-review-patterns.yaml` (project-specific learned patterns)
- Default patterns (hardcoded in code-review.md)

Merge and deduplicate patterns.
```

**Enhanced Review Process:**

```bash
# For each pattern in loaded patterns:
#   1. Check if pattern.files glob matches current files
#   2. Run pattern.detection.pattern regex search
#   3. If matches found, validate using pattern.validation rules
#   4. Report issue with:
#      - Pattern ID
#      - Severity (from pattern.priority)
#      - Location (file:line)
#      - Recommendation (from pattern.remediation)
#      - Example (from pattern.correctPattern)
```

**Priority:** Medium
**Dependencies:** extract-review-patterns
**Effort:** Medium

---

## Part 4: Integration with Deliver Workflow

### 4.1 Pre-PR Review Check

**In `/workflow:deliver` command, before creating PR:**

```bash
# Step 4a: Review PR Comments (if updating existing PR)
if PR exists:
    /ado-get-pr-threads or /gh-get-pr-comments

    if unresolved comments:
        show "⚠️  3 unresolved PR comments"
        prompt: "Review comments before pushing? [Y/n]"

        if yes:
            display comments with context
            for each comment:
                prompt: "Address this comment? [Y/n]"
                if yes:
                    # Give agent context, let it fix
                    run code fix
                    /ado-reply-pr-thread "Fixed - changed to X"
```

### 4.2 Post-PR Creation Pattern Learning

**After PR is merged:**

```bash
# Step N: Learn from PR Feedback
if PR has comments:
    prompt: "Extract learnable patterns from this PR? [Y/n]"

    if yes:
        /quality:extract-review-patterns --pr <pr-id>
        show "✅ Extracted 2 new patterns, added to .claude/quality:code-review-patterns.yaml"

        prompt: "Review extracted patterns? [Y/n]"
        # Allow user to edit/refine before committing
```

---

## Part 5: Implementation Roadmap

### Phase 1: Basic PR Comment Reading (Week 1)
**Priority:** Critical
**Goal:** Can view PR comments from CLI

| Task | Command | Effort | Dependencies |
|------|---------|--------|--------------|
| 1.1 | gh-get-pr-comments | Small | None |
| 1.2 | gh-comment-pr | Small | None |
| 2.1 | ado-get-pr-threads | Medium | None |

**Acceptance Criteria:**
- ✅ Can list all PR comments with context
- ✅ Can add general comments to PRs
- ✅ Works for both GitHub and Azure DevOps

---

### Phase 2: PR Comment Interaction (Week 2)
**Priority:** High
**Goal:** Can respond to and resolve PR comments

| Task | Command | Effort | Dependencies |
|------|---------|--------|--------------|
| 1.3 | gh-reply-pr-comment | Medium | 1.1 |
| 1.4 | gh-resolve-pr-comment | Medium | 1.1 |
| 1.5 | gh-review-pr | Small | None |
| 2.2 | ado-reply-pr-thread | Small | 2.1 |
| 2.3 | ado-resolve-pr-thread | Small | 2.1 |

**Acceptance Criteria:**
- ✅ Can reply to comment threads
- ✅ Can mark threads as resolved/fixed
- ✅ Can submit formal PR reviews (GH)
- ✅ Can change thread status (ADO)

---

### Phase 3: Pattern Extraction System (Week 3-4)
**Priority:** High
**Goal:** Self-improving code review

| Task | Component | Effort | Dependencies |
|------|-----------|--------|--------------|
| 3.1 | Pattern store schema | Small | None |
| 3.2 | Pattern extraction agent | Large | 1.1, 2.1 |
| 3.3 | extract-review-patterns command | Large | 3.1, 3.2 |
| 3.4 | Code review integration | Medium | 3.1 |

**Acceptance Criteria:**
- ✅ Can extract patterns from PR comments
- ✅ Patterns stored in version-controlled YAML
- ✅ Code review command uses custom patterns
- ✅ Patterns include detection and remediation

---

### Phase 4: Deliver Workflow Integration (Week 5)
**Priority:** Medium
**Goal:** Seamless PR comment handling in workflow

| Task | Integration Point | Effort | Dependencies |
|------|-------------------|--------|--------------|
| 4.1 | Pre-PR review check | Medium | Phase 1, Phase 2 |
| 4.2 | Post-merge learning | Small | Phase 3 |
| 2.4 | ado-get-pr-comments-structured | Medium | 2.1, 3.1 |

**Acceptance Criteria:**
- ✅ Deliver workflow shows unresolved comments
- ✅ Can address comments before pushing
- ✅ Auto-extracts patterns after merge
- ✅ Structured comment analysis available

---

## Technical Considerations

### 1. Authentication
- **GitHub:** Uses existing `gh auth` credentials
- **Azure DevOps:** Uses `~/.azuredevops/credentials.json`

### 2. Rate Limiting
- GitHub API: 5000 requests/hour (authenticated)
- Azure DevOps API: No official limit, but use reasonable delays

### 3. Comment Thread Models

**GitHub:**
- Issue comments (general discussion)
- Review comments (inline code feedback)
- Review summaries (approve/request changes)

**Azure DevOps:**
- Threads (can contain multiple comments)
- Thread status (active, fixed, wontFix, closed, byDesign, pending)
- Thread context (file, line, iteration)

### 4. Pattern Storage Strategy

**Why YAML over Database:**
- ✅ Version controlled with code
- ✅ Easy to review/edit
- ✅ Portable across environments
- ✅ No additional infrastructure
- ✅ Human-readable

**Schema Evolution:**
- Use semantic versioning for schema
- Include `schemaVersion: "1.0.0"` in file
- Support migration if schema changes

### 5. Pattern Detection Performance

**Optimization strategies:**
- Cache compiled regex patterns
- Only load patterns relevant to file types being reviewed
- Use file globs to limit scope
- Parallel pattern matching for multiple files

---

## Success Metrics

### Immediate (Phase 1-2)
- **PR comment response time:** < 5 minutes (vs. context switch to browser)
- **Unresolved comment visibility:** 100% (see all comments before merge)
- **CLI workflow completion:** Can complete entire PR review without browser

### Medium-term (Phase 3-4)
- **Pattern extraction rate:** > 50% of merged PRs generate at least 1 pattern
- **Code review coverage:** +20% issues caught before PR (vs. manual review)
- **Pattern library growth:** 50+ patterns after 3 months

### Long-term
- **Pre-PR issue detection:** 80% of common PR feedback caught by code-review
- **PR iteration cycles:** -30% (fewer back-and-forth rounds)
- **Team consistency:** Patterns from senior devs applied uniformly

---

## Risk Mitigation

### Risk 1: Pattern Quality
**Risk:** Extracted patterns may be noisy or irrelevant

**Mitigation:**
- Manual review/approval before adding to pattern store
- Pattern confidence score
- Ability to disable/delete patterns
- Pattern usage tracking (did it help?)

### Risk 2: API Changes
**Risk:** GitHub/ADO API breaking changes

**Mitigation:**
- Version API endpoints explicitly
- Graceful degradation (fall back to browser)
- Regular testing of API integrations
- Monitor API deprecation notices

### Risk 3: Performance
**Risk:** Pattern matching slows down code review

**Mitigation:**
- Lazy pattern loading
- Pattern caching
- Scope limiting (only relevant patterns)
- Progress indicators for long reviews

### Risk 4: False Positives
**Risk:** Code review flags incorrect issues

**Mitigation:**
- Pattern validation step (not just regex)
- Confidence levels (high/medium/low)
- Easy way to mark false positives
- Learn from false positives to refine patterns

---

## Alternative Approaches Considered

### 1. Store Patterns in Database
**Pros:** Query capabilities, relationships, versioning
**Cons:** Requires infrastructure, not version controlled with code
**Decision:** YAML files for simplicity and portability

### 2. Use Machine Learning for Pattern Extraction
**Pros:** More sophisticated pattern detection
**Cons:** Complexity, training data needs, overfitting
**Decision:** LLM-based extraction (simpler, good enough)

### 3. Build PR Comment UI in CLI
**Pros:** Rich interaction, better UX
**Cons:** Complex TUI, maintenance burden
**Decision:** Simple CLI commands + browser fallback

---

## Open Questions

1. **Pattern Conflicts:** What if two patterns contradict?
   - *Proposal:* Priority field, latest wins, manual resolution

2. **Pattern Sharing:** Should patterns be shared across projects?
   - *Proposal:* Project-specific first, consider shared library later

3. **Multi-reviewer Patterns:** What if reviewers disagree?
   - *Proposal:* Track reviewer + context, let team decide

4. **Pattern Evolution:** How to update patterns as practices change?
   - *Proposal:* Pattern versioning, deprecation marking

5. **Comment Threading:** How deep should reply threading go?
   - *Proposal:* Support full thread depth, display hierarchically

---

## Next Steps

1. **Review Plan:** Get feedback on approach and priorities
2. **Spike Phase 1:** Implement gh-get-pr-comments to validate approach
3. **Refine Pattern Schema:** Workshop pattern YAML structure with examples
4. **Create Phase 1 Branch:** `feature/pr-comments-phase1`
5. **Document Integration Points:** Update deliver.md and code-review.md

---

## Related Documents

- [code-review.md](commands/quality:code-review.md) - Current code review implementation
- [deliver.md](agents/workflow:deliver.md) - Delivery workflow that will integrate PR comment handling
- [architecture.yaml](.claude/architecture.yaml) - Architecture patterns and guardrails
- [agent-playbook.yaml](.claude/agent-playbook.yaml) - Project-specific rules

---

## Appendix A: Example Patterns

### Pattern: DI Lifetime Selection

```yaml
- id: DI-LIFETIME-001
  category: DependencyInjection
  priority: High
  title: Use Transient for stateless services
  source:
    system: azuredevops
    pr: 1045
    thread: 4269
    reviewer: Ali Bijanfar
    date: 2025-01-15
  rule: >
    Use Transient lifetime for stateless services (no internal state).
    Use Scoped only if service needs per-request state (like IRequestContext).
    Use Singleton for global shared state (like caches, configuration).
  antiPattern: |
    // BAD: Scoped for stateless service
    services.AddScoped<ISubscriptionQuery, SubscriptionQuery>();
  correctPattern: |
    // GOOD: Transient for stateless service
    services.AddTransient<ISubscriptionQuery, SubscriptionQuery>();
  detection:
    files: ["**/ServiceCollectionExtensions.cs", "**/Program.cs"]
    pattern: "AddScoped<(I\\w+(?:Query|Command|Repository)), (\\w+)>"
    validation: >
      For each match, check if service has instance fields
      (excluding injected dependencies). If no state fields, flag it.
  remediation: >
    Change AddScoped to AddTransient. Review service implementation
    to confirm it has no instance state.
  examples:
    - file: "ServiceCollectionExtensions.cs"
      line: 42
      issue: "AddScoped<ISubscriptionQuery, SubscriptionQuery>()"
      fix: "AddTransient<ISubscriptionQuery, SubscriptionQuery>()"
  relatedPatterns:
    - DI-LIFETIME-002
    - DI-LIFETIME-003
  metadata:
    timesDetected: 0
    lastDetected: null
    falsePositives: 0
```

### Pattern: Vendor Decoupling

```yaml
- id: VENDOR-DECOUPLING-001
  category: Architecture
  priority: High
  title: Keep vendor names out of Abstractions layer
  source:
    system: azuredevops
    pr: 1045
    thread: 4267
    reviewer: Ali Bijanfar
    date: 2025-01-15
  rule: >
    Abstractions layer (domain) should use generic, vendor-agnostic names.
    Vendor-specific implementations belong in Infrastructure layer.
  antiPattern: |
    // In *.Abstractions project - BAD
    public interface IStaxbillService
    {
        Task<StaxbillSubscription> SyncFromStaxBillAsync(string id);
    }
  correctPattern: |
    // In *.Abstractions project - GOOD
    public interface ISubscriptionSyncService
    {
        Task<Subscription> SyncAsync(string providerId);
    }

    // In *.Infrastructure project - GOOD
    public class StaxbillSubscriptionProvider : ISubscriptionProvider
    {
        // Vendor-specific implementation here
    }
  detection:
    files: ["**/*.Abstractions/**/*.cs"]
    pattern: "(?i)\\b(staxbill|stripe|paypal|square|braintree|\\w+bill)\\b"
    validation: >
      Check if match is in interface name, class name, method name,
      or parameter type in Abstractions project.
  remediation: >
    1. Rename interface/method to generic equivalent
    2. Create vendor-specific implementation in Infrastructure
    3. Update DI registration to use generic interface
  examples:
    - file: "Abstractions/IStaxbillService.cs"
      issue: "Interface name contains vendor 'Staxbill'"
      fix: "Rename to ISubscriptionSyncService"
    - file: "Abstractions/ISubscriptionRepository.cs"
      issue: "Method SyncFromStaxBillAsync contains vendor name"
      fix: "Rename to SyncFromProviderAsync"
  relatedPatterns:
    - VENDOR-DECOUPLING-002
  metadata:
    timesDetected: 0
    lastDetected: null
    falsePositives: 0
```

---

## Appendix B: Command Quick Reference

### GitHub Commands

```bash
# View PR comments
/gh-get-pr-comments [pr-number]
/gh-get-pr-comments                    # Current branch's PR

# Add comment
/gh-comment-pr [pr-number] "comment"
/gh-comment-pr "comment"               # Current branch's PR

# Reply to thread
/gh-reply-pr-comment [pr-number] [comment-id] "reply"

# Resolve comment
/gh-resolve-pr-comment [pr-number] [comment-id]

# Submit review
/gh-review-pr [pr-number] --approve --body "LGTM"
/gh-review-pr [pr-number] --request-changes --body "Please address comments"
/gh-review-pr [pr-number] --comment --body "Some thoughts"
```

### Azure DevOps Commands

```bash
# Get PR threads
/ado-get-pr-threads <project> <repo> <pr-id>
/ado-get-pr-threads MyProject MyRepo 123

# Reply to thread
/ado-reply-pr-thread <project> <repo> <pr-id> <thread-id> "reply"
/ado-reply-pr-thread MyProject MyRepo 123 4269 "Fixed - changed to Transient"

# Resolve thread
/ado-resolve-pr-thread <project> <repo> <pr-id> <thread-id> --status fixed
/ado-resolve-pr-thread MyProject MyRepo 123 4269 --status wontFix

# Get structured comments
/ado-get-pr-comments-structured <project> <repo> <pr-id> --format summary
```

### Pattern Management

```bash
# Extract patterns from PR
/quality:extract-review-patterns --source ado --pr 1045
/quality:extract-review-patterns --source github --pr 123

# Run code review with learned patterns
/quality:code-review                           # Uses patterns from .claude/quality:code-review-patterns.yaml
/quality:code-review --focus=services          # Focus on services layer
```

---

**End of Plan**
