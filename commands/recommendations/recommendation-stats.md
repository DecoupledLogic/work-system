---
name: recommendation-stats
description: View usage statistics and analytics for architecture recommendations
---

# Recommendation Stats Command

Display comprehensive statistics and analytics about architecture recommendations including usage frequency, violation rates, disable history, and effectiveness metrics.

## Usage

```
/recommendation-stats                    # All recommendations summary
/recommendation-stats ARCH-G001          # Specific recommendation stats
/recommendation-stats --type guardrails  # Stats by type
/recommendation-stats --period 30d       # Last 30 days
/recommendation-stats --format json      # JSON output
```

## Metrics Tracked

| Metric Category | Description | Applies To |
|----------------|-------------|------------|
| **Enforcement** | Times checked, violations found, PR blocks | Guardrails |
| **Adoption** | Times suggested, times applied, adoption rate | Leverage |
| **Application** | Times triggered, times applied, skip rate | Hygiene |
| **Lifecycle** | Created, disabled periods, modifications | All |

## Implementation

### Step 1: Parse Arguments

Extract recommendation ID and options:

```bash
id=""
type=""
period="30d"  # Default to last 30 days
format="text"  # text or json

# Parse arguments
while [ $# -gt 0 ]; do
  case "$1" in
    ARCH-*)
      id="$1"
      shift
      ;;
    --type)
      type="$2"
      shift 2
      ;;
    --period)
      period="$2"
      shift 2
      ;;
    --format)
      format="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown argument: $1"
      exit 1
      ;;
  esac
done
```

### Step 2: Load Data Sources

Load recommendations and history:

```bash
# Load recommendations file
if [ ! -f "architecture-recommendations.json" ]; then
  echo "❌ No architecture-recommendations.json found"
  exit 1
fi

recommendations=$(cat architecture-recommendations.json)

# Load history log
history_file=".claude/history/recommendations-history.jsonl"
if [ -f "$history_file" ]; then
  history=$(cat "$history_file")
else
  history=""
  echo "ℹ️  No history log found. Stats will be limited."
fi

# Load code-review logs (if available)
review_logs_dir=".claude/logs/code-review"
if [ -d "$review_logs_dir" ]; then
  review_logs=$(find "$review_logs_dir" -name "*.json" -mtime -$period)
else
  review_logs=""
fi
```

### Step 3: Calculate Period

Parse period argument and determine date range:

```bash
# Parse period (e.g., "30d", "7d", "90d")
period_days=$(echo "$period" | sed 's/d$//')

if ! [[ "$period_days" =~ ^[0-9]+$ ]]; then
  echo "❌ Invalid period format: $period"
  echo "Use format: 30d, 7d, 90d, etc."
  exit 1
fi

# Calculate start date
start_date=$(date -d "$period_days days ago" +"%Y-%m-%d")
end_date=$(date +"%Y-%m-%d")

echo "📊 Statistics Period: $start_date to $end_date ($period_days days)"
echo ""
```

### Step 4: Compute Statistics

#### Overall Summary Stats

```bash
total_guardrails=$(echo "$recommendations" | jq '.recommendations.guardrails | length')
total_leverage=$(echo "$recommendations" | jq '.recommendations.leverage | length')
total_hygiene=$(echo "$recommendations" | jq '.recommendations.hygiene | length')
total_all=$((total_guardrails + total_leverage + total_hygiene))

enabled_guardrails=$(echo "$recommendations" | jq '[.recommendations.guardrails[] | select(.disabled != true)] | length')
enabled_leverage=$(echo "$recommendations" | jq '[.recommendations.leverage[] | select(.disabled != true)] | length')
enabled_hygiene=$(echo "$recommendations" | jq '[.recommendations.hygiene[] | select(.disabled != true)] | length')
enabled_all=$((enabled_guardrails + enabled_leverage + enabled_hygiene))

disabled_count=$((total_all - enabled_all))
```

#### Guardrail Stats

```bash
# Count critical, high, medium priorities
critical_count=$(echo "$recommendations" | jq '[.recommendations.guardrails[] | select(.priority == "Critical")] | length')
high_count=$(echo "$recommendations" | jq '[.recommendations.guardrails[] | select(.priority == "High")] | length')
medium_count=$(echo "$recommendations" | jq '[.recommendations.guardrails[] | select(.priority == "Medium")] | length')

# Calculate violation rates from code-review logs
if [ -n "$review_logs" ]; then
  total_reviews=$(echo "$review_logs" | wc -l)
  total_violations=$(grep -h "violation" $review_logs 2>/dev/null | wc -l || echo "0")

  if [ "$total_reviews" -gt 0 ]; then
    violation_rate=$(echo "scale=1; $total_violations / $total_reviews" | bc)
  else
    violation_rate="0"
  fi
else
  total_reviews="N/A"
  total_violations="N/A"
  violation_rate="N/A"
fi
```

#### History Stats

```bash
if [ -n "$history" ]; then
  # Count events by type
  disable_events=$(echo "$history" | jq -s --arg start "$start_date" \
    '[.[] | select(.event == "disable" and .timestamp >= $start)] | length')

  enable_events=$(echo "$history" | jq -s --arg start "$start_date" \
    '[.[] | select(.event == "enable" and .timestamp >= $start)] | length')

  # Calculate average disable duration
  avg_disable_duration=$(echo "$history" | jq -s \
    '[.[] | select(.event == "enable" and .disableDuration) |
     .disableDuration | rtrimstr("d") | tonumber] |
     if length > 0 then (add / length) else 0 end')
else
  disable_events="0"
  enable_events="0"
  avg_disable_duration="0"
fi
```

### Step 5: Display Statistics

#### Summary View (no ID specified)

```
📊 Architecture Recommendations Statistics
Period: 2025-11-11 to 2025-12-11 (30 days)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📈 OVERVIEW
────────────────────────────────────────────────────────
Total Recommendations: 9
  • Guardrails: 3 (2 Critical, 1 High)
  • Leverage: 3
  • Hygiene: 3

Status:
  • ✓ Enabled: 8 (89%)
  • ✗ Disabled: 1 (11%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📌 GUARDRAILS (Critical Rules)
────────────────────────────────────────────────────────
Code Reviews Run: 15
Violations Found: 8
Violation Rate: 0.5 per review
Blocked PRs: 3

Top Violations:
  1. ARCH-G001: Domain layer references (5 times)
  2. ARCH-G002: Sensitive data logged (2 times)
  3. ARCH-G003: Type mismatches (1 time)

Effectiveness: 🟢 High (preventing 0.5 violations/review)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 LEVERAGE PATTERNS (Suggested Improvements)
────────────────────────────────────────────────────────
Times Suggested: 12
Times Applied: 7
Adoption Rate: 58%

Most Applied:
  1. ARCH-L002: Database filtering (4 times)
  2. ARCH-L003: DI lifetime checks (2 times)
  3. ARCH-L001: Vendor extraction (1 time)

Effectiveness: 🟡 Medium (58% adoption when suggested)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🧹 HYGIENE RULES (Quality Practices)
────────────────────────────────────────────────────────
Times Triggered: 25
Times Applied: 20
Application Rate: 80%

Most Applied:
  1. ARCH-H003: Test for bug fixes (12 times)
  2. ARCH-H001: XML comments (5 times)
  3. ARCH-H002: Audit fields (3 times)

Effectiveness: 🟢 High (80% application when triggered)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 LIFECYCLE
────────────────────────────────────────────────────────
Disable Events: 2
Enable Events: 1
Average Disable Duration: 10 days

Currently Disabled:
  • ARCH-G002 (5 days) - Legacy migration

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 INSIGHTS
────────────────────────────────────────────────────────
✅ Strengths:
  • High hygiene rule adoption (80%)
  • Effective violation prevention (0.5/review)
  • Low average disable duration (10d)

⚠️  Areas for Improvement:
  • ARCH-G001 has recurring violations (5 times)
  • Leverage pattern adoption could be higher (58%)
  • 1 guardrail disabled for 5+ days

📊 Recommendations:
  • Review ARCH-G001 violations - may need better docs
  • Promote ARCH-L001 adoption - only 1 application
  • Re-enable ARCH-G002 or document long-term plan

Use /view-recommendation <id> for detailed analysis
Use /list-recommendations --disabled for disabled list
```

#### Detailed View (specific ID)

```
📊 Recommendation Statistics: ARCH-G001

Period: 2025-11-11 to 2025-12-11 (30 days)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 DETAILS
────────────────────────────────────────────────────────
ID: ARCH-G001
Type: Guardrail
Title: Domain layer must not reference Infrastructure
Category: Architecture
Priority: ⚠️  Critical
Status: ✓ Enabled

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 ENFORCEMENT METRICS
────────────────────────────────────────────────────────
Times Checked: 15 reviews
Violations Found: 5 instances
Violation Rate: 33% (5/15)
PRs Blocked: 2
Average Fix Time: 1.5 hours

Violation Trend:
  Week 1: ██████ 3 violations
  Week 2: ████ 2 violations
  Week 3: ░░░░ 0 violations
  Week 4: ░░░░ 0 violations

📉 Trending down (improvement detected)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 VIOLATION DETAILS
────────────────────────────────────────────────────────
Recent Violations:

1. PR #1047 - Domain/Services/PaymentService.cs
   Date: 2025-12-08
   Fixed: Yes (1h)
   Pattern: using Infrastructure.Persistence

2. PR #1045 - Domain/Entities/User.cs
   Date: 2025-12-05
   Fixed: Yes (2h)
   Pattern: using Infrastructure.ExternalServices

Common Patterns:
  • using Infrastructure.Persistence (60%)
  • using Infrastructure.ExternalServices (40%)

Fix Actions Taken:
  • Extract to Infrastructure layer (3 times)
  • Move to Application layer (2 times)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 LIFECYCLE
────────────────────────────────────────────────────────
Created: 2025-01-15 (from PR #1045 feedback)
Source: Ali Bijanfar review
Total Lifetime: 11 months

Disable History:
  • Never disabled

Last Updated: 2025-11-01
  Change: Added automation check pattern

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 EFFECTIVENESS ANALYSIS
────────────────────────────────────────────────────────
Impact: 🟢 High

✅ Positive Impact:
  • Prevented 5 architecture violations
  • Caught issues in 33% of reviews
  • Clear downward violation trend
  • Average fix time reasonable (1.5h)

⚠️  Areas for Improvement:
  • Recurring patterns suggest need for examples
  • Team may need additional training
  • Consider adding pre-commit hook

📊 Overall Assessment:
This guardrail is EFFECTIVE but shows recurring
violations in similar patterns. Consider:
  1. Add code examples to documentation
  2. Team training on clean architecture
  3. IDE analyzer rule for faster feedback

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 Related Commands
• /view-recommendation ARCH-G001      View full details
• /code-review                        Check current code
• /list-recommendations --type guardrails  See all guardrails
```

### Step 6: JSON Output (if requested)

When `--format json` is used:

```json
{
  "period": {
    "start": "2025-11-11",
    "end": "2025-12-11",
    "days": 30
  },
  "summary": {
    "total": 9,
    "enabled": 8,
    "disabled": 1,
    "byType": {
      "guardrails": 3,
      "leverage": 3,
      "hygiene": 3
    }
  },
  "guardrails": {
    "codeReviewsRun": 15,
    "violationsFound": 8,
    "violationRate": 0.53,
    "blockedPRs": 3,
    "topViolations": [
      {"id": "ARCH-G001", "count": 5},
      {"id": "ARCH-G002", "count": 2},
      {"id": "ARCH-G003", "count": 1}
    ]
  },
  "leverage": {
    "timesSuggested": 12,
    "timesApplied": 7,
    "adoptionRate": 0.58
  },
  "hygiene": {
    "timesTriggered": 25,
    "timesApplied": 20,
    "applicationRate": 0.80
  },
  "lifecycle": {
    "disableEvents": 2,
    "enableEvents": 1,
    "avgDisableDuration": 10
  }
}
```

### Step 7: Generate Insights

Analyze data to provide actionable insights:

```bash
# Detect trends
if [ "$violation_rate" -lt "0.3" ]; then
  insight="🟢 Low violation rate - guardrails working well"
elif [ "$violation_rate" -lt "0.7" ]; then
  insight="🟡 Moderate violations - some areas need attention"
else
  insight="🔴 High violation rate - review effectiveness"
fi

# Check for long-term disables
long_disabled=$(echo "$recommendations" | jq -r --arg start "$start_date" \
  '.recommendations | [.guardrails[], .leverage[], .hygiene[]] |
   .[] | select(.disabled == true and .disabledAt < $start) | .id' |
   wc -l)

if [ "$long_disabled" -gt 0 ]; then
  insight="$insight\n⚠️  $long_disabled recommendation(s) disabled >30 days"
fi

# Check adoption rates
if [ -n "$adoption_rate" ] && [ "$(echo "$adoption_rate < 0.5" | bc)" -eq 1 ]; then
  insight="$insight\n⚠️  Low leverage pattern adoption (<50%)"
fi
```

## Examples

### View overall stats

```
> /recommendation-stats

📊 Architecture Recommendations Statistics
Period: Last 30 days

Total: 9 recommendations (8 enabled, 1 disabled)
...
```

### View stats for specific recommendation

```
> /recommendation-stats ARCH-G001

📊 Recommendation Statistics: ARCH-G001

Violations Found: 5 instances
Violation Rate: 33%
Trending: 📉 Down
...
```

### View stats by type

```
> /recommendation-stats --type guardrails

📊 Guardrails Statistics

Code Reviews: 15
Violations: 8
Violation Rate: 0.5 per review
...
```

### View stats for different period

```
> /recommendation-stats --period 7d

📊 Architecture Recommendations Statistics
Period: Last 7 days

Total Reviews: 4
Violations: 1
...
```

### Export as JSON

```
> /recommendation-stats --format json > stats.json

{
  "period": {...},
  "summary": {...},
  ...
}
```

## Metrics Definitions

| Metric | Definition | Formula |
|--------|-----------|---------|
| **Violation Rate** | Average violations per review | violations / reviews |
| **Adoption Rate** | How often suggested patterns are applied | applied / suggested |
| **Application Rate** | How often triggered hygiene is applied | applied / triggered |
| **Disable Duration** | Average time recommendations stay disabled | sum(durations) / count |

## Effectiveness Indicators

| Rating | Icon | Criteria |
|--------|------|----------|
| High | 🟢 | Violation rate <30% OR adoption >70% |
| Medium | 🟡 | Violation rate 30-70% OR adoption 40-70% |
| Low | 🔴 | Violation rate >70% OR adoption <40% |

## Error Handling

### No history data

```
ℹ️  No history log found

Statistics will be limited to current state.
No usage metrics available.

To enable tracking:
  • History is automatically generated when using:
    - /code-review
    - /design
    - /deliver
  • Manual operations are logged to:
    .claude/history/recommendations-history.jsonl
```

### Invalid period format

```
❌ Invalid period format: 30days

Use format: 30d, 7d, 90d, etc.

Examples:
  --period 7d    Last 7 days
  --period 30d   Last 30 days (default)
  --period 90d   Last 90 days
```

### Recommendation not found

```
❌ Recommendation not found: ARCH-G999

Use /list-recommendations to see all available IDs
```

## Integration

### With /code-review

Stats are updated after each code review:
```
> /code-review
> /recommendation-stats
# See latest violation counts
```

### With /view-recommendation

View stats for specific recommendation:
```
> /view-recommendation ARCH-G001
> /recommendation-stats ARCH-G001
# See detailed usage analytics
```

### With /disable-recommendation

Track disable duration:
```
> /disable-recommendation ARCH-G001
# ... time passes ...
> /enable-recommendation ARCH-G001
> /recommendation-stats ARCH-G001
# Shows disable duration in history
```

### With /list-recommendations

View stats summary before drilling down:
```
> /list-recommendations
> /recommendation-stats
> /recommendation-stats ARCH-G001
```

## Data Sources

Statistics are compiled from:

1. **architecture-recommendations.json** - Current state
2. **.claude/history/recommendations-history.jsonl** - Event log
3. **.claude/logs/code-review/*.json** - Review results
4. **.claude/logs/design/*.json** - Design decisions
5. **Git history** - Commit patterns and PR data

## Performance

For large projects with extensive history:
- Consider using shorter periods (`--period 7d`)
- Export to JSON for analysis (`--format json`)
- Archive old history logs periodically

## Related Commands

- `/list-recommendations` - Browse all recommendations
- `/view-recommendation <id>` - View recommendation details
- `/code-review` - Apply recommendations and generate stats
- `/disable-recommendation <id>` - Disable (tracked in stats)
- `/enable-recommendation <id>` - Re-enable (tracked in stats)

---

*Created: 2025-12-11*
*Part of: PR Feedback Learning Loop (Phase 2.5)*
