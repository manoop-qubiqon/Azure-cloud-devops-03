# Azure Fundamentals — Theory Notes

---

## 1. Cloud Computing Concepts: IaaS, PaaS, SaaS

Cloud computing delivers IT resources over the internet on a pay-as-you-go model. The three service models differ by **how much you manage vs. what the provider manages**.

| Layer | IaaS | PaaS | SaaS |
|---|---|---|---|
| **What it is** | Raw infrastructure (VMs, storage, networking) | Platform to build & deploy apps | Ready-to-use software |
| **You manage** | OS, runtime, app, data | App logic & data | Nothing |
| **Provider manages** | Hardware, virtualisation, networking | OS, runtime, middleware | Everything |
| **Azure example** | Azure Virtual Machines | Azure App Service | Microsoft 365 |
| **Use case** | Full control, custom OS configs | Dev/test, web apps, APIs | End-user productivity tools |

> **Rule of thumb:** IaaS = most control, most work. SaaS = least control, least work. PaaS sits in between — great for developers.

---

## 2. Azure Global Infrastructure

### Regions
- A **region** is a geographic area containing one or more datacenters (e.g., East US, West Europe, Central India).
- Choose a region close to your users → **lower latency**.
- Some services (e.g., Azure Active Directory) are **global**, not region-specific.

### Availability Zones (AZs)
- **Physically separate datacenters** within a single region (typically 3 per region).
- Each zone has independent power, cooling, and networking.
- Deploy resources across zones → survive a single datacenter failure → **high availability**.
- Not every region has AZs; check before designing for HA.

```
Region: East US
  ├── Availability Zone 1  (Datacenter A)
  ├── Availability Zone 2  (Datacenter B)
  └── Availability Zone 3  (Datacenter C)
```

### Resource Groups
- A **logical container** that holds related Azure resources (VMs, databases, storage, etc.).
- All resources in a group share the same **lifecycle** — deploy, update, and delete together.
- Apply tags, access control (RBAC), and cost tracking at the resource group level.
- A resource can only belong to **one resource group** at a time.

---

## 3. Azure Management Tools

### Azure Portal
- Web-based GUI at [portal.azure.com](https://portal.azure.com).
- Great for exploration, monitoring dashboards, and one-off tasks.
- Not ideal for automation or repeatable deployments.

### Azure CLI (`az`)
- Command-line tool for managing Azure resources from your terminal.
- Cross-platform: works on Windows, macOS, Linux.
- Example commands:
  ```bash
  az login                          # authenticate
  az group create -n myRG -l eastus # create resource group
  az vm list -o table               # list VMs in table format
  ```

### Azure Cloud Shell
- Browser-based shell (Bash or PowerShell) built into the Azure Portal.
- Pre-authenticated with your Azure account — no local install needed.
- Comes with Azure CLI, Azure PowerShell, Git, Terraform, and more pre-installed.
- Uses a small Azure Storage account to persist your files.

---

## 4. Subscriptions, Management Groups & RBAC

### Subscriptions
- A **billing boundary** and an **access boundary**.
- All Azure resources belong to a subscription; costs are billed per subscription.
- A single organization can have multiple subscriptions (e.g., Dev, Staging, Prod).

### Management Groups
- A **container for subscriptions** — lets you apply policies and RBAC at scale.
- Hierarchy: **Management Group → Subscription → Resource Group → Resource**.
- Policies set at a management group level are **inherited** by all subscriptions below it.

```
Root Management Group
  ├── Management Group: Production
  │     ├── Subscription: Prod-East
  │     └── Subscription: Prod-West
  └── Management Group: Dev/Test
        └── Subscription: Dev-Team
```

### RBAC (Role-Based Access Control)
- Controls **who** can do **what** on **which** resources.
- Three key concepts:
  - **Security Principal** — who (user, group, service principal, managed identity)
  - **Role Definition** — what actions are allowed (e.g., `Owner`, `Contributor`, `Reader`)
  - **Scope** — which resources (Management Group / Subscription / Resource Group / Resource)
- Common built-in roles:

| Role | Can Do |
|---|---|
| Owner | Full access + manage permissions |
| Contributor | Create/manage resources, no permission changes |
| Reader | View resources only |

> RBAC is **additive** — you combine roles, and the most permissive wins, except for explicit **Deny** assignments.

---

## 5. Azure Active Directory (Entra ID) Basics

Azure AD (now officially called **Microsoft Entra ID**) is Azure's cloud-based **identity and access management** service.

| Concept | What it means |
|---|---|
| **Tenant** | A dedicated Entra ID instance for your organization |
| **User** | A person with an account (employee, admin, guest) |
| **Group** | A collection of users — assign permissions to the group, not individuals |
| **Service Principal** | An identity for an application or automated service |
| **Managed Identity** | A service principal managed automatically by Azure (no password to handle) |
| **App Registration** | Register an app so it can authenticate via Entra ID |

**Key difference from on-prem AD:**
- On-premise AD uses **Kerberos/LDAP** (domain join, GPOs).
- Entra ID uses **OAuth 2.0 / OpenID Connect / SAML** (web/cloud protocols).

> For data engineering: use **Managed Identities** when your ADF pipelines, Databricks clusters, or Azure Functions need to access Key Vault, Storage, or SQL — no credentials in code.

---

## 6. Cost Management & Pricing Calculator

### Azure Pricing Calculator
- URL: [azure.microsoft.com/en-us/pricing/calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
- Estimate costs **before** deploying — choose service, region, tier, usage hours.
- Export estimates as Excel or share links with your team.

### Azure Cost Management + Billing
- Built into the Azure Portal; monitors **actual spend** after deployment.
- Key features:
  - **Cost Analysis** — visualise spend by service, resource group, tag, or time period.
  - **Budgets** — set a monthly spend limit and get email alerts when you approach it.
  - **Cost Alerts** — trigger on budget thresholds (e.g., alert at 80%, 100%).
  - **Advisor Recommendations** — Azure suggests right-sizing or shutting down idle resources.

### Cost-Saving Tips

| Strategy | What it does |
|---|---|
| **Reserved Instances** | Commit 1–3 years → up to 72% discount vs pay-as-you-go |
| **Spot VMs** | Use spare Azure capacity at deep discounts (can be evicted) |
| **Auto-shutdown** | Stop dev/test VMs after hours automatically |
| **Right-sizing** | Downgrade oversized VMs using Advisor recommendations |
| **Tags** | Tag resources by project/team → accurate cost attribution |

---

## Quick Revision Summary

```
IaaS → VMs (you manage OS+)
PaaS → App Service (you manage app+data)
SaaS → M365 (you manage nothing)

Region → geographic area
AZ     → separate datacenters within a region (HA)
RG     → logical container for resources (lifecycle + billing)

Subscription → billing + access boundary
Mgmt Group  → group of subscriptions (policy at scale)
RBAC        → who + what + where

Entra ID → cloud identity (OAuth/OIDC), not on-prem AD
Managed Identity → passwordless identity for Azure services

Pricing Calculator → estimate before deploy
Cost Management   → monitor + alert after deploy
```