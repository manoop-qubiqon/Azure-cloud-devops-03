---
 
## 1. What Is a Container?
 
A **container** is a way to run an application together with everything it needs (code, runtime, libraries, settings) in an isolated package. It shares the host machine's operating system kernel but runs as an isolated process.
 
### Container vs Virtual Machine
 
This is the comparison that makes containers "click" for most people.
 
| Aspect | Virtual Machine | Container |
|--------|-----------------|-----------|
| What it virtualizes | Entire hardware + full OS | Just the application + dependencies |
| Size | Gigabytes | Megabytes |
| Startup time | Minutes | Seconds (or less) |
| Isolation | Strong (separate OS) | Lighter (shared kernel) |
| Resource use | Heavy | Lightweight |
 
**Mental model:** A VM is like having a separate house with its own foundation, plumbing, and electricity. A container is like having a separate apartment in a shared building — you get your own private space, but the core infrastructure is shared.
 
---
 
## 2. Installing Docker
 
There are two main options:
 
- **Docker Desktop** — for Windows and macOS (and also available on Linux). Includes a GUI, the Docker engine, and Compose. Easiest for beginners.
- **Docker Engine** — the core engine installed directly on Linux, no GUI.
After installing, verify it works:
 
```bash
docker --version
docker run hello-world
```
 
If `hello-world` prints a welcome message, your installation is working correctly. This image does nothing except confirm the setup.
 
---
 
## 3. Images vs Containers (The Most Important Concept)
 
This single distinction confuses almost every beginner, so go slow here.
 
- An **image** is a read-only template — a snapshot of an application and its environment. It does not run; it just sits there.
- A **container** is a running (or stopped) instance created *from* an image.
**Analogy:** An image is like a class in programming (or a recipe, or a cookie cutter). A container is an object/instance (or the actual cooked meal, or the cookie). From one image you can start many containers.
 
```
   IMAGE  ──(docker run)──▶  CONTAINER
 (template)                  (instance)
```
 
You can run 10 containers from the same single image. Each one is independent.
 
---
 
## 4. Running Your First Containers
 
The main command you'll use constantly is `docker run`.
 
```bash
# Run an nginx web server in the background, mapping port 8080 to the container's port 80
docker run -d -p 8080:80 nginx
```
 
Breaking down the flags:
 
- `-d` — **detached** mode, runs in the background
- `-p 8080:80` — maps **host port 8080** to **container port 80**
- `nginx` — the image to use
Now open `http://localhost:8080` in your browser and you'll see the nginx welcome page.