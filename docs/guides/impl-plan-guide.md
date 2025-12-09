# Implementation Plan Guide

## Purpose

An Implementation Plan breaks down a story or feature into discrete, actionable tasks that guide development. It transforms technical specifications into a sequenced checklist of work items, ensuring systematic progress and clear completion criteria.

## When to Create an Implementation Plan

Create an implementation plan when:

- **Story implementation**: Any story ready for development
- **Multi-step work**: Tasks requiring coordination across components
- **Team handoff**: Work that may be picked up by different developers
- **Complex changes**: Features touching multiple systems or services
- **Dependency management**: Work with prerequisites or sequencing needs

Skip implementation plan for:

- Trivial fixes (single-file changes)
- Spikes and research tasks
- Pure documentation updates
- Config-only changes

## Relationship to Other Artifacts

### Implementation Plan Position in Workflow

```text
Spec (Technical approach documented)
  ↓ (broken into)
Implementation Plan (Tasks defined) ← You are here
  ↓ (guides)
Development (Code written)
  ↓ (verified by)
Test Plan (Tests executed)
```

### What Flows Into Implementation Plan

**From Spec**:

- **Technical approach** → Task breakdown
- **API changes** → API implementation tasks
- **Data changes** → Migration tasks
- **UI changes** → Frontend tasks
- **Acceptance criteria** → Verification checklist

**From Test Plan**:

- **Test cases** → Test implementation tasks
- **Coverage matrix** → Test task priorities

### What Flows from Implementation Plan

**To Development**:

- **Tasks** → Work checklist
- **Sequence** → Dependency order
- **Verification** → Completion criteria

**To Project Tracking**:

- **Tasks** → Subtasks in work management
- **Dependencies** → Task relationships

## Core Structure

### 1. Header and Metadata

```markdown
# Implementation Plan: [Work Item Name]

**Work Item**: [TW-12345 or WI-xxx]
**Spec**: [Link to spec]
**Created**: [Date]
**Status**: Draft | In Progress | Complete
```

### 2. Overview

```markdown
## Overview

[Brief summary of what this implementation achieves]

### Goals

- [Goal 1]
- [Goal 2]

### Non-Goals

- [Explicitly excluded item 1]
- [Explicitly excluded item 2]
```

**Example**:

```markdown
## Overview

Implement the pet contacts feature allowing owners to link emergency contacts to their pets. This enables clinic staff to reach family members during emergencies.

### Goals

- Add contacts CRUD functionality
- Link contacts to pets with junction table
- Display contacts on pet profile
- Enforce 5 contact limit per pet

### Non-Goals

- Contact import from phone (future feature)
- Contact sharing between owners (out of scope)
- SMS/email notification preferences (separate story)
```

### 3. Prerequisites

```markdown
## Prerequisites

- [ ] [Prerequisite 1]
- [ ] [Prerequisite 2]
```

**Example**:

```markdown
## Prerequisites

- [ ] Database migration system configured
- [ ] API authentication working
- [ ] Pet profile page exists
- [ ] Design mockups approved
```

### 4. Task Breakdown

```markdown
## Tasks

### Phase 1: [Phase Name]

#### Task 1.1: [Task Name]

**File(s)**: `path/to/file.ts`

**Description**: [What this task accomplishes]

**Steps**:

1. [Step 1]
2. [Step 2]
3. [Step 3]

**Verification**:

- [ ] [How to verify completion]

---

#### Task 1.2: [Task Name]

**Depends on**: Task 1.1

...
```

**Example**:

```markdown
## Tasks

### Phase 1: Database Setup

#### Task 1.1: Create contacts table migration

**File(s)**: `migrations/20241208_create_contacts.sql`

**Description**: Create the contacts table for storing emergency contact information.

**Steps**:

1. Create migration file with contacts table schema
2. Include id, owner_id, name, phone, email, relationship columns
3. Add foreign key to owners table
4. Add indexes on owner_id

**Verification**:

- [ ] Migration runs without errors
- [ ] Table exists with correct schema
- [ ] Foreign key constraint works

---

#### Task 1.2: Create pet_contacts junction table migration

**Depends on**: Task 1.1

**File(s)**: `migrations/20241208_create_pet_contacts.sql`

**Description**: Create junction table linking pets to contacts.

**Steps**:

1. Create migration with pet_id, contact_id columns
2. Add composite unique constraint
3. Add foreign keys to pets and contacts
4. Add index on pet_id for efficient lookup

**Verification**:

- [ ] Migration runs without errors
- [ ] Unique constraint prevents duplicates
- [ ] Cascade delete works correctly

---

### Phase 2: Backend Implementation

#### Task 2.1: Create Contact model

**Depends on**: Task 1.1

**File(s)**: `src/models/Contact.ts`

**Description**: Define the Contact entity with TypeORM decorators.

**Steps**:

1. Create Contact class with entity decorator
2. Define columns matching database schema
3. Add relationship to Owner entity
4. Add relationship to PetContact junction

**Verification**:

- [ ] Model compiles without errors
- [ ] Can create/read contacts via ORM

---

#### Task 2.2: Create ContactService

**Depends on**: Task 2.1

**File(s)**: `src/services/ContactService.ts`

**Description**: Service layer for contact CRUD operations.

**Steps**:

1. Create service class with repository injection
2. Implement createContact method
3. Implement updateContact method
4. Implement deleteContact method
5. Implement getContactsByOwner method

**Verification**:

- [ ] Unit tests pass for all methods
- [ ] Service handles errors appropriately

---

#### Task 2.3: Create PetContactService

**Depends on**: Task 2.2, Task 1.2

**File(s)**: `src/services/PetContactService.ts`

**Description**: Service for linking contacts to pets.

**Steps**:

1. Create service with repository injection
2. Implement linkContact method with limit check
3. Implement unlinkContact method
4. Implement getContactsForPet method

**Verification**:

- [ ] Cannot link more than 5 contacts
- [ ] Duplicate links rejected
- [ ] Unlink removes only the link, not the contact

---

#### Task 2.4: Create API endpoints

**Depends on**: Task 2.3

**File(s)**: `src/controllers/PetContactController.ts`

**Description**: REST endpoints for pet contact management.

**Steps**:

1. POST /api/pets/{petId}/contacts - link contact
2. GET /api/pets/{petId}/contacts - list contacts
3. DELETE /api/pets/{petId}/contacts/{linkId} - unlink
4. Add request validation
5. Add error handling

**Verification**:

- [ ] All endpoints return correct status codes
- [ ] Validation errors return 400
- [ ] Not found returns 404
- [ ] Limit exceeded returns 400

---

### Phase 3: Frontend Implementation

#### Task 3.1: Create ContactCard component

**Depends on**: None (can parallel with backend)

**File(s)**: `src/components/ContactCard.tsx`

**Description**: Display component for a single contact.

**Steps**:

1. Create component with contact props
2. Display name, phone, relationship
3. Add edit and remove action buttons
4. Style according to design mockups

**Verification**:

- [ ] Matches design mockup
- [ ] Action buttons trigger callbacks

---

#### Task 3.2: Create ContactList component

**Depends on**: Task 3.1

**File(s)**: `src/components/ContactList.tsx`

**Description**: List component showing all pet contacts.

**Steps**:

1. Create component accepting contacts array
2. Map to ContactCard components
3. Show empty state when no contacts
4. Display "X of 5 contacts" indicator

**Verification**:

- [ ] Empty state displays correctly
- [ ] Contact count shows accurately
- [ ] List scrolls when needed

---

#### Task 3.3: Create AddContactModal component

**Depends on**: Task 3.1

**File(s)**: `src/components/AddContactModal.tsx`

**Description**: Modal form for adding/editing contacts.

**Steps**:

1. Create modal with form fields
2. Add validation for required fields
3. Handle save and cancel actions
4. Support edit mode for existing contacts

**Verification**:

- [ ] Form validates before submit
- [ ] Modal closes on save/cancel
- [ ] Edit mode populates existing values

---

#### Task 3.4: Integrate contacts into PetProfile

**Depends on**: Task 3.2, Task 3.3, Task 2.4

**File(s)**: `src/pages/PetProfile.tsx`

**Description**: Add contacts section to pet profile page.

**Steps**:

1. Add ContactList to profile layout
2. Wire up API calls for CRUD
3. Handle loading and error states
4. Refresh list after changes

**Verification**:

- [ ] Contacts load with pet profile
- [ ] Add/edit/remove work end-to-end
- [ ] Error messages display appropriately

---

### Phase 4: Testing

#### Task 4.1: Write backend unit tests

**Depends on**: Task 2.4

**File(s)**: `tests/services/ContactService.test.ts`, `tests/services/PetContactService.test.ts`

**Steps**:

1. Test ContactService CRUD operations
2. Test PetContactService link/unlink
3. Test contact limit enforcement
4. Test error scenarios

**Verification**:

- [ ] All tests pass
- [ ] Coverage > 80%

---

#### Task 4.2: Write API integration tests

**Depends on**: Task 2.4

**File(s)**: `tests/api/petContacts.test.ts`

**Steps**:

1. Test endpoint responses
2. Test validation errors
3. Test authentication requirements
4. Test edge cases

**Verification**:

- [ ] All tests pass
- [ ] API contract verified

---

#### Task 4.3: Write frontend component tests

**Depends on**: Task 3.4

**File(s)**: `tests/components/ContactList.test.tsx`

**Steps**:

1. Test ContactCard rendering
2. Test ContactList states
3. Test AddContactModal validation
4. Test integration with profile

**Verification**:

- [ ] All tests pass
- [ ] Components render correctly
```

### 5. Dependency Graph (Optional)

```markdown
## Dependency Graph

```text
Task 1.1 ─┬─> Task 1.2 ──┬──> Task 2.3 ──> Task 2.4 ──┬──> Task 3.4
          │              │                            │
          └─> Task 2.1 ──┴──> Task 2.2 ───────────────┤
                                                      │
Task 3.1 ──> Task 3.2 ────────────────────────────────┤
     │                                                │
     └─────> Task 3.3 ────────────────────────────────┘
```
```

### 6. Verification Checklist

```markdown
## Verification Checklist

### Functional

- [ ] All acceptance criteria met
- [ ] Happy path works end-to-end
- [ ] Error scenarios handled

### Technical

- [ ] All tests pass
- [ ] No lint errors
- [ ] No type errors
- [ ] Code reviewed

### Deployment

- [ ] Migrations tested
- [ ] Feature flag configured (if applicable)
- [ ] Documentation updated
```

## Template

When creating a new implementation plan, use this template:

```markdown
# Implementation Plan: [Work Item Name]

**Work Item**: [ID]
**Spec**: [Link]
**Created**: [Date]
**Status**: Draft

## Overview

[Brief summary]

### Goals

- [Goal 1]
- [Goal 2]

### Non-Goals

- [Non-goal 1]

## Prerequisites

- [ ] [Prerequisite 1]
- [ ] [Prerequisite 2]

## Tasks

### Phase 1: [Phase Name]

#### Task 1.1: [Task Name]

**File(s)**: `path/to/file`

**Description**: [What this accomplishes]

**Steps**:

1. [Step]
2. [Step]

**Verification**:

- [ ] [Verification item]

---

#### Task 1.2: [Task Name]

**Depends on**: Task 1.1

...

### Phase 2: [Phase Name]

...

## Verification Checklist

### Functional

- [ ] All acceptance criteria met

### Technical

- [ ] All tests pass
- [ ] Code reviewed

### Deployment

- [ ] Migrations tested
```

## Task Writing Guidelines

### Task Granularity

Tasks should be:

- **Completable in one session**: 1-4 hours of focused work
- **Independently verifiable**: Can confirm completion without other tasks
- **Clearly scoped**: Obvious when task starts and ends

**Too Big**:

```markdown
#### Task: Implement backend

Implement all backend functionality for contacts feature.
```

**Just Right**:

```markdown
#### Task: Create ContactService with CRUD methods

Implement the service layer for contact create, read, update, delete operations.
```

**Too Small**:

```markdown
#### Task: Add import statement

Add import for Contact model.
```

### Dependency Documentation

Always note dependencies explicitly:

```markdown
**Depends on**: Task 1.1, Task 2.3
```

Dependencies enable:

- Parallel work identification
- Blocking issue awareness
- Progress tracking

### Verification Criteria

Each task needs clear completion criteria:

**Vague**:

```markdown
**Verification**:

- [ ] Works correctly
```

**Specific**:

```markdown
**Verification**:

- [ ] Unit tests pass for all methods
- [ ] API returns 201 on success
- [ ] Validation rejects invalid input
```

## Common Pitfalls

### Avoid These Mistakes

1. **Missing dependencies**: Tasks that secretly depend on others
   - **Fix**: Trace data/code flow to find all dependencies

2. **Vague verification**: "Make sure it works"
   - **Fix**: List specific testable criteria

3. **Giant tasks**: "Implement feature"
   - **Fix**: Break into 1-4 hour chunks

4. **No phases**: Flat list of unrelated tasks
   - **Fix**: Group by component or workflow stage

5. **Implementation details in steps**: Writing actual code
   - **Fix**: Describe what to do, not the code itself

6. **Missing error handling tasks**: Only happy path
   - **Fix**: Include tasks for validation, errors, edge cases

## Maintenance

Update implementation plan when:

- Tasks discovered during development
- Dependencies change
- Scope adjusts
- Blockers identified
- Verification criteria need refinement

Mark tasks complete as they finish:

```markdown
#### Task 1.1: Create contacts table migration ✅

...

**Verification**:

- [x] Migration runs without errors
- [x] Table exists with correct schema
- [x] Foreign key constraint works
```

## Markdown Linting Requirements

All implementation plans must comply with the markdown standards defined in [markdown-standards.md](../reference/markdown-standards.md).

### Quick Validation

```bash
markdownlint impl-plan.md
```

## Summary

A well-crafted implementation plan:

- **Breaks down** work into manageable tasks
- **Documents** dependencies between tasks
- **Specifies** clear verification criteria
- **Groups** tasks into logical phases
- **Enables** parallel work where possible
- **Tracks** progress toward completion

Use this guide when creating implementation plans for stories and features.
