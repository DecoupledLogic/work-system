# Work System Scripts

Utility scripts for setting up and managing work-system repositories.

## Available Scripts

### setup-github-labels.sh

Creates GitHub labels aligned with the WorkItem schema defined in `docs/core/work-system.md`.

#### Usage

```bash
# For current repository
./setup-github-labels.sh

# For a specific repository
./setup-github-labels.sh owner/repo
```

#### Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- Repository access (owner or collaborator)

#### Labels Created

| Category | Labels | Colors |
|----------|--------|--------|
| **Type** | epic, feature, story, task, client_request | Blue shades |
| **WorkType** | product_delivery, support, maintenance, bug_fix, research | Green shades |
| **Urgency** | critical, now, next, future | Red/Orange/Yellow |
| **Impact** | high, medium, low | Purple shades |
| **Stage** | triage, plan, design, deliver | Neutral/Light |
| **Capability** | development, design, qa, devops, accessibility, marketing, ux | Various |

#### Label Schema Alignment

Labels map directly to WorkItem fields:

```yaml
WorkItem:
  Type: epic | feature | story | task | client_request
  WorkType: product_delivery | support | maintenance | bug_fix | research
  Urgency: critical | now | next | future
  Impact: high | medium | low
  Status: triage | planned | designed | ready_for_dev | in_progress | ...
  Capability: development | design | qa | devops | accessibility | marketing | ux
```

## Adding New Scripts

When adding scripts:

1. Include a usage comment at the top
2. Use `set -e` for error handling
3. Document prerequisites
4. Add entry to this README
