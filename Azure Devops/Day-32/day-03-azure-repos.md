# Day 03 — Azure Repos & Git Essentials

> Goal: host code in Azure Repos and use Git confidently with modern commands.

---

## Objectives

By the end of this day you will:

- Create a Git repository in Azure Repos
- Clone, commit, branch, and push using modern Git syntax
- Understand the branching model you'll use in the course
- Connect a work item to a commit

---

## Concepts

### Git core model

- Working directory → staging area → local repo → remote repo
- Commits are snapshots; branches are movable pointers
- Remote 'origin' is your Azure Repos repository

### Branching strategy

- main is always deployable
- Short-lived feature branches: feature/<name>
- Merge back via pull request (Day 04)

### Modern command syntax

- Use `git switch` / `git switch -c` instead of `git checkout`
- Use `git restore` to discard changes
- Keep commits small and messages descriptive

---

## Hands-on

1. Create a repo named `app` in Azure Repos
2. Clone it, add a README, commit, and push
3. Create a feature branch, make a change, and push it
4. Reference a work item in a commit message with #<id>

---

## Commands / snippets

```
git clone https://dev.azure.com/<org>/<project>/_git/app
cd app
git switch -c feature/add-readme
# ...edit files...
git add .
git commit -m "Add project README #12"
git push -u origin feature/add-readme
```

> Add your own notes, screenshots, and expanded examples in this section.

---

## Homework

- Practise the branch → commit → push loop three times
- Intentionally create and resolve a merge conflict locally
- Explore Files, Commits, Branches, and Tags in the Repos UI

---

## Recap

- Azure Repos hosts unlimited private Git repositories
- A clean branching model keeps main deployable
- Modern Git commands (switch/restore) are clearer and safer
- Next: collaborate and gate quality with pull requests

