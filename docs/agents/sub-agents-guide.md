# Claude Code Sub-Agents Guide

Complete reference guide for creating and managing sub-agents in Claude Code.

## Table of Contents

1. [What are Sub-Agents?](#what-are-sub-agents)
2. [Directory Structure](#directory-structure)
3. [File Format and Structure](#file-format-and-structure)
4. [Sub-Agents vs Commands vs Prompts](#sub-agents-vs-commands-vs-prompts)
5. [How to Invoke Sub-Agents](#how-to-invoke-sub-agents)
6. [Complete Working Examples](#complete-working-examples)
7. [Built-in Sub-Agents](#built-in-sub-agents)
8. [Best Practices](#best-practices)
9. [Common Tool Configurations](#common-tool-configurations)
10. [Management and Workflow](#management-and-workflow)

---

## What are Sub-Agents?

Sub-agents are specialized AI assistants that Claude Code can automatically or explicitly invoke to handle specific tasks.

**Key Characteristics:**
- **Isolated Context**: Each operates with its own context window (prevents context pollution)
- **Custom System Prompts**: Define role, behavior, and capabilities
- **Restricted Tool Access**: Security through principle of least privilege
- **Independent Execution**: Run tasks and return structured results
- **Parallel Processing**: Multiple sub-agents can run simultaneously

**Benefits:**
- Offload context from main session
- Reusable across projects and sessions
- Specialized expertise for specific tasks
- Better security through tool restrictions
- Faster execution through parallelization

---

## Directory Structure

Sub-agents are stored as Markdown files in these locations (in order of precedence):

### Project-Level (Highest Priority)
```
.claude/agents/*.md
```
- Specific to the project
- Should be checked into version control for team collaboration
- Overrides user-level agents with same name

### User-Level (Global)
```
~/.claude/agents/*.md
```
- Available across all projects
- Personal agents for your workflow
- Not shared with team

### Plugin Agents
Plugins can provide additional agents via their `agents/` directory.

---

## File Format and Structure

Each sub-agent is a Markdown file with YAML frontmatter followed by system prompt instructions.

### Basic Template

```markdown
---
name: agent-name
description: When and why this agent should be invoked
tools: Read, Grep, Glob
model: haiku
---

You are a [role description]. Your purpose is to [purpose].

When invoked:
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Output Format
Return structured output as:
```json
{
  "result": "...",
  "metadata": {...}
}
```

Focus on:
- [Key consideration 1]
- [Key consideration 2]
```

### YAML Frontmatter Fields

| Field | Required | Purpose | Example Values |
|-------|----------|---------|----------------|
| `name` | **Yes** | Unique identifier | `code-reviewer`, `task-fetcher` |
| `description` | **Yes** | When agent should be invoked | "Review code changes for security issues" |
| `tools` | No | Permitted tools (comma-separated) | `Read, Write, Edit, Bash` |
| `model` | No | Which model to use | `sonnet`, `opus`, `haiku`, `inherit` |
| `permissionMode` | No | Permission level | `default`, `acceptEdits`, `bypassPermissions`, `plan` |
| `skills` | No | Available skills | Comma-separated skill names |

**Important Notes:**
- If `tools` is omitted, sub-agent inherits all tools from main agent
- Use `inherit` for model to use same model as parent
- Name must be lowercase with hyphens (no spaces or underscores)

### Field Details

#### `name` (Required)
- Unique identifier for the agent
- Used for explicit invocation
- Format: lowercase-with-hyphens
- Examples: `code-reviewer`, `test-runner`, `task-fetcher`

#### `description` (Required)
- Natural language description of when/why to invoke
- Used by Claude for automatic delegation
- Should be action-oriented and clear
- Examples:
  - "Use PROACTIVELY after code changes to review for security issues"
  - "Fetch and enrich tasks from Teamwork projects with pagination"
  - "Debug failing tests and suggest fixes"

#### `tools` (Optional)
- Comma-separated list of allowed tools
- Restricts what the agent can do (security)
- Available tools: `Read`, `Write`, `Edit`, `Bash`, `Glob`, `Grep`, `WebFetch`, `WebSearch`, `TodoWrite`, `Task`, and MCP tools
- If omitted: inherits all tools from parent

#### `model` (Optional)
- Which LLM to use for this agent
- Options: `sonnet`, `opus`, `haiku`, `inherit`
- Defaults to `inherit` (same as parent)
- Use `haiku` for cost-effective, simple tasks
- Use `sonnet` for complex reasoning

#### `permissionMode` (Optional)
- Controls permission behavior
- `default`: Normal permission prompts
- `acceptEdits`: Automatically accept file edits
- `bypassPermissions`: Skip permission checks
- `plan`: Run in plan mode (read-only)

---

## Sub-Agents vs Commands vs Prompts

| Aspect | Sub-Agents | Slash Commands | Prompts |
|--------|-----------|----------------|---------|
| **Directory** | `.claude/agents/` | `.claude/commands/` | N/A |
| **Format** | Markdown + YAML frontmatter | Markdown + YAML frontmatter | Plain text/markdown |
| **Context** | Isolated context window | Shares main context | Part of main context |
| **Invocation** | Automatic or explicit | Manual via `/command` | Inline in conversation |
| **Reusability** | Across sessions | Per invocation | Single use |
| **Tool Control** | Can restrict tools | Uses all allowed tools | Uses all tools |
| **Parallelization** | Can run multiple in parallel | Sequential | N/A |
| **Use Case** | Complex, repeatable workflows | Structured procedures | Quick instructions |
| **Version Control** | Check into git (project-level) | Check into git | Inline in messages |

### When to Use Sub-Agents

✅ **Use sub-agents when you need:**
- Complex, multi-step workflows
- Context isolation (prevent main session pollution)
- Specialized expertise/role-play
- Specific tool restrictions for security
- Parallel processing capability
- Reusable across sessions and projects
- Structured output for downstream processing

### When to Use Commands

✅ **Use slash commands when you need:**
- Quick, one-off structured procedures
- Full visibility in main context
- Manual invocation only
- Simple, repeatable prompts
- Interactive workflows
- Direct user interaction

### When to Use Inline Prompts

✅ **Use inline prompts when:**
- One-time instruction
- Conversational flow
- Quick clarifications
- Exploratory work

---

## How to Invoke Sub-Agents

### 1. Automatic Delegation (Recommended)

Claude automatically selects and invokes sub-agents based on task context and the agent's `description` field.

**Example:**
```
User: Review my recent code changes

[Claude automatically invokes code-reviewer sub-agent based on its description]
```

**How it works:**
- Claude analyzes the user's request
- Matches request to sub-agent descriptions
- Automatically invokes best match
- Returns structured results to main session

**Best for:**
- Proactive workflows
- Natural conversation flow
- Reducing cognitive load

### 2. Explicit Invocation

Request a specific sub-agent directly by name.

**Examples:**
```
User: Use the code-reviewer subagent to check my recent changes
User: Have the task-fetcher agent get my assigned tasks
User: Invoke the test-runner subagent
```

**Best for:**
- When you know exactly which agent you need
- Testing specific agents
- Debugging agent behavior

### 3. Programmatic Invocation

From slash commands or other agents, use the `Task` tool:

```markdown
Call the task-fetcher sub-agent to get tasks:

Use Task tool with:
- subagent_type: "task-fetcher"
- prompt: "Fetch tasks with status 'new' for user@example.com from project 12345"
- model: "haiku"
```

**Best for:**
- Chaining agents together
- Slash command orchestration
- Programmatic workflows

---

## Complete Working Examples

### Example 1: Code Reviewer Agent

**File:** `.claude/agents/quality:code-reviewer.md`

```markdown
---
name: code-reviewer
description: Use PROACTIVELY after code changes. Review modified files for security, style, and maintainability issues.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are a meticulous senior code reviewer with expertise in security, performance, and best practices.

When invoked:

1. Run `git diff --name-only` to identify modified files
2. For each modified file:
   - Read the file contents
   - Analyze for security vulnerabilities (SQL injection, XSS, command injection, etc.)
   - Check for code smells and anti-patterns
   - Identify performance issues
   - Assess maintainability concerns

3. Return structured JSON output:

```json
{
  "summary": "Brief one-line summary of findings",
  "filesReviewed": 5,
  "issues": [
    {
      "file": "src/auth.ts",
      "line": 42,
      "severity": "high",
      "category": "security",
      "description": "SQL injection vulnerability in user query",
      "suggestion": "Use parameterized queries or ORM"
    }
  ],
  "recommendations": [
    "Add input validation for user-supplied data",
    "Consider adding unit tests for edge cases"
  ]
}
```

**Focus Areas:**
- Security vulnerabilities (OWASP Top 10)
- Code smells and anti-patterns
- Performance bottlenecks
- Error handling gaps
- Test coverage gaps
- Documentation quality

**Tone:**
- Constructive and helpful
- Prioritize issues by severity
- Provide specific, actionable suggestions
- Include code examples when possible
```

### Example 2: Task Fetcher Agent

**File:** `~/.claude/agents/task-fetcher.md`

```markdown
---
name: task-fetcher
description: Fetch and enrich tasks from Teamwork projects with comprehensive pagination and parent task context. Returns structured task data.
tools: mcp__Teamwork__twprojects-get_task_lists_by_project_id, mcp__Teamwork__twprojects-list_tasks_by_tasklist, mcp__Teamwork__twprojects-get_task_subtasks, mcp__Teamwork__twprojects-get_task
model: haiku
---

You are a task data fetcher specialized in Teamwork API orchestration.

## Input Parameters

Expect the following from calling context:
- `projectId` (required): Teamwork project ID
- `statusFilters` (required): Array like ["new", "reopened"]
- `userEmail` (required): For assignee filtering
- `userName` (optional): Fallback for matching
- `userId` (optional): For exact matching

## Process

1. **Fetch all task lists** from project
2. **Paginate through all tasks** (up to 20 pages per list)
3. **Enrich with task list context** (add taskListId, taskListName)
4. **Fetch subtasks** for top-level assigned tasks
5. **Enrich subtasks** with parent task context
6. **Filter** by status and assignee
7. **Return structured output**

## Output Format

```json
{
  "tasks": [
    {
      "id": "26134585",
      "name": "Update database schema",
      "status": "new",
      "priority": "high",
      "dueDate": "2025-12-05",
      "estimateMinutes": 120,
      "assignees": [...],
      "taskListId": "1300158",
      "taskListName": "Production Support",
      "parentTask": {
        "id": "26134584",
        "name": "Service Plan Management",
        "assignees": [...]
      }
    }
  ],
  "metadata": {
    "totalTasks": 42,
    "taskListCount": 5,
    "projectId": "545123"
  }
}
```

**Critical:** All Teamwork IDs must be numeric only (no "TW-" prefix)
```

### Example 3: Test Runner Agent

**File:** `.claude/agents/test-runner.md`

```markdown
---
name: test-runner
description: Run test suites, analyze failures, and suggest fixes. Automatically invoked when tests need to be executed.
tools: Bash, Read, Grep, Glob
model: haiku
---

You are a test execution specialist focused on running tests and diagnosing failures.

## When Invoked

1. **Identify test framework** (Jest, pytest, go test, etc.)
2. **Run appropriate test command** with proper flags
3. **Capture and parse output**
4. **Analyze failures** and identify root causes
5. **Return structured results**

## Process

```bash
# Detect test framework
if package.json contains "jest": run npm test
if pytest.ini or test_*.py: run pytest
if go.mod: run go test ./...
if Cargo.toml: run cargo test
```

## Output Format

```json
{
  "summary": "8 passed, 2 failed, 1 skipped",
  "totalTests": 11,
  "passed": 8,
  "failed": 2,
  "skipped": 1,
  "failures": [
    {
      "test": "test_user_authentication",
      "file": "tests/auth_test.py",
      "error": "AssertionError: Expected 200, got 401",
      "suggestion": "Check JWT token generation in auth.py:42"
    }
  ],
  "executionTime": "2.34s"
}
```

**Focus:**
- Clear failure diagnostics
- Root cause analysis
- Actionable suggestions
- Performance insights
```

---

## Built-in Sub-Agents

Claude Code includes three built-in sub-agents:

### 1. `general-purpose`
- **Model:** Sonnet
- **Tools:** All tools (*)
- **Use Case:** Multi-step tasks requiring exploration and modifications
- **When:** Complex refactoring, feature implementation, debugging

### 2. `plan`
- **Model:** Haiku (fast and cheap)
- **Tools:** All tools
- **Use Case:** Codebase research in plan mode
- **When:** Understanding architecture, finding patterns

### 3. `explore`
- **Model:** Haiku
- **Tools:** Read-only (Read, Grep, Glob)
- **Use Case:** Fast, read-only searching and exploration
- **When:** Finding files, searching code, answering questions

---

## Best Practices

### 1. Start with Claude-Generated Agents

Use the `/agents` command to have Claude create initial agents based on your needs, then iterate.

```
/agents
> I want an agent that reviews pull requests for our team standards
```

### 2. Single Responsibility Principle

Each agent should have ONE clear purpose.

❌ **Bad:** "code-helper" (too vague)
✅ **Good:** "code-reviewer", "test-runner", "refactor-assistant"

### 3. Write Detailed System Prompts

Be specific about behavior, process, and output format.

**Good prompt structure:**
```markdown
You are [role with expertise].

When invoked:
1. [Specific step]
2. [Specific step]
3. [Specific step]

## Output Format
[Exact structure expected]

Focus on:
- [Priority 1]
- [Priority 2]
```

### 4. Limit Tool Access

Only grant tools actually needed (principle of least privilege).

**Examples:**
- Read-only analysis: `tools: Read, Grep, Glob`
- Code modification: `tools: Read, Write, Edit`
- Test execution: `tools: Bash, Read`

### 5. Choose Appropriate Models

- **Haiku:** Lightweight tasks, API orchestration, data fetching (3x cheaper)
- **Sonnet:** Complex reasoning, code review, refactoring
- **Opus:** Rare; only for most complex tasks
- **Inherit:** Use parent's model (most flexible)

### 6. Version Control Project Agents

Check `.claude/agents/*.md` into git for team collaboration.

```bash
git add .claude/agents/
git commit -m "Add code-reviewer and test-runner agents"
```

### 7. Start Small, Iterate

Begin with 3-4 core agents:
1. Code reviewer
2. Test runner
3. Task fetcher
4. Documentation generator

Add more as needs arise.

### 8. Use Action-Oriented Descriptions

Help Claude understand when to invoke automatically.

❌ **Bad:** "An agent for reviewing code"
✅ **Good:** "Use PROACTIVELY after code changes to review for security and style issues"

### 9. Return Structured Output

Agents should return JSON or structured markdown for downstream processing.

**Benefits:**
- Easy to parse in main session
- Can be passed to other agents
- Better for programmatic workflows

### 10. Document Your Agents

Include clear comments and examples in the agent file.

```markdown
## Examples

Input: projectId=12345, status=["new"]
Output: {tasks: [...], metadata: {...}}
```

---

## Common Tool Configurations

### Read-Only Analysis Agents
```yaml
tools: Read, Grep, Glob
```
**Use for:** Code exploration, documentation review, static analysis

### Research Specialists
```yaml
tools: Read, Grep, Glob, WebFetch, WebSearch
```
**Use for:** Technology research, documentation lookup, best practices

### Code Modification Agents
```yaml
tools: Read, Write, Edit, Bash, Glob, Grep
```
**Use for:** Refactoring, feature implementation, bug fixes

### Test Execution Agents
```yaml
tools: Read, Bash, Glob, Grep
```
**Use for:** Running tests, analyzing failures, performance testing

### API Orchestration Agents
```yaml
tools: mcp__ServiceName__*
```
**Use for:** External API integration, data fetching, third-party services

### Full Access Agents
```yaml
# Omit tools field to inherit all tools
```
**Use for:** Complex workflows requiring multiple tool types

---

## Management and Workflow

### Interactive Management (Recommended)

```bash
/agents
```

Opens interactive interface to:
- List all available agents
- Create new agents with guided prompts
- Edit existing agents
- Test agent behavior
- View agent usage statistics

### Direct Filesystem Management

Create and edit `.md` files directly:

```bash
# Create new agent
touch ~/.claude/agents/my-agent.md
code ~/.claude/agents/my-agent.md

# List agents
ls -la ~/.claude/agents/
ls -la .claude/agents/

# Edit agent
code .claude/agents/quality:code-reviewer.md
```

### Testing Agents

**Manual test:**
```
User: Use the code-reviewer agent to review src/auth.ts
```

**Automatic test:**
```
User: I just made some changes, can you review them?
[Claude should automatically invoke code-reviewer]
```

### Debugging Agents

1. **Check agent is loaded:**
   ```
   /agents
   ```

2. **Test explicit invocation:**
   ```
   Use the [agent-name] agent to [task]
   ```

3. **Check YAML syntax:**
   - Ensure proper indentation
   - Validate required fields (name, description)
   - Check tool names are valid

4. **Review description field:**
   - Make it action-oriented
   - Include trigger keywords

---

## Quick Reference

### Creating a New Agent

1. Choose location: `.claude/agents/` (project) or `~/.claude/agents/` (global)
2. Create file: `agent-name.md`
3. Add YAML frontmatter with name, description, tools, model
4. Write detailed system prompt with role, process, output format
5. Test with explicit invocation
6. Refine description for automatic invocation

### Agent Template Checklist

- [ ] YAML frontmatter with `---` delimiters
- [ ] `name` field (lowercase-with-hyphens)
- [ ] `description` field (action-oriented, clear)
- [ ] `tools` field (if restricting access)
- [ ] `model` field (haiku/sonnet/opus/inherit)
- [ ] Clear role definition
- [ ] Numbered process steps
- [ ] Structured output format
- [ ] Focus areas or priorities
- [ ] Examples (optional but helpful)

---

## Additional Resources

- Official docs: https://code.claude.com/docs/
- Agent examples: https://code.claude.com/docs/en/agents
- Best practices: https://code.claude.com/docs/en/best-practices
- Community agents: Check Claude Code community forums

---

*Last Updated: 2025-12-03*
