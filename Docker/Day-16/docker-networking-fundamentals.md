# Docker Networking Fundamentals

## Learning Objectives

After completing this lab, students will understand:

* Docker networking basics
* Bridge networks
* Custom bridge networks
* Host networks
* None networks
* Port mapping
* Container-to-container communication
* Docker DNS resolution
* Networking security best practices

---

# What is Docker Networking?

Docker networking allows containers to:

* Communicate with each other
* Communicate with the host machine
* Communicate with external networks

Every container gets its own:

* Network namespace
* IP address
* Routing table
* Network interfaces

---

# View Available Networks

Run:

```bash
docker network ls
```

Example Output:

```text
NETWORK ID     NAME      DRIVER
abc123         bridge    bridge
def456         host      host
ghi789         none      null
```

---

# Default Docker Networks

Docker creates three default networks:

| Network | Purpose                 |
| ------- | ----------------------- |
| bridge  | Container communication |
| host    | Uses host network       |
| none    | No network access       |

---

# 1. Bridge Network

## What is Bridge Network?

Bridge is the default Docker network.

Containers connected to the bridge network receive private IP addresses.

Example:

```bash
docker run -dit --name web1 nginx:alpine
```

Check network:

```bash
docker inspect web1
```

Example:

```text
IPAddress: 172.17.0.2
```

---

## Process Flow

```text
Container Starts
       ↓
Connected to bridge network
       ↓
Receives private IP
       ↓
Can communicate externally
```

---

# Port Mapping

Containers are isolated.

To access services from the host:

```bash
docker run -dit \
-p 8080:80 \
--name web1 \
nginx:alpine
```

Meaning:

```text
Host Port      → Container Port
8080           → 80
```

Access:

```text
http://SERVER_IP:8080
```

---

# Real-World Example

```bash
docker run -dit \
-p 5000:5000 \
my-flask-app
```

Users access:

```text
http://server-ip:5000
```

---

# 2. Custom Bridge Network

## Why Use It?

Default bridge has limitations.

Best practice:

Create custom networks.

---

## Create Network

```bash
docker network create training-net
```

Verify:

```bash
docker network ls
```

---

## Launch Containers

```bash
docker run -dit \
--name app1 \
--network training-net \
nginx:alpine
```

```bash
docker run -dit \
--name app2 \
--network training-net \
alpine sh
```

---

# DNS Resolution

Enter app2:

```bash
docker exec -it app2 sh
```

Install tools:

```bash
apk add curl
```

Test:

```bash
curl app1
```

Output:

```text
Welcome to nginx
```

---

## Process Flow

```text
app2
  ↓
DNS Lookup
  ↓
app1
  ↓
Docker DNS
  ↓
IP Address
  ↓
Communication Success
```

---

# Benefits of Custom Networks

* Automatic DNS
* Better isolation
* Easier management
* Microservices architecture

---

# 3. Host Network

## What is Host Network?

Container shares host network stack.

No private IP.

No NAT.

No port mapping required.

---

## Example

```bash
docker run -dit \
--network host \
nginx:alpine
```

---

## Process Flow

```text
Container
     ↓
Uses Host Network Directly
     ↓
No Bridge Network
     ↓
No Port Mapping
```

---

# Security Concern

Host networking reduces isolation.

Container can directly interact with host networking resources.

Use only when necessary.

---

# 4. None Network

## What is None Network?

Container gets no network access.

Example:

```bash
docker run -dit \
--network none \
alpine sh
```

---

## Verify

```bash
docker exec -it <container> sh
```

Run:

```bash
ip addr
```

Only loopback interface exists.

---

## Process Flow

```text
Container Starts
      ↓
No Network Attached
      ↓
Cannot Reach Internet
      ↓
Maximum Isolation
```

---

# Network Inspection

Inspect bridge network:

```bash
docker network inspect bridge
```

Inspect custom network:

```bash
docker network inspect training-net
```

Useful information:

* Connected containers
* IP addresses
* Subnet
* Gateway

---

# Visual Diagram

```text
                Docker Host
                      │
      ┌───────────────┼───────────────┐
      │               │               │
      ▼               ▼               ▼

   web1           app1            app2
172.17.0.2    172.18.0.2     172.18.0.3

      │               ▲
      │               │
      └────── DNS ────┘
```

---

# Security Best Practices

## Use Custom Networks

Preferred:

```bash
docker network create app-net
```

Avoid placing everything on default bridge.

---

## Expose Only Required Ports

Good:

```bash
-p 8080:80
```

Avoid:

```bash
-p 1-65535
```

---

## Use None Network for Secure Jobs

Example:

```bash
docker run --network none
```

Useful for:

* Batch jobs
* Security testing
* Offline processing

---

## Limit Host Networking

Avoid:

```bash
--network host
```

unless performance requirements demand it.

---

# Comparison Table

| Feature               | Bridge  | Custom Bridge | Host   | None          |
| --------------------- | ------- | ------------- | ------ | ------------- |
| Isolation             | Yes     | Yes           | No     | Maximum       |
| DNS Resolution        | Limited | Yes           | N/A    | No            |
| Port Mapping Required | Yes     | Yes           | No     | N/A           |
| Internet Access       | Yes     | Yes           | Yes    | No            |
| Recommended           | Good    | Best          | Rarely | Special Cases |

---

# Interview Questions

## What is the default Docker network?

Bridge network.

---

## How do containers communicate by name?

Using Docker DNS on custom bridge networks.

---

## Which network provides maximum isolation?

None network.

---

## Which network removes network isolation?

Host network.

---

## How do you create a custom network?

```bash
docker network create app-net
```

---

## How do you connect a container to a network?

```bash
docker run --network app-net
```

---

# Summary

```text
Bridge Network
--------------
Default Docker Network

Custom Bridge
--------------
Best Practice

Host Network
------------
Shares Host Network Stack

None Network
------------
No Network Access

Port Mapping
------------
Host Port → Container Port

Docker DNS
-----------
Container Name Resolution
```

Docker networking is a core topic in Docker, Kubernetes, CKA, CKS, and DevOps interviews and is essential for designing secure containerized applications.
