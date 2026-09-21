# Chapter 1: Introduction to Azure & Azure DevOps

> Get set up with Azure DevOps — your account, organization, and first project.

---

## What is Azure?

**Microsoft Azure** is Microsoft's cloud platform — one of the Big Three alongside AWS and GCP. It offers 200+ services (VMs, databases, AI, networking, etc.) across 60+ regions worldwide.

For this course, we'll mainly use **Azure DevOps** (developer tools) and later an **Azure VM** (Chapter 7) to deploy our app.

---

## What is DevOps?

Traditionally, Development and Operations teams worked in silos. Developers shipped code fast, Ops wanted stability, and releases happened every few months. DevOps brings them together.

**DevOps** is a set of practices to deliver software faster and more reliably:

- **CI (Continuous Integration)** — Merge code frequently, automatically build and test on every push
- **CD (Continuous Deployment)** — Automatically deploy code that passes CI
- **IaC (Infrastructure as Code)** — Define servers in code, not manual clicks
- **Monitoring & Feedback** — Watch production, improve continuously

```
Developer pushes code
        |
        v
  +------------+
  |   CI Build  |  ← Compile, lint, run tests
  +------------+
        |
        v (tests pass)
  +------------+
  |  CD Deploy  |  ← Package and ship to server
  +------------+
        |
        v
  App is live!
```

---

## What is Azure DevOps?

Azure DevOps is Microsoft's all-in-one platform for the entire development lifecycle. Instead of stitching together Jira + GitHub + Jenkins + Nexus, you get everything in one place.

It works with **any language and any cloud** — not locked to Microsoft tech.

### The 5 Core Services

| Service | What It Does |
|---------|-------------|
| **Azure Boards** | Project management — work items, sprints, Kanban boards |
| **Azure Repos** | Unlimited free private Git repos with branch policies and PRs |
| **Azure Pipelines** | CI/CD — build, test, deploy automatically |
| **Azure Artifacts** | Private package feeds (npm, pip, Go, etc.) |
| **Azure Test Plans** | Manual and exploratory testing tools |

These aren't isolated — they're deeply integrated. A work item in Boards links to a branch in Repos, which triggers a Pipeline, which deploys your app. Everything connects.

[Screenshot: Azure DevOps showing the 5 services in the left sidebar]

---

## Azure DevOps Free Tier

This entire course runs on the free tier. No credit card needed.

| Resource | Free Allowance |
|----------|---------------|
| Users (Basic) | 5 free |
| Private Git repos | Unlimited |
| CI/CD (Microsoft-hosted) | 1 parallel job, 1,800 min/month |
| CI/CD (Self-hosted) | 1 parallel job, **unlimited** minutes |
| Azure Artifacts | 2 GiB storage |
| Boards, Repos | Full access |

**What does "1,800 minutes" mean?** A typical pipeline run takes 3-5 minutes, so you can run hundreds of builds per month.

**Self-hosted agent advantage:** In Chapter 7, we'll set up our own agent — unlimited minutes for free. You just provide the VM.

---

## Hands-on: Getting Started

### Step 1: Sign Up for Azure DevOps

1. Go to **[https://dev.azure.com](https://dev.azure.com)**
2. Click **"Start free"**
3. Sign in with your Microsoft account (Outlook, Hotmail, or Live)

[Screenshot: Azure DevOps landing page with "Start free" button]

> Use a **personal** Microsoft account. Work/school accounts may have restrictions.

### Step 2: Create an Organization

1. After signing in, click **Continue**
2. Name your organization (e.g., `yourname-devops`)
3. Select a **region** close to you
4. Click **Continue**

[Screenshot: Organization creation form]

### Step 3: Create the SkillPulse Project

1. On the "Create a project" page, fill in:

   | Field | Value |
   |-------|-------|
   | **Project name** | `SkillPulse` |
   | **Description** | `Skill Tracker and Learning Dashboard` |
   | **Visibility** | Private |

2. Click **Advanced** and set:
   - **Version control**: Git
   - **Work item process**: Agile

3. Click **"Create project"**

[Screenshot: Create new project form with SkillPulse details]

### Step 4: Explore the Dashboard

You'll see a left sidebar with everything:

```
SkillPulse
├── Overview (Summary, Dashboards, Wiki)
├── Boards (Work Items, Boards, Backlogs, Sprints)
├── Repos (Files, Commits, Branches, Pull Requests)
├── Pipelines (Pipelines, Environments, Library)
├── Test Plans
└── Artifacts
```

Click around — Boards, Repos, Pipelines. You can't break anything yet.

[Screenshot: Left sidebar navigation]

---

## What's Next

In **[Chapter 2: Azure Boards](../02-azure-boards/)**, we'll plan the SkillPulse project — create user stories, set up a sprint, and customize our Kanban board.

---

[Back to Course Home](../../) | [Next: Chapter 2 — Azure Boards >>](../02-azure-boards/)
