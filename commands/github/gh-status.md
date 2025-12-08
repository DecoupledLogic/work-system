---
description: Show git working directory and repository status (helper)
allowedTools:
  - Bash
---

# GitHub CLI: Status

Shows comprehensive git status including working directory, staging area, branch info, and remote sync status.

## Usage

```bash
/gh-status                      # Full status overview
/gh-status --short              # Compact format
/gh-status --remote             # Include remote comparison
```

## Input Parameters

- **--short** (optional): Compact single-line format
- **--remote** (optional): Fetch and compare with remote branch

## Implementation

1. **Parse input flags:**
   ```bash
   shortFormat=false
   checkRemote=false

   for arg in "$@"; do
     case "$arg" in
       --short|-s) shortFormat=true ;;
       --remote|-r) checkRemote=true ;;
     esac
   done
   ```

2. **Get branch information:**
   ```bash
   currentBranch=$(git branch --show-current)

   # Check if in a git repo
   if [ -z "$currentBranch" ]; then
     # Might be detached HEAD
     currentBranch=$(git rev-parse --short HEAD 2>/dev/null)
     if [ -z "$currentBranch" ]; then
       echo "❌ Not in a git repository"
       exit 1
     fi
     echo "⚠️  Detached HEAD at $currentBranch"
   fi
   ```

3. **Get working directory status:**
   ```bash
   # Count files by status
   staged=$(git diff --cached --name-only | wc -l | tr -d ' ')
   modified=$(git diff --name-only | wc -l | tr -d ' ')
   untracked=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')

   # Check for conflicts
   conflicts=$(git diff --name-only --diff-filter=U | wc -l | tr -d ' ')
   ```

4. **Get remote sync status (if requested or available):**
   ```bash
   upstream=$(git rev-parse --abbrev-ref "$currentBranch@{upstream}" 2>/dev/null)
   behind=0
   ahead=0

   if [ -n "$upstream" ]; then
     if [ "$checkRemote" = true ]; then
       echo "🔄 Fetching from remote..."
       git fetch origin --quiet 2>/dev/null
     fi

     behind=$(git rev-list --count HEAD.."$upstream" 2>/dev/null || echo 0)
     ahead=$(git rev-list --count "$upstream"..HEAD 2>/dev/null || echo 0)
   fi
   ```

5. **Get recent commits:**
   ```bash
   lastCommit=$(git log -1 --format="%h %s" 2>/dev/null)
   ```

6. **Output result:**

**Full format:**
```text
📍 Branch: feature/user-auth
   Tracking: origin/feature/user-auth
   ↓ 3 behind  ↑ 1 ahead

📁 Working Directory:
   ✅ Staged:     5 files ready to commit
   ✏️  Modified:   2 files (unstaged)
   ❓ Untracked:  3 files

📝 Last Commit:
   a1b2c3d feat(auth): add login form

💡 Suggestions:
   - Pull remote changes: /gh-pull --rebase
   - Stage all changes: git add -A
   - Commit staged: /gh-commit "message"
```

**Short format (--short):**
```text
feature/user-auth | ↓3 ↑1 | staged:5 modified:2 untracked:3
```

**JSON response:**
```json
{
  "branch": {
    "name": "feature/user-auth",
    "upstream": "origin/feature/user-auth",
    "behind": 3,
    "ahead": 1
  },
  "workingDirectory": {
    "staged": 5,
    "modified": 2,
    "untracked": 3,
    "conflicts": 0,
    "clean": false
  },
  "lastCommit": {
    "hash": "a1b2c3d",
    "message": "feat(auth): add login form"
  },
  "suggestions": [
    "Pull remote changes: /gh-pull --rebase",
    "Stage all changes: git add -A"
  ]
}
```

## Status Indicators

| Icon | Meaning |
|------|---------|
| ✅ | Staged (ready to commit) |
| ✏️ | Modified (not staged) |
| ❓ | Untracked (new file) |
| ⚠️ | Conflict (needs resolution) |
| ↓ | Commits behind remote |
| ↑ | Commits ahead of remote |

## Contextual Suggestions

Based on status, provide actionable suggestions:

| Condition | Suggestion |
|-----------|------------|
| Behind remote | `/gh-pull --rebase` |
| Unstaged changes | `git add -A` or `git add <file>` |
| Staged changes | `/gh-commit "message"` |
| Ahead of remote | `git push` or `/gh-push-remote` |
| Conflicts | Resolve conflicts, then `git add` |
| Clean + in sync | "Working directory clean, up to date" |

## Error Handling

**If not in git repository:**
```text
❌ Not in a git repository

Initialize with:
  git init

Or clone existing:
  git clone <url>
```

**If no commits yet:**
```text
📍 Branch: main (no commits)

📁 Working Directory:
   ❓ Untracked:  5 files

💡 Create initial commit:
   git add -A
   /gh-commit "feat: initial commit"
```

## Notes

- **Non-destructive**: Status never modifies files
- **Remote check**: `--remote` fetches to get accurate behind/ahead counts
- **Suggestions**: Contextual help based on current state
- **Integration**: Called by other commands before operations

## Use Cases

### Quick Status Check
```bash
# See what's changed
/gh-status
```

### Before Committing
```bash
# Check what will be committed
/gh-status
/gh-commit "feat: add feature" --all
```

### Check Remote Sync
```bash
# See if you need to pull
/gh-status --remote
```

### CI/Automation
```bash
# Machine-readable short format
/gh-status --short
```

## Integration with Other Commands

This command is called internally by:

- `/gh-commit` - Shows status before commit confirmation
- `/gh-push-remote` - Checks remote status before pushing
- `/gh-pull` - Shows status after pull completes

## Related Commands

- `/gh-fetch` - Fetch without status display
- `/gh-pull` - Pull and update local branch
- `/gh-commit` - Commit staged changes
