# Azure Storage Account Types, Replication & ADLS Gen2


---

## Part 1 — Storage Account Types

A **Storage Account** is the top-level namespace for all Azure Storage services. Everything lives inside one — Blobs, Files, Queues, Tables, Disks.

### Account Types at a Glance

```
┌──────────────────────────────────────────────────────────────────────────┐
│                     Storage Account Types                                │
│                                                                          │
│  ┌───────────────────────┐   ┌────────────────┐   ┌──────────────────┐  │
│  │  General Purpose v2   │   │  Blob Storage  │   │     Premium      │  │
│  │       (GPv2)          │   │   (Legacy)     │   │  (3 subtypes)    │  │
│  │                       │   │                │   │                  │  │
│  │  ← Recommended        │   │  Use GPv2      │   │  High perf only  │  │
│  │    for most use cases │   │  instead       │   │                  │  │
│  └───────────────────────┘   └────────────────┘   └──────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
```

### Detailed Comparison

| Account Type | Supports | Redundancy | Performance | Use Case |
|---|---|---|---|---|
| **General Purpose v2 (GPv2)** | Blob, Files, Queues, Tables, ADLS Gen2 | LRS, ZRS, GRS, GZRS, RA-GRS, RA-GZRS | Standard | ✅ Default choice for everything |
| **General Purpose v1 (GPv1)** | Blob, Files, Queues, Tables | LRS, GRS, RA-GRS | Standard | Legacy — upgrade to GPv2 |
| **Blob Storage (Legacy)** | Block + Append Blobs only | LRS, GRS, RA-GRS | Standard | Legacy — use GPv2 instead |
| **Premium Block Blobs** | Block + Append Blobs | LRS, ZRS | Premium (SSD) | High-throughput blob workloads, ADLS Gen2 |
| **Premium File Shares** | Azure Files only | LRS, ZRS | Premium (SSD) | Low-latency, high-IOPS file shares |
| **Premium Page Blobs** | Page Blobs only | LRS | Premium (SSD) | Unmanaged VM disks (rare today) |

> **Rule of thumb**: Always create **GPv2** unless you specifically need Premium performance. GPv1 and Blob Storage accounts are legacy — Microsoft recommends migrating them to GPv2.

### GPv2 vs Premium — When to Choose

```
Need standard performance + all features?
└── GPv2  ✅  (supports all tiers: Hot / Cool / Cold / Archive)

Need SSD-level performance for blobs?
└── Premium Block Blobs  (no Archive tier — all data stays "hot")

Need SSD-level performance for file shares?
└── Premium File Shares  (NFS requires this type)

Need page blobs with SSD?
└── Premium Page Blobs  (very rare — most use Managed Disks instead)
```

> **Critical exam point**: Premium accounts **cannot** use Archive tier. Premium is designed for low-latency, high-frequency access — archival is the opposite of that.

---

## Part 2 — Replication (Redundancy)

Replication defines **how many copies** of your data exist and **where** they are stored. It's your durability and availability guarantee.

### The 6 Replication Options

```
Single Region ──────────────────────────────────────────────────────────
│
├── LRS  (Locally Redundant Storage)
│   └── 3 copies in 1 datacenter, 1 region
│
├── ZRS  (Zone Redundant Storage)
│   └── 3 copies across 3 Availability Zones, 1 region
│
Multi-Region ────────────────────────────────────────────────────────────
│
├── GRS  (Geo-Redundant Storage)
│   └── LRS in primary + LRS in secondary region (async replication)
│
├── GZRS  (Geo-Zone Redundant Storage)
│   └── ZRS in primary + LRS in secondary region
│
├── RA-GRS  (Read-Access GRS)
│   └── GRS + secondary endpoint is readable
│
└── RA-GZRS  (Read-Access GZRS)
    └── GZRS + secondary endpoint is readable
```

### Visual Architecture

```
LRS — 3 copies, 1 datacenter
┌──────────────────────────────┐
│        Datacenter A          │
│  [Copy 1] [Copy 2] [Copy 3]  │
└──────────────────────────────┘
  Survives: drive/rack failure
  Fails on: datacenter outage


ZRS — 3 copies, 3 zones
┌──────────────────────────────────────────────────────────┐
│                        Region                            │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐         │
│  │  Zone 1    │  │  Zone 2    │  │  Zone 3    │         │
│  │  [Copy 1]  │  │  [Copy 2]  │  │  [Copy 3]  │         │
│  └────────────┘  └────────────┘  └────────────┘         │
└──────────────────────────────────────────────────────────┘
  Survives: zone (datacenter) outage
  Fails on: full region outage


GRS — LRS in 2 regions (secondary read-only unless failover)
┌─────────────────────────┐          ┌─────────────────────────┐
│      Primary Region     │ ──────→  │     Secondary Region    │
│   [C1]  [C2]  [C3]     │  async   │   [C1]  [C2]  [C3]     │
│   (LRS, synchronous)    │          │   (LRS, synchronous)    │
└─────────────────────────┘          └─────────────────────────┘
  Survives: full region outage (after failover)
  RPO: ~15 minutes (async lag)


GZRS — ZRS primary + LRS secondary (best of both)
┌──────────────────────────────────────┐       ┌──────────────────────┐
│          Primary Region              │ ───→  │   Secondary Region   │
│  [Zone1]  [Zone2]  [Zone3]  (ZRS)    │ async │   [C1][C2][C3] (LRS) │
└──────────────────────────────────────┘       └──────────────────────┘
  Survives: zone outage + region outage
  Best durability option available
```

### Comparison Table

| Option | Copies | Locations | Read Secondary? | SLA (Availability) | Best For |
|---|---|---|---|---|---|
| **LRS** | 3 | 1 DC, 1 region | ❌ | 99.9% | Dev/test, low-cost, non-critical |
| **ZRS** | 3 | 3 AZs, 1 region | ❌ | 99.9999% | Zone-resilient production |
| **GRS** | 6 | 2 regions | ❌ (until failover) | 99.9% / 99.99%* | Disaster recovery |
| **GZRS** | 6 | 3 AZs + 2 regions | ❌ (until failover) | 99.9999% | Maximum resilience |
| **RA-GRS** | 6 | 2 regions | ✅ (always) | 99.9% / 99.99%* | DR + read scaling |
| **RA-GZRS** | 6 | 3 AZs + 2 regions | ✅ (always) | 99.9999% | Highest availability |

> \* GRS/RA-GRS: 99.9% write availability; 99.99% read availability (for RA-GRS secondary reads)

### Durability Numbers

| Option | Annual Durability (nines) |
|---|---|
| LRS | 11 nines (99.999999999%) |
| ZRS | 12 nines |
| GRS / RA-GRS | 16 nines |
| GZRS / RA-GZRS | 16 nines |

> All options provide **at least 11 nines** of durability. The difference is **availability** (can you read/write during an outage), not durability (is your data safe).

### Failover Behavior

**GRS/GZRS**: Secondary is read-only by default. To use it as primary:
1. **Microsoft-managed failover** — Azure initiates automatically during major outages
2. **Customer-managed failover** — You trigger it manually via portal or CLI

```bash
# Initiate account failover (GRS/GZRS only)
az storage account failover \
  --name mystorageacct \
  --resource-group myRG

# Check replication status
az storage account show \
  --name mystorageacct \
  --resource-group myRG \
  --query "secondaryLocation"
```

> **After failover**: The account becomes LRS in the new primary region. ZRS/GRS is NOT automatically re-established. You must reconfigure replication.

### RA-GRS Secondary Endpoint

With **RA-GRS** or **RA-GZRS**, a secondary read endpoint is always available:

```
Primary:   https://mystorageacct.blob.core.windows.net
Secondary: https://mystorageacct-secondary.blob.core.windows.net
                                    ↑
                             Note the "-secondary" suffix
```

Use the secondary endpoint for read-heavy apps that can tolerate slight data lag.

### Replication by Account Type

| Account Type | LRS | ZRS | GRS | GZRS | RA-GRS | RA-GZRS |
|---|---|---|---|---|---|---|
| GPv2 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Premium Block Blobs | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Premium File Shares | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Premium Page Blobs | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

> **Premium accounts are single-region only.** No geo-replication. If you need DR for Premium, use snapshots + cross-region copy.

---

## Part 3 — Azure Data Lake Storage Gen2 (ADLS Gen2)

### What Is It?

ADLS Gen2 is **not a separate service** — it's **Azure Blob Storage with two features enabled**:
1. **Hierarchical Namespace (HNS)** — true directory structure
2. **ABFS driver** — Azure Blob File System protocol for big data frameworks

```
Azure Blob Storage (flat namespace)          ADLS Gen2 (hierarchical namespace)
─────────────────────────────────            ─────────────────────────────────
Container: analytics                         Container: analytics (= filesystem)
  blob: year=2024/month=01/data.csv            /raw/
  blob: year=2024/month=02/data.csv              year=2024/
  blob: year=2024/month=01/schema.json             month=01/
  (just key-value naming tricks)                     data.csv
                                                     schema.json
                                                   month=02/
                                                     data.csv
                                             (true directory tree)
```

### Why Hierarchical Namespace Matters

| Operation | Blob Storage (flat) | ADLS Gen2 (HNS) |
|---|---|---|
| Rename a "folder" with 1M files | Copies + deletes each file individually — **O(n)** | Renames the directory pointer — **O(1)** |
| Delete a directory | Must list + delete every blob | Single atomic operation |
| POSIX permissions on a folder | ❌ Not supported | ✅ Supported (ACLs per directory) |
| Atomic directory operations | ❌ | ✅ |
| Spark/Hadoop native access | Wasb:// (legacy, slow) | abfs:// (native, fast) |

> **This is the core value of Gen2**: O(1) directory operations make it viable for petabyte-scale analytics pipelines where you're constantly reorganizing data.

### ADLS Gen2 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│               ADLS Gen2 Storage Account (GPv2 + HNS)           │
│                                                                 │
│  Filesystem (= Container)                                       │
│  └── /                                                          │
│      ├── raw/              ← Landing zone (ingest here)         │
│      │   ├── year=2024/                                         │
│      │   │   ├── month=01/                                      │
│      │   │   │   └── orders.parquet                             │
│      │   │   └── month=02/                                      │
│      │   │       └── orders.parquet                             │
│      ├── curated/          ← Cleaned, validated data            │
│      │   └── orders/                                            │
│      │       └── orders_clean.parquet                           │
│      └── processed/        ← Aggregated, model-ready data       │
│          └── orders_summary.parquet                             │
│                                                                 │
│  Access:  abfs://filesystem@account.dfs.core.windows.net/path   │
└─────────────────────────────────────────────────────────────────┘
          ↑              ↑               ↑              ↑
      Azure Synapse   Databricks    Azure HDInsight   ADF
```

### How to Enable

```bash
# Enable HNS at account creation (CANNOT be disabled after)
az storage account create \
  --name myadlsaccount \
  --resource-group myRG \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2 \
  --enable-hierarchical-namespace true  ← This flag enables ADLS Gen2

# Verify HNS is enabled
az storage account show \
  --name myadlsaccount \
  --resource-group myRG \
  --query "isHnsEnabled"
```

> **Warning**: HNS is a one-way switch. Once enabled, it **cannot be disabled**. Plan before creating.

### Access Protocols

| Protocol | Endpoint suffix | Used by |
|---|---|---|
| **ABFS (Azure Blob File System)** | `.dfs.core.windows.net` | Spark, Databricks, HDInsight, Synapse |
| **Blob REST API** | `.blob.core.windows.net` | ADF, Azure SDK, azcopy, portal |
| **NFS 3.0** | `.blob.core.windows.net` | Linux workloads (requires Premium + HNS) |

```python
# Databricks / PySpark — using ABFS
spark.read.parquet(
    "abfs://raw@myadlsaccount.dfs.core.windows.net/year=2024/month=01/orders.parquet"
)

# Or with abfss:// (SSL)
spark.read.parquet(
    "abfss://raw@myadlsaccount.dfs.core.windows.net/year=2024/"
)
```

### Security Model — RBAC + ACLs

ADLS Gen2 supports **two layers** of access control:

```
Layer 1: Azure RBAC (coarse-grained, at account/container level)
──────────────────────────────────────────────────────────────
  Storage Blob Data Owner     → Full control (read/write/delete + set ACLs)
  Storage Blob Data Contributor → Read/write/delete (no ACL management)
  Storage Blob Data Reader    → Read only

Layer 2: POSIX ACLs (fine-grained, at directory/file level)
──────────────────────────────────────────────────────────────
  Access ACL  → Controls actual access to file/directory
  Default ACL → Inherited by new child items (like umask)

  Format: [scope:]type:id:permissions
  Examples:
    user::rwx          (owning user)
    group::r-x         (owning group)
    other::---         (everyone else)
    user:abc-uuid:rwx  (specific user by Object ID)
    mask::r-x          (permission mask)
```

```bash
# Set ACL on a directory
az storage fs access set \
  --acl "user::rwx,group::r-x,other::---" \
  --path /raw/year=2024 \
  --file-system myfilesystem \
  --account-name myadlsaccount

# Set recursive ACL (applies to all children)
az storage fs access set-recursive \
  --acl "user:abc-object-id:r-x" \
  --path /curated \
  --file-system myfilesystem \
  --account-name myadlsaccount

# Get ACL
az storage fs access show \
  --path /raw \
  --file-system myfilesystem \
  --account-name myadlsaccount
```

> **Exam tip**: If both RBAC and ACLs apply, the **more permissive** takes effect. RBAC Owner bypasses ACL checks entirely.

### Authentication Methods

| Method | Best For |
|---|---|
| **Azure AD (OAuth 2.0)** | Databricks, Synapse, managed identities — recommended |
| **Storage Account Key** | Admin scripts, legacy tools |
| **SAS Token** | External partners, temporary access |
| **Service Principal** | CI/CD pipelines (Azure Pipelines), automation |

```python
# Python SDK with DefaultAzureCredential (uses managed identity / service principal)
from azure.identity import DefaultAzureCredential
from azure.storage.filedatalake import DataLakeServiceClient

credential = DefaultAzureCredential()
service_client = DataLakeServiceClient(
    account_url="https://myadlsaccount.dfs.core.windows.net",
    credential=credential
)

# List directories
fs_client = service_client.get_file_system_client("raw")
paths = fs_client.get_paths("/year=2024")
for path in paths:
    print(path.name)
```

### Data Lake Zones (Medallion Architecture on ADLS Gen2)

```
┌──────────────────────────────────────────────────────────────────────┐
│                     ADLS Gen2 Account                                │
│                                                                      │
│  /raw  (Bronze)          /curated  (Silver)      /processed  (Gold) │
│  ─────────────           ─────────────────       ──────────────────  │
│  As-is from source       Cleaned, validated       Aggregated,        │
│  CSV, JSON, XML          Parquet, Delta            business-ready    │
│  Immutable (append)      Deduplicated              Serving layer     │
│                          Schema enforced           Power BI, reports │
│                                                                      │
│  Ingest via ADF          Transform via Databricks  Load to Synapse   │
│  Event Hubs              or Synapse Spark           or serve via      │
│  IoT Hub                 dbt for SQL transforms     Synapse SQL pool  │
└──────────────────────────────────────────────────────────────────────┘
```

### ADLS Gen2 vs Alternatives

| | ADLS Gen2 | Azure Blob (flat) | Azure Files |
|---|---|---|---|
| HNS (true directories) | ✅ | ❌ | ✅ |
| POSIX ACLs | ✅ | ❌ | Limited |
| Spark/Hadoop native | ✅ abfs:// | Limited wasb:// | ❌ |
| Atomic directory ops | ✅ O(1) | ❌ O(n) | ✅ |
| Blob access tiers | ✅ (via underlying Blob) | ✅ | ❌ |
| Mountable as drive | ❌ (NFS 3.0 preview) | ❌ | ✅ SMB/NFS |
| Best for | Analytics, data lake | Object storage | Shared file system |

---

## Part 4 — Storage Account Configuration Essentials

### Key Settings at Account Creation

| Setting | Options | Notes |
|---|---|---|
| **Performance** | Standard / Premium | Premium = SSD, single region only |
| **Redundancy** | LRS / ZRS / GRS / GZRS / RA-GRS / RA-GZRS | Affects cost and availability |
| **Access tier (default)** | Hot / Cool | Inherited by blobs unless overridden |
| **Hierarchical namespace** | Enabled / Disabled | Enables ADLS Gen2; one-way toggle |
| **Secure transfer required** | Enabled (default) | Forces HTTPS only — keep ON |
| **Minimum TLS version** | 1.0 / 1.1 / 1.2 | Set to TLS 1.2 minimum |
| **Public blob access** | Enabled / Disabled | Allow anonymous access to containers |
| **Shared key access** | Enabled / Disabled | Disable to enforce Azure AD only |

### Networking Options

```
Public endpoint (all networks)     → Open to internet (restrict with firewall rules)
Public endpoint (selected networks) → Specific VNets + IP ranges only
Private endpoint                   → Traffic stays within Azure backbone (no public IP)
Disabled                           → No public access at all
```

```bash
# Restrict storage to a specific VNet subnet
az storage account network-rule add \
  --resource-group myRG \
  --account-name mystorageacct \
  --vnet-name myVNet \
  --subnet mySubnet

# Set default action to Deny (whitelist mode)
az storage account update \
  --name mystorageacct \
  --resource-group myRG \
  --default-action Deny
```

### Lifecycle Policy — Full Example

```json
{
  "rules": [
    {
      "name": "tiering-policy",
      "enabled": true,
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["raw/"]
        },
        "actions": {
          "baseBlob": {
            "tierToCool":    { "daysAfterModificationGreaterThan": 30 },
            "tierToCold":    { "daysAfterModificationGreaterThan": 90 },
            "tierToArchive": { "daysAfterModificationGreaterThan": 180 },
            "delete":        { "daysAfterModificationGreaterThan": 730 }
          },
          "snapshot": {
            "delete": { "daysAfterCreationGreaterThan": 90 }
          }
        }
      }
    }
  ]
}
```

---

## Exam Key Points Summary

| Topic | Key Fact |
|---|---|
| Default account type | GPv2 — use for everything unless you need Premium |
| GPv1 / Blob Storage accounts | Legacy — Microsoft recommends migrating to GPv2 |
| Premium accounts | SSD only, single-region (LRS or ZRS max), no Archive tier |
| LRS durability | 11 nines, 3 copies in 1 datacenter |
| ZRS durability | 12 nines, 3 copies across 3 AZs |
| GRS/GZRS durability | 16 nines, 6 copies across 2 regions |
| RA-GRS secondary endpoint | Append `-secondary` to account name in URL |
| After failover | Account becomes LRS — you must reconfigure replication |
| HNS toggle | One-way: once enabled, cannot be disabled |
| ADLS Gen2 protocol | `abfs://` or `abfss://` — NOT the old `wasb://` |
| ADLS Gen2 = | GPv2 storage account + HNS enabled |
| POSIX ACLs | Only available with HNS (ADLS Gen2) — not plain Blob |
| RBAC vs ACL | Both apply — more permissive wins; Owner bypasses ACL |
| Secure transfer | Enabled by default — forces HTTPS; keep it on |
| Rename 1M files in Blob | O(n) — must copy+delete each file |
| Rename 1M files in ADLS Gen2 | O(1) — single directory pointer update |
| NFS on ADLS Gen2 | Requires Premium Block Blob account + HNS |

---

