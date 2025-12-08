---
description: Approve or vote on an Azure DevOps pull request (helper)
allowedTools:
  - Bash
  - Read
---

# Azure DevOps API: Approve Pull Request

Submits a vote (approval, rejection, or other status) on a pull request.

## Usage

```bash
/ado-approve-pr "MyProject" "MyRepo" 123
/ado-approve-pr "MyProject" "MyRepo" 123 --approve
/ado-approve-pr "MyProject" "MyRepo" 123 --approve-with-suggestions
/ado-approve-pr "MyProject" "MyRepo" 123 --wait-for-author
/ado-approve-pr "MyProject" "MyRepo" 123 --reject
/ado-approve-pr "MyProject" "MyRepo" 123 --reset
```

## Input Parameters

- **project** (required): Project name
- **repository** (required): Repository name
- **pullRequestId** (required): Pull request ID (numeric)
- **--approve** (optional): Approve the PR (vote = 10) - default if no flag
- **--approve-with-suggestions** (optional): Approve with suggestions (vote = 5)
- **--wait-for-author** (optional): Wait for author response (vote = -5)
- **--reject** (optional): Reject the PR (vote = -10)
- **--reset** (optional): Reset vote (vote = 0)

## Vote Values

| Vote | Meaning | Flag |
|------|---------|------|
| 10 | Approved | `--approve` |
| 5 | Approved with suggestions | `--approve-with-suggestions` |
| 0 | No vote / Reset | `--reset` |
| -5 | Waiting for author | `--wait-for-author` |
| -10 | Rejected | `--reject` |

## Implementation

1. **Parse input:**

   ```bash
   project=$1
   repository=$2
   pullRequestId=$3
   shift 3

   # Default to approve
   vote=10

   while [[ $# -gt 0 ]]; do
     case $1 in
       --approve) vote=10; shift ;;
       --approve-with-suggestions) vote=5; shift ;;
       --wait-for-author) vote=-5; shift ;;
       --reject) vote=-10; shift ;;
       --reset) vote=0; shift ;;
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

3. **Get current user ID:**

   ```bash
   # Get authenticated user's ID
   connectionData=$(curl -s \
     -H "Authorization: Basic ${auth}" \
     "${serverUrl}/${collection}/_apis/connectionData")

   userId=$(echo "$connectionData" | jq -r '.authenticatedUser.id')
   ```

4. **Build request body:**

   ```bash
   body=$(jq -n --argjson vote "$vote" '{vote: $vote}')
   ```

5. **Make API request:**

   ```bash
   curl -s \
     -H "Authorization: Basic ${auth}" \
     -H "Content-Type: application/json" \
     -X PUT \
     -d "$body" \
     "${serverUrl}/${collection}/${project}/_apis/git/repositories/${repository}/pullrequests/${pullRequestId}/reviewers/${userId}?api-version=6.0"
   ```

6. **Parse response and format output:**

```json
{
  "reviewer": {
    "id": "user-guid",
    "displayName": "John Doe",
    "uniqueName": "john.doe@company.com",
    "imageUrl": "https://...",
    "vote": 10,
    "hasDeclined": false,
    "isRequired": false,
    "isFlagged": false,
    "_links": {
      "avatar": {
        "href": "https://..."
      }
    }
  },
  "pullRequest": {
    "pullRequestId": 123,
    "title": "Add user authentication feature",
    "status": "active",
    "reviewers": [
      {
        "displayName": "John Doe",
        "vote": 10,
        "isRequired": false
      },
      {
        "displayName": "Jane Smith",
        "vote": 0,
        "isRequired": true
      }
    ]
  }
}
```

## Error Handling

**If required parameters missing:**

```text
Missing required parameters: project, repository, and pullRequestId

Usage: /ado-approve-pr <project> <repository> <pullRequestId> [options]

Options:
  --approve                  Approve (vote = 10) - default
  --approve-with-suggestions Approve with suggestions (vote = 5)
  --wait-for-author          Request changes (vote = -5)
  --reject                   Reject (vote = -10)
  --reset                    Reset vote (vote = 0)

Vote meanings:
   10 = Approved
    5 = Approved with suggestions
    0 = No vote
   -5 = Waiting for author
  -10 = Rejected

Examples:
  /ado-approve-pr "MyProject" "MyRepo" 123
  /ado-approve-pr "MyProject" "MyRepo" 123 --approve-with-suggestions
  /ado-approve-pr "MyProject" "MyRepo" 123 --reject
```

**If credentials missing:**

```text
Azure DevOps credentials not found.

Please create ~/.azuredevops/credentials.json
```

**If API request fails:**

- 401 Unauthorized: "Invalid or expired PAT"
- 404 Not Found: "Pull request '123' not found"
- 400 Bad Request: "Cannot vote on completed pull request"

Return error JSON:

```json
{
  "error": true,
  "message": "Cannot vote on completed pull request",
  "statusCode": 400,
  "pullRequestId": "123"
}
```

## Notes

- **Default action:** Running without flags defaults to `--approve` (vote = 10)
- **Self-approval:** You can vote on your own PR (useful for closing without merge)
- **Change vote:** Submitting a new vote replaces your previous vote
- **Required reviewers:** Some reviewers may be required by branch policies
- **Vote visibility:** All votes are visible to PR participants
- **Policy requirements:** Some policies require minimum approvals before merge
- **Rejected PRs:** A rejection (vote = -10) typically blocks completion until resolved
