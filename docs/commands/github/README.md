# GitHub Commands

GitHub CLI operations for pull requests and issues.

## Prerequisites

- Git installed and configured
- GitHub CLI (`gh`) installed
- SSH or HTTPS authentication

## Commands

### Pull Requests

| Command | Description |
|---------|-------------|
| `/github:gh-create-pr` | Create PR for current branch |
| `/github:gh-get-pr-comments` | List PR comments and reviews |
| `/github:gh-comment-pr` | Add comment to PR |
| `/github:gh-review-pr` | Submit formal review |
| `/github:gh-merge-pr` | Merge PR (rebase) and delete branch |

### Issues

| Command | Description |
|---------|-------------|
| `/github:gh-create-issue` | Create issue with labels |
| `/github:gh-get-issue` | Get issue details |
| `/github:gh-list-issues` | List issues with filters |
| `/github:gh-update-issue` | Update issue properties |
| `/github:gh-issue-comment` | Add comment to issue |
| `/github:gh-issue-dependency` | Set blocked-by/blocking relationships |

## Quick Examples

```bash
# PR workflow
/github:gh-create-pr "Add user authentication"
/github:gh-get-pr-comments 123
/github:gh-merge-pr 123

# Issue workflow
/github:gh-create-issue "Bug: Login fails" "Description" --label bug
/github:gh-issue-comment 456 "Status update"
```

See source commands in [commands/github/](../../../commands/github/) for full documentation.
