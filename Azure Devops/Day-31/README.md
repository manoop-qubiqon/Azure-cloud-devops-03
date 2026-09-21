# Azure DevOps Zero to Hero

> A complete, beginner-friendly course to master Azure DevOps — from planning to deployment.

Build, test, and deploy a real-world application using every core Azure DevOps service. By the end of this course, you'll have a fully working CI/CD pipeline that deploys a containerized app to an Azure VM.

## What You'll Learn

- Set up an Azure DevOps organization and project from scratch
- Plan work using **Azure Boards** (Kanban, sprints, user stories)
- Manage code with **Azure Repos** (Git, PRs, branch policies)
- Build CI/CD pipelines with **Azure Pipelines** (YAML, multi-stage)
- Deploy to an **Azure VM** using a **self-hosted agent**
- Containerize apps with **Docker** and **Docker Compose**
- Explore **Azure Artifacts**, **Test Plans**, dashboards, and security
- (Bonus) Provision infrastructure with **Terraform**

## The Project: SkillPulse

Throughout this course, we build **SkillPulse** — a Skill Tracker / Learning Dashboard where you can:

- Track skills you're learning (Docker, Kubernetes, Terraform, Go, etc.)
- Log study sessions with hours and notes
- View your progress with visual dashboards

**Think of it as your personal GitHub contribution graph, but for learning.**

### Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend | Go (Gin framework) |
| Frontend | HTML / CSS / JavaScript |
| Database | MySQL 8.0 |
| Web Server | Nginx (reverse proxy) |
| Containers | Docker + Docker Compose |
| CI/CD | Azure Pipelines (YAML) |
| Deployment | Azure VM + Self-hosted Agent |

## Prerequisites

- A free [Azure DevOps account](https://dev.azure.com) (we'll set this up in Chapter 1)
- A free [Azure account](https://azure.microsoft.com/free/) (for the VM in Chapter 7)
- Basic familiarity with Git (clone, commit, push)
- Basic understanding of what Docker does (we'll cover the rest)
- A code editor (VS Code recommended)
- A terminal (any OS works — Windows, macOS, Linux)

**No prior Azure or Azure DevOps experience needed. We start from zero.**

## Course Structure

| Chapter | Title | Duration | What You'll Do |
|---------|-------|----------|---------------|
| 01 | [Introduction to Azure & Azure DevOps](chapters/01-intro-azure-devops/) | 15-20 min | Sign up, create your first project |
| 02 | [Azure Boards — Planning Your Project](chapters/02-azure-boards/) | 15-20 min | Create backlog, sprints, Kanban board |
| 03 | [Azure Repos — Version Control](chapters/03-azure-repos/) | 15-20 min | Push code, set branch policies, create PRs |
| 04 | [Building SkillPulse](chapters/04-building-skillpulse/) | 20-25 min | Build the app locally with Docker Compose |
| 05 | [Azure Pipelines — CI (Build & Test)](chapters/05-pipelines-ci/) | 20-25 min | Create your first CI pipeline |
| 06 | [Azure Pipelines — CD (Deploy)](chapters/06-pipelines-cd/) | 20-25 min | Add deployment stages, environments, approvals |
| 07 | [Self-Hosted Agent & Azure VM Deployment](chapters/07-self-hosted-agent-vm/) | 20-25 min | Set up VM, install agent, deploy end-to-end |
| 08 | [Artifacts & Advanced Features](chapters/08-artifacts-advanced/) | 15-20 min | Artifacts, Test Plans, dashboards, security |
| 09 | [Putting It All Together](chapters/09-complete-workflow/) | 15-20 min | Full workflow demo with a new feature |
| Bonus | [Infrastructure as Code with Terraform](chapters/bonus-terraform/) | 15-20 min | Provision Azure VM with Terraform |

**Total Duration: ~2.5-3 hours**

## Azure DevOps Free Tier

Good news — you can complete this entire course on the **free tier**:

| Resource | Free Allowance |
|----------|---------------|
| Users (Basic plan) | First 5 users free |
| Private Git repos | Unlimited |
| CI/CD (Microsoft-hosted) | 1 parallel job, 1,800 min/month |
| CI/CD (Self-hosted) | 1 parallel job, unlimited minutes |
| Azure Artifacts | 2 GiB free storage |
| Boards & Work Tracking | Included |

## Repository Structure

```
azure-devops-zero-to-hero/
├── README.md                    # You are here
├── chapters/
│   ├── 01-intro-azure-devops/   # Chapter READMEs with step-by-step guides
│   ├── 02-azure-boards/
│   ├── 03-azure-repos/
│   ├── 04-building-skillpulse/
│   ├── 05-pipelines-ci/
│   ├── 06-pipelines-cd/
│   ├── 07-self-hosted-agent-vm/
│   ├── 08-artifacts-advanced/
│   ├── 09-complete-workflow/
│   └── bonus-terraform/
├── project/
│   ├── skillpulse/              # The SkillPulse application
│   │   ├── backend/             # Go (Gin) REST API
│   │   ├── frontend/            # HTML/CSS/JS dashboard
│   │   ├── nginx/               # Nginx reverse proxy config
│   │   ├── mysql/               # Database init scripts
│   │   ├── docker-compose.yml
│   │   └── .env.example
│   └── azure-pipelines.yml      # CI/CD pipeline definition
├── scripts/
│   ├── setup-vm.sh              # Azure VM provisioning helper
│   └── install-agent.sh         # Self-hosted agent setup
└── bonus/
    └── terraform/               # Terraform IaC files
```

## How to Use This Course

1. **Follow in order** — Each chapter builds on the previous one
2. **Read the README first** — Every chapter has detailed step-by-step instructions
3. **Do the hands-on** — Don't just read, actually create the resources in Azure DevOps
4. **Use the SkillPulse project** — Clone it, modify it, break it, fix it
5. **Check the free tier** — Everything in this course works on Azure DevOps free tier


## Quick Links

- [Azure DevOps Documentation](https://learn.microsoft.com/en-us/azure/devops/?view=azure-devops)
- [Azure DevOps Pricing](https://azure.microsoft.com/en-us/pricing/details/devops/azure-devops-services/)
- [Azure Free Account](https://azure.microsoft.com/free/)
- [Go Documentation](https://go.dev/doc/)
- [Docker Documentation](https://docs.docker.com/)

---

**Ready to start? Head to [Chapter 1: Introduction to Azure & Azure DevOps](chapters/01-intro-azure-devops/).**
