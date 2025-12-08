# Project Schema

A project is a container for related work items, representing a codebase, initiative, or bounded context.

## Schema Definition

```yaml
Project:
  # Identity
  id: string                    # Internal work system ID (e.g., "PRJ-001")
  externalId: string | null     # ID in external system
  externalSystem: string | null # Source system (teamwork | github | linear | jira | internal)
  externalUrl: string | null    # Direct link to external system

  # Content
  name: string                  # Project name
  description: string | null    # Project description (markdown)
  status: enum                  # active | archived | on_hold

  # Organization
  ownerId: string | null        # Owner agent ID
  teamIds: string[]             # Team IDs with access
  defaultQueueId: string | null # Default queue for new items

  # Configuration
  defaultTemplateId: string | null  # Default process template
  workItemPrefix: string | null     # Prefix for work items (e.g., "AUTH" → AUTH-001)

  # Repository (if applicable)
  repository: object | null
    url: string                 # Git repository URL
    defaultBranch: string       # main, master, etc.
    branchPrefix: string | null # Prefix for feature branches

  # Tracking
  createdAt: datetime
  updatedAt: datetime
  startDate: date | null
  targetDate: date | null

  # Metadata
  metadata: object              # Flexible key-value for system-specific data
```

## Status Values

| Status | Description |
|--------|-------------|
| `active` | Project is actively being worked on |
| `on_hold` | Temporarily paused |
| `archived` | Completed or deprecated |

## Examples

### Project Linked to Teamwork

```yaml
id: "PRJ-001"
externalId: "789456"
externalSystem: "teamwork"
externalUrl: "https://company.teamwork.com/app/projects/789456"
name: "Customer Portal"
description: "Self-service customer portal for account management"
status: "active"
ownerId: "AGT-001"
teamIds: ["TEAM-001", "TEAM-002"]
defaultQueueId: "standard"
defaultTemplateId: "TPL-standard"
workItemPrefix: "CP"
repository:
  url: "git@github.com:company/customer-portal.git"
  defaultBranch: "main"
  branchPrefix: "feature/"
createdAt: "2024-01-15T10:00:00Z"
updatedAt: "2024-12-08T14:30:00Z"
targetDate: "2025-03-01"
metadata:
  teamwork:
    companyId: "123"
    companyName: "ACME Corp"
    categoryId: "456"
```

### Internal Project (No External System)

```yaml
id: "PRJ-002"
externalId: null
externalSystem: "internal"
externalUrl: null
name: "Infrastructure Automation"
description: "Internal tooling for deployment automation"
status: "active"
ownerId: "AGT-002"
teamIds: ["TEAM-003"]
defaultQueueId: "standard"
defaultTemplateId: "TPL-standard"
workItemPrefix: "INFRA"
repository:
  url: "git@github.com:company/infra-automation.git"
  defaultBranch: "main"
  branchPrefix: "feature/"
createdAt: "2024-06-01T10:00:00Z"
updatedAt: "2024-12-08T14:30:00Z"
```

### GitHub-Linked Project

```yaml
id: "PRJ-003"
externalId: "company/oss-library"
externalSystem: "github"
externalUrl: "https://github.com/company/oss-library"
name: "OSS Library"
description: "Open source utility library"
status: "active"
ownerId: "AGT-001"
teamIds: []
defaultQueueId: "standard"
defaultTemplateId: "TPL-oss"
workItemPrefix: "OSS"
repository:
  url: "git@github.com:company/oss-library.git"
  defaultBranch: "main"
  branchPrefix: "feature/"
metadata:
  github:
    visibility: "public"
    topics: ["typescript", "utilities"]
```

## Relationships

```
Project
├── WorkItem[] (via projectId)
├── Agent (owner via ownerId)
├── Team[] (via teamIds)
├── ProcessTemplate (default via defaultTemplateId)
└── Queue (default via defaultQueueId)
```

## Validation Rules

1. **Required fields**: `id`, `name`, `status`
2. **Unique constraint**: `workItemPrefix` must be unique across projects
3. **Repository**: If `repository` is set, `url` and `defaultBranch` are required

## Related Schemas

- [work-item.schema.md](work-item.schema.md) - Work items in the project
- [agent.schema.md](agent.schema.md) - Project owner
- [process-template.schema.md](process-template.schema.md) - Default template
