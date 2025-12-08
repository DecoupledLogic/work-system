---
description: Update an existing Azure DevOps work item (helper)
allowedTools:
  - Bash
  - Read
---

# Azure DevOps API: Update Work Item

Updates fields on an existing work item.

## Usage

```bash
/ado-update-work-item 12345 --state "Active"
/ado-update-work-item 12345 --title "New Title"
/ado-update-work-item 12345 --priority 2
/ado-update-work-item 12345 --assigned-to "user@email.com"
/ado-update-work-item 12345 --state "Closed" --title "Updated Title" --priority 1
```

## Input Parameters

- **workItemId** (required): Work item ID (numeric, "ADO-" prefix stripped)
- **--title** (optional): New title
- **--state** (optional): New state (New, Active, Closed, Resolved, etc.)
- **--priority** (optional): New priority (1-4)
- **--assigned-to** (optional): Assign to user email
- **--description** (optional): New description
- **--area-path** (optional): New area path
- **--iteration-path** (optional): New iteration path

## Implementation

1. **Parse input:**

   ```bash
   workItemId=$1
   shift

   # Strip "ADO-" prefix if present
   workItemId=${workItemId#ADO-}

   # Parse named parameters
   title="" state="" priority="" assignedTo="" description=""
   areaPath="" iterationPath=""

   while [[ $# -gt 0 ]]; do
     case $1 in
       --title) title="$2"; shift 2 ;;
       --state) state="$2"; shift 2 ;;
       --priority) priority="$2"; shift 2 ;;
       --assigned-to) assignedTo="$2"; shift 2 ;;
       --description) description="$2"; shift 2 ;;
       --area-path) areaPath="$2"; shift 2 ;;
       --iteration-path) iterationPath="$2"; shift 2 ;;
       *) shift ;;
     esac
   done

   if [ -z "$workItemId" ]; then
     echo "Error: workItemId required"
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

3. **Build JSON patch document:**

   ```bash
   patchDoc='['
   first=true

   addPatch() {
     field=$1
     value=$2
     if [ "$first" = true ]; then
       first=false
     else
       patchDoc+=','
     fi
     patchDoc+='{"op":"replace","path":"/fields/'"$field"'","value":"'"$value"'"}'
   }

   [ -n "$title" ] && addPatch "System.Title" "$title"
   [ -n "$state" ] && addPatch "System.State" "$state"
   [ -n "$priority" ] && addPatch "Microsoft.VSTS.Common.Priority" "$priority"
   [ -n "$assignedTo" ] && addPatch "System.AssignedTo" "$assignedTo"
   [ -n "$description" ] && addPatch "System.Description" "$description"
   [ -n "$areaPath" ] && addPatch "System.AreaPath" "$areaPath"
   [ -n "$iterationPath" ] && addPatch "System.IterationPath" "$iterationPath"

   patchDoc+=']'
   ```

4. **Make API request:**

   ```bash
   auth=$(echo -n ":${pat}" | base64)

   curl -s \
     -H "Authorization: Basic ${auth}" \
     -H "Content-Type: application/json-patch+json" \
     -X PATCH \
     -d "$patchDoc" \
     "${serverUrl}/${collection}/_apis/wit/workitems/${workItemId}?api-version=6.0"
   ```

5. **Parse response and format output:**

```json
{
  "workItem": {
    "id": 12345,
    "rev": 6,
    "url": "https://azuredevops.discovertec.net/Link/_apis/wit/workItems/12345",
    "fields": {
      "System.Id": 12345,
      "System.Title": "New Title",
      "System.State": "Active",
      "System.WorkItemType": "Task",
      "Microsoft.VSTS.Common.Priority": 2,
      "System.ChangedDate": "2025-01-15T16:30:00Z",
      "System.ChangedBy": {
        "displayName": "API User",
        "uniqueName": "api.user@company.com"
      }
    },
    "_links": {
      "html": {
        "href": "https://azuredevops.discovertec.net/Link/_workitems/edit/12345"
      }
    }
  }
}
```

## Error Handling

**If workItemId not provided:**

```text
Missing required parameter: workItemId

Usage: /ado-update-work-item <workItemId> [options]
Options:
  --title "New Title"           Update title
  --state "Active"              Update state (New, Active, Closed, etc.)
  --priority 2                  Update priority (1-4)
  --assigned-to "user@email"    Assign to user
  --description "Description"   Update description
  --area-path "Project\\Team"   Update area path
  --iteration-path "Sprint 5"   Update iteration path

Examples:
  /ado-update-work-item 12345 --state "Active"
  /ado-update-work-item 12345 --title "New Title" --priority 1
```

**If credentials missing:**

```text
Azure DevOps credentials not found.

Please create ~/.azuredevops/credentials.json
```

**If API request fails:**

- 401 Unauthorized: "Invalid or expired PAT"
- 404 Not Found: "Work item '12345' not found"
- 400 Bad Request: "Invalid field value or state transition"

Return error JSON:

```json
{
  "error": true,
  "message": "Invalid state transition from 'Closed' to 'Active'",
  "statusCode": 400,
  "workItemId": "12345"
}
```

## Notes

- **JSON Patch:** Uses PATCH method with JSON Patch format
- **State transitions:** Not all state transitions are valid (depends on process template)
- **Revision:** Each update increments the revision number
- **Partial updates:** Only specified fields are updated
- **Change tracking:** Azure DevOps tracks who made each change
- **Area/Iteration paths:** Use backslash (\\) for path separators
