# Technical Specification Guide

## Purpose

A Technical Specification (spec) documents the detailed requirements and technical approach for implementing a story. It bridges the gap between product requirements and actual code, providing developers with clear guidance on what to build and how to build it.

## When to Create a Spec

Create a spec when:

- **Story implementation**: Any story that requires code changes
- **Complex logic**: Business rules with multiple branches or edge cases
- **API changes**: New endpoints or modifications to existing APIs
- **Data model changes**: Schema modifications or new entities
- **Integration points**: Connecting with external systems or services

Skip spec for:

- Trivial tasks (typos, style fixes, config changes)
- Spikes and research tasks (use spike-report instead)
- Pure documentation updates

## Relationship to Other Artifacts

### Spec Position in Workflow

```text
PRD (Feature requirements understood)
  ↓ (decomposed into)
Story (User-facing capability defined)
  ↓ (detailed in)
Spec (Technical approach documented) ← You are here
  ↓ (broken into)
Implementation Plan (Tasks defined)
  ↓ (guides)
Development (Code written)
```

### What Flows Into Spec

**From PRD**:

- **Vision** → Story context
- **Actors** → User story personas
- **Acceptance criteria** → Story acceptance criteria

**From Story**:

- **User story** → As a... I want... So that...
- **Acceptance criteria** → Gherkin-format scenarios
- **Parent feature** → Feature context

### What Flows from Spec

**To Implementation Plan**:

- **Technical approach** → Task breakdown
- **API changes** → Endpoint implementation tasks
- **Data changes** → Migration tasks

**To Test Plan**:

- **Acceptance criteria** → Test scenarios
- **Edge cases** → Edge case tests

**To Development**:

- **Technical approach** → Implementation guidance
- **API contracts** → Endpoint signatures
- **Data models** → Schema definitions

## Core Structure

### 1. Header and Metadata

```markdown
# Spec: [Story Name]

**Work Item**: [TW-12345 or WI-xxx]
**Parent Feature**: [Feature Name]
**Created**: [Date]
**Status**: Draft | Review | Approved
```

### 2. User Story

```markdown
## User Story

As a [actor/persona],
I want [capability/action],
So that [benefit/value].
```

**Example**:

```markdown
## User Story

As a pet owner,
I want to link multiple contacts to my pet's profile,
So that the clinic can reach any of my family members in an emergency.
```

### 3. Acceptance Criteria

```markdown
## Acceptance Criteria

### Scenario: [Scenario Name]

**Given** [precondition]
**When** [action]
**Then** [expected outcome]
```

**Example**:

```markdown
## Acceptance Criteria

### Scenario: Add new contact to pet

**Given** I am viewing my pet's profile
**And** the pet has fewer than 5 linked contacts
**When** I click "Add Contact" and enter contact details
**Then** the contact appears in the linked contacts list
**And** the contact can be selected for notifications

### Scenario: Contact limit reached

**Given** my pet already has 5 linked contacts
**When** I try to add another contact
**Then** I see a message explaining the contact limit
**And** no new contact is added

### Scenario: Edit linked contact

**Given** my pet has a linked contact
**When** I edit that contact's phone number
**Then** the change is saved
**And** the updated number is used for future notifications
```

### 4. Technical Approach

```markdown
## Technical Approach

[Describe the implementation strategy at a high level]

### Key Design Decisions

- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

### Components Affected

- [Component 1]: [How it changes]
- [Component 2]: [How it changes]
```

**Example**:

```markdown
## Technical Approach

Implement a many-to-many relationship between pets and contacts using a junction table. Contacts are shared across pets owned by the same owner, reducing duplicate data entry.

### Key Design Decisions

- **Shared contacts**: Contacts belong to the owner, not the pet, allowing reuse across multiple pets
- **Soft limit enforcement**: Contact limit enforced in application layer, not database constraint, for flexibility
- **Lazy loading**: Contact list loaded on demand to avoid impacting pet profile load time

### Components Affected

- **PetProfile component**: Add contacts section with add/edit/remove actions
- **ContactService**: New service for contact CRUD operations
- **NotificationService**: Update to resolve contacts from pet linkages
```

### 5. API Changes

```markdown
## API Changes

### [Method] [Endpoint]

**Purpose**: [What this endpoint does]

**Request**:

```json
{
  "field": "type - description"
}
```

**Response**:

```json
{
  "field": "type - description"
}
```

**Errors**:

- `400`: [When this occurs]
- `404`: [When this occurs]
```

**Example**:

```markdown
## API Changes

### POST /api/pets/{petId}/contacts

**Purpose**: Link a contact to a pet

**Request**:

```json
{
  "contactId": "string - existing contact ID, or null to create new",
  "contact": {
    "name": "string - contact name (required if contactId is null)",
    "phone": "string - phone number",
    "email": "string - email address",
    "relationship": "string - relationship to pet owner"
  }
}
```

**Response**:

```json
{
  "id": "string - link ID",
  "petId": "string - pet ID",
  "contact": {
    "id": "string - contact ID",
    "name": "string",
    "phone": "string",
    "email": "string",
    "relationship": "string"
  },
  "createdAt": "datetime"
}
```

**Errors**:

- `400`: Contact limit reached (max 5 per pet)
- `404`: Pet not found
- `409`: Contact already linked to this pet

### DELETE /api/pets/{petId}/contacts/{linkId}

**Purpose**: Remove a contact link from a pet

**Response**: `204 No Content`

**Errors**:

- `404`: Pet or link not found
```

### 6. Data Changes

```markdown
## Data Changes

### New Tables

#### [Table Name]

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| [column] | [type] | [constraints] | [description] |

### Modified Tables

#### [Table Name]

| Change | Column | Type | Description |
|--------|--------|------|-------------|
| ADD | [column] | [type] | [description] |
| MODIFY | [column] | [type] | [description] |

### Migrations

1. [Migration description]
2. [Migration description]
```

**Example**:

```markdown
## Data Changes

### New Tables

#### pet_contacts (junction table)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK | Link identifier |
| pet_id | UUID | FK → pets.id, NOT NULL | Pet reference |
| contact_id | UUID | FK → contacts.id, NOT NULL | Contact reference |
| created_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | Link creation time |
| | | UNIQUE(pet_id, contact_id) | Prevent duplicate links |

#### contacts

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK | Contact identifier |
| owner_id | UUID | FK → owners.id, NOT NULL | Owning user |
| name | VARCHAR(100) | NOT NULL | Contact name |
| phone | VARCHAR(20) | | Phone number |
| email | VARCHAR(255) | | Email address |
| relationship | VARCHAR(50) | | Relationship to owner |
| created_at | TIMESTAMP | NOT NULL | Creation timestamp |
| updated_at | TIMESTAMP | NOT NULL | Last update timestamp |

### Migrations

1. Create contacts table with owner relationship
2. Create pet_contacts junction table with foreign keys
3. Add index on pet_contacts(pet_id) for efficient lookup
```

### 7. UI Changes

```markdown
## UI Changes

### [Screen/Component Name]

**Current**: [Current behavior]
**New**: [New behavior]

**Wireframe**: [Link or description]

### User Flow

1. [Step 1]
2. [Step 2]
3. [Step 3]
```

**Example**:

```markdown
## UI Changes

### Pet Profile - Contacts Section

**Current**: No contacts section exists
**New**: New "Emergency Contacts" card below pet details

**Layout**:

- Card header: "Emergency Contacts" with "Add" button
- Contact list: Name, phone, relationship, edit/remove icons
- Empty state: "No contacts added. Add emergency contacts for this pet."
- Max indicator: "4 of 5 contacts" shown when approaching limit

### Add Contact Modal

**Fields**:

- Name (required)
- Phone
- Email
- Relationship (dropdown: Owner, Spouse, Family, Friend, Other)

**Actions**:

- Save: Validates and creates link
- Cancel: Closes modal without changes

### User Flow

1. User views pet profile
2. Scrolls to Emergency Contacts section
3. Clicks "Add Contact"
4. Modal opens with form
5. User enters contact details
6. User clicks Save
7. Modal closes, contact appears in list
```

### 8. Testing Notes

```markdown
## Testing Notes

### Key Test Scenarios

- [Scenario 1]
- [Scenario 2]

### Edge Cases

- [Edge case 1]
- [Edge case 2]

### Performance Considerations

- [Consideration 1]
```

**Example**:

```markdown
## Testing Notes

### Key Test Scenarios

- Add first contact to pet with no existing contacts
- Add contact when pet already has contacts
- Attempt to add 6th contact (should fail gracefully)
- Edit existing contact details
- Remove contact from pet
- Contact shared across multiple pets

### Edge Cases

- Owner with no contacts creates first one via pet profile
- Delete contact that is linked to multiple pets
- Concurrent edits to same contact from different pet profiles
- Contact with only email (no phone)
- Very long contact names (boundary testing)

### Performance Considerations

- Contact list should load within 200ms for 5 contacts
- Adding contact should not require full page refresh
- Contact search (if implemented) should be debounced
```

## Template

When creating a new spec, use this template:

```markdown
# Spec: [Story Name]

**Work Item**: [ID]
**Parent Feature**: [Feature Name]
**Created**: [Date]
**Status**: Draft

## User Story

As a [actor],
I want [capability],
So that [benefit].

## Acceptance Criteria

### Scenario: [Name]

**Given** [precondition]
**When** [action]
**Then** [outcome]

## Technical Approach

[High-level implementation strategy]

### Key Design Decisions

- [Decision]: [Rationale]

### Components Affected

- [Component]: [Changes]

## API Changes

### [Method] [Endpoint]

**Purpose**: [Description]

**Request**:

```json
{}
```

**Response**:

```json
{}
```

## Data Changes

### New Tables

#### [Table Name]

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|

### Migrations

1. [Migration step]

## UI Changes

### [Component]

**Current**: [Behavior]
**New**: [Behavior]

## Testing Notes

### Key Test Scenarios

- [Scenario]

### Edge Cases

- [Edge case]
```

## Writing Effective Specs

### User Story Tips

- Use specific actor names, not generic "user"
- Focus on the capability, not the implementation
- Clearly state the value/benefit
- Keep it concise - one sentence for each part

### Acceptance Criteria Tips

- Write in Gherkin format (Given/When/Then)
- Cover happy path and error scenarios
- Include boundary conditions
- Make criteria testable and verifiable
- Avoid implementation details in criteria

### Technical Approach Tips

- Explain the "why" behind design decisions
- Identify components that need changes
- Note any architectural patterns being followed
- Call out dependencies on other work

### API Changes Tips

- Use consistent naming conventions
- Document all request/response fields
- Include all possible error codes
- Specify required vs optional fields
- Note any breaking changes

### Data Changes Tips

- Include all constraints (PK, FK, UNIQUE, NOT NULL)
- Document migration order and dependencies
- Consider backwards compatibility
- Note any data transformations needed

## Common Pitfalls

### Avoid These Mistakes

1. **Vague acceptance criteria**: "System should be fast"
   - **Fix**: "Page loads within 2 seconds for 95th percentile"

2. **Missing error scenarios**: Only documenting happy path
   - **Fix**: Include validation errors, edge cases, system failures

3. **Implementation in user story**: "As a user, I want to click the blue button..."
   - **Fix**: Focus on capability: "I want to save my changes"

4. **Undocumented API contracts**: Just listing endpoints without details
   - **Fix**: Include full request/response schemas

5. **No migration plan**: Adding tables without migration steps
   - **Fix**: Document migration order and rollback strategy

6. **Assuming context**: Referencing decisions not documented
   - **Fix**: Link to ADRs or explain decisions inline

## Maintenance

Update spec when:

- Acceptance criteria change during development
- Technical approach needs adjustment
- New edge cases discovered
- API contracts modified
- Data model evolves

## Markdown Linting Requirements

All specs must comply with the markdown standards defined in [markdown-standards.md](../reference/markdown-standards.md).

### Quick Validation

```bash
markdownlint spec.md
```

## Summary

A well-crafted spec:

- **Captures** the user story in standard format
- **Defines** testable acceptance criteria
- **Documents** the technical approach and rationale
- **Specifies** API contracts with full schemas
- **Details** data model changes and migrations
- **Guides** UI implementation with clear requirements
- **Notes** testing considerations and edge cases

Use this guide when documenting technical specifications for stories.
