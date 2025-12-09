# Release Notes Guide

## Purpose

Release notes communicate what changed in a release to stakeholders, users, and other teams. They summarize new features, improvements, bug fixes, and any breaking changes or migration requirements.

## When to Create Release Notes

Create release notes when:

- **Version release**: Deploying a new version to production
- **Feature launch**: Significant new functionality goes live
- **Breaking changes**: Changes that require user action
- **Security updates**: Patches addressing vulnerabilities
- **Milestone completion**: End of a sprint or development cycle

Skip release notes for:

- Internal development builds
- Hotfixes with no user-visible impact
- Dependency updates (unless breaking)
- Refactoring without behavior changes

## Relationship to Other Artifacts

### Release Notes Position in Workflow

```text
Development (Code written)
  ↓ (tested)
Test Plan (Tests pass)
  ↓ (deployed)
Release (Version shipped)
  ↓ (documented)
Release Notes (Changes communicated) ← You are here
  ↓ (informs)
Retrospective (Learnings captured)
```

### What Flows Into Release Notes

**From Implementation Plans**:

- **Completed tasks** → Feature descriptions
- **Goals** → Release highlights

**From PRDs/Specs**:

- **Feature names** → Feature list
- **Acceptance criteria** → Feature descriptions

**From Bug Reports**:

- **Symptoms** → Bug fix descriptions
- **Impact** → Priority of fixes

**From ADRs**:

- **Decisions** → Breaking changes explanation
- **Consequences** → Migration guidance

### What Flows from Release Notes

**To Users**:

- **Features** → What they can now do
- **Fixes** → Problems resolved
- **Breaking changes** → Required actions

**To Support Teams**:

- **Known issues** → Support documentation
- **Changes** → Training material

**To Retrospective**:

- **Delivered features** → What was accomplished
- **Timeline** → Delivery assessment

## Core Structure

### 1. Header and Metadata

```markdown
# Release Notes: v[Version]

**Release Date**: [Date]
**Environment**: [Production | Staging | Beta]
**Build**: [Build number or commit hash]
```

### 2. Highlights

```markdown
## Highlights

[Brief overview of the most important changes in this release - 2-3 sentences]
```

**Example**:

```markdown
## Highlights

This release introduces emergency contacts for pet profiles, allowing clinics to reach family members during urgent situations. We've also improved appointment scheduling performance and fixed several bugs reported by users.
```

### 3. New Features

```markdown
## New Features

### [Feature Name]

[Description of what the feature does and why it matters]

**How to use**:

1. [Step 1]
2. [Step 2]

**Related work item**: [TW-12345]
```

**Example**:

```markdown
## New Features

### Emergency Contacts for Pets

Pet owners can now add up to 5 emergency contacts to each pet's profile. Clinic staff can see these contacts and reach family members during emergencies when the primary owner is unavailable.

**How to use**:

1. Navigate to your pet's profile
2. Scroll to the "Emergency Contacts" section
3. Click "Add Contact" and enter contact details
4. Save to link the contact to your pet

**Related work item**: TW-26134586

### Appointment Reminders

Configure automated SMS and email reminders for upcoming appointments. Choose reminder timing (24 hours, 48 hours, or 1 week before).

**How to use**:

1. Go to Settings > Notifications
2. Enable appointment reminders
3. Select preferred reminder timing
4. Optionally customize reminder message

**Related work item**: TW-26134590
```

### 4. Improvements

```markdown
## Improvements

- **[Area]**: [What improved and how]
- **[Area]**: [What improved and how]
```

**Example**:

```markdown
## Improvements

- **Appointment scheduling**: Reduced page load time by 40% through query optimization
- **Search**: Added fuzzy matching for pet name searches, finding results even with typos
- **Mobile**: Improved touch targets for action buttons on smaller screens
- **Reports**: Added export to CSV option for vaccination reports
```

### 5. Bug Fixes

```markdown
## Bug Fixes

- **[Area]**: [What was broken and how it's fixed]
- **[Area]**: [What was broken and how it's fixed]
```

**Example**:

```markdown
## Bug Fixes

- **Login**: Fixed issue where users were logged out unexpectedly after 15 minutes of inactivity (TW-26134600)
- **Pet profiles**: Resolved duplicate entries appearing when rapidly clicking save button (TW-26134601)
- **Appointments**: Fixed incorrect timezone display for users in non-US timezones (TW-26134602)
- **Reports**: Corrected calculation error in monthly revenue totals (TW-26134603)
```

### 6. Breaking Changes

```markdown
## Breaking Changes

### [Change Name]

**What changed**: [Description of the change]

**Impact**: [Who is affected and how]

**Required action**: [What users need to do]

**Migration guide**: [Step-by-step migration instructions]
```

**Example**:

```markdown
## Breaking Changes

### API Authentication Update

**What changed**: API authentication now requires OAuth 2.0 tokens instead of API keys. Legacy API key authentication will be disabled on January 15, 2025.

**Impact**: All integrations using the REST API must update their authentication method.

**Required action**: Generate OAuth credentials and update your integration before January 15, 2025.

**Migration guide**:

1. Log in to Settings > API Access
2. Click "Generate OAuth Credentials"
3. Note your Client ID and Client Secret
4. Update your integration to use OAuth 2.0 Bearer tokens
5. Test in staging before production cutover
6. Delete your legacy API key once migration is complete

See [API Migration Documentation](https://docs.example.com/api-migration) for detailed instructions.
```

### 7. Deprecations

```markdown
## Deprecations

### [Feature Name]

**Status**: Deprecated as of v[version], removal planned for v[version]

**Reason**: [Why this is being deprecated]

**Replacement**: [What to use instead]
```

**Example**:

```markdown
## Deprecations

### Legacy Report Builder

**Status**: Deprecated as of v2.5, removal planned for v3.0 (March 2025)

**Reason**: The new Report Studio provides all legacy functionality plus advanced features including scheduled reports and custom visualizations.

**Replacement**: Use Report Studio (Reports > Report Studio) for all reporting needs. Existing legacy reports will be automatically migrated.
```

### 8. Known Issues

```markdown
## Known Issues

- **[Area]**: [Description of issue and workaround if available]
```

**Example**:

```markdown
## Known Issues

- **Safari 16**: Date picker may not display correctly on Safari 16.x. Use Chrome or Firefox as a workaround. Fix planned for v2.5.1.
- **Large file uploads**: Files over 50MB may timeout on slower connections. We're working on chunked upload support for v2.6.
```

### 9. Technical Notes (Optional)

```markdown
## Technical Notes

### Database Migrations

[Description of any database changes]

### Configuration Changes

[New or modified configuration options]

### Dependency Updates

[Notable dependency version changes]
```

**Example**:

```markdown
## Technical Notes

### Database Migrations

This release includes 3 database migrations that run automatically on deployment:

1. `20241208_001_create_contacts` - Creates contacts table
2. `20241208_002_create_pet_contacts` - Creates junction table
3. `20241208_003_add_contact_indexes` - Adds performance indexes

**Estimated migration time**: < 5 minutes for databases under 1M records

### Configuration Changes

New environment variable:

- `CONTACT_LIMIT_PER_PET`: Maximum contacts per pet (default: 5)

### Dependency Updates

- React upgraded from 18.2 to 18.3
- Node.js minimum version now 18.x (was 16.x)
```

## Template

When creating release notes, use this template:

```markdown
# Release Notes: v[Version]

**Release Date**: [Date]
**Environment**: Production
**Build**: [Build/commit]

## Highlights

[2-3 sentence overview of key changes]

## New Features

### [Feature Name]

[Description]

**How to use**: [Brief instructions]

**Related work item**: [ID]

## Improvements

- **[Area]**: [Improvement description]

## Bug Fixes

- **[Area]**: [Fix description] ([ID])

## Breaking Changes

### [Change Name]

**What changed**: [Description]
**Required action**: [What to do]

## Known Issues

- **[Area]**: [Issue and workaround]
```

## Writing Guidelines

### Audience-Appropriate Language

Write for your audience:

- **End users**: Focus on what they can do, not technical implementation
- **Developers/API users**: Include technical details and code examples
- **Administrators**: Emphasize configuration and deployment changes

**Too Technical** (for end users):

```markdown
Optimized N+1 query in PetRepository.GetWithContacts() using eager loading with Include().
```

**User-Friendly**:

```markdown
Pet profile pages now load faster, especially for pets with many records.
```

### Feature Descriptions

Focus on benefits, not implementation:

**Implementation-Focused**:

```markdown
Added ContactService with CRUD endpoints and React components for contact management.
```

**Benefit-Focused**:

```markdown
Add emergency contacts to your pet's profile so clinic staff can reach your family during emergencies.
```

### Bug Fix Descriptions

Describe the symptom and resolution:

**Vague**:

```markdown
Fixed login bug.
```

**Clear**:

```markdown
Fixed issue where users were logged out unexpectedly after 15 minutes of inactivity.
```

### Breaking Change Communication

Be explicit about impact and required actions:

**Incomplete**:

```markdown
Changed authentication method.
```

**Complete**:

```markdown
API authentication now requires OAuth 2.0 tokens. Legacy API keys will stop working on January 15, 2025. Update your integration before this date - see migration guide below.
```

## Versioning Conventions

### Semantic Versioning

Follow semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR** (3.0.0): Breaking changes, major rewrites
- **MINOR** (2.5.0): New features, non-breaking
- **PATCH** (2.4.1): Bug fixes, minor improvements

### Version Naming

Include version in document title and filename:

- Document: `# Release Notes: v2.5.0`
- Filename: `v2.5.0-notes.md`

## Common Pitfalls

### Avoid These Mistakes

1. **Missing breaking changes**: Users surprised by broken integrations
   - **Fix**: Review all API/schema changes for breaking impact

2. **Internal jargon**: References to internal systems users don't know
   - **Fix**: Use user-facing terminology

3. **No migration guidance**: Breaking changes without instructions
   - **Fix**: Include step-by-step migration guide

4. **Incomplete bug descriptions**: "Fixed bugs"
   - **Fix**: Describe the symptom that was fixed

5. **Missing work item links**: Can't trace changes to requirements
   - **Fix**: Include work item IDs for traceability

6. **Stale known issues**: Issues from old releases still listed
   - **Fix**: Review and update known issues each release

## Maintenance

### Pre-Release

1. Gather completed work items since last release
2. Review PRs/commits for undocumented changes
3. Check for breaking changes requiring migration docs
4. Verify all work item links are correct

### Post-Release

1. Update any known issues discovered after release
2. Link release notes from changelog
3. Archive in release documentation
4. Notify stakeholders of availability

## Markdown Linting Requirements

All release notes must comply with the markdown standards defined in [markdown-standards.md](../reference/markdown-standards.md).

### Quick Validation

```bash
markdownlint release-notes.md
```

## Summary

Well-crafted release notes:

- **Highlight** the most important changes upfront
- **Describe** features in terms of user benefits
- **Document** all breaking changes with migration guides
- **List** bug fixes with clear symptom descriptions
- **Acknowledge** known issues with workarounds
- **Link** to related work items for traceability

Use this guide when documenting releases.
