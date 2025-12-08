---
description: Get details of a single Azure DevOps work item (helper)
allowedTools:
  - Bash
  - Read
---

# Azure DevOps API: Get Work Item

Fetches complete details of a single work item by ID.

## Usage

```bash
/ado-get-work-item 12345
/ado-get-work-item ADO-12345
```

## Input Parameters

- **workItemId** (required): Work item ID (numeric only, "ADO-" prefix is stripped)

## Implementation

1. **Validate input:**

   ```bash
   workItemId=$1

   if [ -z "$workItemId" ]; then
     echo "Error: workItemId required"
     exit 1
   fi

   # Strip "ADO-" prefix if present
   workItemId=${workItemId#ADO-}
   ```

2. **Read credentials:**

   ```bash
   credentials=$(cat ~/.azuredevops/credentials.json)
   serverUrl=$(echo "$credentials" | jq -r '.serverUrl')
   collection=$(echo "$credentials" | jq -r '.collection')
   pat=$(echo "$credentials" | jq -r '.pat')
   ```

3. **Create auth header:**

   ```bash
   auth=$(echo -n ":${pat}" | base64)
   ```

4. **Make API request:**

   ```bash
   curl -s \
     -H "Authorization: Basic ${auth}" \
     -H "Content-Type: application/json" \
     "${serverUrl}/${collection}/_apis/wit/workitems/${workItemId}?\$expand=all&api-version=6.0"
   ```

5. **Parse response and format output:**

```json
{
  "workItem": {
    "id": 12345,
    "rev": 5,
    "url": "https://azuredevops.discovertec.net/Link/_apis/wit/workItems/12345",
    "fields": {
      "System.Id": 12345,
      "System.Title": "Implement user authentication",
      "System.Description": "<div>Full description with HTML</div>",
      "System.State": "Active",
      "System.Reason": "Implementation started",
      "System.WorkItemType": "Task",
      "System.AssignedTo": {
        "displayName": "John Doe",
        "uniqueName": "john.doe@company.com",
        "id": "user-guid"
      },
      "System.CreatedDate": "2025-01-10T09:00:00Z",
      "System.CreatedBy": {
        "displayName": "Jane Manager",
        "uniqueName": "jane.manager@company.com"
      },
      "System.ChangedDate": "2025-01-15T14:30:00Z",
      "System.ChangedBy": {
        "displayName": "John Doe",
        "uniqueName": "john.doe@company.com"
      },
      "System.AreaPath": "MyProject\\Team A",
      "System.IterationPath": "MyProject\\Sprint 5",
      "Microsoft.VSTS.Common.Priority": 2,
      "Microsoft.VSTS.Scheduling.OriginalEstimate": 8,
      "Microsoft.VSTS.Scheduling.RemainingWork": 4,
      "Microsoft.VSTS.Scheduling.CompletedWork": 4
    },
    "relations": [
      {
        "rel": "System.LinkTypes.Hierarchy-Reverse",
        "url": "https://azuredevops.discovertec.net/Link/_apis/wit/workItems/12344",
        "attributes": {
          "name": "Parent"
        }
      }
    ],
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

Usage: /ado-get-work-item <workItemId>
Example: /ado-get-work-item 12345

Note: Use numeric ID only, not "ADO-12345"
```

**If credentials missing:**

```text
Azure DevOps credentials not found.

Please create ~/.azuredevops/credentials.json
```

**If API request fails:**

- 401 Unauthorized: "Invalid or expired PAT"
- 404 Not Found: "Work item '12345' not found or access denied"
- Network error: "Cannot connect to Azure DevOps Server"

Return error JSON:

```json
{
  "error": true,
  "message": "Work item '12345' not found or access denied",
  "statusCode": 404,
  "workItemId": "12345"
}
```

## Notes

- **Full expansion:** Uses `$expand=all` to include fields, relations, and links
- **Field names:** Azure DevOps uses namespaced field names (System.*, Microsoft.VSTS.*)
- **Relations:** Includes parent/child relationships and other links
- **Automatic prefix handling:** Strips "ADO-" if provided
- **HTML content:** Description and other fields may contain HTML
