---
description: Run .NET tests with contextual output and coverage (helper)
allowedTools:
  - Bash
---

# .NET: Run Tests

Runs .NET tests with clear, contextual output including pass/fail counts, duration, and optional code coverage.

## Usage

```bash
/dotnet:test
/dotnet:test --verbosity detailed
/dotnet:test --filter "FullyQualifiedName~SubscriptionTests"
/dotnet:test --coverage
/dotnet:test --project Link.Subscriptions.Tests --configuration Release --coverage
```

## Input Parameters

All parameters are optional and follow standard `dotnet test` syntax:

- **--project** - Specific test project path (default: current directory)
- **--filter** - Test filter expression (e.g., "FullyQualifiedName~SubscriptionTests")
- **--verbosity** - Verbosity level: quiet, minimal, normal, detailed, diagnostic (default: minimal)
- **--coverage** - Collect code coverage (boolean flag)
- **--configuration** - Build configuration: Debug or Release (default: Debug)
- **--no-build** - Don't build before testing (boolean flag)
- **--no-restore** - Don't restore before testing (boolean flag)

## Implementation

1. **Parse command-line arguments:**
   ```bash
   project=""
   filter=""
   verbosity="minimal"
   coverage=false
   configuration="Debug"
   no_build=false
   no_restore=false

   for arg in "$@"; do
     case "$arg" in
       --project=*) project="${arg#*=}" ;;
       --project) shift; project="$1" ;;
       --filter=*) filter="${arg#*=}" ;;
       --filter) shift; filter="$1" ;;
       --verbosity=*) verbosity="${arg#*=}" ;;
       --verbosity) shift; verbosity="$1" ;;
       --coverage) coverage=true ;;
       --configuration=*) configuration="${arg#*=}" ;;
       --configuration) shift; configuration="$1" ;;
       --no-build) no_build=true ;;
       --no-restore) no_restore=true ;;
     esac
   done
   ```

2. **Build test command:**
   ```bash
   cmd="dotnet test"

   if [ -n "$project" ]; then
     cmd="$cmd $project"
   fi

   if [ -n "$filter" ]; then
     cmd="$cmd --filter \"$filter\""
   fi

   cmd="$cmd --verbosity $verbosity"
   cmd="$cmd --configuration $configuration"

   if [ "$no_build" = true ]; then
     cmd="$cmd --no-build"
   fi

   if [ "$no_restore" = true ]; then
     cmd="$cmd --no-restore"
   fi

   if [ "$coverage" = true ]; then
     cmd="$cmd --collect:\"XPlat Code Coverage\""
   fi
   ```

3. **Display test context:**
   ```bash
   echo "🧪 Running .NET Tests"
   echo ""
   echo "Configuration:"
   [ -n "$project" ] && echo "  Project: $project"
   echo "  Build Config: $configuration"
   echo "  Verbosity: $verbosity"
   [ -n "$filter" ] && echo "  Filter: $filter"
   [ "$coverage" = true ] && echo "  Coverage: Enabled"
   echo ""
   ```

4. **Execute tests and capture output:**
   ```bash
   # Run tests and capture both stdout and stderr
   test_output=$(eval "$cmd" 2>&1)
   exit_code=$?

   # Display full output
   echo "$test_output"
   echo ""
   ```

5. **Parse test results:**
   ```bash
   # Extract counts from output
   passed=$(echo "$test_output" | grep -oP "Passed! \K\d+(?= test)" || echo "0")
   failed=$(echo "$test_output" | grep -oP "Failed! \K\d+(?= test)" || echo "0")
   skipped=$(echo "$test_output" | grep -oP "Skipped \K\d+(?= test)" || echo "0")
   total=$(echo "$test_output" | grep -oP "Total: \K\d+(?= test)" || echo "$passed")

   # Extract duration
   duration=$(echo "$test_output" | grep -oP "Time: \K[0-9.]+s" || echo "unknown")

   # Extract coverage if enabled
   if [ "$coverage" = true ]; then
     coverage_pct=$(echo "$test_output" | grep -oP "Line coverage: \K[0-9.]+%" || echo "")
   fi
   ```

6. **Display summary:**

**Success (all tests passed):**
```text
✅ Tests Passed: 47
⏭️  Tests Skipped: 2
⏱️  Duration: 4.3s

Code Coverage: 85.2%
```

**Failure (some tests failed):**
```text
✅ Tests Passed: 45
❌ Tests Failed: 2
⏭️  Tests Skipped: 2
⏱️  Duration: 4.8s

Failed Tests:
  - SubscriptionSyncServiceTests.SyncSubscriptionFromStaxBillAsync_InvalidId_ReturnsFailure
  - SubscriptionSyncServiceTests.SyncSubscriptionFromStaxBillAsync_ApiError_RetriesWithBackoff

Review test output above for details.
```

7. **Return appropriate exit code:**
   ```bash
   exit $exit_code
   ```

## Error Handling

**If project not found:**
```text
❌ Test project not found: Link.Subscriptions.Tests

Verify project path:
  - Check project exists
  - Use relative or absolute path
  - Example: --project tests/Link.Subscriptions.Tests
```

**If no tests discovered:**
```text
⚠️  No tests discovered

Possible causes:
  - Filter too restrictive (--filter)
  - Test project has no test classes
  - Test framework not installed (xUnit, NUnit, MSTest)

Current filter: FullyQualifiedName~NonExistentTest
```

**If build fails before tests:**
```text
❌ Build failed - cannot run tests

Build errors must be resolved before running tests.

Options:
  - Fix build errors
  - Run: /dotnet:build to see detailed errors
  - Use: /dotnet:test --no-build (if recently built)
```

**If coverage collection fails:**
```text
⚠️  Tests passed but coverage collection failed

Tests: ✅ 47 passed
Coverage: ❌ Collection failed

Possible causes:
  - Coverage package not installed
  - Run: dotnet add package coverlet.collector
```

## Notes

- **Default verbosity**: Uses "minimal" for concise output
- **Exit codes**: Returns 0 if all tests pass, 1 if any fail
- **Coverage**: Requires `coverlet.collector` package
- **Filters**: Supports full .NET test filter syntax
- **Performance**: Use `--no-build` and `--no-restore` for faster runs after initial build

## Use Cases

### Run All Tests (Default)
```bash
# Run all tests in current project/solution
/dotnet:test
```

### Run with Detailed Output
```bash
# See more test details
/dotnet:test --verbosity detailed
```

### Run Specific Test Class
```bash
# Filter by class name
/dotnet:test --filter "FullyQualifiedName~SubscriptionSyncServiceTests"
```

### Run Specific Test Method
```bash
# Filter by method name
/dotnet:test --filter "FullyQualifiedName~SubscriptionSyncServiceTests.SyncSubscriptionFromStaxBillAsync_ValidId_FetchesSubscription"
```

### Run Tests with Coverage
```bash
# Collect code coverage
/dotnet:test --coverage
```

### Run Tests in Release Mode
```bash
# Test release build
/dotnet:test --configuration Release
```

### Run Tests Without Building
```bash
# Skip build step (faster if already built)
/dotnet:test --no-build
```

### Run Specific Project Tests
```bash
# Test specific project
/dotnet:test --project Link.Subscriptions.Tests
```

### Combined Options
```bash
# Release build with coverage and detailed output
/dotnet:test --configuration Release --coverage --verbosity detailed
```

## Integration with Workflow

### During Development
```bash
# Quick test run after code changes
/dotnet:test --no-restore

# Or just
/dotnet:test
```

### Before Commit
```bash
# Full test suite with coverage
/dotnet:test --coverage --verbosity detailed
```

### Pre-PR Checklist
```bash
# 1. Run all tests
/dotnet:test --coverage

# 2. Verify all pass
# ✅ 47 passed, 0 failed

# 3. Code review
/quality:code-review

# 4. Commit and push
/git:git-commit "feat: implement feature with tests"
/git:git-push
```

## Best Practices

### 1. Run Tests Frequently
```bash
# After every significant code change
/dotnet:test
```

### 2. Use Filters During Development
```bash
# Focus on tests you're working on
/dotnet:test --filter "FullyQualifiedName~FeatureTests"
```

### 3. Verify Coverage Periodically
```bash
# Check coverage weekly or before PRs
/dotnet:test --coverage
```

### 4. Test Both Debug and Release
```bash
# Ensure no release-only issues
/dotnet:test --configuration Debug
/dotnet:test --configuration Release
```

### 5. Keep Tests Fast
```bash
# Use --no-restore and --no-build when possible
/dotnet:test --no-restore --no-build
```

## Test Output Interpretation

### Passed Tests
```text
✅ Tests Passed: 47
```
**Action:** None needed, all tests passing

### Failed Tests
```text
❌ Tests Failed: 2
```
**Action:** Fix failing tests before committing

### Skipped Tests
```text
⏭️  Tests Skipped: 2
```
**Action:** Review why tests are skipped (marked with `[Skip]` attribute)

### Coverage Percentage
```text
Code Coverage: 85.2%
```
**Targets:**
- < 70%: Improve test coverage
- 70-85%: Good coverage
- \> 85%: Excellent coverage

## Filter Syntax

### By Test Class
```bash
/dotnet:test --filter "FullyQualifiedName~SubscriptionTests"
```

### By Test Method
```bash
/dotnet:test --filter "FullyQualifiedName~SubscriptionTests.GetSubscription_ValidId_ReturnsSubscription"
```

### By Category (Trait)
```bash
/dotnet:test --filter "Category=Integration"
```

### By Priority
```bash
/dotnet:test --filter "Priority=1"
```

### Combined Filters
```bash
# Test class AND category
/dotnet:test --filter "FullyQualifiedName~SubscriptionTests&Category=Unit"
```

## Coverage Details

**Coverage report location:**
```
TestResults/*/coverage.cobertura.xml
```

**View coverage:**
```bash
# Generate HTML report (requires reportgenerator)
dotnet tool install -g dotnet-reportgenerator-globaltool

reportgenerator \
  -reports:"TestResults/*/coverage.cobertura.xml" \
  -targetdir:"coveragereport" \
  -reporttypes:Html

# Open report
open coveragereport/index.html
```

## See Also

- [/dotnet:build](build.md) - Build .NET projects
- [/dotnet:restore](restore.md) - Restore NuGet packages
- [/quality:code-review](../quality/code-review.md) - Code review before commit
- [/workflow:deliver](../workflow/deliver.md) - Complete delivery workflow
