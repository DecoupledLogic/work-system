---
description: View commit history and logs (helper)
allowedTools:
  - Bash
---

# Git: Log

View commit history with various formats and filters.

## Usage

```bash
/git-log                         # Recent commits (default 10)
/git-log --oneline               # Compact one-line format
/git-log --count 5               # Show last 5 commits
/git-log --range main..HEAD      # Commits between branches
/git-log --last                  # Just the last commit
```

## Input Parameters

- **--oneline** (optional): Compact one-line format per commit
- **--count N** (optional): Number of commits to show (default: 10)
- **--range RANGE** (optional): Show commits in range (e.g., main..HEAD)
- **--last** (optional): Show only the last commit with details

## Implementation

1. **Parse input flags:**
   ```bash
   onelineFormat=false
   count=10
   range=""
   lastOnly=false

   while [ $# -gt 0 ]; do
     case "$1" in
       --oneline|-o)
         onelineFormat=true
         shift
         ;;
       --count|-c)
         count="$2"
         shift 2
         ;;
       --range|-r)
         range="$2"
         shift 2
         ;;
       --last|-l)
         lastOnly=true
         shift
         ;;
       *)
         shift
         ;;
     esac
   done
   ```

2. **Show last commit only:**
   ```bash
   if [ "$lastOnly" = true ]; then
     hash=$(git log -1 --format="%h")
     author=$(git log -1 --format="%an")
     date=$(git log -1 --format="%ar")
     message=$(git log -1 --format="%s")

     echo "📝 Last Commit"
     echo "   Hash:    $hash"
     echo "   Author:  $author"
     echo "   When:    $date"
     echo "   Message: $message"
     exit 0
   fi
   ```

3. **Show commit range:**
   ```bash
   if [ -n "$range" ]; then
     if [ "$onelineFormat" = true ]; then
       git log --oneline "$range"
     else
       git log --format="%h %s (%an, %ar)" "$range"
     fi
     exit 0
   fi
   ```

4. **Show recent commits:**
   ```bash
   if [ "$onelineFormat" = true ]; then
     git log --oneline -n "$count"
   else
     git log --format="%h %s (%an, %ar)" -n "$count"
   fi
   ```

## Output Format

### Default Format
```
5ebd42d feat(commands): integrate code-review into deliver workflow (Chris Bryant, 2 hours ago)
9c6c366 feat(commands): add code-review command for .NET microservices (Chris Bryant, 3 hours ago)
ec6feaf feat(docs): add testing and release plan guides (Chris Bryant, 5 hours ago)
```

### Oneline Format
```
5ebd42d feat(commands): integrate code-review into deliver workflow
9c6c366 feat(commands): add code-review command for .NET microservices
ec6feaf feat(docs): add testing and release plan guides
```

### Last Commit
```
📝 Last Commit
   Hash:    5ebd42d
   Author:  Chris Bryant
   When:    2 hours ago
   Message: feat(commands): integrate code-review into deliver workflow
```

### Range
```
5ebd42d feat(commands): integrate code-review into deliver workflow (Chris Bryant, 2 hours ago)
9c6c366 feat(commands): add code-review command for .NET microservices (Chris Bryant, 3 hours ago)
```

## Usage Examples

### Recent Commits
```bash
$ /git-log --count 5
5ebd42d feat: add feature (Chris Bryant, 2 hours ago)
9c6c366 fix: fix bug (Chris Bryant, 3 hours ago)
```

### Commits Between Branches
```bash
$ /git-log --range main..feature/auth --oneline
abc123 feat: add login endpoint
def456 test: add auth tests
```

### Last Commit Details
```bash
$ /git-log --last
📝 Last Commit
   Hash:    5ebd42d
   Author:  Chris Bryant
   When:    2 hours ago
   Message: feat(commands): integrate code-review
```

### Use in Scripts
```bash
# Get last commit hash
lastHash=$(git log -1 --format="%h")

# Get last commit message
lastMessage=$(git log -1 --format="%s")

# Check if commits exist in range
if /git-log --range main..HEAD --oneline | grep -q .; then
  echo "Commits to push"
fi
```

## Common Patterns

### Check for Unpushed Commits
```bash
baseBranch="main"
currentBranch=$(/git-branch)
commits=$(/git-log --range "$baseBranch..$currentBranch" --oneline)

if [ -n "$commits" ]; then
  echo "📋 Commits to be included in PR:"
  echo "$commits"
fi
```

### Get Commit Info for Messages
```bash
lastCommit=$(/git-log --last)
echo "Building on: $lastCommit"
```

### Verify Commit Authorship
```bash
lastAuthor=$(git log -1 --format="%an <%ae>")
currentUser=$(git config user.name)

if [ "$lastAuthor" != "$currentUser" ]; then
  echo "⚠️  Last commit by different author"
fi
```

## Related Commands

- **/git-status** - Current status including last commit
- **/git-diff** - Changes in working directory
- **/git-branch** - Current branch information
- **/git-commit** - Create new commit

## Notes

- All times shown in relative format (e.g., "2 hours ago")
- Hash shown in short format (7 characters)
- Default count is 10 commits
- Range syntax follows git log conventions (e.g., main..HEAD, HEAD~5..HEAD)
