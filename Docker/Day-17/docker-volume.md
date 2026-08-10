# Docker Volumes: A Complete Guide

## Table of Contents

1. [What is a Docker Volume?](#what-is-a-docker-volume)
2. [Types of Docker Storage](#types-of-docker-storage)
3. [Volume Commands](#volume-commands)
4. [Using Volumes with Containers](#using-volumes-with-containers)
5. [Bind Mounts](#bind-mounts)
6. [tmpfs Mounts](#tmpfs-mounts)
7. [Docker Compose with Volumes](#docker-compose-with-volumes)
8. [Volume Drivers](#volume-drivers)
9. [Backup and Restore](#backup-and-restore)
10. [Best Practices](#best-practices)

---

## What is a Docker Volume?

A **Docker Volume** is a persistent storage mechanism managed by Docker, used to store and share data between containers or between a container and the host machine. Unlike data stored inside a container's writable layer, volumes persist even after the container is deleted.

### Why use Volumes?

- Data survives container restarts and removal
- Easy sharing of data between multiple containers
- Better performance than writing to a container's writable layer
- Volumes can be backed up, restored, and migrated easily
- Managed by Docker — no need to know host filesystem paths

---

## Types of Docker Storage

| Type         | Description                                      | Use Case                          |
|--------------|--------------------------------------------------|-----------------------------------|
| **Volume**   | Managed by Docker, stored in `/var/lib/docker/volumes/` | Preferred for persistent data |
| **Bind Mount** | Maps a host path directly into the container   | Dev environments, config files    |
| **tmpfs**    | Stored in host memory only (not on disk)         | Sensitive/temp data               |

---

## Volume Commands

### Create a Volume

```bash
docker volume create my_volume
```

### List All Volumes

```bash
docker volume ls
```

**Example output:**
```
DRIVER    VOLUME NAME
local     my_volume
local     postgres_data
local     nginx_logs
```

### Inspect a Volume

```bash
docker volume inspect my_volume
```

**Example output:**
```json
[
  {
    "CreatedAt": "2024-06-01T10:00:00Z",
    "Driver": "local",
    "Labels": {},
    "Mountpoint": "/var/lib/docker/volumes/my_volume/_data",
    "Name": "my_volume",
    "Options": {},
    "Scope": "local"
  }
]
```

### Remove a Volume

```bash
docker volume rm my_volume
```

> ⚠️ You cannot remove a volume that is currently in use by a container.

### Remove All Unused Volumes

```bash
docker volume prune
```

**With confirmation prompt:**
```
WARNING! This will remove all local volumes not used by at least one container.
Are you sure you want to continue? [y/N] y
Deleted Volumes:
my_volume
old_logs

Total reclaimed space: 245MB
```

### Remove Unused Volumes Without Prompt

```bash
docker volume prune -f
```

---

## Using Volumes with Containers

### Mount a Volume Using `--mount` (Recommended)

```bash
docker run -d \
  --name my_app \
  --mount source=my_volume,target=/app/data \
  nginx
```

### Mount a Volume Using `-v` Flag (Short Syntax)

```bash
docker run -d \
  --name my_app \
  -v my_volume:/app/data \
  nginx
```

### Anonymous Volume (Auto-created, unnamed)

```bash
docker run -d \
  -v /app/data \
  nginx
```

Docker auto-generates a random name for this volume.

### Read-Only Volume Mount

```bash
docker run -d \
  --name my_app \
  -v my_volume:/app/data:ro \
  nginx
```

The `:ro` flag makes the volume read-only inside the container.

### Sharing a Volume Between Two Containers

```bash
# Container 1: writes to the volume
docker run -d --name writer -v shared_data:/data busybox \
  sh -c "echo 'Hello from writer' > /data/hello.txt"

# Container 2: reads from the same volume
docker run --rm --name reader -v shared_data:/data busybox \
  cat /data/hello.txt
```

**Output:**
```
Hello from writer
```

---

## Bind Mounts

Bind mounts map a **specific directory on the host** into the container.

### Syntax

```bash
docker run -d \
  --name my_app \
  -v /host/path:/container/path \
  nginx
```

### Example: Mount Current Directory for Development

```bash
docker run -d \
  --name dev_server \
  -v $(pwd):/usr/share/nginx/html \
  -p 8080:80 \
  nginx
```

This serves your current directory via Nginx at `http://localhost:8080`.

### Bind Mount with `--mount` Syntax

```bash
docker run -d \
  --name my_app \
  --mount type=bind,source=/host/path,target=/container/path \
  nginx
```

> 💡 **Bind Mount vs Volume:** Bind mounts depend on the host's directory structure. Volumes are fully managed by Docker and are more portable.

---

## tmpfs Mounts

A **tmpfs** mount is stored in the host's memory and is never written to disk. It is deleted when the container stops.

### Create a tmpfs Mount

```bash
docker run -d \
  --name my_app \
  --tmpfs /app/temp \
  nginx
```

### tmpfs with Options

```bash
docker run -d \
  --name my_app \
  --mount type=tmpfs,destination=/app/temp,tmpfs-size=100m \
  nginx
```

Use this for sensitive data (e.g., secrets, session tokens) that should not persist.

---

## Docker Compose with Volumes

### Named Volume in `docker-compose.yml`

```yaml
version: "3.8"

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: secret
    volumes:
      - postgres_data:/var/lib/postgresql/data

  app:
    image: my_app:latest
    volumes:
      - app_logs:/var/log/app

volumes:
  postgres_data:
  app_logs:
```

### Bind Mount in Compose

```yaml
version: "3.8"

services:
  web:
    image: nginx
    volumes:
      - ./html:/usr/share/nginx/html
    ports:
      - "8080:80"
```

### Sharing a Volume Between Services

```yaml
version: "3.8"

services:
  writer:
    image: busybox
    command: sh -c "echo 'data' > /shared/output.txt"
    volumes:
      - shared:/shared

  reader:
    image: busybox
    command: cat /shared/output.txt
    volumes:
      - shared:/shared
    depends_on:
      - writer

volumes:
  shared:
```

### External Volume (Pre-existing)

```yaml
volumes:
  pre_existing_volume:
    external: true
```

---

## Volume Drivers

Docker supports custom volume drivers for cloud and network storage.

### Local Driver (Default)

```bash
docker volume create --driver local my_volume
```

### NFS Volume

```bash
docker volume create \
  --driver local \
  --opt type=nfs \
  --opt o=addr=192.168.1.100,rw \
  --opt device=:/nfs/shared \
  nfs_volume
```

### Using an NFS Volume in a Container

```bash
docker run -d \
  --name my_app \
  -v nfs_volume:/data \
  nginx
```

---

## Backup and Restore

### Backup a Volume

```bash
docker run --rm \
  -v my_volume:/data \
  -v $(pwd):/backup \
  busybox \
  tar czf /backup/my_volume_backup.tar.gz -C /data .
```

This creates `my_volume_backup.tar.gz` in your current directory.

### Restore a Volume from Backup

```bash
# Create a new volume
docker volume create restored_volume

# Restore data into it
docker run --rm \
  -v restored_volume:/data \
  -v $(pwd):/backup \
  busybox \
  tar xzf /backup/my_volume_backup.tar.gz -C /data
```

### Copy Files Into a Running Container's Volume

```bash
docker cp ./localfile.txt my_container:/app/data/localfile.txt
```

### Copy Files Out of a Volume

```bash
docker cp my_container:/app/data/output.txt ./output.txt
```

---

## Best Practices

| Practice | Description |
|----------|-------------|
| **Use named volumes** | Prefer named volumes over anonymous ones for easier management |
| **Use `--mount` syntax** | More explicit and readable than `-v` for production configs |
| **Don't store secrets in volumes** | Use Docker secrets or environment variables instead |
| **Clean up unused volumes** | Run `docker volume prune` regularly to free disk space |
| **Use bind mounts for dev only** | In production, prefer managed volumes for portability |
| **Label your volumes** | Add labels for easier identification and automation |
| **Back up critical volumes** | Always have a backup strategy for stateful data |

### Labeling a Volume

```bash
docker volume create \
  --label env=production \
  --label project=myapp \
  prod_data
```

### Filter Volumes by Label

```bash
docker volume ls --filter label=env=production
```

---

## Quick Reference Cheatsheet

```bash
# Create
docker volume create my_vol

# List
docker volume ls

# Inspect
docker volume inspect my_vol

# Remove one
docker volume rm my_vol

# Remove all unused
docker volume prune

# Run with volume
docker run -v my_vol:/data image_name

# Run with bind mount
docker run -v $(pwd):/app image_name

# Run with tmpfs
docker run --tmpfs /tmp image_name

# Backup volume
docker run --rm -v my_vol:/data -v $(pwd):/backup busybox \
  tar czf /backup/backup.tar.gz -C /data .

# Restore volume
docker run --rm -v my_vol:/data -v $(pwd):/backup busybox \
  tar xzf /backup/backup.tar.gz -C /data
```

---

