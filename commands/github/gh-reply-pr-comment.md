# Reply to GitHub PR Comment

Reply to an existing comment thread on a GitHub pull request.

## Usage

Reply to a specific comment:
```bash
gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies \
  -X POST \
  -f body="Your reply text here"
```

## Parameters

- `comment_id` (required): The ID of the comment to reply to
- `body` (required): The text of your reply

## Getting Comment IDs

Use `/gh-get-pr-comments` to list all comments and get their IDs.

## Examples

### Reply to a code review comment

```bash
# First, get the comments to find the comment ID
gh pr view 123 --json comments

# Reply to comment ID RC_xyz123
gh api repos/myorg/myrepo/pulls/comments/RC_xyz123/replies \
  -X POST \
  -f body="Fixed - changed to Transient as suggested"
```

### Reply with multi-line text

```bash
gh api repos/myorg/myrepo/pulls/comments/RC_xyz123/replies \
  -X POST \
  -f body="$(cat <<'EOF'
Thanks for the feedback!

I've made the following changes:
- Changed lifetime to Transient
- Added validation
- Updated tests
EOF
)"
```

## Task Instructions

When replying to PR comments:

1. **Get comment context first**: Use `/gh-get-pr-comments` to see the full conversation
2. **Use descriptive replies**: Explain what you changed and why
3. **Reference code**: Use backticks for code snippets in replies
4. **Address all points**: If a comment has multiple concerns, address each one
5. **Be specific**: Instead of "Fixed", say "Fixed - changed to Transient for stateless service"

## Response Format

Success response includes the new comment:

```json
{
  "id": 1234567,
  "body": "Fixed - changed to Transient as suggested",
  "created_at": "2025-01-15T14:30:00Z",
  "user": {
    "login": "cbryant"
  },
  "in_reply_to_id": 7654321
}
```

## Common Patterns

### Acknowledge and fix
```bash
gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies \
  -X POST \
  -f body="Good catch! Fixed in the latest commit."
```

### Ask for clarification
```bash
gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies \
  -X POST \
  -f body="Could you clarify which service you're referring to? There are several Scoped registrations in this file."
```

### Agree with feedback
```bash
gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies \
  -X POST \
  -f body="You're absolutely right. I've refactored this to use the generic interface pattern."
```

## Integration with Workflow

This command is used in the `/deliver` workflow when addressing PR feedback:

1. Agent runs `/gh-get-pr-comments` to see unresolved comments
2. For each comment requiring changes:
   - Agent makes the code changes
   - Agent runs `/gh-reply-pr-comment` to notify reviewer
   - Agent may run `/gh-resolve-pr-comment` if issue is fully resolved

## Error Handling

### Comment not found
```
HTTP 404: Not Found
```
→ Verify the comment ID is correct using `/gh-get-pr-comments`

### Not authorized
```
HTTP 403: Forbidden
```
→ Check that you have write access to the repository

### Invalid reply target
```
HTTP 422: Validation Failed
```
→ Ensure you're replying to a pull request review comment, not a general issue comment

## Notes

- Replies create a threaded conversation on the specific line of code
- All participants in the thread are notified of new replies
- Replies support GitHub-flavored Markdown
- Use `@mentions` to notify specific users
- Replies inherit the file/line context from the parent comment

## Related Commands

- `/gh-get-pr-comments` - List all PR comments to find comment IDs
- `/gh-resolve-pr-comment` - Mark a comment thread as resolved
- `/gh-comment-pr` - Add a general comment (not in a thread)
- `/gh-review-pr` - Submit a formal review with approval/changes

## API Documentation

GitHub REST API: [Reply to a review comment](https://docs.github.com/en/rest/pulls/comments#create-a-reply-for-a-review-comment)
