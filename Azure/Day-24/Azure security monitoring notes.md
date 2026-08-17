# Azure Security & Monitoring 

---

## 1. Azure Key Vault

### What It Is
A managed cloud service for securely storing and accessing **secrets**, **keys**, and **certificates**. Eliminates hard-coded credentials in code and config files.

### Three Core Object Types

| Type | Description | Example |
|------|-------------|---------|
| **Secrets** | Any sensitive string value | DB passwords, API keys, connection strings |
| **Keys** | Cryptographic keys (RSA, EC) | Used for encryption/decryption, signing |
| **Certificates** | X.509 TLS/SSL certificates | HTTPS certs for App Service, API Management |

### Key Concepts

- **Vault URI:** `https://<vault-name>.vault.azure.net`
- **Access Models:**
  - **Vault Access Policy** — legacy per-principal permissions (Get, List, Set, Delete per object type)
  - **Azure RBAC** — preferred model; uses built-in roles like `Key Vault Secrets User`, `Key Vault Administrator`
- **Soft Delete:** Deleted objects retained for 7–90 days; can be recovered or purged
- **Purge Protection:** Prevents permanent deletion during retention period; required for HSM-backed vaults
- **HSM-backed tier:** Premium SKU; keys stored in FIPS 140-2 Level 2 validated Hardware Security Modules
- **Managed Identity Integration:** VMs, App Services, and Functions can access Key Vault without credentials using system-assigned or user-assigned managed identities

### CLI Examples

```bash
# Create a Key Vault
az keyvault create \
  --name myVault2024 \
  --resource-group myRG \
  --location eastus \
  --sku standard

# Store a secret
az keyvault secret set \
  --vault-name myVault2024 \
  --name "DBPassword" \
  --value "P@ssw0rd123!"

# Retrieve a secret
az keyvault secret show \
  --vault-name myVault2024 \
  --name "DBPassword" \
  --query value -o tsv

# Create an RSA key
az keyvault key create \
  --vault-name myVault2024 \
  --name myEncryptionKey \
  --kty RSA \
  --size 2048

# Import a certificate from PFX
az keyvault certificate import \
  --vault-name myVault2024 \
  --name myAppCert \
  --file ./mycert.pfx \
  --password "certpassword"

# Grant a managed identity access (RBAC model)
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee <managed-identity-object-id> \
  --scope /subscriptions/<sub-id>/resourceGroups/myRG/providers/Microsoft.KeyVault/vaults/myVault2024
```

### Python SDK Example — Read Secret from Key Vault

```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

vault_url = "https://myVault2024.vault.azure.net"
credential = DefaultAzureCredential()  # Uses managed identity in Azure

client = SecretClient(vault_url=vault_url, credential=credential)
secret = client.get_secret("DBPassword")
print(f"Secret value: {secret.value}")
```

### Key Exam Points
- Key Vault access logs go to **Azure Monitor / Log Analytics**
- **Firewall & Virtual Network** settings restrict access to specific VNets or IP ranges
- For zero-downtime cert rotation, use **Key Vault Certificate Auto-Renewal** with DigiCert or Let's Encrypt integration
- Always prefer **RBAC** over Access Policies for new deployments

---

## 2. Microsoft Defender for Cloud

### What It Is
A unified **Cloud Security Posture Management (CSPM)** and **Cloud Workload Protection Platform (CWPP)** that continuously assesses, secures, and defends Azure, on-prem, and multi-cloud resources.

### Two Core Pillars

| Pillar | Function |
|--------|----------|
| **CSPM** | Secure Score, recommendations, compliance assessment |
| **CWPP** | Threat detection, alerts, workload-level protection |

### Secure Score
- A percentage score (0–100%) reflecting how well you follow security recommendations
- Each recommendation has a **max score contribution** (e.g., "Enable MFA" = +10 pts)
- Goal: remediate high-impact recommendations to raise score

### Defender Plans (Enhanced Security)

| Plan | Protects |
|------|----------|
| Defender for Servers | VMs (Windows/Linux) — Microsoft Defender Antivirus, vulnerability assessment |
| Defender for Storage | Blob, Files, ADLS — malware scanning, anomaly detection |
| Defender for SQL | Azure SQL, SQL on VMs — injection attacks, anomalous access |
| Defender for Containers | AKS, container registries — image scanning, runtime threat detection |
| Defender for App Service | Web Apps — detect C2C attacks, anomalous behavior |
| Defender for Key Vault | Unusual access patterns to vault |
| Defender for DNS | DNS-based exfiltration detection |

### Security Alerts
- **Low / Medium / High / Critical** severity
- Each alert includes: affected resource, attack description, MITRE ATT&CK tactic, remediation steps
- Alerts can be exported to **Microsoft Sentinel**, Event Hubs, or Log Analytics

### CLI Examples

```bash
# Enable Defender for Servers (Plan 2) on a subscription
az security pricing create \
  --name VirtualMachines \
  --tier Standard

# Get Secure Score
az security secure-score list

# List active security recommendations
az security task list \
  --query "[].{Name:name, State:state, Severity:properties.severity}" \
  -o table

# List security alerts
az security alert list \
  --query "[].{Name:name, Severity:properties.severity, Resource:properties.resourceIdentifiers[0].azureResourceId}" \
  -o table
```

### Key Exam Points
- **Free tier (Foundational CSPM):** Always on; provides Secure Score and basic recommendations
- **Defender plans are per-resource-type** and priced separately (e.g., per server/month)
- **Just-in-Time VM Access:** Defender for Servers feature; locks down management ports (22, 3389) and opens them only on-demand for approved IPs
- **Regulatory Compliance dashboard:** Shows compliance against PCI DSS, ISO 27001, NIST, etc.
- Multi-cloud: Extend coverage to AWS and GCP workloads via **Defender for Cloud connectors**

---

## 3. Azure Monitor

### What It Is
The unified observability platform for Azure — collects, analyzes, and acts on **metrics**, **logs**, and **traces** from any Azure resource.

### Data Types

| Type | Description | Retention |
|------|-------------|-----------|
| **Metrics** | Numeric time-series data (CPU %, requests/sec) | 93 days (default) |
| **Logs** | Structured/unstructured text data (activity logs, diagnostics) | Configurable in Log Analytics |
| **Traces** | Distributed tracing data (via Application Insights) | 90 days |

### Key Components

```
Azure Resources
     │
     ▼
Diagnostic Settings ──► Log Analytics Workspace  ◄── KQL Queries
     │                          │
     │                          ▼
     │                   Azure Workbooks / Dashboards
     │
     ▼
Azure Monitor Metrics ──► Metrics Explorer ──► Alerts
```

### Metrics Explorer
- Available for all Azure resources out of the box (no config needed)
- Supports: **Avg, Min, Max, Sum, Count** aggregations
- Time granularity: 1 min → 1 month
- Can split by dimension (e.g., split VM CPU by OS Disk, or HTTP requests by Status Code)

### Diagnostic Settings
- Required to send **platform logs and metrics** to a destination
- Destinations: Log Analytics Workspace, Storage Account, Event Hub, Partner Solution

```bash
# Enable Diagnostic Settings for a VM
az monitor diagnostic-settings create \
  --name vmDiagnostics \
  --resource /subscriptions/<sub>/resourceGroups/myRG/providers/Microsoft.Compute/virtualMachines/myVM \
  --logs '[{"category": "Administrative","enabled": true}]' \
  --metrics '[{"category": "AllMetrics","enabled": true}]' \
  --workspace /subscriptions/<sub>/resourceGroups/myRG/providers/Microsoft.OperationalInsights/workspaces/myWorkspace
```

### Alerts

#### Alert Types

| Type | Trigger |
|------|---------|
| **Metric Alert** | Threshold on a metric (e.g., CPU > 80% for 5 min) |
| **Log Alert** | KQL query returns results exceeding a count threshold |
| **Activity Log Alert** | Specific control-plane event (e.g., VM deleted, policy assigned) |
| **Smart Detection Alert** | Application Insights anomaly detection (auto) |

#### Alert Components
1. **Scope** — which resource(s) to monitor
2. **Condition** — signal type + threshold + evaluation frequency
3. **Action Group** — who/what to notify (Email, SMS, Webhook, ITSM, Logic App, Runbook)
4. **Alert Rule** — ties scope + condition + action group together

```bash
# Create a metric alert: CPU > 80% on a VM
az monitor metrics alert create \
  --name "High CPU Alert" \
  --resource-group myRG \
  --scopes /subscriptions/<sub>/resourceGroups/myRG/providers/Microsoft.Compute/virtualMachines/myVM \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action /subscriptions/<sub>/resourceGroups/myRG/providers/microsoft.insights/actionGroups/myActionGroup \
  --severity 2

# Create an action group with email notification
az monitor action-group create \
  --name myActionGroup \
  --resource-group myRG \
  --short-name myAG \
  --email-receiver name="OpsTeam" email-address="ops@company.com"
```

### Key Exam Points
- **Activity Log** captures subscription-level events (who did what, when) — retained 90 days by default
- **Resource logs** (formerly Diagnostic Logs) are resource-specific and require Diagnostic Settings to collect
- **Azure Monitor Agent (AMA)** replaces the older Log Analytics Agent (MMA) and Diagnostics Extension
- Metrics are **free to collect**; Log Analytics ingestion and retention incur costs

---

## 4. Log Analytics Workspace & KQL

### What It Is
**Log Analytics Workspace** is the data store for Azure Monitor Logs. All log data from Diagnostic Settings, VMs (via agents), and services flows here. Query it with **Kusto Query Language (KQL)**.

### Workspace Concepts
- **Tables:** Pre-defined schemas for different data sources (e.g., `AzureActivity`, `Heartbeat`, `Perf`, `SecurityEvent`, `ContainerLog`)
- **Data Retention:** Default 30 days; configurable up to 730 days (2 years); archived tier available beyond that
- **Commitment Tiers:** Pay-per-GB or commitment tiers (100 GB/day, 200 GB/day, etc.) for cost savings
- **Workspace ID + Primary Key:** Used by agents to authenticate and send logs

### KQL Fundamentals

KQL uses a **pipe `|` operator** to chain operations — similar to Unix pipes.

```
TableName
| operator1 arguments
| operator2 arguments
| ...
```

#### Core Operators

| Operator | Purpose | Example |
|----------|---------|---------|
| `where` | Filter rows | `where Level == "Error"` |
| `project` | Select columns | `project TimeGenerated, Message` |
| `extend` | Add calculated column | `extend DurationMin = Duration / 60` |
| `summarize` | Aggregate | `summarize count() by bin(TimeGenerated, 1h)` |
| `order by` / `sort by` | Sort | `order by TimeGenerated desc` |
| `top` | Return top N rows | `top 10 by Duration` |
| `join` | Join two tables | `T1 \| join kind=inner T2 on $left.Id == $right.Id` |
| `render` | Visualize results | `render timechart` |
| `distinct` | Unique values | `distinct Computer` |
| `parse` | Extract from strings | `parse Message with * "error=" ErrCode " "` |

### KQL Query Examples

#### Example 1 — View Azure Activity Log (last 24 hours)
```kql
AzureActivity
| where TimeGenerated > ago(24h)
| project TimeGenerated, OperationNameValue, ActivityStatusValue, Caller, ResourceGroup
| order by TimeGenerated desc
```

#### Example 2 — Count Events by Level (Error/Warning/Info)
```kql
AzureActivity
| where TimeGenerated > ago(7d)
| summarize EventCount = count() by ActivityStatusValue
| order by EventCount desc
```

#### Example 3 — VM CPU Performance
```kql
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| where TimeGenerated > ago(1h)
| summarize AvgCPU = avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
| render timechart
```

#### Example 4 — Failed Login Attempts (Security Events)
```kql
SecurityEvent
| where EventID == 4625  // Failed logon
| where TimeGenerated > ago(24h)
| summarize FailedAttempts = count() by Account, Computer, IpAddress
| where FailedAttempts > 5
| order by FailedAttempts desc
```

#### Example 5 — Find Resources with No Heartbeat (Offline VMs)
```kql
Heartbeat
| where TimeGenerated > ago(30m)
| summarize LastHeartbeat = max(TimeGenerated) by Computer
| where LastHeartbeat < ago(15m)
| project Computer, LastHeartbeat
```

#### Example 6 — HTTP 5xx Errors in App Service Logs
```kql
AppServiceHTTPLogs
| where TimeGenerated > ago(1h)
| where ScStatus >= 500
| summarize ErrorCount = count() by ScStatus, CsUriStem
| order by ErrorCount desc
```

#### Example 7 — Key Vault Secret Access Audit
```kql
AzureDiagnostics
| where ResourceType == "VAULTS"
| where OperationName == "SecretGet"
| project TimeGenerated, identity_claim_upn_s, requestUri_s, resultType
| order by TimeGenerated desc
```

#### Example 8 — Alert Log Query — Detect Subscription Role Changes
```kql
AzureActivity
| where OperationNameValue has "roleAssignments"
| where ActivityStatusValue == "Success"
| project TimeGenerated, Caller, OperationNameValue, ResourceGroup, Properties
```

### Key Exam Points
- `ago(24h)` = last 24 hours; `startofday(now())` = midnight today
- `bin(TimeGenerated, 5m)` = group into 5-minute buckets (required for timechart)
- **Saved Searches** = reusable KQL queries stored in the workspace
- **Workbooks** = interactive dashboards built from KQL queries
- Log Analytics and Application Insights now share the same underlying data platform — you can run cross-resource queries

---

## 5. Azure Policy and Blueprints

### Azure Policy

#### What It Is
Azure Policy enforces **organizational standards** and assesses compliance at scale. You define rules (policy definitions) and apply them to scopes (Management Group → Subscription → Resource Group → Resource).

#### Policy Components

| Component | Description |
|-----------|-------------|
| **Policy Definition** | JSON rule: `if [condition] then [effect]` |
| **Initiative Definition** | Collection of related policy definitions (a "policy set") |
| **Assignment** | Applying a definition/initiative to a scope |
| **Compliance** | Dashboard showing compliant vs non-compliant resources |

#### Policy Effects (in order of restrictiveness)

| Effect | Behavior |
|--------|----------|
| `Deny` | Block non-compliant resource creation/update |
| `Audit` | Allow but flag as non-compliant in dashboard |
| `AuditIfNotExists` | Audit if a related resource doesn't exist |
| `DeployIfNotExists` | Auto-deploy a related resource if missing |
| `Modify` | Add/replace/remove tags or properties on resources |
| `Append` | Add fields to the request (e.g., tags) |
| `Disabled` | Policy is off |

#### Built-in Policy Examples
- `Allowed locations` — restrict deployments to specific Azure regions
- `Require a tag and its value` — enforce tagging standards
- `Not allowed resource types` — block creation of specific resource types
- `Allowed virtual machine SKUs` — limit VM sizes
- `Enable Azure Defender for Storage` — auto-enable Defender plan

#### Custom Policy Definition Example — Deny Public IP on VMs

```json
{
  "mode": "All",
  "policyRule": {
    "if": {
      "allOf": [
        {
          "field": "type",
          "equals": "Microsoft.Network/networkInterfaces"
        },
        {
          "field": "Microsoft.Network/networkInterfaces/ipConfigurations[*].publicIPAddress.id",
          "exists": true
        }
      ]
    },
    "then": {
      "effect": "Deny"
    }
  }
}
```

#### CLI Examples

```bash
# List all built-in policy definitions
az policy definition list --query "[?policyType=='BuiltIn'].{Name:displayName, Id:name}" -o table

# Assign a built-in policy: Allowed locations
az policy assignment create \
  --name "restrict-to-eastus" \
  --display-name "Restrict to East US only" \
  --policy "e56962a6-4747-49cd-b67b-bf8b01975c4c" \
  --scope /subscriptions/<sub-id> \
  --params '{"listOfAllowedLocations": {"value": ["eastus", "eastus2"]}}'

# Create a custom policy definition
az policy definition create \
  --name "deny-public-ip-on-nic" \
  --display-name "Deny Public IP on NIC" \
  --description "Prevents attaching public IPs to network interfaces" \
  --rules ./deny-public-ip-policy.json \
  --mode All

# Check compliance
az policy state list \
  --query "[?complianceState=='NonCompliant'].{Resource:resourceId, Policy:policyDefinitionName}" \
  -o table

# Create a remediation task (for DeployIfNotExists / Modify policies)
az policy remediation create \
  --name "remediate-missing-tags" \
  --policy-assignment "restrict-to-eastus" \
  --resource-group myRG
```

---

### Azure Blueprints

#### What It Is
Azure Blueprints packages **role assignments, policy assignments, ARM templates, and resource groups** into a single deployable unit for repeatable, compliant environment setup.

> **Note:** Azure Blueprints is being deprecated in favor of using **Azure DevOps Pipelines / Bicep / Terraform** for environment orchestration. For AZ-104, understand the concepts; for new deployments, prefer IaC.

#### Blueprint Components (Artifacts)

| Artifact Type | Purpose |
|--------------|---------|
| **Role Assignment** | Assign RBAC roles to identities at deployment time |
| **Policy Assignment** | Apply policies as part of the blueprint |
| **ARM Template** | Deploy resources (VNet, NSG, Key Vault, etc.) |
| **Resource Group** | Create resource groups with specific naming/tags |

#### Blueprint Lifecycle

```
Define Blueprint (Draft)
        │
        ▼
Publish Blueprint (with version: e.g., "1.0")
        │
        ▼
Assign Blueprint to Subscription/Management Group
        │
        ▼
Resources Deployed + Lock Applied
        │
        ▼
Update Blueprint (new version) → Re-assign
```

#### Blueprint Locking Modes

| Lock Mode | Behavior |
|-----------|----------|
| `Don't Lock` | No restrictions on deployed resources |
| `Do Not Delete` | Resources cannot be deleted (but can be modified) |
| `Read Only` | Resources cannot be modified or deleted |

#### Key Exam Points
- Blueprint assignments are **tracked** — you can see what subscription was deployed from which blueprint version
- Blueprints use **system-assigned managed identity** during deployment for RBAC assignments
- **Locking is enforced by Azure Policy** behind the scenes, not RBAC
- Blueprint definitions can be stored at **Management Group** or **Subscription** scope

---

## 6. Application Insights — APM

### What It Is
**Application Performance Management (APM)** service for live web applications. Monitors availability, performance, failures, and usage. Integrates with Azure Monitor.

### Data It Collects

| Telemetry Type | Examples |
|---------------|---------|
| **Requests** | HTTP requests: URL, duration, response code, success/failure |
| **Dependencies** | Calls to SQL, HTTP APIs, Redis, Storage — with duration and success |
| **Exceptions** | Unhandled exceptions with stack traces |
| **Page Views** | Browser-side page load times (JavaScript SDK) |
| **Custom Events** | Business events you instrument (e.g., "UserRegistered") |
| **Custom Metrics** | Application-level metrics (e.g., queue depth, order value) |
| **Traces** | Log messages (Information, Warning, Error) |
| **Availability** | URL ping tests from global locations |

### Instrumentation Methods

| Method | Best For |
|--------|----------|
| **Auto-instrumentation** (codeless) | .NET, Java, Node.js on App Service/AKS — zero code change |
| **SDK** | Manual control; custom telemetry; all languages |
| **OpenTelemetry** | Vendor-neutral standard; recommended for new apps |

### Connection String (replaces old Instrumentation Key)

```python
# Python (OpenCensus SDK)
from applicationinsights import TelemetryClient

tc = TelemetryClient("your-instrumentation-key")
tc.track_event("OrderPlaced", {"orderId": "ORD-001"}, {"orderValue": 149.99})
tc.flush()
```

```javascript
// Node.js SDK
const appInsights = require("applicationinsights");
appInsights.setup("your-connection-string").start();

const client = appInsights.defaultClient;
client.trackEvent({ name: "UserLoggedIn", properties: { userId: "u123" } });
client.trackMetric({ name: "ActiveUsers", value: 342 });
```

### Key Features

#### Application Map
- Visual representation of your app's components and their dependencies
- Shows request rates, failure rates, and latency between components
- Automatically discovers microservice topology

#### Live Metrics Stream
- Real-time telemetry with < 1-second latency
- Shows incoming requests, outgoing dependencies, exceptions, and server health
- Useful for validating deployments in real time

#### Smart Detection (Proactive Diagnostics)
- Auto-detects performance anomalies: unusual spike in failures, degradation in response time, memory leaks
- Sends email alerts with built-in analysis — no configuration required

#### Availability Tests

```bash
# Create a URL ping test (via CLI — typically done via portal or ARM)
# Availability tests send HTTP requests from multiple global locations
# Alert if >2 locations fail within 5 minutes
```

| Test Type | Description |
|-----------|-------------|
| **URL Ping Test** | Simple HTTP GET to a URL; check status code and response content |
| **Standard Test** | Single-step HTTP test with SSL validity check and headers |
| **Multi-step Web Test** | Recorded browser session (deprecated; use Playwright instead) |
| **TrackAvailability()** | Custom availability test via SDK |

#### KQL Queries in Application Insights

```kql
-- Top 5 slowest requests
requests
| where timestamp > ago(1h)
| summarize AvgDuration = avg(duration), Requests = count() by name
| top 5 by AvgDuration desc

-- Failed requests by operation
requests
| where success == false
| where timestamp > ago(24h)
| summarize FailureCount = count() by name, resultCode
| order by FailureCount desc

-- Exception breakdown by type
exceptions
| where timestamp > ago(24h)
| summarize ExceptionCount = count() by type, outerMessage
| order by ExceptionCount desc

-- Dependency failures (e.g., SQL timeouts)
dependencies
| where success == false
| where timestamp > ago(1h)
| project timestamp, name, type, target, duration, resultCode
| order by timestamp desc

-- Custom event tracking (business events)
customEvents
| where name == "OrderPlaced"
| where timestamp > ago(7d)
| summarize Orders = count(), AvgValue = avg(todouble(customMeasurements["orderValue"])) by bin(timestamp, 1d)
| render timechart

-- Funnel analysis: Login → Browse → AddToCart → Purchase
customEvents
| where name in ("Login", "ProductViewed", "AddToCart", "OrderPlaced")
| summarize Users = dcount(user_Id) by name
```

#### Sampling
- **Adaptive Sampling** (default): Automatically adjusts the rate to keep telemetry volume within a limit; preserves statistical accuracy
- **Fixed-Rate Sampling:** You control the percentage (e.g., 10% = only 1 in 10 requests tracked)
- **Ingestion Sampling:** Applied at Log Analytics ingestion time; reduces cost but loses some data
- Rule: Correlated telemetry (request + its dependencies + exceptions) is always sampled together

### Key Exam Points
- Application Insights is a **workspace-based** resource — data stored in a Log Analytics Workspace (same data platform)
- **Connection String** is preferred over the legacy Instrumentation Key (supports more endpoints)
- **Distributed Tracing:** Automatically propagates correlation IDs across services; visualized as end-to-end transaction details
- **Retention:** Default 90 days; configurable up to 730 days
- Alerts from Application Insights integrate with **Azure Monitor Action Groups** (same mechanism)
- Cost is based on **data ingestion volume** (GB/month) — use sampling to control costs

---

## Quick Reference — Services at a Glance

| Service | Primary Use | Key Output |
|---------|------------|------------|
| **Key Vault** | Store secrets, keys, certs | Secure credential access via managed identity |
| **Defender for Cloud** | Security posture + threat protection | Secure Score, alerts, recommendations |
| **Azure Monitor Metrics** | Numeric time-series data | Dashboards, metric alerts |
| **Log Analytics + KQL** | Log storage and querying | Insights, log alert rules |
| **Azure Policy** | Enforce governance standards | Compliance reports, deny/audit/remediate |
| **Azure Blueprints** | Repeatable compliant environments | Blueprint assignments with version tracking |
| **Application Insights** | APM for applications | Request/failure/dependency/user telemetry |

---

## Common Exam Scenarios

| Scenario | Answer |
|----------|--------|
| App needs to read secrets without credentials | Use **Managed Identity** + **Key Vault RBAC** (`Key Vault Secrets User`) |
| Block deployment of VMs outside West Europe | Create **Azure Policy** with `Deny` effect + `Allowed locations` parameter |
| Get notified when VM CPU > 90% for 10 min | **Azure Monitor Metric Alert** + Action Group with email receiver |
| Find who deleted a storage account | Query `AzureActivity` in **Log Analytics** for `Delete` operation |
| Ensure all subscriptions have Defender enabled | **Azure Policy** with `DeployIfNotExists` effect or Initiative assignment |
| Track page load time in a React SPA | **Application Insights JavaScript SDK** (browser telemetry) |
| Query slow SQL calls from an API service | **Application Insights** `dependencies` table in KQL |
| Standardize new subscription setup (RBAC + Policy + VNet) | **Azure Blueprints** assignment |
| Monitor container security in AKS | **Defender for Containers** plan in Defender for Cloud |

---
