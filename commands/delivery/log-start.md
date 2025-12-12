---
description: Log story start to delivery-log.csv and post Teamwork comment (helper)
allowedTools:
  - Bash
  - Read
  - SlashCommand
---

# Delivery: Log Story Start

Logs the start of a story to delivery-log.csv and optionally posts a comment to the associated Teamwork task.

## Usage

```bash
/delivery:log-start 1.1.1 "Fetch from Stax Bill" feature/1.1.1-fetch-from-staxbill
/delivery:log-start 1.1.2 "Update Local Database" feature/1.1.2-update-local-database 26262388
/delivery:log-start 1.1.3 "Apply Grace Period Logic" feature/1.1.3-grace-period-logic 26262388 dev-support/tasks/tw-26253606/delivery-log.csv
```

## Input Parameters

- **story_id** (required): Story ID (e.g., "1.1.1", "1.1.2")
- **title** (required): Story title
- **branch** (required): Git branch name
- **teamwork_task_id** (optional): Teamwork task ID for posting comment
- **csv_file** (optional): Path to delivery-log.csv (default: auto-detect from dev-support/tasks/*/delivery-log.csv)

## Implementation

1. **Parse input:**
   ```bash
   story_id=$1
   title=$2
   branch=$3
   teamwork_task_id=$4  # optional
   csv_file=$5          # optional

   # Validate required parameters
   if [ -z "$story_id" ] || [ -z "$title" ] || [ -z "$branch" ]; then
     echo "❌ Missing required parameters"
     exit 1
   fi
   ```

2. **Auto-detect CSV file if not provided:**
   ```bash
   if [ -z "$csv_file" ]; then
     # Search for delivery-log.csv in dev-support/tasks/*/
     csv_file=$(find dev-support/tasks -name "delivery-log.csv" -type f 2>/dev/null | head -n 1)

     if [ -z "$csv_file" ]; then
       echo "❌ Could not find delivery-log.csv"
       echo ""
       echo "Please specify path:"
       echo "  /delivery:log-start $story_id \"$title\" $branch $teamwork_task_id path/to/delivery-log.csv"
       exit 1
     fi

     echo "📄 Using CSV: $csv_file"
   fi
   ```

3. **Generate timestamp:**
   ```bash
   started_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
   ```

4. **Read current row to preserve created_at:**
   ```bash
   current_row=$(grep "^${story_id}," "$csv_file" 2>/dev/null)

   if [ -z "$current_row" ]; then
     # Story doesn't exist, create it with started_at as created_at
     created_at=$started_at
     echo "${story_id},${title},in_progress,${branch},${created_at},${started_at},,,,,," >> "$csv_file"
   else
     # Story exists, preserve created_at
     created_at=$(echo "$current_row" | cut -d',' -f5)

     # Update the row
     sed -i "/^${story_id},/c\\${story_id},${title},in_progress,${branch},${created_at},${started_at},,,,,," "$csv_file"
   fi
   ```

5. **Post Teamwork comment (if task ID provided):**
   ```bash
   if [ -n "$teamwork_task_id" ]; then
     comment_body="## Story ${story_id} Started

**Title:** ${title}
**Branch:** \`${branch}\`
**Started:** ${started_at}

Beginning implementation."

     /teamwork:tw-create-comment "$teamwork_task_id" "$comment_body"
   fi
   ```

6. **Output result:**

**Success response:**
```text
✅ Story 1.1.1 logged as started

   Story ID: 1.1.1
   Title: Fetch from Stax Bill
   Branch: feature/1.1.1-fetch-from-staxbill
   Status: in_progress
   Started: 2025-12-11T18:30:00Z
   CSV: dev-support/tasks/tw-26253606/delivery-log.csv
   Teamwork: Comment posted to task 26262388
```

## Error Handling

**If missing required parameters:**
```text
❌ Missing required parameters

Usage: /delivery:log-start <story_id> <title> <branch> [teamwork_task_id] [csv_file]

Examples:
  /delivery:log-start 1.1.1 "Story Title" feature/1.1.1-story-slug
  /delivery:log-start 1.1.2 "Story Title" feature/1.1.2-story-slug 26262388
  /delivery:log-start 1.1.3 "Story Title" feature/1.1.3-story-slug 26262388 path/to/delivery-log.csv

Parameters:
  story_id           - Story ID (e.g., "1.1.1")
  title              - Story title (use quotes)
  branch             - Git branch name
  teamwork_task_id   - Optional: Teamwork task ID for comment
  csv_file           - Optional: Path to delivery-log.csv (auto-detected if not provided)
```

**If CSV file not found:**
```text
❌ Could not find delivery-log.csv

Searched in: dev-support/tasks/*/delivery-log.csv

Please specify path:
  /delivery:log-start 1.1.1 "Story Title" branch-name task-id path/to/delivery-log.csv
```

**If Teamwork comment fails:**
```text
⚠️  Story logged but Teamwork comment failed

Story 1.1.1 successfully logged to CSV, but could not post comment to Teamwork task 26262388.
Check Teamwork credentials and task ID.
```

## Notes

- **Auto-detection**: Automatically finds delivery-log.csv in dev-support/tasks/*/ if not specified
- **Idempotent**: Running multiple times updates the same row (preserves created_at)
- **Timestamps**: All timestamps in ISO 8601 UTC format
- **CSV format**: Maintains compatibility with delivery-log.csv structure
- **Optional Teamwork**: Can be used with or without Teamwork integration

## CSV Format

The command updates/creates rows in this format:

```csv
story_id,title,status,branch,created_at,started_at,completed_at,lead_time_hours,cycle_time_hours,pr_url,tests_added,notes
1.1.1,Fetch from Stax Bill,in_progress,feature/1.1.1-fetch-from-staxbill,2025-12-08T12:00:00Z,2025-12-11T18:30:00Z,,,,,,
```

**Fields set by log-start:**
- `story_id` - Story identifier
- `title` - Story title
- `status` - Set to "in_progress"
- `branch` - Git branch name
- `created_at` - Preserved if exists, otherwise set to started_at
- `started_at` - Current timestamp

**Fields left empty (set by log-complete):**
- `completed_at`, `lead_time_hours`, `cycle_time_hours`, `pr_url`, `tests_added`, `notes`

## Use Cases

### Start First Story
```bash
# Story doesn't exist in CSV yet
/delivery:log-start 1.1.1 "Fetch from Stax Bill" feature/1.1.1-fetch-from-staxbill 26262388
# Creates new row with created_at = started_at
```

### Restart Story After Pause
```bash
# Story already exists with created_at from earlier
/delivery:log-start 1.1.1 "Fetch from Stax Bill" feature/1.1.1-fetch-from-staxbill 26262388
# Preserves original created_at, updates started_at to now
```

### Start Without Teamwork Integration
```bash
# No Teamwork task ID
/delivery:log-start 1.1.2 "Update Local Database" feature/1.1.2-update-local-database
# Logs to CSV only, no comment posted
```

### Specify Custom CSV Location
```bash
# Explicit CSV path
/delivery:log-start 1.1.3 "Apply Grace Period Logic" feature/1.1.3-grace-period-logic 26262388 custom/path/delivery-log.csv
```

## Integration with Workflow

Typical story workflow:

```bash
# 1. Start the story
/delivery:log-start 1.1.1 "Fetch from Stax Bill" feature/1.1.1-fetch-from-staxbill 26262388

# 2. Create feature branch
/git:git-create-branch feature/1.1.1-fetch-from-staxbill

# 3. Implement with TDD
# ... development work ...

# 4. Complete the story
/delivery:log-complete 1.1.1 https://pr-url 4 "Implemented with retry logic"
```

## Best Practices

1. **Always log at story start**
   - Run immediately after selecting story from backlog
   - Before creating feature branch
   - Ensures accurate cycle time tracking

2. **Use consistent story IDs**
   - Follow hierarchical format: 1.1.1, 1.1.2, etc.
   - Match IDs across all documentation

3. **Descriptive titles**
   - Use clear, actionable titles
   - Match titles in specifications

4. **Branch naming convention**
   - Format: feature/{story_id}-{slug}
   - Example: feature/1.1.1-fetch-from-staxbill

5. **Teamwork integration**
   - Always provide task ID when available
   - Creates audit trail in Teamwork
   - Keeps stakeholders informed
