# GitHub Slash Commands Reference

Git workflow commands for branch management and version control.

## Why These Commands?

These commands provide consistent, safe git operations with:
- **Conventional commit** enforcement for clean history
- **Safety checks** before destructive operations
- **Consistent output** format for automation
- **Integration** with the work system workflow

---

## Configuration

### Prerequisites

- Git installed and configured
- GitHub CLI (`gh`) installed (optional, for PR operations)
- SSH or HTTPS authentication configured

### Recommended Git Config

```bash
# Set default branch
git config --global init.defaultBranch main

# Enable helpful features
git config --global push.autoSetupRemote true
git config --global fetch.prune true
```

---

## Status & Information

### `/git-status`

Show comprehensive git status including working directory, branch info, and remote sync.

```bash
/git-status                      # Full status overview
/git-status --short              # Compact single-line format
/git-status --remote             # Fetch and compare with remote
```

**Parameters:**

- `--short` (optional) - Compact format for quick overview
- `--remote` (optional) - Fetch and show behind/ahead counts

**Output includes:**

- Current branch and tracking info
- Staged, modified, and untracked file counts
- Commits behind/ahead of remote
- Contextual suggestions (pull, commit, push)

**Note:** This command is called internally by `/git-commit` and `/git-push` to show status before operations.

---

## Branch Management

### `/git-create-branch`
Create a new git branch from current or specified base.

```bash
/git-create-branch feature/user-auth              # From current branch
/git-create-branch feature/user-auth main         # From main
/git-create-branch bugfix/login-error --push      # Create and push
```

**Parameters:**
- `branchName` (required) - Name of the new branch
- `baseBranch` (optional) - Base branch to create from
- `--push` (optional) - Push to remote after creation

---

### `/git-delete-branch`
Delete a git branch locally and/or remotely.

```bash
/git-delete-branch feature/old-feature            # Delete local only
/git-delete-branch feature/old-feature --remote   # Delete local and remote
/git-delete-branch feature/old-feature --force    # Force delete unmerged
```

**Parameters:**
- `branchName` (required) - Name of the branch to delete
- `--remote` (optional) - Also delete from remote
- `--force` (optional) - Force delete even if not merged

**Safety features:**
- Warns before deleting unmerged branches
- Cannot delete current branch
- Requires explicit `--remote` for remote deletion

---

### `/git-checkout`

Safely switch branches with automatic stash handling.

```bash
/git-checkout feature/other      # Switch to branch (auto-stash)
/git-checkout main --pull        # Switch and pull latest
/git-checkout -                  # Toggle to previous branch
/git-checkout feature/new --create   # Create and switch
```

**Parameters:**

- `branch` (required) - Branch to switch to
- `--pull` (optional) - Pull latest after switching
- `--create` (optional) - Create branch if doesn't exist
- `--discard` (optional) - Discard changes instead of stashing

**Safety features:**

- Auto-stashes uncommitted changes
- Creates local tracking branch from remote
- Named stashes for easy identification

---

## Committing Changes

### `/git-commit`

Create a git commit with conventional commit message format.

```bash
/git-commit "fix: resolve login timeout"          # Commit staged changes
/git-commit "feat(auth): add 2FA" --all           # Stage all and commit
/git-commit "docs: update README" --push          # Commit and push
/git-commit "refactor: simplify API" --all --push # All options
```

**Parameters:**
- `message` (required) - Commit message in conventional format
- `--all` (optional) - Stage all changes before committing
- `--push` (optional) - Push to remote after committing

**Conventional commit types:**
| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `style` | Code style changes |
| `refactor` | Code refactoring |
| `test` | Adding tests |
| `chore` | Build/tooling |
| `perf` | Performance |
| `ci` | CI/CD changes |

---

### `/git-amend`

Safely amend the last commit with checks.

```bash
/git-amend                       # Add staged changes to last commit
/git-amend "new message"         # Change commit message
/git-amend --all                 # Stage all and amend
/git-amend --push                # Amend and force push
```

**Parameters:**

- `message` (optional) - New commit message
- `--all` (optional) - Stage all changes before amending
- `--push` (optional) - Force push after amending

**Safety features:**

- Checks commit authorship (won't amend others' commits)
- Warns if commit already pushed
- Uses `--force-with-lease` for safe push

---

## Syncing with Remote

### `/git-sync`

Sync current branch with main (most common operation).

```bash
/git-sync                        # Rebase current branch on main
/git-sync develop                # Sync with develop instead
/git-sync --stash                # Auto-stash local changes
/git-sync --push                 # Rebase and force push (update PR)
```

**Parameters:**

- `baseBranch` (optional) - Branch to sync with (default: main)
- `--merge` (optional) - Merge instead of rebase
- `--stash` (optional) - Auto-stash and restore changes
- `--push` (optional) - Force push after rebase

**Default behavior (rebase):**

- Fetches latest from remote
- Rebases your commits on top of main
- Creates clean linear history

---

### `/git-fetch`

Fetch changes from remote without modifying local branches.

```bash
/git-fetch                       # Fetch from origin
/git-fetch --all                 # Fetch from all remotes
/git-fetch --status              # Fetch and show branch status
```

**Parameters:**

- `remote` (optional) - Remote name (default: origin)
- `--all` (optional) - Fetch from all remotes
- `--status` (optional) - Show detailed branch status after fetch

---

### `/git-pull`

Pull latest changes from remote repository.

```bash
/git-pull                        # Pull current branch
/git-pull main                   # Pull and merge main into current
/git-pull --rebase               # Pull with rebase
/git-pull --stash                # Auto-stash local changes
```

**Parameters:**

- `branch` (optional) - Branch to pull from
- `--rebase` (optional) - Rebase instead of merge
- `--stash` (optional) - Stash local changes, restore after pull

---

### `/git-push`

Commit all changes and push to remote in one command.

```bash
/git-push "feat: add feature"              # Commit all and push
/git-push "fix: bug fix" --set-upstream    # Set upstream tracking
/git-push "refactor: cleanup" --force      # Force push (caution!)
```

**Parameters:**

- `message` (required) - Commit message in conventional format
- `--set-upstream` (optional) - Set upstream for new branches
- `--force` (optional) - Force push (overwrites remote)

**Equivalent to:**
```bash
git add -A && git commit -m "message" && git push
```

---

## Pull Requests

### `/gh-create-pr`

Create a GitHub pull request for the current branch.

```bash
/gh-create-pr "Add user authentication"          # Standard PR
/gh-create-pr "WIP: New feature" --draft         # Draft PR
/gh-create-pr "Fix bug" --reviewer=@teammate     # Request review
/gh-create-pr "Feature" --base=develop           # Target non-main branch
```

**Parameters:**

- `title` (required) - PR title
- `--draft` (optional) - Create as draft PR
- `--base` (optional) - Target branch (default: main)
- `--reviewer` (optional) - Request reviewer(s)

**Features:**

- Auto-pushes unpushed commits before creating PR
- Extracts TW-XXXXX task ID from branch name
- Generates PR body with commit list and test checklist

---

### `/gh-get-pr-comments`

List all comments and review threads on a GitHub pull request.

```bash
/gh-get-pr-comments                  # Current branch's PR
/gh-get-pr-comments 123              # Specific PR
```

**Parameters:**

- `pr-number` (optional) - PR number (default: current branch's PR)

**Output includes:**

- General PR comments
- Formal reviews (APPROVED, CHANGES_REQUESTED, COMMENTED)
- Comment authors and timestamps
- Summary counts

**Use cases:**

- View feedback before addressing
- Check for approvals
- Monitor PR discussion

---

### `/gh-comment-pr`

Add a general comment to a GitHub pull request.

```bash
/gh-comment-pr "LGTM!"                          # Current branch's PR
/gh-comment-pr 123 "Looks great! Approved."     # Specific PR
/gh-comment-pr "Can you add tests?"             # Request changes
```

**Parameters:**

- `pr-number` (optional) - PR number (default: current branch's PR)
- `comment` (required) - Comment text (supports Markdown)

**Use cases:**

- General feedback and discussion
- Status updates
- Questions about approach
- Informal approval messages

**Note:** For inline code comments and replies, see `/gh-reply-pr-comment` below.

---

### `/gh-reply-pr-comment`

Reply to an existing comment thread on a pull request.

```bash
# Reply to specific comment
gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies \
  -X POST -f body="Fixed - changed to Transient as suggested"
```

**Parameters:**

- `comment_id` (required) - ID of the comment to reply to
- `body` (required) - Text of your reply

**Use cases:**

- Respond to code review feedback
- Address specific concerns
- Explain changes made
- Ask for clarification on feedback

**Workflow:**
1. Use `/gh-get-pr-comments` to find comment IDs
2. Make necessary code changes
3. Reply to explain what was fixed
4. Optionally resolve with `/gh-resolve-pr-comment`

See [gh-reply-pr-comment.md](gh-reply-pr-comment.md) for detailed usage.

---

### `/gh-resolve-pr-comment`

Mark a pull request comment thread as resolved.

```bash
# Mark comment as resolved
gh api repos/{owner}/{repo}/pulls/comments/{comment_id} \
  -X PATCH -f state="resolved"
```

**Parameters:**

- `comment_id` (required) - ID of the comment thread
- `state` - Either "resolved" or "unresolved"

**Use cases:**

- Mark issues as addressed after fixing
- Close resolved discussions
- Track PR progress

**Best practices:**
- Reply with explanation before resolving
- Let reviewers verify critical fixes
- Resolve obvious typos immediately

See [gh-resolve-pr-comment.md](gh-resolve-pr-comment.md) for detailed usage.

---

### `/gh-review-pr`

Submit a formal code review with approval, change requests, or comments.

```bash
/gh-review-pr 123 --approve --body "LGTM! Great work."
/gh-review-pr 123 --request-changes --body "Please address the DI lifetime issues"
/gh-review-pr 123 --comment --body "Some architectural thoughts"
```

**Parameters:**

- `pr-number` (optional) - PR number (default: current branch's PR)
- `--approve` - Approve the PR
- `--request-changes` - Request changes before merging
- `--comment` - Add review without approval/rejection
- `--body` (required) - Review summary text

**Use cases:**

- Formal PR approval
- Request specific changes
- Provide architectural feedback
- Add non-blocking suggestions

**Review types:**
- **APPROVE**: PR can be merged
- **REQUEST_CHANGES**: Blocks merge, changes needed
- **COMMENT**: Neutral feedback, doesn't block

See [gh-review-pr.md](gh-review-pr.md) for detailed usage.

---

### Learning from PR Feedback

After PR is merged, you can extract learnable patterns from reviewer feedback:

```bash
# Extract patterns from merged PR
/extract-review-patterns --source github --pr 123

# Patterns are saved to code-review-patterns.yaml in project root
# Next time you run /code-review, these patterns will be checked automatically
```

**Pattern Learning Flow:**
1. PR gets feedback → Comments created
2. You address feedback → PR merged
3. Extract patterns → Patterns stored in `code-review-patterns.yaml`
4. Future code reviews → Patterns automatically checked

This creates a self-improving code review system that learns from your team's actual PR feedback.

See [extract-review-patterns.md](../extract-review-patterns.md) for details.

---

### `/gh-merge-pr`

Merge a PR using **rebase strategy** and delete branch.

```bash
/gh-merge-pr                    # Merge current branch's PR
/gh-merge-pr 123                # Merge by PR number
/gh-merge-pr --squash           # Squash merge instead
/gh-merge-pr --no-delete        # Keep branch after merge
```

**Parameters:**

- `prNumber` (optional) - PR number (default: current branch's PR)
- `--squash` (optional) - Use squash merge instead of rebase
- `--no-delete` (optional) - Don't delete branch after merge
- `--admin` (optional) - Merge even if checks fail

**Default behavior (rebase merge):**

- Creates linear git history
- Preserves individual commits
- Deletes remote and local branch
- Switches you to main and pulls latest

---

## Issues

### `/gh-create-issue`

Create a new GitHub issue with optional labels and assignees.

```bash
/gh-create-issue "Issue title" "Issue body"
/gh-create-issue "Bug: Login fails" "Users cannot login" --label bug
/gh-create-issue "Feature request" "Add dark mode" --label "type:feature" --label "impact:high"
/gh-create-issue "Task title" "Description" --assignee @me
```

**Parameters:**

- `title` (required) - The issue title
- `body` (required) - The issue body/description
- `--label` (optional, repeatable) - Labels to apply
- `--assignee` (optional) - Assignee username (`@me` for self)
- `--milestone` (optional) - Milestone name or number

**Use cases:**

- Bug reports with appropriate labels
- Feature requests from work items
- Task creation linked to Teamwork

---

### `/gh-get-issue`

Get details of a single GitHub issue.

```bash
/gh-get-issue 123
/gh-get-issue 123 --json
```

**Parameters:**

- `issueNumber` (required) - The GitHub issue number
- `--json` (optional) - Output raw JSON

**Use cases:**

- View issue details before updating
- Check dependencies before linking
- Verify issue exists

---

### `/gh-list-issues`

List GitHub issues with optional filters.

```bash
/gh-list-issues
/gh-list-issues --state open --label bug
/gh-list-issues --assignee @me
/gh-list-issues --milestone "v2.0" --limit 50
```

**Parameters:**

- `--state` (optional) - Filter by state (`open`, `closed`, `all`)
- `--label` (optional, repeatable) - Filter by label
- `--assignee` (optional) - Filter by assignee (`@me` for self)
- `--milestone` (optional) - Filter by milestone
- `--search` (optional) - Search query
- `--limit` (optional) - Max results (default: 30)
- `--json` (optional) - Output raw JSON

**Use cases:**

- List open bugs
- Find issues by label
- Search for related issues

---

### `/gh-update-issue`

Update properties of an existing GitHub issue.

```bash
/gh-update-issue 123 --title "New title"
/gh-update-issue 123 --add-label bug --add-label urgent
/gh-update-issue 123 --assignee @developer
/gh-update-issue 123 --state closed
```

**Parameters:**

- `issueNumber` (required) - The GitHub issue number
- `--title` (optional) - New issue title
- `--body` (optional) - New issue body
- `--add-label` (optional, repeatable) - Add label
- `--remove-label` (optional, repeatable) - Remove label
- `--assignee` (optional) - Set assignee
- `--add-assignee` (optional, repeatable) - Add assignee
- `--remove-assignee` (optional, repeatable) - Remove assignee
- `--milestone` (optional) - Set milestone
- `--state` (optional) - Set state (`open` or `closed`)

**Use cases:**

- Update labels during workflow
- Close/reopen issues
- Assign team members

---

### `/gh-issue-comment`

Add a comment to a GitHub issue.

```bash
/gh-issue-comment 123 "Status update"
/gh-issue-comment 456 "Routed to urgent queue: high priority"
```

**Parameters:**

- `issueNumber` (required) - The GitHub issue number
- `body` (required) - The comment text

**Use cases:**

- Routing notifications
- Status updates
- Workflow tracking

---

### `/gh-issue-dependency`

Set blocked by/blocking relationships between GitHub issues.

```bash
/gh-issue-dependency 3 --blocked-by 2
/gh-issue-dependency 2 --blocking 3
/gh-issue-dependency 1 --blocked-by 3 --blocked-by 2
/gh-issue-dependency 5 --remove-blocked-by 3
```

**Parameters:**

- `issueNumber` (required) - The issue to modify
- `--blocked-by` (optional, repeatable) - Issue number that blocks this issue
- `--blocking` (optional, repeatable) - Issue number that this issue blocks
- `--remove-blocked-by` (optional) - Remove blocked-by relationship
- `--remove-blocking` (optional) - Remove blocking relationship

**Use cases:**

- Establish dependency chains between issues
- Mark foundation issues as blocking others
- Clear dependencies when prerequisites complete

**Notes:**

- Uses GitHub's native issue dependencies feature (GraphQL API)
- Up to 50 blocked-by and 50 blocking relationships per issue
- Blocked issues show "Blocked" icon on project boards

---

## Common Workflows

### Starting a New Feature
```bash
# 1. Create feature branch
/git-create-branch feature/user-authentication main --push

# 2. Make changes...

# 3. Commit work
/git-commit "feat(auth): implement login flow" --all

# 4. Push and create PR
/git-push "feat(auth): complete feature"
/gh-create-pr "feat: Add user authentication"

# 5. After approval, merge
/gh-merge-pr
```

### Bug Fix Workflow
```bash
# 1. Create bugfix branch
/git-create-branch bugfix/fix-login-error --push

# 2. Fix the bug...

# 3. Commit fix
/git-commit "fix: resolve login timeout issue" --all --push

# 4. Create PR
/gh-create-pr "fix: Fix login timeout"
```

### Cleanup After Merge
```bash
# 1. Switch to main and pull latest
/git-checkout main --pull

# 2. Delete merged branch
/git-delete-branch feature/completed-feature --remote
```

---

## Integration with Work System

These commands integrate with the Teamwork workflow:

### Task Branch Naming
```bash
# Include task ID in branch name for traceability
/git-create-branch feature/TW-26134585-user-auth main --push
```

### Commit with Task Reference
```bash
# Reference task in commit message
/git-commit "feat(auth): implement password reset TW-26134585" --all
```

### Complete Workflow
```bash
# 1. Resume task
/resume

# 2. Create branch
/git-create-branch feature/TW-26134585-implement-feature main --push

# 3. Work on feature...

# 4. Commit changes
/git-commit "feat: implement user feature TW-26134585" --all --push

# 5. Create PR
/gh-create-pr "feat: Implement user feature"

# 6. After merge, cleanup
/git-delete-branch feature/TW-26134585-implement-feature --remote

# 7. Log time
/tw-create-task-timelog 26134585 "2025-12-07" 2 30 "Implemented feature"
```

---

## Error Handling

All commands return consistent error JSON:
```json
{
  "error": true,
  "message": "Description of error",
  "details": {}
}
```

**Common errors:**
- Branch already exists (create)
- Branch not found (delete)
- Cannot delete current branch (delete)
- No staged changes (commit)
- Push failed (network/auth issues)

---

## Notes

- **Branch naming**: Use prefixes (`feature/`, `bugfix/`, `hotfix/`, `chore/`)
- **Commit format**: Follow conventional commits for clean history
- **Safety first**: Destructive operations require explicit flags
- **Task traceability**: Include Teamwork task IDs in branch names and commits
