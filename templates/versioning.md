# Template Versioning

This document describes the versioning system for process templates.

## Versioning Scheme

Templates use **Semantic Versioning** (SemVer):

```
MAJOR.MINOR.PATCH
```

- **MAJOR**: Breaking changes (removed sections, incompatible validation rules)
- **MINOR**: New features (new sections, new optional fields)
- **PATCH**: Bug fixes (typos, clarifications)

## Directory Structure

### Flat (Single Version)

For templates that don't need version history:

```
templates/
├── support/
│   ├── generic.json          # Current version
│   └── remove-profile.json
└── product/
    └── feature.json
```

### Versioned (Multiple Versions)

For templates needing multiple active versions:

```
templates/
└── product/
    ├── story.json            # Redirect/alias to latest
    └── story/
        ├── v1.0.0.json       # Original version
        ├── v1.1.0.json       # Added optional section
        ├── v2.0.0.json       # Breaking change
        └── latest.json       # Symlink to current version
```

## Version Resolution

### Work Item References

Work items reference templates with optional version:

```json
// Latest version (default)
"processTemplate": "product/story"

// Specific version
"processTemplate": "product/story/v1.1.0"

// Latest symlink (explicit)
"processTemplate": "product/story/latest"
```

### Resolution Order

1. Check if exact path exists (e.g., `product/story/v1.1.0.json`)
2. Check if versioned directory exists (e.g., `product/story/`)
3. Check for `latest.json` symlink in versioned directory
4. Check for flat file (e.g., `product/story.json`)
5. Fail with "template not found" error

## When to Version

### Create New Version

- Adding required sections → MAJOR bump
- Changing validation rules that could fail existing items → MAJOR bump
- Adding optional sections → MINOR bump
- Adding recommended sections → MINOR bump
- Changing prompts or examples → PATCH bump
- Fixing typos → PATCH bump

### Keep Single Version

- Template is new and still evolving
- No work items currently reference the template
- Changes are backward compatible

## Upgrading Work Items

### Automatic Upgrade

Work items without version specifier get the latest:

```json
{
  "processTemplate": "product/story"
  // Always resolves to latest version
}
```

### Pinned Version

Work items can pin to a specific version:

```json
{
  "processTemplate": "product/story/v1.0.0"
  // Always uses v1.0.0, even if v2.0.0 exists
}
```

### Migration Path

When a major version is released:

1. Old work items continue using pinned version
2. New work items get latest version
3. Optional: Migration script to upgrade old items

## Registry Integration

The `registry.json` tracks template versions:

```json
{
  "templates": {
    "product/story": {
      "version": "1.1.0",
      "path": "product/story/v1.1.0.json",
      "availableVersions": ["1.0.0", "1.1.0"],
      "deprecated": false
    }
  }
}
```

### Registry Updates

When releasing a new version:

1. Create versioned file: `product/story/v1.2.0.json`
2. Update symlink: `ln -sf v1.2.0.json latest.json`
3. Update registry:
   ```json
   {
     "version": "1.2.0",
     "path": "product/story/v1.2.0.json",
     "availableVersions": ["1.0.0", "1.1.0", "1.2.0"]
   }
   ```

## Deprecation

### Deprecating a Version

Mark a version as deprecated in the registry:

```json
{
  "product/story/v1.0.0": {
    "deprecated": true,
    "deprecationReason": "Use v2.0.0 for improved validation",
    "deprecatedAt": "2024-12-07",
    "removalDate": "2025-03-07"
  }
}
```

### Deprecation Warnings

When a deprecated version is used:

```
WARNING: Template product/story/v1.0.0 is deprecated.
Reason: Use v2.0.0 for improved validation
Will be removed: 2025-03-07
```

## Examples

### Creating a New Version

```bash
# 1. Copy current version
cp templates/product/story/v1.0.0.json templates/product/story/v1.1.0.json

# 2. Edit the new version
# Add new optional section, bump version number

# 3. Update symlink
cd templates/product/story
ln -sf v1.1.0.json latest.json

# 4. Update registry.json
# Add v1.1.0 to availableVersions, update version field
```

### Converting to Versioned

```bash
# 1. Create version directory
mkdir templates/product/story

# 2. Move current file as v1.0.0
mv templates/product/story.json templates/product/story/v1.0.0.json

# 3. Create latest symlink
cd templates/product/story
ln -sf v1.0.0.json latest.json

# 4. Create redirect file (optional)
echo '{ "$ref": "./story/latest.json" }' > templates/product/story.json
```

## Best Practices

1. **Start Simple**: Use flat files until versioning is needed
2. **Document Changes**: Add changelog in template metadata
3. **Backward Compatible**: Prefer adding optional fields over breaking changes
4. **Test Validation**: Ensure existing work items still validate
5. **Clear Deprecation**: Give ample warning before removing versions

## Template Changelog

Each template should track changes in metadata:

```json
{
  "metadata": {
    "version": "1.1.0",
    "changelog": [
      {
        "version": "1.1.0",
        "date": "2024-12-07",
        "changes": ["Added technical_notes section"]
      },
      {
        "version": "1.0.0",
        "date": "2024-12-01",
        "changes": ["Initial release"]
      }
    ]
  }
}
```

---

*Last Updated: 2024-12-07*
