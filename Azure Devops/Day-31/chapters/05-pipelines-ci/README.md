# Chapter 5: Azure Pipelines — Continuous Integration (CI)

> Automate your builds. Every push gets compiled, tested, and validated — no more "it works on my machine."

**Prerequisites**: Chapters 1-4 completed, SkillPulse code pushed to Azure Repos.

---

## What is Azure Pipelines?

Azure Pipelines is the CI/CD engine in Azure DevOps. You define steps in a YAML file, and it runs them automatically every time someone pushes code.

Without CI, bugs hide. Someone changes a file, forgets to test, pushes to `main`, and the app breaks. CI catches that within minutes.

---

## YAML vs Classic Pipelines

Azure DevOps offers two types:

- **YAML pipelines** — Defined in a `.yml` file in your repo. Version-controlled, reviewable in PRs, portable. This is what we'll use.
- **Classic pipelines** — Configured in the web UI with drag-and-drop. Legacy, not recommended for new projects.

YAML is the industry standard. GitHub Actions, GitLab CI, CircleCI — they all use YAML. What you learn here transfers directly.

---

## Pipeline Anatomy

A YAML pipeline has a clear hierarchy:

```
Pipeline
  ├── trigger     → When does it run?
  ├── pool        → Where does it run?
  └── stages
       └── jobs
            └── steps  → Individual commands
```

### Trigger

When to run the pipeline:

```yaml
trigger:
  branches:
    include:
      - main
```

### Pool

Which machine runs it:

```yaml
pool:
  vmImage: 'ubuntu-latest'    # Microsoft-hosted
  # OR
  name: 'SelfHostedPool'      # Your own VM (Chapter 7)
```

### Steps

Two types: **tasks** (pre-built from marketplace) and **scripts** (your own commands):

```yaml
steps:
  - task: GoTool@0
    inputs:
      version: '1.22'
    displayName: 'Install Go'

  - script: go build -o myapp .
    displayName: 'Build the app'
```

---

## Microsoft-hosted vs Self-hosted Agents

| | Microsoft-hosted | Self-hosted |
|---|---|---|
| **Setup** | Zero — just works | You install and maintain |
| **Minutes** | 1,800 free/month | Unlimited |
| **Environment** | Fresh VM every run | Persistent (faster, cached) |
| **Network** | Public internet only | Can access private resources |

We'll use **Microsoft-hosted** (`ubuntu-latest`) for now. In Chapter 7, we switch to self-hosted.

---

## Hands-on: Creating the CI Pipeline

### Step 1: Create the Pipeline

1. Go to **Pipelines** > **Pipelines** > **Create Pipeline**
2. Select **Azure Repos Git**
3. Select your SkillPulse repository
4. Choose **Starter pipeline**

[Screenshot: "Where is your code?" screen]

### Step 2: Write the Pipeline YAML

Replace the starter content with:

```yaml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

stages:
  - stage: Build
    displayName: 'Build & Test'
    jobs:
      - job: BuildJob
        displayName: 'Build SkillPulse'
        steps:
          - task: GoTool@0
            inputs:
              version: '1.22'
            displayName: 'Install Go'

          - script: |
              cd project/skillpulse/backend
              go mod download
              go build -o skillpulse .
            displayName: 'Build Go Backend'

          - script: |
              cd project/skillpulse/backend
              go test ./... -v
            displayName: 'Run Tests'

          - script: |
              cd project/skillpulse
              docker-compose build
            displayName: 'Build Docker Images'
```

> Adjust the `cd` paths if your repo structure is different.

[Screenshot: YAML editor with pipeline code]

### Step 3: Save and Run

1. Click **Save and run**
2. Commit message: `Add SkillPulse CI pipeline`
3. Commit to `main`

Watch each step execute in real-time. Green checkmarks = success.

[Screenshot: Successful pipeline run with all green checkmarks]

If something fails, read the error in the logs. Fix it, push again — the pipeline re-runs automatically.

---

## Pipeline Variables

Don't hardcode values. Use variables instead.

### Inline Variables

```yaml
variables:
  GO_VERSION: '1.22'
  DOCKER_IMAGE_NAME: 'skillpulse-backend'

steps:
  - task: GoTool@0
    inputs:
      version: $(GO_VERSION)
```

### Secret Variables

For passwords and API keys — never put these in YAML.

1. Go to your pipeline > **Edit** > **Variables** (top-right)
2. Add variable, check **Keep this value secret**
3. Reference as `$(DB_PASSWORD)` in YAML — it shows `***` in logs

### Variable Groups

Share variables across multiple pipelines:

1. Go to **Pipelines** > **Library** > **+ Variable group**
2. Name it `skillpulse-secrets`, add your variables
3. Reference in YAML:

```yaml
variables:
  - group: skillpulse-secrets
```

[Screenshot: Variable group in Library]

---

## Viewing Build Results

After each run, check:
- **Status** — Green (passed), Red (failed)
- **Step logs** — Click any step for detailed output
- **Build history** — Spot patterns (builds started failing on Tuesday? Check what changed)
- **Work item links** — Include `#42` in commit messages to auto-link builds to work items

[Screenshot: Pipeline run summary]

---

## Tips

- **Pin tool versions** — Use `version: '1.22'`, not `latest`. Prevents surprise breakages.
- **Use displayName on every step** — Makes debugging much easier when a step fails.
- **Fail fast** — Put quick checks (lint) first, slow checks (docker build) last.
- **Cache dependencies** — Use `Cache@2` task for Go modules to speed up builds.
- **Add build validation** to branch policies — Go to Repos > Branch policies for `main` > Build validation > Add your CI pipeline. Now broken code can't be merged.

---

## What's Next

In **[Chapter 6: Azure Pipelines — CD](../06-pipelines-cd/)**, we'll add a Deploy stage so every merge to `main` automatically ships to your server.

---

[<< Previous: Chapter 4 — Building SkillPulse](../04-building-skillpulse/) | [Next: Chapter 6 — Azure Pipelines CD >>](../06-pipelines-cd/)
