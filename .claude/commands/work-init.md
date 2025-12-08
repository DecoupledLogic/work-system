# Work System Init

Initialize the work system for the current repository.

## What This Does

1. **Detects directory structure** - Single repo, monorepo, or multi-repo parent
2. **Detects your stack** - Scans for .NET, TypeScript/React/Vue, SQL projects
3. **Runs architecture review** - Analyzes codebase structure and patterns
4. **Generates configuration** - Creates architecture spec and agent playbook
5. **Sets up integrations** - Optionally links to Teamwork, Azure DevOps, etc.

## Generated Files

After running, you'll have:

```text
.claude/
├── architecture.yaml              # Machine-readable architecture spec
├── agent-playbook.yaml            # Rules for coding agents
└── architecture-recommendations.json  # Categorized improvements
```

## Instructions

### Step 0: Detect Directory Structure

Before analyzing, determine what kind of directory this is.

**Check for:**

1. `.git` folder in current directory → Single repo or monorepo root
2. `.git` folders in immediate subdirectories → Multi-repo parent directory
3. Multiple `.sln`, `package.json`, or project roots → Could be monorepo or workspace

**If multi-repo parent detected:**

- List the subdirectories that appear to be repositories
- Ask user which option they want:
  - **Initialize all** - Treat as workspace, generate unified architecture
  - **Select specific** - Let user choose which repo(s) to init
  - **Cancel** - User should cd into specific repo first

**If monorepo detected (single .git, multiple projects):**

- Proceed with unified architecture review
- Map relationships between internal projects
- Note which projects are:
  - Shared/common (used by multiple others)
  - Deployable (APIs, workers, frontends)
  - Supporting (tests, tools, scripts)

**If single project:**

- Proceed normally

### Step 1: Detect Technology Stack

Scan for:

- .NET: `*.csproj`, `*.sln`, Program.cs, Startup.cs
- Frontend: package.json, tsconfig.json, src/App.tsx, src/App.vue
- Database: migrations folder, DbContext files, SQL scripts

### Step 2: Run Architecture Review

- Pass 1: Map the system (components, layers, request traces)
- Pass 2: Evaluate with fixed lenses (domain, backend, frontend, data, cross-cutting, evolvability)
- Pass 3: Generate recommendations (guardrails, leverage, hygiene, experiments)

### Step 3: Write Output Files

Write to `.claude/`:

- `architecture.yaml` - Full architecture specification
- `agent-playbook.yaml` - Coding rules and patterns
- `architecture-recommendations.json` - Categorized improvement suggestions

### Step 4: Report Summary

Report to user:

- Stack detected
- Key components found
- Number of guardrails, leverage items, hygiene items, experiments
- Any critical issues that need immediate attention

Use the architecture-review-agent methodology from the work system documentation.

### Handling Existing Files

If `.claude/architecture.yaml` already exists, ask the user whether to:

- **Refresh**: Re-run review and update files (preserving manual customizations where possible)
- **Reset**: Completely regenerate from scratch
- **Cancel**: Keep existing files

## See Also

- `/architecture-review` - Re-run architecture review on demand
- Documentation: `docs/architecture-review-agent.md`
