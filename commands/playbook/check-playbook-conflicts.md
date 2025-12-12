---
name: check-playbook-conflicts
description: Detect conflicts and contradictions between playbook rules
---

# Check Playbook Conflicts Command

Analyze agent-playbook.yaml to detect conflicting rules, contradictory guardrails, and overlapping patterns that could confuse agents or lead to inconsistent behavior.

## Usage

```
/check-playbook-conflicts                 # Check default playbook
/check-playbook-conflicts --file <path>   # Check specific playbook
/check-playbook-conflicts --verbose       # Show detailed conflict analysis
```

## Conflict Types Detected

| Type | Description | Severity |
|------|-------------|----------|
| **Contradictory Guardrails** | Two guardrails that can't both be satisfied | High |
| **Overlapping Patterns** | Multiple patterns apply to same scenario | Medium |
| **Conflicting Hygiene** | Hygiene rules that contradict each other | Low |
| **Layer Violations** | Rules that violate architecture layer boundaries | High |

## Implementation

### Step 1: Parse Arguments

```bash
file=".claude/agent-playbook.yaml"
verbose=false

while [ $# -gt 0 ]; do
  case "$1" in
    --file)
      file="$2"
      shift 2
      ;;
    --verbose)
      verbose=true
      shift
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

### Step 3: Check Guardrail Contradictions

Detect guardrails that contradict each other:

```python
import json

playbook = json.loads('''$playbook''')

contradictions = []

# Example: Check if any guardrail requires what another prohibits
backend_guardrails = playbook.get('backend', {}).get('guardrails', [])

for i, g1 in enumerate(backend_guardrails):
    for g2 in backend_guardrails[i+1:]:
        # Check for logical contradictions
        # Example: One says "Api must call Infrastructure"
        # Another says "Api must not call Infrastructure"

        desc1 = g1.get('description', '').lower()
        desc2 = g2.get('description', '').lower()

        # Simple keyword matching for common contradictions
        if 'must not' in desc1 and 'must' in desc2:
            # Extract subjects
            if any(word in desc1 and word in desc2 for word in ['api', 'domain', 'infrastructure']):
                contradictions.append({
                    'type': 'guardrail_contradiction',
                    'severity': 'high',
                    'rule1': g1.get('id'),
                    'rule2': g2.get('id'),
                    'description': f"Possible contradiction between {g1.get('id')} and {g2.get('id')}"
                })
```

### Step 4: Check Pattern Overlaps

Find patterns that apply to the same scenarios:

```bash
overlaps=()

# Get all patterns
backend_patterns=$(echo "$playbook" | jq -r '.backend.patterns[]? | @json')

# Compare patterns
while IFS= read -r p1_json; do
  p1_id=$(echo "$p1_json" | jq -r '.id')
  p1_when=$(echo "$p1_json" | jq -r '.when // ""' | tr '[:upper:]' '[:lower:]')

  while IFS= read -r p2_json; do
    p2_id=$(echo "$p2_json" | jq -r '.id')
    p2_when=$(echo "$p2_json" | jq -r '.when // ""' | tr '[:upper:]' '[:lower:]')

    if [ "$p1_id" != "$p2_id" ]; then
      # Check for keyword overlap
      common_words=$(comm -12 \
        <(echo "$p1_when" | tr ' ' '\n' | sort) \
        <(echo "$p2_when" | tr ' ' '\n' | sort) \
        | wc -l)

      if [ "$common_words" -gt 3 ]; then
        overlaps+=("$p1_id overlaps with $p2_id (common: $common_words words)")
      fi
    fi
  done <<< "$backend_patterns"
done <<< "$backend_patterns"
```

### Step 5: Check Layer Boundary Violations

Ensure rules don't violate architecture layers:

```bash
layer_violations=()

# Check if any guardrail allows something architecture prohibits
architecture_file=".claude/architecture.yaml"

if [ -f "$architecture_file" ]; then
  # Load architecture dependencies
  layer_deps=$(python3 -c "
import yaml
with open('$architecture_file') as f:
    arch = yaml.safe_load(f)

# Expected dependencies (example):
# Api -> Application -> Domain
# Api should NOT -> Infrastructure

# Check guardrails against this
backend_guardrails = '''$playbook''' |jq '.backend.guardrails[]?'
# ... validation logic ...
")
fi
```

### Step 6: Check Source Conflicts

Detect when PR feedback contradicts architecture review:

```bash
source_conflicts=()

# Find rules with conflicting sources
all_rules=$(echo "$playbook" | jq -r '
  [
    (.backend.guardrails[]? | {id, source, description}),
    (.frontend.guardrails[]? | {id, source, description}),
    (.data.guardrails[]? | {id, source, description})
  ] | .[]
')

# Group by similar descriptions from different sources
# If same concept has source: architecture-review and source: pr-feedback
# Check if they agree or conflict
```

### Step 7: Generate Conflict Report

```
🔍 Playbook Conflict Analysis

File: .claude/agent-playbook.yaml
Checked: 2025-12-11 15:30:00

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 HIGH SEVERITY CONFLICTS (2)
────────────────────────────────────────────────────────

1. Contradictory Guardrails
   BE-G01: "Controllers must not reference Infrastructure"
   BE-G03: "Business rules should not be in SQL"

   ⚠️  Conflict: BE-G01 prohibits Infrastructure references but
   BE-G03 implies business logic shouldn't be in SQL (which is in
   Infrastructure). This creates ambiguity about where query logic lives.

   Recommendation:
   • Clarify that Application layer queries (via repositories) are OK
   • Update BE-G01 description to: "Controllers must not reference
     Infrastructure directly; use Application layer"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟡 MEDIUM SEVERITY CONFLICTS (3)
────────────────────────────────────────────────────────

1. Overlapping Patterns
   BE-P01: "Command/Query Handler"
   BE-P02: "Repository pattern"

   ℹ️  Overlap: Both apply when "accessing persistence"
   Impact: Agent might be uncertain which pattern to follow

   Recommendation:
   • Update BE-P01 to reference BE-P02 in its steps
   • Make BE-P02 a sub-pattern of BE-P01

2. Source Conflict
   BE-H01: source=architecture-review
   BE-H04: source=pr-feedback

   ℹ️  Both recommend dependency injection best practices
   Impact: Possible redundancy or slight differences in guidance

   Recommendation:
   • Merge into single hygiene rule
   • Combine rationales from both sources

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟢 LOW SEVERITY ISSUES (1)
────────────────────────────────────────────────────────

1. Layer Boundary Ambiguity
   FE-G03: "HTTP calls must go through src/shared/api"
   FE-P01: "Create API helper in src/shared/api"

   ℹ️  Redundant: Guardrail and pattern say the same thing
   Impact: Minimal - just verbose

   Recommendation:
   • Keep guardrail (the constraint)
   • Update pattern to reference guardrail

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 SUMMARY
────────────────────────────────────────────────────────
Total Conflicts: 6
  • 🔴 High: 2 (resolve immediately)
  • 🟡 Medium: 3 (review and clarify)
  • 🟢 Low: 1 (optional improvement)

Conflict Rate: 25% (6 conflicts across 24 rules)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 RECOMMENDATIONS

1. Resolve High Severity Conflicts First
   • Update BE-G01 description for clarity
   • Add clarification comment in playbook

2. Merge Overlapping Rules
   • Combine BE-H01 and BE-H04
   • Reference patterns within patterns (hierarchy)

3. Document Relationships
   • Add "relatedRules" field to link related items
   • Show which patterns implement which guardrails

Next Steps:
  • Edit .claude/agent-playbook.yaml to resolve conflicts
  • Run /validate-playbook to verify changes
  • Use /playbook-stats to monitor effectiveness
```

## Verbose Output

When `--verbose` is enabled, show detailed analysis:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 DETAILED ANALYSIS: BE-G01 vs BE-G03
────────────────────────────────────────────────────────

BE-G01:
  ID: BE-G01
  Description: "Controllers must not reference Infrastructure"
  Enforcement: always
  Source: architecture-review

BE-G03:
  ID: BE-G03
  Description: "Business rules should not be in SQL"
  Enforcement: always
  Source: architecture-review

Conflict Detection:
  • Both mention "Infrastructure" and "rules"
  • BE-G01 prohibits direct Infrastructure reference
  • BE-G03 prohibits business logic in SQL (part of Infrastructure)
  • Unclear: Can Application layer use repositories (in Infrastructure)?

Resolution Options:
  1. Update BE-G01 to explicitly allow Application->Infrastructure
  2. Add new rule clarifying repository pattern is the correct approach
  3. Merge both into single rule with examples

Recommended:
  Option 2 - Keep both, add clarifying pattern
```

## Conflict Detection Algorithms

### Contradiction Detection

```python
def detect_contradictions(guardrails):
    contradictions = []

    for g1 in guardrails:
        for g2 in guardrails:
            if g1['id'] != g2['id']:
                # Check for opposite requirements
                if ('must not' in g1['description'].lower() and
                    'must' in g2['description'].lower()):

                    # Extract entities (Api, Domain, Infrastructure)
                    entities1 = extract_entities(g1['description'])
                    entities2 = extract_entities(g2['description'])

                    # If same entities mentioned, possible contradiction
                    if entities1.intersection(entities2):
                        contradictions.append((g1['id'], g2['id']))

    return contradictions
```

### Pattern Overlap Detection

```python
def detect_pattern_overlaps(patterns):
    overlaps = []

    for p1 in patterns:
        for p2 in patterns:
            if p1['id'] != p2['id']:
                # Compare 'when' conditions
                when1_words = set(p1.get('when', '').lower().split())
                when2_words = set(p2.get('when', '').lower().split())

                # Calculate overlap
                common = when1_words.intersection(when2_words)
                if len(common) > 3:
                    overlap_percent = len(common) / min(len(when1_words), len(when2_words))
                    overlaps.append({
                        'pattern1': p1['id'],
                        'pattern2': p2['id'],
                        'overlap': overlap_percent
                    })

    return overlaps
```

## Integration

### With /validate-playbook

Run after validation to check for conflicts:
```
> /validate-playbook
> /check-playbook-conflicts
```

### With /extract-review-patterns

Check for conflicts after adding new rules:
```
> /extract-review-patterns <pr-url>
> /check-playbook-conflicts
```

## Related Commands

- `/validate-playbook` - Validate playbook schema
- `/playbook-stats` - View usage statistics
- `/extract-review-patterns` - Add new rules from PR feedback

---

*Created: 2025-12-11*
*Part of: PR Feedback Learning Loop (Phase 3.4)*
