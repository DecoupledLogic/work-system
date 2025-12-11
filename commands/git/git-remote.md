---
description: Manage and query git remotes (helper)
allowedTools:
  - Bash
---

# Git: Remote

Manage and query git remote repositories.

## Usage

```bash
/git-remote                      # List all remotes
/git-remote --url origin         # Get URL for specific remote
/git-remote --check origin       # Check if remote exists
/git-remote --upstream           # Get upstream remote and branch
```

## Input Parameters

- **--url NAME** (optional): Get URL for specific remote
- **--check NAME** (optional): Check if remote exists (returns 0/1)
- **--upstream** (optional): Get upstream tracking branch

## Implementation

1. **Parse input flags:**
   ```bash
   getUrl=""
   checkRemote=""
   getUpstream=false

   while [ $# -gt 0 ]; do
     case "$1" in
       --url|-u)
         getUrl="$2"
         shift 2
         ;;
       --check|-c)
         checkRemote="$2"
         shift 2
         ;;
       --upstream)
         getUpstream=true
         shift
         ;;
       *)
         shift
         ;;
     esac
   done
   ```

2. **Get upstream tracking branch:**
   ```bash
   if [ "$getUpstream" = true ]; then
     currentBranch=$(git branch --show-current)

     if [ -z "$currentBranch" ]; then
       echo "❌ Not on a branch (detached HEAD)"
       exit 1
     fi

     upstream=$(git rev-parse --abbrev-ref "$currentBranch@{upstream}" 2>/dev/null)

     if [ -z "$upstream" ]; then
       echo "❌ No upstream branch set for $currentBranch"
       exit 1
     fi

     # Parse remote and branch
     remote=$(echo "$upstream" | cut -d'/' -f1)
     branch=$(echo "$upstream" | cut -d'/' -f2-)

     echo "Remote: $remote"
     echo "Branch: $branch"
     exit 0
   fi
   ```

3. **Check if remote exists:**
   ```bash
   if [ -n "$checkRemote" ]; then
     if git remote | grep -q "^$checkRemote$"; then
       echo "✅ Remote '$checkRemote' exists"
       exit 0
     else
       echo "❌ Remote '$checkRemote' not found"
       exit 1
     fi
   fi
   ```

4. **Get remote URL:**
   ```bash
   if [ -n "$getUrl" ]; then
     url=$(git remote get-url "$getUrl" 2>/dev/null)

     if [ -z "$url" ]; then
       echo "❌ Remote '$getUrl' not found"
       exit 1
     fi

     echo "$url"
     exit 0
   fi
   ```

5. **List all remotes:**
   ```bash
   remotes=$(git remote)

   if [ -z "$remotes" ]; then
     echo "📋 No remotes configured"
     echo ""
     echo "Add a remote with:"
     echo "  git remote add origin <url>"
     exit 0
   fi

   echo "📋 Configured remotes:"
   for remote in $remotes; do
     url=$(git remote get-url "$remote" 2>/dev/null)
     echo "  $remote → $url"
   done
   ```

## Output Format

### List Remotes
```
📋 Configured remotes:
  origin → https://github.com/user/repo.git
  upstream → https://github.com/upstream/repo.git
```

### Get URL
```
https://github.com/user/repo.git
```

### Check Remote (exists)
```
✅ Remote 'origin' exists
```

### Check Remote (not found)
```
❌ Remote 'origin' not found
```

### Get Upstream
```
Remote: origin
Branch: main
```

## Usage Examples

### List All Remotes
```bash
$ /git-remote
📋 Configured remotes:
  origin → https://github.com/user/repo.git
```

### Get Origin URL
```bash
$ /git-remote --url origin
https://github.com/user/repo.git
```

### Check if Remote Exists
```bash
$ /git-remote --check origin && echo "Origin configured"
✅ Remote 'origin' exists
Origin configured
```

### Get Upstream Branch
```bash
$ /git-remote --upstream
Remote: origin
Branch: main
```

### Use in Scripts
```bash
# Check if origin is configured
if /git-remote --check origin >/dev/null 2>&1; then
  originUrl=$(/git-remote --url origin)
  echo "Origin: $originUrl"
else
  echo "⚠️  No origin remote configured"
fi

# Get upstream info
if upstreamInfo=$(/git-remote --upstream 2>/dev/null); then
  echo "Tracking: $upstreamInfo"
else
  echo "⚠️  No upstream branch"
fi
```

## Common Patterns

### Verify Remote Before Push
```bash
if ! /git-remote --check origin >/dev/null 2>&1; then
  echo "❌ Origin remote not configured"
  echo "Add with: git remote add origin <url>"
  exit 1
fi
```

### Extract Repository Name from URL
```bash
originUrl=$(/git-remote --url origin)
repoName=$(echo "$originUrl" | sed -E 's|.*[:/]([^/]+)/([^/.]+)(\.git)?$|\2|')
echo "Repository: $repoName"
```

### Check Upstream Tracking
```bash
if /git-remote --upstream >/dev/null 2>&1; then
  echo "✅ Branch is tracking upstream"
else
  echo "⚠️  No upstream tracking"
  currentBranch=$(/git-branch)
  echo "Set with: git push -u origin $currentBranch"
fi
```

### List All Remote Branches
```bash
# Ensure remotes are up to date
git fetch --all --quiet

# Get all remote branches for origin
git branch -r | grep "^  origin/" | sed 's|  origin/||'
```

## Related Commands

- **/git-fetch** - Update remote tracking branches
- **/git-push** - Push to remote
- **/git-pull** - Pull from remote
- **/git-status** - Shows sync status with remote

## Notes

- Most commands assume 'origin' as the default remote
- Upstream tracking is set with `git push -u`
- Remote URLs can be HTTPS or SSH
- Use `git remote add <name> <url>` to add new remotes
- Use `git remote remove <name>` to remove remotes
