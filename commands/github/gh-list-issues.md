---
description: List GitHub issues with filters (helper)
allowedTools:
  - Bash
---

# GitHub CLI: List Issues

Lists GitHub issues with optional filters for state, labels, assignees, and more.

## Usage

```bash
/gh-list-issues
/gh-list-issues --state open
/gh-list-issues --label bug --label urgent
/gh-list-issues --assignee @me
/gh-list-issues --state closed --limit 50
/gh-list-issues --milestone "v2.0"
```

## Input Parameters

- **--state** (optional): Filter by state (`open`, `closed`, `all`) - default: `open`
- **--label** (optional, repeatable): Filter by label
- **--assignee** (optional): Filter by assignee (`@me` for self)
- **--author** (optional): Filter by author
- **--milestone** (optional): Filter by milestone
- **--search** (optional): Search query string
- **--limit** (optional): Maximum number of results (default: 30)
- **--json** (optional): Output raw JSON

## Implementation

1. **Parse input parameters:**
   ```bash
   state="open"
   labels=()
   assignee=""
   author=""
   milestone=""
   search=""
   limit=30
   jsonOutput=false

   while [[ $# -gt 0 ]]; do
     case $1 in
       --state)
         state="$2"
         shift 2
         ;;
       --label)
         labels+=("$2")
         shift 2
         ;;
       --assignee)
         assignee="$2"
         shift 2
         ;;
       --author)
         author="$2"
         shift 2
         ;;
       --milestone)
         milestone="$2"
         shift 2
         ;;
       --search)
         search="$2"
         shift 2
         ;;
       --limit)
         limit="$2"
         shift 2
         ;;
       --json)
         jsonOutput=true
         shift
         ;;
       *)
         shift
         ;;
     esac
   done

   # Validate state
   if [ "$state" != "open" ] && [ "$state" != "closed" ] && [ "$state" != "all" ]; then
     echo "❌ Invalid state: $state"
     echo "   Valid states: open, closed, all"
     exit 1
   fi
   ```

2. **Build gh command:**
   ```bash
   cmd="gh issue list --state $state --limit $limit"

   # Add label filters
   for label in "${labels[@]}"; do
     cmd="$cmd --label \"$label\""
   done

   # Add assignee filter
   if [ -n "$assignee" ]; then
     cmd="$cmd --assignee \"$assignee\""
   fi

   # Add author filter
   if [ -n "$author" ]; then
     cmd="$cmd --author \"$author\""
   fi

   # Add milestone filter
   if [ -n "$milestone" ]; then
     cmd="$cmd --milestone \"$milestone\""
   fi

   # Add search query
   if [ -n "$search" ]; then
     cmd="$cmd --search \"$search\""
   fi

   # Add JSON output format
   if [ "$jsonOutput" = true ]; then
     cmd="$cmd --json number,title,state,author,assignees,labels,createdAt,updatedAt"
   fi
   ```

3. **Execute and format output:**
   ```bash
   echo "🔍 Listing issues..."
   echo ""

   # Show active filters
   [ "$state" != "open" ] && echo "   State: $state"
   [ ${#labels[@]} -gt 0 ] && echo "   Labels: ${labels[*]}"
   [ -n "$assignee" ] && echo "   Assignee: $assignee"
   [ -n "$author" ] && echo "   Author: $author"
   [ -n "$milestone" ] && echo "   Milestone: $milestone"
   [ -n "$search" ] && echo "   Search: $search"
   echo ""

   result=$(eval "$cmd" 2>&1)

   if [ $? -ne 0 ]; then
     echo "❌ Failed to list issues"
     echo "$result"
     exit 1
   fi

   if [ "$jsonOutput" = true ]; then
     echo "$result" | jq '.'
   else
     if [ -z "$result" ]; then
       echo "📋 No issues found matching filters"
     else
       echo "📋 Issues:"
       echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
       echo ""
       echo "$result"
       echo ""
       count=$(echo "$result" | wc -l)
       echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
       echo "Total: $count issues"
     fi
   fi
   ```

**Success response (formatted):**
```text
🔍 Listing issues...

   Labels: bug urgent

📋 Issues:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#123  OPEN   Implement user authentication        bug, urgent
#456  OPEN   Fix login timeout                    bug
#789  OPEN   API returns 500 on edge case         bug, urgent

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: 3 issues
```

**Success response (JSON):**
```json
[
  {
    "number": 123,
    "title": "Implement user authentication",
    "state": "OPEN",
    "author": { "login": "username" },
    "assignees": [{ "login": "developer1" }],
    "labels": [{ "name": "bug" }, { "name": "urgent" }],
    "createdAt": "2024-12-07T10:00:00Z",
    "updatedAt": "2024-12-08T14:30:00Z"
  }
]
```

## Error Handling

**If invalid state:**
```text
❌ Invalid state: pending
   Valid states: open, closed, all
```

**If label not found:**
```text
🔍 Listing issues...

   Labels: nonexistent

📋 No issues found matching filters
```

**If not authenticated:**
```text
❌ Failed to list issues

You may need to authenticate:
  gh auth login
```

## Notes

- **Authentication**: Requires `gh auth login` to be configured
- **Permissions**: User must have read access to the repository
- **Default state**: Shows open issues by default
- **Limit**: Default 30, increase with `--limit` for more results
- **Performance**: Large result sets may take longer to fetch

## Use Cases

### View Open Issues

```bash
# All open issues
/gh-list-issues

# Open bugs
/gh-list-issues --label bug
```

### Filter by Assignee

```bash
# My assigned issues
/gh-list-issues --assignee @me

# Unassigned issues
/gh-list-issues --assignee ""
```

### Filter by Multiple Labels

```bash
# High priority bugs
/gh-list-issues --label bug --label "priority:high"

# Features in current milestone
/gh-list-issues --label "type:feature" --milestone "v2.0"
```

### View Closed Issues

```bash
# Recently closed
/gh-list-issues --state closed --limit 10

# All issues (open and closed)
/gh-list-issues --state all
```

### Search Issues

```bash
# Search for authentication related
/gh-list-issues --search "authentication"

# Search in title only
/gh-list-issues --search "in:title login"
```

### Integration with Work System

```bash
# List issues to analyze for dependencies
/gh-list-issues --state open --json

# List issues by work type
/gh-list-issues --label "type:story" --state open

# Find blocked issues
/gh-list-issues --label "status:blocked"
```

### Triage Workflow

```bash
# Find issues needing triage
/gh-list-issues --label "status:needs-triage"

# After triage, list by priority
/gh-list-issues --label "priority:high" --state open
```

## Related Commands

- `/gh-get-issue` - Get single issue details
- `/gh-create-issue` - Create new issue
- `/gh-update-issue` - Update issue properties
- `/gh-issue-comment` - Add comment to issue
- `/gh-issue-dependency` - Set dependencies
