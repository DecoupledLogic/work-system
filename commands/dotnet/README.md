# .NET Commands

.NET build, test, and package automation commands with clear, contextual output.

## Commands

| Command | Description |
|---------|-------------|
| `/dotnet:test` | Run tests with contextual output and coverage |
| `/dotnet:build` | Build solution/project with clear success/failure reporting |
| `/dotnet:restore` | Restore NuGet packages with progress |

## Overview

These commands wrap the standard `dotnet` CLI tools with enhanced output formatting, error handling, and workflow integration. They provide:

- ✅ **Clear success/failure indicators**
- 📊 **Summarized metrics** (test counts, build times, package counts)
- 🎯 **Contextual error messages** with suggested fixes
- 🔄 **Workflow integration** with other work-system commands

## Quick Start

### Standard Development Workflow

```bash
# 1. Restore packages (after clone or package changes)
/dotnet:restore

# 2. Build the project
/dotnet:build

# 3. Run tests
/dotnet:test

# 4. If all pass, commit
/git:git-commit "feat: implement feature"
```

### Quick Development Loop

```bash
# After code changes (packages already restored)
/dotnet:build --no-restore
/dotnet:test --no-restore
```

### Pre-Commit Checklist

```bash
# Release build with coverage
/dotnet:build --configuration Release
/dotnet:test --configuration Release --coverage

# Code review
/quality:code-review

# Commit if all pass
/git:git-commit "feat: complete feature"
```

## Command Details

### /dotnet:test

Run .NET tests with clear output and optional coverage.

**Basic usage:**
```bash
/dotnet:test
```

**With coverage:**
```bash
/dotnet:test --coverage
```

**Filter specific tests:**
```bash
/dotnet:test --filter "FullyQualifiedName~SubscriptionTests"
```

**Output:**
```text
✅ Tests Passed: 47
⏭️  Tests Skipped: 2
⏱️  Duration: 4.3s

Code Coverage: 85.2%
```

[Full documentation →](test.md)

### /dotnet:build

Build .NET project with clear success/failure reporting.

**Basic usage:**
```bash
/dotnet:build
```

**Release build:**
```bash
/dotnet:build --configuration Release
```

**Specific project:**
```bash
/dotnet:build --project SubscriptionsMicroservice.sln
```

**Output:**
```text
✅ Build Succeeded

   Configuration: Release
   Warnings: 0
   Errors: 0
   Duration: 8.2s
```

[Full documentation →](build.md)

### /dotnet:restore

Restore NuGet packages with progress.

**Basic usage:**
```bash
/dotnet:restore
```

**Force refresh:**
```bash
/dotnet:restore --force
```

**Output:**
```text
✅ Restore Succeeded

   Packages: 147 restored
   Warnings: 0
   Errors: 0
   Duration: 3.1s
```

[Full documentation →](restore.md)

## Workflow Integration

### Story Delivery Workflow

```bash
# 1. Start story
/delivery:log-start 1.1.1 "Story Title" feature/1.1.1-story

# 2. Create branch
/git:git-create-branch feature/1.1.1-story

# 3. Implement with TDD
# ... write code and tests ...

# 4. Run tests frequently
/dotnet:test

# 5. Build when ready
/dotnet:build

# 6. Final verification
/dotnet:test --coverage
/quality:code-review

# 7. Commit and push
/git:git-commit "feat: implement story"
/git:git-push

# 8. Create PR
/azuredevops:ado-create-pr ...

# 9. After merge, log completion
/delivery:log-complete 1.1.1 https://pr-url 4 "Notes"
```

### TDD Workflow (Red-Green-Refactor)

```bash
# RED: Write failing test
# ... edit test file ...
/dotnet:test --filter "FullyQualifiedName~NewFeatureTests"
# ❌ Tests Failed: 1

# GREEN: Write minimal code to pass
# ... edit code file ...
/dotnet:test --filter "FullyQualifiedName~NewFeatureTests"
# ✅ Tests Passed: 1

# REFACTOR: Improve code quality
# ... refactor code ...
/dotnet:test --filter "FullyQualifiedName~NewFeatureTests"
# ✅ Tests Passed: 1
```

### CI/CD Simulation

```bash
# Simulate what CI pipeline will do
/dotnet:restore
/dotnet:build --configuration Release --no-restore
/dotnet:test --configuration Release --no-restore --coverage
```

## Common Patterns

### After Git Pull

```bash
# Check if packages changed
git diff HEAD@{1} -- *.csproj

# If packages changed
/dotnet:restore

# Then build
/dotnet:build --no-restore
```

### Before Creating PR

```bash
# Full verification
/dotnet:restore --force
/dotnet:build --configuration Release
/dotnet:test --configuration Release --coverage
/quality:code-review
```

### Troubleshooting Build Issues

```bash
# 1. Clean restore
dotnet nuget locals all --clear
/dotnet:restore --force

# 2. Clean build
/dotnet:build --no-incremental

# 3. Run tests
/dotnet:test
```

### Performance Optimization

```bash
# Initial setup (slow)
/dotnet:restore

# Subsequent builds (fast)
/dotnet:build --no-restore
/dotnet:test --no-restore
```

## Best Practices

### 1. Test Frequently

```bash
# After every significant code change
/dotnet:test
```

**Benefits:**
- Catch regressions early
- Fast feedback loop
- Confidence in changes

### 2. Build Both Configurations

```bash
# Develop in Debug
/dotnet:build --configuration Debug
/dotnet:test

# Verify in Release before PR
/dotnet:build --configuration Release
/dotnet:test --configuration Release
```

**Rationale:**
- Release may have different optimizations
- Catches release-only issues
- Ensures production parity

### 3. Use Filters During Development

```bash
# Focus on what you're working on
/dotnet:test --filter "FullyQualifiedName~FeatureTests"
```

**Benefits:**
- Faster test runs
- Better focus
- Quick feedback

### 4. Monitor Coverage

```bash
# Check coverage periodically
/dotnet:test --coverage
```

**Targets:**
- < 70%: Improve coverage
- 70-85%: Good coverage
- \> 85%: Excellent coverage

### 5. Fix Warnings

```bash
# Don't ignore build warnings
⚠️  Build Succeeded with Warnings  # <- Fix these!
```

**Rationale:**
- Warnings often indicate real issues
- Can become errors in future .NET versions
- Clean builds are better builds

## Command Options Reference

### Common Options (All Commands)

| Option | Description | Example |
|--------|-------------|---------|
| `--verbosity` | Output detail level | `--verbosity detailed` |
| `--project` | Specific project/solution | `--project Microservice.sln` |
| `--configuration` | Debug or Release | `--configuration Release` |

### Test-Specific Options

| Option | Description | Example |
|--------|-------------|---------|
| `--filter` | Test filter expression | `--filter "FullyQualifiedName~Tests"` |
| `--coverage` | Collect code coverage | `--coverage` |
| `--no-build` | Skip build step | `--no-build` |
| `--no-restore` | Skip restore step | `--no-restore` |

### Build-Specific Options

| Option | Description | Example |
|--------|-------------|---------|
| `--no-incremental` | Full rebuild | `--no-incremental` |
| `--force` | Rebuild all dependencies | `--force` |

### Restore-Specific Options

| Option | Description | Example |
|--------|-------------|---------|
| `--force` | Ignore cache | `--force` |
| `--no-cache` | Don't use or update cache | `--no-cache` |
| `--ignore-failed-sources` | Continue on source failures | `--ignore-failed-sources` |

## Output Interpretation

### Success Indicators

```text
✅ Tests Passed: 47        # All tests passed
✅ Build Succeeded         # Build completed
✅ Restore Succeeded       # Packages restored
```

**Action:** Proceed to next step

### Warning Indicators

```text
⚠️  Build Succeeded with Warnings    # Review warnings
⚠️  Tests Passed with Skipped Tests  # Check skipped tests
⚠️  Restore Succeeded with Warnings  # Review package warnings
```

**Action:** Review warnings before proceeding

### Failure Indicators

```text
❌ Tests Failed: 2         # Fix failing tests
❌ Build Failed            # Fix build errors
❌ Restore Failed          # Fix package issues
```

**Action:** Fix issues and retry

## Troubleshooting

### Build Failures

**Symptoms:**
```text
❌ Build Failed
Errors: 5
```

**Solutions:**
```bash
# 1. Check for missing packages
/dotnet:restore --force

# 2. Clean build
/dotnet:build --no-incremental

# 3. Check verbosity
/dotnet:build --verbosity detailed
```

### Test Failures

**Symptoms:**
```text
❌ Tests Failed: 2
```

**Solutions:**
```bash
# 1. Run specific failing test
/dotnet:test --filter "FullyQualifiedName~FailingTest"

# 2. Run with detailed output
/dotnet:test --verbosity detailed

# 3. Check test logs
```

### Package Restore Issues

**Symptoms:**
```text
❌ Restore Failed
Package 'X' not found
```

**Solutions:**
```bash
# 1. Clear cache and retry
dotnet nuget locals all --clear
/dotnet:restore --force

# 2. Check package sources
dotnet nuget list source

# 3. Verify network/auth
/dotnet:restore --ignore-failed-sources
```

## Performance Tips

1. **Restore once, build many**
   ```bash
   /dotnet:restore
   /dotnet:build --no-restore
   /dotnet:test --no-restore
   ```

2. **Use test filters**
   ```bash
   # During development
   /dotnet:test --filter "FullyQualifiedName~FeatureTests"

   # Full suite before commit
   /dotnet:test
   ```

3. **Skip unnecessary steps**
   ```bash
   # After initial restore
   /dotnet:build --no-restore

   # After build
   /dotnet:test --no-build
   ```

4. **Use incremental builds**
   ```bash
   # Default is incremental (fast)
   /dotnet:build

   # Only disable for troubleshooting
   /dotnet:build --no-incremental
   ```

## See Also

- [/quality:code-review](../quality/code-review.md) - Code review before commit
- [/delivery:log-complete](../delivery/log-complete.md) - Log story completion
- [/workflow:deliver](../workflow/deliver.md) - Complete delivery workflow
- [/git:git-commit](../git/git-commit.md) - Commit changes
- [/azuredevops:ado-create-pr](../azuredevops/ado-create-pr.md) - Create pull request
