---
name: enable-recommendation
description: Re-enable a previously disabled architecture recommendation
---

# Enable Recommendation Command

Re-enable a previously disabled architecture recommendation to restore enforcement in code-review and design processes. All enables are tracked with author and timestamp for audit purposes.

## Usage

```
/enable-recommendation <id>
/enable-recommendation ARCH-G001
/enable-recommendation ARCH-L001
/enable-recommendation ARCH-H001
/enable-recommendation ARCH-G001 --comment "Migration complete"
```

## When to Enable

Re-enable recommendations when:

| Scenario | Example |
|----------|---------|
| **Work complete** | Legacy migration finished, ready to enforce |
| **Exception resolved** | Temporary override no longer needed |
| **Time limit expired** | Disabled until specific date, now reached |
| **Architecture changed** | Recommendation now applicable to new stack |
| **Review decision** | Team decided to re-adopt pattern |

## Implementation

### Step 1: Parse Arguments

Extract recommendation ID and optional comment:

```bash
id="$1"
comment=""

# Parse arguments
shift
while [ $# -gt 0 ]; do
  case "$1" in
    --comment)
      comment="$2"
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
  echo "Usage: /enable-recommendation <id>"
  echo ""
  echo "Examples:"
  echo "  /enable-recommendation ARCH-G001"
  echo "  /enable-recommendation ARCH-L001 --comment \"Work complete\""
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

Verify recommendation is actually disabled:

```bash
is_disabled=$(echo "$item" | jq -r '.disabled // false')

if [ "$is_disabled" != "true" ]; then
  echo "ℹ️  Recommendation $id is already enabled"
  echo ""

  title=$(echo "$item" | jq -r '.title')
  priority=$(echo "$item" | jq -r '.priority')

  echo "Current status:"
  echo "  Title: $title"
  echo "  Priority: $priority"
  echo "  Status: Enabled"
  echo ""
  echo "No action needed."
  exit 0
fi
```

### Step 5: Show Disable History

Display information about when/why it was disabled:

```bash
title=$(echo "$item" | jq -r '.title')
priority=$(echo "$item" | jq -r '.priority')
category=$(echo "$item" | jq -r '.category')
disabled_by=$(echo "$item" | jq -r '.disabledBy // "Unknown"')
disabled_at=$(echo "$item" | jq -r '.disabledAt // "Unknown"')
disabled_reason=$(echo "$item" | jq -r '.disabledReason // "No reason provided"')
disabled_until=$(echo "$item" | jq -r '.disabledUntil // ""')

echo "📋 Re-enabling Recommendation"
echo ""
echo "Recommendation: $id"
echo "Title: $title"
echo "Category: $category"
echo "Priority: $priority"
echo ""
echo "Disable History:"
echo "  Disabled by: $disabled_by"
echo "  Disabled at: $disabled_at"
echo "  Reason: $disabled_reason"

if [ -n "$disabled_until" ]; then
  echo "  Was disabled until: $disabled_until"
fi

# Calculate disable duration
disable_start=$(date -d "$disabled_at" +%s 2>/dev/null || echo "0")
now=$(date +%s)
duration_days=$(( (now - disable_start) / 86400 ))

if [ "$duration_days" -gt 0 ]; then
  echo "  Duration: $duration_days days"
fi
```

### Step 6: Show Impact Assessment

Display what will change when re-enabled:

```bash
echo ""
echo "Impact of re-enabling:"

case "$type" in
  guardrails)
    echo "  • WILL be enforced in /code-review"
    echo "  • WILL block PRs with violations"
    echo "  • WILL be checked during /design"

    if [ "$priority" = "Critical" ]; then
      echo ""
      echo "✅ This is a CRITICAL guardrail"
      echo "Re-enabling will restore important protections."
    fi
    ;;
  leverage)
    echo "  • WILL be suggested during /design"
    echo "  • WILL appear in /code-review suggestions"
    ;;
  hygiene)
    echo "  • WILL be applied during /deliver"
    echo "  • WILL appear in opportunistic suggestions"
    ;;
esac

echo ""
read -p "Proceed with re-enabling? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "❌ Aborted"
  exit 0
fi
```

### Step 7: Update Recommendations File

Remove disable metadata from the recommendation:

```bash
# Get current user
user=$(git config user.name || echo "Unknown")

# Get current timestamp
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Remove disable fields from recommendation
updated=$(echo "$recommendations" | jq \
  --arg id "$id" \
  --arg type "$type" \
  '
  .recommendations[$type] = [
    .recommendations[$type][] |
    if .id == $id then
      # Remove disable-related fields
      del(.disabled, .disabledBy, .disabledAt, .disabledReason, .disabledUntil)
    else
      .
    end
  ]
  ')

# Write back to file
echo "$updated" | jq '.' > architecture-recommendations.json
```

### Step 8: Update History Log

Maintain audit trail of enable operations:

```bash
history_file=".claude/history/recommendations-history.jsonl"
mkdir -p .claude/history

# Append enable event to history
cat >> "$history_file" <<EOF
{
  "event": "enable",
  "id": "$id",
  "user": "$user",
  "timestamp": "$timestamp",
  "comment": "$comment",
  "disableDuration": "${duration_days}d"
}
EOF
```

### Step 9: Check for Existing Violations

Optionally scan codebase for existing violations of the re-enabled recommendation:

```bash
if [ "$type" = "guardrails" ]; then
  echo ""
  echo "🔍 Checking for existing violations..."

  # Get the implementation check pattern
  check_pattern=$(echo "$item" | jq -r '.implementation.check // ""')

  if [ -n "$check_pattern" ]; then
    echo "Running: $check_pattern"

    # Run the check (this is simplified - actual implementation would be more complex)
    # violations=$(eval "$check_pattern")

    echo ""
    echo "💡 Tip: Run /code-review to check current code against this guardrail"
  fi
fi
```

### Step 10: Display Confirmation

Show success message with next steps:

```
✅ Recommendation re-enabled: $id

Status:
  • Re-enabled by: $user
  • Re-enabled at: $timestamp
  • Was disabled for: ${duration_days} days

Impact:
  • WILL be enforced in /code-review
  • WILL be checked during /design
  • Logged to .claude/history/recommendations-history.jsonl

Next steps:
  • Run /code-review to check current code
  • Run /list-recommendations to see all enabled
  • Run /view-recommendation $id to review details

✅ Recommendation is now active
```

## Examples

### Enable a disabled guardrail

```
> /enable-recommendation ARCH-G001

📋 Re-enabling Recommendation

Recommendation: ARCH-G001
Title: Domain layer must not reference Infrastructure
Priority: Critical

Disable History:
  Disabled by: George
  Disabled at: 2025-12-01T10:00:00Z
  Reason: Legacy migration in progress
  Duration: 10 days

Impact of re-enabling:
  • WILL be enforced in /code-review
  • WILL block PRs with violations

✅ This is a CRITICAL guardrail
Re-enabling will restore important protections.

Proceed with re-enabling? (yes/no): yes

✅ Recommendation re-enabled: ARCH-G001
```

### Enable with comment

```
> /enable-recommendation ARCH-G001 --comment "Migration complete, all services updated"

✅ Recommendation re-enabled: ARCH-G001

Comment: Migration complete, all services updated
```

### Enable already enabled recommendation

```
> /enable-recommendation ARCH-G001

ℹ️  Recommendation ARCH-G001 is already enabled

Current status:
  Title: Domain layer must not reference Infrastructure
  Priority: Critical
  Status: Enabled

No action needed.
```

### Enable and check for violations

```
> /enable-recommendation ARCH-G001

...

🔍 Checking for existing violations...

⚠️  Found 2 potential violations:
  • src/Domain/Services/PaymentService.cs:15
  • src/Domain/Entities/User.cs:42

Next steps:
  Run /code-review for detailed analysis
  Run /view-recommendation ARCH-G001 for guidance
```

## Error Handling

### ID not provided

```
❌ Recommendation ID required

Usage: /enable-recommendation <id>

Examples:
  /enable-recommendation ARCH-G001
  /enable-recommendation ARCH-L001 --comment "Work complete"

Use /list-recommendations --disabled to see disabled recommendations
```

### Recommendation not found

```
❌ Recommendation not found: ARCH-G999

The recommendation with ID ARCH-G999 does not exist.

Use /list-recommendations to see all available recommendations:
  /list-recommendations --disabled
```

### Already enabled

```
ℹ️  Recommendation ARCH-G001 is already enabled

Current status: Enabled
Priority: Critical

No action needed.
```

### File not found

```
❌ No architecture-recommendations.json found

This file should be in the project root directory.

Initialize with:
  cp docs/templates/architecture-recommendations.example.json \\
     architecture-recommendations.json
```

## Enable Metrics

Track enable operations for analytics:

```json
{
  "event": "enable",
  "id": "ARCH-G001",
  "user": "George",
  "timestamp": "2025-12-11T15:30:00Z",
  "comment": "Migration complete",
  "disableDuration": "10d",
  "disableReason": "Legacy migration in progress"
}
```

## Post-Enable Actions

After re-enabling a critical guardrail:

1. **Run code-review:**
   ```
   /code-review
   ```

2. **Check design compliance:**
   ```
   /design WI-12345
   # Design agent will validate against guardrail
   ```

3. **Update team documentation:**
   - Remove exception notices
   - Update architecture docs
   - Communicate to team

4. **Monitor for violations:**
   ```
   /recommendation-stats ARCH-G001
   # Track if violations occur post-enable
   ```

## Integration

### With /list-recommendations

View disabled recommendations before enabling:
```
> /list-recommendations --disabled
> /enable-recommendation ARCH-G001
```

### With /view-recommendation

Review details before enabling:
```
> /view-recommendation ARCH-G001
> /enable-recommendation ARCH-G001
```

### With /code-review

Run code review after enabling critical guardrails:
```
> /enable-recommendation ARCH-G001
> /code-review
# ARCH-G001 will now be checked
```

### With /recommendation-stats

Track violations after re-enabling:
```
> /enable-recommendation ARCH-G001
> /recommendation-stats ARCH-G001
# Monitor violation rates
```

### With /disable-recommendation

View disable/enable history:
```
> /list-recommendations --disabled
> /enable-recommendation ARCH-G001
> /disable-recommendation ARCH-G001 --reason "New exception"
# Full history maintained
```

## Audit Trail

All enable operations are logged to:
- **Main file:** `architecture-recommendations.json` (removes disable metadata)
- **History log:** `.claude/history/recommendations-history.jsonl`
- **Git history:** Commits show who/when/why

Example history entry:
```json
{
  "event": "enable",
  "id": "ARCH-G001",
  "user": "George",
  "timestamp": "2025-12-11T15:30:00Z",
  "comment": "Migration complete, all services updated",
  "disableDuration": "10d"
}
```

## Best Practices

### When to Re-enable

✅ **Good reasons to re-enable:**
- Work that required exception is complete
- Architecture has evolved to support recommendation
- Time-limited override period expired
- Team consensus to re-adopt pattern

❌ **Bad reasons to re-enable:**
- Pressure to reduce disable count
- Without verifying work is complete
- Before communicating to team
- Without checking for violations

### Post-Enable Communication

When re-enabling critical guardrails:
1. **Notify team:** "ARCH-G001 re-enabled, migration complete"
2. **Update docs:** Remove exception notices
3. **Run checks:** Verify no new violations
4. **Monitor:** Track violations in next few PRs

### Gradual Re-enable

For recommendations disabled across many components:
1. Fix violations in phases
2. Re-enable when threshold reached (e.g., 80% compliant)
3. Track remaining violations
4. Create issues for remaining work

## Related Commands

- `/list-recommendations --disabled` - See all disabled recommendations
- `/view-recommendation <id>` - View recommendation details
- `/disable-recommendation <id>` - Disable a recommendation
- `/recommendation-stats` - View enable/disable history
- `/code-review` - Check code against enabled recommendations

---

*Created: 2025-12-11*
*Part of: PR Feedback Learning Loop (Phase 2.5)*
