---
description: Switch branches safely with auto-stash (helper)
allowedTools:
  - Bash
  - SlashCommand
---

# GitHub CLI: Checkout Branch

Safely switches to another branch, automatically handling uncommitted changes with stash.

## Usage

```bash
/gh-checkout feature/other      # Switch to branch
/gh-checkout main --pull        # Switch and pull latest
/gh-checkout -                  # Switch to previous branch
/gh-checkout feature/new --create   # Create and switch
```

## Input Parameters

- **branch** (required): Branch to switch to (or `-` for previous)
- **--pull** (optional): Pull latest after switching
- **--create** (optional): Create branch if it doesn't exist
- **--discard** (optional): Discard local changes instead of stashing

## Implementation

1. **Parse input and flags:**
   ```bash
   targetBranch=""
   pullAfter=false
   createBranch=false
   discardChanges=false

   for arg in "$@"; do
     case "$arg" in
       --pull) pullAfter=true ;;
       --create) createBranch=true ;;
       --discard) discardChanges=true ;;
       *)
         if [ -z "$targetBranch" ]; then
           targetBranch="$arg"
         fi
         ;;
     esac
   done

   # Validate required parameters
   if [ -z "$targetBranch" ]; then
     echo "❌ Missing required parameter: branch"
     echo ""
     echo "Usage: /gh-checkout <branch> [--pull] [--create] [--discard]"
     echo ""
     echo "Examples:"
     echo "  /gh-checkout main"
     echo "  /gh-checkout feature/other --pull"
     echo "  /gh-checkout feature/new --create"
     echo "  /gh-checkout -                  # previous branch"
     exit 1
   fi
   ```

2. **Show current status:**
   ```bash
   currentBranch=$(git branch --show-current)

   echo "📍 Current branch: $currentBranch"
   /gh-status --short
   echo ""
   ```

3. **Handle special branch reference:**
   ```bash
   # Handle "-" for previous branch
   if [ "$targetBranch" = "-" ]; then
     targetBranch=$(git rev-parse --abbrev-ref @{-1} 2>/dev/null)
     if [ -z "$targetBranch" ]; then
       echo "❌ No previous branch found"
       exit 1
     fi
     echo "   Previous branch: $targetBranch"
   fi
   ```

4. **Check if branch exists:**
   ```bash
   branchExists=false

   # Check local
   if git show-ref --verify --quiet "refs/heads/$targetBranch"; then
     branchExists=true
   fi

   # Check remote if not local
   if [ "$branchExists" = false ]; then
     git fetch origin --quiet 2>/dev/null
     if git show-ref --verify --quiet "refs/remotes/origin/$targetBranch"; then
       branchExists=true
       isRemote=true
     fi
   fi

   # Handle non-existent branch
   if [ "$branchExists" = false ]; then
     if [ "$createBranch" = true ]; then
       echo "📌 Creating new branch: $targetBranch"
     else
       echo "❌ Branch '$targetBranch' not found"
       echo ""
       echo "Options:"
       echo "  - Create it: /gh-checkout $targetBranch --create"
       echo "  - List branches: git branch -a"
       echo ""
       echo "Local branches:"
       git branch | head -10
       exit 1
     fi
   fi
   ```

5. **Handle uncommitted changes:**
   ```bash
   hasChanges=false
   stashCreated=false

   if [ -n "$(git status --porcelain)" ]; then
     hasChanges=true
     staged=$(git diff --cached --name-only | wc -l | tr -d ' ')
     modified=$(git diff --name-only | wc -l | tr -d ' ')
     untracked=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')

     echo "📦 Uncommitted changes detected:"
     echo "   Staged: $staged | Modified: $modified | Untracked: $untracked"
     echo ""

     if [ "$discardChanges" = true ]; then
       echo "🗑️  Discarding changes..."
       git checkout -- .
       git clean -fd
     else
       echo "📦 Stashing changes..."
       stashMessage="gh-checkout auto-stash from $currentBranch $(date +%Y%m%d-%H%M%S)"
       git stash push -u -m "$stashMessage"
       stashCreated=true
       echo "   Stashed as: $stashMessage"
     fi
   fi
   ```

6. **Switch to branch:**
   ```bash
   echo ""
   echo "🔀 Switching to $targetBranch..."

   if [ "$createBranch" = true ] && [ "$branchExists" = false ]; then
     git checkout -b "$targetBranch"
   elif [ "$isRemote" = true ]; then
     # Create local tracking branch from remote
     git checkout -b "$targetBranch" "origin/$targetBranch"
   else
     git checkout "$targetBranch"
   fi
   ```

7. **Pull if requested:**
   ```bash
   if [ "$pullAfter" = true ]; then
     echo ""
     echo "🔄 Pulling latest..."
     git pull origin "$targetBranch" --rebase 2>/dev/null || git pull origin "$targetBranch"
   fi
   ```

8. **Show final status:**
   ```bash
   echo ""
   echo "✅ Now on: $targetBranch"

   if [ "$stashCreated" = true ]; then
     echo ""
     echo "💡 Your changes from '$currentBranch' are stashed."
     echo "   To restore when back: git stash pop"
     echo "   To see stashes: git stash list"
   fi
   ```

9. **Output result:**

**Success response:**
```json
{
  "checkout": {
    "from": "feature/user-auth",
    "to": "main",
    "stashed": true,
    "stashMessage": "gh-checkout auto-stash from feature/user-auth",
    "pulled": true,
    "created": false
  },
  "success": true
}
```

## Error Handling

**If branch not found:**
```text
❌ Branch 'feature/nonexistent' not found

Options:
  - Create it: /gh-checkout feature/nonexistent --create
  - List branches: git branch -a

Local branches:
  main
  develop
  feature/user-auth
```

**If checkout fails:**
```text
❌ Checkout failed

Could not switch to 'feature/other'.

Possible causes:
  - Unresolved conflicts
  - Uncommitted changes in conflict

Try:
  - Commit or stash changes
  - git status for details
```

**If stash conflicts on return:**
```text
⚠️  Stash apply had conflicts

Your stashed changes conflicted with current state.
Resolve conflicts in:
  src/auth/login.ts

Stash is preserved. After resolving:
  git stash drop
```

Return error JSON:
```json
{
  "error": true,
  "message": "Branch 'feature/nonexistent' not found",
  "availableBranches": ["main", "develop", "feature/user-auth"]
}
```

## Notes

- **Auto-stash**: Automatically stashes uncommitted changes
- **Remote tracking**: Creates local branch from remote if needed
- **Previous branch**: Use `-` to toggle between branches
- **Safe by default**: Never loses uncommitted work

## Use Cases

### Quick Branch Switch
```bash
# Switch to another branch
/gh-checkout feature/other
```

### Switch and Update
```bash
# Switch to main and get latest
/gh-checkout main --pull
```

### Toggle Between Branches
```bash
# Go back to previous branch
/gh-checkout -
```

### Start New Work
```bash
# Create and switch to new branch
/gh-checkout feature/new-feature --create
```

### Review PR Branch
```bash
# Checkout PR branch from remote
/gh-checkout feature/pr-branch --pull
```

### Discard and Switch
```bash
# Abandon local changes and switch
/gh-checkout main --discard
```

## Integration with Work System

Switching between tasks:
```bash
# 1. Working on feature A, need to switch to urgent bug
/gh-checkout bugfix/urgent-fix

# 2. Fix bug, commit, push
/gh-commit "fix: urgent bug" --all
/gh-push-remote "fix: urgent bug"

# 3. Return to feature A (changes auto-restored from stash)
/gh-checkout -
git stash pop
```

Code review workflow:
```bash
# 1. Checkout PR branch
/gh-checkout feature/pr-to-review --pull

# 2. Review code...

# 3. Return to your work
/gh-checkout -
```

## Stash Management

When switching branches, stashes are named with context:
```
gh-checkout auto-stash from feature/user-auth 20251208-143022
```

View your stashes:
```bash
git stash list
```

Restore a specific stash:
```bash
git stash pop stash@{0}
```

## Related Commands

- `/gh-create-branch` - Create new branch from base
- `/gh-sync` - Sync current branch with main
- `/gh-status` - Check current state
