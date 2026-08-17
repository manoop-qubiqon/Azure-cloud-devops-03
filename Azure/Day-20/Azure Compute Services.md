# Azure Compute Services — Notes + Practice Tasks

---

## 1. Virtual Machines (VMs)

A VM is an **IaaS** resource — Azure gives you raw compute; you manage the OS, runtime, and everything above it.

### VM Sizes

Azure organises VM sizes into **families** based on workload type:

| Family | Series | Best For |
|---|---|---|
| General Purpose | B, D, Dsv | Web servers, dev/test, small DBs |
| Compute Optimised | F | CPU-heavy workloads, batch jobs |
| Memory Optimised | E, M | Large databases, in-memory analytics |
| Storage Optimised | L | High disk I/O, NoSQL DBs |
| GPU | N | ML training, rendering, video encoding |

**Size naming format:** `Standard_D4s_v3`
- `Standard` = pricing tier
- `D` = family (general purpose)
- `4` = vCPU count
- `s` = supports Premium SSD
- `v3` = version

### OS Images

When creating a VM, you pick an **image** — a pre-built OS template from the Azure Marketplace.

| Image | Use Case |
|---|---|
| Ubuntu 22.04 LTS | Linux workloads, Docker, data engineering |
| Windows Server 2022 | .NET apps, AD, SQL Server |
| CentOS / RHEL | Enterprise Linux apps |
| Custom Image | Your own pre-configured base image |

### Disks

Every VM has at least two disks:

| Disk Type | Description |
|---|---|
| **OS Disk** | Boots the VM; persistent; usually 30–128 GB |
| **Temporary Disk** | Local SSD on the host; fast but **data is lost on VM stop/restart** |
| **Data Disk** | Attach extra managed disks for app data; persistent |

**Managed Disk tiers (performance vs cost):**

```
Standard HDD → cheapest, dev/test
Standard SSD → web servers, light workloads
Premium SSD  → production databases, high IOPS
Ultra Disk   → mission-critical, sub-ms latency
```

### Example: Create a VM via Azure CLI

```bash
# Create a resource group
az group create --name demo-rg --location eastus

# Create a VM
az vm create \
  --resource-group demo-rg \
  --name my-ubuntu-vm \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys

# Open port 22 for SSH
az vm open-port --port 22 --resource-group demo-rg --name my-ubuntu-vm

# SSH into the VM
ssh azureuser@<public-ip>

# Stop VM (deallocate = stop billing for compute)
az vm deallocate --resource-group demo-rg --name my-ubuntu-vm
```

> **Key concept:** `stop` vs `deallocate` — `stop` keeps the VM allocated (still billed), `deallocate` releases the compute (not billed). Always **deallocate** dev VMs when not in use.

---

## 2. VM Scale Sets (VMSS)

A **VM Scale Set** is a group of **identical VMs** that can automatically scale in/out based on demand. All VMs in the set run the same OS image and config.

### How Auto-Scaling Works

```
Load increases → CPU metric crosses threshold
      ↓
Scale-out rule fires → Azure adds new VM instances
      ↓
Load decreases → Scale-in rule fires → instances removed
```

### Key Concepts

| Concept | Details |
|---|---|
| **Min / Max instances** | Floor and ceiling for the number of VMs |
| **Scale-out rule** | Condition to add VMs (e.g., CPU > 75% for 5 min) |
| **Scale-in rule** | Condition to remove VMs (e.g., CPU < 30% for 10 min) |
| **Cooldown period** | Wait time between scaling actions (prevents thrashing) |
| **Uniform vs Flexible** | Uniform = identical VMs; Flexible = mix of VM sizes/configs |
| **Load Balancer** | Sits in front of the scale set; distributes traffic across all instances |

### Example: Create a Scale Set via CLI

```bash
# Create a VM Scale Set
az vmss create \
  --resource-group demo-rg \
  --name my-scaleset \
  --image Ubuntu2204 \
  --vm-sku Standard_B2s \
  --instance-count 2 \
  --admin-username azureuser \
  --generate-ssh-keys

# Add auto-scale rule: scale out when CPU > 70%
az monitor autoscale create \
  --resource-group demo-rg \
  --resource my-scaleset \
  --resource-type Microsoft.Compute/virtualMachineScaleSets \
  --name autoscale-rule \
  --min-count 2 \
  --max-count 10 \
  --count 2

# Scale out: add 2 instances when CPU > 70%
az monitor autoscale rule create \
  --resource-group demo-rg \
  --autoscale-name autoscale-rule \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 2

# Scale in: remove 1 instance when CPU < 30%
az monitor autoscale rule create \
  --resource-group demo-rg \
  --autoscale-name autoscale-rule \
  --condition "Percentage CPU < 30 avg 5m" \
  --scale in 1
```

---

## 3. Azure App Service

App Service is a **PaaS** web hosting platform — you deploy your app (code or container); Azure manages the OS, runtime, patching, and scaling.

### Supported Runtimes

- Node.js, Python, Java, .NET, PHP, Ruby
- Custom Docker containers

### App Service Plans (Pricing Tiers)

| Tier | Use Case | Features |
|---|---|---|
| Free / Shared | Dev/test only | No SLA, shared infrastructure |
| Basic (B1–B3) | Dev/test with dedicated compute | Manual scale only |
| Standard (S1–S3) | Production | Auto-scale, custom domains, SSL |
| Premium (P1–P3) | High-traffic production | VNet integration, more scale |
| Isolated | Regulated industries | Dedicated environment (ASE) |

> The **App Service Plan** defines the region, OS, and VM size. Multiple apps can share one plan (share the same compute).

### Example: Deploy a Python Web App

```bash
# Create an App Service Plan (Linux, Standard tier)
az appservice plan create \
  --name my-app-plan \
  --resource-group demo-rg \
  --sku S1 \
  --is-linux

# Create the Web App
az webapp create \
  --resource-group demo-rg \
  --plan my-app-plan \
  --name my-python-app-12345 \
  --runtime "PYTHON:3.11"

# Deploy code from local folder using zip deploy
zip -r app.zip .
az webapp deployment source config-zip \
  --resource-group demo-rg \
  --name my-python-app-12345 \
  --src app.zip

# Check the app URL
az webapp show \
  --resource-group demo-rg \
  --name my-python-app-12345 \
  --query defaultHostName
```

Your app runs at: `https://my-python-app-12345.azurewebsites.net`

---

## 4. Azure Functions (Serverless Compute)

Azure Functions lets you run **small pieces of code (functions)** without managing any server. You pay only for the time your code actually runs.

### Key Concepts

| Concept | Details |
|---|---|
| **Trigger** | What starts the function (HTTP request, timer, queue message, blob upload, etc.) |
| **Binding** | Declarative way to connect inputs/outputs (e.g., read from Blob, write to Cosmos DB) |
| **Hosting Plan** | Consumption (serverless) / Premium / Dedicated |
| **Cold Start** | First invocation after idle period takes slightly longer to start |

### Hosting Plans Comparison

| Plan | Billing | Scale | Cold Start |
|---|---|---|---|
| **Consumption** | Per execution | Auto, to zero | Yes |
| **Premium** | Per second (pre-warmed) | Auto, no zero scale | No |
| **Dedicated (App Service)** | Fixed monthly | Manual / auto | No |

### Common Trigger Types

```
HTTP Trigger      → REST API endpoint
Timer Trigger     → cron schedule (e.g., run every day at midnight)
Blob Trigger      → fires when a file lands in Azure Storage
Queue Trigger     → fires when a message appears in a Storage Queue
Event Hub Trigger → fires on streaming events (data pipelines)
```

### Example: HTTP Trigger Function (Python)

```python
# function_app.py
import azure.functions as func
import logging

app = func.FunctionApp()

@app.route(route="hello", methods=["GET"])
def hello_function(req: func.HttpRequest) -> func.HttpResponse:
    name = req.params.get("name", "World")
    logging.info(f"Triggered for: {name}")
    return func.HttpResponse(f"Hello, {name}!", status_code=200)
```

```bash
# Deploy using Azure Functions Core Tools
func init my-function-app --python
cd my-function-app
func new --name hello --template "HTTP trigger"

# Run locally
func start

# Deploy to Azure
func azure functionapp publish my-function-app
```

### Data Engineering Use Case

```
Blob Trigger Function:
  ├── New CSV lands in raw/ container in Azure Storage
  ├── Function fires automatically
  ├── Reads the CSV, validates schema
  └── Writes clean data to processed/ container
        or triggers an ADF pipeline
```

---

## 5. Azure Container Instances (ACI)

ACI lets you run **Docker containers directly in Azure** — no VM to manage, no Kubernetes cluster needed. Fastest way to get a container running in the cloud.

### ACI vs Other Container Options

| Feature | ACI | App Service (Container) | AKS |
|---|---|---|---|
| Setup complexity | Very low | Low | High |
| Auto-scaling | No | Yes | Yes |
| Orchestration | No | Basic | Full Kubernetes |
| Best for | Short tasks, batch jobs, dev/test | Web apps | Production microservices |
| Billing | Per second | Per hour (plan) | Per node/hour |

### Key Concepts

| Concept | Details |
|---|---|
| **Container Group** | One or more containers that share networking and storage (like a pod in Kubernetes) |
| **Public / Private image** | Pull from Docker Hub, ACR (Azure Container Registry), or any registry |
| **Restart policy** | Always / OnFailure / Never — controls what happens after the container exits |
| **Environment variables** | Pass config to your container at runtime |
| **Volume mounts** | Mount Azure File Shares into the container |

### Example: Run a Container in ACI

```bash
# Run a simple nginx container — public IP, port 80
az container create \
  --resource-group demo-rg \
  --name my-container \
  --image nginx:latest \
  --ports 80 \
  --dns-name-label my-nginx-demo \
  --os-type Linux

# Check status
az container show \
  --resource-group demo-rg \
  --name my-container \
  --query "{Status:instanceView.state, FQDN:ipAddress.fqdn}" \
  --output table

# View logs
az container logs \
  --resource-group demo-rg \
  --name my-container

# Delete when done
az container delete \
  --resource-group demo-rg \
  --name my-container --yes
```

Your app is live at: `http://my-nginx-demo.<region>.azurecontainer.io`

### Data Engineering Use Case

```bash
# Run a one-off Python ETL job as a container
az container create \
  --resource-group demo-rg \
  --name etl-job \
  --image myacr.azurecr.io/etl-pipeline:latest \
  --restart-policy Never \
  --environment-variables \
      SOURCE_BLOB="raw/sales_2024.csv" \
      DEST_TABLE="dw.sales" \
  --secure-environment-variables \
      DB_PASSWORD="$DB_PASS"
```

`--restart-policy Never` → runs once and exits. Perfect for batch ETL jobs.

---

## Comparison: When to Use What

| Scenario | Best Choice |
|---|---|
| Full OS control, custom software stack | Virtual Machine |
| Handle traffic spikes automatically | VM Scale Sets |
| Deploy a web app without managing servers | App Service |
| Run code triggered by events (timer, blob, queue) | Azure Functions |
| Run a Docker container quickly, no orchestration | ACI |
| Run containerised microservices at scale | AKS (not in this module) |

---

## Practice Tasks

### Task 1 — Virtual Machine (Beginner)
1. Create a resource group called `compute-lab-rg` in `eastus`.
2. Deploy an Ubuntu 22.04 VM (`Standard_B1s`) using Azure CLI.
3. SSH into the VM and install `htop`.
4. **Deallocate** (not just stop) the VM and verify it no longer incurs compute charges.

### Task 2 — Disk Management (Beginner)
1. Create a new **Premium SSD** managed disk (32 GB) via CLI.
2. Attach it to your VM from Task 1.
3. SSH in, format the disk (`mkfs.ext4`), and mount it at `/data`.
4. Write a test file to `/data` and reboot the VM to verify persistence.

### Task 3 — VM Scale Sets (Intermediate)
1. Create a VMSS with min=2, max=5 instances (Ubuntu, `Standard_B1s`).
2. Add a scale-out rule: add 1 instance when CPU > 60% for 5 minutes.
3. Add a scale-in rule: remove 1 instance when CPU < 20% for 5 minutes.
4. Use `stress` tool inside one VM to spike CPU and watch the scale-out event in Activity Log.

### Task 4 — App Service (Beginner)
1. Create a Linux App Service Plan (Free tier).
2. Create a Python 3.11 Web App.
3. Write a simple Flask `app.py` that returns `{"status": "ok"}` on `GET /health`.
4. Zip-deploy it and verify the endpoint is live via browser.

### Task 5 — Azure Functions (Intermediate)
1. Install Azure Functions Core Tools locally.
2. Create a Python function app with an **HTTP trigger**.
3. Test it locally with `func start`.
4. Add a **Timer trigger** function that logs `"Pipeline check: OK"` every 5 minutes.
5. Deploy both functions to Azure.

### Task 6 — Azure Container Instances (Beginner)
1. Pull the official `python:3.11-slim` image.
2. Write a `Dockerfile` for a script that prints the current UTC time and exits.
3. Push the image to **Azure Container Registry (ACR)**.
4. Run it in ACI with `--restart-policy Never`.
5. Check the logs to confirm the output.

### Task 7 — End-to-End Data Pipeline with ACI (Advanced)
1. Write a Python ETL script:
   - Reads a CSV from Azure Blob Storage (`raw/` container).
   - Cleans the data (drop nulls, rename columns).
   - Writes the result back to Blob (`processed/` container).
2. Containerise it with Docker; push to ACR.
3. Run it as an ACI job using a **Managed Identity** (no hardcoded credentials).
4. Verify the output file appears in the `processed/` container.

---

## Quick Revision Summary

```
VM           → IaaS, full OS control, you patch/manage
VMSS         → group of identical VMs, auto-scale on metrics
App Service  → PaaS, deploy code/container, Azure manages OS
Functions    → serverless, event-driven, pay-per-execution
ACI          → run containers fast, no orchestration, per-second billing

Disk types   → Standard HDD < Standard SSD < Premium SSD < Ultra
Scale Set    → min/max + scale-out rule + scale-in rule + cooldown
Function     → Trigger (what starts it) + Binding (what it reads/writes)
ACI restart  → Always | OnFailure | Never (Never = batch job pattern)
```