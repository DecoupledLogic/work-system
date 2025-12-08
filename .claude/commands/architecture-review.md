# Architecture Review

Run or re-run architecture review on the current repository.

## When to Use

- After significant codebase changes
- When onboarding to a new area of the codebase
- To update recommendations based on recent work
- To validate current architecture against best practices

## What This Does

Executes the 3-pass architecture review process:

1. **Pass 1: Map** - Identify components, layers, and trace request flows
2. **Pass 2: Evaluate** - Assess against fixed lenses (domain, backend, frontend, data, cross-cutting, evolvability)
3. **Pass 3: Recommend** - Generate categorized improvements (guardrails, leverage, hygiene, experiments)

## Instructions

Run the architecture review agent on this repository.

**If `.claude/architecture.yaml` exists:**
- Compare new analysis against existing spec
- Highlight what has changed
- Suggest updates to guardrails and playbook
- Preserve manual customizations unless they conflict with new findings

**If `.claude/architecture.yaml` does not exist:**
- Inform user to run `/work-init` first for full setup
- Or proceed with review-only mode (outputs to console, doesn't write files)

**Output:**
- Summary of system map (components, key flows)
- Lens evaluations with strengths/weaknesses
- Recommendations by category with counts
- Specific action items for critical guardrails

**Optional arguments:**
- `--focus=<area>` - Focus on specific area: backend, frontend, data, cross-cutting
- `--output` - Write updated files (default: report only)
- `--diff` - Show diff against existing architecture.yaml

Use the architecture-review-agent methodology from the work system documentation.

## See Also

- `/work-init` - Full work system initialization
- Documentation: `docs/architecture-review-agent.md`, `docs/architecture-agents-prompts.md`
