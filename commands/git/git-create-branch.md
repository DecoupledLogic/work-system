---
description: Create a new git branch from current or specified base (helper)
allowedTools:
  - Bash
---

# Git: Create Branch

Creates a new git branch locally and optionally pushes to remote.

## Usage

```bash
/git-create-branch feature/user-auth
/git-create-branch feature/user-auth main
/git-create-branch bugfix/login-error develop --push
```

## Input Parameters

- **branchName** (required): Name of the new branch to create
- **baseBranch** (optional): Base branch to create from (default: current branch)
- **--push** (optional): Push branch to remote after creation

## Implementation

1. **Validate and parse input:**
   ```bash
   branchName=$1
   baseBranch=${2:-""}
   pushToRemote=false

   # Check for --push flag
   for arg in "$@"; do
     if [ "$arg" == "--push" ]; then
       pushToRemote=true
     fi
   done

   # Validate required parameters
   if [ -z "$branchName" ]; then
     echo "❌ Missing required parameter: branchName"
     echo ""
     echo "Usage: /git-create-branch <branchName> [baseBranch] [--push]"
     echo ""
     echo "Examples:"
     echo "  /git-create-branch feature/user-auth"
     echo "  /git-create-branch feature/user-auth main"
     echo "  /git-create-branch bugfix/login-error develop --push"
     exit 1
   fi
   ```

2. **Verify clean working directory:**
   ```bash
   if [ -n "$(git status --porcelain)" ]; then
     echo "⚠️  Working directory has uncommitted changes"
     echo ""
     echo "Consider:"
     echo "  - Commit changes: /git-commit \"message\""
     echo "  - Stash changes: git stash"
     echo ""
     echo "Proceeding with branch creation..."
   fi
   ```

3. **Fetch latest from remote:**
   ```bash
   git fetch origin --quiet 2>/dev/null || true
   ```

4. **Create branch:**
   ```bash
   if [ -n "$baseBranch" ]; then
     # Create from specified base
     git checkout -b "$branchName" "origin/$baseBranch" 2>/dev/null || \
     git checkout -b "$branchName" "$baseBranch"
   else
     # Create from current branch
     git checkout -b "$branchName"
   fi
   ```

5. **Optionally push to remote:**
   ```bash
   if [ "$pushToRemote" = true ]; then
     git push -u origin "$branchName"
   fi
   ```

6. **Output result:**

**Success response:**
```json
{
  "branch": {
    "name": "feature/user-auth",
    "baseBranch": "main",
    "pushed": true,
    "tracking": "origin/feature/user-auth"
  },
  "success": true
}
```

## Error Handling

**If branch already exists:**
```text
❌ Branch already exists

Branch 'feature/user-auth' already exists.

Options:
  - Switch to it: git checkout feature/user-auth
  - Delete and recreate: git branch -D feature/user-auth
```

**If base branch not found:**
```text
❌ Base branch not found

Branch 'develop' does not exist locally or on remote.

Available branches:
  - main
  - master
```

**If push fails:**
```text
❌ Failed to push branch

Could not push 'feature/user-auth' to remote.

Possible causes:
  - No remote configured
  - Authentication failed
  - Network error

Branch was created locally. Push manually with:
  git push -u origin feature/user-auth
```

Return error JSON:
```json
{
  "error": true,
  "message": "Branch 'feature/user-auth' already exists",
  "branchName": "feature/user-auth"
}
```

## Notes

- **Branch naming**: Use prefixes like `feature/`, `bugfix/`, `hotfix/`, `chore/`
- **Base branch**: Defaults to current branch if not specified
- **Tracking**: `--push` sets up remote tracking automatically
- **Dirty worktree**: Warns but proceeds with uncommitted changes

## Use Cases

### Feature Development
```bash
# Start new feature from main
/git-create-branch feature/user-authentication main --push
```

### Bug Fix
```bash
# Create bugfix branch from current
/git-create-branch bugfix/fix-login-error --push
```

### Hotfix from Production
```bash
# Create hotfix from production branch
/git-create-branch hotfix/critical-fix production --push
```

### Local Experimentation
```bash
# Create local branch without pushing
/git-create-branch experiment/try-new-approach
```

## Integration with Work System

When starting work on a Teamwork task:
```bash
# 1. Select or resume task
/resume

# 2. Create feature branch
/git-create-branch feature/TW-26134585-user-auth main --push

# 3. Begin development...
```
