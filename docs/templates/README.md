# Architecture Templates

Templates for the Architecture Review Agent output. These serve as starting points that get customized per-repo.

## Files

| Template | Purpose |
|----------|---------|
| [architecture.yaml](architecture.yaml) | Machine-readable architecture spec - layers, dependencies, rules |
| [agent-playbook.yaml](agent-playbook.yaml) | Concrete do/don't rules and workflows for coding agents |

## Usage

### During Init (`/work:init`)

The work system separates **install** (global, once) from **init** (per-repo):

```text
work-system install    → Global setup of agents and commands
/work:init             → Per-repo setup with architecture review
```

When running `/work:init` in a repo directory:

1. Architecture Review Agent analyzes the codebase
2. Agent generates customized versions of these templates
3. Files are saved to `.claude/` in the target repo:
   - `.claude/architecture.yaml`
   - `.claude/agent-playbook.yaml`
   - `.claude/architecture-recommendations.json`

### For Builder Agents

Builder agents receive these files as context before implementing any changes:

```yaml
# Injected into agent context
architecture: <contents of .claude/architecture.yaml>
playbook: <contents of .claude/agent-playbook.yaml>
```

### Manual Customization

After initial generation, these files can be manually edited to:

- Add project-specific guardrails
- Refine patterns based on team preferences
- Update rules as architecture evolves

Re-running the Architecture Review Agent will produce updated recommendations but won't overwrite manual customizations without confirmation.

## Template Structure

### architecture.yaml

```yaml
system:           # High-level system description
backend:          # .NET project structure, layers, dependencies
frontend:         # React/Vue structure, directories, rules
data:             # Database schemas, migration strategy, rules
crossCutting:     # Auth, logging, observability, testing
evolvability:     # Principles, red lines, extension points
tooling:          # Architecture tests, linting config
```

### agent-playbook.yaml

```yaml
taskTypes:            # feature, bugfix, refactor, experiment, chore
generalGuidelines:    # Universal rules for all changes
backend:              # BE guardrails, patterns, hygiene
frontend:             # FE guardrails, patterns, hygiene
data:                 # DB guardrails, patterns
crossCutting:         # Auth, logging, error handling rules
improvementGuidelines:# Leverage, experiments, refusal rules
workflow:             # Per-task steps and required outputs
```
