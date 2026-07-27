# OSI & TCP/IP Models
 
---
 
## 1. Why a Network Model at All?
 
Networking is layered so each layer can solve **one problem well** and hide the rest. As a DevOps/Cloud engineer, you almost never touch layers 1–2, but you live in layers 3, 4, and 7 every day — VPC routing (L3), load balancers and firewalls (L4), API gateways and ingress (L7).
 
**Two models matter:**
- **OSI** — 7 layers, conceptual. Great for teaching and troubleshooting vocabulary.
- **TCP/IP** — 4 layers, what the internet actually runs on.
---
 
## 2. The OSI Model (7 Layers)
 
Mnemonic (top → bottom): **A**ll **P**eople **S**eem **T**o **N**eed **D**ata **P**rocessing
Or bottom → top: **P**lease **D**o **N**ot **T**hrow **S**ausage **P**izza **A**way
 
| # | Layer | Job | Data Unit | Examples |
|---|-------|-----|-----------|----------|
| 7 | Application | Interface to user/app | Data | HTTP, HTTPS, DNS, SSH, FTP, SMTP |
| 6 | Presentation | Encoding, encryption, compression | Data | TLS/SSL, JPEG, ASCII, JSON, gzip |
| 5 | Session | Open/maintain/close sessions | Data | NetBIOS, RPC, TLS handshake |
| 4 | Transport | End-to-end delivery, reliability | Segment | TCP, UDP, QUIC |
| 3 | Network | Logical addressing & routing | Packet | IP, ICMP, BGP, OSPF |
| 2 | Data Link | Node-to-node delivery on same network | Frame | Ethernet, ARP, MAC, VLAN |
| 1 | Physical | Bits on the wire/air | Bits | Cables, fiber, Wi-Fi radios, NICs |
 
### Layer-by-layer talking points
 
**L1 – Physical**
The actual signal. Copper, fiber, radio. In cloud, this is abstracted — but availability zones still map to real physical buildings.
 
**L2 – Data Link**
Switches operate here. MAC addresses, ARP, VLANs. In AWS/Azure: subnets share an L2 broadcast domain conceptually, though the cloud provider virtualises it.
 
**L3 – Network**
**IP lives here.** Routing tables, route propagation, NAT gateways, VPC peering, transit gateways — all L3. Teach `ping`, `traceroute`, CIDR math here.
 
**L4 – Transport**
**TCP vs UDP** — the single most important distinction. TCP = reliable, ordered, connection-oriented (web, SSH, DBs). UDP = fast, fire-and-forget (DNS, VoIP, gaming, QUIC underlying).
Cloud relevance: Network Load Balancers (NLB) operate at L4. Security group rules specify protocol + port — that's L4 too.
 
**L5 – Session**
Often glossed over. Think TLS handshake establishment, session cookies, RDP/SSH session state.
 
**L6 – Presentation**
Encryption (TLS), encoding (UTF-8, base64), serialization (JSON, protobuf). When learners ask "where does HTTPS sit?" — the **S** (TLS) is L6, HTTP is L7.
 
**L7 – Application**
HTTP, gRPC, DNS, SMTP. **Application Load Balancers, API Gateways, Ingress controllers, WAFs, service meshes (Istio, Linkerd)** all operate here. This is where most DevOps debugging happens.
 
---
 
## 3. The TCP/IP Model (4 Layers)
 
The model that actually runs the internet. Pragmatic, fewer layers.
 
| # | Layer | Maps to OSI | Examples |
|---|-------|-------------|----------|
| 4 | Application | 5, 6, 7 | HTTP, DNS, SSH, TLS |
| 3 | Transport | 4 | TCP, UDP |
| 2 | Internet | 3 | IP, ICMP, routing |
| 1 | Network Access (Link) | 1, 2 | Ethernet, Wi-Fi, ARP |
 
> Some textbooks split Link into Physical + Data Link, giving a **5-layer hybrid model**. Mention it so learners aren't confused when they see it.
 
---
 
## 4. Side-by-Side Comparison
 
```
   OSI (7 layers)            TCP/IP (4 layers)
┌──────────────────┐
│  7. Application  │  ┐
├──────────────────┤  │
│  6. Presentation │  ├──►  Application
├──────────────────┤  │
│  5. Session      │  ┘
├──────────────────┤
│  4. Transport    │  ────►  Transport
├──────────────────┤
│  3. Network      │  ────►  Internet
├──────────────────┤
│  2. Data Link    │  ┐
├──────────────────┤  ├──►  Network Access
│  1. Physical     │  ┘
└──────────────────┘
```
 
**Key differences to highlight:**
- OSI is a **reference model** (theoretical). TCP/IP is the **implementation** (what we actually use).
- TCP/IP came first historically; OSI came after as a standardization effort.
- Most real-world docs mix the two — people say "L4 load balancer" (OSI) while running on TCP/IP.
---
 
## 5. Encapsulation — The Key Concept
 
Each layer wraps the data from the layer above. This is **the** concept learners must internalize.
 
```
[ HTTP request ]                           ← L7 data
[ TLS record [ HTTP ] ]                    ← L6
[ TCP header | TLS [ HTTP ] ]              ← L4 segment
[ IP header | TCP | TLS [ HTTP ] ]         ← L3 packet
[ Eth header | IP | TCP | TLS [ HTTP ] ]   ← L2 frame
```
 
On the receiving side, each layer strips its header and hands the payload up. This is why a Wireshark capture shows nested headers.
 
---
 
## 6. DevOps / Cloud Mapping (the part learners care about)
 
| Cloud / DevOps Concept | Layer | Notes |
|------------------------|-------|-------|
| VPC, Subnet, Route Table | L3 | IP routing within and across VPCs |
| Security Groups | L3/L4 | Allow by IP (L3) + protocol/port (L4) |
| NACLs (Network ACLs) | L3/L4 | Stateless, subnet-level |
| NAT Gateway | L3 | Source IP translation |
| Network Load Balancer (NLB) | L4 | TCP/UDP, preserves source IP |
| Application Load Balancer (ALB) | L7 | Host/path-based routing, header rules |
| API Gateway | L7 | Auth, rate limiting, request transformation |
| Ingress Controller (NGINX, Traefik) | L7 | HTTP routing in Kubernetes |
| Service Mesh (Istio, Linkerd) | L7 | mTLS, retries, circuit breaking |
| CloudFront / CDN | L7 | HTTP caching at edge |
| WAF | L7 | Inspects HTTP payload |
| VPN, Direct Connect | L2/L3 | Site-to-site connectivity |
| DNS (Route 53, Cloud DNS) | L7 | Runs over UDP/53 (and TCP for large responses) |
| TLS termination | L6 (with L4 socket) | Done at LB or ingress |
 
---
 
## 7. Protocols & Ports Cheat Sheet
 
| Protocol | Port | Transport | Layer | Use |
|----------|------|-----------|-------|-----|
| HTTP | 80 | TCP | 7 | Web |
| HTTPS | 443 | TCP | 7 (+ TLS at 6) | Secure web |
| SSH | 22 | TCP | 7 | Remote shell |
| DNS | 53 | UDP (and TCP) | 7 | Name resolution |
| SMTP | 25, 587 | TCP | 7 | Email send |
| FTP | 21 | TCP | 7 | File transfer |
| NTP | 123 | UDP | 7 | Time sync |
| SNMP | 161 | UDP | 7 | Monitoring |
| Kubernetes API | 6443 | TCP | 7 | Cluster control |
| PostgreSQL | 5432 | TCP | 7 | DB |
| Redis | 6379 | TCP | 7 | Cache |
 
---
 
## 8. Troubleshooting by Layer (great for labs)
 
Teach learners to **debug bottom-up** when something breaks:
 
| Symptom | Suspect Layer | Tools |
|---------|---------------|-------|
| No link light, NIC down | L1 | `ip link`, physical check |
| Can't ARP, wrong VLAN | L2 | `ip neigh`, `arp -a` |
| `ping` fails, wrong route | L3 | `ping`, `traceroute`, `ip route` |
| Port closed, firewall, no SYN-ACK | L4 | `telnet host port`, `nc -zv`, `ss`, `netstat` |
| TLS handshake fails, cert error | L5/L6 | `openssl s_client -connect host:443` |
| 4xx/5xx, app misbehaving | L7 | `curl -v`, app logs, browser devtools, Wireshark |

 
---
 
## 9. Suggested Lecture Flow (≈ 90 min session)
 
1. **Hook (5 min)** — Ask: "What happens when you type `https://google.com` and press Enter?" Park this question; return to it at the end.
2. **Why layering? (10 min)** — Modularity analogy: postal system, restaurant kitchen.
3. **OSI walkthrough (25 min)** — Top-down or bottom-up; use the table.
4. **TCP/IP and comparison (10 min)** — Show why we have two models.
5. **Encapsulation demo (10 min)** — Live Wireshark capture of a `curl` request.
6. **Cloud mapping (15 min)** — The table in §6 — this is the payoff.
7. **Troubleshooting drill (10 min)** — Run through 2–3 scenarios.
8. **Recap with the opening question (5 min)** — Now answer "what happens when you hit Enter."
---
 
## 10. Recommended Hands-on Labs
 
- `tcpdump`/Wireshark capture of an HTTP vs HTTPS request — see the headers per layer.
- Create an ALB + NLB in AWS; route the same app through both and compare.
- Misconfigure a security group on purpose; have learners diagnose using `nc` and `curl`.
- DNS deep-dive: `dig +trace google.com` to show recursive resolution.
- TLS handshake inspection: `openssl s_client -connect example.com:443 -showcerts`.
- Kubernetes: trace a request from Ingress → Service → Pod and label each hop's layer.
---
 
## 11. Common Learner Misconceptions
 
- **"TCP/IP replaced OSI."** — No. OSI is still the vocabulary; TCP/IP is the implementation.
- **"HTTPS is a separate protocol."** — It's HTTP over TLS. Same L7 protocol, encrypted at L6.
- **"Load balancers are all the same."** — L4 vs L7 LBs have very different capabilities and costs.
- **"Security groups are firewalls at L7."** — No, they filter at L3/L4 only. Use a WAF for L7.
- **"UDP is unreliable, so never use it."** — DNS, QUIC (HTTP/3), and video conferencing all use UDP successfully.
---
 
## 12. Quick Reference Card (print/share with class)
 
```
L7 Application   → HTTP, DNS, SSH, gRPC      → ALB, API GW, Ingress, WAF
L6 Presentation  → TLS, JSON, gzip           → Cert mgmt, TLS termination
L5 Session       → Session state, RPC        → Sticky sessions
L4 Transport     → TCP, UDP                  → NLB, Security Groups, ports
L3 Network       → IP, ICMP, routing         → VPC, subnets, route tables, NAT
L2 Data Link     → Ethernet, ARP, MAC        → VLANs (mostly abstracted in cloud)
L1 Physical      → Cables, radio             → AZ hardware (fully abstracted)
```
 
---
 
