# Work Item Initialization Templates

Templates used when initializing a new work item directory.

## Files

| Template | Output | Git | Purpose |
|----------|--------|-----|---------|
| `work-item.yaml.template` | `work-item.yaml` | Tracked | Metadata snapshot |
| `activity-log.md.template` | `activity-log.md` | Tracked | Cross-session history |
| `session-notes.md.template` | `session-notes.md` | Ignored | Personal notes |

## Variables

Templates use `{{variable}}` syntax for substitution:

| Variable | Description | Example |
|----------|-------------|---------|
| `{{id}}` | Directory name | `tw-26253606` |
| `{{name}}` | Work item title | `Subscription Renewal System` |
| `{{externalSystem}}` | Source system | `teamwork` |
| `{{externalId}}` | External ID | `26253606` |
| `{{externalUrl}}` | Link to source | `https://...` |
| `{{type}}` | Work item type | `epic` |
| `{{status}}` | Current status | `triaged` |
| `{{stage}}` | Current stage | `triage` |
| `{{queue}}` | Queue assignment | `standard` |
| `{{createdAt}}` | Creation timestamp | `2025-12-09T14:30:00Z` |
| `{{initializedAt}}` | Init timestamp | `2025-12-09T14:30:00Z` |
| `{{initializedDate}}` | Init date only | `2025-12-09` |
| `{{updatedAt}}` | Update timestamp | `2025-12-09T14:30:00Z` |
| `{{sessionId}}` | Current session | `ses-20251209-143000` |

## Usage

The triage agent uses these templates during directory initialization:

```python
# Pseudocode
context = {
    "id": "tw-26253606",
    "name": work_item.name,
    "externalSystem": "teamwork",
    # ... etc
}

for template in ["work-item.yaml", "activity-log.md"]:
    content = read_template(f"{template}.template")
    rendered = substitute_variables(content, context)
    write_file(f"work-items/{id}/{template}", rendered)
```

## Related

- Schema: [work-item-directory.schema.md](../../schema/work-item-directory.schema.md)
- ADR: [0006-work-item-directories.md](../../docs/adrs/0006-work-item-directories.md)
