# Command Reorganization Implementation Plan

This document defines the implementation plan for reorganizing work-system commands into a namespaced directory structure with new delivery and dotnet automation commands.

## Background

### Current State

Commands are partially organized with some in directories and others as standalone files:

**Organized (in directories):**
- `git/` - 15 git commands
- `teamwork/` - 15 teamwork commands
- `azuredevops/` - 20 Azure DevOps commands (includes new PR thread commands)
- `github/` - 18 GitHub commands (includes new PR comment commands)
- `domain/` - 4 domain model query commands
- `delivery/` - 3 story delivery automation commands ✅ COMPLETED
- `dotnet/` - 3 .NET build/test/restore commands ✅ COMPLETED
- `playbook/` - 9 agent playbook management commands ✅ COMPLETED

**Unorganized (standalone files):**
- Workflow: deliver, design, plan, triage, queue, route, resume, select-task
- Quality: code-review, architecture-review, extract-review-patterns
- Recommendations: disable-recommendation, enable-recommendation, list-recommendations, recommendation-stats, view-recommendation
- Work system: work-init, work-status
- Documentation: doc-write

### Problem

1. **Lack of organization** - Standalone commands scattered in root directory
2. **Unclear categorization** - Hard to discover related commands
3. **Inconsistent naming** - Some namespaced (git:*), some not
4. **Poor scalability** - Adding new commands to root creates more clutter
5. **Missing organization** - New playbook and recommendation commands need categorization

### Goals

1. 🚧 **Organize all commands** into logical domain directories (partially complete)
2. ✅ **Created delivery and .NET commands** - delivery logging and .NET automation (DONE)
3. ✅ **Created playbook commands** - agent playbook management (DONE)
4. 🚧 **Namespace all commands** consistently (category:command)
5. 🚧 **Update all references** in agents, documents, and index
6. 🚧 **Improve discoverability** with category-level READMEs

## Proposed Structure

```
commands/
├── workflow/          # Work system stage commands
│   ├── README.md
│   ├── deliver.md
│   ├── design.md
│   ├── plan.md
│   ├── triage.md
│   ├── queue.md
│   ├── route.md
│   ├── resume.md
│   └── select-task.md
│
├── quality/           # Code review and quality assurance
│   ├── README.md
│   ├── code-review.md
│   ├── architecture-review.md
│   └── extract-review-patterns.md
│
├── recommendations/   # Architecture recommendation management (NEW)
│   ├── README.md
│   ├── disable-recommendation.md
│   ├── enable-recommendation.md
│   ├── list-recommendations.md
│   ├── recommendation-stats.md
│   └── view-recommendation.md
│
├── work/              # Work system management
│   ├── README.md
│   ├── work-init.md
│   └── work-status.md
│
├── docs/              # Documentation generation
│   ├── README.md
│   └── doc-write.md
│
├── delivery/          # Story delivery automation ✅ COMPLETED
│   ├── README.md
│   ├── log-start.md
│   ├── log-complete.md
│   └── log-update.md
│
├── dotnet/            # .NET build/test automation ✅ COMPLETED
│   ├── README.md
│   ├── test.md
│   ├── build.md
│   └── restore.md
│
├── playbook/          # Agent playbook management ✅ COMPLETED
│   ├── README.md
│   ├── check-playbook-conflicts.md
│   ├── export-patterns.md
│   ├── import-patterns.md
│   ├── pattern-evolve.md
│   ├── pattern-merge.md
│   ├── pattern-report.md
│   ├── playbook-stats.md
│   ├── track-pattern-detection.md
│   └── validate-playbook.md
│
├── git/               # Git operations (existing - 15 commands)
├── teamwork/          # Teamwork API commands (existing - 15 commands)
│
├── azuredevops/       # Azure DevOps commands (20 commands, 3 new)
│   ├── ... (existing 17 commands)
│   ├── ado-get-pr-threads.md      ✅ NEW
│   ├── ado-reply-pr-thread.md     ✅ NEW
│   └── ado-resolve-pr-thread.md   ✅ NEW
│
├── github/            # GitHub CLI helpers (18 commands, 5 new)
│   ├── ... (existing 13 commands)
│   ├── gh-comment-pr.md           ✅ NEW
│   ├── gh-get-pr-comments.md      ✅ NEW
│   ├── gh-reply-pr-comment.md     ✅ NEW
│   ├── gh-resolve-pr-comment.md   ✅ NEW
│   └── gh-review-pr.md            ✅ NEW
│
├── domain/            # Work item queries (existing - 4 commands)
│
├── README.md          # Updated with new structure
└── index.yaml         # Updated command registry
```

## Command Namespace Mapping

### Workflow Commands
| Old Command | New Command | Category | Status |
|-------------|-------------|----------|--------|
| `/workflow:select-task` | `/workflow:select-task` | workflow | To migrate |
| `/workflow:resume` | `/workflow:resume` | workflow | To migrate |
| `/workflow:deliver` | `/workflow:deliver` | workflow | To migrate |
| `/workflow:design` | `/workflow:design` | workflow | To migrate |
| `/workflow:plan` | `/workflow:plan` | workflow | To migrate |
| `/workflow:triage` | `/workflow:triage` | workflow | To migrate |
| `/workflow:queue` | `/workflow:queue` | workflow | To migrate |
| `/workflow:route` | `/workflow:route` | workflow | To migrate |

### Quality Commands
| Old Command | New Command | Category | Status |
|-------------|-------------|----------|--------|
| `/quality:code-review` | `/quality:code-review` | quality | To migrate |
| `/quality:architecture-review` | `/quality:architecture-review` | quality | To migrate |
| `/quality:extract-review-patterns` | `/quality:extract-review-patterns` | quality | To migrate |

### Recommendation Commands (NEW)
| Old Command | New Command | Category | Status |
|-------------|-------------|----------|--------|
| `/recommendations:disable` | `/recommendations:disable` | recommendations | To migrate |
| `/recommendations:enable` | `/recommendations:enable` | recommendations | To migrate |
| `/recommendations:list` | `/recommendations:list` | recommendations | To migrate |
| `/recommendations:stats` | `/recommendations:stats` | recommendations | To migrate |
| `/recommendations:view` | `/recommendations:view` | recommendations | To migrate |

### Work System Commands
| Old Command | New Command | Category | Status |
|-------------|-------------|----------|--------|
| `/work:init` | `/work:init` | work | To migrate |
| `/work:status` | `/work:status` | work | To migrate |

### Documentation Commands
| Old Command | New Command | Category | Status |
|-------------|-------------|----------|--------|
| `/docs:write` | `/docs:write` | docs | To migrate |

### Delivery Commands (NEW)
| Old Command | New Command | Category | Status |
|-------------|-------------|----------|--------|
| (new) | `/delivery:log-start` | delivery | ✅ Complete |
| (new) | `/delivery:log-complete` | delivery | ✅ Complete |
| (new) | `/delivery:log-update` | delivery | ✅ Complete |

### .NET Commands (NEW)
| Old Command | New Command | Category | Status |
|-------------|-------------|----------|--------|
| (new) | `/dotnet:test` | dotnet | ✅ Complete |
| (new) | `/dotnet:build` | dotnet | ✅ Complete |
| (new) | `/dotnet:restore` | dotnet | ✅ Complete |

### Playbook Commands (NEW)
| Old Command | New Command | Category | Status |
|-------------|-------------|----------|--------|
| (new) | `/playbook:validate` | playbook | ✅ Complete |
| (new) | `/playbook:check-conflicts` | playbook | ✅ Complete |
| (new) | `/playbook:stats` | playbook | ✅ Complete |
| (new) | `/playbook:track-detection` | playbook | ✅ Complete |
| (new) | `/playbook:export-patterns` | playbook | ✅ Complete |
| (new) | `/playbook:import-patterns` | playbook | ✅ Complete |
| (new) | `/playbook:pattern-evolve` | playbook | ✅ Complete |
| (new) | `/playbook:pattern-merge` | playbook | ✅ Complete |
| (new) | `/playbook:pattern-report` | playbook | ✅ Complete |

### Azure DevOps PR Thread Commands (NEW)
| Old Command | New Command | Category | Status |
|-------------|-------------|----------|--------|
| (new) | `/azuredevops:get-pr-threads` | azuredevops | ✅ Complete |
| (new) | `/azuredevops:reply-pr-thread` | azuredevops | ✅ Complete |
| (new) | `/azuredevops:resolve-pr-thread` | azuredevops | ✅ Complete |

### GitHub PR Commands (NEW)
| Old Command | New Command | Category | Status |
|-------------|-------------|----------|--------|
| (new) | `/github:comment-pr` | github | ✅ Complete |
| (new) | `/github:get-pr-comments` | github | ✅ Complete |
| (new) | `/github:reply-pr-comment` | github | ✅ Complete |
| (new) | `/github:resolve-pr-comment` | github | ✅ Complete |
| (new) | `/github:review-pr` | github | ✅ Complete |

## Implementation Steps

### Phase 1: Create New Directories and Commands

#### 1.1 Create Directory Structure

```bash
cd /home/cbryant/projects/work-system/commands
mkdir -p workflow quality work docs recommendations
# delivery/, dotnet/, playbook/ already exist ✅
```

**Deliverables:**
- ✅ delivery/ - COMPLETE (3 commands)
- ✅ dotnet/ - COMPLETE (3 commands)
- ✅ playbook/ - COMPLETE (9 commands)
- 🚧 workflow/ - TO CREATE
- 🚧 quality/ - TO CREATE
- 🚧 work/ - TO CREATE
- 🚧 docs/ - TO CREATE
- 🚧 recommendations/ - TO CREATE

#### 1.2 Create Delivery Commands ✅ COMPLETE

**File: `delivery/log-start.md`** ✅
- Logs story start to delivery-log.csv
- Records started_at timestamp
- Updates status to 'in_progress'
- Posts comment to Teamwork task

**File: `delivery/log-complete.md`** ✅
- Logs story completion to delivery-log.csv
- Records completed_at timestamp
- Calculates lead_time and cycle_time
- Updates status to 'completed'
- Posts completion comment with metrics to Teamwork

**File: `delivery/log-update.md`** ✅
- Updates arbitrary fields in delivery-log.csv
- Useful for corrections or adding notes

**Deliverables:**
- ✅ 3 delivery command files created
- ✅ delivery/README.md created
- ✅ Automation for delivery-log.csv tracking

#### 1.3 Create .NET Commands ✅ COMPLETE

**File: `dotnet/test.md`** ✅
- Wrapper for `dotnet test`
- Supports verbosity, filters, coverage options
- Contextual output with pass/fail summary

**File: `dotnet/build.md`** ✅
- Wrapper for `dotnet build`
- Supports configuration, verbosity options
- Reports build success/failure clearly

**File: `dotnet/restore.md`** ✅
- Wrapper for `dotnet restore`
- Reports package restoration status

**Deliverables:**
- ✅ 3 dotnet command files created
- ✅ dotnet/README.md created
- ✅ .NET workflow automation

#### 1.4 Create Playbook Commands ✅ COMPLETE

**File: `playbook/validate-playbook.md`** ✅
- Validates agent-playbook.yaml against schema
- Checks ID format, uniqueness, required fields
- Auto-fix mode available

**File: `playbook/check-playbook-conflicts.md`** ✅
- Detects contradictory rules
- Finds overlapping patterns
- Identifies layer boundary violations

**File: `playbook/playbook-stats.md`** ✅
- Analyzes rule usage patterns
- Shows effectiveness metrics
- Tracks confidence levels

**Plus 6 more playbook commands** ✅

**Deliverables:**
- ✅ 9 playbook command files created
- ✅ playbook/README.md created
- ✅ Playbook validation and management automation

#### 1.5 Create Recommendation Commands (TODO)

**File: `recommendations/recommendations:disable.md`**
- Disable architecture recommendation temporarily
- Track reason, author, timestamp for audit

**File: `recommendations/recommendations:enable.md`**
- Re-enable previously disabled recommendation
- Update tracking metadata

**File: `recommendations/recommendations:list.md`**
- List all architecture recommendations
- Filter by status, category, confidence

**File: `recommendations/recommendations:stats.md`**
- Show recommendation usage statistics
- Track effectiveness and false positives

**File: `recommendations/recommendations:view.md`**
- View detailed recommendation information
- Show examples, rationale, impact

**Deliverables:**
- 🚧 5 recommendation command files (TO CREATE)
- 🚧 recommendations/README.md (TO CREATE)

#### 1.6 Create Category READMEs

Each new directory needs a README.md:

**File: `workflow/README.md`** 🚧
- Overview of work system stages
- Command descriptions and usage
- Stage transition map

**File: `quality/README.md`** 🚧
- Code review philosophy
- Architecture review process
- Pattern extraction workflow

**File: `recommendations/README.md`** 🚧
- Architecture recommendation system
- Enable/disable workflows
- Statistics and tracking

**File: `work/README.md`** 🚧
- Work system initialization
- Status tracking
- Configuration guide

**File: `docs/README.md`** 🚧
- Documentation generation
- Template system
- Output formats

**File: `delivery/README.md`** ✅ COMPLETE
- Story delivery workflow
- Metrics tracking (lead time, cycle time)
- CSV log format

**File: `dotnet/README.md`** ✅ COMPLETE
- .NET automation commands
- Build/test/restore workflows
- Configuration options

**File: `playbook/README.md`** ✅ COMPLETE
- Playbook validation and management
- Pattern tracking and evolution
- Conflict detection

**Deliverables:**
- ✅ 3 category READMEs complete (delivery, dotnet, playbook)
- 🚧 5 category READMEs to create (workflow, quality, recommendations, work, docs)

### Phase 2: Move Existing Commands

#### 2.1 Move Workflow Commands

```bash
cd /home/cbryant/projects/work-system/commands
mv deliver.md workflow/
mv design.md workflow/
mv plan.md workflow/
mv triage.md workflow/
mv queue.md workflow/
mv route.md workflow/
mv resume.md workflow/
mv select-task.md workflow/
```

**Deliverables:**
- 8 workflow commands relocated

#### 2.2 Move Quality Commands

```bash
mv code-review.md quality/
mv architecture-review.md quality/
mv extract-review-patterns.md quality/
```

**Deliverables:**
- 3 quality commands relocated

#### 2.3 Move Work Commands

```bash
mv work-init.md work/
mv work-status.md work/
```

**Deliverables:**
- 2 work commands relocated

#### 2.4 Move Documentation Commands

```bash
mv doc-write.md docs/
```

**Deliverables:**
- 1 docs command relocated

### Phase 3: Update Command Metadata

#### 3.1 Update Command Files

Each moved command file needs its header updated to reflect new namespace:

**Old header example:**
```markdown
# /workflow:select-task - Select New Work

Select new work from tasks assigned to you...
```

**New header example:**
```markdown
# /workflow:select-task - Select New Work

Select new work from tasks assigned to you...
```

**Files to update:**
- workflow/workflow:deliver.md
- workflow/workflow:design.md
- workflow/workflow:plan.md
- workflow/workflow:triage.md
- workflow/workflow:queue.md
- workflow/workflow:route.md
- workflow/workflow:resume.md
- workflow/workflow:select-task.md
- quality/quality:code-review.md
- quality/quality:architecture-review.md
- quality/quality:extract-review-patterns.md
- work/work:init.md
- work/work:status.md
- docs/docs:write.md

**Deliverables:**
- 14 command files updated with new namespaces

### Phase 4: Update Documentation

#### 4.1 Update Main README

**File: `commands/README.md`**

Update command categories table:

```markdown
| Category | Description | Documentation |
|----------|-------------|---------------|
| **Workflow** | Work system stage commands | [workflow/README.md](workflow/README.md) |
| **Quality** | Code review and analysis | [quality/README.md](quality/README.md) |
| **Recommendations** | Architecture recommendation management | [recommendations/README.md](recommendations/README.md) |
| **Work** | Work system management | [work/README.md](work/README.md) |
| **Docs** | Documentation generation | [docs/README.md](docs/README.md) |
| **Delivery** | Story delivery automation | [delivery/README.md](delivery/README.md) |
| **.NET** | Build, test, restore automation | [dotnet/README.md](dotnet/README.md) |
| **Playbook** | Agent playbook management | [playbook/README.md](playbook/README.md) |
| **Git** | Git operations | [git/README.md](git/README.md) |
| **Teamwork** | Teamwork API commands | [teamwork/README.md](teamwork/README.md) |
| **Azure DevOps** | Azure DevOps commands (20 total, 3 new PR thread commands) | [azuredevops/README.md](azuredevops/README.md) |
| **GitHub** | GitHub CLI helpers (18 total, 5 new PR commands) | [github/README.md](github/README.md) |
| **Domain** | Work item queries | [domain/README.md](domain/README.md) |
```

Add sections for new command categories with usage examples.

**Deliverables:**
- 🚧 Updated main README.md with all categories including playbook and recommendations

#### 4.2 Update index.yaml

**File: `commands/index.yaml`**

Update stage command references:

```yaml
stages:
  - name: select
    description: Select work from queue
    commands:
      - /workflow:select-task
      - /workflow:resume

  - name: triage
    description: Categorize work item, assign template, route to queue
    commands:
      - /workflow:triage

  - name: plan
    description: Break down work items, set estimates, create children
    commands:
      - /workflow:plan

  - name: design
    description: Create solution options, make decisions, produce ADRs
    commands:
      - /workflow:design

  - name: deliver
    description: Implement solution, run tests, evaluate results
    commands:
      - /workflow:deliver
      - /quality:code-review
      - /quality:extract-review-patterns
      - /recommendations:disable
      - /recommendations:enable
      - /delivery:log-start
      - /delivery:log-complete
      - /delivery:log-update
      - /dotnet:test
      - /dotnet:build
      - /dotnet:restore
      - /playbook:validate
      - /playbook:check-conflicts
```

**Deliverables:**
- 🚧 Updated index.yaml with all new command paths including playbook, recommendations, delivery, dotnet

### Phase 5: Update References

#### 5.1 Find All Command References

```bash
cd /home/cbryant/projects/work-system
# Workflow commands (to be migrated)
grep -r "/workflow:deliver\b" --include="*.md" --include="*.yaml" .
grep -r "/workflow:design\b" --include="*.md" --include="*.yaml" .
grep -r "/workflow:plan\b" --include="*.md" --include="*.yaml" .
grep -r "/workflow:triage\b" --include="*.md" --include="*.yaml" .
grep -r "/workflow:queue\b" --include="*.md" --include="*.yaml" .
grep -r "/workflow:route\b" --include="*.md" --include="*.yaml" .
grep -r "/workflow:resume\b" --include="*.md" --include="*.yaml" .
grep -r "/workflow:select-task\b" --include="*.md" --include="*.yaml" .

# Quality commands (to be migrated)
grep -r "/quality:code-review\b" --include="*.md" --include="*.yaml" .
grep -r "/quality:architecture-review\b" --include="*.md" --include="*.yaml" .
grep -r "/quality:extract-review-patterns\b" --include="*.md" --include="*.yaml" .

# Recommendation commands (to be migrated)
grep -r "/recommendations:disable\b" --include="*.md" --include="*.yaml" .
grep -r "/recommendations:enable\b" --include="*.md" --include="*.yaml" .
grep -r "/recommendations:list\b" --include="*.md" --include="*.yaml" .
grep -r "/recommendations:stats\b" --include="*.md" --include="*.yaml" .
grep -r "/recommendations:view\b" --include="*.md" --include="*.yaml" .

# Work system commands (to be migrated)
grep -r "/work:init\b" --include="*.md" --include="*.yaml" .
grep -r "/work:status\b" --include="*.md" --include="*.yaml" .

# Documentation commands (to be migrated)
grep -r "/docs:write\b" --include="*.md" --include="*.yaml" .
```

**Expected files to update:**
- `~/.claude/agents/*.md` - Agent definition files
- `docs/**/*.md` - Documentation files
- `templates/**/*.md` - Template files
- Any workflow or guide documents

#### 5.2 Update Agent Files

Agent files in `~/.claude/agents/` that reference commands:
- task-fetcher.md
- task-selector.md
- work-item-mapper.md
- triage-agent.md (if exists)
- plan-agent.md (if exists)
- design-agent.md (if exists)
- dev-agent.md (if exists)
- qa-agent.md (if exists)
- eval-agent.md (if exists)

Update command references to use new namespaces.

**Deliverables:**
- All agent files updated with new command names

#### 5.3 Update Documentation Files

Files in `docs/` that reference commands:
- workflow/*.md
- guides/*.md
- specifications/*.md

Update all command references.

**Deliverables:**
- All documentation updated

#### 5.4 Update Template Files

Files in `~/.claude/templates/` that reference commands.

**Deliverables:**
- All templates updated

### Phase 6: Update External References

#### 6.1 Update Atlas delivery-workflow.md

**File: `/home/cbryant/projects/link/atlas/dev-support/tasks/delivery-workflow.md`**

Update Slash Commands Reference section to use new namespaces:
- `/delivery:log-start`
- `/delivery:log-complete`
- `/dotnet:test`
- `/dotnet:build`

**Deliverables:**
- Atlas workflow updated with new commands

### Phase 7: Testing and Validation

#### 7.1 Test New Commands

**Test delivery commands:**
```bash
/delivery:log-start 1.1.1 "Story Title" feature/1.1.1-story-slug
/delivery:log-complete 1.1.1 https://pr-url 4 "Story notes"
/delivery:log-update 1.1.1 --field notes --value "Updated notes"
```

**Test dotnet commands:**
```bash
cd SubscriptionsMicroservice
/dotnet:test
/dotnet:build
/dotnet:restore
```

**Deliverables:**
- All new commands tested and working

#### 7.2 Test Renamed Commands

**Test workflow commands:**
```bash
/workflow:select-task
/workflow:resume
/workflow:deliver
```

**Test quality commands:**
```bash
/quality:code-review
```

**Test work commands:**
```bash
/work:work-status
```

**Deliverables:**
- All renamed commands working with new namespaces

#### 7.3 Verify No Broken References

Run comprehensive search to ensure no old command references remain:

```bash
cd /home/cbryant/projects/work-system
grep -r " /workflow:deliver\b" --include="*.md" . | grep -v "^commands/"
grep -r " /workflow:select-task\b" --include="*.md" . | grep -v "^commands/"
# ... repeat for all commands
```

Should return zero results (except in changelog/historical sections).

**Deliverables:**
- No broken references found

## Rollout Plan

### Stage 1: Internal Testing (Week 1)
- Implement all changes
- Test all new and renamed commands
- Verify references updated
- Document any issues

### Stage 2: Documentation (Week 1)
- Ensure all READMEs are complete
- Add usage examples
- Create migration guide for users

### Stage 3: Deployment (Week 1)
- Commit all changes
- Create announcement/changelog
- No user action required (backward compatibility maintained during transition)

## Success Criteria

### Completed ✅
- ✅ delivery/ directory created with 3 commands and README
- ✅ dotnet/ directory created with 3 commands and README
- ✅ playbook/ directory created with 9 commands and README
- ✅ Azure DevOps PR thread commands added (3 new commands)
- ✅ GitHub PR comment commands added (5 new commands)

### In Progress 🚧
- 🚧 Create recommendations/ directory with 5 commands
- 🚧 Create workflow/ directory and move 8 commands
- 🚧 Create quality/ directory and move 3 commands
- 🚧 Create work/ directory and move 2 commands
- 🚧 Create docs/ directory and move 1 command
- 🚧 Update all command files with new namespaces
- 🚧 Update all references in agents, docs, templates
- 🚧 Update main README.md with all new categories
- 🚧 Update index.yaml with all new command paths
- 🚧 Create remaining category READMEs (5 needed)

### Not Started ❌
- ❌ Verify no broken command references
- ❌ Test all renamed commands
- ❌ Update external references (Atlas, etc.)

## Risks and Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Broken command references | High | Comprehensive grep search before/after |
| User confusion with new names | Medium | Create migration guide, maintain old names temporarily |
| Commands don't work after move | High | Thorough testing of all commands |
| Missing references in external repos | Medium | Search Atlas and other repos for references |
| Git history lost for moved files | Low | Use `git mv` if tracking needed |

## Future Enhancements

1. **Command Aliases** - Support both old and new names during transition
2. **Command Discovery** - Interactive `/commands` to browse categories
3. **Auto-completion** - Shell completion for command namespaces
4. **Metrics Dashboard** - `/delivery:metrics` to view all story metrics
5. **Parallel Testing** - `/dotnet:test --parallel` for faster feedback

## Appendix

### A. New Command Specifications

#### /delivery:log-start

**Purpose:** Log story start to delivery-log.csv and post Teamwork comment

**Parameters:**
- `story_id` (required) - Story ID (e.g., "1.1.1")
- `title` (required) - Story title
- `branch` (required) - Git branch name
- `csv_file` (optional) - Path to delivery-log.csv (default: dev-support/tasks/*/delivery-log.csv)
- `teamwork_task_id` (optional) - Teamwork task ID for comment posting

**Behavior:**
1. Generate started_at timestamp (ISO 8601 UTC)
2. Update CSV row: status=in_progress, started_at={timestamp}
3. Post Teamwork comment with story start details
4. Display confirmation message

**Output:**
```
✅ Story 1.1.1 logged as started
   CSV: dev-support/tasks/tw-26253606/delivery-log.csv
   Started: 2025-12-11T15:30:00Z
   Teamwork: Comment posted to task 26253606
```

#### /delivery:log-complete

**Purpose:** Log story completion, calculate metrics, post Teamwork comment

**Parameters:**
- `story_id` (required) - Story ID
- `pr_url` (required) - Pull request URL
- `tests_added` (required) - Number of tests added
- `notes` (optional) - Completion notes
- `csv_file` (optional) - Path to delivery-log.csv
- `teamwork_task_id` (optional) - Teamwork task ID

**Behavior:**
1. Read current CSV row to get created_at and started_at
2. Generate completed_at timestamp
3. Calculate lead_time_hours = (completed_at - created_at) / 3600
4. Calculate cycle_time_hours = (completed_at - started_at) / 3600
5. Update CSV row with all completion data
6. Post Teamwork comment with metrics
7. Display summary

**Output:**
```
✅ Story 1.1.1 logged as completed
   CSV: dev-support/tasks/tw-26253606/delivery-log.csv
   Completed: 2025-12-11T18:30:00Z
   Lead Time: 6.0 hours
   Cycle Time: 3.0 hours
   PR: https://azuredevops.../pullrequest/1045
   Tests Added: 4
   Teamwork: Comment posted with metrics
```

#### /delivery:log-update

**Purpose:** Update specific field in delivery-log.csv

**Parameters:**
- `story_id` (required) - Story ID
- `field` (required) - Field name (notes, pr_url, tests_added, etc.)
- `value` (required) - New value
- `csv_file` (optional) - Path to delivery-log.csv

**Behavior:**
1. Find story row in CSV
2. Update specified field
3. Preserve all other fields
4. Display confirmation

**Output:**
```
✅ Story 1.1.1 updated
   Field: notes
   Value: "Added retry logic with exponential backoff"
```

#### /dotnet:test

**Purpose:** Run .NET tests with contextual output

**Parameters:**
- `project` (optional) - Specific test project path
- `filter` (optional) - Test filter (e.g., "FullyQualifiedName~SubscriptionTests")
- `verbosity` (optional) - Verbosity level (quiet, minimal, normal, detailed)
- `coverage` (optional) - Collect code coverage (boolean)
- `configuration` (optional) - Build configuration (Debug, Release)

**Behavior:**
1. Execute `dotnet test` with specified options
2. Parse output for pass/fail counts
3. Display summary with color coding
4. Return exit code (0 = success, 1 = failure)

**Output:**
```
Running .NET tests...
Configuration: Release
Coverage: Enabled

✅ Tests Passed: 47
❌ Tests Failed: 0
⏭️  Tests Skipped: 2
⏱️  Duration: 4.3s

Code Coverage: 85.2%
```

#### /dotnet:build

**Purpose:** Build .NET solution/project with clear output

**Parameters:**
- `project` (optional) - Specific project/solution path
- `configuration` (optional) - Configuration (Debug, Release)
- `verbosity` (optional) - Verbosity level
- `no-restore` (optional) - Skip restore (boolean)

**Behavior:**
1. Execute `dotnet build` with options
2. Parse output for errors/warnings
3. Display summary
4. Return exit code

**Output:**
```
Building .NET solution...
Configuration: Release

✅ Build Succeeded
   Warnings: 0
   Errors: 0
   Duration: 8.2s
```

#### /dotnet:restore

**Purpose:** Restore NuGet packages

**Parameters:**
- `project` (optional) - Specific project path
- `verbosity` (optional) - Verbosity level

**Behavior:**
1. Execute `dotnet restore`
2. Display package restoration progress
3. Report success/failure

**Output:**
```
Restoring NuGet packages...

✅ Restore Succeeded
   Packages: 147 restored
   Duration: 3.1s
```

### B. CSV Format Reference

**File: `delivery-log.csv`**

```csv
story_id,title,status,branch,created_at,started_at,completed_at,lead_time_hours,cycle_time_hours,pr_url,tests_added,notes
1.1.1,Fetch from Stax Bill,completed,feature/1.1.1-fetch-from-staxbill,2025-12-08T12:00:00Z,2025-12-08T12:00:00Z,2025-12-09T18:00:00Z,30,6,https://...,5,Merged after PR review
1.1.2,Update Local Database,in_progress,feature/1.1.2-update-local-database,2025-12-09T23:00:00Z,2025-12-09T23:00:00Z,,,,,,
1.1.3,Apply Grace Period Logic,pending,feature/1.1.3-grace-period-logic,,,,,,,,
```

**Field Definitions:**
- `story_id` - Unique story identifier (e.g., "1.1.1")
- `title` - Story title
- `status` - pending | in_progress | completed
- `branch` - Git branch name
- `created_at` - ISO 8601 timestamp when story was created
- `started_at` - ISO 8601 timestamp when implementation started
- `completed_at` - ISO 8601 timestamp when story was completed
- `lead_time_hours` - Total time from creation to completion
- `cycle_time_hours` - Active work time (started to completed)
- `pr_url` - Pull request URL
- `tests_added` - Number of tests added for the story
- `notes` - Optional notes about the story

## Timeline

| Week | Tasks | Deliverables |
|------|-------|--------------|
| 1 | Phase 1: Create directories and new commands | 6 directories, 6 new commands, 6 READMEs |
| 1 | Phase 2: Move existing commands | 14 commands relocated |
| 1 | Phase 3: Update command metadata | 14 files updated with namespaces |
| 1 | Phase 4: Update documentation | README.md, index.yaml updated |
| 1 | Phase 5: Update references | All agents, docs, templates updated |
| 1 | Phase 6: Update external references | Atlas workflow updated |
| 1 | Phase 7: Testing and validation | All tests passing, no broken refs |

**Total Duration:** 1 week

## Sign-off

- [ ] Plan reviewed and approved
- [ ] Resources allocated
- [ ] Timeline confirmed
- [ ] Success criteria agreed
- [ ] Risk mitigation accepted
- [ ] Ready to begin implementation
