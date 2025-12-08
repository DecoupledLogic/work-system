---
description: Fetch all Teamwork projects (helper)
allowedTools:
  - Bash
  - Read
---

# Teamwork API: Get Projects

Fetches all projects from Teamwork.

## Usage

```bash
/tw-get-projects
```

Optional filters:
```bash
/tw-get-projects active      # Only active projects
/tw-get-projects archived    # Only archived projects
```

## Implementation

1. **Read credentials:**
   - Read `~/.teamwork/credentials.json`
   - Extract `apiKey` and `domain`
   - If missing or invalid: Display error with setup instructions

2. **Make API request:**
   ```bash
   curl -s -u "${apiKey}:xxx" \
     "https://${domain}/projects.json?status=${status}"
   ```

3. **Parse response and format output:**
   - Extract projects array
   - Return JSON in this format:

```json
{
  "projects": [
    {
      "id": "388711",
      "name": "BVI Modernization Plan - Phase 1 Project",
      "company": {
        "id": "123456",
        "name": "BVI"
      },
      "status": "active",
      "starred": false
    }
  ],
  "meta": {
    "count": 42,
    "status": "active"
  }
}
```

## Error Handling

**If credentials file missing:**
```text
❌ Teamwork Credentials Required

Please create ~/.teamwork/credentials.json:

{
  "apiKey": "twp_YOUR_API_KEY_HERE",
  "domain": "yourcompany.teamwork.com"
}

To get your API key:
1. Log into Teamwork
2. Click your profile → Edit My Details
3. Go to "API & Mobile" tab
4. Copy your API key (starts with "twp_")
```

**If API request fails:**
- 401 Unauthorized: "Invalid API key. Check ~/.teamwork/credentials.json"
- 403 Forbidden: "Access denied. Verify your Teamwork permissions."
- Network error: "Cannot connect to Teamwork API. Check internet connection."

Return error JSON:
```json
{
  "error": true,
  "message": "Invalid API key",
  "statusCode": 401
}
```

## Notes

- Returns all projects by default (no status filter)
- Use `active` filter to exclude archived projects
- Projects are sorted alphabetically by name
- Includes company/client information for each project
