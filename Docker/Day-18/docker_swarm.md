# Docker Swarm — Complete Notes

> A production-ready guide to container orchestration with Docker Swarm, covering architecture, commands, real examples, and expected outputs.

---

## Table of Contents

1. [What is Docker Swarm?](#1-what-is-docker-swarm)
2. [Key Concepts](#2-key-concepts)
3. [Architecture](#3-architecture)
4. [Setting Up a Swarm](#4-setting-up-a-swarm)
5. [Services](#5-services)
6. [Scaling Services](#6-scaling-services)
7. [Rolling Updates](#7-rolling-updates)
8. [Overlay Networks](#8-overlay-networks)
9. [Secrets Management](#9-secrets-management)
10. [Configs](#10-configs)
11. [Docker Stack (Compose for Swarm)](#11-docker-stack-compose-for-swarm)
12. [Node Management](#12-node-management)
13. [High Availability](#13-high-availability)
14. [Monitoring & Troubleshooting](#14-monitoring--troubleshooting)
15. [Swarm vs Kubernetes](#15-swarm-vs-kubernetes)
16. [Quick Reference Cheatsheet](#16-quick-reference-cheatsheet)

---

## 1. What is Docker Swarm?

Docker Swarm is Docker's **native clustering and orchestration** tool. It turns a pool of Docker hosts into a single virtual Docker host, allowing you to deploy, manage, and scale containerized applications across multiple machines.

### Why Swarm?

- Built into Docker — no extra installation needed
- Uses the same Docker CLI and Compose file format
- Handles **automatic load balancing**, **self-healing**, and **rolling updates**
- Simpler than Kubernetes for small to medium deployments

---

## 2. Key Concepts

| Term | Description |
|---|---|
| **Swarm** | A cluster of Docker nodes operating together |
| **Node** | A machine (physical or virtual) running Docker in swarm mode |
| **Manager Node** | Controls the swarm, schedules tasks, maintains cluster state |
| **Worker Node** | Executes tasks assigned by the manager |
| **Service** | The definition of a task to run (image + replicas + config) |
| **Task** | A single container running on a node |
| **Replica** | A copy of a container for a service |
| **Stack** | A group of related services defined in a Compose file |
| **Overlay Network** | A virtual network spanning all swarm nodes |
| **Secret** | Encrypted sensitive data (passwords, tokens) |
| **Config** | Non-sensitive configuration data managed by swarm |

---

## 3. Architecture

```
┌────────────────────────────────────────────────────────┐
│                      DOCKER SWARM                       │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              MANAGER NODES (Raft Consensus)      │   │
│  │                                                   │   │
│  │   ┌──────────┐  ┌──────────┐  ┌──────────┐      │   │
│  │   │ Manager 1│  │ Manager 2│  │ Manager 3│      │   │
│  │   │ (Leader) │  │(Follower)│  │(Follower)│      │   │
│  │   └────┬─────┘  └──────────┘  └──────────┘      │   │
│  └────────┼────────────────────────────────────────┘   │
│           │ assigns tasks                               │
│  ┌────────▼────────────────────────────────────────┐   │
│  │              WORKER NODES                        │   │
│  │                                                   │   │
│  │   ┌──────────┐  ┌──────────┐  ┌──────────┐      │   │
│  │   │ Worker 1 │  │ Worker 2 │  │ Worker 3 │      │   │
│  │   │[task][t] │  │[task][t] │  │[task]    │      │   │
│  │   └──────────┘  └──────────┘  └──────────┘      │   │
│  └─────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────┘
```

### Raft Consensus Algorithm
Managers use **Raft** to maintain a consistent cluster state. For fault tolerance:

| Manager Nodes | Max Failures Tolerated |
|---|---|
| 1 | 0 |
| 3 | 1 |
| 5 | 2 |
| 7 | 3 |

> **Rule:** Always use an **odd number** of managers (1, 3, 5, 7).

---

## 4. Setting Up a Swarm

### Step 1 — Initialize the Swarm (on Manager Node)

```bash
docker swarm init --advertise-addr <MANAGER-IP>
```

**Output:**
```
Swarm initialized: current node (xyz123abc) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-3oa0...abc123 192.168.1.10:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

### Step 2 — Get Join Tokens

```bash
# Token for workers
docker swarm join-token worker

# Token for managers
docker swarm join-token manager
```

**Output:**
```
To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-49nj1...worker-token 192.168.1.10:2377
```

### Step 3 — Join Worker Nodes (run on each worker)

```bash
docker swarm join --token SWMTKN-1-49nj1...worker-token 192.168.1.10:2377
```

**Output:**
```
This node joined a swarm as a worker.
```

### Step 4 — Verify the Swarm

```bash
docker node ls
```

**Output:**
```
ID                            HOSTNAME   STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
xyz123abc *                   manager1   Ready     Active         Leader           24.0.5
def456hij                     worker1    Ready     Active                          24.0.5
ghi789jkl                     worker2    Ready     Active                          24.0.5
```

> `*` = the node you are currently on. `Leader` = the active Raft leader.

---

## 5. Services

A **service** is the core unit of work in Swarm — it defines what to run and how many replicas.

### Create a Service

```bash
docker service create \
  --name web \
  --replicas 3 \
  --publish published=80,target=80 \
  nginx:latest
```

**Output:**
```
x4g9klm2n3op
overall progress: 3 out of 3 tasks
1/3: running   [==================================================>]
2/3: running   [==================================================>]
3/3: running   [==================================================>]
verify: Service converged
```

### List Services

```bash
docker service ls
```

**Output:**
```
ID             NAME      MODE         REPLICAS   IMAGE          PORTS
x4g9klm2n3op  web       replicated   3/3        nginx:latest   *:80->80/tcp
```

### Inspect a Service

```bash
docker service inspect web --pretty
```

**Output:**
```
ID:             x4g9klm2n3op
Name:           web
Service Mode:   Replicated
 Replicas:      3
Placement:
UpdateConfig:
 Parallelism:   1
 On failure:    pause
 Monitoring Period: 5s
 Max failure ratio: 0
 Update order:      stop-first
RollbackConfig:
 Parallelism:   1
 On failure:    pause
ContainerSpec:
 Image:         nginx:latest
Resources:
Endpoint Mode:  vip
Ports:
 PublishedPort = 80
  Protocol = tcp
  TargetPort = 80
  PublishMode = ingress
```

### View Service Tasks (Containers)

```bash
docker service ps web
```

**Output:**
```
ID             NAME      IMAGE          NODE       DESIRED STATE   CURRENT STATE            ERROR
a1b2c3d4e5f6   web.1     nginx:latest   worker1    Running         Running 2 minutes ago
b2c3d4e5f6g7   web.2     nginx:latest   worker2    Running         Running 2 minutes ago
c3d4e5f6g7h8   web.3     nginx:latest   manager1   Running         Running 2 minutes ago
```

### Remove a Service

```bash
docker service rm web
```

**Output:**
```
web
```

---

## 6. Scaling Services

### Scale Up

```bash
docker service scale web=5
```

**Output:**
```
web scaled to 5
overall progress: 5 out of 5 tasks
1/5: running   [==================================================>]
2/5: running   [==================================================>]
3/5: running   [==================================================>]
4/5: running   [==================================================>]
5/5: running   [==================================================>]
verify: Service converged
```

### Scale Down

```bash
docker service scale web=2
```

**Output:**
```
web scaled to 2
overall progress: 2 out of 2 tasks
1/2: running   [==================================================>]
2/2: running   [==================================================>]
verify: Service converged
```

### Scale Multiple Services at Once

```bash
docker service scale web=5 api=3 worker=2
```

---

## 7. Rolling Updates

Rolling updates let you update services **without downtime** — containers are updated one at a time (or in batches).

### Update the Image

```bash
docker service update \
  --image nginx:1.25 \
  --update-parallelism 1 \
  --update-delay 10s \
  web
```

**Output:**
```
web
overall progress: 3 out of 3 tasks
1/3: running   [==================================================>]
2/3: running   [==================================================>]
3/3: running   [==================================================>]
verify: Service converged
```

### What the flags mean

| Flag | Description |
|---|---|
| `--update-parallelism 1` | Update 1 container at a time |
| `--update-delay 10s` | Wait 10s between each update |
| `--update-failure-action pause` | Pause on failure (default) |
| `--update-failure-action rollback` | Auto-rollback on failure |

### Rollback a Service

```bash
docker service rollback web
```

**Output:**
```
web
rollback: manually requested rollback
overall progress: 3 out of 3 tasks
1/3: running   [==================================================>]
2/3: running   [==================================================>]
3/3: running   [==================================================>]
verify: Service converged
```

---

## 8. Overlay Networks

Overlay networks span all nodes in the swarm, allowing containers on different machines to communicate as if they were on the same LAN.

### Create an Overlay Network

```bash
docker network create \
  --driver overlay \
  --attachable \
  my-network
```

**Output:**
```
q8r9s0t1u2v3w4x5y6z7
```

### List Networks

```bash
docker network ls
```

**Output:**
```
NETWORK ID     NAME              DRIVER    SCOPE
a1b2c3d4e5f6   bridge            bridge    local
b2c3d4e5f6g7   docker_gwbridge   bridge    local
c3d4e5f6g7h8   host              host      local
d4e5f6g7h8i9   ingress           overlay   swarm
q8r9s0t1u2v3   my-network        overlay   swarm
```

### Attach a Service to an Overlay Network

```bash
docker service create \
  --name api \
  --network my-network \
  --replicas 2 \
  myapp/api:latest
```

### Built-in Networks

| Network | Purpose |
|---|---|
| `ingress` | Load balancing and routing mesh (auto-created) |
| `docker_gwbridge` | Connects overlay networks to the host |

---

## 9. Secrets Management

Secrets are encrypted at rest and in transit. Only services that are granted access can read them.

### Create a Secret

```bash
# From a string
echo "supersecretpassword" | docker secret create db_password -

# From a file
docker secret create ssl_cert ./ssl/cert.pem
```

**Output:**
```
y7z8a1b2c3d4e5f6
```

### List Secrets

```bash
docker secret ls
```

**Output:**
```
ID                          NAME          DRIVER    CREATED          UPDATED
y7z8a1b2c3d4e5f6            db_password             2 minutes ago    2 minutes ago
z8a1b2c3d4e5f6g7            ssl_cert                1 minute ago     1 minute ago
```

### Use a Secret in a Service

```bash
docker service create \
  --name db \
  --secret db_password \
  --env MYSQL_ROOT_PASSWORD_FILE=/run/secrets/db_password \
  mysql:8.0
```

> Secrets are mounted at `/run/secrets/<secret_name>` inside the container.

### Inspect a Secret (metadata only — value is never revealed)

```bash
docker secret inspect db_password
```

**Output:**
```json
[
    {
        "ID": "y7z8a1b2c3d4e5f6",
        "Version": { "Index": 11 },
        "CreatedAt": "2024-01-15T10:30:00.000000000Z",
        "UpdatedAt": "2024-01-15T10:30:00.000000000Z",
        "Spec": {
            "Name": "db_password",
            "Labels": {}
        }
    }
]
```

### Remove a Secret

```bash
docker secret rm db_password
```

---

## 10. Configs

Similar to secrets but for **non-sensitive** configuration files (nginx.conf, app.properties, etc.).

### Create a Config

```bash
docker config create nginx_conf ./nginx.conf
```

### Use a Config in a Service

```bash
docker service create \
  --name proxy \
  --config source=nginx_conf,target=/etc/nginx/nginx.conf \
  nginx:latest
```

### List Configs

```bash
docker config ls
```

**Output:**
```
ID                          NAME          CREATED          UPDATED
a1b2c3d4e5f6g7h8            nginx_conf    3 minutes ago    3 minutes ago
```

---

## 11. Docker Stack (Compose for Swarm)

A **stack** deploys a full application (multiple services) defined in a `docker-compose.yml` file.

### Example: `docker-compose.yml`

```yaml
version: "3.9"

services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    networks:
      - frontend
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure

  app:
    image: myapp:latest
    networks:
      - frontend
      - backend
    secrets:
      - db_password
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: "0.5"
          memory: 256M

  db:
    image: postgres:15
    networks:
      - backend
    secrets:
      - db_password
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    volumes:
      - db_data:/var/lib/postgresql/data
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager

networks:
  frontend:
    driver: overlay
  backend:
    driver: overlay
    internal: true

volumes:
  db_data:

secrets:
  db_password:
    external: true
```

### Deploy a Stack

```bash
docker stack deploy -c docker-compose.yml myapp
```

**Output:**
```
Creating network myapp_frontend
Creating network myapp_backend
Creating service myapp_web
Creating service myapp_app
Creating service myapp_db
```

### List Stacks

```bash
docker stack ls
```

**Output:**
```
NAME      SERVICES
myapp     3
```

### List Services in a Stack

```bash
docker stack services myapp
```

**Output:**
```
ID             NAME          MODE         REPLICAS   IMAGE             PORTS
a1b2c3d4e5f6   myapp_web     replicated   3/3        nginx:latest      *:80->80/tcp
b2c3d4e5f6g7   myapp_app     replicated   2/2        myapp:latest
c3d4e5f6g7h8   myapp_db      replicated   1/1        postgres:15
```

### List Tasks in a Stack

```bash
docker stack ps myapp
```

**Output:**
```
ID             NAME            IMAGE          NODE       DESIRED STATE   CURRENT STATE
a1b2c3       myapp_web.1     nginx:latest   worker1    Running         Running 5 min ago
b2c3d4       myapp_web.2     nginx:latest   worker2    Running         Running 5 min ago
c3d4e5       myapp_web.3     nginx:latest   manager1   Running         Running 5 min ago
d4e5f6       myapp_app.1     myapp:latest   worker1    Running         Running 5 min ago
e5f6g7       myapp_app.2     myapp:latest   worker2    Running         Running 5 min ago
f6g7h8       myapp_db.1      postgres:15    manager1   Running         Running 5 min ago
```

### Remove a Stack

```bash
docker stack rm myapp
```

**Output:**
```
Removing service myapp_web
Removing service myapp_app
Removing service myapp_db
Removing network myapp_frontend
Removing network myapp_backend
```

---

## 12. Node Management

### List Nodes

```bash
docker node ls
```

**Output:**
```
ID                            HOSTNAME   STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
xyz123abc *                   manager1   Ready     Active         Leader           24.0.5
def456hij                     worker1    Ready     Active                          24.0.5
ghi789jkl                     worker2    Ready     Active                          24.0.5
```

### Inspect a Node

```bash
docker node inspect worker1 --pretty
```

**Output:**
```
ID:                     def456hij
Hostname:               worker1
Joined at:              2024-01-15 10:00:00.000000000 +0000 utc
Status:
 State:                 Ready
 Availability:          Active
 Address:               192.168.1.11
Manager Status:
Platform:
 Operating System:      linux
 Architecture:          x86_64
Resources:
 CPUs:                  4
 Memory:                8GiB
```

### Drain a Node (for maintenance)

```bash
docker node update --availability drain worker1
```

**Output:**
```
worker1
```

> Tasks are automatically rescheduled to other nodes. No downtime.

### Re-activate a Node

```bash
docker node update --availability active worker1
```

### Promote a Worker to Manager

```bash
docker node promote worker1
```

**Output:**
```
Node worker1 promoted to a manager in the swarm.
```

### Demote a Manager to Worker

```bash
docker node demote worker1
```

### Add Labels to Nodes

```bash
docker node update --label-add zone=us-east worker1
docker node update --label-add ssd=true worker2
```

### Use Labels in Placement Constraints

```yaml
deploy:
  placement:
    constraints:
      - node.labels.zone == us-east
      - node.labels.ssd == true
```

### Remove a Node from the Swarm

```bash
# On the node itself
docker swarm leave

# Force remove from manager (if node is down)
docker node rm worker1
```

---

## 13. High Availability

### Service Modes

#### Replicated Mode (default)
Run a specific number of replicas distributed across nodes.

```bash
docker service create --mode replicated --replicas 3 nginx
```

#### Global Mode
Run exactly **one container on every node** (good for monitoring agents, log collectors).

```bash
docker service create --mode global \
  --name node-exporter \
  prom/node-exporter:latest
```

**Output:**
```
overall progress: 3 out of 3 tasks
xyz123abc: running   [==================================================>]
def456hij: running   [==================================================>]
ghi789jkl: running   [==================================================>]
verify: Service converged
```

### Restart Policy

```yaml
deploy:
  restart_policy:
    condition: on-failure    # always | on-failure | none
    delay: 5s                # wait before restarting
    max_attempts: 3          # give up after N failures
    window: 120s             # evaluation window
```

### Resource Limits

```yaml
deploy:
  resources:
    limits:
      cpus: "0.50"
      memory: 512M
    reservations:
      cpus: "0.25"
      memory: 256M
```

### Self-Healing Demo

```bash
# Kill a container manually
docker ps  # get container ID on a worker
docker rm -f <container_id>

# Swarm automatically restarts it
docker service ps web
```

**Output (after kill):**
```
ID             NAME      IMAGE          NODE       DESIRED STATE   CURRENT STATE             ERROR
a1b2c3d4e5f6   web.1     nginx:latest   worker1    Running         Running 10 seconds ago
b2c3d4e5f6g7   web.1     nginx:latest   worker1    Shutdown        Failed 15 seconds ago     "task: non-zero exit (137)"
```

> Swarm detected the failure and immediately launched a replacement.

---

## 14. Monitoring & Troubleshooting

### View Service Logs

```bash
docker service logs web
docker service logs web --follow
docker service logs web --tail 50
```

**Output:**
```
web.1.a1b2c3@worker1    | /docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
web.1.a1b2c3@worker1    | /docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
web.2.b2c3d4@worker2    | 2024/01/15 10:35:22 [notice] 1#1: start worker processes
web.3.c3d4e5@manager1   | 192.168.1.1 - - [15/Jan/2024:10:35:30 +0000] "GET / HTTP/1.1" 200 615
```

### Check Service Health

```bash
docker service ps web --no-trunc
```

### Inspect Task Errors

```bash
# Find failed tasks
docker service ps web --filter "desired-state=shutdown"
```

**Output:**
```
ID             NAME      IMAGE          NODE     DESIRED STATE   CURRENT STATE           ERROR
z9y8x7w6v5u   web.2     nginx:latest   worker1  Shutdown        Failed 2 minutes ago    "starting container failed: ..."
```

### Common Issues & Fixes

| Issue | Cause | Fix |
|---|---|---|
| Service stuck at 0/3 | Image pull failure | Check `docker service ps web --no-trunc` |
| Tasks failing immediately | Bad env vars or missing secrets | Check service logs |
| Nodes not joining | Firewall blocking port 2377 | Open TCP 2377, UDP 4789, TCP/UDP 7946 |
| Overlay network unreachable | MTU mismatch | Set `--opt com.docker.network.driver.mtu=1450` |

### Required Open Ports

| Port | Protocol | Purpose |
|---|---|---|
| 2377 | TCP | Swarm management |
| 7946 | TCP/UDP | Node communication |
| 4789 | UDP | Overlay network traffic |

---

## 15. Swarm vs Kubernetes

| Feature | Docker Swarm | Kubernetes |
|---|---|---|
| Setup complexity | Simple (minutes) | Complex (hours/days) |
| Learning curve | Low | High |
| CLI | Docker CLI | kubectl |
| Auto-scaling | Manual only | Horizontal Pod Autoscaler |
| Load balancing | Built-in routing mesh | Requires Ingress controller |
| Storage | Basic volumes | PersistentVolumes, StorageClasses |
| Community & ecosystem | Smaller | Massive |
| Best for | Small/medium apps, teams new to orchestration | Large-scale, complex microservices |

---

## 16. Quick Reference Cheatsheet

### Swarm Lifecycle

```bash
docker swarm init --advertise-addr <IP>    # Initialize swarm
docker swarm join --token <token> <IP>     # Join as worker
docker swarm join-token worker             # Get worker join token
docker swarm join-token manager            # Get manager join token
docker swarm leave --force                 # Leave swarm (--force on manager)
```

### Services

```bash
docker service create --name <n> --replicas <N> <image>   # Create service
docker service ls                                           # List services
docker service ps <name>                                    # List tasks
docker service inspect <name> --pretty                      # Inspect service
docker service logs <name>                                  # View logs
docker service scale <name>=<N>                             # Scale service
docker service update --image <img> <name>                  # Update image
docker service rollback <name>                              # Rollback update
docker service rm <name>                                    # Remove service
```

### Stacks

```bash
docker stack deploy -c docker-compose.yml <name>    # Deploy stack
docker stack ls                                      # List stacks
docker stack services <name>                         # List stack services
docker stack ps <name>                               # List stack tasks
docker stack rm <name>                               # Remove stack
```

### Nodes

```bash
docker node ls                                        # List nodes
docker node inspect <node>                            # Inspect node
docker node update --availability drain <node>        # Drain node
docker node update --availability active <node>       # Re-activate node
docker node promote <node>                            # Promote to manager
docker node demote <node>                             # Demote to worker
docker node rm <node>                                 # Remove node
```

### Networks, Secrets, Configs

```bash
docker network create --driver overlay <name>              # Create overlay network
echo "value" | docker secret create <name> -               # Create secret
docker secret ls                                            # List secrets
docker config create <name> <file>                          # Create config
docker config ls                                            # List configs
```

---

