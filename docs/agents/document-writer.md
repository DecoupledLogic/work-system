# Document Writer Agent

Transform structured context into lint-safe markdown documents using templates.

## Overview

| Property | Value |
|----------|-------|
| **Name** | document-writer |
| **Model** | sonnet |
| **Tools** | Read, Write |
| **Stage** | Cross-cutting |

## Purpose

The Document Writer agent generates consistent, well-formatted documents from structured context. It does NOT generate freeform markdown - it fills templates and applies strict formatting rules to ensure lint compliance.

## Core Principle

```
Structured Context → Template → Formatting Rules → Lint-Safe Markdown
```

## Input

Expects a document request with template and context:

```json
{
  "template": "prd",
  "context": {
    "featureName": "Link Contacts",
    "vision": "Enable pet owners to link multiple contacts...",
    "actors": ["Pet Owner", "Clinic Tech"],
    "acceptanceCriteria": [
      "Given a pet owner, when they add a contact, then..."
    ]
  },
  "formatOptions": {
    "includeTOC": false,
    "includeMetadata": true
  }
}
```

## Output

Returns structured result with document and validation:

```json
{
  "status": "ok",
  "document": "# PRD: Link Contacts\n\n...",
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

## Supported Templates

| Template | Required Fields | Purpose |
|----------|-----------------|---------|
| **PRD** | featureName, vision, actors, acceptanceCriteria | Product Requirements Document |
| **Spec** | storyName, workItemId, userStory, acceptanceCriteria | Technical Specification |
| **ADR** | title, context, decision, consequences | Architecture Decision Record |
| **Implementation Plan** | workItemName, workItemId, tasks | Implementation breakdown |
| **Test Plan** | workItemName, workItemId, testStrategy | Testing strategy |
| **Spike Report** | title, workItemId, question, findings | Research/investigation results |
| **Bug Report** | title, workItemId, symptoms, stepsToReproduce | Bug documentation |
| **Release Notes** | version, releaseDate, features | Release documentation |
| **Retrospective** | workItemId, whatWentWell, whatCouldImprove | Sprint/iteration review |

## Formatting Rules

### Spacing Rules

| Element | Rule |
|---------|------|
| Headings | Blank line BEFORE and AFTER every heading |
| Lists | Blank line BEFORE and AFTER every list |
| Code blocks | Blank line BEFORE and AFTER every code block |
| Paragraphs | Blank line between paragraphs |

### List Rules

| Rule | Correct | Incorrect |
|------|---------|-----------|
| Marker spacing | `- Item` | `-  Item` |
| Nested indent | 2 spaces | 4 spaces |
| Marker style | `-` | `*` or `+` |

### Code Block Rules

| Rule | Requirement |
|------|-------------|
| Language | ALWAYS specify (use `text` if none) |
| Nested blocks | Outer fence has more backticks |

### Heading Rules

| Rule | Requirement |
|------|-------------|
| Uniqueness | Prefix duplicates with context |
| Syntax | Use `#` not `**bold**` |
| Hierarchy | Sequential levels (don't skip) |

## Processing Steps

1. **Validate Input** - Check template exists, verify required fields
2. **Load Template** - Read template definition
3. **Bind Context** - Replace placeholders, evaluate conditionals
4. **Apply Formatting** - Insert blank lines, format lists
5. **Validate Output** - Check lint compliance, heading uniqueness
6. **Return Result** - Include document, reports, and metadata

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
    "availableTemplates": ["prd", "spec", "adr", ...]
  }
}
```

## Content Rules

1. **Bind from context only** - Never fabricate content
2. **Omit empty sections** - Skip sections without data
3. **Preserve meaning** - Rephrase for clarity, not semantics
4. **Be concise** - No filler words or unnecessary content

## Focus Areas

- **Lint Compliance** - Every document must pass markdownlint
- **Consistency** - Same template produces same structure
- **Completeness** - All required fields must be present
- **Clarity** - Documents should be readable and well-organized

## Integration Points

| Agent | Direction | Data |
|-------|-----------|------|
| plan-agent | Called by | Plan documents |
| design-agent | Called by | ADRs, implementation plans |
| eval-agent | Called by | Implementation summaries |

## Related

- [plan-agent](plan-agent.md) - Uses for plan documents
- [design-agent](design-agent.md) - Uses for ADRs
- [index](index.md) - Agent overview
