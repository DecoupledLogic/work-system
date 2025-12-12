# Git Commands

Platform-agnostic git operations with safety features and conventional commits.

## Commands

| Command | Description |
|---------|-------------|
| `/git:git-status` | Show working directory and remote sync status |
| `/git:git-branch` | Get current branch or list branches |
| `/git:git-create-branch` | Create new branch from current or specified base |
| `/git:git-delete-branch` | Delete branch locally and/or remotely |
| `/git:git-checkout` | Switch branches with auto-stash |
| `/git:git-commit` | Commit with conventional commit format |
| `/git:git-amend` | Amend last commit with safety checks |
| `/git:git-fetch` | Fetch from remote without merging |
| `/git:git-pull` | Pull changes with optional rebase |
| `/git:git-push` | Commit all and push in one command |
| `/git:git-sync` | Rebase current branch on main |
| `/git:git-diff` | Show changes in working directory |
| `/git:git-log` | View commit history |
| `/git:git-remote` | Manage git remotes |

## Quick Examples

```bash
# Feature workflow
/git:git-create-branch feature/TW-12345-auth main --push
/git:git-commit "feat(auth): add login" --all
/git:git-push

# Keep branch updated
/git:git-sync --stash

# After PR merge
/git:git-checkout main --pull
/git:git-delete-branch feature/TW-12345-auth --remote
```

## Conventional Commits

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`

See source commands in [commands/git/](../../../commands/git/) for full documentation.
