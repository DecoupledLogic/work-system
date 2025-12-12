---
name: validate-playbook
description: Validate agent-playbook.yaml against schema and check for common issues
---

# Validate Playbook Command

Validate the agent-playbook.yaml file against its JSON schema, check for common issues, and ensure all rules are properly formatted with required fields.

## Usage

```
/validate-playbook                    # Validate default playbook
/validate-playbook --file <path>      # Validate specific playbook file
/validate-playbook --strict           # Enable strict validation
/validate-playbook --fix              # Auto-fix common issues
```

## Purpose

Ensure playbook quality and consistency by:
- Validating against JSON schema
- Checking ID format and uniqueness
- Verifying required fields are present
- Detecting missing metadata
- Finding duplicate rules
- Validating PR source references

## Implementation

### Step 1: Parse Arguments

```bash
file=".claude/agent-playbook.yaml"
strict=false
fix=false

while [ $# -gt 0 ]; do
  case "$1" in
    --file)
      file="$2"
      shift 2
      ;;
    --strict)
      strict=true
      shift
      ;;
    --fix)
      fix=true
      shift
      ;;
    *)
      echo "❌ Unknown argument: $1"
      exit 1
      ;;
  esac
done
```

### Step 2: Check File Exists

```bash
if [ ! -f "$file" ]; then
  echo "❌ Playbook file not found: $file"
  echo ""
  echo "Expected location: .claude/agent-playbook.yaml"
  echo ""
  echo "Initialize with:"
  echo "  cp docs/templates/agent-playbook.enhanced.yaml .claude/agent-playbook.yaml"
  exit 1
fi
```

### Step 3: Load and Parse YAML

```bash
# Convert YAML to JSON for validation
playbook_json=$(python3 -c "
import yaml, json, sys
try:
    with open('$file') as f:
        data = yaml.safe_load(f)
    print(json.dumps(data))
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
    sys.exit(1)
")

if [ $? -ne 0 ]; then
  echo "❌ Failed to parse YAML file"
  echo "$playbook_json"
  exit 1
fi
```

### Step 4: Validate Against Schema

```bash
schema_file="docs/schemas/agent-playbook.schema.json"

if [ ! -f "$schema_file" ]; then
  echo "⚠️  Schema file not found: $schema_file"
  echo "Skipping schema validation"
else
  # Validate using Python jsonschema
  validation_result=$(python3 << EOF
import json, sys
from jsonschema import validate, ValidationError

try:
    with open('$schema_file') as f:
        schema = json.load(f)

    playbook = json.loads('''$playbook_json''')
    validate(instance=playbook, schema=schema)
    print("VALID")
except ValidationError as e:
    print(f"INVALID: {e.message}")
    print(f"Path: {'.'.join(map(str, e.path))}")
    sys.exit(1)
except Exception as e:
    print(f"ERROR: {e}")
    sys.exit(1)
EOF
)

  if [ $? -ne 0 ]; then
    echo "❌ Schema validation failed"
    echo "$validation_result"
    exit 1
  fi

  echo "✅ Schema validation passed"
fi
```

### Step 5: Check Rule IDs

Validate ID formats and check for duplicates:

```bash
echo ""
echo "Checking rule IDs..."

# Extract all IDs from all layers
all_ids=$(echo "$playbook_json" | jq -r '
  [
    (.backend.guardrails[]?.id // empty),
    (.backend.patterns[]?.id // empty),
    (.backend.hygiene[]?.id // empty),
    (.frontend.guardrails[]?.id // empty),
    (.frontend.patterns[]?.id // empty),
    (.frontend.hygiene[]?.id // empty),
    (.data.guardrails[]?.id // empty),
    (.data.patterns[]?.id // empty),
    (.data.hygiene[]?.id // empty),
    (.improvementGuidelines.leverage[]?.id // empty),
    (.improvementGuidelines.experiments[]?.id // empty)
  ] | sort
')

# Check ID format
invalid_ids=()
while IFS= read -r id; do
  if [ -n "$id" ]; then
    # Guardrails: XX-G## (e.g., BE-G01)
    # Patterns: XX-P## (e.g., BE-P01)
    # Hygiene: XX-H## (e.g., BE-H01)
    # Leverage: IMP-L## (e.g., IMP-L01)
    # Experiments: IMP-E## (e.g., IMP-E01)
    if ! echo "$id" | grep -qE '^([A-Z]{2,3}-[GPH][0-9]{2}|IMP-[LE][0-9]{2})$'; then
      invalid_ids+=("$id")
    fi
  fi
done <<< "$all_ids"

if [ ${#invalid_ids[@]} -gt 0 ]; then
  echo "❌ Invalid ID formats found:"
  for id in "${invalid_ids[@]}"; do
    echo "  - $id"
  done
  echo ""
  echo "Valid formats:"
  echo "  - Guardrails: BE-G01, FE-G01, DB-G01"
  echo "  - Patterns: BE-P01, FE-P01, DB-P01"
  echo "  - Hygiene: BE-H01, FE-H01, DB-H01"
  echo "  - Leverage: IMP-L01"
  echo "  - Experiments: IMP-E01"
  exit 1
else
  echo "✅ All IDs have valid formats"
fi

# Check for duplicates
duplicate_ids=$(echo "$all_ids" | sort | uniq -d)
if [ -n "$duplicate_ids" ]; then
  echo "❌ Duplicate IDs found:"
  echo "$duplicate_ids"
  exit 1
else
  echo "✅ No duplicate IDs"
fi
```

### Step 6: Check Required Fields

Ensure all rules have required fields:

```bash
echo ""
echo "Checking required fields..."

# Check guardrails have required fields
missing_fields=false

# Backend guardrails
backend_issues=$(echo "$playbook_json" | jq -r '
  .backend.guardrails[]? |
  select(.id == null or .description == null) |
  "Missing fields in guardrail: \(.id // "unknown")"
')

if [ -n "$backend_issues" ]; then
  echo "❌ Backend guardrail issues:"
  echo "$backend_issues"
  missing_fields=true
fi

# Similar checks for frontend, data, patterns, hygiene...

if [ "$missing_fields" = true ]; then
  echo ""
  echo "Fix missing fields or use --fix to auto-correct"
  exit 1
else
  echo "✅ All rules have required fields"
fi
```

### Step 7: Validate PR Sources

Check PR source references are properly formatted:

```bash
echo ""
echo "Checking PR sources..."

# Find rules with source: pr-feedback
pr_feedback_rules=$(echo "$playbook_json" | jq -r '
  [
    (.backend.guardrails[]? | select(.source == "pr-feedback")),
    (.backend.patterns[]? | select(.source == "pr-feedback")),
    (.backend.hygiene[]? | select(.source == "pr-feedback")),
    (.frontend.guardrails[]? | select(.source == "pr-feedback")),
    (.frontend.patterns[]? | select(.source == "pr-feedback")),
    (.frontend.hygiene[]? | select(.source == "pr-feedback")),
    (.data.guardrails[]? | select(.source == "pr-feedback"))
  ] | .[]
')

# Check each has prSource with required fields
pr_source_issues=()
while IFS= read -r rule; do
  if [ -n "$rule" ]; then
    id=$(echo "$rule" | jq -r '.id')
    has_pr=$(echo "$rule" | jq -r '.prSource.pr')
    has_reviewer=$(echo "$rule" | jq -r '.prSource.reviewer')
    has_date=$(echo "$rule" | jq -r '.prSource.date')

    if [ "$has_pr" = "null" ] || [ "$has_reviewer" = "null" ] || [ "$has_date" = "null" ]; then
      pr_source_issues+=("$id: Missing prSource fields")
    fi
  fi
done <<< "$pr_feedback_rules"

if [ ${#pr_source_issues[@]} -gt 0 ]; then
  echo "❌ PR source validation issues:"
  for issue in "${pr_source_issues[@]}"; do
    echo "  - $issue"
  done
  exit 1
else
  echo "✅ All PR sources properly formatted"
fi
```

### Step 8: Check Metadata Fields

Validate metadata tracking fields:

```bash
echo ""
echo "Checking metadata..."

# Count rules with metadata
rules_with_metadata=$(echo "$playbook_json" | jq '
  [
    (.backend.guardrails[]? | select(.metadata != null)),
    (.backend.patterns[]? | select(.metadata != null)),
    (.backend.hygiene[]? | select(.metadata != null))
  ] | length
')

total_rules=$(echo "$playbook_json" | jq '
  [
    (.backend.guardrails[]?),
    (.backend.patterns[]?),
    (.backend.hygiene[]?)
  ] | length
')

metadata_percent=$(echo "scale=0; $rules_with_metadata * 100 / $total_rules" | bc)

echo "📊 Metadata coverage: $rules_with_metadata/$total_rules ($metadata_percent%)"

if [ "$metadata_percent" -lt 50 ] && [ "$strict" = true ]; then
  echo "⚠️  Low metadata coverage in strict mode"
  echo "Consider adding metadata fields to track usage"
fi
```

### Step 9: Generate Report

```
✅ Playbook Validation Report

File: .claude/agent-playbook.yaml
Schema: docs/schemas/agent-playbook.schema.json

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ PASSED CHECKS
────────────────────────────────────────────────────────
✓ Schema validation
✓ ID format validation
✓ No duplicate IDs
✓ Required fields present
✓ PR sources properly formatted
✓ Metadata fields valid

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 STATISTICS
────────────────────────────────────────────────────────
Total Rules: 24
  • Guardrails: 9 (3 backend, 4 frontend, 2 data)
  • Patterns: 6 (3 backend, 2 frontend, 1 data)
  • Hygiene: 7 (4 backend, 2 frontend, 1 data)
  • Leverage: 2

From PR Feedback: 8 rules (33%)
Metadata Coverage: 18/24 (75%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Playbook is valid and ready to use

Next steps:
  • Use /check-playbook-conflicts to detect rule conflicts
  • Use /playbook-stats to see detailed usage analytics
```

## Auto-Fix Mode

When `--fix` is enabled, automatically correct common issues:

```bash
if [ "$fix" = true ]; then
  echo ""
  echo "🔧 Auto-fixing issues..."

  # Fix missing metadata fields
  fixed_playbook=$(echo "$playbook_json" | jq '
    # Add default metadata to rules missing it
    (.backend.guardrails[]? | select(.metadata == null)) |= . + {
      "metadata": {
        "timesTriggered": 0,
        "falsePositives": 0,
        "lastTriggered": null,
        "created": (now | todate)
      }
    }
  ')

  # Write back to file
  echo "$fixed_playbook" | python3 -c "
import yaml, json, sys
data = json.load(sys.stdin)
with open('$file', 'w') as f:
    yaml.dump(data, f, default_flow_style=False)
  "

  echo "✅ Fixed missing metadata fields"
fi
```

## Error Examples

### Invalid ID Format

```
❌ Invalid ID formats found:
  - BACKEND-G01 (should be BE-G01)
  - FE-GUARD-01 (should be FE-G01)

Valid formats:
  - Guardrails: BE-G01, FE-G01, DB-G01
  - Patterns: BE-P01, FE-P01, DB-P01
```

### Missing PR Source

```
❌ PR source validation issues:
  - BE-G05: Missing prSource fields
    Rule has source: pr-feedback but no prSource.pr
```

### Duplicate IDs

```
❌ Duplicate IDs found:
BE-G01
FE-P02

Check your playbook for duplicate rule IDs
```

## Integration

### With /extract-review-patterns

Validate after extracting patterns:
```
> /extract-review-patterns <pr-url>
> /validate-playbook
```

### With /deliver

Validate before delivery to ensure clean configuration:
```
> /validate-playbook
> /deliver WI-12345
```

## Related Commands

- `/check-playbook-conflicts` - Detect conflicts between rules
- `/playbook-stats` - View playbook usage statistics
- `/extract-review-patterns` - Extract new rules from PR feedback

---

*Created: 2025-12-11*
*Part of: PR Feedback Learning Loop (Phase 3.4)*
