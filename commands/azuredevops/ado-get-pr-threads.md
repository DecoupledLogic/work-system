---
description: List all comment threads on an Azure DevOps pull request (helper)
allowedTools:
  - Bash
  - Read
---

# Azure DevOps API: Get PR Threads

Lists all comment threads on an Azure DevOps pull request, including thread status, file context, and all comments/replies in each thread.

## Usage

```bash
/ado-get-pr-threads "MyProject" "MyRepo" 123
/ado-get-pr-threads "MyProject" "MyRepo" 123 --status active
/ado-get-pr-threads "MyProject" "MyRepo" 123 --format summary
```

## Input Parameters

- **project** (required): Project name
- **repository** (required): Repository name
- **pullRequestId** (required): Pull request ID (numeric)
- **--status** (optional): Filter by status (active, fixed, closed, wontFix, byDesign, pending)
- **--format** (optional): Output format (detailed|summary) - default: detailed

## Implementation

1. **Parse input:**

   ```bash
   project=$1
   repository=$2
   pullRequestId=$3
   shift 3

   # Parse optional flags
   filterStatus=""
   format="detailed"

   while [[ $# -gt 0 ]]; do
     case $1 in
       --status)
         filterStatus="$2"
         shift 2
         ;;
       --format)
         format="$2"
         shift 2
         ;;
       *)
         shift
         ;;
     esac
   done

   # Validate required parameters
   if [ -z "$project" ] || [ -z "$repository" ] || [ -z "$pullRequestId" ]; then
     echo "❌ Missing required parameters"
     echo ""
     echo "Usage: /ado-get-pr-threads <project> <repository> <pullRequestId> [options]"
     echo ""
     echo "Options:"
     echo "  --status <status>    Filter by status (active, fixed, closed, wontFix, byDesign, pending)"
     echo "  --format <format>    Output format (detailed|summary) - default: detailed"
     echo ""
     echo "Example:"
     echo "  /ado-get-pr-threads \"MyProject\" \"MyRepo\" 123"
     echo "  /ado-get-pr-threads \"MyProject\" \"MyRepo\" 123 --status active"
     exit 1
   fi
   ```

2. **Read credentials:**

   ```bash
   if [ ! -f ~/.azuredevops/credentials.json ]; then
     echo "❌ Azure DevOps credentials not found"
     echo ""
     echo "Please create ~/.azuredevops/credentials.json with:"
     echo "{"
     echo "  \"serverUrl\": \"https://dev.azure.com\","
     echo "  \"collection\": \"your-org\","
     echo "  \"pat\": \"your-personal-access-token\""
     echo "}"
     exit 1
   fi

   credentials=$(cat ~/.azuredevops/credentials.json)
   serverUrl=$(echo "$credentials" | jq -r '.serverUrl')
   collection=$(echo "$credentials" | jq -r '.collection')
   pat=$(echo "$credentials" | jq -r '.pat')

   if [ -z "$pat" ] || [ "$pat" = "null" ]; then
     echo "❌ Invalid credentials file"
     exit 1
   fi

   auth=$(echo -n ":${pat}" | base64)
   ```

3. **Fetch PR details:**

   ```bash
   echo "📥 Fetching PR #$pullRequestId threads..."
   echo ""

   # Get PR info first
   prData=$(curl -s \
     -H "Authorization: Basic ${auth}" \
     -H "Content-Type: application/json" \
     "${serverUrl}/${collection}/${project}/_apis/git/repositories/${repository}/pullrequests/${pullRequestId}?api-version=6.0")

   if [ $? -ne 0 ] || [ "$(echo "$prData" | jq -r '.pullRequestId // empty')" = "" ]; then
     echo "❌ Failed to fetch PR #$pullRequestId"
     echo ""
     echo "$prData" | jq -r '.message // .'
     exit 1
   fi

   prTitle=$(echo "$prData" | jq -r '.title')
   prStatus=$(echo "$prData" | jq -r '.status')
   prCreatedBy=$(echo "$prData" | jq -r '.createdBy.displayName')
   prUrl=$(echo "$prData" | jq -r '._links.web.href')
   ```

4. **Fetch all threads:**

   ```bash
   # Get all threads
   threadsData=$(curl -s \
     -H "Authorization: Basic ${auth}" \
     -H "Content-Type: application/json" \
     "${serverUrl}/${collection}/${project}/_apis/git/repositories/${repository}/pullrequests/${pullRequestId}/threads?api-version=6.0")

   if [ $? -ne 0 ]; then
     echo "❌ Failed to fetch PR threads"
     echo ""
     echo "$threadsData"
     exit 1
   fi

   threads=$(echo "$threadsData" | jq '.value // []')

   if [ "$threads" = "[]" ]; then
     echo "No threads found for PR #$pullRequestId"
     exit 0
   fi
   ```

5. **Filter and count threads:**

   ```bash
   # Filter by status if specified
   if [ -n "$filterStatus" ]; then
     threads=$(echo "$threads" | jq --arg status "$filterStatus" \
       '[.[] | select(.status == $status)]')
   fi

   # Count threads by status
   totalThreads=$(echo "$threads" | jq 'length')
   activeThreads=$(echo "$threads" | jq '[.[] | select(.status == "active")] | length')
   fixedThreads=$(echo "$threads" | jq '[.[] | select(.status == "fixed")] | length')
   closedThreads=$(echo "$threads" | jq '[.[] | select(.status == "closed")] | length')
   wontFixThreads=$(echo "$threads" | jq '[.[] | select(.status == "wontFix")] | length')
   byDesignThreads=$(echo "$threads" | jq '[.[] | select(.status == "byDesign")] | length')
   pendingThreads=$(echo "$threads" | jq '[.[] | select(.status == "pending")] | length')

   unresolvedTotal=$((activeThreads + pendingThreads))
   ```

6. **Display PR info and summary:**

   ```bash
   echo "📋 PR #$pullRequestId: $prTitle"
   echo "   Author: $prCreatedBy"
   echo "   Status: $prStatus"
   echo "   URL: $prUrl"
   echo ""
   echo "💬 Thread Summary:"
   echo "   Total: $totalThreads"
   echo "   ├─ Active: $activeThreads"
   echo "   ├─ Pending: $pendingThreads"
   echo "   ├─ Fixed: $fixedThreads"
   echo "   ├─ Closed: $closedThreads"
   echo "   ├─ Won't Fix: $wontFixThreads"
   echo "   └─ By Design: $byDesignThreads"
   echo ""
   echo "⚠️  Unresolved: $unresolvedTotal"
   echo ""
   ```

7. **Display threads (if detailed format):**

   ```bash
   if [ "$format" = "detailed" ] && [ "$totalThreads" -gt 0 ]; then
     echo "═══════════════════════════════════════════════════════════"
     echo "Thread Details"
     echo "═══════════════════════════════════════════════════════════"
     echo ""

     # Process each thread
     echo "$threads" | jq -r '.[] |
       "Thread #\(.id)
       Status: \(.status)
       Published: \(.publishedDate)
       Updated: \(.lastUpdatedDate)
       " +
       (if .threadContext then
         "File: \(.threadContext.filePath // "N/A")
       Line: \(if .threadContext.rightFileStart then "\(.threadContext.rightFileStart.line)\(if .threadContext.rightFileEnd.line != .threadContext.rightFileStart.line then "-\(.threadContext.rightFileEnd.line)" else "" end)" else "N/A" end)
       " else "" end) +
       "Comments: \(.comments | length)
       ───────────────────────────────────────────────────────────"'

     # Display comments in each thread
     echo "$threads" | jq -c '.[]' | while IFS= read -r thread; do
       threadId=$(echo "$thread" | jq -r '.id')
       comments=$(echo "$thread" | jq -c '.comments[]')

       echo "$comments" | while IFS= read -r comment; do
         commentId=$(echo "$comment" | jq -r '.id')
         author=$(echo "$comment" | jq -r '.author.displayName')
         content=$(echo "$comment" | jq -r '.content')
         date=$(echo "$comment" | jq -r '.publishedDate')
         parentId=$(echo "$comment" | jq -r '.parentCommentId // 0')

         indent=""
         if [ "$parentId" != "0" ]; then
           indent="  ↳ "
         fi

         echo "${indent}💬 $author ($(date -d "$date" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$date"))"
         echo "${indent}   $content"
         echo ""
       done

       echo "───────────────────────────────────────────────────────────"
       echo ""
     done
   fi
   ```

8. **Output structured JSON:**

   ```bash
   # Create structured output
   jq -n \
     --argjson pr "$(echo "$prData" | jq '{pullRequestId, title, status, createdBy, url: ._links.web.href}')" \
     --argjson threads "$threads" \
     --argjson summary "$(jq -n \
       --argjson total "$totalThreads" \
       --argjson active "$activeThreads" \
       --argjson pending "$pendingThreads" \
       --argjson fixed "$fixedThreads" \
       --argjson closed "$closedThreads" \
       --argjson wontFix "$wontFixThreads" \
       --argjson byDesign "$byDesignThreads" \
       --argjson unresolved "$unresolvedTotal" \
       '{total: $total, active: $active, pending: $pending, fixed: $fixed, closed: $closed, wontFix: $wontFix, byDesign: $byDesign, unresolved: $unresolved}')" \
     '{pullRequest: $pr, threads: $threads, summary: $summary}'
   ```

## Output Format

**Console Display (Detailed):**
```text
📥 Fetching PR #123 threads...

📋 PR #123: Add subscription sync
   Author: John Doe
   Status: active
   URL: https://dev.azure.com/org/project/_git/repo/pullrequest/123

💬 Thread Summary:
   Total: 15
   ├─ Active: 3
   ├─ Pending: 1
   ├─ Fixed: 10
   ├─ Closed: 1
   ├─ Won't Fix: 0
   └─ By Design: 0

⚠️  Unresolved: 4

═══════════════════════════════════════════════════════════
Thread Details
═══════════════════════════════════════════════════════════

Thread #4269
Status: active
Published: 2025-01-15T10:30:00Z
Updated: 2025-01-15T14:00:00Z
File: /ServiceCollectionExtensions.cs
Line: 42
Comments: 2
───────────────────────────────────────────────────────────
💬 Ali Bijanfar (2025-01-15 10:30)
   Use Transient here, not Scoped. This service is stateless.

  ↳ 💬 Claude Agent (2025-01-15 14:00)
     Fixed - changed to AddTransient<ISubscriptionQuery, SubscriptionQuery>()

───────────────────────────────────────────────────────────

Thread #4270
Status: fixed
Published: 2025-01-15T10:45:00Z
Updated: 2025-01-15T15:30:00Z
File: /IStaxbillService.cs
Line: 15
Comments: 3
───────────────────────────────────────────────────────────
💬 Ali Bijanfar (2025-01-15 10:45)
   This should be named generically, not with vendor name

  ↳ 💬 Claude Agent (2025-01-15 12:00)
     Good point! What would you suggest?

  ↳ 💬 Ali Bijanfar (2025-01-15 15:30)
     ISubscriptionSyncService - keep vendor implementation in Infrastructure

───────────────────────────────────────────────────────────
```

**Console Display (Summary):**
```text
📥 Fetching PR #123 threads...

📋 PR #123: Add subscription sync
   Author: John Doe
   Status: active
   URL: https://dev.azure.com/org/project/_git/repo/pullrequest/123

💬 Thread Summary:
   Total: 15
   ├─ Active: 3
   ├─ Pending: 1
   ├─ Fixed: 10
   ├─ Closed: 1
   ├─ Won't Fix: 0
   └─ By Design: 0

⚠️  Unresolved: 4
```

**JSON Output:**
```json
{
  "pullRequest": {
    "pullRequestId": 123,
    "title": "Add subscription sync",
    "status": "active",
    "createdBy": {
      "displayName": "John Doe",
      "uniqueName": "john.doe@company.com",
      "id": "user-guid"
    },
    "url": "https://dev.azure.com/org/project/_git/repo/pullrequest/123"
  },
  "threads": [
    {
      "id": 4269,
      "status": "active",
      "publishedDate": "2025-01-15T10:30:00Z",
      "lastUpdatedDate": "2025-01-15T14:00:00Z",
      "threadContext": {
        "filePath": "/ServiceCollectionExtensions.cs",
        "rightFileStart": {
          "line": 42,
          "offset": 1
        },
        "rightFileEnd": {
          "line": 42,
          "offset": 1
        }
      },
      "comments": [
        {
          "id": 1,
          "parentCommentId": 0,
          "author": {
            "displayName": "Ali Bijanfar",
            "uniqueName": "ali.bijanfar@company.com",
            "id": "reviewer-guid"
          },
          "content": "Use Transient here, not Scoped. This service is stateless.",
          "publishedDate": "2025-01-15T10:30:00Z",
          "commentType": "text"
        },
        {
          "id": 2,
          "parentCommentId": 1,
          "author": {
            "displayName": "Claude Agent",
            "uniqueName": "claude@company.com",
            "id": "agent-guid"
          },
          "content": "Fixed - changed to AddTransient<ISubscriptionQuery, SubscriptionQuery>()",
          "publishedDate": "2025-01-15T14:00:00Z",
          "commentType": "text"
        }
      ],
      "isDeleted": false
    }
  ],
  "summary": {
    "total": 15,
    "active": 3,
    "pending": 1,
    "fixed": 10,
    "closed": 1,
    "wontFix": 0,
    "byDesign": 0,
    "unresolved": 4
  }
}
```

## Error Handling

**If required parameters missing:**
```text
❌ Missing required parameters

Usage: /ado-get-pr-threads <project> <repository> <pullRequestId> [options]

Options:
  --status <status>    Filter by status (active, fixed, closed, wontFix, byDesign, pending)
  --format <format>    Output format (detailed|summary) - default: detailed

Example:
  /ado-get-pr-threads "MyProject" "MyRepo" 123
  /ado-get-pr-threads "MyProject" "MyRepo" 123 --status active
```

**If credentials missing:**
```text
❌ Azure DevOps credentials not found

Please create ~/.azuredevops/credentials.json with:
{
  "serverUrl": "https://dev.azure.com",
  "collection": "your-org",
  "pat": "your-personal-access-token"
}
```

**If API request fails:**
- 401 Unauthorized: "Invalid or expired PAT"
- 404 Not Found: "Pull request '123' not found in repository 'MyRepo'"

Return error JSON:
```json
{
  "error": true,
  "message": "Pull request '123' not found in repository 'MyRepo'",
  "statusCode": 404,
  "pullRequestId": "123",
  "repository": "MyRepo"
}
```

## Notes

- **Thread structure:** Azure DevOps uses threads (not individual comments). Each thread can have multiple comments (replies)
- **Thread status values:**
  - `active` - Open, requires attention
  - `pending` - Awaiting response
  - `fixed` - Issue addressed
  - `closed` - Discussion closed
  - `wontFix` - Won't be addressed
  - `byDesign` - Intentional behavior
- **Unresolved count:** Sum of `active` + `pending` threads
- **File context:** Shows which file and line number(s) the thread references
- **Comment hierarchy:** Parent-child relationships shown with indentation (↳)
- **Performance:** Single API call fetches all threads with comments

## Use Cases

### View All Unresolved Comments
```bash
/ado-get-pr-threads "MyProject" "MyRepo" 123 --status active
```

### Quick Summary
```bash
/ado-get-pr-threads "MyProject" "MyRepo" 123 --format summary
```

### Before Addressing Feedback
```bash
# See what needs to be addressed
/ado-get-pr-threads "MyProject" "MyRepo" 123

# Fix issues
# ... make changes ...

# Reply to threads
/ado-reply-pr-thread "MyProject" "MyRepo" 123 4269 "Fixed - changed to Transient"

# Mark as fixed
/ado-resolve-pr-thread "MyProject" "MyRepo" 123 4269 --status fixed
```

### Monitor PR Review Progress
```bash
# Check overall status
/ado-get-pr-threads "MyProject" "MyRepo" 123 --format summary

# Deep dive into specific issues
/ado-get-pr-threads "MyProject" "MyRepo" 123 --status active
```

## Integration with Work System

### Deliver Workflow
```bash
# In /deliver command, before pushing updates
/ado-get-pr-threads "$project" "$repo" "$prId" --status active

# If unresolved threads exist, prompt:
# "⚠️  3 unresolved PR comments. Address them? [Y/n]"

# For each thread:
#   - Show thread context
#   - Agent makes fix
#   - /ado-reply-pr-thread with explanation
#   - /ado-resolve-pr-thread --status fixed
```

### Pattern Extraction (Phase 3)
```bash
# After PR merged, extract learnable patterns
/ado-get-pr-threads "$project" "$repo" "$prId"
/extract-review-patterns --source ado --pr "$prId"
```

## Related Commands

- `/ado-reply-pr-thread` - Reply to a thread (Phase 2)
- `/ado-resolve-pr-thread` - Update thread status (Phase 2)
- `/ado-comment-pr` - Create a new thread
- `/ado-get-pr` - Get PR details
- `/ado-get-pr-comments-structured` - Enhanced analysis (Phase 4)
- `/extract-review-patterns` - Learn from threads (Phase 3)

## Comparison with GitHub

| Feature | GitHub | Azure DevOps |
|---------|--------|--------------|
| **Container** | Comments, Reviews | Threads |
| **Replies** | Limited threading | Full thread support |
| **Status** | Resolved (unreliable) | active, fixed, closed, wontFix, byDesign, pending |
| **File context** | path, line | filePath, rightFileStart, rightFileEnd, iteration |
| **Command** | `/gh-get-pr-comments` | `/ado-get-pr-threads` |

## Future Enhancements

Phase 2 will add:
- `/ado-reply-pr-thread` - Reply to existing threads
- `/ado-resolve-pr-thread` - Change thread status

Phase 4 will add:
- `/ado-get-pr-comments-structured` - Group by file, categorize, extract patterns
- Pattern analysis for recurring feedback
