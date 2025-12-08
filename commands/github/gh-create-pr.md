---
description: Create a GitHub pull request for current branch (helper)
allowedTools:
  - Bash
  - SlashCommand
---

# GitHub CLI: Create Pull Request

Creates a GitHub pull request for the current branch with standardized format.

## Usage

```bash
/gh-create-pr "Add user authentication"
/gh-create-pr "Fix login timeout" --draft
/gh-create-pr "Implement dashboard" --base develop
/gh-create-pr "Update API" --reviewer @username
```

## Input Parameters

- **title** (required): PR title (use quotes for multi-word)
- **--draft** (optional): Create as draft PR
- **--base** (optional): Target branch (default: main)
- **--reviewer** (optional): Request reviewer(s) - comma-separated
- **--label** (optional): Add label(s) - comma-separated

## Implementation

1. **Parse input and flags:**
   ```bash
   title=""
   draft=false
   baseBranch="main"
   reviewers=""
   labels=""

   for arg in "$@"; do
     case "$arg" in
       --draft) draft=true ;;
       --base=*) baseBranch="${arg#--base=}" ;;
       --reviewer=*) reviewers="${arg#--reviewer=}" ;;
       --label=*) labels="${arg#--label=}" ;;
       *)
         if [ -z "$title" ]; then
           title="$arg"
         fi
         ;;
     esac
   done

   # Validate required parameters
   if [ -z "$title" ]; then
     echo "❌ Missing required parameter: title"
     echo ""
     echo "Usage: /gh-create-pr <title> [--draft] [--base=branch] [--reviewer=@user]"
     echo ""
     echo "Examples:"
     echo "  /gh-create-pr \"Add user authentication\""
     echo "  /gh-create-pr \"Fix login bug\" --draft"
     echo "  /gh-create-pr \"New feature\" --base=develop --reviewer=@teammate"
     exit 1
   fi
   ```

2. **Show current status:**
   ```bash
   echo "📊 Pre-PR Check:"
   /gh-status --remote
   echo ""
   ```

3. **Verify branch state:**
   ```bash
   currentBranch=$(git branch --show-current)

   # Check not on main/base
   if [ "$currentBranch" = "$baseBranch" ]; then
     echo "❌ Cannot create PR from $baseBranch"
     echo ""
     echo "Create a feature branch first:"
     echo "  /gh-create-branch feature/my-feature $baseBranch --push"
     exit 1
   fi

   # Check for unpushed commits
   git fetch origin --quiet 2>/dev/null
   upstream=$(git rev-parse --abbrev-ref "$currentBranch@{upstream}" 2>/dev/null)

   if [ -z "$upstream" ]; then
     echo "⚠️  Branch not pushed to remote"
     echo ""
     echo "Pushing branch..."
     git push -u origin "$currentBranch"
   else
     ahead=$(git rev-list --count "$upstream"..HEAD 2>/dev/null || echo 0)
     if [ "$ahead" -gt 0 ]; then
       echo "⚠️  $ahead unpushed commit(s)"
       echo ""
       echo "Pushing commits..."
       git push origin "$currentBranch"
     fi
   fi
   ```

4. **Check for uncommitted changes:**
   ```bash
   if [ -n "$(git status --porcelain)" ]; then
     echo "⚠️  Uncommitted changes detected"
     echo ""
     echo "Options:"
     echo "  - Commit first: /gh-commit \"message\" --all"
     echo "  - Continue anyway (changes won't be in PR)"
     echo ""
   fi
   ```

5. **Get commits for PR body:**
   ```bash
   # Get commits unique to this branch
   commits=$(git log "$baseBranch..$currentBranch" --oneline 2>/dev/null)
   commitCount=$(echo "$commits" | grep -c . || echo 0)

   echo "📝 PR includes $commitCount commit(s)"
   ```

6. **Build PR body:**
   ```bash
   # Extract task ID if present in branch name (TW-XXXXX pattern)
   taskId=$(echo "$currentBranch" | grep -oE 'TW-[0-9]+' || echo "")

   body="## Summary
   $(echo "$commits" | sed 's/^/- /')

   ## Test Plan
   - [ ] Unit tests pass
   - [ ] Manual testing completed
   - [ ] Code reviewed"

   if [ -n "$taskId" ]; then
     body="$body

   ## Related
   - Teamwork Task: $taskId"
   fi

   body="$body

   🤖 Submitted by George with love ♥"
   ```

7. **Create PR using gh CLI:**
   ```bash
   echo ""
   echo "🚀 Creating pull request..."

   prArgs="--title \"$title\" --base $baseBranch"

   if [ "$draft" = true ]; then
     prArgs="$prArgs --draft"
   fi

   if [ -n "$reviewers" ]; then
     prArgs="$prArgs --reviewer $reviewers"
   fi

   if [ -n "$labels" ]; then
     prArgs="$prArgs --label $labels"
   fi

   # Create PR with body via heredoc
   prUrl=$(gh pr create $prArgs --body "$body")

   echo ""
   echo "✅ Pull request created!"
   echo "   $prUrl"
   ```

8. **Output result:**

**Success response:**
```json
{
  "pr": {
    "url": "https://github.com/org/repo/pull/123",
    "number": 123,
    "title": "Add user authentication",
    "branch": "feature/user-auth",
    "base": "main",
    "draft": false,
    "commits": 5
  },
  "success": true
}
```

## Error Handling

**If on main branch:**
```text
❌ Cannot create PR from main

Create a feature branch first:
  /gh-create-branch feature/my-feature main --push
```

**If gh CLI not installed:**
```text
❌ GitHub CLI not installed

Install gh CLI:
  macOS: brew install gh
  Linux: See https://cli.github.com/

Then authenticate:
  gh auth login
```

**If not authenticated:**
```text
❌ Not authenticated with GitHub

Run:
  gh auth login

And follow the prompts.
```

**If PR already exists:**
```text
⚠️  Pull request already exists

Existing PR: https://github.com/org/repo/pull/42

Options:
  - View PR: gh pr view (or visit URL above)
  - Update PR: /gh-push-remote "message" to push more commits
  - Close and recreate: gh pr close 42
```

Return error JSON:
```json
{
  "error": true,
  "message": "Cannot create PR from main branch",
  "currentBranch": "main"
}
```

## Notes

- **Auto-push**: Automatically pushes unpushed commits before creating PR
- **Task linking**: Extracts TW-XXXXX from branch name for PR body
- **Draft mode**: Use `--draft` for work-in-progress PRs
- **Reviewers**: Can specify multiple with `--reviewer=@user1,@user2`

## PR Body Template

The generated PR body follows this format:

```markdown
## Summary
- a1b2c3d First commit message
- d4e5f6g Second commit message

## Test Plan
- [ ] Unit tests pass
- [ ] Manual testing completed
- [ ] Code reviewed

## Related
- Teamwork Task: TW-26134585

🤖 Submitted by George with love ♥
```

## Use Cases

### Standard Feature PR
```bash
# After completing feature work
/gh-create-pr "feat: Add user authentication"
```

### Draft for Early Feedback
```bash
# Get feedback before completing
/gh-create-pr "WIP: New dashboard design" --draft
```

### PR with Reviewers
```bash
# Request specific reviewers
/gh-create-pr "Fix critical bug" --reviewer=@senior-dev,@tech-lead
```

### PR to Non-Main Branch
```bash
# Target develop instead of main
/gh-create-pr "Feature for next release" --base=develop
```

## Integration with Work System

Complete feature workflow:
```bash
# 1. Create branch from task
/gh-create-branch feature/TW-26134585-user-auth main --push

# 2. Work on feature...
/gh-commit "feat(auth): implement login" --all
/gh-commit "feat(auth): add password reset" --all

# 3. Push and create PR
/gh-push-remote "feat(auth): complete authentication"
/gh-create-pr "feat: Add user authentication"

# 4. After approval, merge
/gh-merge-pr
```

## Related Commands

- `/gh-push-remote` - Push commits before PR
- `/gh-merge-pr` - Merge PR after approval
- `/gh-status` - Check current branch status
