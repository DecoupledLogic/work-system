# .NET Commands

.NET build, test, and restore automation with clear output.

## Commands

| Command | Description |
|---------|-------------|
| `/dotnet:test` | Run tests with coverage |
| `/dotnet:build` | Build solution/project |
| `/dotnet:restore` | Restore NuGet packages |

## Quick Examples

```bash
# Standard workflow
/dotnet:restore
/dotnet:build
/dotnet:test

# Fast development loop (after restore)
/dotnet:build --no-restore
/dotnet:test --no-restore

# Release build with coverage
/dotnet:build --configuration Release
/dotnet:test --configuration Release --coverage

# Filter tests
/dotnet:test --filter "FullyQualifiedName~FeatureTests"
```

## Output Format

```text
# Success
✅ Tests Passed: 47
✅ Build Succeeded

# With warnings
⚠️  Build Succeeded with Warnings

# Failure
❌ Tests Failed: 2
❌ Build Failed
```

## Common Options

| Option | Description |
|--------|-------------|
| `--configuration` | Debug or Release |
| `--no-restore` | Skip restore step |
| `--coverage` | Collect code coverage |
| `--filter` | Test filter expression |
| `--verbosity` | Output detail level |

See source commands in [commands/dotnet/](../../../commands/dotnet/) for full documentation.
