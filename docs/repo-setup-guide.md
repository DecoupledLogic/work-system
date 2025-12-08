# Work System Repository Setup Guide

This guide documents how to create a Git repository from your work system files using **symlinks** for zero-maintenance synchronization.

## Overview

You've built a work system in `~/.claude/` that contains:

- **Work system files**: Agents, commands, templates, docs (to include in repo)
- **Claude Code core files**: Internal state, history, settings (to exclude from repo)

This guide uses **symlinks** to keep your repository and Claude Code in sync automatically - edit in one place, changes appear in both.

## How Symlinks Work

```
~/.claude/agents/  →  points to  →  ~/projects/work-system/agents/
```

When Claude Code reads `~/.claude/agents/triage-agent.md`, the OS transparently redirects to `~/projects/work-system/agents/triage-agent.md`. One file, two paths, zero copying.

## Files Inventory

### Include in Repository

**Agents** (`agents/`):

- `work-item-mapper.md`
- `triage-agent.md`
- `plan-agent.md`
- `design-agent.md`
- `dev-agent.md`
- `qa-agent.md`
- `eval-agent.md`
- `session-logger.md`
- `template-validator.md`
- `task-selector.md`
- `task-fetcher.md`

**Commands** (`commands/`):

- `README.md`
- `select-task.md`
- `resume.md`
- `triage.md`
- `plan.md`
- `design.md`
- `deliver.md`
- `queue.md`
- `route.md`
- `work-status.md`
- `teamwork/*.md` (all Teamwork helper commands)

**Templates** (`templates/`):

- `README.md`
- `versioning.md`
- `registry.json`
- `_schema.json`
- `support/*.json`
- `product/*.json`
- `product/story/*.json` (versioned)
- `delivery/*.json`
- `delivery/*.md`

**Session Templates** (`session/`):

- `.gitignore` - Excludes ephemeral session files
- `logging-guide.md` - Integration guide

**Work Managers** (`work-managers/`):

- `README.md`
- `queue-store.md`

**Documentation** (`docs/`):

- `adrs/README.md`
- `adrs/0001-work-manager-abstraction.md`
- `adrs/0002-local-first-session-state.md`
- `adrs/0003-stage-based-workflow.md`
- `quick-reference.md`
- `sub-agents-guide.md` - Agent development guide
- `work-system-guide.md` - User guide
- `work-system-implementation-plan.md` - Implementation history
- `repo-setup-guide.md` - This guide

### Exclude from Repository

**User-Specific**:

- `CLAUDE.md` - User's personal Claude Code config
- `.credentials.json` - API tokens
- `teamwork.json` - Teamwork credentials
- `settings.json` - User settings

**Claude Code Internal**:

- `debug/` - Debug logs
- `file-history/` - File edit history
- `history.jsonl` - Command history
- `ide/` - IDE integration state
- `plans/` - Plan files
- `plugins/` - Installed plugins
- `projects/` - Project-specific state
- `session-env/` - Session environments
- `shell-snapshots/` - Shell state snapshots
- `statsig/` - Usage analytics
- `todos/` - Todo state

**Ephemeral Session State**:

- `session/active-work.md` - Current work (user-specific)
- `session/session-log.md` - Activity log (user-specific)
- `session/queues.json` - Queue assignments (user-specific)
- `session/local-work-items.json` - Local work items (user-specific)

## Step-by-Step Setup

### Step 1: Create Repository Directory

```bash
# Create the repository directory
mkdir -p ~/projects/work-system
cd ~/projects/work-system

# Initialize git
git init
```

### Step 2: Move Work System Files to Repository

```bash
# Move directories (not copy - we want originals in repo)
mv ~/.claude/agents ~/projects/work-system/
mv ~/.claude/commands ~/projects/work-system/
mv ~/.claude/templates ~/projects/work-system/
mv ~/.claude/docs ~/projects/work-system/
mv ~/.claude/work-managers ~/projects/work-system/

# Move session directory (contains templates + ephemeral state)
mv ~/.claude/session ~/projects/work-system/

# Move root-level documentation
mv ~/.claude/work-system.md ~/projects/work-system/
mv ~/.claude/work-system-implementation-plan.md ~/projects/work-system/
mv ~/.claude/work-system-guide.md ~/projects/work-system/
mv ~/.claude/sub-agents-guide.md ~/projects/work-system/
```

### Step 3: Create Symlinks in ~/.claude

```bash
# Create symlinks from ~/.claude pointing to repository
ln -s ~/projects/work-system/agents ~/.claude/agents
ln -s ~/projects/work-system/commands ~/.claude/commands
ln -s ~/projects/work-system/templates ~/.claude/templates
ln -s ~/projects/work-system/docs ~/.claude/docs
ln -s ~/projects/work-system/work-managers ~/.claude/work-managers
ln -s ~/projects/work-system/session ~/.claude/session

# Symlink root-level docs
ln -s ~/projects/work-system/work-system.md ~/.claude/work-system.md
ln -s ~/projects/work-system/work-system-implementation-plan.md ~/.claude/work-system-implementation-plan.md
ln -s ~/projects/work-system/work-system-guide.md ~/.claude/work-system-guide.md
ln -s ~/projects/work-system/sub-agents-guide.md ~/.claude/sub-agents-guide.md
```

### Step 4: Verify Symlinks

```bash
# Check symlinks are working
ls -la ~/.claude/

# Should show arrows pointing to repo:
# agents -> /home/username/projects/work-system/agents
# commands -> /home/username/projects/work-system/commands
# etc.

# Verify Claude Code can read files
cat ~/.claude/agents/triage-agent.md
```

### Step 5: Set Up Repository Files

```bash
cd ~/projects/work-system

# Create README from existing doc (or rename)
cp docs/work-system-readme.md README.md 2>/dev/null || echo "# Work System" > README.md

# Create .gitignore for session ephemeral files
cat > .gitignore << 'EOF'
# Session ephemeral state (user-specific)
session/active-work.md
session/session-log.md
session/queues.json
session/local-work-items.json

# OS files
.DS_Store
Thumbs.db
EOF

# Create example configurations
mkdir -p examples/config

cat > examples/config/work-manager.teamwork.yaml << 'EOF'
# Example Teamwork configuration
manager: teamwork

teamwork:
  projectId: YOUR_PROJECT_ID
  tasklistId: YOUR_TASKLIST_ID  # optional

queues:
  storage: local  # or: native
EOF

cat > examples/config/work-manager.github.yaml << 'EOF'
# Example GitHub configuration
manager: github

github:
  owner: YOUR_ORG
  repo: YOUR_REPO

queues:
  storage: native
  mapping:
    immediate: "priority: critical"
    todo: "priority: high"
    backlog: "priority: medium"
    icebox: "priority: low"
EOF
```

### Step 6: Create Initial Commit

```bash
cd ~/projects/work-system

git add .
git commit -m "Initial commit: Claude Code Work System

AI-powered work management system with stage-based workflow,
specialized agents, and process templates.

Features:
- 11 specialized AI agents
- 4-stage workflow (Triage -> Plan -> Design -> Deliver)
- 9 process templates
- Multi-backend support (Teamwork, GitHub, Linear, Local)
- Local-first queue management
- Session logging and analytics

🤖 Submitted by George with love ♥"
```

### Step 7: Push to GitHub (Optional)

```bash
# Create GitHub repository and push
gh repo create work-system --public --source=. --remote=origin
git push -u origin main
```

## Post-Setup Verification

```bash
# Verify symlinks work
ls -la ~/.claude/ | grep "^l"  # Show only symlinks

# Test that Claude Code can read through symlinks
cat ~/.claude/commands/select-task.md

# Verify git tracks the right files
cd ~/projects/work-system
git ls-files

# Should see:
# - agents/*.md
# - commands/*.md
# - templates/*.json
# - docs/*.md
# - work-managers/*.md
# - session/.gitignore
# - session/logging-guide.md
# - *.md (documentation)
# - README.md
# - .gitignore
```

## Repository Structure

```
~/projects/work-system/
├── README.md                         # Repository overview
├── .gitignore                        # Excludes ephemeral files
├── install.sh                        # Installer script
├── uninstall.sh                      # Uninstaller script
├── work-system.md                    # Core specification
├── work-system-implementation-plan.md # Implementation history
├── work-system-guide.md              # Complete user guide
├── sub-agents-guide.md               # Agent development guide
├── agents/                           # AI agents
│   ├── work-item-mapper.md
│   ├── triage-agent.md
│   ├── plan-agent.md
│   ├── design-agent.md
│   ├── dev-agent.md
│   ├── qa-agent.md
│   ├── eval-agent.md
│   ├── session-logger.md
│   ├── template-validator.md
│   ├── task-selector.md
│   └── task-fetcher.md
├── commands/                         # Slash commands
│   ├── README.md
│   ├── select-task.md
│   ├── resume.md
│   ├── triage.md
│   ├── plan.md
│   ├── design.md
│   ├── deliver.md
│   ├── queue.md
│   ├── route.md
│   ├── work-status.md
│   └── teamwork/                     # Teamwork helpers
│       └── *.md
├── templates/                        # Process templates
│   ├── README.md
│   ├── versioning.md
│   ├── registry.json
│   ├── _schema.json
│   ├── support/
│   ├── product/
│   └── delivery/
├── session/                          # Session templates
│   ├── .gitignore                    # Excludes ephemeral state
│   └── logging-guide.md              # Integration guide
├── work-managers/                    # Backend abstraction
│   ├── README.md
│   └── queue-store.md
├── docs/                             # Documentation
│   └── adrs/                         # Architecture decisions
│       ├── README.md
│       ├── 0001-work-manager-abstraction.md
│       ├── 0002-local-first-session-state.md
│       └── 0003-stage-based-workflow.md
└── examples/                         # Example configs
    └── config/
        ├── work-manager.teamwork.yaml
        └── work-manager.github.yaml
```

## Installation Script

Create `install.sh` in the repository root:

```bash
#!/bin/bash
# install.sh - Install work system to Claude Code using symlinks
#
# This script creates symlinks from ~/.claude to the repository,
# allowing Claude Code to read files while git tracks changes.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

echo "Installing Claude Code Work System..."
echo "Repository: ${SCRIPT_DIR}"
echo "Target: ${CLAUDE_DIR}"
echo ""

# Create ~/.claude if it doesn't exist
mkdir -p "${CLAUDE_DIR}"

# Function to create symlink with backup
create_symlink() {
    local source="$1"
    local target="$2"
    local name="$(basename "$target")"

    if [ -L "$target" ]; then
        # Already a symlink - remove and recreate
        echo "  Updating symlink: $name"
        rm "$target"
    elif [ -e "$target" ]; then
        # Exists but not a symlink - backup
        echo "  Backing up existing: $name -> ${name}.backup"
        mv "$target" "${target}.backup"
    else
        echo "  Creating symlink: $name"
    fi

    ln -s "$source" "$target"
}

echo "Creating symlinks..."

# Directories
create_symlink "${SCRIPT_DIR}/agents" "${CLAUDE_DIR}/agents"
create_symlink "${SCRIPT_DIR}/commands" "${CLAUDE_DIR}/commands"
create_symlink "${SCRIPT_DIR}/templates" "${CLAUDE_DIR}/templates"
create_symlink "${SCRIPT_DIR}/docs" "${CLAUDE_DIR}/docs"
create_symlink "${SCRIPT_DIR}/work-managers" "${CLAUDE_DIR}/work-managers"
create_symlink "${SCRIPT_DIR}/session" "${CLAUDE_DIR}/session"

# Root-level documentation files
if [ -f "${SCRIPT_DIR}/work-system.md" ]; then
    create_symlink "${SCRIPT_DIR}/work-system.md" "${CLAUDE_DIR}/work-system.md"
fi

if [ -f "${SCRIPT_DIR}/work-system-implementation-plan.md" ]; then
    create_symlink "${SCRIPT_DIR}/work-system-implementation-plan.md" "${CLAUDE_DIR}/work-system-implementation-plan.md"
fi

if [ -f "${SCRIPT_DIR}/work-system-guide.md" ]; then
    create_symlink "${SCRIPT_DIR}/work-system-guide.md" "${CLAUDE_DIR}/work-system-guide.md"
fi

if [ -f "${SCRIPT_DIR}/sub-agents-guide.md" ]; then
    create_symlink "${SCRIPT_DIR}/sub-agents-guide.md" "${CLAUDE_DIR}/sub-agents-guide.md"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Verify with: ls -la ~/.claude/ | grep '^l'"
echo ""
echo "Next steps:"
echo "1. Configure work manager (if needed): vim ~/.claude/work-manager.yaml"
echo "2. Verify installation: /work-status in Claude Code"
echo "3. Read the guide: cat ~/.claude/work-system-guide.md"
```

## Uninstallation Script

Create `uninstall.sh` in the repository root:

```bash
#!/bin/bash
# uninstall.sh - Remove work system symlinks from Claude Code
#
# This removes symlinks but does NOT delete the repository files.
# After uninstalling, you can delete ~/projects/work-system if desired.

set -e

CLAUDE_DIR="${HOME}/.claude"

echo "Uninstalling Claude Code Work System..."
echo ""

# Function to remove symlink and optionally restore backup
remove_symlink() {
    local target="$1"
    local name="$(basename "$target")"

    if [ -L "$target" ]; then
        echo "  Removing symlink: $name"
        rm "$target"

        # Restore backup if exists
        if [ -e "${target}.backup" ]; then
            echo "  Restoring backup: ${name}.backup -> $name"
            mv "${target}.backup" "$target"
        fi
    elif [ -e "$target" ]; then
        echo "  Skipping (not a symlink): $name"
    else
        echo "  Skipping (doesn't exist): $name"
    fi
}

echo "Removing symlinks..."

# Directories
remove_symlink "${CLAUDE_DIR}/agents"
remove_symlink "${CLAUDE_DIR}/commands"
remove_symlink "${CLAUDE_DIR}/templates"
remove_symlink "${CLAUDE_DIR}/docs"
remove_symlink "${CLAUDE_DIR}/work-managers"
remove_symlink "${CLAUDE_DIR}/session"

# Root-level files
remove_symlink "${CLAUDE_DIR}/work-system.md"
remove_symlink "${CLAUDE_DIR}/work-system-implementation-plan.md"
remove_symlink "${CLAUDE_DIR}/work-system-guide.md"
remove_symlink "${CLAUDE_DIR}/sub-agents-guide.md"

echo ""
echo "Uninstallation complete!"
echo ""
echo "The repository at ~/projects/work-system is still intact."
echo "To fully remove, run: rm -rf ~/projects/work-system"
```

Make both scripts executable:

```bash
chmod +x install.sh uninstall.sh
```

## Usage

### For New Users

```bash
# Clone repository
git clone https://github.com/yourname/work-system.git ~/projects/work-system
cd ~/projects/work-system

# Install using symlinks
./install.sh

# Verify
ls -la ~/.claude/ | grep "^l"
```

### For Contributors

```bash
# Fork and clone
gh repo fork yourname/work-system --clone
cd work-system

# Install locally
./install.sh

# Make changes (edit files in repo OR through ~/.claude - same files!)
vim agents/triage-agent.md
# OR
vim ~/.claude/agents/triage-agent.md  # Same file!

# Commit and push
git add .
git commit -m "Update triage agent

🤖 Submitted by George with love ♥"
git push

# Create PR
gh pr create --title "Update triage agent" --body "Description"
```

### Updating Your Installation

```bash
cd ~/projects/work-system
git pull origin main
# Done! Symlinks automatically point to updated files
```

## Maintenance

### No Sync Required

With symlinks, there's no maintenance burden:

- Edit files in `~/projects/work-system/` - Claude Code sees changes immediately
- Edit files via `~/.claude/` - Git sees changes immediately
- Pull updates with `git pull` - Claude Code sees them immediately

### Versioning

Use semantic versioning for releases:

```bash
# Create a new version
git tag -a v1.1.0 -m "Release v1.1.0: Add new features"
git push origin v1.1.0

# Create GitHub release
gh release create v1.1.0 --title "v1.1.0" --notes "Release notes here"
```

## Troubleshooting

### Symlink Points to Wrong Location

```bash
# Check where symlink points
ls -la ~/.claude/agents

# Remove and recreate
rm ~/.claude/agents
ln -s ~/projects/work-system/agents ~/.claude/agents
```

### "File exists" Error When Creating Symlink

```bash
# Something already exists at that path
ls -la ~/.claude/agents

# If it's a directory with files you want to keep:
mv ~/.claude/agents ~/.claude/agents.backup
ln -s ~/projects/work-system/agents ~/.claude/agents

# If it's safe to remove:
rm -rf ~/.claude/agents
ln -s ~/projects/work-system/agents ~/.claude/agents
```

### Claude Code Not Finding Files

```bash
# Verify symlinks are valid (not broken)
file ~/.claude/agents
# Should say: symbolic link to /home/.../projects/work-system/agents

# If broken, the target doesn't exist - check repo path
ls ~/projects/work-system/agents
```

### Accidentally Committed Credentials

If you committed `.credentials.json` or other sensitive files:

```bash
# Remove from history
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch .credentials.json' \
  --prune-empty --tag-name-filter cat -- --all

# Force push (WARNING: Rewrites history)
git push origin --force --all

# Rotate exposed credentials immediately
```

## Recommended Repository Settings

### Branch Protection

Set up branch protection for `main`:

1. Go to repository Settings -> Branches
2. Add rule for `main` branch:
   - Require pull request reviews before merging
   - Require status checks to pass
   - Require branches to be up to date

### Topics

Add GitHub topics for discoverability:

- `claude-code`
- `ai-agents`
- `work-management`
- `workflow-automation`
- `process-templates`
- `task-management`

### Description

```
AI-powered work management system with stage-based workflow, specialized agents, and process templates
```

---

Part of the AgenticOps Work System

🤖 Submitted by George with love ♥
