# Process Templates

Templates define structured processes for different types of work. They specify what sections are required, what outputs are expected, and what validation rules apply.

## Overview

Templates are the "code" that drives agent behavior. When a work item is assigned a template, all agents processing that work item follow the template's requirements.

## Directory Structure

```
templates/
├── README.md                 # This file
├── _schema.json              # JSON schema for template validation
├── registry.json             # Template registry (Phase 7)
├── support/                  # Support workflow templates
│   ├── generic.json          # Generic support request
│   ├── remove-profile.json   # Account/profile deletion
│   └── subscription-change.json
├── product/                  # Product delivery templates
│   ├── prd.json              # Product Requirements Document
│   ├── feature.json          # Feature specification
│   └── story.json            # User story
└── delivery/                 # Technical delivery templates
    ├── adr.json              # Architecture Decision Record
    ├── implementation-plan.json
    └── bug-fix.json          # Bug fix process
```

## Template Format

Each template is a JSON file with this structure:

```json
{
  "templateId": "support/generic",
  "name": "Generic Support Request",
  "description": "Standard process for handling customer support requests",
  "version": "1.0.0",
  "appliesTo": ["story"],
  "workType": "support",
  "requiredSections": [
    "problem",
    "customer",
    "investigation",
    "resolution"
  ],
  "recommendedSections": [
    "root_cause",
    "prevention"
  ],
  "outputs": [
    {
      "type": "comment",
      "location": "teamwork",
      "format": "markdown"
    }
  ],
  "validationRules": [
    "customer email must be provided",
    "resolution must include verification steps"
  ],
  "stages": {
    "triage": {
      "required": true,
      "outputs": ["categorized work item"]
    },
    "plan": {
      "required": false,
      "skip_if": "simple resolution"
    },
    "design": {
      "required": false,
      "skip_if": "no code changes"
    },
    "deliver": {
      "required": true,
      "outputs": ["resolution comment", "status update"]
    }
  }
}
```

## Template Fields

| Field | Required | Description |
|-------|----------|-------------|
| `templateId` | Yes | Unique identifier (category/name format) |
| `name` | Yes | Human-readable name |
| `description` | Yes | Purpose and when to use |
| `version` | Yes | Semantic version (major.minor.patch) |
| `appliesTo` | Yes | Work item types: epic, feature, story, task |
| `workType` | No | Expected work type: support, bug_fix, etc. |
| `requiredSections` | Yes | Sections that must be completed |
| `recommendedSections` | No | Optional but helpful sections |
| `outputs` | Yes | Expected deliverables |
| `validationRules` | No | Rules for template validator |
| `stages` | No | Stage-specific requirements |

## Using Templates

### Assignment

Templates are assigned during triage:
1. Triage agent detects work type
2. Matches to appropriate template
3. Sets `processTemplate` field on work item

### Enforcement

Agents check template requirements:
1. Read template from registry
2. Validate required sections exist
3. Produce required outputs
4. Follow stage requirements

### Validation

Template validator agent checks:
1. All required sections completed
2. Outputs created in correct format
3. Validation rules pass

## Template Categories

### Support Templates (`support/`)

For customer-facing support work:
- `generic.json` - Standard support request
- `remove-profile.json` - Account deletion requests
- `subscription-change.json` - Plan changes, billing

### Product Templates (`product/`)

For product development work:
- `prd.json` - Product Requirements Document
- `feature.json` - Feature specification
- `story.json` - User story with acceptance criteria

### Delivery Templates (`delivery/`)

For technical implementation:
- `adr.json` - Architecture decisions
- `implementation-plan.json` - Task breakdown
- `bug-fix.json` - Bug investigation and fix

## Versioning

Templates are versioned for stability:

```
templates/product/prd/
├── v1.0.0.json
├── v1.1.0.json
└── latest -> v1.1.0.json
```

Work items reference specific versions:
```json
"processTemplate": "product/prd/v1.1.0"
```

## Creating New Templates

1. Identify the work type pattern
2. Define required sections based on what's always needed
3. Define outputs based on what the process produces
4. Add validation rules for quality gates
5. Specify stage requirements (which stages apply)
6. Add to registry.json
7. Test with sample work items

## Integration with Work System

Templates connect to:
- **Triage Stage**: Template assigned based on work type
- **Plan Stage**: Template informs decomposition strategy
- **Design Stage**: Template defines required artifacts (ADRs, specs)
- **Deliver Stage**: Template defines acceptance criteria
- **Eval Stage**: Template defines success metrics

## Related Files

- `~/.claude/work-system.md` - Full work system specification
- `~/.claude/work-system-implementation-plan.md` - Implementation roadmap
- `~/.claude/agents/template-validator.md` - Validation agent (Phase 7)

---

*Last Updated: 2024-12-07*
