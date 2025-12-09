# Architecture Blueprint Guide

## Purpose

An architecture blueprint is a design document that establishes technical patterns, component boundaries, and integration contracts before implementation begins. It serves as the foundation for all downstream artifacts (delivery plan, estimate, presentation deck) and provides the "why" behind architectural decisions.

## When to Create an Architecture Blueprint

Create a blueprint when:

- **Greenfield systems**: New microservices, bounded contexts, or major components
- **Architecture changes**: Migrating from synchronous to event-driven, refactoring service boundaries
- **Cross-service integration**: Defining contracts between microservices, external systems
- **Complex domain modeling**: Subscription management, entitlements, billing, authorization
- **Pattern establishment**: Setting standards for future features (webhook handling, reconciliation)

Use simpler documentation for:

- Single-service feature additions using established patterns
- Bug fixes or incremental enhancements
- Temporary workarounds or tactical fixes

## Relationship to Other Artifacts

### Architecture Blueprint Position in Workflow

```markdown
Architecture Blueprint (Design) ← Foundation
  ↓ (translates to)
Estimate CSV (Scope)
  ↓ (expands to)
Delivery Plan (Implementation)
  ↓ (communicates via)
Presentation Deck (Alignment)
```

### Blueprint as Foundation

**What flows from blueprint to delivery plan**:

- **Core Principles** → Strategy section in delivery plan
- **Components** → Epics and features
- **Event Contracts** → Code examples in stories
- **Domain Models** → Database schema stories
- **Integration Patterns** → Webhook, API, messaging stories

**What flows from blueprint to presentation deck**:

- **Principles** → Architecture Principles slides
- **Data Flow Diagrams** → Architecture Components slides
- **Event Contracts** → Architecture Vision slides
- **Migration Strategy** → Deployment Strategy slides

## Core Structure

### 1. Overview

```markdown
# [System/Feature] Architecture Blueprint

## Overview

[2-3 paragraphs describing the system, its purpose, and how it fits into the broader ecosystem]

[Include a sentence about the source of truth and projection pattern if applicable]

[Mention key external integrations and their role]
```

**Example**:

```markdown
# Subscription and Entitlement Architecture with Stax Bill

## Overview

This document describes how we integrate Stax Bill with our internal Subscription service and Entitlements service to control access in SaaS products.

Stax Bill is the system of record for billing and subscription lifecycle. Our Subscription service projects Stax Bill state into our domain. Our Entitlements service converts subscription state into runtime access decisions for the app.

We use Stax Bill webhooks as the primary trigger for updates and Stax Bill REST APIs for reconciliation and enrichment. Stax Bill exposes webhook events for invoices, subscriptions, payments, and related objects.
```

### 2. Goals

```markdown
## Goals

- [Goal 1: Separation of concerns or bounded contexts]
- [Goal 2: Event-driven integration patterns]
- [Goal 3: Support for common scenarios]
- [Goal 4: Reconciliation and consistency]
```

**Purpose**: Explicit design objectives that guide decisions

**Example**:

```markdown
## Goals

- Keep billing and entitlements as separate bounded contexts.
- Use invoice and subscription events from Stax Bill in a predictable way.
- Make entitlement logic simple, fast, and cacheable.
- Support common SaaS scenarios:
  - trials, renewals, upgrades, downgrades
  - payment failures and dunning
  - cancellations and holds
  - admin overrides, promos, and zero dollar extensions
- Allow periodic reconciliation with Stax Bill via REST APIs.
```

### 3. High Level Architecture

```markdown
## High Level Architecture

Components:

- [Component 1]
  - [Responsibility 1]
  - [Responsibility 2]
- [Component 2]
  - [Responsibility 1]
  - [Responsibility 2]
- [Component 3]
  - [Responsibility 1]
```

**Purpose**: System decomposition and responsibility assignment

**Example**:

```markdown
## High Level Architecture

Components:

- Stax Bill (External System)
  - Emits webhooks: InvoiceCreated, InvoiceStatusChanged, SubscriptionUpdated
  - Exposes REST APIs for subscriptions, invoices, customers

- Subscription Service (Our System)
  - Owns local models: Subscription, InvoiceProjection
  - Handles Stax Bill webhooks
  - Calls Stax Bill REST APIs for enrichment and reconciliation
  - Publishes SubscriptionStateChanged events to downstream systems

- Entitlements Service
  - Consumes SubscriptionStateChanged events
  - Maintains Entitlement records per account
  - Exposes read APIs for app and internal services: GET /entitlements?subjectId=...
  - Provides feature, tier, limit, and status checks

- Application Layer
  - Calls Entitlements for gate checks
  - Optionally calls Subscription service for billing views
```

### 4. Core Principles / Invariants

```markdown
## Core Principles

1. **[Principle 1]**: [Explanation]
2. **[Principle 2]**: [Explanation]
3. **[Principle 3]**: [Explanation]

### Why This Pattern?
- [Benefit 1]
- [Benefit 2]
- [Benefit 3]
```

**Purpose**: Design decisions and tradeoffs

**Example**:

```markdown
## Core Principles

The core invariant:
- Invoice and subscription events from Stax Bill move subscription state.
- Subscription state events from our service move entitlement state.

1. **Stax Bill is the system of record** for billing and subscription lifecycle
2. **Subscription service projects** Stax Bill state into our domain
3. **Entitlements service converts** subscription state into runtime access decisions
4. **Webhooks as triggers** (not source of truth)
5. **APIs for enrichment** (fetch full context when needed)
6. **Periodic reconciliation** (eventual consistency guarantee)
```

### 5. Event Sources and What We Use Them For

```markdown
## Event Sources and What We Use Them For

From [External System] webhooks:

- [EventType1]
  - Includes: [data fields]
  - We use this to: [purpose]

- [EventType2]
  - Includes: [data fields]
  - We use this to: [purpose]

From [External System] REST APIs:

- [Endpoint1]
  - Used for: [purpose]
```

**Purpose**: Catalog of integration points and their purposes

**Example**:

```markdown
## Event Sources and What We Use Them For

From Stax Bill webhooks:

- InvoiceStatusChanged
  - Includes: invoice status, payment schedule, invoice metadata
  - We treat specific status transitions as authoritative signals for term commitment (e.g., to Paid).

- SubscriptionUpdated
  - Fires only when specific subscription fields change and explicitly does not fire when automatic billing updates the next period start date.
  - We use this for configuration changes, not for renewals.

From Stax Bill REST APIs:

- Invoice summaries, customers, AR activities via /invoiceSummaries, /customers, /aractivities
  - Used for nightly reconciliation and historical reports.
```

### 6. Domain Model

```markdown
## Domain Model

### [Service] Domain

Key aggregates:

[EntityName]
- field1
- field2
- field3
  - possibleValue1
  - possibleValue2

[EventName] (outbound)
- field1
- field2
- reason
  - possibleReason1
  - possibleReason2
```

**Purpose**: Define entities, events, and value objects

**Example**:

```markdown
## Domain Model

### Subscription Service Domain

Key aggregates:

Subscription
- id
- externalSubscriptionId (Stax Bill subscription id)
- customerId
- planCode
- billingFrequency
- status
  - active
  - trialing
  - canceled
  - past_due
  - on_hold
  - paused
- currentTermStart
- currentTermEnd
- nextBillingDate
- cancellationEffectiveDate

SubscriptionStateChangeEvent (outbound)
- subjectId (account, org, tenant)
- subscriptionId
- status
- termStart
- termEnd
- tier
- featureBundle
- reason
  - renewal
  - non_payment_cancellation
  - customer_cancellation
  - admin_cancellation
  - admin_hold
  - admin_resume
  - manual_extension
```

### 7. Core Flows

```markdown
## Core Flows

### 1. [Flow Name]

1. [Step 1]
2. [Step 2]
3. [Step 3]:
   1. [Sub-step 1]
   2. [Sub-step 2]
4. [Step 4]:
   1. [Sub-step 1]
   2. [Sub-step 2]

### 2. [Flow Name]

[Repeat structure...]
```

**Purpose**: Step-by-step scenarios showing how components interact

**Example**:

```markdown
## Core Flows

### 1. Renewal

1. Stax Bill performs automatic billing.
2. Stax Bill updates invoice(s), triggers InvoiceUpdated and InvoiceStatusChanged for the new renewal invoice.
3. Subscription service receives invoice events:
   1. fetches latest invoice and subscription via Stax Bill API if needed
   2. computes new termStart and termEnd
   3. updates Subscription aggregate
   4. publishes SubscriptionStateChanged with:
      1. reason = renewal
      2. termStart and termEnd
4. Entitlements service:
   1. updates expiresAt to new termEnd
   2. status stays active

We do not depend on SubscriptionUpdated, because documentation states automatic billing will update nextPeriodStartDate but will not dispatch this webhook.

### 2. Payment Failure and Dunning

1. Stax Bill attempts charge and fails.
2. Stax Bill emits PaymentFailed and possibly InvoiceStatusChanged to past_due status.
3. Subscription service:
   1. records the failure for analytics
   2. if invoice status crosses into past_due or dunning:
      1. updates Subscription status to past_due or in_dunning
      2. publishes SubscriptionStateChanged with reason = payment_failed
4. Entitlements:
   1. can either keep status = active while in dunning window, or
   2. set status = suspended but retain the same expiresAt
```

### 8. Integration Design

```markdown
## [Integration Type] Handling Design

[Service] exposes webhook endpoints:

- POST /webhooks/[external-system]
  - Validates signature if configured
  - Reads EventType and payload

Processing pattern:

- [Step 1]
- [Step 2]
- [Step 3]

Idempotency rules:

- [Rule 1]
- [Rule 2]
```

**Purpose**: Describe webhook handling, API enrichment patterns

**Example**:

```markdown
## Webhook Handling Design

Subscription service exposes one or more Stax Bill webhook endpoints:

- POST /webhooks/staxbill
  - Validates signature if configured
  - Reads EventType and payload: InvoiceUpdated, InvoiceStatusChanged, SubscriptionUpdated, etc.

Processing pattern:

- Place webhook body on an internal queue (e.g., staxbill-events) with idempotency key derived from event type and object id.
- Worker processes events:
  - normalizes by type
  - upserts Subscription and InvoiceProjection
  - if state transition affects termEnd, status, or tier, emits SubscriptionStateChanged.

Idempotency rules:

- Keep an event_log table with: externalEventType, externalObjectId, receivedAt, processedAt, processingResult
- Before processing, check if same externalEventType + externalObjectId has been processed successfully.
- If yes, skip or ensure operations are idempotent.
```

### 9. Event Contracts

````markdown
## [EventName] Event Contract

Example payload:

```json
{
  "eventType": "EventName",
  "eventId": "uuid",
  "occurredAt": "2025-12-06T10:15:00Z",
  "field1": "value1",
  "field2": "value2"
}
```

[Service] treats this as its single integration surface with [other service].
````

**Purpose**: Define event schema for inter-service communication

**Example**:

````markdown
## SubscriptionStateChanged Event Contract

Example payload:

```json
{
  "eventType": "SubscriptionStateChanged",
  "eventId": "uuid",
  "occurredAt": "2025-12-06T10:15:00Z",
  "subjectId": "tenant-123",
  "subscriptionId": "sub-456",
  "status": "active",
  "termStart": "2025-12-01",
  "termEnd": "2026-01-01",
  "expiresAt": "2026-01-01T00:00:00Z",
  "tier": "pro",
  "featureBundle": ["feature_a", "feature_b"],
  "reason": "renewal",
  "previous": {
    "status": "active",
    "termStart": "2025-11-01",
    "termEnd": "2025-12-01"
  }
}
```

Entitlements treats this as its single integration surface with billing.
````

### 10. Service APIs

```markdown
## [Service] API

Key endpoints:

- GET /[resource]?[filter]=[value]
  - Returns: [description]
- POST /[resource]/[action]
  - Input: [fields]
  - Output: [fields]

Internal behavior:

- On [Event]:
  - [action 1]
  - [action 2]

Caching:

- [caching strategy]
```

**Purpose**: Define public API surface for service

**Example**:

```markdown
## Entitlements Service API

Key endpoints:

- GET /entitlements?subjectId=...
  - Returns current entitlement record.
- POST /entitlements/check
  - Input: subjectId, feature
  - Output: allowed (true/false), reason

Internal behavior:

- On SubscriptionStateChanged:
  - upsert Entitlement
  - compute derived fields (status, expiresAt)
  - write to storage with indexes optimized for subjectId lookups

Caching:

- Application layer can cache Entitlement responses using TTL ≤ expected update frequency.
- Hard changes (revocation) can be pushed through message bus or invalidation channel if needed.
```

### 11. Reconciliation Strategy

```markdown
## Reconciliation Job

Assumption: [why reconciliation is needed]

[Frequency] job in [Service]:

- Queries [external system] REST APIs: [endpoints]
- Compares external state with internal [entities].
- For any drift:
  - [action 1]
  - [action 2]

This keeps us aligned even if [failure scenario].
```

**Purpose**: Describe eventual consistency mechanism

**Example**:

```markdown
## Reconciliation Job

Assumption: webhooks can be delayed or missed in real operations.

Nightly (or hourly) job in Subscription service:

- Queries Stax Bill REST APIs: invoice summaries, subscriptions, AR activities
- Compares external state with internal Subscription and InvoiceProjection.
- For any drift:
  - updates Subscription state
  - emits SubscriptionStateChanged as needed

This keeps us aligned even if a webhook was lost or if manual adjustments were made directly in Stax Bill.
```

### 12. Security and Tenancy

```markdown
## Security and Tenancy

- The webhook endpoint must be protected by:
  - [protection 1]
  - [protection 2]
- Customer identifiers in our system map to [external system] [identifier] one-to-one.
- We never expose [external system] identifiers to end users directly where not necessary.
- [Entities] are always computed per [tenant identifier] to avoid cross-tenant leakage.
```

**Purpose**: Security requirements and multi-tenancy considerations

### 13. Open Questions

```markdown
## Open Questions

- [Question 1]
- [Question 2]
- [Question 3]

If you want, next step is we can [potential next actions].
```

**Purpose**: Document unresolved design decisions

**Example**:

```markdown
## Open Questions

- Exact mapping between Stax Bill subscription status codes and our internal status enums.
- How long we keep a suspended user active before full revocation in non-payment scenarios.
- Whether we allow partial entitlements during dunning periods (e.g., read-only access).
- Whether we need per-seat entitlements or keep it per-tenant initially.

If you want, next step is we can collapse this into a shorter internal RFC, or generate C# interface and DTO definitions for SubscriptionStateChanged and the Entitlements storage models.
```

## Optional Sections

### Migration Strategy (for refactoring initiatives)

```markdown
## Migration Strategy

### Current Architecture
[Description of current state]
- **Problem**: [pain points]

### Future Architecture
[Description of target state]
- **Benefits**: [improvements]

### Migration Steps
1. [Phase 1: Dual-write]
2. [Phase 2: Monitoring]
3. [Phase 3: Gradual migration]
4. [Phase 4: Cutover]
```

### Failure Modes and Recovery

```markdown
## Failure Modes and Recovery

### [Failure Scenario 1]
- **Trigger**: [what causes this]
- **Impact**: [blast radius]
- **Detection**: [how we know it happened]
- **Recovery**: [how we fix it]

### [Failure Scenario 2]
[Repeat structure...]
```

### Performance Considerations

```markdown
## Performance Considerations

### Throughput
- [Expected volume]: [number] events/second, [number] API calls/minute

### Latency
- [Operation 1]: <[target] ms p95
- [Operation 2]: <[target] seconds p99

### Scalability
- [Horizontal scaling strategy]
- [Caching strategy]
- [Rate limiting]
```

## Blueprint Template

When creating a new architecture blueprint, use this template:

````markdown
# [System/Feature] Architecture Blueprint

## Overview

[2-3 paragraphs describing the system and its purpose]

## Goals

- [Goal 1]
- [Goal 2]
- [Goal 3]

## High Level Architecture

Components:

- [Component 1]
  - [Responsibility 1]
  - [Responsibility 2]
- [Component 2]
  - [Responsibility 1]

## Core Principles

1. **[Principle 1]**: [Explanation]
2. **[Principle 2]**: [Explanation]

### Why This Pattern?
- [Benefit 1]
- [Benefit 2]

## Event Sources and What We Use Them For

From [External System] webhooks:

- [EventType1]
  - We use this to: [purpose]

From [External System] REST APIs:

- [Endpoint1]
  - Used for: [purpose]

## Domain Model

### [Service] Domain

Key aggregates:

[EntityName]
- field1
- field2

[EventName] (outbound)
- field1
- reason

## Core Flows

### 1. [Flow Name]

1. [Step 1]
2. [Step 2]
3. [Step 3]

## [Integration Type] Handling Design

[Service] exposes endpoints:

- POST /[endpoint]
  - [Purpose]

Processing pattern:

- [Pattern description]

Idempotency rules:

- [Rules]

## [EventName] Event Contract

Example payload:

```json
{
  "eventType": "EventName",
  "field1": "value1"
}
```

## [Service] API

Key endpoints:

- GET /[resource]
  - Returns: [description]

## Reconciliation Job

Assumption: [why needed]

[Frequency] job:

- [Actions]

## Security and Tenancy

- [Security requirements]

## Open Questions

- [Question 1]
- [Question 2]
````

## Maintenance and Evolution

### When to Update a Blueprint

**Triggers for updates**:

- New integration discovered (additional webhook types, API endpoints)
- Event contract changed (new fields, new reason codes)
- Flow modifications (new failure scenarios, state transitions)
- Pattern refinements (idempotency improvements, caching strategies)
- Open questions resolved (design decisions finalized)

### Update Process

1. **Identify change**: What aspect of architecture changed?
2. **Update blueprint section**: Modify affected sections (flows, event contracts, APIs)
3. **Propagate to delivery plan**: Update stories that implement the changed patterns
4. **Update presentation deck**: Adjust architecture slides to match blueprint
5. **Document rationale**: Add note in blueprint about why change was made

### Versioning Strategy

#### Option 1: In-place updates with git history

- Update blueprint.md directly
- Rely on git commits to show evolution
- Use git tags for major revisions (v1.0, v2.0)

#### Option 2: Versioned blueprints

- Create blueprint-v1.md, blueprint-v2.md
- Keep blueprint.md as symlink to latest
- Easier to compare major architecture shifts

**Recommendation**: In-place updates with clear commit messages:

```bash
git commit -m "Update blueprint: Add InvoiceProjection entity to support analytics"
```

## Common Pitfalls

### ❌ Avoid These Mistakes

1. **Implementation details in blueprint**: Describing FastEndpoints structure, EF migrations
   - **Fix**: Blueprint is design-level; implementation details go in delivery plan

2. **No core principles**: Jumping straight to domain model without explaining "why"
   - **Fix**: Always include principles section to justify architectural choices

3. **Missing event contracts**: Describing that events exist without showing schema
   - **Fix**: Include example JSON payloads for all inter-service events

4. **Vague flows**: "System processes payment" without step-by-step breakdown
   - **Fix**: Number each step, show which component does what

5. **No reconciliation strategy**: Assuming webhooks always work
   - **Fix**: Always describe reconciliation mechanism for external integrations

6. **Ignoring failure modes**: Happy path only, no error handling
   - **Fix**: Include failure scenarios in flows (payment failure, API timeout, etc.)

7. **Open questions never resolved**: Blueprint stays "draft" forever
   - **Fix**: Set deadline for resolving open questions; update blueprint when resolved

8. **Blueprint-delivery plan divergence**: Implementation uses different patterns than blueprint
   - **Fix**: Treat blueprint as source of truth; update delivery plan to match (or update blueprint if it was wrong)

## Alignment with Delivery Plan

### Blueprint → Delivery Plan Mapping

| Blueprint Section       | Delivery Plan Section                               |
|-------------------------|-----------------------------------------------------|
| Goals                   | Strategy paragraph                                  |
| High Level Architecture | Epic structure (components → epics)                 |
| Core Principles         | Implementation approach in epics                    |
| Domain Model            | Database schema stories, entity definitions         |
| Core Flows              | Story acceptance criteria (Gherkin format)          |
| Event Contracts         | Code examples in event publishing/consuming stories |
| Service APIs            | Endpoint creation stories                           |
| Reconciliation Job      | Reconciliation epic/feature                         |
| Security and Tenancy    | Cross-cutting concerns (Epic 0)                     |

### Validation Checklist

Before finalizing delivery plan, cross-check with blueprint:

- [ ] Every component in blueprint has corresponding epic in delivery plan
- [ ] All event contracts in blueprint have implementation stories
- [ ] Core flows in blueprint map to integration test stories
- [ ] Domain model entities have schema migration stories
- [ ] Service APIs have endpoint creation stories
- [ ] Reconciliation job has dedicated feature/epic
- [ ] Security requirements covered in cross-cutting concerns

## Examples by Architecture Type

### Event-Driven Microservices

**Blueprint Focus**:

- Event contracts (detailed JSON schemas)
- Dual-write migration strategy
- Idempotency patterns
- Message bus configuration

**Key Sections**: Event Sources, Event Contracts, Migration Strategy

### External System Integration

**Blueprint Focus**:

- Webhook handling patterns
- API enrichment strategies
- Reconciliation mechanisms
- Projection patterns (external state → domain model)

**Key Sections**: Event Sources, Integration Design, Reconciliation Strategy, Core Flows

### Domain-Driven Design

**Blueprint Focus**:

- Bounded context boundaries
- Aggregate design
- Domain events
- Repository patterns

**Key Sections**: Domain Model, Core Principles, Service APIs

## Markdown Linting Requirements

All architecture blueprints must comply with the markdown standards defined in [markdown-standards.md](../markdown-standards.md).

### Blueprint-Specific Rules

In addition to the common rules, architecture blueprints should pay attention to:

- **MD036 (No Emphasis as Heading)**: Use proper heading syntax for section headers, not bold text (e.g., `### Core Principles` not `**Core Principles**`)

### Quick Validation

```bash
markdownlint architecture-blueprint.md
```

See [markdown-standards.md](../markdown-standards.md) for complete linting rules, IDE setup, and enforcement policies.

## Summary

A well-crafted architecture blueprint:

- **Establishes** principles and patterns before implementation
- **Defines** component boundaries and responsibilities
- **Documents** event contracts and integration points
- **Describes** core flows and failure scenarios
- **Guides** delivery plan creation (blueprint → delivery plan)
- **Evolves** as design decisions are made and open questions resolved

Use this guide as a template when creating architecture blueprints for any new system or major refactoring.
