# Day 05 — Azure Pipelines — CI Fundamentals (YAML)

> Goal: create a YAML pipeline that builds and validates code on every push.

---

## Objectives

By the end of this day you will:

- Understand pipelines, stages, jobs, steps, and tasks
- Write a basic azure-pipelines.yml
- Trigger CI automatically on commits and PRs
- Read pipeline logs and fix a failing run

---

## Concepts

### Pipeline anatomy

- Pipeline → Stages → Jobs → Steps (tasks/scripts)
- Agents run jobs (Microsoft-hosted: Linux, macOS, Windows)
- Triggers define when the pipeline runs

### YAML pipelines as code

- The pipeline lives in the repo as azure-pipelines.yml
- Versioned alongside app code and reviewed via PR
- Variables, templates, and conditions add flexibility

### CI mindset

- Build + test on every commit to catch issues early
- Fast feedback keeps main healthy

---

## Hands-on

1. Add an azure-pipelines.yml to the repo
2. Define a trigger on main and a single build stage
3. Push and watch the run in Pipelines
4. Break the build on purpose, read the logs, and fix it

---

## Commands / snippets

```
trigger:
  - main
pool:
  vmImage: ubuntu-latest
steps:
  - script: echo "Building..."
    displayName: Build
  - script: echo "Running tests..."
    displayName: Test
```

> Add your own notes, screenshots, and expanded examples in this section.

---

## Homework

- Add a second job that runs in parallel
- Introduce a pipeline variable and use it in a step
- Make the pipeline also trigger on pull requests

---

## Recap

- Pipelines automate build/test on every change
- YAML keeps the pipeline versioned and reviewable
- Stages/jobs/steps structure the work; agents run it
- Next: real build, test, and code-quality steps

