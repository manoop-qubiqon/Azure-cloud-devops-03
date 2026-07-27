# IP Addressing & Subnetting 
 
---
 
## 1. What an IP Address Really Is
 
An IPv4 address is **32 bits**, written as four 8-bit octets in dotted decimal:
 
```
192 . 168 . 1 . 10
11000000 . 10101000 . 00000001 . 00001010
```
 
Two pieces are always present in any IP address:
- **Network portion** — which network the host belongs to
- **Host portion** — which device within that network
The boundary between the two is defined by the **subnet mask** (or its CIDR equivalent `/n`).
 
 
---
 
## 2. IPv4 Classes (Legacy, but You Must Know Them)
 
Before 1993, IPs were assigned in **fixed classes**. We don't use classful routing anymore — but exam questions, legacy docs, and casual conversation still reference classes.
 
| Class | First Octet Range | Default Mask | Default CIDR | # Networks | Hosts per Network | Purpose |
|-------|-------------------|--------------|--------------|------------|-------------------|---------|
| A | 1 – 126 | 255.0.0.0 | /8 | 126 | 16,777,214 | Huge orgs, governments |
| B | 128 – 191 | 255.255.0.0 | /16 | 16,384 | 65,534 | Medium-large orgs |
| C | 192 – 223 | 255.255.255.0 | /24 | 2,097,152 | 254 | Small networks |
| D | 224 – 239 | — | — | — | — | Multicast |
| E | 240 – 255 | — | — | — | — | Experimental / reserved |
 
**Special / reserved:**
- `0.0.0.0/8` — "this network" / default route
- `127.0.0.0/8` — **loopback** (most famously `127.0.0.1`)
- `169.254.0.0/16` — **link-local** / APIPA (AWS uses `169.254.169.254` for instance metadata!)
- `255.255.255.255` — limited broadcast
---
 
## 3. CIDR Notation (the Modern Way)
 
**CIDR = Classless Inter-Domain Routing.** Introduced in 1993 to stop IPv4 exhaustion by allowing **variable-length** network boundaries.
 
Format: `IP/prefix-length`
 
```
192.168.1.0/24      ← 24 bits = network, 8 bits = host
10.0.0.0/16         ← 16 bits = network, 16 bits = host
172.16.5.0/22       ← 22 bits = network, 10 bits = host
```
 
**The math you must memorize:**
- Total addresses in a block = **2^(32 − prefix)**
- Usable hosts = **2^(32 − prefix) − 2** (subtract network ID + broadcast)
| CIDR | Mask | Addresses | Usable Hosts |
|------|------|-----------|--------------|
| /8 | 255.0.0.0 | 16,777,216 | 16,777,214 |
| /16 | 255.255.0.0 | 65,536 | 65,534 |
| /24 | 255.255.255.0 | 256 | 254 |
| /25 | 255.255.255.128 | 128 | 126 |
| /26 | 255.255.255.192 | 64 | 62 |
| /27 | 255.255.255.224 | 32 | 30 |
| /28 | 255.255.255.240 | 16 | 14 |
| /29 | 255.255.255.248 | 8 | 6 |
| /30 | 255.255.255.252 | 4 | 2 |
| /31 | 255.255.255.254 | 2 | 2 (point-to-point) |
| /32 | 255.255.255.255 | 1 | 1 (single host) |
 
> **Cloud caveat:** AWS reserves **5 addresses per subnet** (network, VPC router, DNS, future use, broadcast), not 2. So a `/28` in AWS gives you **11 usable IPs**, not 14. 
 
---
 
## 4. Subnet Mask, Network ID, Broadcast Address
 
For any IP + mask, three things are derived:
 
### Network ID
Bitwise **AND** of IP and mask. Identifies the subnet.
 
### Broadcast Address
All **host bits** set to **1**. Used to address every host on the subnet.
 
### Usable Host Range
Everything between network ID + 1 and broadcast − 1.
 
**Worked example: `192.168.10.130/26`**
 
1. `/26` mask → `255.255.255.192` → host portion is 6 bits → block size = 64
2. Subnets step by 64 in the 4th octet: `.0`, `.64`, `.128`, `.192`
3. `.130` falls in the `.128` subnet
4. **Network ID:** `192.168.10.128`
5. **Broadcast:** `192.168.10.191`
6. **Usable range:** `192.168.10.129` – `192.168.10.190` (62 hosts)
**The "block size shortcut"** — for any /n where n > 24:
 
```
Block size = 256 − (last octet of mask)
Subnets start at multiples of the block size.
```
 
This trick alone will get learners through 90% of subnetting problems.
 
---
 
## 5. Subnetting Practice
 
### Exercise A — Splitting a /24
 
You're given `192.168.1.0/24`. Split it into **4 equal subnets**.
 
- 4 subnets → borrow 2 bits → new prefix = `/26`
- Block size = 64
| Subnet | Network ID | Broadcast | Usable Range |
|--------|------------|-----------|--------------|
| 1 | 192.168.1.0 | 192.168.1.63 | .1 – .62 |
| 2 | 192.168.1.64 | 192.168.1.127 | .65 – .126 |
| 3 | 192.168.1.128 | 192.168.1.191 | .129 – .190 |
| 4 | 192.168.1.192 | 192.168.1.255 | .193 – .254 |
 
### Exercise B — Splitting a /16
 
You're given `10.10.0.0/16`. Carve out **8 subnets** for 8 microservice tiers.
 
- 8 subnets → borrow 3 bits → `/19`
- Block size in 3rd octet = 32
| Subnet | CIDR | Usable Hosts |
|--------|------|--------------|
| 1 | 10.10.0.0/19 | 8,190 |
| 2 | 10.10.32.0/19 | 8,190 |
| 3 | 10.10.64.0/19 | 8,190 |
| 4 | 10.10.96.0/19 | 8,190 |
| 5 | 10.10.128.0/19 | 8,190 |
| 6 | 10.10.160.0/19 | 8,190 |
| 7 | 10.10.192.0/19 | 8,190 |
| 8 | 10.10.224.0/19 | 8,190 |
 
### Exercise C — Splitting a /8 for AWS VPCs across regions
 
You own `10.0.0.0/8`. Allocate **/16 per region** (256 regions possible).
 
| Region | VPC CIDR |
|--------|----------|
| us-east-1 | 10.0.0.0/16 |
| us-west-2 | 10.1.0.0/16 |
| eu-west-1 | 10.2.0.0/16 |
| ap-south-1 | 10.3.0.0/16 |
| … | … |
 
Inside each VPC, split into **/20 subnets per AZ** (4,094 hosts each), 16 subnets per VPC — plenty of room for public, private, db, and spare tiers across 3 AZs.
 
> **Real-world DevOps habit:** Always document your IP plan in a spreadsheet or IPAM tool (e.g., AWS VPC IPAM, NetBox). The day you need to peer two VPCs and discover overlapping CIDRs is a bad day.
 
---
 
## 6. Private vs Public IP Ranges
 
### Private — RFC 1918 (and friends)
 
These are **not routable on the public internet**. Use freely inside VPCs, on-prem, home networks.
 
| Range | CIDR | Size | Common Use |
|-------|------|------|------------|
| 10.0.0.0 – 10.255.255.255 | 10.0.0.0/8 | 16.7M | Enterprises, large cloud VPCs |
| 172.16.0.0 – 172.31.255.255 | 172.16.0.0/12 | 1M | Mid-size networks, AWS default VPC |
| 192.168.0.0 – 192.168.255.255 | 192.168.0.0/16 | 65K | Home routers, labs |
| 169.254.0.0/16 | 169.254.0.0/16 | 65K | Link-local (AWS metadata service `169.254.169.254`) |
| 100.64.0.0/10 | 100.64.0.0/10 | 4M | **CGNAT** (carrier-grade NAT); AWS EKS pods often use this |
 
### Public
 
Everything else (excluding multicast/reserved). Assigned by **IANA → RIRs → ISPs**. Cloud providers own huge public blocks (AWS, GCP, Azure each have tens of millions of IPs).
 
### NAT — How private talks to public
- **SNAT** (Source NAT): outbound traffic from private gets rewritten with a public IP. Cloud equivalent: **NAT Gateway / NAT Instance**.
- **DNAT** (Destination NAT): inbound public traffic redirected to a private IP. Cloud equivalent: **Elastic IP attached to instance / Load Balancer**.
---
 
## 7. IPv6 Basics
 
**Why we needed it:** IPv4 has ~4.3 billion addresses. We exhausted IANA's pool in 2011. IPv6 has **2^128 ≈ 3.4 × 10^38** — enough for every grain of sand to have its own internet.
 
### Address Format
 
- **128 bits**, written as **8 groups of 4 hex digits**, separated by `:`
- Each group = 16 bits
```
2001:0db8:85a3:0000:0000:8a2e:0370:7334
```
 
### Compression Rules
 
1. **Drop leading zeros** in each group:
   ```
   2001:db8:85a3:0:0:8a2e:370:7334
   ```
2. **Replace one consecutive run of all-zero groups with `::`** (only once per address):
   ```
   2001:db8:85a3::8a2e:370:7334
   ```
 
**Examples:**
| Full | Compressed |
|------|------------|
| `0000:0000:0000:0000:0000:0000:0000:0001` | `::1` (loopback) |
| `0000:0000:0000:0000:0000:0000:0000:0000` | `::` (unspecified) |
| `fe80:0000:0000:0000:1234:5678:9abc:def0` | `fe80::1234:5678:9abc:def0` |
 
### Key IPv6 Ranges
 
| Range | Purpose |
|-------|---------|
| `::1/128` | Loopback (IPv4's `127.0.0.1`) |
| `::/128` | Unspecified |
| `fe80::/10` | **Link-local** (auto-assigned on every interface) |
| `fc00::/7` | **Unique local** (private; IPv4's RFC 1918 equivalent) |
| `2000::/3` | **Global unicast** (public internet) |
| `ff00::/8` | **Multicast** |
 
> **No broadcast in IPv6.** Broadcast was replaced by multicast and anycast — cleaner, more efficient.
 
### IPv6 Concepts Worth a Mention
 
- **No NAT needed** — every device can have a public address. But firewalls still matter.
- **SLAAC** (Stateless Address Autoconfiguration) — devices self-assign addresses using the router's prefix + their MAC-derived suffix. DHCPv6 also exists.
- **Dual-stack** — most production environments run IPv4 and IPv6 simultaneously during transition.
### Cloud Notes
- AWS, Azure, GCP all support IPv6 in VPCs, but it's **opt-in**. Default VPCs are IPv4-only.
- Kubernetes supports **dual-stack** services as of v1.23 stable.
- IPv6-only clusters are increasingly common at scale to avoid pod IP exhaustion.
---
 
## 8. DevOps / Cloud Application Map
 
| Concept | Where IP/CIDR Knowledge Matters |
|---------|----------------------------------|
| **VPC CIDR design** | Pick a private block large enough to grow, non-overlapping with peers/on-prem |
| **Subnet per AZ** | Split VPC into /N subnets — public, private, DB tiers × 3 AZs |
| **Security Groups / NACLs** | Source/destination defined by CIDR |
| **VPC Peering / Transit Gateway** | Fails immediately if CIDRs overlap |
| **VPN / Direct Connect** | On-prem and cloud must agree on non-overlapping CIDRs |
| **Kubernetes Pod CIDR** | `kubeadm init --pod-network-cidr=` ; can't overlap node CIDR |
| **Kubernetes Service CIDR** | Cluster-internal virtual IPs (`kube-proxy`) |
| **CNI plugins (Calico, Cilium)** | Allocate pod IPs from the cluster CIDR |
| **NAT Gateway sizing** | One NAT per AZ, each handles port-based connections |
| **Load Balancer target IPs** | ALB/NLB need free IPs in each subnet they live in |
 
### A real CIDR plan (memorize this pattern)
 
```
VPC:              10.20.0.0/16    (65,536 IPs)
├── Public AZ-a:    10.20.0.0/20    (4,094 IPs)
├── Public AZ-b:    10.20.16.0/20
├── Public AZ-c:    10.20.32.0/20
├── Private AZ-a:   10.20.64.0/20
├── Private AZ-b:   10.20.80.0/20
├── Private AZ-c:   10.20.96.0/20
├── DB AZ-a:        10.20.128.0/22  (1,022 IPs)
├── DB AZ-b:        10.20.132.0/22
├── DB AZ-c:        10.20.136.0/22
└── Reserved:       10.20.192.0/18  (growth)
```
 
---
 
## 9. Common Learner Mistakes
 
- **Forgetting AWS reserves 5 IPs, not 2.** `/29` is unusable for most things in AWS.
- **Confusing `/24` mask with class C.** They're numerically equal but conceptually different.
- **Overlapping CIDRs between VPC and on-prem.** Discovered the day you try to peer or VPN.
- **Sizing too small.** EKS pods can eat IPs fast — `/26` per subnet is rarely enough.
- **Picking `192.168.0.0/16` for a corporate VPC.** Works, but every employee's home router uses it — VPN clients will have routing conflicts. Prefer `10.x` or `172.16.x`.
- **Thinking `::1` and `127.0.0.1` are interchangeable.** They're equivalent purposes on different stacks; an app must bind to both for dual-stack support.
---
 
## 10. Hands-On Lab Ideas
 
1. **CIDR drills** — Give 10 IPs with prefixes; learners produce network ID, broadcast, usable range, and host count.
2. **AWS VPC build** — Design a 3-AZ VPC for a 3-tier app, justify every CIDR.
3. **VPC peering with overlap** — Intentionally create two VPCs with overlapping CIDRs, watch the peering fail, fix it.
4. **kubeadm cluster** — Spin up a cluster and inspect pod/service CIDRs with `kubectl cluster-info dump | grep -i cidr`.
5. **IPv6 ping** — On any Linux box: `ping6 ::1` and `ip -6 addr show` to see auto-assigned link-local.
6. **Subnet calculator face-off** — No tools allowed for the first 5 problems; then compare with `ipcalc` or `sipcalc`.
---
 
## 11. Quick Reference Card
 
```
IPv4: 32 bits, 4 octets, dotted decimal
IPv6: 128 bits, 8 hex groups, :: compresses zeros
 
Block size shortcut (octet 4): 256 − mask octet
Hosts per subnet: 2^(32−prefix) − 2  (AWS: −5)
 
Private ranges:
  10.0.0.0/8        172.16.0.0/12        192.168.0.0/16
  169.254.0.0/16    100.64.0.0/10 (CGNAT)
 
IPv6 must-knows:
  ::1 = loopback        fe80::/10 = link-local
  fc00::/7 = ULA        2000::/3 = global unicast
  ff00::/8 = multicast  (no broadcast in IPv6)
 
CIDR cheat:
  /24 = 256 IPs    /20 = 4,096    /16 = 65,536
  /28 = 16 IPs     /26 = 64       /22 = 1,024
```
 
---