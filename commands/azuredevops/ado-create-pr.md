---
description: Create a new Azure DevOps pull request (helper)
allowedTools:
  - Bash
  - Read
---

# Azure DevOps API: Create Pull Request

Creates a new pull request in an Azure DevOps repository.

## Usage

```bash
/ado-create-pr "feature/auth" "main" "Add authentication"
/ado-create-pr "feature/auth" "main" "Add authentication" "## Summary\n- New login flow"
/ado-create-pr "feature/auth" "main" "Add auth" "" --draft
/ado-create-pr "feature/auth" "main" "Add auth" "" --repo "MyRepo" --project "MyProject"
```

## Input Parameters

- **sourceBranch** (required): Source branch name (with or without `refs/heads/`)
- **targetBranch** (required): Target branch name (with or without `refs/heads/`)
- **title** (required): Pull request title
- **description** (optional): PR description (supports markdown)
- **--project** (optional): Override project from work-manager.yaml
- **--repo** (optional): Override repository (auto-detected from git remote if not specified)
- **--draft** (optional): Create as draft PR
- **--reviewers** (optional): Comma-separated reviewer emails
- **--work-items** (optional): Comma-separated work item IDs to link

## Implementation

1. **Parse input:**

   ```bash
   sourceBranch=$1
   targetBranch=$2
   title=$3
   description=${4:-""}

   # Parse flags
   isDraft=false
   reviewers=""
   workItems=""
   projectOverride=""
   repoOverride=""

   shift 4 2>/dev/null || shift $#
   while [[ $# -gt 0 ]]; do
     case $1 in
       --draft) isDraft=true; shift ;;
       --reviewers) reviewers="$2"; shift 2 ;;
       --work-items) workItems="$2"; shift 2 ;;
       --project) projectOverride="$2"; shift 2 ;;
       --repo) repoOverride="$2"; shift 2 ;;
       *) shift ;;
     esac
   done

   if [ -z "$sourceBranch" ] || [ -z "$targetBranch" ] || [ -z "$title" ]; then
     echo "Error: sourceBranch, targetBranch, and title are required"
     exit 1
   fi

   # Ensure refs/heads/ prefix
   [[ "$sourceBranch" != refs/heads/* ]] && sourceBranch="refs/heads/$sourceBranch"
   [[ "$targetBranch" != refs/heads/* ]] && targetBranch="refs/heads/$targetBranch"
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
   # Use override, then config, then fail
   project="${projectOverride:-$configProject}"
   if [ -z "$project" ]; then
     echo "Error: project not specified. Use --project or set in .claude/work-manager.yaml"
     exit 1
   fi

   # Use override, then config, then auto-detect from git
   repository="${repoOverride:-$configRepo}"
   if [ -z "$repository" ]; then
     # Auto-detect from git remote
     repository=$(git remote get-url origin 2>/dev/null | sed -E 's|.*[:/]([^/]+)/([^/.]+)(\.git)?$|\2|')
   fi
   if [ -z "$repository" ]; then
     echo "Error: repository not specified and could not auto-detect from git remote"
     exit 1
   fi
   ```

5. **Build request body:**

   ```bash
   # Start building JSON
   body=$(jq -n \
     --arg source "$sourceBranch" \
     --arg target "$targetBranch" \
     --arg title "$title" \
     --arg desc "$description" \
     --argjson isDraft "$isDraft" \
     '{
       sourceRefName: $source,
       targetRefName: $target,
       title: $title,
       description: $desc,
       isDraft: $isDraft
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
     "${serverUrl}/${collection}/${project}/_apis/git/repositories/${repository}/pullrequests?api-version=6.0")
   ```

7. **Add reviewers if specified:**

   ```bash
   if [ -n "$reviewers" ]; then
     prId=$(echo "$response" | jq -r '.pullRequestId')

     IFS=',' read -ra REVIEWERS <<< "$reviewers"
     for reviewer in "${REVIEWERS[@]}"; do
       # Get user ID from email (requires additional API call)
       # Then add reviewer
       curl -s \
         -H "Authorization: Basic ${auth}" \
         -H "Content-Type: application/json" \
         -X PUT \
         -d '{"vote": 0}' \
         "${serverUrl}/${collection}/${project}/_apis/git/repositories/${repository}/pullrequests/${prId}/reviewers/${reviewerId}?api-version=6.0"
     done
   fi
   ```

8. **Link work items if specified:**

   ```bash
   if [ -n "$workItems" ]; then
     prId=$(echo "$response" | jq -r '.pullRequestId')
     artifactId="vstfs:///Git/PullRequestId/${project}%2F${repository}%2F${prId}"

     IFS=',' read -ra ITEMS <<< "$workItems"
     for itemId in "${ITEMS[@]}"; do
       curl -s \
         -H "Authorization: Basic ${auth}" \
         -H "Content-Type: application/json-patch+json" \
         -X PATCH \
         -d "[{\"op\":\"add\",\"path\":\"/relations/-\",\"value\":{\"rel\":\"ArtifactLink\",\"url\":\"${artifactId}\",\"attributes\":{\"name\":\"Pull Request\"}}}]" \
         "${serverUrl}/${collection}/_apis/wit/workitems/${itemId}?api-version=6.0"
     done
   fi
   ```

9. **Parse response and format output:**

```json
{
  "pullRequest": {
    "pullRequestId": 456,
    "codeReviewId": 456,
    "status": "active",
    "createdBy": {
      "displayName": "John Doe",
      "uniqueName": "john.doe@company.com",
      "id": "user-guid"
    },
    "creationDate": "2025-01-15T10:00:00Z",
    "title": "Add authentication",
    "description": "## Summary\n- New login flow",
    "sourceRefName": "refs/heads/feature/auth",
    "targetRefName": "refs/heads/main",
    "mergeStatus": "queued",
    "isDraft": false,
    "repository": {
      "id": "repo-guid",
      "name": "MyRepo",
      "project": {
        "id": "project-guid",
        "name": "MyProject"
      }
    },
    "url": "https://azuredevops.discovertec.net/Link/_apis/git/repositories/MyRepo/pullRequests/456",
    "_links": {
      "web": {
        "href": "https://azuredevops.discovertec.net/Link/_git/MyRepo/pullrequest/456"
      }
    }
  }
}
```

## Error Handling

**If required parameters missing:**

```text
Missing required parameters.

Usage: /ado-create-pr <sourceBranch> <targetBranch> <title> [description] [options]

Options:
  --project "MyProject"      Override project from config
  --repo "MyRepo"            Override repository (auto-detected from git)
  --draft                    Create as draft PR
  --reviewers "a@x,b@y"      Add reviewers by email
  --work-items "123,456"     Link work items

Examples:
  /ado-create-pr "feature/auth" "main" "Add auth feature"
  /ado-create-pr "feature/auth" "main" "Add auth" "Description here" --draft
  /ado-create-pr "feature/auth" "main" "Add auth" "" --repo "other-repo"
```

**If credentials missing:**

```text
Azure DevOps credentials not found.

Please create ~/.azuredevops/credentials.json
```

**If API request fails:**

- 401 Unauthorized: "Invalid or expired PAT"
- 404 Not Found: "Repository 'MyRepo' not found"
- 409 Conflict: "Pull request already exists for this source branch"

Return error JSON:

```json
{
  "error": true,
  "message": "Pull request already exists for source branch 'feature/auth'",
  "statusCode": 409,
  "sourceBranch": "feature/auth",
  "targetBranch": "main"
}
```

## Notes

- **Repository auto-detect:** If not specified in config or `--repo`, extracts repo name from git remote origin
- **Multi-repo projects:** Works seamlessly - just run from within the microservice repo directory
- **Branch refs:** Automatically adds `refs/heads/` prefix if not provided
- **Draft PRs:** Use `--draft` flag to create PR in draft state
- **Reviewers:** Added as optional reviewers with vote=0 (no vote)
- **Work item linking:** Creates artifact links from work items to the PR
- **Merge status:** New PRs start with `queued` merge status while Azure evaluates mergeability
- **Web link:** `_links.web.href` provides direct browser link to PR
