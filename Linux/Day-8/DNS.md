# DNS Notes — Domain Name System
 
## What is DNS?
 
**DNS (Domain Name System)** is the "phonebook of the internet." It translates human-friendly domain names (like `www.google.com`) into machine-readable IP addresses (like `142.250.182.4`) that computers use to identify each other on a network.
 
Without DNS, we would have to remember IP addresses for every website we visit.
 
---
 
## Why DNS is Needed
 
- Humans remember **names** easily (e.g., `youtube.com`).
- Computers communicate using **IP addresses** (e.g., `172.217.160.110`).
- DNS bridges this gap by mapping names to IPs.
---
 
## How DNS Works (Step-by-Step)
 
When you type `www.example.com` in a browser, the following happens:
 
1. **Browser Cache Check** — The browser first checks its own cache for the IP.
2. **OS Cache Check** — If not found, the OS checks its local cache (`/etc/hosts`, etc.).
3. **Recursive Resolver** — The request goes to a DNS resolver (usually provided by your ISP or services like Google `8.8.8.8` or Cloudflare `1.1.1.1`).
4. **Root Name Server** — The resolver asks a root server, which directs it to the correct TLD server (`.com`, `.org`, etc.).
5. **TLD Name Server** — The TLD server points to the **authoritative name server** for `example.com`.
6. **Authoritative Name Server** — Returns the actual IP address for `www.example.com`.
7. **Response to Browser** — The IP is returned to the browser, which then loads the website.
8. **Caching** — The result is cached at multiple levels (browser, OS, resolver) for faster future lookups.
```
User → Browser → OS → Resolver → Root → TLD → Authoritative → IP Address
```
 
---
 
## DNS Hierarchy
 
```
                  . (Root)
                    |
        ┌───────────┼───────────┐
       .com        .org        .net   (TLD - Top Level Domain)
        |
     example.com               (Second Level Domain)
        |
   www.example.com             (Subdomain / Host)
```
 
---
 
## Types of DNS Records
 
DNS records are instructions stored in authoritative DNS servers. Each record type serves a specific purpose.
 
### 1. A Record (Address Record)
 
- Maps a **domain name to an IPv4 address**.
- Most common DNS record type.
**Example:**
```
example.com.    IN    A    192.0.2.1
```
Meaning: `example.com` → `192.0.2.1`
 
---
 
### 2. AAAA Record (Quad-A Record)
 
- Maps a **domain name to an IPv6 address**.
- Used for next-generation IP addressing.
**Example:**
```
example.com.    IN    AAAA    2001:0db8:85a3::8a2e:0370:7334
```
 
---
 
### 3. CNAME Record (Canonical Name)
 
- Creates an **alias** from one domain to another.
- Used when one domain should point to another instead of an IP.
**Example:**
```
www.example.com.    IN    CNAME    example.com.
blog.example.com.   IN    CNAME    medium.com.
```
Meaning: `www.example.com` and `blog.example.com` are aliases.
 
---
 
### 4. MX Record (Mail Exchange)
 
- Specifies the **mail server** responsible for receiving emails for a domain.
- Has a priority value (lower number = higher priority).
**Example:**
```
example.com.    IN    MX    10    mail1.example.com.
example.com.    IN    MX    20    mail2.example.com.
```
Meaning: Email to `@example.com` first tries `mail1`, falls back to `mail2`.
 
---
 
### 5. NS Record (Name Server)
 
- Identifies the **authoritative name servers** for a domain.
- Tells the internet which servers hold DNS records for that domain.
**Example:**
```
example.com.    IN    NS    ns1.example.com.
example.com.    IN    NS    ns2.example.com.
```
 
---
 
### 6. TXT Record (Text Record)
 
- Stores **text information** about a domain.
- Commonly used for email security (SPF, DKIM, DMARC) and domain ownership verification.
**Example:**
```
example.com.    IN    TXT    "v=spf1 include:_spf.google.com ~all"
example.com.    IN    TXT    "google-site-verification=abc123xyz"
```
 
---
 
### 7. PTR Record (Pointer Record)
 
- Performs a **reverse DNS lookup** (IP to domain name).
- Opposite of an A record.
- Used in email servers for spam verification.
**Example:**
```
1.2.0.192.in-addr.arpa.    IN    PTR    example.com.
```
Meaning: IP `192.0.2.1` → `example.com`
 
---
 
### 8. SOA Record (Start of Authority)
 
- Contains **administrative information** about the DNS zone.
- Includes primary name server, admin email, serial number, refresh intervals.
- Every zone must have exactly one SOA record.
**Example:**
```
example.com.    IN    SOA    ns1.example.com. admin.example.com. (
                              2026050901  ; Serial
                              3600        ; Refresh
                              1800        ; Retry
                              1209600     ; Expire
                              86400 )     ; Minimum TTL
```
 
---
 
### 9. SRV Record (Service Record)
 
- Specifies the **location of services** (hostname and port).
- Used by VoIP, XMPP, Microsoft services, etc.
**Example:**
```
_sip._tcp.example.com.    IN    SRV    10 5 5060 sipserver.example.com.
```
Format: `priority weight port target`
 
---
 
### 10. CAA Record (Certification Authority Authorization)
 
- Specifies which **Certificate Authorities (CAs)** can issue SSL/TLS certificates for the domain.
- Improves security by restricting unauthorized cert issuance.
**Example:**
```
example.com.    IN    CAA    0 issue "letsencrypt.org"
```
 
---
 
## Quick Summary Table
 
| Record Type | Purpose | Example Value |
|-------------|---------|---------------|
| **A** | Maps domain → IPv4 | `192.0.2.1` |
| **AAAA** | Maps domain → IPv6 | `2001:db8::1` |
| **CNAME** | Domain alias | `example.com` |
| **MX** | Mail server | `mail.example.com` |
| **NS** | Name server | `ns1.example.com` |
| **TXT** | Text/verification info | `v=spf1 ...` |
| **PTR** | Reverse lookup (IP → domain) | `example.com` |
| **SOA** | Zone authority info | Admin details |
| **SRV** | Service location | `port + hostname` |
| **CAA** | Allowed SSL CA | `letsencrypt.org` |
 
---
 
## Useful DNS Commands
 
### Linux / macOS
 
```bash
# Query A record
dig example.com
 
# Query specific record type
dig example.com MX
dig example.com TXT
dig example.com AAAA
 
# Short answer only
dig +short example.com
 
# Reverse DNS lookup
dig -x 8.8.8.8
 
# Use a specific DNS server
dig @8.8.8.8 example.com
 
# Trace full DNS resolution path
dig +trace example.com
 
# Alternative: nslookup
nslookup example.com
nslookup -type=MX example.com
 
# Host command
host example.com
host -t MX example.com
```
 
### Windows
 
```cmd
nslookup example.com
nslookup -type=MX example.com
ipconfig /flushdns
```
 
---
 
## DNS Caching & TTL
 
- **TTL (Time To Live)** — How long a DNS record can be cached (in seconds).
- Lower TTL = faster propagation but more DNS queries.
- Higher TTL = better performance but slower changes.
**Common TTL values:**
- `300` (5 minutes) — frequent updates
- `3600` (1 hour) — standard
- `86400` (1 day) — stable records
---
 
## Common Public DNS Servers
 
| Provider | Primary | Secondary |
|----------|---------|-----------|
| Google | `8.8.8.8` | `8.8.4.4` |
| Cloudflare | `1.1.1.1` | `1.0.0.1` |
| OpenDNS | `208.67.222.222` | `208.67.220.220` |
| Quad9 | `9.9.9.9` | `149.112.112.112` |
 
---
 
## Key Takeaways
 
- DNS converts **names to IPs** (and vice versa).
- It works as a **distributed, hierarchical system**.
- Different **record types** serve different purposes (A, MX, CNAME, etc.).
- **Caching** at multiple levels speeds up lookups.
- Tools like `dig` and `nslookup` help troubleshoot DNS issues.
---