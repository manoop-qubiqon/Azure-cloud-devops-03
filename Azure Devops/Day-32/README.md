# Azure DevOps — Zero to Hero (Day-wise Course)

A structured, hands-on path through Azure DevOps. Each day is a **separate `.md` file** you can teach, edit, and expand independently. Days build on each other, moving from fundamentals to a full end-to-end CI/CD project.

---

## How this course is organised

Each day file follows the same structure so it's easy to teach and extend:

- **Objectives** — what you'll be able to do by the end of the day
- **Concepts** — the theory, explained plainly
- **Hands-on** — step-by-step practical work
- **Commands / snippets** — copy-paste reference
- **Homework** — a task to reinforce the day
- **Recap** — the key takeaways

> Prefer modern command syntax throughout (e.g. `git switch` over `git checkout`, `docker container run` over `docker run`).

---

## Curriculum at a glance

| Day | Topic | File |
|-----|-------|------|
| 00 | Prerequisites & environment setup | [day-00-setup.md](day-00-setup.md) |
| 01 | DevOps fundamentals & Azure DevOps overview | [day-01-devops-fundamentals.md](day-01-devops-fundamentals.md) |
| 02 | Azure Boards — plan & track work | [day-02-azure-boards.md](day-02-azure-boards.md) |
| 03 | Azure Repos & Git essentials | [day-03-azure-repos.md](day-03-azure-repos.md) |
| 04 | Pull requests, branch policies & code review | [day-04-pull-requests.md](day-04-pull-requests.md) |
| 05 | Azure Pipelines — CI fundamentals (YAML) | [day-05-pipelines-ci.md](day-05-pipelines-ci.md) |
| 06 | Build, test & code quality in pipelines | [day-06-build-test.md](day-06-build-test.md) |
| 07 | Azure Artifacts & package management | [day-07-artifacts.md](day-07-artifacts.md) |
| 08 | Containers — Docker & Azure Container Registry | [day-08-docker-acr.md](day-08-docker-acr.md) |
| 09 | Continuous Delivery — environments & releases | [day-09-cd-releases.md](day-09-cd-releases.md) |
| 10 | Deploy to Azure Kubernetes Service (AKS) | [day-10-aks-deploy.md](day-10-aks-deploy.md) |
| 11 | Infrastructure as Code — Terraform & Bicep | [day-11-iac.md](day-11-iac.md) |
| 12 | Security, monitoring & the capstone project | [day-12-security-monitoring-capstone.md](day-12-security-monitoring-capstone.md) |

---

## Suggested learning tracks

- **Fast overview (1 day):** Day 01 + Day 05
- **Developer track (1 week):** Days 01–07
- **Full DevOps track (2 weeks):** Days 00–12
- **Data engineering focus:** Days 01, 03, 04, 05, 11 (version-control dbt/PySpark/ADF, automate deployments with Pipelines + Terraform/Bicep)

---

## What you'll build

By the end you'll have a working **CI/CD pipeline** that takes code from a developer commit all the way to production on AKS:

```
Developer → Boards → Repos (Git) → Pull Request → Code Review →
Pipelines → Build → Test → Security Scan → Docker Build → ACR → AKS → Production
```

---

## Prerequisites

- An Azure DevOps organisation (free at [dev.azure.com](https://dev.azure.com))
- An Azure subscription (free tier is enough for most days)
- Git, a code editor (VS Code recommended), and Docker installed locally

See [day-00-setup.md](day-00-setup.md) to get everything ready.
