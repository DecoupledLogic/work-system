# Workflow Commands

This directory contains commands for managing work items through the different stages of the work system.

## Purpose

Workflow commands coordinate the movement of work items through the work system stages: Select, Triage, Plan, Design, and Deliver. These commands integrate with the domain aggregates to ensure consistent work item state management.

## Commands

### `/workflow:select-task`
Select new work from tasks assigned to you across all task lists in the project. Displays tasks in an interactive selector with grouping and sorting options.

**Usage:**
```bash
/workflow:select-task
```

### `/workflow:resume`
Resume work on in-progress tasks assigned to you. Shows all work items currently in progress that you're working on.

**Usage:**
```bash
/workflow:resume
```

### `/workflow:triage`
Triage a work item - categorize, assign process template, and route to appropriate urgency queue.

**Usage:**
```bash
/workflow:triage
```

### `/workflow:plan`
Plan a work item - decompose into smaller tasks, size the work, and elaborate with acceptance criteria.

**Usage:**
```bash
/workflow:plan
```

### `/workflow:design`
Design a work item - explore solution options, make architectural decisions, and generate implementation plans.

**Usage:**
```bash
/workflow:design
```

### `/workflow:deliver`
Deliver a work item - implement the solution, run tests, evaluate results, and complete the work.

**Usage:**
```bash
/workflow:deliver
```

### `/workflow:queue`
Display work items by urgency queue. Shows queue contents sorted by priority with age and status information.

**Usage:**
```bash
/workflow:queue
```

### `/workflow:route`
Move work items between urgency queues. Updates local queue store with history tracking.

**Usage:**
```bash
/workflow:route
```

## Stage Transitions

The workflow commands follow this stage progression:

```
Select → Triage → Plan → Design → Deliver → Eval
```

- **Select**: Choose work from your assigned tasks
- **Triage**: Categorize and route to appropriate queue
- **Plan**: Break down and estimate the work
- **Design**: Create solution architecture
- **Deliver**: Implement and test the solution
- **Eval**: Evaluate results and capture learnings

## Integration

All workflow commands integrate with the `/domain:work-item` aggregate for consistent state management and cross-platform synchronization (Teamwork, Azure DevOps, GitHub).
