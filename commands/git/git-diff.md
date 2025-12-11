---
description: Show changes in working directory or between commits (helper)
allowedTools:
  - Bash
---

# Git: Diff

Show changes in working directory, staging area, or between commits.

## Usage

```bash
/git-diff                        # Unstaged changes
/git-diff --staged               # Staged changes
/git-diff --stat                 # Summary statistics
/git-diff --name-only            # Just file names
/git-diff --range main..HEAD     # Changes between branches
```

## Input Parameters

- **--staged** (optional): Show staged changes instead of unstaged
- **--stat** (optional): Show summary statistics instead of full diff
- **--name-only** (optional): Show only file names
- **--name-status** (optional): Show file names with status (A/M/D)
- **--range RANGE** (optional): Compare between branches/commits
- **--cached** (optional): Alias for --staged

## Implementation

1. **Parse input flags:**
   ```bash
   showStaged=false
   showStat=false
   nameOnly=false
   nameStatus=false
   range=""

   for arg in "$@"; do
     case "$arg" in
       --staged|--cached) showStaged=true ;;
       --stat|-s) showStat=true ;;
       --name-only|-n) nameOnly=true ;;
       --name-status) nameStatus=true ;;
       --range|-r)
         shift
         range="$1"
         ;;
     esac
     shift
   done
   ```

2. **Handle range comparison:**
   ```bash
   if [ -n "$range" ]; then
     if [ "$showStat" = true ]; then
       git diff "$range" --stat
     elif [ "$nameOnly" = true ]; then
       git diff "$range" --name-only
     elif [ "$nameStatus" = true ]; then
       git diff "$range" --name-status
     else
       git diff "$range"
     fi
     exit 0
   fi
   ```

3. **Show staged changes:**
   ```bash
   if [ "$showStaged" = true ]; then
     if [ "$showStat" = true ]; then
       git diff --cached --stat
     elif [ "$nameOnly" = true ]; then
       git diff --cached --name-only
     elif [ "$nameStatus" = true ]; then
       git diff --cached --name-status
     else
       git diff --cached
     fi
     exit 0
   fi
   ```

4. **Show unstaged changes:**
   ```bash
   if [ "$showStat" = true ]; then
     git diff --stat
   elif [ "$nameOnly" = true ]; then
     git diff --name-only
   elif [ "$nameStatus" = true ]; then
     git diff --name-status
   else
     git diff
   fi
   ```

## Output Format

### Full Diff (Default)
```diff
diff --git a/src/auth/login.ts b/src/auth/login.ts
index abc123..def456 100644
--- a/src/auth/login.ts
+++ b/src/auth/login.ts
@@ -10,7 +10,7 @@ export function login(username: string) {
-  return false;
+  return authenticate(username);
 }
```

### Statistics (--stat)
```
 src/auth/login.ts      | 12 +++++++-----
 src/auth/logout.ts     |  5 +++--
 src/utils/helpers.ts   |  8 +++++---
 3 files changed, 15 insertions(+), 10 deletions(-)
```

### Name Only (--name-only)
```
src/auth/login.ts
src/auth/logout.ts
src/utils/helpers.ts
```

### Name with Status (--name-status)
```
M       src/auth/login.ts
M       src/auth/logout.ts
A       src/utils/helpers.ts
D       src/old/deprecated.ts
```

## Usage Examples

### Check Unstaged Changes
```bash
$ /git-diff --name-only
src/auth/login.ts
src/auth/logout.ts
```

### Check Staged Changes
```bash
$ /git-diff --staged --stat
 src/auth/login.ts  | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)
```

### Compare Branches
```bash
$ /git-diff --range main..feature/auth --stat
 src/auth/login.ts     | 25 +++++++++++++++++++++++++
 src/auth/register.ts  | 18 ++++++++++++++++++
 2 files changed, 43 insertions(+)
```

### Use in Scripts
```bash
# Check if there are unstaged changes
if /git-diff --name-only | grep -q .; then
  echo "⚠️  You have unstaged changes"
fi

# Count staged files
stagedCount=$(/git-diff --staged --name-only | wc -l)
echo "Staged files: $stagedCount"

# Get list of modified files
modifiedFiles=$(/git-diff --name-only)
```

## Common Patterns

### Check for Changes Before Operations
```bash
# Check if working directory is clean
if /git-diff --name-only | grep -q . || /git-diff --staged --name-only | grep -q .; then
  echo "⚠️  Working directory has changes"
  exit 1
fi
```

### Get File Status Counts
```bash
staged=$(/git-diff --staged --name-only | wc -l | tr -d ' ')
modified=$(/git-diff --name-only | wc -l | tr -d ' ')

echo "Staged: $staged, Modified: $modified"
```

### Check for Conflicts
```bash
conflicts=$(/git-diff --name-only --diff-filter=U | wc -l)

if [ "$conflicts" -gt 0 ]; then
  echo "⚠️  $conflicts conflict(s) to resolve"
  /git-diff --name-only --diff-filter=U
fi
```

### Show Changes in PR
```bash
baseBranch="main"
currentBranch=$(/git-branch)

echo "📋 Changes in this branch:"
/git-diff --range "$baseBranch..HEAD" --stat
```

## Status Codes

| Code | Meaning |
|------|---------|
| `A` | Added (new file) |
| `M` | Modified |
| `D` | Deleted |
| `R` | Renamed |
| `C` | Copied |
| `U` | Unmerged (conflict) |

## Related Commands

- **/git-status** - Overall status including diff summary
- **/git-log** - Commit history
- **/git-commit** - Commit changes
- **/git-checkout** - Discard changes

## Notes

- Default shows unstaged changes (working directory vs index)
- `--staged` shows staged changes (index vs HEAD)
- `--stat` is useful for commit messages and PR descriptions
- `--name-only` and `--name-status` are ideal for scripting
- Use `--range` to compare branches before merging
