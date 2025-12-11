---
description: Pull changes from remote repository (helper)
allowedTools:
  - Bash
---

# Git: Pull Changes

Pulls latest changes from remote repository with options for rebase or merge.

## Usage

```bash
/git-pull                        # Pull current branch
/git-pull main                   # Pull and merge main into current
/git-pull --rebase               # Pull with rebase
/git-pull origin develop         # Pull from specific remote/branch
```

## Input Parameters

- **branch** (optional): Branch to pull from (default: current branch's upstream)
- **remote** (optional): Remote name (default: origin)
- **--rebase** (optional): Rebase local changes on top of remote
- **--stash** (optional): Stash local changes before pull, restore after

## Implementation

1. **Parse input and flags:**
   ```bash
   remote="origin"
   branch=""
   useRebase=false
   autoStash=false

   for arg in "$@"; do
     case "$arg" in
       --rebase) useRebase=true ;;
       --stash) autoStash=true ;;
       *)
         if [ -z "$branch" ]; then
           # Check if it looks like a remote name
           if git remote | grep -q "^$arg$"; then
             remote="$arg"
           else
             branch="$arg"
           fi
         else
           branch="$arg"
         fi
         ;;
     esac
   done

   # Default to current branch if not specified
   if [ -z "$branch" ]; then
     branch=$(git branch --show-current)
   fi
   ```

2. **Check for uncommitted changes:**
   ```bash
   hasChanges=false
   if [ -n "$(git status --porcelain)" ]; then
     hasChanges=true

     if [ "$autoStash" = true ]; then
       echo "📦 Stashing local changes..."
       git stash push -m "git-pull auto-stash"
     else
       echo "⚠️  You have uncommitted changes"
       echo ""
       echo "Options:"
       echo "  - Stash automatically: /git-pull --stash"
       echo "  - Commit first: /git-commit \"message\" --all"
       echo "  - Stash manually: git stash"
       echo ""
       echo "Proceeding with pull (may cause conflicts)..."
     fi
   fi
   ```

3. **Fetch latest:**
   ```bash
   echo "🔄 Fetching from $remote..."
   git fetch "$remote" --prune
   ```

4. **Check for upstream changes:**
   ```bash
   localRef=$(git rev-parse HEAD)
   remoteRef=$(git rev-parse "$remote/$branch" 2>/dev/null)

   if [ "$localRef" = "$remoteRef" ]; then
     echo "✅ Already up to date"
     exit 0
   fi

   # Count commits behind/ahead
   behind=$(git rev-list --count HEAD.."$remote/$branch")
   ahead=$(git rev-list --count "$remote/$branch"..HEAD)

   echo "📊 Status: $behind commits behind, $ahead commits ahead"
   ```

5. **Pull changes:**
   ```bash
   if [ "$useRebase" = true ]; then
     echo "🔀 Rebasing on $remote/$branch..."
     git pull --rebase "$remote" "$branch"
   else
     echo "🔀 Merging from $remote/$branch..."
     git pull "$remote" "$branch"
   fi
   ```

6. **Restore stashed changes:**
   ```bash
   if [ "$autoStash" = true ] && [ "$hasChanges" = true ]; then
     echo "📦 Restoring stashed changes..."
     git stash pop
   fi
   ```

7. **Output result:**

**Success response:**
```json
{
  "pull": {
    "remote": "origin",
    "branch": "main",
    "method": "rebase",
    "commitsBehind": 5,
    "commitsAhead": 2,
    "stashed": true,
    "conflicts": false
  },
  "success": true
}
```

## Error Handling

**If merge conflicts occur:**
```text
❌ Merge conflicts detected

The following files have conflicts:
  - src/auth/login.ts
  - src/api/user.ts

Resolve conflicts, then:
  1. Edit conflicting files
  2. Stage resolved files: git add <file>
  3. Complete merge: git commit

Or abort: git merge --abort
```

**If rebase conflicts occur:**
```text
❌ Rebase conflicts detected

Conflict in: src/auth/login.ts

Options:
  1. Resolve conflict in file
  2. Stage: git add src/auth/login.ts
  3. Continue: git rebase --continue

Or abort: git rebase --abort
```

**If branch not found:**
```text
❌ Remote branch not found

Branch 'feature/old' does not exist on 'origin'.

Available remote branches:
  origin/main
  origin/develop
  origin/feature/user-auth
```

**If no upstream configured:**
```text
❌ No upstream branch configured

Current branch 'feature/new' has no upstream.

Set upstream with:
  git push -u origin feature/new

Or pull from specific branch:
  /git-pull main
```

Return error JSON:
```json
{
  "error": true,
  "message": "Merge conflicts detected",
  "conflicts": ["src/auth/login.ts", "src/api/user.ts"]
}
```

## Notes

- **Default behavior**: Pulls from tracking upstream of current branch
- **Rebase preferred**: Use `--rebase` for cleaner history
- **Auto-stash**: `--stash` handles uncommitted changes automatically
- **Prune**: Always prunes deleted remote branches on fetch

## Use Cases

### Daily Sync
```bash
# Start of day - pull latest main
git checkout main
/git-pull
```

### Update Feature Branch
```bash
# Rebase feature on latest main
/git-pull main --rebase
```

### Pull with Local Changes
```bash
# Auto-stash and restore
/git-pull --stash --rebase
```

### Pull from Upstream Fork
```bash
# Pull from upstream remote
/git-pull upstream main
```

## Integration with Work System

Before starting work on a task:
```bash
# 1. Switch to main and pull latest
git checkout main
/git-pull

# 2. Create feature branch
/git-create-branch feature/TW-26134585-new-feature main --push

# 3. Begin work...
```

During long-running feature work:
```bash
# Keep feature branch updated with main
/git-pull main --rebase --stash
```
