# Global Teamwork Task Management Commands

This directory contains global Claude Code commands for managing Teamwork tasks across all your projects.

## Available Commands

### `/select-task` - Select New Work
Pick new work from tasks assigned to you with status "new" or "reopened". Shows all tasks across all task lists in the configured project, with smart grouping by priority and urgency.

### `/resume` - Resume In-Progress Work
Continue work on tasks you've already started (status "in_progress"). Shows progress percentage and time in progress for each task.

## Architecture

### Context-Efficient Agent-Based Design

These commands use a **context-efficient agent-based architecture** to minimize memory footprint in your main coding session:

**Traditional Approach (Before):**
- 619-658 lines of instructions loaded per command
- All business logic in main session context
- ~15-20KB of context per invocation

**Agent-Based Approach (Current):**
- ~40-line orchestration layer in main session
- Heavy logic offloaded to specialized sub-agents
- Sub-agents run in isolated contexts
- Main session receives only structured JSON output
- **~90% context reduction**

### Sub-Agents

The commands leverage two specialized sub-agents located in `~/.claude/agents/`:

**1. `task-fetcher` (API Orchestration)**
- Handles all Teamwork API calls
- Implements pagination (up to 20 pages per list)
- Enriches tasks with parent and list context
- Filters by status and assignee
- Returns structured JSON task array
- Model: Haiku (cost-effective for API work)

**2. `task-selector` (Display & Interaction)**
- Sorts and groups tasks by priority/urgency
- Formats display with icons and context
- Handles user selection interaction
- Returns structured selected task object
- Model: Haiku (simple presentation logic)

### Benefits

✅ **Context Efficiency**: Main session only sees ~500 bytes of orchestration + output
✅ **Reusability**: Agents can be called by other commands and agents
✅ **Maintainability**: Single source of truth for business logic
✅ **Composability**: Easy to create new commands (e.g., `/my-overdue-tasks`)
✅ **Testability**: Agents have clear input/output contracts
✅ **Performance**: Acceptable latency tradeoff for massive context savings

### How Commands Call Agents

Commands orchestrate agents using the `Task` tool:

```markdown
# 1. Read configuration from files (~500 bytes)

# 2. Call task-fetcher agent
Task tool → task-fetcher agent
  Input: projectId, statusFilters, userEmail
  Output: { tasks: [...], metadata: {...} }

# 3. Call task-selector agent
Task tool → task-selector agent
  Input: tasks from step 2, displayMode
  Output: { selectedTask: {...} }

# 4. Display confirmation in main session
```

This pattern keeps the main coding session lightweight and focused on implementation work rather than task management overhead.

## Quick Start

### 1. Configure Your User Identity (One Time)

Edit `~/.claude/teamwork.json`:

```json
{
  "user": {
    "email": "your.email@company.com",
    "name": "Your Name",
    "id": "123456"
  }
}
```

**How to find your information:**
1. Open Teamwork: https://company.teamwork.com
2. Click your avatar (top right) → **Settings** → **Profile**
3. Copy your **email address** (required)
4. Copy your **display name** (optional but recommended)
5. For **user ID**: See "Finding Your User ID" section below

### 2. Configure Each Project

In each repository, edit `.claude/settings.json`:

```json
{
  "teamwork": {
    "projectId": "999999",
    "projectName": "Production Support",
    "clientName": "ACME Corp"
  }
}
```

**How to find project ID:**
- See "Finding Your Project ID" section below

### 3. Use the Commands

From any directory in your configured repository:

```bash
# Select new work
/select-task

# Resume in-progress work
/resume
```

## Configuration Guide

### Finding Your User ID

Your Teamwork user ID is needed for precise task filtering.

**Method 1: From Profile URL**
1. Go to Teamwork
2. Click your avatar → **Settings** → **Profile**
3. Check the browser URL: `https://company.teamwork.com/people/132683`
4. The number at the end is your user ID: `132683`

**Method 2: From API (using MCP)**
If the MCP tool `mcp__Teamwork__twprojects-get_people` is available:
1. Use Claude Code to call: `mcp__Teamwork__twprojects-get_people`
2. Find your entry in the results
3. Copy the `id` field

**Method 3: From Task Assignment**
1. Open any task assigned to you in Teamwork
2. Right-click on your name in the assignees list
3. Inspect element (browser dev tools)
4. Look for `data-user-id="132683"` attribute
5. That's your user ID

**Note:** User ID is optional. The commands will work with just your email address, but including the ID provides more accurate matching.

### Finding Your Project ID

The project ID tells the commands which Teamwork project to fetch tasks from.

**Method 1: From Project URL**
1. Go to Teamwork
2. Navigate to your project (e.g., "Production Support")
3. Click **Project Settings** (gear icon)
4. Check the browser URL: `https://company.teamwork.com/app/projects/545123`
5. The number is your project ID: `545123`

**Method 2: From Task URL**
1. Open any task in the project
2. Check the browser URL: `https://company.teamwork.com/app/tasks/26162664`
3. Click the project name breadcrumb at the top
4. URL changes to: `https://company.teamwork.com/app/projects/545123`
5. The number is your project ID: `545123`

**Method 3: From Project Settings**
1. Open your project in Teamwork
2. Click **Project Settings** (gear icon)
3. Go to **API & Integrations**
4. The project ID is displayed on this page

**Method 4: Using MCP Tool**
If the MCP tool `mcp__Teamwork__twprojects-list_projects` is available:
1. Use Claude Code to call: `mcp__Teamwork__twprojects-list_projects`
2. Find your project in the results
3. Copy the `id` field

### Finding Your Task List ID (Optional)

Task list IDs are optional with the new project-level commands. However, if you need to reference a specific task list:

**Method 1: From Task List URL**
1. Go to Teamwork
2. Navigate to your project
3. Click **Tasks** in the left sidebar
4. Click on a task list (e.g., "Production Support")
5. Check the browser URL: `https://company.teamwork.com/app/tasklists/1300158/list`
6. The number is your task list ID: `1300158`

**Method 2: Using MCP Tool**
If the MCP tool `mcp__Teamwork__twprojects-get_task_lists_by_project_id` is available:
1. Use Claude Code to call: `mcp__Teamwork__twprojects-get_task_lists_by_project_id` with your project ID
2. Find your task list in the results
3. Copy the `id` field

## Configuration Files Reference

### Global User Configuration

**File:** `~/.claude/teamwork.json`

**Purpose:** Stores your Teamwork user identity for filtering tasks assigned to you.

**Fields:**
- `user.email` (REQUIRED) - Your Teamwork email address
- `user.name` (optional) - Your display name (fallback if email doesn't match)
- `user.id` (optional) - Your Teamwork user ID (for exact matching)

**Example:**
```json
{
  "user": {
    "email": "cbryant@discovertec.com",
    "name": "Charles Bryant",
    "id": "132683"
  }
}
```

### Per-Repository Project Configuration

**File:** `<repository-root>/.claude/settings.json`

**Purpose:** Specifies which Teamwork project to fetch tasks from for this repository.

**Fields:**
- `teamwork.projectId` (REQUIRED) - Teamwork project ID
- `teamwork.projectName` (optional) - Project name for display
- `teamwork.clientName` (optional) - Client/customer name for context

**Example:**
```json
{
  "teamwork": {
    "projectId": "545123",
    "projectName": "Production Support",
    "clientName": "Discover TEC"
  }
}
```

**Note:** Each repository can have a different project configuration, allowing you to work on multiple client projects.

## How The Commands Work

### Data Fetching

Both `/select-task` and `/resume` follow this process:

1. **Read Configuration**
   - Global user identity from `~/.claude/teamwork.json`
   - Project ID from repository's `.claude/settings.json`

2. **Fetch All Task Lists**
   - Get all task lists in the project

3. **Fetch All Tasks with Pagination**
   - For each task list, fetch all pages (up to 20 pages = 2,000 tasks max)
   - Ensures no tasks are missed, even in large projects
   - Shows progress indicator: "Fetching tasks from Production Support (page 2)..."

4. **Fetch Subtasks**
   - For each task assigned to you, fetch subtasks (2 levels deep)
   - Includes subtasks assigned to you even if parent isn't assigned

5. **Filter Tasks**
   - `/select-task`: status = "new" OR "reopened"
   - `/resume`: status = "in_progress"
   - Only show tasks assigned to you (matches by email/name/ID)

6. **Enrich with Context**
   - Add parent task information for subtasks
   - Add task list name for context
   - Calculate urgency (overdue, today, this week, future)

7. **Sort and Group**
   - Primary: Priority (high → medium → low)
   - Secondary: Due date (overdue → future)
   - Tertiary: Age (oldest → newest)
   - Group by: Urgency + Priority for visual priority queue

8. **Display and Select**
   - Show flat numbered list with parent context
   - Simple selection: enter number (1, 2, 3...)
   - Display selected task details

### Why Pagination Matters

**Problem:** If a task list has 100 tasks and you only fetch the first 50, you might miss tasks beyond page 1.

**Example:**
- Task list has 100 tasks total
- 60 are "completed"
- 40 are "new"/"reopened"
- If you only fetch page 1 (50 tasks), and 40 of those are completed, you only see 10 actionable tasks
- You miss the other 30 actionable tasks on page 2

**Solution:** The commands implement robust pagination:
- Fetch all pages from all task lists
- Safety limit: 20 pages (2,000 tasks) per task list
- Progress indicators show fetching status
- Warnings if limit reached

### Performance

**Typical Project** (3 task lists, 150 total tasks):
- API calls: ~10-20
- Load time: 3-5 seconds
- Acceptable for interactive use

**Large Project** (10 task lists, 500 total tasks):
- API calls: ~50-100
- Load time: 10-20 seconds
- Progress indicators shown

**Very Large Project** (10+ task lists, 2,000+ tasks):
- API calls: ~200+ (hits safety limit)
- Load time: 30-60 seconds
- Warning displayed about truncation

## Display Format

### Task List Example

```markdown
# New Work - Production Support (Discover TEC)
Fetched 15 tasks from 3 task lists | Assigned to: cbryant@discovertec.com

## Overdue - High Priority (2 tasks) 🚨⚡

1. **[26134585]** Update database schema
   ├─ Parent: [26134584] Service Plan Management (Team Lead)
   ├─ List: Production Support
   ├─ Priority: High | Due: Oct 31 (7 days overdue) | Est: 2h
   └─ Status: New

2. **[26142100]** Bug Fix: Email Notifications
   ├─ Parent: (none - top-level task)
   ├─ List: Bug Fixes
   ├─ Priority: High | Due: Oct 28 (10 days overdue) | Est: 1h
   └─ Status: Reopened

## Due Today - High Priority (1 task) ⏰⚡

3. **[26162622]** Service Plan Review
   ├─ Parent: (none - top-level task)
   ├─ List: Customer Support
   ├─ Priority: High | Due: Today | Est: 30m
   └─ Status: New

---
Enter task number (1-3) to start work, or 'cancel' to exit:
```

### Field Explanations

- **Task ID**: Numeric Teamwork task ID (e.g., `[26134585]`)
- **Parent**: Shows parent task for subtasks, with assignment info
  - If parent not assigned to you: "Assigned to: [Name]"
  - If parent also assigned: "Also assigned to you"
  - If top-level: "(none - top-level task)"
- **List**: Which task list this task belongs to
- **Priority**: high, medium, low, or (not set)
- **Due**: Date with relative time
  - Overdue: "Oct 31 (7 days overdue)"
  - Today: "Today"
  - Future: "Dec 5 (2 days)"
- **Est**: Estimated time
  - < 60 min: "30m"
  - >= 60 min: "2h 30m"
  - Not set: "Not set"
- **Status**: New, Reopened, or In Progress
- **Progress** (for `/resume`): Percentage complete (0-100%)

### Icons

- 🚨 Overdue
- ⏰ Due today
- 📅 Due this week
- 📋 Future
- ⚡ High priority
- 🔄 In progress

## Troubleshooting

### "User Configuration Required"

**Problem:** `~/.claude/teamwork.json` is missing or invalid.

**Solution:**
1. Create `~/.claude/teamwork.json`
2. Add your user information (see Quick Start)
3. At minimum, include your email address

### "Project Configuration Required"

**Problem:** `.claude/settings.json` in repository is missing teamwork.projectId.

**Solution:**
1. Edit `.claude/settings.json` in repository root
2. Add teamwork configuration (see Quick Start)
3. Find your project ID (see "Finding Your Project ID")

### "Teamwork API Unavailable"

**Possible causes:**
- Internet connection issue
- Teamwork MCP not enabled
- Invalid project ID
- Insufficient permissions

**Solutions:**
1. Check internet connection
2. Verify MCP is enabled: Teamwork Settings → AI
3. Verify project ID is correct
4. Check you have access to the project in Teamwork UI

### "No Tasks Assigned to You"

**Possible causes:**
- All your tasks are completed or in progress
- Email address mismatch
- You're not assigned to any tasks

**Solutions:**
1. Check if email in `~/.claude/teamwork.json` matches Teamwork
2. Verify you have tasks assigned in Teamwork UI
3. Check if tasks are in different project
4. Try `/resume` to see in-progress tasks

### "Large Project Detected"

**Problem:** Project has 2,000+ tasks, hitting the safety limit.

**Impact:** Some tasks beyond page 20 may not be shown.

**Solutions:**
1. Archive completed tasks in Teamwork
2. Split large project into smaller projects
3. Use Teamwork UI for bulk operations
4. Contact project admin to organize task lists

### Tasks Not Showing Up

**Checklist:**
1. ✅ Email address in `~/.claude/teamwork.json` matches Teamwork
2. ✅ Task is assigned to you in Teamwork UI
3. ✅ Task status is "new" or "reopened" (for `/select-task`)
4. ✅ Task status is "in_progress" (for `/resume`)
5. ✅ Task is in the configured project
6. ✅ Project ID is correct in `.claude/settings.json`
7. ✅ You have access to the project

### Performance is Slow

**Expected load times:**
- Small project (< 100 tasks): 2-5 seconds
- Medium project (100-500 tasks): 5-15 seconds
- Large project (500-2000 tasks): 15-60 seconds

**If slower than expected:**
1. Check internet connection speed
2. Verify Teamwork API is responsive (check status page)
3. Consider archiving completed tasks
4. Project may have many subtasks (increases API calls)

## Advanced Usage

### Multiple Projects

Each repository can have its own project configuration:

```bash
# Repository 1: Client A
cd ~/projects/client-a
cat .claude/settings.json
# { "teamwork": { "projectId": "111111", "projectName": "Client A" } }
/select-task  # Shows tasks from Client A project

# Repository 2: Client B
cd ~/projects/client-b
cat .claude/settings.json
# { "teamwork": { "projectId": "222222", "projectName": "Client B" } }
/select-task  # Shows tasks from Client B project
```

### Working Across Multiple Task Lists

The commands automatically fetch from **all task lists** in the project, including:
- Production Support
- Bug Fixes
- Feature Development
- Customer Requests
- Technical Debt
- etc.

All tasks are combined and sorted by priority + urgency, giving you a unified view of your work across the entire project.

### Parent Task Context

If you're assigned to a subtask but not the parent task, you'll see the parent task context:

```
1. **[26134585]** Update database schema
   ├─ Parent: [26134584] Service Plan Management (Assigned to: Team Lead)
   ...
```

This helps you understand the larger context of your work without needing to open Teamwork.

### Filtering by Status

The commands filter tasks by status automatically:

| Command | Included Statuses | Excluded Statuses |
|---------|------------------|-------------------|
| `/select-task` | new, reopened | in_progress, completed |
| `/resume` | in_progress | new, reopened, completed |

This separation helps you:
- `/select-task`: Pick something new to start
- `/resume`: Continue what you're already working on

### Future Workflow Integration

These commands are designed as the first step in a complete task workflow:

1. `/select-task` → Pick new work
2. *(Future)* `/triage TW-12345` → Create issue and investigate
3. *(Future)* `/investigate` → Document findings
4. *(Future)* `/validate` → Test solution
5. *(Future)* `/verify` → Verify with stakeholders
6. *(Future)* `/close` → Complete and close task

The task selection commands provide the foundation for this workflow by giving you a quick, prioritized view of your work.

## Technical Details

### API Calls

**Task fetching pattern:**
```
1. getTaskListsByProjectId(projectId) → 1 call
2. For each task list:
   - getTasksByTaskListId(listId, page) → N calls (until no more pages)
3. For each task assigned to you:
   - getTaskSubtasks(taskId) → M calls
4. For each subtask without parent info:
   - getTask(parentId) → P calls

Total: 1 + (N × task_lists) + M + P calls
```

**Safety limits:**
- Max 20 pages per task list (2,000 tasks)
- Max 100 tasks per page
- Max 5 levels of subtask depth (we fetch 2 levels)

### Data Caching

**Currently:** No caching - fresh data on every invocation

**Future enhancement:** Session-based caching to reduce API calls and improve performance for repeated invocations within the same work session.

### Teamwork ID Format

**Important:** Teamwork MCP tools require **numeric IDs only**.

- ✅ Correct: `26134585` (numeric)
- ❌ Wrong: `TW-26134585` (with prefix)

The commands handle this automatically:
- Display: Shows IDs in brackets `[26134585]` for readability
- API calls: Uses numeric ID only
- Future: `/triage` command will add "TW-" prefix when needed

### Error Handling

The commands handle:
- Missing configuration files
- Invalid project IDs
- API failures and timeouts
- Empty result sets
- Parent task fetch failures
- Pagination limits
- Network issues

All errors include:
- Clear description of the problem
- Specific steps to resolve
- Helpful context (file paths, URLs, etc.)

## Getting Help

### Command Help

For detailed information about a specific command, read its markdown file:
- [select-task.md](./select-task.md) - Complete `/select-task` implementation
- [resume.md](./resume.md) - Complete `/resume` implementation

### Common Questions

**Q: Why am I not seeing all my tasks?**
A: Check that your email in `~/.claude/teamwork.json` exactly matches your Teamwork account email. Also verify the task status matches the command (new/reopened for `/select-task`, in_progress for `/resume`).

**Q: Can I use these commands without configuring a project?**
A: No, both commands require a project ID to know which Teamwork project to fetch tasks from. This is configured per-repository in `.claude/settings.json`.

**Q: How often should I run these commands?**
A: Run them whenever you want to pick new work or see your current work. The commands fetch fresh data from Teamwork each time (no caching currently).

**Q: Can I use task list ID instead of project ID?**
A: The commands are designed for project-level fetching (all task lists). However, you can keep the `defaultTaskListId` in your settings for reference or backward compatibility with other commands.

**Q: What if I have tasks in multiple projects?**
A: Each repository can be configured for a different project. Switch between repositories to see tasks from different projects. A future `/my-tasks` command may provide a cross-project dashboard view.

**Q: How do I know if pagination is working?**
A: If a task list has multiple pages, you'll see progress indicators like "Fetching tasks from Production Support (page 2)..." during the fetch process.

## Changelog

### Version 1.0 (Current)
- Initial implementation
- Project-level task fetching
- Robust pagination (up to 20 pages per task list)
- Subtask support (2 levels deep)
- Assignee filtering
- Parent task context
- Priority + urgency grouping
- Flat display with task list context
- Two commands: `/select-task` and `/resume`

### Future Enhancements
- Session-based caching
- Parallel task list fetching
- Cross-project dashboard (`/my-tasks`)
- Auto-invoke `/triage` after selection
- Progress tracking and time logging
- Sprint/milestone filtering
- Team view and load balancing
- Custom filters (tags, priority, date range)

## Contributing

If you have suggestions for improving these commands or find issues:
1. Document the issue or enhancement idea
2. Share with your team
3. Consider contributing improvements to the command markdown files

## License

These commands are part of your team's Claude Code configuration and can be customized to fit your workflow needs.
