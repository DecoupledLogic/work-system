---
description: Merge a GitHub PR with rebase and delete branch (helper)
allowedTools:
  - Bash
---

# GitHub CLI: Merge Pull Request

Merges a GitHub pull request using rebase strategy, then deletes the branch both locally and remotely.

## Usage

```bash
/gh-merge-pr                    # Merge current branch's PR
/gh-merge-pr 123                # Merge PR by number
/gh-merge-pr --squash           # Use squash merge instead of rebase
/gh-merge-pr --no-delete        # Keep branch after merge
```

## Input Parameters

- **prNumber** (optional): PR number to merge (default: PR for current branch)
- **--squash** (optional): Use squash merge instead of rebase
- **--no-delete** (optional): Don't delete branch after merge
- **--admin** (optional): Merge even if checks haven't passed (admin only)

## Merge Strategy

**Default: Rebase merge**
- Creates linear history
- Each commit appears individually on main
- Cleaner git history
- Easier to bisect issues

**Alternative: Squash merge (`--squash`)**
- Combines all commits into one
- Good for messy commit history
- Single commit on main

## Implementation

1. **Parse input and flags:**
   ```bash
   prNumber=""
   mergeStrategy="rebase"
   deleteBranch=true
   adminMerge=false

   for arg in "$@"; do
     case "$arg" in
       --squash) mergeStrategy="squash" ;;
       --no-delete) deleteBranch=false ;;
       --admin) adminMerge=true ;;
       [0-9]*) prNumber="$arg" ;;
     esac
   done
   ```

2. **Get PR information:**
   ```bash
   currentBranch=$(git branch --show-current)

   if [ -z "$prNumber" ]; then
     echo "🔍 Finding PR for branch '$currentBranch'..."
     prInfo=$(gh pr view --json number,title,state,headRefName,baseRefName,mergeable,mergeStateStatus 2>/dev/null)

     if [ -z "$prInfo" ]; then
       echo "❌ No PR found for current branch"
       echo ""
       echo "Create a PR first:"
       echo "  /gh-create-pr \"PR title\""
       exit 1
     fi

     prNumber=$(echo "$prInfo" | jq -r '.number')
     prTitle=$(echo "$prInfo" | jq -r '.title')
     prState=$(echo "$prInfo" | jq -r '.state')
     headBranch=$(echo "$prInfo" | jq -r '.headRefName')
     baseBranch=$(echo "$prInfo" | jq -r '.baseRefName')
     mergeable=$(echo "$prInfo" | jq -r '.mergeable')
     mergeStatus=$(echo "$prInfo" | jq -r '.mergeStateStatus')
   else
     echo "🔍 Getting PR #$prNumber..."
     prInfo=$(gh pr view "$prNumber" --json number,title,state,headRefName,baseRefName,mergeable,mergeStateStatus)
     prTitle=$(echo "$prInfo" | jq -r '.title')
     prState=$(echo "$prInfo" | jq -r '.state')
     headBranch=$(echo "$prInfo" | jq -r '.headRefName')
     baseBranch=$(echo "$prInfo" | jq -r '.baseRefName')
     mergeable=$(echo "$prInfo" | jq -r '.mergeable')
     mergeStatus=$(echo "$prInfo" | jq -r '.mergeStateStatus')
   fi

   echo ""
   echo "📋 PR #$prNumber: $prTitle"
   echo "   $headBranch → $baseBranch"
   echo "   State: $prState | Mergeable: $mergeable"
   ```

3. **Check PR state:**
   ```bash
   if [ "$prState" != "OPEN" ]; then
     echo ""
     echo "❌ PR is not open (state: $prState)"
     exit 1
   fi

   if [ "$mergeable" = "CONFLICTING" ]; then
     echo ""
     echo "❌ PR has merge conflicts"
     echo ""
     echo "Resolve conflicts:"
     echo "  1. git checkout $headBranch"
     echo "  2. git pull origin $baseBranch"
     echo "  3. Resolve conflicts"
     echo "  4. git push"
     exit 1
   fi
   ```

4. **Check CI status:**
   ```bash
   echo ""
   echo "🔄 Checking CI status..."
   checks=$(gh pr checks "$prNumber" 2>/dev/null)
   failedChecks=$(echo "$checks" | grep -c "fail\|error" || echo 0)
   pendingChecks=$(echo "$checks" | grep -c "pending" || echo 0)

   if [ "$failedChecks" -gt 0 ]; then
     echo "❌ $failedChecks check(s) failed"
     echo ""
     echo "$checks" | grep "fail\|error"
     echo ""
     if [ "$adminMerge" = false ]; then
       echo "Options:"
       echo "  - Fix failing checks"
       echo "  - Force merge (admin): /gh-merge-pr --admin"
       exit 1
     else
       echo "⚠️  Proceeding with admin merge..."
     fi
   elif [ "$pendingChecks" -gt 0 ]; then
     echo "⏳ $pendingChecks check(s) still running"
     echo ""
     echo "Wait for checks or use --admin to merge anyway"
     if [ "$adminMerge" = false ]; then
       exit 1
     fi
   else
     echo "✅ All checks passed"
   fi
   ```

5. **Check review status:**
   ```bash
   echo ""
   echo "👀 Checking reviews..."
   reviews=$(gh pr view "$prNumber" --json reviews --jq '.reviews | group_by(.author.login) | map({author: .[0].author.login, state: .[-1].state})')
   approvals=$(echo "$reviews" | jq '[.[] | select(.state == "APPROVED")] | length')
   changesRequested=$(echo "$reviews" | jq '[.[] | select(.state == "CHANGES_REQUESTED")] | length')

   if [ "$changesRequested" -gt 0 ]; then
     echo "⚠️  Changes requested by reviewer"
     if [ "$adminMerge" = false ]; then
       echo "Address feedback before merging"
       exit 1
     fi
   elif [ "$approvals" -gt 0 ]; then
     echo "✅ Approved by $approvals reviewer(s)"
   else
     echo "⚠️  No approvals yet"
   fi
   ```

6. **Perform merge:**
   ```bash
   echo ""
   echo "🔀 Merging PR #$prNumber with $mergeStrategy strategy..."

   mergeArgs="$prNumber"

   if [ "$mergeStrategy" = "squash" ]; then
     mergeArgs="$mergeArgs --squash"
   else
     mergeArgs="$mergeArgs --rebase"
   fi

   if [ "$deleteBranch" = true ]; then
     mergeArgs="$mergeArgs --delete-branch"
   fi

   if [ "$adminMerge" = true ]; then
     mergeArgs="$mergeArgs --admin"
   fi

   gh pr merge $mergeArgs

   echo ""
   echo "✅ PR merged successfully!"
   ```

7. **Clean up local branch:**
   ```bash
   if [ "$deleteBranch" = true ]; then
     echo ""
     echo "🧹 Cleaning up local branch..."

     # Switch to base branch
     git checkout "$baseBranch"

     # Pull latest
     git pull origin "$baseBranch"

     # Delete local branch if it exists
     if git show-ref --verify --quiet "refs/heads/$headBranch"; then
       git branch -D "$headBranch"
       echo "   Deleted local branch: $headBranch"
     fi

     # Prune remote tracking
     git fetch --prune
     echo "   Pruned remote tracking refs"
   fi
   ```

8. **Output result:**

**Success response:**
```json
{
  "merge": {
    "prNumber": 123,
    "title": "Add user authentication",
    "strategy": "rebase",
    "headBranch": "feature/user-auth",
    "baseBranch": "main",
    "branchDeleted": true
  },
  "success": true
}
```

## Error Handling

**If no PR found:**
```text
❌ No PR found for current branch

Create a PR first:
  /gh-create-pr "PR title"
```

**If PR has conflicts:**
```text
❌ PR has merge conflicts

Resolve conflicts:
  1. git checkout feature/user-auth
  2. git pull origin main
  3. Resolve conflicts
  4. git push
```

**If checks failed:**
```text
❌ 2 check(s) failed

  ✗ build        Build failed
  ✗ lint         Linting errors

Options:
  - Fix failing checks
  - Force merge (admin): /gh-merge-pr --admin
```

**If changes requested:**
```text
⚠️  Changes requested by reviewer

Address feedback before merging.

View comments:
  gh pr view --comments (or view in browser)
```

Return error JSON:
```json
{
  "error": true,
  "message": "PR has merge conflicts",
  "prNumber": 123,
  "conflicts": true
}
```

## Notes

- **Rebase default**: Uses rebase merge for clean linear history
- **Auto-cleanup**: Deletes branch locally and remotely after merge
- **CI check**: Verifies all checks pass before merge
- **Review check**: Warns if changes requested or no approvals

## Merge Strategies Comparison

| Strategy | History | Commits | Use When |
|----------|---------|---------|----------|
| Rebase | Linear | Individual | Clean commit history |
| Squash | Linear | Single | Messy commits, want clean |
| Merge | Non-linear | All + merge | Preserve branch history |

**Our default: Rebase** - Keeps individual commits, creates linear history.

## Use Cases

### Standard Merge
```bash
# Merge current branch's PR
/gh-merge-pr
```

### Merge by PR Number
```bash
# Merge specific PR
/gh-merge-pr 123
```

### Squash Messy History
```bash
# Squash many small commits into one
/gh-merge-pr --squash
```

### Keep Branch
```bash
# Merge but don't delete branch
/gh-merge-pr --no-delete
```

### Admin Override
```bash
# Merge despite failing checks (use carefully)
/gh-merge-pr --admin
```

## Integration with Work System

Complete PR workflow:
```bash
# 1. Create and work on feature
/gh-create-branch feature/TW-26134585-user-auth main --push

# 2. Commit changes
/gh-commit "feat(auth): implement login" --all
/gh-push-remote "feat(auth): complete feature"

# 3. Create PR
/gh-create-pr "feat: Add user authentication"

# 4. After review approval
/gh-merge-pr

# 5. Log time on task
/tw-create-task-timelog 26134585 "2025-12-07" 4 0 "Completed user authentication feature"
```

## Post-Merge State

After `/gh-merge-pr`:
- PR is merged and closed
- Remote branch is deleted
- You're switched to main/base branch
- Local feature branch is deleted
- Remote tracking refs are pruned

## Related Commands

- `/gh-create-pr` - Create PR before merge
- `/gh-delete-branch` - Manual branch cleanup
- `/gh-sync` - Sync branch before merge
- `/gh-status` - Check current branch status
