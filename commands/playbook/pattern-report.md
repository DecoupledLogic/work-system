---
name: pattern-report
description: Generate pattern effectiveness dashboard showing usage statistics and health metrics
---

# Pattern Report Command

Analyzes code review pattern effectiveness, generates comprehensive dashboard with usage statistics, false positive rates, time savings, and recommendations for pattern library improvements.

## Usage

```bash
/pattern-report                      # Full report for all patterns
/pattern-report --period 30d         # Last 30 days only
/pattern-report --category DI        # Filter by category
/pattern-report --priority High      # Filter by priority
/pattern-report --format json        # JSON output for automation
/pattern-report --output report.md   # Save to file
```

## Purpose

Provide visibility into:
- Pattern detection effectiveness
- False positive rates
- Time savings from early detection
- Patterns needing refinement
- Unused or outdated patterns
- Overall pattern library health

## Implementation

### Step 1: Parse Arguments

```bash
period="all"
category=""
priority=""
output_format="text"
output_file=""

while [ $# -gt 0 ]; do
  case "$1" in
    --period)
      period="$2"
      shift 2
      ;;
    --category)
      category="$2"
      shift 2
      ;;
    --priority)
      priority="$2"
      shift 2
      ;;
    --format)
      output_format="$2"
      shift 2
      ;;
    --output)
      output_file="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown argument: $1"
      exit 1
      ;;
  esac
done
```

### Step 2: Load Patterns and History

```bash
patterns_file="code-review-patterns.yaml"
history_log=".claude/history/pattern-detections.jsonl"

if [ ! -f "$patterns_file" ]; then
  echo "❌ Patterns file not found: $patterns_file"
  exit 1
fi

# Load patterns
patterns=$(python3 -c "
import yaml, json
with open('$patterns_file') as f:
    data = yaml.safe_load(f)
print(json.dumps(data))
")

# Load detection history if exists
if [ -f "$history_log" ]; then
  detection_history=$(cat "$history_log")
else
  detection_history=""
fi
```

### Step 3: Calculate Statistics

```bash
stats=$(python3 << 'EOF'
import json
import sys
from datetime import datetime, timedelta
from collections import defaultdict

patterns_data = json.loads('''$patterns''')
patterns = patterns_data.get('patterns', [])

# Filter by period
period = "$period"
cutoff_date = None
if period != "all" and period.endswith('d'):
    days = int(period[:-1])
    cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

# Apply filters
filtered_patterns = patterns
if "$category":
    filtered_patterns = [p for p in filtered_patterns if p.get('category') == "$category"]
if "$priority":
    filtered_patterns = [p for p in filtered_patterns if p.get('priority') == "$priority"]

# Calculate aggregate statistics
total_patterns = len(filtered_patterns)
total_detections = sum(p.get('metadata', {}).get('timesDetected', 0) for p in filtered_patterns)
total_false_positives = sum(p.get('metadata', {}).get('falsePositives', 0) for p in filtered_patterns)
patterns_with_detections = len([p for p in filtered_patterns if p.get('metadata', {}).get('timesDetected', 0) > 0])

# Overall false positive rate
overall_fp_rate = total_false_positives / total_detections if total_detections > 0 else 0

# Calculate time saved
total_time_saved_minutes = 0
for pattern in filtered_patterns:
    metadata = pattern.get('metadata', {})
    total_saved = metadata.get('totalTimeSaved', '')
    if total_saved:
        if 'hour' in total_saved:
            hours = float(total_saved.split()[0])
            total_time_saved_minutes += hours * 60
        elif 'minute' in total_saved:
            minutes = int(total_saved.split()[0])
            total_time_saved_minutes += minutes

# Top patterns by detection
top_patterns = sorted(
    filtered_patterns,
    key=lambda p: p.get('metadata', {}).get('timesDetected', 0),
    reverse=True
)[:10]

# Patterns needing review (high false positive rate)
patterns_needing_review = [
    p for p in filtered_patterns
    if p.get('metadata', {}).get('falsePositiveRate', 0) > 0.20 and
       p.get('metadata', {}).get('timesDetected', 0) > 5
]

# Unused patterns (no detections in period)
unused_patterns = [
    p for p in filtered_patterns
    if p.get('metadata', {}).get('timesDetected', 0) == 0
]

# Recently inactive patterns
days_threshold = 60
recently_inactive = []
for p in filtered_patterns:
    last_detected = p.get('metadata', {}).get('lastDetected')
    if last_detected:
        days_since = (datetime.now() - datetime.fromisoformat(last_detected.replace('Z', '+00:00'))).days
        if days_since > days_threshold:
            recently_inactive.append({
                'pattern': p,
                'daysSince': days_since
            })

# Calculate library health score
health_score = 0
if total_patterns > 0:
    # Factor 1: Active patterns (40%)
    active_ratio = patterns_with_detections / total_patterns
    health_score += active_ratio * 40

    # Factor 2: Low false positive rate (40%)
    fp_quality = max(0, 1 - overall_fp_rate)
    health_score += fp_quality * 40

    # Factor 3: Recent usage (20%)
    recently_used = len([p for p in filtered_patterns
                         if p.get('metadata', {}).get('lastDetected') and
                         (datetime.now() - datetime.fromisoformat(p.get('metadata', {}).get('lastDetected').replace('Z', '+00:00'))).days < 30])
    recent_ratio = recently_used / total_patterns
    health_score += recent_ratio * 20

# Category breakdown
category_stats = defaultdict(lambda: {'count': 0, 'detections': 0})
for p in filtered_patterns:
    cat = p.get('category', 'Unknown')
    category_stats[cat]['count'] += 1
    category_stats[cat]['detections'] += p.get('metadata', {}).get('timesDetected', 0)

result = {
    'total_patterns': total_patterns,
    'total_detections': total_detections,
    'total_false_positives': total_false_positives,
    'patterns_with_detections': patterns_with_detections,
    'overall_fp_rate': overall_fp_rate,
    'total_time_saved_hours': total_time_saved_minutes / 60,
    'top_patterns': [
        {
            'id': p['id'],
            'title': p['title'],
            'detections': p.get('metadata', {}).get('timesDetected', 0),
            'fpRate': p.get('metadata', {}).get('falsePositiveRate', 0),
            'timeSaved': p.get('metadata', {}).get('totalTimeSaved', 'N/A')
        }
        for p in top_patterns
    ],
    'patterns_needing_review': [
        {
            'id': p['id'],
            'title': p['title'],
            'fpRate': p.get('metadata', {}).get('falsePositiveRate', 0),
            'detections': p.get('metadata', {}).get('timesDetected', 0)
        }
        for p in patterns_needing_review
    ],
    'unused_patterns': [
        {
            'id': p['id'],
            'title': p['title'],
            'created': p.get('metadata', {}).get('created', 'Unknown')
        }
        for p in unused_patterns
    ],
    'recently_inactive': [
        {
            'id': item['pattern']['id'],
            'title': item['pattern']['title'],
            'daysSince': item['daysSince']
        }
        for item in recently_inactive
    ],
    'health_score': health_score,
    'category_stats': dict(category_stats)
}

print(json.dumps(result, indent=2))
EOF
)
```

### Step 4: Generate Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pattern Effectiveness Report
Generated: 2025-12-11 16:00:00
Period: Last 30 days
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 OVERVIEW
────────────────────────────────────────────────────────
Total Patterns: 24
Active Patterns: 18 (75%)
Total Detections: 156
Total False Positives: 12 (7.7%)

Time Saved: 13.2 hours
Issues Caught Before PR: 156
Estimated Review Time Saved: 26.0 hours
  (Assumes 10 minutes average discussion per issue)

Pattern Library Health: ████████░░ 82%

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏆 TOP PATTERNS BY DETECTION
────────────────────────────────────────────────────────

1. DI-LIFETIME-001: Use Transient for stateless services
   Detections: 23 | FP Rate: 8.7% | Time Saved: 115 min
   Effectiveness: ████████░░ 91%

2. VENDOR-DECOUPLING-001: Keep vendor names out of Abstractions
   Detections: 18 | FP Rate: 5.6% | Time Saved: 180 min
   Effectiveness: █████████░ 94%

3. ARCH-LAYER-001: Controllers must not reference Infrastructure
   Detections: 15 | FP Rate: 0.0% | Time Saved: 75 min
   Effectiveness: ██████████ 100%

4. SEC-LOGGING-001: Do not log sensitive data
   Detections: 12 | FP Rate: 0.0% | Time Saved: 60 min
   Effectiveness: ██████████ 100%

5. PERF-QUERY-001: Use async database operations
   Detections: 10 | FP Rate: 10.0% | Time Saved: 50 min
   Effectiveness: █████████░ 90%

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  PATTERNS NEEDING REVIEW (High False Positive)
────────────────────────────────────────────────────────

1. PERF-QUERY-002: Filter data at database level
   FP Rate: 45.5% (5/11 detections)
   Issue: Overly broad regex matches valid in-memory operations
   Recommendation: Refine detection pattern to exclude LINQ operations
                   on already-loaded collections

2. CONV-NAMING-001: Use plural names for collections
   FP Rate: 33.3% (2/6 detections)
   Issue: Flags valid singular names in specific contexts
   Recommendation: Add context validation to check if name is appropriate

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 RECENTLY INACTIVE PATTERNS (Last 60+ days)
────────────────────────────────────────────────────────

1. TEST-COVERAGE-001: Ensure critical paths have tests
   Last Detected: 87 days ago
   Recommendation: Review if pattern is still relevant or update detection

2. DOC-COMMENTS-001: Add XML comments to public APIs
   Last Detected: 72 days ago
   Recommendation: Consider moving to hygiene rules in playbook

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ UNUSED PATTERNS (Never Detected)
────────────────────────────────────────────────────────

1. ERROR-HANDLING-003: Use Result pattern for failures
   Created: 2025-10-15
   Age: 57 days
   Recommendation: Archive or update detection logic

2. ASYNC-VOID-001: Avoid async void methods
   Created: 2025-09-20
   Age: 82 days
   Recommendation: Verify pattern is working correctly

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📈 CATEGORY BREAKDOWN
────────────────────────────────────────────────────────

DependencyInjection:     6 patterns | 45 detections
Architecture:            5 patterns | 38 detections
Security:                4 patterns | 25 detections
Performance:             3 patterns | 18 detections
Testing:                 2 patterns | 12 detections
Conventions:             2 patterns |  8 detections
Documentation:           2 patterns | 10 detections

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 RECOMMENDATIONS
────────────────────────────────────────────────────────

HIGH PRIORITY:

1. Refine High False Positive Patterns
   • PERF-QUERY-002 (45.5% FP rate)
   • CONV-NAMING-001 (33.3% FP rate)
   → Use /pattern-evolve to get refinement suggestions

2. Review Inactive Patterns
   • 2 patterns not detected in 60+ days
   → Consider archiving or updating detection logic

3. Investigate Unused Patterns
   • 2 patterns never detected
   → Verify they're working or remove them

MEDIUM PRIORITY:

4. Promote High-Value Patterns
   • ARCH-LAYER-001 (100% effectiveness, 15 detections)
   • SEC-LOGGING-001 (100% effectiveness, 12 detections)
   → Consider adding to agent-playbook.yaml as guardrails

5. Expand Successful Categories
   • DependencyInjection: High detection rate, low FP
   → Review recent PRs for more DI patterns

LOW PRIORITY:

6. Update Documentation
   • Add examples from actual detections to pattern definitions
   • Document common false positive scenarios

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 NEXT ACTIONS
────────────────────────────────────────────────────────

Run these commands to improve pattern library:

  # Get detailed evolution suggestions
  /pattern-evolve

  # Review and refine specific patterns
  /view-recommendation PERF-QUERY-002

  # Archive unused patterns
  /archive-pattern ERROR-HANDLING-003 --reason "Never detected, no longer relevant"

  # Promote effective patterns to playbook
  /promote-to-playbook ARCH-LAYER-001 --type guardrail
```

## JSON Output Format

For automation and integration:

```bash
/pattern-report --format json
```

```json
{
  "generated": "2025-12-11T16:00:00Z",
  "period": "30d",
  "summary": {
    "totalPatterns": 24,
    "activePatterns": 18,
    "totalDetections": 156,
    "totalFalsePositives": 12,
    "overallFpRate": 0.077,
    "timeSavedHours": 13.2,
    "healthScore": 82
  },
  "topPatterns": [
    {
      "id": "DI-LIFETIME-001",
      "title": "Use Transient for stateless services",
      "detections": 23,
      "fpRate": 0.087,
      "timeSaved": "115 minutes",
      "effectiveness": 0.91
    }
  ],
  "patternsNeedingReview": [
    {
      "id": "PERF-QUERY-002",
      "title": "Filter data at database level",
      "fpRate": 0.455,
      "detections": 11,
      "recommendation": "Refine detection pattern"
    }
  ],
  "unusedPatterns": [...],
  "recentlyInactive": [...],
  "categoryStats": {...},
  "recommendations": [...]
}
```

## Integration

### With Pattern Evolution Engine

Generate evolution suggestions based on report:

```bash
/pattern-report --format json | jq '.patternsNeedingReview' | /pattern-evolve --input -
```

### With CI/CD

Fail builds if pattern health drops below threshold:

```bash
health_score=$(/pattern-report --format json | jq '.summary.healthScore')
if [ "$health_score" -lt 70 ]; then
  echo "❌ Pattern library health below 70%: $health_score%"
  exit 1
fi
```

### Scheduled Reporting

Weekly pattern health email:

```bash
# In cron job or GitHub Actions
/pattern-report --period 7d --output weekly-pattern-report.md
# Send report via email or Slack
```

## Related Commands

- `/track-pattern-detection` - Record pattern detections
- `/pattern-evolve` - Get refinement suggestions (Phase 4.3)
- `/playbook-stats` - Playbook statistics
- `/code-review` - Run code review with pattern detection

---

*Created: 2025-12-11*
*Part of: PR Feedback Learning Loop (Phase 4.2)*
