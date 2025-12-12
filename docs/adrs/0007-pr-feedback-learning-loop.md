# ADR-0007: PR Feedback Learning Loop

## Status

Accepted

## Date

2025-12-11

## Context

### The Problem: Knowledge Locked in PR Comments

When senior developers review PRs, they provide valuable feedback that represents:
- **Architectural principles**: "This service should be in Infrastructure, not Domain"
- **Team conventions**: "Use Transient for stateless services, not Scoped"
- **Domain knowledge**: "Customer entities should never reference billing providers directly"
- **Security patterns**: "Never log API keys or tokens"
- **Performance lessons**: "Avoid N+1 queries - filter at database level"

This knowledge is currently:
1. ❌ **Lost in PR history** - Hard to search, easy to forget
2. ❌ **Repeated in every PR** - Same feedback given multiple times
3. ❌ **Manually enforced** - Reviewers must remember and check every time
4. ❌ **Inconsistently applied** - Depends on who reviews the PR
5. ❌ **Not actionable by agents** - AI agents can't learn from PR feedback

### The Opportunity: Learning Loop

PR feedback contains **actionable patterns** that can improve multiple systems:

```
┌─────────────────────────────────────────────────────────────┐
│                    PR FEEDBACK LEARNING LOOP                 │
└─────────────────────────────────────────────────────────────┘

   PR Review                Pattern Extraction         System Updates
   ─────────                ──────────────────         ──────────────

┌──────────────┐         ┌──────────────────┐      ┌────────────────┐
│              │         │                  │      │ Code Review    │
│ Reviewer:    │────────▶│  /extract-review │─────▶│ Patterns       │
│ "Use         │         │  -patterns       │      │ ✓ Catch before │
│  Transient   │         │                  │      │   PR creation  │
│  here"       │         │  Analyzes:       │      └────────────────┘
│              │         │  • Anti-pattern  │
└──────────────┘         │  • Correct code  │      ┌────────────────┐
                         │  • Detection     │      │ Architecture   │
                         │  • Remediation   │─────▶│ Recommendations│
                         │                  │      │ ✓ Guide design │
                         └──────────────────┘      │   decisions    │
                                  │                └────────────────┘
                                  │
                                  │                ┌────────────────┐
                                  │                │ Agent Playbook │
                                  └───────────────▶│ ✓ Agents follow│
                                                   │   team rules   │
                                                   └────────────────┘
```

**The Vision:** Extract patterns once, improve three systems automatically.

## Decision

Implement a **PR Feedback Learning Loop** that:

1. **Extracts patterns** from PR comments (both GitHub and Azure DevOps)
2. **Stores patterns** in structured, version-controlled files
3. **Updates multiple systems** with learned knowledge:
   - Code review patterns (immediate checking)
   - Architecture recommendations (design guidance)
   - Agent playbook (agent behavior rules)

### Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                      PATTERN EXTRACTION PIPELINE                  │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Input: PR Comments (GitHub/ADO)                                 │
│    ↓                                                              │
│  ┌──────────────────────────────────────────┐                   │
│  │ Step 1: Filter Actionable Comments       │                   │
│  │  • Look for: "should", "must", "avoid"   │                   │
│  │  • Code examples (backticks)             │                   │
│  │  • Comparison words: "instead", "not"    │                   │
│  └────────────────┬─────────────────────────┘                   │
│                   ↓                                               │
│  ┌──────────────────────────────────────────┐                   │
│  │ Step 2: Classify by Type                 │                   │
│  │  • Architecture (layers, dependencies)   │                   │
│  │  • Patterns (DI, CQRS, Repository)       │                   │
│  │  • Security (auth, validation, logging)  │                   │
│  │  • Performance (queries, caching)        │                   │
│  │  • Conventions (naming, formatting)      │                   │
│  └────────────────┬─────────────────────────┘                   │
│                   ↓                                               │
│  ┌──────────────────────────────────────────┐                   │
│  │ Step 3: Extract Pattern Structure        │                   │
│  │  • Rule/principle                        │                   │
│  │  • Anti-pattern (what was wrong)         │                   │
│  │  • Correct pattern (what should be)      │                   │
│  │  • Detection (how to find it)            │                   │
│  │  • Remediation (how to fix it)           │                   │
│  └────────────────┬─────────────────────────┘                   │
│                   ↓                                               │
│  ┌──────────────────────────────────────────┐                   │
│  │ Step 4: Generate Structured Outputs      │                   │
│  │                                           │                   │
│  │  Pattern Type: Architecture               │                   │
│  │  ├─▶ code-review-patterns.yaml           │                   │
│  │  ├─▶ architecture-recommendations.json   │                   │
│  │  └─▶ agent-playbook.yaml                 │                   │
│  │                                           │                   │
│  │  Pattern Type: DI/Patterns                │                   │
│  │  ├─▶ code-review-patterns.yaml           │                   │
│  │  └─▶ agent-playbook.yaml                 │                   │
│  │                                           │                   │
│  │  Pattern Type: Security                   │                   │
│  │  ├─▶ code-review-patterns.yaml           │                   │
│  │  ├─▶ architecture-recommendations.json   │                   │
│  │  └─▶ agent-playbook.yaml (guardrail)     │                   │
│  │                                           │                   │
│  └──────────────────────────────────────────┘                   │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

### Pattern Routing by Type

Different pattern types update different systems:

| Pattern Type | code-review-patterns.yaml | architecture-recommendations.json | agent-playbook.yaml |
|--------------|---------------------------|-----------------------------------|---------------------|
| **Architecture** | ✅ Detect violations | ✅ Add to recommendations | ✅ Add as guardrail |
| **DI/Patterns** | ✅ Check registrations | ❌ Not architectural | ✅ Add as leverage |
| **Security** | ✅ Scan for issues | ✅ Add to recommendations | ✅ Add as guardrail |
| **Performance** | ✅ Detect anti-patterns | ✅ Add to recommendations | ✅ Add as hygiene |
| **Conventions** | ✅ Check naming/style | ❌ Not architectural | ✅ Add as hygiene |

### File Formats

#### 1. code-review-patterns.yaml (Already Implemented)

```yaml
patterns:
  - id: ARCH-LAYER-001
    category: Architecture
    priority: Critical
    title: Domain layer must not reference Infrastructure
    rule: >
      Domain entities and interfaces should have no dependencies
      on Infrastructure layer. Keep domain pure.
    detection:
      files: ["**/*.Domain/**/*.cs"]
      pattern: "using.*\\.Infrastructure"
    # ... rest of pattern
```

#### 2. architecture-recommendations.json (New)

```json
{
  "schemaVersion": "1.0.0",
  "lastUpdated": "2025-12-11T14:30:00Z",
  "source": "pr-feedback-learning",
  "recommendations": {
    "guardrails": [
      {
        "id": "ARCH-G001",
        "category": "Architecture",
        "priority": "Critical",
        "title": "Domain layer must not reference Infrastructure",
        "description": "Keep domain layer pure - no dependencies on Infrastructure",
        "rationale": "Maintaining clean architecture boundaries ensures domain logic remains portable and testable",
        "source": {
          "type": "pr-feedback",
          "pr": 1045,
          "reviewer": "Ali Bijanfar",
          "date": "2025-01-15"
        },
        "implementation": {
          "check": "Scan Domain project for Infrastructure references",
          "frequency": "every-commit",
          "automation": "code-review command"
        }
      }
    ],
    "leverage": [
      {
        "id": "ARCH-L001",
        "category": "Refactoring",
        "priority": "Medium",
        "title": "Extract vendor-specific code to Infrastructure",
        "pattern": "When touching Abstractions with vendor names, extract to Infrastructure",
        "benefit": "Improves testability and enables vendor switching",
        "source": {
          "type": "pr-feedback",
          "pr": 1045,
          "reviewer": "Ali Bijanfar"
        }
      }
    ],
    "hygiene": [
      {
        "id": "ARCH-H001",
        "category": "Documentation",
        "priority": "Low",
        "title": "Add XML comments to public APIs",
        "trigger": "When modifying public interface or class",
        "action": "Add /// summary comments",
        "benefit": "Improves discoverability and IntelliSense"
      }
    ]
  }
}
```

#### 3. agent-playbook.yaml (Enhanced)

```yaml
# Existing structure enhanced with learned patterns

backend:
  guardrails:
    - id: BE-G01
      rule: "Api controllers must only call Application services"
      enforcement: always
      source: architecture-review

    - id: BE-G02  # NEW: From PR feedback
      rule: "Domain layer must not reference Infrastructure"
      enforcement: always
      source: pr-feedback
      prSource:
        pr: 1045
        reviewer: Ali Bijanfar
        date: 2025-01-15
      detection:
        files: ["**/*.Domain/**/*.cs"]
        pattern: "using.*\\.Infrastructure"
      remediation: >
        Remove Infrastructure dependency. If you need external services,
        define an interface in Domain and implement in Infrastructure.

  leverage:
    - id: BE-L01
      pattern: "When adding new entity, follow Repository+CQRS pattern"
      source: architecture-review

    - id: BE-L02  # NEW: From PR feedback
      pattern: "When touching DI registrations, verify lifetime selection"
      guidance: |
        • Transient: Stateless services (Query, Command, Repository)
        • Scoped: Per-request state (DbContext, IRequestContext)
        • Singleton: Global shared state (Cache, Configuration)
      source: pr-feedback
      prSource:
        pr: 1045
        thread: 4269

  hygiene:
    - id: BE-H01
      trigger: "When touching a file"
      action: "Add missing XML doc comments to public members"
      source: architecture-review

    - id: BE-H02  # NEW: From PR feedback
      trigger: "When touching entity classes"
      action: "Ensure audit fields present (CreatedOn, CreatedBy, UpdatedOn, UpdatedBy)"
      source: pr-feedback
```

## Consequences

### Positive

1. **Faster Team Learning**
   - Extract pattern once → Apply everywhere
   - New team members benefit from senior knowledge
   - Patterns captured in machine-readable format

2. **Reduced Review Burden**
   - Same issues not repeated in every PR
   - Reviewers focus on logic, not patterns
   - Automated checking catches common issues

3. **Improved Agent Behavior**
   - Agents learn team conventions automatically
   - Agent-generated code follows PR feedback patterns
   - Fewer back-and-forth iterations

4. **Architecture Evolution Tracking**
   - See how architectural patterns evolve over time
   - Track which patterns are most commonly violated
   - Data-driven architecture decisions

5. **Cross-Project Knowledge Transfer**
   - Patterns can be exported and shared
   - Common patterns across projects can be identified
   - Best practices propagate faster

### Negative

1. **Initial Setup Overhead**
   - Requires `/work:init` to set up files
   - First few PRs need manual pattern extraction
   - Learning curve for pattern extraction command

2. **Pattern Maintenance**
   - Patterns may become outdated
   - Need periodic review and cleanup
   - False positives may need tuning

3. **Over-Enforcement Risk**
   - Too many patterns may slow development
   - Edge cases may be blocked incorrectly
   - Balance needed between guidance and flexibility

4. **Multi-System Coordination**
   - Updates to 3 files must stay in sync
   - Conflicting patterns need resolution
   - Schema changes affect multiple files

### Mitigations

1. **Gradual Adoption**
   - Start with code-review-patterns.yaml only
   - Add architecture recommendations gradually
   - Enable agent playbook updates when confident

2. **Pattern Quality Gates**
   - Manual review before accepting patterns
   - Confidence scoring for extracted patterns
   - Easy disable/delete for bad patterns

3. **Regular Cleanup**
   - Quarterly pattern review sessions
   - Remove patterns with high false positive rates
   - Update patterns as architecture evolves

4. **Override Mechanisms**
   - Allow developers to disable specific patterns
   - Provide "ignore" comments for edge cases
   - Escalation path for pattern disputes

## Implementation Plan

### Phase 1: Enhanced Pattern Extraction (Week 1-2)

**Goal:** Extract patterns that can update multiple systems

**Tasks:**
1. Enhance `/quality:extract-review-patterns` command:
   - Add pattern type classification (architecture, di, security, etc.)
   - Generate outputs for all three files
   - Provide preview of what will be added where

2. Create update templates:
   - Template for architecture-recommendations.json entry
   - Template for agent-playbook.yaml guardrail/leverage/hygiene
   - Unified pattern structure across all files

3. Add routing logic:
   - Determine which files to update based on pattern type
   - Handle conflicts (pattern already exists)
   - Provide clear diff of changes

**Acceptance Criteria:**
- ✅ `/quality:extract-review-patterns` generates updates for all applicable files
- ✅ User can preview changes before applying
- ✅ Routing logic correctly categorizes patterns by type
- ✅ All three files maintain valid schemas after update

### Phase 2: Architecture Recommendations Integration (Week 3)

**Goal:** Use recommendations to guide design and code review

**Tasks:**
1. Create `architecture-recommendations.json` schema
2. Implement recommendation loader in `/workflow:design` command:
   - Load guardrails → Check design options against them
   - Load leverage patterns → Suggest during design

3. Integrate with `/quality:code-review`:
   - Check against architecture guardrails
   - Report violations with recommendation ID

4. Add CLI commands:
   - `/recommendations:list` - Show all active recommendations
   - `/recommendations:view <id>` - View details
   - `/recommendations:disable <id>` - Temporarily disable

**Acceptance Criteria:**
- ✅ Recommendations file has valid schema
- ✅ Design command considers architecture guardrails
- ✅ Code review reports violations with recommendation IDs
- ✅ CLI commands work for viewing/managing recommendations

### Phase 3: Agent Playbook Enhancement (Week 4)

**Goal:** Agents automatically follow learned patterns

**Tasks:**
1. Enhance agent-playbook.yaml schema:
   - Add `source` field (architecture-review vs pr-feedback)
   - Add `prSource` metadata for traceability
   - Support confidence levels

2. Update `/workflow:deliver` command:
   - Load agent playbook before agent work
   - Pass guardrails to dev-agent
   - Validate compliance after implementation

3. Add agent awareness:
   - dev-agent reads and follows playbook rules
   - qa-agent validates against guardrails
   - eval-agent checks playbook compliance

**Acceptance Criteria:**
- ✅ Agent playbook contains both review-generated and PR-learned rules
- ✅ Agents load and follow playbook during delivery
- ✅ Compliance status included in delivery report
- ✅ Violations trigger warnings or blocks (based on enforcement level)

### Phase 4: Feedback Loop Optimization (Week 5-6)

**Goal:** Close the loop - measure and improve

**Tasks:**
1. Add pattern usage tracking:
   - Count how many times pattern detected
   - Track false positive rate
   - Measure time saved (issues caught before PR)

2. Pattern evolution:
   - Merge similar patterns automatically
   - Suggest pattern updates based on usage
   - Deprecate patterns with high false positives

3. Reporting dashboard:
   - Show most common patterns
   - Identify areas needing more patterns
   - Track pattern effectiveness over time

4. Cross-project learning:
   - Export patterns from one project
   - Import vetted patterns to new projects
   - Share pattern library across organization

**Acceptance Criteria:**
- ✅ Pattern usage metrics tracked and reported
- ✅ False positive rate monitored per pattern
- ✅ Dashboard shows pattern effectiveness
- ✅ Patterns can be exported/imported between projects

## Success Metrics

### Immediate (Phase 1-2)
- **Pattern extraction rate**: >60% of merged PRs generate at least 1 pattern
- **Multi-system updates**: Patterns update 2+ systems automatically
- **Extraction time**: <2 minutes to extract and apply patterns

### Medium-term (Phase 3-4)
- **Pre-PR detection**: 50%+ of common PR feedback caught by `/quality:code-review`
- **Agent compliance**: 90%+ of agent code follows playbook rules
- **Review time reduction**: -25% time spent on pattern-related feedback

### Long-term (3-6 months)
- **Pattern library growth**: 100+ patterns across categories
- **False positive rate**: <5% for high-priority patterns
- **Team consistency**: Same patterns applied uniformly regardless of reviewer
- **Knowledge retention**: New team members productive faster with pattern library

## Related Documents

- [ADR-0004: Architecture-Aware Agent System](0004-architecture-aware-agents.md)
- [PR Comments System Plan](../plans/pr-comments-system.md)
- `/quality:extract-review-patterns` command
- `/quality:code-review` command
- `/work:init` command

## Future Enhancements

### Pattern Confidence Scoring
Use ML to score pattern quality:
- High confidence: Auto-apply
- Medium confidence: Suggest with warning
- Low confidence: Require manual review

### Natural Language Queries
Ask questions about patterns:
- "What patterns apply to DI lifetime selection?"
- "Show me all security-related patterns"
- "Which patterns came from Ali's reviews?"

### Cross-Project Pattern Marketplace
Share patterns across organization:
- Public pattern library (vetted, common patterns)
- Project-specific extensions
- Community voting on pattern quality

### Integration with Static Analysis
Export patterns to linters:
- Generate ESLint rules from patterns
- Create StyleCop rules from conventions
- Auto-configure SonarQube

---

**Decision Made By:** System Architect
**Approved By:** George
**Implementation Start:** 2025-12-11
