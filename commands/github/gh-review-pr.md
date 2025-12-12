# Submit GitHub PR Review

Submit a formal review for a GitHub pull request with approval, change requests, or comments.

## Usage

### Approve a PR
```bash
gh pr review <pr-number> --approve --body "LGTM! Great work."
```

### Request changes
```bash
gh pr review <pr-number> --request-changes --body "Please address the comments about DI lifetimes."
```

### Add review comments without approval
```bash
gh pr review <pr-number> --comment --body "Some thoughts on the implementation approach."
```

## Parameters

- `pr-number` (optional): PR number to review (defaults to current branch's PR)
- `--approve`: Approve the PR
- `--request-changes`: Request changes before merging
- `--comment`: Add review without approval/rejection
- `--body` (required): Review summary text

## Examples

### Approve after code review

```bash
gh pr review 123 --approve --body "$(cat <<'EOF'
Looks good! I've verified:
- All tests pass
- Code follows our patterns
- Documentation is updated
EOF
)"
```

### Request specific changes

```bash
gh pr review 123 --request-changes --body "$(cat <<'EOF'
Please address:
1. Change ISubscriptionQuery lifetime to Transient
2. Remove vendor name from Abstractions layer
3. Add validation for null inputs

See inline comments for details.
EOF
)"
```

### Add comments without blocking

```bash
gh pr review 123 --comment --body "Nice refactoring! Consider extracting the validation logic into a separate method for better testability."
```

### Review current branch's PR

```bash
# Review the PR for current branch
gh pr review --approve --body "LGTM"
```

## Review Types

### 1. APPROVE
- Indicates you approve merging the changes
- Can merge after approval (if branch protection allows)
- Shows green checkmark in GitHub UI
- Counts toward required approvals

**When to use:**
- All concerns are addressed
- Code meets quality standards
- Tests are passing
- No blocking issues

### 2. REQUEST_CHANGES
- Blocks PR from merging (if branch protection enabled)
- Indicates changes are needed before merge
- Shows red X in GitHub UI
- Author must push new commits

**When to use:**
- Critical bugs found
- Security issues present
- Patterns violated
- Breaking changes without discussion

### 3. COMMENT
- Neutral review without approval/rejection
- Doesn't affect merge status
- Shows comment icon in GitHub UI
- Good for suggestions and questions

**When to use:**
- Non-blocking suggestions
- Questions about approach
- Early feedback during development
- Architectural discussions

## Task Instructions

When submitting PR reviews:

1. **Be specific in body**: Summarize key points even if inline comments exist
2. **Use appropriate type**: Don't request changes for minor suggestions
3. **Provide context**: Explain why changes are needed
4. **Reference standards**: Link to architecture docs or patterns
5. **Be constructive**: Suggest solutions, not just problems

## Review Body Format

Good review bodies follow this structure:

```markdown
## Summary
Brief overview of the changes

## Strengths
- What works well
- Good patterns used

## Concerns / Suggestions
1. Specific issue or suggestion
2. Another point
3. Reference to inline comments

## Next Steps
- Action items if requesting changes
- Or approval statement
```

## Common Patterns

### Approve with minor suggestions
```bash
gh pr review 123 --approve --body "$(cat <<'EOF'
LGTM! A few minor suggestions in inline comments, but nothing blocking.

Great work on the clean architecture separation and comprehensive tests.
EOF
)"
```

### Request changes with clear action items
```bash
gh pr review 123 --request-changes --body "$(cat <<'EOF'
Please address these blocking issues:

1. **DI Lifetime**: Change ISubscriptionQuery to Transient (see comment on line 42)
2. **Vendor Coupling**: Remove 'Staxbill' from interface names in Abstractions (see comment on line 18)
3. **Missing Tests**: Add unit tests for error scenarios

After addressing these, I'll review again.
EOF
)"
```

### Comment for architectural discussion
```bash
gh pr review 123 --comment --body "$(cat <<'EOF'
Interesting approach! A few thoughts:

**Pros:**
- Clean separation of concerns
- Good use of interfaces

**Questions:**
- Have we considered using the repository pattern here?
- What's the performance impact of the multiple database calls?

Happy to discuss further.
EOF
)"
```

## Integration with Workflow

### Pre-merge review (by reviewer)
```bash
# 1. Check out PR branch
gh pr checkout 123

# 2. Run tests
dotnet test

# 3. Review code locally
# ... examine files ...

# 4. Submit review
gh pr review 123 --approve --body "Verified locally, all tests pass. LGTM!"
```

### Self-review (by PR author)
```bash
# Request review from specific people
gh pr review 123 --comment --body "Ready for review! @ali-bijanfar @senior-dev please take a look"
```

## Response Format

Success message:
```
https://github.com/owner/repo/pull/123#pullrequestreview-123456789
```

The review is immediately visible on GitHub with your chosen state.

## Error Handling

### PR not found
```
could not find pull request
```
→ Verify PR number or check if branch has an open PR

### Already reviewed
GitHub allows multiple reviews from the same person. Latest review updates your overall state.

### Not authorized
```
403 Forbidden
```
→ Ensure you have read access to repository

### Missing body
```
--body is required
```
→ Always provide a review body explaining your decision

## Review States and Permissions

**Who can review:**
- Any repository collaborator
- Team members (for organization repos)
- Anyone with read access can comment

**Review requirements:**
- Set in branch protection rules
- Can require N approvals before merge
- Can require approval from code owners
- Can dismiss stale reviews on new commits

## Notes

- Reviews are associated with the latest commit at review time
- New commits may mark review as "stale" depending on settings
- You can change your review by submitting a new one
- Inline comments are separate from review submission
- Review body supports GitHub-flavored Markdown
- @mentions in review body trigger notifications

## Best Practices

**For thorough reviews:**
1. Test the changes locally
2. Check for security issues
3. Verify tests are comprehensive
4. Ensure documentation is updated
5. Check for breaking changes
6. Validate architectural patterns

**For review tone:**
- Be respectful and constructive
- Explain the "why" behind suggestions
- Acknowledge good work
- Ask questions rather than make demands
- Suggest alternatives
- Assume good intent

**For blocking vs. non-blocking:**
- Request changes for: security issues, broken functionality, pattern violations
- Comment for: style preferences, alternative approaches, questions
- Approve with suggestions for: minor issues that can be addressed later

## Related Commands

- `/gh-get-pr-comments` - View all comments and reviews
- `/gh-reply-pr-comment` - Reply to specific review comments
- `/gh-resolve-pr-comment` - Mark comment threads as resolved
- `/gh-comment-pr` - Add general comment without formal review

## API Documentation

GitHub CLI: [gh pr review](https://cli.github.com/manual/gh_pr_review)

## Additional Features

### Review with inline comments

You can combine a formal review with inline comments:

```bash
# Add inline comments first (using GitHub UI or API)
# Then submit the review
gh pr review 123 --approve --body "Approved with suggestions in inline comments"
```

### Change review after submission

```bash
# Update your review by submitting a new one
gh pr review 123 --approve --body "All concerns addressed, approving now"
```

### Review from specific commit

The review is automatically associated with the HEAD commit of the PR at review time. If new commits are pushed, some settings may mark your review as "stale".
