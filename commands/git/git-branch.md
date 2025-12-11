---
description: Get current branch name or list branches (helper)
allowedTools:
  - Bash
---

# Git: Branch

Get current branch name, previous branch, or list available branches.

## Usage

```bash
/git-branch                      # Get current branch name
/git-branch --previous          # Get previous branch name
/git-branch --list              # List local branches
/git-branch --list --all        # List all branches (local + remote)
```

## Input Parameters

- **--previous** (optional): Get previous branch name
- **--list** (optional): List branches instead of showing current
- **--all** (optional): Include remote branches (requires --list)

## Implementation

1. **Parse input flags:**
   ```bash
   showPrevious=false
   listBranches=false
   showAll=false

   for arg in "$@"; do
     case "$arg" in
       --previous|-p) showPrevious=true ;;
       --list|-l) listBranches=true ;;
       --all|-a) showAll=true ;;
     esac
   done
   ```

2. **Get previous branch:**
   ```bash
   if [ "$showPrevious" = true ]; then
     previousBranch=$(git rev-parse --abbrev-ref @{-1} 2>/dev/null)

     if [ -z "$previousBranch" ]; then
       echo "❌ No previous branch found"
       exit 1
     fi

     echo "$previousBranch"
     exit 0
   fi
   ```

3. **List branches:**
   ```bash
   if [ "$listBranches" = true ]; then
     if [ "$showAll" = true ]; then
       echo "📋 All branches (local + remote):"
       git branch -a
     else
       echo "📋 Local branches:"
       git branch
     fi
     exit 0
   fi
   ```

4. **Get current branch:**
   ```bash
   currentBranch=$(git branch --show-current)

   # Check if in detached HEAD state
   if [ -z "$currentBranch" ]; then
     currentBranch=$(git rev-parse --short HEAD 2>/dev/null)
     if [ -z "$currentBranch" ]; then
       echo "❌ Not in a git repository"
       exit 1
     fi
     echo "⚠️  Detached HEAD at $currentBranch"
     exit 0
   fi

   echo "$currentBranch"
   ```

## Output Format

### Current Branch
```
feature/user-auth
```

### Previous Branch
```
main
```

### List Branches
```
📋 Local branches:
  main
* feature/user-auth
  feature/notifications
```

### List All Branches
```
📋 All branches (local + remote):
  main
* feature/user-auth
  remotes/origin/main
  remotes/origin/feature/user-auth
```

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Not in git repo | Exit with error message |
| Detached HEAD | Show commit hash with warning |
| No previous branch | Exit with error message |

## Usage Examples

### Get Current Branch
```bash
$ /git-branch
feature/user-auth
```

### Get Previous Branch
```bash
$ /git-branch --previous
main
```

### Use in Scripts
```bash
# Store current branch in variable
currentBranch=$(/git-branch)
echo "Working on: $currentBranch"

# Check if on main branch
if [ "$(/git-branch)" = "main" ]; then
  echo "On main branch"
fi
```

## Common Patterns

### Branch Name for Commit Message
```bash
branch=$(/git-branch)
echo "Changes on $branch"
```

### Check Before Operations
```bash
if [ "$(/git-branch)" = "main" ]; then
  echo "⚠️  You're on main branch"
  exit 1
fi
```

### Switch Back to Previous Branch
```bash
previousBranch=$(/git-branch --previous)
/git-checkout "$previousBranch"
```

## Related Commands

- **/git-checkout** - Switch branches
- **/git-create-branch** - Create new branch
- **/git-delete-branch** - Delete branch
- **/git-status** - Full status including branch info

## Notes

- Returns just the branch name (no decorations) for easy scripting
- Detached HEAD state shows commit hash instead
- Remote branches require fetch to be up-to-date
- Previous branch uses git's @{-1} syntax
