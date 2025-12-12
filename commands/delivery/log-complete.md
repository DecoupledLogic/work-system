---
description: Log story completion with metrics to delivery-log.csv and post Teamwork comment (helper)
allowedTools:
  - Bash
  - Read
  - SlashCommand
---

# Delivery: Log Story Complete

Logs story completion to delivery-log.csv, calculates lead time and cycle time metrics, and optionally posts a completion comment to Teamwork.

## Usage

```bash
/delivery:log-complete 1.1.1 https://azuredevops.../pr/1045 4
/delivery:log-complete 1.1.2 https://azuredevops.../pr/1046 3 "Added ProviderSubscriptionId field"
/delivery:log-complete 1.1.3 https://azuredevops.../pr/1047 5 "Implemented with exponential backoff" 26262388
/delivery:log-complete 1.1.4 https://azuredevops.../pr/1048 2 "Edge cases handled" 26262388 dev-support/tasks/tw-26253606/delivery-log.csv
```

## Input Parameters

- **story_id** (required): Story ID (e.g., "1.1.1")
- **pr_url** (required): Pull request URL
- **tests_added** (required): Number of tests added
- **notes** (optional): Completion notes
- **teamwork_task_id** (optional): Teamwork task ID for posting comment
- **csv_file** (optional): Path to delivery-log.csv (default: auto-detect)

## Implementation

1. **Parse input:**
   ```bash
   story_id=$1
   pr_url=$2
   tests_added=$3
   notes=$4              # optional
   teamwork_task_id=$5   # optional
   csv_file=$6           # optional

   # Validate required parameters
   if [ -z "$story_id" ] || [ -z "$pr_url" ] || [ -z "$tests_added" ]; then
     echo "❌ Missing required parameters"
     exit 1
   fi

   # Validate tests_added is numeric
   if ! [[ "$tests_added" =~ ^[0-9]+$ ]]; then
     echo "❌ tests_added must be a number"
     exit 1
   fi
   ```

2. **Auto-detect CSV file if not provided:**
   ```bash
   if [ -z "$csv_file" ]; then
     csv_file=$(find dev-support/tasks -name "delivery-log.csv" -type f 2>/dev/null | head -n 1)

     if [ -z "$csv_file" ]; then
       echo "❌ Could not find delivery-log.csv"
       exit 1
     fi

     echo "📄 Using CSV: $csv_file"
   fi
   ```

3. **Read current row:**
   ```bash
   current_row=$(grep "^${story_id}," "$csv_file")

   if [ -z "$current_row" ]; then
     echo "❌ Story ${story_id} not found in CSV"
     echo ""
     echo "Did you run /delivery:log-start first?"
     exit 1
   fi

   # Extract timestamps
   title=$(echo "$current_row" | cut -d',' -f2)
   branch=$(echo "$current_row" | cut -d',' -f4)
   created_at=$(echo "$current_row" | cut -d',' -f5)
   started_at=$(echo "$current_row" | cut -d',' -f6)

   if [ -z "$started_at" ]; then
     echo "❌ Story has no started_at timestamp"
     echo ""
     echo "Run /delivery:log-start before log-complete"
     exit 1
   fi
   ```

4. **Generate completion timestamp:**
   ```bash
   completed_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
   ```

5. **Calculate metrics:**
   ```bash
   # Convert ISO 8601 timestamps to epoch seconds
   created_seconds=$(date -d "$created_at" +%s)
   started_seconds=$(date -d "$started_at" +%s)
   completed_seconds=$(date -d "$completed_at" +%s)

   # Calculate time differences in seconds
   lead_time_seconds=$((completed_seconds - created_seconds))
   cycle_time_seconds=$((completed_seconds - started_seconds))

   # Convert to hours (with 2 decimal places)
   lead_time_hours=$(echo "scale=2; $lead_time_seconds / 3600" | bc)
   cycle_time_hours=$(echo "scale=2; $cycle_time_seconds / 3600" | bc)
   ```

6. **Update CSV row:**
   ```bash
   # Escape commas in notes field
   notes_escaped=$(echo "$notes" | sed 's/,/;/g')

   # Build complete row
   new_row="${story_id},${title},completed,${branch},${created_at},${started_at},${completed_at},${lead_time_hours},${cycle_time_hours},${pr_url},${tests_added},${notes_escaped}"

   # Update CSV
   sed -i "/^${story_id},/c\\${new_row}" "$csv_file"
   ```

7. **Post Teamwork comment (if task ID provided):**
   ```bash
   if [ -n "$teamwork_task_id" ]; then
     comment_body="## Story ${story_id} Completed

**Title:** ${title}
**PR:** ${pr_url}
**Completed:** ${completed_at}

### Metrics
- **Lead Time:** ${lead_time_hours} hours
- **Cycle Time:** ${cycle_time_hours} hours
- **Tests Added:** ${tests_added}

### Changes
${notes}

✅ Story complete and merged to main."

     /teamwork:tw-create-comment "$teamwork_task_id" "$comment_body"
   fi
   ```

8. **Output result:**

**Success response:**
```text
✅ Story 1.1.1 logged as completed

   Story ID: 1.1.1
   Title: Fetch from Stax Bill
   Status: completed
   Completed: 2025-12-11T21:30:00Z

   📊 Metrics:
      Lead Time: 30.50 hours (created → completed)
      Cycle Time: 3.00 hours (started → completed)
      Flow Efficiency: 9.84% (cycle/lead)

   🔗 PR: https://azuredevops.../pullrequest/1045
   ✅ Tests Added: 4
   📝 Notes: Implemented with retry logic

   CSV: dev-support/tasks/tw-26253606/delivery-log.csv
   Teamwork: Comment posted to task 26262388
```

## Error Handling

**If missing required parameters:**
```text
❌ Missing required parameters

Usage: /delivery:log-complete <story_id> <pr_url> <tests_added> [notes] [teamwork_task_id] [csv_file]

Examples:
  /delivery:log-complete 1.1.1 https://pr-url 4
  /delivery:log-complete 1.1.2 https://pr-url 3 "Story notes"
  /delivery:log-complete 1.1.3 https://pr-url 5 "Notes" 26262388
  /delivery:log-complete 1.1.4 https://pr-url 2 "Notes" 26262388 path/to/delivery-log.csv

Parameters:
  story_id           - Story ID (e.g., "1.1.1")
  pr_url             - Pull request URL
  tests_added        - Number of tests added (numeric)
  notes              - Optional: Completion notes
  teamwork_task_id   - Optional: Teamwork task ID for comment
  csv_file           - Optional: Path to delivery-log.csv (auto-detected)
```

**If story not started:**
```text
❌ Story 1.1.1 not found in CSV

Did you run /delivery:log-start first?

To start tracking:
  /delivery:log-start 1.1.1 "Story Title" feature/1.1.1-story-slug
```

**If tests_added not numeric:**
```text
❌ Invalid tests_added value: "abc"

tests_added must be a number (e.g., 0, 3, 5, 10)
```

**If Teamwork comment fails:**
```text
⚠️  Story logged but Teamwork comment failed

Story 1.1.1 successfully logged to CSV with metrics, but could not post comment to Teamwork task 26262388.
Check Teamwork credentials and task ID.
```

## Notes

- **Requires log-start**: Story must be started with `/delivery:log-start` before completion
- **Automatic metrics**: Calculates lead time and cycle time automatically
- **Flow efficiency**: Displayed as (cycle_time / lead_time) × 100%
- **Idempotent**: Can be run multiple times (updates metrics based on current time)
- **CSV format**: Maintains compatibility with delivery-log.csv structure

## Metrics Definitions

### Lead Time
**Total time from story creation to completion**

```
Lead Time = completed_at - created_at
```

Includes:
- Wait time (in backlog)
- Development time
- Review time
- Deployment time

### Cycle Time
**Active working time on the story**

```
Cycle Time = completed_at - started_at
```

Includes:
- Development time
- Testing time
- Review time
- PR time

Excludes:
- Wait time in backlog

### Flow Efficiency
**Ratio of active work to total lead time**

```
Flow Efficiency = (Cycle Time / Lead Time) × 100%
```

**Target:**
- > 40% is good
- > 60% is excellent

## CSV Format

The command updates rows to this format:

```csv
story_id,title,status,branch,created_at,started_at,completed_at,lead_time_hours,cycle_time_hours,pr_url,tests_added,notes
1.1.1,Fetch from Stax Bill,completed,feature/1.1.1-fetch-from-staxbill,2025-12-08T12:00:00Z,2025-12-11T18:30:00Z,2025-12-11T21:30:00Z,81.50,3.00,https://...,4,Implemented with retry logic
```

**Fields set by log-complete:**
- `status` - Set to "completed"
- `completed_at` - Current timestamp
- `lead_time_hours` - Calculated from created_at to completed_at
- `cycle_time_hours` - Calculated from started_at to completed_at
- `pr_url` - Pull request URL
- `tests_added` - Number of tests added
- `notes` - Completion notes (commas replaced with semicolons)

## Use Cases

### Complete Story with Minimal Info
```bash
# Just story ID, PR URL, and test count
/delivery:log-complete 1.1.1 https://azuredevops.../pr/1045 4
```

### Complete with Descriptive Notes
```bash
# Add notes about what was implemented
/delivery:log-complete 1.1.2 https://azuredevops.../pr/1046 3 "Added ProviderSubscriptionId field and migration"
```

### Complete with Teamwork Integration
```bash
# Post comment to Teamwork task
/delivery:log-complete 1.1.3 https://azuredevops.../pr/1047 5 "Implemented grace period logic with tests" 26262388
```

### Complete with Custom CSV Location
```bash
# Specify CSV path explicitly
/delivery:log-complete 1.1.4 https://azuredevops.../pr/1048 2 "Edge cases handled" 26262388 custom/path/delivery-log.csv
```

## Integration with Workflow

Typical story completion workflow:

```bash
# 1. Merge PR and confirm success
/azuredevops:ado-merge-pr 1045 --repository SubscriptionsMicroservice --project Atlas --squash

# 2. Log completion with metrics
/delivery:log-complete 1.1.1 https://azuredevops.../pr/1045 4 "Story implementation notes" 26262388

# 3. Sync main branch
/git:git-sync

# 4. Delete feature branch
/git:git-delete-branch feature/1.1.1-fetch-from-staxbill --local --remote
```

## Best Practices

1. **Complete immediately after merge**
   - Run as soon as PR is merged
   - Ensures accurate metrics
   - Provides real-time progress tracking

2. **Record actual test count**
   - Count unit tests, integration tests
   - Include all tests added for the story
   - Use 0 if no tests added (but this is discouraged)

3. **Meaningful notes**
   - Summarize what was implemented
   - Mention key technical decisions
   - Note any gotchas or learnings

4. **Verify metrics**
   - Check lead time seems reasonable
   - Verify cycle time matches actual work time
   - Investigate if flow efficiency is very low

5. **Keep CSV clean**
   - Don't manually edit completed rows
   - Use /delivery:log-update for corrections
   - Maintain one row per story

## Metrics Analysis

After completing multiple stories, analyze trends:

```bash
# View CSV to analyze metrics
cat dev-support/tasks/tw-26253606/delivery-log.csv

# Calculate averages (using spreadsheet or awk)
awk -F',' 'NR>1 && $3=="completed" {sum+=$8; count++} END {print "Avg Lead Time:", sum/count, "hours"}' delivery-log.csv
awk -F',' 'NR>1 && $3=="completed" {sum+=$9; count++} END {print "Avg Cycle Time:", sum/count, "hours"}' delivery-log.csv
```

**Good metrics indicate:**
- ✅ Consistent cycle times (predictable velocity)
- ✅ Short lead times (quick delivery)
- ✅ High flow efficiency (minimal wait time)
- ✅ Increasing test coverage (quality focus)

**Red flags:**
- ⚠️  Highly variable cycle times (estimation issues)
- ⚠️  Long lead times (process bottlenecks)
- ⚠️  Low flow efficiency (<20%) (too much wait time)
- ⚠️  Zero tests added (quality risk)
