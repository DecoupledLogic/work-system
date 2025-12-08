---
description: Queue aggregate - urgency-based work containers
allowedTools:
  - Bash
  - Read
  - SlashCommand
---

# Queue Aggregate

Queues organize work items by urgency with SLA tracking.

## Command Syntax

```
/queue <action> [id] [--options]
```

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `list` | List all queues with counts | `/queue list` |
| `show` | Show items in a queue | `/queue show urgent` |
| `stats` | Queue statistics and SLA | `/queue stats` |

> **Note:** Items are routed to queues via `/work-item route <id> <queue>`

---

## Usage Examples

### List All Queues

```bash
/queue list
```

**Output:**
```
📬 Queues
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Queue       Items  SLA Response  SLA Resolution  Status
─────────── ────── ───────────── ─────────────── ──────────────
immediate   2      15 min        4 hours         ⚠️ 1 breached
urgent      5      1 hour        24 hours        ✅ OK
standard    23     4 hours       5 days          ✅ OK
deferred    47     -             -               ✅ Backlog

Total: 77 items across 4 queues
```

### Show Queue Contents

```bash
/queue show urgent
```

**Output:**
```
📬 Urgent Queue (5 items)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SLA: Response 1h | Resolution 24h

ID       Age    SLA Status   Priority  Assignee   Name
──────── ────── ──────────── ───────── ────────── ─────────────────────
WI-002   2h     ⚠️ Warning   critical  @cbryant   Login fails on Safari
WI-015   45m    ✅ OK        high      -          API timeout errors
WI-018   30m    ✅ OK        high      @claude    Payment processing bug
WI-021   15m    ✅ OK        high      -          Mobile app crash
WI-024   5m     ✅ OK        critical  -          Data sync failure

Unassigned: 3 items need attention
Oldest item: WI-002 (2h - approaching SLA breach)
```

### Queue Statistics

```bash
/queue stats
```

**Output:**
```
📊 Queue Statistics
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

immediate
  Items:        2
  Avg Age:      45m
  SLA Breaches: 1 (response)
  Oldest:       WI-001 (1h 30m) ⚠️

urgent
  Items:        5
  Avg Age:      1h 15m
  SLA Breaches: 0
  Oldest:       WI-002 (2h)

standard
  Items:        23
  Avg Age:      2d 4h
  SLA Breaches: 0
  Oldest:       WI-045 (4d)

deferred
  Items:        47
  Avg Age:      12d
  Oldest:       WI-012 (45d)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Today's Activity:
  Routed to immediate:  1
  Routed to urgent:     3
  Resolved from urgent: 2
  Escalated:            1

SLA Performance (30 days):
  Response SLA met:   94%
  Resolution SLA met: 87%
```

### Show Immediate (High Priority)

```bash
/queue show immediate
```

**Output:**
```
🚨 Immediate Queue (2 items)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SLA: Response 15min | Resolution 4h
⚠️  1 item has breached SLA

ID       Age      SLA Status   Assignee   Name
──────── ──────── ──────────── ────────── ─────────────────────
WI-001   1h 30m   ❌ BREACHED  @cbryant   Production DB down
WI-099   10m      ✅ OK        -          Auth service 500s

Action Required:
  → WI-001 breached response SLA 1h 15m ago
  → WI-099 needs immediate assignment
```

---

## Implementation

### Action: list

```bash
queues=("immediate" "urgent" "standard" "deferred")

echo "📬 Queues"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
printf "%-12s %-6s %-14s %-16s %s\n" "Queue" "Items" "SLA Response" "SLA Resolution" "Status"
echo "─────────── ────── ───────────── ─────────────── ──────────────"

total=0
for queue in "${queues[@]}"; do
  count=$(count_queue_items "$queue")
  slaResponse=$(get_queue_sla_response "$queue")
  slaResolution=$(get_queue_sla_resolution "$queue")
  breaches=$(count_sla_breaches "$queue")

  status="✅ OK"
  [ "$breaches" -gt 0 ] && status="⚠️ $breaches breached"
  [ "$queue" == "deferred" ] && status="✅ Backlog"

  printf "%-12s %-6s %-14s %-16s %s\n" "$queue" "$count" "$slaResponse" "$slaResolution" "$status"
  total=$((total + count))
done

echo ""
echo "Total: $total items across ${#queues[@]} queues"
```

### Action: show

```bash
queueId="$1"

# Validate queue
validQueues=("immediate" "urgent" "standard" "deferred")
if [[ ! " ${validQueues[*]} " =~ " $queueId " ]]; then
  echo "❌ Invalid queue: $queueId"
  echo "   Valid queues: ${validQueues[*]}"
  exit 1
fi

# Get queue config
queue=$(get_queue "$queueId")
slaResponse=$(echo "$queue" | jq -r '.sla.responseTime // "-"')
slaResolution=$(echo "$queue" | jq -r '.sla.resolutionTime // "-"')

# Get items in queue
items=$(query_work_items --queue "$queueId" --sort age)
count=$(echo "$items" | jq 'length')

# Check for breaches
breaches=$(echo "$items" | jq '[.[] | select(.slaStatus == "breached")] | length')

# Display header
icon="📬"
[ "$queueId" == "immediate" ] && icon="🚨"

echo "$icon ${queueId^} Queue ($count items)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "SLA: Response $slaResponse | Resolution $slaResolution"
[ "$breaches" -gt 0 ] && echo "⚠️  $breaches item(s) have breached SLA"
echo ""

# Display items
display_queue_items "$items"

# Show summary
unassigned=$(echo "$items" | jq '[.[] | select(.assigneeId == null)] | length')
oldest=$(echo "$items" | jq -r '.[0].id')
oldestAge=$(echo "$items" | jq -r '.[0].age')

echo ""
[ "$unassigned" -gt 0 ] && echo "Unassigned: $unassigned items need attention"
echo "Oldest item: $oldest ($oldestAge)"
```

---

## Routing Items

Items are routed via the work-item aggregate:

```bash
# Route to urgent with reason
/work-item route WI-001 urgent "Customer escalation"

# Route to immediate (emergency)
/work-item route WI-002 immediate "Production down"

# Move to backlog
/work-item route WI-003 deferred "Low priority, do later"
```

The queue aggregate tracks the items but doesn't perform routing directly.

---

## SLA Configuration

```yaml
immediate:
  responseTime: "PT15M"    # 15 minutes
  resolutionTime: "PT4H"   # 4 hours

urgent:
  responseTime: "PT1H"     # 1 hour
  resolutionTime: "P1D"    # 1 day

standard:
  responseTime: "PT4H"     # 4 hours
  resolutionTime: "P5D"    # 5 days

deferred:
  responseTime: null       # No SLA
  resolutionTime: null
```

---

## Related

- [Schema: queue](../../schema/queue.schema.md)
- [Command: /work-item route](work-item.md#action-route)
