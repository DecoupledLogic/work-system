---
description: Add a comment to an Azure DevOps work item (helper)
allowedTools:
  - Bash
  - Read
---

# Azure DevOps API: Create Comment

Adds a comment to an existing work item's discussion history.

## Usage

```bash
/ado-create-comment 12345 "Investigation complete. Ready for development."
/ado-create-comment ADO-12345 "Found root cause: null pointer exception in auth module."
```

## Input Parameters

- **workItemId** (required): Work item ID (numeric, "ADO-" prefix stripped)
- **comment** (required): Comment text (supports basic HTML/markdown)

## Implementation

1. **Validate input:**

   ```bash
   workItemId=$1
   comment=$2

   if [ -z "$workItemId" ] || [ -z "$comment" ]; then
     echo "Error: workItemId and comment are required"
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

3. **Build request body:**

   ```bash
   # Escape comment text for JSON
   escapedComment=$(echo "$comment" | jq -Rs '.')

   requestBody='{"text":'"$escapedComment"'}'
   ```

4. **Make API request:**

   ```bash
   auth=$(echo -n ":${pat}" | base64)

   curl -s \
     -H "Authorization: Basic ${auth}" \
     -H "Content-Type: application/json" \
     -X POST \
     -d "$requestBody" \
     "${serverUrl}/${collection}/_apis/wit/workitems/${workItemId}/comments?api-version=6.0-preview.3"
   ```

5. **Parse response and format output:**

```json
{
  "comment": {
    "id": 456789,
    "workItemId": 12345,
    "version": 1,
    "text": "Investigation complete. Ready for development.",
    "createdBy": {
      "displayName": "API User",
      "uniqueName": "api.user@company.com",
      "id": "user-guid"
    },
    "createdDate": "2025-01-15T16:45:00Z",
    "modifiedBy": {
      "displayName": "API User",
      "uniqueName": "api.user@company.com"
    },
    "modifiedDate": "2025-01-15T16:45:00Z",
    "url": "https://azuredevops.discovertec.net/Link/_apis/wit/workItems/12345/comments/456789"
  }
}
```

## Error Handling

**If required parameters missing:**

```text
Missing required parameters: workItemId and comment

Usage: /ado-create-comment <workItemId> "comment text"
Examples:
  /ado-create-comment 12345 "Investigation complete."
  /ado-create-comment ADO-12345 "Found the root cause of the bug."

Note: Use quotes around comment text.
```

**If credentials missing:**

```text
Azure DevOps credentials not found.

Please create ~/.azuredevops/credentials.json
```

**If API request fails:**

- 401 Unauthorized: "Invalid or expired PAT"
- 404 Not Found: "Work item '12345' not found"
- 400 Bad Request: "Invalid comment format"

Return error JSON:

```json
{
  "error": true,
  "message": "Work item '12345' not found",
  "statusCode": 404,
  "workItemId": "12345"
}
```

## Notes

- **API Version:** Uses preview API (6.0-preview.3) for comments
- **Discussion history:** Comments appear in work item's Discussion section
- **HTML support:** Basic HTML/markdown supported in comment text
- **Notifications:** Adding a comment may trigger notifications to watchers
- **@mentions:** Use @displayName to mention users in comments
- **Editing:** Comments can be edited after creation via the web UI
