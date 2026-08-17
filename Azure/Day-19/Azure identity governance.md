# Azure Identity & Governance: Subscriptions, Management Groups, RBAC, and Entra ID

---

## 1. Azure Subscriptions

A **Subscription** is the fundamental billing and resource boundary in Azure. Every resource (VM, storage, database) lives inside exactly one subscription.

### What a Subscription Does

- Acts as a **billing unit** — each subscription gets its own invoice
- Acts as a **trust boundary** — linked to one Azure Entra ID (AAD) tenant
- Acts as a **resource container** — all resources are deployed inside a subscription
- Enforces **quota limits** per region (e.g., max 20,000 vCores per region)

### Types of Subscriptions

| Type | Use Case |
|---|---|
| Pay-As-You-Go | Default for most individuals/small orgs |
| Enterprise Agreement (EA) | Large orgs with volume discounts |
| Dev/Test | Discounted rates for non-production |
| Free Trial | $200 credit for 30 days |
| CSP (Cloud Solution Provider) | Managed by a Microsoft partner |

### Example: Multi-Subscription Architecture

```
Contoso Corp (Entra ID Tenant)
├── Subscription: Production        ← Live customer workloads
├── Subscription: Development       ← Dev/Test (cheaper SKUs)
├── Subscription: Staging           ← Pre-prod validation
└── Subscription: Security/Logging  ← Centralized audit logs
```

> **Why multiple subscriptions?**
> - **Isolation** — a blast radius from one environment doesn't affect others
> - **Cost tracking** — separate invoices per team or project
> - **Quota management** — each subscription gets its own quota

### Subscription Limits (Examples)

| Resource | Limit per Subscription |
|---|---|
| VMs | 25,000 per region |
| VNets | 1,000 |
| Resource Groups | 980 |
| Storage Accounts | 250 per region |

---

## 2. Management Groups

**Management Groups** are containers that sit *above* subscriptions in the hierarchy. They let you apply governance (policies, RBAC) across many subscriptions at once.

### Hierarchy Structure

```
Root Management Group (Tenant Root)
├── MG: Corporate
│   ├── MG: Production
│   │   ├── Subscription: Prod-EastUS
│   │   └── Subscription: Prod-WestEurope
│   └── MG: Non-Production
│       ├── Subscription: Dev
│       └── Subscription: Staging
└── MG: Sandboxes
    └── Subscription: Developer-Sandbox
```

### Key Facts

- Up to **6 levels** of hierarchy (not counting root)
- A subscription can only belong to **one** management group at a time
- Policies and RBAC applied to a management group **inherit down** to all subscriptions/resources inside it
- The **Tenant Root Management Group** is automatically created — every subscription is a descendant

### Real-World Example: Applying a Policy at MG Level

```bash
# Assign "Allowed Locations" policy at the Production MG level
# This restricts ALL subscriptions under Production MG to East US only

az policy assignment create \
  --name "restrict-location-prod" \
  --policy "e56962a6-4747-49cd-b67b-bf8b01975c4f" \
  --scope "/providers/Microsoft.Management/managementGroups/Production" \
  --params '{"listOfAllowedLocations": {"value": ["eastus"]}}'
```

Now every subscription under the Production management group is locked to East US — no exceptions, even for subscription owners.

### Management Group vs Resource Group vs Subscription

| | Management Group | Subscription | Resource Group |
|---|---|---|---|
| Purpose | Governance at scale | Billing & trust boundary | Logical grouping of resources |
| Contains | Subscriptions / other MGs | Resource Groups | Individual resources |
| Billing | No | Yes | No |
| Policy scope | Yes | Yes | Yes |
| RBAC scope | Yes | Yes | Yes |

---

## 3. RBAC — Role-Based Access Control

**RBAC** is how Azure controls *who* can do *what* on *which* resources. Instead of giving someone full access, you assign them a specific role with specific permissions.

### The RBAC Model: 3 Key Components

```
RBAC Assignment = Security Principal + Role Definition + Scope
```

| Component | What It Is | Example |
|---|---|---|
| **Security Principal** | Who gets access | User, Group, Service Principal, Managed Identity |
| **Role Definition** | What they can do | Contributor, Reader, Owner |
| **Scope** | Where it applies | Management Group, Subscription, Resource Group, Resource |

### Built-in Roles (Most Important)

| Role | Permissions | Typical Use |
|---|---|---|
| **Owner** | Full access + manage access | Subscription admin |
| **Contributor** | Create/manage resources, NO access management | DevOps engineers |
| **Reader** | View everything, no changes | Auditors, stakeholders |
| **User Access Administrator** | Manage access only, no resources | IAM-only admins |

### Specialized Built-in Roles for Data Engineering

| Role | Scope | Use Case |
|---|---|---|
| Storage Blob Data Contributor | Storage Account | Read/write blob data (e.g., Data Lake) |
| Storage Blob Data Reader | Storage Account | Read-only on Data Lake (analysts) |
| Azure Data Factory Contributor | Resource Group | Manage ADF pipelines |
| SQL DB Contributor | SQL Server | Create/manage Azure SQL databases |
| Key Vault Secrets User | Key Vault | Read secrets (for apps/pipelines) |
| Monitoring Reader | Subscription | View metrics & logs |

### Example: Assigning RBAC via Azure CLI

```bash
# Give a user "Contributor" on a specific Resource Group
az role assignment create \
  --assignee "manoop@company.com" \
  --role "Contributor" \
  --scope "/subscriptions/<sub-id>/resourceGroups/rg-data-engineering"

# Give a Service Principal "Storage Blob Data Contributor" on a storage account
az role assignment create \
  --assignee "<service-principal-object-id>" \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/<sub-id>/resourceGroups/rg-data/providers/Microsoft.Storage/storageAccounts/mydatalake"

# List all role assignments on a resource group
az role assignment list \
  --resource-group rg-data-engineering \
  --output table
```

### Scope Inheritance (Critical to Understand)

Permissions flow **downward** through the hierarchy. Assigning a role at a higher scope automatically grants it at all lower scopes.

```
Management Group (RBAC assigned here)
    ↓ inherits
  Subscription
    ↓ inherits
    Resource Group
      ↓ inherits
      Individual Resource
```

**Example:** If you assign `Reader` to a user at the Subscription level, they can read **all** Resource Groups and resources inside that subscription — even ones created later.

### Custom Roles

When built-in roles are too broad or too narrow, you can create custom roles.

```json
// custom-role.json
{
  "Name": "Data Pipeline Operator",
  "Description": "Can trigger ADF pipelines and read storage, but not modify them",
  "Actions": [
    "Microsoft.DataFactory/factories/read",
    "Microsoft.DataFactory/factories/pipelines/read",
    "Microsoft.DataFactory/factories/pipelines/createRun/action",
    "Microsoft.Storage/storageAccounts/blobServices/containers/read",
    "Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey/action"
  ],
  "NotActions": [],
  "DataActions": [
    "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read"
  ],
  "AssignableScopes": [
    "/subscriptions/<your-sub-id>"
  ]
}
```

```bash
# Create the custom role
az role definition create --role-definition custom-role.json

# Assign it
az role assignment create \
  --assignee "pipeline-operator@company.com" \
  --role "Data Pipeline Operator" \
  --scope "/subscriptions/<sub-id>/resourceGroups/rg-data"
```

### Actions vs DataActions

| | Actions | DataActions |
|---|---|---|
| What | Control plane (manage resources) | Data plane (access data inside resources) |
| Example | Create a storage account | Read blobs from a storage account |
| Checked by | ARM (Azure Resource Manager) | Individual service |

> **Important:** A `Contributor` has all Actions but **zero** DataActions. They can create a storage account but cannot read the data inside it unless also given a data role like `Storage Blob Data Reader`.

---

## 4. Azure Active Directory — Entra ID

**Microsoft Entra ID** (formerly Azure Active Directory / AAD) is Azure's cloud-based identity and access management service. It is the **authentication backbone** for Azure, Microsoft 365, and any app you integrate.

### Core Concepts

| Concept | Description |
|---|---|
| **Tenant** | An organization's dedicated instance of Entra ID |
| **User** | A person with credentials (username + password/MFA) |
| **Group** | A collection of users — assign RBAC/permissions to groups, not individuals |
| **Service Principal** | An identity for an application (like a user, but for apps/automation) |
| **Managed Identity** | A service principal automatically managed by Azure (no credentials to handle) |
| **App Registration** | Registering your application in Entra ID so it can authenticate |

### Authentication Flow (Simplified)

```
User/App → Entra ID (authenticate) → Gets Token → Presents Token to Azure Resource → Access Granted
```

### Users vs Service Principals vs Managed Identities

| | Human User | Service Principal | Managed Identity |
|---|---|---|---|
| Who manages credentials | User | Developer | Azure (automatic) |
| Secret rotation | Manual / SSPR | Manual (or via Key Vault) | Automatic |
| Use case | People | External apps, CI/CD | Azure resources talking to Azure |
| Best practice | Use for humans only | Use for non-Azure workloads | Preferred for Azure-native |

### Managed Identity — Preferred Pattern for Azure Workloads

Instead of storing secrets in your code, the Azure resource itself gets an identity.

```bash
# Enable System-Assigned Managed Identity on a VM
az vm identity assign \
  --name my-data-vm \
  --resource-group rg-data-engineering

# Now give that VM's identity access to a Key Vault
az keyvault set-policy \
  --name my-keyvault \
  --object-id <vm-managed-identity-object-id> \
  --secret-permissions get list
```

```python
# Python: Authenticate using Managed Identity (no credentials in code!)
from azure.identity import ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient

credential = ManagedIdentityCredential()
client = SecretClient(vault_url="https://my-keyvault.vault.azure.net/", credential=credential)

secret = client.get_secret("db-password")
print(secret.value)
```

No passwords. No client secrets. No rotation headaches. The VM's identity is used automatically.

### Groups — Assign Permissions to Groups, Not Individuals

```bash
# Create a security group
az ad group create \
  --display-name "Data Engineers" \
  --mail-nickname "data-engineers"

# Add a user to the group
az ad group member add \
  --group "Data Engineers" \
  --member-id "<user-object-id>"

# Assign RBAC to the group (not the individual)
az role assignment create \
  --assignee "<group-object-id>" \
  --role "Contributor" \
  --scope "/subscriptions/<sub-id>/resourceGroups/rg-data-engineering"
```

Now when a new data engineer joins, you just add them to the group — they automatically get all the right permissions. When they leave, remove them from the group — all access revoked instantly.

### Entra ID Tiers

| Feature | Free | P1 | P2 |
|---|---|---|---|
| Basic user/group management | ✅ | ✅ | ✅ |
| MFA | ✅ (basic) | ✅ | ✅ |
| Conditional Access | ❌ | ✅ | ✅ |
| PIM (Privileged Identity Management) | ❌ | ❌ | ✅ |
| Identity Protection (risk-based) | ❌ | ❌ | ✅ |
| Entitlement Management | ❌ | ✅ | ✅ |

### Conditional Access — Example Policy

With P1/P2, you can enforce context-aware access rules:

```
IF:
  User = any user in "Data Engineers" group
  AND App = Azure Portal
  AND Location = NOT "Corporate Network"
THEN:
  Require MFA
```

This means engineers working from home or a café must use MFA to access the portal, but office access is seamless.

### PIM — Privileged Identity Management (P2)

PIM provides **just-in-time** privileged access. Instead of being permanently assigned Owner or Contributor, a user is *eligible* and must activate the role when needed (with justification + approval + time limit).

```
Normal state:  Manoop → Reader (always-on)
When needed:   Manoop activates "Contributor" for 4 hours
               → Provides justification
               → Gets approved (or auto-approved)
               → Role expires automatically after 4 hours
```

---

## 5. Putting It All Together

### Full Governance Example: Data Engineering Team Setup

```
Tenant: contoso.onmicrosoft.com (Entra ID)
│
├── Groups:
│   ├── DE-Leads         → Owner on Dev, Contributor on Prod
│   ├── DE-Engineers     → Contributor on Dev, Reader on Prod
│   └── DE-Analysts      → Storage Blob Data Reader on Prod Data Lake
│
Management Group: Data Platform
├── Subscription: DE-Production
│   ├── Resource Group: rg-ingestion-prod
│   │   ├── Azure Data Factory (Managed Identity enabled)
│   │   └── Storage Account: datalakeprod
│   └── Resource Group: rg-transform-prod
│       ├── Azure Databricks
│       └── Azure Synapse
│
└── Subscription: DE-Development
    └── Resource Group: rg-ingestion-dev
        ├── Azure Data Factory
        └── Storage Account: dlakedev
```

**Policy applied at Management Group level:**
- All resources must be in `eastus` or `eastus2`
- Diagnostic logs must be sent to central Log Analytics Workspace
- Storage accounts must require HTTPS only

**RBAC applied at Subscription/RG level:**
- `DE-Leads` → Contributor on `rg-*-dev`, Reader on `rg-*-prod`
- `DE-Engineers` → Contributor on `rg-*-dev`
- `DE-Analysts` → Storage Blob Data Reader on `datalakeprod`

**ADF uses Managed Identity** to authenticate to:
- Key Vault (to fetch DB passwords)
- Data Lake (to read/write blobs)
- Azure SQL (via AAD auth, no password stored anywhere)

---

## 6. Quick Reference Summary

| Concept | One-Line Summary |
|---|---|
| Subscription | Billing unit + resource boundary; all resources live here |
| Management Group | Groups subscriptions for policy/RBAC at scale |
| RBAC | Who (principal) + What (role) + Where (scope) |
| Entra ID | The identity store — users, groups, apps, managed identities |
| Managed Identity | Azure-managed service principal — no credentials in code |
| PIM | Just-in-time privileged access with time limits and approvals |
| Conditional Access | Context-aware access rules (location, device, risk) |

---

