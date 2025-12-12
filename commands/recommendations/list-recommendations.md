---
name: list-recommendations
description: List architecture recommendations from architecture-recommendations.json with filtering options
---

# List Recommendations Command

Display architecture recommendations organized by type (guardrails, leverage, hygiene) with filtering and search capabilities.

## Usage

```
/list-recommendations                        # Show all recommendations
/list-recommendations --type guardrails      # Show only guardrails
/list-recommendations --type leverage        # Show only leverage patterns
/list-recommendations --type hygiene         # Show only hygiene rules
/list-recommendations --category Security    # Filter by category
/list-recommendations --priority Critical    # Filter by priority
/list-recommendations --disabled             # Show disabled recommendations
/list-recommendations --enabled              # Show only enabled recommendations (default)
/list-recommendations --search "domain"      # Search in titles and descriptions
```

## Recommendation Types

The architecture recommendations system uses three types:

| Type | Priority Range | Description | Application |
|------|---------------|-------------|-------------|
| **Guardrails** | Critical, High, Medium | Critical rules that MUST be followed | Enforced in code-review and design |
| **Leverage** | Medium | Sanctioned improvements that SHOULD be applied | Suggested during design and code-review |
| **Hygiene** | Low | Nice-to-have improvements applied when touching code | Applied opportunistically |

## Implementation

### Step 1: Parse Arguments

Parse command-line arguments to determine filters:

```bash
type=""           # guardrails, leverage, hygiene
category=""       # Architecture, Security, Performance, etc.
priority=""       # Critical, High, Medium, Low
disabled=false    # Show disabled recommendations
enabled=true      # Show enabled recommendations
search=""         # Search term
```

### Step 2: Load Recommendations File

Load `architecture-recommendations.json` from project root:

```bash
if [ ! -f "architecture-recommendations.json" ]; then
  echo "❌ No architecture-recommendations.json found"
  echo ""
  echo "Initialize with:"
  echo "  cp docs/templates/architecture-recommendations.example.json architecture-recommendations.json"
  echo ""
  echo "Or run:"
  echo "  /extract-review-patterns <pr-url>"
  exit 1
fi

recommendations=$(cat architecture-recommendations.json)
```

Validate schema:
```bash
# Check schema version
schemaVersion=$(echo "$recommendations" | jq -r '.schemaVersion')
if [ "$schemaVersion" != "1.0.0" ]; then
  echo "⚠️  Unknown schema version: $schemaVersion"
fi
```

### Step 3: Apply Filters

Filter recommendations based on arguments:

**Type filter:**
```bash
if [ -n "$type" ]; then
  case "$type" in
    guardrails)
      items=$(echo "$recommendations" | jq '.recommendations.guardrails')
      ;;
    leverage)
      items=$(echo "$recommendations" | jq '.recommendations.leverage')
      ;;
    hygiene)
      items=$(echo "$recommendations" | jq '.recommendations.hygiene')
      ;;
    *)
      echo "❌ Invalid type: $type"
      echo "Valid types: guardrails, leverage, hygiene"
      exit 1
      ;;
  esac
else
  # Show all types
  guardrails=$(echo "$recommendations" | jq '.recommendations.guardrails')
  leverage=$(echo "$recommendations" | jq '.recommendations.leverage')
  hygiene=$(echo "$recommendations" | jq '.recommendations.hygiene')
fi
```

**Category filter:**
```bash
if [ -n "$category" ]; then
  items=$(echo "$items" | jq --arg cat "$category" '[.[] | select(.category == $cat)]')
fi
```

**Priority filter:**
```bash
if [ -n "$priority" ]; then
  items=$(echo "$items" | jq --arg pri "$priority" '[.[] | select(.priority == $pri)]')
fi
```

**Enabled/disabled filter:**
```bash
if [ "$disabled" = true ]; then
  items=$(echo "$items" | jq '[.[] | select(.disabled == true)]')
elif [ "$enabled" = true ]; then
  items=$(echo "$items" | jq '[.[] | select(.disabled != true)]')
fi
```

**Search filter:**
```bash
if [ -n "$search" ]; then
  items=$(echo "$items" | jq --arg term "$search" \
    '[.[] | select(.title | ascii_downcase | contains($term | ascii_downcase)) or
            (.description | ascii_downcase | contains($term | ascii_downcase))]')
fi
```

### Step 4: Display Recommendations

Format and display recommendations based on type:

#### Summary View (no type filter)

```
🏗️  Architecture Recommendations

Last Updated: 2025-12-11T14:30:00Z
Source: pr-feedback-learning

📌 GUARDRAILS (3 critical rules)
   ARCH-G001  ✓  Domain layer must not reference Infrastructure
   ARCH-G002  ✓  Never log sensitive data
   ARCH-G003  ✓  Migration types must match entity definitions

💡 LEVERAGE PATTERNS (3 suggested improvements)
   ARCH-L001  ✓  Extract vendor-specific code to Infrastructure
   ARCH-L002  ✓  Filter at database level, not in memory
   ARCH-L003  ✓  Verify DI lifetime selection when adding services

🧹 HYGIENE RULES (3 quality practices)
   ARCH-H001  ✓  Add XML comments to public APIs
   ARCH-H002  ✓  Ensure audit fields on entities
   ARCH-H003  ✓  Add test cases when fixing bugs

Total: 9 recommendations (9 enabled, 0 disabled)

Use /list-recommendations --type <type> for details
Use /view-recommendation <id> to see full details
```

#### Detailed View (with type filter)

**Guardrails:**
```
📌 GUARDRAILS (3 items)

┌─────────────┬──────────────┬──────────────────────────────────────────────┬────────────────┐
│ ID          │ Priority     │ Title                                        │ Category       │
├─────────────┼──────────────┼──────────────────────────────────────────────┼────────────────┤
│ ARCH-G001   │ ⚠️  Critical │ Domain layer must not reference Infrastructure│ Architecture   │
│ ARCH-G002   │ ⚠️  Critical │ Never log sensitive data                      │ Security       │
│ ARCH-G003   │ 🔶 High      │ Migration types must match entity definitions │ Data           │
└─────────────┴──────────────┴──────────────────────────────────────────────┴────────────────┘

✓ All enabled  |  Enforced in: code-review, design

Use /view-recommendation <id> for full details
Use /disable-recommendation <id> to temporarily disable
```

**Leverage Patterns:**
```
💡 LEVERAGE PATTERNS (3 items)

┌─────────────┬──────────────────────────────────────────────┬──────────────────┐
│ ID          │ Title                                        │ Category         │
├─────────────┼──────────────────────────────────────────────┼──────────────────┤
│ ARCH-L001   │ Extract vendor-specific code to Infrastructure│ Refactoring     │
│ ARCH-L002   │ Filter at database level, not in memory      │ Performance      │
│ ARCH-L003   │ Verify DI lifetime selection                 │ DependencyInject │
└─────────────┴──────────────────────────────────────────────┴──────────────────┘

✓ All enabled  |  Suggested during: design, code-review

Use /view-recommendation <id> for pattern details
```

**Hygiene Rules:**
```
🧹 HYGIENE RULES (3 items)

┌─────────────┬──────────────────────────────────────────────┬──────────────────┐
│ ID          │ Title                                        │ Category         │
├─────────────┼──────────────────────────────────────────────┼──────────────────┤
│ ARCH-H001   │ Add XML comments to public APIs              │ Documentation    │
│ ARCH-H002   │ Ensure audit fields on entities              │ DataIntegrity    │
│ ARCH-H003   │ Add test cases when fixing bugs              │ Testing          │
└─────────────┴──────────────────────────────────────────────┴──────────────────┘

✓ All enabled  |  Applied when: touching related code

Use /view-recommendation <id> for trigger conditions
```

### Step 5: Display Statistics

Include summary statistics in output:

```
📊 Statistics
- Total recommendations: 9
- Guardrails: 3 (2 Critical, 1 High)
- Leverage patterns: 3
- Hygiene rules: 3
- Enabled: 9
- Disabled: 0
- Last updated: 2 days ago
```

### Step 6: Suggest Actions

Based on recommendations state, suggest relevant actions:

```
💡 Suggested Actions
- Run /view-recommendation ARCH-G001 to see enforcement details
- Run /code-review to apply guardrails to current branch
- Run /recommendation-stats to see usage analytics
```

## Priority Indicators

Visual indicators for priority levels:

| Priority | Indicator | Color |
|----------|-----------|-------|
| Critical | ⚠️  | Red |
| High     | 🔶 | Orange |
| Medium   | 🟡 | Yellow |
| Low      | ⚪ | Gray |

## Status Indicators

| Status | Indicator | Meaning |
|--------|-----------|---------|
| Enabled | ✓ | Active and enforced |
| Disabled | ✗ | Temporarily disabled |
| New | 🆕 | Added in last 7 days |

## Examples

### List all recommendations

```
> /list-recommendations

🏗️  Architecture Recommendations
...
Total: 9 recommendations (9 enabled, 0 disabled)
```

### List only guardrails

```
> /list-recommendations --type guardrails

📌 GUARDRAILS (3 items)
...
```

### Filter by category

```
> /list-recommendations --category Security

🏗️  Architecture Recommendations - Security

ARCH-G002  ✓  Never log sensitive data (Critical)
Category: Security
Type: Guardrail
```

### Search recommendations

```
> /list-recommendations --search "domain"

🏗️  Architecture Recommendations - Search: "domain"

ARCH-G001  ✓  Domain layer must not reference Infrastructure
Type: Guardrail  |  Priority: Critical  |  Category: Architecture
```

### Show disabled recommendations

```
> /list-recommendations --disabled

🏗️  Architecture Recommendations - Disabled

ARCH-G002  ✗  Never log sensitive data
Disabled by: George
Disabled on: 2025-12-10
Reason: Legacy migration in progress

Use /enable-recommendation ARCH-G002 to re-enable
```

## Error Handling

### File not found

```
❌ No architecture-recommendations.json found

This file should be in the project root directory.

Initialize with:
  cp docs/templates/architecture-recommendations.example.json architecture-recommendations.json

Or extract from PR feedback:
  /extract-review-patterns <pr-url>
```

### Invalid schema

```
⚠️  Invalid schema detected

Expected version: 1.0.0
Found version: 0.9.0

Update your architecture-recommendations.json to the latest schema.
See docs/schemas/architecture-recommendations.schema.json
```

### No recommendations match filter

```
ℹ️  No recommendations match your filters

Filters applied:
- Type: guardrails
- Category: Performance
- Priority: Critical

Try:
- Remove some filters
- Check spelling of category/priority
- Use /list-recommendations to see all
```

## Integration

### With /view-recommendation

Each recommendation ID can be viewed in detail:
```
> /list-recommendations --type guardrails
> /view-recommendation ARCH-G001
```

### With /code-review

Guardrails are automatically applied during code review:
```
> /list-recommendations --type guardrails
> /code-review
# Applies all enabled guardrails
```

### With /design

Recommendations inform design decisions:
```
> /list-recommendations --type leverage
> /design WI-12345
# Design agent considers leverage patterns
```

### With /disable-recommendation

Temporarily disable a recommendation:
```
> /list-recommendations
> /disable-recommendation ARCH-G001 --reason "Legacy code migration"
```

## Configuration

Recommendations are stored in:
- **Main file:** `architecture-recommendations.json` (project root)
- **Schema:** `docs/schemas/architecture-recommendations.schema.json`
- **Template:** `docs/templates/architecture-recommendations.example.json`

## Related Commands

- `/view-recommendation <id>` - View full details of a recommendation
- `/disable-recommendation <id>` - Disable a recommendation
- `/enable-recommendation <id>` - Re-enable a recommendation
- `/recommendation-stats` - View usage statistics
- `/extract-review-patterns` - Extract new recommendations from PR feedback

---

*Created: 2025-12-11*
*Part of: PR Feedback Learning Loop (Phase 2.5)*
