# Docker: Build Context, Multi-Stage Builds & Docker Compose

> A hands-on guide with real examples and expected outputs

---

## Table of Contents

1. [Build Context & `.dockerignore`](#1-build-context--dockerignore)
2. [Multi-Stage Builds](#2-multi-stage-builds)
3. [Docker Compose — Multi-Container Apps](#3-docker-compose--multi-container-apps)
   - [docker-compose.yml Structure](#docker-composeyml-structure)
   - [Services, Networks, Volumes](#services-networks-and-volumes-in-compose)
   - [depends_on, Health Checks, Env Files](#depends_on-health-checks-and-env-files)
   - [Compose Commands](#compose-commands)
4. [Full Practice Project](#4-full-practice-project)

---

## 1. Build Context & `.dockerignore`

### What is Build Context?

When you run `docker build`, Docker sends a **build context** — the set of files in your specified directory — to the Docker daemon. Every file in that directory is included unless you tell Docker otherwise.

```bash
docker build -t my_app .
#                      ^ This dot = build context (current directory)
```

> ⚠️ If your project folder is large (e.g., contains `node_modules`, `.git`, logs), Docker will send ALL of it to the daemon — making builds **slow and bloated**.

---

### The `.dockerignore` File

`.dockerignore` works exactly like `.gitignore` — it tells Docker which files/folders to **exclude** from the build context.

### Example Project Structure

```
my-node-app/
├── src/
│   └── index.js
├── node_modules/       ← huge, should be excluded
├── .git/               ← not needed in image
├── .env                ← sensitive, exclude
├── Dockerfile
├── .dockerignore
└── package.json
```

### `.dockerignore` File

```dockerignore
# Dependencies (will be installed inside container)
node_modules/

# Git history
.git/
.gitignore

# Environment files
.env
.env.*

# Logs
logs/
*.log

# OS files
.DS_Store
Thumbs.db

# Test files
coverage/
*.test.js

# Docker files themselves (optional)
Dockerfile
.dockerignore
```

### Dockerfile (Node.js Example)

```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY src/ ./src/

EXPOSE 3000
CMD ["node", "src/index.js"]
```

### Build Commands & Expected Output

```bash
docker build -t my-node-app .
```

**Output (with `.dockerignore` properly set):**
```
[+] Building 12.3s (9/9) FINISHED
 => [internal] load build definition from Dockerfile              0.1s
 => [internal] load .dockerignore                                 0.1s
 => [internal] load metadata for docker.io/library/node:20-alpine 2.1s
 => [1/4] FROM docker.io/library/node:20-alpine                   0.0s
 => [2/4] WORKDIR /app                                            0.1s
 => [3/4] COPY package*.json ./                                   0.1s
 => [4/4] RUN npm install                                         8.3s
 => [5/4] COPY src/ ./src/                                        0.1s
 => exporting to image                                            0.4s
 => naming to docker.io/library/my-node-app                       0.1s
```

### Without vs With `.dockerignore`

```bash
# Check build context size BEFORE .dockerignore
docker build -t test . 2>&1 | head -5
# => Sending build context to Docker daemon  142.6MB   ← SLOW

# After adding .dockerignore
docker build -t test . 2>&1 | head -5
# => Sending build context to Docker daemon  48.5kB    ← FAST ✅
```

---

## 2. Multi-Stage Builds

### The Problem Without Multi-Stage

A typical Go or Java app Dockerfile:

```dockerfile
# ❌ BAD: Single stage — final image includes compiler, source, build tools
FROM golang:1.22

WORKDIR /app
COPY . .
RUN go build -o server .

EXPOSE 8080
CMD ["./server"]
```

**Result:** Image size ~ **900MB** (includes entire Go toolchain)

---

### Multi-Stage Build — The Solution

```dockerfile
# ✅ GOOD: Multi-stage build

# ── Stage 1: Builder ──────────────────────────────────
FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o server .

# ── Stage 2: Final (minimal runtime image) ────────────
FROM alpine:3.19

WORKDIR /app

# Copy ONLY the compiled binary from builder stage
COPY --from=builder /app/server .

EXPOSE 8080
CMD ["./server"]
```

**Result:** Image size ~ **12MB** ✅ (only the binary + Alpine)

---

### Build & Verify

```bash
# Build the image
docker build -t my-go-app .
```

**Output:**
```
[+] Building 28.4s (12/12) FINISHED
 => [internal] load build definition from Dockerfile              0.1s
 => [builder 1/5] FROM golang:1.22-alpine                        10.2s
 => [builder 2/5] WORKDIR /app                                    0.1s
 => [builder 3/5] COPY go.mod go.sum ./                           0.1s
 => [builder 4/5] RUN go mod download                             5.3s
 => [builder 5/5] RUN go build -o server .                        8.4s
 => [stage-2 1/2] FROM alpine:3.19                                1.2s
 => [stage-2 2/2] COPY --from=builder /app/server .               0.1s
 => exporting to image                                            0.2s
```

```bash
# Compare image sizes
docker images | grep my-go-app
```

**Output:**
```
REPOSITORY    TAG       IMAGE ID       CREATED         SIZE
my-go-app     latest    a1b2c3d4e5f6   2 minutes ago   12.4MB
```

---

### Multi-Stage: Node.js React App Example

```dockerfile
# Stage 1: Build React app
FROM node:20-alpine AS build

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build          # produces /app/dist or /app/build

# Stage 2: Serve with Nginx
FROM nginx:alpine AS production

# Remove default nginx page
RUN rm -rf /usr/share/nginx/html/*

# Copy built static files from Stage 1
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**Build with a specific target stage:**

```bash
# Build only up to the 'build' stage (for debugging)
docker build --target build -t my-app:debug .

# Build the full production image
docker build --target production -t my-app:prod .
```

---

### Multi-Stage: Python App Example

```dockerfile
# Stage 1: Dependencies
FROM python:3.12-slim AS deps

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Runtime
FROM python:3.12-slim AS runtime

WORKDIR /app

# Copy installed packages from deps stage
COPY --from=deps /install /usr/local

# Copy application source
COPY src/ ./src/

EXPOSE 8000
CMD ["python", "src/main.py"]
```

---

## 3. Docker Compose — Multi-Container Apps

Docker Compose lets you define and run **multi-container applications** with a single YAML file.

---

### `docker-compose.yml` Structure

```yaml
version: "3.8"           # Compose file version

services:                # Define your containers here
  service_name:
    image: image_name    # Use a pre-built image
    build: ./path        # OR build from a Dockerfile
    ports:
      - "host:container"
    environment:
      - KEY=VALUE
    volumes:
      - volume_name:/path
    networks:
      - network_name
    depends_on:
      - other_service

networks:                # Define custom networks
  network_name:
    driver: bridge

volumes:                 # Define named volumes
  volume_name:
```

---

### Services, Networks, and Volumes in Compose

### Full Example: Web App + Database + Cache

```yaml
version: "3.8"

services:

  # ── Frontend ──────────────────────────────────────────
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    networks:
      - app_network
    depends_on:
      - backend

  # ── Backend API ───────────────────────────────────────
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "5000:5000"
    environment:
      - DATABASE_URL=postgres://user:password@db:5432/mydb
      - REDIS_URL=redis://cache:6379
    volumes:
      - ./backend:/app           # bind mount for dev hot-reload
      - uploads:/app/uploads     # named volume for file uploads
    networks:
      - app_network
    depends_on:
      - db
      - cache

  # ── PostgreSQL Database ───────────────────────────────
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: mydb
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql  # auto-runs on first start
    networks:
      - app_network
    ports:
      - "5432:5432"              # expose for local DB tools (optional)

  # ── Redis Cache ───────────────────────────────────────
  cache:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - app_network
    ports:
      - "6379:6379"

networks:
  app_network:
    driver: bridge

volumes:
  postgres_data:
  redis_data:
  uploads:
```

---

### `depends_on`, Health Checks, and Env Files

#### `depends_on` — Start Order Control

```yaml
services:
  backend:
    image: my-backend
    depends_on:
      - db        # db container starts BEFORE backend
      - cache

  db:
    image: postgres:15
```

> ⚠️ `depends_on` only waits for the container to **start**, not for the service inside to be **ready**. Use health checks to solve this.

---

#### Health Checks — Wait Until Ready

```yaml
services:
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: mydb
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d mydb"]
      interval: 10s       # check every 10s
      timeout: 5s         # fail if no response in 5s
      retries: 5          # retry 5 times before marking unhealthy
      start_period: 30s   # grace period on startup

  backend:
    image: my-backend
    depends_on:
      db:
        condition: service_healthy   # wait until db is HEALTHY ✅
```

**Checking health status:**
```bash
docker ps
```

**Output:**
```
CONTAINER ID   IMAGE         STATUS
a1b2c3d4e5f6   postgres:15   Up 30 seconds (healthy)
f6e5d4c3b2a1   my-backend    Up 10 seconds
```

---

#### Environment Files (`.env`)

Instead of hardcoding secrets in `docker-compose.yml`, use `.env` files.

**`.env` file:**
```env
POSTGRES_USER=admin
POSTGRES_PASSWORD=supersecret123
POSTGRES_DB=production_db
REDIS_PASSWORD=redissecret
APP_PORT=5000
```

**`docker-compose.yml` using `.env`:**
```yaml
version: "3.8"

services:
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}

  backend:
    image: my-backend
    env_file:
      - .env             # load ALL variables from .env file
    ports:
      - "${APP_PORT}:5000"
```

> 🔒 Always add `.env` to `.gitignore` to avoid committing secrets!

**Multiple env files:**
```yaml
  backend:
    env_file:
      - .env             # shared base config
      - .env.production  # environment-specific overrides
```

---

### Compose Commands

#### Start Services

```bash
# Start all services in detached (background) mode
docker compose up -d
```

**Output:**
```
[+] Running 5/5
 ✔ Network myapp_app_network    Created   0.1s
 ✔ Volume "myapp_postgres_data" Created   0.0s
 ✔ Container myapp-db-1         Started   1.2s
 ✔ Container myapp-cache-1      Started   1.1s
 ✔ Container myapp-backend-1    Started   2.3s
```

#### Stop Services

```bash
# Stop and remove containers (keeps volumes)
docker compose down

# Stop and remove containers + volumes (⚠️ deletes data)
docker compose down -v

# Stop without removing containers
docker compose stop
```

**Output:**
```
[+] Running 4/4
 ✔ Container myapp-backend-1    Removed   0.3s
 ✔ Container myapp-cache-1      Removed   0.2s
 ✔ Container myapp-db-1         Removed   0.5s
 ✔ Network myapp_app_network    Removed   0.1s
```

#### View Logs

```bash
# Logs from all services
docker compose logs

# Follow live logs
docker compose logs -f

# Logs from a specific service
docker compose logs -f backend

# Last 50 lines from db
docker compose logs --tail=50 db
```

**Output:**
```
backend-1  | Server running on port 5000
backend-1  | Connected to PostgreSQL
db-1       | LOG: database system is ready to accept connections
cache-1    | * Ready to accept connections
```

#### Scale Services

```bash
# Run 3 instances of the backend service
docker compose up -d --scale backend=3
```

**Output:**
```
[+] Running 5/5
 ✔ Container myapp-db-1        Running   0.0s
 ✔ Container myapp-cache-1     Running   0.0s
 ✔ Container myapp-backend-1   Running   0.0s
 ✔ Container myapp-backend-2   Started   1.2s
 ✔ Container myapp-backend-3   Started   1.3s
```

```bash
# Verify running containers
docker compose ps
```

**Output:**
```
NAME                 IMAGE          STATUS         PORTS
myapp-backend-1      my-backend     Up 2 minutes   0.0.0.0:5000->5000/tcp
myapp-backend-2      my-backend     Up 1 minute
myapp-backend-3      my-backend     Up 1 minute
myapp-cache-1        redis:7        Up 2 minutes   6379/tcp
myapp-db-1           postgres:15    Up 2 minutes   5432/tcp
```

#### Other Useful Commands

```bash
# Rebuild images before starting
docker compose up -d --build

# Pull latest base images
docker compose pull

# List running services
docker compose ps

# Run a one-off command in a service
docker compose exec backend sh
docker compose exec db psql -U user -d mydb

# Restart a specific service
docker compose restart backend

# View resource usage
docker compose top
```

---

## 4. Full Practice Project

Let's build a **complete Todo API** with Node.js + PostgreSQL + Redis using everything covered.

### Project Structure

```
todo-app/
├── backend/
│   ├── src/
│   │   └── index.js
│   ├── Dockerfile
│   └── package.json
├── init.sql
├── .env
├── .dockerignore
└── docker-compose.yml
```

---

### `backend/Dockerfile` (Multi-Stage)

```dockerfile
# Stage 1: Install dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Production image
FROM node:20-alpine AS production
WORKDIR /app

# Copy deps from stage 1
COPY --from=deps /app/node_modules ./node_modules
COPY src/ ./src/
COPY package.json .

EXPOSE 5000
CMD ["node", "src/index.js"]
```

---

### `.dockerignore`

```dockerignore
node_modules/
.git/
.env
*.log
coverage/
.DS_Store
```

---

### `init.sql` (Auto-runs when PostgreSQL starts)

```sql
CREATE TABLE IF NOT EXISTS todos (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO todos (title) VALUES
  ('Learn Docker'),
  ('Master Docker Compose'),
  ('Build something awesome');
```

---

### `.env`

```env
POSTGRES_USER=todouser
POSTGRES_PASSWORD=todopassword
POSTGRES_DB=tododb
REDIS_URL=redis://cache:6379
DATABASE_URL=postgres://todouser:todopassword@db:5432/tododb
APP_PORT=5000
```

---

### `docker-compose.yml`

```yaml
version: "3.8"

services:

  backend:
    build:
      context: ./backend
      target: production
    ports:
      - "${APP_PORT}:5000"
    env_file:
      - .env
    volumes:
      - ./backend/src:/app/src   # hot reload in dev
    networks:
      - todo_network
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_started
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - todo_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 20s

  cache:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - todo_network

networks:
  todo_network:
    driver: bridge

volumes:
  postgres_data:
  redis_data:
```

---

### Practice Commands & Expected Outputs

```bash
# 1. Start everything
docker compose up -d --build
```

```
[+] Building 18.4s (10/10) FINISHED
 => [backend deps 1/3] FROM node:20-alpine          5.2s
 => [backend deps 2/3] COPY package*.json ./         0.1s
 => [backend deps 3/3] RUN npm ci --only=production  8.3s
 => [backend production 1/3] COPY node_modules       0.5s
 => [backend production 2/3] COPY src/               0.1s
 => exporting to image                               0.3s

[+] Running 5/5
 ✔ Network todo-app_todo_network    Created   0.1s
 ✔ Volume "todo-app_postgres_data"  Created   0.0s
 ✔ Volume "todo-app_redis_data"     Created   0.0s
 ✔ Container todo-app-db-1          Healthy   15.3s
 ✔ Container todo-app-cache-1       Started   1.1s
 ✔ Container todo-app-backend-1     Started   16.2s
```

```bash
# 2. Check all containers
docker compose ps
```

```
NAME                    STATUS              PORTS
todo-app-backend-1      Up 1 minute         0.0.0.0:5000->5000/tcp
todo-app-cache-1        Up 1 minute         6379/tcp
todo-app-db-1           Up 1 minute (healthy)  5432/tcp
```

```bash
# 3. View logs
docker compose logs -f backend
```

```
todo-app-backend-1  | Server started on port 5000
todo-app-backend-1  | Connected to PostgreSQL at db:5432
todo-app-backend-1  | Redis connected at redis://cache:6379
```

```bash
# 4. Connect to database and verify seed data
docker compose exec db psql -U todouser -d tododb -c "SELECT * FROM todos;"
```

```
 id |           title           | completed |         created_at
----+---------------------------+-----------+----------------------------
  1 | Learn Docker              | f         | 2024-06-01 10:00:00.123456
  2 | Master Docker Compose     | f         | 2024-06-01 10:00:00.123456
  3 | Build something awesome   | f         | 2024-06-01 10:00:00.123456
(3 rows)
```

```bash
# 5. Scale backend to 3 instances
docker compose up -d --scale backend=3
```

```
[+] Running 5/5
 ✔ Container todo-app-db-1        Running
 ✔ Container todo-app-cache-1     Running
 ✔ Container todo-app-backend-1   Running
 ✔ Container todo-app-backend-2   Started
 ✔ Container todo-app-backend-3   Started
```

```bash
# 6. Tear everything down (keep volumes)
docker compose down
```

```
[+] Running 4/4
 ✔ Container todo-app-backend-1   Removed   0.4s
 ✔ Container todo-app-cache-1     Removed   0.2s
 ✔ Container todo-app-db-1        Removed   0.6s
 ✔ Network todo-app_todo_network  Removed   0.1s
```

```bash
# 7. Tear down and DELETE all volumes (fresh start)
docker compose down -v
```

```
[+] Running 6/6
 ✔ Container todo-app-backend-1       Removed
 ✔ Container todo-app-cache-1         Removed
 ✔ Container todo-app-db-1            Removed
 ✔ Volume todo-app_postgres_data      Removed
 ✔ Volume todo-app_redis_data         Removed
 ✔ Network todo-app_todo_network      Removed
```

---

## Quick Reference Cheatsheet

```bash
# ── Build Context ─────────────────────────────────────
docker build -t app .                    # build from current dir
docker build -t app -f custom.Dockerfile # custom Dockerfile
docker build --target builder -t app .   # build specific stage

# ── Multi-Stage ───────────────────────────────────────
COPY --from=builder /app/binary .        # copy from stage by name
COPY --from=0 /app/binary .              # copy from stage by index

# ── Compose ───────────────────────────────────────────
docker compose up -d                     # start in background
docker compose up -d --build             # rebuild then start
docker compose down                      # stop & remove containers
docker compose down -v                   # + delete volumes
docker compose ps                        # list services
docker compose logs -f [service]         # follow logs
docker compose exec [service] sh         # open shell in service
docker compose restart [service]         # restart one service
docker compose pull                      # pull latest images
docker compose up -d --scale app=3       # run 3 app instances
docker compose top                       # show resource usage
```

---

