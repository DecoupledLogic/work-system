---
name: disable-recommendation
description: Temporarily disable an architecture recommendation with tracked reason and history
---

# Disable Recommendation Command

Temporarily disable an architecture recommendation to exclude it from enforcement in code-review and design processes. All disables are tracked with reason, author, and timestamp for audit purposes.

## Usage

```
/disable-recommendation <id> --reason "explanation"
/disable-recommendation ARCH-G001 --reason "Legacy migration in progress"
/disable-recommendation ARCH-L001 --reason "Not applicable to our stack"
/disable-recommendation ARCH-G002 --reason "Logging audit requirement" --until 2025-12-31
```

## When to Disable

Disable recommendations temporarily when:

| Scenario | Example | Duration |
|----------|---------|----------|
| **Legacy migration** | Moving old code, will fix later | Weeks to months |
| **Not applicable** | Recommendation doesn't fit your architecture | Permanent (until removed) |
| **Temporary override** | Special case requires exception | Days to weeks |
| **Testing/debugging** | Need to bypass temporarily | Hours to days |
| **Compliance conflict** | Legal/audit requirement overrides | Until resolved |

## Implementation

### Step 1: Parse Arguments

Extract recommendation ID and reason:

```bash
id="$1"
reason=""
until=""

# Parse arguments
shift
while [ $# -gt 0 ]; do
  case "$1" in
    --reason)
      reason="$2"
      shift 2
      ;;
    --until)
      until="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown argument: $1"
      exit 1
      ;;
  esac
done

# Validate required arguments
if [ -z "$id" ]; then
  echo "❌ Recommendation ID required"
  echo ""
  echo "Usage: /disable-recommendation <id> --reason \"explanation\""
  echo ""
  echo "Examples:"
  echo "  /disable-recommendation ARCH-G001 --reason \"Legacy migration\""
  echo "  /disable-recommendation ARCH-L001 --reason \"Not applicable\""
  exit 1
fi

if [ -z "$reason" ]; then
  echo "❌ Reason is required for disabling recommendations"
  echo ""
  echo "Usage: /disable-recommendation <id> --reason \"explanation\""
  echo ""
  echo "Provide a clear reason for audit and team visibility"
  exit 1
fi
```

### Step 2: Validate ID Format

Ensure ID matches expected pattern:

```bash
if ! echo "$id" | grep -qE '^ARCH-[GLH][0-9]{3}$'; then
  echo "❌ Invalid recommendation ID format: $id"
  echo ""
  echo "Valid formats:"
  echo "  ARCH-G### - Guardrails (e.g., ARCH-G001)"
  echo "  ARCH-L### - Leverage patterns (e.g., ARCH-L001)"
  echo "  ARCH-H### - Hygiene rules (e.g., ARCH-H001)"
  exit 1
fi
```

### Step 3: Load Recommendations File

Load and validate the recommendations file:

```bash
if [ ! -f "architecture-recommendations.json" ]; then
  echo "❌ No architecture-recommendations.json found"
  exit 1
fi

recommendations=$(cat architecture-recommendations.json)

# Determine type from ID prefix
type=""
case "${id:5:1}" in
  G) type="guardrails" ;;
  L) type="leverage" ;;
  H) type="hygiene" ;;
esac

# Find recommendation
item=$(echo "$recommendations" | jq --arg id "$id" --arg type "$type" \
  '.recommendations[$type] | .[] | select(.id == $id)')

if [ -z "$item" ] || [ "$item" = "null" ]; then
  echo "❌ Recommendation not found: $id"
  echo ""
  echo "Use /list-recommendations to see all available IDs"
  exit 1
fi
```

### Step 4: Check Current Status

Verify recommendation is not already disabled:

```bash
is_disabled=$(echo "$item" | jq -r '.disabled // false')

if [ "$is_disabled" = "true" ]; then
  echo "⚠️  Recommendation $id is already disabled"
  echo ""

  # Show current disable info
  disabled_by=$(echo "$item" | jq -r '.disabledBy // "Unknown"')
  disabled_at=$(echo "$item" | jq -r '.disabledAt // "Unknown"')
  disabled_reason=$(echo "$item" | jq -r '.disabledReason // "No reason provided"')

  echo "Current status:"
  echo "  Disabled by: $disabled_by"
  echo "  Disabled at: $disabled_at"
  echo "  Reason: $disabled_reason"
  echo ""
  echo "Use /enable-recommendation $id to re-enable"
  exit 0
fi
```

### Step 5: Show Confirmation Prompt

Display impact assessment before disabling:

```bash
title=$(echo "$item" | jq -r '.title')
priority=$(echo "$item" | jq -r '.priority')
category=$(echo "$item" | jq -r '.category')

echo "⚠️  Confirm Disable"
echo ""
echo "Recommendation: $id"
echo "Title: $title"
echo "Category: $category"
echo "Priority: $priority"
echo ""
echo "Reason: $reason"

if [ -n "$until" ]; then
  echo "Until: $until"
fi

echo ""
echo "Impact:"

# Show impact based on type and priority
case "$type" in
  guardrails)
    echo "  • Will NOT be enforced in /code-review"
    echo "  • Will NOT block PRs with violations"
    echo "  • Will NOT be checked during /design"

    if [ "$priority" = "Critical" ]; then
      echo ""
      echo "⚠️  WARNING: This is a CRITICAL guardrail"
      echo "Disabling may introduce serious risks."
    fi
    ;;
  leverage)
    echo "  • Will NOT be suggested during /design"
    echo "  • Will NOT appear in /code-review suggestions"
    ;;
  hygiene)
    echo "  • Will NOT be applied during /deliver"
    echo "  • Will NOT appear in opportunistic suggestions"
    ;;
esac

echo ""
read -p "Proceed with disabling? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "❌ Aborted"
  exit 0
fi
```

### Step 6: Update Recommendations File

Add disable metadata to the recommendation:

```bash
# Get current user
user=$(git config user.name || echo "Unknown")

# Get current timestamp
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Update recommendation with disable info
updated=$(echo "$recommendations" | jq \
  --arg id "$id" \
  --arg type "$type" \
  --arg user "$user" \
  --arg timestamp "$timestamp" \
  --arg reason "$reason" \
  --arg until "$until" \
  '
  .recommendations[$type] = [
    .recommendations[$type][] |
    if .id == $id then
      . + {
        disabled: true,
        disabledBy: $user,
        disabledAt: $timestamp,
        disabledReason: $reason
      } + (if $until != "" then {disabledUntil: $until} else {} end)
    else
      .
    end
  ]
  ')

# Write back to file
echo "$updated" | jq '.' > architecture-recommendations.json
```

### Step 7: Update History Log

Maintain audit trail of disable operations:

```bash
history_file=".claude/history/recommendations-history.jsonl"
mkdir -p .claude/history

# Append disable event to history
cat >> "$history_file" <<EOF
{
  "event": "disable",
  "id": "$id",
  "user": "$user",
  "timestamp": "$timestamp",
  "reason": "$reason",
  "until": "$until"
}
EOF
```

### Step 8: Display Confirmation

Show success message with next steps:

```
✅ Recommendation disabled: $id

Status:
  • Disabled by: $user
  • Disabled at: $timestamp
  • Reason: $reason

Impact:
  • Will NOT be enforced in /code-review
  • Will NOT be checked during /design
  • Logged to .claude/history/recommendations-history.jsonl

Next steps:
  • Use /list-recommendations --disabled to see all disabled
  • Use /enable-recommendation $id to re-enable
  • Use /recommendation-stats to track disable duration

⚠️  Remember to document this decision with your team
```

## Disable Metadata

Each disabled recommendation includes:

```json
{
  "id": "ARCH-G001",
  "disabled": true,
  "disabledBy": "George",
  "disabledAt": "2025-12-11T15:30:00Z",
  "disabledReason": "Legacy migration in progress",
  "disabledUntil": "2025-12-31T00:00:00Z"
}
```

## Time-based Disables

Use `--until` for temporary disables:

```bash
# Disable until specific date
/disable-recommendation ARCH-G001 \
  --reason "Testing period" \
  --until 2025-12-31

# System will show warning when date approaches
```

When date is reached:
```
⚠️  Time-limited disable expired

ARCH-G001 was disabled until 2025-12-31
The date has passed. Consider re-enabling or extending:

  /enable-recommendation ARCH-G001
  /disable-recommendation ARCH-G001 --reason "Extended" --until 2026-01-31
```

## Examples

### Disable a guardrail temporarily

```
> /disable-recommendation ARCH-G001 --reason "Legacy migration in progress"

⚠️  Confirm Disable

Recommendation: ARCH-G001
Title: Domain layer must not reference Infrastructure
Priority: Critical

Reason: Legacy migration in progress

Impact:
  • Will NOT be enforced in /code-review
  • Will NOT block PRs with violations

⚠️  WARNING: This is a CRITICAL guardrail
Disabling may introduce serious risks.

Proceed with disabling? (yes/no): yes

✅ Recommendation disabled: ARCH-G001
```

### Disable with time limit

```
> /disable-recommendation ARCH-L001 \
    --reason "Not using this pattern yet" \
    --until 2025-12-31

✅ Recommendation disabled: ARCH-L001

Will auto-expire on: 2025-12-31
```

### Abort disable

```
> /disable-recommendation ARCH-G002 --reason "Test"

⚠️  Confirm Disable
...
Proceed with disabling? (yes/no): no

❌ Aborted
```

## Error Handling

### No reason provided

```
❌ Reason is required for disabling recommendations

Usage: /disable-recommendation <id> --reason "explanation"

Provide a clear reason for audit and team visibility

Examples:
  --reason "Legacy code migration"
  --reason "Not applicable to our architecture"
  --reason "Compliance requirement overrides"
```

### Already disabled

```
⚠️  Recommendation ARCH-G001 is already disabled

Current status:
  Disabled by: George
  Disabled at: 2025-12-10T10:00:00Z
  Reason: Legacy migration in progress

Use /enable-recommendation ARCH-G001 to re-enable
```

### Invalid date format (for --until)

```
❌ Invalid date format for --until: 12/31/2025

Use ISO 8601 format: YYYY-MM-DD

Examples:
  --until 2025-12-31
  --until 2026-01-15
```

### Critical guardrail warning

```
⚠️  WARNING: Disabling CRITICAL guardrail

ARCH-G002: Never log sensitive data

This guardrail protects against serious security vulnerabilities.

Disabling requires additional justification:
  --reason must explain:
    1. Why this is necessary
    2. What mitigations are in place
    3. When it will be re-enabled

Consider:
  • Alternative approaches that don't require disabling
  • Temporary workarounds that comply
  • Consulting with security team
```

## Best Practices

### Writing Good Reasons

Good reasons are:
- **Specific:** "Migrating 10 legacy services, cleanup by Q1 2026"
- **Actionable:** "Waiting for updated style guide from architecture team"
- **Time-bound:** "Temporary override for v2.0 launch, re-enable after"

Bad reasons:
- ❌ "Doesn't work"
- ❌ "Too strict"
- ❌ "Team decision"

### When to Disable vs Remove

| Action | When |
|--------|------|
| **Disable** | Temporary override, will re-enable later |
| **Remove** | Recommendation is permanently not applicable |

To remove permanently:
```
# Edit architecture-recommendations.json manually
# Or use /extract-review-patterns to regenerate
```

### Team Communication

When disabling critical guardrails:
1. Document in team chat/wiki
2. Create tracking issue
3. Set calendar reminder to review
4. Plan re-enable or mitigation

## Integration

### With /list-recommendations

See all disabled recommendations:
```
> /list-recommendations --disabled
> /disable-recommendation ARCH-G001 --reason "..."
> /list-recommendations --disabled
```

### With /view-recommendation

View details before disabling:
```
> /view-recommendation ARCH-G001
> /disable-recommendation ARCH-G001 --reason "..."
```

### With /code-review

Disabled guardrails are not checked:
```
> /disable-recommendation ARCH-G001 --reason "Migration"
> /code-review
# ARCH-G001 will not be checked
```

### With /recommendation-stats

Track how long recommendations are disabled:
```
> /disable-recommendation ARCH-G001 --reason "..."
> /recommendation-stats ARCH-G001
# Shows disable duration and impact
```

## Audit Trail

All disable operations are logged to:
- **Main file:** `architecture-recommendations.json` (disable metadata)
- **History log:** `.claude/history/recommendations-history.jsonl`
- **Git history:** Commits show who/when/why

Example history entry:
```json
{
  "event": "disable",
  "id": "ARCH-G001",
  "user": "George",
  "timestamp": "2025-12-11T15:30:00Z",
  "reason": "Legacy migration in progress",
  "until": "2025-12-31T00:00:00Z"
}
```

## Related Commands

- `/list-recommendations --disabled` - See all disabled recommendations
- `/view-recommendation <id>` - View recommendation details
- `/enable-recommendation <id>` - Re-enable a recommendation
- `/recommendation-stats` - View disable duration and impact
- `/code-review` - Apply enabled recommendations only

---

*Created: 2025-12-11*
*Part of: PR Feedback Learning Loop (Phase 2.5)*
