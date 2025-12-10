# Release Plan Guide

## Purpose

A release plan is a living document that tracks the release readiness of a work item or feature. It consolidates PR status, deployment steps, risk assessment, rollback procedures, and release notes into a single source of truth. The release plan is updated incrementally as each PR is merged, ensuring the team always has current information about what is ready to deploy and what risks to consider.

## When to Create a Release Plan

Create a release plan when:

- **Multiple PRs**: Work involves 2+ pull requests that should be released together
- **Database migrations**: Changes include schema modifications requiring coordinated deployment
- **Production impact**: Changes touch production data or user-facing functionality
- **Staged rollout**: Features require phased deployment or feature flags
- **Cross-service changes**: Work spans multiple microservices or repositories

Skip for:

- Single-PR bug fixes with no database changes
- Documentation-only changes
- Test-only changes that don't affect production

## Relationship to Other Artifacts

```text
Delivery Plan (Implementation)
  |
  +-> Release Plan (Deployment)
  |     |
  |     +-> Updated per PR
  |     +-> Risk assessment
  |     +-> Rollback procedures
  |
  +-> Testing Plan (Verification)
```

**From Delivery Plan**:

- **Stories** -> PR tracking rows in release plan
- **Implementation details** -> Technical deployment notes
- **Dependencies** -> Release order requirements

**To Operations**:

- **Deployment steps** -> Runbook for release
- **Rollback plan** -> Emergency procedures
- **Success criteria** -> Post-release verification checklist

## Core Structure

### Header and Metadata

```markdown
# [Initiative Name] Release Plan

**Work Item**: [TW-XXXXX or WI-xxx]
**Delivery Plan**: [Relative path to delivery-plan.md]
**Repository**: [Repository name and URL]
**Target Environment**: [Dev/Staging/Production]

## Status Summary

| Metric | Value |
|--------|-------|
| Total PRs | X |
| Merged | Y |
| Pending Review | Z |
| Release Ready | Yes/No |
```

### PR Tracking Table

Track each PR with its status, risk level, and key changes:

```markdown
## Pull Request Status

| PR | Title | Status | Risk | Migration | Merged |
|----|-------|--------|------|-----------|--------|
| #1045 | Story 1.1.1 - Fetch from API | Merged | Low | No | 2025-12-09 |
| #1047 | Story 1.1.2 - Update database | Active | Low | Yes | - |
```

**Status values**: Draft, Active, Approved, Merged, Closed
**Risk values**: Low, Medium, High, Critical

### Impact Assessment

Document what the changes affect:

```markdown
## Impact Assessment

### Production Traffic Impact

[Describe whether production traffic flows through these changes]

### Database Impact

| Change | Table | Type | Reversible |
|--------|-------|------|------------|
| Add column | Entity | Additive | Yes |
| Add index | Entity | Additive | Yes |

### API Contract Impact

[Document any changes to public API contracts]

### Dependencies

[List any service dependencies or deployment order requirements]
```

### Risk Analysis

```markdown
## Risk Analysis

### Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Migration fails | Low | Medium | Test in staging first |
| Performance regression | Low | Low | Monitor after deploy |

### Overall Risk Level: [Low/Medium/High]

[One paragraph justification of the overall risk assessment]
```

### Deployment Checklist

```markdown
## Deployment Checklist

### Pre-Deployment

- [ ] All PRs merged to main
- [ ] CI/CD pipeline passing
- [ ] Database backup completed
- [ ] Staging environment tested
- [ ] Release notes reviewed

### Deployment Steps

1. [Step-by-step deployment instructions]
2. [Include any manual steps required]
3. [Note any environment-specific configuration]

### Post-Deployment Verification

- [ ] Application starts without errors
- [ ] Health endpoints responding
- [ ] Database migrations applied successfully
- [ ] Key functionality smoke tested
- [ ] Monitoring dashboards show normal metrics
```

### Rollback Plan

```markdown
## Rollback Plan

### Rollback Triggers

- [Conditions that should trigger a rollback]

### Rollback Steps

1. [Step-by-step rollback instructions]
2. [Include database rollback if applicable]

### Rollback Limitations

[Document any data or state that cannot be rolled back]
```

### Release Notes

```markdown
## Release Notes

### Version: [X.Y.Z or date-based]

### Summary

[One paragraph summary of the release]

### Changes

#### Added

- [New features or capabilities]

#### Changed

- [Modifications to existing behavior]

#### Fixed

- [Bug fixes]

#### Technical

- [Internal changes not visible to users]

### Known Issues

- [Any known issues or limitations]

### Migration Notes

- [Any manual steps required after deployment]
```

### Change Log

```markdown
## Change Log

| Date | Author | Change |
|------|--------|--------|
| 2025-12-09 | username | Initial release plan created |
| 2025-12-09 | username | Added PR #1045 details |
| 2025-12-10 | username | Added PR #1047 risk assessment |
```

## Living Document Practices

### When to Update

Update the release plan when:

1. **PR created**: Add new row to PR tracking table
2. **PR merged**: Update status and merge date
3. **Risk identified**: Add to risk matrix with mitigation
4. **Deployment planned**: Fill in deployment checklist
5. **Release completed**: Update status summary and add to change log

### Update Workflow

```text
PR Created
  -> Add PR to tracking table (Status: Active)
  -> Assess risk level
  -> Document any migrations

PR Reviewed
  -> Update risk assessment if needed
  -> Add any reviewer concerns to risks

PR Merged
  -> Update status to Merged
  -> Record merge date
  -> Update release notes

All PRs Merged
  -> Set Release Ready: Yes
  -> Complete deployment checklist
  -> Finalize release notes
```

### Version Control

- Commit release plan updates with each PR
- Use descriptive commit messages: `docs: update release plan for PR #1047`
- Keep change log at bottom of document

## Example: Minimal Release Plan

For simple releases with 1-2 PRs:

```markdown
# Feature X Release Plan

**Work Item**: TW-12345
**Repository**: ServiceName

## PR Status

| PR | Title | Status | Risk | Migration |
|----|-------|--------|------|-----------|
| #100 | Add feature X | Merged | Low | No |

## Risk: Low

No database migrations. Additive changes only. No production traffic impact until feature is enabled.

## Deployment

1. Merge PR #100
2. Deploy to staging, verify
3. Deploy to production
4. Verify health endpoints

## Rollback

Revert commit and redeploy. No data migration required.
```

## Example: Complex Release Plan

For multi-PR releases with migrations, include:

- Detailed migration documentation
- Cross-service coordination steps
- Feature flag configuration
- Phased rollout plan
- Extended monitoring period

## Anti-Patterns

**Avoid these common mistakes**:

1. **Stale documentation**: Not updating after each PR
2. **Missing rollback plan**: Every release needs a way back
3. **Vague risk assessment**: Be specific about what could go wrong
4. **Incomplete deployment steps**: Someone unfamiliar should be able to follow
5. **No success criteria**: How do you know the release worked?

## Template

A blank release plan template is available at:
`/docs/templates/documents/release-plan.md`

## Related Guides

- [Delivery Plan Guide](delivery-plan-guide.md) - Implementation planning
- [Testing Plan Guide](testing-plan-guide.md) - Test coverage verification
- [Release Notes Guide](release-notes-guide.md) - User-facing changelog
