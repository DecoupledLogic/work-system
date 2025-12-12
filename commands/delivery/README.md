# Delivery Commands

Story delivery automation commands for tracking story progress, metrics, and posting updates to Teamwork.

## Commands

| Command | Description |
|---------|-------------|
| `/delivery:log-start` | Log story start with timestamp and Teamwork comment |
| `/delivery:log-complete` | Log completion with metrics (lead time, cycle time) |
| `/delivery:log-update` | Update specific CSV fields |

## Overview

The delivery commands automate tracking of story delivery metrics in a CSV log file (`delivery-log.csv`). They integrate with Teamwork for automated status updates and provide real-time metrics for lead time, cycle time, and flow efficiency.

## Quick Start

### 1. Start a Story

```bash
/delivery:log-start 1.1.1 "Fetch from Stax Bill" feature/1.1.1-fetch-from-staxbill 26262388
```

**What it does:**
- Records start timestamp in delivery-log.csv
- Sets status to "in_progress"
- Posts "Story Started" comment to Teamwork task

### 2. Complete a Story

```bash
/delivery:log-complete 1.1.1 https://azuredevops.../pr/1045 4 "Implemented with retry logic" 26262388
```

**What it does:**
- Records completion timestamp
- Calculates lead time and cycle time
- Updates CSV with PR URL, test count, and notes
- Posts "Story Completed" comment with metrics to Teamwork

### 3. Update Story Info (if needed)

```bash
/delivery:log-update 1.1.1 notes "Added exponential backoff pattern"
```

**What it does:**
- Updates specific field in CSV
- Useful for corrections or adding missing info

## CSV Format

**File:** `dev-support/tasks/{task-id}/delivery-log.csv`

```csv
story_id,title,status,branch,created_at,started_at,completed_at,lead_time_hours,cycle_time_hours,pr_url,tests_added,notes
1.1.1,Fetch from Stax Bill,completed,feature/1.1.1-fetch-from-staxbill,2025-12-08T12:00:00Z,2025-12-11T18:30:00Z,2025-12-11T21:30:00Z,81.50,3.00,https://...,4,Retry logic
1.1.2,Update Local Database,in_progress,feature/1.1.2-update-local-database,2025-12-09T23:00:00Z,2025-12-09T23:00:00Z,,,,,,
1.1.3,Apply Grace Period Logic,pending,feature/1.1.3-grace-period-logic,,,,,,,,
```

### Field Descriptions

| Field | Description | Set By |
|-------|-------------|--------|
| `story_id` | Story identifier (e.g., "1.1.1") | Manual or log-start |
| `title` | Story title | log-start |
| `status` | pending \| in_progress \| completed | log-start, log-complete |
| `branch` | Git branch name | log-start |
| `created_at` | ISO 8601 timestamp (story creation) | log-start |
| `started_at` | ISO 8601 timestamp (work started) | log-start |
| `completed_at` | ISO 8601 timestamp (work completed) | log-complete |
| `lead_time_hours` | Total time from creation to completion | log-complete (calculated) |
| `cycle_time_hours` | Active work time (started to completed) | log-complete (calculated) |
| `pr_url` | Pull request URL | log-complete |
| `tests_added` | Number of tests added | log-complete |
| `notes` | Completion notes | log-complete |

## Metrics

### Lead Time

**Total time from story creation to completion**

```
Lead Time = completed_at - created_at
```

**Includes:**
- Wait time (in backlog)
- Development time
- Review time
- Deployment time

### Cycle Time

**Active working time on the story**

```
Cycle Time = completed_at - started_at
```

**Includes:**
- Development time
- Testing time
- Review time
- PR time

**Excludes:**
- Wait time in backlog

### Flow Efficiency

**Ratio of active work to total lead time**

```
Flow Efficiency = (Cycle Time / Lead Time) × 100%
```

**Targets:**
- \> 40% is good
- \> 60% is excellent

## Workflow Integration

### Complete Story Workflow

```bash
# 1. Select story from backlog
/workflow:select-task

# 2. Log story start
/delivery:log-start 1.1.1 "Story Title" feature/1.1.1-story-slug 26262388

# 3. Create feature branch
/git:git-create-branch feature/1.1.1-story-slug

# 4. Implement with TDD (Red-Green-Refactor)
# ... development work ...

# 5. Run tests
/dotnet:test

# 6. Code review
/quality:code-review

# 7. Push and create PR
/git:git-push -u origin feature/1.1.1-story-slug
/azuredevops:ado-create-pr --repository RepoName --project Atlas --source-branch feature/1.1.1-story-slug --target-branch main --title "Story Title" --description "PR description"

# 8. Merge PR
/azuredevops:ado-merge-pr <PR_ID> --repository RepoName --project Atlas --squash --delete-source-branch

# 9. Log completion
/delivery:log-complete 1.1.1 https://pr-url 4 "Implementation notes" 26262388

# 10. Sync main branch
/git:git-sync
```

## Teamwork Integration

When Teamwork task ID is provided, commands post formatted comments:

### Start Comment
```markdown
## Story 1.1.1 Started

**Title:** Fetch from Stax Bill
**Branch:** `feature/1.1.1-fetch-from-staxbill`
**Started:** 2025-12-11T18:30:00Z

Beginning implementation.
```

### Completion Comment
```markdown
## Story 1.1.1 Completed

**Title:** Fetch from Stax Bill
**PR:** https://azuredevops.../pullrequest/1045
**Completed:** 2025-12-11T21:30:00Z

### Metrics
- **Lead Time:** 81.50 hours
- **Cycle Time:** 3.00 hours
- **Tests Added:** 4

### Changes
Implemented with retry logic and exponential backoff

✅ Story complete and merged to main.
```

## Best Practices

### 1. Log Immediately

**Start logging:**
- Run `/delivery:log-start` as soon as you begin work
- Before creating feature branch
- Ensures accurate cycle time

**Complete logging:**
- Run `/delivery:log-complete` immediately after PR merge
- Don't wait until end of day
- Maintains accurate metrics

### 2. Accurate Test Counts

```bash
# Count all tests added for the story
# Include unit tests, integration tests, etc.
/delivery:log-complete 1.1.1 https://pr-url 4 "Notes"

# Use 0 if no tests (but this is discouraged)
/delivery:log-complete 1.1.2 https://pr-url 0 "Hotfix - no tests added"
```

### 3. Meaningful Notes

```bash
# Good: Describes what was done
/delivery:log-complete 1.1.1 https://pr-url 4 "Implemented Staxbill sync with retry logic and exponential backoff"

# Avoid: Too vague
/delivery:log-complete 1.1.1 https://pr-url 4 "Done"
```

### 4. Always Include Teamwork ID

```bash
# Good: Posts comment to Teamwork
/delivery:log-start 1.1.1 "Title" branch 26262388

# Less optimal: No Teamwork update
/delivery:log-start 1.1.1 "Title" branch
```

### 5. Use log-update for Corrections Only

```bash
# Prefer using the primary commands
/delivery:log-start ...
/delivery:log-complete ...

# Only use log-update for corrections
/delivery:log-update 1.1.1 tests_added 5  # Fixed count
```

## Analyzing Metrics

### View All Metrics

```bash
cat dev-support/tasks/tw-26253606/delivery-log.csv
```

### Calculate Averages

```bash
# Average lead time (completed stories only)
awk -F',' 'NR>1 && $3=="completed" {sum+=$8; count++} END {print "Avg Lead Time:", sum/count, "hours"}' delivery-log.csv

# Average cycle time
awk -F',' 'NR>1 && $3=="completed" {sum+=$9; count++} END {print "Avg Cycle Time:", sum/count, "hours"}' delivery-log.csv

# Average flow efficiency
awk -F',' 'NR>1 && $3=="completed" {sum+=($9/$8)*100; count++} END {print "Avg Flow Efficiency:", sum/count, "%"}' delivery-log.csv
```

### Good Metrics Indicators

✅ **Consistent cycle times** - Predictable velocity
✅ **Short lead times** - Quick delivery
✅ **High flow efficiency (>40%)** - Minimal wait time
✅ **Increasing test coverage** - Quality focus

### Warning Signs

⚠️ **Highly variable cycle times** - Estimation issues
⚠️ **Long lead times** - Process bottlenecks
⚠️ **Low flow efficiency (<20%)** - Too much wait time
⚠️ **Zero tests added** - Quality risk

## File Location

Commands auto-detect `delivery-log.csv` in:
```
dev-support/tasks/*/delivery-log.csv
```

Or specify explicitly:
```bash
/delivery:log-start 1.1.1 "Title" branch 26262388 custom/path/delivery-log.csv
```

## Error Handling

Commands provide clear error messages:

```bash
# Missing required parameter
❌ Missing required parameters
Usage: /delivery:log-start <story_id> <title> <branch> [teamwork_task_id] [csv_file]

# Story not started
❌ Story 1.1.1 not found in CSV
Did you run /delivery:log-start first?

# Invalid field
❌ Invalid field: invalid_field
Valid fields: title, status, branch, pr_url, tests_added, notes
```

## See Also

- [log-start.md](log-start.md) - Detailed log-start documentation
- [log-complete.md](log-complete.md) - Detailed log-complete documentation
- [log-update.md](log-update.md) - Detailed log-update documentation
- [/workflow:deliver](../workflow/deliver.md) - Story delivery workflow
- [/teamwork:tw-create-comment](../teamwork/tw-create-comment.md) - Teamwork commenting
