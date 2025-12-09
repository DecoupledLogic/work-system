# Presentation Deck Guide

## Purpose

Presentation decks serve as alignment tools for communicating technical initiatives across diverse audiences: executives, product management, and engineering teams. A well-structured deck enables modular storytelling—technical teams can dive into implementation details while leadership focuses on business impact and resource requirements.

## When to Create a Presentation Deck

Create a deck when:

- **Scope is significant**: Initiative affects multiple services, teams, or systems
- **Multiple stakeholders**: Different audiences need different depth (execs, PMs, devs)
- **Resource approval needed**: Estimate review, headcount allocation, timeline commitment
- **Architectural changes**: New patterns, service boundaries, or integration approaches
- **Risk communication**: Deployment strategy, rollback plans, failure modes

Skip the deck for:

- Small bug fixes or incremental features
- Single-team, single-service changes
- Low-risk updates with established patterns

## Core Structure

### 1. Executive Summary `[EXEC]`

**Audience**: Leadership, decision-makers
**Purpose**: 3-5 minute overview for approval/resource allocation
**Content**:

- **Problem**: What's broken? Business impact (revenue, support, UX)
- **Solution**: High-level approach in 3-5 bullets
- **Timeline**: Emergency path vs. complete solution
- **ROI**: Quantifiable benefits (zero incidents, reduced support load, foundation for X)

**Example**:

```markdown
## [EXEC] Executive Summary

### The Problem
- Users with active paid subscriptions are getting locked out
- Root cause: Missing renewal signal from billing system
- Impact: Support escalations, revenue loss, manual intervention required

### The Solution
- **Immediate Fix**: Webhook-driven sync (Epic 1) - 34 hours
- **Resilience**: Grace period + reconciliation (Epics 2-3) - 32 hours
- **Future-Ready**: Event-driven architecture (Epics 4-6) - 50 hours

### Timeline
- **Emergency Path**: Deploy Epic 1 in 4-5 days
- **Complete Solution**: 138 hours (~17 days for 1 dev, ~9 days for 2 devs)
- **ROI**: Zero lockout incidents, reduced support load, billing feature foundation
```

### 2. Problem Statement `[ALL]`

**Audience**: All stakeholders
**Purpose**: Shared understanding of why this work matters

**Content**:

- **Current State**: Step-by-step description of broken behavior
- **Why This Happens**: Technical root cause (missing webhook, no reconciliation)
- **Business Impact**: Customer satisfaction, support load, revenue risk, scalability

### 3. Solution Overview `[ALL]`

**Audience**: All stakeholders
**Purpose**: Conceptual approach without implementation details

**Content**:

- **Layered Approach**: Primary path, safety nets, user protections
- **Key Mechanisms**: Webhooks as triggers, APIs for truth, reconciliation for consistency
- **Expected Behavior**: How the system will work after changes

### 4. Architecture Principles `[DEV]` `[PM]`

**Audience**: Product + Engineering
**Purpose**: Design decisions and tradeoffs

**Content**:

- **Core Invariants**: Systems of record, data flow direction, responsibility boundaries
- **Data Flow Diagram**: Visual representation of components and events
- **Key Patterns**: Webhooks vs. APIs, event-driven vs. synchronous, caching strategies

**Example**:

````markdown
### Core Invariants
1. **Stax Bill is the system of record** for billing and subscription lifecycle
2. **Subscription service projects** Stax Bill state into our domain
3. **Entitlements service converts** subscription state into runtime access decisions

### Data Flow
```
Stax Bill (Truth)
  → Webhook Events (Trigger)
    → Subscription Service (Projection)
      → SubscriptionStateChanged Events
        → Entitlements Service (Access Control)
          → Application (Feature Gates)
```
````

### 5. Epic Breakdown `[PM]` `[DEV]`

**Audience**: Product + Engineering

**Purpose**: Scope definition and feature-level understanding

**Content**:

- **Per Epic**: Goal, Features (3-5 bullets), Value/Impact
- **Structure**: Mirror the delivery plan structure (Epics 0-N)
- **Brevity**: 3-5 slides, one epic per slide (or two epics if small)

**Template**:

```markdown
### Epic X: [Name] ([Hours] hours)
**Goal**: [One sentence]

**Features**:
- [Feature 1]: [One sentence description]
- [Feature 2]: [One sentence description]
- [Feature 3]: [One sentence description]

**Value**: [Why this epic matters - business or technical benefit]
```

### 6. Timeline & Estimate `[ALL]`

**Audience**: All stakeholders

**Purpose**: Resource planning and prioritization

**Content**:

- **Summary Table**: Epic, Description, Hours, Days (1 dev), Priority
- **Parallelization Options**: 2+ developers, critical path analysis
- **Emergency Path**: Minimum viable scope for immediate relief

**Example**:

```markdown
| Epic | Description              | Hours | Days (1 dev) | Priority |
|------|--------------------------|-------|--------------|----------|
| 1    | Renewal Fix              | 34    | 4-5          | P0       |
| 2    | Schema Enhancement       | 8     | 1            | P0       |
| 3    | Reconciliation Safety Net| 24    | 3            | P0       |
| 0    | Cross Cutting Concerns   | 22    | 3            | P0       |
|      | **TOTAL**                | **88**| **~11**      |          |

### Parallelization Options
- **2 Developers**: ~6 days (Epics 1-2 in parallel with Epic 3)
- **Emergency Path**: Epic 1 only → 4-5 days → Stop the bleeding
```

### 7. Success Metrics `[ALL]`

**Audience**: All stakeholders

**Purpose**: Define "done" and post-deployment validation

**Content**:

- **Pre-Deployment Validation**: Checklist before going live
- **Post-Deployment KPIs**: Measurable outcomes per epic
- **Monitoring**: Dashboards, alerts, thresholds

**Example**:

```markdown
### Pre-Deployment Validation
- ✅ All unit and integration tests passing
- ✅ Backfill completes successfully for all active subscriptions
- ✅ Rollback procedures tested in staging

### Post-Deployment KPIs
**Epic 1 (Renewal Fix)**:
- Webhook success rate: >99% within 1 minute
- Sync latency: <5 seconds p95
- Zero lockout incidents after renewals
```

### 8. Deployment Strategy `[PM]` `[DEV]`

**Audience**: Product + Engineering

**Purpose**: Risk mitigation through phased rollout

**Content**:

- **Phased Rollout**: Week-by-week plan with validation gates
- **Emergency Fast-Track**: Minimum scope for immediate deployment
- **Risk Assessment**: Per-phase risk level (Low/Medium/High)

### 9. Risk Mitigation `[ALL]`

**Audience**: All stakeholders

**Purpose**: Failure mode analysis and recovery plans

**Content**:

- **What Could Go Wrong**: Common failure scenarios
- **Mitigation**: How we prevent or detect each failure
- **Recovery Time**: How quickly we can recover
- **Impact**: Blast radius if failure occurs
- **Safety Mechanisms**: Idempotency, rollback, feature flags

### 10. Technical Deep Dives `[DEV]`

**Audience**: Engineering only

**Purpose**: Implementation-level clarity for developers

**Content**:

- **Before/After Flows**: Step-by-step behavior comparison
- **Code Examples**: Pseudocode or actual implementation snippets
- **Edge Cases**: Failure scenarios, race conditions, retry logic

**When to Include**:

- Complex state transitions (renewal flow, payment failures)
- Non-obvious patterns (grace period calculation, reconciliation algorithm)
- Integration points (webhook handling, event publishing)

**When to Skip**:

- Standard CRUD operations
- Well-established patterns (REST endpoints, database queries)
- Implementation details covered in delivery plan

### 11. Architecture Vision `[PM]` `[DEV]`

**Audience**: Product + Engineering

**Purpose**: Long-term direction beyond immediate fix

**Content**:

- **Current Architecture**: Diagram showing current state and pain points
- **Future Architecture**: Diagram showing target state (often from architecture blueprint)
- **Migration Strategy**: How we get from current to future (dual-write, gradual rollout)

**Example**:

````markdown
### Current Architecture (Tight Coupling)
```
Subscription Service
  ↓ (HTTP API Call)
Entitlements Service
```
- **Problem**: Synchronous dependency, retry complexity, cascading failures

### Future Architecture (Loose Coupling - Epic 5)
```
Subscription Service
  ↓ (Publish Event to SQS)
Message Bus (AWS SQS)
  ↓ (Subscribe to Events)
Entitlements Service
```
- **Benefits**: Services decoupled, async processing, better fault tolerance
````

### 12. Expected Outcomes `[EXEC]`

**Audience**: Leadership

**Purpose**: Business value and customer impact

**Content**:

- **Immediate Benefits**: Quick wins from P0 epics
- **Long-Term Benefits**: Strategic value from P1 epics
- **Customer Experience**: Before/after comparison

### 13. Key Decision Points `[ALL]`

**Audience**: All stakeholders

**Purpose**: Drive discussion and alignment

**Content**:

- **Scope for Initial Release**: Options (emergency vs. complete)
- **Configuration Choices**: Grace period duration, reconciliation frequency
- **Deployment Timeline**: Phased vs. aggressive vs. emergency

### 14. Resource Requirements `[EXEC]`

**Audience**: Leadership

**Purpose**: Headcount, infrastructure, dependency mapping

**Content**:

- **Development Team**: Roles, duration, parallelization
- **Infrastructure**: Services, quotas, configuration access
- **Dependencies**: Other teams, external systems, approvals

### 15. Next Steps `[ALL]`

**Audience**: All stakeholders

**Purpose**: Call to action and pre-development checklist

**Content**:

- **Immediate Actions**: Approvals, resource assignments, scheduling
- **Pre-Development**: Monitoring setup, rollback docs, staging tests
- **Development Kickoff**: Sprint planning, epic sequencing

### 16. Questions & Discussion `[ALL]`

**Audience**: All stakeholders

**Purpose**: Facilitate Q&A and capture action items

**Content**:

- **Technical Contacts**: Who owns each component
- **Open Discussion Topics**: Preference questions, tradeoffs
- **Thank You**: Closing slide

### 17. Appendix: Glossary (Optional)

**Audience**: All stakeholders (especially non-technical)
**Purpose**: Define domain-specific terminology
**Content**: Alphabetical list of terms with one-sentence definitions

## Audience Tagging System

Use consistent tags to indicate slide relevance:

- `[EXEC]`: Executive summary, outcomes, resource requirements
- `[PM]`: Product management - epics, features, deployment strategy
- `[DEV]`: Engineering - architecture, technical deep dives, code
- `[ALL]`: All audiences - problem, solution, timeline, metrics, risks

**Usage in markdown**:

```markdown
## [EXEC] Executive Summary
## [ALL] Problem Statement
## [DEV] [PM] Architecture Principles
```

**Benefits**:

- Easy to create filtered versions (execs-only, devs-only)
- Presenters know which slides to skip for specific audiences
- Stakeholders can self-filter when reviewing async

## Modularity Guidelines

### Creating Modular Decks

1. **Self-Contained Slides**: Each slide should make sense without prior slides (except problem→solution dependency)
2. **Section Markers**: Use horizontal rules (`---`) to separate slides
3. **Consistent Formatting**: Use same structure for similar slide types (all epic slides follow same template)
4. **Optional Deep Dives**: Technical slides are additive, not required for understanding

### Combining Slides for Different Audiences

**For Executives** (15-20 minute deck):

1. Executive Summary `[EXEC]`
2. Problem Statement `[ALL]`
3. Solution Overview `[ALL]`
4. Timeline & Estimate `[ALL]`
5. Expected Outcomes `[EXEC]`
6. Key Decision Points `[ALL]`
7. Resource Requirements `[EXEC]`
8. Next Steps `[ALL]`

**For Product Management** (30-40 minute deck):

1. Executive Summary `[EXEC]`
2. Problem Statement `[ALL]`
3. Solution Overview `[ALL]`
4. Architecture Principles `[DEV]` `[PM]`
5. Epic Breakdown `[PM]` `[DEV]` (all epics)
6. Timeline & Estimate `[ALL]`
7. Success Metrics `[ALL]`
8. Deployment Strategy `[PM]` `[DEV]`
9. Risk Mitigation `[ALL]`
10. Architecture Vision `[PM]` `[DEV]` (if applicable)
11. Expected Outcomes `[EXEC]`
12. Key Decision Points `[ALL]`
13. Next Steps `[ALL]`

**For Engineering** (60+ minute deck):

- All slides (include technical deep dives)

## Alignment with Other Artifacts

### Delivery Plan Alignment

- **Epic structure** in deck must match delivery plan exactly
- **Estimate hours** must match estimate.csv (source of truth)
- **Features** in deck should be high-level summaries of delivery plan features
- **Success metrics** should align with acceptance criteria in delivery plan

### Architecture Blueprint Alignment

- **Architecture principles** in deck come from blueprint's "Core Principles" section
- **Data flow diagrams** should visualize blueprint's component interactions
- **Architecture vision** slides should reference blueprint for details
- **Event contracts** and domain models come from blueprint

### Estimate Alignment

- **Timeline table** must exactly match estimate.csv totals
- **Epic hour counts** must match CSV (epic breakdown is source of truth)
- **Parallelization options** should be based on epic dependencies in estimate

## Common Pitfalls

### ❌ Avoid These Mistakes

1. **Inconsistent estimates**: Deck shows 88 hours, CSV shows 138 hours
   - **Fix**: Always reference estimate.csv as source of truth

2. **Missing audience tags**: Can't filter slides by audience
   - **Fix**: Tag every slide with `[EXEC]`, `[PM]`, `[DEV]`, or `[ALL]`

3. **Technical jargon for executives**: Executives see implementation details
   - **Fix**: Keep `[EXEC]` slides at business level (outcomes, ROI, resource needs)

4. **No decision prompts**: Presentation ends without clear next steps
   - **Fix**: Include "Key Decision Points" slide with explicit options

5. **Stale deck**: Deck doesn't reflect latest delivery plan changes
   - **Fix**: Version control alignment - update deck when delivery plan changes

6. **Epic mismatch**: Deck shows different epics than delivery plan
   - **Fix**: Epic breakdown in deck is summary of delivery plan, not independent source

7. **Missing risk mitigation**: No failure scenarios or rollback plans
   - **Fix**: Always include "What Could Go Wrong?" section with recovery times

8. **Unclear scope options**: Leadership doesn't understand emergency vs. complete
   - **Fix**: Provide explicit scope options (Epic 1 only, Epics 1-3, All epics)

## Maintenance and Updates

### When to Update the Deck

**Triggers for updates**:

- Estimate hours change in CSV
- New epics added to delivery plan
- Architecture blueprint updated with new patterns
- Deployment strategy changes (phased → emergency)
- Risk assessment changes (new failure modes discovered)

### Update Process

1. **Identify changed section**: Epic hours, features, architecture
2. **Update deck section**: Modify only affected slides
3. **Verify alignment**: Cross-check with estimate.csv, delivery-plan.md, architecture blueprint
4. **Update version/date**: Add "Last Updated: YYYY-MM-DD" to deck header
5. **Notify stakeholders**: If already presented, send update summary

## Template Usage

When creating a new presentation deck:

1. **Copy structure** from existing deck (this guide's "Core Structure" section)
2. **Adapt slide types** to your initiative (not all slides needed for every project)
3. **Tag slides** with audience markers
4. **Cross-reference** estimate.csv, delivery plan, architecture blueprint
5. **Review** for consistency (hours match, epics match, principles align)

## Examples by Initiative Type

### Emergency Fix Initiative

**Include**: Problem, Solution, Epic 1 only, Timeline (emergency path), Risk Mitigation, Next Steps
**Skip**: Architecture vision, future epics, long-term benefits
**Audience**: Execs + Engineering (get approval, deploy fast)

### Greenfield Architecture Initiative

**Include**: All slides, heavy emphasis on Architecture Principles, Vision, Event Contracts
**Skip**: Emergency path (no broken production behavior)
**Audience**: All audiences (alignment across org)

### Incremental Enhancement

**Include**: Problem, Solution, 1-2 Epics, Timeline, Metrics
**Skip**: Executive summary (no resource approval needed), Deep dives (standard patterns)
**Audience**: PM + Engineering (execution alignment)

## Markdown Linting Requirements

All presentation decks must comply with the markdown standards defined in [markdown-standards.md](../markdown-standards.md).

### Quick Validation

```bash
markdownlint presentation-deck.md
```

See [markdown-standards.md](../markdown-standards.md) for complete linting rules, IDE setup, and enforcement policies.

## Summary

A well-crafted presentation deck:

- **Aligns** with delivery plan, estimate, and architecture blueprint
- **Targets** multiple audiences with tagged, modular slides
- **Drives** decisions with clear options and next steps
- **Mitigates** risk with failure modes and recovery plans
- **Evolves** with the initiative (updated when artifacts change)

Use this guide as a checklist when creating or reviewing presentation decks for any initiative.
