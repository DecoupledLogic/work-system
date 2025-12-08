---
description: Get details of a single Azure DevOps project (helper)
allowedTools:
  - Bash
  - Read
---

# Azure DevOps API: Get Project

Fetches detailed information about a specific project by name or ID.

## Usage

```bash
/ado-get-project MyProject
/ado-get-project "Project Name With Spaces"
/ado-get-project a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

## Input Parameters

- **projectNameOrId** (required): Project name or GUID

## Implementation

1. **Validate input:**

   ```bash
   projectNameOrId=$1

   if [ -z "$projectNameOrId" ]; then
     echo "Error: projectNameOrId required"
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

3. **Create auth header:**

   ```bash
   auth=$(echo -n ":${pat}" | base64)
   ```

4. **Make API request:**

   ```bash
   # URL encode project name if it contains spaces
   encodedProject=$(echo "$projectNameOrId" | jq -sRr @uri)

   curl -s \
     -H "Authorization: Basic ${auth}" \
     -H "Content-Type: application/json" \
     "${serverUrl}/${collection}/_apis/projects/${encodedProject}?includeCapabilities=true&api-version=6.0"
   ```

5. **Parse response and format output:**

```json
{
  "project": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "name": "MyProject",
    "description": "Project description here",
    "url": "https://azuredevops.discovertec.net/Link/_apis/projects/a1b2c3d4...",
    "state": "wellFormed",
    "revision": 456,
    "visibility": "private",
    "lastUpdateTime": "2025-01-15T10:30:00Z",
    "capabilities": {
      "versioncontrol": {
        "sourceControlType": "Git"
      },
      "processTemplate": {
        "templateName": "Agile",
        "templateTypeId": "adcc42ab-9882-485e-a3ed-7678f01f66bc"
      }
    },
    "defaultTeam": {
      "id": "team-guid",
      "name": "MyProject Team"
    }
  }
}
```

## Error Handling

**If projectNameOrId not provided:**

```text
Missing required parameter: projectNameOrId

Usage: /ado-get-project <projectNameOrId>
Example: /ado-get-project MyProject
```

**If credentials missing:**

```text
Azure DevOps credentials not found.

Please create ~/.azuredevops/credentials.json
```

**If API request fails:**

- 401 Unauthorized: "Invalid or expired PAT"
- 404 Not Found: "Project 'MyProject' not found or access denied"
- Network error: "Cannot connect to Azure DevOps Server"

Return error JSON:

```json
{
  "error": true,
  "message": "Project 'MyProject' not found or access denied",
  "statusCode": 404,
  "projectNameOrId": "MyProject"
}
```

## Notes

- **Capabilities:** Includes version control type (Git/TFVC) and process template
- **Default team:** Returns the default team for the project
- **URL encoding:** Project names with spaces are automatically URL-encoded
- **Case sensitivity:** Project names are case-insensitive
