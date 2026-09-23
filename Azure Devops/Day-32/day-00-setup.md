# Day 00 — Prerequisites & Environment Setup

> Goal: get every tool installed and every account ready so the rest of the course is friction-free.

---

## Objectives

By the end of this day you will:

- Have an Azure DevOps organisation and your first project
- Have an Azure subscription ready
- Have Git, VS Code, Docker, and the Azure CLI installed and verified
- Understand how the pieces connect

---

## Concepts

Azure DevOps is a **SaaS platform** — you access it in the browser at `dev.azure.com`. To do real work you also need:

- **Git** — the version control client on your machine
- **A code editor** — VS Code is recommended and integrates well
- **Azure CLI (`az`)** — command-line access to Azure resources
- **Docker** — to build and run containers locally (used from Day 08)

An **organisation** contains one or more **projects**. A project bundles Boards, Repos, Pipelines, Test Plans, and Artifacts for one product or team.

---

## Hands-on

### 1. Create an Azure DevOps organisation

1. Go to [dev.azure.com](https://dev.azure.com) and sign in with a Microsoft account.
2. Create a new organisation (pick a region close to you).
3. Create your first project — name it `zero-to-hero`, visibility **Private**.

### 2. Get an Azure subscription

- Sign up for a free Azure account at [azure.microsoft.com/free](https://azure.microsoft.com/free) if you don't have one.
- The free tier + credits cover almost everything in this course.

### 3. Install the tools

| Tool | Verify with |
|------|-------------|
| Git | `git --version` |
| VS Code | open it, install the "Azure Repos" extension |
| Azure CLI | `az --version` |
| Docker | `docker --version` |
| kubectl | `kubectl version --client` |

### 4. Log in from the CLI

```bash
az login                     # opens a browser to authenticate
az account show              # confirm the active subscription
```

---

## Commands / snippets

```bash
# Configure your Git identity (once per machine)
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"

# Use 'main' as the default branch name for new repos
git config --global init.defaultBranch main

# Confirm everything is installed
git --version
az --version
docker --version
kubectl version --client
```

---

## Homework

- Create the `zero-to-hero` project in Azure DevOps.
- Run every command in the verify table and confirm no errors.
- Explore the left-hand menu: Overview, Boards, Repos, Pipelines, Test Plans, Artifacts.

---

## Recap

- Azure DevOps lives in the browser; your local tools (Git, Docker, Azure CLI) do the heavy lifting.
- An **organisation → project** hierarchy holds all five services.
- With accounts and tools verified, you're ready to learn the fundamentals on Day 01.
