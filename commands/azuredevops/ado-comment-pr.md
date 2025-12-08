---
description: Add a comment to an Azure DevOps pull request (helper)
allowedTools:
  - Bash
  - Read
---

# Azure DevOps API: Comment on Pull Request

Adds a comment thread to a pull request.

## Usage

```bash
/ado-comment-pr "MyProject" "MyRepo" 123 "Great work on this implementation!"
/ado-comment-pr "MyProject" "MyRepo" 123 "Please fix this" --status active
/ado-comment-pr "MyProject" "MyRepo" 123 "Code review comment" --file "src/auth.ts" --line 42
/ado-comment-pr "MyProject" "MyRepo" 123 "Suggestion" --file "src/auth.ts" --line 42 --line-end 45
```

## Input Parameters

- **project** (required): Project name
- **repository** (required): Repository name
- **pullRequestId** (required): Pull request ID (numeric)
- **comment** (required): Comment text (supports markdown)
- **--status** (optional): Thread status (active, fixed, wontFix, closed, byDesign, pending)
- **--file** (optional): File path for inline comment
- **--line** (optional): Line number for inline comment
- **--line-end** (optional): End line for multi-line comment
- **--iteration** (optional): PR iteration number (default: latest)

## Implementation

1. **Parse input:**

   ```bash
   project=$1
   repository=$2
   pullRequestId=$3
   comment=$4
   shift 4

   # Parse named parameters
   status="active"
   filePath="" lineNumber="" lineEnd="" iteration=""

   while [[ $# -gt 0 ]]; do
     case $1 in
       --status) status="$2"; shift 2 ;;
       --file) filePath="$2"; shift 2 ;;
       --line) lineNumber="$2"; shift 2 ;;
       --line-end) lineEnd="$2"; shift 2 ;;
       --iteration) iteration="$2"; shift 2 ;;
       *) shift ;;
     esac
   done

   if [ -z "$project" ] || [ -z "$repository" ] || [ -z "$pullRequestId" ] || [ -z "$comment" ]; then
     echo "Error: project, repository, pullRequestId, and comment are required"
     exit 1
   fi
   ```

2. **Read credentials:**

   ```bash
   credentials=$(cat ~/.azuredevops/credentials.json)
   serverUrl=$(echo "$credentials" | jq -r '.serverUrl')
   collection=$(echo "$credentials" | jq -r '.collection')
   pat=$(echo "$credentials" | jq -r '.pat')
   auth=$(echo -n ":${pat}" | base64)
   ```

3. **Get latest iteration if needed for file comments:**

   ```bash
   if [ -n "$filePath" ] && [ -z "$iteration" ]; then
     iterations=$(curl -s \
       -H "Authorization: Basic ${auth}" \
       "${serverUrl}/${collection}/${project}/_apis/git/repositories/${repository}/pullrequests/${pullRequestId}/iterations?api-version=6.0")
     iteration=$(echo "$iterations" | jq -r '.value | last | .id')
   fi
   ```

4. **Build request body:**

   ```bash
   # Build comment object
   commentObj=$(jq -n --arg content "$comment" '{content: $content, commentType: "text"}')

   # Build thread object
   threadObj=$(jq -n \
     --argjson comments "[$commentObj]" \
     --arg status "$status" \
     '{comments: $comments, status: $status}')

   # Add thread context for file comments
   if [ -n "$filePath" ]; then
     rightFileEnd=${lineEnd:-$lineNumber}
     threadContext=$(jq -n \
       --arg file "$filePath" \
       --argjson line "$lineNumber" \
       --argjson lineEnd "$rightFileEnd" \
       '{
         filePath: $file,
         rightFileStart: {line: $line, offset: 1},
         rightFileEnd: {line: $lineEnd, offset: 1}
       }')
     threadObj=$(echo "$threadObj" | jq --argjson ctx "$threadContext" '. + {threadContext: $ctx}')

     # Add pull request thread context
     prContext=$(jq -n \
       --argjson iter "$iteration" \
       '{iterationContext: {firstComparingIteration: $iter, secondComparingIteration: $iter}}')
     threadObj=$(echo "$threadObj" | jq --argjson ctx "$prContext" '. + {pullRequestThreadContext: $ctx}')
   fi
   ```

5. **Make API request:**

   ```bash
   curl -s \
     -H "Authorization: Basic ${auth}" \
     -H "Content-Type: application/json" \
     -X POST \
     -d "$threadObj" \
     "${serverUrl}/${collection}/${project}/_apis/git/repositories/${repository}/pullrequests/${pullRequestId}/threads?api-version=6.0"
   ```

6. **Parse response and format output:**

```json
{
  "thread": {
    "id": 789,
    "publishedDate": "2025-01-15T14:30:00Z",
    "lastUpdatedDate": "2025-01-15T14:30:00Z",
    "status": "active",
    "threadContext": {
      "filePath": "/src/auth.ts",
      "rightFileStart": {
        "line": 42,
        "offset": 1
      },
      "rightFileEnd": {
        "line": 45,
        "offset": 1
      }
    },
    "comments": [
      {
        "id": 1,
        "parentCommentId": 0,
        "author": {
          "displayName": "John Doe",
          "uniqueName": "john.doe@company.com",
          "id": "user-guid"
        },
        "content": "Please fix this",
        "publishedDate": "2025-01-15T14:30:00Z",
        "commentType": "text"
      }
    ],
    "isDeleted": false,
    "_links": {
      "self": {
        "href": "https://azuredevops.discovertec.net/Link/_apis/git/repositories/MyRepo/pullRequests/123/threads/789"
      }
    }
  }
}
```

## Error Handling

**If required parameters missing:**

```text
Missing required parameters: project, repository, pullRequestId, and comment

Usage: /ado-comment-pr <project> <repository> <pullRequestId> <comment> [options]

Options:
  --status <status>           Thread status (active, fixed, wontFix, closed, byDesign, pending)
  --file "path/to/file.ts"    File path for inline comment
  --line 42                   Line number for inline comment
  --line-end 45               End line for multi-line comment
  --iteration 3               PR iteration number

Examples:
  /ado-comment-pr "MyProject" "MyRepo" 123 "LGTM!"
  /ado-comment-pr "MyProject" "MyRepo" 123 "Fix this bug" --status active
  /ado-comment-pr "MyProject" "MyRepo" 123 "Consider refactoring" --file "src/auth.ts" --line 42
```

**If credentials missing:**

```text
Azure DevOps credentials not found.

Please create ~/.azuredevops/credentials.json
```

**If API request fails:**

- 401 Unauthorized: "Invalid or expired PAT"
- 404 Not Found: "Pull request '123' not found"
- 400 Bad Request: "Invalid file path or line number"

Return error JSON:

```json
{
  "error": true,
  "message": "File '/src/auth.ts' not found in pull request",
  "statusCode": 400,
  "pullRequestId": "123",
  "filePath": "/src/auth.ts"
}
```

## Notes

- **Thread vs comment:** Azure DevOps uses threads which can contain multiple comments (replies)
- **Status values:**
  - `active` - Open discussion requiring attention
  - `fixed` - Issue has been addressed
  - `wontFix` - Issue will not be addressed
  - `closed` - Thread closed
  - `byDesign` - Behavior is intentional
  - `pending` - Awaiting response
- **Inline comments:** Requires `--file` and `--line` to attach to specific code
- **Multi-line:** Use `--line-end` to highlight a range of lines
- **Iteration:** For file comments, uses latest iteration by default
- **Markdown:** Comment content supports markdown formatting
