---
description: Get details of a single Azure DevOps pull request (helper)
allowedTools:
  - Bash
  - Read
---

# Azure DevOps API: Get Pull Request

Fetches complete details of a single pull request by ID.

## Usage

```bash
/ado-get-pr "MyProject" "MyRepo" 123
```

## Input Parameters

- **project** (required): Project name
- **repository** (required): Repository name
- **pullRequestId** (required): Pull request ID (numeric)

## Implementation

1. **Validate input:**

   ```bash
   project=$1
   repository=$2
   pullRequestId=$3

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

3. **Make API request:**

   ```bash
   auth=$(echo -n ":${pat}" | base64)

   curl -s \
     -H "Authorization: Basic ${auth}" \
     -H "Content-Type: application/json" \
     "${serverUrl}/${collection}/${project}/_apis/git/repositories/${repository}/pullrequests/${pullRequestId}?api-version=6.0"
   ```

4. **Parse response and format output:**

```json
{
  "pullRequest": {
    "pullRequestId": 123,
    "codeReviewId": 123,
    "status": "active",
    "createdBy": {
      "displayName": "John Doe",
      "uniqueName": "john.doe@company.com",
      "id": "user-guid",
      "imageUrl": "https://..."
    },
    "creationDate": "2025-01-14T10:00:00Z",
    "closedDate": null,
    "title": "Add user authentication feature",
    "description": "## Summary\n- Implements login functionality\n- Adds logout endpoint\n- Includes unit tests\n\n## Test Plan\n- [ ] Manual testing completed\n- [ ] Unit tests pass",
    "sourceRefName": "refs/heads/feature/auth",
    "targetRefName": "refs/heads/main",
    "mergeStatus": "succeeded",
    "mergeId": "merge-guid",
    "lastMergeSourceCommit": {
      "commitId": "abc123...",
      "url": "https://..."
    },
    "lastMergeTargetCommit": {
      "commitId": "def456...",
      "url": "https://..."
    },
    "isDraft": false,
    "supportsIterations": true,
    "reviewers": [
      {
        "displayName": "Jane Reviewer",
        "uniqueName": "jane.reviewer@company.com",
        "id": "reviewer-guid",
        "vote": 10,
        "isRequired": true,
        "isFlagged": false
      },
      {
        "displayName": "Build Service",
        "uniqueName": "build@company.com",
        "vote": 0,
        "isRequired": false
      }
    ],
    "labels": [
      {
        "id": "label-guid",
        "name": "bug-fix",
        "active": true
      }
    ],
    "completionOptions": {
      "mergeCommitMessage": "Merged PR 123: Add user authentication feature",
      "deleteSourceBranch": true,
      "squashMerge": false,
      "mergeStrategy": "noFastForward"
    },
    "autoCompleteSetBy": null,
    "repository": {
      "id": "repo-guid",
      "name": "MyRepo",
      "url": "https://...",
      "project": {
        "id": "project-guid",
        "name": "MyProject"
      }
    },
    "url": "https://azuredevops.discovertec.net/Link/_apis/git/repositories/MyRepo/pullRequests/123",
    "_links": {
      "web": {
        "href": "https://azuredevops.discovertec.net/Link/_git/MyRepo/pullrequest/123"
      },
      "workItems": {
        "href": "https://..."
      }
    }
  }
}
```

## Error Handling

**If required parameters missing:**

```text
Missing required parameters: project, repository, and pullRequestId

Usage: /ado-get-pr <project> <repository> <pullRequestId>
Example: /ado-get-pr "MyProject" "MyRepo" 123
```

**If credentials missing:**

```text
Azure DevOps credentials not found.

Please create ~/.azuredevops/credentials.json
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

- **Full details:** Includes reviewers, labels, completion options, and linked commits
- **Merge status values:**
  - `succeeded` - Can be merged
  - `conflicts` - Has merge conflicts
  - `rejectedByPolicy` - Blocked by branch policy
  - `queued` - Merge in progress
- **Vote values:** See ado-get-prs for vote meaning
- **Web link:** `_links.web.href` provides direct browser link to PR
- **Work items:** Use the workItems link to get associated work items
