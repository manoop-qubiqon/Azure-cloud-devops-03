# Creating a Dockerfile: A Practical Guide

A Dockerfile is a plain text file containing a sequence of instructions that Docker reads to build an image automatically. Each instruction creates a layer in the image, and the resulting image can be run as a container anywhere Docker is installed.

## How It Works

When you run `docker build`, Docker reads the Dockerfile from top to bottom, executing each instruction in order. Instructions are cached as layers, so unchanged steps are reused on subsequent builds, making rebuilds faster. The file is conventionally named `Dockerfile` (no extension) and lives at the root of your project.

```bash
docker build -t myapp:latest .
docker run -p 8080:8080 myapp:latest
```

## Core Instructions

### FROM

Every Dockerfile begins with `FROM`, which sets the base image you build on top of. Choosing a small, specific base (like an `-slim` or `-alpine` variant) keeps your image lean.

```dockerfile
FROM python:3.12-slim
```

### WORKDIR

Sets the working directory for any `RUN`, `CMD`, `COPY`, and `ADD` instructions that follow. It creates the directory if it doesn't exist, and is cleaner than chaining `cd` commands.

```dockerfile
WORKDIR /app
```

### COPY and ADD

`COPY` transfers files and directories from your build context into the image. `ADD` does the same but additionally supports remote URLs and automatic extraction of local tar archives. Prefer `COPY` unless you specifically need `ADD`'s extra behavior.

```dockerfile
COPY requirements.txt .
COPY . .
```

### RUN

Executes a command during the build, typically to install dependencies. Chain related commands with `&&` to reduce the number of layers and clean up in the same step.

```dockerfile
RUN apt-get update && apt-get install -y \
        curl \
    && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir -r requirements.txt
```

### ENV and ARG

`ENV` sets environment variables that persist in the running container. `ARG` defines build-time variables available only during the build.

```dockerfile
ARG VERSION=1.0
ENV APP_ENV=production
```

### EXPOSE

Documents which port the container listens on. This is informational; you still publish ports with `-p` at runtime.

```dockerfile
EXPOSE 8080
```

### CMD and ENTRYPOINT

`CMD` provides the default command run when the container starts and can be overridden on the command line. `ENTRYPOINT` sets a command that always runs, with `CMD` supplying default arguments to it. Use the exec form (JSON array) rather than the shell form for predictable signal handling.

```dockerfile
ENTRYPOINT ["python"]
CMD ["app.py"]
```

## A Complete Example

```dockerfile
FROM python:3.12-slim

WORKDIR /app

# Install dependencies first to leverage layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

EXPOSE 8080

CMD ["python", "app.py"]
```

## Multi-Stage Builds

Multi-stage builds let you use one stage to compile or build artifacts and a second, smaller stage to run them. This keeps build tools out of the final image, dramatically reducing its size.

```dockerfile
# Build stage
FROM golang:1.22 AS builder
WORKDIR /src
COPY . .
RUN go build -o /bin/app .

# Runtime stage
FROM gcr.io/distroless/base-debian12
COPY --from=builder /bin/app /bin/app
ENTRYPOINT ["/bin/app"]
```

## Best Practices

- **Order instructions by change frequency.** Put rarely-changing steps (installing dependencies) before frequently-changing ones (copying source code) so the cache stays valid longer.
- **Use a `.dockerignore` file.** Exclude things like `.git`, `node_modules`, and local build artifacts from the build context to speed builds and avoid leaking secrets.
- **Pin versions.** Reference specific tags or digests for base images rather than `latest` to make builds reproducible.
- **Run as a non-root user.** Add a dedicated user and switch to it with `USER` to limit the blast radius if the container is compromised.
- **Combine and clean up in a single `RUN`.** Removing package caches in the same layer where you install keeps the layer small.
- **Keep images minimal.** Smaller images pull faster, have a smaller attack surface, and start quicker.

## A `.dockerignore` Example

```
.git
.gitignore
node_modules
*.log
.env
Dockerfile
README.md
```

## Building and Running

```bash
# Build the image with a tag
docker build -t myapp:1.0 .

# Run it, mapping host port 8080 to container port 8080
docker run -d -p 8080:8080 --name myapp myapp:1.0

# Inspect logs
docker logs myapp
```

With these instructions and practices, you can write Dockerfiles that build quickly, stay small, and run reliably across environments.