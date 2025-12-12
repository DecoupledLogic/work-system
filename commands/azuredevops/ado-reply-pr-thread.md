---
description: Reply to an Azure DevOps PR comment thread (helper)
allowedTools:
  - Bash
  - Read
---

# Azure DevOps API: Reply to PR Thread

Reply to an existing comment thread on an Azure DevOps pull request.

## Usage

```bash
/ado-reply-pr-thread <pr-id> <thread-id> "Your reply text"
/ado-reply-pr-thread <pr-id> <thread-id> "Reply text" --project "MyProject" --repo "MyRepo"
```

## Input Parameters

- **pr-id** (required): Pull request ID
- **thread-id** (required): Thread ID to reply to
- **reply-text** (required): Text of your reply
- **--project** (optional): Override project from work-manager.yaml
- **--repo** (optional): Override repository (auto-detected from git remote if not specified)

## Implementation

1. **Parse input:**

   ```bash
   prId=$1
   threadId=$2
   replyText=$3

   # Parse flags
   projectOverride=""
   repoOverride=""

   shift 3
   while [[ $# -gt 0 ]]; do
     case $1 in
       --project) projectOverride="$2"; shift 2 ;;
       --repo) repoOverride="$2"; shift 2 ;;
       *) shift ;;
     esac
   done

   if [ -z "$prId" ] || [ -z "$threadId" ] || [ -z "$replyText" ]; then
     echo "Error: pr-id, thread-id, and reply-text are required"
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
     --arg content "$replyText" \
     '{
       content: $content,
       commentType: "text"
     }')
   ```

6. **Make API request:**

   ```bash
   auth=$(echo -n ":${pat}" | base64)

   response=$(curl -s \
     -H "Authorization: Basic ${auth}" \
     -H "Content-Type: application/json" \
     -X POST \
     -d "$body" \
     "${serverUrl}/${collection}/${project}/_apis/git/repositories/${repository}/pullrequests/${prId}/threads/${threadId}/comments?api-version=6.0")
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
   commentId=$(echo "$response" | jq -r '.id')
   authorName=$(echo "$response" | jq -r '.author.displayName')
   publishedDate=$(echo "$response" | jq -r '.publishedDate')

   echo "✅ Reply added to thread ${threadId}"
   echo ""
   echo "Comment ID: ${commentId}"
   echo "Author: ${authorName}"
   echo "Published: ${publishedDate}"
   ```

## Response Format

Success response:

```json
{
  "comment": {
    "id": 2,
    "parentCommentId": 1,
    "author": {
      "displayName": "Claude Agent",
      "id": "user-guid",
      "uniqueName": "agent@company.com"
    },
    "content": "Fixed - changed to Transient for stateless service",
    "publishedDate": "2025-01-15T14:30:00Z",
    "lastUpdatedDate": "2025-01-15T14:30:00Z",
    "lastContentUpdatedDate": "2025-01-15T14:30:00Z",
    "commentType": "text",
    "_links": {
      "self": {
        "href": "https://azuredevops.discovertec.net/Link/_apis/git/repositories/MyRepo/pullRequests/123/threads/4269/comments/2"
      }
    }
  }
}
```

## Examples

### Reply to address feedback

```bash
/ado-reply-pr-thread 123 4269 "Fixed - changed lifetime to Transient as suggested. See commit abc123."
```

### Reply with multi-line explanation

```bash
/ado-reply-pr-thread 123 4269 "Thanks for catching this!

I've made the following changes:
- Changed ISubscriptionQuery to Transient
- Added validation for null inputs
- Updated unit tests

Let me know if you'd like any other adjustments."
```

### Reply with project and repo override

```bash
/ado-reply-pr-thread 123 4269 "Updated the implementation" --project "MyProject" --repo "MyRepo"
```

## Task Instructions

When replying to PR threads:

1. **Get thread context first**: Use `/ado-get-pr-threads` to see full conversation
2. **Be specific**: Explain what changed and why
3. **Reference commits**: Mention commit hashes if applicable
4. **Address all concerns**: If thread has multiple points, address each one
5. **Use markdown**: ADO supports markdown in comment content
6. **Follow up with status change**: Often reply + resolve together

## Common Patterns

### Acknowledge and fix
```bash
/ado-reply-pr-thread 123 4269 "Good catch! Fixed in commit abc123."
```

### Explain reasoning
```bash
/ado-reply-pr-thread 123 4269 "I kept this as Scoped because the service maintains per-request context via IRequestContext injection. Let me know if you'd prefer a different approach."
```

### Request clarification
```bash
/ado-reply-pr-thread 123 4269 "Could you clarify which specific service you're referring to? There are several Scoped registrations in ServiceCollectionExtensions.cs."
```

### Agree with refactoring suggestion
```bash
/ado-reply-pr-thread 123 4269 "Excellent suggestion! I've refactored to use the generic ISubscriptionSyncService pattern as you recommended."
```

## Typical Workflow

```bash
# 1. Get unresolved threads
/ado-get-pr-threads MyProject MyRepo 123

# 2. Make code changes to address thread 4269
# ... edit files ...

# 3. Commit changes
git add .
git commit -m "fix: change service lifetime to Transient"

# 4. Reply to thread
/ado-reply-pr-thread 123 4269 "Fixed - changed to Transient. See latest commit."

# 5. Mark thread as resolved
/ado-resolve-pr-thread 123 4269 --status fixed

# 6. Push changes
git push
```

## Integration with Deliver Workflow

This command is used in `/deliver` when addressing PR feedback:

1. Agent runs `/ado-get-pr-threads` to identify unresolved threads
2. For each thread requiring changes:
   - Agent analyzes the feedback
   - Makes necessary code changes
   - Runs `/ado-reply-pr-thread` to notify reviewer
   - Runs `/ado-resolve-pr-thread` if issue is fully addressed
3. Agent pushes all changes together

## Error Handling

**If required parameters missing:**

```text
Missing required parameters.

Usage: /ado-reply-pr-thread <pr-id> <thread-id> <reply-text> [options]

Options:
  --project "MyProject"    Override project from config
  --repo "MyRepo"          Override repository (auto-detected from git)

Examples:
  /ado-reply-pr-thread 123 4269 "Fixed - changed to Transient"
  /ado-reply-pr-thread 123 4269 "Updated" --project "MyProject"
```

**If credentials missing:**

```text
Azure DevOps credentials not found.

Please create ~/.azuredevops/credentials.json
```

**If API request fails:**

- 401 Unauthorized: "Invalid or expired PAT"
- 404 Not Found: "Thread '4269' not found in PR '123'"
- 403 Forbidden: "You don't have permission to comment on this PR"

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

## Thread Context

When replying to threads, the reply:
- Inherits the file/line context from the parent thread
- Appears in chronological order within the thread
- Notifies all thread participants
- Maintains the thread's open/resolved status (until explicitly changed)
- Shows up in Azure DevOps UI as a nested reply

## Reply Formatting

Azure DevOps comment content supports markdown:

```markdown
Fixed - here's what changed:

**Before:**
```csharp
services.AddScoped<IQuery, Query>();
```

**After:**
```csharp
services.AddTransient<IQuery, Query>();
```

Reasoning: Service is stateless and doesn't need per-request lifetime.
```

## Notes

- **Thread hierarchy:** Replies maintain parent-child relationship via `parentCommentId`
- **Notifications:** All thread participants receive notifications of new replies
- **Markdown support:** Full GitHub-flavored markdown supported
- **Code blocks:** Use triple backticks with language for syntax highlighting
- **@mentions:** Use `@<DisplayName>` to mention users (e.g., `@Ali Bijanfar`)
- **Links:** Support for hyperlinks and work item references (#12345)
- **Multi-repo:** Works across all repos in project - just run from correct directory
- **Auto-detect:** Repository name auto-detected from git remote origin

## Related Commands

- `/ado-get-pr-threads` - List all threads to find thread IDs
- `/ado-resolve-pr-thread` - Change thread status after reply
- `/ado-create-pr` - Create new PR
- `/ado-comment-pr` - Add comment (creates new thread, not a reply)

## API Documentation

Azure DevOps REST API: [Add Comment to Thread](https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pull-request-thread-comments/create)
