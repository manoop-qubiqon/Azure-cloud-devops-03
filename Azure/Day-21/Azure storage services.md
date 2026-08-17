# Azure Storage Services — Detailed Study Notes


---

## Overview — The Three Core Storage Types

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Azure Storage Account                           │
│                                                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐ │
│  │  Blob Storage   │  │  Azure Files    │  │   Managed Disks     │ │
│  │  (Object Store) │  │  (File Share)   │  │  (Block Device)     │ │
│  │                 │  │                 │  │                     │ │
│  │  Unstructured   │  │  SMB / NFS      │  │  HDD / SSD / Ultra  │ │
│  │  data at scale  │  │  mountable FS   │  │  attached to VMs    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

| Feature | Blob Storage | Azure Files | Managed Disks |
|---|---|---|---|
| Use case | Objects, media, backups | Shared file system | VM OS/data disks |
| Protocol | HTTP/HTTPS REST | SMB 3.0 / NFS 4.1 | Block I/O (internal) |
| Mountable? | No (API only) | Yes — like a network drive | Yes — as disk to VM |
| Max size | 190.7 TB per blob | 100 TiB per share | 64 TiB per disk |
| Shared access | Multi-client via API | True concurrent multi-mount | Single VM (standard) |

---

## 1. Azure Blob Storage

### What Is It?
A massively scalable **object storage** service. "Blob" = Binary Large Object. Think: S3 equivalent on Azure.

### Hierarchy

```
Storage Account
└── Container  (like a folder / bucket)
    └── Blob   (the actual file/object)
        ├── Block Blob    → files, media, backups (most common)
        ├── Append Blob   → log files (write-once, append-only)
        └── Page Blob     → random read/write (used by VHDs)
```

### Blob Types — When to Use What

| Blob Type | Internals | Best For |
|---|---|---|
| **Block Blob** | Split into blocks (up to 4000 blocks × 4000 MiB each) | Files, images, videos, backups |
| **Append Blob** | Can only append blocks; no modify/delete of existing | Log aggregation, event streams |
| **Page Blob** | 512-byte pages, random R/W | Azure VM disks (VHD/VHDX), databases |

> **Exam tip**: ADF, Data Lake Gen2, and Synapse all sit on top of Blob Storage with hierarchical namespace enabled.

---

### Access Tiers

Azure Blob has **4 access tiers** that trade off cost vs. access speed.

```
Frequency of Access
High ←─────────────────────────────────────────────────────→ Low

┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────────┐
│   HOT    │   │   COOL   │   │   COLD   │   │   ARCHIVE    │
│          │   │          │   │          │   │              │
│ Highest  │   │ Lower    │   │ Lowest   │   │ Cheapest     │
│ storage  │   │ storage  │   │ storage  │   │ storage cost │
│ cost     │   │ cost     │   │ cost     │   │              │
│ Lowest   │   │ Higher   │   │ Higher   │   │ Highest      │
│ access   │   │ access   │   │ access   │   │ access cost  │
│ cost     │   │ cost     │   │ cost     │   │              │
└──────────┘   └──────────┘   └──────────┘   └──────────────┘
  Instant        Instant        Instant       Rehydrate first
  access         access         access        (hours → days)
```

| Tier | Min Storage Duration | Retrieval Time | Use Case |
|---|---|---|---|
| **Hot** | None | Instant | Active data, frequent reads |
| **Cool** | 30 days | Instant | Backups accessed monthly |
| **Cold** | 90 days | Instant | Long-term, rarely accessed |
| **Archive** | 180 days | 1–15 hours (rehydrate) | Compliance, yearly access |

> **Rehydration**: To read an Archive blob, you must first "rehydrate" it to Hot or Cool. Two options:
> - Copy to a new blob at Hot/Cool tier (original stays archived)
> - Change tier in-place (takes hours)

#### Lifecycle Management Policy
Automate tier transitions and deletion with rules:

```json
{
  "rules": [{
    "name": "move-to-cool-after-30-days",
    "type": "Lifecycle",
    "definition": {
      "filters": { "blobTypes": ["blockBlob"] },
      "actions": {
        "baseBlob": {
          "tierToCool":    { "daysAfterModificationGreaterThan": 30 },
          "tierToArchive": { "daysAfterModificationGreaterThan": 90 },
          "delete":        { "daysAfterModificationGreaterThan": 365 }
        }
      }
    }
  }]
}
```

---

### Containers and Access Levels

```
Storage Account
  └── Container (access level set here, not per blob)
       ├── Private (default)      → No anonymous access
       ├── Blob                   → Anonymous read for blobs only
       └── Container              → Anonymous read for container + blobs
```

> **Best practice**: Keep containers Private. Use **SAS tokens** or **Azure AD** for controlled access.

### Access Options Summary

| Method | What It Is | When To Use |
|---|---|---|
| **Storage Account Key** | Master key, full access | Admin / automation only |
| **SAS Token** | Scoped, time-limited URL | External sharing, temp access |
| **Azure AD + RBAC** | Identity-based | Enterprise, managed identities |
| **Anonymous Access** | No auth needed | Public CDN content only |

### CLI Examples

```bash
# Create a storage account
az storage account create \
  --name mystorageacct \
  --resource-group myRG \
  --location eastus \
  --sku Standard_LRS

# Create a container
az storage container create \
  --name mycontainer \
  --account-name mystorageacct

# Upload a blob
az storage blob upload \
  --container-name mycontainer \
  --file ./data.csv \
  --name data/2024/data.csv \
  --account-name mystorageacct

# Change blob tier to Archive
az storage blob set-tier \
  --container-name mycontainer \
  --name data/2024/data.csv \
  --tier Archive \
  --account-name mystorageacct

# Generate SAS token (expires in 1 hour)
az storage blob generate-sas \
  --container-name mycontainer \
  --name data/2024/data.csv \
  --permissions r \
  --expiry 2024-12-31T23:59:00Z \
  --account-name mystorageacct
```

---

## 2. Azure Files

### What Is It?
A fully managed **cloud file share** accessible via **SMB** (Windows) or **NFS** (Linux). Mount it like a network drive. Drop-in replacement for on-prem file servers.

### Architecture

```
                  ┌─────────────────────────────┐
                  │     Storage Account          │
                  │   ┌─────────────────────┐   │
                  │   │    File Share        │   │
                  │   │   (e.g. /finance)    │   │
                  │   │                     │   │
                  │   │  /reports/          │   │
                  │   │  /templates/        │   │
                  │   │  /exports/          │   │
                  │   └─────────────────────┘   │
                  └─────────────────────────────┘
                            ↑         ↑
               ┌────────────┘         └────────────┐
               │                                   │
    ┌──────────────────┐               ┌─────────────────────┐
    │   Windows VM     │               │    Linux VM         │
    │  (SMB 3.0 mount) │               │  (NFS 4.1 mount)    │
    │  net use Z:      │               │  mount -t nfs ...   │
    └──────────────────┘               └─────────────────────┘
```

### SMB vs NFS

| | SMB | NFS |
|---|---|---|
| Protocol | SMB 3.0 | NFS 4.1 |
| OS | Windows, Linux, macOS | Linux only |
| Auth | Azure AD / Storage Key | Storage Key / RBAC |
| Port | 445 | 2049 |
| Performance tier | Standard or Premium | Premium only |

> **Port 445 issue**: Many ISPs block outbound port 445. On-premises SMB mounts may fail. Use **Azure VPN Gateway** or **ExpressRoute** as a workaround.

### Tiers

| Tier | Storage Type | IOPS | Use Case |
|---|---|---|---|
| **Transaction Optimized** | HDD (Standard) | Low | General purpose, low-frequency access |
| **Hot** | HDD (Standard) | Medium | Team shares, general collaboration |
| **Cool** | HDD (Standard) | Low | Archives, cold backup shares |
| **Premium** | SSD | Very high | Databases, dev environments, latency-sensitive |

### Key Features

**Azure File Sync** — Hybrid file server:
```
On-prem File Server ←─── Sync ───→ Azure File Share
  (cache layer,                      (cloud master,
   fast local access)                 full content)
```
- Only hot files stay cached on-prem
- Cold files recalled on demand
- Great for branch offices

**Snapshots** — Point-in-time backups:
```bash
# Create a share snapshot
az storage share snapshot --name myshare --account-name mystorageacct

# List snapshots
az storage share list --account-name mystorageacct --include-snapshots

# Restore a file from snapshot
az storage file copy start \
  --source-share myshare \
  --source-path reports/q1.xlsx \
  --source-snapshot "2024-01-15T08:00:00.0000000Z" \
  --destination-share myshare \
  --destination-path reports/q1-restored.xlsx \
  --account-name mystorageacct
```

### Mount Examples

**Windows (SMB):**
```powershell
# Mount Azure File Share on Windows
net use Z: \\mystorageacct.file.core.windows.net\myshare /user:Azure\mystorageacct <storage-account-key>

# Persistent mount (survives reboot)
cmdkey /add:mystorageacct.file.core.windows.net /user:Azure\mystorageacct /pass:<key>
net use Z: \\mystorageacct.file.core.windows.net\myshare /persistent:yes
```

**Linux (SMB):**
```bash
# Install cifs-utils
sudo apt install cifs-utils

# Mount
sudo mount -t cifs \
  //mystorageacct.file.core.windows.net/myshare /mnt/share \
  -o vers=3.0,username=mystorageacct,password=<key>,serverino

# fstab for persistent mount
//mystorageacct.file.core.windows.net/myshare /mnt/share \
  cifs vers=3.0,username=mystorageacct,password=<key>,serverino 0 0
```

**Linux (NFS — Premium only):**
```bash
sudo mount -t nfs \
  mystorageacct.file.core.windows.net:/mystorageacct/myshare \
  /mnt/share \
  -o vers=4,minorversion=1,sec=sys
```

---

## 3. Azure Managed Disks

### What Is It?
Block-level storage that **attaches directly to Azure VMs** as virtual hard disks. Azure manages the underlying storage infrastructure — you just pick size, type, and attach.

### Architecture

```
┌──────────────────────────────────────────────────────┐
│                    Azure VM                          │
│                                                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │   OS Disk   │  │  Data Disk  │  │ Temp Disk   │  │
│  │  (Managed)  │  │  (Managed)  │  │ (Non-perm.) │  │
│  │             │  │             │  │             │  │
│  │ Windows/    │  │ Databases,  │  │ Page file,  │  │
│  │ Linux image │  │ app data    │  │ swap space  │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  │
│        ↓                 ↓              ↓             │
└──────────────────────────────────────────────────────┘
         ↓                 ↓
┌─────────────────────────────────────────┐
│          Azure Storage Backend           │
│  (HDD / SSD / Ultra — you choose type)  │
└─────────────────────────────────────────┘
```

> **Temp Disk** ≠ Managed Disk. It lives on the physical host. Data is lost on VM deallocation/resize. Never store important data here.

### Disk Types — Full Comparison

| | Standard HDD | Standard SSD | Premium SSD | Premium SSD v2 | Ultra Disk |
|---|---|---|---|---|---|
| **Storage type** | HDD | SSD | SSD | SSD | SSD (NVMe) |
| **Max IOPS** | 2,000 | 6,000 | 20,000 | 80,000 | 400,000 |
| **Max throughput** | 500 MB/s | 750 MB/s | 900 MB/s | 1,200 MB/s | 4,000 MB/s |
| **Max size** | 32 TiB | 32 TiB | 32 TiB | 64 TiB | 64 TiB |
| **Latency** | High (ms) | Low (ms) | Low (ms) | Sub-ms | Sub-ms |
| **Use case** | Dev/test, cold backups | Web servers, light prod | Prod databases, SAP | Mission-critical DB | Extreme IOPS workloads |
| **Cost** | Cheapest | Low | Medium | Higher | Most expensive |

### When to Choose Which

```
Dev/Test workload         → Standard HDD
Web server / light prod   → Standard SSD
Production database       → Premium SSD
SAP HANA / SQL Server     → Premium SSD v2
Real-time analytics       → Ultra Disk
```

### Disk Roles on a VM

| Disk | Managed? | Persistent? | Notes |
|---|---|---|---|
| **OS Disk** | Yes | Yes | Created from image at VM provisioning |
| **Data Disk** | Yes | Yes | Attach multiple; max count depends on VM size |
| **Temp Disk** | No | No | Local SSD on host; lost on deallocation |
| **Cache Disk** | No | No | Write-back cache for Premium SSD |

### Disk Caching Options

| Mode | Behavior | Best For |
|---|---|---|
| **None** | No caching | Write-heavy workloads (log files, databases) |
| **Read-Only** | Cache reads, write direct | Read-heavy (OS, static data) |
| **Read/Write** | Cache reads and writes | Balanced workloads |

> **Exam tip**: Premium SSD supports Read/Write caching. Ultra Disk does NOT support caching.

### Snapshots and Images

```
VM Disk
  ├── Snapshot  → Point-in-time copy of a disk (incremental)
  │               Use: backup, clone, cross-region copy
  │
  └── Image     → Capture entire VM config + OS + data disks
                  Use: VM templates, scale sets, golden images
```

```bash
# Create a disk snapshot
az snapshot create \
  --name myDiskSnapshot \
  --resource-group myRG \
  --source /subscriptions/.../disks/myOSDisk

# Create a managed disk from snapshot
az disk create \
  --name myRestoredDisk \
  --resource-group myRG \
  --source myDiskSnapshot \
  --sku Premium_LRS

# Attach a data disk to a VM
az vm disk attach \
  --vm-name myVM \
  --resource-group myRG \
  --name myDataDisk \
  --new \
  --size-gb 128 \
  --sku Premium_LRS

# Detach a disk
az vm disk detach \
  --vm-name myVM \
  --resource-group myRG \
  --name myDataDisk
```

### Disk Encryption

| Type | What it encrypts | Keys |
|---|---|---|
| **Azure Disk Encryption (ADE)** | OS + data disks using BitLocker/DM-Crypt | Keys in Azure Key Vault |
| **Server-Side Encryption (SSE)** | Data at rest on storage | Platform-managed or CMK |
| **Encryption at host** | Temp disk + cache | Extends SSE to all disk types |

> **Default**: SSE with platform-managed keys is ON by default. No config needed for basic compliance.

### Availability Zones & Disk Redundancy

| Redundancy | Description | Use Case |
|---|---|---|
| **LRS** (Locally Redundant) | 3 copies in 1 datacenter | Default, cost-effective |
| **ZRS** (Zone Redundant) | 3 copies across 3 AZs | High availability, no ZRS for Premium v2 |
| **Ultra + ZRS** | Zone-redundant Ultra | Mission-critical, extreme HA |

---

## Architecture Decision Guide

```
What type of data do you have?
│
├── Unstructured files, media, blobs, logs?
│   └── Azure Blob Storage
│       ├── Accessed frequently?          → Hot tier
│       ├── Accessed monthly?             → Cool tier
│       ├── Accessed quarterly?           → Cold tier
│       └── Compliance / archive?         → Archive tier
│
├── Need a shared file system (mountable)?
│   └── Azure Files
│       ├── Windows workloads?            → SMB
│       ├── Linux workloads?              → NFS (Premium)
│       ├── Hybrid on-prem sync?          → Azure File Sync
│       └── High IOPS file shares?        → Premium tier
│
└── Block storage for a VM?
    └── Managed Disks
        ├── Dev / test?                   → Standard HDD
        ├── Web servers?                  → Standard SSD
        ├── Prod databases?               → Premium SSD
        ├── SAP / SQL critical?           → Premium SSD v2
        └── Extreme IOPS?                 → Ultra Disk
```

---

## Storage Account SKUs

| SKU | Redundancy | Supports |
|---|---|---|
| **Standard_LRS** | Local (single DC) | Blob, Files, Queues, Tables |
| **Standard_ZRS** | Zone (3 AZs) | Blob, Files |
| **Standard_GRS** | Geo (2 regions) | Blob, Files, Queues, Tables |
| **Standard_GZRS** | Geo + Zone | Blob, Files |
| **Premium_LRS** | Local | Block Blobs or Page Blobs or Files |
| **Premium_ZRS** | Zone | Block Blobs or Files |

> **Important**: Premium storage accounts are type-specific. A Premium account for Blob Storage **cannot** host Azure Files, and vice versa.

---

## Key Exam Points Summary

| Topic | Key Fact |
|---|---|
| Archive rehydration | Takes 1–15 hours; cannot read directly |
| Archive min retention | 180 days (early deletion fee applies) |
| Cool min retention | 30 days |
| Cold min retention | 90 days |
| SAS token | Scoped, time-limited, no Azure AD needed |
| Blob access tier default | Set at account level; blobs inherit unless overridden |
| Azure Files port | SMB = 445; NFS = 2049 |
| NFS shares | Premium tier only |
| Temp disk | NOT managed, NOT persistent |
| Ultra Disk caching | Not supported |
| ADE keys | Stored in Azure Key Vault |
| Default encryption | SSE with platform-managed keys — always ON |
| ZRS Managed Disks | Available for Standard SSD and Premium SSD (not Ultra, not Standard HDD) |
| Blob soft delete | Protects against accidental deletion — configure retention period |
| Append Blob | Write-once append model — ideal for logs |
| Page Blob | Used internally by Azure VHDs |

---

