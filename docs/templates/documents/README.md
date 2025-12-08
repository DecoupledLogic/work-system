# Document Templates

YAML-based templates for generating lint-safe markdown documents via the Document Writer Agent.

## Available Templates

| Template | Purpose | Required Fields |
|----------|---------|-----------------|
| [prd.yaml](prd.yaml) | Product Requirements Document | featureName, vision, actors, acceptanceCriteria |
| [spec.yaml](spec.yaml) | Technical Specification | storyName, workItemId, userStory, acceptanceCriteria |
| [adr.yaml](adr.yaml) | Architecture Decision Record | title, context, decision, consequences |
| [impl-plan.yaml](impl-plan.yaml) | Implementation Plan | workItemName, workItemId, tasks |
| [test-plan.yaml](test-plan.yaml) | Test Plan | workItemName, workItemId, testStrategy |
| [spike-report.yaml](spike-report.yaml) | Research/Investigation Report | title, workItemId, question, findings |
| [bug-report.yaml](bug-report.yaml) | Bug Documentation | title, workItemId, symptoms, stepsToReproduce |
| [release-notes.yaml](release-notes.yaml) | Release Notes | version, releaseDate, features |
| [retro.yaml](retro.yaml) | Retrospective/Learnings | workItemId, whatWentWell, whatCouldImprove |
| [delivery-plan.yaml](delivery-plan.yaml) | Delivery Plan (epic-level) | initiativeName, strategy, problem, epics |
| [architecture-blueprint.yaml](architecture-blueprint.yaml) | Architecture Blueprint | systemName, overview, goals, components, corePrinciples |

## Template Structure

Each template follows a standard YAML structure:

```yaml
name: template-name
version: 1
description: Template description

requiredContext:
  - field1
  - field2

optionalContext:
  - field3
  - field4

render:
  - type: heading
    level: 1
    content: "{{field1}}"
  - type: paragraph
    content: "{{field2}}"
```

## Render Block Types

| Type | Description | Properties |
|------|-------------|------------|
| `heading` | Section heading | level (1-6), content |
| `paragraph` | Text block | content |
| `list` | Unordered list | items (array or template) |
| `orderedList` | Numbered list | items (array or template) |
| `table` | Data table | headers, rows |
| `code` | Code block | language, content |
| `metadata` | Key-value pairs | fields |
| `conditional` | Conditional rendering | if, blocks |
| `forEach` | Loop over items | items, blocks |

## Usage

Templates are used via the `/doc-write` slash command:

```bash
# Generate PRD from work item
/doc-write prd --work-item TW-12345

# Interactive mode
/doc-write spec --interactive

# Custom output
/doc-write adr --title "Use JWT" --output docs/adrs/0005-jwt.md
```

## Adding New Templates

1. Create a new YAML file in this directory
2. Define `name`, `version`, `description`
3. List `requiredContext` and `optionalContext` fields
4. Define `render` blocks for document structure
5. Update `commands/doc-write.md` to include the new template

## Template Guidelines

- **Required fields**: Only include fields essential for a valid document
- **Optional fields**: Use conditionals to skip empty sections
- **Nesting**: Use `forEach` for repeating structures (features, stories, etc.)
- **Spacing**: The renderer adds blank lines per markdown linting rules
- **Code examples**: Always specify language for code blocks

## Related Documentation

- [Document Writer Agent](../../agents/document-writer-agent.md) - Agent methodology
- [Markdown Standards](../../reference/markdown-standards.md) - Linting rules
- [doc-write Command](../../../commands/doc-write.md) - Slash command usage
