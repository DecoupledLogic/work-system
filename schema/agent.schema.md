# Agent Schema

An agent is any entity that can perform work in the system - human users, AI assistants, or automated processes.

## Schema Definition

```yaml
Agent:
  # Identity
  id: string                    # Internal work system ID (e.g., "AGT-001")
  externalId: string | null     # ID in external system
  externalSystem: string | null # Source system (teamwork | github | linear | internal)

  # Classification
  type: enum                    # human | ai | automation
  role: enum                    # developer | reviewer | manager | system

  # Profile
  name: string                  # Display name
  handle: string | null         # Username/handle (e.g., "@cbryant")
  email: string | null          # Email address
  avatar: string | null         # Avatar URL

  # Capabilities
  capabilities: string[]        # What the agent can do
  skills: string[]              # Technical skills/domains
  maxConcurrentItems: number    # How many items can work simultaneously

  # Availability
  status: enum                  # active | away | offline
  timezone: string | null       # IANA timezone (e.g., "America/New_York")
  workingHours: object | null
    start: string               # "09:00"
    end: string                 # "17:00"
    days: string[]              # ["mon", "tue", "wed", "thu", "fri"]

  # Tracking
  createdAt: datetime
  updatedAt: datetime
  lastActiveAt: datetime | null

  # Metadata
  metadata: object              # Flexible key-value for system-specific data
```

## Agent Types

| Type | Description | Examples |
|------|-------------|----------|
| `human` | Human team member | Developers, managers, reviewers |
| `ai` | AI assistant | Claude, GPT-based agents |
| `automation` | Automated process | CI/CD bots, scheduled jobs |

## Roles

| Role | Description | Typical Capabilities |
|------|-------------|---------------------|
| `developer` | Implements work items | code, test, document |
| `reviewer` | Reviews and approves | review, approve, comment |
| `manager` | Manages work and team | assign, prioritize, report |
| `system` | Automated system role | notify, sync, audit |

## Capabilities

Standard capabilities that can be assigned to agents:

```yaml
capabilities:
  - triage      # Can triage incoming work
  - plan        # Can break down and estimate work
  - design      # Can create solution designs
  - code        # Can write code
  - test        # Can write and run tests
  - review      # Can review work
  - approve     # Can approve/merge work
  - deploy      # Can deploy to environments
  - assign      # Can assign work to others
  - prioritize  # Can set priorities and queues
  - comment     # Can add comments
  - close       # Can close/complete work items
```

## Examples

### Human Developer

```yaml
id: "AGT-001"
externalId: "456789"
externalSystem: "teamwork"
type: "human"
role: "developer"
name: "Chris Bryant"
handle: "@cbryant"
email: "cbryant@company.com"
avatar: "https://avatars.example.com/cbryant.jpg"
capabilities:
  - triage
  - plan
  - design
  - code
  - test
  - review
  - comment
skills:
  - "typescript"
  - "python"
  - "react"
  - "aws"
maxConcurrentItems: 3
status: "active"
timezone: "America/New_York"
workingHours:
  start: "09:00"
  end: "17:00"
  days: ["mon", "tue", "wed", "thu", "fri"]
metadata:
  teamwork:
    userId: "456789"
    companyId: "123"
```

### AI Assistant (Claude)

```yaml
id: "AGT-002"
externalId: null
externalSystem: "internal"
type: "ai"
role: "developer"
name: "Claude"
handle: "@claude"
email: null
avatar: null
capabilities:
  - triage
  - plan
  - design
  - code
  - test
  - review
  - comment
skills:
  - "typescript"
  - "python"
  - "rust"
  - "go"
  - "documentation"
  - "architecture"
maxConcurrentItems: 1
status: "active"
timezone: null
workingHours: null  # Available 24/7
metadata:
  model: "claude-opus-4-5-20251101"
  context: "work-system"
```

### CI/CD Bot

```yaml
id: "AGT-003"
externalId: "github-actions"
externalSystem: "github"
type: "automation"
role: "system"
name: "GitHub Actions"
handle: "@github-actions[bot]"
email: null
capabilities:
  - test
  - deploy
  - comment
  - notify
skills: []
maxConcurrentItems: 100
status: "active"
metadata:
  github:
    appId: "15368"
```

## Status Values

| Status | Description |
|--------|-------------|
| `active` | Available for work |
| `away` | Temporarily unavailable |
| `offline` | Not available |

## Relationships

```
Agent
├── WorkItem[] (assignee via assigneeId)
├── WorkItem[] (reporter via reporterId)
├── Project[] (owner via ownerId)
├── Team[] (member via teamIds)
└── Session[] (current sessions)
```

## Validation Rules

1. **Required fields**: `id`, `type`, `role`, `name`
2. **Email format**: If `email` is set, must be valid email format
3. **Working hours**: If `workingHours` is set, `start`, `end`, and `days` are required
4. **Timezone**: Must be valid IANA timezone if set

## Related Schemas

- [work-item.schema.md](work-item.schema.md) - Assigned work
- [project.schema.md](project.schema.md) - Owned projects
- [session.schema.md](session.schema.md) - Work sessions
