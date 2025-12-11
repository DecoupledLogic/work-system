---
description: Create a git commit with conventional commit message (helper)
allowedTools:
  - Bash
  - SlashCommand
---

# Git: Commit Changes

Creates a git commit with staged or all changes using conventional commit format.

## Usage

```bash
/git-commit "fix: resolve login authentication bug"
/git-commit "feat(auth): add password reset flow" --all
/git-commit "docs: update API documentation" --push
/git-commit "refactor: simplify user service" --all --push
```

## Input Parameters

- **message** (required): Commit message (use quotes for multi-word)
- **--all** (optional): Stage all changes before committing (`git add -A`)
- **--push** (optional): Push to remote after committing

## Conventional Commit Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation changes |
| `style` | Code style (formatting, semicolons, etc.) |
| `refactor` | Code refactoring (no feature/fix) |
| `test` | Adding or updating tests |
| `chore` | Build process, dependencies, tooling |
| `perf` | Performance improvements |
| `ci` | CI/CD configuration changes |

## Implementation

1. **Parse input and flags:**
   ```bash
   message=""
   stageAll=false
   pushAfter=false

   for arg in "$@"; do
     case "$arg" in
       --all) stageAll=true ;;
       --push) pushAfter=true ;;
       *)
         if [ -z "$message" ]; then
           message="$arg"
         fi
         ;;
     esac
   done

   # Validate required parameters
   if [ -z "$message" ]; then
     echo "❌ Missing required parameter: message"
     echo ""
     echo "Usage: /git-commit <message> [--all] [--push]"
     echo ""
     echo "Examples:"
     echo "  /git-commit \"fix: resolve login bug\""
     echo "  /git-commit \"feat(auth): add 2FA support\" --all"
     echo "  /git-commit \"docs: update README\" --push"
     exit 1
   fi
   ```

2. **Show current status (via /git-status):**
   ```bash
   echo "📊 Current Status:"
   /git-status --short

   # Or inline status display:
   currentBranch=$(git branch --show-current)
   staged=$(git diff --cached --name-only | wc -l | tr -d ' ')
   modified=$(git diff --name-only | wc -l | tr -d ' ')
   untracked=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')

   echo "📍 Branch: $currentBranch"
   echo "   Staged: $staged | Modified: $modified | Untracked: $untracked"
   echo ""
   ```

3. **Validate commit message format:**
   ```bash
   # Check for conventional commit format (optional but recommended)
   if ! echo "$message" | grep -qE "^(feat|fix|docs|style|refactor|test|chore|perf|ci)(\(.+\))?:"; then
     echo "⚠️  Non-conventional commit format detected"
     echo ""
     echo "Recommended format: type(scope): description"
     echo "  feat: new feature"
     echo "  fix: bug fix"
     echo "  docs: documentation"
     echo ""
     echo "Proceeding with commit..."
   fi
   ```

4. **Stage changes if --all:**
   ```bash
   if [ "$stageAll" = true ]; then
     git add -A
   fi
   ```

5. **Check for staged changes:**
   ```bash
   if [ -z "$(git diff --cached --name-only)" ]; then
     echo "❌ No staged changes to commit"
     echo ""
     echo "Options:"
     echo "  - Stage specific files: git add <file>"
     echo "  - Stage all changes: /git-commit \"message\" --all"
     exit 1
   fi
   ```

6. **Show files to be committed:**
   ```bash
   echo "📝 Files to commit:"
   git diff --cached --name-status | while read status file; do
     case "$status" in
       A) echo "   ➕ $file (new)" ;;
       M) echo "   ✏️  $file (modified)" ;;
       D) echo "   ➖ $file (deleted)" ;;
       R*) echo "   📛 $file (renamed)" ;;
       *) echo "   $status $file" ;;
     esac
   done
   echo ""
   ```

7. **Create commit:**
   ```bash
   # Get list of staged files for output
   stagedFiles=$(git diff --cached --name-only)
   fileCount=$(echo "$stagedFiles" | wc -l)

   # Create the commit
   git commit -m "$message"

   # Get commit hash
   commitHash=$(git rev-parse --short HEAD)
   ```

8. **Push if requested:**
   ```bash
   if [ "$pushAfter" = true ]; then
     currentBranch=$(git branch --show-current)
     git push origin "$currentBranch"
   fi
   ```

9. **Output result:**

**Success response:**
```json
{
  "commit": {
    "hash": "a1b2c3d",
    "message": "feat(auth): add password reset flow",
    "branch": "feature/user-auth",
    "filesChanged": 5,
    "pushed": true
  },
  "success": true
}
```

## Error Handling

**If no changes to commit:**
```text
❌ No staged changes to commit

Working directory status:
  - Modified (unstaged): 3 files
  - Untracked: 2 files

Options:
  - Stage specific files: git add <file>
  - Stage all changes: /git-commit "message" --all
```

**If commit message empty:**
```text
❌ Missing required parameter: message

Usage: /git-commit <message> [--all] [--push]

Conventional commit types:
  feat:     New feature
  fix:      Bug fix
  docs:     Documentation
  refactor: Code refactoring
  test:     Adding tests
  chore:    Build/tooling changes
```

**If push fails:**
```text
❌ Commit created but push failed

Commit 'a1b2c3d' created successfully.
Could not push to remote.

Possible causes:
  - Remote branch doesn't exist (use: git push -u origin branch)
  - Authentication failed
  - Remote has diverged (pull first)

Push manually with:
  git push origin feature/user-auth
```

Return error JSON:
```json
{
  "error": true,
  "message": "No staged changes to commit",
  "staged": 0,
  "unstaged": 3,
  "untracked": 2
}
```

## Notes

- **Conventional commits**: Follows Angular/Conventional Commits spec
- **Scope optional**: `feat: message` or `feat(scope): message`
- **Quotes required**: Always quote multi-word commit messages
- **Atomic commits**: Prefer small, focused commits over large ones
- **Pre-commit hooks**: Respects any configured git hooks

## Use Cases

### Simple Bug Fix
```bash
# Stage and commit specific fix
git add src/auth/login.ts
/git-commit "fix: resolve login timeout issue"
```

### Feature with All Changes
```bash
# Stage all and commit
/git-commit "feat(dashboard): add user activity chart" --all
```

### Quick Documentation Update
```bash
# Commit and push immediately
/git-commit "docs: update installation guide" --all --push
```

### Scoped Refactoring
```bash
# Refactor with scope
/git-commit "refactor(api): simplify error handling" --all
```

## Integration with Work System

After completing work on a task:
```bash
# 1. Commit changes
/git-commit "feat(auth): implement password reset TW-26134585" --all

# 2. Push changes
git push origin feature/password-reset

# 3. Create PR or update task status
```

## Best Practices

1. **One logical change per commit**
   ```bash
   # Good: focused commits
   /git-commit "feat: add user model"
   /git-commit "feat: add user repository"
   /git-commit "feat: add user service"

   # Avoid: mixing unrelated changes
   /git-commit "feat: add user stuff and fix login and update docs"
   ```

2. **Use scope for multi-component projects**
   ```bash
   /git-commit "feat(api): add user endpoints"
   /git-commit "feat(web): add user profile page"
   /git-commit "fix(mobile): resolve crash on login"
   ```

3. **Reference task IDs when relevant**
   ```bash
   /git-commit "fix: resolve authentication timeout TW-26134585"
   ```
