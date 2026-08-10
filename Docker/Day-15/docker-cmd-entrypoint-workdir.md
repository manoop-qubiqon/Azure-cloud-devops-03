# Docker CMD, ENTRYPOINT, and WORKDIR - Complete Practical Guide

## Learning Objectives

After completing this lab, students will understand:

* What CMD is
* What ENTRYPOINT is
* What WORKDIR is
* The difference between CMD and ENTRYPOINT
* How Docker processes commands during container startup
* Real-world use cases and interview questions

---

# 1. CMD

## Purpose

CMD provides the default command that runs when a container starts.

## Dockerfile

```dockerfile
FROM alpine:latest

CMD ["echo", "Hello from CMD"]
```

## Build the Image

```bash
docker build -f Dockerfile.cmd -t cmd-demo .
```

## Run the Container

```bash
docker run --rm cmd-demo
```

### Output

```text
Hello from CMD
```

---

## Override CMD

```bash
docker run --rm cmd-demo date
```

### Output

```text
Mon Jun 01 10:20:00 UTC 2026
```

### Explanation

CMD acts as a default command.

If another command is supplied during `docker run`, Docker replaces the CMD instruction.

---

## Process Flow

```text
Docker Build
      ↓
Docker Image Created
      ↓
docker run cmd-demo
      ↓
CMD Executes
      ↓
echo "Hello from CMD"
      ↓
Container Stops
```

---

# 2. ENTRYPOINT

## Purpose

ENTRYPOINT defines the main executable of the container.

## Dockerfile

```dockerfile
FROM alpine:latest

ENTRYPOINT ["echo"]
```

## Build

```bash
docker build -f Dockerfile.entrypoint -t entry-demo .
```

## Run

```bash
docker run --rm entry-demo Docker
```

### Output

```text
Docker
```

---

## Process Flow

```text
Docker Build
      ↓
Docker Image Created
      ↓
docker run entry-demo Docker
      ↓
ENTRYPOINT Executes
      ↓
echo Docker
      ↓
Output Displayed
```

---

## Important Note

```bash
docker run entry-demo Security
```

Docker internally executes:

```bash
echo Security
```

Arguments are appended to ENTRYPOINT.

---

## Override ENTRYPOINT

```bash
docker run --rm --entrypoint date entry-demo
```

Output:

```text
Mon Jun 01 10:20:00 UTC 2026
```

---

# 3. CMD and ENTRYPOINT Together

## Dockerfile

```dockerfile
FROM alpine:latest

ENTRYPOINT ["echo"]

CMD ["Docker Zero To Hero 🚀"]
```

## Build

```bash
docker build -t combo-demo .
```

## Run

```bash
docker run --rm combo-demo
```

### Output

```text
Docker Zero To Hero 🚀
```

---

## Override CMD

```bash
docker run --rm combo-demo "DevOps Security"
```

### Output

```text
DevOps Security
```

---

## Process Flow

```text
ENTRYPOINT = Command
CMD        = Default Arguments

docker run combo-demo
        ↓
echo "Docker Zero To Hero 🚀"
        ↓
Output Displayed
```

---

## Key Concept

```text
ENTRYPOINT = Main Command
CMD        = Default Arguments
```

This combination is commonly used in production containers.

---

# 4. WORKDIR

## Purpose

WORKDIR sets the working directory inside the container.

## Dockerfile

```dockerfile
FROM alpine:latest

WORKDIR /training

CMD ["sh"]
```

## Build

```bash
docker build -f Dockerfile.workdir -t workdir-demo .
```

## Run

```bash
docker run -it --rm workdir-demo
```

Check current directory:

```bash
pwd
```

### Output

```text
/training
```

---

## Process Flow

```text
Container Starts
       ↓
Docker Creates /training
       ↓
Switches to /training
       ↓
Starts Shell
       ↓
User lands in /training
```

---

## Why WORKDIR?

Without WORKDIR:

```bash
cd /training
```

must be executed manually.

With WORKDIR:

Docker automatically switches to the desired directory.

---

# Real-World Analogy

Imagine a car.

```text
Car = Docker Container
```

### ENTRYPOINT

```text
Engine
```

The engine is fixed and must start.

Example:

```dockerfile
ENTRYPOINT ["nginx"]
```

---

### CMD

```text
Destination
```

The destination can change.

Example:

```dockerfile
CMD ["-g", "daemon off;"]
```

---

### WORKDIR

```text
Starting Location
```

Example:

```dockerfile
WORKDIR /app
```

Docker starts operations from this location.

---

# Comparison Table

| Feature    | Purpose           | Can Override?                    |
| ---------- | ----------------- | -------------------------------- |
| CMD        | Default command   | Yes                              |
| ENTRYPOINT | Main executable   | No (unless --entrypoint is used) |
| WORKDIR    | Working directory | Not Applicable                   |

---

# Classroom Demonstration

## Demo 1 - CMD

```bash
docker run cmd-demo
docker run cmd-demo date
```

Question:

Why did the output change?

Answer:

CMD can be overridden.

---

## Demo 2 - ENTRYPOINT

```bash
docker run entry-demo
docker run entry-demo Security
```

Question:

Why is "Security" printed?

Answer:

ENTRYPOINT remains fixed and arguments are appended.

---

## Demo 3 - CMD + ENTRYPOINT

```bash
docker run combo-demo
docker run combo-demo "Docker Security"
```

Question:

What changed?

Answer:

Only CMD arguments changed.

---

## Demo 4 - WORKDIR

```bash
docker run -it workdir-demo

pwd
ls
```

Question:

Why are we already inside `/training`?

Answer:

WORKDIR automatically sets the container's working directory.

---

# Interview Questions

## What is CMD?

CMD provides the default command or arguments that run when a container starts.

---

## What is ENTRYPOINT?

ENTRYPOINT defines the main executable of the container and ensures a specific command always runs.

---

## What is WORKDIR?

WORKDIR sets the working directory inside the container.

All subsequent instructions such as RUN, COPY, and CMD execute relative to this directory.

---

## Real-World Example

```dockerfile
FROM python:3.12-alpine

WORKDIR /app

COPY . .

ENTRYPOINT ["python"]

CMD ["app.py"]
```

Docker executes:

```bash
python app.py
```

If a user runs:

```bash
docker run myapp test.py
```

Docker executes:

```bash
python test.py
```

---

# Summary

```text
CMD        → Default Command
ENTRYPOINT → Main Executable
WORKDIR    → Default Directory

ENTRYPOINT + CMD
            ↓
Best Practice for Production Containers
```

Understanding these three instructions is essential for Docker image creation, container management, troubleshooting, and DevOps interviews.
