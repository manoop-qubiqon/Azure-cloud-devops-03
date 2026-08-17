# Azure Database Services — Detailed Study Notes


---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                     AZURE DATABASE SERVICES                         │
├──────────────────┬──────────────────┬───────────────────────────────┤
│  RELATIONAL (SQL) │   NoSQL / DIST.  │      CACHING / SPEED          │
│                  │                  │                               │
│  Azure SQL DB    │  Cosmos DB       │  Azure Cache for Redis        │
│  Azure DB for    │  (multi-API)     │  (in-memory key-value)        │
│  PostgreSQL      │                  │                               │
│  Azure DB for    │                  │                               │
│  MySQL           │                  │                               │
└──────────────────┴──────────────────┴───────────────────────────────┘
         │                  │                        │
         └──────────────────┴────────────────────────┘
                            │
              ┌─────────────▼─────────────┐
              │   BACKUP & GEO-REDUNDANCY │
              │  Point-in-time restore    │
              │  Geo-replication          │
              │  Zone-redundant replicas  │
              └───────────────────────────┘
```

---

## 1. Azure SQL Database (Managed SQL Server)

### What It Is
Fully managed PaaS relational database based on **SQL Server engine**. Handles patching, backups, HA automatically. No OS/server management needed.

### Key Tiers

| Tier | Use Case | Pricing Model |
|------|----------|---------------|
| **General Purpose** | Most workloads | vCores + storage |
| **Business Critical** | High IOPS, low latency, read replicas | vCores (premium) |
| **Hyperscale** | Large databases (up to 100 TB) | vCores + autoscale |
| **Serverless** | Intermittent/unpredictable load | Per second (auto-pause) |

### CLI Commands

```bash
# ── Variables ─────────────────────────────────────────────────────────
RG="contoso-rg"
LOCATION="eastus"
SERVER="contoso-sqlserver-001"
DB="contoso-db"
ADMIN="sqladmin"
PASSWORD="P@ssword1234!"

# ── Create Resource Group ─────────────────────────────────────────────
az group create \
  --name $RG \
  --location $LOCATION

# ── Create SQL Server (logical server) ───────────────────────────────
az sql server create \
  --name $SERVER \
  --resource-group $RG \
  --location $LOCATION \
  --admin-user $ADMIN \
  --admin-password $PASSWORD

# ── Create SQL Database ───────────────────────────────────────────────
az sql db create \
  --resource-group $RG \
  --server $SERVER \
  --name $DB \
  --service-objective S3 \
  --backup-storage-redundancy Geo

# ── Create using vCore model (General Purpose) ───────────────────────
az sql db create \
  --resource-group $RG \
  --server $SERVER \
  --name $DB \
  --edition GeneralPurpose \
  --family Gen5 \
  --capacity 4 \
  --compute-model Serverless \
  --auto-pause-delay 60

# ── Allow Azure services to access the server ────────────────────────
az sql server firewall-rule create \
  --resource-group $RG \
  --server $SERVER \
  --name "AllowAzureServices" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# ── Add client IP to firewall ─────────────────────────────────────────
az sql server firewall-rule create \
  --resource-group $RG \
  --server $SERVER \
  --name "MyClientIP" \
  --start-ip-address 203.0.113.5 \
  --end-ip-address 203.0.113.5

# ── Enable Active Geo-Replication ─────────────────────────────────────
az sql db replica create \
  --resource-group $RG \
  --server $SERVER \
  --name $DB \
  --partner-server contoso-sqlserver-secondary \
  --partner-resource-group $RG

# ── Failover to secondary ─────────────────────────────────────────────
az sql db replica set-primary \
  --resource-group $RG \
  --server contoso-sqlserver-secondary \
  --name $DB

# ── Scale up the database ─────────────────────────────────────────────
az sql db update \
  --resource-group $RG \
  --server $SERVER \
  --name $DB \
  --service-objective P1

# ── View connection string ────────────────────────────────────────────
az sql db show-connection-string \
  --server $SERVER \
  --name $DB \
  --client ado.net

# ── List databases on a server ───────────────────────────────────────
az sql db list \
  --resource-group $RG \
  --server $SERVER \
  --output table

# ── Delete database ───────────────────────────────────────────────────
az sql db delete \
  --resource-group $RG \
  --server $SERVER \
  --name $DB \
  --yes
```

### Connection Example (Python)
```python
import pyodbc

conn = pyodbc.connect(
    "Driver={ODBC Driver 18 for SQL Server};"
    f"Server=tcp:{SERVER}.database.windows.net,1433;"
    f"Database={DB};"
    f"Uid={ADMIN};"
    f"Pwd={PASSWORD};"
    "Encrypt=yes;TrustServerCertificate=no;"
)
cursor = conn.cursor()
cursor.execute("SELECT TOP 5 * FROM Orders")
for row in cursor.fetchall():
    print(row)
```

### Exam Tips
> ⚠️ **AZ-104:** Azure SQL Database ≠ SQL Server on VM. SQL DB is PaaS — no OS access.
> - **DTU model** = bundled compute+IO+memory; **vCore model** = separate compute/storage — use vCore for Azure Hybrid Benefit (BYOL).
> - Serverless auto-pauses after inactivity — first query after pause has cold-start latency.
> - Firewall is at **server level** (all DBs) or **database level** (specific DB).

---

## 2. Azure Cosmos DB — NoSQL Globally Distributed

### What It Is
Microsoft's globally distributed, multi-model NoSQL database. Guarantees **single-digit millisecond latency** at any scale, anywhere. Supports multiple APIs.

### API Options

| API | Use Case | Wire Protocol |
|-----|----------|---------------|
| **NoSQL (Core)** | JSON documents, default | Cosmos SDK |
| **MongoDB** | Migrate existing Mongo apps | MongoDB protocol |
| **Cassandra** | Wide-column, IoT, time-series | CQL |
| **Gremlin** | Graph data, relationships | Gremlin |
| **Table** | Key-value, Azure Table migration | OData |
| **PostgreSQL** | Distributed relational (Citus) | PostgreSQL wire |

### Consistency Levels (Weakest → Strongest)

```
Eventual → Consistent Prefix → Session → Bounded Staleness → Strong
  (best perf)                 (default)                  (highest latency)
```

| Level | Guarantee | Latency |
|-------|-----------|---------|
| Strong | Always reads latest | Highest |
| Bounded Staleness | Lag bounded by K ops or T time | High |
| Session | Consistent within a session | Medium |
| Consistent Prefix | No out-of-order reads | Low |
| Eventual | No ordering guarantee | Lowest |

### CLI Commands

```bash
# ── Variables ─────────────────────────────────────────────────────────
RG="contoso-rg"
COSMOS_ACCOUNT="contoso-cosmos-001"
DB_NAME="contoso-nosqldb"
CONTAINER="orders"
PARTITION_KEY="/customerId"

# ── Create Cosmos DB Account ──────────────────────────────────────────
az cosmosdb create \
  --name $COSMOS_ACCOUNT \
  --resource-group $RG \
  --kind GlobalDocumentDB \
  --default-consistency-level Session \
  --locations regionName="East US" failoverPriority=0 isZoneRedundant=True \
  --locations regionName="West US" failoverPriority=1 isZoneRedundant=False \
  --enable-automatic-failover true

# ── Create MongoDB API Account ────────────────────────────────────────
az cosmosdb create \
  --name contoso-mongo-001 \
  --resource-group $RG \
  --kind MongoDB \
  --server-version 4.2 \
  --default-consistency-level Session

# ── Create NoSQL Database ─────────────────────────────────────────────
az cosmosdb sql database create \
  --account-name $COSMOS_ACCOUNT \
  --resource-group $RG \
  --name $DB_NAME

# ── Create Container with partition key ───────────────────────────────
az cosmosdb sql container create \
  --account-name $COSMOS_ACCOUNT \
  --resource-group $RG \
  --database-name $DB_NAME \
  --name $CONTAINER \
  --partition-key-path $PARTITION_KEY \
  --throughput 400

# ── Enable autoscale (instead of fixed RU/s) ─────────────────────────
az cosmosdb sql container create \
  --account-name $COSMOS_ACCOUNT \
  --resource-group $RG \
  --database-name $DB_NAME \
  --name "orders-autoscale" \
  --partition-key-path $PARTITION_KEY \
  --max-throughput 4000

# ── Add a region (global distribution) ───────────────────────────────
az cosmosdb update \
  --name $COSMOS_ACCOUNT \
  --resource-group $RG \
  --locations regionName="East US" failoverPriority=0 \
              regionName="West Europe" failoverPriority=1 \
              regionName="Southeast Asia" failoverPriority=2

# ── Trigger manual failover ───────────────────────────────────────────
az cosmosdb failover-priority-change \
  --name $COSMOS_ACCOUNT \
  --resource-group $RG \
  --failover-policies "West US=0" "East US=1"

# ── Get connection string ─────────────────────────────────────────────
az cosmosdb keys list \
  --name $COSMOS_ACCOUNT \
  --resource-group $RG \
  --type connection-strings

# ── Get primary key ───────────────────────────────────────────────────
az cosmosdb keys list \
  --name $COSMOS_ACCOUNT \
  --resource-group $RG \
  --type keys \
  --query primaryMasterKey \
  --output tsv

# ── List containers ───────────────────────────────────────────────────
az cosmosdb sql container list \
  --account-name $COSMOS_ACCOUNT \
  --resource-group $RG \
  --database-name $DB_NAME \
  --output table
```

### SDK Example (Python — NoSQL API)
```python
from azure.cosmos import CosmosClient, PartitionKey

ENDPOINT = "https://contoso-cosmos-001.documents.azure.com:443/"
KEY = "<your-primary-key>"

client = CosmosClient(ENDPOINT, KEY)
database = client.get_database_client("contoso-nosqldb")
container = database.get_container_client("orders")

# Insert a document
container.upsert_item({
    "id": "order-001",
    "customerId": "cust-42",
    "product": "Azure T-Shirt",
    "quantity": 3,
    "total": 59.97
})

# Query documents
query = "SELECT * FROM c WHERE c.customerId = 'cust-42'"
for item in container.query_items(query=query, enable_cross_partition_query=True):
    print(item)
```

### Exam Tips
> ⚠️ **AZ-104:**
> - **RU/s (Request Units)** = currency for Cosmos DB throughput. 1 RU = read of 1 KB item.
> - Partition key choice is **critical** — high cardinality, even distribution. Bad partition key = hot partitions.
> - **Free tier** = 1000 RU/s + 25 GB storage free per subscription (one account only).
> - Automatic failover requires `--enable-automatic-failover true` at account creation.
> - Strong consistency is not available for multi-region write accounts.

---

## 3. Azure Database for PostgreSQL

### What It Is
Fully managed open-source PostgreSQL as a PaaS service. Two deployment modes:

| Mode | Description |
|------|-------------|
| **Flexible Server** | Recommended. More control, better cost, stop/start. |
| **Single Server** | Legacy, being retired — avoid for new projects. |

### CLI Commands

```bash
# ── Variables ─────────────────────────────────────────────────────────
RG="contoso-rg"
PG_SERVER="contoso-postgres-001"
PG_DB="contosodb"
ADMIN="pgadmin"
PASSWORD="P@ssword1234!"
LOCATION="eastus"

# ── Create Flexible Server ────────────────────────────────────────────
az postgres flexible-server create \
  --name $PG_SERVER \
  --resource-group $RG \
  --location $LOCATION \
  --admin-user $ADMIN \
  --admin-password $PASSWORD \
  --sku-name Standard_D2s_v3 \
  --tier GeneralPurpose \
  --storage-size 128 \
  --version 16 \
  --high-availability ZoneRedundant \
  --zone 1 \
  --standby-zone 3

# ── Create database inside server ────────────────────────────────────
az postgres flexible-server db create \
  --resource-group $RG \
  --server-name $PG_SERVER \
  --database-name $PG_DB

# ── Configure firewall (allow client IP) ─────────────────────────────
az postgres flexible-server firewall-rule create \
  --resource-group $RG \
  --name $PG_SERVER \
  --rule-name "AllowMyIP" \
  --start-ip-address 203.0.113.5 \
  --end-ip-address 203.0.113.5

# ── Allow all Azure services ──────────────────────────────────────────
az postgres flexible-server firewall-rule create \
  --resource-group $RG \
  --name $PG_SERVER \
  --rule-name "AllowAzureServices" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# ── Stop server (save cost when not in use) ───────────────────────────
az postgres flexible-server stop \
  --resource-group $RG \
  --name $PG_SERVER

# ── Start server ──────────────────────────────────────────────────────
az postgres flexible-server start \
  --resource-group $RG \
  --name $PG_SERVER

# ── Restore from backup (point-in-time) ──────────────────────────────
az postgres flexible-server restore \
  --resource-group $RG \
  --name "contoso-postgres-restored" \
  --source-server $PG_SERVER \
  --restore-time "2025-06-15T08:00:00Z"

# ── Scale compute tier ────────────────────────────────────────────────
az postgres flexible-server update \
  --resource-group $RG \
  --name $PG_SERVER \
  --sku-name Standard_D4s_v3

# ── Create read replica ───────────────────────────────────────────────
az postgres flexible-server replica create \
  --replica-name "contoso-postgres-replica" \
  --resource-group $RG \
  --source-server $PG_SERVER \
  --location "westus"

# ── Connect using psql ────────────────────────────────────────────────
psql \
  --host="${PG_SERVER}.postgres.database.azure.com" \
  --port=5432 \
  --username="${ADMIN}" \
  --dbname="${PG_DB}" \
  --set=sslmode=require
```

### Connection Example (Python)
```python
import psycopg2

conn = psycopg2.connect(
    host="contoso-postgres-001.postgres.database.azure.com",
    port=5432,
    database="contosodb",
    user="pgadmin",
    password="P@ssword1234!",
    sslmode="require"
)
cur = conn.cursor()
cur.execute("SELECT version();")
print(cur.fetchone())
conn.close()
```

---

## 4. Azure Database for MySQL

### What It Is
Fully managed MySQL as PaaS. Same Flexible Server architecture as PostgreSQL. Supports MySQL 8.0.

### CLI Commands

```bash
# ── Variables ─────────────────────────────────────────────────────────
RG="contoso-rg"
MYSQL_SERVER="contoso-mysql-001"
MYSQL_DB="shopdb"
ADMIN="mysqladmin"
PASSWORD="P@ssword1234!"
LOCATION="eastus"

# ── Create MySQL Flexible Server ──────────────────────────────────────
az mysql flexible-server create \
  --name $MYSQL_SERVER \
  --resource-group $RG \
  --location $LOCATION \
  --admin-user $ADMIN \
  --admin-password $PASSWORD \
  --sku-name Standard_D2ds_v4 \
  --tier GeneralPurpose \
  --storage-size 64 \
  --version 8.0.21 \
  --high-availability ZoneRedundant \
  --zone 1 \
  --standby-zone 2

# ── Create database ───────────────────────────────────────────────────
az mysql flexible-server db create \
  --resource-group $RG \
  --server-name $MYSQL_SERVER \
  --database-name $MYSQL_DB

# ── Configure firewall ────────────────────────────────────────────────
az mysql flexible-server firewall-rule create \
  --resource-group $RG \
  --name $MYSQL_SERVER \
  --rule-name "AllowMyIP" \
  --start-ip-address 203.0.113.5 \
  --end-ip-address 203.0.113.5

# ── Stop / Start server ───────────────────────────────────────────────
az mysql flexible-server stop --resource-group $RG --name $MYSQL_SERVER
az mysql flexible-server start --resource-group $RG --name $MYSQL_SERVER

# ── Point-in-time restore ─────────────────────────────────────────────
az mysql flexible-server restore \
  --resource-group $RG \
  --name "contoso-mysql-restored" \
  --source-server $MYSQL_SERVER \
  --restore-time "2025-06-15T08:00:00Z"

# ── Create read replica ───────────────────────────────────────────────
az mysql flexible-server replica create \
  --replica-name "contoso-mysql-replica" \
  --resource-group $RG \
  --source-server $MYSQL_SERVER

# ── Connect using mysql CLI ───────────────────────────────────────────
mysql \
  --host="${MYSQL_SERVER}.mysql.database.azure.com" \
  --user="${ADMIN}" \
  --password="${PASSWORD}" \
  --ssl-mode=REQUIRED \
  --database="${MYSQL_DB}"
```

### PostgreSQL vs MySQL — Quick Comparison

| Feature | PostgreSQL Flexible | MySQL Flexible |
|---------|---------------------|----------------|
| Max Storage | 32 TB | 16 TB |
| Extensions | Rich (PostGIS, uuid-ossp, etc.) | Limited |
| JSON Support | JSONB (binary, indexed) | JSON (text) |
| Stored Procedures | PL/pgSQL | Yes |
| Read Replicas | Yes | Yes |
| Zone Redundant HA | Yes | Yes |
| Best For | Complex queries, GIS, analytics | Web apps, WordPress, Laravel |

---

## 5. Azure Cache for Redis

### What It Is
Fully managed **in-memory data store** based on open-source Redis. Used for caching, session management, pub/sub messaging, leaderboards, and rate limiting.

### Tiers

| Tier | RAM | Clustering | Persistence | Use Case |
|------|-----|------------|-------------|----------|
| **Basic** | 250 MB – 53 GB | No | No | Dev/Test only |
| **Standard** | 250 MB – 53 GB | No | Yes | Production with HA |
| **Premium** | 6 GB – 1.2 TB | Yes (10 shards) | Yes | High throughput, VNet |
| **Enterprise** | 12 GB+ | Yes | Yes | RediSearch, RedisJSON |
| **Enterprise Flash** | Large + SSD | Yes | Yes | Cost-effective large cache |

### CLI Commands

```bash
# ── Variables ─────────────────────────────────────────────────────────
RG="contoso-rg"
REDIS_NAME="contoso-redis-001"
LOCATION="eastus"

# ── Create Redis Cache (Standard tier, 1 GB) ──────────────────────────
az redis create \
  --name $REDIS_NAME \
  --resource-group $RG \
  --location $LOCATION \
  --sku Standard \
  --vm-size c1 \
  --enable-non-ssl-port false

# ── Common vm-size values:
# Basic/Standard: c0(250MB), c1(1GB), c2(2.5GB), c3(6GB), c4(13GB), c6(53GB)
# Premium: p1(6GB), p2(13GB), p3(26GB), p4(53GB)

# ── Create Premium cache with clustering (3 shards) ───────────────────
az redis create \
  --name "contoso-redis-premium" \
  --resource-group $RG \
  --location $LOCATION \
  --sku Premium \
  --vm-size p1 \
  --shard-count 3

# ── Get access keys ───────────────────────────────────────────────────
az redis list-keys \
  --name $REDIS_NAME \
  --resource-group $RG

# ── Get hostname and port ─────────────────────────────────────────────
az redis show \
  --name $REDIS_NAME \
  --resource-group $RG \
  --query "{host:hostName, sslPort:sslPort, port:port}" \
  --output table

# ── Regenerate access key ─────────────────────────────────────────────
az redis regenerate-keys \
  --name $REDIS_NAME \
  --resource-group $RG \
  --key-type Primary

# ── Enable Redis persistence (RDB snapshot) ───────────────────────────
az redis update \
  --name $REDIS_NAME \
  --resource-group $RG \
  --set "redisConfiguration.rdb-backup-enabled=true" \
        "redisConfiguration.rdb-backup-frequency=60" \
        "redisConfiguration.rdb-storage-connection-string=<storage-conn-string>"

# ── Scale up cache ────────────────────────────────────────────────────
az redis update \
  --name $REDIS_NAME \
  --resource-group $RG \
  --sku Standard \
  --vm-size c3

# ── Delete cache ──────────────────────────────────────────────────────
az redis delete \
  --name $REDIS_NAME \
  --resource-group $RG \
  --yes
```

### Connection Example (Python)
```python
import redis

# Connect using SSL (always use SSL in production)
r = redis.StrictRedis(
    host="contoso-redis-001.redis.cache.windows.net",
    port=6380,
    password="<your-access-key>",
    ssl=True
)

# Basic operations
r.set("session:user-42", '{"name":"Manoop","role":"admin"}', ex=3600)  # TTL=1hr
data = r.get("session:user-42")
print(data)

# Increment counter (rate limiting)
r.incr("api:calls:user-42")
r.expire("api:calls:user-42", 60)  # Reset every minute

# Cache aside pattern
def get_user(user_id):
    cache_key = f"user:{user_id}"
    cached = r.get(cache_key)
    if cached:
        return cached  # Cache hit
    # Cache miss — fetch from DB
    user = db.query(f"SELECT * FROM users WHERE id = {user_id}")
    r.setex(cache_key, 300, str(user))  # Cache for 5 min
    return user
```

### Common Redis Data Structures

```bash
# String (cache)
SET key value EX 3600          # Set with TTL
GET key

# Hash (object)
HSET user:42 name "Manoop" role "admin"
HGET user:42 name
HGETALL user:42

# List (queue / timeline)
LPUSH queue:jobs "job-001"
RPOP queue:jobs

# Set (unique tags)
SADD tags:post-1 "azure" "cloud" "devops"
SMEMBERS tags:post-1

# Sorted Set (leaderboard)
ZADD leaderboard 1500 "player-1"
ZADD leaderboard 2300 "player-2"
ZRANGE leaderboard 0 -1 WITHSCORES REV
```

---

## 6. Database Backups and Geo-Redundancy

### Backup Overview by Service

| Service | Auto Backup | Retention | PITR | Geo-Redundant |
|---------|-------------|-----------|------|---------------|
| Azure SQL DB | ✅ Yes | 7–35 days | ✅ Yes | Optional |
| Cosmos DB | ✅ Continuous | 30 days (continuous) | ✅ Yes | Built-in |
| PostgreSQL Flexible | ✅ Yes | 7–35 days | ✅ Yes | Optional |
| MySQL Flexible | ✅ Yes | 7–35 days | ✅ Yes | Optional |
| Redis | Manual (RDB/AOF) | N/A | ❌ No | Via geo-replication |

### Azure SQL — Backup & Restore

```bash
# ── List available restore points ─────────────────────────────────────
az sql db list-deleted \
  --resource-group $RG \
  --server $SERVER

# ── Point-in-time restore (new DB from backup) ────────────────────────
az sql db restore \
  --resource-group $RG \
  --server $SERVER \
  --name "contoso-db-restored" \
  --source-database $DB \
  --time "2025-06-15T08:00:00Z"

# ── Configure long-term backup retention (up to 10 years) ────────────
az sql db ltr-policy set \
  --resource-group $RG \
  --server $SERVER \
  --database $DB \
  --weekly-retention P4W \
  --monthly-retention P12M \
  --yearly-retention P5Y \
  --week-of-year 1

# ── List LTR backups ──────────────────────────────────────────────────
az sql db ltr-backup list \
  --location eastus \
  --server $SERVER \
  --database $DB

# ── Restore from LTR backup ───────────────────────────────────────────
BACKUP_ID=$(az sql db ltr-backup list \
  --location eastus --server $SERVER --database $DB \
  --query "[0].id" --output tsv)

az sql db ltr-backup restore \
  --backup-id $BACKUP_ID \
  --dest-database "contoso-db-ltr-restore" \
  --dest-server $SERVER \
  --dest-resource-group $RG
```

### Cosmos DB — Backup Modes

```bash
# ── Enable continuous backup (PITR) at account creation ──────────────
az cosmosdb create \
  --name $COSMOS_ACCOUNT \
  --resource-group $RG \
  --backup-policy-type Continuous \
  --continuous-tier Continuous30Days

# ── Restore Cosmos DB (continuous backup) ────────────────────────────
az cosmosdb restore \
  --account-name "contoso-cosmos-restored" \
  --resource-group $RG \
  --source-database-account-name $COSMOS_ACCOUNT \
  --restore-timestamp "2025-06-15T10:00:00Z" \
  --location "East US"

# ── Trigger on-demand backup (periodic mode) ─────────────────────────
az cosmosdb update \
  --name $COSMOS_ACCOUNT \
  --resource-group $RG \
  --backup-interval 240 \
  --backup-retention 24

# ── Check backup policy ───────────────────────────────────────────────
az cosmosdb show \
  --name $COSMOS_ACCOUNT \
  --resource-group $RG \
  --query "backupPolicy"
```

### PostgreSQL / MySQL — Backup & Geo-Restore

```bash
# ── Point-in-time restore (PostgreSQL) ───────────────────────────────
az postgres flexible-server restore \
  --resource-group $RG \
  --name "pg-pitr-restored" \
  --source-server $PG_SERVER \
  --restore-time "2025-06-15T08:00:00Z"

# ── Geo-restore (restore to different region) ────────────────────────
az postgres flexible-server geo-restore \
  --resource-group $RG \
  --name "pg-geo-restored" \
  --source-server "/subscriptions/<sub-id>/resourceGroups/$RG/providers/Microsoft.DBforPostgreSQL/flexibleServers/$PG_SERVER" \
  --location "West US"

# ── Point-in-time restore (MySQL) ────────────────────────────────────
az mysql flexible-server restore \
  --resource-group $RG \
  --name "mysql-pitr-restored" \
  --source-server $MYSQL_SERVER \
  --restore-time "2025-06-15T08:00:00Z"

# ── Geo-restore (MySQL) ───────────────────────────────────────────────
az mysql flexible-server geo-restore \
  --resource-group $RG \
  --name "mysql-geo-restored" \
  --source-server $MYSQL_SERVER \
  --location "West Europe"
```

### Geo-Redundancy Architecture

```
                ┌─────────────────────────────────────────────┐
                │              PRIMARY REGION (East US)       │
                │  ┌─────────────┐   ┌──────────────────────┐ │
                │  │  SQL Server │   │  PostgreSQL Flexible  │ │
                │  │  Primary DB │   │  Primary + Standby    │ │
                │  └──────┬──────┘   └──────────┬───────────┘ │
                └─────────┼────────────────────┼─────────────┘
                           │ Async replication  │
                           ▼                    ▼
                ┌─────────────────────────────────────────────┐
                │            SECONDARY REGION (West US)       │
                │  ┌─────────────┐   ┌──────────────────────┐ │
                │  │  SQL Server │   │  Geo-Restore Target   │ │
                │  │  Geo-Replica│   │  (On-demand restore)  │ │
                │  └─────────────┘   └──────────────────────┘ │
                └─────────────────────────────────────────────┘
```

### Backup Redundancy Options

| Storage Redundancy | Description | RPO Target |
|--------------------|-------------|------------|
| **LRS** (Locally Redundant) | 3 copies in 1 datacenter | Datacenter failure: data lost |
| **ZRS** (Zone Redundant) | 3 copies across AZs in 1 region | Zone failure: protected |
| **GRS** (Geo Redundant) | LRS + async copy to paired region | Region failure: protected |
| **GZRS** (Geo-Zone Redundant) | ZRS + async copy to paired region | Best protection |

```bash
# Set backup redundancy when creating Azure SQL DB
az sql db create \
  --resource-group $RG \
  --server $SERVER \
  --name $DB \
  --service-objective S3 \
  --backup-storage-redundancy Geo   # Options: Local, Zone, Geo, GeoZone
```

---

## 7. Service Comparison Summary

| Feature | Azure SQL DB | Cosmos DB | PostgreSQL | MySQL | Redis |
|---------|-------------|-----------|------------|-------|-------|
| **Type** | Relational | NoSQL | Relational | Relational | In-memory |
| **Global Distribution** | Via geo-replication | Native, built-in | Via replica | Via replica | Via geo-replication |
| **Latency** | <10ms (same region) | <10ms (any region) | <10ms | <10ms | <1ms |
| **Scale** | Up to 4 TB (Hyperscale: 100TB) | Unlimited | Up to 32 TB | Up to 16 TB | Up to 1.2 TB (Premium) |
| **Consistency Options** | Strong (ACID) | 5 levels | Strong (ACID) | Strong (ACID) | Eventual |
| **Open Source** | ❌ (SQL Server) | ❌ | ✅ | ✅ | ✅ |
| **Best For** | Enterprise apps, migrations | IoT, eCommerce, gaming | Web apps, analytics | Web apps, CMS | Caching, sessions |
| **Pricing Unit** | DTU or vCore | RU/s | vCore | vCore | Cache size (GB) |

---

## 8. Common Scenarios & Which Service to Choose

```
Need to cache API responses for < 1ms latency?
  └─► Azure Cache for Redis

Need relational DB, migrating from SQL Server?
  └─► Azure SQL Database

Need globally distributed, multi-region writes at any scale?
  └─► Azure Cosmos DB

Need open-source PostgreSQL with zone redundant HA?
  └─► Azure Database for PostgreSQL (Flexible Server)

Need open-source MySQL for WordPress / Laravel app?
  └─► Azure Database for MySQL (Flexible Server)

Need graph relationships between entities?
  └─► Cosmos DB with Gremlin API

Need full-text search with NoSQL documents?
  └─► Cosmos DB Enterprise with RediSearch
       OR Azure AI Search + Cosmos DB
```

---

## 9. Quick Reference — Resource Naming Conventions

```
SQL Server (logical):     <project>-sqlserver-<env>      e.g. contoso-sqlserver-prod
SQL Database:             <project>-db-<env>             e.g. contoso-db-prod
Cosmos DB Account:        <project>-cosmos-<env>         e.g. contoso-cosmos-prod
PostgreSQL Server:        <project>-postgres-<env>       e.g. contoso-postgres-prod
MySQL Server:             <project>-mysql-<env>          e.g. contoso-mysql-prod
Redis Cache:              <project>-redis-<env>          e.g. contoso-redis-prod
```

---

*Notes prepared for AZ-104 study & Contoso Retail project series | akumenbyq*