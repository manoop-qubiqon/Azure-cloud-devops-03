# Chapter 6: Azure Pipelines — Continuous Deployment (CD)

> You built it. You tested it. Now let's ship it — automatically.

**Prerequisites**: Chapters 1-5 completed (working CI pipeline). An Azure VM with Docker is helpful but not required — you can follow along conceptually and wire it up in Chapter 7.

---

## What is Continuous Deployment?

CI builds and tests your code. CD **deploys** it. Together, the workflow becomes:

```
Code Push → CI (Build + Test) → CD (Deploy) → App Running
```

No more SSH-ing into servers. No more manual `git pull` and `docker-compose up`. Push code, pipeline handles the rest.

---

## Multi-Stage Pipelines

In Chapter 5, we had one stage (Build). Now we add a second (Deploy):

```yaml
stages:
  - stage: Build       # Compile, test
  - stage: Deploy      # Ship to server
    dependsOn: Build   # Only runs if Build passes
```

Separating stages gives you visibility (where is it?), control (deploy only if tests pass), and approval gates (human sign-off before production).

---

## Environments and Approvals

An **environment** represents a deployment target (dev, staging, production). It gives you deployment history and approval gates.

### Create the Production Environment

1. Go to **Pipelines** > **Environments** > **Create environment**
2. Name: `production`
3. Resource: **None** (for now)
4. Click **Create**

[Screenshot: Create environment dialog]

### Add Approval Gate

1. On the `production` environment page, click **...** > **Approvals and checks**
2. Click **+ Add check** > **Approvals**
3. Add yourself as approver
4. Click **Create**

Now the pipeline will pause at Deploy and wait for your approval before shipping.

[Screenshot: Approval configuration]

---

## Service Connections

A **service connection** stores credentials securely so your pipeline can connect to external resources (VMs, cloud accounts, Docker registries).

### Create an SSH Connection

1. Go to **Project Settings** > **Service connections** > **New service connection**
2. Select **SSH**
3. Fill in:
   - **Host name**: Your VM's public IP
   - **Port**: 22
   - **Username**: `azureuser`
   - **Private key**: Paste your SSH key
   - **Name**: `SkillPulse-VM`
   - **Grant access to all pipelines**: Check
4. Click **Save**

[Screenshot: SSH service connection form]

---

## Deployment Strategies

| Strategy | How It Works | Use When |
|----------|-------------|----------|
| **runOnce** | Deploy everything at once | Single server, small projects (what we use) |
| **rolling** | Deploy to a few servers at a time | Multi-server setups |
| **canary** | Route small % of traffic to new version first | Large-scale production |

For SkillPulse with one VM, `runOnce` is perfect.

---

## Hands-on: Adding the Deploy Stage

Update your `azure-pipelines.yml` with the full multi-stage pipeline:

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
        steps:
          - task: GoTool@0
            inputs:
              version: '1.22'

          - script: |
              cd project/skillpulse/backend
              go mod download
              go build -o skillpulse .
            displayName: 'Build Go Backend'

          - script: |
              cd project/skillpulse/backend
              go test ./... -v
            displayName: 'Run Tests'

  - stage: Deploy
    displayName: 'Deploy to Azure VM'
    dependsOn: Build
    condition: succeeded()
    jobs:
      - deployment: DeployToVM
        displayName: 'Deploy SkillPulse'
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: SSH@0
                  inputs:
                    sshEndpoint: 'SkillPulse-VM'
                    runOptions: 'inline'
                    inline: |
                      cd /opt/skillpulse
                      git pull origin main
                      docker-compose down
                      docker-compose up -d --build
                  displayName: 'Deploy via SSH'
```

Key things in the Deploy stage:
- **`dependsOn: Build`** — waits for Build to finish
- **`condition: succeeded()`** — skips if Build failed
- **`deployment`** — special job type (not `job`) with environment support
- **`environment: 'production'`** — triggers the approval gate
- **`task: SSH@0`** — connects to VM using the service connection

### Push and Watch

```bash
git add azure-pipelines.yml
git commit -m "Add CD stage to deploy SkillPulse to Azure VM"
git push origin main
```

Watch the Build stage pass, then the pipeline **pauses** at Deploy — "Waiting for review."

[Screenshot: Pipeline paused at Deploy stage]

Click **Review** > **Approve**. The Deploy stage runs, SSHs into your VM, and deploys.

### Verify

- Browser: `http://<your-vm-ip>` → SkillPulse dashboard
- SSH: `docker ps` → 3 running containers
- Health: `curl http://<your-vm-ip>/health` → `{"status": "ok"}`

[Screenshot: SkillPulse running on VM]

Check deployment history at **Pipelines** > **Environments** > **production**.

---

## Tips

- **Add a health check** after deployment: `curl --fail http://localhost/health || exit 1`
- **Keep deployment scripts simple** — if they get complex, move them to a shell script
- **Never deploy without tests** — keep `dependsOn: Build` always
- **Use separate environments**: dev (auto-deploy), staging (auto-deploy), production (approval required)

---

## What's Next

In **[Chapter 7: Self-Hosted Agent & Azure VM](../07-self-hosted-agent-vm/)**, we'll provision the Azure VM from scratch, install a self-hosted agent, and simplify deployment — no SSH needed when the agent runs on the same machine.

---

[<< Previous: Chapter 5 — Pipelines CI](../05-pipelines-ci/) | [Next: Chapter 7 — Self-Hosted Agent & VM >>](../07-self-hosted-agent-vm/)
