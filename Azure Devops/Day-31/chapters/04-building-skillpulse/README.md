# Chapter 4: Building SkillPulse

> Build and run the SkillPulse application locally using Docker Compose.

**Prerequisites**: Docker and Docker Compose installed, Chapters 1-3 completed.

---

## What We're Building

SkillPulse is a **Skill Tracker / Learning Dashboard** with three services:

```
┌──────────────────────────────────────────────┐
│                   Browser                     │
│              http://localhost                  │
└──────────────────┬───────────────────────────┘
                   │ Port 80
┌──────────────────▼───────────────────────────┐
│                  Nginx                        │
│         (Reverse Proxy + Static Files)        │
│                                               │
│   /          → Serves HTML/CSS/JS (frontend)  │
│   /api/*     → Proxies to Go backend          │
│   /health    → Proxies to Go backend          │
└──────────────────┬───────────────────────────┘
                   │ Port 8080 (internal)
┌──────────────────▼───────────────────────────┐
│              Go Backend (Gin)                  │
│            REST API on :8080                   │
│                                               │
│   GET    /api/skills      → List all skills    │
│   POST   /api/skills      → Add a skill        │
│   GET    /api/skills/:id  → Skill details      │
│   DELETE /api/skills/:id  → Delete a skill     │
│   POST   /api/skills/:id/log → Log session     │
│   GET    /api/dashboard   → Dashboard stats    │
│   GET    /health          → Health check       │
└──────────────────┬───────────────────────────┘
                   │ Port 3306 (internal)
┌──────────────────▼───────────────────────────┐
│               MySQL 8.0                       │
│         Database: skillpulse                  │
│                                               │
│   Tables: skills, learning_logs               │
└──────────────────────────────────────────────┘
```

---

## Project Structure

```
project/skillpulse/
├── backend/
│   ├── main.go              # Entry point
│   ├── go.mod               # Go module
│   ├── handlers/
│   │   ├── skills.go        # Skill CRUD
│   │   ├── logs.go          # Learning logs
│   │   └── dashboard.go     # Dashboard + health
│   ├── models/
│   │   └── skill.go         # Data structures
│   ├── database/
│   │   └── db.go            # MySQL connection
│   └── Dockerfile           # Multi-stage build
├── frontend/
│   ├── index.html           # Dashboard page
│   ├── css/style.css        # Styles
│   └── js/app.js            # Frontend logic
├── nginx/nginx.conf          # Reverse proxy config
├── mysql/init.sql            # Schema + seed data
├── docker-compose.yml        # Orchestration
└── .env.example              # Env vars template
```

---

## The Backend

The backend is a Go REST API using the [Gin framework](https://gin-gonic.com/).

### main.go

```go
package main

import (
    "log"
    "os"

    "github.com/gin-gonic/gin"
    "github.com/trainwithshubham/skillpulse/database"
    "github.com/trainwithshubham/skillpulse/handlers"
)

func main() {
    database.Connect()

    router := gin.Default()

    api := router.Group("/api")
    {
        api.GET("/skills", handlers.GetSkills)
        api.POST("/skills", handlers.CreateSkill)
        api.GET("/skills/:id", handlers.GetSkill)
        api.DELETE("/skills/:id", handlers.DeleteSkill)
        api.POST("/skills/:id/log", handlers.CreateLog)
        api.GET("/dashboard", handlers.GetDashboard)
    }

    router.GET("/health", handlers.HealthCheck)

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("SkillPulse API running on port %s", port)
    router.Run(":" + port)
}
```

### Database Schema

Two tables with a one-to-many relationship:

```sql
CREATE TABLE skills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) DEFAULT '',
    target_hours INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE learning_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    skill_id INT NOT NULL,
    hours DECIMAL(4,1) NOT NULL,
    notes TEXT,
    log_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE
);
```

`ON DELETE CASCADE` means deleting a skill also deletes all its logs.

### Dockerfile — Multi-Stage Build

```dockerfile
# Stage 1: Build the Go binary
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY . .
RUN go mod tidy && CGO_ENABLED=0 GOOS=linux go build -o skillpulse .

# Stage 2: Run with a tiny image
FROM alpine:3.19
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY --from=builder /app/skillpulse .
EXPOSE 8080
CMD ["./skillpulse"]
```

Stage 1 uses `golang:1.22-alpine` (~300MB) to compile. Stage 2 uses `alpine:3.19` (~5MB) to run. Final image is ~20MB.

---

## The Frontend

Plain HTML/CSS/JavaScript — no framework. Features:
- Dashboard stats (total skills, hours, sessions)
- Skills grid with progress bars
- Modals for adding skills and logging sessions
- CSS Grid layout, custom properties for theming
- `fetch()` for API calls, no build step needed

---

## Nginx Config

```nginx
server {
    listen 80;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://backend:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /health {
        proxy_pass http://backend:8080;
    }
}
```

`http://backend:8080` works because Docker Compose networking lets services find each other by name.

---

## Docker Compose

```yaml
services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${DB_NAME}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
      - ./mysql/init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build: ./backend
    environment:
      DB_HOST: db
      DB_PORT: "3306"
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      DB_NAME: ${DB_NAME}
    depends_on:
      db:
        condition: service_healthy

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./frontend:/usr/share/nginx/html:ro
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - backend

volumes:
  mysql_data:
```

**Startup order**: MySQL starts first (with healthcheck), backend waits for MySQL to be healthy, Nginx starts last.

---

## Run It Locally

```bash
cd project/skillpulse
cp .env.example .env
docker-compose up --build
```

Wait for: `backend-1 | SkillPulse API running on port 8080`

Open **http://localhost** — you should see the dashboard with seed data (5 pre-loaded skills).

[Screenshot: SkillPulse dashboard with seed data]

**Try it out:**
1. Add a new skill — click "+ Add Skill"
2. Log a session — click "Log Session" on any skill
3. Watch the progress bar update
4. Check the API: http://localhost/api/skills
5. Health check: http://localhost/health → `{"status": "healthy"}`

**Stop:**

```bash
docker-compose down       # Stop containers
docker-compose down -v    # Stop + remove database data
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Port 80 in use | Stop other web servers: `sudo lsof -i :80` |
| Backend can't connect to DB | Wait 30 seconds — it retries automatically |
| init.sql didn't run | `docker-compose down -v` then rebuild |
| Frontend not updating | Hard refresh: Cmd+Shift+R / Ctrl+Shift+R |
| Docker permission denied | `sudo usermod -aG docker $USER`, restart terminal |

---

## What's Next

In **[Chapter 5: Azure Pipelines — CI](../05-pipelines-ci/)**, we'll automate this. Every push to `main` will automatically build and test SkillPulse — no more manual `docker-compose build`.

---

[<< Previous: Chapter 3 — Azure Repos](../03-azure-repos/) | [Next: Chapter 5 — Azure Pipelines CI >>](../05-pipelines-ci/)
