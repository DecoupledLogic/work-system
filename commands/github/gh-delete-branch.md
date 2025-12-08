---
description: Delete a git branch locally and/or remotely (helper)
allowedTools:
  - Bash
---

# GitHub CLI: Delete Branch

Deletes a git branch from local repository and optionally from remote.

## Usage

```bash
/gh-delete-branch feature/old-feature
/gh-delete-branch feature/old-feature --remote
/gh-delete-branch feature/old-feature --force
/gh-delete-branch feature/old-feature --remote --force
```

## Input Parameters

- **branchName** (required): Name of the branch to delete
- **--remote** (optional): Also delete from remote origin
- **--force** (optional): Force delete even if not fully merged

## Implementation

1. **Parse input and flags:**
   ```bash
   branchName=$1
   deleteRemote=false
   forceDelete=false

   for arg in "$@"; do
     case "$arg" in
       --remote) deleteRemote=true ;;
       --force) forceDelete=true ;;
     esac
   done

   # Validate required parameters
   if [ -z "$branchName" ]; then
     echo "❌ Missing required parameter: branchName"
     echo ""
     echo "Usage: /gh-delete-branch <branchName> [--remote] [--force]"
     echo ""
     echo "Examples:"
     echo "  /gh-delete-branch feature/old-feature"
     echo "  /gh-delete-branch feature/old-feature --remote"
     echo "  /gh-delete-branch feature/old-feature --force"
     exit 1
   fi
   ```

2. **Check current branch:**
   ```bash
   currentBranch=$(git branch --show-current)

   if [ "$currentBranch" == "$branchName" ]; then
     echo "❌ Cannot delete current branch"
     echo ""
     echo "You are currently on '$branchName'."
     echo "Switch to another branch first:"
     echo "  git checkout main"
     exit 1
   fi
   ```

3. **Check if branch exists:**
   ```bash
   # Check local
   localExists=false
   if git show-ref --verify --quiet "refs/heads/$branchName"; then
     localExists=true
   fi

   # Check remote
   remoteExists=false
   if git ls-remote --exit-code --heads origin "$branchName" &>/dev/null; then
     remoteExists=true
   fi

   if [ "$localExists" = false ] && [ "$remoteExists" = false ]; then
     echo "❌ Branch not found"
     echo ""
     echo "Branch '$branchName' does not exist locally or on remote."
     exit 1
   fi
   ```

4. **Check merge status (unless --force):**
   ```bash
   if [ "$forceDelete" = false ] && [ "$localExists" = true ]; then
     # Check if branch is merged into main/master
     defaultBranch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
     defaultBranch=${defaultBranch:-main}

     if ! git branch --merged "$defaultBranch" | grep -q "^\s*$branchName$"; then
       echo "⚠️  Branch not fully merged"
       echo ""
       echo "Branch '$branchName' has unmerged changes."
       echo ""
       echo "Options:"
       echo "  - Force delete: /gh-delete-branch $branchName --force"
       echo "  - Merge first: git checkout $defaultBranch && git merge $branchName"
       echo ""
       echo "Unmerged commits:"
       git log "$defaultBranch..$branchName" --oneline | head -5
       exit 1
     fi
   fi
   ```

5. **Delete local branch:**
   ```bash
   deletedLocal=false
   if [ "$localExists" = true ]; then
     if [ "$forceDelete" = true ]; then
       git branch -D "$branchName"
     else
       git branch -d "$branchName"
     fi
     deletedLocal=true
   fi
   ```

6. **Delete remote branch if requested:**
   ```bash
   deletedRemote=false
   if [ "$deleteRemote" = true ] && [ "$remoteExists" = true ]; then
     git push origin --delete "$branchName"
     deletedRemote=true
   fi
   ```

7. **Output result:**

**Success response:**
```json
{
  "branch": {
    "name": "feature/old-feature",
    "deletedLocal": true,
    "deletedRemote": true,
    "wasForced": false
  },
  "success": true
}
```

## Error Handling

**If on same branch:**
```text
❌ Cannot delete current branch

You are currently on 'feature/old-feature'.
Switch to another branch first:
  git checkout main
  git checkout develop
```

**If branch not found:**
```text
❌ Branch not found

Branch 'feature/nonexistent' does not exist locally or on remote.

Available local branches:
  main
  develop
  feature/user-auth
```

**If branch has unmerged changes:**
```text
⚠️  Branch not fully merged

Branch 'feature/wip' has unmerged changes.

Options:
  - Force delete: /gh-delete-branch feature/wip --force
  - Merge first: git checkout main && git merge feature/wip

Unmerged commits:
  a1b2c3d Add user authentication
  d4e5f6g Implement login form
  g7h8i9j Add password validation
```

**If remote delete fails:**
```text
❌ Local branch deleted, remote delete failed

Local branch 'feature/old' deleted successfully.
Could not delete remote branch.

Possible causes:
  - Remote branch doesn't exist
  - No push permissions
  - Network error

Delete remote manually with:
  git push origin --delete feature/old
```

Return error JSON:
```json
{
  "error": true,
  "message": "Cannot delete current branch",
  "currentBranch": "feature/old-feature",
  "branchName": "feature/old-feature"
}
```

## Notes

- **Safety first**: Won't delete unmerged branches without `--force`
- **Current branch**: Cannot delete branch you're currently on
- **Remote optional**: Use `--remote` to also delete from origin
- **Prune remotes**: After deleting, run `git fetch --prune` to clean up tracking refs

## Use Cases

### Clean Up After PR Merge
```bash
# After PR is merged, delete local and remote
/gh-delete-branch feature/completed-feature --remote
```

### Delete Abandoned Branch
```bash
# Force delete an experimental branch
/gh-delete-branch experiment/failed-approach --force --remote
```

### Local Cleanup Only
```bash
# Delete local branch, keep remote
/gh-delete-branch feature/old-branch
```

### Batch Cleanup
```bash
# Delete multiple old branches
/gh-delete-branch feature/old-1 --remote
/gh-delete-branch feature/old-2 --remote
/gh-delete-branch feature/old-3 --remote

# Prune remote tracking branches
git fetch --prune
```

## Integration with Work System

After completing and merging a task:
```bash
# 1. Switch to main and pull latest
/gh-checkout main --pull

# 2. Delete feature branch
/gh-delete-branch feature/TW-26134585-user-auth --remote

# 5. Update task status in Teamwork
/tw-update-task 26134585 --status completed
```

## Safety Features

1. **Merge check**: Warns before deleting unmerged branches
2. **Current branch protection**: Cannot delete active branch
3. **Explicit remote deletion**: Remote deletion requires `--remote` flag
4. **Force acknowledgment**: Unmerged deletion requires `--force`

## Related Commands

- `/gh-create-branch` - Create a new branch
- `/gh-commit` - Commit changes
- `git branch -a` - List all branches
- `git fetch --prune` - Clean up stale remote refs
