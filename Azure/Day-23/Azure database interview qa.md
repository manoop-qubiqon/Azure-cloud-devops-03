# Azure Database Services — Real-Time Interview Q&A
> **Level:** Beginner → Advanced | **Tag:** `#akumenbyq` `#azure-interviews` `#az-104`

---

## How to Use This Guide

- Questions are grouped by **difficulty**: 🟢 Basic | 🟡 Intermediate | 🔴 Advanced
- Each answer includes **what the interviewer is really testing**
- Key phrases are marked — say these confidently in the interview
- Scenario-based questions simulate real on-the-job situations

---

## SECTION 1 — Azure SQL Database

---

### 🟢 Q1. What is Azure SQL Database and how is it different from SQL Server on a VM?

**Answer:**

Azure SQL Database is a **fully managed PaaS (Platform as a Service)** relational database built on the SQL Server engine. The key difference is in the management responsibility:

| Aspect | Azure SQL Database (PaaS) | SQL Server on VM (IaaS) |
|--------|--------------------------|-------------------------|
| OS Management | Microsoft manages | You manage |
| Patching | Automatic | Manual |
| Backups | Automatic | Manual |
| HA/DR | Built-in | You configure |
| Cost | Pay per usage | Pay for VM always |
| Custom extensions | Limited | Full control |

You choose SQL Server on a VM when you need OS-level access, specific SQL Server features not available in PaaS (like SQL Agent jobs in older versions), or are doing a lift-and-shift migration.

> 💡 **What the interviewer tests:** Do you understand the shared responsibility model and when to use PaaS vs IaaS?

---

### 🟢 Q2. What are DTU and vCore purchasing models in Azure SQL Database?

**Answer:**

**DTU (Database Transaction Unit)** is a bundled, pre-configured unit that combines CPU, memory, and I/O in a fixed ratio. It's simpler but less flexible.

**vCore (Virtual Core)** lets you independently choose the number of cores, memory, and storage. It also supports **Azure Hybrid Benefit** — meaning you can bring your existing SQL Server licenses to save up to 55% cost.

```
DTU Model:   Basic → Standard → Premium
vCore Model: General Purpose | Business Critical | Hyperscale
```

**When to recommend vCore:**
- You want to use existing SQL Server licenses (Azure Hybrid Benefit)
- You need more than 3 TB storage
- You want Serverless (auto-pause/resume) compute
- You need Business Critical tier (in-memory OLTP, readable replicas)

> 💡 **What the interviewer tests:** Cost optimization knowledge and ability to pick the right tier.

---

### 🟢 Q3. What is Serverless compute in Azure SQL Database?

**Answer:**

Serverless is a compute tier in Azure SQL Database (vCore model) where the database **automatically scales compute up and down** based on workload demand and **pauses automatically** during inactivity.

Key behaviors:
- You set a **min and max vCore range** (e.g., 0.5 to 4 vCores)
- When idle for a configurable delay (e.g., 60 minutes), the database pauses — **you pay only for storage**
- The first query after a pause triggers a **cold start** (a few seconds delay)

**Best for:** Dev/test environments, applications with intermittent or unpredictable usage.

**Not suitable for:** Latency-sensitive apps that cannot tolerate cold-start delays.

> 💡 **What the interviewer tests:** Cost awareness and understanding of trade-offs.

---

### 🟡 Q4. How does geo-replication work in Azure SQL Database?

**Answer:**

**Active Geo-Replication** creates readable secondary replicas in up to **4 other regions**. Replication is **asynchronous**, so there is a small lag (RPO typically < 5 seconds).

Architecture:
```
Primary DB (East US) ──async──► Secondary (West US)  [readable]
                     ──async──► Secondary (West EU)   [readable]
```

Key points:
- Secondary is **readable** — great for offloading reporting queries
- You can manually **failover** to a secondary (promote it to primary)
- For **automatic** failover, use **Failover Groups** — they provide a single connection endpoint that automatically redirects traffic after failover

```bash
# Create geo-replica
az sql db replica create \
  --resource-group myRG \
  --server primary-server \
  --name myDB \
  --partner-server secondary-server

# Failover (promote secondary to primary)
az sql db replica set-primary \
  --resource-group myRG \
  --server secondary-server \
  --name myDB
```

> 💡 **What the interviewer tests:** HA/DR knowledge and understanding of RTO/RPO.

---

### 🟡 Q5. What is Long-Term Retention (LTR) in Azure SQL Database?

**Answer:**

By default, Azure SQL Database keeps backups for **7 to 35 days** (configurable). Long-Term Retention extends this to **up to 10 years** by storing full database backups in Azure Blob Storage with read-access geo-redundant storage (RA-GRS).

You configure an LTR policy with:
- **Weekly** retention (e.g., keep last 4 weekly backups)
- **Monthly** retention (e.g., keep 12 monthly backups)
- **Yearly** retention (e.g., keep 5 yearly backups)

```bash
az sql db ltr-policy set \
  --resource-group myRG \
  --server myServer \
  --database myDB \
  --weekly-retention P4W \
  --monthly-retention P12M \
  --yearly-retention P5Y \
  --week-of-year 1
```

**Use case:** Compliance requirements (healthcare, finance) that mandate data retention for years.

> 💡 **What the interviewer tests:** Compliance and governance awareness.

---

### 🔴 Q6. A developer says their Azure SQL Database is slow during business hours but fine at night. What would you investigate?

**Answer:**

This is a classic **resource contention during peak load** scenario. I would investigate in this order:

**1. Check Query Performance Insight (Azure Portal)**
- Identify top resource-consuming queries by CPU, duration, or I/O
- Look for missing indexes, full table scans

**2. Check DTU/CPU utilization metrics**
```bash
az monitor metrics list \
  --resource "/subscriptions/.../databases/myDB" \
  --metric "dtu_consumption_percent" \
  --interval PT1H
```
If DTU is consistently hitting 80–100%, the database needs to be scaled up.

**3. Look for blocking and deadlocks**
- Enable **Query Store** to capture wait statistics
- Check `sys.dm_exec_requests` for blocking sessions

**4. Check connection pooling**
- Application might be opening too many connections

**5. Consider Read Scale-Out**
- If using Business Critical tier, offload read queries to the secondary replica
- Add `ApplicationIntent=ReadOnly` to connection string

**Root fixes:**
- Scale up compute tier
- Add missing indexes
- Rewrite expensive queries
- Enable Automatic Tuning (Azure will auto-create/drop indexes)

> 💡 **What the interviewer tests:** Real-world troubleshooting and performance tuning skills.

---

## SECTION 2 — Azure Cosmos DB

---

### 🟢 Q7. What is Azure Cosmos DB and what makes it different from traditional databases?

**Answer:**

Azure Cosmos DB is Microsoft's **globally distributed, multi-model NoSQL database** designed for modern applications that need:

- **Global distribution** — replicate data to any Azure region in minutes
- **Single-digit millisecond latency** — both read and write, at any scale
- **99.999% availability SLA** — five nines
- **Elastic scale** — throughput and storage scale independently

What makes it unique:
1. **Multi-API** — one service, many interfaces (SQL/NoSQL, MongoDB, Cassandra, Gremlin, Table)
2. **Turnkey global distribution** — add/remove regions with a click, no code changes
3. **Tunable consistency** — 5 levels from Strong to Eventual
4. **Automatic indexing** — all fields indexed by default, no schema required

> 💡 **What the interviewer tests:** Ability to articulate value proposition, not just features.

---

### 🟢 Q8. What are the 5 consistency levels in Cosmos DB? When would you use each?

**Answer:**

Cosmos DB offers 5 consistency levels, trading off **latency/throughput vs data accuracy:**

```
Strong ◄──────────────────────────────────► Eventual
(highest latency, strongest guarantee)   (lowest latency, weakest guarantee)
```

| Level | Guarantee | Use Case |
|-------|-----------|----------|
| **Strong** | Always reads latest committed write | Financial transactions, inventory |
| **Bounded Staleness** | Reads lag behind by K operations or T time | Global apps needing near-fresh data |
| **Session** *(default)* | Consistent within a user session | User profiles, shopping cart |
| **Consistent Prefix** | Never sees out-of-order writes | Social feeds, event streams |
| **Eventual** | No ordering guarantee, eventually consistent | Likes, view counts, analytics |

**Most common choice:** Session — it gives strong consistency for the user's own writes while allowing high throughput globally.

> 💡 **What the interviewer tests:** Deep understanding of distributed systems trade-offs.

---

### 🟡 Q9. What is a partition key in Cosmos DB and why is it so important?

**Answer:**

A partition key is the field Cosmos DB uses to **distribute data across physical partitions** (nodes). Once set at container creation, it **cannot be changed**.

**Why it matters:**
- Cosmos DB distributes data into logical partitions based on partition key value
- Each logical partition has a **20 GB limit**
- All items with the same partition key land in the same logical partition
- Cross-partition queries are slower and more expensive (consume more RU/s)

**Choosing a good partition key:**
```
✅ High cardinality    — many unique values (userId, orderId, deviceId)
✅ Even distribution   — no single value dominates (avoid status: "active/inactive")
✅ Frequent in queries — used in WHERE clause to avoid cross-partition scans
✅ Immutable           — value should not change after insert
```

**Bad partition key example:** `country` — if 80% of your users are from the US, that partition becomes a **hot partition** and throttles performance.

**Good partition key example:** `customerId` for an order management system — evenly distributed, high cardinality, used in most queries.

> 💡 **What the interviewer tests:** This is one of the most common Cosmos DB interview questions. Interviewers look for real understanding, not just a definition.

---

### 🟡 Q10. What are Request Units (RU/s) in Cosmos DB?

**Answer:**

**Request Units (RU/s)** are the **currency of throughput** in Cosmos DB. Every database operation (read, write, query, delete) consumes a certain number of RUs based on:
- Item size
- Item complexity (number of properties)
- Operation type (point read vs query vs write)
- Indexing policy

**Reference point:** Reading a **1 KB item by its ID and partition key** (point read) costs exactly **1 RU**.

| Operation | Approx RU Cost |
|-----------|---------------|
| Point read (1 KB item) | 1 RU |
| Write (1 KB item) | 5 RU |
| Cross-partition query | 10–100+ RU |
| Stored procedure | Varies |

**Provisioned vs Autoscale:**
- **Provisioned:** You set a fixed RU/s (e.g., 400 RU/s) — you pay even if unused
- **Autoscale:** You set a max RU/s — Cosmos scales between 10% of max and max automatically

**Cost tip:** If RU consumption hits the provisioned limit, Cosmos DB **throttles requests** with a 429 error. Use Azure Monitor to track `NormalizedRUConsumption`.

> 💡 **What the interviewer tests:** Understanding of Cosmos DB's pricing and capacity planning.

---

### 🔴 Q11. An e-commerce app using Cosmos DB is seeing 429 (Too Many Requests) errors during flash sales. How do you fix this?

**Answer:**

429 errors mean the application is **exceeding provisioned RU/s**. Here's my troubleshooting and resolution approach:

**Immediate fix:**
```bash
# Scale up RU/s temporarily
az cosmosdb sql container throughput update \
  --account-name myCosmosAccount \
  --resource-group myRG \
  --database-name myDB \
  --name orders \
  --throughput 10000
```

**Medium-term fix — switch to Autoscale:**
```bash
az cosmosdb sql container throughput migrate \
  --account-name myCosmosAccount \
  --resource-group myRG \
  --database-name myDB \
  --name orders \
  --throughput-type autoscale
```

**Application-level fixes:**
1. **Implement retry with exponential backoff** — SDKs do this, but verify it's enabled
2. **Cache read-heavy data in Redis** — product catalog, pricing rarely changes; no need to hit Cosmos every time
3. **Review partition key** — if a single product is causing a hot partition, re-evaluate the key
4. **Use bulk executor** — for write-heavy operations, batch writes
5. **Optimize queries** — replace cross-partition queries with partition-scoped queries

**Root cause check:**
- Use **Cosmos DB Insights** in Azure Monitor
- Check `NormalizedRUConsumption` per partition — if one partition is near 100%, it's a hot partition problem

> 💡 **What the interviewer tests:** Real-world incident response, not just theoretical knowledge.

---

## SECTION 3 — Azure Database for PostgreSQL & MySQL

---

### 🟢 Q12. What is the difference between Single Server and Flexible Server for PostgreSQL?

**Answer:**

| Feature | Single Server | Flexible Server |
|---------|--------------|-----------------|
| Status | **Retiring (March 2025)** | **Recommended** |
| Stop/Start | ❌ No | ✅ Yes (save cost) |
| Zone Redundant HA | ❌ No | ✅ Yes |
| Custom maintenance window | ❌ No | ✅ Yes |
| Burstable tier | ❌ No | ✅ Yes |
| Minor version upgrades | Automatic | Controlled |
| VNet integration | Via service endpoint | Native VNet injection |
| Cost | Always running | Can stop to save money |

**Always recommend Flexible Server** for any new project. If a customer is on Single Server, recommend migrating to Flexible Server.

> 💡 **What the interviewer tests:** Up-to-date knowledge and practical recommendations.

---

### 🟡 Q13. How does Zone Redundant High Availability work in PostgreSQL Flexible Server?

**Answer:**

Zone Redundant HA deploys a **primary server in one Availability Zone** and a **standby server in a different Availability Zone** within the same region.

```
Region: East US
┌─────────────────────────────────────────────────────┐
│  Zone 1                      Zone 3                 │
│  ┌──────────────┐            ┌──────────────────┐   │
│  │   PRIMARY    │──sync──────│    STANDBY       │   │
│  │  (read/write)│            │ (hot standby)    │   │
│  └──────────────┘            └──────────────────┘   │
└─────────────────────────────────────────────────────┘
         ↑
   Application connects via single endpoint
   (auto-redirects on failover in ~60-120 seconds)
```

Key points:
- Replication is **synchronous** — zero data loss (RPO = 0)
- Failover is **automatic** — happens in 60–120 seconds (RTO)
- Application uses **a single endpoint** — no connection string changes needed
- **Extra cost:** You pay for both primary and standby servers

```bash
az postgres flexible-server create \
  --name myPGServer \
  --resource-group myRG \
  --high-availability ZoneRedundant \
  --zone 1 \
  --standby-zone 3
```

> 💡 **What the interviewer tests:** HA architecture design knowledge.

---

### 🟡 Q14. When would you choose PostgreSQL over MySQL on Azure?

**Answer:**

**Choose PostgreSQL when:**
- You need **advanced JSON support** — PostgreSQL's `JSONB` is binary, indexed, and faster than MySQL's JSON
- You need **PostGIS** for geospatial data (maps, location-based services)
- Complex queries, **window functions**, CTEs, and analytical workloads
- You need **rich extension ecosystem** (uuid-ossp, pg_trgm, pgcrypto, etc.)
- You're working with **time-series data** (with TimescaleDB extension)
- Data integrity is critical — PostgreSQL's MVCC and ACID implementation is stricter

**Choose MySQL when:**
- Building traditional **web applications** (WordPress, Drupal, Magento, Laravel)
- **Simplicity** is preferred over advanced features
- Team has existing **MySQL expertise**
- **Read-heavy** workloads with simple queries
- Your ORM (like Eloquent or Django) works equally well with both and you have no special requirements

> 💡 **What the interviewer tests:** Ability to make and justify architecture decisions.

---

### 🔴 Q15. How would you migrate an on-premises PostgreSQL database to Azure Database for PostgreSQL with minimal downtime?

**Answer:**

I would use **Azure Database Migration Service (DMS)** with online migration to minimize downtime:

**Phase 1 — Prepare**
```bash
# Create target Flexible Server
az postgres flexible-server create \
  --name target-pg-server \
  --resource-group myRG \
  --version 16 \
  --sku-name Standard_D4s_v3

# Enable logical replication on source (on-premises)
# In postgresql.conf:
# wal_level = logical
# max_replication_slots = 5
# max_wal_senders = 5
```

**Phase 2 — Initial full load**
- DMS performs a full dump of the source database to the target
- Application continues running on the old database

**Phase 3 — Continuous sync (CDC)**
- DMS uses **logical replication** (Change Data Capture) to stream ongoing changes
- Any inserts/updates/deletes on source are replicated to target in near-real time

**Phase 4 — Cutover (minimal downtime window)**
1. Monitor DMS migration status until lag is near zero
2. Briefly stop writes to the source application (maintenance mode, seconds to minutes)
3. Wait for DMS to sync remaining changes
4. Update application connection string to target server
5. Resume application

**Phase 5 — Validate**
- Run row count checks
- Validate data integrity on critical tables
- Run smoke tests

**Downtime:** Only during final cutover step — typically under 5 minutes.

> 💡 **What the interviewer tests:** Real migration experience and understanding of CDC/logical replication.

---

## SECTION 4 — Azure Cache for Redis

---

### 🟢 Q16. What is Azure Cache for Redis and what are its common use cases?

**Answer:**

Azure Cache for Redis is a **fully managed in-memory data store** based on the open-source Redis project. It stores data in RAM, making reads and writes **sub-millisecond** — far faster than any disk-based database.

**Common use cases:**

| Use Case | How Redis Helps |
|----------|-----------------|
| **Caching** | Store DB query results, API responses to reduce DB load |
| **Session Management** | Store user sessions — stateless app servers, fast access |
| **Rate Limiting** | Increment counters with TTL to throttle API calls |
| **Pub/Sub Messaging** | Lightweight message broker between microservices |
| **Leaderboards** | Sorted Sets for real-time rankings |
| **Distributed Locking** | Prevent race conditions in distributed systems |
| **Queue** | List data structure acts as a FIFO/LIFO queue |

> 💡 **What the interviewer tests:** Breadth of knowledge — Redis is not just a cache.

---

### 🟡 Q17. Explain the Cache-Aside pattern. How do you implement it with Redis?

**Answer:**

Cache-Aside (also called **Lazy Loading**) is the most common caching pattern:

```
Application checks cache first
       │
       ▼
  ┌─────────┐     HIT ──────────────────────► Return cached data
  │  Redis   │
  └─────────┘     MISS
       │
       ▼
  ┌─────────┐
  │Database │──► Return data from DB
  └─────────┘
       │
       ▼
  Write result to Redis with TTL
       │
       ▼
  Return data to application
```

**Python implementation:**
```python
import redis
import json

r = redis.StrictRedis(
    host="myredis.redis.cache.windows.net",
    port=6380, ssl=True, password="<key>"
)

def get_product(product_id):
    cache_key = f"product:{product_id}"

    # 1. Check cache
    cached = r.get(cache_key)
    if cached:
        print("Cache HIT")
        return json.loads(cached)

    # 2. Cache miss — query DB
    print("Cache MISS")
    product = db.query(f"SELECT * FROM products WHERE id = {product_id}")

    # 3. Write to cache with TTL (10 minutes)
    r.setex(cache_key, 600, json.dumps(product))

    return product
```

**Cache invalidation strategy:**
- On product update → `r.delete(f"product:{product_id}")`
- Or set a short TTL and accept brief staleness

> 💡 **What the interviewer tests:** Design pattern knowledge and practical implementation.

---

### 🟡 Q18. What Redis tier would you recommend for a production banking application?

**Answer:**

I would recommend **Premium tier** (or **Enterprise tier** for very critical workloads).

**Reasoning:**

| Requirement | Why Premium/Enterprise |
|-------------|----------------------|
| Data persistence | Premium supports RDB (snapshot) + AOF (every-write log) |
| Cluster support | Premium supports up to 10 shards for horizontal scale |
| VNet injection | Premium can be deployed inside a private VNet — no public endpoint |
| Zone redundancy | Premium supports zone-redundant replication |
| Geo-replication | Premium supports passive geo-replication to another region |
| SLA | Premium: 99.9% → Enterprise: 99.99% |

**I would NOT use Basic or Standard for banking because:**
- Basic has no SLA and no replication
- Standard has replication but no clustering, no VNet injection, no persistence with AOF

**For a banking app I would also:**
```bash
# Create Premium with VNet integration
az redis create \
  --name banking-redis \
  --resource-group myRG \
  --sku Premium \
  --vm-size p2 \
  --subnet-id "/subscriptions/.../subnets/redis-subnet"

# Enable AOF persistence (every write logged)
az redis update \
  --name banking-redis \
  --resource-group myRG \
  --set "redisConfiguration.aof-backup-enabled=true"
```

> 💡 **What the interviewer tests:** Security, compliance, and architecture decision-making.

---

### 🔴 Q19. Your Redis cache hit rate is only 40%. How do you diagnose and improve it?

**Answer:**

A 40% hit rate means 60% of requests are going to the database — Redis is barely helping. Here's my approach:

**Step 1 — Diagnose using Redis metrics**
```bash
# Check cache hit/miss ratio in Azure Portal
# Metric: Cache Hits and Cache Misses under Monitoring

# Connect to Redis and check info
redis-cli -h myredis.redis.cache.windows.net -p 6380 --tls -a <key> INFO stats
# Look for: keyspace_hits and keyspace_misses
```

**Step 2 — Find root causes**

| Cause | Symptom | Fix |
|-------|---------|-----|
| TTL too short | Keys expire before reuse | Increase TTL |
| Cache keys not matching | Different key formats for same data | Standardize key naming |
| Cold cache after restart | All keys evicted | Warm up cache on startup |
| Wrong eviction policy | Keys evicted under memory pressure | Change to `allkeys-lru` |
| Missing cache logic | Some code paths bypass cache | Audit all DB call sites |
| High cardinality keys | `product:42:user:99:session:xyz` — never reused | Simplify key design |

**Step 3 — Fix eviction policy**
```bash
# Check current policy
redis-cli CONFIG GET maxmemory-policy

# Set to LRU eviction (evicts least recently used when memory full)
az redis update \
  --name myRedis \
  --resource-group myRG \
  --set "redisConfiguration.maxmemory-policy=allkeys-lru"
```

**Step 4 — Warm up cache on deploy**
```python
# Pre-load top 100 products on application startup
def warm_cache():
    top_products = db.query("SELECT * FROM products ORDER BY views DESC LIMIT 100")
    for p in top_products:
        r.setex(f"product:{p['id']}", 3600, json.dumps(p))
```

**Target:** Aim for 90%+ cache hit rate for read-heavy workloads.

> 💡 **What the interviewer tests:** Observability, debugging methodology, and Redis internals.

---

## SECTION 5 — Backup, Geo-Redundancy & DR

---

### 🟢 Q20. What is the difference between RTO and RPO?

**Answer:**

These are the two most important metrics in disaster recovery planning:

**RPO (Recovery Point Objective):**
> "How much data can we afford to lose?"

The maximum age of data that must be recovered. If RPO = 1 hour, backups must be taken at least every hour, so in a disaster you lose at most 1 hour of data.

**RTO (Recovery Time Objective):**
> "How quickly must the system be back online?"

The maximum acceptable downtime after a disaster. If RTO = 30 minutes, the system must be restored within 30 minutes.

```
Disaster happens
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│◄──── RPO ────►│◄──────────────── RTO ──────────────────►│
│               │                                          │
│ Last Backup   │ Disaster                           System│
│               │ Strikes                            Online│
└──────────────────────────────────────────────────────────┘
```

**Azure services and their DR characteristics:**

| Service | RPO | RTO |
|---------|-----|-----|
| SQL DB (Failover Group) | < 5 seconds | < 60 seconds |
| PostgreSQL Zone Redundant HA | 0 (synchronous) | 60–120 seconds |
| Cosmos DB (multi-region) | < 1 second | < 30 seconds |
| Redis Geo-replication | Minutes | Minutes |

> 💡 **What the interviewer tests:** Business-oriented thinking, not just technical knowledge.

---

### 🟡 Q21. What is the difference between geo-replication and geo-redundant backup?

**Answer:**

These solve different problems:

**Geo-Replication (Active):**
- A **live, continuously updated copy** of the database in another region
- Used for **automatic or manual failover** when the primary region fails
- Secondary is immediately available (near-zero RTO)
- Typically costs ~2x (you're running two databases)
- Example: SQL Database Active Geo-Replication, Cosmos DB multi-region

**Geo-Redundant Backup:**
- A **backup copy stored in a paired region** (not a live database)
- Used for **point-in-time restore** if the primary region is completely lost
- Restore takes **minutes to hours** (higher RTO)
- Much cheaper than geo-replication
- Example: Setting `--backup-storage-redundancy Geo` in Azure SQL DB

```
Geo-Replication:    Primary ──live sync──► Secondary (always running, instant failover)
Geo-Redundant Bkp: Primary ──backup──────► Blob Storage in paired region (restore needed)
```

**When to use which:**
- Mission-critical, low RTO required → **Geo-Replication**
- Compliance requirement to store backups offsite → **Geo-Redundant Backup**
- Both? → Use geo-replication AND geo-redundant backups for maximum protection

> 💡 **What the interviewer tests:** Nuanced understanding of HA vs DR strategies.

---

### 🟡 Q22. What backup redundancy options exist in Azure database services?

**Answer:**

Azure offers 4 backup storage redundancy options:

| Option | Copies | Protection Level | Cost |
|--------|--------|-----------------|------|
| **LRS** (Locally Redundant) | 3 copies, 1 datacenter | Datacenter failure: data at risk | Lowest |
| **ZRS** (Zone Redundant) | 3 copies, 3 AZs, 1 region | Zone failure: protected | Medium |
| **GRS** (Geo Redundant) | LRS + async copy to paired region | Region failure: protected | High |
| **GZRS** (Geo-Zone Redundant) | ZRS + async copy to paired region | Zone + Region failure: protected | Highest |

**Recommendation by scenario:**
- Dev/Test → LRS (cheapest)
- Production, single-region → ZRS
- Production, DR requirement → GRS or GZRS
- Regulated industries (banking, healthcare) → GZRS

```bash
# Set backup redundancy at creation
az sql db create \
  --resource-group myRG \
  --server myServer \
  --name myDB \
  --service-objective S3 \
  --backup-storage-redundancy GeoZone
```

> 💡 **What the interviewer tests:** Cost-conscious decision making and compliance awareness.

---

### 🔴 Q23. Design a DR strategy for a critical e-commerce application using Azure database services.

**Answer:**

This is a design question. Structure your answer around RTO/RPO requirements, then justify each choice.

**Assumed requirements:**
- RPO: 0 (no data loss acceptable for orders)
- RTO: < 5 minutes for critical path
- Regions: Primary = East US, DR = West US

**Architecture:**

```
┌──────────────────────────────────────────────────────────────────┐
│                        PRIMARY (East US)                         │
│                                                                  │
│  App Service  ──►  Azure SQL DB  ──►  Cosmos DB  ──►  Redis      │
│  (primary)     (primary, Business   (multi-region   (Premium,    │
│                 Critical tier)       write enabled)  geo-repl.)  │
└──────────────────┬───────────────────────────────┬──────────────┘
                   │ Sync replication               │ Active-active
                   ▼                               ▼
┌──────────────────────────────────────────────────────────────────┐
│                        FAILOVER (West US)                        │
│                                                                  │
│  App Service  ──►  SQL DB Replica  ──►  Cosmos DB  ──►  Redis    │
│  (standby)     (readable secondary)   (West US node) (passive    │
│                                                        replica)  │
└──────────────────────────────────────────────────────────────────┘
                         ▲
               Azure Traffic Manager
               (health-probe based failover)
```

**Service-specific DR choices:**

| Service | Strategy | Why |
|---------|----------|-----|
| Azure SQL DB | Failover Group (auto) + Business Critical | Auto-failover, readable replica, RPO < 5s |
| Cosmos DB | Multi-region writes enabled | Native active-active, RPO ~0 |
| Redis | Premium geo-replication | Passive replica in DR region |
| App Layer | Traffic Manager + App Service in both regions | DNS-level failover |

**Failover process (automated):**
1. Traffic Manager health probe detects East US failure
2. DNS switches to West US endpoint
3. SQL Failover Group auto-promotes secondary to primary (< 60 sec)
4. Cosmos DB already serving from West US (active-active)
5. Redis in West US already warmed (geo-replica promoted)

**Testing:**
- Run **chaos engineering drills** quarterly — simulate region failure
- Use Azure Site Recovery drills to test without impacting production

> 💡 **What the interviewer tests:** End-to-end architecture thinking and ability to justify decisions under constraints.

---

## SECTION 6 — Mixed / Scenario-Based Questions

---

### 🟡 Q24. When would you use Azure SQL Database vs Cosmos DB?

**Answer:**

| Factor | Choose Azure SQL DB | Choose Cosmos DB |
|--------|--------------------|--------------------|
| **Data structure** | Structured, relational, fixed schema | Semi-structured, schema-flexible, JSON |
| **Query type** | Complex JOINs, aggregations, reporting | Simple lookups by partition key |
| **Global users** | Single-region or limited regions | Globally distributed users, low latency everywhere |
| **Consistency** | Always strong ACID needed | Tunable (can accept eventual consistency) |
| **Scale** | Predictable scale, vertical scale sufficient | Massive unpredictable scale, IoT, gaming |
| **Cost model** | vCore or DTU | RU/s (tricky to estimate, can be expensive) |
| **Migration** | Migrating from on-premises SQL Server | Greenfield, cloud-native application |

**Real-world example:**
> "For the Contoso Retail app, I would use Azure SQL DB for order processing (ACID transactions critical, complex joins needed) and Cosmos DB for the product catalog (high read throughput, global users, schema flexibility for different product types)."

> 💡 **What the interviewer tests:** Ability to make and explain architecture trade-offs.

---

### 🟡 Q25. How do you secure Azure database services?

**Answer:**

Security is applied in layers — **defense in depth:**

**1. Network Security**
```bash
# Private Endpoint — remove all public access
az sql server update \
  --resource-group myRG \
  --name myServer \
  --restrict-outbound-network-access true

az network private-endpoint create \
  --name sql-private-ep \
  --resource-group myRG \
  --vnet-name myVNet \
  --subnet mySubnet \
  --private-connection-resource-id "/subscriptions/.../servers/myServer" \
  --group-id sqlServer
```

**2. Authentication**
- Use **Azure Active Directory (Entra ID)** authentication instead of SQL logins
- Disable SQL admin account after setting up AAD admin
- Use **Managed Identity** so app code never stores credentials

**3. Encryption**
- Data at rest: **Transparent Data Encryption (TDE)** — enabled by default
- Data in transit: TLS 1.2+ enforced — always connect with `Encrypt=Yes`
- Sensitive columns: **Always Encrypted** — data encrypted client-side, even DBAs can't see plaintext

**4. Auditing & Threat Detection**
```bash
# Enable Advanced Threat Protection
az sql db threat-policy update \
  --resource-group myRG \
  --server myServer \
  --database myDB \
  --state Enabled \
  --storage-account myStorageAccount \
  --email-addresses security@contoso.com
```

**5. RBAC & Least Privilege**
- Grant minimum necessary permissions per user/app
- Use database roles, not sysadmin
- Separate service accounts per application

> 💡 **What the interviewer tests:** Security depth — network, identity, encryption, monitoring.

---

### 🔴 Q26. You need to store 500 million IoT sensor readings per day globally with < 10ms read latency worldwide. Which Azure database service do you choose and why?

**Answer:**

**Choice: Azure Cosmos DB with NoSQL (Core) API**

**Justification:**

**Volume:** 500 million records/day = ~5,800 writes/second. Cosmos DB scales horizontally to millions of RU/s — handles this easily with autoscale.

**Global low latency:** Cosmos DB's native multi-region distribution delivers single-digit millisecond reads from any Azure region. SQL DB or PostgreSQL would require complex geo-replication setup and still wouldn't match Cosmos DB's latency guarantees.

**Schema flexibility:** IoT sensors from different manufacturers send different payloads. Cosmos DB's schema-free JSON model handles this without ALTER TABLE migrations.

**Data model design:**
```json
{
  "id": "sensor-001-2025-06-17T10:30:00Z",
  "deviceId": "sensor-001",          ← partition key
  "timestamp": "2025-06-17T10:30:00Z",
  "temperature": 23.4,
  "humidity": 61.2,
  "location": { "lat": 12.97, "lon": 77.59 },
  "status": "normal"
}
```

**Partition key:** `deviceId` — high cardinality (millions of sensors), evenly distributed, most queries filter by device.

**Consistency level:** Eventual or Session — sensor data with slight staleness is acceptable, and eventual gives lowest latency + highest throughput.

**Complementary services:**
- **Azure Stream Analytics** — process the incoming IoT stream
- **Azure Cache for Redis** — cache latest reading per sensor (dashboard queries)
- **Azure Synapse Analytics** — long-term analytics on historical sensor data

**I would NOT choose:**
- SQL DB — cannot scale writes to this level without extreme sharding complexity
- PostgreSQL — same limitation, not designed for this write throughput
- Redis alone — not persistent, not queryable at this scale

> 💡 **What the interviewer tests:** Ability to reason through a real architecture problem with multiple constraints.

---

## Quick Reference — Key Numbers to Remember

| Fact | Value |
|------|-------|
| Azure SQL DB max storage (Hyperscale) | 100 TB |
| SQL DB default backup retention | 7 days |
| SQL DB max LTR retention | 10 years |
| Cosmos DB point read cost | 1 RU (1 KB item) |
| Cosmos DB write cost | ~5 RU (1 KB item) |
| Cosmos DB logical partition max size | 20 GB |
| Cosmos DB free tier | 1,000 RU/s + 25 GB |
| PostgreSQL Flexible max storage | 32 TB |
| MySQL Flexible max storage | 16 TB |
| Redis Basic/Standard max size | 53 GB |
| Redis Premium max size | 1.2 TB |
| Cosmos DB 99.999% SLA | Multi-region, multi-write |
| SQL DB Failover Group RPO | < 5 seconds |
| PostgreSQL Zone HA RTO | 60–120 seconds |

---

## Common Interview Mistakes to Avoid

| ❌ Mistake | ✅ Correct Approach |
|-----------|-------------------|
| Saying "Cosmos DB is just MongoDB" | Cosmos DB supports MongoDB API but is its own service with 5 APIs |
| Saying "Azure SQL DB is just SQL Server" | It's a fully managed PaaS with different feature set and limitations |
| Ignoring partition key in Cosmos DB | Always bring up partition key strategy — it's the #1 design decision |
| Choosing Basic Redis for production | Always recommend Standard or Premium for production |
| Saying "backups are automatic so DR is covered" | Backups ≠ DR. Distinguish backup restore vs geo-replication failover |
| Treating all consistency levels as equal | Know when eventual consistency is acceptable vs when strong is required |
| Forgetting to mention security | Always mention Private Endpoints, Managed Identity, TDE |

---

*Prepared for real-time interview preparation | akumenbyq | Azure Database Services*