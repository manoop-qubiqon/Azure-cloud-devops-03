# Chapter 3: Azure Repos — Version Control for SkillPulse

> Your code needs a home. Azure Repos gives it one — with Git, branch policies, and pull requests.

**Prerequisites**: Chapters 1-2 completed, Git installed (`git --version`), a code editor.

---

## What is Azure Repos?

Azure Repos provides **unlimited free private Git repositories** inside Azure DevOps. It's tightly integrated with Boards (link code to work items) and Pipelines (trigger builds on push).

You get branch policies, pull request reviews, code search, and a built-in web editor — all in one place.

[Screenshot: Azure Repos section in sidebar]

---

## Branch Strategy

We'll use **trunk-based development** — the simplest approach:

- Everyone works off `main`
- Feature branches are short-lived (1-3 days max)
- Merge back to `main` via Pull Requests
- Keep `main` always deployable

Branch naming convention: `feature/`, `bugfix/`, `hotfix/` followed by a short name.

---

## Hands-on: Setting Up the SkillPulse Repository

### Step 1: Initialize the Repo

1. Go to **Repos** > **Files** in your SkillPulse project
2. Click **"Initialize"** at the bottom (add a README)

[Screenshot: Empty repo page with Initialize button]

### Step 2: Clone Locally

1. Click **Clone** in the top-right, copy the HTTPS URL
2. In your terminal:

```bash
git clone https://dev.azure.com/{your-org}/SkillPulse/_git/SkillPulse
cd SkillPulse
```

**Authentication**: When prompted, use a **Personal Access Token (PAT)** as your password.

To create a PAT:
1. Click your profile icon (top-right) > **Personal access tokens**
2. Click **New Token**, name it `SkillPulse-local`
3. Set scope to **Code: Read & Write**
4. Copy the token — use it as your password

[Screenshot: PAT creation page]

### Step 3: Create a Feature Branch

```bash
git checkout -b feature/initial-setup
```

### Step 4: Add .gitignore

Create `.gitignore` in the repo root:

```gitignore
# Go
*.exe
*.dll
*.so
*.dylib
/backend/skillpulse
/backend/tmp/
*.test
*.out
go.work
go.work.sum
vendor/

# Node / Frontend
node_modules/
dist/
build/

# Docker
docker-compose.override.yml

# Environment Variables
.env
.env.local
.env.*.local
!.env.example

# IDE / Editor
.vscode/settings.json
.vscode/launch.json
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# MySQL data
mysql-data/
data/mysql/
```

### Step 5: Add SkillPulse Project Files

Copy the project files into the repo. Your structure should look like:

```
SkillPulse/
├── .gitignore
├── README.md
├── backend/
├── frontend/
├── nginx/
├── mysql/
├── docker-compose.yml
└── .env.example
```

> We'll build the actual code in Chapter 4. For now, you can copy from `project/skillpulse/` in this course repo.

### Step 6: Push

```bash
git add .
git commit -m "Initial SkillPulse project setup"
git push origin feature/initial-setup
```

Verify in Azure DevOps > **Repos** > **Branches** — you should see both `main` and `feature/initial-setup`.

[Screenshot: Branches page showing both branches]

---

## Setting Up Branch Policies

Branch policies protect `main` from broken code. Go to **Repos** > **Branches**, click the **...** menu next to `main`, select **Branch policies**.

### Policy 1: Require Reviewers

- Toggle **"Require a minimum number of reviewers"** → ON
- Set minimum to **1**
- For solo learning: check "Allow requestors to approve their own changes"

[Screenshot: Reviewer policy settings]

### Policy 2: Linked Work Items

- Toggle **"Check for linked work items"** → ON, set to **Required**

### Policy 3: Build Validation

> We'll set this up in Chapter 5 after creating our CI pipeline.

### Policy 4: Merge Strategy

- Toggle **"Limit merge types"** → ON
- Check only **Squash merge** — keeps `main` history clean

[Screenshot: Branch policies configured]

---

## Pull Request Workflow

### Create a PR

1. Go to **Repos** > **Pull Requests** > **New Pull Request**
2. Source: `feature/initial-setup` → Target: `main`
3. Title: `Initial SkillPulse project setup`
4. Link a work item from your Azure Boards backlog
5. Add yourself as reviewer
6. Click **Create**

[Screenshot: PR creation form]

### Review the PR

Click the **Files** tab to see the diff. You can leave inline comments on any line.

[Screenshot: PR Files tab with diff]

### Approve and Merge

1. Click **Approve**
2. Click **Complete**
3. Select **Squash merge**, check **Delete branch after merging**
4. Click **Complete merge**

[Screenshot: Complete merge dialog]

### Clean Up Locally

```bash
git checkout main
git pull origin main
git branch -d feature/initial-setup
```

Your code is now on `main`. Done!

---

## Tips

- **Commit messages**: Use the format `type: description` (e.g., `feat: add skill API endpoint`, `fix: db connection timeout`)
- **Never commit secrets** — `.env` files, API keys, passwords. Use `.env.example` with placeholders instead
- **Pull before push**: `git pull origin main --rebase` to avoid conflicts
- **Reference work items** in commits: `Fixed #42 — Added skill creation endpoint`

---

## What's Next

In **[Chapter 4: Building SkillPulse](../04-building-skillpulse/)**, we'll walk through the entire application — Go backend, frontend, Nginx, Docker — and run it locally.

---

[<< Previous: Chapter 2 — Azure Boards](../02-azure-boards/) | [Next: Chapter 4 — Building SkillPulse >>](../04-building-skillpulse/)
