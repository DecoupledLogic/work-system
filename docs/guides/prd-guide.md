# PRD (Product Requirements Document) Guide

## Purpose

A Product Requirements Document defines what a feature should accomplish without prescribing how to implement it. It captures the vision, user needs, acceptance criteria, and constraints that guide design and implementation decisions.

## When to Create a PRD

Create a PRD when:

- **New feature**: Adding significant functionality to a product
- **Feature epic**: Breaking down a large capability into implementable scope
- **Product enhancement**: Major improvement to existing functionality
- **User-facing change**: Any change that affects how users interact with the product

Use simpler artifacts for:

- Bug fixes (use bug-report instead)
- Technical refactoring (use spec instead)
- Single-story tasks (include requirements in story)

## Relationship to Other Artifacts

### PRD Position in Workflow

```text
Product Strategy / Delivery Plan (Vision)
  ↓ (breaks down to)
PRD (Feature Requirements) ← You are here
  ↓ (informs)
Design Stage (Technical approach)
  ↓ (produces)
Spec (Story-level details)
```

### What Flows from PRD

**To Design**:

- **Vision** → Architecture goals
- **Actors** → User flow design
- **Acceptance criteria** → Technical requirements
- **Constraints** → Design constraints

**To Specs**:

- **Feature name** → Parent feature reference
- **Acceptance criteria** → Story acceptance criteria
- **Out of scope** → Boundary clarification

## Core Structure

### 1. Header

```markdown
# PRD: [Feature Name]

**Work Item**: [TW-12345 or WI-xxx]
**Created**: [Date]
**Status**: [Draft | Review | Approved]
```

### 2. Vision

```markdown
## Vision

[2-3 sentences describing what this feature enables and why it matters.
Focus on user outcomes, not implementation details.]
```

**Example**:

```markdown
## Vision

Enable pet owners to link multiple contacts (family members, pet sitters, emergency contacts) to their pet's profile. This allows clinics to reach the right person in emergencies and lets families share responsibility for pet care.
```

### 3. Actors

```markdown
## Actors

[List the user personas who interact with this feature]

- **[Actor 1]**: [Brief description of this persona]
- **[Actor 2]**: [Brief description of this persona]
```

**Example**:

```markdown
## Actors

- **Pet Owner**: Primary account holder who manages pet profiles
- **Secondary Contact**: Family member or caregiver with limited access
- **Clinic Tech**: Staff member who views and contacts pet guardians
- **Clinic Admin**: Staff member who manages clinic-side contact preferences
```

### 4. Jobs to be Done (Optional)

```markdown
## Jobs to be Done

[User needs framed as jobs. Format: "When [situation], I want to [action], so I can [outcome]"]

- When [situation], I want to [action], so I can [outcome].
- When [situation], I want to [action], so I can [outcome].
```

**Example**:

```markdown
## Jobs to be Done

- When I'm traveling, I want to give my pet sitter access to my pet's records, so they can handle emergencies.
- When my pet has an appointment, I want the clinic to be able to reach my spouse, so someone can answer even if I'm busy.
- When I need to contact a pet's owner, I want to see all available contacts, so I can reach someone quickly.
```

### 5. Acceptance Criteria

```markdown
## Acceptance Criteria

[Gherkin-format criteria that define when the feature is complete]

- GIVEN [precondition]
  WHEN [action]
  THEN [expected outcome]

- GIVEN [precondition]
  WHEN [action]
  THEN [expected outcome]
```

**Example**:

```markdown
## Acceptance Criteria

- GIVEN a pet owner viewing their pet's profile
  WHEN they click "Add Contact"
  THEN they can enter contact name, phone, email, and relationship

- GIVEN a pet with linked contacts
  WHEN a clinic tech views the pet's record
  THEN they see all contacts with their preferred contact method

- GIVEN a secondary contact
  WHEN they receive an invitation link
  THEN they can view the pet's profile without creating a full account

- GIVEN a pet owner
  WHEN they remove a linked contact
  THEN that contact immediately loses access to the pet's profile
```

### 6. Constraints

```markdown
## Constraints

[Technical, business, or regulatory limitations that affect implementation]

- [Constraint 1]
- [Constraint 2]
```

**Example**:

```markdown
## Constraints

- Maximum 5 linked contacts per pet (system limitation)
- Contact information must comply with GDPR (explicit consent required)
- Must work offline (contact list cached locally)
- Cannot expose one contact's information to another contact
```

### 7. Out of Scope

```markdown
## Out of Scope

[Explicitly excluded functionality to prevent scope creep]

- [Exclusion 1]
- [Exclusion 2]
```

**Example**:

```markdown
## Out of Scope

- Contact-to-contact messaging (contacts cannot message each other)
- Permission levels beyond view access (no edit permissions for contacts)
- Contact inheritance across pets (each pet's contacts are independent)
- Integration with external contact management systems
```

### 8. Risks (Optional)

```markdown
## Risks

[Potential issues that could affect feature success]

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk] | [H/M/L] | [H/M/L] | [Mitigation] |
```

**Example**:

```markdown
## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Users spam contacts with invitations | Medium | Low | Rate limit invitations, add unsubscribe |
| Privacy concerns from secondary contacts | Medium | Medium | Clear consent flow, easy removal |
| Clinic staff confused by multiple contacts | Low | Medium | Training materials, clear UI hierarchy |
```

### 9. Success Metrics (Optional)

```markdown
## Success Metrics

[How we'll measure feature success after launch]

- [Metric 1]: [Target]
- [Metric 2]: [Target]
```

**Example**:

```markdown
## Success Metrics

- Adoption: 20% of active pets have at least one linked contact within 90 days
- Engagement: Linked contacts view pet profile at least once per month
- Clinic efficiency: 15% reduction in "unable to reach owner" incidents
```

### 10. Dependencies (Optional)

```markdown
## Dependencies

[External dependencies that affect this feature]

- [Dependency 1]
- [Dependency 2]
```

## Template

When creating a new PRD, use this template:

```markdown
# PRD: [Feature Name]

**Work Item**: [ID]
**Created**: [Date]
**Status**: Draft

## Vision

[2-3 sentences on what this enables and why it matters]

## Actors

- **[Actor 1]**: [Description]
- **[Actor 2]**: [Description]

## Jobs to be Done

- When [situation], I want to [action], so I can [outcome].
- When [situation], I want to [action], so I can [outcome].

## Acceptance Criteria

- GIVEN [precondition]
  WHEN [action]
  THEN [expected outcome]

- GIVEN [precondition]
  WHEN [action]
  THEN [expected outcome]

## Constraints

- [Constraint 1]
- [Constraint 2]

## Out of Scope

- [Exclusion 1]
- [Exclusion 2]

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk] | [H/M/L] | [H/M/L] | [Mitigation] |

## Success Metrics

- [Metric]: [Target]
```

## Writing Good Acceptance Criteria

### Gherkin Format

```text
GIVEN [precondition/context]
WHEN [action/trigger]
THEN [expected outcome]
AND [additional outcome] (optional)
```

### Tips for Effective Criteria

1. **One behavior per criterion**: Don't combine multiple behaviors
2. **Testable outcomes**: Each criterion should be verifiable
3. **User perspective**: Write from the user's point of view
4. **Specific values**: Use concrete examples where helpful
5. **Edge cases**: Include boundary conditions and error cases

### Good vs. Bad Examples

**Bad**: "User can add contacts"

**Good**:

```text
GIVEN a pet owner on their pet's profile page
WHEN they click "Add Contact" and enter valid contact details
THEN the contact appears in the linked contacts list
AND the contact receives an invitation email
```

**Bad**: "System handles errors"

**Good**:

```text
GIVEN a pet owner adding a contact
WHEN they enter an invalid email format
THEN an inline error message explains the correct format
AND the form is not submitted
```

## Common Pitfalls

### Avoid These Mistakes

1. **Implementation details**: Describing how instead of what
   - **Fix**: Focus on user outcomes, leave implementation to design

2. **Vague acceptance criteria**: "Feature works correctly"
   - **Fix**: Use Gherkin format with specific, testable outcomes

3. **Missing actors**: Not identifying who uses the feature
   - **Fix**: List all user personas who interact with the feature

4. **Scope creep via "nice to haves"**: Including wishlist items
   - **Fix**: Put stretch goals in separate "Future Considerations" section

5. **No out of scope section**: Boundaries unclear
   - **Fix**: Explicitly state what is NOT included

6. **Conflicting criteria**: Acceptance criteria that contradict
   - **Fix**: Review criteria together for consistency

## Maintenance and Updates

### When to Update PRD

**Triggers for updates**:

- Acceptance criteria refined during design
- Constraints discovered during implementation
- Scope adjusted based on capacity
- Stakeholder feedback incorporated

### Update Process

1. **Track changes**: Note what changed and why
2. **Update status**: Move from Draft → Review → Approved
3. **Notify stakeholders**: Communicate significant changes
4. **Update specs**: Ensure downstream specs reflect PRD changes

## Markdown Linting Requirements

All PRDs must comply with the markdown standards defined in [markdown-standards.md](../markdown-standards.md).

### Quick Validation

```bash
markdownlint prd.md
```

## Summary

A well-crafted PRD:

- **Articulates** clear vision without implementation details
- **Identifies** all actors who interact with the feature
- **Defines** testable acceptance criteria in Gherkin format
- **Establishes** constraints and boundaries
- **Excludes** explicitly what's out of scope
- **Evolves** as understanding deepens during development

Use this guide when creating PRDs for features and epics.
