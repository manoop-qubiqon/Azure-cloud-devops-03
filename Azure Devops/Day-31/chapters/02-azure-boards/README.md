# Chapter 2: Azure Boards — Planning Your Project

> Before you write a single line of code, you need a plan. Azure Boards is where that happens.

**Prerequisites**: Chapter 1 completed, SkillPulse project created in Azure DevOps.

---

## What is Azure Boards?

Azure Boards is the project management tool inside Azure DevOps. Think Jira or Trello, but integrated with your repos, pipelines, and everything else.

You can plan work, organize sprints, visualize progress on a Kanban board, and link work items directly to code branches and PRs.

It's **completely free** for up to 5 users.

---

## Key Concepts

### Work Items

Everything is tracked as a work item, organized in a hierarchy:

```
Epic
 └── Issue
      └── Task
```

| Type | What It Represents | Example |
|------|-------------------|---------|
| **Epic** | Big initiative | "SkillPulse MVP" |
| **Issue** | A feature, bug, or piece of work | "Add a new skill with name and category" |
| **Task** | Technical step inside an Issue | "Create MySQL schema for skills table" |

### Process Templates

When you create a project, you pick a process template:

| Template | Work Item Types | Best For |
|----------|----------------|----------|
| **Basic** | Epic, Issue, Task | Small teams, simplicity |
| **Agile** | Epic, Feature, User Story, Task, Bug | More structure |
| **Scrum** | Epic, Feature, PBI, Task, Bug | Strict Scrum |

We're using **Basic** in this course. If you picked Agile, your "Issues" will be called "User Stories" — same idea.

[Screenshot: Process template selection]

### Backlogs & Sprints

The **backlog** is your ordered to-do list. A **sprint** is a time-boxed period (usually 2 weeks) where you pick items from the backlog and commit to finishing them.

### Kanban Board

A visual board with columns representing status. Default columns: `To Do | Doing | Done`. You drag cards across as work progresses.

[Screenshot: Kanban board with cards]

---

## Hands-on: Setting Up the SkillPulse Backlog

### Step 1: Verify Your Process Template

1. Go to **Project settings** (gear icon, bottom-left)
2. Under **Boards** > **Project configuration**, check the process template

[Screenshot: Project settings showing process template]

### Step 2: Create the Epic — "SkillPulse MVP"

1. Go to **Boards** > **Backlogs**
2. Set backlog level to **Epics**
3. Click **+ New Work Item**, type: **SkillPulse MVP**
4. Open it, add a description: `Build the first version of SkillPulse — a personal learning dashboard.`
5. Set Priority to **1**, click **Save & Close**

[Screenshot: Creating the SkillPulse MVP Epic]

### Step 3: Create Issues

Switch to **Issues** backlog level. Create these 10 issues:

| # | Issue Title | Parent |
|---|------------|--------|
| 1 | View list of skills with progress bars | SkillPulse MVP |
| 2 | Add a new skill with name and category | SkillPulse MVP |
| 3 | Set a target hours goal for each skill | SkillPulse MVP |
| 4 | Log a learning session (hours + notes) | SkillPulse MVP |
| 5 | Dashboard with total skills, hours, and sessions | SkillPulse MVP |
| 6 | Delete a skill I'm no longer tracking | SkillPulse MVP |
| 7 | View learning history for a specific skill | SkillPulse MVP |
| 8 | Progress bar showing hours vs target | SkillPulse MVP |
| 9 | (Bonus) Filter skills by category | SkillPulse MVP |
| 10 | (Bonus) Export learning data | SkillPulse MVP |

For each Issue:
- Set the **Parent** to SkillPulse MVP
- Add **Acceptance Criteria** in the description (what "done" looks like)
- Add **Tags**: `backend`, `frontend`, `database`, or `devops`
- Set **Effort**: Small = 2, Medium = 3, Large = 5

[Screenshot: Backlog showing all 10 Issues]

### Step 4: Create Tasks Under Issues

Open Issue #1 and create child Tasks:

| Task | Estimated Hours |
|------|----------------|
| Create MySQL schema for skills table | 1 |
| Build GET /api/skills endpoint in Go | 2 |
| Create skill listing UI component | 2 |
| Add progress bar component | 1 |
| Write unit tests for skills API | 1 |

Repeat for Issues #2, #4, and #5 with similar breakdowns. You don't need tasks for every issue right now — in practice, you create them during sprint planning.

[Screenshot: Issue with child Tasks]

### Step 5: Set Up Sprint 1

1. Go to **Boards** > **Sprints** (or **Project Settings** > **Iterations**)
2. Create a sprint: **Sprint 1 — Foundation**, 2 weeks starting today
3. Assign Issues #1-5 to Sprint 1 (open each issue, set the **Iteration** field)

You can also drag items from the backlog into the sprint.

[Screenshot: Sprint setup with work items]

### Step 6: Customize the Kanban Board

1. Go to **Boards** > **Boards**
2. Click the **gear icon** (board settings) > **Columns**
3. Add a **Testing** column between Doing and Done
4. Set **WIP limits**: Doing = 3, Testing = 2

WIP limits prevent your team from starting too many things at once. If the column is full, finish something before starting something new.

[Screenshot: Customized Kanban board with Testing column]

Now drag a card from To Do to Doing — you've just started your first sprint!

---

## What's Next

In **[Chapter 3: Azure Repos](../03-azure-repos/)**, we'll push the SkillPulse code to a Git repo, set up branch policies, and create our first Pull Request.

---

[<< Previous: Chapter 1](../01-intro-azure-devops/) | [Next: Chapter 3 — Azure Repos >>](../03-azure-repos/)
