---
description: Create a subtask in Teamwork (helper)
allowedTools:
  - Bash
  - Read
---

# Teamwork API: Create Subtask

Creates a new subtask (child task) under a parent task in Teamwork. This command ONLY creates subtasks to maintain task hierarchy and prevent orphaned tasks.

## Usage

```bash
/tw-create-task 26134585 "Implement user authentication"
/tw-create-task 26134585 "Add login form" "Create React component for login UI"
/tw-create-task TW-26134585 "Write unit tests" "Add tests for auth module" 120
```

## Input Parameters

- **parentTaskId** (required): Parent task ID (numeric or with "TW-" prefix)
- **name** (required): Task name/title (use quotes for multi-word)
- **description** (optional): Task description
- **estimateMinutes** (optional): Time estimate in minutes

## Implementation

1. **Validate and parse input:**
   ```bash
   parentTaskId=$1
   name=$2
   description=${3:-""}
   estimateMinutes=${4:-""}

   # Strip "TW-" prefix if present
   parentTaskId=${parentTaskId#TW-}

   # Validate required parameters
   if [ -z "$parentTaskId" ] || [ -z "$name" ]; then
     echo "❌ Missing required parameters"
     echo ""
     echo "Usage: /tw-create-task <parentTaskId> <name> [description] [estimateMinutes]"
     echo ""
     echo "Examples:"
     echo "  /tw-create-task 26134585 \"Implement feature\""
     echo "  /tw-create-task 26134585 \"Add tests\" \"Write unit tests\" 120"
     exit 1
   fi

   # Validate parentTaskId is numeric
   if ! [[ "$parentTaskId" =~ ^[0-9]+$ ]]; then
     echo "❌ Invalid parent task ID: must be numeric"
     exit 1
   fi
   ```

2. **Read credentials:**
   ```bash
   CREDS_FILE="$HOME/.teamwork/credentials.json"

   if [ ! -f "$CREDS_FILE" ]; then
     echo "❌ Teamwork Credentials Required"
     echo ""
     echo "Please create ~/.teamwork/credentials.json"
     exit 1
   fi

   apiKey=$(jq -r '.apiKey' "$CREDS_FILE")
   domain=$(jq -r '.domain' "$CREDS_FILE")

   if [ -z "$apiKey" ] || [ -z "$domain" ]; then
     echo "❌ Invalid credentials file"
     exit 1
   fi
   ```

3. **Build request payload:**
   ```json
   {
     "todo-item": {
       "content": "Implement user authentication",
       "description": "Create React component for login UI",
       "estimateMinutes": 120,
       "parentTaskId": "26134585"
     }
   }
   ```

   **Note:** Teamwork API expects:
   - `content` field for task name (not `name`)
   - `description` field is optional
   - `estimateMinutes` for time estimates
   - Task is automatically created as a subtask when using the subtasks endpoint

4. **Make API request:**
   ```bash
   # Build JSON payload dynamically
   payload='{"todo-item":{"content":"'"${name}"'"'

   if [ -n "$description" ]; then
     payload="${payload}"',"description":"'"${description}"'"'
   fi

   if [ -n "$estimateMinutes" ]; then
     payload="${payload}"',"estimateMinutes":'"${estimateMinutes}"
   fi

   payload="${payload}"'}}'

   # Create subtask using parent task endpoint
   response=$(curl -s -w "\n%{http_code}" -X POST \
     -u "${apiKey}:xxx" \
     -H "Content-Type: application/json" \
     -d "$payload" \
     "https://${domain}/tasks/${parentTaskId}/subtasks.json")

   # Extract status code and body
   httpCode=$(echo "$response" | tail -n1)
   body=$(echo "$response" | head -n-1)
   ```

5. **Parse response and format output:**

**Success response:**
```json
{
  "task": {
    "id": "26134586",
    "name": "Implement user authentication",
    "description": "Create React component for login UI",
    "estimateMinutes": 120,
    "parentTaskId": "26134585",
    "progress": 0,
    "createdAt": "2025-12-07T15:30:00Z"
  },
  "success": true
}
```

## Error Handling

**If required parameters missing:**
```text
❌ Missing required parameters

Usage: /tw-create-task <parentTaskId> <name> [description] [estimateMinutes]

Examples:
  /tw-create-task 26134585 "Implement feature"
  /tw-create-task 26134585 "Add tests" "Write unit tests"
  /tw-create-task 26134585 "Fix bug" "Resolve login issue" 60
  /tw-create-task TW-26134585 "Code review" "" 30

Parameters:
  parentTaskId    - Parent task ID (numeric or with "TW-" prefix)
  name            - Task name (use quotes for multi-word)
  description     - Optional task description
  estimateMinutes - Optional time estimate in minutes

Note: This command ONLY creates subtasks. A parent task ID is required.
```

**If parent task not found:**
```text
❌ Parent task not found

Parent task '26134585' does not exist or you don't have access.
Verify the task ID and try again.
```

**If credentials missing:**
```text
❌ Teamwork Credentials Required

Please create ~/.teamwork/credentials.json with:
{
  "apiKey": "twp_YOUR_API_KEY",
  "domain": "yourcompany.teamwork.com"
}
```

**If API request fails:**
- 401 Unauthorized: "Invalid API key"
- 404 Not Found: "Parent task '${parentTaskId}' not found or access denied"
- 422 Unprocessable: "Invalid task data. Check required fields."

Return error JSON:
```json
{
  "error": true,
  "message": "Parent task '26134585' not found or access denied",
  "statusCode": 404,
  "parentTaskId": "26134585"
}
```

## Notes

- **Subtasks only**: This command ONLY creates subtasks, never standalone tasks
- **Parent required**: A valid parent task ID is always required
- **Automatic prefix handling**: Strips "TW-" if provided in parentTaskId
- **Task hierarchy**: Maintains proper parent-child relationships in Teamwork
- **Estimate visibility**: Setting estimate makes time visible in Teamwork UI
- **Progress tracking**: New tasks start at 0% progress
- **Inherits context**: Subtasks inherit project and tasklist from parent

## Why Subtasks Only?

This design prevents:
- **Orphaned tasks**: Tasks created without proper project/tasklist context
- **Hierarchy confusion**: Tasks floating without clear ownership
- **Planning gaps**: Tasks not tied to structured work breakdown

For standalone tasks, use Teamwork UI where you can properly:
- Select the correct project
- Choose the appropriate tasklist
- Set milestone associations
- Configure visibility and permissions

## Use Cases

### Planning Phase - Create Stories
```bash
# After planning a feature, create story subtasks
/tw-create-task 26134585 "User can login with email" "Implement email/password authentication" 480
/tw-create-task 26134585 "User can reset password" "Add password reset flow" 240
/tw-create-task 26134585 "User can logout" "Implement logout functionality" 120
```

### Story Breakdown - Create Tasks
```bash
# After planning a story, create implementation tasks
/tw-create-task 26134586 "Create login component" "Build React login form" 120
/tw-create-task 26134586 "Add authentication API" "Implement backend auth endpoint" 180
/tw-create-task 26134586 "Write integration tests" "Add E2E tests for login flow" 90
```

### Bug Investigation - Create Subtasks
```bash
# Break down investigation into steps
/tw-create-task 26134590 "Reproduce issue locally" "" 30
/tw-create-task 26134590 "Check error logs" "" 15
/tw-create-task 26134590 "Identify root cause" "" 45
/tw-create-task 26134590 "Implement fix" "" 60
```

## Examples

### Basic Subtask Creation
```bash
/tw-create-task 26134585 "Implement authentication"
```

### With Description
```bash
/tw-create-task 26134585 "Add login form" "Create React component for user login"
```

### With Estimate
```bash
/tw-create-task 26134585 "Write unit tests" "Add comprehensive test coverage" 120
```

### With TW- Prefix
```bash
/tw-create-task TW-26134585 "Code review" "Review authentication implementation" 30
```

### Multiple Subtasks for Planning
```bash
# Feature decomposition
/tw-create-task 26134585 "Design database schema" "Define tables and relationships" 180
/tw-create-task 26134585 "Implement API endpoints" "Create REST API for auth" 360
/tw-create-task 26134585 "Build frontend UI" "Create login and registration forms" 480
/tw-create-task 26134585 "Write documentation" "Document API and user flows" 120
```

## Integration with /plan Command

The `/plan` command uses this to create child work items:

```bash
# In /plan workflow, after decomposing a feature:
for story in stories:
  /tw-create-task {featureId} {story.name} {story.description} {story.estimateMinutes}
```

This ensures:
- All planned work items are created in Teamwork
- Proper hierarchy is maintained (feature → stories → tasks)
- Estimates are captured for reporting
- Work breakdown is visible to the team
