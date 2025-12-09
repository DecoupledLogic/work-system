---
description: Create a new GitHub issue with labels (helper)
allowedTools:
  - Bash
---

# GitHub CLI: Create Issue

Creates a new GitHub issue with optional labels, assignees, and milestone.

## Usage

```bash
/gh-create-issue "Issue title" "Issue body"
/gh-create-issue "Bug: Login fails" "Users cannot login" --label bug
/gh-create-issue "Feature request" "Add dark mode" --label "type:feature" --label "impact:high"
/gh-create-issue "Task title" "Description" --assignee @me
```

## Input Parameters

- **title** (required): The issue title
- **body** (required): The issue body/description
- **--label** (optional, repeatable): Labels to apply to the issue
- **--assignee** (optional): Assignee username (use `@me` for self)
- **--milestone** (optional): Milestone name or number

## Implementation

1. **Parse input parameters:**
   ```bash
   title=""
   body=""
   labels=()
   assignee=""
   milestone=""

   # Parse arguments
   while [[ $# -gt 0 ]]; do
     case $1 in
       --label)
         labels+=("$2")
         shift 2
         ;;
       --assignee)
         assignee="$2"
         shift 2
         ;;
       --milestone)
         milestone="$2"
         shift 2
         ;;
       *)
         if [ -z "$title" ]; then
           title="$1"
         elif [ -z "$body" ]; then
           body="$1"
         fi
         shift
         ;;
     esac
   done

   # Validate required parameters
   if [ -z "$title" ]; then
     echo "❌ Missing required parameter: title"
     echo ""
     echo "Usage: /gh-create-issue \"title\" \"body\" [options]"
     echo ""
     echo "Options:"
     echo "  --label <name>      Add label (repeatable)"
     echo "  --assignee <user>   Assign to user (@me for self)"
     echo "  --milestone <name>  Add to milestone"
     echo ""
     echo "Examples:"
     echo "  /gh-create-issue \"Bug: Login fails\" \"Users cannot login\""
     echo "  /gh-create-issue \"Feature\" \"Description\" --label bug --label urgent"
     exit 1
   fi

   # Default body if not provided
   if [ -z "$body" ]; then
     body="No description provided."
   fi
   ```

2. **Build gh command:**
   ```bash
   cmd="gh issue create --title \"$title\" --body \"$body\""

   # Add labels
   for label in "${labels[@]}"; do
     cmd="$cmd --label \"$label\""
   done

   # Add assignee
   if [ -n "$assignee" ]; then
     cmd="$cmd --assignee \"$assignee\""
   fi

   # Add milestone
   if [ -n "$milestone" ]; then
     cmd="$cmd --milestone \"$milestone\""
   fi
   ```

3. **Create issue:**
   ```bash
   echo "📝 Creating issue..."
   echo "   Title: $title"
   if [ ${#labels[@]} -gt 0 ]; then
     echo "   Labels: ${labels[*]}"
   fi
   if [ -n "$assignee" ]; then
     echo "   Assignee: $assignee"
   fi
   echo ""

   issueUrl=$(eval "$cmd" 2>&1)

   if [ $? -eq 0 ]; then
     issueNumber=$(echo "$issueUrl" | grep -oE '[0-9]+$')
     echo "✅ Issue created successfully"
     echo ""
     echo "   Issue: #$issueNumber"
     echo "   URL: $issueUrl"
   else
     echo "❌ Failed to create issue"
     echo ""
     echo "$issueUrl"
     exit 1
   fi
   ```

4. **Output result:**

**Success response:**
```json
{
  "issue": {
    "number": 5,
    "title": "Bug: Login fails",
    "url": "https://github.com/owner/repo/issues/5",
    "labels": ["bug", "urgent"],
    "assignee": "username"
  },
  "success": true
}
```

## Error Handling

**If missing title:**
```text
❌ Missing required parameter: title

Usage: /gh-create-issue "title" "body" [options]

Options:
  --label <name>      Add label (repeatable)
  --assignee <user>   Assign to user (@me for self)
  --milestone <name>  Add to milestone

Examples:
  /gh-create-issue "Bug: Login fails" "Users cannot login"
  /gh-create-issue "Feature" "Description" --label bug --label urgent
```

**If label doesn't exist:**
```text
❌ Failed to create issue

Label 'nonexistent' not found in repository.

Create the label first:
  gh label create "nonexistent" --color "#FF0000"
```

**If not authenticated:**
```text
❌ Failed to create issue

You may need to authenticate:
  gh auth login
```

Return error JSON:
```json
{
  "error": true,
  "message": "Label 'nonexistent' not found",
  "title": "Bug: Login fails"
}
```

## Notes

- **Authentication**: Requires `gh auth login` to be configured
- **Permissions**: User must have write access to the repository
- **Markdown support**: Body supports GitHub-flavored markdown
- **Labels**: Must exist in the repository before use

## Use Cases

### Bug Report

```bash
# Create bug with appropriate labels
/gh-create-issue "Bug: API returns 500" "Steps to reproduce..." --label bug --label "priority:high"
```

### Feature Request

```bash
# Create feature with work type labels
/gh-create-issue "Add dark mode support" "Users want dark mode..." --label "type:feature" --label "impact:high"
```

### Task from Work Item

```bash
# Create issue linked to Teamwork task
/gh-create-issue "Implement user auth" "See TW-26134585 for details" --label "type:story" --assignee @me
```

### With Milestone

```bash
# Create issue in a milestone
/gh-create-issue "Complete onboarding flow" "Details..." --milestone "v2.0" --label "type:feature"
```

## Integration with Work System

Create issues from work items:
```bash
# 1. Get work item details
/tw-get-task 26134585

# 2. Create corresponding GitHub issue
/gh-create-issue "Implement feature X" "From TW-26134585: description here" \
  --label "type:feature" --label "worktype:product_delivery"
```

Triage workflow:
```bash
# 1. Triage determines urgency and impact
/triage WI-123

# 2. Create issue with appropriate labels
/gh-create-issue "Process payment refunds" "Details..." \
  --label "urgency:now" --label "impact:high" --label "type:story"
```

## Related Commands

- `/gh-issue-comment` - Add comment to issue
- `/gh-issue-dependency` - Set blocked by/blocking relationships
- `/gh-create-pr` - Create PR (can reference issues)
- `/gh-status` - Check repository status
