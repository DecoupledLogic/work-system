---
description: Create a comment on a Teamwork task (helper)
allowedTools:
  - Bash
  - Read
---

# Teamwork API: Create Comment

Creates a new comment on a Teamwork task. Used by workflow commands to post progress updates and status notifications.

## Usage

```bash
/tw-create-comment 26134585 "🚀 Triage Started"
/tw-create-comment 26134585 "Investigation complete. Found 3 issues." "TEXT"
/tw-create-comment TW-26134585 "<h2>Resolution Summary</h2><p>Fixed subscription</p>" "HTML"
```

## Input Parameters

- **taskId** (required): Task ID (numeric or with "TW-" prefix)
- **body** (required): Comment text (supports plain text or HTML)
- **contentType** (optional): "TEXT" or "HTML" (default: "TEXT")

## Implementation

1. **Validate and parse input:**
   ```bash
   taskId=$1
   body=$2
   contentType=${3:-TEXT}  # Default to TEXT

   # Strip "TW-" prefix if present
   taskId=${taskId#TW-}

   # Validate required parameters
   if [ -z "$taskId" ] || [ -z "$body" ]; then
     echo "Error: Missing required parameters"
     exit 1
   fi

   # Validate contentType
   if [ "$contentType" != "TEXT" ] && [ "$contentType" != "HTML" ]; then
     echo "Error: contentType must be TEXT or HTML"
     exit 1
   fi
   ```

2. **Read credentials:**
   - Read `~/.teamwork/credentials.json`
   - Extract `apiKey` and `domain`

3. **Build request payload:**
   ```json
   {
     "comment": {
       "body": "🚀 Triage Started",
       "content-type": "TEXT",
       "notify": ""
     }
   }
   ```

   **Note:** Teamwork API expects:
   - `content-type` field (not contentType)
   - `notify` field (empty string for no notifications)
   - HTML must be valid if contentType is HTML

4. **Make API request:**
   ```bash
   curl -s -X POST \
     -u "${apiKey}:xxx" \
     -H "Content-Type: application/json" \
     -d '{JSON_PAYLOAD}' \
     "https://${domain}/tasks/${taskId}/comments.json"
   ```

5. **Parse response and format output:**

```json
{
  "comment": {
    "id": "456789",
    "taskId": "26134585",
    "body": "🚀 Triage Started",
    "contentType": "TEXT",
    "author": {
      "id": "123456",
      "firstName": "John",
      "lastName": "Doe"
    },
    "createdAt": "2025-12-03T15:30:00Z"
  },
  "success": true
}
```

## Error Handling

**If required parameters missing:**
```text
❌ Missing required parameters

Usage: /tw-create-comment <taskId> <body> [contentType]

Examples:
  /tw-create-comment 26134585 "Task started"
  /tw-create-comment TW-26134585 "Progress update" "TEXT"
  /tw-create-comment 26134585 "<b>Important</b>" "HTML"

Parameters:
  taskId      - Task ID (numeric or with "TW-" prefix)
  body        - Comment text (use quotes for multi-word)
  contentType - Optional: "TEXT" or "HTML" (default: TEXT)
```

**If invalid content type:**
```text
❌ Invalid content type

contentType must be "TEXT" or "HTML"
```

**If credentials missing:**
```text
❌ Teamwork Credentials Required

Please create ~/.teamwork/credentials.json
```

**If API request fails:**
- 401 Unauthorized: "Invalid API key"
- 404 Not Found: "Task '${taskId}' not found or access denied"
- 422 Unprocessable: "Invalid comment data. Check HTML syntax if using HTML content type."

Return error JSON:
```json
{
  "error": true,
  "message": "Task '26134585' not found or access denied",
  "statusCode": 404,
  "taskId": "26134585"
}
```

## Notes

- **Automatic prefix handling**: Strips "TW-" if provided in taskId
- **Content type flexibility**: Supports plain text and HTML formatting
- **No notifications**: Comments are posted without triggering email notifications
- **Markdown support**: TEXT content type supports Teamwork markdown
- **HTML validation**: HTML must be well-formed if using HTML content type
- **Emoji support**: Full emoji support in both TEXT and HTML modes

## Use Cases

- **Workflow automation**: Post status updates at each workflow phase
  - "🚀 Triage Started"
  - "🔍 Investigation Complete"
  - "✅ Verification Passed"

- **Progress tracking**: Document investigation findings
  - "Found 3 affected users: ID-123, ID-456, ID-789"

- **Safety alerts**: Warn about validation issues
  - "⚠️ Safety score: 65/100 - Manual review required"

- **Resolution summaries**: Post complete closure details
  - "🎯 Issue Resolved - TTR: 2h 15m"

## Examples

### Plain Text Comment
```bash
/tw-create-comment 26134585 "Investigation started. Running queries..."
```

### HTML Formatted Comment
```bash
/tw-create-comment 26134585 "<h3>Investigation Summary</h3><ul><li>User ID: 12345</li><li>Status: Active</li></ul>" "HTML"
```

### With TW- Prefix
```bash
/tw-create-comment TW-26134585 "Triage complete. Moving to investigation phase."
```

### Multi-Line Plain Text
```bash
/tw-create-comment 26134585 "Investigation Results:
- Found 3 affected users
- All subscriptions active
- No data anomalies detected"
```
