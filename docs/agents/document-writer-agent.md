# Document Writer Agent Methodology

This document defines the methodology for the Document Writer Agent - a deterministic, template-driven system for producing lint-safe markdown documents.

## Core Principle

> Don't "generate markdown."
> **Generate structured content → apply markdown rules → emit formatted output.**

The agent doesn't *try* to format. It **fills a canonical schema and the formatter applies standards**.

```text
Structured Input → Template → Renderer → Lint-Safe Markdown
```

## Why Template-Driven?

Traditional LLM document generation suffers from:

- Inconsistent formatting (random blank lines, indentation)
- Duplicate headings across similar sections
- Missing language specifiers on code blocks
- Bold text used as headings
- Nested list indentation errors

**The solution**: Separate content from formatting.

| Traditional | Template-Driven |
|-------------|-----------------|
| LLM generates markdown directly | LLM fills structured fields |
| Formatting varies by prompt | Formatting is deterministic |
| Lint errors require manual fixes | Lint compliance is built-in |
| Hard to validate structure | Schema validation possible |
| Each output is unique | Outputs are predictable |

## Document Types

The work system uses these document types:

| Template | Purpose | When Used |
|----------|---------|-----------|
| `prd` | Product Requirements Document | Features, Epics |
| `spec` | Technical Specification | Stories |
| `adr` | Architecture Decision Record | Design decisions |
| `impl-plan` | Implementation Plan | Design stage |
| `test-plan` | Test Plan | Design stage |
| `spike-report` | Research/Investigation Report | Spikes |
| `bug-report` | Bug Documentation | Bug triage |
| `release-notes` | Release Documentation | Releases |
| `retro` | Retrospective/Learnings | Post-delivery |

## Input Contract

Every document request follows this structure:

```yaml
DocumentRequest:
  template: string           # Template ID (prd, spec, adr, etc.)
  context: object            # Template-specific data
  formatOptions:             # Optional formatting preferences
    includeTOC: boolean      # Include table of contents
    headingDepth: number     # Maximum heading depth
    includeMetadata: boolean # Include frontmatter
```

### Example: PRD Request

```json
{
  "template": "prd",
  "context": {
    "featureName": "Link Contacts",
    "vision": "Enable pet owners to link multiple contacts to a single pet for shared care responsibilities",
    "actors": ["Pet Owner", "Clinic Tech", "Secondary Contact"],
    "jobs": [
      "Pet Owner wants to share pet information with family members",
      "Clinic Tech needs to contact multiple people for a pet"
    ],
    "acceptanceCriteria": [
      "Given a pet owner, when they add a secondary contact, then that contact can view pet details",
      "Given a clinic tech, when they view a pet, then they see all linked contacts"
    ],
    "constraints": [
      "Must respect privacy settings",
      "Cannot exceed 5 linked contacts per pet"
    ],
    "outOfScope": [
      "Contact permissions management",
      "Contact-to-contact communication"
    ]
  },
  "formatOptions": {
    "includeTOC": true
  }
}
```

### Example: Spec Request

```json
{
  "template": "spec",
  "context": {
    "storyName": "Add Secondary Contact Form",
    "workItemId": "TW-26134586",
    "parentFeature": "Link Contacts",
    "userStory": "As a pet owner, I want to add a secondary contact to my pet's profile so that they can be notified about appointments",
    "acceptanceCriteria": [
      "Form validates email format",
      "Form validates phone format",
      "User receives confirmation after adding contact"
    ],
    "technicalApproach": "Add React form component with Zod validation",
    "apiChanges": [
      "POST /api/pets/{petId}/contacts"
    ],
    "dataChanges": [
      "Add PetContact table with foreign keys to Pet and Contact"
    ],
    "testingNotes": "Focus on validation edge cases"
  }
}
```

## Template Structure

Templates define the document structure as a sequence of blocks:

```yaml
name: prd
version: 1
description: Product Requirements Document for features
requiredContext:
  - featureName
  - vision
  - actors
  - acceptanceCriteria
optionalContext:
  - jobs
  - constraints
  - outOfScope
  - risks
  - dependencies

render:
  - type: heading
    level: 1
    content: "PRD: {{featureName}}"

  - type: metadata
    fields:
      - "Created: {{currentDate}}"
      - "Status: Draft"

  - type: heading
    level: 2
    content: "Vision"

  - type: paragraph
    content: "{{vision}}"

  - type: heading
    level: 2
    content: "Actors"

  - type: list
    items: "{{actors}}"

  - type: conditional
    if: "{{jobs}}"
    blocks:
      - type: heading
        level: 2
        content: "Jobs to be Done"
      - type: list
        items: "{{jobs}}"

  - type: heading
    level: 2
    content: "Acceptance Criteria"

  - type: list
    items: "{{acceptanceCriteria}}"

  - type: conditional
    if: "{{constraints}}"
    blocks:
      - type: heading
        level: 2
        content: "Constraints"
      - type: list
        items: "{{constraints}}"

  - type: conditional
    if: "{{outOfScope}}"
    blocks:
      - type: heading
        level: 2
        content: "Out of Scope"
      - type: list
        items: "{{outOfScope}}"
```

### Block Types

| Type | Description | Properties |
|------|-------------|------------|
| `heading` | Section heading | `level`, `content` |
| `paragraph` | Text block | `content` |
| `list` | Bullet list | `items` (array or template ref) |
| `orderedList` | Numbered list | `items` |
| `table` | Data table | `headers`, `rows` |
| `code` | Code block | `content`, `language` |
| `conditional` | Conditional section | `if`, `blocks` |
| `metadata` | Frontmatter/info | `fields` |

## Rendering Rules

The renderer enforces markdown standards automatically:

### Spacing Rules

| Rule | Enforcement |
|------|-------------|
| MD022 | Blank line before and after every heading |
| MD032 | Blank line before and after every list and code block |
| MD031 | Proper fence expansion for nested code |

### List Rules

| Rule | Enforcement |
|------|-------------|
| MD007 | 2-space indentation for nested lists |
| MD030 | Exactly 1 space after list markers |

### Code Block Rules

| Rule | Enforcement |
|------|-------------|
| MD040 | Language always specified (default: `text`) |
| MD031 | Outer fence uses more backticks than inner |

### Heading Rules

| Rule | Enforcement |
|------|-------------|
| MD024 | Duplicates auto-prefixed with context |
| MD036 | Bold text converted to proper headings |

### Content Rules

| Rule | Enforcement |
|------|-------------|
| MD038 | No spaces inside inline code backticks |

## Output Contract

Every document output follows this structure:

```yaml
DocumentResult:
  status: enum              # ok | error
  document: string          # Rendered markdown (if status=ok)
  lintReport: array         # Should be empty
  structureReport:
    missingRequiredFields: array
    duplicatedHeadings: array
    warnings: array
  metadata:
    template: string
    generatedAt: datetime
    wordCount: number
    headingCount: number
```

### Example Output

```json
{
  "status": "ok",
  "document": "# PRD: Link Contacts\n\n**Created:** 2024-12-08\n**Status:** Draft\n\n## Vision\n\nEnable pet owners to link multiple contacts...\n\n## Actors\n\n- Pet Owner\n- Clinic Tech\n- Secondary Contact\n\n...",
  "lintReport": [],
  "structureReport": {
    "missingRequiredFields": [],
    "duplicatedHeadings": [],
    "warnings": []
  },
  "metadata": {
    "template": "prd",
    "generatedAt": "2024-12-08T15:30:00Z",
    "wordCount": 245,
    "headingCount": 6
  }
}
```

## Validation

### Pre-Render Validation

Before rendering, validate:

1. **Template exists**: Template ID maps to a valid template
2. **Required context**: All required fields present
3. **Type validation**: Fields match expected types (arrays are arrays, etc.)

### Post-Render Validation

After rendering, validate:

1. **Lint compliance**: Run markdown rules against output
2. **Structure integrity**: Heading hierarchy is correct
3. **No duplicates**: Headings are unique (or prefixed)

## Integration with Work System

### With Plan Stage

When planning a feature, generate PRD:

```text
/plan TW-12345 → generates PRD context → /doc-write prd
```

### With Design Stage

When designing, generate multiple documents:

```text
/design TW-12345 → generates:
  - ADR (if architectural decision)
  - Implementation Plan
  - Test Plan
```

### With Deliver Stage

When completing work, generate:

```text
/deliver TW-12345 complete → generates:
  - Release Notes (if applicable)
  - Retrospective (if configured)
```

### With Triage Stage

When triaging bugs, generate:

```text
/triage TW-12345 (bug) → generates Bug Report
```

## Document Storage

Generated documents are stored:

```text
docs/
├── prd/
│   └── TW-{id}-{slug}.md
├── specs/
│   └── TW-{id}-{slug}.md
├── architecture/
│   └── adr/
│       └── ADR-{number}-{title}.md
├── plans/
│   ├── TW-{id}-implementation.md
│   └── TW-{id}-test-plan.md
├── spikes/
│   └── TW-{id}-{slug}.md
└── releases/
    └── v{version}-notes.md
```

## Error Handling

### Missing Required Field

```json
{
  "status": "error",
  "error": {
    "code": "MISSING_REQUIRED_FIELD",
    "message": "Required field 'acceptanceCriteria' is missing",
    "field": "acceptanceCriteria",
    "template": "prd"
  }
}
```

### Invalid Template

```json
{
  "status": "error",
  "error": {
    "code": "INVALID_TEMPLATE",
    "message": "Template 'xyz' not found",
    "availableTemplates": ["prd", "spec", "adr", "impl-plan", "test-plan"]
  }
}
```

### Lint Failure (Should Not Happen)

```json
{
  "status": "error",
  "error": {
    "code": "LINT_FAILURE",
    "message": "Generated document failed lint validation",
    "lintErrors": [
      {"rule": "MD032", "line": 15, "message": "..."}
    ]
  }
}
```

## Extending the System

### Adding a New Template

1. Create template file: `docs/templates/documents/{name}.yaml`
2. Define required/optional context fields
3. Define render blocks
4. Add to template registry
5. Test with sample inputs

### Customizing Existing Templates

Templates can be overridden per-project:

```text
.claude/
└── templates/
    └── documents/
        └── prd.yaml  # Project-specific PRD template
```

Project templates take precedence over system templates.

## References

- [Document Writer Prompts](document-writer-prompts.md) - Agent system prompts
- [Markdown Standards](markdown-standards.md) - Linting rules
- [Document Schema](../schema/document.schema.md) - Schema definitions
- [Document Templates](templates/documents/) - Template library
