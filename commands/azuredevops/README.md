# Azure DevOps Server Slash Commands Reference

Direct API commands for Azure DevOps Server (on-premise) project management and pull request operations.

## Why These Commands?

These commands provide direct access to the Azure DevOps Server REST API without the overhead of external MCP servers. Benefits include:

- **Direct API access** - No middleware dependencies
- **Faster response times** - Direct curl calls
- **Better error messages** - Full control over error handling
- **Flexible configuration** - Easy to change servers/collections

---

## Configuration

### Step 1: API Credentials (Global - Named Profiles)

Create `~/.azuredevops/credentials.json` with named profiles:

```json
{
  "default": {
    "serverUrl": "https://azuredevops.discovertec.net",
    "collection": "Link",
    "pat": "YOUR_PERSONAL_ACCESS_TOKEN_HERE"
  },
  "client-b": {
    "serverUrl": "https://devops.client-b.com",
    "collection": "Projects",
    "pat": "DIFFERENT_PAT_HERE"
  }
}
```

**Profile Structure:**

- `default` - Used when no profile is specified
- Custom profiles - Any name you want (e.g., `client-b`, `internal`, `production`)

Each profile contains:

- `serverUrl` - Azure DevOps Server base URL
- `collection` - Collection name (path segment after base URL)
- `pat` - Personal Access Token for authentication

**Get your Personal Access Token (PAT):**

1. Log into Azure DevOps Server
2. Click your profile icon (top right) → Security
3. Personal Access Tokens → New Token
4. Set expiration and select scopes:
   - **Work Items:** Read & Write
   - **Code:** Read & Write
   - **Pull Requests:** Read & Write
5. Copy the generated token

**Security Notes:**

- Store credentials in home directory (`~/.azuredevops/`)
- Never commit credentials to git
- PAT should have minimum required permissions
- Rotate PAT periodically

### Step 2: Per-Repository Configuration

In each repository (or parent directory for multi-repo projects), configure in `.claude/work-manager.yaml`:

```yaml
manager: azuredevops
azuredevops:
  profile: default          # Which credentials profile to use
  project: MyProject        # Azure DevOps project name
  # repository: my-repo     # Optional: auto-detected from git remote for PR operations
  areaPath: MyProject\Team  # Optional: default area path
  iterationPath: MyProject\Sprint 1  # Optional: default iteration
```

**Multi-Repo Projects:**

For projects with multiple microservices, place config in the parent directory:

```yaml
# /projects/my-app/.claude/work-manager.yaml
manager: azuredevops
azuredevops:
  profile: default
  project: MyApp
  # repository omitted - PR commands auto-detect from git remote
```

PR commands will auto-detect the repository from the current directory's git remote, so you can run them from within any microservice subdirectory.

**Using Different Profiles:**

```yaml
# Repository connecting to client-b's Azure DevOps
manager: azuredevops
azuredevops:
  profile: client-b
  project: ClientProject
  # repository: client-app  # Optional: specify if not auto-detecting
```

### Optional: User Configuration

Create `~/.claude/azuredevops.json` for user identity:

```json
{
  "user": {
    "email": "your.email@company.com",
    "name": "Your Name",
    "id": "azure-user-guid"
  }
}
```

This is used for operations that need user context (like assigning work items).

---

## Work Item Commands

### `/ado-get-projects`

List all projects in the collection.

```bash
/ado-get-projects              # All projects
/ado-get-projects active       # Filter by state
```

**Returns:** JSON with projects array.

---

### `/ado-get-project`

Get details of a single project.

```bash
/ado-get-project MyProject
/ado-get-project "Project Name With Spaces"
```

**Parameters:**

- `projectName` (required) - Project name or ID

**Returns:** JSON with project details.

---

### `/ado-get-work-item`

Get details of a single work item by ID.

```bash
/ado-get-work-item 12345
/ado-get-work-item ADO-12345
```

**Parameters:**

- `workItemId` (required) - Work item ID (numeric, "ADO-" prefix is stripped)

**Returns:** JSON with work item details (fields, relations, etc.)

---

### `/ado-get-work-items`

Query work items using WIQL (Work Item Query Language).

```bash
/ado-get-work-items "MyProject"                          # All items in project
/ado-get-work-items "MyProject" "Task"                   # Filter by type
/ado-get-work-items "MyProject" "" "Active"              # Filter by state
/ado-get-work-items "MyProject" "Bug" "Active" "user@email.com"  # Assigned to user
```

**Parameters:**

- `project` (required) - Project name
- `workItemType` (optional) - Task, Bug, User Story, Feature, etc.
- `state` (optional) - Active, New, Closed, Resolved, etc.
- `assignedTo` (optional) - User email or display name

**Returns:** JSON with work items array.

---

### `/ado-create-work-item`

Create a new work item.

```bash
/ado-create-work-item "MyProject" "Task" "Fix login bug" "Description here"
/ado-create-work-item "MyProject" "Bug" "API error" "Full description" "High"
```

**Parameters:**

- `project` (required) - Project name
- `type` (required) - Work item type (Task, Bug, User Story, Feature)
- `title` (required) - Work item title
- `description` (optional) - Work item description
- `priority` (optional) - Priority (1-4)

**Returns:** JSON with created work item details.

---

### `/ado-update-work-item`

Update an existing work item.

```bash
/ado-update-work-item 12345 --state "Active"
/ado-update-work-item 12345 --title "New Title" --priority 2
/ado-update-work-item 12345 --assigned-to "user@email.com"
```

**Parameters:**

- `workItemId` (required) - Work item ID
- `--title` (optional) - New title
- `--state` (optional) - New state
- `--priority` (optional) - New priority
- `--assigned-to` (optional) - Assign to user
- `--description` (optional) - New description

**Returns:** JSON with updated work item.

---

### `/ado-create-comment`

Add a comment to a work item.

```bash
/ado-create-comment 12345 "Investigation complete. Ready for development."
```

**Parameters:**

- `workItemId` (required) - Work item ID
- `comment` (required) - Comment text

**Returns:** JSON with created comment details.

---

## Pull Request Commands

### `/ado-get-prs`

List pull requests in a repository.

```bash
/ado-get-prs "MyProject" "MyRepo"                    # All active PRs
/ado-get-prs "MyProject" "MyRepo" "completed"        # Completed PRs
/ado-get-prs "MyProject" "MyRepo" "" "user@email.com"  # Created by user
```

**Parameters:**

- `project` (required) - Project name
- `repository` (required) - Repository name
- `status` (optional) - active, completed, abandoned, all (default: active)
- `creatorId` (optional) - Filter by creator email

**Returns:** JSON with pull requests array.

---

### `/ado-get-pr`

Get details of a single pull request.

```bash
/ado-get-pr "MyProject" "MyRepo" 123
```

**Parameters:**

- `project` (required) - Project name
- `repository` (required) - Repository name
- `pullRequestId` (required) - PR ID

**Returns:** JSON with PR details (title, description, reviewers, status, etc.)

---

### `/ado-create-pr`

Create a new pull request.

```bash
/ado-create-pr "MyProject" "MyRepo" "feature/my-feature" "main" "Add new feature"
/ado-create-pr "MyProject" "MyRepo" "bugfix/fix" "develop" "Fix bug" "Detailed description"
```

**Parameters:**

- `project` (required) - Project name
- `repository` (required) - Repository name
- `sourceBranch` (required) - Source branch name
- `targetBranch` (required) - Target branch name
- `title` (required) - PR title
- `description` (optional) - PR description

**Returns:** JSON with created PR details.

---

### `/ado-update-pr`

Update an existing pull request.

```bash
/ado-update-pr "MyProject" "MyRepo" 123 --title "New Title"
/ado-update-pr "MyProject" "MyRepo" 123 --description "Updated description"
/ado-update-pr "MyProject" "MyRepo" 123 --target-branch "release/v2"
```

**Parameters:**

- `project` (required) - Project name
- `repository` (required) - Repository name
- `pullRequestId` (required) - PR ID
- `--title` (optional) - New title
- `--description` (optional) - New description
- `--target-branch` (optional) - New target branch

**Returns:** JSON with updated PR.

---

### `/ado-comment-pr`

Add a comment to a pull request.

```bash
/ado-comment-pr "MyProject" "MyRepo" 123 "LGTM! Great work."
```

**Parameters:**

- `project` (required) - Project name
- `repository` (required) - Repository name
- `pullRequestId` (required) - PR ID
- `comment` (required) - Comment text

**Returns:** JSON with created comment thread.

---

### `/ado-merge-pr`

Complete (merge) a pull request.

```bash
/ado-merge-pr "MyProject" "MyRepo" 123
/ado-merge-pr "MyProject" "MyRepo" 123 --delete-source
/ado-merge-pr "MyProject" "MyRepo" 123 --squash
```

**Parameters:**

- `project` (required) - Project name
- `repository` (required) - Repository name
- `pullRequestId` (required) - PR ID
- `--delete-source` (optional) - Delete source branch after merge
- `--squash` (optional) - Squash commits

**Returns:** JSON with completed PR details.

---

### `/ado-approve-pr`

Approve a pull request (set vote to Approved).

```bash
/ado-approve-pr "MyProject" "MyRepo" 123
/ado-approve-pr "MyProject" "MyRepo" 123 --with-suggestions
```

**Parameters:**

- `project` (required) - Project name
- `repository` (required) - Repository name
- `pullRequestId` (required) - PR ID
- `--with-suggestions` (optional) - Approve with suggestions (vote = 5 instead of 10)

**Returns:** JSON with updated reviewer status.

---

## Common Use Cases

### Work Item Workflow

```bash
# Get current work items assigned to me
/ado-get-work-items "MyProject" "" "Active" "my.email@company.com"

# Create a new task
/ado-create-work-item "MyProject" "Task" "Implement feature X" "Details..."

# Update progress
/ado-update-work-item 12345 --state "Active"

# Add investigation notes
/ado-create-comment 12345 "Found root cause. Starting implementation."

# Mark as complete
/ado-update-work-item 12345 --state "Closed"
```

### Pull Request Workflow

```bash
# Create PR for feature branch
/ado-create-pr "MyProject" "MyRepo" "feature/new-feature" "main" "Add new feature" "Implements feature X per ADO-12345"

# Check PR status
/ado-get-pr "MyProject" "MyRepo" 456

# Add review comment
/ado-comment-pr "MyProject" "MyRepo" 456 "Please add unit tests for the new method."

# Approve PR
/ado-approve-pr "MyProject" "MyRepo" 456

# Merge PR
/ado-merge-pr "MyProject" "MyRepo" 456 --delete-source
```

---

## Error Handling

All commands return consistent error JSON:

```json
{
  "error": true,
  "message": "Description of error",
  "statusCode": 404,
  "details": {}
}
```

**Common errors:**

- 401 Unauthorized: Invalid or expired PAT in `~/.azuredevops/credentials.json`
- 403 Forbidden: PAT lacks required permissions
- 404 Not Found: Project/repo/work item doesn't exist or no access
- 400 Bad Request: Invalid parameters (check API requirements)

---

## Notes

- **Work Item IDs:** Use numeric IDs only ("ADO-" prefix is auto-stripped)
- **Branch names:** Don't include `refs/heads/` prefix - it's added automatically
- **Dates:** Returned in ISO 8601 format
- **Pagination:** Most list commands automatically handle pagination
- **API Version:** All commands use API version 6.0

---

## API Reference

For detailed API documentation, see:

- [Azure DevOps REST API Reference](https://docs.microsoft.com/en-us/rest/api/azure/devops/)
- [Work Items API](https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/work-items)
- [Pull Requests API](https://docs.microsoft.com/en-us/rest/api/azure/devops/git/pull-requests)
