---
name: view-recommendation
description: View detailed information about a specific architecture recommendation
---

# View Recommendation Command

Display comprehensive details about a specific architecture recommendation including description, rationale, implementation guidance, and source information.

## Usage

```
/view-recommendation <id>              # View recommendation by ID
/view-recommendation ARCH-G001         # View guardrail
/view-recommendation ARCH-L001         # View leverage pattern
/view-recommendation ARCH-H001         # View hygiene rule
/view-recommendation ARCH-G001 --json  # Output as JSON
```

## ID Format

Recommendation IDs follow the pattern:

| Type | Format | Example |
|------|--------|---------|
| Guardrail | `ARCH-G###` | `ARCH-G001` |
| Leverage | `ARCH-L###` | `ARCH-L001` |
| Hygiene | `ARCH-H###` | `ARCH-H001` |

## Implementation

### Step 1: Parse Arguments

Extract recommendation ID and output format:

```bash
id="$1"
format="text"  # text or json

if [ -z "$id" ]; then
  echo "❌ Recommendation ID required"
  echo ""
  echo "Usage: /view-recommendation <id>"
  echo ""
  echo "Examples:"
  echo "  /view-recommendation ARCH-G001"
  echo "  /view-recommendation ARCH-L001"
  echo ""
  echo "Use /list-recommendations to see all IDs"
  exit 1
fi

# Check for --json flag
if [ "$2" = "--json" ]; then
  format="json"
fi
```

### Step 2: Validate ID Format

Ensure ID matches expected pattern:

```bash
if ! echo "$id" | grep -qE '^ARCH-[GLH][0-9]{3}$'; then
  echo "❌ Invalid recommendation ID format: $id"
  echo ""
  echo "Valid formats:"
  echo "  ARCH-G### - Guardrails (e.g., ARCH-G001)"
  echo "  ARCH-L### - Leverage patterns (e.g., ARCH-L001)"
  echo "  ARCH-H### - Hygiene rules (e.g., ARCH-H001)"
  exit 1
fi
```

### Step 3: Load and Find Recommendation

Load `architecture-recommendations.json` and search for the ID:

```bash
if [ ! -f "architecture-recommendations.json" ]; then
  echo "❌ No architecture-recommendations.json found"
  echo ""
  echo "Initialize with:"
  echo "  cp docs/templates/architecture-recommendations.example.json architecture-recommendations.json"
  exit 1
fi

recommendations=$(cat architecture-recommendations.json)

# Determine type from ID prefix
type=""
case "${id:5:1}" in
  G) type="guardrails" ;;
  L) type="leverage" ;;
  H) type="hygiene" ;;
esac

# Find recommendation
item=$(echo "$recommendations" | jq --arg id "$id" --arg type "$type" \
  '.recommendations[$type] | .[] | select(.id == $id)')

if [ -z "$item" ] || [ "$item" = "null" ]; then
  echo "❌ Recommendation not found: $id"
  echo ""
  echo "Use /list-recommendations to see all available IDs"
  exit 1
fi
```

### Step 4: Display Detailed View

Format output based on recommendation type:

#### Guardrail View

```
📌 GUARDRAIL: ARCH-G001

Title: Domain layer must not reference Infrastructure
Category: Architecture
Priority: ⚠️  Critical
Status: ✓ Enabled

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Description
────────────────────────────────────────────────────────
Keep domain layer pure - no dependencies on Infrastructure
layer. Domain entities and interfaces should have no knowledge
of persistence, HTTP, or external services.

💡 Rationale
────────────────────────────────────────────────────────
Maintaining clean architecture boundaries ensures domain logic
remains portable, testable, and independent of infrastructure
concerns. This enables easy migration to different data stores
or frameworks.

🔧 Implementation
────────────────────────────────────────────────────────
Check: Scan Domain project for Infrastructure references
       using pattern: using.*\.Infrastructure

Frequency: every-commit
Automation: code-review command

⚖️  Enforcement
────────────────────────────────────────────────────────
This guardrail is CRITICAL and will:
- Block PRs with violations
- Be enforced in /code-review
- Be checked during /design

📚 Source
────────────────────────────────────────────────────────
Type: PR Feedback
PR: #1045
Reviewer: Ali Bijanfar
Date: 2025-01-15

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 Related Commands
- /code-review          Check current code against this rule
- /disable-recommendation ARCH-G001  Disable temporarily
- /list-recommendations --type guardrails  See all guardrails
```

#### Leverage Pattern View

```
💡 LEVERAGE PATTERN: ARCH-L001

Title: Extract vendor-specific code to Infrastructure
Category: Refactoring
Priority: 🟡 Medium
Status: ✓ Enabled

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Pattern
────────────────────────────────────────────────────────
When touching Abstractions with vendor names (Staxbill, Stripe,
etc.), extract to Infrastructure

💎 Benefit
────────────────────────────────────────────────────────
Improves testability, enables vendor switching, keeps domain
layer clean and portable

🎯 When to Apply
────────────────────────────────────────────────────────
- Working with vendor-specific APIs
- Refactoring Abstractions layer
- Adding new third-party integrations
- Improving testability of domain logic

📚 Source
────────────────────────────────────────────────────────
Type: PR Feedback
PR: #1045
Reviewer: Ali Bijanfar
Date: 2025-01-15

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 Related Commands
- /design WI-12345      Design agent will suggest this pattern
- /code-review          Get suggestions to apply this pattern
- /list-recommendations --type leverage  See all patterns
```

#### Hygiene Rule View

```
🧹 HYGIENE RULE: ARCH-H001

Title: Add XML comments to public APIs
Category: Documentation
Priority: ⚪ Low
Status: ✓ Enabled

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎬 Trigger
────────────────────────────────────────────────────────
When modifying public interface or class

✅ Action
────────────────────────────────────────────────────────
Add /// summary comments describing purpose, parameters,
and return values

💎 Benefit
────────────────────────────────────────────────────────
Improves discoverability, enhances IntelliSense, helps
future developers understand APIs

🎯 Apply When
────────────────────────────────────────────────────────
- Creating new public methods
- Modifying existing public APIs
- Refactoring interfaces
- Already touching related code

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 Related Commands
- /code-review          Get suggestions for missing comments
- /deliver WI-12345     Dev agent applies hygiene rules
- /list-recommendations --type hygiene  See all hygiene rules
```

### Step 5: JSON Output (if requested)

When `--json` flag is used, output raw JSON:

```json
{
  "id": "ARCH-G001",
  "type": "guardrail",
  "category": "Architecture",
  "priority": "Critical",
  "title": "Domain layer must not reference Infrastructure",
  "description": "Keep domain layer pure...",
  "rationale": "Maintaining clean architecture boundaries...",
  "source": {
    "type": "pr-feedback",
    "pr": 1045,
    "reviewer": "Ali Bijanfar",
    "date": "2025-01-15"
  },
  "implementation": {
    "check": "Scan Domain project for Infrastructure references...",
    "frequency": "every-commit",
    "automation": "code-review command"
  },
  "disabled": false
}
```

### Step 6: Show Usage Context

Include context about where this recommendation is used:

For guardrails:
```
📊 Usage Context
- Applied in: /code-review, /design
- Enforcement: Blocking
- Last checked: 2 hours ago
- Violations found (last 7 days): 0
```

For leverage patterns:
```
📊 Usage Context
- Suggested in: /design, /code-review
- Times suggested (last 30 days): 5
- Times applied: 3 (60% adoption)
```

For hygiene rules:
```
📊 Usage Context
- Applied in: /deliver, /code-review
- Trigger frequency: ~10 times/week
- Applied opportunistically when touching related code
```

### Step 7: Suggest Related Actions

Based on recommendation type and status, suggest relevant actions:

```
💡 What you can do
- Run /code-review to check current code
- Run /disable-recommendation ARCH-G001 to disable temporarily
- Run /recommendation-stats to see analytics
- Edit architecture-recommendations.json to modify
```

## Display Sections by Type

### Guardrails Display

1. Header (ID, title, category, priority, status)
2. Description (what must be followed)
3. Rationale (why it matters)
4. Implementation (how to check)
5. Enforcement (what happens on violation)
6. Source (where it came from)
7. Usage context (current statistics)
8. Related commands

### Leverage Display

1. Header (ID, title, category, priority, status)
2. Pattern (when to apply)
3. Benefit (why it helps)
4. Application triggers
5. Source
6. Usage context
7. Related commands

### Hygiene Display

1. Header (ID, title, category, priority, status)
2. Trigger (when to consider)
3. Action (what to do)
4. Benefit (why it helps)
5. Application context
6. Usage context
7. Related commands

## Examples

### View a guardrail

```
> /view-recommendation ARCH-G001

📌 GUARDRAIL: ARCH-G001

Title: Domain layer must not reference Infrastructure
...
```

### View in JSON format

```
> /view-recommendation ARCH-G001 --json

{
  "id": "ARCH-G001",
  "type": "guardrail",
  ...
}
```

### View disabled recommendation

```
> /view-recommendation ARCH-G002

📌 GUARDRAIL: ARCH-G002

Title: Never log sensitive data
Status: ✗ DISABLED

⚠️  This recommendation is currently disabled

Disabled by: George
Disabled on: 2025-12-10T15:30:00Z
Reason: Legacy migration in progress

Use /enable-recommendation ARCH-G002 to re-enable

...
```

## Error Handling

### ID not provided

```
❌ Recommendation ID required

Usage: /view-recommendation <id>

Examples:
  /view-recommendation ARCH-G001
  /view-recommendation ARCH-L001

Use /list-recommendations to see all IDs
```

### Invalid ID format

```
❌ Invalid recommendation ID format: ARCH-X001

Valid formats:
  ARCH-G### - Guardrails (e.g., ARCH-G001)
  ARCH-L### - Leverage patterns (e.g., ARCH-L001)
  ARCH-H### - Hygiene rules (e.g., ARCH-H001)
```

### Recommendation not found

```
❌ Recommendation not found: ARCH-G999

The recommendation with ID ARCH-G999 does not exist.

Use /list-recommendations to see all available recommendations:
  /list-recommendations --type guardrails
```

### File not found

```
❌ No architecture-recommendations.json found

This file should be in the project root directory.

Initialize with:
  cp docs/templates/architecture-recommendations.example.json \\
     architecture-recommendations.json

Or extract from PR feedback:
  /extract-review-patterns <pr-url>
```

## Integration

### With /list-recommendations

Browse all recommendations, then view details:
```
> /list-recommendations --type guardrails
> /view-recommendation ARCH-G001
```

### With /code-review

View recommendation details when violations are found:
```
> /code-review
# Violation found: ARCH-G001
> /view-recommendation ARCH-G001
```

### With /disable-recommendation

View before disabling to confirm:
```
> /view-recommendation ARCH-G001
> /disable-recommendation ARCH-G001 --reason "Legacy migration"
```

### With /recommendation-stats

View recommendation, then check usage stats:
```
> /view-recommendation ARCH-L001
> /recommendation-stats ARCH-L001
```

## Configuration

Recommendations are stored in:
- **Main file:** `architecture-recommendations.json` (project root)
- **Schema:** `docs/schemas/architecture-recommendations.schema.json`
- **Template:** `docs/templates/architecture-recommendations.example.json`

## Related Commands

- `/list-recommendations` - Browse all recommendations
- `/disable-recommendation <id>` - Disable a recommendation
- `/enable-recommendation <id>` - Re-enable a recommendation
- `/recommendation-stats [id]` - View usage statistics
- `/code-review` - Apply guardrails to current code

---

*Created: 2025-12-11*
*Part of: PR Feedback Learning Loop (Phase 2.5)*
