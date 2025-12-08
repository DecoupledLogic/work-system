# Markdown Standards

This document defines the markdown formatting and linting standards for all documentation in the dev-support directory. All guide files and task documents must adhere to these standards.

## Purpose

Consistent markdown formatting ensures:

- Documents render correctly across all viewers (GitHub, IDEs, documentation sites)
- Code examples are properly displayed and copyable
- Nested structures are correctly indented
- Automated linting can validate documents in CI/CD pipelines

## Linting Rules

### MD007: List Indentation

Use **2 spaces** for nested list indentation.

- ❌ 4-space indent: `····- Nested item` (where · = space)
- ✅ 2-space indent: `··- Nested item` (where · = space)

**Example**:

```markdown
- Parent item
  - Child item (2 spaces)
    - Grandchild item (4 spaces total)
```

### MD022: Blanks Around Headings

Headings must be surrounded by blank lines.

- ❌ Text immediately before/after heading (no blank line)
- ✅ Blank line before and after every heading

**Correct**:

```markdown
Some paragraph text here.

## Section Heading

Content after the heading.
```

**Incorrect**:

```markdown
Some paragraph text here.
## Section Heading
Content after the heading.
```

### MD024: No Duplicate Headings

Headings must be unique within the document. Prefix repeated section names with context.

- ❌ Multiple `#### Deployment` headings across epics
- ✅ `#### Epic 1 Deployment`, `#### Epic 2 Deployment`, `#### Epic 3 Deployment`

### MD030: List Marker Spacing

Use exactly **1 space** after list markers (`-`, `*`, `1.`, etc.).

- ❌ `-   Item` (3 spaces after marker)
- ✅ `- Item` (1 space after marker)

For ordered lists:

- ❌ `1.  Item` (2 spaces after marker)
- ✅ `1. Item` (1 space after marker)

### MD031: Fenced Code Blocks (Nested)

When nesting code blocks, the outer fence must use more backticks than the inner fence.

- ❌ Nested code blocks with same fence length (``` inside ```)
- ✅ Outer fence uses more backticks than inner (```` for outer, ``` for inner)

**Example of nested code blocks**:

`````markdown
Use 4+ backticks for outer fence when showing markdown with code:

````markdown
##### Story Example

```csharp
// Inner code block uses 3 backticks
public void Method() { }
```
````
`````

### MD032: Blanks Around Lists and Fenced Code Blocks

Lists and fenced code blocks must be surrounded by blank lines.

- ❌ Text immediately before/after list or code block (no blank line)
- ✅ Blank line before and after every list and fenced code block

**Correct (lists)**:

```markdown
Some paragraph text.

- List item 1
- List item 2

More paragraph text.
```

**Incorrect (lists)**:

```markdown
Some paragraph text.
- List item 1
- List item 2
More paragraph text.
```

**Correct (code blocks)**:

````markdown
Some text explaining the code.

```csharp
public void Example() { }
```

More text after the code block.
````

**Incorrect (code blocks)** - text runs into the code block:

```text
Some text explaining the code.    <-- No blank line before code
```csharp                         <-- Code block starts immediately
public void Example() { }
```                               <-- Code block ends
More text after the code block.   <-- No blank line after code
```

### MD036: No Emphasis as Heading

Use proper heading syntax instead of bold text for headings.

- ❌ `**Epic 1: Renewal Fix**`
- ✅ `### Epic 1: Renewal Fix`

### MD038: No Space in Code

Inline code spans should not have leading or trailing spaces inside the backticks.

- ❌ `` ` code ` `` (spaces inside backticks)
- ✅ `` `code` `` (no spaces inside backticks)

**Note**: When showing indented code patterns (like list indentation), use a code block instead of inline code, or use visual markers like `··` to represent spaces.

### MD040: Fenced Code Block Language

Fenced code blocks should specify a language for syntax highlighting.

- ❌ Code block with no language specified
- ✅ Code block with language (e.g., `csharp`, `bash`, `markdown`, `json`)

**Correct**:

````markdown
```csharp
public void Example() { }
```
````

**Incorrect** (missing language after opening fence):

```text
```                           <-- No language specified
public void Example() { }
```                           <-- Linter will flag this
```

**Common languages**: `csharp`, `bash`, `markdown`, `json`, `yaml`, `gherkin`, `sql`, `xml`, `text`

Use `text` for plain text output or when no syntax highlighting is appropriate.

## Validating Linting

Before committing any markdown document:

```bash
# Run markdownlint (if installed)
markdownlint <filename>.md

# Or use the built-in linter in your IDE (VS Code, etc.)
```

### Common Fixes

```bash
# Fix list marker spacing (3 spaces to 1 space)
sed -i 's/^-   /- /g' document.md

# Fix ordered list marker spacing (2 spaces to 1 space)
sed -i 's/^\([0-9]\+\)\.  /\1. /g' document.md

# Fix nested list indentation (4 spaces to 2 spaces)
sed -i 's/^    - /  - /g' document.md
```

## Mandatory Linting Enforcement

**Linting is not optional.** Every markdown document must pass linting before commit.

### Workflow Integration

1. **Before committing**: Run linter and fix all errors
2. **During code review**: Reviewer checks for linting compliance
3. **CI/CD**: Add markdownlint to pipeline (fail build on errors)

### IDE Setup (Recommended)

- **VS Code**: Install `markdownlint` extension (davidanson.vscode-markdownlint)
- **JetBrains**: Enable built-in Markdown linting in Settings → Editor → Inspections
- **Vim/Neovim**: Use `ale` or `coc-markdownlint`

### Pre-commit Hook (Optional)

```bash
# .git/hooks/pre-commit
#!/bin/bash
FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.md$')
if [ -n "$FILES" ]; then
    npx markdownlint-cli $FILES
    if [ $? -ne 0 ]; then
        echo "Markdown linting failed. Fix errors before committing."
        exit 1
    fi
fi
```

### When Linting Fails

1. Read the error message carefully (includes line number and rule ID)
2. Look up the rule at <https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md>
3. Fix the issue at the source (don't disable rules without justification)
4. Re-run linter to confirm fix
5. Commit only when all errors are resolved

**Never commit markdown files with known linting errors.** If a rule seems wrong for your use case, discuss with the team before disabling it.

## Document Structure Best Practices

### Heading Hierarchy

- Use heading levels sequentially (`#`, `##`, `###`, `####`)
- Don't skip levels (e.g., don't go from `##` to `####`)
- Use headings for document structure, not for emphasis

### Code Blocks

- Always specify the language for syntax highlighting
- Use appropriate languages: `markdown`, `bash`, `csharp`, `json`, `yaml`, `gherkin`
- Keep code examples concise and focused

### Lists

- Use `-` for unordered lists (consistent across documents)
- Use numbered lists (`1.`, `2.`) only when order matters
- Keep list items parallel in structure

### Tables

- Use tables for structured data with multiple columns
- Align columns for readability in source
- Include header row with separator

```markdown
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Data     | Data     | Data     |
```

## References

- [markdownlint Rules Documentation](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md)
- [CommonMark Specification](https://spec.commonmark.org/)
- [GitHub Flavored Markdown](https://github.github.com/gfm/)
