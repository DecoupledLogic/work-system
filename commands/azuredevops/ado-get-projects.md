---
description: List all Azure DevOps projects in the collection (helper)
allowedTools:
  - Bash
  - Read
---

# Azure DevOps API: Get Projects

Lists all projects in the configured Azure DevOps Server collection.

## Usage

```bash
/ado-get-projects
/ado-get-projects active
/ado-get-projects all
```

## Input Parameters

- **stateFilter** (optional): Filter by project state
  - `wellFormed` (default) - Active projects
  - `all` - All projects including deleted
  - `createPending` - Projects being created
  - `deleting` - Projects being deleted

## Implementation

1. **Read profile from work-manager config (if in repo context):**

   ```bash
   # Get profile name from .claude/work-manager.yaml if available
   profile="default"
   if [ -f ".claude/work-manager.yaml" ]; then
     profile=$(grep -A10 "azuredevops:" .claude/work-manager.yaml | grep "profile:" | awk '{print $2}' || echo "default")
     [ -z "$profile" ] && profile="default"
   fi
   ```

2. **Read credentials from named profile:**

   ```bash
   credentials=$(cat ~/.azuredevops/credentials.json)
   serverUrl=$(echo "$credentials" | jq -r ".${profile}.serverUrl // .default.serverUrl")
   collection=$(echo "$credentials" | jq -r ".${profile}.collection // .default.collection")
   pat=$(echo "$credentials" | jq -r ".${profile}.pat // .default.pat")
   ```

3. **Validate credentials:**

   ```bash
   if [ -z "$serverUrl" ] || [ -z "$collection" ] || [ -z "$pat" ]; then
     echo "Error: Invalid credentials file or profile '${profile}' not found"
     exit 1
   fi
   ```

4. **Create auth header:**

   ```bash
   auth=$(echo -n ":${pat}" | base64)
   ```

5. **Make API request:**

   ```bash
   stateFilter=${1:-wellFormed}

   curl -s \
     -H "Authorization: Basic ${auth}" \
     -H "Content-Type: application/json" \
     "${serverUrl}/${collection}/_apis/projects?stateFilter=${stateFilter}&api-version=6.0"
   ```

6. **Parse response and format output:**

```json
{
  "count": 5,
  "projects": [
    {
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "name": "MyProject",
      "description": "Project description",
      "url": "https://azuredevops.discovertec.net/Link/_apis/projects/a1b2c3d4...",
      "state": "wellFormed",
      "revision": 123,
      "visibility": "private",
      "lastUpdateTime": "2025-01-15T10:30:00Z"
    }
  ]
}
```

## Error Handling

**If credentials file missing:**

```text
Azure DevOps credentials not found.

Please create ~/.azuredevops/credentials.json with named profiles:
{
  "default": {
    "serverUrl": "https://your-server.com",
    "collection": "YourCollection",
    "pat": "YOUR_PAT_HERE"
  }
}
```

**If profile not found:**

```text
Profile 'client-b' not found in ~/.azuredevops/credentials.json.

Available profiles: default, internal
```

**If API request fails:**

- 401 Unauthorized: "Invalid or expired PAT"
- 403 Forbidden: "PAT lacks project read permissions"
- Network error: "Cannot connect to Azure DevOps Server"

Return error JSON:

```json
{
  "error": true,
  "message": "Cannot connect to Azure DevOps Server",
  "statusCode": 0,
  "serverUrl": "https://azuredevops.discovertec.net"
}
```

## Notes

- **Pagination:** API returns all projects (no pagination needed for typical usage)
- **Permissions:** PAT needs at least "Project and Team (Read)" scope
- **State filter:** Most use cases only need `wellFormed` (active projects)
