# Template Validator Agent

Validate work item outputs against their assigned process template requirements.

## Overview

| Property | Value |
|----------|-------|
| **Name** | template-validator |
| **Model** | haiku |
| **Tools** | Read |
| **Stage** | Cross-cutting |

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
      { "type": "comment", "location": "teamwork" }
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
      "resolution": { "status": "complete", "issues": ["missing verification"] }
    },
    "recommended": {
      "root_cause": { "status": "missing", "issues": [] }
    }
  },
  "outputs": {
    "expected": ["comment", "document"],
    "found": ["comment"],
    "missing": ["document"]
  },
  "rules": {
    "passed": ["customer info provided", "problem clear"],
    "failed": ["resolution needs verification"]
  },
  "recommendations": [
    "Add verification steps to resolution"
  ]
}
```

## Validation Process

### 1. Load Template

```
1. Read template from registry: ~/.claude/templates/registry.json
2. Resolve template path
3. Parse template JSON
4. Validate template against schema
```

### 2. Check Required Sections

For each section in `template.requiredSections`:
- Check if section exists
- Validate content is not empty
- Check format matches template spec
- Run section-specific validation

**Status:** `complete` | `incomplete` | `missing`

### 3. Check Recommended Sections

For each section in `template.recommendedSections`:
- Check if section exists
- Note missing recommended sections
- No failure on missing (just recommendations)

### 4. Validate Outputs

For each output in `template.outputs`:
- Check if output exists
- Validate format matches spec
- Validate location matches spec

### 5. Run Validation Rules

For each rule in `template.validationRules`:
- Parse rule into checkable condition
- Evaluate against workItem data
- Record pass/fail

**Common Rule Patterns:**

| Pattern | Check |
|---------|-------|
| "{field} must be provided" | exists(field) && notEmpty(field) |
| "{field} must include {phrase}" | contains(field, phrase) |
| "at least {n} {items}" | count(items) >= n |
| "{field} must follow {pattern}" | matches(field, pattern) |

### 6. Check Stage Requirements

Get stage config from `template.stages[currentStage]`:
- If required=true, check stage was completed
- Check all stage outputs are present
- Validate stage-specific agents were used

## Scoring Algorithm

```
Base Score: 100

Deductions:
  - Missing required section: -20 each
  - Incomplete required section: -10 each
  - Missing required output: -15 each
  - Failed validation rule: -10 each
  - Missing stage output: -5 each

Quality gates:
  - score >= 80: Ready for next stage
  - score >= 60: Review needed
  - score < 60: Blocked, must address issues
```

## Validation Modes

### Validate Only Mode

```json
{ "validateOnly": true }
```

Returns results without blocking. Use for:
- Preview before submission
- Progress checking during work
- Recommendations for improvement

### Strict Mode

```json
{ "strictMode": true }
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

## Stage Integration

### With Triage Stage

After triage-agent assigns template:
1. Validate with `validateOnly=true`
2. Check minimum required fields
3. Report immediate issues

### With Plan Stage

After plan-agent elaborates:
1. Validate acceptance criteria format
2. Validate task breakdown exists
3. Check sizing constraints

### With Deliver Stage

Before completion:
1. Validate with `strictMode=true`
2. All required sections complete
3. All outputs exist
4. Fail if score < 80

## Error Messages

### Missing Section

```
ERROR: Required section 'customer' is missing

Expected: Customer identification
To fix: Add customer section with at least one identifier
```

### Failed Rule

```
ERROR: Validation rule failed

Rule: "acceptance criteria must use Gherkin format"
Expected: Scenarios with Given/When/Then
To fix: Rewrite using Gherkin format
```

## Rule Examples

**support/generic:**
```
- "customer information must be provided"
  → exists(customer.email) || exists(customer.account_id)

- "resolution must include verification"
  → contains(resolution, "verified") || contains(resolution, "tested")
```

**product/story:**
```
- "user story must follow format"
  → matches(user_story, /^As a .+, I want .+/)

- "acceptance criteria must use Gherkin"
  → contains(criteria, "Given") && contains(criteria, "When")
```

## Focus Areas

- **Completeness** - All required fields validated
- **Consistency** - Same template, same validation
- **Clarity** - Clear error messages with fix suggestions
- **Flexibility** - Multiple validation modes

## Integration Points

| Agent | Direction | Data |
|-------|-----------|------|
| triage-agent | Called by | Template validation after assignment |
| plan-agent | Called by | Acceptance criteria validation |
| deliver workflow | Called by | Completion validation |

## Related

- [triage-agent](triage-agent.md) - Assigns templates
- [plan-agent](plan-agent.md) - Elaborates work items
- [index](index.md) - Agent overview
