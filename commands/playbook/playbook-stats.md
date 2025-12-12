---
name: playbook-stats
description: View playbook usage statistics and effectiveness metrics
---

# Playbook Statistics Command

Analyze agent-playbook.yaml usage patterns, rule effectiveness, and adoption metrics to understand which rules are being applied, which are being violated, and overall playbook health.

## Usage

```
/playbook-stats                          # Show all statistics
/playbook-stats --layer backend          # Show backend layer stats only
/playbook-stats --type guardrails        # Show guardrails stats only
/playbook-stats --source pr-feedback     # Show PR feedback rules only
/playbook-stats --sort effectiveness     # Sort by effectiveness
/playbook-stats --period 30d             # Stats for last 30 days
```

## Purpose

Track and visualize:
- Rule application frequency
- Effectiveness ratings
- False positive rates
- Source distribution (architecture-review vs pr-feedback)
- Confidence level distribution
- Adoption trends over time
- Most/least triggered rules

## Implementation

### Step 1: Parse Arguments

```bash
file=".claude/agent-playbook.yaml"
layer=""
type=""
source=""
sort="timesTriggered"
period="all"

while [ $# -gt 0 ]; do
  case "$1" in
    --file)
      file="$2"
      shift 2
      ;;
    --layer)
      layer="$2"
      shift 2
      ;;
    --type)
      type="$2"
      shift 2
      ;;
    --source)
      source="$2"
      shift 2
      ;;
    --sort)
      sort="$2"
      shift 2
      ;;
    --period)
      period="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown argument: $1"
      exit 1
      ;;
  esac
done
```

### Step 2: Load Playbook

```bash
if [ ! -f "$file" ]; then
  echo "❌ Playbook file not found: $file"
  exit 1
fi

playbook=$(python3 -c "
import yaml, json
with open('$file') as f:
    data = yaml.safe_load(f)
print(json.dumps(data))
")
```

### Step 3: Calculate Overall Statistics

```bash
# Get all rules with metadata
all_rules=$(echo "$playbook" | jq -r '
  [
    (.backend.guardrails[]? | . + {layer: "backend", type: "guardrail"}),
    (.backend.patterns[]? | . + {layer: "backend", type: "pattern"}),
    (.backend.hygiene[]? | . + {layer: "backend", type: "hygiene"}),
    (.frontend.guardrails[]? | . + {layer: "frontend", type: "guardrail"}),
    (.frontend.patterns[]? | . + {layer: "frontend", type: "pattern"}),
    (.frontend.hygiene[]? | . + {layer: "frontend", type: "hygiene"}),
    (.data.guardrails[]? | . + {layer: "data", type: "guardrail"}),
    (.data.patterns[]? | . + {layer: "data", type: "pattern"}),
    (.data.hygiene[]? | . + {layer: "data", type: "hygiene"}),
    (.improvementGuidelines.leverage[]? | . + {layer: "improvement", type: "leverage"}),
    (.improvementGuidelines.experiments[]? | . + {layer: "improvement", type: "experiment"})
  ] | .[]
')

# Total counts
total_rules=$(echo "$all_rules" | jq -s 'length')
total_guardrails=$(echo "$all_rules" | jq -s '[.[] | select(.type == "guardrail")] | length')
total_patterns=$(echo "$all_rules" | jq -s '[.[] | select(.type == "pattern")] | length')
total_hygiene=$(echo "$all_rules" | jq -s '[.[] | select(.type == "hygiene")] | length')
total_leverage=$(echo "$all_rules" | jq -s '[.[] | select(.type == "leverage")] | length')

# Source distribution
from_architecture=$(echo "$all_rules" | jq -s '[.[] | select(.source == "architecture-review")] | length')
from_pr_feedback=$(echo "$all_rules" | jq -s '[.[] | select(.source == "pr-feedback")] | length')

# Confidence distribution
high_confidence=$(echo "$all_rules" | jq -s '[.[] | select(.confidence == "high")] | length')
medium_confidence=$(echo "$all_rules" | jq -s '[.[] | select(.confidence == "medium")] | length')
low_confidence=$(echo "$all_rules" | jq -s '[.[] | select(.confidence == "low")] | length')

# Usage statistics
total_triggered=$(echo "$all_rules" | jq -s '[.[].metadata.timesTriggered // 0] | add')
total_false_positives=$(echo "$all_rules" | jq -s '[.[].metadata.falsePositives // 0] | add')

# Average effectiveness
avg_effectiveness=$(echo "$all_rules" | jq -s '
  [.[].metadata.effectiveness // 0] |
  if length > 0 then (add / length) else 0 end
')

# Rules with usage
rules_with_usage=$(echo "$all_rules" | jq -s '[.[] | select(.metadata.timesTriggered > 0)] | length')

# Recently active rules (last 7 days)
seven_days_ago=$(date -d '7 days ago' -u +"%Y-%m-%dT%H:%M:%SZ")
recently_active=$(echo "$all_rules" | jq -s --arg date "$seven_days_ago" '
  [.[] | select(.metadata.lastTriggered != null and .metadata.lastTriggered > $date)] | length
')
```

### Step 4: Apply Filters

```bash
filtered_rules="$all_rules"

if [ -n "$layer" ]; then
  filtered_rules=$(echo "$filtered_rules" | jq -s --arg layer "$layer" '[.[] | select(.layer == $layer)] | .[]')
fi

if [ -n "$type" ]; then
  filtered_rules=$(echo "$filtered_rules" | jq -s --arg type "$type" '[.[] | select(.type == $type)] | .[]')
fi

if [ -n "$source" ]; then
  filtered_rules=$(echo "$filtered_rules" | jq -s --arg source "$source" '[.[] | select(.source == $source)] | .[]')
fi

# Period filtering
if [ "$period" != "all" ]; then
  # Parse period (e.g., "30d", "7d", "90d")
  days=$(echo "$period" | sed 's/d$//')
  cutoff_date=$(date -d "$days days ago" -u +"%Y-%m-%dT%H:%M:%SZ")

  filtered_rules=$(echo "$filtered_rules" | jq -s --arg date "$cutoff_date" '
    [.[] | select(
      .metadata.lastTriggered == null or
      .metadata.lastTriggered > $date
    )] | .[]
  ')
fi
```

### Step 5: Sort Results

```bash
sorted_rules=$(echo "$filtered_rules" | jq -s --arg sort "$sort" '
  if $sort == "timesTriggered" then
    sort_by(-.metadata.timesTriggered // 0)
  elif $sort == "effectiveness" then
    sort_by(-.metadata.effectiveness // 0)
  elif $sort == "falsePositives" then
    sort_by(-.metadata.falsePositives // 0)
  elif $sort == "lastTriggered" then
    sort_by(-.metadata.lastTriggered // "")
  else
    .
  end
')
```

### Step 6: Generate Statistics Report

```
📊 Agent Playbook Statistics

File: .claude/agent-playbook.yaml
Generated: 2025-12-11 15:45:00
Period: All time

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📈 OVERVIEW
────────────────────────────────────────────────────────
Total Rules: 24
  • Guardrails: 9 (37%)
  • Patterns: 6 (25%)
  • Hygiene: 7 (29%)
  • Leverage: 2 (8%)

Rules with Usage: 18/24 (75%)
Recently Active (7d): 12 rules

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 SOURCE DISTRIBUTION
────────────────────────────────────────────────────────
Architecture Review: 16 rules (67%)
PR Feedback: 8 rules (33%)

Source Breakdown by Type:
  Guardrails:
    • Architecture Review: 4 (44%)
    • PR Feedback: 5 (56%)
  Patterns:
    • Architecture Review: 5 (83%)
    • PR Feedback: 1 (17%)
  Hygiene:
    • Architecture Review: 4 (57%)
    • PR Feedback: 3 (43%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 CONFIDENCE LEVELS
────────────────────────────────────────────────────────
High Confidence: 18 rules (75%)
Medium Confidence: 4 rules (17%)
Low Confidence: 2 rules (8%)

Confidence by Source:
  Architecture Review:
    • High: 14 (88%)
    • Medium: 2 (12%)
  PR Feedback:
    • High: 4 (50%)
    • Medium: 2 (25%)
    • Low: 2 (25%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔥 USAGE STATISTICS
────────────────────────────────────────────────────────
Total Triggers: 95
Total False Positives: 7 (7.4%)
Average Effectiveness: 0.84 (84%)

Usage by Type:
  • Guardrails: 35 triggers (37%)
  • Patterns: 41 triggers (43%)
  • Hygiene: 15 triggers (16%)
  • Leverage: 4 triggers (4%)

Usage by Layer:
  • Backend: 58 triggers (61%)
  • Frontend: 25 triggers (26%)
  • Data: 12 triggers (13%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏆 TOP RULES (by triggers)
────────────────────────────────────────────────────────

1. BE-P01: Command/Query Handler
   Triggered: 20 times
   False Positives: 0
   Effectiveness: 88%
   Last Used: 2025-12-01 10:00

2. FE-H01: Extract UI components
   Triggered: 15 times
   False Positives: 3
   Effectiveness: 70%
   Last Used: 2025-12-01 09:00

3. BE-H01: Move mixed concerns
   Triggered: 12 times
   False Positives: 1
   Effectiveness: 80%
   Last Used: 2025-12-05 11:00

4. FE-P01: Feature Page with Data Fetching
   Triggered: 10 times
   False Positives: 0
   Effectiveness: 85%
   Last Used: 2025-11-30 15:00

5. DB-P01: Add New Entity
   Triggered: 8 times
   False Positives: 0
   Effectiveness: 92%
   Last Used: 2025-12-03 12:00

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  UNDERUTILIZED RULES (0 triggers)
────────────────────────────────────────────────────────

1. BE-G01: Controllers must not reference Infrastructure
   Created: 2025-01-01
   Confidence: High
   Reason: Never violated (good!)

2. DB-G01: New tables via EF migrations
   Created: 2024-11-01
   Confidence: High
   Reason: No new tables recently

3. FE-G01: New screens in feature folders
   Created: 2024-11-01
   Confidence: High
   Reason: No new features recently

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎭 EFFECTIVENESS ANALYSIS
────────────────────────────────────────────────────────

High Performers (>90% effectiveness):
  • DB-G05: Migration type matching (100%)
  • BE-G06: No logging sensitive data (100%)
  • BE-H04: DI lifetime checks (95%)
  • DB-G01: EF Core migrations (95%)

Medium Performers (70-90%):
  • BE-P01: Command/Query Handler (88%)
  • IMP-L03: Filter at database level (88%)
  • FE-P01: Feature Page pattern (85%)
  • BE-H01: Move mixed concerns (80%)

Low Performers (<70%):
  • IMP-L01: Adopt new patterns (65%)
  • BE-H05: XML documentation (60%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 PR FEEDBACK INSIGHTS
────────────────────────────────────────────────────────

Total PR Sources: 8 unique PRs
Top Contributing Reviewers:
  1. Ali Bijanfar: 5 rules (63%)
  2. Security Team: 1 rule (12%)
  3. Performance Review: 1 rule (12%)
  4. Code Review Bot: 1 rule (12%)

PR Feedback Rule Performance:
  • Average Effectiveness: 0.86 (86%)
  • Average Triggers: 4.6 per rule
  • False Positive Rate: 6.5%

Most Recent PR Feedback:
  • BE-G05: Domain entities purity (PR #1045)
    Date: 2025-01-15
    Triggers: 5
    Effectiveness: 92%

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 TIMELINE ANALYSIS
────────────────────────────────────────────────────────

Activity Last 7 Days:
  • Rules Triggered: 12
  • Total Triggers: 28
  • New Rules Added: 0

Activity Last 30 Days:
  • Rules Triggered: 18
  • Total Triggers: 67
  • New Rules Added: 3

Activity Last 90 Days:
  • Rules Triggered: 22
  • Total Triggers: 95
  • New Rules Added: 8

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 RECOMMENDATIONS
────────────────────────────────────────────────────────

1. Review Low Performers
   • BE-H05 (60% effectiveness) - Consider revising or removing
   • IMP-L01 (65% effectiveness) - May need clearer trigger conditions

2. Promote High Performers
   • DB-G05 and BE-G06 have 100% effectiveness
   • Consider making them templates for new rules

3. Address Underutilized Rules
   • 6 rules never triggered
   • Verify they're still relevant or update conditions

4. PR Feedback Success
   • PR feedback rules performing well (86% avg effectiveness)
   • Continue extracting patterns from code reviews

5. False Positive Investigation
   • FE-H01 has 20% false positive rate
   • Review and refine trigger conditions

Next Steps:
  • Run /check-playbook-conflicts to detect rule conflicts
  • Use /validate-playbook to ensure schema compliance
  • Review underutilized rules for relevance
```

## Detailed Rule View

When viewing specific layer or type:

```
📊 Backend Guardrails Statistics

Total: 4 guardrails
Active: 3 (75%)
Average Effectiveness: 0.92

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Detailed Breakdown:
────────────────────────────────────────────────────────

BE-G01: Controllers must not reference Infrastructure
  Source: architecture-review
  Confidence: high
  Triggers: 0
  False Positives: 0
  Effectiveness: 95%
  Status: Never violated ✓

BE-G05: Domain entities must not reference Infrastructure
  Source: pr-feedback (PR #1045, Ali Bijanfar)
  Confidence: high
  Triggers: 5
  False Positives: 0
  Effectiveness: 92%
  Last Triggered: 2025-12-10 14:30
  Status: Active ✓

BE-G06: Avoid logging sensitive data
  Source: pr-feedback (PR #1047, Security Team)
  Confidence: high
  Triggers: 2
  False Positives: 0
  Effectiveness: 100%
  Last Triggered: 2025-11-15 09:00
  Status: Active ✓
```

## Export Options

### JSON Export

```bash
/playbook-stats --format json > playbook-stats.json
```

Generates machine-readable statistics:

```json
{
  "generated": "2025-12-11T15:45:00Z",
  "period": "all",
  "summary": {
    "totalRules": 24,
    "rulesByType": {
      "guardrails": 9,
      "patterns": 6,
      "hygiene": 7,
      "leverage": 2
    },
    "rulesWithUsage": 18,
    "recentlyActive": 12
  },
  "usage": {
    "totalTriggers": 95,
    "totalFalsePositives": 7,
    "falsePositiveRate": 0.074,
    "avgEffectiveness": 0.84
  },
  "topRules": [
    {
      "id": "BE-P01",
      "name": "Command/Query Handler",
      "triggers": 20,
      "effectiveness": 0.88
    }
  ],
  "recommendations": [
    "Review low performers",
    "Promote high performers",
    "Address underutilized rules"
  ]
}
```

### CSV Export

```bash
/playbook-stats --format csv > playbook-stats.csv
```

Generates spreadsheet-compatible data:

```csv
id,type,layer,source,confidence,triggers,falsePositives,effectiveness,lastTriggered
BE-G01,guardrail,backend,architecture-review,high,0,0,0.95,
BE-G05,guardrail,backend,pr-feedback,high,5,0,0.92,2025-12-10T14:30:00Z
BE-P01,pattern,backend,architecture-review,high,20,0,0.88,2025-12-01T10:00:00Z
```

## Integration

### With /extract-review-patterns

View effectiveness of newly added rules:

```bash
> /extract-review-patterns <pr-url>
> /playbook-stats --source pr-feedback --period 7d
```

### With /validate-playbook

Validate then view statistics:

```bash
> /validate-playbook
> /playbook-stats
```

### With /deliver

Track rule application during delivery:

```bash
> /deliver WI-12345
> /playbook-stats --period 1d
```

## Filtering Examples

### Backend rules only
```
/playbook-stats --layer backend
```

### PR feedback guardrails
```
/playbook-stats --type guardrails --source pr-feedback
```

### Recently active rules
```
/playbook-stats --period 7d
```

### Sort by effectiveness
```
/playbook-stats --sort effectiveness
```

### Low confidence rules
```bash
# Show rules that need review
echo "$all_rules" | jq -s '[.[] | select(.confidence == "low")]'
```

## Related Commands

- `/validate-playbook` - Validate playbook schema
- `/check-playbook-conflicts` - Detect rule conflicts
- `/extract-review-patterns` - Add new rules from PR feedback

---

*Created: 2025-12-11*
*Part of: PR Feedback Learning Loop (Phase 3.4)*
