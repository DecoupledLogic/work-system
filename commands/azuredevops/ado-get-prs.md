---
description: List Azure DevOps pull requests in a repository (helper)
allowedTools:
  - Bash
  - Read
---

# Azure DevOps API: Get Pull Requests

Lists pull requests in a repository with optional filtering.

## Usage

```bash
/ado-get-prs "MyProject" "MyRepo"
/ado-get-prs "MyProject" "MyRepo" "completed"
/ado-get-prs "MyProject" "MyRepo" "active" "user@email.com"
/ado-get-prs "MyProject" "MyRepo" "" "" "refs/heads/main"
```

## Input Parameters

- **project** (required): Project name
- **repository** (required): Repository name
- **status** (optional): Filter by status
  - `active` (default) - Open PRs
  - `completed` - Merged PRs
  - `abandoned` - Closed without merge
  - `all` - All PRs
- **creatorId** (optional): Filter by creator email
- **targetRefName** (optional): Filter by target branch (e.g., refs/heads/main)

## Implementation

1. **Validate input:**

   ```bash
   project=$1
   repository=$2
   status=${3:-active}
   creatorId=${4:-""}
   targetRefName=${5:-""}

   if [ -z "$project" ] || [ -z "$repository" ]; then
     echo "Error: project and repository are required"
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

3. **Build query parameters:**

   ```bash
   queryParams="searchCriteria.status=${status}"

   if [ -n "$creatorId" ]; then
     queryParams+="&searchCriteria.creatorId=${creatorId}"
   fi

   if [ -n "$targetRefName" ]; then
     encodedRef=$(echo "$targetRefName" | jq -sRr @uri)
     queryParams+="&searchCriteria.targetRefName=${encodedRef}"
   fi
   ```

4. **Make API request:**

   ```bash
   auth=$(echo -n ":${pat}" | base64)

   curl -s \
     -H "Authorization: Basic ${auth}" \
     -H "Content-Type: application/json" \
     "${serverUrl}/${collection}/${project}/_apis/git/repositories/${repository}/pullrequests?${queryParams}&api-version=6.0"
   ```

5. **Parse response and format output:**

```json
{
  "count": 5,
  "pullRequests": [
    {
      "pullRequestId": 123,
      "codeReviewId": 123,
      "status": "active",
      "createdBy": {
        "displayName": "John Doe",
        "uniqueName": "john.doe@company.com",
        "id": "user-guid"
      },
      "creationDate": "2025-01-14T10:00:00Z",
      "title": "Add user authentication feature",
      "description": "Implements login and logout functionality",
      "sourceRefName": "refs/heads/feature/auth",
      "targetRefName": "refs/heads/main",
      "mergeStatus": "succeeded",
      "isDraft": false,
      "reviewers": [
        {
          "displayName": "Jane Reviewer",
          "uniqueName": "jane.reviewer@company.com",
          "vote": 10,
          "isRequired": true
        }
      ],
      "url": "https://azuredevops.discovertec.net/Link/_apis/git/repositories/MyRepo/pullRequests/123",
      "repository": {
        "id": "repo-guid",
        "name": "MyRepo",
        "project": {
          "id": "project-guid",
          "name": "MyProject"
        }
      }
    }
  ]
}
```

## Reviewer Vote Values

| Vote | Meaning |
|------|---------|
| 10 | Approved |
| 5 | Approved with suggestions |
| 0 | No vote |
| -5 | Waiting for author |
| -10 | Rejected |

## Error Handling

**If required parameters missing:**

```text
Missing required parameters: project and repository

Usage: /ado-get-prs <project> <repository> [status] [creatorId] [targetRefName]
Examples:
  /ado-get-prs "MyProject" "MyRepo"
  /ado-get-prs "MyProject" "MyRepo" "completed"
  /ado-get-prs "MyProject" "MyRepo" "active" "user@email.com"
  /ado-get-prs "MyProject" "MyRepo" "" "" "refs/heads/main"

Status: active (default), completed, abandoned, all
```

**If credentials missing:**

```text
Azure DevOps credentials not found.

Please create ~/.azuredevops/credentials.json
```

**If API request fails:**

- 401 Unauthorized: "Invalid or expired PAT"
- 404 Not Found: "Repository 'MyRepo' not found in project 'MyProject'"

Return error JSON:

```json
{
  "error": true,
  "message": "Repository 'MyRepo' not found in project 'MyProject'",
  "statusCode": 404,
  "project": "MyProject",
  "repository": "MyRepo"
}
```

## Notes

- **Default status:** Returns only active (open) PRs by default
- **Branch names:** Use full ref name format (refs/heads/branch-name)
- **Pagination:** Returns up to 101 PRs by default; use $top and $skip for more
- **Merge status:** `succeeded`, `conflicts`, `rejectedByPolicy`, `queued`
- **Draft PRs:** isDraft=true indicates work-in-progress PRs
