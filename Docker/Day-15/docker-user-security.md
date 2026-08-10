# Docker Security: Why Create a User in a Dockerfile?

Creating a **non-root user** in a Dockerfile is one of the most important Docker security best practices.

---

## Why Create a User in a Dockerfile?

By default, containers run as:

```bash
root
```

This means the application inside the container has administrative privileges.

If an attacker compromises the application, they gain root access inside the container and may attempt container escape attacks or access sensitive files.

---

## Security Risk Example

### Dockerfile

```dockerfile
FROM nginx:alpine
```

Run the container:

```bash
docker run nginx:alpine
```

Check the user:

```bash
docker exec -it <container_id> sh
whoami
```

Output:

```text
root
```

The application is running as root.

---

## Secure Approach

Create a dedicated user:

```dockerfile
FROM alpine:latest

RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup

USER appuser

CMD ["sh"]
```

Build the image:

```bash
docker build -t secure-app .
```

Run the container:

```bash
docker run -it secure-app
```

Check the user:

```bash
whoami
```

Output:

```text
appuser
```

Now the container runs with limited privileges.

---

# Benefits of Creating a User

## 1. Principle of Least Privilege

Give only the permissions required.

```text
Root User  -> Full Control
App User   -> Limited Control
```

---

## 2. Prevent Accidental Changes

A non-root user cannot:

```bash
rm -rf /etc
```

or modify critical system files.

---

## 3. Reduce Impact of Vulnerabilities

Suppose your Flask application has a Remote Code Execution (RCE) vulnerability.

If running as root:

```text
Attacker -> Root Access
```

If running as appuser:

```text
Attacker -> Limited User Access
```

Damage is significantly reduced.

---

## 4. Meet Security Compliance Requirements

Many standards require containers not to run as root:

- CIS Docker Benchmark
- PCI-DSS
- SOC 2
- ISO 27001
- Kubernetes Security Best Practices

---

# Demo for Students

## Insecure Container

Dockerfile:

```dockerfile
FROM alpine
CMD ["sh"]
```

Build:

```bash
docker build -t insecure-demo .
```

Run:

```bash
docker run -it insecure-demo
```

Check:

```bash
whoami
```

Output:

```text
root
```

---

## Secure Container

Dockerfile:

```dockerfile
FROM alpine

RUN adduser -D devops

USER devops

CMD ["sh"]
```

Build:

```bash
docker build -t secure-demo .
```

Run:

```bash
docker run -it secure-demo
```

Check:

```bash
whoami
```

Output:

```text
devops
```

---

# Real-World Example: Python Flask Application

```dockerfile
FROM python:3.12-alpine

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

RUN addgroup -S flaskgrp && \
    adduser -S flaskuser -G flaskgrp

RUN chown -R flaskuser:flaskgrp /app

USER flaskuser

EXPOSE 5000

CMD ["python", "app.py"]
```

---

# Container Security Hierarchy

```text
1. Use Official Images
2. Use Minimal Images (Alpine)
3. Create Non-Root User
4. Remove Unnecessary Packages
5. Read-Only Filesystem
6. Drop Linux Capabilities
7. Scan Images for Vulnerabilities
```

---

# Interview Answer

**Question:** Why do we create a non-root user in a Dockerfile?

**Answer:**

> We create a non-root user in a Dockerfile to follow the Principle of Least Privilege. If the application is compromised, the attacker gets limited permissions instead of root access. This reduces security risks, prevents unauthorized system modifications, and helps meet security compliance requirements.