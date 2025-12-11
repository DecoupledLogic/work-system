# Git Commands

Platform-agnostic git operations for the work system. These commands provide a unified interface for common git workflows that work with any repository hosting platform (GitHub, Azure DevOps, GitLab, etc.).

## Overview

This directory contains git operations decoupled from any specific platform. These commands focus solely on local and remote git operations without platform-specific API calls.

## Available Commands

### Repository Status

#### `/git-status`
Show comprehensive git status including working directory, staging area, and remote sync status.

```bash
/git-status                      # Full status overview
/git-status --short              # Compact format
/git-status --remote             # Include remote comparison
```

**Use when:** Checking current state before operations

---

### Branch Operations

#### `/git-branch`

Get current branch name, previous branch, or list branches.

```bash
/git-branch                      # Get current branch name
/git-branch --previous          # Get previous branch name
/git-branch --list              # List local branches
/git-branch --list --all        # List all branches (local + remote)
```

**Use when:** Scripting, checking current context, navigating branches

#### `/git-create-branch`
Create a new git branch from current or specified base.

```bash
/git-create-branch feature/user-auth
/git-create-branch feature/user-auth main
/git-create-branch bugfix/login-error develop --push
```

**Features:**
- Create from current or specified base branch
- Optional immediate push to remote
- Auto-tracking setup

#### `/git-delete-branch`
Delete a git branch locally and/or remotely.

```bash
/git-delete-branch feature/old-feature
/git-delete-branch feature/old-feature --remote
/git-delete-branch feature/old-feature --force
```

**Safety features:**
- Won't delete unmerged branches without `--force`
- Cannot delete current branch
- Explicit `--remote` flag required for remote deletion

#### `/git-checkout`
Switch branches safely with auto-stash.

```bash
/git-checkout feature/other      # Switch to branch
/git-checkout main --pull        # Switch and pull latest
/git-checkout -                  # Switch to previous branch
/git-checkout feature/new --create   # Create and switch
```

**Features:**
- Auto-stash uncommitted changes
- Create branches on-the-fly
- Pull after checkout

---

### Commit Operations

#### `/git-commit`
Create a git commit with conventional commit format.

```bash
/git-commit "fix: resolve login authentication bug"
/git-commit "feat(auth): add password reset flow" --all
/git-commit "docs: update API documentation" --push
```

**Conventional Commit Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code formatting
- `refactor`: Code refactoring
- `test`: Testing
- `chore`: Build/tooling

#### `/git-amend`
Amend last commit safely with checks.

```bash
/git-amend                       # Add staged changes to last commit
/git-amend "new message"         # Change commit message
/git-amend --all                 # Stage all and amend
/git-amend --push                # Amend and force push
```

**Safety features:**
- Checks commit authorship
- Warns if already pushed
- Uses `--force-with-lease`

---

### Remote Operations

#### `/git-remote`

Manage and query git remote repositories.

```bash
/git-remote                      # List all remotes
/git-remote --url origin         # Get URL for specific remote
/git-remote --check origin       # Check if remote exists
/git-remote --upstream           # Get upstream remote and branch
```

**Use when:** Checking remote configuration, scripting remote operations

#### `/git-fetch`
Fetch changes from remote without merging.

```bash
/git-fetch                       # Fetch from origin
/git-fetch --all                 # Fetch from all remotes
/git-fetch upstream              # Fetch from specific remote
/git-fetch --status              # Fetch and show branch status
```

**Use when:** Checking for updates without modifying local branches

#### `/git-pull`
Pull latest changes from remote repository.

```bash
/git-pull                        # Pull current branch
/git-pull main                   # Pull and merge main into current
/git-pull --rebase               # Pull with rebase
/git-pull origin develop         # Pull from specific remote/branch
```

**Features:**
- Auto-stash support
- Rebase or merge
- Conflict handling

#### `/git-push`
Commit all changes and push to remote in one command.

```bash
/git-push "feat: add user authentication"
/git-push "fix: resolve login bug" --force
/git-push "docs: update README" --set-upstream
```

**Convenience command** that combines:
1. Stage all changes (`git add -A`)
2. Create commit
3. Push to remote

---

### Information Operations

#### `/git-log`

View commit history with various formats and filters.

```bash
/git-log                         # Recent commits (default 10)
/git-log --oneline               # Compact one-line format
/git-log --count 5               # Show last 5 commits
/git-log --range main..HEAD      # Commits between branches
/git-log --last                  # Just the last commit
```

**Use when:** Reviewing commit history, checking for unpushed commits

#### `/git-diff`
Show changes in working directory or between commits.

```bash
/git-diff                        # Unstaged changes
/git-diff --staged               # Staged changes
/git-diff --stat                 # Summary statistics
/git-diff --name-only            # Just file names
/git-diff --range main..HEAD     # Changes between branches
```

**Use when:** Reviewing changes before commit, checking for conflicts

---

### Workflow Operations

#### `/git-sync`
Sync current branch with main/base branch.

```bash
/git-sync                        # Rebase current branch on main
/git-sync develop                # Rebase on develop instead
/git-sync --merge                # Merge instead of rebase
/git-sync --stash                # Auto-stash local changes
/git-sync --push                 # Force push after sync
```

**Use when:** Keeping feature branch up to date with base branch

---

## Command Philosophy

### Hybrid Approach

These commands follow a hybrid approach:

1. **Primitive operations use raw git** (inside implementations)
   - Faster, simpler, atomic
   - Example: `git-push.md` internally uses `git push`

2. **Composite operations call other slash commands**
   - DRY principle, orchestration
   - Example: `git-sync.md` calls `/git-pull`

3. **All user-facing examples use slash commands**
   - Consistent interface
   - Platform-agnostic

### Safety First

All commands include:
- Input validation
- Safety checks (merge status, authorship, etc.)
- Clear error messages
- Contextual suggestions

### Conventional Commits

Commit commands encourage [Conventional Commits](https://www.conventionalcommits.org/) format for consistent history.

---

## Common Workflows

### Start New Feature
```bash
# Update main and create feature branch
/git-checkout main --pull
/git-create-branch feature/my-feature main --push
```

### Daily Development
```bash
# Check status
/git-status

# Commit work
/git-commit "feat: implement login form" --all

# Push to remote
/git-push
```

### Keep Branch Updated
```bash
# Sync with main
/git-sync --stash

# Continue work...
```

### Complete Feature
```bash
# Final sync and push
/git-sync --push

# Create PR (platform-specific command)
/gh-create-pr "feat: My Feature"     # GitHub
/ado-create-pr "main" "feature" "My Feature"  # Azure DevOps
```

### Code Review
```bash
# Fetch and checkout PR branch
/git-fetch
/git-checkout feature/pr-branch --pull

# Review code...

# Return to your branch
/git-checkout -
```

---

## Integration with Platform Commands

These git commands work with any platform:

### GitHub
```bash
/git-commit "feat: add feature" --all
/gh-create-pr "feat: Add Feature"
```

### Azure DevOps
```bash
/git-commit "feat: add feature" --all
/ado-create-pr "main" "feature/branch" "Add Feature"
```

### Any Platform
```bash
# Git operations are the same
/git-status
/git-commit "message"
/git-push

# Only API operations differ by platform
```

---

## Best Practices

1. **Check status before operations**
   ```bash
   /git-status
   ```

2. **Use conventional commits**
   ```bash
   /git-commit "feat(scope): description"
   ```

3. **Keep branches synced**
   ```bash
   /git-sync --stash  # Daily
   ```

4. **Review before pushing**
   ```bash
   /git-status
   /git-commit "message" --all
   # Review changes...
   /git-push
   ```

5. **Clean up after PR merge**
   ```bash
   /git-checkout main --pull
   /git-delete-branch feature/old-feature --remote
   ```

---

## Related Commands

- **Platform-specific PR operations**: See `/commands/github/` or `/commands/azuredevops/`
- **Work item operations**: See `/commands/teamwork/`
- **Workflow orchestration**: See `/commands/deliver.md`, `/commands/design.md`

---

## Notes

- All commands are platform-agnostic
- Work with GitHub, Azure DevOps, GitLab, Bitbucket, etc.
- Focus on git operations only (no platform APIs)
- Designed for work system integration
