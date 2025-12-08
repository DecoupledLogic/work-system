---
description: Update an existing Azure DevOps pull request (helper)
allowedTools:
  - Bash
  - Read
---

# Azure DevOps API: Update Pull Request

Updates properties of an existing pull request.

## Usage

```bash
/ado-update-pr "MyProject" "MyRepo" 123 --title "New title"
/ado-update-pr "MyProject" "MyRepo" 123 --description "Updated description"
/ado-update-pr "MyProject" "MyRepo" 123 --target-branch "develop"
/ado-update-pr "MyProject" "MyRepo" 123 --draft true
/ado-update-pr "MyProject" "MyRepo" 123 --title "New title" --description "New desc"
```

## Input Parameters

- **project** (required): Project name
- **repository** (required): Repository name
- **pullRequestId** (required): Pull request ID (numeric)
- **--title** (optional): New title
- **--description** (optional): New description
- **--target-branch** (optional): New target branch
- **--draft** (optional): Set draft status (true/false)
- **--auto-complete** (optional): Enable auto-complete (true/false)
- **--merge-strategy** (optional): Set merge strategy (noFastForward, squash, rebase, rebaseMerge)
- **--delete-source** (optional): Delete source branch after merge (true/false)

## Implementation

1. **Parse input:**

   ```bash
   project=$1
   repository=$2
   pullRequestId=$3
   shift 3

   # Parse named parameters
   title="" description="" targetBranch="" isDraft=""
   autoComplete="" mergeStrategy="" deleteSource=""

   while [[ $# -gt 0 ]]; do
     case $1 in
       --title) title="$2"; shift 2 ;;
       --description) description="$2"; shift 2 ;;
       --target-branch) targetBranch="$2"; shift 2 ;;
       --draft) isDraft="$2"; shift 2 ;;
       --auto-complete) autoComplete="$2"; shift 2 ;;
       --merge-strategy) mergeStrategy="$2"; shift 2 ;;
       --delete-source) deleteSource="$2"; shift 2 ;;
       *) shift ;;
     esac
   done

   if [ -z "$project" ] || [ -z "$repository" ] || [ -z "$pullRequestId" ]; then
     echo "Error: project, repository, and pullRequestId are required"
     exit 1
   fi
   ```

2. **Read credentials:**

   ```bash
   credentials=$(cat ~/.azuredevops/credentials.json)
   serverUrl=$(echo "$credentials" | jq -r '.serverUrl')
   collection=$(echo "$credentials" | jq -r '.collection')
   pat=$(echo "$credentials" | jq -r '.pat')
   ```

3. **Build update body:**

   ```bash
   # Build JSON object with only provided fields
   body='{}'

   [ -n "$title" ] && body=$(echo "$body" | jq --arg v "$title" '. + {title: $v}')
   [ -n "$description" ] && body=$(echo "$body" | jq --arg v "$description" '. + {description: $v}')
   [ -n "$targetBranch" ] && body=$(echo "$body" | jq --arg v "refs/heads/$targetBranch" '. + {targetRefName: $v}')
   [ -n "$isDraft" ] && body=$(echo "$body" | jq --argjson v "$isDraft" '. + {isDraft: $v}')

   # Handle auto-complete settings
   if [ -n "$autoComplete" ] || [ -n "$mergeStrategy" ] || [ -n "$deleteSource" ]; then
     completionOptions='{}'
     [ -n "$mergeStrategy" ] && completionOptions=$(echo "$completionOptions" | jq --arg v "$mergeStrategy" '. + {mergeStrategy: $v}')
     [ -n "$deleteSource" ] && completionOptions=$(echo "$completionOptions" | jq --argjson v "$deleteSource" '. + {deleteSourceBranch: $v}')
     body=$(echo "$body" | jq --argjson opts "$completionOptions" '. + {completionOptions: $opts}')

     if [ "$autoComplete" = "true" ]; then
       # Get current user ID for autoCompleteSetBy
       userId=$(curl -s -H "Authorization: Basic $(echo -n ":${pat}" | base64)" \
         "${serverUrl}/${collection}/_apis/connectionData" | jq -r '.authenticatedUser.id')
       body=$(echo "$body" | jq --arg id "$userId" '. + {autoCompleteSetBy: {id: $id}}')
     elif [ "$autoComplete" = "false" ]; then
       body=$(echo "$body" | jq '. + {autoCompleteSetBy: null}')
     fi
   fi
   ```

4. **Make API request:**

   ```bash
   auth=$(echo -n ":${pat}" | base64)

   curl -s \
     -H "Authorization: Basic ${auth}" \
     -H "Content-Type: application/json" \
     -X PATCH \
     -d "$body" \
     "${serverUrl}/${collection}/${project}/_apis/git/repositories/${repository}/pullrequests/${pullRequestId}?api-version=6.0"
   ```

5. **Parse response and format output:**

```json
{
  "pullRequest": {
    "pullRequestId": 123,
    "status": "active",
    "title": "New title",
    "description": "Updated description",
    "sourceRefName": "refs/heads/feature/auth",
    "targetRefName": "refs/heads/main",
    "isDraft": false,
    "autoCompleteSetBy": {
      "displayName": "John Doe",
      "id": "user-guid"
    },
    "completionOptions": {
      "mergeStrategy": "squash",
      "deleteSourceBranch": true
    },
    "url": "https://azuredevops.discovertec.net/Link/_apis/git/repositories/MyRepo/pullRequests/123",
    "_links": {
      "web": {
        "href": "https://azuredevops.discovertec.net/Link/_git/MyRepo/pullrequest/123"
      }
    }
  }
}
```

## Error Handling

**If required parameters missing:**

```text
Missing required parameters: project, repository, and pullRequestId

Usage: /ado-update-pr <project> <repository> <pullRequestId> [options]

Options:
  --title "New Title"           Update title
  --description "Description"   Update description
  --target-branch "develop"     Change target branch
  --draft true|false            Set draft status
  --auto-complete true|false    Enable/disable auto-complete
  --merge-strategy <strategy>   Set merge strategy
  --delete-source true|false    Delete source branch after merge

Merge strategies: noFastForward, squash, rebase, rebaseMerge

Examples:
  /ado-update-pr "MyProject" "MyRepo" 123 --title "Updated title"
  /ado-update-pr "MyProject" "MyRepo" 123 --auto-complete true --merge-strategy squash
```

**If credentials missing:**

```text
Azure DevOps credentials not found.

Please create ~/.azuredevops/credentials.json
```

**If API request fails:**

- 401 Unauthorized: "Invalid or expired PAT"
- 404 Not Found: "Pull request '123' not found"
- 400 Bad Request: "Cannot update completed pull request"

Return error JSON:

```json
{
  "error": true,
  "message": "Cannot update completed pull request",
  "statusCode": 400,
  "pullRequestId": "123"
}
```

## Notes

- **Partial updates:** Only specified fields are updated
- **Target branch:** Can change target branch (requires `refs/heads/` prefix, auto-added)
- **Draft toggle:** Use `--draft false` to publish a draft PR
- **Auto-complete:** When enabled, PR will auto-merge when all policies pass
- **Merge strategies:**
  - `noFastForward` - Create merge commit (default)
  - `squash` - Squash all commits into one
  - `rebase` - Rebase source onto target
  - `rebaseMerge` - Rebase and create merge commit
- **Completion options:** Only apply when PR is completed/merged
