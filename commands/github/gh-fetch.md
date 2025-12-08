---
description: Fetch changes from remote without merging (helper)
allowedTools:
  - Bash
---

# GitHub CLI: Fetch Changes

Fetches latest changes from remote repository without modifying local branches.

## Usage

```bash
/gh-fetch                       # Fetch from origin
/gh-fetch --all                 # Fetch from all remotes
/gh-fetch upstream              # Fetch from specific remote
/gh-fetch --status              # Fetch and show branch status
```

## Input Parameters

- **remote** (optional): Remote name to fetch from (default: origin)
- **--all** (optional): Fetch from all configured remotes
- **--status** (optional): Show detailed status of all branches after fetch
- **--prune** (optional): Remove stale remote-tracking refs (default: true)

## Implementation

1. **Parse input and flags:**
   ```bash
   remote="origin"
   fetchAll=false
   showStatus=false
   prune=true

   for arg in "$@"; do
     case "$arg" in
       --all) fetchAll=true ;;
       --status) showStatus=true ;;
       --no-prune) prune=false ;;
       *)
         if git remote | grep -q "^$arg$"; then
           remote="$arg"
         fi
         ;;
     esac
   done
   ```

2. **List configured remotes:**
   ```bash
   remotes=$(git remote)
   if [ -z "$remotes" ]; then
     echo "❌ No remotes configured"
     echo ""
     echo "Add a remote with:"
     echo "  git remote add origin <url>"
     exit 1
   fi
   ```

3. **Fetch from remote(s):**
   ```bash
   if [ "$fetchAll" = true ]; then
     echo "🔄 Fetching from all remotes..."
     for r in $remotes; do
       echo "  Fetching $r..."
       if [ "$prune" = true ]; then
         git fetch "$r" --prune --tags
       else
         git fetch "$r" --tags
       fi
     done
   else
     echo "🔄 Fetching from $remote..."
     if [ "$prune" = true ]; then
       git fetch "$remote" --prune --tags
     else
       git fetch "$remote" --tags
     fi
   fi
   ```

4. **Get current branch status:**
   ```bash
   currentBranch=$(git branch --show-current)

   # Check if current branch has upstream
   upstream=$(git rev-parse --abbrev-ref "$currentBranch@{upstream}" 2>/dev/null)

   if [ -n "$upstream" ]; then
     behind=$(git rev-list --count HEAD.."$upstream")
     ahead=$(git rev-list --count "$upstream"..HEAD)
   else
     behind=0
     ahead=0
     upstream="(no upstream)"
   fi
   ```

5. **Show branch status if requested:**
   ```bash
   if [ "$showStatus" = true ]; then
     echo ""
     echo "📊 Branch Status:"
     echo ""

     # Show status for all local branches
     git for-each-ref --format='%(refname:short) %(upstream:short) %(upstream:track)' refs/heads | \
     while read branch upstream track; do
       if [ -n "$upstream" ]; then
         echo "  $branch → $upstream $track"
       else
         echo "  $branch (no upstream)"
       fi
     done
   fi
   ```

6. **Output result:**

**Success response:**
```json
{
  "fetch": {
    "remote": "origin",
    "pruned": true,
    "currentBranch": {
      "name": "feature/user-auth",
      "upstream": "origin/feature/user-auth",
      "behind": 3,
      "ahead": 1
    },
    "newBranches": ["feature/new-feature"],
    "deletedBranches": ["feature/old-feature"]
  },
  "success": true
}
```

## Error Handling

**If remote not found:**
```text
❌ Remote not found

Remote 'upstream' is not configured.

Configured remotes:
  origin - git@github.com:user/repo.git

Add remote with:
  git remote add upstream <url>
```

**If network error:**
```text
❌ Fetch failed

Could not connect to 'origin'.

Possible causes:
  - No internet connection
  - Authentication failed
  - Remote repository unavailable

Check remote URL:
  git remote get-url origin
```

**If authentication fails:**
```text
❌ Authentication failed

Could not authenticate with 'origin'.

For SSH:
  - Check SSH key: ssh -T git@github.com
  - Add key: ssh-add ~/.ssh/id_rsa

For HTTPS:
  - Update credentials: git credential reject
  - Re-authenticate on next fetch
```

Return error JSON:
```json
{
  "error": true,
  "message": "Remote 'upstream' not found",
  "configuredRemotes": ["origin"]
}
```

## Notes

- **Non-destructive**: Fetch never modifies local branches
- **Prune default**: Automatically removes stale remote refs
- **Tags included**: Fetches tags along with branches
- **Status check**: Use `--status` to see what needs pulling

## Use Cases

### Quick Status Check
```bash
# See what's changed on remote
/gh-fetch --status
```

### Before Code Review
```bash
# Fetch PR branch to review locally
/gh-fetch
git checkout origin/feature/pr-branch
```

### Multi-Remote Project
```bash
# Fetch from all remotes (fork workflow)
/gh-fetch --all --status
```

### CI/CD Sync
```bash
# Fetch to check for updates
/gh-fetch
git diff HEAD..origin/main --stat
```

## Fetch vs Pull

| Operation | Fetch | Pull |
|-----------|-------|------|
| Downloads changes | ✅ | ✅ |
| Updates local branch | ❌ | ✅ |
| Safe with local changes | ✅ | ⚠️ |
| Can cause conflicts | ❌ | ✅ |

**When to use fetch:**
- Check what's new before integrating
- Review changes before merging
- Working with multiple remotes
- CI/CD status checks

**When to use pull:**
- Ready to integrate remote changes
- Starting fresh work on a branch
- After reviewing fetched changes

## Integration with Work System

Before starting work:
```bash
# 1. Fetch to see current state
/gh-fetch --status

# 2. If behind, pull
/gh-pull

# 3. Create feature branch
/gh-create-branch feature/TW-26134585 main --push
```

During PR review:
```bash
# 1. Fetch the PR
/gh-fetch

# 2. Check out PR branch (detached)
git checkout origin/feature/pr-branch

# 3. Review code...

# 4. Return to your branch
git checkout -
```
