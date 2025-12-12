---
description: Restore NuGet packages with progress reporting (helper)
allowedTools:
  - Bash
---

# .NET: Restore Packages

Restores NuGet packages for a .NET solution or project with clear progress and status reporting.

## Usage

```bash
/dotnet:restore
/dotnet:restore --project SubscriptionsMicroservice.sln
/dotnet:restore --verbosity detailed
/dotnet:restore --force
```

## Input Parameters

All parameters are optional and follow standard `dotnet restore` syntax:

- **--project** - Specific project/solution path (default: current directory)
- **--verbosity** - Verbosity level: quiet, minimal, normal, detailed, diagnostic (default: minimal)
- **--force** - Force restore even if cache is valid (boolean flag)
- **--no-cache** - Don't use NuGet package cache (boolean flag)
- **--ignore-failed-sources** - Treat package source failures as warnings (boolean flag)

## Implementation

1. **Parse command-line arguments:**
   ```bash
   project=""
   verbosity="minimal"
   force=false
   no_cache=false
   ignore_failed_sources=false

   for arg in "$@"; do
     case "$arg" in
       --project=*) project="${arg#*=}" ;;
       --project) shift; project="$1" ;;
       --verbosity=*) verbosity="${arg#*=}" ;;
       --verbosity) shift; verbosity="$1" ;;
       --force) force=true ;;
       --no-cache) no_cache=true ;;
       --ignore-failed-sources) ignore_failed_sources=true ;;
     esac
   done
   ```

2. **Build restore command:**
   ```bash
   cmd="dotnet restore"

   if [ -n "$project" ]; then
     cmd="$cmd $project"
   fi

   cmd="$cmd --verbosity $verbosity"

   if [ "$force" = true ]; then
     cmd="$cmd --force"
   fi

   if [ "$no_cache" = true ]; then
     cmd="$cmd --no-cache"
   fi

   if [ "$ignore_failed_sources" = true ]; then
     cmd="$cmd --ignore-failed-sources"
   fi
   ```

3. **Display restore context:**
   ```bash
   echo "📦 Restoring NuGet Packages"
   echo ""
   echo "Configuration:"
   [ -n "$project" ] && echo "  Project: $project" || echo "  Project: Current directory"
   echo "  Verbosity: $verbosity"
   [ "$force" = true ] && echo "  Force: Yes (ignoring cache)"
   [ "$no_cache" = true ] && echo "  Cache: Disabled"
   echo ""
   ```

4. **Execute restore:**
   ```bash
   # Capture start time
   start_time=$(date +%s)

   # Run restore
   restore_output=$(eval "$cmd" 2>&1)
   exit_code=$?

   # Calculate duration
   end_time=$(date +%s)
   duration=$((end_time - start_time))

   # Display output
   echo "$restore_output"
   echo ""
   ```

5. **Parse restore results:**
   ```bash
   # Count packages restored
   packages_restored=$(echo "$restore_output" | grep -c "Restored" || echo "0")

   # Check for failures
   failures=$(echo "$restore_output" | grep -c "error" || echo "0")

   # Check for warnings
   warnings=$(echo "$restore_output" | grep -c "warn" || echo "0")
   ```

6. **Display summary:**

**Success:**
```text
✅ Restore Succeeded

   Packages: 147 restored
   Warnings: 0
   Errors: 0
   Duration: 3.1s
```

**Success with warnings:**
```text
⚠️  Restore Succeeded with Warnings

   Packages: 147 restored
   Warnings: 2
   Errors: 0
   Duration: 3.5s

   Review warnings above.
```

**Failure:**
```text
❌ Restore Failed

   Packages: 140 restored (7 failed)
   Warnings: 1
   Errors: 7
   Duration: 5.2s

   Failed packages:
     - SomePackage.Core v1.2.3 - Not found
     - AnotherPackage v2.0.0 - Network error

   Retry with:
     /dotnet:restore --force
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

**If network error:**
```text
❌ Restore failed - network error

Unable to connect to NuGet package sources.

Check:
  - Internet connection
  - VPN/firewall settings
  - NuGet.org status

Retry:
  /dotnet:restore --ignore-failed-sources
```

**If package not found:**
```text
❌ Restore failed - package not found

Package 'SomePackage.Core' version '1.2.3' not found on any source.

Possible causes:
  - Package version doesn't exist
  - Package source not configured
  - Typo in package reference

Check:
  - Package name and version in .csproj
  - NuGet.config sources
```

**If auth required:**
```text
❌ Restore failed - authentication required

Private package source requires authentication.

Configure credentials:
  - Add to NuGet.config
  - Or use environment variables
  - Or run: dotnet nuget add source <url> -u <user> -p <password>
```

## Notes

- **Default behavior**: Uses local NuGet cache for speed
- **Exit codes**: Returns 0 on success, 1 on failure
- **Parallel downloads**: Downloads packages in parallel
- **Package sources**: Uses sources from NuGet.config
- **Lock files**: Updates package-lock.json if present

## Use Cases

### Standard Restore
```bash
# Restore packages for current solution
/dotnet:restore
```

### Specific Solution
```bash
# Restore for named solution
/dotnet:restore --project SubscriptionsMicroservice.sln
```

### Force Refresh
```bash
# Ignore cache and re-download
/dotnet:restore --force
```

### Ignore Cache
```bash
# Don't use or update cache
/dotnet:restore --no-cache
```

### Ignore Failed Sources
```bash
# Continue even if some sources fail
/dotnet:restore --ignore-failed-sources
```

### Detailed Output
```bash
# See all package restore details
/dotnet:restore --verbosity detailed
```

## Integration with Workflow

### Initial Setup
```bash
# After cloning repository
cd SubscriptionsMicroservice
/dotnet:restore
```

### After Pulling Changes
```bash
# After git pull that updated packages
git pull
/dotnet:restore
```

### Before Building
```bash
# Clean restore before build
/dotnet:restore
/dotnet:build
```

### CI/CD Pipeline
```bash
# Standard CI steps
/dotnet:restore
/dotnet:build --no-restore
/dotnet:test --no-restore
```

## Best Practices

### 1. Restore After Package Changes
```bash
# After modifying .csproj or adding packages
/dotnet:restore
```

### 2. Use Force for Issues
```bash
# When facing weird package errors
/dotnet:restore --force
```

### 3. Don't Restore Unnecessarily
```bash
# Build/test automatically restore if needed
# Only run explicitly when:
# - After git pull with package changes
# - After modifying .csproj
# - Troubleshooting package issues
```

### 4. Check Restore Before Building
```bash
# Ensure packages restored before build
/dotnet:restore

# Build without restore
/dotnet:build --no-restore  # Faster!
```

### 5. Use Verbosity for Debugging
```bash
# When troubleshooting package issues
/dotnet:restore --verbosity detailed
```

## Restore Output Interpretation

### Success
```text
✅ Restore Succeeded
Packages: 147 restored
```
**Action:** Proceed to building

### Success with Warnings
```text
⚠️  Restore Succeeded with Warnings
Warnings: 2
```
**Action:** Review warnings (usually safe to proceed)

### Failure
```text
❌ Restore Failed
Errors: 7
```
**Action:** Fix package references or network issues

## Common Restore Errors

### Package Not Found
```text
Error NU1101: Unable to find package 'PackageName'

Solutions:
  1. Check package name spelling
  2. Verify version exists
  3. Check package source configuration
```

### Version Conflict
```text
Error NU1107: Version conflict detected

Solutions:
  1. Update conflicting packages
  2. Add explicit package reference
  3. Use --force to override
```

### Network Timeout
```text
Error NU1301: Unable to load package source

Solutions:
  1. Check internet connection
  2. Retry: /dotnet:restore
  3. Use: /dotnet:restore --ignore-failed-sources
```

### Authentication Failure
```text
Error NU1301: Unable to authenticate to source

Solutions:
  1. Configure credentials in NuGet.config
  2. Use environment variables
  3. Check access to private feeds
```

## Package Sources

### View Configured Sources
```bash
dotnet nuget list source
```

### Add Package Source
```bash
dotnet nuget add source https://pkgs.dev.azure.com/org/_packaging/feed/nuget/v3/index.json \
  --name AzureArtifacts \
  --username user@example.com \
  --password <token>
```

### Disable Package Source
```bash
dotnet nuget disable source AzureArtifacts
```

## Performance Tips

1. **Use local cache** (default)
   - Much faster for repeated restores
   - Only use --no-cache when troubleshooting

2. **Restore once, build many**
   ```bash
   /dotnet:restore
   /dotnet:build --no-restore
   /dotnet:test --no-restore
   ```

3. **Use --force sparingly**
   - Only when cache is corrupted
   - Forces full re-download (slow)

4. **Configure package caching**
   - Use local NuGet cache
   - Consider package source mirrors

## Troubleshooting

### Corrupted Cache
```bash
# Clear NuGet cache and restore
dotnet nuget locals all --clear
/dotnet:restore --force
```

### Proxy Issues
```bash
# Configure proxy in NuGet.config
# Then restore
/dotnet:restore
```

### Lock File Issues
```bash
# Delete lock file and restore
rm packages.lock.json
/dotnet:restore
```

## See Also

- [/dotnet:build](build.md) - Build after restore
- [/dotnet:test](test.md) - Test after restore
- [/work:work-init](../work/work-init.md) - Initial project setup
