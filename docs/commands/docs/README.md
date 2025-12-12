# Documentation Commands

Generate structured markdown documents from templates.

## Commands

| Command | Description |
|---------|-------------|
| `/docs:doc-write` | Generate lint-safe markdown from templates |

## /docs:doc-write

Generate documents using predefined templates.

```bash
/docs:doc-write <template> <output-file> [context]
/docs:doc-write adr docs/adrs/0001-example.md --title "Use Event Sourcing"
/docs:doc-write playbook .claude/agent-playbook.yaml --from-analysis
```

## Available Templates

| Template | Description | Output |
|----------|-------------|--------|
| `adr` | Architecture Decision Record | `docs/adrs/NNNN-*.md` |
| `playbook` | Agent playbook YAML | `.claude/agent-playbook.yaml` |
| `architecture` | Architecture documentation | `.claude/architecture.yaml` |
| `guide` | User/developer guides | `docs/guides/*.md` |
| `plan` | Implementation plans | `docs/plans/*.md` |
| `spec` | Technical specifications | `docs/specs/*.md` |

## Features

- Template-based generation
- Markdown lint compliance
- Schema validation
- Consistent formatting
- Context injection

See source commands in [commands/docs/](../../../commands/docs/) for full documentation.
