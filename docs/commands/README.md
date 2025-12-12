# Command Reference

Quick reference for all available slash commands in the work system.

## Namespaces

| Namespace | Purpose |
|-----------|---------|
| [workflow](workflow/) | Stage orchestration (select, triage, plan, design, deliver) |
| [git](git/) | Platform-agnostic git operations |
| [teamwork](teamwork/) | Teamwork API helpers |
| [github](github/) | GitHub CLI operations |
| [azuredevops](azuredevops/) | Azure DevOps API operations |
| [quality](quality/) | Code review and architecture analysis |
| [playbook](playbook/) | Agent playbook management |
| [domain](domain/) | Work item aggregates |
| [dotnet](dotnet/) | .NET build/test automation |
| [delivery](delivery/) | Story metrics logging |
| [recommendations](recommendations/) | Architecture recommendation management |
| [work](work/) | System initialization |
| [docs](docs/) | Documentation generation |

## Quick Start

```bash
# Initialize work system in a repo
/work:init

# Start new work
/workflow:select-task
/workflow:triage
/workflow:plan
/workflow:design
/workflow:deliver

# Git workflow
/git:git-status
/git:git-commit "feat: add feature"
/git:git-push

# Code quality
/quality:code-review
```

See [quick-reference.md](../reference/quick-reference.md) for a full command cheat sheet.
