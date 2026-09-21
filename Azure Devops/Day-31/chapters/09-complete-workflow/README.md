# Chapter 9: The Complete Azure DevOps Workflow

> Everything connects. One feature, start to finish — Board to production.

**Prerequisites**: Chapters 1-8 completed, SkillPulse running on your VM with CI/CD pipeline.

---

## The DevOps Loop

Every feature follows the same loop:

```
Plan → Branch → Code → Push → PR → CI → Review → Merge → CD → Verify → Done
```

| Step | What Happens | Azure DevOps Service |
|------|-------------|---------------------|
| Plan | Create work item | Boards |
| Branch | Create feature branch | Repos |
| Code | Write changes locally | Your editor |
| Push | Push to Azure Repos | Repos |
| PR | Create Pull Request | Repos |
| CI | Auto build + test | Pipelines |
| Review | Code review, approve | Repos |
| Merge | Squash merge to main | Repos |
| CD | Auto deploy to VM | Pipelines |
| Verify | Check it works live | Browser |
| Done | Move work item to Done | Boards |

Every deployed change traces back to a work item, branch, PR, and pipeline run. That's the power of an integrated platform.

---

## Hands-on: Adding "Category Filter" End-to-End

Let's walk through the entire loop with a real feature.

### Step 1: Create a User Story

1. **Boards** > **Backlogs** > **+ New Work Item**
2. Title: `As a user, I can filter skills by category`
3. Description: Add a category filter dropdown to the dashboard
4. Story Points: 3
5. Move to **Active** on the Kanban board

[Screenshot: User Story on Kanban board]

### Step 2: Create a Feature Branch

From the work item, click **Create a branch** in the Development section:
- Branch name: `feature/category-filter`
- Based on: `main`

Or from terminal:

```bash
git checkout main
git pull origin main
git checkout -b feature/category-filter
```

### Step 3: Code the Changes

**Backend** — Add optional `category` query parameter to `GET /api/skills`:

```go
// handlers/skills.go
func GetSkills(c *gin.Context) {
    category := c.Query("category")

    var skills []models.Skill
    query := database.DB
    if category != "" {
        query = query.Where("category = ?", category)
    }
    query.Find(&skills)

    c.JSON(http.StatusOK, skills)
}
```

**Frontend** — Add filter dropdown in `index.html`:

```html
<div class="filter-bar">
    <label for="category-filter">Filter by Category:</label>
    <select id="category-filter" onchange="filterByCategory()">
        <option value="">All Categories</option>
        <option value="Cloud">Cloud</option>
        <option value="Programming">Programming</option>
        <option value="DevOps">DevOps</option>
        <option value="Database">Database</option>
    </select>
</div>
```

```javascript
// js/app.js
function filterByCategory() {
    const category = document.getElementById('category-filter').value;
    const url = category ? `/api/skills?category=${category}` : '/api/skills';
    fetch(url)
        .then(res => res.json())
        .then(skills => renderSkills(skills));
}
```

**Test locally**: `docker-compose up --build`, try the dropdown.

[Screenshot: Dashboard with category filter working locally]

### Step 4: Commit and Push

```bash
git add backend/handlers/skills.go frontend/index.html frontend/js/app.js
git commit -m "Add category filter to skills dashboard

- Add optional 'category' query parameter to GET /api/skills
- Add filter dropdown to frontend
- Related work item: #42"
```

> Reference work item IDs with `#42` — Azure DevOps auto-links the commit.

```bash
git push origin feature/category-filter
```

### Step 5: Create a Pull Request

1. **Repos** > **Pull Requests** > You'll see a banner for the new branch
2. Title: `Add category filter to skills dashboard`
3. Link to your User Story
4. Add reviewer
5. Click **Create**

[Screenshot: PR creation]

### Step 6: CI Pipeline Runs Automatically

The branch policy triggers build validation. The pipeline builds, tests, and reports back to the PR — green checkmark if it passes.

[Screenshot: PR with CI passing]

### Step 7: Review and Merge

1. Review the code in the **Files** tab
2. Click **Approve**
3. Click **Complete** — Squash merge, delete branch, complete associated work items
4. Click **Complete merge**

[Screenshot: Complete merge dialog]

### Step 8: CD Pipeline Deploys

The merge to `main` triggers the CD pipeline. It runs on your self-hosted agent, rebuilds containers, and deploys.

[Screenshot: CD pipeline running]

### Step 9: Verify

Open `http://<your-vm-ip>` — the category filter should be there. Try filtering by "Cloud" or "DevOps".

[Screenshot: Category filter working on live VM]

### Step 10: Done

Check your Kanban board — the User Story should be in **Done** (auto-moved if you checked "Complete work items" during merge).

Open the work item — you'll see the linked branch, PR, and pipeline runs. Full traceability.

---

## Course Recap

| Chapter | What You Built |
|---------|---------------|
| 1 | Azure DevOps org + SkillPulse project |
| 2 | Backlog, sprints, Kanban board |
| 3 | Git repo, branch policies, PR workflow |
| 4 | SkillPulse app — Go + Nginx + MySQL + Docker |
| 5 | CI pipeline — auto build and test |
| 6 | CD pipeline — auto deploy with approvals |
| 7 | Azure VM + self-hosted agent |
| 8 | Artifacts, dashboards, security practices |
| 9 | Full end-to-end workflow |

You started with an empty Azure DevOps project. Now you have a fully planned board, a protected Git repo, an automated CI/CD pipeline, a self-hosted agent, and a live app on an Azure VM.

That's not a toy setup. That's how real teams ship software.

---

## What's Next

- **[Bonus: Terraform](../bonus-terraform/)** — Replace manual VM setup with Infrastructure as Code
- **AZ-400 Certification** — Microsoft DevOps Engineer Expert exam. You already have a head start.
- **Practice** — Apply this workflow to your own projects. The tools are the same, only the app changes.

---

**[<< Previous: Chapter 8 — Artifacts & Advanced](../08-artifacts-advanced/) | [Bonus: Terraform >>](../bonus-terraform/)**

[Back to Course Home](../../)
