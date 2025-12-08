---
description: Complete/merge an Azure DevOps pull request (helper)
allowedTools:
  - Bash
  - Read
---

# Azure DevOps API: Merge Pull Request

Completes (merges) an approved pull request.

## Usage

```bash
/ado-merge-pr "MyProject" "MyRepo" 123
/ado-merge-pr "MyProject" "MyRepo" 123 --squash
/ado-merge-pr "MyProject" "MyRepo" 123 --delete-branch
/ado-merge-pr "MyProject" "MyRepo" 123 --squash --delete-branch
/ado-merge-pr "MyProject" "MyRepo" 123 --message "Merged PR 123: Add auth feature"
/ado-merge-pr "MyProject" "MyRepo" 123 --bypass-policy --bypass-reason "Emergency fix"
```

## Input Parameters

- **project** (required): Project name
- **repository** (required): Repository name
- **pullRequestId** (required): Pull request ID (numeric)
- **--squash** (optional): Squash commits into single commit
- **--rebase** (optional): Rebase instead of merge
- **--delete-branch** (optional): Delete source branch after merge
- **--message** (optional): Custom merge commit message
- **--bypass-policy** (optional): Bypass branch policies (requires permission)
- **--bypass-reason** (optional): Reason for bypassing policies

## Implementation

1. **Parse input:**

   ```bash
   project=$1
   repository=$2
   pullRequestId=$3
   shift 3

   # Parse flags
   mergeStrategy="noFastForward"
   deleteSource=false
   mergeMessage=""
   bypassPolicy=false
   bypassReason=""

   while [[ $# -gt 0 ]]; do
     case $1 in
       --squash) mergeStrategy="squash"; shift ;;
       --rebase) mergeStrategy="rebase"; shift ;;
       --delete-branch) deleteSource=true; shift ;;
       --message) mergeMessage="$2"; shift 2 ;;
       --bypass-policy) bypassPolicy=true; shift ;;
       --bypass-reason) bypassReason="$2"; shift 2 ;;
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
   auth=$(echo -n ":${pat}" | base64)
   ```

3. **Get PR details to verify status and get last merge source commit:**

   ```bash
   pr=$(curl -s \
     -H "Authorization: Basic ${auth}" \
     "${serverUrl}/${collection}/${project}/_apis/git/repositories/${repository}/pullrequests/${pullRequestId}?api-version=6.0")

   status=$(echo "$pr" | jq -r '.status')
   if [ "$status" != "active" ]; then
     echo "Error: Pull request is not active (status: $status)"
     exit 1
   fi

   lastMergeSourceCommit=$(echo "$pr" | jq -r '.lastMergeSourceCommit.commitId')
   ```

4. **Build completion body:**

   ```bash
   # Get default merge message if not provided
   if [ -z "$mergeMessage" ]; then
     title=$(echo "$pr" | jq -r '.title')
     mergeMessage="Merged PR ${pullRequestId}: ${title}"
   fi

   # Build completion options
   completionOptions=$(jq -n \
     --arg strategy "$mergeStrategy" \
     --argjson deleteSource "$deleteSource" \
     --arg message "$mergeMessage" \
     --argjson bypass "$bypassPolicy" \
     --arg reason "$bypassReason" \
     '{
       mergeStrategy: $strategy,
       deleteSourceBranch: $deleteSource,
       mergeCommitMessage: $message,
       bypassPolicy: $bypass,
       bypassReason: (if $bypass then $reason else null end)
     }')

   # Build update body to complete PR
   body=$(jq -n \
     --arg commitId "$lastMergeSourceCommit" \
     --argjson opts "$completionOptions" \
     '{
       status: "completed",
       lastMergeSourceCommit: {commitId: $commitId},
       completionOptions: $opts
     }')
   ```

5. **Make API request:**

   ```bash
   curl -s \
     -H "Authorization: Basic ${auth}" \
     -H "Content-Type: application/json" \
     -X PATCH \
     -d "$body" \
     "${serverUrl}/${collection}/${project}/_apis/git/repositories/${repository}/pullrequests/${pullRequestId}?api-version=6.0"
   ```

6. **Parse response and format output:**

```json
{
  "pullRequest": {
    "pullRequestId": 123,
    "status": "completed",
    "closedDate": "2025-01-15T16:00:00Z",
    "closedBy": {
      "displayName": "John Doe",
      "uniqueName": "john.doe@company.com",
      "id": "user-guid"
    },
    "title": "Add user authentication feature",
    "sourceRefName": "refs/heads/feature/auth",
    "targetRefName": "refs/heads/main",
    "mergeStatus": "succeeded",
    "mergeId": "merge-guid",
    "lastMergeCommit": {
      "commitId": "abc123def456...",
      "url": "https://..."
    },
    "completionOptions": {
      "mergeCommitMessage": "Merged PR 123: Add user authentication feature",
      "deleteSourceBranch": true,
      "squashMerge": false,
      "mergeStrategy": "noFastForward"
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

Usage: /ado-merge-pr <project> <repository> <pullRequestId> [options]

Options:
  --squash               Squash commits into single commit
  --rebase               Rebase instead of merge
  --delete-branch        Delete source branch after merge
  --message "msg"        Custom merge commit message
  --bypass-policy        Bypass branch policies (requires permission)
  --bypass-reason "why"  Reason for bypassing policies

Examples:
  /ado-merge-pr "MyProject" "MyRepo" 123
  /ado-merge-pr "MyProject" "MyRepo" 123 --squash --delete-branch
  /ado-merge-pr "MyProject" "MyRepo" 123 --message "feat: add authentication"
```

**If credentials missing:**

```text
Azure DevOps credentials not found.

Please create ~/.azuredevops/credentials.json
```

**If API request fails:**

- 401 Unauthorized: "Invalid or expired PAT"
- 404 Not Found: "Pull request '123' not found"
- 409 Conflict: "Pull request has merge conflicts"
- 400 Bad Request: "Pull request does not meet policy requirements"

Return error JSON:

```json
{
  "error": true,
  "message": "Pull request does not meet policy requirements: Minimum 2 reviewers required",
  "statusCode": 400,
  "pullRequestId": "123",
  "policyFailures": [
    "Minimum number of reviewers (2 required, 1 approved)",
    "Build validation failed"
  ]
}
```

## Notes

- **Prerequisites:** PR must be approved and pass all policies (unless bypassing)
- **Merge strategies:**
  - `noFastForward` - Create merge commit (default)
  - `squash` - Squash all commits into one
  - `rebase` - Rebase source commits onto target
  - `rebaseMerge` - Rebase then create merge commit
- **Source branch:** Use `--delete-branch` to clean up after merge
- **Policy bypass:** Requires "Bypass policies when completing pull requests" permission
- **Merge conflicts:** Cannot complete if conflicts exist
- **Status transition:** PR moves from `active` to `completed`
- **Last merge commit:** The API validates against the commit ID to prevent race conditions
