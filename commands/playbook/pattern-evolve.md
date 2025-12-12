---
name: pattern-evolve
description: Analyze pattern usage and suggest automated improvements
---

# Pattern Evolution Engine

Automatically analyzes code review patterns based on usage data and suggests improvements: refining high false-positive patterns, archiving unused ones, promoting effective patterns to guardrails, and merging similar patterns.

## Usage

```bash
/pattern-evolve                           # Analyze all patterns
/pattern-evolve --pattern DI-LIFETIME-001 # Analyze specific pattern
/pattern-evolve --auto-apply              # Apply safe improvements automatically
/pattern-evolve --review                  # Interactive review mode
/pattern-evolve --export suggestions.json # Export suggestions for review
```

## Purpose

Continuously improve pattern library by:
- Refining patterns with high false positive rates
- Archiving unused or outdated patterns
- Promoting highly effective patterns to playbook guardrails
- Merging duplicate or similar patterns
- Adjusting priority levels based on effectiveness
- Updating detection logic based on common failures

## Implementation

### Step 1: Load Patterns and Metrics

```bash
patterns_file="code-review-patterns.yaml"
history_log=".claude/history/pattern-detections.jsonl"

if [ ! -f "$patterns_file" ]; then
  echo "❌ Patterns file not found: $patterns_file"
  exit 1
fi

patterns=$(python3 -c "
import yaml, json
with open('$patterns_file') as f:
    data = yaml.safe_load(f)
print(json.dumps(data))
")
```

### Step 2: Analyze Patterns and Generate Suggestions

```python
def evolve_patterns(patterns, usage_data):
    """
    Analyze pattern usage and suggest improvements
    """
    suggestions = []

    for pattern in patterns:
        pattern_id = pattern['id']
        metadata = pattern.get('metadata', {})

        times_detected = metadata.get('timesDetected', 0)
        false_positives = metadata.get('falsePositives', 0)
        fp_rate = metadata.get('falsePositiveRate', 0)
        last_detected = metadata.get('lastDetected')

        # Rule 1: High false positive rate → Refine
        if fp_rate > 0.20 and times_detected > 5:
            suggestions.append({
                "pattern": pattern_id,
                "action": "refine",
                "priority": "high",
                "reason": f"High false positive rate: {fp_rate:.1%} ({false_positives}/{times_detected})",
                "suggestion": analyze_false_positives(pattern, usage_data),
                "auto_apply": False  # Requires manual review
            })

        # Rule 2: No recent detections → Archive
        if last_detected:
            days_since = (now() - parse_date(last_detected)).days
            if days_since > 90:
                suggestions.append({
                    "pattern": pattern_id,
                    "action": "archive",
                    "priority": "medium",
                    "reason": f"Not detected in {days_since} days",
                    "suggestion": f"Move to archived-patterns.yaml or remove if no longer relevant",
                    "auto_apply": False
                })
        elif times_detected == 0:
            # Never detected
            days_since_created = (now() - parse_date(metadata.get('created', now()))).days
            if days_since_created > 30:
                suggestions.append({
                    "pattern": pattern_id,
                    "action": "archive",
                    "priority": "high",
                    "reason": f"Never detected in {days_since_created} days since creation",
                    "suggestion": "Verify detection logic is working or remove pattern",
                    "auto_apply": False
                })

        # Rule 3: High effectiveness → Promote to playbook
        if times_detected > 20 and fp_rate < 0.05:
            suggestions.append({
                "pattern": pattern_id,
                "action": "promote",
                "priority": "medium",
                "reason": f"High detection rate ({times_detected}) with low false positives ({fp_rate:.1%})",
                "suggestion": "Consider adding to agent-playbook.yaml as guardrail",
                "playbook_category": infer_playbook_category(pattern),
                "playbook_id": suggest_playbook_id(pattern),
                "auto_apply": False
            })

        # Rule 4: Medium usage, low FP → Increase priority
        if 10 <= times_detected < 20 and fp_rate < 0.10 and pattern.get('priority') != 'High':
            suggestions.append({
                "pattern": pattern_id,
                "action": "adjust_priority",
                "priority": "low",
                "reason": f"Consistent detections ({times_detected}) with low FP rate ({fp_rate:.1%})",
                "suggestion": "Increase priority from {pattern['priority']} to High",
                "new_priority": "High",
                "auto_apply": True  # Safe to auto-apply
            })

        # Rule 5: Low usage, high priority → Decrease priority
        if times_detected < 5 and pattern.get('priority') == 'High':
            suggestions.append({
                "pattern": pattern_id,
                "action": "adjust_priority",
                "priority": "low",
                "reason": f"Low detection rate ({times_detected}) for High priority pattern",
                "suggestion": "Consider lowering priority to Medium",
                "new_priority": "Medium",
                "auto_apply": True
            })

    return suggestions


def analyze_false_positives(pattern, usage_data):
    """
    Analyze false positive cases to suggest refinements
    """
    pattern_id = pattern['id']

    # Get false positive cases from history
    fp_cases = [
        event for event in usage_data
        if event['pattern'] == pattern_id and event.get('falsePositive')
    ]

    if not fp_cases:
        return "No false positive cases recorded. Enable FP tracking with --reason flag."

    # Extract common reasons
    reasons = [case.get('fpReason', '') for case in fp_cases if case.get('fpReason')]

    # Common patterns in false positives
    common_files = Counter([case['file'] for case in fp_cases if case.get('file')])
    common_contexts = extract_common_contexts(fp_cases)

    suggestions = []

    # Suggest detection refinements
    if common_files:
        top_file_patterns = common_files.most_common(3)
        suggestions.append(f"Exclude files matching: {', '.join(f for f, _ in top_file_patterns)}")

    if common_contexts:
        suggestions.append(f"Add negative lookahead for: {', '.join(common_contexts)}")

    if "intentionally" in ' '.join(reasons).lower():
        suggestions.append("Add context validation to detect intentional usage")

    if "test" in ' '.join(reasons).lower():
        suggestions.append("Exclude test files from detection")

    return " | ".join(suggestions) if suggestions else "Manual review required"
```

### Step 3: Generate Evolution Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pattern Evolution Analysis
Generated: 2025-12-11 17:00:00
Patterns Analyzed: 24
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 HIGH PRIORITY ACTIONS (3)
────────────────────────────────────────────────────────

1. REFINE: PERF-QUERY-002
   Reason: High false positive rate: 45.5% (5/11)
   Current Detection: \.ToList\(\)|\.ToArray\(\)
   Suggested Refinement:
     • Exclude test files from detection
     • Add negative lookahead for: already-loaded collections
     • Exclude files matching: **/*Tests.cs, **/TestHelpers.cs

   Auto-apply: No
   Action: Review false positive cases and update detection regex

2. ARCHIVE: ERROR-HANDLING-003
   Reason: Never detected in 57 days since creation
   Last Modified: 2025-10-15
   Suggested Action: Verify detection logic works or remove pattern

   Auto-apply: No
   Action: /archive-pattern ERROR-HANDLING-003

3. REFINE: CONV-NAMING-001
   Reason: High false positive rate: 33.3% (2/6)
   Current Detection: \w+(List|Array|Collection)
   Suggested Refinement:
     • Add context validation to check if name is appropriate
     • Exclude files matching: **/Models/*.cs

   Auto-apply: No
   Action: Update validation logic

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟡 MEDIUM PRIORITY ACTIONS (4)
────────────────────────────────────────────────────────

4. PROMOTE: ARCH-LAYER-001
   Reason: High detection rate (23) with low false positives (0.0%)
   Effectiveness: 100%
   Time Saved: 115 minutes

   Suggested Playbook Entry:
     Layer: backend
     Type: guardrail
     ID: BE-G06
     Description: Controllers in Api layer must not reference Infrastructure directly

   Auto-apply: No
   Action: /promote-to-playbook ARCH-LAYER-001 --type guardrail --layer backend

5. PROMOTE: SEC-LOGGING-001
   Reason: High detection rate (12) with low false positives (0.0%)
   Effectiveness: 100%
   Time Saved: 60 minutes

   Suggested Playbook Entry:
     Layer: backend
     Type: guardrail
     ID: BE-G07
     Description: Do not log sensitive data (passwords, tokens, API keys)

   Auto-apply: No
   Action: /promote-to-playbook SEC-LOGGING-001 --type guardrail

6. ARCHIVE: TEST-COVERAGE-001
   Reason: Not detected in 87 days
   Last Detected: 2025-09-15
   Suggested Action: Update detection logic or archive if no longer relevant

   Auto-apply: No
   Action: Review and decide

7. ARCHIVE: DOC-COMMENTS-001
   Reason: Not detected in 72 days
   Last Detected: 2025-10-01
   Suggested Action: Consider moving to hygiene rules in playbook

   Auto-apply: No
   Action: /move-to-playbook DOC-COMMENTS-001 --type hygiene

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟢 LOW PRIORITY ACTIONS (5) - Auto-apply Available
────────────────────────────────────────────────────────

8. ADJUST_PRIORITY: DI-LIFETIME-002 → High
   Reason: Consistent detections (12) with low FP rate (0.0%)
   Current: Medium
   Suggested: High

   Auto-apply: Yes ✓
   Action: Increase priority to High

9. ADJUST_PRIORITY: ASYNC-PATTERNS-001 → Medium
   Reason: Low detection rate (3) for High priority pattern
   Current: High
   Suggested: Medium

   Auto-apply: Yes ✓
   Action: Decrease priority to Medium

10. ADJUST_PRIORITY: NULL-CHECK-001 → Medium
    Reason: Low detection rate (2) for High priority pattern
    Current: High
    Suggested: Medium

    Auto-apply: Yes ✓

11. ADJUST_PRIORITY: PERF-STRING-001 → High
    Reason: Consistent detections (14) with low FP rate (7.1%)
    Current: Medium
    Suggested: High

    Auto-apply: Yes ✓

12. ADJUST_PRIORITY: SEC-XSS-001 → High
    Reason: Consistent detections (11) with low FP rate (0.0%)
    Current: Medium
    Suggested: High

    Auto-apply: Yes ✓

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 SUMMARY
────────────────────────────────────────────────────────
Total Suggestions: 12
  • High Priority: 3 (requires manual review)
  • Medium Priority: 4 (requires manual review)
  • Low Priority: 5 (auto-apply available)

Estimated Impact:
  • Patterns to refine: 2 (expected FP reduction: 30-40%)
  • Patterns to archive: 3 (cleanup library)
  • Patterns to promote: 2 (strengthen playbook)
  • Priority adjustments: 5 (better triage)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 NEXT STEPS
────────────────────────────────────────────────────────

Manual Review Required (7 actions):
  1. Review high FP patterns and refine detection
  2. Verify archived patterns before removal
  3. Review promoted patterns for playbook addition

Auto-apply Available (5 actions):
  • Run: /pattern-evolve --auto-apply
  • This will safely adjust 5 pattern priorities

After applying changes:
  • Run /pattern-report to verify improvements
  • Run /validate-playbook to ensure no conflicts
```

## Interactive Review Mode

```bash
/pattern-evolve --review
```

Steps through each suggestion for approval:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Suggestion 1 of 12

Action: REFINE
Pattern: PERF-QUERY-002
Priority: HIGH
Reason: High false positive rate: 45.5% (5/11)

Current Detection:
  Files: ["**/*.cs"]
  Pattern: \.ToList\(\)|\.ToArray\(\)

Suggested Refinement:
  • Exclude test files from detection
  • Add negative lookahead for already-loaded collections
  • Exclude files matching: **/*Tests.cs, **/TestHelpers.cs

Apply this refinement? [y/N/edit/skip]
> edit

Opening pattern in editor...
[Editor shows current pattern YAML]

Updated pattern saved.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Suggestion 2 of 12
...
```

## Auto-apply Mode

```bash
/pattern-evolve --auto-apply
```

Automatically applies safe changes:

```
🤖 Auto-applying 5 safe improvements...

✅ DI-LIFETIME-002: Priority increased to High
✅ ASYNC-PATTERNS-001: Priority decreased to Medium
✅ NULL-CHECK-001: Priority decreased to Medium
✅ PERF-STRING-001: Priority increased to High
✅ SEC-XSS-001: Priority increased to High

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Auto-apply Complete

Changes Applied: 5
Manual Review Still Needed: 7

Run /pattern-report to verify improvements
```

## JSON Export

```bash
/pattern-evolve --export suggestions.json
```

```json
{
  "generated": "2025-12-11T17:00:00Z",
  "suggestions": [
    {
      "pattern": "PERF-QUERY-002",
      "action": "refine",
      "priority": "high",
      "reason": "High false positive rate: 45.5% (5/11)",
      "currentDetection": {
        "pattern": "\\.ToList\\(\\)|\\.ToArray\\(\\)",
        "files": ["**/*.cs"]
      },
      "suggestedRefinement": {
        "excludeFiles": ["**/*Tests.cs", "**/TestHelpers.cs"],
        "addNegativeLookahead": ["already-loaded collections"],
        "addContextValidation": true
      },
      "autoApply": false
    }
  ]
}
```

## Integration

### With CI/CD

Run evolution analysis weekly:

```yaml
# .github/workflows/pattern-evolution.yml
name: Pattern Evolution
on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday

jobs:
  evolve:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Analyze patterns
        run: /pattern-evolve --export suggestions.json
      - name: Create PR if suggestions exist
        run: |
          if [ -s suggestions.json ]; then
            # Create PR with suggested changes
          fi
```

### With Pattern Report

Generate report, then evolve:

```bash
/pattern-report --format json > report.json
/pattern-evolve --input report.json
```

## Related Commands

- `/pattern-report` - Generate effectiveness dashboard
- `/track-pattern-detection` - Record detections
- `/promote-to-playbook` - Promote pattern to playbook (Phase 4.4)
- `/archive-pattern` - Archive unused pattern (Phase 4.4)

---

*Created: 2025-12-11*
*Part of: PR Feedback Learning Loop (Phase 4.3)*
