---
description: Get details of a single GitHub issue (helper)
allowedTools:
  - Bash
---

# GitHub CLI: Get Issue

Fetches complete details of a single GitHub issue by number.

## Usage

```bash
/gh-get-issue 123
/gh-get-issue 123 --json
```

## Input Parameters

- **issueNumber** (required): The GitHub issue number
- **--json** (optional): Output raw JSON instead of formatted display

## Implementation

1. **Parse input parameters:**
   ```bash
   issueNumber=""
   jsonOutput=false

   while [[ $# -gt 0 ]]; do
     case $1 in
       --json)
         jsonOutput=true
         shift
         ;;
       *)
         if [[ "$1" =~ ^[0-9]+$ ]]; then
           issueNumber="$1"
         fi
         shift
         ;;
     esac
   done

   # Validate required parameters
   if [ -z "$issueNumber" ]; then
     echo "❌ Missing required parameter: issueNumber"
     echo ""
     echo "Usage: /gh-get-issue <number> [--json]"
     echo ""
     echo "Examples:"
     echo "  /gh-get-issue 123"
     echo "  /gh-get-issue 456 --json"
     exit 1
   fi
   ```

2. **Fetch issue details:**
   ```bash
   echo "🔍 Fetching issue #$issueNumber..."

   issueData=$(gh issue view "$issueNumber" --json number,title,body,state,author,assignees,labels,milestone,createdAt,updatedAt,closedAt,comments 2>&1)

   if [ $? -ne 0 ]; then
     echo "❌ Issue #$issueNumber not found"
     echo ""
     echo "Verify the issue exists:"
     echo "  gh issue view $issueNumber"
     exit 1
   fi
   ```

3. **Format and display output:**
   ```bash
   if [ "$jsonOutput" = true ]; then
     echo "$issueData" | jq '.'
     exit 0
   fi

   # Extract fields
   title=$(echo "$issueData" | jq -r '.title')
   state=$(echo "$issueData" | jq -r '.state')
   author=$(echo "$issueData" | jq -r '.author.login')
   body=$(echo "$issueData" | jq -r '.body // "No description"')
   createdAt=$(echo "$issueData" | jq -r '.createdAt')
   updatedAt=$(echo "$issueData" | jq -r '.updatedAt')

   # Format labels
   labels=$(echo "$issueData" | jq -r '.labels[].name' | tr '\n' ', ' | sed 's/,$//')
   [ -z "$labels" ] && labels="(none)"

   # Format assignees
   assignees=$(echo "$issueData" | jq -r '.assignees[].login' | tr '\n' ', ' | sed 's/,$//')
   [ -z "$assignees" ] && assignees="(unassigned)"

   # Format milestone
   milestone=$(echo "$issueData" | jq -r '.milestone.title // "(none)"')

   # Display formatted output
   echo ""
   echo "📋 Issue #$issueNumber: $title"
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   echo ""
   echo "State:     $state"
   echo "Author:    @$author"
   echo "Assignees: $assignees"
   echo "Labels:    $labels"
   echo "Milestone: $milestone"
   echo ""
   echo "Created:   $createdAt"
   echo "Updated:   $updatedAt"
   echo ""
   echo "Description:"
   echo "$body" | head -20
   if [ $(echo "$body" | wc -l) -gt 20 ]; then
     echo "..."
     echo "(truncated - use --json for full content)"
   fi
   ```

**Success response (formatted):**
```text
📋 Issue #123: Implement user authentication
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

State:     OPEN
Author:    @username
Assignees: @developer1, @developer2
Labels:    type:feature, impact:high
Milestone: v2.0

Created:   2024-12-07T10:00:00Z
Updated:   2024-12-08T14:30:00Z

Description:
Implement OAuth2 authentication flow...
```

**Success response (JSON):**
```json
{
  "number": 123,
  "title": "Implement user authentication",
  "body": "Implement OAuth2 authentication flow...",
  "state": "OPEN",
  "author": { "login": "username" },
  "assignees": [{ "login": "developer1" }],
  "labels": [{ "name": "type:feature" }],
  "milestone": { "title": "v2.0" },
  "createdAt": "2024-12-07T10:00:00Z",
  "updatedAt": "2024-12-08T14:30:00Z"
}
```

## Error Handling

**If issue not found:**
```text
❌ Issue #999 not found

Verify the issue exists:
  gh issue view 999
```

**If missing parameters:**
```text
❌ Missing required parameter: issueNumber

Usage: /gh-get-issue <number> [--json]

Examples:
  /gh-get-issue 123
  /gh-get-issue 456 --json
```

**If not authenticated:**
```text
❌ Issue #123 not found

You may need to authenticate:
  gh auth login
```

## Notes

- **Authentication**: Requires `gh auth login` to be configured
- **Permissions**: User must have read access to the repository
- **Full data**: Use `--json` flag to get complete issue data including full body
- **Comments**: Comment count included; use `gh issue view N --comments` for full comments

## Use Cases

### View Issue Details

```bash
# Quick view of issue status
/gh-get-issue 123

# Get full JSON for processing
/gh-get-issue 123 --json
```

### Before Setting Dependencies

```bash
# Check issue details before linking
/gh-get-issue 2
/gh-get-issue 3

# Then set dependency
/gh-issue-dependency 3 --blocked-by 2
```

### Integration with Work System

```bash
# 1. Check GitHub issue details
/gh-get-issue 123

# 2. Create linked work item
/work-item create --type task --name "Issue #123"
/work-item link WI-001 --external github:#123
```

## Related Commands

- `/gh-create-issue` - Create new issue
- `/gh-update-issue` - Update issue properties
- `/gh-list-issues` - List issues with filters
- `/gh-issue-comment` - Add comment to issue
- `/gh-issue-dependency` - Set dependencies
