---
description: Set blocked by/blocking relationships between GitHub issues (helper)
allowedTools:
  - Bash
---

# GitHub CLI: Issue Dependency

Creates or removes dependency relationships between GitHub issues using GitHub's native issue dependencies feature.

## Usage

```bash
/gh-issue-dependency 3 --blocked-by 2
/gh-issue-dependency 2 --blocking 3
/gh-issue-dependency 1 --blocked-by 3 --blocked-by 2
/gh-issue-dependency 5 --remove-blocked-by 3
```

## Input Parameters

- **issueNumber** (required): The issue to modify
- **--blocked-by** (optional, repeatable): Issue number that blocks this issue
- **--blocking** (optional, repeatable): Issue number that this issue blocks
- **--remove-blocked-by** (optional, repeatable): Remove blocked-by relationship
- **--remove-blocking** (optional, repeatable): Remove blocking relationship

## Implementation

1. **Parse input parameters:**
   ```bash
   issueNumber=""
   blockedBy=()
   blocking=()
   removeBlockedBy=()
   removeBlocking=()

   # First argument is the issue number
   if [[ $1 =~ ^[0-9]+$ ]]; then
     issueNumber="$1"
     shift
   fi

   # Parse remaining arguments
   while [[ $# -gt 0 ]]; do
     case $1 in
       --blocked-by)
         blockedBy+=("$2")
         shift 2
         ;;
       --blocking)
         blocking+=("$2")
         shift 2
         ;;
       --remove-blocked-by)
         removeBlockedBy+=("$2")
         shift 2
         ;;
       --remove-blocking)
         removeBlocking+=("$2")
         shift 2
         ;;
       *)
         shift
         ;;
     esac
   done

   # Validate required parameters
   if [ -z "$issueNumber" ]; then
     echo "❌ Missing required parameter: issueNumber"
     echo ""
     echo "Usage: /gh-issue-dependency <number> [options]"
     echo ""
     echo "Options:"
     echo "  --blocked-by <number>        Mark as blocked by issue (repeatable)"
     echo "  --blocking <number>          Mark as blocking issue (repeatable)"
     echo "  --remove-blocked-by <number> Remove blocked-by relationship"
     echo "  --remove-blocking <number>   Remove blocking relationship"
     echo ""
     echo "Examples:"
     echo "  /gh-issue-dependency 3 --blocked-by 2"
     echo "  /gh-issue-dependency 2 --blocking 3"
     echo "  /gh-issue-dependency 1 --blocked-by 2 --blocked-by 3"
     echo "  /gh-issue-dependency 5 --remove-blocked-by 3"
     exit 1
   fi

   # Validate at least one relationship specified
   if [ ${#blockedBy[@]} -eq 0 ] && [ ${#blocking[@]} -eq 0 ] && \
      [ ${#removeBlockedBy[@]} -eq 0 ] && [ ${#removeBlocking[@]} -eq 0 ]; then
     echo "❌ No relationship specified"
     echo ""
     echo "Specify at least one of:"
     echo "  --blocked-by <number>"
     echo "  --blocking <number>"
     echo "  --remove-blocked-by <number>"
     echo "  --remove-blocking <number>"
     exit 1
   fi
   ```

2. **Get repository info and issue node IDs:**
   ```bash
   echo "🔍 Fetching issue information..."

   # Get repo owner and name
   repoInfo=$(gh repo view --json owner,name)
   owner=$(echo "$repoInfo" | jq -r '.owner.login')
   repo=$(echo "$repoInfo" | jq -r '.name')

   # Build list of all issue numbers we need
   allIssues=("$issueNumber" "${blockedBy[@]}" "${blocking[@]}" "${removeBlockedBy[@]}" "${removeBlocking[@]}")
   uniqueIssues=($(printf '%s\n' "${allIssues[@]}" | sort -u))

   # Build GraphQL query to get all node IDs
   query="{ repository(owner: \"$owner\", name: \"$repo\") {"
   for num in "${uniqueIssues[@]}"; do
     query="$query issue$num: issue(number: $num) { id number title }"
   done
   query="$query }}"

   issueData=$(gh api graphql -f query="$query")

   if [ $? -ne 0 ]; then
     echo "❌ Failed to fetch issue data"
     exit 1
   fi

   # Extract node ID for main issue
   mainIssueId=$(echo "$issueData" | jq -r ".data.repository.issue$issueNumber.id")
   mainIssueTitle=$(echo "$issueData" | jq -r ".data.repository.issue$issueNumber.title")

   if [ "$mainIssueId" == "null" ]; then
     echo "❌ Issue #$issueNumber not found"
     exit 1
   fi

   echo "   #$issueNumber: $mainIssueTitle"
   echo ""
   ```

3. **Add blocked-by relationships:**
   ```bash
   for blockerNum in "${blockedBy[@]}"; do
     blockerId=$(echo "$issueData" | jq -r ".data.repository.issue$blockerNum.id")
     blockerTitle=$(echo "$issueData" | jq -r ".data.repository.issue$blockerNum.title")

     if [ "$blockerId" == "null" ]; then
       echo "⚠️  Issue #$blockerNum not found, skipping"
       continue
     fi

     echo "🔗 Setting #$issueNumber blocked by #$blockerNum..."

     result=$(gh api graphql -f query="
       mutation {
         addBlockedBy(input: {
           issueId: \"$mainIssueId\"
           blockingIssueId: \"$blockerId\"
         }) {
           issue { number }
           blockingIssue { number title }
         }
       }
     " 2>&1)

     if [ $? -eq 0 ]; then
       echo "   ✅ #$issueNumber blocked by #$blockerNum ($blockerTitle)"
     else
       echo "   ❌ Failed to set relationship"
       echo "   $result"
     fi
   done
   ```

4. **Add blocking relationships:**
   ```bash
   for blockedNum in "${blocking[@]}"; do
     blockedId=$(echo "$issueData" | jq -r ".data.repository.issue$blockedNum.id")
     blockedTitle=$(echo "$issueData" | jq -r ".data.repository.issue$blockedNum.title")

     if [ "$blockedId" == "null" ]; then
       echo "⚠️  Issue #$blockedNum not found, skipping"
       continue
     fi

     echo "🔗 Setting #$issueNumber blocking #$blockedNum..."

     result=$(gh api graphql -f query="
       mutation {
         addBlockedBy(input: {
           issueId: \"$blockedId\"
           blockingIssueId: \"$mainIssueId\"
         }) {
           issue { number title }
           blockingIssue { number }
         }
       }
     " 2>&1)

     if [ $? -eq 0 ]; then
       echo "   ✅ #$issueNumber blocking #$blockedNum ($blockedTitle)"
     else
       echo "   ❌ Failed to set relationship"
       echo "   $result"
     fi
   done
   ```

5. **Remove blocked-by relationships:**
   ```bash
   for blockerNum in "${removeBlockedBy[@]}"; do
     blockerId=$(echo "$issueData" | jq -r ".data.repository.issue$blockerNum.id")

     if [ "$blockerId" == "null" ]; then
       echo "⚠️  Issue #$blockerNum not found, skipping"
       continue
     fi

     echo "🔓 Removing blocked-by #$blockerNum from #$issueNumber..."

     result=$(gh api graphql -f query="
       mutation {
         removeBlockedBy(input: {
           issueId: \"$mainIssueId\"
           blockingIssueId: \"$blockerId\"
         }) {
           issue { number }
         }
       }
     " 2>&1)

     if [ $? -eq 0 ]; then
       echo "   ✅ Removed blocked-by relationship"
     else
       echo "   ❌ Failed to remove relationship"
       echo "   $result"
     fi
   done
   ```

6. **Remove blocking relationships:**
   ```bash
   for blockedNum in "${removeBlocking[@]}"; do
     blockedId=$(echo "$issueData" | jq -r ".data.repository.issue$blockedNum.id")

     if [ "$blockedId" == "null" ]; then
       echo "⚠️  Issue #$blockedNum not found, skipping"
       continue
     fi

     echo "🔓 Removing blocking #$blockedNum from #$issueNumber..."

     result=$(gh api graphql -f query="
       mutation {
         removeBlockedBy(input: {
           issueId: \"$blockedId\"
           blockingIssueId: \"$mainIssueId\"
         }) {
           issue { number }
         }
       }
     " 2>&1)

     if [ $? -eq 0 ]; then
       echo "   ✅ Removed blocking relationship"
     else
       echo "   ❌ Failed to remove relationship"
       echo "   $result"
     fi
   done
   ```

7. **Output summary:**
   ```bash
   echo ""
   echo "📋 Summary for #$issueNumber:"
   echo "   Blocked by: ${#blockedBy[@]} added, ${#removeBlockedBy[@]} removed"
   echo "   Blocking: ${#blocking[@]} added, ${#removeBlocking[@]} removed"
   ```

**Success response:**
```json
{
  "issue": {
    "number": 3,
    "title": "Implement Event-Driven Architecture",
    "blockedBy": [2],
    "blocking": [1]
  },
  "success": true
}
```

## Error Handling

**If issue not found:**
```text
❌ Issue #999 not found

Verify the issue exists:
  gh issue view 999
```

**If no relationship specified:**
```text
❌ No relationship specified

Specify at least one of:
  --blocked-by <number>
  --blocking <number>
  --remove-blocked-by <number>
  --remove-blocking <number>
```

**If GraphQL mutation fails:**
```text
❌ Failed to set relationship

The issue dependency feature may not be available.
Ensure you have write access to the repository.
```

Return error JSON:
```json
{
  "error": true,
  "message": "Issue #999 not found",
  "issueNumber": 3
}
```

## Notes

- **Feature availability**: Requires GitHub's issue dependencies feature (GA August 2025)
- **Limit**: Up to 50 blocked-by and 50 blocking relationships per issue
- **Authentication**: Requires `gh auth login` with write access
- **Visibility**: Blocked issues show a "Blocked" icon on project boards

## Use Cases

### Establish Dependency Chain

```bash
# State machine must be done first
# Events depend on state machine
# Conductor depends on events
/gh-issue-dependency 3 --blocked-by 2
/gh-issue-dependency 1 --blocked-by 3
```

### Mark Foundation Issue as Blocking

```bash
# Foundation issue blocks multiple others
/gh-issue-dependency 2 --blocking 3 --blocking 5 --blocking 7
```

### Multiple Dependencies

```bash
# Issue blocked by multiple prerequisites
/gh-issue-dependency 10 --blocked-by 5 --blocked-by 6 --blocked-by 7
```

### Remove Completed Dependency

```bash
# Remove blocked-by after prerequisite is complete
/gh-issue-dependency 3 --remove-blocked-by 2
```

### Analyze and Set Dependencies

```bash
# 1. List issues to analyze
gh issue list --state open --json number,title

# 2. Set discovered dependencies
/gh-issue-dependency 3 --blocked-by 2
/gh-issue-dependency 1 --blocked-by 3
```

## Integration with Work System

Dependency management workflow:
```bash
# 1. Analyze work items for dependencies
/queue

# 2. Set GitHub issue dependencies
/gh-issue-dependency 3 --blocked-by 2

# 3. Route unblocked items first
/route WI-456 now "No blockers, ready to start"
```

Work item synchronization:
```bash
# When local work item has dependency
# Sync to GitHub issue
/gh-issue-dependency 5 --blocked-by 3

# Add comment for traceability
/gh-issue-comment 5 "Blocked by #3 - waiting for API implementation"
```

## Related Commands

- `/gh-create-issue` - Create new issue
- `/gh-issue-comment` - Add comment to issue
- `/git-status` - Check repository status
