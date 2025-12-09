# Product Strategy Guide

## Purpose

A product strategy document establishes the vision, north star metrics, OKRs, and strategic initiatives for a product or engagement. It serves as the foundational alignment document that informs all downstream work including delivery plans, PRDs, and architecture decisions.

## When to Create a Product Strategy

Create a product strategy when:

- **New consulting engagement**: Client engagement begins with strategy alignment
- **Product launch**: New product or major product line being introduced
- **Annual/Quarterly planning**: Strategic refresh for existing products
- **Pivot or repositioning**: Product direction fundamentally changing
- **Investment round**: Need to articulate vision and roadmap for stakeholders

Use simpler artifacts for:

- Single-feature additions to existing products
- Bug fixes or maintenance work
- Incremental enhancements within existing strategy

## Relationship to Other Artifacts

### Product Strategy Position in Workflow

```text
Product Strategy (Vision) ← Foundation for consulting engagements
  ↓ (informs)
Spike Reports (Research) ← Answers strategic questions
  ↓ (drives)
Delivery Plan (Implementation) ← Translates strategy into epics
  ↓ (breaks down to)
PRDs (Features) ← Individual feature requirements
```

### What Flows from Product Strategy

**To Delivery Plans**:

- **Vision** → Initiative framing
- **OKRs** → Success metrics
- **Initiatives** → Epic structure
- **Risks** → Mitigation stories

**To PRDs**:

- **Vision** → Feature vision alignment
- **Target Customers** → Actor definitions
- **Problem Statement** → Jobs to be done

**To Architecture Blueprints**:

- **Initiatives** → System components
- **Assumptions** → Design constraints

## Core Structure

### 1. Header and Metadata

```markdown
# [Product Name] Product Strategy

**Engagement**: [Client/Project name]
**Date**: [Strategy date]
**Status**: [Draft | Active | Superseded]
```

### 2. Vision

```markdown
## Vision

[2-3 sentences describing the aspirational future state the product enables.
Focus on the outcome for users, not features.]
```

**Example**:

```markdown
## Vision

Enable veterinary clinics to provide seamless, connected care for pets and their families. Pet owners have a single source of truth for their pet's health, while clinics operate efficiently with reduced administrative burden.
```

### 3. North Star

```markdown
## North Star

[Single metric or goal that the entire organization rallies around.
Should be measurable, aspirational, and customer-centric.]
```

**Example**:

```markdown
## North Star

**Monthly Active Pet Profiles**: The number of pet profiles with at least one owner interaction or clinic update per month.

This metric captures both engagement (owners using the app) and value delivery (clinics updating records).
```

### 4. Target Customers

```markdown
## Target Customers

### Primary: [Segment Name]

[Description of primary customer segment, their characteristics, and why they matter]

### Secondary: [Segment Name]

[Description of secondary customer segment]
```

**Example**:

```markdown
## Target Customers

### Primary: Multi-Pet Households

Families with 2+ pets who struggle to keep track of appointments, medications, and records across multiple animals. High lifetime value due to multiple subscriptions.

### Secondary: Specialty Clinics

Veterinary practices focused on specific care (dermatology, oncology) that need to coordinate with general practice clinics on shared patients.
```

### 5. Problem Statement

```markdown
## Problem Statement

[Clear articulation of the problem(s) being solved. Include current pain points
and their impact on customers.]
```

**Example**:

```markdown
## Problem Statement

Pet owners juggle multiple apps, portals, and paper records to manage their pets' health. When emergencies occur, critical information is scattered or inaccessible. Clinics waste time requesting records and playing phone tag with owners.

The result: delayed care, frustrated owners, and inefficient clinic operations.
```

### 6. OKRs (Objectives and Key Results)

```markdown
## OKRs

### Objective 1: [Objective Statement]

- **KR1**: [Measurable key result with target]
- **KR2**: [Measurable key result with target]
- **KR3**: [Measurable key result with target]

### Objective 2: [Objective Statement]

- **KR1**: [Measurable key result with target]
- **KR2**: [Measurable key result with target]
```

**Guidelines**:

- 2-4 objectives per strategy period
- 2-4 key results per objective
- Key results should be specific and measurable
- Include baseline and target numbers where possible

**Example**:

```markdown
## OKRs

### Objective 1: Become the trusted health record for pets

- **KR1**: Increase Monthly Active Pet Profiles from 50K to 150K
- **KR2**: Achieve 40% of profiles with complete vaccination history
- **KR3**: Reduce average time to access records in emergency from 15 min to 2 min

### Objective 2: Make clinic operations effortless

- **KR1**: Reduce record request handling time by 60%
- **KR2**: Onboard 200 new clinic partners
- **KR3**: Achieve 4.5+ star clinic satisfaction rating
```

### 7. Strategic Initiatives

```markdown
## Strategic Initiatives

### Initiative 1: [Initiative Name]

**Priority**: [High | Medium | Low]

[Description of initiative, what it aims to achieve, and rough scope]

### Initiative 2: [Initiative Name]

**Priority**: [High | Medium | Low]

[Description]
```

**Example**:

```markdown
## Strategic Initiatives

### Initiative 1: Universal Pet Passport

**Priority**: High

Create a portable, shareable pet health record that owners control. Includes vaccination history, medications, allergies, and care instructions. Works across any clinic in our network.

### Initiative 2: Clinic Integration Platform

**Priority**: High

Streamline clinic onboarding and data sync. Automatic import from major practice management systems. Real-time updates when records change.

### Initiative 3: Care Coordination Hub

**Priority**: Medium

Enable secure messaging between owners and clinics. Appointment reminders, medication alerts, and follow-up coordination in one place.
```

### 8. Assumptions

```markdown
## Assumptions

[List key assumptions the strategy depends on. These should be validated
or monitored as the strategy executes.]

- [Assumption 1]
- [Assumption 2]
- [Assumption 3]
```

**Example**:

```markdown
## Assumptions

- Pet owners are willing to create and maintain digital profiles for their pets
- Clinics will adopt a shared platform if it reduces their administrative burden
- Regulatory environment allows secure sharing of pet health records
- Mobile-first approach is appropriate for primary user interactions
```

### 9. Risks

```markdown
## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | [H/M/L] | [H/M/L] | [Mitigation approach] |
| [Risk 2] | [H/M/L] | [H/M/L] | [Mitigation approach] |
```

**Example**:

```markdown
## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Clinic adoption slower than expected | Medium | High | Offer free tier, white-glove onboarding |
| Competitor launches similar product | Medium | Medium | Focus on integration depth, not breadth |
| Data privacy regulations change | Low | High | Build privacy-by-design, stay ahead of GDPR/CCPA |
| Pet owner engagement drops after signup | High | Medium | Automated reminders, gamification, value-add features |
```

### 10. Dependencies

```markdown
## Dependencies

[External dependencies that could impact strategy execution]

- [Dependency 1]
- [Dependency 2]
```

**Example**:

```markdown
## Dependencies

- Partner API access from major practice management systems (Cornerstone, AVImark)
- Mobile app approval from Apple and Google app stores
- Cloud infrastructure scaling in target regions
- Legal review of data sharing agreements with clinics
```

### 11. Timeline (Optional)

```markdown
## Timeline

[High-level timeline for initiative delivery. Avoid specific dates;
use quarters or phases.]

- **Phase 1 (Q1)**: [Milestone]
- **Phase 2 (Q2)**: [Milestone]
- **Phase 3 (Q3-Q4)**: [Milestone]
```

## Template

When creating a new product strategy, use this template:

```markdown
# [Product Name] Product Strategy

**Engagement**: [Client/Project]
**Date**: [Date]
**Status**: Draft

## Vision

[2-3 sentences describing aspirational future state]

## North Star

[Single metric or goal the organization rallies around]

## Target Customers

### Primary: [Segment]

[Description]

### Secondary: [Segment]

[Description]

## Problem Statement

[Clear articulation of problems being solved]

## OKRs

### Objective 1: [Statement]

- **KR1**: [Measurable result]
- **KR2**: [Measurable result]
- **KR3**: [Measurable result]

### Objective 2: [Statement]

- **KR1**: [Measurable result]
- **KR2**: [Measurable result]

## Strategic Initiatives

### Initiative 1: [Name]

**Priority**: High

[Description]

### Initiative 2: [Name]

**Priority**: Medium

[Description]

## Assumptions

- [Assumption 1]
- [Assumption 2]
- [Assumption 3]

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk] | [H/M/L] | [H/M/L] | [Mitigation] |

## Dependencies

- [Dependency 1]
- [Dependency 2]
```

## Common Pitfalls

### Avoid These Mistakes

1. **Feature list instead of vision**: Listing features rather than outcomes
   - **Fix**: Focus on user outcomes and business impact, not implementation

2. **Unmeasurable OKRs**: "Improve user experience" without metrics
   - **Fix**: Include specific numbers, baselines, and targets

3. **Too many initiatives**: 10+ initiatives dilutes focus
   - **Fix**: Limit to 3-5 initiatives with clear prioritization

4. **Missing risk assessment**: Optimistic plan without contingencies
   - **Fix**: Include realistic risks and mitigation strategies

5. **No north star**: Multiple competing metrics
   - **Fix**: Choose one metric that best represents success

6. **Static document**: Strategy never updated
   - **Fix**: Review quarterly, update when market or priorities change

## Maintenance and Updates

### When to Update Product Strategy

**Triggers for updates**:

- Quarterly planning cycle
- Significant market change or competitor move
- OKR progress review (hit or miss targets)
- New customer segment identified
- Major assumption invalidated

### Update Process

1. **Review current state**: Which OKRs are on track?
2. **Assess assumptions**: Which have been validated/invalidated?
3. **Update initiatives**: Reprioritize based on learnings
4. **Communicate changes**: Share updates with stakeholders

## Markdown Linting Requirements

All product strategy documents must comply with the markdown standards defined in [markdown-standards.md](../markdown-standards.md).

### Quick Validation

```bash
markdownlint product-strategy.md
```

## Summary

A well-crafted product strategy:

- **Articulates** a clear vision and north star metric
- **Identifies** target customers and their problems
- **Sets** measurable OKRs for the strategy period
- **Prioritizes** strategic initiatives that deliver outcomes
- **Acknowledges** assumptions, risks, and dependencies
- **Evolves** as the market and learnings dictate

Use this guide when creating product strategies for consulting engagements or product planning.
