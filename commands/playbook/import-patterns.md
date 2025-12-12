---
name: import-patterns
description: Import code review patterns from external sources
---

# Import Patterns Command

Import code review patterns from other projects or teams, with interactive review and conflict detection. Supports merging with existing patterns, filtering by category/priority, and customizing for your project.

## Usage

```bash
/import-patterns --source other-project-patterns.yaml          # Import with review
/import-patterns --source patterns.yaml --auto-merge           # Auto-merge non-conflicting
/import-patterns --source patterns.yaml --category Security    # Import specific category
/import-patterns --source patterns.yaml --dry-run              # Preview without importing
/import-patterns --source patterns.yaml --replace              # Replace existing patterns
```

## Purpose

Enable pattern reuse by:
- Importing patterns from other projects
- Bootstrapping new projects with proven patterns
- Sharing organizational best practices
- Contributing community patterns
- Merging team pattern libraries
- Restoring from backups

## Implementation

### Step 1: Parse Arguments

```bash
source_file=""
auto_merge=false
category=""
priority=""
dry_run=false
replace=false

while [ $# -gt 0 ]; do
  case "$1" in
    --source)
      source_file="$2"
      shift 2
      ;;
    --auto-merge)
      auto_merge=true
      shift
      ;;
    --category)
      category="$2"
      shift 2
      ;;
    --priority)
      priority="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --replace)
      replace=true
      shift
      ;;
    *)
      echo "❌ Unknown argument: $1"
      exit 1
      ;;
  esac
done

if [ -z "$source_file" ]; then
  echo "❌ --source argument required"
  exit 1
fi

if [ ! -f "$source_file" ]; then
  echo "❌ Source file not found: $source_file"
  exit 1
fi
```

### Step 2: Load Source and Destination

```bash
patterns_file="code-review-patterns.yaml"

# Load source patterns
source_patterns=$(python3 -c "
import yaml, json
with open('$source_file') as f:
    data = yaml.safe_load(f)
print(json.dumps(data))
")

# Load existing patterns if they exist
if [ -f "$patterns_file" ] && [ "$replace" = "false" ]; then
  existing_patterns=$(python3 -c "
import yaml, json
with open('$patterns_file') as f:
    data = yaml.safe_load(f)
print(json.dumps(data))
  ")
else
  existing_patterns='{"schemaVersion": "1.0.0", "patterns": []}'
fi
```

### Step 3: Analyze Conflicts

```python
def analyze_import(source_patterns, existing_patterns):
    """
    Analyze patterns for conflicts and categorize
    """
    source = source_patterns.get('patterns', [])
    existing = existing_patterns.get('patterns', [])

    existing_ids = {p['id']: p for p in existing}

    result = {
        'new': [],          # Patterns with new IDs
        'conflicts': [],    # Patterns with same ID but different content
        'duplicates': [],   # Exact duplicates (same ID and content)
        'updated': []       # Patterns with newer version
    }

    for pattern in source:
        pattern_id = pattern['id']

        if pattern_id not in existing_ids:
            # New pattern
            result['new'].append(pattern)
        else:
            existing_pattern = existing_ids[pattern_id]

            # Compare content
            if patterns_equal(pattern, existing_pattern):
                result['duplicates'].append(pattern)
            elif is_newer(pattern, existing_pattern):
                result['updated'].append({
                    'new': pattern,
                    'old': existing_pattern
                })
            else:
                result['conflicts'].append({
                    'imported': pattern,
                    'existing': existing_pattern
                })

    return result


def patterns_equal(p1, p2):
    """Check if patterns are functionally equal"""
    # Compare key fields
    return (
        p1.get('rule') == p2.get('rule') and
        p1.get('detection', {}).get('pattern') == p2.get('detection', {}).get('pattern') and
        p1.get('priority') == p2.get('priority')
    )


def is_newer(p1, p2):
    """Check if p1 is newer than p2"""
    updated1 = p1.get('metadata', {}).get('updated') or p1.get('metadata', {}).get('created')
    updated2 = p2.get('metadata', {}).get('updated') or p2.get('metadata', {}).get('created')

    if updated1 and updated2:
        return updated1 > updated2
    return False
```

### Step 4: Interactive Review

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pattern Import Analysis
Source: other-project-patterns.yaml
Destination: code-review-patterns.yaml
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 IMPORT SUMMARY
────────────────────────────────────────────────────────
Total patterns in source: 15

  ✅ New patterns: 8
  🔄 Updates available: 3
  ⚠️  Conflicts: 2
  ℹ️  Duplicates (skipped): 2

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ NEW PATTERNS (8)
────────────────────────────────────────────────────────

1. ASYNC-VOID-001: Avoid async void methods
   Category: BestPractices
   Priority: High
   Effectiveness: 95%

2. API-DESIGN-001: Use consistent API naming
   Category: Architecture
   Priority: Medium
   Effectiveness: 88%

3. PERF-CACHING-001: Cache expensive operations
   Category: Performance
   Priority: High
   Effectiveness: 92%

[... 5 more patterns ...]

Import all new patterns? [Y/n]
> y

✅ Importing 8 new patterns

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔄 UPDATES AVAILABLE (3)
────────────────────────────────────────────────────────

1. DI-LIFETIME-001: Use Transient for stateless services
   Changes:
     • Detection pattern refined (reduced false positives)
     • Added 2 new examples
     • Updated remediation steps

   Your version:
     Last Updated: 2025-11-15
     Detections: 23
     FP Rate: 8.7%

   Imported version:
     Last Updated: 2025-12-01
     Detections: 45
     FP Rate: 4.2%

   Apply update? [y/N/diff]
   > y

2. SEC-LOGGING-001: Do not log sensitive data
   Changes:
     • Expanded detection pattern to catch more cases
     • Added PII detection rules

   Apply update? [y/N/diff]
   > diff

   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Diff: SEC-LOGGING-001

   Detection Pattern:
   - Old: (password|token|apikey|secret)
   + New: (password|token|apikey|secret|ssn|creditcard|email)

   Rule:
   - Old: Do not log passwords, tokens, API keys, or secrets
   + New: Do not log passwords, tokens, API keys, secrets, or PII

   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Apply this update? [y/N]
   > y

3. ARCH-LAYER-001: Controllers must not reference Infrastructure
   Changes:
     • Clarified rule description
     • No functional changes

   Apply update? [y/N/diff]
   > n

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  CONFLICTS (2)
────────────────────────────────────────────────────────

1. PERF-QUERY-002: Filter data at database level
   Conflict: Both versions have different detection patterns

   Your version:
     Pattern: \.ToList\(\)|\.ToArray\(\)
     Priority: High
     FP Rate: 45.5%

   Imported version:
     Pattern: \.ToList\(\)(?!.*Where)
     Priority: High
     FP Rate: 12.0%

   Resolution options:
     [k] Keep your version
     [i] Use imported version
     [m] Merge (combine both patterns)
     [e] Edit manually
     [s] Skip

   > i
   Using imported version (lower FP rate)

2. CONV-NAMING-001: Use plural names for collections
   Conflict: Different priorities

   Your version: Priority Medium, FP Rate 33%
   Imported version: Priority Low, FP Rate 15%

   Resolution: [k/i/m/s]
   > k
   Keeping your version

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 IMPORT PLAN
────────────────────────────────────────────────────────

Actions to perform:
  • Add 8 new patterns
  • Update 2 existing patterns
  • Replace 1 conflicting pattern
  • Skip 1 conflicting pattern
  • Skip 2 duplicates

Total patterns after import: 24 → 31 (+7)

Proceed with import? [Y/n]
> y
```

### Step 5: Apply Import

```bash
python3 << 'EOF'
import yaml
import json
from datetime import datetime

source = json.loads('''$source_patterns''')
existing = json.loads('''$existing_patterns''')
import_decisions = json.loads('''$import_decisions''')

# Build new pattern list
final_patterns = list(existing.get('patterns', []))

# Add new patterns
for pattern in import_decisions['add']:
    # Reset metadata for new project
    pattern['metadata'] = {
        'timesDetected': 0,
        'lastDetected': None,
        'falsePositives': 0,
        'falsePositiveRate': 0.0,
        'avgFixTime': None,
        'totalTimeSaved': None,
        'created': datetime.now().isoformat() + 'Z',
        'updated': None,
        'importedFrom': '$source_file',
        'importedDate': datetime.now().isoformat() + 'Z'
    }
    final_patterns.append(pattern)

# Update existing patterns
for pattern_id, new_pattern in import_decisions['update'].items():
    # Find and replace
    for i, p in enumerate(final_patterns):
        if p['id'] == pattern_id:
            # Preserve existing metadata
            old_metadata = p.get('metadata', {})
            new_pattern['metadata'] = old_metadata
            new_pattern['metadata']['updated'] = datetime.now().isoformat() + 'Z'
            final_patterns[i] = new_pattern
            break

# Replace conflicting patterns
for pattern_id, new_pattern in import_decisions['replace'].items():
    for i, p in enumerate(final_patterns):
        if p['id'] == pattern_id:
            # Reset metadata but keep detection history
            old_metadata = p.get('metadata', {})
            new_pattern['metadata'] = {
                **old_metadata,
                'updated': datetime.now().isoformat() + 'Z',
                'replacedFrom': '$source_file'
            }
            final_patterns[i] = new_pattern
            break

# Write to file
result = {
    'schemaVersion': existing.get('schemaVersion', '1.0.0'),
    'patterns': final_patterns
}

if not "$dry_run" == "true":
    with open('$patterns_file', 'w') as f:
        yaml.dump(result, f, default_flow_style=False, sort_keys=False)

print(json.dumps({
    'success': True,
    'added': len(import_decisions['add']),
    'updated': len(import_decisions['update']),
    'replaced': len(import_decisions['replace']),
    'total': len(final_patterns)
}))
EOF
```

### Step 6: Display Results

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Import Complete

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Changes Applied:
  • Added: 8 patterns
  • Updated: 2 patterns
  • Replaced: 1 pattern
  • Skipped: 4 patterns

Total Patterns: 24 → 31 (+7)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 NEXT STEPS
────────────────────────────────────────────────────────

1. Review imported patterns:
   /pattern-report

2. Test pattern detection:
   /code-review

3. Customize for your project:
   • Update detection patterns for your codebase structure
   • Adjust priorities based on team needs
   • Add project-specific examples

4. Run validation:
   /validate-playbook

5. Check for duplicates:
   /pattern-merge --find-duplicates
```

## Auto-merge Mode

```bash
/import-patterns --source patterns.yaml --auto-merge
```

Automatically imports non-conflicting patterns:

```
🤖 Auto-merging patterns...

✅ Added 8 new patterns
✅ Updated 2 patterns (no conflicts)
⚠️  Skipped 2 patterns (conflicts detected)

Conflicts requiring manual review:
  • PERF-QUERY-002
  • CONV-NAMING-001

Run without --auto-merge to resolve conflicts interactively
```

## Dry Run Mode

```bash
/import-patterns --source patterns.yaml --dry-run
```

Preview changes without applying:

```
🔍 DRY RUN - No changes will be applied

Import Analysis:
  • Would add: 8 patterns
  • Would update: 2 patterns
  • Would skip (conflicts): 2 patterns
  • Would skip (duplicates): 2 patterns

Run without --dry-run to apply changes
```

## Integration

### Bootstrap new project

```bash
# Clone team pattern library
git clone https://github.com/team/pattern-library
cd my-new-project
/import-patterns --source ../pattern-library/patterns.yaml --auto-merge
```

### Periodic updates

```bash
# Update from central library
/import-patterns --source team-patterns.yaml --dry-run
# Review changes, then apply
/import-patterns --source team-patterns.yaml
```

## Related Commands

- `/export-patterns` - Export patterns for sharing
- `/pattern-merge` - Detect and merge similar patterns (Phase 4.5)
- `/pattern-report` - View effectiveness after import

---

*Created: 2025-12-11*
*Part of: PR Feedback Learning Loop (Phase 4.4)*
