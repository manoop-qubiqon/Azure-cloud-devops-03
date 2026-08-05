# Docker Flags & Short Keys Cheat Sheet
 
A quick reference for common Docker commands, their long flags, and the
single-letter short forms you can use instead.
 
---
 
## `docker run`
 
| Long flag | Short | Meaning |
|-----------|-------|---------|
| `--detach` | `-d` | Run container in background |
| `--interactive` | `-i` | Keep STDIN open |
| `--tty` | `-t` | Allocate a pseudo-TTY (often combined as `-it`) |
| `--name` | — | Assign a name to the container |
| `--publish` | `-p` | Map host port to container port (`-p 8080:80`) |
| `--env` | `-e` | Set an environment variable (`-e KEY=val`) |
| `--volume` | `-v` | Mount a volume / bind mount (`-v /host:/container`) |
| `--workdir` | `-w` | Set working directory inside container |
| `--user` | `-u` | Run as a specific user/UID |
| `--memory` | `-m` | Memory limit (`-m 512m`) |
| `--rm` | — | Remove container automatically when it exits |
| `--network` | — | Connect to a named network |
 
Common combo: `docker run -it --rm -p 8080:80 nginx`
 
---
 
## `docker exec`
 
| Long flag | Short | Meaning |
|-----------|-------|---------|
| `--detach` | `-d` | Run command in background |
| `--interactive` | `-i` | Keep STDIN open |
| `--tty` | `-t` | Allocate a pseudo-TTY |
| `--env` | `-e` | Set environment variable |
| `--user` | `-u` | Run as specific user |
| `--workdir` | `-w` | Working directory for the command |
 
Common combo: `docker exec -it <container> bash`
 
---
 
## `docker ps`
 
| Long flag | Short | Meaning |
|-----------|-------|---------|
| `--all` | `-a` | Show all containers (not just running) |
| `--quiet` | `-q` | Only display container IDs |
| `--filter` | `-f` | Filter output (`-f status=exited`) |
| `--no-trunc` | — | Don't truncate output |
| `--latest` | `-l` | Show the latest created container |
 
---
 
## `docker images`
 
| Long flag | Short | Meaning |
|-----------|-------|---------|
| `--all` | `-a` | Show all images including intermediates |
| `--quiet` | `-q` | Only show image IDs |
| `--filter` | `-f` | Filter output |
 
---
 
## `docker build`
 
| Long flag | Short | Meaning |
|-----------|-------|---------|
| `--tag` | `-t` | Name and optionally tag the image (`-t app:1.0`) |
| `--file` | `-f` | Path to a custom Dockerfile |
| `--build-arg` | — | Set a build-time variable |
| `--no-cache` | — | Build without using cache |
| `--quiet` | `-q` | Suppress build output |
 
Common: `docker build -t myapp:latest .`
 
---
 
## `docker rm` / `docker rmi`
 
| Long flag | Short | Meaning |
|-----------|-------|---------|
| `--force` | `-f` | Force removal of running container / used image |
| `--volumes` | `-v` | Remove associated volumes (`docker rm`) |
 
---
 
## `docker logs`
 
| Long flag | Short | Meaning |
|-----------|-------|---------|
| `--follow` | `-f` | Stream logs live |
| `--tail` | — | Show last N lines (`--tail 100`) |
| `--timestamps` | `-t` | Show timestamps |
 
---
 
## `docker stop` / `docker start` / `docker restart`
 
| Long flag | Short | Meaning |
|-----------|-------|---------|
| `--time` | `-t` | Seconds to wait before killing (`stop`/`restart`) |
| `--attach` | `-a` | Attach STDOUT/STDERR (`start`) |
| `--interactive` | `-i` | Attach STDIN (`start`) |
 
---
 
## `docker cp`
 
Copies files between host and container — no short flags, syntax is:
 
```
docker cp <container>:/path/in/container ./host/path
docker cp ./host/file <container>:/path/in/container
```
 
---
 
## Global tips
 
- Single-letter flags can be **combined**: `-it` == `-i -t`, `-itd` == `-i -t -d`.
- Long flags use `--flag value` or `--flag=value`; short flags use `-f value`.
- `-f` means different things per command (force vs. file vs. follow vs. filter) —
  always check the command context.
- Use `docker <command> --help` to see every flag for any command.
---
 
## `docker compose` quick flags
 
| Long flag | Short | Meaning |
|-----------|-------|---------|
| `--detach` | `-d` | Run services in background (`up -d`) |
| `--file` | `-f` | Specify a compose file |
| `--build` | — | Rebuild images before starting |
| `--volumes` | `-v` | Remove volumes (`down -v`) |
 
Common: `docker compose up -d` / `docker compose down`