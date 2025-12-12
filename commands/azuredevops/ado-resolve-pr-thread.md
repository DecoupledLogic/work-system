---
description: Resolve/update Azure DevOps PR comment thread status (helper)
allowedTools:
  - Bash
  - Read
---

# Azure DevOps API: Resolve PR Thread

Update the status of a comment thread on an Azure DevOps pull request.

## Usage

```bash
/ado-resolve-pr-thread <pr-id> <thread-id> --status <status>
/ado-resolve-pr-thread <pr-id> <thread-id> --status fixed
/ado-resolve-pr-thread <pr-id> <thread-id> --status wontFix --project "MyProject" --repo "MyRepo"
```

## Input Parameters

- **pr-id** (required): Pull request ID
- **thread-id** (required): Thread ID to update
- **--status** (required): New thread status
- **--project** (optional): Override project from work-manager.yaml
- **--repo** (optional): Override repository (auto-detected from git remote if not specified)

## Status Options

| Status | Description | When to Use |
|--------|-------------|-------------|
| `active` | Thread is open and needs attention | Default for new threads |
| `fixed` | Issue has been resolved | Changes made to address feedback |
| `wontFix` | Issue acknowledged but won't be addressed | Out of scope or intentional |
| `closed` | Discussion is complete | No changes needed, just closing |
| `byDesign` | Behavior is intentional | Not a bug, working as designed |
| `pending` | Waiting for response | Need clarification or input |

## Implementation

1. **Parse input:**

   ```bash
   prId=$1
   threadId=$2

   # Parse flags
   status=""
   projectOverride=""
   repoOverride=""

   shift 2
   while [[ $# -gt 0 ]]; do
     case $1 in
       --status) status="$2"; shift 2 ;;
       --project) projectOverride="$2"; shift 2 ;;
       --repo) repoOverride="$2"; shift 2 ;;
       *) shift ;;
     esac
   done

   if [ -z "$prId" ] || [ -z "$threadId" ] || [ -z "$status" ]; then
     echo "Error: pr-id, thread-id, and --status are required"
     exit 1
   fi

   # Validate status
   valid_statuses=("active" "fixed" "wontFix" "closed" "byDesign" "pending")
   if [[ ! " ${valid_statuses[@]} " =~ " ${status} " ]]; then
     echo "Error: Invalid status. Must be one of: ${valid_statuses[*]}"
     exit 1
   fi
   ```

2. **Read profile from work-manager config:**

   ```bash
   profile="default"
   configProject=""
   configRepo=""

   if [ -f ".claude/work-manager.yaml" ]; then
     profile=$(grep -A10 "azuredevops:" .claude/work-manager.yaml | grep "profile:" | awk '{print $2}' || echo "default")
     configProject=$(grep -A10 "azuredevops:" .claude/work-manager.yaml | grep "project:" | awk '{print $2}')
     configRepo=$(grep -A10 "azuredevops:" .claude/work-manager.yaml | grep "repository:" | awk '{print $2}')
     [ -z "$profile" ] && profile="default"
   fi
   ```

3. **Read credentials from named profile:**

   ```bash
   credentials=$(cat ~/.azuredevops/credentials.json)
   serverUrl=$(echo "$credentials" | jq -r ".${profile}.serverUrl // .default.serverUrl")
   collection=$(echo "$credentials" | jq -r ".${profile}.collection // .default.collection")
   pat=$(echo "$credentials" | jq -r ".${profile}.pat // .default.pat")
   ```

4. **Determine project and repository:**

   ```bash
   project="${projectOverride:-$configProject}"
   if [ -z "$project" ]; then
     echo "Error: project not specified. Use --project or set in .claude/work-manager.yaml"
     exit 1
   fi

   repository="${repoOverride:-$configRepo}"
   if [ -z "$repository" ]; then
     repository=$(git remote get-url origin 2>/dev/null | sed -E 's|.*[:/]([^/]+)/([^/.]+)(\.git)?$|\2|')
   fi
   if [ -z "$repository" ]; then
     echo "Error: repository not specified and could not auto-detect from git remote"
     exit 1
   fi
   ```

5. **Build request body:**

   ```bash
   body=$(jq -n \
     --arg status "$status" \
     '{
       status: $status
     }')
   ```

6. **Make API request:**

   ```bash
   auth=$(echo -n ":${pat}" | base64)

   response=$(curl -s \
     -H "Authorization: Basic ${auth}" \
     -H "Content-Type: application/json" \
     -X PATCH \
     -d "$body" \
     "${serverUrl}/${collection}/${project}/_apis/git/repositories/${repository}/pullrequests/${prId}/threads/${threadId}?api-version=6.0")
   ```

7. **Parse and format response:**

   ```bash
   # Check for errors
   if echo "$response" | jq -e '.message' > /dev/null 2>&1; then
     error=$(echo "$response" | jq -r '.message')
     echo "Error: $error"
     exit 1
   fi

   # Format success output
   threadStatus=$(echo "$response" | jq -r '.status')
   commentCount=$(echo "$response" | jq -r '.comments | length')
   filePath=$(echo "$response" | jq -r '.threadContext.filePath // "N/A"')

   echo "✅ Thread status updated"
   echo ""
   echo "Thread ID: ${threadId}"
   echo "New Status: ${threadStatus}"
   echo "File: ${filePath}"
   echo "Comments: ${commentCount}"
   ```

## Response Format

Success response:

```json
{
  "thread": {
    "id": 4269,
    "status": "fixed",
    "publishedDate": "2025-01-15T10:30:00Z",
    "lastUpdatedDate": "2025-01-15T14:45:00Z",
    "threadContext": {
      "filePath": "/ServiceCollectionExtensions.cs",
      "rightFileStart": {
        "line": 42,
        "offset": 0
      },
      "rightFileEnd": {
        "line": 42,
        "offset": 80
      }
    },
    "comments": [
      {
        "id": 1,
        "author": {"displayName": "Ali Bijanfar"},
        "content": "Use Transient here, not Scoped",
        "commentType": "text"
      },
      {
        "id": 2,
        "author": {"displayName": "Claude Agent"},
        "content": "Fixed - changed to Transient",
        "parentCommentId": 1
      }
    ],
    "properties": {
      "CodeReviewThreadType": "VoteUpdate"
    }
  }
}
```

## Examples

### Mark thread as fixed

```bash
/ado-resolve-pr-thread 123 4269 --status fixed
```

### Mark as won't fix with explanation

```bash
# First reply to explain why
/ado-reply-pr-thread 123 4270 "This is intentional - we need Scoped here because the service uses IRequestContext"

# Then mark as wontFix
/ado-resolve-pr-thread 123 4270 --status wontFix
```

### Close discussion thread

```bash
/ado-resolve-pr-thread 123 4271 --status closed
```

### Mark as by design

```bash
/ado-reply-pr-thread 123 4272 "This behavior is intentional per our architecture guidelines for vendor decoupling"
/ado-resolve-pr-thread 123 4272 --status byDesign
```

### Reopen a thread

```bash
/ado-resolve-pr-thread 123 4269 --status active
```

## Task Instructions

When resolving PR threads:

1. **Reply before resolving**: Always explain what was done before changing status
2. **Use appropriate status**: Match status to situation (fixed vs. wontFix vs. byDesign)
3. **Verify fixes**: Test changes before marking as fixed
4. **Be clear about wontFix**: Explain reasoning when marking wontFix
5. **Let reviewers verify**: For critical issues, reply + push changes, let reviewer mark as fixed

## Status Decision Guide

### Use `fixed` when:
- Code changes address the feedback
- Tests validate the fix
- Issue is fully resolved

### Use `wontFix` when:
- Feedback is valid but out of scope for this PR
- Changes would introduce other issues
- Team decides not to implement suggestion

### Use `byDesign` when:
- Behavior is intentional
- Follows established patterns
- Matches architecture guidelines

### Use `closed` when:
- Question is answered
- Discussion reached conclusion
- No action needed

### Use `pending` when:
- Waiting for reviewer response
- Need clarification
- Blocked on external dependency

## Typical Workflow

```bash
# 1. Get unresolved threads
/ado-get-pr-threads MyProject MyRepo 123

# 2. Review thread 4269 about DI lifetime
# Thread: "Use Transient here, not Scoped"

# 3. Make code changes
# ... edit ServiceCollectionExtensions.cs ...

# 4. Commit changes
git add .
git commit -m "fix: change ISubscriptionQuery to Transient"

# 5. Reply to thread
/ado-reply-pr-thread 123 4269 "Fixed - changed to Transient for stateless service. See commit abc123."

# 6. Mark as fixed
/ado-resolve-pr-thread 123 4269 --status fixed

# 7. Push changes
git push
```

## Batch Operations

Update multiple threads:

```bash
# Fix multiple related issues, then resolve them
/ado-resolve-pr-thread 123 4269 --status fixed  # DI lifetime issue
/ado-resolve-pr-thread 123 4270 --status fixed  # Validation issue
/ado-resolve-pr-thread 123 4271 --status fixed  # Test coverage issue
```

## Integration with Deliver Workflow

This command is used in `/deliver` workflow:

1. Agent analyzes unresolved threads
2. Makes code changes to address feedback
3. For each addressed thread:
   - Runs `/ado-reply-pr-thread` to explain fix
   - Runs `/ado-resolve-pr-thread --status fixed`
4. Pushes all changes together
5. PR ready for re-review with fewer active threads

## Error Handling

**If required parameters missing:**

```text
Missing required parameters.

Usage: /ado-resolve-pr-thread <pr-id> <thread-id> --status <status> [options]

Status options: active, fixed, wontFix, closed, byDesign, pending

Options:
  --project "MyProject"    Override project from config
  --repo "MyRepo"          Override repository (auto-detected from git)

Examples:
  /ado-resolve-pr-thread 123 4269 --status fixed
  /ado-resolve-pr-thread 123 4270 --status wontFix --project "MyProject"
```

**If invalid status:**

```text
Error: Invalid status 'resolved'. Must be one of: active, fixed, wontFix, closed, byDesign, pending
```

**If credentials missing:**

```text
Azure DevOps credentials not found.

Please create ~/.azuredevops/credentials.json
```

**If API request fails:**

- 401 Unauthorized: "Invalid or expired PAT"
- 404 Not Found: "Thread '4269' not found in PR '123'"
- 403 Forbidden: "You don't have permission to update this thread"

Return error JSON:

```json
{
  "error": true,
  "message": "Thread '4269' not found in pull request '123'",
  "statusCode": 404,
  "prId": 123,
  "threadId": 4269
}
```

## Thread Status Lifecycle

Typical thread lifecycle:

```
active → [code changes] → fixed → [PR merged]
  ↓
  → wontFix / byDesign / closed
  ↓
  → pending → [clarification] → active
```

## Best Practices

### For PR Authors:
- Don't immediately resolve after replying - give reviewer time to see response
- Use `fixed` only when changes are tested and pushed
- Use `pending` when you need clarification from reviewer
- Resolve obvious typos immediately with `fixed`

### For Reviewers:
- Let authors resolve their own comments after addressing
- Use `active` to reopen if fix is insufficient
- Use `byDesign` for architectural decisions that are intentional
- Document reasoning when marking `wontFix`

### For Teams:
- Establish conventions for status meanings
- Use `pending` to track blocked threads
- Review thread status before merging PR
- Keep thread history for future reference

## Notes

- **Status history:** Azure tracks status changes with timestamps
- **Notifications:** Thread participants notified of status changes
- **UI display:** Different statuses show with different icons/colors in ADO UI
- **Merge blocking:** Active threads may block PR merge depending on policy
- **Auto-resolve:** Some teams configure policies to auto-resolve on merge
- **Thread properties:** Status is separate from vote (approve/reject)
- **Multiple updates:** Can change status multiple times (active → pending → fixed)
- **Bulk operations:** Can script to update multiple threads efficiently

## Status Semantics

Azure DevOps thread statuses have specific meanings:

- **active**: Default state, indicates discussion ongoing
- **fixed**: Most common resolution, issue addressed with code changes
- **wontFix**: Acknowledged but won't implement (scope, design, etc.)
- **closed**: Discussion complete without code changes needed
- **byDesign**: Intentional behavior, not a bug/issue
- **pending**: Waiting for response, clarification, or external factor

## Related Commands

- `/ado-get-pr-threads` - List threads with current status
- `/ado-reply-pr-thread` - Reply before resolving
- `/ado-create-pr` - Create new PR
- `/ado-comment-pr` - Add new comment thread

## API Documentation

Azure DevOps REST API: [Update Pull Request Thread](https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pull-request-threads/update)
