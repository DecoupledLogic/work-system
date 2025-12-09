---
description: Work item aggregate - query and command interface
allowedTools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - SlashCommand
---

# WorkItem Aggregate

The primary domain aggregate for managing work items across all external systems.

## Command Syntax

```
/work-item <action> [id] [--options]
```

## Actions

### Queries

| Action | Description | Example |
|--------|-------------|---------|
| `get` | Get work item by ID | `/work-item get WI-001` |
| `list` | List work items with filters | `/work-item list --status in_progress` |
| `history` | View change history | `/work-item history WI-001` |

### Lifecycle Commands

| Action | Description | Example |
|--------|-------------|---------|
| `create` | Create new work item | `/work-item create --type task --name "..."` |
| `update` | Update work item | `/work-item update WI-001 --priority high` |
| `delete` | Soft delete work item | `/work-item delete WI-001` |

### Assignment Commands

| Action | Description | Example |
|--------|-------------|---------|
| `assign` | Assign to agent | `/work-item assign WI-001 @cbryant` |
| `unassign` | Remove assignment | `/work-item unassign WI-001` |

### Workflow Commands

| Action | Description | Example |
|--------|-------------|---------|
| `transition` | Move to stage | `/work-item transition WI-001 deliver` |
| `route` | Route to queue | `/work-item route WI-001 urgent "customer escalation"` |
| `block` | Mark as blocked | `/work-item block WI-001 "waiting on API"` |
| `unblock` | Remove block | `/work-item unblock WI-001` |

### Collaboration Commands

| Action | Description | Example |
|--------|-------------|---------|
| `comment` | Add comment | `/work-item comment WI-001 "Starting work"` |
| `log-time` | Log time spent | `/work-item log-time WI-001 2h30m "implementation"` |

### Hierarchy Commands

| Action | Description | Example |
|--------|-------------|---------|
| `add-child` | Create child item | `/work-item add-child WI-001 --type task --name "..."` |
| `move` | Reparent item | `/work-item move WI-001 --parent WI-002` |

### Dependency Commands

| Action | Description | Example |
|--------|-------------|---------|
| `depend` | Add/remove dependency | `/work-item depend WI-001 --blocked-by WI-002` |
| `show-dependencies` | Show dependency graph | `/work-item show-dependencies WI-001` |

### Sync Commands

| Action | Description | Example |
|--------|-------------|---------|
| `sync` | Sync with external | `/work-item sync WI-001` |
| `link` | Link to external | `/work-item link WI-001 --external teamwork:26134585` |

---

## Implementation

### 1. Parse Command

```bash
action="$1"
shift

case "$action" in
  get|list|history|show-dependencies)
    # Query actions
    ;;
  create|update|delete|assign|unassign|transition|route|block|unblock|comment|log-time|add-child|move|sync|link|depend)
    # Command actions
    ;;
  *)
    echo "Unknown action: $action"
    echo "Run /work-item --help for usage"
    exit 1
    ;;
esac
```

### 2. Action: get

**Query a work item by ID or external reference.**

```bash
# /work-item get WI-001
# /work-item get --external teamwork:26134585

id=""
externalRef=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --external)
      externalRef="$2"
      shift 2
      ;;
    *)
      id="$1"
      shift
      ;;
  esac
done

if [ -n "$externalRef" ]; then
  # Parse system:id format
  system="${externalRef%%:*}"
  externalId="${externalRef#*:}"

  # Look up by external reference
  workItem=$(lookup_by_external "$system" "$externalId")
else
  # Look up by internal ID
  workItem=$(lookup_by_id "$id")
fi

if [ -z "$workItem" ]; then
  echo "❌ Work item not found: ${id:-$externalRef}"
  exit 1
fi

# Display work item
display_work_item "$workItem"
```

**Output:**
```
📋 WI-001: Implement user authentication
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type:     task
Status:   in_progress
Priority: high
Queue:    standard
Stage:    deliver

Project:  PRJ-001 (Customer Portal)
Parent:   WI-000 (Auth Epic)
Assignee: @cbryant

External: teamwork:26134585
          https://company.teamwork.com/app/tasks/26134585

Created:  2024-12-07 10:00
Updated:  2024-12-08 14:30
Due:      2024-12-15

Acceptance Criteria:
  ✓ User can log in with Google
  ○ User can log in with GitHub
  ○ Session persists across refresh

Tags: auth, security, oauth
```

### 3. Action: list

**List work items with filters.**

```bash
# /work-item list --status in_progress --assignee @cbryant --project PRJ-001

status=""
assignee=""
project=""
type=""
queue=""
limit=20

while [[ $# -gt 0 ]]; do
  case "$1" in
    --status) status="$2"; shift 2 ;;
    --assignee) assignee="$2"; shift 2 ;;
    --project) project="$2"; shift 2 ;;
    --type) type="$2"; shift 2 ;;
    --queue) queue="$2"; shift 2 ;;
    --limit) limit="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Build filter and query
workItems=$(query_work_items "$status" "$assignee" "$project" "$type" "$queue" "$limit")

# Display list
display_work_item_list "$workItems"
```

**Output:**
```
📋 Work Items (12 found)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID       Type   Status       Priority  Assignee   Name
──────── ────── ──────────── ───────── ────────── ─────────────────────
WI-001   task   in_progress  high      @cbryant   Implement user auth
WI-002   bug    triaged      critical  -          Login fails on Safari
WI-003   task   planned      medium    @claude    Add rate limiting
...
```

### 4. Action: create

**Create a new work item.**

```bash
# /work-item create --type task --name "Implement feature" --project PRJ-001

type=""
name=""
description=""
project=""
parent=""
priority="medium"
assignee=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type) type="$2"; shift 2 ;;
    --name) name="$2"; shift 2 ;;
    --description) description="$2"; shift 2 ;;
    --project) project="$2"; shift 2 ;;
    --parent) parent="$2"; shift 2 ;;
    --priority) priority="$2"; shift 2 ;;
    --assignee) assignee="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Validate required fields
if [ -z "$type" ] || [ -z "$name" ]; then
  echo "❌ Required: --type and --name"
  exit 1
fi

# Validate type
validTypes=("epic" "feature" "story" "task" "bug" "spike")
if [[ ! " ${validTypes[*]} " =~ " $type " ]]; then
  echo "❌ Invalid type: $type"
  echo "   Valid types: ${validTypes[*]}"
  exit 1
fi

# Generate ID
id=$(generate_work_item_id "$project")

# Create work item
workItem=$(create_work_item "$id" "$type" "$name" "$description" "$project" "$parent" "$priority" "$assignee")

echo "✅ Created: $id"
display_work_item "$workItem"
```

### 5. Action: transition

**Move work item to a new stage.**

```bash
# /work-item transition WI-001 deliver

id="$1"
targetStage="$2"

# Get current work item
workItem=$(lookup_by_id "$id")
if [ -z "$workItem" ]; then
  echo "❌ Work item not found: $id"
  exit 1
fi

currentStage=$(echo "$workItem" | jq -r '.stage')
templateId=$(echo "$workItem" | jq -r '.templateId')

# Get allowed transitions from template
template=$(get_template "$templateId")
allowedTransitions=$(echo "$template" | jq -r ".stages[] | select(.id == \"$currentStage\") | .allowedTransitions[]")

# Validate transition
if [[ ! " $allowedTransitions " =~ " $targetStage " ]]; then
  echo "❌ Invalid transition: $currentStage → $targetStage"
  echo ""
  echo "Allowed transitions from '$currentStage':"
  echo "$allowedTransitions" | while read t; do echo "  - $t"; done
  exit 1
fi

# Check entry conditions
entryConditions=$(echo "$template" | jq -r ".stages[] | select(.id == \"$targetStage\") | .entryConditions[]")
# ... validate conditions

# Perform transition
workItem=$(update_work_item "$id" ".stage = \"$targetStage\"")

# Trigger hooks
trigger_stage_hooks "$id" "$currentStage" "$targetStage"

echo "✅ Transitioned: $currentStage → $targetStage"
display_work_item "$workItem"
```

### 6. Action: route

**Route work item to urgency queue.**

```bash
# /work-item route WI-001 urgent "customer escalation"

id="$1"
targetQueue="$2"
reason="${3:-}"

# Validate queue
validQueues=("immediate" "urgent" "standard" "deferred")
if [[ ! " ${validQueues[*]} " =~ " $targetQueue " ]]; then
  echo "❌ Invalid queue: $targetQueue"
  echo "   Valid queues: ${validQueues[*]}"
  exit 1
fi

# Get work item
workItem=$(lookup_by_id "$id")
currentQueue=$(echo "$workItem" | jq -r '.queue')
status=$(echo "$workItem" | jq -r '.status')

# Must be triaged to route
if [ "$status" == "draft" ]; then
  echo "❌ Cannot route: work item not yet triaged"
  echo "   Current status: $status"
  exit 1
fi

# Route
workItem=$(update_work_item "$id" ".queue = \"$targetQueue\"")

# Record routing history
record_routing "$id" "$currentQueue" "$targetQueue" "$reason"

# Add comment about routing
if [ -n "$reason" ]; then
  add_comment "$id" "Routed to $targetQueue: $reason"
fi

echo "✅ Routed: $currentQueue → $targetQueue"
[ -n "$reason" ] && echo "   Reason: $reason"
```

### 7. Action: comment

**Add comment to work item.**

```bash
# /work-item comment WI-001 "Starting implementation"

id="$1"
body="$2"

if [ -z "$body" ]; then
  echo "❌ Comment body required"
  exit 1
fi

# Get work item to find external system
workItem=$(lookup_by_id "$id")
externalSystem=$(echo "$workItem" | jq -r '.externalSystem')
externalId=$(echo "$workItem" | jq -r '.externalId')

# Add comment locally
commentId=$(add_comment "$id" "$body")

# Sync to external system if configured
if [ "$externalSystem" != "null" ] && [ "$externalSystem" != "internal" ]; then
  sync_comment_to_external "$externalSystem" "$externalId" "$body"
  echo "✅ Comment added and synced to $externalSystem"
else
  echo "✅ Comment added"
fi
```

### 8. Action: log-time

**Log time spent on work item.**

```bash
# /work-item log-time WI-001 2h30m "implementation work"

id="$1"
duration="$2"
description="${3:-}"

# Parse duration (2h30m, 1.5h, 90m, etc.)
minutes=$(parse_duration "$duration")

if [ "$minutes" -le 0 ]; then
  echo "❌ Invalid duration: $duration"
  echo "   Examples: 2h, 30m, 2h30m, 1.5h"
  exit 1
fi

# Get work item
workItem=$(lookup_by_id "$id")
externalSystem=$(echo "$workItem" | jq -r '.externalSystem')
externalId=$(echo "$workItem" | jq -r '.externalId')

# Log time locally
timelogId=$(log_time "$id" "$minutes" "$description")

# Sync to external system if configured
if [ "$externalSystem" != "null" ] && [ "$externalSystem" != "internal" ]; then
  sync_timelog_to_external "$externalSystem" "$externalId" "$minutes" "$description"
  echo "✅ Time logged and synced to $externalSystem"
else
  echo "✅ Time logged"
fi

hours=$((minutes / 60))
mins=$((minutes % 60))
echo "   Duration: ${hours}h ${mins}m"
[ -n "$description" ] && echo "   Description: $description"
```

### 9. Action: depend

**Manage dependencies between work items.**

```bash
# /work-item depend WI-001 --blocked-by WI-002
# /work-item depend WI-001 --blocking WI-003
# /work-item depend WI-001 --remove-blocked-by WI-002

id="$1"
shift

blockedBy=()
blocking=()
removeBlockedBy=()
removeBlocking=()
depType="complete"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --blocked-by) blockedBy+=("$2"); shift 2 ;;
    --blocking) blocking+=("$2"); shift 2 ;;
    --remove-blocked-by) removeBlockedBy+=("$2"); shift 2 ;;
    --remove-blocking) removeBlocking+=("$2"); shift 2 ;;
    --type) depType="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Validate work item exists
workItem=$(lookup_by_id "$id")
if [ -z "$workItem" ]; then
  echo "❌ Work item not found: $id"
  exit 1
fi

# Validate all referenced work items exist
for depId in "${blockedBy[@]}" "${blocking[@]}"; do
  depItem=$(lookup_by_id "$depId")
  if [ -z "$depItem" ]; then
    echo "❌ Dependency work item not found: $depId"
    exit 1
  fi
done

# Check for circular dependencies
for depId in "${blockedBy[@]}"; do
  if is_circular_dependency "$id" "$depId"; then
    echo "❌ Circular dependency detected"
    echo "   $depId already depends on $id"
    exit 1
  fi
done

# Update local work item (source of truth)
# - Add to blockedBy array of this item
# - Add to blocking array of the dependency item (inverse)
update_dependencies "$id" "$blockedBy" "$blocking" "$removeBlockedBy" "$removeBlocking" "$depType"

# Sync to external systems
externalSystem=$(echo "$workItem" | jq -r '.externalSystem')
if [ "$externalSystem" != "null" ] && [ "$externalSystem" != "internal" ]; then
  sync_dependencies_to_external "$id"
fi

echo "✅ Dependencies updated for $id"
display_dependencies "$id"
```

**Output:**

```text
✅ Dependencies updated for WI-001

Blocked by (1):
  ⬤ WI-002: Setup database schema (teamwork:456) [complete]

Blocking (0):
  (none)

Synced to: teamwork
```

### 10. Action: show-dependencies

**Display dependency graph for a work item.**

```bash
# /work-item show-dependencies WI-001
# /work-item show-dependencies WI-001 --recursive

id="$1"
recursive=false

if [ "$2" == "--recursive" ]; then
  recursive=true
fi

workItem=$(lookup_by_id "$id")
if [ -z "$workItem" ]; then
  echo "❌ Work item not found: $id"
  exit 1
fi

name=$(echo "$workItem" | jq -r '.name')
blockedBy=$(echo "$workItem" | jq -r '.blockedBy // []')
blocking=$(echo "$workItem" | jq -r '.blocking // []')

echo "📋 Dependency Graph for $id: $name"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Show blocked by
blockedByCount=$(echo "$blockedBy" | jq 'length')
echo "Blocked by ($blockedByCount):"
if [ "$blockedByCount" -eq 0 ]; then
  echo "  (none)"
else
  echo "$blockedBy" | jq -r '.[] | "  ⬤ \(.workItemId): \(.name // "Unknown") (\(.externalSystem):\(.externalId)) [\(.type)]"'
fi
echo ""

# Show blocking
blockingCount=$(echo "$blocking" | jq 'length')
echo "Blocking ($blockingCount):"
if [ "$blockingCount" -eq 0 ]; then
  echo "  (none)"
else
  echo "$blocking" | jq -r '.[] | "  ⬤ \(.workItemId): \(.name // "Unknown") (\(.externalSystem):\(.externalId)) [\(.type)]"'
fi

# Show chain analysis if recursive
if [ "$recursive" = true ]; then
  echo ""
  echo "Chain Analysis:"
  analyze_dependency_chain "$id"
fi
```

**Output:**

```text
📋 Dependency Graph for WI-001: Implement Event-Driven Architecture
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Blocked by (2):
  ⬤ WI-002: Implement State Machine (teamwork:456) [complete]
  ⬤ WI-005: Setup Event Bus (github:#789) [complete]

Blocking (1):
  ⬤ WI-003: Build Conductor Service (github:#123) [complete]

Chain Analysis:
  WI-002 ──▶ WI-001 ──▶ WI-003
  WI-005 ───┘
```

---

## Dependency Schema

Work items include the following dependency fields:

```yaml
# Dependency Fields
blockedBy: Dependency[]         # Work items that must complete before this one
blocking: Dependency[]          # Work items waiting on this one

# Dependency Type Definition
Dependency:
  workItemId: string            # Internal ID (e.g., "WI-002")
  externalId: string | null     # External ID (e.g., "26134585")
  externalSystem: string | null # Source (teamwork | github | linear | jira)
  type: enum                    # complete | start
  addedAt: datetime             # When dependency was added
  addedBy: string | null        # Who added it
```

**Dependency Types:**

| Type | Description |
|------|-------------|
| `complete` | This item can complete when the dependency completes (default) |
| `start` | This item can complete when the dependency starts |

---

## External System Sync

When a work item is linked to an external system, aggregate commands automatically sync:

| Command | Sync Behavior |
|---------|---------------|
| `update` | Updates external system fields |
| `transition` | Updates external status (via mapping) |
| `comment` | Creates comment in external system |
| `log-time` | Creates time entry in external system |
| `assign` | Updates assignee in external system |
| `depend` | Creates dependency in external system (or appends to description) |

### Sync Flow

```
/work-item comment WI-001 "message"
         │
         ▼
┌─────────────────────────┐
│  WorkItem Aggregate     │
│  1. Validate work item  │
│  2. Add comment locally │
│  3. Get external config │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐     ┌─────────────────┐
│  External System Check  │────▶│ externalSystem: │
│  teamwork? github?      │     │ "teamwork"      │
└───────────┬─────────────┘     │ externalId:     │
            │                   │ "26134585"      │
            ▼                   └─────────────────┘
┌─────────────────────────┐
│  Teamwork Adapter       │
│  createComment(         │
│    taskId: 26134585,    │
│    body: "message"      │
│  )                      │
└─────────────────────────┘
```

---

## Response Format

All commands return structured output:

**Success:**
```yaml
success: true
aggregate: work-item
action: transition
id: WI-001
result:
  previousStage: plan
  currentStage: deliver
synced:
  - teamwork
```

**Error:**
```yaml
success: false
aggregate: work-item
action: transition
id: WI-001
error: INVALID_TRANSITION
message: "Cannot transition from 'draft' to 'deliver'"
allowed:
  - triaged
```

---

## Examples

### Complete Workflow

```bash
# 1. Create a task
/work-item create --type task --name "Add rate limiting" --project PRJ-001

# 2. Assign to developer
/work-item assign WI-003 @cbryant

# 3. Move through stages
/work-item transition WI-003 plan
/work-item transition WI-003 deliver

# 4. Log progress
/work-item comment WI-003 "Starting implementation"
/work-item log-time WI-003 2h "Initial implementation"

# 5. Complete
/work-item transition WI-003 eval
/work-item update WI-003 --status done
```

### Handle External Work

```bash
# 1. Link existing Teamwork task
/work-item create --type task --name "Fix login bug"
/work-item link WI-004 --external teamwork:26134585

# 2. Now all commands sync automatically
/work-item comment WI-004 "Fixed in commit abc123"
# → Comment appears in Teamwork

/work-item log-time WI-004 1h30m "debugging and fix"
# → Time logged in Teamwork
```

---

## Related

- [Schema: work-item](../../schema/work-item.schema.md)
- [Schema: aggregates](../../schema/aggregates.md)
- [Command: /project](project.md)
- [Command: /queue](queue.md)
