# Document Schema

The document system enables template-driven generation of lint-safe markdown documents. This schema defines the structure for document requests, templates, and outputs.

## Document Request Schema

```yaml
DocumentRequest:
  # Template selection
  template: enum                    # Template identifier
    - prd                           # Product Requirements Document
    - spec                          # Technical Specification
    - adr                           # Architecture Decision Record
    - impl-plan                     # Implementation Plan
    - test-plan                     # Test Plan
    - spike-report                  # Research/Investigation Report
    - bug-report                    # Bug Documentation
    - release-notes                 # Release Notes
    - retro                         # Retrospective/Learnings
    - delivery-plan                 # Delivery Plan (epic-level)
    - architecture-blueprint        # Architecture Blueprint

  # Context data
  context: object                   # Template-specific fields
    # Fields vary by template
    # See Template Context section below

  # Format options
  formatOptions:
    includeTOC: boolean             # Include table of contents (default: false)
    includeMetadata: boolean        # Include metadata header (default: true)
    maxHeadingLevel: number         # Maximum heading depth (default: 6)
```

## Document Result Schema

```yaml
DocumentResult:
  # Status
  status: enum                      # ok | error
  error: object | null              # Error details if status = error
    code: string                    # Error code
    message: string                 # Human-readable message
    field: string | null            # Field that caused error
    template: string | null         # Template that failed

  # Output
  document: string | null           # Generated markdown content

  # Validation
  lintReport: LintIssue[]           # List of lint issues (should be empty)
  structureReport:
    missingRequiredFields: string[] # Fields missing from context
    duplicatedHeadings: string[]    # Duplicate heading text found
    warnings: string[]              # Non-critical issues

  # Metadata
  metadata:
    template: string                # Template used
    generatedAt: datetime           # Generation timestamp
    wordCount: number               # Total word count
    headingCount: number            # Number of headings
```

## Lint Issue Schema

```yaml
LintIssue:
  rule: string                      # Markdown lint rule ID (e.g., "MD032")
  line: number                      # Line number
  message: string                   # Issue description
  fixable: boolean                  # Can be auto-fixed
```

## Template Definition Schema

```yaml
DocumentTemplate:
  # Identity
  name: string                      # Template identifier (e.g., "prd")
  version: number                   # Template version
  description: string               # Human-readable description

  # Context requirements
  requiredContext: string[]         # Fields that must be provided
  optionalContext: string[]         # Fields that may be provided

  # Render instructions
  render: RenderBlock[]             # Ordered list of render blocks
```

## Render Block Types

```yaml
RenderBlock:
  type: enum
    - heading                       # Section heading
    - paragraph                     # Text block
    - list                          # Unordered list (-)
    - orderedList                   # Numbered list (1., 2., ...)
    - table                         # Data table
    - code                          # Code block
    - metadata                      # Key-value metadata
    - conditional                   # Conditional rendering
    - forEach                       # Loop over items

HeadingBlock:
  type: "heading"
  level: number                     # 1-6
  content: string                   # Heading text (supports {{placeholders}})

ParagraphBlock:
  type: "paragraph"
  content: string                   # Paragraph text (supports {{placeholders}})

ListBlock:
  type: "list"
  items: string | string[]          # Items or template expression

OrderedListBlock:
  type: "orderedList"
  items: string | string[]          # Items or template expression

TableBlock:
  type: "table"
  headers: string[]                 # Column headers
  rows: string                      # Template expression for row data

CodeBlock:
  type: "code"
  language: string                  # Language identifier (e.g., "json", "typescript")
  content: string                   # Code content (supports {{placeholders}})

MetadataBlock:
  type: "metadata"
  fields: string[]                  # Metadata fields (supports {{placeholders}})

ConditionalBlock:
  type: "conditional"
  if: string                        # Template expression to evaluate
  blocks: RenderBlock[]             # Blocks to render if condition is truthy

ForEachBlock:
  type: "forEach"
  items: string                     # Template expression for array
  blocks: RenderBlock[]             # Blocks to render for each item
                                    # Use {{item}} or {{item.field}} in blocks
```

## Template Context by Type

### PRD (Product Requirements Document)

```yaml
PRDContext:
  # Required
  featureName: string               # Feature title
  vision: string                    # Vision statement
  actors: string[]                  # User personas involved
  acceptanceCriteria: string[]      # Success criteria

  # Optional
  workItemId: string                # External work item reference
  jobs: string[]                    # Jobs to be done
  constraints: string[]             # Technical/business constraints
  outOfScope: string[]              # Explicitly excluded items
  risks: string[]                   # Identified risks
  dependencies: string[]            # External dependencies
  successMetrics: string[]          # Measurable outcomes
```

### Spec (Technical Specification)

```yaml
SpecContext:
  # Required
  storyName: string                 # Story title
  workItemId: string                # Work item reference
  userStory: string                 # As a... I want... So that...
  acceptanceCriteria: string[]      # Gherkin-format criteria

  # Optional
  parentFeature: string             # Parent feature name
  technicalApproach: string         # Implementation approach
  apiChanges: APIChange[]           # API modifications
  dataChanges: DataChange[]         # Database/schema changes
  uiChanges: string[]               # UI modifications
  testingNotes: string              # Testing guidance
```

### ADR (Architecture Decision Record)

```yaml
ADRContext:
  # Required
  title: string                     # Decision title
  context: string                   # Why this decision is needed
  decision: string                  # What was decided
  consequences: Consequences        # Outcomes of the decision

  # Optional
  number: number                    # ADR number (auto-assigned if not provided)
  status: string                    # Proposed | Accepted | Deprecated | Superseded
  alternatives: Alternative[]       # Options considered
  relatedDecisions: string[]        # Related ADR references
  references: string[]              # External references

Consequences:
  positive: string[]                # Benefits
  negative: string[]                # Drawbacks

Alternative:
  name: string                      # Alternative name
  reason: string                    # Why not chosen
```

### Architecture Blueprint

```yaml
ArchitectureBlueprintContext:
  # Required
  systemName: string                # System/service name
  overview: string                  # System overview (2-3 paragraphs)
  goals: string[]                   # Design goals
  components: Component[]           # System components
  corePrinciples: Principle[]       # Core design principles

  # Optional
  taskUrl: string                   # External task reference
  eventSources: EventSources        # Integration events
  domainModel: DomainModel          # Domain entities
  coreFlows: Flow[]                 # Key workflows
  integrationDesign: IntegrationDesign
  eventContracts: EventContract[]   # Event schemas
  serviceApis: ServiceAPI[]         # API definitions
  reconciliationStrategy: ReconciliationStrategy
  securityAndTenancy: string[]      # Security requirements
  openQuestions: string[]           # Unresolved decisions
  migrationStrategy: MigrationStrategy
  failureModes: FailureMode[]       # Failure scenarios
  performanceConsiderations: PerformanceConsiderations

Component:
  name: string                      # Component name
  responsibilities: string[]        # What it does

Principle:
  number: number                    # Principle number
  name: string                      # Short name
  explanation: string               # Full explanation
  benefits: string[]                # Why this pattern (optional, on first principle)
```

### Delivery Plan

```yaml
DeliveryPlanContext:
  # Required
  initiativeName: string            # Initiative title
  strategy: string                  # Overall strategy
  problem: string[]                 # Problems being solved
  epics: Epic[]                     # Delivery epics

  # Optional
  taskUrl: string                   # External task reference
  blueprintUrl: string              # Architecture blueprint link
  estimateUrl: string               # Estimate document link
  successMetrics: string[]          # Success criteria
  dependencies: string[]            # External dependencies
  risks: Risk[]                     # Risk matrix
  rolloutStrategy: string           # Deployment approach

Epic:
  number: number                    # Epic number
  name: string                      # Epic title
  goal: string                      # Epic goal
  taskUrl: string | null            # External task link
  features: Feature[]               # Epic features
  deployment: Deployment            # Deployment details

Feature:
  id: string                        # Feature ID (e.g., "1.1")
  name: string                      # Feature name
  purpose: string                   # Why this feature
  stories: Story[]                  # Implementation stories

Story:
  id: string                        # Story ID (e.g., "1.1.1")
  name: string                      # Story name
  acceptanceCriteria: string[]      # Gherkin criteria
  implementationNotes: string       # Developer guidance (optional)
  codeExample: string               # Code snippet (optional)
  codeLanguage: string              # Language for code block

Deployment:
  prerequisites: string[]           # Pre-deployment requirements
  steps: string[]                   # Deployment steps
  rollback: string[]                # Rollback procedure
  risk: string                      # Deployment risk level
```

## Error Codes

| Code | Description |
|------|-------------|
| `INVALID_TEMPLATE` | Template name not recognized |
| `MISSING_REQUIRED_FIELD` | Required context field not provided |
| `INVALID_FIELD_TYPE` | Field has wrong data type |
| `RENDER_ERROR` | Error during document rendering |
| `LINT_FAILURE` | Generated document has lint errors |

## Usage Examples

### Request PRD Generation

```json
{
  "template": "prd",
  "context": {
    "featureName": "Link Contacts",
    "vision": "Enable pet owners to link multiple contacts to their pet profile",
    "actors": ["Pet Owner", "Clinic Tech"],
    "acceptanceCriteria": [
      "Given a pet profile, when adding a contact, then the contact appears in the linked contacts list",
      "Given a linked contact, when editing their phone, then the change reflects across all linked pets"
    ]
  }
}
```

### Successful Response

```json
{
  "status": "ok",
  "document": "# PRD: Link Contacts\n\n**Created:** 2024-12-08\n**Status:** Draft\n\n## Vision\n\n...",
  "lintReport": [],
  "structureReport": {
    "missingRequiredFields": [],
    "duplicatedHeadings": [],
    "warnings": ["Optional field 'constraints' was empty"]
  },
  "metadata": {
    "template": "prd",
    "generatedAt": "2024-12-08T15:30:00Z",
    "wordCount": 245,
    "headingCount": 6
  }
}
```

## Related Documentation

- [Document Writer Agent](../agents/document-writer-agent.md) - Agent definition
- [Document Templates](../docs/templates/documents/README.md) - Available templates
- [doc-write Command](../commands/doc-write.md) - Slash command
- [Markdown Standards](../docs/reference/markdown-standards.md) - Linting rules
