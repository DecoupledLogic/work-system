# Resolve GitHub PR Comment

Mark a GitHub pull request review comment thread as resolved.

## Usage

Resolve a comment thread:
```bash
gh api repos/{owner}/{repo}/pulls/comments/{comment_id} \
  -X PATCH \
  -f state="resolved"
```

## Parameters

- `comment_id` (required): The ID of the top-level comment in the thread
- `state`: Either "resolved" or "unresolved"

## Getting Comment IDs

Use `/gh-get-pr-comments` to list all comments and their resolution status.

## Examples

### Resolve a comment thread

```bash
# Mark comment thread as resolved
gh api repos/myorg/myrepo/pulls/comments/RC_xyz123 \
  -X PATCH \
  -f state="resolved"
```

### Unresolve a comment

```bash
# Reopen a resolved thread
gh api repos/myorg/myrepo/pulls/comments/RC_xyz123 \
  -X PATCH \
  -f state="unresolved"
```

### Get current repository from git remote

```bash
# Get owner and repo from current directory
REPO_INFO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
OWNER=$(echo $REPO_INFO | cut -d'/' -f1)
REPO=$(echo $REPO_INFO | cut -d'/' -f2)

gh api repos/$OWNER/$REPO/pulls/comments/RC_xyz123 \
  -X PATCH \
  -f state="resolved"
```

## Task Instructions

When resolving PR comments:

1. **Only resolve when addressed**: Don't mark as resolved unless the issue is actually fixed
2. **Reply before resolving**: Add a comment explaining what was done before resolving
3. **Verify the fix**: Test that your changes actually address the concern
4. **Use with replies**: Typical flow is reply → push changes → resolve
5. **Let reviewers resolve**: Sometimes it's better to reply and let the reviewer mark as resolved

## Typical Workflow

```bash
# 1. Get unresolved comments
gh pr view 123 --json comments | jq '.comments[] | select(.isResolved == false)'

# 2. Make code changes to address comment
# ... edit files ...

# 3. Reply to comment explaining the fix
gh api repos/myorg/myrepo/pulls/comments/RC_xyz123/replies \
  -X POST \
  -f body="Fixed - changed to Transient for stateless service"

# 4. Commit and push changes
git add .
git commit -m "fix: change service lifetime to Transient"
git push

# 5. Resolve the thread
gh api repos/myorg/myrepo/pulls/comments/RC_xyz123 \
  -X PATCH \
  -f state="resolved"
```

## Response Format

Success response:

```json
{
  "id": 1234567,
  "state": "resolved",
  "resolved_at": "2025-01-15T14:30:00Z",
  "resolved_by": {
    "login": "cbryant"
  }
}
```

## Common Patterns

### Resolve after fixing issue
```bash
# Reply first
gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies \
  -X POST \
  -f body="Fixed in commit abc123"

# Then resolve
gh api repos/{owner}/{repo}/pulls/comments/{comment_id} \
  -X PATCH \
  -f state="resolved"
```

### Batch resolve multiple comments
```bash
# Get all comment IDs for unresolved threads
COMMENT_IDS=$(gh pr view 123 --json comments | jq -r '.comments[] | select(.isResolved == false) | .id')

# Resolve each one
for comment_id in $COMMENT_IDS; do
  gh api repos/{owner}/{repo}/pulls/comments/$comment_id \
    -X PATCH \
    -f state="resolved"
done
```

## When to Resolve

**✅ Good reasons to resolve:**
- Issue is fixed and tested
- Concern is addressed with code changes
- Question is answered with clarification
- Reviewer's suggestion is implemented

**❌ Don't resolve if:**
- You haven't actually addressed the issue
- Changes are still in progress
- You're not sure the fix is correct
- Reviewer should verify the fix first

## Integration with Workflow

This command is used in the `/deliver` workflow:

1. Agent reviews unresolved comments
2. For each comment:
   - Makes necessary code changes
   - Adds reply explaining changes
   - Resolves thread if fully addressed
3. Pushes all changes together
4. PR is ready for re-review with fewer unresolved threads

## Error Handling

### Comment not found
```
HTTP 404: Not Found
```
→ Verify the comment ID using `/gh-get-pr-comments`

### Not authorized
```
HTTP 403: Forbidden
```
→ Check that you have write access to the repository

### Invalid state
```
HTTP 422: Validation Failed
```
→ Ensure state is either "resolved" or "unresolved"

## Notes

- Only the PR author or comment author can resolve threads (repository settings may vary)
- Resolving a parent comment resolves the entire thread
- GitHub sends notifications when threads are resolved
- Resolved threads are collapsed in the UI but can be expanded
- Force-pushing after resolving preserves resolution state (unlike outdated comments)

## Resolution Etiquette

**For PR Authors:**
- Don't resolve comments immediately after replying - give reviewer time to see response
- If unsure about fix, reply but don't resolve (let reviewer confirm)
- Resolve obvious typo fixes immediately

**For Reviewers:**
- Resolve your own comments once satisfied with fix
- Don't resolve others' comments unless you're the PR author
- Leave threads unresolved if more discussion needed

## Related Commands

- `/gh-get-pr-comments` - List all PR comments with resolution status
- `/gh-reply-pr-comment` - Reply to comment before resolving
- `/gh-review-pr` - Submit formal review with overall approval
- `/gh-comment-pr` - Add general comment to PR

## API Documentation

GitHub REST API: [Update a pull request review comment](https://docs.github.com/en/rest/pulls/comments#update-a-review-comment)

## Additional Notes

GitHub doesn't have a dedicated "resolve" endpoint. The resolution is handled through the comment state field when updating the comment. The actual resolution mechanism may depend on GitHub's API version and repository settings.
