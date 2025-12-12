---
name: track-pattern-detection
description: Record pattern detection events and update usage metadata
---

# Track Pattern Detection Command

Records when a code review pattern is detected, updates usage statistics, and maintains detection history for effectiveness analysis.

## Usage

```bash
# Record a detection
/track-pattern-detection --pattern DI-LIFETIME-001 --file ServiceCollectionExtensions.cs --line 42

# Record a false positive
/track-pattern-detection --pattern DI-LIFETIME-001 --false-positive --reason "Service actually has state"

# Record detection with fix time
/track-pattern-detection --pattern VENDOR-DECOUPLING-001 --fixed --duration "5 minutes"

# Batch record multiple detections
/track-pattern-detection --batch detections.json
```

## Purpose

Automatically track pattern usage to:
- Count detection frequency
- Calculate false positive rates
- Measure fix times
- Estimate time saved
- Identify effective patterns
- Find patterns needing refinement

## Implementation

### Step 1: Parse Arguments

```bash
pattern_id=""
file=""
line=""
false_positive=false
fp_reason=""
fixed=false
duration=""
batch_file=""

while [ $# -gt 0 ]; do
  case "$1" in
    --pattern)
      pattern_id="$2"
      shift 2
      ;;
    --file)
      file="$2"
      shift 2
      ;;
    --line)
      line="$2"
      shift 2
      ;;
    --false-positive)
      false_positive=true
      shift
      ;;
    --reason)
      fp_reason="$2"
      shift 2
      ;;
    --fixed)
      fixed=true
      shift
      ;;
    --duration)
      duration="$2"
      shift 2
      ;;
    --batch)
      batch_file="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown argument: $1"
      exit 1
      ;;
  esac
done
```

### Step 2: Load Pattern File

```bash
patterns_file="code-review-patterns.yaml"

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
```

### Step 3: Find Pattern

```bash
pattern=$(echo "$patterns" | jq --arg id "$pattern_id" '
  .patterns[] | select(.id == $id)
')

if [ -z "$pattern" ]; then
  echo "❌ Pattern not found: $pattern_id"
  exit 1
fi
```

### Step 4: Update Metadata

```bash
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

updated_patterns=$(python3 << EOF
import json
import yaml
from datetime import datetime

patterns = json.loads('''$patterns''')
pattern_id = "$pattern_id"
is_false_positive = "$false_positive" == "true"
is_fixed = "$fixed" == "true"
duration = "$duration"

# Find and update the pattern
for pattern in patterns['patterns']:
    if pattern['id'] == pattern_id:
        metadata = pattern.get('metadata', {})

        # Update detection count
        times_detected = metadata.get('timesDetected', 0)
        if not is_false_positive:
            times_detected += 1
            metadata['timesDetected'] = times_detected

        # Update false positives
        if is_false_positive:
            false_positives = metadata.get('falsePositives', 0) + 1
            metadata['falsePositives'] = false_positives

            # Recalculate false positive rate
            if times_detected > 0:
                metadata['falsePositiveRate'] = false_positives / times_detected

        # Update last detected
        metadata['lastDetected'] = "$timestamp"
        metadata['updated'] = "$timestamp"

        # Update fix time
        if is_fixed and duration:
            # Parse duration to minutes
            if 'minute' in duration:
                fix_minutes = int(duration.split()[0])
            elif 'hour' in duration:
                fix_minutes = int(duration.split()[0]) * 60
            else:
                fix_minutes = 0

            # Calculate average fix time
            avg_fix = metadata.get('avgFixTime')
            if avg_fix:
                # Extract existing avg in minutes
                if 'minute' in avg_fix:
                    existing_minutes = int(avg_fix.split()[0])
                else:
                    existing_minutes = 0

                # Calculate new average
                total_detections = times_detected
                new_avg_minutes = ((existing_minutes * (total_detections - 1)) + fix_minutes) / total_detections
                metadata['avgFixTime'] = f"{int(new_avg_minutes)} minutes"
            else:
                metadata['avgFixTime'] = duration

            # Update total time saved
            total_saved_minutes = times_detected * int(metadata.get('avgFixTime', '0').split()[0])
            if total_saved_minutes >= 60:
                hours = total_saved_minutes / 60
                metadata['totalTimeSaved'] = f"{hours:.1f} hours"
            else:
                metadata['totalTimeSaved'] = f"{total_saved_minutes} minutes"

        pattern['metadata'] = metadata
        break

# Write back to YAML
with open('$patterns_file', 'w') as f:
    yaml.dump(patterns, f, default_flow_style=False, sort_keys=False)

print(json.dumps(metadata, indent=2))
EOF
)
```

### Step 5: Log Detection Event

```bash
# Create history log if it doesn't exist
history_log=".claude/history/pattern-detections.jsonl"
mkdir -p "$(dirname "$history_log")"

# Append detection event
detection_event=$(cat << EOF
{
  "timestamp": "$timestamp",
  "pattern": "$pattern_id",
  "file": "$file",
  "line": $line,
  "falsePositive": $false_positive,
  "fpReason": "$fp_reason",
  "fixed": $fixed,
  "duration": "$duration"
}
EOF
)

echo "$detection_event" >> "$history_log"
```

### Step 6: Display Update

```
✅ Pattern Detection Recorded

Pattern: DI-LIFETIME-001
File: ServiceCollectionExtensions.cs:42
Time: 2025-12-11 15:45:00 UTC

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Updated Metadata:
────────────────────────────────────────────────────────
Times Detected: 16 (+1)
False Positives: 2
False Positive Rate: 12.5%
Last Detected: 2025-12-11 15:45:00
Average Fix Time: 5 minutes
Total Time Saved: 80 minutes (1.3 hours)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Pattern Effectiveness: ████████░░ 87.5%

Next Steps:
  • Run /playbook-stats to see overall pattern health
  • Run /pattern-report for detailed effectiveness analysis
```

## Batch Processing

Process multiple detections from JSON file:

```json
{
  "detections": [
    {
      "pattern": "DI-LIFETIME-001",
      "file": "ServiceCollectionExtensions.cs",
      "line": 42,
      "fixed": true,
      "duration": "5 minutes"
    },
    {
      "pattern": "VENDOR-DECOUPLING-001",
      "file": "Abstractions/IStaxbillService.cs",
      "line": 15,
      "fixed": true,
      "duration": "10 minutes"
    },
    {
      "pattern": "DI-LIFETIME-001",
      "file": "Startup.cs",
      "line": 78,
      "falsePositive": true,
      "reason": "Service needs request-scoped state"
    }
  ]
}
```

```bash
/track-pattern-detection --batch detections.json
```

Output:
```
Processing 3 detections...

✅ DI-LIFETIME-001: Recorded (fixed in 5 minutes)
✅ VENDOR-DECOUPLING-001: Recorded (fixed in 10 minutes)
⚠️  DI-LIFETIME-001: Marked as false positive

Summary:
  Detections: 2
  False Positives: 1
  Total Fix Time: 15 minutes
  Patterns Updated: 2
```

## Integration

### With /code-review

Automatically track patterns during code review:

```bash
/code-review
# ... performs review ...
# Automatically calls /track-pattern-detection for each pattern found
```

### Manual Tracking

Record patterns found during development:

```bash
# Found an issue
/track-pattern-detection --pattern DI-LIFETIME-001 --file MyFile.cs --line 42

# Fixed it
/track-pattern-detection --pattern DI-LIFETIME-001 --fixed --duration "3 minutes"
```

### False Positive Reporting

Mark incorrect detections:

```bash
/track-pattern-detection --pattern PERF-QUERY-002 --false-positive \
  --reason "Query is intentionally executed in memory for business logic"
```

## History Log Format

Each detection is logged to `.claude/history/pattern-detections.jsonl`:

```jsonl
{"timestamp":"2025-12-11T15:45:00Z","pattern":"DI-LIFETIME-001","file":"ServiceCollectionExtensions.cs","line":42,"falsePositive":false,"fixed":true,"duration":"5 minutes"}
{"timestamp":"2025-12-11T15:46:00Z","pattern":"VENDOR-DECOUPLING-001","file":"Abstractions/IStaxbillService.cs","line":15,"falsePositive":false,"fixed":true,"duration":"10 minutes"}
{"timestamp":"2025-12-11T15:47:00Z","pattern":"DI-LIFETIME-001","file":"Startup.cs","line":78,"falsePositive":true,"fpReason":"Service needs request-scoped state"}
```

This log can be analyzed for:
- Pattern effectiveness over time
- Common false positive scenarios
- Average fix times by pattern
- Detection trends

## Related Commands

- `/code-review` - Performs code review and auto-tracks patterns
- `/playbook-stats` - View pattern usage statistics
- `/pattern-report` - Detailed effectiveness analysis (Phase 4.2)

---

*Created: 2025-12-11*
*Part of: PR Feedback Learning Loop (Phase 4.1)*
