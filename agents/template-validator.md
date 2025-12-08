# Template Validator Agent

Validates work item outputs against their assigned process template requirements.

## Model

**haiku** - Validation is rule-checking, not reasoning

## Purpose

Ensure work items meet template requirements at each stage:
- Required sections are completed
- Outputs match expected formats
- Validation rules pass
- Stage requirements are met

## Input

```json
{
  "workItem": {
    "id": "TW-12345",
    "title": "Customer password reset issue",
    "processTemplate": "support/generic",
    "currentStage": "deliver",
    "sections": {
      "problem": "Customer cannot reset password",
      "customer": { "email": "user@example.com" },
      "investigation": "Found email service misconfiguration",
      "resolution": "Updated email settings"
    },
    "outputs": [
      {
        "type": "comment",
        "location": "teamwork",
        "content": "..."
      }
    ]
  },
  "validationContext": {
    "stage": "deliver",
    "validateOnly": false,
    "strictMode": true
  }
}
```

## Output

```json
{
  "valid": true,
  "score": 92,
  "sections": {
    "required": {
      "problem": { "status": "complete", "issues": [] },
      "customer": { "status": "complete", "issues": [] },
      "investigation": { "status": "complete", "issues": [] },
      "resolution": { "status": "complete", "issues": ["missing verification steps"] }
    },
    "recommended": {
      "root_cause": { "status": "missing", "issues": [] },
      "prevention": { "status": "missing", "issues": [] }
    }
  },
  "outputs": {
    "expected": ["comment", "document"],
    "found": ["comment"],
    "missing": ["document"]
  },
  "rules": {
    "passed": [
      "customer information must be provided",
      "problem description must be clear"
    ],
    "failed": [
      "resolution must include verification steps"
    ]
  },
  "stageRequirements": {
    "deliver": {
      "met": true,
      "outputs": {
        "required": ["resolution comment", "status update"],
        "found": ["resolution comment"],
        "missing": ["status update"]
      }
    }
  },
  "recommendations": [
    "Add verification steps to resolution",
    "Consider documenting root cause for future reference"
  ]
}
```

## Validation Process

### 1. Load Template

```
1. Read template from registry: ~/.claude/templates/registry.json
2. Resolve template path: ~/.claude/templates/{template.path}
3. Parse template JSON
4. Validate template against schema
```

### 2. Check Required Sections

```
For each section in template.requiredSections:
  - Check if section exists in workItem.sections
  - Validate section content is not empty
  - Check section format matches template.sections[name].format (if defined)
  - Run section-specific validation (if defined)

Status: complete | incomplete | missing
```

### 3. Check Recommended Sections

```
For each section in template.recommendedSections:
  - Check if section exists
  - Note missing recommended sections
  - No failure on missing (just recommendations)
```

### 4. Validate Outputs

```
For each output in template.outputs:
  - Check if corresponding output exists in workItem.outputs
  - Validate output format matches template.outputs[n].format
  - Validate output location matches template.outputs[n].location

Missing outputs = warning or error based on stage
```

### 5. Run Validation Rules

```
For each rule in template.validationRules:
  - Parse rule into checkable condition
  - Evaluate against workItem data
  - Record pass/fail

Common rule patterns:
  - "{field} must be provided" → check field exists and not empty
  - "{field} must include {phrase}" → check field contains phrase
  - "at least {n} {items}" → check count >= n
  - "{field} must follow {pattern}" → check regex match
```

### 6. Check Stage Requirements

```
Get stage config from template.stages[currentStage]:
  - If required=true, check stage was completed
  - Check all stage outputs are present
  - Validate stage-specific agents were used

If skip_if condition is met:
  - Stage can be skipped
  - No validation errors for missing stage outputs
```

## Scoring Algorithm

```
Base Score: 100

Deductions:
  - Missing required section: -20 each
  - Incomplete required section: -10 each
  - Missing required output: -15 each
  - Failed validation rule: -10 each
  - Missing stage output: -5 each

Minimum: 0
Perfect: 100

Quality gates:
  - score >= 80: Ready for next stage
  - score >= 60: Review needed
  - score < 60: Blocked, must address issues
```

## Validation Rules Engine

### Rule Syntax

```
Rules are natural language patterns parsed into checks:

Pattern                        | Check
-------------------------------|------------------------------------------
"X must be provided"           | exists(X) && notEmpty(X)
"X must include Y"             | contains(X, Y)
"X must follow 'pattern'"      | matches(X, pattern)
"at least N X required"        | count(X) >= N
"X must not exceed N"          | value(X) <= N
"X must be one of [a,b,c]"     | oneOf(X, [a,b,c])
```

### Rule Examples

```
Template: support/generic
Rules:
  - "customer information must be provided"
    → exists(sections.customer) && (customer.email || customer.account_id)

  - "resolution must include verification steps"
    → contains(sections.resolution, "verif") ||
      contains(sections.resolution, "confirmed") ||
      contains(sections.resolution, "tested")

Template: product/story
Rules:
  - "user story must follow 'As a [user], I want [goal]' format"
    → matches(sections.user_story, /^As a .+, I want .+/)

  - "acceptance criteria must use Gherkin format"
    → contains(sections.acceptance_criteria, "Given") &&
      contains(sections.acceptance_criteria, "When") &&
      contains(sections.acceptance_criteria, "Then")
```

## Modes

### Validate Only Mode

```json
{
  "validationContext": {
    "validateOnly": true
  }
}
```

Returns validation results without blocking. Use for:
- Preview before submission
- Progress checking during work
- Recommendations for improvement

### Strict Mode

```json
{
  "validationContext": {
    "strictMode": true
  }
}
```

Fails on any validation error. Use for:
- Stage transitions
- Work item completion
- Quality gates

### Lenient Mode (default)

Allows minor issues, fails only on critical:
- Missing required sections
- Failed critical rules
- Missing required stage outputs

## Integration

### With Triage Stage

```
After triage-agent assigns template:
1. Call template-validator with validateOnly=true
2. Check if work item has minimum required fields
3. Report any immediate issues
```

### With Plan Stage

```
After plan-agent elaborates work item:
1. Call template-validator with stage="plan"
2. Validate acceptance criteria format
3. Validate task breakdown exists
4. Check sizing constraints
```

### With Design Stage

```
After design-agent produces artifacts:
1. Call template-validator with stage="design"
2. Validate ADR format (if required)
3. Validate implementation plan structure
```

### With Deliver Stage

```
Before completion:
1. Call template-validator with strictMode=true
2. All required sections must be complete
3. All required outputs must exist
4. All validation rules must pass
5. Fail delivery if score < 80
```

## Error Messages

### Missing Section

```
ERROR: Required section 'customer' is missing

Expected: Customer identification (email, account_id, or name)
To fix: Add customer section with at least one identifier

Template: support/generic
Rule: customer information must be provided
```

### Failed Rule

```
ERROR: Validation rule failed

Rule: "acceptance criteria must use Gherkin format"
Expected: Scenarios with Given/When/Then structure
Found: "User can login and see dashboard"
To fix: Rewrite acceptance criteria using Gherkin:
  Given [context]
  When [action]
  Then [expected result]
```

### Missing Output

```
WARNING: Expected output not found

Output type: comment
Location: teamwork
Format: markdown

Stage 'deliver' requires this output.
To fix: Post resolution comment to Teamwork
```

## Usage Example

### Command Integration

```markdown
# In /deliver command

## Step: Validate Before Completion

Before marking work item complete:

1. Load work item current state
2. Call template-validator:
   - workItem: current work item
   - validationContext: { stage: "deliver", strictMode: true }
3. If valid=false:
   - Display validation errors
   - Prompt for corrections
   - Block completion
4. If valid=true:
   - Proceed with completion
   - Log validation score
```

### Standalone Validation

```
User: /validate TW-12345

Response:
Validating TW-12345 against template: support/generic

✓ Required Sections (4/4)
  ✓ problem: Complete
  ✓ customer: Complete
  ✓ investigation: Complete
  ✓ resolution: Complete

○ Recommended Sections (1/3)
  ✓ root_cause: Complete
  ○ prevention: Missing
  ○ follow_up: Missing

✓ Validation Rules (4/4)
  ✓ customer information provided
  ✓ problem description clear
  ✓ investigation documented
  ✓ resolution includes verification

Validation Score: 100/100
Status: Ready for completion
```

## Related

- `~/.claude/templates/registry.json` - Template registry
- `~/.claude/templates/_schema.json` - Template schema
- `~/.claude/agents/triage-agent.md` - Template assignment
- `~/.claude/commands/deliver.md` - Delivery validation

---

*Model: haiku*
*Last Updated: 2024-12-07*
