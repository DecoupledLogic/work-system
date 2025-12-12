---
name: export-patterns
description: Export code review patterns for sharing across projects
---

# Export Patterns Command

Export learned code review patterns to shareable YAML format for use in other projects or teams. Supports filtering by category, priority, effectiveness, and allows anonymizing sensitive project data.

## Usage

```bash
/export-patterns                                  # Export all patterns
/export-patterns --output my-patterns.yaml        # Save to specific file
/export-patterns --category Architecture          # Export specific category
/export-patterns --priority High                  # Export high priority only
/export-patterns --min-effectiveness 0.8          # Export effective patterns only
/export-patterns --anonymize                      # Remove project-specific details
/export-patterns --include-metadata               # Include usage statistics
```

## Purpose

Enable pattern sharing to:
- Share successful patterns across teams
- Build org-wide pattern libraries
- Onboard new projects with proven patterns
- Contribute patterns to open source
- Backup pattern libraries
- Migrate patterns between repos

## Implementation

### Step 1: Parse Arguments

```bash
output_file="exported-patterns.yaml"
category=""
priority=""
min_effectiveness=""
anonymize=false
include_metadata=false

while [ $# -gt 0 ]; do
  case "$1" in
    --output)
      output_file="$2"
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
    --min-effectiveness)
      min_effectiveness="$2"
      shift 2
      ;;
    --anonymize)
      anonymize=true
      shift
      ;;
    --include-metadata)
      include_metadata=true
      shift
      ;;
    *)
      echo "❌ Unknown argument: $1"
      exit 1
      ;;
  esac
done
```

### Step 2: Load and Filter Patterns

```bash
patterns_file="code-review-patterns.yaml"

if [ ! -f "$patterns_file" ]; then
  echo "❌ Patterns file not found: $patterns_file"
  exit 1
fi

filtered_patterns=$(python3 << 'EOF'
import yaml
import json
from datetime import datetime

with open('$patterns_file') as f:
    data = yaml.safe_load(f)

patterns = data.get('patterns', [])

# Apply filters
if "$category":
    patterns = [p for p in patterns if p.get('category') == "$category"]

if "$priority":
    patterns = [p for p in patterns if p.get('priority') == "$priority"]

if "$min_effectiveness":
    min_eff = float("$min_effectiveness")
    patterns = [p for p in patterns
                if (1 - p.get('metadata', {}).get('falsePositiveRate', 1)) >= min_eff]

# Anonymize if requested
anonymize = "$anonymize" == "true"
if anonymize:
    for pattern in patterns:
        # Remove source details
        if 'source' in pattern:
            pattern['source'] = {
                'system': 'anonymized',
                'pr': 0,
                'reviewer': 'Anonymous',
                'date': '2025-01-01'
            }

        # Remove specific file paths in examples
        if 'examples' in pattern:
            for example in pattern['examples']:
                if 'file' in example:
                    # Keep just filename, remove project path
                    example['file'] = example['file'].split('/')[-1]

# Remove metadata if not requested
include_meta = "$include_metadata" == "true"
if not include_meta:
    for pattern in patterns:
        if 'metadata' in pattern:
            # Reset metadata for fresh start in new project
            pattern['metadata'] = {
                'timesDetected': 0,
                'lastDetected': None,
                'falsePositives': 0,
                'falsePositiveRate': 0.0,
                'avgFixTime': None,
                'totalTimeSaved': None,
                'created': datetime.now().isoformat() + 'Z',
                'updated': None
            }

result = {
    'schemaVersion': data.get('schemaVersion', '1.0.0'),
    'exported': datetime.now().isoformat() + 'Z',
    'exportedBy': 'Pattern Export Tool',
    'patterns': patterns
}

print(json.dumps(result))
EOF
)
```

### Step 3: Generate Export File

```bash
python3 << 'EOF'
import yaml
import json

filtered = json.loads('''$filtered_patterns''')

# Write to YAML
with open('$output_file', 'w') as f:
    # Write header comment
    f.write("# Exported Code Review Patterns\n")
    f.write(f"# Exported: {filtered['exported']}\n")
    f.write(f"# Pattern Count: {len(filtered['patterns'])}\n")
    f.write("#\n")
    f.write("# Import these patterns into your project:\n")
    f.write("#   /import-patterns --source exported-patterns.yaml --review\n")
    f.write("\n")

    # Write patterns
    yaml.dump(filtered, f, default_flow_style=False, sort_keys=False)

print(f"✅ Exported {len(filtered['patterns'])} patterns to {args.output}")
EOF
```

### Step 4: Display Export Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pattern Export Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Exported: 2025-12-11 17:30:00 UTC
Output: my-project-patterns.yaml

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 EXPORT STATISTICS
────────────────────────────────────────────────────────
Total Patterns Exported: 15

By Category:
  • Architecture: 5 patterns
  • DependencyInjection: 4 patterns
  • Security: 3 patterns
  • Performance: 2 patterns
  • Testing: 1 pattern

By Priority:
  • High: 10 patterns
  • Medium: 4 patterns
  • Low: 1 pattern

Effectiveness Distribution:
  • 90-100%: 8 patterns
  • 80-90%: 5 patterns
  • 70-80%: 2 patterns

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 EXPORT DETAILS
────────────────────────────────────────────────────────
File Size: 24.5 KB
Anonymized: No
Metadata Included: Yes

Top Exported Patterns:
  1. ARCH-LAYER-001 (100% effectiveness)
  2. DI-LIFETIME-001 (91% effectiveness)
  3. SEC-LOGGING-001 (100% effectiveness)
  4. PERF-ASYNC-001 (88% effectiveness)
  5. TEST-COVERAGE-001 (85% effectiveness)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 SHARING OPTIONS
────────────────────────────────────────────────────────

Share with team:
  • Add to shared repo: git clone team-patterns && cp my-project-patterns.yaml team-patterns/
  • Upload to wiki or documentation
  • Share via Slack/Teams

Import into another project:
  cd /path/to/other-project
  /import-patterns --source /path/to/my-project-patterns.yaml --review

Create pull request:
  • Add patterns to team's central pattern library
  • Submit as contribution to open source project
```

## Export Examples

### Export high-value patterns

```bash
/export-patterns \
  --min-effectiveness 0.85 \
  --priority High \
  --output high-value-patterns.yaml
```

### Export for public sharing (anonymized)

```bash
/export-patterns \
  --anonymize \
  --output public-patterns.yaml
```

### Export specific category

```bash
/export-patterns \
  --category Security \
  --include-metadata \
  --output security-patterns.yaml
```

### Backup all patterns

```bash
/export-patterns \
  --include-metadata \
  --output backup-$(date +%Y%m%d).yaml
```

## Exported File Format

```yaml
# Exported Code Review Patterns
# Exported: 2025-12-11T17:30:00Z
# Pattern Count: 15

schemaVersion: "1.0.0"
exported: "2025-12-11T17:30:00Z"
exportedBy: "Pattern Export Tool"

patterns:
  - id: ARCH-LAYER-001
    category: Architecture
    priority: High
    title: Controllers must not reference Infrastructure
    source:
      system: github
      pr: 1045
      reviewer: Ali Bijanfar
      date: 2025-01-15
    rule: >
      Controllers in Api layer must not reference Infrastructure layer directly.
      Use Application layer abstractions instead.
    antiPattern: |
      // BAD
      public class PaymentController : ControllerBase
      {
          private readonly PaymentRepository _repo; // Direct Infrastructure reference
      }
    correctPattern: |
      // GOOD
      public class PaymentController : ControllerBase
      {
          private readonly IPaymentService _service; // Application abstraction
      }
    detection:
      files: ["**/Controllers/*.cs", "**/Api/**/*.cs"]
      pattern: "using \\w+\\.Infrastructure\\."
      validation: "Check if using statement is in Api project"
    remediation: >
      1. Create interface in Application layer
      2. Implement interface in Infrastructure
      3. Inject Application interface in Controller
    metadata:
      timesDetected: 15
      lastDetected: "2025-12-10T14:30:00Z"
      falsePositives: 0
      falsePositiveRate: 0.0
      avgFixTime: "5 minutes"
      totalTimeSaved: "75 minutes"
      created: "2025-01-15T10:00:00Z"
      updated: "2025-12-10T14:30:00Z"
```

## Integration

### Automated backup

```bash
# Cron job: Daily pattern backup
0 2 * * * /export-patterns --include-metadata --output ~/backups/patterns-$(date +\%Y\%m\%d).yaml
```

### CI/CD export

```yaml
# .github/workflows/export-patterns.yml
name: Export Patterns
on:
  release:
    types: [published]

jobs:
  export:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Export patterns
        run: /export-patterns --min-effectiveness 0.8 --output patterns-v${{ github.ref }}.yaml
      - name: Upload to release
        uses: actions/upload-release-asset@v1
        with:
          upload_url: ${{ github.event.release.upload_url }}
          asset_path: patterns-v${{ github.ref }}.yaml
```

## Related Commands

- `/import-patterns` - Import patterns from another project
- `/pattern-report` - View pattern effectiveness
- `/pattern-evolve` - Analyze and improve patterns

---

*Created: 2025-12-11*
*Part of: PR Feedback Learning Loop (Phase 4.4)*
