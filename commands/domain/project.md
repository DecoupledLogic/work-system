---
description: Project aggregate - container for related work items
allowedTools:
  - Bash
  - Read
  - Write
  - SlashCommand
---

# Project Aggregate

Projects are containers for related work items, representing a codebase, initiative, or bounded context.

## Command Syntax

```
/project <action> [id] [--options]
```

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `get` | Get project details | `/project get PRJ-001` |
| `list` | List all projects | `/project list --status active` |
| `stats` | Project statistics | `/project stats PRJ-001` |
| `create` | Create project | `/project create --name "..."` |
| `update` | Update project | `/project update PRJ-001 --status archived` |
| `add-member` | Add team member | `/project add-member PRJ-001 @cbryant` |
| `remove-member` | Remove member | `/project remove-member PRJ-001 @cbryant` |
| `sync` | Sync with external | `/project sync PRJ-001` |
| `link` | Link to external | `/project link PRJ-001 --external teamwork:789456` |

---

## Usage Examples

### Query Projects

```bash
# Get project details
/project get PRJ-001

# List active projects
/project list --status active

# Get project statistics
/project stats PRJ-001
```

**Output for `/project get PRJ-001`:**
```
📁 PRJ-001: Customer Portal
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status:   active
Owner:    @cbryant

External: teamwork:789456
          https://company.teamwork.com/app/projects/789456

Repository:
  URL:    git@github.com:company/customer-portal.git
  Branch: main

Team Members:
  @cbryant (owner)
  @claude (developer)
  @jane (reviewer)

Work Items:  42 total
  ├── 3 in_progress
  ├── 8 planned
  ├── 12 done
  └── 19 backlog
```

**Output for `/project stats PRJ-001`:**
```
📊 PRJ-001: Customer Portal - Statistics
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Work Items by Status:
  draft        ████░░░░░░░░░░░░░░░░  5
  triaged      ██████░░░░░░░░░░░░░░  8
  planned      ████████░░░░░░░░░░░░  10
  in_progress  ███░░░░░░░░░░░░░░░░░  3
  review       ██░░░░░░░░░░░░░░░░░░  2
  done         ████████████░░░░░░░░  14

By Type:
  epic     2
  feature  5
  story    15
  task     18
  bug      2

Time This Week:
  Logged:    24h 30m
  Estimated: 32h 00m

Velocity (last 4 weeks):
  Week -3:  12 items
  Week -2:  15 items
  Week -1:  11 items
  Current:   8 items (in progress)
```

### Create Project

```bash
/project create --name "API Gateway" --template standard --repo git@github.com:company/api-gateway.git
```

**Output:**
```
✅ Created: PRJ-002

📁 PRJ-002: API Gateway
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status:   active
Template: standard

Repository:
  URL:    git@github.com:company/api-gateway.git
  Branch: main

Next steps:
  /project add-member PRJ-002 @developer
  /project link PRJ-002 --external teamwork:123456
```

### Team Management

```bash
# Add member with role
/project add-member PRJ-001 @newdev --role developer

# Remove member
/project remove-member PRJ-001 @olddev
```

### Link to External System

```bash
# Link to Teamwork project
/project link PRJ-001 --external teamwork:789456

# Link to GitHub repo (for issues)
/project link PRJ-001 --external github:company/customer-portal
```

---

## Implementation

### Action: get

```bash
id="$1"

project=$(lookup_project "$id")
if [ -z "$project" ]; then
  echo "❌ Project not found: $id"
  exit 1
fi

display_project "$project"
```

### Action: stats

```bash
id="$1"

project=$(lookup_project "$id")
workItems=$(query_work_items_by_project "$id")

# Calculate statistics
statusCounts=$(echo "$workItems" | jq 'group_by(.status) | map({status: .[0].status, count: length})')
typeCounts=$(echo "$workItems" | jq 'group_by(.type) | map({type: .[0].type, count: length})')
timeLogged=$(sum_time_logs "$id" "this_week")
velocity=$(calculate_velocity "$id" 4)

display_project_stats "$project" "$statusCounts" "$typeCounts" "$timeLogged" "$velocity"
```

### Action: add-member

```bash
projectId="$1"
agentHandle="$2"
role="developer"

while [[ $# -gt 2 ]]; do
  case "$3" in
    --role) role="$4"; shift 2 ;;
    *) shift ;;
  esac
done

# Resolve agent
agent=$(resolve_agent "$agentHandle")
if [ -z "$agent" ]; then
  echo "❌ Agent not found: $agentHandle"
  exit 1
fi

agentId=$(echo "$agent" | jq -r '.id')

# Add to project
add_project_member "$projectId" "$agentId" "$role"

echo "✅ Added $agentHandle to $projectId as $role"
```

### Action: sync

```bash
projectId="$1"

project=$(lookup_project "$projectId")
externalSystem=$(echo "$project" | jq -r '.externalSystem')

if [ "$externalSystem" == "null" ] || [ "$externalSystem" == "internal" ]; then
  echo "❌ Project not linked to external system"
  echo "   Link first: /project link $projectId --external <system>:<id>"
  exit 1
fi

echo "🔄 Syncing $projectId with $externalSystem..."

# Sync work items
syncResult=$(sync_project_work_items "$projectId" "$externalSystem")

created=$(echo "$syncResult" | jq '.created')
updated=$(echo "$syncResult" | jq '.updated')
errors=$(echo "$syncResult" | jq '.errors')

echo "✅ Sync complete"
echo "   Created: $created"
echo "   Updated: $updated"
[ "$errors" -gt 0 ] && echo "   Errors:  $errors"
```

---

## Integration

Projects integrate with work items through the `projectId` field:

```bash
# Create work item in project
/work-item create --type feature --name "User Auth" --project PRJ-001

# List project work items
/work-item list --project PRJ-001

# Project stats include all work items
/project stats PRJ-001
```

---

## Related

- [Schema: project](../../schema/project.schema.md)
- [Command: /work-item](work-item.md)
- [Command: /agent](agent.md)
