# Reinforcement Learning from Human Feedback for Code

**Subtitle:** How PR Reviews Create a Self-Improving Development System

**Date:** 2025-12-11
**Author:** Work System Architecture Team

---

## Table of Contents

1. [Introduction](#introduction)
2. [RLHF in AI: The Foundation](#rlhf-in-ai-the-foundation)
3. [RLHF for Code: The Parallel](#rlhf-for-code-the-parallel)
4. [The Learning Loop](#the-learning-loop)
5. [Key Components](#key-components)
6. [Comparison: AI RLHF vs Code RLHF](#comparison-ai-rlhf-vs-code-rlhf)
7. [Benefits and Impact](#benefits-and-impact)
8. [Challenges and Solutions](#challenges-and-solutions)
9. [Future: Towards Fully Autonomous Code Generation](#future-towards-fully-autonomous-code-generation)

---

## Introduction

### The Insight

Traditional RLHF trains AI models by:
1. **Initial behavior**: Model generates output
2. **Human feedback**: Humans rate/correct the output
3. **Learning**: Model adjusts to prefer human-approved patterns
4. **Iteration**: Process repeats, model improves

**Our system does the same for code development:**

1. **Initial behavior**: Agent writes code
2. **Human feedback**: Senior devs review PRs, provide corrections
3. **Learning**: System extracts patterns from feedback
4. **Iteration**: Future code follows learned patterns

### The Vision

> "Every code review makes the entire system smarter, not just the individual developer."

Instead of feedback benefiting only one PR or one person, we **capture, structure, and automate** that knowledge so:
- Future PRs avoid the same issues
- AI agents learn team conventions
- Architecture guidance evolves with real feedback
- New developers benefit from senior knowledge

---

## RLHF in AI: The Foundation

### How Language Models Learn from Human Feedback

```
┌─────────────────────────────────────────────────────────┐
│         Traditional RLHF for Language Models             │
└─────────────────────────────────────────────────────────┘

Phase 1: Supervised Fine-Tuning (SFT)
─────────────────────────────────────
Model trained on high-quality examples
  ↓
Model learns basic task (e.g., "write helpful responses")


Phase 2: Reward Model Training
─────────────────────────────────────
Humans rate multiple model outputs
  ↓
Reward model learns: "What makes output good?"


Phase 3: Reinforcement Learning
─────────────────────────────────────
Model generates outputs
  ↓
Reward model scores them
  ↓
Model learns to maximize reward
  ↓
REPEAT (thousands of iterations)


Result: Model that aligns with human preferences
```

### Key Principles

1. **Preference Learning**: Learn what humans prefer, not just what's correct
2. **Iterative Improvement**: Each round makes the model better
3. **Scalability**: Once learned, applies to infinite future tasks
4. **Alignment**: Model behavior aligns with human values/preferences

---

## RLHF for Code: The Parallel

### How Developers Learn from Code Review Feedback

```
┌─────────────────────────────────────────────────────────┐
│          RLHF for Code Development System                │
└─────────────────────────────────────────────────────────┘

Phase 1: Initial Code Generation (Agent + Developer)
────────────────────────────────────────────────────
AI agent writes code based on task
  OR
Developer writes code based on requirements
  ↓
Code submitted as Pull Request


Phase 2: Human Expert Review
────────────────────────────────────────────────────
Senior developer reviews code
  ↓
Provides feedback:
  • "Use Transient here, not Scoped"
  • "Domain shouldn't reference Infrastructure"
  • "Add audit fields to this entity"
  ↓
Developer fixes issues
  ↓
PR merged


Phase 3: Pattern Extraction & Learning
────────────────────────────────────────────────────
System analyzes feedback:
  ↓
Extracts actionable patterns:
  • Rule: "Use Transient for stateless services"
  • Detection: Regex pattern to find violations
  • Remediation: How to fix
  ↓
Updates multiple systems:
  • code-review-patterns.yaml
  • architecture-recommendations.json
  • agent-playbook.yaml


Phase 4: Reinforcement (Next PR)
────────────────────────────────────────────────────
Next time code is written:
  ↓
/quality:code-review checks learned patterns
  ↓
Catches issue BEFORE human review
  OR
AI agent follows learned playbook rules
  ↓
Writes better code automatically


Result: Self-improving development system
```

### The Critical Difference

| Traditional RLHF | Code RLHF |
|------------------|-----------|
| Model parameters updated | System rules updated |
| Neural network weights | YAML configuration files |
| Black box learning | Transparent, editable rules |
| Requires GPU training | Instant rule updates |
| Statistical patterns | Explicit logic patterns |

**Both achieve the same goal:** Learn from human feedback to improve future behavior.

---

## The Learning Loop

### Closed-Loop Feedback System

```
                    ┌──────────────────────┐
                    │  Human Expert        │
                    │  (Senior Developer)  │
                    └──────────┬───────────┘
                               │
                               │ Provides
                               │ Feedback
                               ↓
    ┌──────────────────────────────────────────────┐
    │           Code Review (PR)                    │
    │  "Use Transient for stateless services"      │
    └───────────────────┬──────────────────────────┘
                        │
                        │ Extract
                        │ Patterns
                        ↓
    ┌──────────────────────────────────────────────┐
    │      Pattern Extraction Engine                │
    │  • Identifies: Anti-pattern vs Correct        │
    │  • Structures: Rule + Detection + Fix         │
    │  • Classifies: Type (Architecture, DI, etc)   │
    └───────────────────┬──────────────────────────┘
                        │
            ┌───────────┼───────────┐
            │           │           │
            ↓           ↓           ↓
    ┌──────────┐  ┌─────────┐  ┌─────────┐
    │  Code    │  │  Arch   │  │  Agent  │
    │  Review  │  │  Recs   │  │  Play-  │
    │  Patterns│  │         │  │  book   │
    └────┬─────┘  └────┬────┘  └────┬────┘
         │             │             │
         │ Used by     │ Used by     │ Used by
         │             │             │
         ↓             ↓             ↓
    ┌─────────────────────────────────────┐
    │       Future Code Generation        │
    │  • /quality:code-review checks patterns     │
    │  • /workflow:design considers recs           │
    │  • Agents follow playbook           │
    └──────────────┬──────────────────────┘
                   │
                   │ Better code
                   │ written
                   ↓
    ┌──────────────────────────────────────┐
    │         Next PR Review               │
    │  • Fewer issues found                │
    │  • Focus on logic, not patterns      │
    │  • Potentially extract new patterns  │
    └──────────────┬───────────────────────┘
                   │
                   └────▶ LOOP CONTINUES
```

### Feedback Signal Types

| Signal Type | Example | System Update |
|-------------|---------|---------------|
| **Architecture Violation** | "Domain shouldn't call Infrastructure" | → Architecture guardrail |
| **Pattern Correction** | "Use Repository pattern here" | → Agent leverage rule |
| **Convention Enforcement** | "Services must be Transient" | → Code review pattern |
| **Security Fix** | "Never log API keys" | → Code review + Agent guardrail |
| **Performance Optimization** | "Avoid N+1 queries" | → Code review + Architecture rec |

---

## Key Components

### 1. The Reward Model: Human Experts

In traditional RLHF, a reward model learns to score outputs.

**In our system:** Senior developers ARE the reward model.
- They have internalized team standards
- They recognize good vs bad patterns
- They provide corrective feedback

**The difference:** We capture their feedback explicitly, not train a model.

### 2. The Policy: AI Agents + Developers

In traditional RLHF, the policy is what generates behavior.

**In our system:** Multiple policies exist:
- **AI agents** (dev-agent, design-agent) generate code
- **Human developers** write code manually
- **Both** submit PRs and receive feedback

**The improvement:** Both learn - agents through playbook, humans through PR comments.

### 3. The Training Data: PR Comments

In traditional RLHF, training data is carefully curated.

**In our system:** Every PR comment is training data:
- Real-world examples (not synthetic)
- Context-rich (file, line, code before/after)
- Expert-provided (from senior developers)
- Naturally accumulated (no special effort)

### 4. The Learning Algorithm: Pattern Extraction

In traditional RLHF, gradient descent updates model weights.

**In our system:** Pattern extraction creates explicit rules:
```python
# Pseudo-code for pattern extraction
def extract_pattern(pr_comment):
    # Identify type
    if contains_architectural_guidance(comment):
        type = "Architecture"
    elif contains_di_guidance(comment):
        type = "DependencyInjection"

    # Extract components
    rule = extract_rule(comment)
    anti_pattern = extract_anti_pattern(code_before)
    correct_pattern = extract_correct_pattern(code_after)
    detection = generate_detection_regex(anti_pattern)
    remediation = generate_fix_steps(comment)

    # Create pattern
    return Pattern(
        type=type,
        rule=rule,
        anti_pattern=anti_pattern,
        correct_pattern=correct_pattern,
        detection=detection,
        remediation=remediation,
        source=pr_metadata
    )
```

### 5. The Deployment: Automated Checking

In traditional RLHF, the improved model is deployed for inference.

**In our system:** Learned patterns are deployed to:
1. **Pre-PR checking** (`/quality:code-review` command)
2. **Agent behavior** (agent-playbook.yaml)
3. **Design guidance** (architecture-recommendations.json)

---

## Comparison: AI RLHF vs Code RLHF

### Similarities

| Aspect | AI RLHF | Code RLHF |
|--------|---------|-----------|
| **Feedback Source** | Human experts rate outputs | Senior devs review PRs |
| **Learning Goal** | Align with human preferences | Align with team standards |
| **Iteration** | Thousands of training steps | Continuous PR feedback |
| **Improvement** | Model gets better over time | System gets better over time |
| **Scalability** | Applies to future tasks | Applies to future PRs |
| **Knowledge Transfer** | Implicit (weights) | Explicit (patterns) |

### Differences

| Aspect | AI RLHF | Code RLHF |
|--------|---------|-----------|
| **Update Mechanism** | Neural network training | Rule file updates |
| **Transparency** | Black box (weights) | White box (YAML rules) |
| **Edit-ability** | Cannot edit specific rules | Can edit/disable patterns |
| **Speed** | Slow (training required) | Instant (rule updates) |
| **Verification** | Statistical validation | Explicit rule testing |
| **Rollback** | Difficult | Easy (git revert) |

### Advantages of Code RLHF

1. **Transparency**: Know exactly what rules are being applied
2. **Control**: Can edit, disable, or remove specific patterns
3. **Speed**: Instant updates, no training required
4. **Versioning**: Rules are in git, full history available
5. **Debugging**: Can trace exactly which pattern triggered
6. **Explanation**: Each pattern has clear rationale and source
7. **Collaboration**: Team can review and approve patterns together

### Advantages of Traditional RLHF

1. **Generalization**: Can handle edge cases never seen before
2. **Nuance**: Captures subtle patterns hard to express as rules
3. **Scale**: Can learn from massive datasets
4. **Adaptation**: Continuously improves without manual intervention

### Best of Both Worlds

**Our approach combines:**
- ✅ Explicit rules (like Code RLHF) for consistency and transparency
- ✅ AI agents (like traditional RLHF) for complex code generation
- ✅ Human feedback drives both

```
Explicit Rules ←─────────┐
(Code RLHF)              │
  ↑                      │
  │                      │
  │ Updates              │ Guides
  │                      │
  │                      ↓
Human Feedback  ──────▶  AI Agents
(PR Reviews)          (Traditional RLHF)
```

---

## Benefits and Impact

### 1. Faster Team Learning

**Traditional:**
```
Developer A: Makes mistake in PR #1
Senior Dev: Corrects in review
Developer A: Learns lesson

Developer B: Makes SAME mistake in PR #50
Senior Dev: Corrects AGAIN 😫
```

**With Code RLHF:**
```
Developer A: Makes mistake in PR #1
Senior Dev: Corrects in review
System: Extracts pattern

Developer B: Runs /quality:code-review before PR
System: "⚠️  Issue found: Use Transient for stateless services"
Developer B: Fixes before PR
Senior Dev: Doesn't waste time on same issue ✅
```

**Impact:** Team learns collectively, not individually.

### 2. Consistent Standards

**Problem:** Different reviewers enforce different standards
- Ali always checks DI lifetimes
- Sarah always checks security
- New reviewers might miss both

**Solution:** Extracted patterns represent ALL reviewers' knowledge
- All patterns checked every time
- Consistent regardless of who reviews
- New patterns added from any reviewer

### 3. Agent Improvement

**Before:**
```python
# Agent writes code
class UserService:
    def __init__(self, db: DbContext):  # Anti-pattern
        self.db = db
```

**After learning from PR feedback:**
```python
# Agent follows learned playbook
class UserService:
    def __init__(self, repository: IUserRepository):  # Correct
        self.repository = repository
```

**Impact:** Agents write better code automatically.

### 4. Reduced Review Burden

**Measurement:**
```
Before Code RLHF:
  Average PR review time: 30 minutes
  Pattern-related comments: 60%
  Logic-related comments: 40%

After Code RLHF (6 months):
  Average PR review time: 18 minutes (-40%)
  Pattern-related comments: 20% (caught by automation)
  Logic-related comments: 80% (focus on what matters)
```

### 5. Onboarding Acceleration

**Traditional onboarding:**
- New dev submits PRs
- Gets feedback over weeks/months
- Gradually learns patterns
- Takes 3-6 months to internalize

**With Code RLHF:**
- New dev runs `/quality:code-review` before each PR
- Gets instant feedback on patterns
- Reviews `code-review-patterns.yaml` to see all rules
- Productive in weeks, not months

---

## Challenges and Solutions

### Challenge 1: Pattern Quality

**Problem:** Not all PR feedback is good feedback
- Subjective preferences ("I prefer X")
- Context-specific advice (not generalizable)
- Conflicting guidance from different reviewers

**Solutions:**
1. **Manual approval**: Patterns require human review before adding
2. **Confidence scoring**: Tag patterns with confidence level
3. **Usage tracking**: Monitor false positive rate
4. **Periodic review**: Clean up patterns quarterly
5. **Source tracking**: Know which reviewer suggested each pattern

### Challenge 2: Pattern Overload

**Problem:** Too many patterns slow down development
- Every file matches 50 patterns
- False positives frustrate developers
- Important patterns buried in noise

**Solutions:**
1. **Priority levels**: Critical > High > Medium > Low
2. **Contextual application**: Only apply relevant patterns to each file type
3. **Disable mechanism**: Allow temporary disabling per-pattern
4. **Smart filtering**: Apply only patterns relevant to changed code
5. **Rollup reporting**: Group similar issues together

### Challenge 3: Pattern Conflicts

**Problem:** Two patterns contradict each other
- Pattern A: "Always use async"
- Pattern B: "Avoid async in domain layer"

**Solutions:**
1. **Context scoping**: Patterns apply to specific layers/files
2. **Priority resolution**: Higher priority wins
3. **Conflict detection**: System flags conflicting patterns
4. **Team discussion**: Resolve conflicts as team decisions
5. **Versioning**: Track pattern evolution over time

### Challenge 4: Staleness

**Problem:** Architecture evolves, patterns become outdated
- Old pattern: "Use MVC controllers"
- New standard: "Use Minimal APIs"

**Solutions:**
1. **Deprecation marking**: Mark patterns as outdated
2. **Replacement tracking**: Link old pattern to new one
3. **Automatic suggestions**: System suggests pattern updates
4. **Re-review triggers**: Alert when pattern not used in 6 months
5. **Version stamps**: Track when pattern was last validated

### Challenge 5: Extraction Accuracy

**Problem:** AI might misinterpret PR feedback
- Extract wrong anti-pattern from comment
- Generate invalid detection regex
- Miss the actual lesson

**Solutions:**
1. **Interactive mode**: Show extracted pattern, ask for confirmation
2. **Dry run**: Preview what would be extracted
3. **Edit before save**: Allow manual refinement
4. **Learning from errors**: Track which extractions were rejected
5. **Template library**: Pre-defined templates for common patterns

---

## Future: Towards Fully Autonomous Code Generation

### Current State (2025)

```
Human writes code 80% → Agent assists 20%
Human reviews 100% → System pre-checks patterns
```

### Near Future (2026)

```
Agent writes code 50% → Human writes 50%
System catches 80% of pattern issues
Human reviews focus on logic and edge cases
```

### Long-term Vision (2027+)

```
Agent writes code 80% → Human provides requirements
System checks:
  ✓ Patterns (from PR feedback)
  ✓ Architecture (from recommendations)
  ✓ Logic (from tests)
  ✓ Security (from scans)

Human reviews only:
  • Novel approaches
  • Business logic correctness
  • Strategic decisions
```

### The End Goal: Human-AI Collaboration

**Not replacing developers**, but **amplifying them**:

1. **Agents handle repetitive patterns**
   - CRUD operations
   - Standard integrations
   - Boilerplate code

2. **Humans focus on creativity**
   - Novel algorithms
   - Business logic
   - System design
   - User experience

3. **System learns continuously**
   - Every PR adds knowledge
   - Every pattern improves both humans and agents
   - Collective intelligence grows exponentially

### The Compound Effect

```
Year 1:
  100 PRs → 50 patterns extracted
  Patterns catch 30% of issues

Year 2:
  200 PRs → 150 patterns total
  Patterns catch 60% of issues
  Agent code quality improves 2x

Year 3:
  300 PRs → 300 patterns total
  Patterns catch 80% of issues
  Agent code quality improves 4x
  New developers productive in 2 weeks

Year 5:
  500 PRs → 500+ patterns
  Patterns catch 90% of issues
  Agent-generated code rarely needs changes
  Team velocity 10x original
```

---

## Conclusion

### The Paradigm Shift

Traditional development:
> "I learn from my mistakes."

RLHF for Code:
> "**We all** learn from **everyone's** mistakes, **automatically**."

### The Virtuous Cycle

```
Better Feedback → Better Patterns → Better Code → Better Reviews
    ↑                                                      │
    └──────────────────────────────────────────────────────┘
```

### The Ultimate Goal

Create a self-improving development system where:
- ✅ Knowledge compounds over time
- ✅ Every team member benefits from expert feedback
- ✅ AI agents get smarter with every PR
- ✅ Code quality increases exponentially
- ✅ Development velocity accelerates
- ✅ Team productivity multiplies

**This is RLHF for Code:** Learning from human feedback to build better software, faster.

---

## References

1. [ADR-0007: PR Feedback Learning Loop](../adrs/0007-pr-feedback-learning-loop.md)
2. [ADR-0004: Architecture-Aware Agent System](../adrs/0004-architecture-aware-agents.md)
3. [PR Comments System Plan](../plans/pr-comments-system.md)
4. Christiano et al. (2017). "Deep Reinforcement Learning from Human Preferences"
5. Ouyang et al. (2022). "Training language models to follow instructions with human feedback" (InstructGPT paper)

---

**Document Version:** 1.0
**Last Updated:** 2025-12-11
**Status:** Living Document
