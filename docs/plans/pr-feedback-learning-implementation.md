# PR Feedback Learning Loop - Implementation Plan

**Status:** Planning
**Priority:** High
**Start Date:** 2025-12-11
**Target Completion:** 6 weeks

---

## Executive Summary

This plan implements a **Reinforcement Learning from Human Feedback (RLHF) system for code development** where PR review feedback automatically improves:

1. **Code Review** - Catch issues before PR creation
2. **Architecture** - Guide design decisions with learned patterns
3. **Agent Behavior** - AI agents follow team conventions automatically

**Key Innovation:** Extract patterns once from PR feedback → Update three systems simultaneously → Create compounding improvement effect.

---

## Goals & Success Metrics

### Primary Goals

1. **Accelerate Learning**: Team learns from every PR, not just individual developers
2. **Reduce Review Burden**: Catch 60%+ of pattern issues before human review
3. **Improve Agent Code**: Agent-generated code follows team standards automatically
4. **Scale Knowledge**: New developers productive in weeks, not months

### Success Metrics

| Metric | Baseline | Target (3 months) | Target (6 months) |
|--------|----------|-------------------|-------------------|
| **Pre-PR Detection Rate** | 0% | 40% | 60% |
| **Average PR Review Time** | 30 min | 22 min (-27%) | 18 min (-40%) |
| **Pattern Library Size** | 0 patterns | 50 patterns | 150 patterns |
| **Agent Compliance Rate** | N/A | 80% | 95% |
| **False Positive Rate** | N/A | <10% | <5% |
| **New Dev Onboarding Time** | 3 months | 6 weeks | 2 weeks |

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                PR FEEDBACK LEARNING LOOP ARCHITECTURE             │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────┐                                                 │
│  │   PR with   │                                                 │
│  │  Feedback   │                                                 │
│  └──────┬──────┘                                                 │
│         │                                                         │
│         ↓                                                         │
│  ┌──────────────────────────────────────────┐                   │
│  │  /quality:extract-review-patterns                │                   │
│  │  ┌────────────────────────────────────┐  │                   │
│  │  │ 1. Fetch comments (GH/ADO)         │  │                   │
│  │  │ 2. Filter actionable feedback      │  │                   │
│  │  │ 3. Classify by type                │  │                   │
│  │  │ 4. Extract pattern structure       │  │                   │
│  │  │ 5. Route to target systems         │  │                   │
│  │  └────────────────────────────────────┘  │                   │
│  └───────────┬──────────┬──────────┬─────────┘                   │
│              │          │          │                             │
│              ↓          ↓          ↓                             │
│  ┌─────────────────────────────────────────────────────┐         │
│  │              PATTERN ROUTING ENGINE                  │         │
│  │                                                      │         │
│  │  Pattern Type    →    Target Systems                │         │
│  │  ────────────    ─    ──────────────                │         │
│  │  Architecture    →    All 3 systems                 │         │
│  │  DI/Patterns     →    CodeReview + Playbook         │         │
│  │  Security        →    All 3 systems                 │         │
│  │  Performance     →    CodeReview + ArchRecs         │         │
│  │  Conventions     →    CodeReview + Playbook         │         │
│  └───────────┬──────────┬──────────┬─────────────────────┘       │
│              │          │          │                             │
│              ↓          ↓          ↓                             │
│  ┌────────────┐  ┌──────────┐  ┌──────────────┐                │
│  │Code Review │  │Arch Recs │  │Agent Playbook│                │
│  │Patterns    │  │          │  │              │                │
│  │.yaml       │  │.json     │  │.yaml         │                │
│  └─────┬──────┘  └─────┬────┘  └──────┬───────┘                │
│        │               │               │                         │
│        └───────────────┴───────────────┘                         │
│                        │                                         │
│                        ↓                                         │
│  ┌──────────────────────────────────────────────┐               │
│  │         AUTOMATED APPLICATION                 │               │
│  │  ┌─────────────────────────────────────────┐ │               │
│  │  │ /quality:code-review                            │ │               │
│  │  │   Loads: code-review-patterns.yaml      │ │               │
│  │  │   Checks: All patterns against code     │ │               │
│  │  │   Reports: Issues found with pattern ID │ │               │
│  │  └─────────────────────────────────────────┘ │               │
│  │  ┌─────────────────────────────────────────┐ │               │
│  │  │ /workflow:design                                 │ │               │
│  │  │   Loads: architecture-recommendations   │ │               │
│  │  │   Validates: Options against guardrails│ │               │
│  │  │   Suggests: Leverage patterns           │ │               │
│  │  └─────────────────────────────────────────┘ │               │
│  │  ┌─────────────────────────────────────────┐ │               │
│  │  │ /workflow:deliver (dev-agent)                    │ │               │
│  │  │   Loads: agent-playbook.yaml            │ │               │
│  │  │   Follows: Guardrails + Leverage rules  │ │               │
│  │  │   Reports: Compliance status            │ │               │
│  │  └─────────────────────────────────────────┘ │               │
│  └──────────────────────────────────────────────┘               │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Enhanced Pattern Extraction (Weeks 1-2)

### Goal
Extract patterns that can update multiple systems simultaneously.

### Tasks

#### 1.1 Enhance Pattern Classification
**File:** `commands/quality:extract-review-patterns.md`

Add pattern type detection logic:

```python
def classify_pattern_type(comment, code_context):
    """
    Classify pattern into one of:
    - Architecture (layer violations, dependencies)
    - DI (dependency injection, lifetimes)
    - Security (auth, validation, secrets)
    - Performance (queries, caching, async)
    - Conventions (naming, formatting, documentation)
    """
    # Check for architecture keywords
    if matches_any(comment, [
        "layer", "boundary", "infrastructure", "domain",
        "abstractions", "dependency", "coupling"
    ]):
        return "Architecture"

    # Check for DI keywords
    if matches_any(comment, [
        "transient", "scoped", "singleton", "di",
        "injection", "lifetime", "service"
    ]):
        return "DependencyInjection"

    # Check for security keywords
    if matches_any(comment, [
        "security", "auth", "validate", "sanitize",
        "secret", "token", "password", "api key"
    ]):
        return "Security"

    # Check for performance keywords
    if matches_any(comment, [
        "performance", "query", "n+1", "cache",
        "async", "await", "slow", "optimize"
    ]):
        return "Performance"

    # Default to conventions
    return "Conventions"
```

#### 1.2 Create Multi-System Output Templates

**Template 1: Code Review Pattern**
```yaml
patterns:
  - id: {CATEGORY}-{SUBCATEGORY}-{NUMBER}
    category: {category}
    priority: {High|Medium|Low}
    title: {short title}
    source:
      system: {github|azuredevops}
      pr: {pr-number}
      thread: {thread-id}
      reviewer: {reviewer-name}
      date: {YYYY-MM-DD}
    rule: >
      {multi-line rule description}
    antiPattern: |
      {code showing what NOT to do}
    correctPattern: |
      {code showing correct way}
    detection:
      files: [{glob patterns}]
      pattern: "{regex}"
      validation: >
        {additional validation logic}
    remediation: >
      {step-by-step fix instructions}
    metadata:
      timesDetected: 0
      lastDetected: null
      falsePositives: 0
```

**Template 2: Architecture Recommendation**
```json
{
  "guardrails": [{
    "id": "ARCH-G{NNN}",
    "category": "{category}",
    "priority": "Critical|High|Medium",
    "title": "{title}",
    "description": "{description}",
    "rationale": "{why this matters}",
    "source": {
      "type": "pr-feedback",
      "pr": {pr-number},
      "reviewer": "{name}",
      "date": "{YYYY-MM-DD}"
    },
    "implementation": {
      "check": "{what to check}",
      "frequency": "every-commit|every-pr|weekly",
      "automation": "code-review command"
    }
  }],
  "leverage": [{
    "id": "ARCH-L{NNN}",
    "category": "{category}",
    "priority": "Medium",
    "title": "{title}",
    "pattern": "{when to apply}",
    "benefit": "{what improves}",
    "source": {
      "type": "pr-feedback",
      "pr": {pr-number}
    }
  }],
  "hygiene": [{
    "id": "ARCH-H{NNN}",
    "category": "{category}",
    "priority": "Low",
    "title": "{title}",
    "trigger": "{when to apply}",
    "action": "{what to do}",
    "benefit": "{why it helps}"
  }]
}
```

**Template 3: Agent Playbook Rule**
```yaml
backend:
  guardrails:
    - id: BE-G{NN}
      rule: "{rule description}"
      enforcement: always|recommended|optional
      source: pr-feedback
      prSource:
        pr: {pr-number}
        reviewer: "{name}"
        date: "{YYYY-MM-DD}"
      detection:
        files: ["{globs}"]
        pattern: "{regex}"
      remediation: >
        {how to fix}

  leverage:
    - id: BE-L{NN}
      pattern: "{when to apply}"
      guidance: |
        {detailed guidance}
      source: pr-feedback
      prSource:
        pr: {pr-number}

  hygiene:
    - id: BE-H{NN}
      trigger: "{when to apply}"
      action: "{what to do}"
      source: pr-feedback
```

#### 1.3 Implement Routing Logic

```python
def route_pattern(pattern_type, extracted_pattern):
    """
    Determine which systems to update based on pattern type
    """
    routes = {
        "Architecture": ["code-review", "arch-recs", "playbook"],
        "DependencyInjection": ["code-review", "playbook"],
        "Security": ["code-review", "arch-recs", "playbook"],
        "Performance": ["code-review", "arch-recs"],
        "Conventions": ["code-review", "playbook"]
    }

    targets = routes.get(pattern_type, ["code-review"])

    updates = {}
    for target in targets:
        if target == "code-review":
            updates["code-review-patterns.yaml"] = format_code_review_pattern(extracted_pattern)
        elif target == "arch-recs":
            updates["architecture-recommendations.json"] = format_arch_rec(extracted_pattern)
        elif target == "playbook":
            updates[".claude/agent-playbook.yaml"] = format_playbook_rule(extracted_pattern)

    return updates
```

#### 1.4 Add Preview & Confirmation

```bash
$ /quality:extract-review-patterns --pr 1045 --project MyProject --repo MyRepo

Analyzing PR #1045...
Found 5 actionable comments

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pattern 1/5: DI Lifetime Selection
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reviewer: Ali Bijanfar
Comment: "Use Transient for stateless services, not Scoped"

Extracted Pattern:
  ID: DI-LIFETIME-001
  Category: DependencyInjection
  Priority: High
  Rule: Use Transient lifetime for stateless services

Will update:
  ✓ code-review-patterns.yaml (new pattern)
  ✓ .claude/agent-playbook.yaml (leverage rule)

Preview:
  code-review-patterns.yaml:
    + patterns:
    +   - id: DI-LIFETIME-001
    +     category: DependencyInjection
    +     ...

  agent-playbook.yaml:
    + leverage:
    +   - id: BE-L05
    +     pattern: "When adding DI registrations..."
    +     ...

Accept this pattern? [Y/n/e/skip]
  Y = Accept and continue
  n = Reject and continue
  e = Edit before accepting
  skip = Skip to next pattern
```

### Deliverables

- [ ] Enhanced `/quality:extract-review-patterns` command with classification
- [ ] Multi-system output templates
- [ ] Routing logic implementation
- [ ] Preview and confirmation UI
- [ ] Unit tests for classification and routing

### Acceptance Criteria

✅ Command correctly classifies pattern types (>90% accuracy)
✅ Generates valid outputs for all target systems
✅ Preview shows clear diff of what will change
✅ User can edit patterns before accepting

---

## Phase 2: Architecture Recommendations Integration (Week 3)

### Goal
Use learned patterns to guide architecture decisions and design.

### Tasks

#### 2.1 Create architecture-recommendations.json Schema

**File:** `docs/schemas/architecture-recommendations.schema.json`

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Architecture Recommendations",
  "type": "object",
  "required": ["schemaVersion", "recommendations"],
  "properties": {
    "schemaVersion": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+\\.\\d+$"
    },
    "lastUpdated": {
      "type": "string",
      "format": "date-time"
    },
    "source": {
      "type": "string",
      "enum": ["architecture-review", "pr-feedback-learning", "manual"]
    },
    "recommendations": {
      "type": "object",
      "properties": {
        "guardrails": {
          "type": "array",
          "items": { "$ref": "#/definitions/guardrail" }
        },
        "leverage": {
          "type": "array",
          "items": { "$ref": "#/definitions/leverage" }
        },
        "hygiene": {
          "type": "array",
          "items": { "$ref": "#/definitions/hygiene" }
        }
      }
    }
  },
  "definitions": {
    "guardrail": {
      "type": "object",
      "required": ["id", "category", "priority", "title", "description"],
      "properties": {
        "id": { "type": "string", "pattern": "^ARCH-G\\d{3}$" },
        "category": { "type": "string" },
        "priority": { "enum": ["Critical", "High", "Medium"] },
        "title": { "type": "string" },
        "description": { "type": "string" },
        "rationale": { "type": "string" },
        "source": { "$ref": "#/definitions/source" },
        "implementation": { "$ref": "#/definitions/implementation" }
      }
    }
  }
}
```

#### 2.2 Initialize Template File

**File:** `docs/templates/architecture-recommendations.example.json`

Create template with examples from common patterns.

#### 2.3 Integrate with /workflow:design Command

**Update:** `commands/workflow:design.md`

Add step to load and validate against recommendations:

```markdown
### Step 2.5: Load Architecture Recommendations

Load recommendations from `architecture-recommendations.json` (if exists):

1. Load guardrails → Must be followed
2. Load leverage patterns → Should be considered
3. Load hygiene rules → Nice to have

When evaluating design options:
- Check each option against guardrails
- Suggest leverage patterns that apply
- Note hygiene improvements possible

Report compliance:
```json
{
  "option1": {
    "guardrailsChecked": ["ARCH-G001", "ARCH-G002"],
    "compliance": "compliant",
    "leverageOpportunities": ["ARCH-L003"]
  }
}
```
```

#### 2.4 Integrate with /quality:code-review Command

**Update:** `commands/quality:code-review.md` Step 1.5

```markdown
### Step 1.5: Load Custom Review Patterns

Load patterns from multiple sources:

1. **code-review-patterns.yaml** - Pattern detection rules
2. **architecture-recommendations.json** - Guardrails to check
3. Built-in patterns

When reviewing code:
- Check pattern detection rules (code-review-patterns.yaml)
- Verify guardrails compliance (architecture-recommendations.json)
- Report violations with pattern ID and recommendation ID
```

#### 2.5 Add CLI Commands

**New commands:**

```bash
# List all recommendations
/recommendations:list [--type guardrails|leverage|hygiene]

# View specific recommendation
/recommendations:view <id>

# Disable recommendation temporarily
/recommendations:disable <id> [--reason "explanation"]

# Re-enable recommendation
/recommendations:enable <id>

# Show recommendation statistics
/recommendations:stats
```

### Deliverables

- [ ] architecture-recommendations.json schema
- [ ] Example template file
- [ ] /workflow:design integration
- [ ] /quality:code-review integration
- [ ] CLI management commands
- [ ] Documentation

### Acceptance Criteria

✅ Schema validates recommendations correctly
✅ /workflow:design checks options against guardrails
✅ /quality:code-review reports guardrail violations
✅ CLI commands work for viewing/managing
✅ Documentation explains integration

---

## Phase 3: Agent Playbook Enhancement (Week 4)

### Goal
AI agents automatically follow learned patterns from PR feedback.

### Tasks

#### 3.1 Enhance agent-playbook.yaml Schema

Add fields for PR feedback tracking:

```yaml
backend:
  guardrails:
    - id: BE-G{NN}
      rule: "{rule}"
      enforcement: always|recommended|optional
      source: architecture-review|pr-feedback  # NEW
      prSource:  # NEW - if source is pr-feedback
        pr: {number}
        reviewer: "{name}"
        date: "{YYYY-MM-DD}"
        thread: {thread-id}
      confidence: high|medium|low  # NEW
      metadata:  # NEW
        timesTriggered: 0
        falsePositives: 0
        lastTriggered: null
```

#### 3.2 Update /workflow:deliver Command

**File:** `commands/workflow:deliver.md`

Add architecture loading step:

```markdown
### Step 3: Load Architecture Context

Before starting implementation:

1. Load `.claude/architecture.yaml` (if exists)
2. Load `.claude/agent-playbook.yaml` (if exists)
3. Load `architecture-recommendations.json` (if exists)

Pass to agents:
- dev-agent: Receives guardrails + leverage + hygiene
- qa-agent: Receives guardrails for validation
- eval-agent: Receives all for compliance checking

Report compliance in delivery output:
```json
{
  "architectureCompliance": {
    "guardrailsChecked": ["BE-G01", "BE-G02", "BE-G05"],
    "status": "compliant",
    "leverageApplied": ["BE-L02", "BE-L03"],
    "hygieneApplied": ["BE-H01"]
  }
}
```
```

#### 3.3 Update dev-agent

**File:** `agents/dev-agent.md`

Add playbook awareness:

```markdown
### Architecture Awareness

When implementing code, follow agent playbook rules:

**Guardrails (MUST follow):**
For each guardrail with enforcement: always
- Check if rule applies to current code
- Follow the rule strictly
- Report compliance

**Leverage (SHOULD apply):**
For each leverage pattern
- Check if pattern applies to current code
- Apply if appropriate
- Note in implementation log

**Hygiene (NICE to have):**
For each hygiene rule
- Check if trigger condition met
- Apply if time permits
- Note in implementation log

**Report:**
After implementation, report:
- Which guardrails were checked
- Which leverage patterns were applied
- Which hygiene rules were applied
- Any violations (with justification)
```

#### 3.4 Add Playbook Validation

Create validation tool:

```bash
# Validate playbook schema
/validate-playbook

# Check for conflicts
/check-playbook-conflicts

# Show playbook statistics
/playbook-stats
```

### Deliverables

- [ ] Enhanced agent-playbook.yaml schema
- [ ] Updated /workflow:deliver command
- [ ] Updated dev-agent with playbook awareness
- [ ] Playbook validation tools
- [ ] Compliance reporting

### Acceptance Criteria

✅ Agent playbook tracks PR feedback sources
✅ dev-agent loads and follows playbook rules
✅ Delivery reports include compliance status
✅ Validation catches schema errors
✅ Statistics show playbook usage

---

## Phase 4: Feedback Loop Optimization (Weeks 5-6)

### Goal
Close the loop - measure, learn, and improve continuously.

### Tasks

#### 4.1 Pattern Usage Tracking

Add telemetry to pattern system:

```yaml
# In code-review-patterns.yaml
patterns:
  - id: DI-LIFETIME-001
    # ... existing fields ...
    metadata:
      timesDetected: 15  # Incremented on each detection
      lastDetected: "2025-12-10"
      falsePositives: 2  # User can mark as false positive
      falsePositiveRate: 0.13  # 2/15
      avgFixTime: "5 minutes"  # Time to fix issues
      totalTimeSaved: "75 minutes"  # 15 * 5
```

#### 4.2 Pattern Effectiveness Dashboard

Create reporting command:

```bash
$ /pattern-report

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pattern Effectiveness Report
Generated: 2025-12-11 14:30:00
Period: Last 30 days
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Top Patterns by Detection:
1. DI-LIFETIME-001 (15 detections, 13 fixed)
2. ARCH-LAYER-001 (12 detections, 12 fixed)
3. SEC-LOGGING-001 (8 detections, 8 fixed)

Patterns Needing Review (High False Positive):
1. PERF-QUERY-002 (50% false positive rate)
   → Suggest: Refine detection regex

Patterns Not Used (Last 60 days):
1. CONV-NAMING-003
   → Suggest: Archive or update

Time Saved: 4.2 hours
Issues Caught Before PR: 35
Estimated Review Time Saved: 17.5 hours

Pattern Library Health: ████████░░ 80%
```

#### 4.3 Pattern Evolution Engine

Automatic pattern improvement:

```python
def evolve_patterns(patterns, usage_data):
    """
    Analyze pattern usage and suggest improvements
    """
    suggestions = []

    for pattern in patterns:
        # Check for high false positive rate
        if pattern.metadata.falsePositiveRate > 0.20:
            suggestions.append({
                "pattern": pattern.id,
                "action": "refine",
                "reason": f"High false positive rate: {pattern.metadata.falsePositiveRate:.0%}",
                "suggestion": "Review detection regex and validation logic"
            })

        # Check for low usage
        days_since_last_detected = (now() - pattern.metadata.lastDetected).days
        if days_since_last_detected > 60:
            suggestions.append({
                "pattern": pattern.id,
                "action": "archive",
                "reason": f"Not detected in {days_since_last_detected} days",
                "suggestion": "Consider archiving or updating to match current codebase"
            })

        # Check for high value patterns
        if pattern.metadata.timesDetected > 20 and pattern.metadata.falsePositiveRate < 0.05:
            suggestions.append({
                "pattern": pattern.id,
                "action": "promote",
                "reason": f"High detection rate ({pattern.metadata.timesDetected}) with low false positives",
                "suggestion": "Consider adding to agent playbook as guardrail"
            })

    return suggestions
```

#### 4.4 Cross-Project Pattern Sharing

Enable pattern export/import:

```bash
# Export patterns to share
/export-patterns --output my-project-patterns.yaml

# Import patterns from another project
/import-patterns --source other-project-patterns.yaml --review

# Show imported patterns for review
# User can accept, reject, or modify each pattern
```

#### 4.5 Pattern Merge & Deduplication

Detect similar patterns:

```python
def find_similar_patterns(patterns):
    """
    Find patterns that might be duplicates or could be merged
    """
    similarities = []

    for i, p1 in enumerate(patterns):
        for p2 in patterns[i+1:]:
            # Compare detection patterns
            if patterns_similar(p1.detection.pattern, p2.detection.pattern):
                similarities.append({
                    "pattern1": p1.id,
                    "pattern2": p2.id,
                    "similarity": calculate_similarity(p1, p2),
                    "suggestion": "Consider merging these patterns"
                })

    return similarities
```

### Deliverables

- [ ] Pattern usage tracking implementation
- [ ] Pattern effectiveness dashboard
- [ ] Pattern evolution engine
- [ ] Cross-project sharing tools
- [ ] Pattern merge detection

### Acceptance Criteria

✅ Usage metrics tracked automatically
✅ Dashboard shows pattern effectiveness
✅ Evolution engine suggests improvements
✅ Patterns can be exported/imported
✅ Similar patterns detected automatically

---

## Integration Timeline

```
Week 1-2: Phase 1 - Enhanced Pattern Extraction
  ├─ Pattern classification
  ├─ Multi-system templates
  ├─ Routing logic
  └─ Preview & confirmation

Week 3: Phase 2 - Architecture Recommendations
  ├─ Schema creation
  ├─ /workflow:design integration
  ├─ /quality:code-review integration
  └─ CLI commands

Week 4: Phase 3 - Agent Playbook
  ├─ Schema enhancement
  ├─ /workflow:deliver integration
  ├─ dev-agent updates
  └─ Validation tools

Week 5-6: Phase 4 - Loop Optimization
  ├─ Usage tracking
  ├─ Effectiveness dashboard
  ├─ Evolution engine
  └─ Cross-project sharing

Week 7: Testing & Documentation
  ├─ Integration testing
  ├─ Documentation updates
  ├─ Team training
  └─ Launch preparation
```

---

## Risk Management

### Risk 1: Pattern Extraction Accuracy

**Risk:** AI might extract incorrect patterns from ambiguous feedback

**Mitigation:**
- Interactive mode with preview before accepting
- Confidence scoring on extracted patterns
- Manual review required for high-impact patterns
- Easy rollback mechanism (git revert)
- Track false positives and refine

### Risk 2: System Complexity

**Risk:** Three interconnected systems might be hard to maintain

**Mitigation:**
- Clear separation of concerns (each file has distinct purpose)
- Comprehensive documentation
- Validation tools for each system
- Gradual rollout (can use systems independently)
- Version all files in git

### Risk 3: Pattern Overload

**Risk:** Too many patterns slow down development

**Mitigation:**
- Priority levels (only enforce high priority)
- Context-aware application (patterns only apply to relevant files)
- Regular cleanup of unused patterns
- Disable mechanism for edge cases
- Performance monitoring

### Risk 4: Team Adoption

**Risk:** Team might resist automated pattern checking

**Mitigation:**
- Start with informational warnings only
- Gather feedback and refine
- Show time savings metrics
- Make patterns visible and editable
- Allow override for valid exceptions

### Risk 5: False Positives

**Risk:** Incorrect pattern detections frustrate developers

**Mitigation:**
- Track false positive rate per pattern
- Automatic suggestions to refine high-FP patterns
- Easy "mark as false positive" mechanism
- Pattern confidence levels
- Regular pattern quality reviews

---

## Success Criteria

### Phase 1 Success
- ✅ Can extract patterns from 80%+ of actionable PR comments
- ✅ Correctly classifies pattern types with 90%+ accuracy
- ✅ Generates valid updates for all target systems
- ✅ Preview shows clear before/after diff

### Phase 2 Success
- ✅ Architecture recommendations file properly structured
- ✅ /workflow:design considers guardrails when evaluating options
- ✅ /quality:code-review reports violations with recommendation IDs
- ✅ CLI commands provide easy management

### Phase 3 Success
- ✅ Agent playbook enhanced with PR feedback sources
- ✅ dev-agent follows playbook rules automatically
- ✅ 90%+ agent compliance rate on playbook rules
- ✅ Delivery reports include compliance status

### Phase 4 Success
- ✅ Pattern usage tracked and reported
- ✅ False positive rate < 5% for high-priority patterns
- ✅ Evolution engine suggests 5+ improvements per month
- ✅ Cross-project pattern sharing works smoothly

### Overall Success (6 months)
- ✅ 150+ patterns in library
- ✅ 60%+ of pattern issues caught before PR
- ✅ 40% reduction in average PR review time
- ✅ 95% agent compliance rate
- ✅ Team velocity increased by 30%

---

## Next Steps

1. **Review and approve this plan**
2. **Create Phase 1 branch:** `feature/pr-feedback-learning-phase1`
3. **Implement Phase 1** (Weeks 1-2)
4. **Demo to team** and gather feedback
5. **Iterate and continue** to Phase 2

---

## Related Documents

- [ADR-0007: PR Feedback Learning Loop](../adrs/0007-pr-feedback-learning-loop.md)
- [RLHF for Code Concept](../concepts/rlhf-for-code.md)
- [ADR-0004: Architecture-Aware Agent System](../adrs/0004-architecture-aware-agents.md)
- [PR Comments System Plan](pr-comments-system.md)

---

**Status:** Ready for Review
**Owner:** Work System Team
**Last Updated:** 2025-12-11
