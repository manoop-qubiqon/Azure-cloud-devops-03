# Day 01 — DevOps Fundamentals & Azure DevOps Overview

> Goal: understand what DevOps is, why it matters, and how Azure DevOps supports the full lifecycle.

---

## Objectives

By the end of this day you will:

- Explain DevOps as people + process + technology
- Describe the continuous delivery lifecycle
- Name the five Azure DevOps services and what each does
- See how the services map onto the DevOps lifecycle

---

## Concepts

### What is DevOps?

DevOps is the union of **people, processes, and technology** to continuously deliver value to end users. It is an Agile methodology that improves both deployment and the ongoing maintenance of what a team builds.

Rather than separate hand-offs between "dev" and "ops", DevOps ties the whole flow into one continuous loop:

```
Plan & Track → Develop → Build & Test → Deploy → Operate → Monitor & Learn → (repeat)
```

The aim is **continuous delivery** — small, frequent, reliable releases instead of large, risky ones.

### Why DevOps?

- Speed up software release times
- Improve code quality
- Guarantee greater stability and security
- Standardise the infrastructure
- Automate distributions
- Test applications across environments
- Increase the overall success rate of delivery

### What is Azure DevOps?

Azure DevOps is Microsoft's complete solution for managing software projects — an entire ecosystem of services spanning requirements gathering all the way to release and production monitoring. It works with any language, any platform, and any cloud, and integrates with GitHub and other Git providers.

---

## The five core services

| Service | Purpose | Lifecycle stage |
|---------|---------|-----------------|
| **Azure Boards** | Plan and track work (Kanban, backlogs, sprints) | Plan & track |
| **Azure Repos** | Private Git repos, pull requests, code search | Code |
| **Azure Pipelines** | CI/CD for any language, platform, or cloud | Build, test, deploy |
| **Azure Test Plans** | Planned and exploratory testing | Test |
| **Azure Artifacts** | Package management (Maven, npm, NuGet, Python) | Build & release |

---

## Hands-on

1. Open your `zero-to-hero` project.
2. Click through each of the five services in the left menu and note what each landing page shows.
3. In **Overview → Summary**, add a short project description.
4. In **Boards**, look at the default board columns (New / Active / Resolved / Closed).

No code yet — today is about the mental model. From Day 02 you'll start using each service in turn.

---

## Commands / snippets

No CLI today. One thing worth bookmarking:

```
Developer → Boards → Repos → Pull Request → Code Review →
Pipelines → Build → Test → Security Scan → Docker → ACR → AKS → Production
```

This is the end-to-end flow you'll build across the course.

---

## Homework

- In your own words, write a 3-sentence definition of DevOps.
- Map each of the five services to a stage in the lifecycle loop.
- List which two services you expect to use most in your day job, and why.

---

## Recap

- DevOps = people + process + technology in one continuous delivery loop.
- Azure DevOps is Microsoft's complete platform for the whole software lifecycle.
- The five services — Boards, Repos, Pipelines, Test Plans, Artifacts — can be used together or independently.
- Next: **Azure Boards**, to plan and track the work.
