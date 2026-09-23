# Day 04 — Pull Requests, Branch Policies & Code Review

> Goal: collaborate safely with pull requests, reviews, and enforced branch policies.

---

## Objectives

By the end of this day you will:

- Open, review, and complete a pull request
- Configure branch policies on main
- Require reviewers, linked work items, and successful builds
- Understand merge strategies

---

## Concepts

### The pull request (PR)

- A request to merge a feature branch into main
- Carries diffs, comments, reviewers, and status checks
- Discussion + approvals happen before merge

### Branch policies

- Require a minimum number of approvals
- Require linked work items and resolved comments
- Require a passing build (CI) before completion
- Block direct pushes to main

### Merge strategies

- Merge commit, squash, rebase — trade-offs in history cleanliness
- Squash keeps main history tidy for feature branches

---

## Hands-on

1. Open a PR from your feature branch into main
2. Add a reviewer and leave a comment thread
3. Enable a branch policy requiring 1 approval on main
4. Complete the PR using squash merge

---

## Commands / snippets

```
az repos pr create --repository app --source-branch feature/add-readme --target-branch main --title "Add README"
az repos pr list --status active
az repos pr update --id <id> --status completed
```

> Add your own notes, screenshots, and expanded examples in this section.

---

## Homework

- Configure at least three branch policies on main
- Run a full review cycle: comment, update, re-review, approve, merge
- Document your team's chosen merge strategy and why

---

## Recap

- PRs are where collaboration and quality gates live
- Branch policies enforce standards automatically
- main stays protected and always mergeable
- Next: automate builds with Azure Pipelines (CI)

