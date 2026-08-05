### Essential lifecycle commands
 
```bash
docker container ls               # list running containers
docker container ls -a            # list ALL containers (including stopped ones)
docker container stop <id>        # stop a running container
docker container start <id>       # start a stopped container
docker container rm <id>          # remove a container (must be stopped first)
docker container rm -f <id>       # force remove (stops and removes)
```
 
You can refer to a container by its **ID** (first few characters are enough) or its **name**.
 
```bash
# Give your container a friendly name
docker container run -d --name my-web -p 8080:80 nginx
docker container stop my-web
```
 
---
 
##  Working with Images
 
```bash
docker image pull nginx           # download an image from Docker Hub
docker image ls                   # list images you have locally
docker image rm nginx             # remove an image
```
 
**Docker Hub** (hub.docker.com) is the default public registry — a huge library of pre-built images for databases, languages, web servers, and more.
 
### Tags
 
Images have **tags** that usually indicate the version:
 
```bash
docker image pull nginx:1.27      # specific version
docker image pull nginx:latest    # the "latest" tag (default if you omit it)
docker image pull python:3.12-slim
```
 
>  **Tip:** Avoid relying on `latest` in real projects — it can change unexpectedly. Pin a specific version for predictability.
 
---
 
##  Inspecting and Interacting with Containers
 
These commands are how you debug and understand what's happening inside.
 
```bash
docker container logs <id>            # see the container's output/logs
docker container logs -f <id>         # follow logs live (like tail -f)
 
docker container exec -it <id> bash   # open an interactive shell inside the container
docker container exec -it <id> sh     # use sh if bash isn't available (e.g. alpine images)
 
docker container inspect <id>         # detailed JSON info: networks, mounts, config, etc.
docker container stats                # live resource usage of running containers
```
 
The `docker container exec -it ... bash` command is extremely useful — it "drops you inside" a running container so you can look around, just like SSH-ing into a machine.
 
Breaking down `-it`:
 
- `-i` — interactive (keeps input open)
- `-t` — allocates a terminal (gives you a proper prompt)
Type `exit` to leave the container's shell (the container keeps running if it was detached).
 
---
 
##  Cleaning Up
 
Containers and images pile up over time. Clean them periodically:
 
```bash
docker container rm $(docker container ls -aq)   # remove all stopped containers
docker image prune                               # remove unused (dangling) images
docker system prune                              # remove all unused data (containers, networks, images)
```
 
>  Be careful with `prune` — it deletes things. Read what it asks before confirming.
 
---
 
## Command Cheat Sheet
 
| Task | Command |
|------|---------|
| Run a container | `docker container run -d -p HOST:CONTAINER image` |
| List running containers | `docker container ls` |
| List all containers | `docker container ls -a` |
| Stop a container | `docker container stop <id>` |
| Remove a container | `docker container rm <id>` |
| List images | `docker image ls` |
| Download an image | `docker image pull <image>` |
| Remove an image | `docker image rm <image>` |
| View logs | `docker container logs <id>` |
| Shell into a container | `docker container exec -it <id> bash` |
| Inspect details | `docker container inspect <id>` |
 
---