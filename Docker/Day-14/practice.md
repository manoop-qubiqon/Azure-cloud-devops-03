# Dockerfile Practice Exercises

A set of hands-on exercises that build from beginner to advanced. Each one gives you a goal, the starting files you'd create, and a hint. Try writing the Dockerfile yourself before peeking at the solution.

---

## Exercise 1: Your First Image (Beginner)

**Goal:** Containerize a simple static HTML page served by Nginx.

**Project files:**

```
project/
├── Dockerfile
└── index.html
```

`index.html`:

```html
<h1>Hello from Docker!</h1>
```

**Task:** Write a Dockerfile that uses an Nginx base image and copies `index.html` into the web root (`/usr/share/nginx/html`).

<details>
<summary>Solution</summary>

```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
```

Build and run:

```bash
docker build -t static-site .
docker run -d -p 8080:80 static-site
# Visit http://localhost:8080
```
</details>

---

## Exercise 2: A Python Script (Beginner)

**Goal:** Run a one-off Python script inside a container.

**Project files:**

```
project/
├── Dockerfile
└── greet.py
```

`greet.py`:

```python
print("Containerized Python is running!")
```

**Task:** Use a slim Python base, copy the script in, and run it with `CMD`.

<details>
<summary>Solution</summary>

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY greet.py .
CMD ["python", "greet.py"]
```
</details>

---

## Exercise 3: Installing Dependencies (Intermediate)

**Goal:** Build a Python Flask web app that installs packages from `requirements.txt`.

**Project files:**

```
project/
├── Dockerfile
├── requirements.txt
└── app.py
```

`requirements.txt`:

```
flask==3.0.0
```

`app.py`:

```python
from flask import Flask
app = Flask(__name__)

@app.route("/")
def home():
    return "Flask in Docker!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

**Task:** Copy and install dependencies *before* copying the app code so the dependency layer stays cached. Expose port 5000.

<details>
<summary>Solution</summary>

```dockerfile
FROM python:3.12-slim
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000
CMD ["python", "app.py"]
```

Notice that copying `requirements.txt` first means changing `app.py` won't bust the `pip install` cache layer.
</details>

---

## Exercise 4: Node.js App with Environment Variables (Intermediate)

**Goal:** Containerize a small Node.js app that reads a port from an environment variable.

**Project files:**

```
project/
├── Dockerfile
├── package.json
└── server.js
```

`server.js`:

```javascript
const http = require("http");
const port = process.env.PORT || 3000;
http.createServer((req, res) => res.end("Node in Docker!"))
    .listen(port, () => console.log(`Listening on ${port}`));
```

**Task:** Install dependencies with `npm install`, set a default `PORT` env var, and start the server.

<details>
<summary>Solution</summary>

```dockerfile
FROM node:20-alpine
WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

ENV PORT=3000
EXPOSE 3000
CMD ["node", "server.js"]
```

Override the port at runtime: `docker run -p 4000:4000 -e PORT=4000 myapp`
</details>

---

## Exercise 5: Run as a Non-Root User (Intermediate)

**Goal:** Take the Flask app from Exercise 3 and harden it by running as a non-root user.

**Task:** Create a dedicated user and switch to it with `USER` before the app starts.

<details>
<summary>Solution</summary>

```dockerfile
FROM python:3.12-slim
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

# Create a non-root user and hand over ownership
RUN useradd --create-home appuser && chown -R appuser /app
USER appuser

EXPOSE 5000
CMD ["python", "app.py"]
```

Verify inside the container with `docker exec <container> whoami` — it should print `appuser`.
</details>

---

## Exercise 6: Multi-Stage Build (Advanced)

**Goal:** Build a Go program in one stage and ship only the compiled binary in a tiny final image.

**Project files:**

```
project/
├── Dockerfile
└── main.go
```

`main.go`:

```go
package main

import "fmt"

func main() {
    fmt.Println("Go binary running in a minimal container!")
}
```

**Task:** Use a `golang` image to compile, then copy the binary into a `distroless` or `alpine` runtime image.

<details>
<summary>Solution</summary>

```dockerfile
# --- Build stage ---
FROM golang:1.22 AS builder
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -o /bin/app main.go

# --- Runtime stage ---
FROM gcr.io/distroless/static-debian12
COPY --from=builder /bin/app /bin/app
ENTRYPOINT ["/bin/app"]
```

Compare image sizes with `docker images` — the multi-stage result is often under 10 MB versus hundreds of MB for the build image.
</details>

---

## Exercise 7: Optimize a Bad Dockerfile (Advanced)

**Goal:** Fix the problems in this deliberately inefficient Dockerfile.

```dockerfile
FROM ubuntu:latest
RUN apt-get update
RUN apt-get install -y python3
RUN apt-get install -y python3-pip
COPY . /app
RUN pip3 install -r /app/requirements.txt
WORKDIR /app
CMD python3 app.py
```

**Problems to spot:**
- `latest` tag isn't reproducible.
- Multiple `RUN` layers that should be combined.
- Package caches never cleaned up.
- Source copied before dependencies, hurting cache reuse.
- Shell-form `CMD` handles signals poorly.

<details>
<summary>Improved version</summary>

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "app.py"]
```

Using an official Python base eliminates the manual apt installs entirely, dependencies are cached separately from source, and the exec-form `CMD` forwards signals correctly.
</details>

---

## Exercise 8: Add a Health Check (Advanced)

**Goal:** Extend the Flask app so Docker can monitor whether it's actually responding.

**Task:** Add a `HEALTHCHECK` instruction that curls the app's root endpoint. (You may need to install `curl` first.)

<details>
<summary>Solution</summary>

```dockerfile
FROM python:3.12-slim
WORKDIR /app

RUN apt-get update && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD curl -f http://localhost:5000/ || exit 1

CMD ["python", "app.py"]
```

Run the container and check `docker ps` — the status column will show `healthy` once the check passes.
</details>

---

## Challenge Tasks

Once you're comfortable, try these without solutions:

1. Containerize a multi-service app (web + database) and connect them — explore `docker compose` once your individual Dockerfiles work.
2. Build the same app for both `linux/amd64` and `linux/arm64` using `docker buildx`.
3. Use a build `ARG` to switch between development and production dependency sets.
4. Write a `.dockerignore` that shrinks your build context, then measure the difference in build time.
5. Pin your base image to a digest (`@sha256:...`) instead of a tag and explain why that matters.

Work through them in order, build each image, run it, and inspect the result with `docker images`, `docker ps`, and `docker logs`. The fastest way to learn is to break things and rebuild.