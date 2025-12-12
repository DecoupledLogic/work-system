# Documentation Commands

This directory contains commands for generating structured markdown documentation from templates.

## Purpose

Documentation commands transform structured context and data into lint-safe, well-formatted markdown documents using predefined templates. This ensures consistent documentation across the project.

## Commands

### `/docs:write`
Generate lint-safe markdown documents from templates. Deterministic document generation with built-in formatting rules.

**Usage:**
```bash
/docs:write <template> <output-file> [context]
/docs:write adr docs/adrs/0001-example.md --title "Use Event Sourcing"
/docs:write playbook .claude/agent-playbook.yaml --from-analysis
```

**Features:**
- Template-based generation
- Markdown linting compliance (markdownlint)
- Consistent formatting
- Schema validation
- Context injection

**Common Templates:**
- `adr` - Architecture Decision Record
- `playbook` - Agent playbook YAML
- `architecture` - Architecture documentation
- `guide` - User/developer guides
- `plan` - Implementation plans
- `spec` - Technical specifications

## Document Templates

Templates are stored in `docs/templates/` and follow a standard structure:

```markdown
---
schema: <schema-file>
required_context:
  - field1
  - field2
---

# Document Template

{{ context.field1 }}

{{ context.field2 }}
```

### Available Templates

1. **ADR (Architecture Decision Record)**
   - Schema: `docs/schemas/adr.schema.yaml`
   - Required context: title, status, context, decision, consequences
   - Output: `docs/adrs/NNNN-title.md`

2. **Agent Playbook**
   - Schema: `docs/schemas/agent-playbook.schema.yaml`
   - Required context: guardrails, patterns, hygiene
   - Output: `.claude/agent-playbook.yaml`

3. **Architecture Documentation**
   - Schema: `docs/schemas/architecture.schema.yaml`
   - Required context: tech_stack, layers, patterns
   - Output: `.claude/architecture.yaml`

## Document Linting

All generated documents are validated against:
- **markdownlint** - Markdown style and formatting rules
- **JSON Schema** - For YAML documents
- **Custom rules** - Project-specific validation

Common lint rules enforced:
- Consistent heading hierarchy
- Proper list formatting
- Code block language tags
- Line length limits
- Blank lines around blocks

## Best Practices

1. **Use templates** - Don't write documentation from scratch
2. **Validate context** - Ensure required fields are provided
3. **Review output** - Check generated docs before committing
4. **Update templates** - Keep templates current with standards
5. **Schema validation** - Always validate against schemas

## Integration

Documentation commands integrate with:
- **Architecture Review** (`/quality:architecture-review`) - Generates architecture.yaml
- **Playbook** (`/playbook:*`) - Generates and validates playbook
- **Work Init** (`/work:init`) - Creates initial documentation
