# Extract Review Patterns Command

**Agent:** User Command
**Purpose:** Extract learnable code review patterns from PR comments and add them to the pattern store
**Trigger:** `/extract-review-patterns [--source github|ado] [--pr <id>] [--project <project>] [--repo <repo>]`

## Overview

This command analyzes PR comments from GitHub or Azure DevOps to identify recurring feedback patterns. It extracts structured patterns that can be used by the `/code-review` command to catch similar issues before PR creation.

## Pattern Extraction Process

### Step 1: Fetch PR Comments

Based on the `--source` parameter:

**GitHub:**
```bash
# Use gh-get-pr-comments to fetch all comments
/gh-get-pr-comments <pr-number>
```

**Azure DevOps:**
```bash
# Use ado-get-pr-threads to fetch all threads
/ado-get-pr-threads <project> <repo> <pr-id>
```

### Step 2: Filter Actionable Comments

Look for comments that contain:
- Comparison words: "instead", "not", "don't", "avoid", "use X not Y"
- Directive language: "should", "must", "need to", "should be", "should not be"
- Code examples (backticks or fenced code blocks)
- References to layers/files/patterns
- Architectural guidance

**Exclude:**
- General discussion ("thoughts?", "LGTM", "thanks")
- Questions without guidance
- Typo corrections
- Comments already marked as "off-topic" or "resolved"

### Step 3: Classify Pattern Type

Before extracting pattern details, classify the pattern type to determine which systems to update:

**Classification Keywords:**

| Pattern Type | Keywords | Target Systems |
|--------------|----------|----------------|
| **Architecture** | layer, boundary, infrastructure, domain, abstractions, dependency, coupling, separation | All 3 systems |
| **DependencyInjection** | transient, scoped, singleton, di, injection, lifetime, service | CodeReview + Playbook |
| **Security** | security, auth, validate, sanitize, secret, token, password, api key, xss, injection | All 3 systems |
| **Performance** | performance, query, n+1, cache, async, await, slow, optimize, memory | CodeReview + ArchRecs |
| **Conventions** | naming, formatting, documentation, comments, style, convention | CodeReview + Playbook |

**Classification Process:**
1. Extract keywords from comment text
2. Match against classification table
3. If multiple matches, prioritize by severity (Security > Architecture > Performance > DI > Conventions)
4. Default to "Conventions" if no clear match

### Step 4: Analyze Each Comment for Pattern Structure

For each actionable comment, extract:

1. **Rule/Principle:** What is the guideline being enforced?
2. **Anti-Pattern:** What was done wrong? (include code if available)
3. **Correct Pattern:** What should be done instead? (include code if available)
4. **Category:** From classification (Architecture, DependencyInjection, Security, Performance, Conventions)
5. **Priority:** High/Medium/Low based on reviewer emphasis
6. **Bucket:** Determine if guardrail (must enforce), leverage (sanctioned improvement), or hygiene (nice-to-have)
7. **Detection:** Where can this pattern be detected?
   - File patterns (globs)
   - Regex patterns
   - Validation rules
8. **Remediation:** How to fix it?

### Step 5: Determine Pattern Bucket

Classify the pattern into one of three buckets based on enforcement level:

**Guardrails (Critical/High Priority):**
- **Must** be followed - violations block PRs or trigger warnings
- Security issues, architecture violations, data loss risks
- Example: "Domain layer must not reference Infrastructure"
- Target: All 3 systems (guardrails section)

**Leverage (Medium Priority):**
- **Should** be applied when appropriate - sanctioned improvements
- Refactoring patterns, performance optimizations, modernization
- Example: "Extract vendor-specific code to Infrastructure"
- Target: ArchRecs (leverage) + Playbook (leverage)

**Hygiene (Low Priority):**
- **Nice to have** - apply when touching related code
- Code cleanliness, documentation, minor improvements
- Example: "Add XML comments to public members"
- Target: ArchRecs (hygiene) + Playbook (hygiene)

### Step 6: Route to Target Systems

Based on pattern type and bucket, determine which files to update:

```
Pattern Type: Architecture + Bucket: Guardrail
  ✓ code-review-patterns.yaml (detection rules)
  ✓ architecture-recommendations.json (guardrails section)
  ✓ .claude/agent-playbook.yaml (backend.guardrails)

Pattern Type: DependencyInjection + Bucket: Leverage
  ✓ code-review-patterns.yaml (detection rules)
  ✓ .claude/agent-playbook.yaml (backend.leverage)

Pattern Type: Security + Bucket: Guardrail
  ✓ code-review-patterns.yaml (detection rules)
  ✓ architecture-recommendations.json (guardrails section)
  ✓ .claude/agent-playbook.yaml (backend.guardrails)

Pattern Type: Performance + Bucket: Leverage
  ✓ code-review-patterns.yaml (detection rules)
  ✓ architecture-recommendations.json (leverage section)

Pattern Type: Conventions + Bucket: Hygiene
  ✓ code-review-patterns.yaml (detection rules)
  ✓ .claude/agent-playbook.yaml (backend.hygiene)
```

### Step 7: Structure the Pattern

Generate pattern entries for each target system:

**Template 1: Code Review Pattern (code-review-patterns.yaml)**

```yaml
- id: <CATEGORY>-<SUBCATEGORY>-<NUMBER>
  category: <Category>
  priority: <High|Medium|Low>
  title: <Short descriptive title>
  source:
    system: <github|azuredevops>
    pr: <pr-number>
    thread: <thread-id or comment-id>
    reviewer: <reviewer-name>
    date: <YYYY-MM-DD>
  rule: >
    <Multi-line description of the rule/guideline>
  antiPattern: |
    <Code example showing what NOT to do>
  correctPattern: |
    <Code example showing the correct way>
  detection:
    files: [<glob patterns>]
    pattern: "<regex pattern>"
    validation: >
      <Additional validation logic description>
  remediation: >
    <Step-by-step fix instructions>
  examples:
    - file: "<filename>"
      line: <line-number>
      issue: "<what was wrong>"
      fix: "<how it was fixed>"
  relatedPatterns: []
  metadata:
    timesDetected: 0
    lastDetected: null
    falsePositives: 0
```

**Template 2: Architecture Recommendation (architecture-recommendations.json)**

For Guardrails:
```json
{
  "id": "ARCH-G<NNN>",
  "category": "<category>",
  "priority": "Critical|High|Medium",
  "title": "<title>",
  "description": "<description>",
  "rationale": "<why this matters>",
  "source": {
    "type": "pr-feedback",
    "pr": <pr-number>,
    "reviewer": "<name>",
    "date": "<YYYY-MM-DD>"
  },
  "implementation": {
    "check": "<what to check>",
    "frequency": "every-commit|every-pr|weekly",
    "automation": "code-review command"
  }
}
```

For Leverage:
```json
{
  "id": "ARCH-L<NNN>",
  "category": "<category>",
  "priority": "Medium",
  "title": "<title>",
  "pattern": "<when to apply>",
  "benefit": "<what improves>",
  "source": {
    "type": "pr-feedback",
    "pr": <pr-number>,
    "reviewer": "<name>"
  }
}
```

For Hygiene:
```json
{
  "id": "ARCH-H<NNN>",
  "category": "<category>",
  "priority": "Low",
  "title": "<title>",
  "trigger": "<when to apply>",
  "action": "<what to do>",
  "benefit": "<why it helps>"
}
```

**Template 3: Agent Playbook Rule (.claude/agent-playbook.yaml)**

For Guardrails:
```yaml
- id: BE-G<NN>
  rule: "<rule description>"
  enforcement: always|recommended|optional
  source: pr-feedback
  prSource:
    pr: <pr-number>
    reviewer: "<name>"
    date: "<YYYY-MM-DD>"
    thread: <thread-id>
  detection:
    files: ["<globs>"]
    pattern: "<regex>"
  remediation: >
    <how to fix>
```

For Leverage:
```yaml
- id: BE-L<NN>
  pattern: "<when to apply>"
  guidance: |
    <detailed guidance>
  source: pr-feedback
  prSource:
    pr: <pr-number>
    reviewer: "<name>"
```

For Hygiene:
```yaml
- id: BE-H<NN>
  trigger: "<when to apply>"
  action: "<what to do>"
  source: pr-feedback
```

### Step 8: Generate Pattern IDs

Generate appropriate IDs for each target system:

**Code Review Pattern ID:** `<CATEGORY>-<SUBCATEGORY>-<NUMBER>`
- Examples: `DI-LIFETIME-001`, `ARCH-VENDOR-001`, `SEC-INJECTION-001`
- Load existing patterns from `code-review-patterns.yaml`
- Find highest number for category, increment by 1

**Architecture Recommendation ID:** `ARCH-<BUCKET><NUMBER>`
- Guardrails: `ARCH-G001`, `ARCH-G002`
- Leverage: `ARCH-L001`, `ARCH-L002`
- Hygiene: `ARCH-H001`, `ARCH-H002`
- Load existing from `architecture-recommendations.json`
- Find highest number for bucket, increment by 1

**Agent Playbook ID:** `BE-<BUCKET><NUMBER>`
- Guardrails: `BE-G01`, `BE-G02` (2 digits)
- Leverage: `BE-L01`, `BE-L02`
- Hygiene: `BE-H01`, `BE-H02`
- Load existing from `.claude/agent-playbook.yaml`
- Find highest number for bucket, increment by 1

**Category Mapping:**
- Dependency Injection → `DI`
- Architecture → `ARCH`
- Security → `SEC`
- Performance → `PERF`
- Testing → `TEST`
- Naming → `NAMING`
- ErrorHandling → `ERROR`
- Conventions → `CONV`

### Step 9: Preview Changes

Before writing, show user what will be updated:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pattern 1/3: DI Lifetime Selection
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reviewer: Ali Bijanfar
Comment: "Use Transient for stateless services, not Scoped"

Extracted Pattern:
  Type: DependencyInjection
  Bucket: Leverage
  Priority: High
  Rule: Use Transient lifetime for stateless services

Will update:
  ✓ code-review-patterns.yaml (new pattern DI-LIFETIME-003)
  ✓ .claude/agent-playbook.yaml (new leverage BE-L05)

Preview:

┌─ code-review-patterns.yaml ──────────────────────────┐
│ patterns:                                             │
│ + - id: DI-LIFETIME-003                               │
│ +   category: DependencyInjection                     │
│ +   priority: High                                    │
│ +   title: Use Transient for stateless services       │
│ +   ...                                               │
└───────────────────────────────────────────────────────┘

┌─ .claude/agent-playbook.yaml ────────────────────────┐
│ backend:                                              │
│   leverage:                                           │
│ +   - id: BE-L05                                      │
│ +     pattern: "When adding DI registrations..."      │
│ +     guidance: |                                     │
│ +       Use Transient for stateless services...      │
└───────────────────────────────────────────────────────┘

[a]ccept  [e]dit  [s]kip  [q]uit  [A]ccept all
```

**User Options:**
- `a` - Accept this pattern and continue
- `e` - Edit pattern before accepting
- `s` - Skip this pattern
- `q` - Quit without saving remaining
- `A` - Accept all remaining patterns without review

### Step 10: Validate Pattern Quality

Before adding, check:

1. **Specificity:** Is the pattern specific enough to be actionable?
2. **Detectability:** Can we reasonably detect this pattern automatically?
3. **Non-redundancy:** Does this pattern overlap with existing patterns?
4. **Clarity:** Are the anti-pattern and correct-pattern clear?
5. **Completeness:** Do we have enough information to fix issues?

If quality checks fail, prompt user:
```
⚠️  Pattern extracted but needs refinement:
   - Missing: <what's missing>
   - Unclear: <what's unclear>

   Continue anyway? [y/N]
```

### Step 11: Update All Target Systems

For each accepted pattern, update the appropriate files based on routing:

**1. Update code-review-patterns.yaml:**
```bash
# Always updated for all patterns
1. Read existing file (or create if missing)
2. Parse YAML
3. Append pattern to patterns array
4. Sort by category, then ID
5. Write back with proper formatting
```

**2. Update architecture-recommendations.json (if routed):**
```bash
# Updated for Architecture, Security, Performance patterns
1. Read existing file (or create from template if missing)
2. Parse JSON
3. Append to appropriate section (guardrails/leverage/hygiene)
4. Update lastUpdated timestamp
5. Validate against schema
6. Write back with pretty formatting
```

**3. Update .claude/agent-playbook.yaml (if routed):**
```bash
# Updated for Architecture, DI, Security, Conventions patterns
1. Read existing file (or create from template if missing)
2. Parse YAML
3. Append to appropriate backend section (guardrails/leverage/hygiene)
4. Ensure proper nesting and indentation
5. Write back with proper formatting
```

**File Creation:**
- If file doesn't exist, create from template in `docs/templates/`
- Initialize with schema version and metadata
- Log file creation for user awareness

**Conflict Handling:**
- If pattern ID already exists, increment number
- If similar pattern detected (fuzzy match > 80%), ask user to merge or skip
- If file locked/unwritable, queue updates and retry

### Step 12: Report Results

```
✅ Extracted patterns from PR #1045

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Patterns Extracted: 3
  ✓ Accepted: 3
  ⊘ Skipped: 0
  ✗ Failed: 0

Systems Updated: 3
  ✓ code-review-patterns.yaml
  ✓ architecture-recommendations.json
  ✓ .claude/agent-playbook.yaml

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
New Patterns
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. DI-LIFETIME-003: Use Transient for stateless services
   Priority: High | Type: DependencyInjection | Bucket: Leverage
   → code-review-patterns.yaml (pattern)
   → .claude/agent-playbook.yaml (leverage BE-L05)

2. ARCH-LAYER-001: Domain layer must not reference Infrastructure
   Priority: Critical | Type: Architecture | Bucket: Guardrail
   → code-review-patterns.yaml (pattern)
   → architecture-recommendations.json (guardrail ARCH-G001)
   → .claude/agent-playbook.yaml (guardrail BE-G07)

3. SEC-LOGGING-002: Never log API keys or tokens
   Priority: Critical | Type: Security | Bucket: Guardrail
   → code-review-patterns.yaml (pattern)
   → architecture-recommendations.json (guardrail ARCH-G002)
   → .claude/agent-playbook.yaml (guardrail BE-G08)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Files Updated
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

code-review-patterns.yaml
  Before: 12 patterns
  After:  15 patterns (+3)

architecture-recommendations.json
  Created: New file initialized
  Guardrails: 2 added
  Leverage: 0 added
  Hygiene: 0 added

.claude/agent-playbook.yaml
  Before: 6 guardrails, 4 leverage, 2 hygiene
  After:  8 guardrails (+2), 5 leverage (+1), 2 hygiene

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Next Steps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Review patterns:
   cat code-review-patterns.yaml
   cat architecture-recommendations.json
   cat .claude/agent-playbook.yaml

2. Test pattern detection:
   /code-review --dry-run

3. Commit pattern updates:
   git add code-review-patterns.yaml architecture-recommendations.json .claude/agent-playbook.yaml
   git commit -m "feat(patterns): add 3 patterns from PR #1045"

4. Apply patterns automatically:
   Patterns will be used by:
   - /code-review (checks all patterns)
   - /design (considers architecture recommendations)
   - /deliver (dev-agent follows playbook rules)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pattern Learning Loop Active
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Your team's code review knowledge is now captured and will automatically
improve code quality across future PRs and agent-generated code.

Run /pattern-report to see pattern effectiveness over time.
```

## Command Arguments

### Required (one of):
- `--pr <number>` - PR number to analyze
- `--current` - Analyze current branch's PR

### Optional:
- `--source <github|ado>` - Source system (auto-detected if not specified)
- `--project <name>` - Azure DevOps project (required for ADO)
- `--repo <name>` - Repository name (required for ADO)
- `--filter <string>` - Only analyze comments containing text
- `--reviewer <name>` - Only analyze comments from specific reviewer
- `--dry-run` - Show what would be extracted without writing
- `--interactive` - Review each pattern before adding

## Examples

### GitHub PR
```bash
# Extract from GitHub PR 123
/extract-review-patterns --source github --pr 123

# Extract from current branch's PR
/extract-review-patterns --current

# Interactive mode - review each pattern
/extract-review-patterns --pr 123 --interactive

# Patterns saved to: code-review-patterns.yaml
```

### Azure DevOps PR
```bash
# Extract from ADO PR
/extract-review-patterns --source ado --pr 1045 --project MyProject --repo MyRepo

# Only patterns from specific reviewer
/extract-review-patterns --pr 1045 --project MyProject --repo MyRepo --reviewer "Ali Bijanfar"

# Dry run - see what would be extracted
/extract-review-patterns --pr 1045 --project MyProject --repo MyRepo --dry-run
```

## Integration with Deliver Workflow

After PR is merged, the `/deliver` command prompts:

```bash
✅ PR #1045 merged successfully

💡 Extract learnable patterns from PR feedback? [Y/n]
```

If yes:
```bash
Running: /extract-review-patterns --pr 1045
...
✅ Extracted 2 new patterns

Review patterns? [Y/n]
```

## Pattern Categories

Common categories to extract:

### 1. Dependency Injection
- Service lifetime (Transient vs Scoped vs Singleton)
- Constructor injection patterns
- Service registration patterns

### 2. Architecture
- Layer separation (Abstractions vs Infrastructure)
- Vendor decoupling
- Domain model purity
- CQRS patterns

### 3. Security
- Input validation
- SQL injection prevention
- XSS prevention
- Authentication/authorization patterns

### 4. Performance
- N+1 query prevention
- Caching strategies
- Async/await patterns
- Database query optimization

### 5. Testing
- Test naming conventions
- Test structure (Arrange-Act-Assert)
- Mock usage patterns
- Test coverage expectations

### 6. Naming
- Interface naming (I prefix)
- Method naming conventions
- Variable naming
- File/class organization

### 7. Error Handling
- Exception usage
- Result patterns
- Validation approaches
- Error message clarity

## Error Handling

### No Comments Found
```
ℹ️  No comments found on PR #123
   Nothing to extract
```

### API Errors
```
❌ Failed to fetch PR comments
   Error: API rate limit exceeded

   Try again in 15 minutes or use --cached flag
```

### Invalid Pattern
```
⚠️  Could not extract valid pattern from comment:
   "LGTM, ship it!"

   Reason: No actionable guidance found
   Skipping...
```

## Pattern Store Location

Patterns are stored in:
```
code-review-patterns.yaml
```

**Location:** Project root directory (where the /code-review command is run)

**Important:** This is a **per-project** file. Each project using the work system should have its own pattern file that learns from that project's specific PR feedback.

**Creating the file:**
```bash
# Option 1: Copy from template
cp ~/.claude/docs/templates/code-review-patterns.example.yaml code-review-patterns.yaml

# Option 2: Let /extract-review-patterns create it
/extract-review-patterns --source github --pr 123
# File will be created automatically on first extraction
```

This file should be:
- ✅ Version controlled with project
- ✅ Reviewed before committing
- ✅ Edited manually if needed
- ✅ Shared across team
- ⚠️ Project-specific (not shared between different projects)

## Implementation Notes

### Pattern Extraction Algorithm

1. **Comment Classification:**
   - Score each comment on "actionability" (0-10)
   - Threshold: >= 7 for pattern extraction

2. **Pattern Matching:**
   - Look for before/after code examples
   - Identify cause-effect relationships
   - Extract file/line context

3. **LLM Prompt Template:**
```
Analyze this PR comment and extract a code review pattern:

Comment:
"""
{comment_text}
"""

File Context: {file_path}:{line_number}
Code Before:
"""
{code_before}
"""

Extract:
1. Rule/Principle being enforced
2. What was wrong (anti-pattern)
3. What should be done (correct pattern)
4. How to detect this issue (regex/glob patterns)
5. How to fix it (remediation steps)

Return as structured YAML following this schema:
{pattern_schema}
```

### Performance Considerations

- Cache PR comments to avoid repeated API calls
- Process comments in parallel where possible
- Batch YAML writes (append all patterns at once)
- Skip comments already processed (track by comment ID)

### Quality Assurance

- Default to `--interactive` mode first time
- Allow editing patterns before writing
- Validate YAML syntax before writing
- Ensure pattern IDs are unique

## Related Commands

- `/code-review` - Uses patterns to review code
- `/gh-get-pr-comments` - Fetches GitHub PR comments
- `/ado-get-pr-threads` - Fetches ADO PR threads
- `/deliver` - Integrates pattern extraction post-merge

## Success Criteria

- ✅ Can extract patterns from both GitHub and ADO PRs
- ✅ Patterns include detection rules and remediation
- ✅ Pattern quality is validated before adding
- ✅ YAML file is properly formatted and version controlled
- ✅ Extracted patterns work with /code-review command
