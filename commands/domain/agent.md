---
description: Agent aggregate - humans, AI, and automation that perform work
allowedTools:
  - Bash
  - Read
  - SlashCommand
---

# Agent Aggregate

Agents are entities that perform work - humans, AI assistants, or automated processes.

## Command Syntax

```
/agent <action> [id] [--options]
```

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `get` | Get agent details | `/agent get @cbryant` |
| `list` | List agents | `/agent list --available` |
| `workload` | Show current workload | `/agent workload @cbryant` |
| `status` | Set your status | `/agent status --away` |
| `my-work` | List your assignments | `/agent my-work` |

---

## Usage Examples

### Query Agents

```bash
# Get agent details
/agent get @cbryant

# List available agents
/agent list --available

# List by type
/agent list --type ai
```

**Output for `/agent get @cbryant`:**
```
👤 AGT-001: Chris Bryant (@cbryant)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type:   human
Role:   developer
Status: active

Capabilities:
  triage, plan, design, code, test, review, comment

Skills:
  typescript, python, react, aws

Current Workload: 3 / 5 max
  WI-001  in_progress  Implement user auth
  WI-003  planned      Add rate limiting
  WI-007  review       Fix login bug

External: teamwork:456789
```

**Output for `/agent list --available`:**
```
👥 Available Agents
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Handle     Type    Role       Workload  Status
────────── ─────── ────────── ───────── ──────
@cbryant   human   developer  3/5       active
@claude    ai      developer  1/1       active
@jane      human   reviewer   2/4       active
@bot       auto    system     -         active

Unavailable:
@mike      human   developer  5/5       away
```

### Check Workload

```bash
/agent workload @cbryant
```

**Output:**
```
📊 Workload: @cbryant
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Capacity: 3 / 5 items

Current Work:
  ID       Status       Priority  Due        Name
  ──────── ──────────── ───────── ────────── ─────────────────
  WI-001   in_progress  high      Dec 15     Implement user auth
  WI-003   planned      medium    Dec 20     Add rate limiting
  WI-007   review       low       Dec 18     Fix login bug

Time This Week:
  Logged:    18h 30m
  Remaining: 21h 30m (based on 40h week)

Queue Distribution:
  immediate  0
  urgent     1
  standard   2
  deferred   0
```

### Your Work (Current Agent)

```bash
# See what you're working on
/agent my-work

# Filter by status
/agent my-work --status in_progress
```

**Output:**
```
📋 My Work (@cbryant)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

In Progress:
  WI-001  [high]  Implement user auth
    Stage: deliver | Due: Dec 15
    Last: "Starting OAuth implementation" (2h ago)

Planned:
  WI-003  [medium]  Add rate limiting
    Stage: plan | Due: Dec 20

In Review:
  WI-007  [low]  Fix login bug
    Stage: deliver | Due: Dec 18
    Waiting for: @jane

Suggested Next:
  → WI-003 is ready to start (plan → deliver)
  → WI-012 in urgent queue needs attention
```

### Set Status

```bash
# Set yourself as away
/agent status --away

# Set yourself as active
/agent status --active

# Set with message
/agent status --away "In meetings until 3pm"
```

---

## Implementation

### Action: my-work

```bash
# Get current agent (from session context)
currentAgent=$(get_current_agent)
agentId=$(echo "$currentAgent" | jq -r '.id')

status=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --status) status="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Query assigned work items
workItems=$(query_work_items --assignee "$agentId" ${status:+--status "$status"})

# Group by status
inProgress=$(echo "$workItems" | jq '[.[] | select(.status == "in_progress")]')
planned=$(echo "$workItems" | jq '[.[] | select(.status == "planned")]')
review=$(echo "$workItems" | jq '[.[] | select(.status == "review")]')

# Display
display_my_work "$inProgress" "$planned" "$review"

# Suggest next action
suggest_next_action "$workItems"
```

### Action: status

```bash
currentAgent=$(get_current_agent)
agentId=$(echo "$currentAgent" | jq -r '.id')

newStatus=""
message=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --away) newStatus="away"; shift ;;
    --active) newStatus="active"; shift ;;
    --offline) newStatus="offline"; shift ;;
    *) message="$1"; shift ;;
  esac
done

if [ -z "$newStatus" ]; then
  # Show current status
  display_agent_status "$currentAgent"
  exit 0
fi

# Update status
update_agent_status "$agentId" "$newStatus" "$message"

echo "✅ Status updated: $newStatus"
[ -n "$message" ] && echo "   Message: $message"
```

---

## AI Agent Integration

AI agents (like Claude) are first-class citizens:

```yaml
Agent:
  id: "AGT-002"
  type: "ai"
  role: "developer"
  name: "Claude"
  handle: "@claude"
  capabilities:
    - triage
    - plan
    - design
    - code
    - test
    - review
    - comment
  maxConcurrentItems: 1
  status: "active"
```

AI agents can:
- Be assigned work items
- Transition through stages
- Add comments and log time
- Follow the same workflow as humans

```bash
# Assign to AI
/work-item assign WI-001 @claude

# AI can work on it
/work-item transition WI-001 deliver
/work-item comment WI-001 "Implementation complete"
/work-item log-time WI-001 45m "coding"
```

---

## Related

- [Schema: agent](../../schema/agent.schema.md)
- [Command: /work-item](work-item.md)
- [Command: /project](project.md)
