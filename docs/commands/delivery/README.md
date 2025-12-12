# Delivery Commands

Story delivery metrics logging with Teamwork integration.

## Commands

| Command | Description |
|---------|-------------|
| `/delivery:log-start` | Log story start, post to Teamwork |
| `/delivery:log-complete` | Log completion with metrics |
| `/delivery:log-update` | Update specific CSV fields |

## Quick Examples

```bash
# Start story
/delivery:log-start 1.1.1 "Story Title" feature/branch 26262388

# Complete story
/delivery:log-complete 1.1.1 https://pr-url 4 "Implementation notes" 26262388

# Fix a field
/delivery:log-update 1.1.1 tests_added 5
```

## Metrics Tracked

- **Lead Time**: Total time from creation to completion
- **Cycle Time**: Active work time (started to completed)
- **Flow Efficiency**: Cycle Time / Lead Time

## CSV Output

```csv
story_id,title,status,branch,created_at,started_at,completed_at,lead_time_hours,cycle_time_hours,pr_url,tests_added,notes
1.1.1,Story Title,completed,feature/branch,...
```

## Teamwork Integration

When task ID provided, commands post formatted comments:
- Story started notification
- Completion summary with metrics

See source commands in [commands/delivery/](../../../commands/delivery/) for full documentation.
