---
name: pattern-merge
description: Detect and merge similar or duplicate patterns
---

# Pattern Merge Command

Automatically detects similar, duplicate, or overlapping code review patterns and provides intelligent merge suggestions to keep pattern library clean and efficient.

## Usage

```bash
/pattern-merge                          # Find all similar patterns
/pattern-merge --find-duplicates        # Find exact duplicates only
/pattern-merge --threshold 0.8          # Adjust similarity threshold (0.0-1.0)
/pattern-merge --auto-merge             # Auto-merge exact duplicates
/pattern-merge --category Architecture  # Check specific category only
/pattern-merge --export report.json     # Export similarity report
```

## Purpose

Maintain pattern library quality by:
- Detecting exact duplicate patterns
- Finding similar patterns that could be merged
- Identifying overlapping detection logic
- Reducing false positives from competing patterns
- Consolidating redundant rules
- Improving pattern library clarity

## Implementation

### Step 1: Load Patterns

```bash
patterns_file="code-review-patterns.yaml"

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

### Step 2: Find Similar Patterns

```python
from difflib import SequenceMatcher
import re
from collections import defaultdict

def calculate_similarity(pattern1, pattern2):
    """
    Calculate similarity score between two patterns
    """
    scores = []

    # Compare titles (30% weight)
    title_sim = SequenceMatcher(None,
                                pattern1.get('title', '').lower(),
                                pattern2.get('title', '').lower()).ratio()
    scores.append(('title', title_sim, 0.30))

    # Compare rules (40% weight)
    rule_sim = SequenceMatcher(None,
                               pattern1.get('rule', '').lower(),
                               pattern2.get('rule', '').lower()).ratio()
    scores.append(('rule', rule_sim, 0.40))

    # Compare detection patterns (30% weight)
    det1 = pattern1.get('detection', {}).get('pattern', '')
    det2 = pattern2.get('detection', {}).get('pattern', '')
    detection_sim = SequenceMatcher(None, det1, det2).ratio()
    scores.append(('detection', detection_sim, 0.30))

    # Weighted average
    total_score = sum(score * weight for _, score, weight in scores)

    return {
        'overall': total_score,
        'breakdown': {name: score for name, score, _ in scores}
    }


def find_similar_patterns(patterns, threshold=0.7):
    """
    Find patterns that might be duplicates or could be merged
    """
    similarities = []

    for i, p1 in enumerate(patterns):
        for j, p2 in enumerate(patterns[i+1:], start=i+1):
            # Skip if different categories
            if p1.get('category') != p2.get('category'):
                continue

            similarity = calculate_similarity(p1, p2)

            if similarity['overall'] >= threshold:
                similarities.append({
                    'pattern1': p1,
                    'pattern2': p2,
                    'similarity': similarity,
                    'type': classify_similarity(similarity)
                })

    return similarities


def classify_similarity(similarity):
    """
    Classify the type of similarity
    """
    overall = similarity['overall']
    breakdown = similarity['breakdown']

    if overall >= 0.95:
        return 'exact_duplicate'
    elif breakdown['detection'] >= 0.90 and breakdown['title'] < 0.70:
        return 'overlapping_detection'
    elif breakdown['rule'] >= 0.85:
        return 'redundant_rule'
    elif overall >= 0.70:
        return 'similar'
    else:
        return 'unrelated'


def suggest_merge(pattern1, pattern2, similarity_type):
    """
    Suggest how to merge two similar patterns
    """
    if similarity_type == 'exact_duplicate':
        # Keep the one with more detections
        metadata1 = pattern1.get('metadata', {})
        metadata2 = pattern2.get('metadata', {})

        if metadata1.get('timesDetected', 0) >= metadata2.get('timesDetected', 0):
            return {
                'action': 'delete',
                'keep': pattern1['id'],
                'delete': pattern2['id'],
                'reason': f"{pattern1['id']} has more detections ({metadata1.get('timesDetected', 0)} vs {metadata2.get('timesDetected', 0)})"
            }
        else:
            return {
                'action': 'delete',
                'keep': pattern2['id'],
                'delete': pattern1['id'],
                'reason': f"{pattern2['id']} has more detections"
            }

    elif similarity_type == 'overlapping_detection':
        return {
            'action': 'merge_detection',
            'suggestion': 'Combine detection patterns with OR logic',
            'pattern1': pattern1['id'],
            'pattern2': pattern2['id']
        }

    elif similarity_type == 'redundant_rule':
        return {
            'action': 'consolidate',
            'suggestion': 'Merge into single pattern with comprehensive rule',
            'pattern1': pattern1['id'],
            'pattern2': pattern2['id']
        }

    else:  # similar
        return {
            'action': 'review',
            'suggestion': 'Patterns are similar - manual review recommended',
            'pattern1': pattern1['id'],
            'pattern2': pattern2['id']
        }
```

### Step 3: Generate Similarity Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pattern Similarity Analysis
Generated: 2025-12-11 18:00:00
Patterns Analyzed: 24
Similarity Threshold: 70%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 SUMMARY
────────────────────────────────────────────────────────
Similar Pattern Groups: 5

  🔴 Exact Duplicates: 2 pairs
  🟡 Overlapping Detection: 1 pair
  🟠 Redundant Rules: 1 pair
  🔵 Similar (review needed): 1 pair

Recommended Actions:
  • Delete 2 duplicate patterns
  • Merge 2 pattern pairs
  • Review 1 pattern pair

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 EXACT DUPLICATES (2)
────────────────────────────────────────────────────────

1. DI-LIFETIME-001 ≈ DI-LIFETIME-004
   Similarity: 98%
   Breakdown:
     • Title: 100% match
     • Rule: 97% match
     • Detection: 96% match

   DI-LIFETIME-001:
     Priority: High
     Detections: 23
     FP Rate: 8.7%
     Created: 2025-01-15

   DI-LIFETIME-004:
     Priority: High
     Detections: 3
     FP Rate: 0.0%
     Created: 2025-11-20

   Recommendation: DELETE DI-LIFETIME-004
   Reason: DI-LIFETIME-001 has significantly more usage (23 vs 3 detections)
   Action: Keep DI-LIFETIME-001, consolidate metadata

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

2. SEC-LOGGING-001 ≈ SEC-LOGGING-003
   Similarity: 96%
   Breakdown:
     • Title: 95% match
     • Rule: 98% match
     • Detection: 95% match

   SEC-LOGGING-001:
     Title: "Do not log sensitive data"
     Detection: (password|token|apikey|secret)
     Detections: 12
     FP Rate: 0.0%

   SEC-LOGGING-003:
     Title: "Avoid logging passwords and tokens"
     Detection: (password|token)
     Detections: 8
     FP Rate: 0.0%

   Recommendation: MERGE into SEC-LOGGING-001
   Reason: SEC-LOGGING-001 has broader coverage and more detections
   Merged Detection: (password|token|apikey|secret)  # Already covers both

   Action: Delete SEC-LOGGING-003, keep SEC-LOGGING-001

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟡 OVERLAPPING DETECTION (1)
────────────────────────────────────────────────────────

3. PERF-QUERY-001 ≈ PERF-QUERY-003
   Similarity: 72%
   Breakdown:
     • Title: 60% match
     • Rule: 68% match
     • Detection: 92% match (HIGH OVERLAP)

   PERF-QUERY-001:
     Title: "Use async database operations"
     Detection: \.ExecuteNonQuery\(\)|\.ExecuteReader\(\)
     Detections: 10

   PERF-QUERY-003:
     Title: "Prefer async over sync database calls"
     Detection: \.ExecuteNonQuery\(\)|\.ExecuteScalar\(\)
     Detections: 7

   Issue: Detection patterns overlap significantly
   Both patterns catch ExecuteNonQuery()

   Recommendation: MERGE DETECTION PATTERNS
   Suggested merged pattern:
     Detection: \.Execute(NonQuery|Reader|Scalar)\(\)
     Title: "Use async database operations"
     Combined Rule: Always use async variants of Execute* methods

   Action: Merge into single pattern PERF-QUERY-001

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟠 REDUNDANT RULES (1)
────────────────────────────────────────────────────────

4. ARCH-LAYER-001 ≈ ARCH-LAYER-003
   Similarity: 85%
   Breakdown:
     • Title: 75% match
     • Rule: 92% match (VERY SIMILAR)
     • Detection: 70% match

   ARCH-LAYER-001:
     Title: "Controllers must not reference Infrastructure"
     Rule: "Controllers in Api layer must not reference Infrastructure layer directly"
     Detection: using \\w+\\.Infrastructure\\.

   ARCH-LAYER-003:
     Title: "Api layer should not depend on Infrastructure"
     Rule: "Api project must not have direct dependency on Infrastructure project"
     Detection: <ProjectReference.*Infrastructure.*/>

   Analysis: Both enforce the same architectural rule but at different levels
     • ARCH-LAYER-001: Code-level (using statements)
     • ARCH-LAYER-003: Project-level (project references)

   Recommendation: CONSOLIDATE into comprehensive pattern
   Merged Pattern:
     ID: ARCH-LAYER-001
     Title: "Api layer must not reference Infrastructure"
     Rule: "Controllers must not reference Infrastructure (code or project level)"
     Detection:
       - using \\w+\\.Infrastructure\\. (code)
       - <ProjectReference.*Infrastructure.*/> (project)

   Action: Merge both into ARCH-LAYER-001, update detection logic

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔵 SIMILAR - REVIEW NEEDED (1)
────────────────────────────────────────────────────────

5. TEST-COVERAGE-001 ≈ TEST-COVERAGE-002
   Similarity: 74%
   Breakdown:
     • Title: 80% match
     • Rule: 75% match
     • Detection: 68% match

   TEST-COVERAGE-001:
     Focus: Critical business paths must have tests
     Scope: Domain layer

   TEST-COVERAGE-002:
     Focus: Public APIs must have integration tests
     Scope: Api layer

   Analysis: Similar intent but different scopes
   May be complementary rather than duplicates

   Recommendation: KEEP BOTH
   Reason: Cover different layers of testing pyramid
   Suggested improvement: Add cross-references between patterns

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 MERGE PLAN
────────────────────────────────────────────────────────

Automatic (2 deletions):
  1. Delete DI-LIFETIME-004 (duplicate of DI-LIFETIME-001)
  2. Delete SEC-LOGGING-003 (duplicate of SEC-LOGGING-001)

Manual Review Required (2 merges):
  3. Merge PERF-QUERY-001 and PERF-QUERY-003
  4. Consolidate ARCH-LAYER-001 and ARCH-LAYER-003

No Action Needed (1):
  5. Keep TEST-COVERAGE-001 and TEST-COVERAGE-002 separate

Impact:
  • Patterns before: 24
  • Patterns after: 20 (-4)
  • Library clarity: ↑ 17%
  • Duplicate overhead: ↓ 100%

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 NEXT STEPS
────────────────────────────────────────────────────────

Auto-apply safe deletions:
  /pattern-merge --auto-merge

Or review each merge interactively:
  /pattern-merge --review

Export report for team review:
  /pattern-merge --export similarity-report.json
```

## Interactive Review Mode

```bash
/pattern-merge --review
```

Steps through each similar pair:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Similar Pair 1 of 5

DI-LIFETIME-001 ≈ DI-LIFETIME-004
Similarity: 98% (Exact Duplicate)

[Shows detailed comparison...]

Recommended Action: Delete DI-LIFETIME-004

Options:
  [d] Delete DI-LIFETIME-004 (recommended)
  [k] Keep both
  [m] Merge into new pattern
  [s] Skip
  [v] View full diff

> d

✅ Deleted DI-LIFETIME-004
   Metadata from DI-LIFETIME-004 added to notes in DI-LIFETIME-001

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Similar Pair 2 of 5
...
```

## Auto-merge Mode

```bash
/pattern-merge --auto-merge
```

Automatically merges exact duplicates:

```
🤖 Auto-merging exact duplicates...

✅ Deleted DI-LIFETIME-004 (duplicate of DI-LIFETIME-001)
✅ Deleted SEC-LOGGING-003 (duplicate of SEC-LOGGING-001)

Summary:
  Exact duplicates removed: 2
  Patterns requiring manual review: 3

Total patterns: 24 → 22 (-2)

Run /pattern-merge --review to handle remaining similar patterns
```

## JSON Export

```bash
/pattern-merge --export similarity-report.json
```

```json
{
  "generated": "2025-12-11T18:00:00Z",
  "threshold": 0.7,
  "totalPatterns": 24,
  "similarGroups": 5,
  "similarities": [
    {
      "pattern1": "DI-LIFETIME-001",
      "pattern2": "DI-LIFETIME-004",
      "similarity": 0.98,
      "type": "exact_duplicate",
      "recommendation": {
        "action": "delete",
        "keep": "DI-LIFETIME-001",
        "delete": "DI-LIFETIME-004",
        "reason": "DI-LIFETIME-001 has more detections"
      }
    }
  ],
  "summary": {
    "exactDuplicates": 2,
    "overlappingDetection": 1,
    "redundantRules": 1,
    "similarNeedReview": 1
  }
}
```

## Integration

### Periodic cleanup

```bash
# Monthly pattern library cleanup
0 0 1 * * /pattern-merge --auto-merge && /pattern-report
```

### Post-import cleanup

After importing patterns from another project:

```bash
/import-patterns --source team-patterns.yaml
/pattern-merge --find-duplicates --auto-merge
```

### CI/CD quality gate

```bash
# Fail if too many duplicates detected
duplicates=$(/pattern-merge --find-duplicates --export - | jq '.summary.exactDuplicates')
if [ "$duplicates" -gt 5 ]; then
  echo "❌ Too many duplicate patterns: $duplicates"
  echo "Run /pattern-merge --auto-merge to clean up"
  exit 1
fi
```

## Related Commands

- `/pattern-report` - View pattern effectiveness
- `/import-patterns` - Import patterns (may create duplicates)
- `/export-patterns` - Export cleaned patterns
- `/pattern-evolve` - Suggest pattern improvements

---

*Created: 2025-12-11*
*Part of: PR Feedback Learning Loop (Phase 4.5)*
