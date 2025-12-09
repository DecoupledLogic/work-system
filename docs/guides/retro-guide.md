# Retrospective Guide

## Purpose

A Retrospective (retro) captures learnings from completed work to improve future delivery. It documents what went well, what could improve, and specific action items to apply these learnings. Retros are stored globally because insights from one project inform all future work.

## When to Create a Retro

Create a retro when:

- **Feature completion**: After delivering a significant feature or epic
- **Sprint/iteration end**: Regular cadence for continuous improvement
- **Project milestone**: At key delivery points
- **Incident resolution**: After production issues or outages
- **Significant learnings**: When discoveries warrant documentation

Skip retro for:

- Trivial tasks without meaningful learnings
- Work that followed established patterns exactly
- Short tasks with no surprises or insights

## Relationship to Other Artifacts

### Retro Position in Workflow

```text
Development (Code written)
  ↓ (tested)
Delivery (Feature shipped)
  ↓ (documented)
Release Notes (Changes communicated)
  ↓ (reflected)
Retrospective (Learnings captured) ← You are here
  ↓ (informs)
Future Work (Improvements applied)
```

### What Flows Into Retro

**From Implementation**:

- **Challenges encountered** → What could improve
- **Successful approaches** → What went well
- **Time spent vs estimated** → Process learnings

**From Delivery**:

- **Deployment issues** → Technical learnings
- **User feedback** → Product learnings

**From Release Notes**:

- **Features delivered** → Scope for reflection
- **Known issues** → Areas for improvement

### What Flows from Retro

**To Future Planning**:

- **Estimates** → Calibration data
- **Risks** → Known pitfalls

**To Process**:

- **Action items** → Process improvements
- **Best practices** → Team standards

**To Future Retros**:

- **Action item status** → Follow-up tracking

## Core Structure

### 1. Header and Metadata

```markdown
# Retrospective: [Work Item Name]

**Work Item**: [TW-12345 or WI-xxx]
**Completed**: [Date]
**Duration**: [Actual time spent]
**Participants**: [Who was involved]
```

### 2. Summary

```markdown
## Summary

[Brief overview of what was delivered and the overall outcome]
```

**Example**:

```markdown
## Summary

Delivered the emergency contacts feature for pet profiles, allowing owners to add up to 5 contacts per pet. Feature shipped on time with positive initial user feedback. Some technical challenges with the database design extended implementation by 1 day.
```

### 3. What Went Well

```markdown
## What Went Well

### [Category]

- [Specific positive outcome]
- [Specific positive outcome]

### [Category]

- [Specific positive outcome]
```

**Example**:

```markdown
## What Went Well

### Planning

- Clear acceptance criteria from PRD made implementation straightforward
- Breaking work into phases allowed parallel frontend/backend development
- Early design review caught API inconsistencies before implementation

### Technical

- New ContactService followed established patterns, quick to implement
- TypeORM migrations worked smoothly in all environments
- Component tests caught two edge cases before QA

### Collaboration

- Daily syncs kept frontend and backend aligned on API contract
- Designer available for quick feedback on component styling
- QA involved early, test plan ready before implementation complete

### Delivery

- Zero critical bugs in production
- Users found the feature intuitive (based on support ticket volume)
- Performance met targets (< 200ms contact list load)
```

### 4. What Could Improve

```markdown
## What Could Improve

### [Category]

- **[Issue]**: [Description of what happened and impact]
- **[Issue]**: [Description of what happened and impact]
```

**Example**:

```markdown
## What Could Improve

### Planning

- **Junction table not in original spec**: Had to add pet_contacts table mid-implementation when many-to-many requirement became clear. Added 4 hours of rework.
- **Contact limit not specified early**: 5 contact limit was decided during implementation, required UI changes to show counter.

### Technical

- **Database index missing in initial migration**: Performance degraded with test data, had to add index as separate migration.
- **No pagination on contact list**: Will become problem as users add more contacts. Should have planned for this.

### Process

- **Late stakeholder feedback**: Product requested relationship field after backend was complete, required additional changes.
- **No staging environment testing**: Went straight from local to production, missed timezone issue.

### Communication

- **API changes not communicated**: Changed response format without updating mobile team, caused brief mobile app issues.
```

### 5. Action Items

```markdown
## Action Items

| Action | Owner | Due | Status |
|--------|-------|-----|--------|
| [Action description] | [Name] | [Date] | [Open/In Progress/Done] |
```

**Example**:

```markdown
## Action Items

| Action | Owner | Due | Status |
|--------|-------|-----|--------|
| Add pagination to spec checklist template | Sarah | 2024-12-15 | Open |
| Update API change notification process | Mike | 2024-12-20 | Open |
| Create staging environment for feature testing | DevOps | 2024-12-31 | In Progress |
| Add relationship types to data model documentation | Chris | 2024-12-12 | Done |
| Review specs for missing many-to-many relationships | Team | 2024-12-18 | Open |
```

### 6. Metrics (Optional)

```markdown
## Metrics

| Metric | Planned | Actual | Notes |
|--------|---------|--------|-------|
| [Metric] | [Value] | [Value] | [Explanation] |
```

**Example**:

```markdown
## Metrics

| Metric | Planned | Actual | Notes |
|--------|---------|--------|-------|
| Duration | 5 days | 6 days | Junction table rework added 1 day |
| Story points | 8 | 8 | Accurate estimate despite scope additions |
| Test coverage | 80% | 87% | Exceeded target |
| Bugs found in QA | - | 3 | All minor, fixed same day |
| Bugs in production | 0 | 0 | Clean release |
| Support tickets (week 1) | - | 2 | Both feature requests, not bugs |
```

### 7. Key Learnings

```markdown
## Key Learnings

1. **[Learning title]**: [Detailed learning that can be applied to future work]

2. **[Learning title]**: [Detailed learning that can be applied to future work]
```

**Example**:

```markdown
## Key Learnings

1. **Identify relationship cardinality early**: Many-to-many relationships require junction tables. During spec review, explicitly ask "Can X have multiple Ys? Can Y have multiple Xs?" to catch these early.

2. **Include limits in acceptance criteria**: Any feature with user-created lists should specify limits upfront. This affects UI (counter display), API (validation), and database (query planning).

3. **Parallel development needs API contract freeze**: When frontend and backend work in parallel, establish and freeze API contracts early. Changes after implementation starts cause coordination overhead.

4. **Always test in staging**: Even for "simple" features, staging environment testing catches environment-specific issues (timezones, config, data volume) that local testing misses.

5. **Pagination is not premature optimization**: If users can create unbounded lists, pagination should be in the initial design. Retrofitting pagination is more expensive than building it in.
```

### 8. Follow-up from Previous Retros (Optional)

```markdown
## Follow-up from Previous Retros

| Previous Action | Status | Outcome |
|----------------|--------|---------|
| [Action from previous retro] | [Status] | [What happened] |
```

**Example**:

```markdown
## Follow-up from Previous Retros

| Previous Action | Status | Outcome |
|----------------|--------|---------|
| Add integration test suite for API | Done | Used in this feature, caught 2 bugs |
| Document deployment runbook | Done | Smooth deployment using new runbook |
| Improve error messages | Partial | Backend done, frontend still needed |
```

## Template

When creating a retro, use this template:

```markdown
# Retrospective: [Work Item Name]

**Work Item**: [ID]
**Completed**: [Date]
**Duration**: [Time spent]

## Summary

[Brief overview of outcome]

## What Went Well

### Planning

- [Positive]

### Technical

- [Positive]

### Delivery

- [Positive]

## What Could Improve

### Planning

- **[Issue]**: [Impact]

### Technical

- **[Issue]**: [Impact]

### Process

- **[Issue]**: [Impact]

## Action Items

| Action | Owner | Due | Status |
|--------|-------|-----|--------|
| [Action] | [Owner] | [Date] | Open |

## Key Learnings

1. **[Learning]**: [Application to future work]

2. **[Learning]**: [Application to future work]
```

## Writing Guidelines

### Be Specific, Not Vague

**Vague**:

```markdown
- Communication was sometimes difficult
```

**Specific**:

```markdown
- **API changes not communicated**: Changed response format without notifying mobile team, causing 2 hours of debugging and a hotfix.
```

### Focus on Systems, Not People

Retros improve processes, not assign blame:

**Blame-Focused**:

```markdown
- Developer didn't test properly
```

**System-Focused**:

```markdown
- No staging environment for pre-production testing meant issues only discovered in production
```

### Make Action Items Actionable

**Not Actionable**:

```markdown
| Action | Owner | Due |
|--------|-------|-----|
| Be more careful | Everyone | Ongoing |
```

**Actionable**:

```markdown
| Action | Owner | Due |
|--------|-------|-----|
| Add pre-commit hook to run linter | DevOps | 2024-12-15 |
```

### Extract Reusable Learnings

Transform specific incidents into general principles:

**Specific Incident**:

```markdown
We forgot pagination on the contacts list.
```

**Reusable Learning**:

```markdown
Any feature with user-created lists should include pagination in the initial design. Add "pagination requirements" to the spec template checklist.
```

## Categories for Organization

### Common "What Went Well" Categories

- **Planning**: Requirements, estimates, scope
- **Technical**: Architecture, code quality, testing
- **Collaboration**: Communication, teamwork, reviews
- **Delivery**: Deployment, performance, quality
- **Process**: Workflows, tools, automation

### Common "What Could Improve" Categories

- **Planning**: Missing requirements, underestimates
- **Technical**: Bugs, performance, technical debt
- **Process**: Bottlenecks, inefficiencies
- **Communication**: Coordination, documentation
- **Tools**: Missing automation, environment issues

## Storage and Location

Retros are stored globally because learnings apply across projects:

```text
~/.claude/docs/retros/
├── TW-26134585-pet-contacts-retro.md
├── TW-26134590-appointment-reminders-retro.md
└── TW-26134600-api-redesign-retro.md
```

## Common Pitfalls

### Avoid These Mistakes

1. **All positive, no improvements**: Missed learning opportunity
   - **Fix**: Require at least 2-3 improvement items

2. **No action items**: Learnings not applied
   - **Fix**: Every improvement should have an action

3. **Vague action items**: "Be more careful"
   - **Fix**: Specific, measurable, time-bound actions

4. **No follow-up**: Actions never completed
   - **Fix**: Review previous actions in each retro

5. **Blame individuals**: Creates defensive culture
   - **Fix**: Focus on process and systems

6. **Too long after completion**: Details forgotten
   - **Fix**: Write retro within 1-2 days of completion

## Maintenance

### During Delivery

- Note issues as they happen (don't rely on memory)
- Track time spent vs estimated
- Collect feedback from stakeholders

### After Delivery

- Write retro within 1-2 days while fresh
- Get input from all participants
- Create action items with owners and dates

### Ongoing

- Review action item status weekly
- Reference previous retros when planning similar work
- Update action items when completed

## Markdown Linting Requirements

All retros must comply with the markdown standards defined in [markdown-standards.md](../reference/markdown-standards.md).

### Quick Validation

```bash
markdownlint retro.md
```

## Summary

A well-crafted retrospective:

- **Captures** what went well to reinforce good practices
- **Identifies** what could improve without blame
- **Creates** specific, actionable improvement items
- **Extracts** reusable learnings for future work
- **Tracks** action items to ensure follow-through
- **Measures** metrics to calibrate future estimates

Use this guide when documenting retrospectives after completing work.
