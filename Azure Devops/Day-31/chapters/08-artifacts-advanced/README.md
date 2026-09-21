# Chapter 8: Azure Artifacts, Test Plans, Dashboards & Security

> The "polish and protect" chapter — make your project more professional, more visible, and more secure.

**Prerequisites**: Chapters 1-7 completed, SkillPulse deployed with a working CI/CD pipeline.

---

## 1. Azure Artifacts — Package Feeds

Azure Artifacts lets you create **private package feeds** — your team's own npm registry, PyPI server, or Go module proxy.

For a single app like SkillPulse, you probably don't need it. But in the real world, it's essential when:
- Multiple services share a common library
- You want to cache public packages (protection against deleted packages)
- Compliance requires controlling exact package versions

**Supported formats**: npm, NuGet, Maven, pip, Go, Cargo, Universal packages.

**Free tier**: 2 GiB storage per organization, unlimited feeds and downloads.

### Hands-on: Create a Feed

1. Go to **Artifacts** in the left sidebar
2. Click **Create Feed**
3. Name: `skillpulse-packages`
4. Visibility: Members of your org
5. Check **Include packages from common public sources** (enables upstream caching)
6. Click **Create**

[Screenshot: Create Feed dialog]

Explore your feed:
- **Connect to feed** — shows setup instructions for npm, pip, Go, etc.
- **Feed settings** — manage upstream sources, permissions, retention policies
- **Upstream sources** — pre-configured connections to npmjs.com, nuget.org, pypi.org

[Screenshot: Feed with upstream sources]

---

## 2. Azure Test Plans

Automated tests (in your pipeline) catch known bugs. **Manual and exploratory testing** catches the stuff automation misses — visual issues, usability problems, edge cases.

Azure Test Plans has two tiers:
- **Free**: Test & Feedback browser extension — screenshots, notes, bug creation during exploratory testing
- **Paid**: Formal test plans, test suites, test case management (~$52/user/month)

We'll use the free extension.

### Quick Exploratory Testing

1. Install the **Test & Feedback** extension ([Chrome](https://chrome.google.com/webstore/detail/test-feedback/gnldpbnocfnlkkicnaplmkaphfdnlplb) / [Edge](https://microsoftedge.microsoft.com/addons/detail/test-feedback/gcknhkkoolaabfmlnjonogaaifnjlfnp))
2. Click the extension icon > Settings > Connect to your Azure DevOps org and SkillPulse project
3. Click **Start session**
4. Use SkillPulse normally — add skills, log sessions, try edge cases
5. Capture screenshots, add notes, create bugs directly from the extension
6. Bugs are auto-linked with context (screenshots, browser info)

[Screenshot: Test & Feedback extension in action]

---

## 3. Dashboards

Dashboards give you a visual overview of project health. Instead of digging through pipeline runs and work items, share a dashboard link.

### Build a Project Dashboard

1. Go to **Overview** > **Dashboards** > **+ New Dashboard**
2. Name: `SkillPulse Project Health`

Add these widgets:

**Build History** — Recent pipeline runs with pass/fail status.
- Search "Build History", add it, configure to show your CI pipeline

**Query Tile (Active Bugs)** — Shows bug count at a glance.
- First create a query: **Boards** > **Queries** > New query: `Work Item Type = Bug AND State = Active`, save as "Active Bugs"
- Add "Query Tile" widget, point it to your query
- Set color rules: green for 0, red for > 0

**Chart for Work Items** — Pie chart of work items by state.
- Add "Chart for Work Items" widget, group by State

**Markdown (Quick Links)** — Custom text widget.
- Add links to your pipeline, deployed app, backlog

**Pull Requests** — Shows open PRs.

[Screenshot: Completed dashboard with all widgets]

Arrange widgets, click **Done Editing**. Check it daily.

---

## 4. Security Best Practices

This is the most important section. A leaked password can ruin everything.

### Azure Key Vault + Variable Groups

Pipeline variables work for learning, but in production, use **Azure Key Vault**:

```
Key Vault (stores secrets) ←→ Variable Group (links to Key Vault) → Pipeline uses $(SECRET_NAME)
```

The pipeline never stores secrets — it fetches them at runtime from Key Vault.

**Setup** (requires Azure subscription):
1. Create a Key Vault in Azure Portal
2. Add secrets (e.g., `DB-PASSWORD`)
3. Create an Azure Resource Manager service connection in Azure DevOps
4. Create a Variable Group in **Pipelines** > **Library**, toggle on **Link secrets from Azure Key Vault**
5. Select your Key Vault, add the secrets you need

```yaml
variables:
  - group: skillpulse-secrets  # Linked to Key Vault

steps:
  - script: docker compose up -d
    env:
      DB_PASSWORD: $(DB-PASSWORD)  # Fetched at runtime
```

[Screenshot: Variable group linked to Key Vault]

### Service Connection Security

Apply **least privilege** — restrict service connections to specific pipelines:

1. **Project Settings** > **Service connections** > click your connection > **Security**
2. Under Pipeline permissions, click **Restrict** and add only the pipelines that need it

### Branch Policies as Security Gates

Your branch policies from Chapter 3 aren't just workflow — they're security:

| Policy | Security Benefit |
|--------|-----------------|
| Require PR reviewers | Second pair of eyes catches accidental secrets, insecure code |
| Build validation | Failing tests can't be merged |
| Linked work items | Rogue changes stand out |
| Comment resolution | Security concerns must be addressed before merge |

### Never Commit .env Files

Rule #1. Your `.gitignore` should have:

```gitignore
.env
.env.local
.env.*.local
!.env.example
```

Always commit `.env.example` with placeholder values. If you accidentally committed a `.env`:
1. **Rotate all secrets immediately** — consider them compromised
2. Remove from tracking: `git rm --cached .env`
3. Deleting the file isn't enough — it's still in Git history

### Secure Files

Store SSH keys and certificates in **Pipelines** > **Library** > **Secure files**. They're encrypted at rest, available only during pipeline runs, and auto-cleaned afterward. Much better than storing them in the repo.

### Security Checklist

- `.env` is in `.gitignore` and NOT in the repo
- `.env.example` exists with placeholders
- Secrets in Key Vault (or at minimum, marked secret in pipeline variables)
- Service connections restricted to specific pipelines
- Branch policies on `main` (PR required, reviewer, build validation)
- No secrets printed in pipeline logs
- VM firewall: SSH restricted to your IP in production

---

## 5. GitHub Advanced Security for Azure DevOps (GHAzDO)

Worth knowing about (paid add-on):

- **Code scanning** — Finds vulnerabilities (SQL injection, XSS, hardcoded creds) using CodeQL
- **Secret scanning** — Detects accidentally committed secrets (AWS keys, Azure tokens, etc.)
- **Dependency scanning** — Checks `go.mod`, Docker images for known CVEs

Even without GHAzDO, adopt the mindset: scan code, watch for leaked secrets, keep dependencies updated. Free tools like `go vet`, `gosec`, and `trivy` can help.

---

## What's Next

In **[Chapter 9: The Complete Workflow](../09-complete-workflow/)**, we'll bring everything together — add a real feature to SkillPulse using the full Azure DevOps loop from Board to production.

---

[<< Previous: Chapter 7 — Self-Hosted Agent](../07-self-hosted-agent-vm/) | [Next: Chapter 9 — Complete Workflow >>](../09-complete-workflow/)
