---
description: Commit all changes and push to remote in one command (helper)
allowedTools:
  - Bash
  - SlashCommand
---

# Git: Push to Remote

Commits all changes and pushes to remote repository in a single operation. This is a convenience command that combines `/git-commit --all` with `git push`.

## Usage

```bash
/git-push "feat: add user authentication"
/git-push "fix: resolve login bug" --force
/git-push "docs: update README" --set-upstream
```

## Input Parameters

- **message** (required): Commit message in conventional commit format
- **--force** (optional): Force push (use with caution)
- **--set-upstream** (optional): Set upstream tracking for new branches

## Implementation

1. **Parse input and flags:**
   ```bash
   message=""
   forcePush=false
   setUpstream=false

   for arg in "$@"; do
     case "$arg" in
       --force) forcePush=true ;;
       --set-upstream|-u) setUpstream=true ;;
       *)
         if [ -z "$message" ]; then
           message="$arg"
         fi
         ;;
     esac
   done

   # Validate required parameters
   if [ -z "$message" ]; then
     echo "❌ Missing required parameter: message"
     echo ""
     echo "Usage: /git-push <message> [--force] [--set-upstream]"
     echo ""
     echo "Examples:"
     echo "  /git-push \"feat: add login form\""
     echo "  /git-push \"fix: resolve crash\" --set-upstream"
     exit 1
   fi
   ```

2. **Show current status (via /git-status):**
   ```bash
   echo "📊 Current Status:"
   /git-status --short
   echo ""
   ```

3. **Fetch and check remote status:**
   ```bash
   currentBranch=$(git branch --show-current)
   echo "🔄 Checking remote status..."
   git fetch origin --quiet 2>/dev/null

   # Check if upstream exists
   upstream=$(git rev-parse --abbrev-ref "$currentBranch@{upstream}" 2>/dev/null)

   if [ -n "$upstream" ]; then
     behind=$(git rev-list --count HEAD.."$upstream" 2>/dev/null || echo 0)
     ahead=$(git rev-list --count "$upstream"..HEAD 2>/dev/null || echo 0)

     if [ "$behind" -gt 0 ] && [ "$forcePush" = false ]; then
       echo "⚠️  Remote is $behind commit(s) ahead"
       echo ""
       echo "Options:"
       echo "  1. Pull first: /git-pull --rebase"
       echo "  2. Force push: /git-push \"message\" --force"
       echo "     ⚠️  This will overwrite remote changes!"
       echo ""
       echo "Aborting to prevent overwriting remote changes."
       exit 1
     fi

     echo "   ↓ $behind behind | ↑ $ahead ahead"
   else
     echo "   No upstream tracking (will set with push)"
     setUpstream=true
   fi
   echo ""
   ```

4. **Check for changes:**
   ```bash
   # Check for any changes (staged or unstaged)
   if [ -z "$(git status --porcelain)" ]; then
     echo "⚠️  No changes to commit"
     echo ""
     echo "Working directory is clean."
     echo ""
     echo "Options:"
     echo "  - Make changes first"
     echo "  - Push existing commits: git push"
     exit 0
   fi
   ```

5. **Stage all changes:**
   ```bash
   echo "📦 Staging all changes..."
   git add -A

   # Show what will be committed
   stagedFiles=$(git diff --cached --name-only)
   fileCount=$(echo "$stagedFiles" | grep -c .)
   echo "   $fileCount file(s) staged"
   ```

6. **Run commit via /git-commit:**
   ```bash
   # Execute the git-commit command
   echo ""
   echo "📝 Creating commit..."
   /git-commit "$message" --all

   # Get commit info
   commitHash=$(git rev-parse --short HEAD)
   echo "   Commit: $commitHash"
   ```

   **Alternative direct implementation:**
   ```bash
   # Validate conventional commit format (warning only)
   if ! echo "$message" | grep -qE "^(feat|fix|docs|style|refactor|test|chore|perf|ci)(\(.+\))?:"; then
     echo "⚠️  Non-conventional commit format"
   fi

   # Create commit
   git commit -m "$message"
   commitHash=$(git rev-parse --short HEAD)
   ```

7. **Get current branch and remote info:**
   ```bash
   currentBranch=$(git branch --show-current)

   # Check if upstream is set
   upstream=$(git rev-parse --abbrev-ref "$currentBranch@{upstream}" 2>/dev/null)
   hasUpstream=$?
   ```

8. **Push to remote:**
   ```bash
   echo ""
   echo "🚀 Pushing to remote..."

   pushArgs="origin $currentBranch"

   # Add flags
   if [ "$forcePush" = true ]; then
     echo "   ⚠️  Force pushing..."
     pushArgs="--force $pushArgs"
   fi

   if [ "$setUpstream" = true ] || [ $hasUpstream -ne 0 ]; then
     echo "   Setting upstream tracking..."
     pushArgs="-u $pushArgs"
   fi

   git push $pushArgs
   ```

9. **Output result:**

**Success response:**
```json
{
  "commit": {
    "hash": "a1b2c3d",
    "message": "feat: add user authentication",
    "filesChanged": 5
  },
  "push": {
    "remote": "origin",
    "branch": "feature/user-auth",
    "forced": false,
    "upstreamSet": true
  },
  "success": true
}
```

## Error Handling

**If no changes to commit:**
```text
⚠️  No changes to commit

Working directory is clean.

Options:
  - Make changes first
  - Push existing commits: git push
```

**If commit fails:**
```text
❌ Commit failed

Could not create commit. Possible causes:
  - Pre-commit hook failed
  - Invalid commit message format

Check git status and try again.
```

**If push fails (no upstream):**
```text
❌ Push failed - no upstream branch

Branch 'feature/new' has no upstream tracking.

Set upstream with:
  /git-push "message" --set-upstream

Or manually:
  git push -u origin feature/new
```

**If push fails (remote ahead):**
```text
❌ Push rejected - remote has changes

Remote branch has commits not in local.

Options:
  1. Pull first: /git-pull --rebase
  2. Force push: /git-push "message" --force
     ⚠️  This will overwrite remote changes!
```

**If push fails (authentication):**
```text
❌ Push failed - authentication error

Could not authenticate with remote.

For SSH:
  ssh -T git@github.com

For HTTPS:
  git credential reject
```

Return error JSON:
```json
{
  "error": true,
  "message": "Push rejected - remote has changes",
  "localCommit": "a1b2c3d",
  "suggestion": "Pull first with: /git-pull --rebase"
}
```

## Notes

- **All-in-one**: Stages all changes, commits, and pushes
- **Conventional commits**: Validates commit message format
- **Auto-upstream**: Automatically sets upstream for new branches with `--set-upstream`
- **Force with caution**: `--force` overwrites remote history

## Use Cases

### Quick Feature Push
```bash
# After completing a feature
/git-push "feat(auth): implement password reset"
```

### Bug Fix
```bash
# Quick bug fix
/git-push "fix: resolve null pointer in login"
```

### New Branch First Push
```bash
# First push of a new branch
/git-push "feat: initial feature implementation" --set-upstream
```

### Force Update After Rebase
```bash
# After rebasing, force push to update PR
/git-push "refactor: clean up authentication code" --force
```

## Workflow Comparison

### Without git-push
```bash
git add -A
git commit -m "feat: add feature"
git push origin feature/branch
```

### With git-push
```bash
/git-push "feat: add feature"
```

## Integration with Work System

Complete task workflow:
```bash
# 1. Work on task...

# 2. Push all changes
/git-push "feat(auth): implement login TW-26134585"

# 3. Create PR
/github:gh-create-pr "feat(auth): Implement login"

# 4. Log time
/tw-create-task-timelog 26134585 "2025-12-07" 2 30 "Implemented login feature"
```

## Safety Features

1. **No silent overwrites**: Warns before force push
2. **Shows staged files**: Displays what will be committed
3. **Commit validation**: Warns on non-conventional commit format
4. **Upstream handling**: Prompts to set upstream for new branches

## Related Commands

- `/git-commit` - Commit without pushing
- `/git-pull` - Pull before pushing if remote ahead
- `/git-create-branch` - Create branch with `--push` for immediate upstream
