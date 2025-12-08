---
description: Sync current branch with main/base branch (helper)
allowedTools:
  - Bash
  - SlashCommand
---

# GitHub CLI: Sync Branch

Fetches latest changes and rebases current branch on main (or specified base). This is the most common operation for keeping feature branches up to date.

## Usage

```bash
/gh-sync                        # Rebase current branch on main
/gh-sync develop                # Rebase on develop instead
/gh-sync --merge                # Merge instead of rebase
/gh-sync --stash                # Auto-stash local changes
```

## Input Parameters

- **baseBranch** (optional): Branch to sync with (default: main)
- **--merge** (optional): Use merge instead of rebase
- **--stash** (optional): Auto-stash and restore local changes
- **--push** (optional): Force push after rebase (for updating PR)

## Implementation

1. **Parse input and flags:**
   ```bash
   baseBranch="main"
   useRebase=true
   autoStash=false
   pushAfter=false

   for arg in "$@"; do
     case "$arg" in
       --merge) useRebase=false ;;
       --stash) autoStash=true ;;
       --push) pushAfter=true ;;
       *)
         # Check if it's a branch name
         if ! [[ "$arg" == --* ]]; then
           baseBranch="$arg"
         fi
         ;;
     esac
   done
   ```

2. **Show current status:**
   ```bash
   currentBranch=$(git branch --show-current)

   echo "📊 Sync Status:"
   echo "   Current: $currentBranch"
   echo "   Target:  $baseBranch"
   echo ""

   # Check if on base branch
   if [ "$currentBranch" = "$baseBranch" ]; then
     echo "📍 On $baseBranch - pulling latest..."
     /gh-pull
     exit 0
   fi
   ```

3. **Check for uncommitted changes:**
   ```bash
   hasChanges=false
   if [ -n "$(git status --porcelain)" ]; then
     hasChanges=true

     if [ "$autoStash" = true ]; then
       echo "📦 Stashing local changes..."
       git stash push -m "gh-sync auto-stash $(date +%Y%m%d-%H%M%S)"
       stashCreated=true
     else
       echo "⚠️  Uncommitted changes detected"
       echo ""
       echo "Options:"
       echo "  - Auto-stash: /gh-sync --stash"
       echo "  - Commit first: /gh-commit \"message\" --all"
       echo "  - Stash manually: git stash"
       echo ""
       exit 1
     fi
   fi
   ```

4. **Fetch latest from remote:**
   ```bash
   echo "🔄 Fetching latest..."
   git fetch origin --prune

   # Check if base branch exists on remote
   if ! git rev-parse --verify "origin/$baseBranch" &>/dev/null; then
     echo "❌ Branch 'origin/$baseBranch' not found"
     echo ""
     echo "Available remote branches:"
     git branch -r | grep -v HEAD | head -10
     exit 1
   fi
   ```

5. **Show what will be synced:**
   ```bash
   # Count commits to rebase
   behindBase=$(git rev-list --count HEAD.."origin/$baseBranch" 2>/dev/null || echo 0)
   aheadBase=$(git rev-list --count "origin/$baseBranch"..HEAD 2>/dev/null || echo 0)

   echo ""
   echo "📈 Branch status:"
   echo "   $baseBranch has $behindBase new commit(s)"
   echo "   $currentBranch has $aheadBase commit(s) to rebase"

   if [ "$behindBase" -eq 0 ]; then
     echo ""
     echo "✅ Already up to date with $baseBranch"

     # Restore stash if created
     if [ "$stashCreated" = true ]; then
       echo "📦 Restoring stashed changes..."
       git stash pop
     fi
     exit 0
   fi
   ```

6. **Perform sync (rebase or merge):**
   ```bash
   echo ""

   if [ "$useRebase" = true ]; then
     echo "🔀 Rebasing on origin/$baseBranch..."
     if ! git rebase "origin/$baseBranch"; then
       echo ""
       echo "❌ Rebase conflicts detected"
       echo ""
       echo "Resolve conflicts:"
       echo "  1. Edit conflicting files"
       echo "  2. git add <resolved-files>"
       echo "  3. git rebase --continue"
       echo ""
       echo "Or abort: git rebase --abort"

       # Show conflicting files
       echo ""
       echo "Conflicting files:"
       git diff --name-only --diff-filter=U
       exit 1
     fi
   else
     echo "🔀 Merging origin/$baseBranch..."
     if ! git merge "origin/$baseBranch" -m "Merge $baseBranch into $currentBranch"; then
       echo ""
       echo "❌ Merge conflicts detected"
       echo ""
       echo "Resolve conflicts, then:"
       echo "  git add <resolved-files>"
       echo "  git commit"
       echo ""
       echo "Or abort: git merge --abort"
       exit 1
     fi
   fi

   echo "✅ Sync complete!"
   ```

7. **Restore stashed changes:**
   ```bash
   if [ "$stashCreated" = true ]; then
     echo ""
     echo "📦 Restoring stashed changes..."
     if ! git stash pop; then
       echo "⚠️  Stash conflicts - resolve manually"
       echo "   Your changes are in: git stash list"
     fi
   fi
   ```

8. **Push if requested:**
   ```bash
   if [ "$pushAfter" = true ]; then
     echo ""
     echo "🚀 Force pushing to update remote..."
     git push --force-with-lease origin "$currentBranch"
   fi
   ```

9. **Output result:**

**Success response:**
```json
{
  "sync": {
    "currentBranch": "feature/user-auth",
    "baseBranch": "main",
    "method": "rebase",
    "commitsRebased": 5,
    "newCommitsFromBase": 3,
    "pushed": true
  },
  "success": true
}
```

## Error Handling

**If uncommitted changes:**
```text
⚠️  Uncommitted changes detected

Options:
  - Auto-stash: /gh-sync --stash
  - Commit first: /gh-commit "message" --all
  - Stash manually: git stash
```

**If rebase conflicts:**
```text
❌ Rebase conflicts detected

Resolve conflicts:
  1. Edit conflicting files
  2. git add <resolved-files>
  3. git rebase --continue

Or abort: git rebase --abort

Conflicting files:
  src/auth/login.ts
  src/api/user.ts
```

**If base branch not found:**
```text
❌ Branch 'origin/develop' not found

Available remote branches:
  origin/main
  origin/feature/other
```

Return error JSON:
```json
{
  "error": true,
  "message": "Rebase conflicts detected",
  "conflicts": ["src/auth/login.ts", "src/api/user.ts"]
}
```

## Notes

- **Rebase default**: Uses rebase for clean linear history
- **Safe stash**: `--stash` safely preserves uncommitted work
- **Force push**: Use `--push` after rebase to update PR
- **On main**: If already on main, just pulls latest

## Use Cases

### Daily Sync
```bash
# Keep feature branch up to date
/gh-sync
```

### Before Creating PR
```bash
# Ensure branch is current before PR
/gh-sync --push
```

### Quick Sync with Local Changes
```bash
# Auto-stash, sync, restore
/gh-sync --stash
```

### Sync with Different Base
```bash
# Sync with develop instead of main
/gh-sync develop
```

### Update PR After Main Changes
```bash
# Rebase and update PR
/gh-sync --push
```

## Integration with Work System

Daily workflow:
```bash
# 1. Start of day - sync your branch
/gh-sync --stash

# 2. Work on feature...
/gh-commit "feat: progress on feature" --all

# 3. Before PR or end of day
/gh-sync --push
```

Before PR review:
```bash
# Ensure branch is current
/gh-sync --push
/gh-create-pr "feat: My feature"
```

## Rebase vs Merge

| Aspect | Rebase (default) | Merge |
|--------|------------------|-------|
| History | Linear | Shows merge commits |
| Commits | Rewritten | Preserved |
| PR updates | Requires force push | Normal push |
| Conflicts | Per-commit | All at once |

**We default to rebase** for clean linear history.

## Related Commands

- `/gh-pull` - Pull current branch's upstream
- `/gh-push-remote` - Push after sync
- `/gh-create-pr` - Create PR after sync
