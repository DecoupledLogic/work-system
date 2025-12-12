---
description: Build .NET solution/project with clear output (helper)
allowedTools:
  - Bash
---

# .NET: Build Project

Builds a .NET solution or project with clear success/failure reporting and error summaries.

## Usage

```bash
/dotnet:build
/dotnet:build --configuration Release
/dotnet:build --project SubscriptionsMicroservice.sln
/dotnet:build --verbosity detailed
/dotnet:build --no-restore
```

## Input Parameters

All parameters are optional and follow standard `dotnet build` syntax:

- **--project** - Specific project/solution path (default: current directory)
- **--configuration** - Build configuration: Debug or Release (default: Debug)
- **--verbosity** - Verbosity level: quiet, minimal, normal, detailed, diagnostic (default: minimal)
- **--no-restore** - Skip package restoration (boolean flag)
- **--no-incremental** - Disable incremental build (boolean flag)
- **--force** - Force rebuild of all dependencies (boolean flag)

## Implementation

1. **Parse command-line arguments:**
   ```bash
   project=""
   configuration="Debug"
   verbosity="minimal"
   no_restore=false
   no_incremental=false
   force=false

   for arg in "$@"; do
     case "$arg" in
       --project=*) project="${arg#*=}" ;;
       --project) shift; project="$1" ;;
       --configuration=*) configuration="${arg#*=}" ;;
       --configuration) shift; configuration="$1" ;;
       --verbosity=*) verbosity="${arg#*=}" ;;
       --verbosity) shift; verbosity="$1" ;;
       --no-restore) no_restore=true ;;
       --no-incremental) no_incremental=true ;;
       --force) force=true ;;
     esac
   done
   ```

2. **Build command:**
   ```bash
   cmd="dotnet build"

   if [ -n "$project" ]; then
     cmd="$cmd $project"
   fi

   cmd="$cmd --configuration $configuration"
   cmd="$cmd --verbosity $verbosity"

   if [ "$no_restore" = true ]; then
     cmd="$cmd --no-restore"
   fi

   if [ "$no_incremental" = true ]; then
     cmd="$cmd --no-incremental"
   fi

   if [ "$force" = true ]; then
     cmd="$cmd --force"
   fi
   ```

3. **Display build context:**
   ```bash
   echo "🔨 Building .NET Project"
   echo ""
   echo "Configuration:"
   [ -n "$project" ] && echo "  Project: $project" || echo "  Project: Current directory"
   echo "  Build Config: $configuration"
   echo "  Verbosity: $verbosity"
   [ "$no_restore" = true ] && echo "  Restore: Skipped"
   echo ""
   ```

4. **Execute build:**
   ```bash
   # Capture start time
   start_time=$(date +%s)

   # Run build
   build_output=$(eval "$cmd" 2>&1)
   exit_code=$?

   # Calculate duration
   end_time=$(date +%s)
   duration=$((end_time - start_time))

   # Display output
   echo "$build_output"
   echo ""
   ```

5. **Parse build results:**
   ```bash
   # Extract counts
   warnings=$(echo "$build_output" | grep -oP "\K\d+(?= Warning\(s\))" || echo "0")
   errors=$(echo "$build_output" | grep -oP "\K\d+(?= Error\(s\))" || echo "0")
   ```

6. **Display summary:**

**Success:**
```text
✅ Build Succeeded

   Configuration: Release
   Warnings: 0
   Errors: 0
   Duration: 8.2s
```

**Success with warnings:**
```text
⚠️  Build Succeeded with Warnings

   Configuration: Release
   Warnings: 3
   Errors: 0
   Duration: 8.5s

   Review warnings above.
```

**Failure:**
```text
❌ Build Failed

   Configuration: Debug
   Warnings: 2
   Errors: 5
   Duration: 3.1s

   Fix errors and rebuild:
     /dotnet:build

   Error Summary:
     - CS0246: Type or namespace 'InvalidType' not found
     - CS1002: ; expected
     - CS0103: Name 'undefinedVar' does not exist
     - CS0029: Cannot implicitly convert type 'string' to 'int'
     - CS0115: No suitable method found to override
```

7. **Return exit code:**
   ```bash
   exit $exit_code
   ```

## Error Handling

**If project not found:**
```text
❌ Project not found: NonExistentProject.sln

Verify project path:
  - Check file exists
  - Use relative or absolute path
  - Example: --project path/to/project.sln
```

**If configuration invalid:**
```text
❌ Invalid configuration: InvalidConfig

Valid configurations: Debug, Release

Example: /dotnet:build --configuration Release
```

**If restore required:**
```text
❌ Build failed - packages not restored

Run restore first:
  /dotnet:restore

Or build with restore:
  /dotnet:build (without --no-restore)
```

## Notes

- **Default configuration**: Builds in Debug mode
- **Exit codes**: Returns 0 on success, 1 on failure
- **Incremental**: Uses incremental build by default for speed
- **Restore**: Runs restore by default unless --no-restore specified
- **Parallel**: Uses parallel build by default

## Use Cases

### Standard Build
```bash
# Build current solution/project
/dotnet:build
```

### Release Build
```bash
# Build for production
/dotnet:build --configuration Release
```

### Specific Solution
```bash
# Build named solution
/dotnet:build --project SubscriptionsMicroservice.sln
```

### Quick Rebuild
```bash
# Skip restore for faster build
/dotnet:build --no-restore
```

### Force Clean Build
```bash
# Rebuild everything
/dotnet:build --no-incremental --force
```

### Detailed Output
```bash
# See more build details
/dotnet:build --verbosity detailed
```

## Integration with Workflow

### During Development
```bash
# Quick build after changes
/dotnet:build --no-restore
```

### Before Running Tests
```bash
# Ensure clean build
/dotnet:build

# Then test
/dotnet:test
```

### Before Commit
```bash
# Build release to catch release-only issues
/dotnet:build --configuration Release

# Run tests
/dotnet:test --configuration Release
```

### CI/CD Simulation
```bash
# Clean build like CI would do
/dotnet:restore
/dotnet:build --configuration Release
/dotnet:test --configuration Release --coverage
```

## Best Practices

### 1. Build Often
```bash
# After every significant change
/dotnet:build
```

### 2. Fix Warnings
```bash
# Treat warnings seriously
# Don't commit with warnings
⚠️  Build Succeeded with Warnings  # <- Fix these!
```

### 3. Test Both Configurations
```bash
# Debug for development
/dotnet:build --configuration Debug

# Release before PR
/dotnet:build --configuration Release
```

### 4. Use --no-restore When Appropriate
```bash
# After initial restore
/dotnet:restore

# Subsequent builds can skip restore
/dotnet:build --no-restore  # Faster!
```

### 5. Clean Build Periodically
```bash
# Weekly or when weird errors occur
/dotnet:build --no-incremental --force
```

## Build Output Interpretation

### Success (No Warnings)
```text
✅ Build Succeeded
Warnings: 0
Errors: 0
```
**Action:** Proceed to testing

### Success (With Warnings)
```text
⚠️  Build Succeeded with Warnings
Warnings: 3
Errors: 0
```
**Action:** Review and fix warnings before committing

### Failure
```text
❌ Build Failed
Warnings: 2
Errors: 5
```
**Action:** Fix errors and rebuild

## Common Build Errors

### Missing NuGet Packages
```text
Error: The type or namespace 'PackageName' could not be found

Solution: /dotnet:restore
```

### Syntax Errors
```text
Error CS1002: ; expected

Solution: Fix syntax error in code
```

### Type Errors
```text
Error CS0246: The type or namespace 'TypeName' could not be found

Solution: Check using statements and references
```

### Version Mismatch
```text
Error: Project targets framework .NET 9.0 but installed SDK is 8.0

Solution: Install correct SDK or update project target
```

## Performance Tips

1. **Use incremental builds** (default)
   - Only rebuilds changed files
   - Much faster for development

2. **Skip restore when possible**
   ```bash
   /dotnet:build --no-restore
   ```

3. **Use parallel builds** (default)
   - Builds multiple projects simultaneously

4. **Avoid clean builds during development**
   - Only use --no-incremental for troubleshooting

## See Also

- [/dotnet:restore](restore.md) - Restore NuGet packages
- [/dotnet:test](test.md) - Run tests after build
- [/quality:code-review](../quality/code-review.md) - Review before commit
- [/workflow:deliver](../workflow/deliver.md) - Complete delivery workflow
