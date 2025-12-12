---
description: Select new work from assigned tasks across all task lists in the project (user)
allowedTools:
  - Read
  - Task
---

# Select New Work

Interactively select a task from all assigned tasks in the project. Shows tasks with status "new" or "reopened" that are assigned to you.

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

This command orchestrates two specialized sub-agents to fetch and select tasks with minimal context overhead.

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
  statusFilters: ["new", "reopened"]
  userEmail: <email from config>
  userName: <name from config>
  userId: <id from config>
  projectName: <projectName from config>
  clientName: <clientName from config>

  Return structured JSON with tasks array and metadata."
```

**Expected output:** JSON with `tasks` array and `metadata` object

**If error returned:** Display error message from agent and exit

### Step 3: Format Tasks with task-selector Agent

Call the `task-selector` sub-agent using the Task tool:

```
Use Task tool:
- subagent_type: "task-selector"
- model: "haiku"
- prompt: "Format tasks for display with the following data:

  <paste full JSON output from task-fetcher agent>

  displayMode: 'format'

  Return formatted markdown text ready to display to user. Include task counts,
  grouping by priority/due date, and clear numbering for selection."
```

**Expected output:** Formatted markdown text with organized task list

**If error returned:** Display error message from agent and exit

**If no tasks:** Display "No tasks found matching criteria (status: new/reopened, assigned to you)" and exit

### Step 4: Display Formatted Task List

**IMPORTANT:** Display the complete formatted output from the task-selector agent directly to the user. This includes:
- Task counts and metadata
- Grouped task listings (by priority, due date, etc.)
- Task details (ID, name, parent, list, priority, due date, estimate, status, progress)
- Selection instructions

Do not summarize or paraphrase - show the full formatted output as-is.

### Step 5: Prompt for User Selection

After displaying the task list, add a prompt for the user:

```
Enter task number (1-{total_count}) to start work, or 'cancel' to exit:
```

Wait for the user's response in the next message.

### Step 6: Process Selection (Future Enhancement)

**Note:** Currently, this command ends after displaying tasks and prompting for selection. The user will respond with a task number in their next message, which should trigger follow-up actions.

**Future enhancement:** When the user provides a task number, automatically:
1. Validate the selection
2. Invoke `/triage TW-{taskId}` to begin work
3. Display confirmation message

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

## Future Enhancements

1. **Auto-invoke /triage**: After selection, automatically call `/triage TW-[taskId]`
2. **Parallel agent execution**: Run fetcher and selector in parallel where possible
3. **Caching**: Cache task data for session duration
4. **Cross-project view**: `/my-tasks` to see tasks across all projects
