---
description: Amend last commit safely with checks (helper)
allowedTools:
  - Bash
---

# Git: Amend Commit

Safely amends the last commit to add staged changes or update the message. Includes safety checks to prevent amending pushed or others' commits.

## Usage

```bash
/git-amend                       # Add staged changes to last commit
/git-amend "new message"         # Change commit message
/git-amend --all                 # Stage all and amend
/git-amend --push                # Amend and force push
```

## Input Parameters

- **message** (optional): New commit message (keeps original if not provided)
- **--all** (optional): Stage all changes before amending
- **--push** (optional): Force push after amending
- **--force** (optional): Skip safety checks (use carefully)

## Implementation

1. **Parse input and flags:**
   ```bash
   newMessage=""
   stageAll=false
   pushAfter=false
   forceAmend=false

   for arg in "$@"; do
     case "$arg" in
       --all) stageAll=true ;;
       --push) pushAfter=true ;;
       --force) forceAmend=true ;;
       *)
         if [ -z "$newMessage" ] && ! [[ "$arg" == --* ]]; then
           newMessage="$arg"
         fi
         ;;
     esac
   done
   ```

2. **Safety check - verify last commit:**
   ```bash
   # Get last commit info
   lastCommit=$(git log -1 --format="%H")
   lastCommitShort=$(git log -1 --format="%h")
   lastCommitMsg=$(git log -1 --format="%s")
   lastCommitAuthor=$(git log -1 --format="%an <%ae>")

   echo "📝 Last commit:"
   echo "   $lastCommitShort $lastCommitMsg"
   echo "   Author: $lastCommitAuthor"
   echo ""
   ```

3. **Safety check - verify authorship:**
   ```bash
   # Get current user
   currentUser=$(git config user.name)
   currentEmail=$(git config user.email)

   # Check if we authored this commit
   commitAuthorName=$(git log -1 --format="%an")
   commitAuthorEmail=$(git log -1 --format="%ae")

   if [ "$forceAmend" = false ]; then
     if [ "$commitAuthorName" != "$currentUser" ] || [ "$commitAuthorEmail" != "$currentEmail" ]; then
       echo "❌ Cannot amend someone else's commit"
       echo ""
       echo "   Commit author: $commitAuthorName <$commitAuthorEmail>"
       echo "   You are: $currentUser <$currentEmail>"
       echo ""
       echo "Options:"
       echo "  - Create new commit instead: /git-commit \"message\""
       echo "  - Force amend (not recommended): /git-amend --force"
       exit 1
     fi
   fi
   ```

4. **Safety check - verify not pushed:**
   ```bash
   currentBranch=$(git branch --show-current)
   upstream=$(git rev-parse --abbrev-ref "$currentBranch@{upstream}" 2>/dev/null)

   if [ -n "$upstream" ] && [ "$forceAmend" = false ]; then
     # Check if commit exists on remote
     git fetch origin --quiet 2>/dev/null

     if git branch -r --contains "$lastCommit" 2>/dev/null | grep -q "origin/$currentBranch"; then
       echo "⚠️  Last commit already pushed to remote"
       echo ""
       echo "Amending will require force push."
       echo ""
       echo "Options:"
       echo "  - Amend and force push: /git-amend --push"
       echo "  - Create new commit: /git-commit \"fix: correction\""
       echo "  - Force amend only: /git-amend --force"

       if [ "$pushAfter" = false ]; then
         exit 1
       else
         echo ""
         echo "Proceeding with amend (--push specified)..."
       fi
     fi
   fi
   ```

5. **Stage changes if requested:**
   ```bash
   if [ "$stageAll" = true ]; then
     echo "📦 Staging all changes..."
     git add -A
   fi
   ```

6. **Check what will be amended:**
   ```bash
   staged=$(git diff --cached --name-only)
   stagedCount=$(echo "$staged" | grep -c . || echo 0)

   if [ "$stagedCount" -gt 0 ]; then
     echo "📝 Changes to add to commit:"
     git diff --cached --name-status | while read status file; do
       case "$status" in
         A) echo "   ➕ $file (new)" ;;
         M) echo "   ✏️  $file (modified)" ;;
         D) echo "   ➖ $file (deleted)" ;;
         *) echo "   $status $file" ;;
       esac
     done
     echo ""
   elif [ -z "$newMessage" ]; then
     echo "⚠️  No staged changes and no new message"
     echo ""
     echo "Options:"
     echo "  - Stage changes: git add <file>"
     echo "  - Stage all: /git-amend --all"
     echo "  - Change message: /git-amend \"new message\""
     exit 1
   fi
   ```

7. **Perform amend:**
   ```bash
   echo "🔄 Amending commit..."

   if [ -n "$newMessage" ]; then
     git commit --amend -m "$newMessage"
     echo "   Message updated: $newMessage"
   else
     git commit --amend --no-edit
     echo "   Changes added to: $lastCommitMsg"
   fi

   newCommitHash=$(git rev-parse --short HEAD)
   echo ""
   echo "✅ Amended: $lastCommitShort → $newCommitHash"
   ```

8. **Force push if requested:**
   ```bash
   if [ "$pushAfter" = true ]; then
     echo ""
     echo "🚀 Force pushing..."
     git push --force-with-lease origin "$currentBranch"
     echo "   Remote updated"
   fi
   ```

9. **Output result:**

**Success response:**
```json
{
  "amend": {
    "originalCommit": "a1b2c3d",
    "newCommit": "e4f5g6h",
    "message": "feat: add user authentication",
    "filesAdded": 2,
    "pushed": true
  },
  "success": true
}
```

## Error Handling

**If amending someone else's commit:**
```text
❌ Cannot amend someone else's commit

   Commit author: Jane Doe <jane@example.com>
   You are: John Smith <john@example.com>

Options:
  - Create new commit instead: /git-commit "message"
  - Force amend (not recommended): /git-amend --force
```

**If commit already pushed:**
```text
⚠️  Last commit already pushed to remote

Amending will require force push.

Options:
  - Amend and force push: /git-amend --push
  - Create new commit: /git-commit "fix: correction"
  - Force amend only: /git-amend --force
```

**If nothing to amend:**
```text
⚠️  No staged changes and no new message

Options:
  - Stage changes: git add <file>
  - Stage all: /git-amend --all
  - Change message: /git-amend "new message"
```

Return error JSON:
```json
{
  "error": true,
  "message": "Cannot amend someone else's commit",
  "commitAuthor": "Jane Doe <jane@example.com>",
  "currentUser": "John Smith <john@example.com>"
}
```

## Notes

- **Safe by default**: Checks authorship and push status
- **Force push aware**: Uses `--force-with-lease` for safety
- **Preserves message**: Keeps original message unless new one provided
- **Staged changes**: Only amends with staged changes

## Use Cases

### Add Forgotten File
```bash
# Forgot to include a file
git add src/forgotten-file.ts
/git-amend
```

### Fix Typo in Last Commit
```bash
# Fix typo in commit message
/git-amend "feat: correct spelling in feature name"
```

### Add All Changes to Last Commit
```bash
# Add all uncommitted changes
/git-amend --all
```

### Update PR with Amended Commit
```bash
# Amend and update PR
/git-amend --all --push
```

### Fix Last Commit Message
```bash
# Just change the message, no file changes
/git-amend "fix: better description of the fix"
```

## Integration with Work System

Quick fixes during development:
```bash
# 1. Make initial commit
/git-commit "feat: add login form" --all

# 2. Realize you forgot something
git add src/login/styles.css
/git-amend

# 3. Or fix the message
/git-amend "feat(auth): add login form with styling"

# 4. Push to PR
/git-amend --push
```

## Safety Features

1. **Authorship check**: Won't amend others' commits
2. **Push check**: Warns if commit is already on remote
3. **Force-with-lease**: Prevents overwriting others' changes
4. **Explicit flags**: Requires `--force` or `--push` for risky operations

## When NOT to Amend

- Commit is already merged
- Others have based work on the commit
- On a shared branch (main, develop)
- Commit is not yours

In these cases, create a new commit instead:
```bash
/git-commit "fix: correction to previous change"
```

## Related Commands

- `/git-commit` - Create new commit
- `/git-push` - Push changes
- `/git-sync` - Sync branch after amend
