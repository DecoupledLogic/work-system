---
description: Add a comment to a GitHub issue (helper)
allowedTools:
  - Bash
---

# GitHub CLI: Issue Comment

Adds a comment to a GitHub issue. Useful for automated status updates, routing notifications, and workflow tracking.

## Usage

```bash
/gh-issue-comment 123 "This is my comment"
/gh-issue-comment 123 "Routed to urgent queue"
/gh-issue-comment 456 "Status update: in progress"
```

## Input Parameters

- **issueNumber** (required): The GitHub issue number
- **body** (required): The comment text to add

## Implementation

1. **Parse input parameters:**
   ```bash
   issueNumber=""
   body=""

   # First arg is issue number, rest is body
   if [ $# -ge 2 ]; then
     issueNumber="$1"
     shift
     body="$*"
   fi

   # Validate required parameters
   if [ -z "$issueNumber" ] || [ -z "$body" ]; then
     echo "❌ Missing required parameters"
     echo ""
     echo "Usage: /gh-issue-comment <number> \"comment text\""
     echo ""
     echo "Examples:"
     echo "  /gh-issue-comment 123 \"This is my comment\""
     echo "  /gh-issue-comment 456 \"Routed to urgent queue: high priority\""
     exit 1
   fi

   # Validate issue number is numeric
   if ! [[ "$issueNumber" =~ ^[0-9]+$ ]]; then
     echo "❌ Invalid issue number: $issueNumber"
     echo ""
     echo "Issue number must be a positive integer."
     exit 1
   fi
   ```

2. **Check if issue exists:**
   ```bash
   echo "🔍 Checking issue #$issueNumber..."

   issueInfo=$(gh issue view "$issueNumber" --json number,title,state 2>/dev/null)

   if [ -z "$issueInfo" ]; then
     echo "❌ Issue #$issueNumber not found"
     echo ""
     echo "Verify the issue exists:"
     echo "  gh issue view $issueNumber"
     exit 1
   fi

   issueTitle=$(echo "$issueInfo" | jq -r '.title')
   issueState=$(echo "$issueInfo" | jq -r '.state')

   echo "   #$issueNumber: $issueTitle"
   echo "   State: $issueState"
   echo ""
   ```

3. **Add comment:**
   ```bash
   echo "💬 Adding comment..."

   if gh issue comment "$issueNumber" --body "$body"; then
     echo ""
     echo "✅ Comment added to issue #$issueNumber"
   else
     echo ""
     echo "❌ Failed to add comment"
     exit 1
   fi
   ```

4. **Output result:**

**Success response:**
```json
{
  "comment": {
    "issueNumber": 123,
    "issueTitle": "Feature request: dark mode",
    "body": "Routed to urgent queue: high priority",
    "success": true
  }
}
```

## Error Handling

**If issue not found:**
```text
❌ Issue #999 not found

Verify the issue exists:
  gh issue view 999
```

**If missing parameters:**
```text
❌ Missing required parameters

Usage: /gh-issue-comment <number> "comment text"

Examples:
  /gh-issue-comment 123 "This is my comment"
  /gh-issue-comment 456 "Routed to urgent queue: high priority"
```

**If not authenticated:**
```text
❌ Failed to add comment

You may need to authenticate:
  gh auth login
```

Return error JSON:
```json
{
  "error": true,
  "message": "Issue #999 not found",
  "issueNumber": 999
}
```

## Notes

- **Authentication**: Requires `gh auth login` to be configured
- **Permissions**: User must have write access to the repository
- **Markdown support**: Comment body supports GitHub-flavored markdown

## Use Cases

### Routing Notification

```bash
# Notify when routing work item
/gh-issue-comment 123 "Routed to urgent queue: high priority customer request"
```

### Status Update

```bash
# Update issue with progress
/gh-issue-comment 456 "Status update: Implementation complete, ready for review"
```

### Workflow Tracking

```bash
# Log workflow transitions
/gh-issue-comment 789 "Moved from Triage to Plan stage"
```

### Link to Related Work

```bash
# Reference related items
/gh-issue-comment 123 "Related to TW-26134585. See PR #42 for implementation."
```

## Integration with Work System

Route command workflow:
```bash
# 1. Route work item to queue
/route TW-26134585 urgent "High priority customer request"

# 2. If linked to GitHub issue, add comment
/gh-issue-comment 123 "Routed to urgent queue: High priority customer request"
```

Triage workflow:
```bash
# 1. Triage incoming item
/triage TW-26134585

# 2. Update GitHub issue with triage result
/gh-issue-comment 456 "Triaged as: feature request, assigned process template: standard"
```

## Related Commands

- `/gh-create-pr` - Create PR (can reference issues)
- `/gh-status` - Check repository status
