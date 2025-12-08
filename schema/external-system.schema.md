# External System Schema

An external system represents an integration with a third-party service (Teamwork, GitHub, Linear, JIRA, etc.) that can be a source or target for work system data.

## Schema Definition

```yaml
ExternalSystem:
  # Identity
  id: string                    # System ID (e.g., "teamwork", "github")
  name: string                  # Display name
  type: enum                    # project_management | issue_tracker | source_control | combined

  # Connection
  baseUrl: string               # API base URL
  authType: enum                # api_key | oauth2 | basic | token
  status: enum                  # connected | disconnected | error

  # Capabilities
  capabilities: string[]        # What operations are supported
  syncDirection: enum           # inbound | outbound | bidirectional

  # Mapping
  fieldMappings: FieldMapping[] # How fields map to work system schema
  typeMappings: TypeMapping[]   # How types map

  # Sync Configuration
  syncConfig: object
    enabled: boolean
    interval: string            # ISO 8601 duration (e.g., "PT5M")
    lastSyncAt: datetime | null
    filters: object             # What to sync

  # Tracking
  createdAt: datetime
  updatedAt: datetime

  # Metadata
  metadata: object              # System-specific configuration
```

## System Types

| Type | Description | Examples |
|------|-------------|----------|
| `project_management` | Project/task management | Teamwork, Asana, Monday |
| `issue_tracker` | Issue/bug tracking | GitHub Issues, JIRA, Linear |
| `source_control` | Code repositories | GitHub, GitLab, Bitbucket |
| `combined` | Multiple capabilities | GitHub (issues + source), GitLab |

## Capabilities

```yaml
capabilities:
  # Work Items
  - read_workitems       # Read work items from system
  - write_workitems      # Create/update work items
  - delete_workitems     # Delete work items

  # Comments
  - read_comments        # Read comments
  - write_comments       # Create comments

  # Time Tracking
  - read_timelogs        # Read time entries
  - write_timelogs       # Log time

  # Projects
  - read_projects        # Read projects
  - write_projects       # Create/update projects

  # Users
  - read_users           # Read user data
  - sync_users           # Sync users to agents

  # Webhooks
  - webhooks             # Receive real-time updates
```

## Field Mappings

```yaml
FieldMapping:
  workSystemField: string       # Field in work system schema
  externalField: string         # Field in external system
  direction: enum               # inbound | outbound | bidirectional
  transform: string | null      # Transformation function name
  default: any | null           # Default value if missing
```

## Type Mappings

```yaml
TypeMapping:
  workSystemType: string        # Work item type (epic, feature, story, task, bug, spike)
  externalType: string          # Type in external system
  externalTypeId: string | null # ID if system uses IDs for types
```

## Examples

### Teamwork Integration

```yaml
id: "teamwork"
name: "Teamwork"
type: "project_management"
baseUrl: "https://company.teamwork.com"
authType: "api_key"
status: "connected"

capabilities:
  - read_workitems
  - write_workitems
  - read_comments
  - write_comments
  - read_timelogs
  - write_timelogs
  - read_projects
  - read_users
  - webhooks

syncDirection: "bidirectional"

fieldMappings:
  - workSystemField: "name"
    externalField: "content"
    direction: "bidirectional"

  - workSystemField: "description"
    externalField: "description"
    direction: "bidirectional"

  - workSystemField: "status"
    externalField: "status"
    direction: "bidirectional"
    transform: "teamwork_status_to_workitem_status"

  - workSystemField: "priority"
    externalField: "priority"
    direction: "bidirectional"
    transform: "teamwork_priority_to_workitem_priority"

  - workSystemField: "assigneeId"
    externalField: "responsible-party-ids"
    direction: "bidirectional"
    transform: "teamwork_user_to_agent"

  - workSystemField: "dueDate"
    externalField: "due-date"
    direction: "bidirectional"

  - workSystemField: "estimatedMinutes"
    externalField: "estimated-minutes"
    direction: "bidirectional"

  - workSystemField: "tags"
    externalField: "tags"
    direction: "bidirectional"
    transform: "teamwork_tags_to_array"

typeMappings:
  - workSystemType: "task"
    externalType: "task"
  - workSystemType: "story"
    externalType: "task"  # Teamwork doesn't distinguish
  - workSystemType: "bug"
    externalType: "task"
  - workSystemType: "epic"
    externalType: "milestone"

syncConfig:
  enabled: true
  interval: "PT5M"
  lastSyncAt: "2024-12-08T14:30:00Z"
  filters:
    projectIds: ["789456"]
    excludeCompleted: false
    modifiedSince: "2024-12-01T00:00:00Z"

metadata:
  apiVersion: "v3"
  siteId: "company"
  webhookSecret: "***"
```

### GitHub Integration

```yaml
id: "github"
name: "GitHub"
type: "combined"
baseUrl: "https://api.github.com"
authType: "token"
status: "connected"

capabilities:
  - read_workitems       # Issues
  - write_workitems
  - read_comments
  - write_comments
  - read_projects        # Repositories
  - webhooks

syncDirection: "bidirectional"

fieldMappings:
  - workSystemField: "name"
    externalField: "title"
    direction: "bidirectional"

  - workSystemField: "description"
    externalField: "body"
    direction: "bidirectional"

  - workSystemField: "status"
    externalField: "state"
    direction: "bidirectional"
    transform: "github_state_to_workitem_status"

  - workSystemField: "assigneeId"
    externalField: "assignees"
    direction: "bidirectional"
    transform: "github_assignees_to_agent"

  - workSystemField: "tags"
    externalField: "labels"
    direction: "bidirectional"
    transform: "github_labels_to_tags"

typeMappings:
  - workSystemType: "bug"
    externalType: "issue"
    externalTypeId: null  # Determined by labels
  - workSystemType: "feature"
    externalType: "issue"
  - workSystemType: "task"
    externalType: "issue"

syncConfig:
  enabled: true
  interval: "PT5M"
  lastSyncAt: "2024-12-08T14:30:00Z"
  filters:
    repositories: ["company/customer-portal"]
    excludeClosed: false

metadata:
  appId: "12345"
  installationId: "67890"
```

### Azure DevOps Server Integration

```yaml
id: "azuredevops"
name: "Azure DevOps Server"
type: "combined"
baseUrl: "https://azuredevops.discovertec.net"
authType: "pat"
status: "connected"

capabilities:
  - read_workitems
  - write_workitems
  - read_comments
  - write_comments
  - read_projects
  - read_users
  - webhooks

syncDirection: "bidirectional"

fieldMappings:
  - workSystemField: "name"
    externalField: "System.Title"
    direction: "bidirectional"

  - workSystemField: "description"
    externalField: "System.Description"
    direction: "bidirectional"

  - workSystemField: "status"
    externalField: "System.State"
    direction: "bidirectional"
    transform: "ado_state_to_workitem_status"

  - workSystemField: "priority"
    externalField: "Microsoft.VSTS.Common.Priority"
    direction: "bidirectional"
    transform: "ado_priority_to_workitem_priority"

  - workSystemField: "assigneeId"
    externalField: "System.AssignedTo"
    direction: "bidirectional"
    transform: "ado_user_to_agent"

  - workSystemField: "dueDate"
    externalField: "Microsoft.VSTS.Scheduling.DueDate"
    direction: "bidirectional"

  - workSystemField: "tags"
    externalField: "System.Tags"
    direction: "bidirectional"
    transform: "ado_tags_to_array"

typeMappings:
  - workSystemType: "epic"
    externalType: "Epic"
  - workSystemType: "feature"
    externalType: "Feature"
  - workSystemType: "story"
    externalType: "User Story"
  - workSystemType: "task"
    externalType: "Task"
  - workSystemType: "bug"
    externalType: "Bug"
  - workSystemType: "spike"
    externalType: "Task"

syncConfig:
  enabled: true
  interval: "PT5M"
  lastSyncAt: "2024-12-08T14:30:00Z"
  filters:
    projectNames: ["MyProject"]
    excludeCompleted: false
    modifiedSince: "2024-12-01T00:00:00Z"

metadata:
  collection: "Link"
  apiVersion: "6.0"
```

### Linear Integration

```yaml
id: "linear"
name: "Linear"
type: "issue_tracker"
baseUrl: "https://api.linear.app"
authType: "oauth2"
status: "connected"

capabilities:
  - read_workitems
  - write_workitems
  - read_comments
  - write_comments
  - read_projects
  - webhooks

syncDirection: "bidirectional"

fieldMappings:
  - workSystemField: "name"
    externalField: "title"
    direction: "bidirectional"

  - workSystemField: "description"
    externalField: "description"
    direction: "bidirectional"

  - workSystemField: "status"
    externalField: "state.name"
    direction: "bidirectional"
    transform: "linear_state_to_workitem_status"

  - workSystemField: "priority"
    externalField: "priority"
    direction: "bidirectional"
    transform: "linear_priority_to_workitem_priority"

typeMappings:
  - workSystemType: "epic"
    externalType: "Project"
  - workSystemType: "feature"
    externalType: "Issue"
  - workSystemType: "story"
    externalType: "Issue"
  - workSystemType: "task"
    externalType: "Issue"
  - workSystemType: "bug"
    externalType: "Issue"

syncConfig:
  enabled: true
  interval: "PT1M"
  filters:
    teamIds: ["team-123"]

metadata:
  workspaceId: "workspace-abc"
```

## Adapter Interface

Each external system has an adapter that implements these operations:

```yaml
ExternalSystemAdapter:
  # Connection
  connect(): Promise<void>
  disconnect(): Promise<void>
  healthCheck(): Promise<boolean>

  # Work Items
  fetchWorkItem(externalId: string): Promise<WorkItem>
  fetchWorkItems(filter: object): Promise<WorkItem[]>
  createWorkItem(workItem: WorkItem): Promise<string>  # Returns external ID
  updateWorkItem(externalId: string, changes: object): Promise<void>
  deleteWorkItem(externalId: string): Promise<void>

  # Comments
  fetchComments(workItemExternalId: string): Promise<Comment[]>
  createComment(workItemExternalId: string, body: string): Promise<string>

  # Time Logs (if supported)
  fetchTimeLogs(workItemExternalId: string): Promise<TimeLog[]>
  createTimeLog(workItemExternalId: string, timeLog: TimeLog): Promise<string>

  # Projects
  fetchProjects(): Promise<Project[]>
  fetchProject(externalId: string): Promise<Project>

  # Users
  fetchUsers(): Promise<Agent[]>

  # Sync
  syncInbound(): Promise<SyncResult>
  syncOutbound(workItems: WorkItem[]): Promise<SyncResult>

  # Webhooks
  handleWebhook(payload: object): Promise<void>
```

## Sync Process

```
┌─────────────┐     ┌──────────────┐     ┌────────────────┐
│  External   │────▶│   Adapter    │────▶│  Work System   │
│   System    │◀────│  (Transform) │◀────│    Schema      │
└─────────────┘     └──────────────┘     └────────────────┘

Inbound:  External → Transform → Work Item
Outbound: Work Item → Transform → External
```

## Validation Rules

1. **Required fields**: `id`, `name`, `type`, `baseUrl`, `authType`
2. **Valid mappings**: All `workSystemField` values must be valid schema fields
3. **Credentials**: Auth credentials stored securely (not in schema)

## Related Schemas

- [work-item.schema.md](work-item.schema.md) - Mapped work items
- [project.schema.md](project.schema.md) - Mapped projects
- [agent.schema.md](agent.schema.md) - Mapped users
