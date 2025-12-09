# AgenticOps Value Train™ an AI-Driven Value Delivery System

![A train with smoke coming out of it AI-generated content may be incorrect.](media/de2e2bfd3b17fddfb6ded16928486d82.png)

**All Aboard the Value Train!**

This document defines the goals, framework, concepts, risks, and roadmap for the AgenticOps Value Train™, delivering AI driven projects for world class teams.

# Goals

We want teams to:

-   Stay in process – everyone aligned to a shared, visible workflow.
-   Improve flow – reduce WIP, avoid bottlenecks, increase throughput.
-   Deliver value at high standards – across *usability*, *quality*, *security*, *maintainability*, *scalability*, and *viability*.
-   Enable effective and safe interaction with AI agents – to help each team member *execute, deliver, and communicate* with consistency and excellence.

The AgenticOps Value Train provides the framework to move towards these goals.

# Framework

## Pipeline Design

The framework enables value stream pipeline design with phases, checklists, artifacts, and agents per stream phase. This is our core domain.

## Role-Aware Assistants

The framework provides AI Assistants for Product Managers, Designers, Developers, Quality Analysts, Engineers, and Operations Managers. Each assistant knows its roles and responsibilities aligned with its operator. Assistants delivers artifacts efficiently and of the highest standard. Assistants talks in context and in the language of the operations team. Assistants are our core user interface.

## Flow-Aware System

The system tracks flow time (cycle time, lead time), throughput, WIP, flow balance, cumulative flow and enables the visualization of work in WarRoom dashboards. This is our flow control and continuous improvement system.

## Automation & Evaluation

The framework integrates with WarRoom, CDMS, FlowForge, Nucleus, GitHub, n8n, and Claude SDK all rolling together to plan, design, build, deploy, evaluate, and improve agentic workflows. This is our bolt on interchangeable engine.

## Standards & Guardrails

The framework enables the establishment operator team based standard conventions for commit rules, validation scripts, required artifacts, phase transitions, and CI gates. This is how we keep AI on the rails and human’s on board.

## Integrations

### WarRoom

Provides real-time visibility into value delivery, flow metrics, and strategic alignment across projects, teams, and clients.

### CMDS (Context Management Development System)

Manages scoped memory, context injection, and mode switching to ensure agents act with precision and relevance.

### FlowForge

Orchestrates structured, multi-agent workflows using reusable templates and live evaluation to automate delivery pipelines.

### Nucleus

Evaluates agent outputs using LLMs, rules, or human feedback, scoring effectiveness and surfacing improvement recommendations.

### n8n

Runs event-driven automation workflows, connecting tools, services, and agents through a flexible visual interface.

### GitHub API

Enables agents to create, update, and manage code, issues, branches, pull requests, and CI/CD pipelines in a controlled, versioned environment.

### Claude SDK

Powers intelligent agent behaviors and structured reasoning through Anthropic’s Claude models, optimized for collaborative development tasks.

### OpenAI API

Supports natural language understanding, content generation, and decision support through GPT-based large language models.

# Concepts

## Pipelines

### Pre-Engagement

#### Phase

| Phase                 | Agent     | Description                                       | Goal                                                       | Outcome                                        | Artifacts               |
|-----------------------|-----------|---------------------------------------------------|------------------------------------------------------------|------------------------------------------------|-------------------------|
| Opportunity Triage    | Onboarder | Qualify and assess AI opportunity                 | Determine fit for AI and strategic value                   | Internal Go/No-Go + Rough Opportunity Doc      | Opportunity Brief       |
| Discovery & Framing   | Onboarder | Elicit context, define use case, align objectives | Understand user need, business case, technical feasibility | Use Case Brief + Problem Statement             | Use Case One-Pager      |
| Client Readiness      | Onboarder | Assess data, systems, team, and constraints       | De-risk delivery and surface blockers early                | AI Readiness Score + Risk Profile              | Readiness Questionnaire |
| Scope & Pitch         | Onboarder | Define MVP scope, pricing, and delivery plan      | Land the right-sized engagement with clear value           | MVP Plan + Pricing + SOW + Pitch Deck          | SOW, Pitch Deck         |
| Pre-Kickoff Logistics | Onboarder | Confirm legal, technical, and team alignment      | Eliminate blockers before Day 1                            | Signed SOW + DPA + Access Checklist + Contacts | Access Checklist, DPA   |

#### Checklist

| Step                            | Agent     | Asset                                 |
|---------------------------------|-----------|---------------------------------------|
| Log opportunity in CRM / Notion | Conductor | CRM Tool                              |
| Fill in Opportunity Brief       | Onboarder | Notion / Docs / Template              |
| Schedule discovery workshop     | Onboarder | Calendar + MCP Scheduler              |
| Send AI Readiness Form          | Onboarder | Docs / Forms / Email                  |
| Request sample data             | Onboarder | Secure Share (S3 / Azure / GDrive)    |
| Run Data Profiler               | Lab       | Python / C\# Notebook                 |
| Draft SOW and Budget            | Onboarder | Docs + Budget Calculator              |
| Build pitch deck                | Onboarder | Slides / Pitch.com / Canva            |
| Send DPA and checklist          | Onboarder | Docs / HelloSign / Email              |
| Finalize contacts               | Onboarder | Shared Sheet / CRM / Contract Tracker |

#### Artifacts

| Type      | Title                          | File Path                                         | Purpose                                                     |
|-----------|--------------------------------|---------------------------------------------------|-------------------------------------------------------------|
| Framing   | Opportunity Brief              | /preengagement/framing/opportunity-brief.md       | Summarize problem, urgency, and AI fit                      |
| Framing   | Use Case One-Pager             | /preengagement/framing/use-case-one-pager.md      | Confirm understanding and alignment                         |
| Discovery | AI Readiness Questionnaire     | /preengagement/discovery/ai-readiness.md          | Surface capability gaps and risks                           |
| Discovery | Data Profile Template          | /preengagement/discovery/data-profiler.ipynb      | Summarize data coverage, nulls, types, quality              |
| Legal     | DPA Template                   | /preengagement/legal/dpa-template.docx            | Enable data sharing safely                                  |
| Planning  | SOW Template                   | /preengagement/planning/sow-template.md           | Define scope, timeline, pricing, and success metrics        |
| Planning  | Access Checklist               | /preengagement/planning/credentials-checklist.md  | Ensure no technical blockers at start                       |
| Planning  | Project Contact Sheet          | /preengagement/planning/contact-sheet.md          | List client and vendor team leads and SMEs                  |
| Planning  | Glossary of Terms              | /preengagement/planning/glossary.md               | Ensure common vocabulary across business and tech           |
| Pitch     | Pitch Deck                     | /preengagement/pitch/pitch-deck-template.pptx     | Win buy-in with value story and delivery plan               |
| Planning  | Reference Architecture Diagram | /preengagement/planning/architecture-diagram.pptx | Visualize how the AI system integrates into the environment |
| Comm      | Client Alignment Email         | /preengagement/communication/client-email.txt     | Confirm plan, docs, and roles before kickoff                |
| Comm      | Internal Kickoff Email         | /preengagement/communication/internal-email.txt   | Clarify scope and agent assignments internally              |

### Delivery

#### Phase

| Phase                | Agent(s)             | Description                                                  | Goal                                    | Outcome                        | Artifacts                     |
|----------------------|----------------------|--------------------------------------------------------------|-----------------------------------------|--------------------------------|-------------------------------|
| Data Sources         | Onboarder + Lab      | Identify data assets and export strategies                   | Create clean extractable dataset        | Source schema and access       | Source map, data access plan  |
| Extraction           | Lab                  | Pull, clean, standardize raw input into structured form      | Consistent structure across sources     | Extracted and normalized files | Extraction script, log        |
| Preparation          | Lab + Studio         | Handle missing values, partition sets, validate input schema | Create model-ready training dataset     | Clean, split data artifacts    | Prepared dataset, schema spec |
| Exploration          | Lab                  | Profile features, classes, distribution, anomalies           | Identify promising variables and gaps   | Data profile report            | Profile notebook              |
| Feature Engineering  | Lab + Studio         | Generate derived features from SIGs, quantities, etc.        | Model-input features                    | Feature map and derivation     | Feature config, map           |
| Model Architecture   | Studio               | Choose modeling approach, design interfaces                  | AI system plan                          | Model flow design              | Model flow diagram            |
| Training             | Lab                  | Train models, log experiments, tune hyperparameters          | Model with target metric                | Training notebook and logs     | Training notebook, MLflow     |
| Validation           | Evaluator            | Evaluate model performance against business-aligned metrics  | Ensure quality and success acceptance   | Evaluation metrics and summary | Evaluation report             |
| Deployment           | Studio + Ops         | Deploy model as batch/API, tag infra, configure rollback     | Functional, secure, and scalable system | Live model endpoint            | Deployment config             |
| Monitoring           | Evaluator + Ops      | Track performance, usage, cost, drift                        | Detect issues early                     | Live metrics and drift logs    | Monitoring dashboard          |
| Evaluation           | Evaluator            | Compare to baselines, SME feedback, business value           | Show ROI and user alignment             | Stakeholder validation         | Champion challenger log       |
| Performance Analysis | Evaluator + Improver | Analyze failure patterns, edge cases, mispredictions         | Prioritize improvements                 | Root cause notes               | Error log, review doc         |
| Improvement          | Improver             | Refine features, annotations, interfaces                     | Higher accuracy and less friction       | Recommendations and roadmap    | Improvement roadmap           |
| Retraining Loop      | Improver + Lab       | Trigger retraining, run new versions, log improvements       | Sustainable model performance           | Updated model and baseline     | Retraining notebook           |

#### Checklist

| Step                        | Agent(s)             | Asset                                 |
|-----------------------------|----------------------|---------------------------------------|
| Define source systems       | Onboarder + Lab      | Business framing, Source Map          |
| Pull and clean data         | Lab                  | Extraction tool, data profiler        |
| Split and validate dataset  | Lab + Studio         | C\# / Python notebook, schema checker |
| Run profiling notebook      | Lab                  | Data profiler notebook                |
| Engineer features           | Lab + Studio         | Feature map, SIG logic                |
| Define model architecture   | Studio               | Architecture design, DAG flow tool    |
| Train model and log run     | Lab                  | MLflow, training notebook             |
| Evaluate results            | Evaluator            | Evaluation metrics, benchmark report  |
| Package and deploy model    | Studio + Ops         | CI/CD, TorchScript, AWS deployment    |
| Set up monitoring alerts    | Ops + Evaluator      | CloudWatch, Eval-Perf-Watcher         |
| Review stakeholder feedback | Evaluator            | Business framing, results summary     |
| Analyze edge cases          | Evaluator + Improver | Root cause analysis                   |
| Recommend improvements      | Improver             | Post-mortem, improvement roadmap      |
| Retrain updated model       | Improver + Lab       | Retraining plan, baseline comparison  |

#### Artifacts

| Type     | Title                   | File Path                             | Purpose                                  |
|----------|-------------------------|---------------------------------------|------------------------------------------|
| Data     | Source Map              | /delivery/data/source-map.md          | Document systems and fields              |
| Data     | Extraction Script       | /delivery/data/extract.py             | Reproducible ETL process                 |
| Data     | Prepared Dataset        | /delivery/data/prepared.csv           | Cleaned data used for training           |
| Analysis | Profile Report          | /delivery/exploration/profile.ipynb   | Data profile results and visualizations  |
| Features | Feature Map             | /delivery/features/feature-map.md     | Inputs used in model pipeline            |
| Model    | Model Flow Diagram      | /delivery/model/architecture.pptx     | Illustrate pipeline architecture         |
| Model    | Training Notebook       | /delivery/model/train.ipynb           | Tracks model development                 |
| Model    | Evaluation Report       | /delivery/validation/eval-results.pdf | Summarizes model performance and metrics |
| Deploy   | Deployment Config       | /delivery/deploy/deploy.yaml          | Infra as code definition                 |
| Monitor  | Monitoring Dashboard    | /delivery/monitor/dashboard-link.txt  | Live performance visualizations          |
| Review   | Champion Challenger Log | /delivery/evaluation/champion-log.md  | Track comparison of model versions       |
| Ops      | Error Log               | /delivery/performance/error-log.json  | Document failures for analysis           |
| Roadmap  | Improvement Roadmap     | /delivery/improvement/roadmap.md      | Guide to next improvements               |
| Retrain  | Retraining Notebook     | /delivery/retrain/retrain.ipynb       | Tracks next round of model tuning        |

## Auto-Pilot

The Autopilot Agent autonomously operates and manages how phase tickets are stored, validated, and advanced so that:

-   Human operators can manually mark actions complete without merge conflicts.
-   The Autopilot Agent can autonomously run a queue of GitHub Issues end‑to‑end.
-   Conductor agent, pre-commit hook, and CI/CD are the gatekeeper for quality and progress.

### Getting Started

To run the pipeline locally:

1.  Clone the repository and install dependencies.
2.  Run:

```bash
make venv
source venv/bin/activate
```

1.  Ensure your Issues are labeled `Task` and `auto` and are unassigned.
2.  Start Auto-Pilot with:

```bash
/drive
```

Use `/plan` to queue up more tasks when needed.

### End‑to‑End Steps

| \# | Step             | Initiator                | Key Artifacts / Scripts                                                                 | Expected Outcome                                                                 |
|----|------------------|--------------------------|-----------------------------------------------------------------------------------------|----------------------------------------------------------------------------------|
| 0  | Kickoff          | Operator                 | —                                                                                       | Repo scaffolded via `/kick`; Issues triaged & labelled via /plan                 |
| 1  | Issue Select     | Auto-Pilot               | `select_next_issue.py`                                                                  | Issue chosen and self‑assigned                                                   |
| 2  | Branch & Folder  | Auto-Pilot               | —                                                                                       | Ticket branch and folder created                                                 |
| 3  | Session Seed     | Auto-Pilot               | `checklist.md, ACTIVE_SESSION.md`                                                       | Ticket initialized                                                               |
| 4  | Execute Tasks    | Lab / Studio / Evaluator | Multiple phase‑specific helpers (e.g. `data_pull.py`, `train_model.py`, `run_tests.sh`) |                                                                                  |
| 5  | CI Gate          | CI                       | `check_todo.py` • `check_artifacts.py`                                                  | Required bullets all checks and artifacts exist; pipeline green                  |
| 6  | Merge & Finalize | Conductor                | `conductor_update.py`                                                                   | PR merged; `ACTIVE_SESSION.md.status` → `done`; next phase Issue prepared        |
| 7  | Loop / Finish    | Auto-Pilot               | —                                                                                       | Return to Step 1 until no qualifying Issues remain; bot posts completion comment |

>   Note: All Python helpers are executed in the project’s virtual environment (`venv/bin/activate`) to ensure dependency isolation.

### Detailed Breakdown

#### Trigger

-   An operator or a cron‑triggered automated workflow can run Auto-Pilot by running the /drive command
-   If no active phase issue exists, Auto-Pilot picks the oldest `auto` issue.
-   Because each phase issue has its own folder and branch, Auto-Pilot can safely run in parallel or sequentially finishing one ticket, waiting for merge, then starting the next ticket, all with no merge conflicts or path collisions.

#### Issue Selection (Step 1)

-   Task queue is determined by
    -   Priority order: `now` → `next` → `future`.
    -   Filters: labels `Task` & `auto`; no assignee; state `open`.
    -   Deterministic: oldest `created_at` wins in a priority and filter tie.
-   Implemented by /scripts/select_next_issue.py (venv). The script returns the Issue ID or an empty string. If empty string is returned, the train is halted and Auto-Pilot stopped and the operator is given an alert message to run /plan mode to fill the task queue.

#### Branch & Folder Creation (Step 2)

-   Branch pattern `phase/<phase>_<id>.`
-   Create branch and checkout branch.
-   Branch pattern is enforced by a prepare‑commit‑msg hook and push is rejected if the pattern fails.
-   Folder pattern `tickets/<phase>_<id>/` created on the new branch.
-   Inside each phase-ticket folder:

```text
tickets/<phase>_<id>/
  artifacts/          # outputs produced by the ticket’s steps
  ACTIVE_SESSION.md   # markdown file with session state
  checklist.md        # markdown list – required bullets marked *
  ticket.yml         # ticket meta data
```

-   A ticket.yml file holds meta data for the ticket.

```yaml
ticket: train_142
issue_id: 142
title: "Train model with HPO"
description: "Use curated dataset to optimize model accuracy."

operator: cbryant
team: ML-Pipeline
project: Koala-Refill-Adherence
client: Koala Health
prd_issue: 95
crd_issue: 103

phase: train
stage: HPO
mode: /drive
status: InProgress

checklist:
  - name: select_dataset
  - name: prepare_model_config
  - name: run_hpo_job
  - name: evaluate_accuracy
  - name: update_docs
    required: false

artifacts:
  - path: /models/model_v3.zip
  - path: /src/train_142/model_config.json
  - path: /docs/train_142_eval_report.md
    required: false

entry_criteria:
  - curated dataset is available
  - PRD approved

exit_criteria:
  - accuracy >= 90%
  - PR merged

next_phase: validate

started_at: 2025-07-19T09:42:00Z
completed_at: null
duration_estimate: "6h"
revenue_value: 1250.00
effort_hours: null

evaluation:
  checklist:
    status: false
    eval: checklist-complete.md
    notes: "evaluate_accuracy not marked complete"

  artifacts:
    status: false
    eval: artifact-check.md
    notes: "Missing model_config.json"

  entry_criteria:
    status: true
    eval: entry-check.md
    required: false

  exit_criteria:
    status: false
    eval: exit-check.py

  issue_closed:
    status: false
    eval: issue-status-check.py

  labels_valid:
    status: true
    eval: label-validation.json

  ready_for_next_phase:
    status: false
    eval: transition.yml
```

#### Session Initiation (Step 3)

/begin

#### Task Execution & Checklist Ticking (Step 4)

-   Each unchecked bullet maps to a concrete action.
-   If an action fails (e.g., script error, missing dependency), Auto-Pilot logs the error in the ticket folder and re-attempts later.
-   After three failures, the action is marked as blocked and Auto-Pilot pauses, requiring operator intervention or manual retry.
-   Each action calls a skill, tool, MCP, A2A, runs a notebook, executes a script.
-   Each successful action results in stage → pre-commit → commit → push.
-   Auto-Pilot continues pushing until all required bullets are checked and artifacts exist.
-   Once the ticket meets every requirement, Auto-Pilot opens a PR.
-   CI validates the completed ticket.
-   If CI fails, Conductor run /pause to halt Auto-Pilot and runs /fix on the CI action.
-   If CI passes, Conductor run /merge and moves to next ticket.
-   Scripts (e.g., `data_pull.py`) are called inside the venv and record outputs to `artifacts/`.

#### CI Gate (Step 5)

`ci.yml`

-   Checkout repo (fetch‑depth: 0 for diff).
-   make test
    -   Run lint and unit tests.
-   venv python scripts/check_todo.py
    -   No required action remain.
    -   No previously checked action is reverted.
-   venv python scripts/check_artifacts.py
    -   Ensures artifacts listed in `ticket.yml` exist in the ticket folder.
-   All checks must pass for PR merge.

#### Finalization & Next Phase (Step 6)

-   On PR merge, `conductor_update.py` (venv) sets `status: done` in `ACTIVE_SESSION.md` and bumps the pipeline state.
-   Conductor creates the next phase branch + ticket if another Issue awaits.
-   Trigger: push to main that modifies any `checklist.md`.
-   If the modified checklist’s `status` became done:
    -   Updates `docs/session-context/ACTIVE_SESSION.md` with next phase, mode & timestamp.
    -   Creates new branch `phase/<next_phase>_<next_issue>` with skeleton checklist folder.
    -   Pushes branch+commit; opens draft PR targeting main.

*No folder move to* `_archive/`*; finished lists stay where they are.*

#### Drive Completion (Step 7)

-   If `select_next_issue.py` returns nothing, Auto-Pilot posts an alert:

>   🚂 Drive complete — task queue empty. Run `/plan` to create or label new Issues with Task and auto (use priority labels `now` → `next` → `future`). The train halts until the operator refills the queue.

### Operator Responsibilities

| When                        | Action                                                                 |
|-----------------------------|------------------------------------------------------------------------|
| Before running Auto-Pilot   | Label Issues correctly and leave them un‑assigned.                     |
| While Auto-Pilot runs       | Optionally monitor PRs; intervene with `/pause` or `/abort` if needed. |
| After Auto-Pilot completion | Use `/plan` to create or re‑label tasks in the queue for the next run. |

## Agents

### Conductor

-   Leads the value train from planning to delivery
-   Coordinates handoffs, ensures business alignment
-   Resolves cross-agent blockers

### Onboarder

-   Owns pre-engagement success
-   Aligns client expectations, deliverables, and readiness

### Lab

-   Handles data profiling, extraction, cleaning, and initial modeling
-   Iterates with Improver for retraining and feature updates

### Studio

-   Designs models, architecture, and inference systems
-   Collaborates with Lab + Ops to productionize logic

### Ops

-   Provisions cloud resources, manages IAM, cost tagging, monitoring
-   Ensures deployment is secure, auditable, and reversible

### Evaluator

-   Defines and validates model quality
-   Tracks success metrics over time and triggers retraining reviews

### Improver

-   Optimizes features, feedback loops, retraining cadence
-   Converts feedback and errors into better performance

## Assets

Skills, tools, MCPs, and A2A available to agents.

| Type  | Name                  | Description                                    | Available To         |
|-------|-----------------------|------------------------------------------------|----------------------|
| Tool  | Data Profiler         | Jupyter or C\# notebook for EDA                | Lab                  |
| Tool  | MLflow Tracker        | Logs and visualizes experiment results         | Lab, Evaluator       |
| Tool  | Deployment Pipeline   | CI/CD system for model packaging               | Studio, Ops          |
| Skill | Architecture Design   | Ability to map inputs → model → outputs        | Studio, Conductor    |
| Skill | Business Framing      | Translate client needs into scoped delivery    | Onboarder, Conductor |
| MCP   | GPT-Prompting v1      | Structured prompt set for interviews/workshops | All agents           |
| A2A   | Conductor-Task-Router | Assigns, sequences, and re-tries agent tasks   | Conductor            |
| A2A   | Eval-Perf-Watcher     | Periodic model accuracy and drift monitor      | Evaluator, Improver  |

### Skill

A capability or domain of expertise that an agent can apply to perform reasoning, decision-making, or execution within its scope.

-   Often taught via examples, documentation, or demonstrations.
-   May be specific (e.g., “label schema design”) or abstract (e.g., “business framing”).
-   Can be possessed by both human agents and AI agents.
-   Normally scoped to functionality implemented inside of the agentic system.
-   Usually implemented with system prompts for LLM based AI agents.

### Tool

A tangible asset or software utility that an agent uses to complete a task.

-   Examples: notebooks, CI/CD pipelines, code libraries, dashboards.
-   Tools have affordances and outputs that shape how agents operate.
-   May require configuration, permissions, or integrations.
-   Normally scoped to functionality implemented outside of an agentic system.
-   Usually implemented as discrete functions callable by an LLM based AI agent.

### MCP (Model Context Protocol)

A structured prompt set or communication format that governs how models are instructed, queried, or guided across phases.

-   Ensures consistency across agent interactions with LLMs.
-   Think of it as an API contract between agents and models.

### A2A (Agent-to-Agent)

A system-level interaction, interface, or automation that enables coordination or information flow between agents.

-   Includes handoffs, alerts, task routing, retry policies, or chat interfaces.
-   Can be human-mediated or machine-driven (e.g., orchestrated by the Conductor).

### Asset Registry

Add a simple YAML or markdown table (one per category) under `/docs/rules/asset-registry.md`. Agents reference it instead of hard-coding paths in every mode header.

Example skeleton:

```yaml
skills:
  architecture_design: Studio, Conductor
  data_profiling: Lab

tools:
  data_profiler: Lab
  mlflow_tracker: Lab, Evaluator
  deployment_pipeline: Studio, Ops

mcps:
  mcp_discovery_v1: All
  mcp_review_v2: Evaluator

a2a:
  conductor_task_router: Conductor
  eval_perf_watcher: Evaluator, Improver
```

## Workshops

Workshops are exercises where the agent is engaged in collaborative, human-in-the-loop, design, thinking, and problem solving with operators. Agents ask questions, run 1:1 or group interviews, and collaborate with operators to think, ideate, and solve challenges.

| Phase               | Goal                                         |
|---------------------|----------------------------------------------|
| Opportunity Triage  | Determine if this is a real AI opportunity   |
| Discovery & Framing | Define the use case and success metrics      |
| Client Readiness    | Identify blockers and readiness gaps         |
| Data Sources        | Locate and understand data systems           |
| Feature Engineering | Clarify business logic for features          |
| Evaluation          | Confirm how value and quality will be judged |

### Question Prompts

Question prompts provide examples for agent to ask questions to operators on various categories of questions.

#### Use Case & Impact

-   What problem are we solving?
-   What happens when this problem isn’t solved?
-   Who feels the pain, and how often?
-   How are you solving it today?
-   What would a successful solution unlock?

#### Business Alignment

-   What’s the measurable business value of solving this?
-   What metric would make this project a success?
-   Who ultimately approves or evaluates the result?
-   Are there organizational initiatives this aligns with?

#### Data & Feasibility

-   What systems store the relevant data?
-   How is the data structured? How complete?
-   Is the data labeled, annotated, or pre-processed?
-   How far back does the data go?
-   Who controls or owns this data internally?

#### Delivery Constraints

-   Is there a specific deadline or external driver?
-   What systems will this need to integrate with?
-   Is there a budget constraint for this initiative?
-   Are there technical or regulatory constraints?

#### Stakeholders & Decision-Makers

-   Who will use the output or predictions?
-   Who is responsible for approving the results?
-   Who can label data or validate outcomes?
-   Who is the internal technical POC?

#### Risk & Failure Handling

-   What are the risks if the model is wrong?
-   How do you currently handle mistakes in this process?
-   Are there legal or operational boundaries we should be aware of?

### Usage Instructions

Agents can:

-   Pull relevant sections for 1:1 or group interviews
-   Use prompt sets in workshops or GPT-guided discovery
-   Turn completed answers into Opportunity Briefs, Risk Registers, and Use Case Docs

For each session:

-   Document the agent name, date, participants
-   Save responses as markdown or form JSON for system ingestion
-   Push summaries into CRM, Notion, or project tracker

## Modes

A Mode is a bounded operating context with its own:

-   Front-matter
    -   Description header
    -   Allowed tool list
-   Status
-   Checklist
-   Rules
-   Exit criteria
-   Transitions

A Mode is *not* the same as a pipeline phase; it is a controlled working state an agent enters to complete a focused slice of work.

| Mode Command | Agents               | Purpose                                                                         |
|--------------|----------------------|---------------------------------------------------------------------------------|
| `/intake`    | Onboarder            | Qualify lead, capture opportunity brief, decide Go/No-Go                        |
| `/discover`  | Onboarder            | Workshops, data samples, risk and readiness scoring                             |
| `/scope`     | Onboarder, Conductor | Produce MVP plan, SOW, pricing, pitch                                           |
| `/design`    | Studio, Lab          | Architect data flow, feature plan, model approach                               |
| `/build`     | Lab, Studio          | Extract data, engineer features, train models (TDD or TML “test-measure-learn”) |
| `/evaluate`  | Evaluator            | Formal validation against metrics and business KPIs                             |
| `/deliver`   | Studio, Ops          | Final tests, package artifacts, create PR or release                            |
| `/operate`   | Ops, Evaluator       | Watch live performance, drift, cost, error budgets                              |
| `/improve`   | Improver, Lab        | Root-cause analysis, retraining, roadmap updates                                |

Each mode inherits a common shell but has its own checklist and transition map.

### Mode Template

```Code
---
description: <one-sentence purpose>
allowed-tools: Read, Write, TodoWrite, Bash(git:*), Bash(gh:*), Bash(test:*)
---
# <Mode Name> Agent

Always start responses with:
🤖 [<Mode Name>]

Initial status block:
🤖 [<Mode Name>]
Status
Git status: !git status 
Current branch: !git branch --show-current 
Open PRs: !gh pr list --head $(git branch --show-current)

### Checklist (TodoWrite)

0. Read rule and context files *
1. ...
n. Ready for mode switch *

### Rules
* @docs/rules/rulel-filename.ext
* @docs/rules/rule2-filename.ext

### Exit Requirements
* Itemised list

### Allowed Transitions
* `/other-mode`,`/another-mode`
```

### Modes to Phases Mapping

| Pipeline Phase       | Active Mode         |
|----------------------|---------------------|
| Data Sources         | /discover, /design  |
| Extraction           | /build              |
| Preparation          | /build              |
| Exploration          | /build              |
| Feature Engineering  | /build              |
| Model Architecture   | /design             |
| Training             | /build              |
| Validation           | /evaluate           |
| Deployment           | /deliver            |
| Monitoring           | /operate            |
| Evaluation           | /operate, /evaluate |
| Performance Analysis | /improve            |
| Improvement          | /improve            |
| Retraining Loop      | /improve, /build    |

### Other Modes

-   /scope: Finalise SOW, budget, pitch deck; push artifacts; get Conductor approval.
-   /design: Write model flow diagram, feature spec, ADRs; review security implications.
-   /build: Red-green-refactor for code or train-measure-iterate for models; commit MLflow runs.
-   /evaluate: Run test suite and KPI checks; record champion–challenger comparison.
-   /deliver: Merge to main, tag release, update CURRENT_STATE and NEXT_TASKS.
-   /operate: Verify monitors live; update cost dashboards; produce weekly performance note.
-   /improve: Open issues for failure themes; draft improvement roadmap; farm new training data.

## Scripts

-   All Python scripts are executed in the project’s virtual environment (`venv/bin/activate`) to ensure dependency isolation.
-   To initialize your environment locally, run:

```bash
make venv
source venv/bin/activate
```

-   All scripts are unit tested by test script in `/tests/scripts/`

| Script                     | Purpose                                                            | Trigger           |
|----------------------------|--------------------------------------------------------------------|-------------------|
| `select_next_issue.py`     | Select issue                                                       | Auto-Pilot        |
| `check_todo.py`            | Validate checklist monotonicity & required ticks                   | CI                |
| `check_artifacts.py`       | Verify artifacts presence                                          | CI                |
| `check_session.py`         | Verify values between base & head                                  | CI                |
| `conductor_update.py`      | Mark phase done & open next                                        | Post‑merge Action |
| `validate_active_state.py` | Validate `phase`, `mode`, `status` against `/docs/rules/enums.yml` | CI                |

## Pre‑Commit Hooks

-   branch‑name‑check.sh – validates `phase/<slug>_<id>`. To install it locally:

```bash
pre-commit install --hook-type prepare-commit-msg
```

-   size‑guard.sh – rejects new blobs \> 5 MB (unless in Git LFS).

| Guard‑rail           | Implementation                                                                                                                                           | Location                           |
|----------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------|
| Git LFS routing      | Add `.gitattributes` so heavy formats (`*.ipynb`, `*.pptx`, `*.csv`, `*.parquet`, `*.onnx`, `*.pth`) are stored via LFS, not Git history.                | repo root                          |
| CI size gate         | Workflow `size-check.yml` aborts PR if any new blob \> 5 MB and not LFS‑tracked.                                                                         | `.github/workflows/size-check.yml` |
| Pre‑commit size hook | Local script warns dev if adding files \> 1 MB without LFS pointer.                                                                                      | `.pre-commit-config.yml`           |
| Artifact folder rule | Only text / small images (\<500 KB) belong in `artifacts/`. Heavy assets go to cloud store (S3 / Azure Blob) and are referenced by URL in the checklist. | Documentation rule                 |

>   CI fails if size gate trips, prompting contributor to use LFS or external storage.

-   After successful action, Auto-Pilot edits `checklist.md`, stages, and commits.

## Guard‑Rails

| Layer                   | Mechanism / Check                                                                                     | Tool / What it prevents                   |
|-------------------------|-------------------------------------------------------------------------------------------------------|-------------------------------------------|
| Path protection         | `checklists/**` & `ACTIVE_SESSION.md` CODEOWNED by @conductor-bot; branch protection requires PR & CI | Blocks direct pushes and rogue edits      |
| Single‑writer rule      | Only Conductor‑bot commits to `ACTIVE_SESSION.md`; humans read‑only                                   | Eliminates human‑human conflicts          |
| Phase branch naming     | Each phase branch updates only its own ticket folder                                                  | Parallel phase work doesn’t collide       |
| Bot commit queue        | Conductor re‑bases & force‑pushes if `main` advanced                                                  | Prevents bot‑bot races                    |
| CI gate (session)       | `check_session.py` fails if conflicting phase values between base & head                              | Prevents logical divergence               |
| Monotonic diff          | A checked bullet must never revert to unchecked                                                       | `check_todo.py` guards against regression |
| Required boxes          | All bullets marked `*` must be checked                                                                | `check_todo.py` ensures completeness      |
| Artifact check          | Expected artifacts (from `pipeline.yml`) must exist                                                   | `check_artifacts.py` verifies outputs     |
| Freeze finished tickets | If `status: done` ticket is modified CI fails                                                         | `check_todo.py` locks history             |
| Large‑file guard        | PR fails if new blob \> 5 MB and not in Git LFS                                                       | `size-check.yml` prevents repo bloat      |

## Recovery Protocol

1.  CI detects conflict → marks PR red with explanation.
2.  Operator runs `/abort` or re‑bases their branch.
3.  Conductor bot regenerates `ACTIVE_SESSION.md` based on latest `main` + their phase checklist.

# Risks

Here’s how it could tip off-track:

-   Scope drift: If agents don’t tie to concrete roles, processes, and outcomes, they become glorified chatbots.
-   Context overload: If instructions or prompts get too long or too abstract (context poisoning), your agents might hallucinate or misfire.
-   Artifact chaos: If the framework doesn’t enforce artifact standards or version control, you’ll end up with inconsistent delivery.
-   Disconnected team: If assistants don’t surface work visibly or integrate with daily ops, the team won’t adopt them.

# Roadmap

Stuff we’re thinking about:

-   Map each phase to specific agents, inputs, outputs, checklists, and commands.
-   Codify roles and expectations: what does a Dev Assistant *do*, and *how* does it help a dev stay in flow?
-   Instrument the system with dashboards and feedback loops from FlowForge + Nucleus.
-   Define intervention triggers: what does the system do when something falls off the track (missed deadline, low quality, no artifact)?
-   Keep running experiments on agent workflows, evaluate them like dev teams evaluate A/B features.

# Contribute

We’re laying the rails as the engine barrels forward. Won’t you join the ride. If you’re thinking about this stuff and want to think together, maybe you just want to help engineer the train or lay the rails, we welcome you to contribute.

All aboard!

# FAQ

| Question                                                 | Answer                                                                                                   |
|----------------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| Why not store checklists in Issues?                      | Simpler pipeline; CI doesn’t need GitHub API tokens; fewer race conditions.                              |
| Will folders crowd the repo?                             | Plain‑text checklists are tiny (\< 2 KB). Heavy artifacts should go to Git LFS or external storage.      |
| Can we restart a failed phase?                           | Re-open the Issue or create a new one with a new ID. The original folder remains frozen for audit trail. |
| What if someone force-pushes?                            | Branch protection (including for admins) prevents unauthorized force-pushes to `main`.                   |
| How do I run the pipeline locally without creating a PR? | Use `/drive --local` to run scripts and CI validations without opening or pushing a PR.                  |
| What if Auto-Pilot selects an Issue I want to work on?   | Assign yourself to the Issue. Auto-Pilot only picks unassigned issues labeled `auto`.                    |
| CI failed due to large file size. What now?              | Use `git lfs track <file>`, recommit, and push using `--force-with-lease`.                               |
| How do I add a new required checklist bullet type?       | Edit `/docs/rules/templates/checklist.yml` and update related tests in `check_todo.py`.                  |

# Glossary

| Term            | Definition                                                                                                                                    |
|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| Ticket          | The combination of `checklist.md`, `ACTIVE_SESSION.md`, and `artifacts/` for a specific Phase × Issue.                                        |
| Required bullet | An item flagged with \*; pipeline cannot advance until all required items are checked. Only items marked with \* are required for CI to pass. |
| Operator        | Human users who triage and prioritize issues and may switch modes manually.                                                                   |
| Phase           | A defined step in the value delivery lifecycle such as plan, build, test, train, validate, release.                                           |
| Mode            | A command (e.g., `/build`, `/evaluate`) that activates a specific checklist, agents, and workflow for a phase.                                |
| Conductor       | The agent that coordinates pipeline state, merges PRs, and creates next phase tickets.                                                        |
| Lab             | Agent responsible for data profiling, extraction, cleaning, and model experimentation.                                                        |
| Studio          | Agent that designs models, architecture, and production logic.                                                                                |
| Evaluator       | Agent that defines success metrics and validates quality and performance.                                                                     |
| Improver        | Agent that handles error correction, feedback loops, retraining cadence, and continuous model improvement.                                    |
| Session         | A single run of Auto-Pilot, starting from kickoff and ending at completion or pause.                                                          |
| Ticket folder   | The folder named `tickets/<phase>_<id>/` that holds a ticket’s session, checklist, and artifacts.                                             |
| Checklist       | The markdown list of actions to complete for a phase; lives in `checklist.md`.                                                                |
