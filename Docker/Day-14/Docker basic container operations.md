# Basic Container Operations in Docker
 
A grouped reference using the **new management command syntax** (`docker container <subcommand>`, introduced in Docker 1.13+). Each section shows the syntax and a worked example.
 
---
 
## 1. Create a Container
 
Creates a container but does **not** start it.
 
**Syntax**
```bash
docker container create [OPTIONS] IMAGE [COMMAND] [ARG...]
```
 
**Example**
```bash
docker container create --name web httpd
```
 
---
 
## 2. Run a Container
 
Creates **and** starts a container in one step.
 
**Syntax**
```bash
docker container run [OPTIONS] IMAGE [COMMAND] [ARG...]
```
 
**Example**
```bash
# Detached, named "web", host port 8080 -> container port 80
docker container run -d --name web -p 8080:80 httpd
```
 
---
 
## 3. List Containers
 
**Syntax**
```bash
docker container ls [OPTIONS]
```
 
**Example**
```bash
# Running containers
docker container ls
 
# All containers (running + stopped)
docker container ls -a
```
 
---
 
## 4. Start / Stop / Restart
 
**Syntax**
```bash
docker container start   CONTAINER
docker container stop    CONTAINER
docker container restart CONTAINER
docker container pause   CONTAINER
docker container unpause CONTAINER
```
 
**Example**
```bash
docker container start web
docker container stop web
docker container restart web
```
 
---
 
## 5. Attach to a Running Container
 
Connects your terminal's input/output/error streams to the container's **main process** (PID 1). Unlike `exec`, it does not start a new process — it hooks into the one already running.
 
**Syntax**
```bash
docker container attach [OPTIONS] CONTAINER
```
 
**Example**
```bash
# Attach to the running container "web"
docker container attach web
 
# Attach but keep stdin closed, and don't forward signals
docker container attach --no-stdin --sig-proxy=false web
```
 
> **Tip:** Detach without stopping the container using the escape sequence `Ctrl-P` then `Ctrl-Q`. Pressing `Ctrl-C` while attached sends SIGINT to the main process and may stop the container.
 
---
 
## 6. Inspect & Monitor
 
**Syntax**
```bash
docker container logs    CONTAINER
docker container inspect CONTAINER
docker container stats   [CONTAINER...]
docker container top     CONTAINER
```
 
**Example**
```bash
# Follow logs in real time
docker container logs -f web
 
# Low-level details (JSON)
docker container inspect web
 
# Live resource usage
docker container stats web
```
 
---
 
## 7. Execute a Command Inside a Container
 
**Syntax**
```bash
docker container exec [OPTIONS] CONTAINER COMMAND [ARG...]
```
 
**Example**
```bash
# Interactive shell
docker container exec -it web bash
 
# Single command
docker container exec web ls /usr/local/apache2/htdocs
```
 
---
 
## 8. Copy Files
 
**Syntax**
```bash
docker container cp SRC_PATH CONTAINER:DEST_PATH
docker container cp CONTAINER:SRC_PATH DEST_PATH
```
 
**Example**
```bash
# Host -> container
docker container cp index.html web:/usr/local/apache2/htdocs/
 
# Container -> host
docker container cp web:/usr/local/apache2/conf/httpd.conf ./httpd.conf
```
 
---
 
## 9. Remove Containers
 
**Syntax**
```bash
docker container rm [OPTIONS] CONTAINER [CONTAINER...]
docker container prune
```
 
**Example**
```bash
# Remove a stopped container
docker container rm web
 
# Force-remove a running container
docker container rm -f web
 
# Remove all stopped containers
docker container prune
```
 
---
 
## 10. Rename & Update
 
**Syntax**
```bash
docker container rename OLD_NAME NEW_NAME
docker container update [OPTIONS] CONTAINER
```
 
**Example**
```bash
docker container rename web frontend
docker container update --memory 512m --cpus 1 frontend
```
 
---
 
## Quick Reference Cheat Sheet
 
| Action | Command |
|--------|---------|
| Create | `docker container create --name web httpd` |
| Run | `docker container run -d --name web httpd` |
| List running | `docker container ls` |
| List all | `docker container ls -a` |
| Start | `docker container start web` |
| Stop | `docker container stop web` |
| Restart | `docker container restart web` |
| Attach | `docker container attach web` |
| Logs | `docker container logs -f web` |
| Shell into | `docker container exec -it web bash` |
| Inspect | `docker container inspect web` |
| Copy in | `docker container cp file web:/path` |
| Remove | `docker container rm -f web` |
| Clean stopped | `docker container prune` |