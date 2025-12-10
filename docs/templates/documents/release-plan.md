# [Initiative Name] - Release Plan

**Work Item**: [TW-XXXXX or WI-xxx]
**Delivery Plan**: [delivery-plan.md](delivery-plan.md)
**Repository**: [Repository Name](repository-url)
**Target Environment**: Production

## Status Summary

| Metric | Value |
|--------|-------|
| Total PRs | X |
| Merged | Y |
| Pending Review | Z |
| Release Ready | No |

## Pull Request Status

| PR | Title | Branch | Status | Risk | Migration | Merged |
|----|-------|--------|--------|------|-----------|--------|
| #XXX | Story X.X.X - Description | `feature/branch-name` | Active | Low | No | - |

**Status**: Draft, Active, Approved, Merged, Closed
**Risk**: Low, Medium, High, Critical

## Impact Assessment

### Production Traffic Impact

[Describe whether production traffic flows through these changes. Be specific about which endpoints or code paths are affected.]

### Database Impact

| PR | Change | Table | Type | Reversible | Notes |
|----|--------|-------|------|------------|-------|
| #XXX | Description | TableName | Additive/Breaking | Yes/No | Details |

### API Contract Impact

[Document any changes to public API contracts - new endpoints, modified request/response schemas, removed endpoints]

### Dependencies

| Dependency | Status | Notes |
|------------|--------|-------|
| Service Name | Available/Pending | Description |

## Risk Analysis

### Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Risk description | Low/Medium/High | Low/Medium/High/Critical | How to prevent or handle |

### Overall Risk Level: [Low/Medium/High]

[One paragraph justification of the overall risk assessment]

## Deployment Checklist

### Pre-Deployment

- [ ] All PRs merged to main
- [ ] CI/CD pipeline passing
- [ ] Database backup completed
- [ ] Staging environment tested
- [ ] Release notes reviewed by team

### Deployment Steps

1. **Step Name**

   ```bash
   # Commands or instructions
   ```

2. **Deploy to Staging**
   - [Instructions]

3. **Verify Staging**
   - [Verification steps]

4. **Deploy to Production**
   - [Instructions]

5. **Verify Production**
   - [Verification steps]

### Post-Deployment Verification

- [ ] Application starts without errors
- [ ] Health endpoint responding
- [ ] Database migrations applied
- [ ] Key functionality smoke tested
- [ ] Monitoring dashboards normal

## Rollback Plan

### Rollback Triggers

- [Condition that should trigger rollback]
- [Condition that should trigger rollback]

### Rollback Steps

1. **Application Rollback**

   ```bash
   # Commands
   ```

2. **Database Rollback** (if applicable)

   ```bash
   # Commands
   ```

### Rollback Limitations

- [Describe any data or state that cannot be rolled back]

## Release Notes

### Version: [X.Y.Z or date]

### Summary

[One paragraph summary of the release]

### Changes

#### Added

- [New feature or capability]

#### Changed

- [Modification to existing behavior]

#### Fixed

- [Bug fix]

#### Technical

- [Internal change not visible to users]

### Known Issues

- [Known issue or limitation]

### Migration Notes

- [Manual steps required after deployment]

## Upcoming Work

| Story | Title | Dependency |
|-------|-------|------------|
| X.X.X | Title | Prerequisite |

## Change Log

| Date | Author | Change |
|------|--------|--------|
| YYYY-MM-DD | username | Initial release plan created |
