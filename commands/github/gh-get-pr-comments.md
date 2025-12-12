---
description: List all comments and review threads on a GitHub pull request (helper)
allowedTools:
  - Bash
---

# GitHub CLI: Get PR Comments

Lists all comments and review threads on a GitHub pull request, including replies, status, authors, and timestamps.

## Usage

```bash
/gh-get-pr-comments 123
/gh-get-pr-comments              # Current branch's PR
```

## Input Parameters

- **pr-number** (optional): PR number. If omitted, uses current branch's PR

## Implementation

1. **Parse input:**

   ```bash
   prNumber=$1

   # If no PR number provided, get from current branch
   if [ -z "$prNumber" ]; then
     currentBranch=$(git branch --show-current)

     # Try to get PR for current branch
     prNumber=$(gh pr view --json number --jq '.number' 2>/dev/null)

     if [ -z "$prNumber" ]; then
       echo "❌ No PR found for current branch '$currentBranch'"
       echo ""
       echo "Options:"
       echo "  - Specify PR number: /gh-get-pr-comments <number>"
       echo "  - Create PR first: /gh-create-pr \"title\""
       exit 1
     fi
   fi
   ```

2. **Fetch PR data with comments and reviews:**

   ```bash
   echo "📥 Fetching PR #$prNumber comments..."
   echo ""

   # Fetch PR details including comments and reviews
   prData=$(gh pr view "$prNumber" --json \
     number,title,state,url,author,\
     comments,reviews,reviewThreads \
     2>&1)

   if [ $? -ne 0 ]; then
     echo "❌ Failed to fetch PR #$prNumber"
     echo ""
     echo "$prData"
     exit 1
   fi
   ```

3. **Parse and structure comments:**

   ```bash
   # Extract basic PR info
   prTitle=$(echo "$prData" | jq -r '.title')
   prAuthor=$(echo "$prData" | jq -r '.author.login')
   prState=$(echo "$prData" | jq -r '.state')
   prUrl=$(echo "$prData" | jq -r '.url')

   # Parse comments (general PR comments)
   generalComments=$(echo "$prData" | jq '.comments // []')

   # Parse reviews (formal review submissions)
   reviews=$(echo "$prData" | jq '.reviews // []')

   # Parse review threads (inline code comments)
   reviewThreads=$(echo "$prData" | jq '.reviewThreads // []')
   ```

4. **Count and categorize:**

   ```bash
   # Count different types of comments
   generalCount=$(echo "$generalComments" | jq 'length')
   reviewCount=$(echo "$reviews" | jq 'length')

   # Count resolved vs unresolved threads (GitHub API limitation: may not have full status)
   # Note: GitHub's API doesn't always expose resolved status reliably

   totalComments=$((generalCount + reviewCount))

   echo "📋 PR #$prNumber: $prTitle"
   echo "   Author: $prAuthor"
   echo "   State: $prState"
   echo "   URL: $prUrl"
   echo ""
   echo "💬 Comments Summary:"
   echo "   General comments: $generalCount"
   echo "   Reviews: $reviewCount"
   echo "   Total: $totalComments"
   echo ""
   ```

5. **Display comments:**

   ```bash
   # Display general comments
   if [ "$generalCount" -gt 0 ]; then
     echo "═══════════════════════════════════════════════════════════"
     echo "General Comments"
     echo "═══════════════════════════════════════════════════════════"
     echo ""

     echo "$generalComments" | jq -r '.[] |
       "Comment #\(.databaseId // "N/A")
       Author: \(.author.login)
       Date: \(.createdAt)
       \(.body)
       ───────────────────────────────────────────────────────────
       "'
   fi

   # Display reviews
   if [ "$reviewCount" -gt 0 ]; then
     echo ""
     echo "═══════════════════════════════════════════════════════════"
     echo "Reviews"
     echo "═══════════════════════════════════════════════════════════"
     echo ""

     echo "$reviews" | jq -r '.[] |
       "Review #\(.databaseId // "N/A")
       Author: \(.author.login)
       State: \(.state)
       Date: \(.submittedAt)
       \(.body // "No comment")
       ───────────────────────────────────────────────────────────
       "'
   fi
   ```

6. **Output structured JSON:**

   ```bash
   # Create structured output
   cat <<EOF
   {
     "pr": {
       "number": $prNumber,
       "title": "$prTitle",
       "author": "$prAuthor",
       "state": "$prState",
       "url": "$prUrl"
     },
     "comments": {
       "general": $generalComments,
       "reviews": $reviews
     },
     "summary": {
       "generalComments": $generalCount,
       "reviews": $reviewCount,
       "total": $totalComments
     }
   }
EOF
   ```

## Output Format

**Console Display:**
```text
📋 PR #123: Add user authentication
   Author: john-dev
   State: OPEN
   URL: https://github.com/org/repo/pull/123

💬 Comments Summary:
   General comments: 3
   Reviews: 2
   Total: 5

═══════════════════════════════════════════════════════════
General Comments
═══════════════════════════════════════════════════════════

Comment #456789
Author: jane-reviewer
Date: 2025-01-15T10:30:00Z
Should we add rate limiting to the login endpoint?
───────────────────────────────────────────────────────────

Comment #456790
Author: john-dev
Date: 2025-01-15T11:00:00Z
Good point! I'll add it in the next iteration.
───────────────────────────────────────────────────────────

═══════════════════════════════════════════════════════════
Reviews
═══════════════════════════════════════════════════════════

Review #123456
Author: senior-dev
State: APPROVED
Date: 2025-01-15T14:30:00Z
LGTM! Great work on the error handling.
───────────────────────────────────────────────────────────
```

**JSON Output:**
```json
{
  "pr": {
    "number": 123,
    "title": "Add user authentication",
    "author": "john-dev",
    "state": "OPEN",
    "url": "https://github.com/org/repo/pull/123"
  },
  "comments": {
    "general": [
      {
        "databaseId": 456789,
        "author": {
          "login": "jane-reviewer"
        },
        "createdAt": "2025-01-15T10:30:00Z",
        "body": "Should we add rate limiting to the login endpoint?"
      }
    ],
    "reviews": [
      {
        "databaseId": 123456,
        "author": {
          "login": "senior-dev"
        },
        "state": "APPROVED",
        "submittedAt": "2025-01-15T14:30:00Z",
        "body": "LGTM! Great work on the error handling."
      }
    ]
  },
  "summary": {
    "generalComments": 3,
    "reviews": 2,
    "total": 5
  }
}
```

## Error Handling

**If no PR for current branch:**
```text
❌ No PR found for current branch 'feature/auth'

Options:
  - Specify PR number: /gh-get-pr-comments <number>
  - Create PR first: /gh-create-pr "title"
```

**If PR not found:**
```text
❌ Failed to fetch PR #999

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

- **GitHub API Limitation:** GitHub's GraphQL API doesn't reliably expose "resolved" status for review threads through `gh` CLI. For full thread resolution status, use GitHub's REST API directly or the web interface.
- **Comment Types:**
  - **General comments:** Discussion on the PR itself (not tied to specific code lines)
  - **Reviews:** Formal review submissions (APPROVED, CHANGES_REQUESTED, COMMENTED)
  - **Review threads:** Inline code comments (requires separate API call for full details)
- **Auto-detection:** If no PR number provided, automatically detects PR for current branch
- **Performance:** Fetches all data in a single API call for efficiency

## Use Cases

### View Comments Before Addressing Feedback
```bash
# Check what needs to be addressed
/gh-get-pr-comments

# Review specific PR
/gh-get-pr-comments 456
```

### Monitor PR Reviews
```bash
# Check if reviewers have responded
/gh-get-pr-comments

# Look for approval
```

### Integration with Deliver Workflow
```bash
# Before pushing updates
/gh-get-pr-comments    # See what needs addressing
# Fix issues
/git-commit "Address review comments" --all
/git-push
```

## Related Commands

- `/gh-comment-pr` - Add a general comment to the PR
- `/gh-reply-pr-comment` - Reply to a specific comment thread
- `/gh-review-pr` - Submit a formal review
- `/gh-resolve-pr-comment` - Mark a comment thread as resolved
- `/gh-create-pr` - Create a new pull request
- `/gh-merge-pr` - Merge an approved PR

## Future Enhancements

Phase 2 will add:
- Reply to specific comment threads (`/gh-reply-pr-comment`)
- Resolve comment threads (`/gh-resolve-pr-comment`)
- Filter by unresolved only
- Better inline code comment display with file context
