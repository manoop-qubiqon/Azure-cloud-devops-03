# Day 02 — Azure Boards — Plan & Track Work

> Goal: plan, track, and manage work using Boards, backlogs, and sprints.

---

## Objectives

By the end of this day you will:

- Create and manage work items (Epics, Features, User Stories, Tasks, Bugs)
- Use Kanban boards and backlogs to visualise work
- Plan and run a sprint
- Link work items to code and pull requests

---

## Concepts

### Work item types & hierarchy

- Epic → Feature → User Story / Bug → Task hierarchy
- Fields: assignee, state, priority, effort, tags, area & iteration paths
- States move work across the board (New → Active → Resolved → Closed)

### Boards, backlogs & sprints

- Kanban board: drag-and-drop columns, WIP limits, swimlanes
- Backlog: prioritised, ordered list of upcoming work
- Sprints: time-boxed iterations with capacity planning

### Queries & dashboards

- Write queries to filter and report on work items
- Add board/chart widgets to team dashboards

---

## Hands-on

1. Create an Epic, then a Feature and two User Stories under it
2. Break one User Story into Tasks with estimates
3. Set up a 2-week sprint and assign the stories to it
4. Customise the Kanban board columns and add a WIP limit

---

## Commands / snippets

```
# Boards is UI-driven, but work items are also reachable via CLI:
az boards work-item create --title "Set up CI pipeline" --type "User Story"
az boards work-item show --id <id>
```

> Add your own notes, screenshots, and expanded examples in this section.

---

## Homework

- Build a small backlog of 5–8 work items for a sample app
- Organise them into an Epic/Feature/Story hierarchy
- Create a dashboard with a board widget and a query tile

---

## Recap

- Boards turns requirements into trackable, prioritised work
- Epics/Features/Stories/Tasks give structure at different levels
- Sprints time-box the work; the board visualises its flow
- Next: put the code under version control with Azure Repos

