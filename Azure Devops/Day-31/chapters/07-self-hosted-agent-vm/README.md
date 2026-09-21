# Chapter 7: Self-Hosted Agent & Azure VM Deployment

> Set up your own Azure VM, install a self-hosted agent, and deploy SkillPulse end-to-end.

**Prerequisites**: Chapters 1-6 completed. An Azure account ([free tier](https://azure.microsoft.com/free/) works — $200 credit for 30 days).

---

## Why Self-Hosted Agents?

Microsoft-hosted agents work out of the box, but they have limits:
- **1,800 free minutes/month** — self-hosted gives you **unlimited**
- **No private network access** — self-hosted can reach internal resources
- **Cold start every run** — self-hosted keeps Docker caches, making builds faster

For SkillPulse, the agent runs on the same VM as the app. So deployment is just `docker compose up` locally — no SSH needed.

---

## Part 1: Provisioning the Azure VM

Pick one approach:

### Option A: Azure Portal

**1. Create Resource Group**

1. Go to [portal.azure.com](https://portal.azure.com)
2. Search **"Resource groups"** > **+ Create**
3. Name: `skillpulse-rg`, pick a region close to you
4. Click **Create**

[Screenshot: Resource group creation]

**2. Create Virtual Machine**

1. Search **"Virtual machines"** > **+ Create** > **Azure virtual machine**
2. Settings:

   | Setting | Value |
   |---------|-------|
   | Resource group | `skillpulse-rg` |
   | VM name | `skillpulse-vm` |
   | Image | **Ubuntu Server 22.04 LTS** |
   | Size | **Standard_B1ms** (free-tier eligible) |
   | Auth type | SSH public key |
   | Username | `azureuser` |
   | Inbound ports | HTTP (80) + SSH (22) |

3. Click **Review + create** > **Create**
4. **Download the private key** when prompted — save to `~/.ssh/skillpulse-vm_key.pem`

[Screenshot: VM creation form]

**3. Get the Public IP**

After deployment, go to the VM overview page and note the **Public IP address**.

[Screenshot: VM overview with IP highlighted]

**4. SSH In**

```bash
chmod 400 ~/.ssh/skillpulse-vm_key.pem
ssh -i ~/.ssh/skillpulse-vm_key.pem azureuser@YOUR_VM_IP
```

### Option B: Azure CLI

```bash
# Create resource group
az group create --name skillpulse-rg --location eastus

# Create VM
az vm create \
  --resource-group skillpulse-rg \
  --name skillpulse-vm \
  --image Ubuntu2204 \
  --size Standard_B1ms \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard

# Open ports
az vm open-port --resource-group skillpulse-rg --name skillpulse-vm --port 80
az vm open-port --resource-group skillpulse-rg --name skillpulse-vm --port 22 --priority 1001

# SSH in
ssh azureuser@YOUR_VM_IP
```

---

## Part 2: Setting Up the VM

Run these **on the VM** (after SSH-ing in):

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker and Docker Compose
sudo apt install -y docker.io docker-compose-v2

# Add yourself to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Git
sudo apt install -y git

# Verify
docker --version
docker compose version
```

[Screenshot: Docker version output]

### Clone and Run SkillPulse

```bash
git clone https://dev.azure.com/{your-org}/{your-project}/_git/SkillPulse
cd SkillPulse
cp .env.example .env
docker compose up -d
```

Open `http://YOUR_VM_IP` in your browser — SkillPulse should be running!

[Screenshot: SkillPulse on VM in browser]

---

## Part 3: Installing the Self-Hosted Agent

### Step 1: Create a PAT

1. Go to [dev.azure.com](https://dev.azure.com) > profile icon > **Personal access tokens**
2. Click **+ New Token**
3. Name: `self-hosted-agent`
4. Scopes: **Agent Pools — Read & manage**
5. Click **Create** and **copy the token immediately**

[Screenshot: PAT creation with Agent Pools scope]

### Step 2: Create an Agent Pool

1. Go to **Organization Settings** > **Agent pools** > **Add pool**
2. Type: **Self-hosted**
3. Name: `SelfHostedPool`
4. Check **Grant access to all pipelines**
5. Click **Create**

[Screenshot: Add agent pool dialog]

### Step 3: Download and Configure the Agent

On your VM:

```bash
cd ~
mkdir myagent && cd myagent

# Download (check https://github.com/microsoft/azure-pipelines-agent/releases for latest)
curl -O https://vstsagentpackage.azureedge.net/agent/3.248.0/vsts-agent-linux-x64-3.248.0.tar.gz
tar zxvf vsts-agent-linux-x64-3.248.0.tar.gz

# Configure
./config.sh
```

When prompted:

```
Server URL > https://dev.azure.com/{your-organization}
Auth type  > PAT
PAT        > (paste your token)
Agent pool > SelfHostedPool
Agent name > skillpulse-vm
```

### Step 4: Run as a Service

```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

Verify in Azure DevOps: **Organization Settings** > **Agent pools** > **SelfHostedPool** > **Agents** — you should see `skillpulse-vm` as **Online**.

[Screenshot: Agent showing Online in Azure DevOps]

---

## Part 4: Pipeline Using Self-Hosted Agent

Update `azure-pipelines.yml` — change `pool` and simplify deployment (no SSH needed since the agent is on the VM):

```yaml
trigger:
  - main

pool:
  name: 'SelfHostedPool'

variables:
  projectPath: '$(Build.SourcesDirectory)/project/skillpulse'

stages:
  - stage: Build
    displayName: 'Build & Test'
    jobs:
      - job: BuildJob
        displayName: 'Build SkillPulse'
        steps:
          - script: |
              cd $(projectPath)
              docker compose build
            displayName: 'Build Docker images'

          - script: |
              cd $(projectPath)/backend
              go test ./... -v
            displayName: 'Run Go tests'

  - stage: Deploy
    displayName: 'Deploy to VM'
    dependsOn: Build
    jobs:
      - deployment: DeployJob
        displayName: 'Deploy SkillPulse'
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self

                - script: |
                    cd $(projectPath)
                    cp .env.example .env
                    docker compose down
                    docker compose up -d --build
                  displayName: 'Deploy with Docker Compose'

                - script: |
                    sleep 15
                    curl -f http://localhost/health || exit 1
                    echo "Health check passed!"
                  displayName: 'Health check'
```

Notice: no SSH task. The pipeline runs **on the VM itself**, so `docker compose up` happens locally.

```bash
git add azure-pipelines.yml
git commit -m "Use self-hosted agent for deployment"
git push origin main
```

Watch the pipeline run on your VM. When it finishes, open `http://YOUR_VM_IP` — deployed!

[Screenshot: Pipeline running on self-hosted agent]

---

## Cleanup: Don't Get Charged!

### Delete everything (when done with course)

```bash
az group delete --name skillpulse-rg --yes --no-wait
```

### Or just stop the VM (to resume later)

```bash
az vm deallocate --resource-group skillpulse-rg --name skillpulse-vm
# Start again later:
az vm start --resource-group skillpulse-rg --name skillpulse-vm
```

> The public IP may change after restart. Also revoke your PAT when done: Azure DevOps > Personal access tokens > Revoke.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Docker permission denied | `sudo usermod -aG docker $USER && newgrp docker` |
| Agent shows Offline | `cd ~/myagent && sudo ./svc.sh start` |
| Can't connect during config | Check your org URL and PAT |
| Port 80 not accessible | Check Azure NSG rules, verify Nginx is running |
| "No space left on device" | `docker system prune -a` |

---

## What's Next

In **[Chapter 8: Artifacts, Dashboards & Security](../08-artifacts-advanced/)**, we'll explore Azure Artifacts, build a project dashboard, and lock down the project with security best practices.

---

[<< Previous: Chapter 6 — Pipelines CD](../06-pipelines-cd/) | [Next: Chapter 8 — Artifacts & Advanced >>](../08-artifacts-advanced/)
