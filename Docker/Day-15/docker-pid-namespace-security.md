# Docker Security: Absolute PID vs Relative PID

## Learning Objectives

After completing this lab, students will understand:

* What a PID is
* What a PID Namespace is
* What Relative PID means
* What Absolute PID means
* How Docker isolates processes
* Security implications of PID namespaces
* The risk of using `--pid=host`

---

# Introduction

Every process running on Linux has a unique Process ID (PID).

Docker uses Linux PID Namespaces to isolate container processes from the host and from other containers.

This means:

```text
A container has its own view of processes.
```

The process IDs seen inside a container are different from those seen on the host.

---

# Key Terminology

## Relative PID

The PID visible inside a container.

Example:

```text
PID 1
PID 2
PID 3
```

These IDs exist only within the container namespace.

---

## Absolute PID

The actual PID visible on the Docker host.

Example:

```text
2187
2234
2241
```

These are the real Linux process IDs.

---

# Lab Setup

We will create two containers:

* Alpine Container
* Nginx Container

---

# Step 1: Create Containers

## Alpine Container

```bash id="odjlwm"
docker run -dit --name alpine1 alpine:latest sh
```

---

## Nginx Container

```bash id="2if3hh"
docker run -dit --name nginx1 nginx:alpine
```

---

## Verify

```bash id="dxqz4z"
docker ps
```

Example:

```text id="lttdzq"
CONTAINER ID   IMAGE          NAMES
abc123         alpine         alpine1
def456         nginx:alpine   nginx1
```

---

# Step 2: Observe Relative PID

Enter Alpine:

```bash id="qg1ddh"
docker exec -it alpine1 sh
```

Install process tools:

```bash id="f2h3m9"
apk add procps
```

View processes:

```bash id="cyr2c9"
ps -ef
```

Output:

```text id="sx4cdh"
PID   USER     COMMAND
1     root     sh
25    root     ps -ef
```

---

## Observation

Inside the container:

```text id="e9afn7"
PID 1 = sh
```

The shell process appears as PID 1.

This is called the Relative PID.

---

# Step 3: Observe Relative PID in Nginx

Enter Nginx:

```bash id="5mnp7q"
docker exec -it nginx1 sh
```

Check processes:

```bash id="1u5g2g"
ps -ef
```

Output:

```text id="vdc8q6"
PID USER COMMAND

1 root nginx: master process
31 nginx nginx: worker process
```

---

## Observation

Inside the Nginx container:

```text id="kjgjyw"
PID 1 = nginx
```

Again, PID numbering starts from the container namespace.

---

# Step 4: Observe Absolute PID

Exit the containers and run:

```bash id="s13gse"
docker inspect -f '{{.State.Pid}}' alpine1
```

Example Output:

```text id="e0z7pr"
2187
```

---

Check Nginx:

```bash id="76q8k5"
docker inspect -f '{{.State.Pid}}' nginx1
```

Example Output:

```text id="p8j6s8"
2234
```

---

## Observation

Actual Linux Host PIDs:

```text id="s5ps3u"
Alpine Container = 2187
Nginx Container  = 2234
```

These are called Absolute PIDs.

---

# Visual Representation

```text id="u2stlx"
HOST OPERATING SYSTEM

PID 2187
└── alpine1
     └── PID 1 (sh)

PID 2234
└── nginx1
     └── PID 1 (nginx)
```

---

# Why Is This Important?

Without PID namespaces:

```text id="87cl8p"
Container A
    ↓
Can See
    ↓
Container B Processes
```

Security becomes weak.

---

With PID namespaces:

```text id="1adgw9"
Container A
    ↓
Sees Only Its Processes

Container B
    ↓
Sees Only Its Processes
```

Better isolation and security.

---

# Step 5: Demonstrate Process Isolation

Enter Alpine:

```bash id="xbh6n8"
docker exec -it alpine1 sh
```

Run:

```bash id="e7spbn"
ps -ef
```

Students will see only Alpine processes.

---

Enter Nginx:

```bash id="u18ccs"
docker exec -it nginx1 sh
```

Run:

```bash id="i9eqhp"
ps -ef
```

Students will see only Nginx processes.

---

## Security Benefit

```text id="0vwjy4"
Container A cannot inspect
Container B processes.
```

This is process isolation.

---

# Step 6: Demonstrate Security Risk Using Host PID Namespace

Create a container:

```bash id="c5vwst"
docker run -dit \
--name alpine-hostpid \
--pid=host \
alpine sh
```

---

Enter the container:

```bash id="k3vd66"
docker exec -it alpine-hostpid sh
```

Install process tools:

```bash id="p9vafq"
apk add procps
```

Run:

```bash id="m32wsu"
ps -ef
```

Output:

```text id="lf3q5w"
systemd
dockerd
containerd
sshd
nginx
...
```

---

## Observation

The container can now see:

* Host processes
* Docker daemon
* System services
* Other container processes

---

# Security Concern

Using:

```bash id="u26eol"
--pid=host
```

breaks PID isolation.

Generally avoid using it unless:

* Monitoring tools require it
* Troubleshooting requires it
* Security review has approved it

---

# Process Flow Diagram

```text id="m3gw1k"
Container Starts
        ↓
Docker Creates PID Namespace
        ↓
Container Gets PID 1
        ↓
Processes Are Isolated
        ↓
Host Sees Absolute PID
        ↓
Container Sees Relative PID
```

---

# Comparison Table

| Feature                  | Relative PID | Absolute PID |
| ------------------------ | ------------ | ------------ |
| Visible Inside Container | Yes          | No           |
| Visible On Host          | No           | Yes          |
| Example                  | PID 1        | PID 2187     |
| Namespace Specific       | Yes          | No           |
| Security Isolation       | Yes          | No           |

---

# Real-World Analogy

Imagine an apartment building.

```text id="wq3n6l"
Apartment Number = Relative PID
Street Address   = Absolute PID
```

Inside the apartment:

```text id="hjlwmk"
Apartment 1
Apartment 2
Apartment 3
```

Within the city:

```text id="n5ehp8"
Building A, Apartment 1
Building B, Apartment 1
```

The apartment number may repeat, but the street address is unique.

The same concept applies to Docker PID namespaces.

---

# Interview Questions

## What is a PID Namespace?

A PID Namespace isolates process IDs so that containers see only their own processes.

---

## What is Relative PID?

The process ID visible inside a container.

Example:

```text id="glnl9g"
PID 1 = nginx
```

---

## What is Absolute PID?

The actual Linux process ID visible on the Docker host.

Example:

```text id="ls81ho"
2234
```

---

## How Do You Find the Host PID of a Container?

```bash id="m6cl2f"
docker inspect -f '{{.State.Pid}}' <container_name>
```

---

## Why Is PID Isolation Important?

* Process isolation
* Security enhancement
* Reduced attack surface
* Multi-tenant container environments

---

## What Does --pid=host Do?

It disables PID namespace isolation and allows the container to see host processes.

---

# Summary

```text id="mv5o1n"
Relative PID
------------
Container View
PID 1
PID 2
PID 3

Absolute PID
------------
Host View
2187
2234
2251

PID Namespace
-------------
Provides process isolation.

--pid=host
-----------
Removes process isolation.
```

Understanding PID namespaces is a fundamental Docker security concept and is commonly discussed in Docker, Kubernetes, CKA, CKS, and DevOps interviews.
