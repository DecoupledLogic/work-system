---
description: Add a general comment to a GitHub pull request (helper)
allowedTools:
  - Bash
---

# GitHub CLI: Comment on PR

Adds a general comment to a GitHub pull request. This is for general feedback, questions, or status updates not tied to specific code lines.

## Usage

```bash
/gh-comment-pr 123 "Looks great! Approved."
/gh-comment-pr "LGTM!"                        # Current branch's PR
/gh-comment-pr "Can you add tests for the edge cases?"
```

## Input Parameters

- **pr-number** (optional): PR number. If omitted, uses current branch's PR
- **comment** (required): Comment text (use quotes for multi-word comments)

## Implementation

1. **Parse input:**

   ```bash
   # Determine if first arg is PR number or comment
   if [[ "$1" =~ ^[0-9]+$ ]]; then
     # First arg is PR number
     prNumber=$1
     comment="$2"
   else
     # First arg is comment, get PR from current branch
     comment="$1"

     currentBranch=$(git branch --show-current)
     prNumber=$(gh pr view --json number --jq '.number' 2>/dev/null)

     if [ -z "$prNumber" ]; then
       echo "❌ No PR found for current branch '$currentBranch'"
       echo ""
       echo "Options:"
       echo "  - Specify PR number: /gh-comment-pr <number> \"comment\""
       echo "  - Create PR first: /gh-create-pr \"title\""
       exit 1
     fi
   fi

   # Validate comment is provided
   if [ -z "$comment" ]; then
     echo "❌ Missing required parameter: comment"
     echo ""
     echo "Usage:"
     echo "  /gh-comment-pr <pr-number> \"comment text\""
     echo "  /gh-comment-pr \"comment text\"              # For current branch's PR"
     echo ""
     echo "Examples:"
     echo "  /gh-comment-pr 123 \"LGTM!\""
     echo "  /gh-comment-pr \"Can you add tests?\""
     exit 1
   fi
   ```

2. **Get PR details:**

   ```bash
   echo "📝 Adding comment to PR #$prNumber..."
   echo ""

   # Get PR title for confirmation
   prData=$(gh pr view "$prNumber" --json title,url 2>&1)

   if [ $? -ne 0 ]; then
     echo "❌ Failed to find PR #$prNumber"
     echo ""
     echo "$prData"
     exit 1
   fi

   prTitle=$(echo "$prData" | jq -r '.title')
   prUrl=$(echo "$prData" | jq -r '.url')

   echo "PR: $prTitle"
   echo "URL: $prUrl"
   echo ""
   ```

3. **Add comment using gh CLI:**

   ```bash
   # Post comment
   result=$(gh pr comment "$prNumber" --body "$comment" 2>&1)

   if [ $? -ne 0 ]; then
     echo "❌ Failed to add comment"
     echo ""
     echo "$result"
     exit 1
   fi
   ```

4. **Confirm success:**

   ```bash
   echo "✅ Comment added successfully!"
   echo ""
   echo "Comment: $comment"
   echo ""
   echo "View PR: $prUrl"
   ```

5. **Output structured JSON:**

   ```bash
   cat <<EOF
   {
     "success": true,
     "pr": {
       "number": $prNumber,
       "title": "$prTitle",
       "url": "$prUrl"
     },
     "comment": {
       "body": "$comment",
       "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
     }
   }
EOF
   ```

## Output Format

**Console Display:**
```text
📝 Adding comment to PR #123...

PR: Add user authentication
URL: https://github.com/org/repo/pull/123

✅ Comment added successfully!

Comment: Looks great! Approved.

View PR: https://github.com/org/repo/pull/123
```

**JSON Output:**
```json
{
  "success": true,
  "pr": {
    "number": 123,
    "title": "Add user authentication",
    "url": "https://github.com/org/repo/pull/123"
  },
  "comment": {
    "body": "Looks great! Approved.",
    "timestamp": "2025-01-15T14:30:00Z"
  }
}
```

## Error Handling

**If no PR for current branch:**
```text
❌ No PR found for current branch 'feature/auth'

Options:
  - Specify PR number: /gh-comment-pr <number> "comment"
  - Create PR first: /gh-create-pr "title"
```

**If comment missing:**
```text
❌ Missing required parameter: comment

Usage:
  /gh-comment-pr <pr-number> "comment text"
  /gh-comment-pr "comment text"              # For current branch's PR

Examples:
  /gh-comment-pr 123 "LGTM!"
  /gh-comment-pr "Can you add tests?"
```

**If PR not found:**
```text
❌ Failed to find PR #999

no pull requests found
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

Return error JSON:
```json
{
  "error": true,
  "message": "No pull requests found for PR #999",
  "prNumber": 999
}
```

## Notes

- **General comments only:** This command adds comments to the PR itself, not inline code comments
- **For inline comments:** Use GitHub's web interface or wait for Phase 2 (`/gh-reply-pr-comment`)
- **Auto-detection:** If no PR number provided, automatically uses current branch's PR
- **Markdown support:** Comments support full GitHub-flavored Markdown
- **Notifications:** Comment author and PR author will be notified

## Use Cases

### Approve PR
```bash
/gh-comment-pr "LGTM! Great work!"
```

### Request Changes (Informal)
```bash
/gh-comment-pr "Can you add tests for the edge cases?"
```

### Status Update
```bash
/gh-comment-pr "Working on addressing the feedback now"
```

### Ask Questions
```bash
/gh-comment-pr "Should we consider rate limiting for this endpoint?"
```

### Link to Related Issues
```bash
/gh-comment-pr "This resolves #456 and partially addresses #789"
```

### Multi-line Comments
```bash
/gh-comment-pr "Few points:
- Great error handling
- Consider adding JSDoc comments
- Tests look good"
```

## Integration with Work System

### Respond to Feedback
```bash
# View comments
/gh-get-pr-comments

# Address issues
# ... make fixes ...

# Notify reviewers
/gh-comment-pr "Addressed all feedback - ready for re-review"

# Push changes
/git-commit "Address review feedback" --all
/git-push
```

### Request Specific Review
```bash
/gh-comment-pr "Hey @senior-dev, can you review the security aspects?"
```

### Deliver Workflow Integration
```bash
# In /deliver command after pushing
/gh-comment-pr "Updates pushed - addressed comments #1-5"
```

## Related Commands

- `/gh-get-pr-comments` - View all PR comments
- `/gh-reply-pr-comment` - Reply to a specific comment thread (Phase 2)
- `/gh-review-pr` - Submit a formal review (approve/request changes)
- `/gh-resolve-pr-comment` - Mark comment thread as resolved (Phase 2)
- `/gh-create-pr` - Create a new pull request
- `/gh-merge-pr` - Merge an approved PR

## Comparison with Related Commands

| Command | Purpose | Use When |
|---------|---------|----------|
| `/gh-comment-pr` | General PR discussion | Questions, status updates, general feedback |
| `/gh-reply-pr-comment` | Reply to specific thread | Responding to inline code comments |
| `/gh-review-pr` | Formal review | Approving or requesting changes officially |

## Future Enhancements

Phase 2 will add:
- Inline code comment support
- Reply to specific comment threads
- @mention auto-completion
- Quote previous comments in replies
