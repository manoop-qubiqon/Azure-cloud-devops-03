# Introduction to Azure DevOps

*Plan smarter, collaborate better, and ship faster with a set of modern development services.*

---

## What is DevOps?

DevOps is the union of **people, processes, and technology** working together to continuously deliver value to end users. It is an Agile methodology that improves both the deployment process and the ongoing maintenance of what a team builds.

Instead of treating planning, development, testing, deployment, and monitoring as separate hand-offs, DevOps ties them into one continuous, organic loop:

```
Plan & Track → Develop → Build & Test → Deploy → Operate → Monitor & Learn → (repeat)
```

The goal is **continuous delivery**: small, frequent, reliable releases rather than large, risky, infrequent ones.

### Why teams adopt DevOps

- Speed up software release times
- Improve code quality
- Guarantee greater stability and security
- Standardise the infrastructure
- Automate distributions
- Test applications across different environments
- Increase the overall success rate of software delivery

---

## What is Azure DevOps?

Azure DevOps is the complete solution offered by **Microsoft** for managing software development projects. It provides an entire ecosystem of services covering the full lifecycle — from requirements gathering all the way through to the release and monitoring of production systems.

It works with any language, any platform, and any cloud, and it integrates with GitHub and other Git providers rather than locking you in.

---

## The five core services

Azure DevOps is made up of five services that map neatly onto the DevOps lifecycle. You can adopt them individually or use them together.

| Service | Purpose |
|---------|---------|
| **Azure Boards** | Plan, track, and discuss work across teams using Kanban boards, backlogs, sprints, and dashboards. |
| **Azure Repos** | Unlimited private Git repositories with pull requests, branch policies, and code search. |
| **Azure Pipelines** | CI/CD for any language, platform, or cloud. Cloud-hosted agents for Linux, macOS, and Windows. |
| **Azure Test Plans** | Planned and exploratory testing with rich charts and full traceability. |
| **Azure Artifacts** | Create, host, and share packages (Maven, npm, NuGet, Python) and feed them into your pipelines. |

### Azure Boards

Keep track of work with Kanban boards, backlogs, team dashboards, and customised reporting. Combine sprint planning with drag-and-drop work-item management and full tracking, giving the team one place to capture every idea — big or small.

### Azure Repos

Free, unlimited private Git repositories with collaborative pull requests, advanced file management, and code search. It also supports Team Foundation Version Control (TFVC), scaling from a hobby project up to very large repositories.

### Azure Pipelines

Cloud-hosted build and release pipelines for Linux, macOS, and Windows. Build web, desktop, and mobile applications, then deploy to any cloud or on-premises environment. Pipelines automate builds and deployments so the team spends less time on manual technical steps.

### Azure Test Plans

A planned and exploratory testing solution. Improve code quality with structured test suites, exploratory sessions, and reporting that ties test results back to work items and builds.

### Azure Artifacts

Fully integrated package management. Create and share feeds for Maven, npm, NuGet, and Python packages from public and private sources, and add them to CI/CD pipelines with a single click.

---

## A complete CI/CD workflow

A typical end-to-end flow in Azure DevOps looks like this:

```
Developer
   ↓
Azure Boards        (plan the work item)
   ↓
Azure Repos (Git)   (commit + push a feature branch)
   ↓
Pull Request        (open a PR into main)
   ↓
Code Review         (approvals + branch policies)
   ↓
Azure Pipelines     (CI triggers on merge)
   ↓
Build → Unit Tests → Security Scan
   ↓
Docker Build
   ↓
Azure Container Registry (ACR)
   ↓
Azure Kubernetes Service (AKS)
   ↓
Production
```

Everything above the deployment can run automatically on each commit (**continuous integration**), and everything below can promote through environments automatically (**continuous delivery**).

---

## Everything as code

A mature Azure DevOps setup defines its pipeline and infrastructure as version-controlled files that live right alongside the application code.

**`azure-pipelines.yml`** — the pipeline definition:

```yaml
trigger:
  - main
pool: ubuntu-latest
stages:
  - stage: Build
  - stage: Test
  - stage: Deploy   # deploy to AKS
```

**`Dockerfile`** — how the app is containerised:

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

**`deployment.yaml`** — the Kubernetes deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 3
  template:
    spec:
      containers:
        - image: acr.io/nexpay
          ports:
            - containerPort: 3000
```

**`main.tf`** — infrastructure provisioned with Terraform:

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_kubernetes_cluster" "aks" {
  name       = "nexpay-aks"
  node_count = 3
}
```

Common commands that drive each stage:

```bash
git push origin main              # trigger the pipeline
docker build -t acr.io/app:v1 .   # build the image
docker push acr.io/app:v1         # push to Azure Container Registry
kubectl apply -f deployment.yaml  # roll out to AKS
terraform apply -auto-approve     # provision infrastructure
```

---

## Supporting Azure services

A production workload usually relies on other Azure platform services around the pipeline:

- **Identity & security:** Azure Active Directory (Entra ID), Azure Key Vault
- **Compute & data:** Azure App Service, Azure SQL Database, Azure Storage
- **Networking & monitoring:** Azure Monitor, Azure Log Analytics, Azure Virtual Network, Azure Load Balancer

---

## Freedom of choice

Azure DevOps does not force a single toolset. You can mix Microsoft, open-source, and third-party tools to build the workflow that suits your team, and target any cloud, on-premises, or both.

| Lifecycle stage | Azure-native | Common alternative |
|-----------------|--------------|--------------------|
| Plan & track | Azure Boards | Trello |
| Code | Azure Repos | GitHub |
| Build & test | Azure Pipelines + Test Plans | Jenkins |
| Deploy | Azure Artifacts + Pipelines | Terraform |
| Operate | Azure Policy | Ansible |
| Monitor | Application Insights | ELK Stack |

A large marketplace of extensions adds further integrations, dashboards, and automation on top.

---

## Getting started

1. **Create an organisation and project** at [dev.azure.com](https://dev.azure.com).
2. **Set up Azure Boards** — add a few work items and a sprint so the team has a shared backlog.
3. **Push code to Azure Repos** — initialise a Git repo and enable branch policies for `main`.
4. **Add a pipeline** — commit an `azure-pipelines.yml` to enable CI on every push.
5. **Add a release stage** — deploy to a dev environment, then promote to staging and production.
6. **Layer in tests and monitoring** — connect Azure Test Plans and Azure Monitor to close the loop.

Start small with one or two services, then expand across the lifecycle as the team gets comfortable.

---

## Key takeaways

- DevOps unites people, process, and technology into one continuous delivery loop.
- Azure DevOps is Microsoft's complete platform covering the entire software lifecycle.
- Its five services — Boards, Repos, Pipelines, Test Plans, and Artifacts — can be used together or independently.
- Pipelines, containers, and infrastructure are all defined **as code** and version-controlled.
- It is open and flexible: any language, any platform, any cloud, and it plays well with third-party tools.