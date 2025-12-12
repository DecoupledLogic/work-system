# Teamwork Commands

Direct Teamwork API commands for task and time management.

## Configuration

- `~/.teamwork/credentials.json` - API key and domain
- `~/.claude/teamwork.json` - User identity

## Commands

### Tasks

| Command | Description |
|---------|-------------|
| `/teamwork:tw-get-projects` | List all projects |
| `/teamwork:tw-get-tasklists` | Get task lists for project |
| `/teamwork:tw-get-tasks` | Get tasks from task list |
| `/teamwork:tw-get-task` | Get single task details |
| `/teamwork:tw-get-subtasks` | Get subtasks of parent |
| `/teamwork:tw-create-task` | Create subtask |
| `/teamwork:tw-update-task` | Update task properties |
| `/teamwork:tw-assign-task` | Assign/unassign users |
| `/teamwork:tw-create-comment` | Add comment to task |
| `/teamwork:tw-task-dependency` | Set predecessor/successor relationships |

### Time Logging

| Command | Description |
|---------|-------------|
| `/teamwork:tw-create-task-timelog` | Log time to task |
| `/teamwork:tw-get-task-timelogs` | Get task timelogs |
| `/teamwork:tw-get-subtasks-timelogs` | Get all subtask timelogs |
| `/teamwork:tw-get-project-timelogs` | Get project timelogs |

## Quick Examples

```bash
# Get tasks
/teamwork:tw-get-task 26134585

# Log time (auto-rounds to 15 min)
/teamwork:tw-create-task-timelog 26134585 "2025-12-07" 2 10 "Implementation work"

# Add comment
/teamwork:tw-create-comment 26134585 "Starting implementation"
```

See source commands in [commands/teamwork/](../../../commands/teamwork/) for full documentation.
