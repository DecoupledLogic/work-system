# Architecture Review Agent

A repeatable methodology for reviewing software architecture and encoding guardrails for coding agents.

## Overview

This document defines a systematic approach to architecture review that:

1. Maps system shape without judgment
2. Evaluates along fixed lenses for consistency
3. Produces actionable recommendations and agent guardrails

The methodology is tailored for .NET, TypeScript/React/Vue, and SQL Server/Postgres stacks but the pattern applies broadly.

---

## Pass 1: Map the System

**Goal:** Understand what exists without judging it.

### 1.1 Find the Boundaries

- **Deployable units:** APIs, background workers, frontends, databases, queues
- **Communication paths:** web → API → DB, plus external systems

### 1.2 Identify Main Layers

**For .NET:**
- Projects and folders: Api, Application, Domain, Infrastructure, Workers, Shared
- Cross-references between projects (who references whom)

**For JS/TS (React/Vue):**
- Code grouping: by feature, by layer (components/services), or chaos
- Where routing lives, where data-fetching lives, where state lives

**For SQL:**
- Main schemas / databases
- Tables grouped by concept
- Views, procs, triggers, functions

### 1.3 Trace a Request End to End

- Choose a core use case: "Create Order", "Sign In", "Get Dashboard"
- Follow it from UI → API → domain/app layer → data → back
- Note where logic lives: UI, controller, services, domain, DB

### 1.4 Pass 1 Output: System Map

| Section | Content |
|---------|---------|
| Context | What the app is for |
| Components | List of deployables and their tech |
| Diagram | High-level boxes and arrows |
| Request Traces | One or two traced flows |

---

## Pass 2: Evaluate with Fixed Lenses

Use the same lenses every time to build muscle memory:

1. Domain & boundaries
2. Backend (.NET) implementation
3. Frontend (TS/React/Vue) implementation
4. Data (SQL Server/Postgres) design
5. Cross-cutting concerns
6. Evolvability

### 2.1 Domain & Boundaries

**What to look for:**
- Is the domain modeled explicitly or is everything "services + DTOs + tables"
- Are there clear bounded contexts or one big ball
- Do modules have clear ownership (who owns a concept)

**Smells:**
- Anemic domain: everything is simple DTOs and giant service methods
- Shared God tables (User, Customer, Item) used everywhere with no boundary
- No clear home for domain rules (scattered in UI/API/DB)

**Improvement direction:**
- Name domain modules or bounded contexts explicitly
- Move important invariants into domain types or domain services
- Make "this module owns X data and rules" very clear

### 2.2 Backend (.NET)

Focus on structure and dependency rules first, patterns second.

**Check project structure:**
- Clean Architecture style:
  - MyApp.Domain
  - MyApp.Application
  - MyApp.Infrastructure
  - MyApp.Api
  - MyApp.Workers
- Or vertical slices: Features/Orders, Features/Accounts each with Api/Application/Domain/Infra inside

**Check dependency direction:**
- Domain has no external dependencies
- Application depends on Domain only
- Infrastructure depends on Application/Domain
- Api depends on Application (and maybe Domain for contracts), not Infrastructure directly

**Check composition:**
- All wiring in Startup/Program + DI container
- Implementation details resolved via interfaces / abstractions

**Check patterns in use:**
- CQRS / Mediator (e.g. MediatR) or simpler service pattern
- Validation strategies (FluentValidation, custom validators, data annotations)
- Background work: IHostedService, Hangfire, Quartz, etc.

**Smells:**
- Api project directly new-ing DbContexts or calling raw SQL everywhere
- Circular references between projects
- "Utils" or "Common" projects that know too much about everything
- Business logic heavily in controllers or in EF entities

**Improvement moves:**
- Introduce a clear layering rule: Api → Application → Domain; Infrastructure isolated
- Extract domain concepts into Domain project
- Put EF stuff and external integrations into Infrastructure
- Add a mediator or Application service layer if everything is in controllers today

### 2.3 Frontend (TS/React/Vue)

**Check structure:**
- Grouped by feature vs by technical layer vs random
- Where routing is defined
- Where global layout lives

**Check data & state:**
- How HTTP calls are done: direct in components, dedicated API client, TanStack Query, Vue Query
- What is global state vs local state and how managed (Context, Redux, Zustand, Pinia)

**Check boundaries:**
- Shared component library / design system or everything bespoke
- Clear split: pages / feature modules / shared components / primitives

**Check type safety and contracts:**
- TS models that align with API contracts
- Central place for API types, or scattered any/unknown blobs

**Smells:**
- Components that fetch data, run business logic, handle navigation, and render UI in one 400-line file
- Duplicated HTTP calls with slightly different shapes across components
- Lots of "any" and "unknown" and runtime type guessing
- UI rules diverging from backend rules

**Improvement moves:**
- Introduce feature-first structure: features/account, features/orders, shared/ui, shared/api
- Create an API client layer and/or query hooks to centralize data fetching
- Pull domain-ish rules into a "client domain" or "services" layer instead of embedding in JSX templates
- Create a minimal design system and align to it

### 2.4 Data (SQL Server/Postgres)

**Check data model:**
- Tables grouped logically into schemas (billing, identity, operations)
- Naming consistency
- Appropriate normalization vs denormalization for the use case

**Check data ownership:**
- Which service owns which table
- Shared integration tables vs tight coupling everywhere

**Check access patterns:**
- How the app talks to the DB: ORM (EF Core), micro-ORM (Dapper), raw SQL
- Use of views, stored procs, triggers

**Check performance & safety:**
- Indexing on common queries
- Use of constraints, FKs, unique indexes
- Migration strategy (EF migrations, Flyway, Liquibase, custom scripts)

**Smells:**
- One schema with 150 tables, no separation
- No foreign keys because "we handle that in the app" but you clearly don't
- Every table has the same few generic columns and no constraints
- Complex business rules enforced purely in triggers and stored procs nobody understands

**Improvement moves:**
- Introduce schemas and name ownership boundaries
- Add constraints and indexes where obviously missing
- Move business rules that belong at domain level out of overly clever SQL
- Introduce a clean migration pipeline if it's ad hoc right now

### 2.5 Cross-Cutting Concerns

**Check authn/authz:**
- Central vs scattered
- Policy-based or random checks spread across controllers and components

**Check observability:**
- Structured logging
- Metrics and traces tied to key flows
- Correlation IDs across backend and frontend

**Check resilience:**
- Retries, timeouts, circuit breakers for external calls
- Graceful error handling and user-facing messages

**Check testing:**
- Unit tests for domain rules
- Integration tests for core flows
- Contract tests between frontend and backend if schemas change often

**Smells:**
- No central error handling in API
- Frontend swallows errors or shows generic "Something went wrong" without helpful context
- No test coverage on core money-making flows

**Improvement moves:**
- Add API-level exception handling + standard error shape
- Introduce a basic logging/metrics plan around core use cases
- Add a few high-value tests before trying to boil the ocean

### 2.6 Evolvability

This is your "can agents safely build on this?" lens.

**Check:**
- Is the architecture simple enough to explain to a new dev or agent in a page?
- Are there clear "red lines" (rules that must not be broken) vs "playgrounds" (places to experiment)?
- Is it obvious where to add a new feature end-to-end?

**Smells:**
- No clear pattern for adding a feature, every feature done differently
- Architectural rules live in someone's head, not in code or docs
- Agents would have to guess where to put things

**Improvement moves:**
- Write a one-page reference architecture with dependency rules and folder conventions
- Add simple architecture tests / linters to enforce the most important rules
- Document "How to add a new feature" with a concrete example

---

## Pass 3: Recommendations

Categorize recommendations into four buckets for prioritization and agent consumption:

### Recommendation Buckets

| Bucket | Purpose | Examples |
|--------|---------|----------|
| **Guardrails** | Must-fix things that cause bugs or unbounded complexity | Stop API from talking directly to DB; enforce unique indexes |
| **Leverage** | High ROI changes that make future work cheaper | Feature-based frontend structure; create core domain module |
| **Hygiene** | Cleanup that improves clarity and maintainability | Rename confusing tables; delete dead code |
| **Experiments** | Safe places to try improved patterns | Try CQRS on one feature; try React Query on one screen |

---

## Encoding Guardrails for Coding Agents

### 1. Architecture as Data

Maintain a machine-readable reference file that agents can consume:

```yaml
system:
  style: "modular-monolith"
  languages:
    backend: "csharp"
    frontend: "typescript-react"
    database: "sql-server"

layers:
  - name: "Domain"
    rules:
      depends_on: []
  - name: "Application"
    rules:
      depends_on: ["Domain"]
  - name: "Infrastructure"
    rules:
      depends_on: ["Domain", "Application"]
  - name: "Api"
    rules:
      depends_on: ["Application"]

frontend:
  structure: "feature-first"
  features_root: "src/features"
  shared_root: "src/shared"
  data_access:
    pattern: "react-query"
    location: "src/shared/api"

database:
  migration_tool: "EFCore"
  schemas:
    - name: "billing"
    - name: "identity"
    - name: "operations"
```

Agents read `architecture.yaml` before writing code and obey its rules.

### 2. Enforce Rules in Code

**For .NET:**
- Use ArchUnitNET or custom test suite:
  - Api cannot reference Infrastructure
  - Domain cannot reference EF Core
  - No references to "Common.Utils" from Domain

**For TS/React/Vue:**
- Use dependency-cruiser or similar:
  - features/* cannot import from other features/* directly
  - shared/* can be imported by features, but not the other way around

**For SQL:**
- Add SQL linters / migration reviewers:
  - No tables created outside approved schemas
  - No direct DDL in random scripts, only migrations

### 3. Agent Playbook

Provide agents with explicit rules and examples.

#### Adding a Backend Feature

1. Add request/response models and endpoint in Api layer only
2. Add handlers or service methods in Application
3. Put domain rules in Domain entities or domain services
4. Use repositories or DbContext abstractions in Infrastructure only

#### Adding a Frontend Feature

1. Create a folder under `src/features/<feature>`
2. Put pages, components, hooks there
3. Use `shared/api` for HTTP clients
4. Use `shared/ui` for shared components and design system

#### Improving Architecture

1. If moving logic from controller to Application layer, do it in a small slice and keep tests green
2. Tag "architectural experiment" in commits and keep it isolated to one feature

### Do / Don't Table

| Do | Don't |
|----|-------|
| Follow the feature template | Invent a new pattern when a similar one exists |
| Use existing patterns and folders | Call the database from controllers |
| Add tests when moving logic out of controllers or SQL | Create new cross-cutting libraries without updating the architecture spec |

---

## Using This in Practice

1. Take one existing .NET + React + SQL system
2. Run Pass 1 and Pass 2 using the lenses above
3. Write a short Architecture Review doc
4. From that doc, pull out:
   - 5–10 guardrail rules to enforce
   - 3–5 leverage moves to improve the architecture
5. Encode the rules in:
   - `architecture.yaml`
   - Architecture tests / linters
   - Agent Playbook doc

From there, every new feature (human or agent) runs through the same expectations.

---

## Integration with Work System

The architecture review process integrates with the work system at:

- **Install time:** Establish baseline understanding of the architecture
- **Design stage:** Validate proposed changes against architectural rules
- **Deliver stage:** Enforce guardrails during implementation

The agent playbook becomes part of the system memory that guides all coding agents working in the codebase.
