# Estimate Guide

## Purpose

The estimate CSV is the single source of truth for project scope and effort. It defines the epic/feature/story hierarchy and assigns hour estimates to each story. All other artifacts (delivery plan, presentation deck) derive their structure and timelines from the estimate CSV.

## When to Create an Estimate CSV

Create an estimate CSV when:

- **Scoping initiatives**: Multi-epic work requiring effort breakdown
- **Resource planning**: Leadership needs timeline estimates for staffing
- **Progress tracking**: Teams need a baseline to measure actual vs. estimated hours
- **Dependency mapping**: Understanding which stories block others

Use simpler methods for:

- Single-story tasks (< 8 hours) - just log hours in Teamwork
- Exploratory spikes with unknown scope - time-box instead of estimate
- Maintenance work without clear deliverables - track actual time, not estimates

## Relationship to Other Artifacts

### Estimate CSV Position in Workflow

```text
Architecture Blueprint (Design)
  ↓ (informs)
Estimate CSV (Hours) ← Source of Truth
  ↓ (structures)
Delivery Plan (Implementation Details)
  ↓ (summarizes to)
Presentation Deck (Communication)
```

### Estimate CSV is Source of Truth

**All artifacts must align with estimate CSV**:

- **Delivery plan** epic/feature/story structure must exactly match CSV
- **Delivery plan** estimate summary table must exactly match CSV totals
- **Presentation deck** epic breakdown must match CSV epic names and hours
- **Presentation deck** timeline table must show CSV hour totals

**When conflicts arise**:

- Estimate CSV wins (it's the source of truth)
- Update delivery plan and deck to match CSV
- If CSV is wrong, update CSV first, then propagate changes

## CSV Structure

### Column Definitions

```csv
Epic,FT,Feature,ST,Story,Name,Description,Risk,Value,Hours
```

**Epic**: Epic number (1, 2, 3, 0 for cross-cutting concerns)
**FT**: Feature number (sequential within epic: 1, 2, 3)
**Feature**: Composite feature identifier (Epic.Feature: 1.1, 1.2, 2.1)
**ST**: Story number (sequential within feature: 1, 2, 3)
**Story**: Composite story identifier (Epic.Feature.Story: 1.1.1, 1.1.2, 1.2.1)
**Name**: Name of epic, feature, or story
**Description**: Brief description or acceptance criteria summary
**Risk**: Low, Medium, High (epic-level only)
**Value**: High, Medium, Low (epic-level only)
**Hours**: Estimated hours (story-level only)

### Row Types

**Epic Row**:

```csv
1,,,,,Renewal Fix,Fixes lockout issue,Low,High,
```

- Epic column populated (1)
- FT, Feature, ST, Story columns empty
- Name is epic name
- Description is epic goal
- Risk and Value populated
- Hours empty (calculated as sum of story hours)

**Feature Row**:

```csv
,1,1.1,,,Core Sync Service,,,,
```

- Epic column empty
- FT column populated (1)
- Feature column populated (Epic.Feature: 1.1)
- ST and Story columns empty
- Name is feature name
- Description, Risk, Value, Hours empty

**Story Row**:

```csv
,,,1,1.1.1,Fetch from Stax Bill,Sync Service Fetches from Stax Bill,,,3
```

- Epic and FT columns empty
- Feature column populated (1.1)
- ST column populated (1)
- Story column populated (Epic.Feature.Story: 1.1.1)
- Name is story name
- Description is brief acceptance criteria
- Risk and Value empty
- Hours populated (3)

### Full Example

```csv
Epic,FT,Feature,ST,Story,Name,Description,Risk,Value,Hours
1,,,,,Renewal Fix,Fixes lockout issue,Low,High,
,1,1.1,,,Core Sync Service,,,,
,,,1,1.1.1,Fetch from Stax Bill,Sync Service Fetches from Stax Bill,,,3
,,,2,1.1.2,Update Local Database,Sync Service Updates Local Database,,,3
,,,3,1.1.3,Apply Grace Period Logic,Grace Period Logic Applied,,,2
,2,1.2,,,Invoice Webhook Handler,,,,
,,,1,1.2.1,Receive Invoice Events,Webhook Receives Invoice Events,,,2
,,,2,1.2.2,Detect Renewal,Renewal Detection via Invoice,,,3
2,,,,,Schema Enhancement,Enables grace period,Low,High,
,1,2.1,,,Database Schema Enhancement,,,,
,,,1,2.1.1,Migrate Database,Migration Executes Successfully,,,2
,,,2,2.1.2,Create Repository Methods,Repository Methods Available,,,2
```

## Estimating Guidelines

### Story Sizing

**Small Stories (1-2 hours)**:

- Single database field addition
- Simple DTO creation
- Basic endpoint with no business logic
- Standard repository method

**Medium Stories (3-4 hours)**:

- Integration with external API (one endpoint)
- Business logic method with 2-3 branches
- Database migration with rollback
- Webhook handler with signature validation

**Large Stories (5-8 hours)**:

- Complex business logic (grace period calculation, reconciliation algorithm)
- End-to-end feature with API + service + repository
- Event contract definition + publisher + consumer
- Background job with error handling and metrics

**Extra Large Stories (> 8 hours)**:

- Break into multiple stories
- Example: "Implement reconciliation job" (12 hours) →
  - Story 1: "Run job on schedule" (3 hours)
  - Story 2: "Detect drift" (4 hours)
  - Story 3: "Prevent false positives" (2 hours)
  - Story 4: "Handle failures" (3 hours)

### Feature Totals

Feature hours = sum of story hours within that feature

**Example**:

```text
Feature 1.1: Core Sync Service
- Story 1.1.1: 3 hours
- Story 1.1.2: 3 hours
- Story 1.1.3: 2 hours
- Story 1.1.4: 4 hours
= 12 hours total (not shown in CSV, calculated)
```

### Epic Totals

Epic hours = sum of all story hours across all features in that epic

**Example**:

```text
Epic 1: Renewal Fix
- Feature 1.1 (Core Sync Service): 12 hours
- Feature 1.2 (Invoice Webhook Handler): 10 hours
- Feature 1.3 (Entitlements Integration): 12 hours
= 34 hours total (not shown in CSV, calculated)
```

### Total Estimate

Total hours = sum of all epic hours (including Epic 0)

**Example**:

```text
Epic 1: 34 hours
Epic 2: 8 hours
Epic 3: 24 hours
Epic 4: 12 hours
Epic 5: 18 hours
Epic 6: 20 hours
Epic 0: 22 hours
= 138 hours total
```

## Epic Numbering Convention

### Standard Epic Numbers

**Epic 1-N**: Functional epics in priority order

- Epic 1: Most critical (usually the immediate fix or core feature)
- Epic 2: Next critical (often infrastructure enablement)
- Epic 3+: Additional features in descending priority

### Epic 0: Cross-Cutting Concerns

- Integration testing across all epics
- Rollback procedures
- Monitoring and logging
- Documentation
- Success metric definition

**Why Epic 0 is special**:

- Applies to all other epics (not standalone)
- Usually estimated as 15-20% of total functional epic hours
- Should be done last (after all functional epics are understood)

### Epic Priority Mapping

| Epic | Priority | Description                                     |
|------|----------|-------------------------------------------------|
| 1    | P0       | Emergency fix or foundational capability        |
| 2    | P0       | Critical enablement (schema, infrastructure)    |
| 3    | P0       | Resilience and safety nets                      |
| 4    | P1       | Nice-to-have enhancements                       |
| 5    | P1       | Architecture alignment                          |
| 6    | P1       | Future-facing features                          |
| 0    | P0       | Testing, monitoring, rollback (always critical) |

## Risk and Value Assessment

### Risk Levels

**Low Risk**:

- No schema changes
- Additive features (not modifying existing behavior)
- Well-established patterns
- Easy rollback (remove feature flag, redeploy)

**Medium Risk**:

- Database migrations required
- Modifications to existing critical paths
- Integration with external systems (but with fallbacks)
- Moderate rollback complexity

**High Risk**:

- Event-driven architecture migration (dual-write complexity)
- Major refactoring of core business logic
- No easy rollback (data migrations that can't be reversed)
- Cross-service orchestration with failure modes

### Value Levels

**High Value**:

- Fixes production incidents
- Unblocks revenue (renewals, upgrades)
- Foundational for multiple future features
- Significant customer experience improvement

**Medium Value**:

- Operational efficiency gains
- Analytics and reporting capabilities
- Developer experience improvements
- Architecture alignment (reduces future complexity)

**Low Value**:

- Nice-to-have features
- Edge case handling for rare scenarios
- Minor UX polish
- Refactoring without functional changes

### Risk/Value Matrix

| Risk/Value      | High Value        | Medium Value   | Low Value       |
|-----------------|-------------------|----------------|-----------------|
| **Low Risk**    | Do First          | Do Soon        | Maybe Later     |
| **Medium Risk** | Do First          | Carefully Plan | Probably Skip   |
| **High Risk**   | Mitigate Then Do  | Reconsider     | Definitely Skip |

**Example from Renewal Fix**:

- Epic 1 (Renewal Fix): Low Risk, High Value → ✅ Do First
- Epic 2 (Schema Enhancement): Medium Risk, High Value → ✅ Do First (with migration testing)
- Epic 5 (Event-Driven Migration): High Risk, Medium Value → ⚠️ Carefully plan dual-write, gradual rollout

## Creating an Estimate CSV

### Step-by-Step Process

#### Step 1: Start with Architecture Blueprint

- Identify major components → Epics
- Break components into capabilities → Features
- List implementation tasks → Stories

#### Step 2: Create CSV Template

```csv
Epic,FT,Feature,ST,Story,Name,Description,Risk,Value,Hours
```

#### Step 3: Add Epic Rows

- Number epics 1-N in priority order
- Add Epic 0 at the end for cross-cutting concerns
- Fill Epic, Name, Description, Risk, Value columns
- Leave Hours empty

#### Step 4: Add Feature Rows

- For each epic, add 2-5 features
- Number features sequentially (FT: 1, 2, 3)
- Create composite Feature identifier (Epic.Feature)
- Fill Name only
- Leave all other columns empty

#### Step 5: Add Story Rows

- For each feature, add 2-8 stories
- Number stories sequentially within feature (ST: 1, 2, 3)
- Create composite Story identifier (Epic.Feature.Story)
- Fill Name, Description, Hours
- Use Gherkin-style description when possible (or at least hint at acceptance criteria)

#### Step 6: Estimate Story Hours

- Start with stories you're most confident about (anchor estimates)
- Use t-shirt sizing first (S=2h, M=4h, L=6h, XL=8h+)
- Refine estimates based on similar past work
- Add buffer for unknown complexity (multiply by 1.2-1.5 for unfamiliar domains)

#### Step 7: Calculate Totals

- Sum story hours per feature (for your own validation)
- Sum feature hours per epic (for your own validation)
- Sum all epic hours for total estimate
- Verify total makes sense (does 138 hours feel right for this scope?)

#### Step 8: Add Total Row

```csv
,,,,,,TOTAL ESTIMATE,,,138
```

### Validation Checklist

Before finalizing estimate CSV:

- [ ] All epic numbers are sequential (1, 2, 3, ..., 0)
- [ ] All feature numbers are composite (Epic.Feature)
- [ ] All story numbers are composite (Epic.Feature.Story)
- [ ] Every story has hour estimate (no blank hours except epic/feature rows)
- [ ] Epic 0 exists for cross-cutting concerns
- [ ] Total row matches sum of all story hours
- [ ] No story > 8 hours (break large stories into smaller ones)
- [ ] All epics have Risk and Value assigned

## Updating an Estimate CSV

### When to Update

**Triggers for updates**:

- New stories discovered during development
- Story hours were significantly over/under estimated
- Scope change (adding or removing epics/features)
- Splitting large stories into smaller ones
- Combining small stories into one larger story

### Update Process

#### Step 1: Identify Change

- What changed? (new story, adjusted hours, removed feature)
- Why? (discovered complexity, reduced scope, estimation error)

#### Step 2: Update CSV

- Add/remove/modify rows as needed
- Recalculate feature and epic totals
- Update total row

#### Step 3: Propagate Changes

- Update delivery plan (add/remove stories, update estimate summary table)
- Update presentation deck (adjust timeline table, epic breakdown slides)
- Notify stakeholders if timeline significantly changed (> 10% delta)

#### Step 4: Track Variance

- Keep original estimate for reference
- Document why estimates changed (in delivery plan or commit message)
- Use actual hours tracked to improve future estimates

### Versioning Strategy

#### Option 1: Overwrite (Simpler)

- Update estimate.csv in place
- Rely on git history to see previous versions
- Use `git diff` to see changes

#### Option 2: Versioned Files (More Explicit)

- Create estimate-v1.csv, estimate-v2.csv
- Keep estimate.csv pointing to latest (symlink or copy)
- Easier to compare versions side-by-side

**Recommendation**: Overwrite with clear commit messages:

```bash
git commit -m "Update estimate: Add Epic 4 stories for invoice projection (+12 hours)"
```

## Common Pitfalls

### ❌ Avoid These Mistakes

1. **Forgetting Epic 0**: No cross-cutting concerns epic
   - **Fix**: Always include Epic 0 for testing, monitoring, rollback

2. **Inconsistent numbering**: Story 1.1.1, then 1.1.3 (skipped 1.1.2)
   - **Fix**: Number stories sequentially within features

3. **Vague story names**: "Do the thing" instead of "Fetch from Stax Bill"
   - **Fix**: Use descriptive action verbs (Create, Update, Fetch, Validate, etc.)

4. **Missing hours on stories**: Some stories have hours, some don't
   - **Fix**: Every story must have hour estimate (even if it's 1 hour)

5. **Epic hours populated**: Epic row has hours filled in
   - **Fix**: Only story rows have hours; epic/feature rows are blank

6. **Total mismatch**: Total row shows 100 hours but sum of stories is 138 hours
   - **Fix**: Recalculate total using sum of all story hours

7. **Overly large stories**: Story estimated at 16 hours
   - **Fix**: Break into 2-3 smaller stories (max 8 hours per story)

8. **Missing risk/value**: Epic rows have no risk or value assessment
   - **Fix**: Assign risk (Low/Medium/High) and value (Low/Medium/High) to all epics

## Tracking Actuals vs. Estimates

### During Development

**Log actual hours in Teamwork** (or similar tracking tool):

- Link time entries to specific stories (use Story 1.1.1 format in description)
- Track daily as work is done (not retroactively)
- Include all time (coding, debugging, testing, code review)

**Compare actuals to estimates weekly**:

```text
Story 1.1.1: Fetch from Stax Bill
- Estimated: 3 hours
- Actual: 4.5 hours
- Variance: +1.5 hours (+50%)
```

**Adjust remaining estimates** if pattern emerges:

- If all stories are 50% over estimate, scale remaining stories by 1.5x
- If specific epic consistently under-estimated, adjust that epic's remaining stories
- Update estimate CSV to reflect new understanding

### Post-Mortem Analysis

After initiative completes:

**Create variance report**:

| Epic | Feature | Story | Estimated | Actual | Variance | %    |
|------|---------|-------|-----------|--------|----------|------|
| 1    | 1.1     | 1.1.1 | 3         | 4.5    | +1.5     | +50% |
| 1    | 1.1     | 1.1.2 | 3         | 2.5    | -0.5     | -17% |

**Identify patterns**:

- External API integrations consistently over-estimated?
- Database migrations consistently under-estimated?
- Testing stories under-estimated?

**Improve future estimates**:

- Adjust estimation multipliers (e.g., API integration = base estimate × 1.5)
- Create reference stories (e.g., "Webhook handler = 3-4 hours")
- Document lessons learned in estimate guide updates

## Example: Complete Estimate CSV

```csv
Epic,FT,Feature,ST,Story,Name,Description,Risk,Value,Hours
1,,,,,Renewal Fix,Fixes lockout issue,Low,High,
,1,1.1,,,Core Sync Service,,,,
,,,1,1.1.1,Fetch from Stax Bill,Sync Service Fetches from Stax Bill,,,3
,,,2,1.1.2,Update Local Database,Sync Service Updates Local Database,,,3
,,,3,1.1.3,Apply Grace Period Logic,Grace Period Logic Applied,,,2
,,,4,1.1.4,Handle Edge Cases,Sync Service Handles Edge Cases,,,4
,2,1.2,,,Invoice Webhook Handler,,,,
,,,1,1.2.1,Receive Invoice Events,Webhook Receives Invoice Events,,,2
,,,2,1.2.2,Detect Renewal,Renewal Detection via Invoice,,,3
,,,3,1.2.3,Trigger Sync,Webhook Triggers Sync Pattern,,,2
,,,4,1.2.4,Handle Errors,Webhook Error Handling,,,3
,3,1.3,,,Entitlements Integration,,,,
,,,1,1.3.1,Create Entitlements Endpoint,Renew Entitlement Endpoint Exists,,,3
,,,2,1.3.2,Create Entitlements Methods,Entitlements Client Method Available,,,2
,,,3,1.3.3,Update Entitlements,Sync Service Updates Entitlements,,,4
,,,4,1.3.4,Make Renewal Idempotent,Entitlement Renewal Idempotency,,,3
2,,,,,Schema Enhancement,Enables grace period,Low,High,
,1,2.1,,,Database Schema Enhancement,,,,
,,,1,2.1.1,Migrate Database,Migration Executes Successfully,,,2
,,,2,2.1.2,Create Repository Methods,Repository Methods Available,,,2
,,,3,2.1.3,Compute IsEntitled,IsEntitled Property Computes Correctly,,,2
,,,4,2.1.4,Rollback Migration,Migration Rollback Works,,,2
3,,,,,Reconciliation Safety Net,Ensures reliability,Medium,High,
,1,3.1,,,Reconciliation Job,,,,
,,,1,3.1.1,Run Job,Job Runs on Schedule,,,3
,,,2,3.1.2,Detect Drift,Drift Detection Works,,,4
,,,3,3.1.3,Prevent False Positives,No False Positives,,,2
,,,4,3.1.4,Handle Failures,Job Handles Failures Gracefully,,,3
,,,5,3.1.5,Log Metrics,Metrics and Logging,,,2
,2,3.2,,,Backfill Existing Data,,,,
,,,1,3.2.1,Create Backfill Endpoint,Backfill Endpoint Accessible,,,2
,,,2,3.2.2,Backfill Active Subscriptions,All Active Subscriptions Backfilled,,,3
,,,3,3.2.3,Make Backfill Idempotent,Backfill Idempotency,,,2
,,,4,3.2.4,Handle Missing Data,Backfill Handles Missing Stax Bill Data,,,2
,,,5,3.2.5,Verify Backfill,Backfill Verification,,,1
0,,,,,Cross Cutting Concerns,,Low,Medium,
,1,0.1,,,Integration & End-to-End Testing,,,,
,,,1,0.1.1,Test Renewal Flow,Complete Renewal Flow,,,4
,,,2,0.1.2,Test Failure and Recovery,Webhook Failure and Reconciliation Recovery,,,4
,,,3,0.1.3,Test Payment Grace Period,Payment Failure and Grace Period,,,4
,,,4,0.1.4,Test Grace Period Expiration,Grace Period Expiration,,,4
,2,0.2,,,Rollback & Monitoring,,,,
,,,1,0.2.1,Document Rollback,Rollback Procedure Documented,,,2
,,,2,0.2.2,Define Success Metrics,Success Metrics Defined,,,2
,,,3,0.2.3,Insure Zero Data Loss,Zero Data Loss on Rollback,,,2
,,,,,,TOTAL ESTIMATE,,,88
```

**Epic Totals** (calculated):

- Epic 1: 34 hours (12 + 10 + 12)
- Epic 2: 8 hours
- Epic 3: 24 hours (14 + 10)
- Epic 0: 22 hours (16 + 6)
- **Total: 88 hours**

## Markdown Linting Requirements

All estimate documentation must comply with the markdown standards defined in [markdown-standards.md](../markdown-standards.md).

### Quick Validation

```bash
markdownlint estimate-guide.md
```

See [markdown-standards.md](../markdown-standards.md) for complete linting rules, IDE setup, and enforcement policies.

## Summary

A well-crafted estimate CSV:

- **Drives** all other artifacts (delivery plan, presentation deck)
- **Structures** work into epics, features, and stories
- **Estimates** hours at story level (not epic or feature level)
- **Tracks** variance between estimated and actual hours
- **Improves** over time through post-mortem analysis

Use this guide as a checklist when creating or updating estimate CSVs for any initiative.
