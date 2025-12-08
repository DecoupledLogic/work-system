---
description: Query Azure DevOps work items using WIQL (helper)
allowedTools:
  - Bash
  - Read
---

# Azure DevOps API: Get Work Items

Queries work items using WIQL (Work Item Query Language) with optional filters.

## Usage

```bash
/ado-get-work-items "MyProject"
/ado-get-work-items "MyProject" "Task"
/ado-get-work-items "MyProject" "" "Active"
/ado-get-work-items "MyProject" "Bug" "Active" "user@email.com"
```

## Input Parameters

- **project** (required): Project name
- **workItemType** (optional): Task, Bug, User Story, Feature, Epic, etc.
- **state** (optional): Active, New, Closed, Resolved, Removed, etc.
- **assignedTo** (optional): User email or display name

## Implementation

1. **Validate input:**

   ```bash
   project=$1
   workItemType=${2:-""}
   state=${3:-""}
   assignedTo=${4:-""}

   if [ -z "$project" ]; then
     echo "Error: project required"
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

3. **Build WIQL query:**

   ```bash
   # Start with base query
   query="SELECT [System.Id], [System.Title], [System.State], [System.AssignedTo], [System.WorkItemType], [System.CreatedDate], [Microsoft.VSTS.Common.Priority] FROM WorkItems WHERE [System.TeamProject] = '${project}'"

   # Add optional filters
   if [ -n "$workItemType" ]; then
     query="$query AND [System.WorkItemType] = '${workItemType}'"
   fi

   if [ -n "$state" ]; then
     query="$query AND [System.State] = '${state}'"
   fi

   if [ -n "$assignedTo" ]; then
     query="$query AND [System.AssignedTo] = '${assignedTo}'"
   fi

   query="$query ORDER BY [System.ChangedDate] DESC"
   ```

4. **Make WIQL API request:**

   ```bash
   auth=$(echo -n ":${pat}" | base64)

   # Execute WIQL query to get work item IDs
   queryBody=$(jq -n --arg q "$query" '{"query": $q}')

   response=$(curl -s \
     -H "Authorization: Basic ${auth}" \
     -H "Content-Type: application/json" \
     -X POST \
     -d "$queryBody" \
     "${serverUrl}/${collection}/${project}/_apis/wit/wiql?api-version=6.0")
   ```

5. **Fetch work item details:**

   ```bash
   # Extract work item IDs from WIQL response
   ids=$(echo "$response" | jq -r '.workItems[].id' | tr '\n' ',' | sed 's/,$//')

   if [ -n "$ids" ]; then
     # Fetch details for all work items
     curl -s \
       -H "Authorization: Basic ${auth}" \
       -H "Content-Type: application/json" \
       "${serverUrl}/${collection}/_apis/wit/workitems?ids=${ids}&api-version=6.0"
   fi
   ```

6. **Parse response and format output:**

```json
{
  "count": 15,
  "workItems": [
    {
      "id": 12345,
      "rev": 3,
      "fields": {
        "System.Id": 12345,
        "System.Title": "Implement login feature",
        "System.State": "Active",
        "System.WorkItemType": "Task",
        "System.AssignedTo": {
          "displayName": "John Doe",
          "uniqueName": "john.doe@company.com"
        },
        "System.CreatedDate": "2025-01-10T09:00:00Z",
        "Microsoft.VSTS.Common.Priority": 2
      },
      "url": "https://azuredevops.discovertec.net/Link/_apis/wit/workItems/12345"
    }
  ]
}
```

## Error Handling

**If project not provided:**

```text
Missing required parameter: project

Usage: /ado-get-work-items <project> [workItemType] [state] [assignedTo]
Examples:
  /ado-get-work-items "MyProject"
  /ado-get-work-items "MyProject" "Task" "Active"
  /ado-get-work-items "MyProject" "" "" "user@email.com"

Use "" to skip optional parameters.
```

**If credentials missing:**

```text
Azure DevOps credentials not found.

Please create ~/.azuredevops/credentials.json
```

**If API request fails:**

- 401 Unauthorized: "Invalid or expired PAT"
- 404 Not Found: "Project 'MyProject' not found"
- 400 Bad Request: "Invalid WIQL query syntax"

Return error JSON:

```json
{
  "error": true,
  "message": "Project 'MyProject' not found",
  "statusCode": 404,
  "project": "MyProject"
}
```

## Notes

- **WIQL:** Work Item Query Language is SQL-like but for Azure DevOps
- **Two-step process:** First query for IDs, then batch fetch details
- **Max results:** WIQL returns up to 200 work items by default
- **Empty filters:** Use empty string "" to skip optional parameters
- **Field selection:** Query selects common fields; use ado-get-work-item for full details
- **Ordering:** Results ordered by most recently changed first
