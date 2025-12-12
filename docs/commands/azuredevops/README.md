# Azure DevOps Commands

Azure DevOps Server API commands for work items and pull requests.

## Configuration

- `~/.azuredevops/credentials.json` - PAT and server profiles
- `.claude/work-manager.yaml` - Per-repo project settings

## Commands

### Work Items

| Command | Description |
|---------|-------------|
| `/azuredevops:ado-get-projects` | List projects in collection |
| `/azuredevops:ado-get-project` | Get project details |
| `/azuredevops:ado-get-work-item` | Get work item by ID |
| `/azuredevops:ado-get-work-items` | Query work items (WIQL) |
| `/azuredevops:ado-create-work-item` | Create new work item |
| `/azuredevops:ado-update-work-item` | Update work item |
| `/azuredevops:ado-create-comment` | Add comment to work item |

### Pull Requests

| Command | Description |
|---------|-------------|
| `/azuredevops:ado-get-prs` | List pull requests |
| `/azuredevops:ado-get-pr` | Get PR details |
| `/azuredevops:ado-get-pr-threads` | List PR comment threads |
| `/azuredevops:ado-create-pr` | Create pull request |
| `/azuredevops:ado-update-pr` | Update PR properties |
| `/azuredevops:ado-comment-pr` | Add comment to PR |
| `/azuredevops:ado-reply-pr-thread` | Reply to comment thread |
| `/azuredevops:ado-resolve-pr-thread` | Resolve/close thread |
| `/azuredevops:ado-approve-pr` | Approve PR |
| `/azuredevops:ado-merge-pr` | Merge PR |

## Quick Examples

```bash
# Work items
/azuredevops:ado-get-work-item 12345
/azuredevops:ado-update-work-item 12345 --state "Active"

# Pull requests
/azuredevops:ado-create-pr "Project" "Repo" "feature/x" "main" "Title"
/azuredevops:ado-get-pr-threads "Project" "Repo" 123
/azuredevops:ado-merge-pr "Project" "Repo" 123 --delete-source
```

See source commands in [commands/azuredevops/](../../../commands/azuredevops/) for full documentation.
