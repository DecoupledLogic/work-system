---
description: Update specific field in delivery-log.csv (helper)
allowedTools:
  - Bash
  - Read
---

# Delivery: Update Log Field

Updates a specific field in delivery-log.csv for a story. Useful for corrections or adding information after initial logging.

## Usage

```bash
/delivery:log-update 1.1.1 notes "Updated implementation notes"
/delivery:log-update 1.1.2 tests_added 5
/delivery:log-update 1.1.3 pr_url https://azuredevops.../pr/1047
/delivery:log-update 1.1.4 status completed dev-support/tasks/tw-26253606/delivery-log.csv
```

## Input Parameters

- **story_id** (required): Story ID (e.g., "1.1.1")
- **field** (required): Field name to update
- **value** (required): New value for the field
- **csv_file** (optional): Path to delivery-log.csv (default: auto-detect)

## Valid Fields

| Field | Type | Example | Description |
|-------|------|---------|-------------|
| `title` | string | "Fetch from Stax Bill" | Story title |
| `status` | enum | completed, in_progress, pending | Story status |
| `branch` | string | feature/1.1.1-story | Git branch name |
| `pr_url` | string | https://... | Pull request URL |
| `tests_added` | number | 5 | Number of tests added |
| `notes` | string | "Implementation details" | Completion notes |

**Note:** Timestamps (created_at, started_at, completed_at) and calculated metrics (lead_time_hours, cycle_time_hours) cannot be updated directly. Use `/delivery:log-start` or `/delivery:log-complete` instead.

## Implementation

1. **Parse input:**
   ```bash
   story_id=$1
   field=$2
   value=$3
   csv_file=$4  # optional

   # Validate required parameters
   if [ -z "$story_id" ] || [ -z "$field" ] || [ -z "$value" ]; then
     echo "❌ Missing required parameters"
     exit 1
   fi
   ```

2. **Validate field name:**
   ```bash
   valid_fields=("title" "status" "branch" "pr_url" "tests_added" "notes")

   if [[ ! " ${valid_fields[@]} " =~ " ${field} " ]]; then
     echo "❌ Invalid field: $field"
     echo ""
     echo "Valid fields: ${valid_fields[*]}"
     exit 1
   fi
   ```

3. **Validate field-specific constraints:**
   ```bash
   # Validate status enum
   if [ "$field" = "status" ]; then
     valid_statuses=("pending" "in_progress" "completed")
     if [[ ! " ${valid_statuses[@]} " =~ " ${value} " ]]; then
       echo "❌ Invalid status: $value"
       echo "Valid statuses: ${valid_statuses[*]}"
       exit 1
     fi
   fi

   # Validate tests_added is numeric
   if [ "$field" = "tests_added" ]; then
     if ! [[ "$value" =~ ^[0-9]+$ ]]; then
       echo "❌ tests_added must be a number"
       exit 1
     fi
   fi
   ```

4. **Auto-detect CSV file:**
   ```bash
   if [ -z "$csv_file" ]; then
     csv_file=$(find dev-support/tasks -name "delivery-log.csv" -type f 2>/dev/null | head -n 1)

     if [ -z "$csv_file" ]; then
       echo "❌ Could not find delivery-log.csv"
       exit 1
     fi
   fi
   ```

5. **Read current row:**
   ```bash
   current_row=$(grep "^${story_id}," "$csv_file")

   if [ -z "$current_row" ]; then
     echo "❌ Story ${story_id} not found in CSV"
     exit 1
   fi
   ```

6. **Determine field position:**
   ```bash
   # CSV columns (1-indexed):
   # 1=story_id, 2=title, 3=status, 4=branch, 5=created_at,
   # 6=started_at, 7=completed_at, 8=lead_time_hours,
   # 9=cycle_time_hours, 10=pr_url, 11=tests_added, 12=notes

   case "$field" in
     title) field_pos=2 ;;
     status) field_pos=3 ;;
     branch) field_pos=4 ;;
     pr_url) field_pos=10 ;;
     tests_added) field_pos=11 ;;
     notes) field_pos=12 ;;
   esac
   ```

7. **Update field value:**
   ```bash
   # Escape value for sed (escape commas, slashes, ampersands)
   value_escaped=$(echo "$value" | sed 's/,/;/g' | sed 's/[\/&]/\\&/g')

   # Split row into array
   IFS=',' read -ra fields <<< "$current_row"

   # Update the specific field (0-indexed array, so subtract 1)
   fields[$((field_pos-1))]="$value_escaped"

   # Rebuild row
   new_row=$(IFS=','; echo "${fields[*]}")

   # Update CSV
   sed -i "/^${story_id},/c\\${new_row}" "$csv_file"
   ```

8. **Output result:**

**Success response:**
```text
✅ Story 1.1.1 updated

   Field: notes
   Old Value: "Implemented with retry logic"
   New Value: "Implemented with retry logic and exponential backoff"

   CSV: dev-support/tasks/tw-26253606/delivery-log.csv
```

## Error Handling

**If missing required parameters:**
```text
❌ Missing required parameters

Usage: /delivery:log-update <story_id> <field> <value> [csv_file]

Examples:
  /delivery:log-update 1.1.1 notes "Updated notes"
  /delivery:log-update 1.1.2 tests_added 5
  /delivery:log-update 1.1.3 pr_url https://pr-url
  /delivery:log-update 1.1.4 status completed path/to/delivery-log.csv

Parameters:
  story_id  - Story ID (e.g., "1.1.1")
  field     - Field name (title, status, branch, pr_url, tests_added, notes)
  value     - New value for the field
  csv_file  - Optional: Path to delivery-log.csv (auto-detected)
```

**If invalid field:**
```text
❌ Invalid field: invalid_field_name

Valid fields:
  title        - Story title
  status       - Story status (pending, in_progress, completed)
  branch       - Git branch name
  pr_url       - Pull request URL
  tests_added  - Number of tests added (numeric)
  notes        - Completion notes
```

**If invalid status:**
```text
❌ Invalid status: invalid_status

Valid statuses: pending, in_progress, completed
```

**If story not found:**
```text
❌ Story 1.1.1 not found in CSV

Check story ID and CSV file path.
```

**If protected field update attempted:**
```text
❌ Cannot update protected field: created_at

Protected fields (timestamps and metrics) cannot be updated directly.
Use the appropriate log commands instead:
  - /delivery:log-start to update started_at
  - /delivery:log-complete to update completed_at and metrics
```

## Notes

- **Limited field updates**: Only editable fields can be updated (not timestamps or metrics)
- **Comma escaping**: Commas in values are automatically escaped to semicolons
- **Idempotent**: Running multiple times with same value is safe
- **No recalculation**: Updating fields does not recalculate metrics
- **Audit trail**: Consider posting Teamwork comment when making significant changes

## Use Cases

### Fix Story Title Typo
```bash
/delivery:log-update 1.1.1 title "Fetch from Stax Bill (corrected typo)"
```

### Add Missing PR URL
```bash
# Forgot to include PR URL during log-complete
/delivery:log-update 1.1.2 pr_url https://azuredevops.../pullrequest/1046
```

### Update Test Count
```bash
# Realized more tests were added
/delivery:log-update 1.1.3 tests_added 7
```

### Enhance Completion Notes
```bash
# Add more details to notes
/delivery:log-update 1.1.4 notes "Implemented with exponential backoff. Also added circuit breaker pattern for resilience."
```

### Change Story Status
```bash
# Mark story as pending if it needs to be restarted
/delivery:log-update 1.1.1 status pending
```

### Update Branch Name
```bash
# Branch was renamed
/delivery:log-update 1.1.2 branch feature/1.1.2-update-database-schema
```

## Integration with Workflow

Typical correction workflow:

```bash
# 1. Review delivery log
cat dev-support/tasks/tw-26253606/delivery-log.csv

# 2. Identify error or missing info
# Story 1.1.1 has wrong test count (should be 5, not 4)

# 3. Update the field
/delivery:log-update 1.1.1 tests_added 5

# 4. Optionally document the change in Teamwork
/teamwork:tw-create-comment 26262388 "Corrected test count for Story 1.1.1: was 4, should be 5"

# 5. Verify update
grep "^1.1.1," dev-support/tasks/tw-26253606/delivery-log.csv
```

## Best Practices

1. **Document corrections**
   - Post Teamwork comment when making significant updates
   - Explain why the change was needed
   - Maintain audit trail

2. **Use specific commands when possible**
   - Prefer `/delivery:log-start` for starting stories
   - Prefer `/delivery:log-complete` for completing stories
   - Use log-update only for corrections

3. **Verify before updating**
   - Check current value first
   - Ensure new value is correct
   - Consider impact on metrics

4. **Don't update metrics manually**
   - Never update lead_time_hours or cycle_time_hours
   - These are calculated automatically
   - Re-run log-complete if metrics need recalculation

5. **Batch updates if needed**
   - Multiple fields can be updated with multiple commands
   - Example:
     ```bash
     /delivery:log-update 1.1.1 pr_url https://new-url
     /delivery:log-update 1.1.1 tests_added 5
     /delivery:log-update 1.1.1 notes "Updated with new info"
     ```

## CSV Field Reference

```csv
story_id,title,status,branch,created_at,started_at,completed_at,lead_time_hours,cycle_time_hours,pr_url,tests_added,notes
```

**Editable via log-update:**
- Column 2: `title`
- Column 3: `status`
- Column 4: `branch`
- Column 10: `pr_url`
- Column 11: `tests_added`
- Column 12: `notes`

**Not editable (use appropriate log commands):**
- Column 1: `story_id` (immutable identifier)
- Column 5: `created_at` (set during creation)
- Column 6: `started_at` (use /delivery:log-start)
- Column 7: `completed_at` (use /delivery:log-complete)
- Column 8: `lead_time_hours` (calculated by log-complete)
- Column 9: `cycle_time_hours` (calculated by log-complete)

## Limitations

1. **No bulk updates** - One story, one field at a time
2. **No calculated fields** - Metrics are read-only
3. **No validation of related data** - Changing branch doesn't check git
4. **No audit log** - Changes not automatically tracked in Teamwork

## Future Enhancements

- Support bulk updates: `/delivery:log-update 1.1.* notes "Same note for all"`
- Add change history tracking
- Validate branch exists in git
- Auto-post Teamwork comment on update
- Support updating multiple fields at once
