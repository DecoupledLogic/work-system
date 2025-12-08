---
description: Resume work on in-progress tasks assigned to you (user)
allowedTools:
  - Read
  - Task
---

# Resume Work

Interactively select from tasks currently in progress. Shows tasks with status "in_progress" that are assigned to you, including progress percentage and time tracking.

## Configuration Requirements

This command requires two levels of configuration:

### Global User Configuration (REQUIRED)
**File**: `~/.claude/teamwork.json`

```json
{
  "user": {
    "email": "your.email@company.com",
    "name": "Your Name",
    "id": "123456"
  }
}
```

### Per-Repo Project Configuration (REQUIRED)
**File**: `.claude/settings.json` (in the repo root)

```json
{
  "teamwork": {
    "projectId": "999999",
    "projectName": "Production Support",
    "clientName": "ACME Corp"
  }
}
```

## Instructions

This command orchestrates two specialized sub-agents to fetch and select in-progress tasks with minimal context overhead.

### Step 1: Read Configuration

1. **Read global user configuration:**
   - Read `~/.claude/teamwork.json`
   - Extract `user.email` (REQUIRED)
   - Extract `user.name` (optional)
   - Extract `user.id` (optional)
   - **If missing or invalid**: Display error (see Error Handling) and exit

2. **Read project configuration:**
   - Read `.claude/settings.json` in current working directory
   - Extract `teamwork.projectId` (REQUIRED)
   - Extract `teamwork.projectName` (optional)
   - Extract `teamwork.clientName` (optional)
   - **If missing or invalid**: Display error (see Error Handling) and exit

### Step 2: Fetch Tasks with task-fetcher Agent

Call the `task-fetcher` sub-agent using the Task tool:

```
Use Task tool:
- subagent_type: "task-fetcher"
- model: "haiku"
- prompt: "Fetch tasks from Teamwork project with the following parameters:

  projectId: <projectId from config>
  statusFilters: ["in_progress"]
  userEmail: <email from config>
  userName: <name from config>
  userId: <id from config>
  projectName: <projectName from config>
  clientName: <clientName from config>

  Return structured JSON with tasks array and metadata."
```

**Expected output:** JSON with `tasks` array and `metadata` object

**If error returned:** Display error message from agent and exit

### Step 3: Select Task with task-selector Agent

Call the `task-selector` sub-agent using the Task tool:

```
Use Task tool:
- subagent_type: "task-selector"
- model: "haiku"
- prompt: "Display and facilitate selection of tasks with the following data:

  <paste full JSON output from task-fetcher agent>

  displayMode: 'resume'

  Return structured JSON with selectedTask object."
```

**Expected output:** JSON with `selectedTask` object or `cancelled: true`

**If cancelled:** Display "Selection cancelled." and exit

**If noTasks:** Display appropriate message and exit

### Step 4: Display Confirmation

If selection successful, display:

```markdown
✅ Task selected successfully!

**Next steps:**
- Task [[taskId]] is ready to resume
- Future: Auto-invoke `/triage TW-[taskId]`
```

## Error Handling

### Missing User Configuration

If `~/.claude/teamwork.json` is missing or doesn't contain user information:

```text
❌ User Configuration Required

Please configure your Teamwork identity in ~/.claude/teamwork.json:

{
  "user": {
    "email": "your.email@company.com",
    "name": "Your Name"
  }
}

This allows filtering tasks assigned to you.
```

### Missing Project Configuration

If `.claude/settings.json` is missing or doesn't contain project information:

```text
❌ Project Configuration Required

Please configure the Teamwork project in .claude/settings.json:

{
  "teamwork": {
    "projectId": "999999",
    "projectName": "Production Support"
  }
}

To find your project ID:
1. Open Teamwork
2. Navigate to your project
3. Check the URL or Project Settings → API & Integrations
```

### Agent Errors

If either sub-agent returns an error, display the error message from the agent and exit gracefully.

### No In-Progress Tasks

If no tasks are found:

```text
✅ No Tasks In Progress

No in-progress tasks found in project "[Project Name]" assigned to: [user email]

To start new work, use: /select-task
```

## Architecture Notes

This command is a thin orchestration layer that:
1. Reads configuration (minimal context: ~500 bytes)
2. Calls task-fetcher agent (isolates ~10-20KB of API logic)
3. Calls task-selector agent (isolates ~5-10KB of display logic)
4. Returns structured output (minimal: ~500 bytes)

**Context savings:** ~90% reduction in main session context compared to monolithic command.

**Benefits:**
- Faster main session response
- Reusable agents across multiple commands
- Easier maintenance (single source of truth)
- Better error isolation
- Can run agents in parallel (future enhancement)

## Differences from /select-task

- **Status filter:** `["in_progress"]` instead of `["new", "reopened"]`
- **Display mode:** Shows progress percentage and time tracking
- **Purpose:** Resume existing work rather than starting new tasks

## Future Enhancements

1. **Auto-invoke /triage**: After selection, automatically call `/triage TW-[taskId]`
2. **Time tracking**: Show how long task has been in progress
3. **Progress insights**: Suggest tasks near completion
4. **Caching**: Cache task data for session duration
