---
description: Fetch all task lists from a Teamwork project (helper)
allowedTools:
  - Bash
  - Read
---

# Teamwork API: Get Task Lists

Fetches all task lists for a given project ID.

## Usage

```bash
/tw-get-tasklists 388711
```

## Input Parameters

- **projectId** (required): Teamwork project ID

## Implementation

1. **Validate input:**
   - Ensure projectId is provided
   - Ensure projectId is numeric

2. **Read credentials:**
   - Read `~/.teamwork/credentials.json`
   - Extract `apiKey` and `domain`
   - If missing: Display error (see Error Handling)

3. **Make API request:**
   ```bash
   curl -s -u "${apiKey}:xxx" \
     "https://${domain}/projects/${projectId}/tasklists.json"
   ```

4. **Parse response and format output:**
   - Extract tasklists array
   - Return JSON in this format:

```json
{
  "tasklists": [
    {
      "id": "1300158",
      "name": "Production Support",
      "description": "Ongoing production support tasks",
      "status": "active",
      "complete": false,
      "projectId": "388711"
    },
    {
      "id": "1300159",
      "name": "Bug Fixes",
      "description": "",
      "status": "active",
      "complete": false,
      "projectId": "388711"
    }
  ],
  "meta": {
    "projectId": "388711",
    "count": 2
  }
}
```

## Error Handling

**If projectId not provided:**
```text
❌ Missing required parameter: projectId

Usage: /tw-get-tasklists <projectId>
Example: /tw-get-tasklists 388711
```

**If credentials missing:**
```text
❌ Teamwork Credentials Required

Please create ~/.teamwork/credentials.json:

{
  "apiKey": "twp_YOUR_API_KEY_HERE",
  "domain": "yourcompany.teamwork.com"
}
```

**If API request fails:**
- 401 Unauthorized: "Invalid API key"
- 404 Not Found: "Project '${projectId}' not found or access denied"
- Network error: "Cannot connect to Teamwork API"

Return error JSON:
```json
{
  "error": true,
  "message": "Project '388711' not found or access denied",
  "statusCode": 404,
  "projectId": "388711"
}
```

## Notes

- Returns ALL task lists (completed and active)
- Task lists are returned in default Teamwork order
- Includes metadata like status and completion state
