# Linux Network Troubleshooting Commands
 
A practical reference guide for diagnosing and fixing network issues on Linux systems.
 
---
 
## 1. `ping` — Test Connectivity
 
Checks if a remote host is reachable using ICMP echo requests.
 
```bash
# Basic ping
ping google.com
 
# Send only 4 packets
ping -c 4 google.com
 
# Set interval between packets (2 seconds)
ping -i 2 google.com
 
# Ping with specific packet size
ping -s 1000 google.com
 
# Flood ping (root only) - stress test
sudo ping -f google.com
```
 
**Sample Output:**
```
PING google.com (142.250.182.14) 56(84) bytes of data.
64 bytes from 142.250.182.14: icmp_seq=1 ttl=117 time=14.2 ms
64 bytes from 142.250.182.14: icmp_seq=2 ttl=117 time=13.8 ms
 
--- google.com ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
```
 
**Use Case:** First step to check if a host is alive and measure latency.
 
---
 
## 2. `traceroute` / `tracepath` — Trace Network Path
 
Shows the route packets take to reach a destination.
 
```bash
# Trace route to a host
traceroute google.com
 
# Use ICMP instead of UDP
traceroute -I google.com
 
# Use TCP (good when ICMP is blocked)
traceroute -T -p 80 google.com
 
# tracepath (no root needed)
tracepath google.com
```
 
**Sample Output:**
```
traceroute to google.com (142.250.182.14), 30 hops max
 1  192.168.1.1     0.482 ms
 2  10.20.30.1      8.234 ms
 3  isp-gateway     12.456 ms
 4  72.14.215.85    14.892 ms
 5  142.250.182.14  15.234 ms
```
 
**Use Case:** Find where packets are getting lost or slowed down.
 
---
 
## 3. `mtr` — Real-time Traceroute + Ping
 
Combines `ping` and `traceroute` for continuous monitoring.
 
```bash
# Interactive mode
mtr google.com
 
# Report mode (10 cycles)
mtr -r -c 10 google.com
 
# Show IPs only (no DNS resolution)
mtr -n google.com
```
 
**Sample Output:**
```
HOST: myhost              Loss%   Snt   Last   Avg  Best  Wrst
  1.|-- 192.168.1.1        0.0%    10    0.5    0.6   0.4   0.9
  2.|-- 10.20.30.1         0.0%    10    8.2    8.5   7.9   9.1
  3.|-- isp-gateway       10.0%    10   12.4   13.1  11.8  15.2
  4.|-- 142.250.182.14     0.0%    10   14.8   15.1  14.2  16.0
```
 
**Use Case:** Best tool for identifying intermittent packet loss along a route.
 
---
 
## 4. `ip` — Modern Network Configuration
 
Replacement for the older `ifconfig`. Manages addresses, routes, and links.
 
```bash
# Show all interfaces
ip addr show
ip a                       # short form
 
# Show specific interface
ip addr show eth0
 
# Bring interface up/down
sudo ip link set eth0 up
sudo ip link set eth0 down
 
# Add IP address
sudo ip addr add 192.168.1.100/24 dev eth0
 
# Remove IP address
sudo ip addr del 192.168.1.100/24 dev eth0
 
# Show routing table
ip route show
ip r                       # short form
 
# Add default gateway
sudo ip route add default via 192.168.1.1
 
# Show network statistics
ip -s link
```
 
**Sample Output:**
```
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
    link/ether 00:1a:2b:3c:4d:5e brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.105/24 brd 192.168.1.255 scope global eth0
    inet6 fe80::21a:2bff:fe3c:4d5e/64 scope link
```
 
**Use Case:** Primary tool for viewing and configuring network interfaces.
 
---
 
## 5. `ifconfig` — Legacy Interface Tool
 
Older command (may need `net-tools` package). Still widely used.
 
```bash
# Show all interfaces
ifconfig
 
# Show specific interface
ifconfig eth0
 
# Bring interface up/down
sudo ifconfig eth0 up
sudo ifconfig eth0 down
 
# Assign IP address
sudo ifconfig eth0 192.168.1.100 netmask 255.255.255.0
```
 
**Use Case:** Quick view of network interfaces (on older systems).
 
---
 
## 6. `netstat` — Network Statistics (Legacy)
 
Shows connections, listening ports, routing tables.
 
```bash
# Show all listening TCP/UDP ports
netstat -tulnp
 
# Show all connections
netstat -an
 
# Show routing table
netstat -rn
 
# Show network statistics
netstat -s
 
# Show interface statistics
netstat -i
```
 
**Flags:**
- `-t` TCP, `-u` UDP, `-l` listening, `-n` numeric, `-p` process
**Sample Output:**
```
Proto  Local Address      Foreign Address    State       PID/Program
tcp    0.0.0.0:22         0.0.0.0:*          LISTEN      1234/sshd
tcp    0.0.0.0:80         0.0.0.0:*          LISTEN      2345/nginx
tcp    192.168.1.5:22     203.0.113.10:54321 ESTABLISHED 6789/sshd
```
 
**Use Case:** See which ports are open and what's connected.
 
---
 
## 7. `ss` — Modern Socket Statistics
 
Faster replacement for `netstat`.
 
```bash
# Show all listening TCP ports
ss -tlnp
 
# Show all listening UDP ports
ss -ulnp
 
# Show all sockets
ss -a
 
# Show established connections only
ss -t state established
 
# Show summary statistics
ss -s
 
# Filter by port
ss -tlnp sport = :80
```
 
**Sample Output:**
```
State    Recv-Q  Send-Q  Local Address:Port  Peer Address:Port  Process
LISTEN   0       128     0.0.0.0:22          0.0.0.0:*          users:(("sshd",pid=1234))
LISTEN   0       511     0.0.0.0:80          0.0.0.0:*          users:(("nginx",pid=2345))
ESTAB    0       0       192.168.1.5:22      203.0.113.10:54321 users:(("sshd",pid=6789))
```
 
**Use Case:** Modern, fast way to inspect sockets and connections.
 
---
 
## 8. `nslookup` — DNS Lookup
 
Query DNS records.
 
```bash
# Basic lookup
nslookup google.com
 
# Query specific record type
nslookup -type=MX google.com
nslookup -type=NS google.com
nslookup -type=TXT google.com
 
# Use specific DNS server
nslookup google.com 8.8.8.8
 
# Reverse lookup
nslookup 8.8.8.8
```
 
**Sample Output:**
```
Server:    192.168.1.1
Address:   192.168.1.1#53
 
Non-authoritative answer:
Name:    google.com
Address: 142.250.182.14
```
 
**Use Case:** Quick DNS lookups and testing DNS servers.
 
---
 
## 9. `dig` — Advanced DNS Tool
 
More powerful and detailed than `nslookup`.
 
```bash
# Basic query
dig google.com
 
# Short answer only
dig +short google.com
 
# Query specific record
dig google.com MX
dig google.com AAAA
dig google.com TXT
 
# Use specific DNS server
dig @8.8.8.8 google.com
 
# Trace full resolution path
dig +trace google.com
 
# Reverse DNS lookup
dig -x 8.8.8.8
 
# Query all records
dig google.com ANY
```
 
**Sample Output:**
```
;; ANSWER SECTION:
google.com.    300    IN    A    142.250.182.14
 
;; Query time: 24 msec
;; SERVER: 8.8.8.8#53(8.8.8.8)
```
 
**Use Case:** Best tool for detailed DNS troubleshooting.
 
---
 
## 10. `host` — Simple DNS Lookup
 
Quick and clean DNS query tool.
 
```bash
# Basic lookup
host google.com
 
# Query specific record
host -t MX google.com
host -t NS google.com
 
# Verbose output
host -v google.com
 
# Reverse lookup
host 8.8.8.8
```
 
**Sample Output:**
```
google.com has address 142.250.182.14
google.com has IPv6 address 2607:f8b0:4004:c08::65
google.com mail is handled by 10 smtp.google.com.
```
 
**Use Case:** Fast, simple DNS queries.
 
---
 
## 11. `curl` — Test HTTP/HTTPS Connections
 
Transfer data and test web services.
 
```bash
# Get response headers only
curl -I https://example.com
 
# Verbose mode (full request/response)
curl -v https://example.com
 
# Check HTTP status code only
curl -o /dev/null -s -w "%{http_code}\n" https://example.com
 
# Measure timing
curl -w "Connect: %{time_connect}s\nTotal: %{time_total}s\n" -o /dev/null -s https://example.com
 
# Test with specific DNS
curl --resolve example.com:443:1.2.3.4 https://example.com
 
# Follow redirects
curl -L https://example.com
```
 
**Sample Output:**
```
HTTP/2 200
content-type: text/html; charset=UTF-8
date: Sat, 09 May 2026 10:00:00 GMT
server: nginx/1.24.0
```
 
**Use Case:** Test web services, APIs, and HTTPS connectivity.
 
---
 
## 12. `wget` — Download / Test URLs
 
Non-interactive file downloader.
 
```bash
# Download a file
wget https://example.com/file.zip
 
# Test if URL is reachable (spider mode)
wget --spider https://example.com
 
# Limit download speed
wget --limit-rate=100k https://example.com/file.zip
 
# Download with retries
wget --tries=5 --timeout=30 https://example.com/file.zip
```
 
**Use Case:** Test URLs and download files from scripts.
 
---
 
## 13. `nc` (netcat) — Network Swiss Army Knife
 
Read/write across network connections.
 
```bash
# Test if TCP port is open
nc -zv example.com 80
 
# Test multiple ports
nc -zv example.com 20-30
 
# Test UDP port
nc -zvu example.com 53
 
# Listen on a port (server mode)
nc -l 8080
 
# Connect and send data
echo "GET / HTTP/1.0\r\n\r\n" | nc example.com 80
 
# Transfer a file
# On receiver:    nc -l 9000 > received.txt
# On sender:      nc receiver_ip 9000 < file.txt
```
 
**Sample Output:**
```
Connection to example.com 80 port [tcp/http] succeeded!
```
 
**Use Case:** Test port connectivity, debug services, transfer data.
 
---
 
## 14. `telnet` — Test TCP Connections
 
Older but still useful for testing TCP ports.
 
```bash
# Test if port is open
telnet example.com 80
 
# Test SMTP server
telnet mail.example.com 25
```
 
**Sample Output:**
```
Trying 93.184.216.34...
Connected to example.com.
Escape character is '^]'.
```
 
**Use Case:** Test if a TCP service is responding.
 
---
 
## 15. `nmap` — Network Scanner
 
Scan hosts and ports.
 
```bash
# Quick scan
nmap example.com
 
# Scan specific ports
nmap -p 22,80,443 example.com
 
# Scan port range
nmap -p 1-1000 example.com
 
# Scan all ports
nmap -p- example.com
 
# OS detection (needs root)
sudo nmap -O example.com
 
# Service version detection
nmap -sV example.com
 
# Scan a subnet
nmap 192.168.1.0/24
 
# Fast scan (top 100 ports)
nmap -F example.com
```
 
**Sample Output:**
```
PORT     STATE  SERVICE  VERSION
22/tcp   open   ssh      OpenSSH 8.9
80/tcp   open   http     nginx 1.24.0
443/tcp  open   ssl/http nginx 1.24.0
```
 
**Use Case:** Port scanning, service discovery, security audits.
 
---
 
## 16. `tcpdump` — Packet Capture
 
Capture and analyze network packets.
 
```bash
# Capture on default interface
sudo tcpdump
 
# Capture on specific interface
sudo tcpdump -i eth0
 
# Capture specific port
sudo tcpdump -i eth0 port 80
 
# Capture specific host
sudo tcpdump host 192.168.1.100
 
# Capture and save to file
sudo tcpdump -i eth0 -w capture.pcap
 
# Read from file
tcpdump -r capture.pcap
 
# Show packet contents (ASCII)
sudo tcpdump -A -i eth0 port 80
 
# Limit packet count
sudo tcpdump -c 100 -i eth0
```
 
**Sample Output:**
```
10:00:01.234567 IP 192.168.1.5.54321 > 142.250.182.14.443: Flags [S], seq 12345
10:00:01.245678 IP 142.250.182.14.443 > 192.168.1.5.54321: Flags [S.], seq 67890
```
 
**Use Case:** Deep packet inspection and protocol analysis.
 
---
 
## 17. `iftop` — Real-time Bandwidth Monitor
 
Shows bandwidth usage per connection.
 
```bash
# Monitor default interface
sudo iftop
 
# Specific interface
sudo iftop -i eth0
 
# Show port numbers
sudo iftop -P
 
# Don't resolve hostnames
sudo iftop -n
```
 
**Use Case:** Identify which connections are using bandwidth.
 
---
 
## 18. `nload` — Network Traffic Monitor
 
Shows incoming/outgoing traffic per interface.
 
```bash
# Monitor all interfaces
nload
 
# Specific interface
nload eth0
 
# Multiple interfaces
nload eth0 wlan0
```
 
**Use Case:** Visualize current network throughput.
 
---
 
## 19. `iperf3` — Bandwidth Testing
 
Measure network throughput between two hosts.
 
```bash
# On server
iperf3 -s
 
# On client
iperf3 -c server_ip
 
# Test for 30 seconds
iperf3 -c server_ip -t 30
 
# UDP test
iperf3 -c server_ip -u
 
# Reverse direction (server → client)
iperf3 -c server_ip -R
 
# Parallel streams
iperf3 -c server_ip -P 4
```
 
**Sample Output:**
```
[ ID] Interval    Transfer    Bitrate
[  5] 0.0-10.0s   1.10 GBytes 944 Mbits/sec
```
 
**Use Case:** Test maximum bandwidth between two endpoints.
 
---
 
## 20. `route` / `ip route` — View Routing Table
 
Show how packets get routed.
 
```bash
# Show routing table (legacy)
route -n
 
# Show routing table (modern)
ip route show
 
# Add static route
sudo ip route add 10.0.0.0/24 via 192.168.1.1
 
# Delete route
sudo ip route del 10.0.0.0/24
 
# Show route for specific destination
ip route get 8.8.8.8
```
 
**Sample Output:**
```
default via 192.168.1.1 dev eth0
192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.5
```
 
**Use Case:** Check and modify routing decisions.
 
---
 
## 21. `arp` / `ip neigh` — ARP Table
 
Show MAC address mappings.
 
```bash
# Show ARP table (legacy)
arp -a
 
# Modern equivalent
ip neigh show
 
# Delete ARP entry
sudo ip neigh del 192.168.1.100 dev eth0
 
# Add static ARP entry
sudo arp -s 192.168.1.100 00:11:22:33:44:55
```
 
**Sample Output:**
```
192.168.1.1  dev eth0 lladdr aa:bb:cc:dd:ee:ff REACHABLE
192.168.1.5  dev eth0 lladdr 11:22:33:44:55:66 STALE
```
 
**Use Case:** Debug Layer 2 (MAC address) issues.
 
---
 
## 22. `ethtool` — Ethernet Device Settings
 
View and modify NIC settings.
 
```bash
# Show interface info
sudo ethtool eth0
 
# Show driver info
sudo ethtool -i eth0
 
# Show statistics
sudo ethtool -S eth0
 
# Test cable
sudo ethtool -t eth0
 
# Set speed/duplex
sudo ethtool -s eth0 speed 1000 duplex full
```
 
**Use Case:** Check link speed, duplex, and hardware-level issues.
 
---
 
## 23. `whois` — Domain Information
 
Lookup domain registration details.
 
```bash
# Domain lookup
whois example.com
 
# IP lookup
whois 8.8.8.8
```
 
**Use Case:** Find domain owner, registration date, name servers.
 
---
 
## 24. `hostname` — System Hostname
 
```bash
# Show hostname
hostname
 
# Show FQDN
hostname -f
 
# Show all IPs
hostname -I
 
# Change hostname (temporary)
sudo hostname new-name
```
 
---
 
## 25. `/etc/resolv.conf` — DNS Resolver Config
 
```bash
# View current DNS servers
cat /etc/resolv.conf
 
# Example contents:
nameserver 8.8.8.8
nameserver 1.1.1.1
search example.com
```
 
---
 
## Common Troubleshooting Workflow
 
Follow this systematic approach when network issues arise:
 
| Step | Check | Command |
|------|-------|---------|
| 1 | Is interface up? | `ip a` |
| 2 | Have an IP? | `ip addr show` |
| 3 | Have a gateway? | `ip route show` |
| 4 | Can reach gateway? | `ping <gateway>` |
| 5 | Can reach internet? | `ping 8.8.8.8` |
| 6 | DNS working? | `ping google.com` or `dig google.com` |
| 7 | Specific port open? | `nc -zv host port` |
| 8 | Trace the path | `mtr host` |
| 9 | Check listening services | `ss -tlnp` |
| 10 | Capture packets | `tcpdump -i eth0` |
 
---
 
## Quick Reference Table
 
| Command | Purpose |
|---------|---------|
| `ping` | Test connectivity |
| `traceroute` | Trace network path |
| `mtr` | Continuous traceroute |
| `ip` | Manage interfaces/routes |
| `ifconfig` | Legacy interface tool |
| `ss` | Socket statistics (modern) |
| `netstat` | Socket statistics (legacy) |
| `nslookup` | DNS query |
| `dig` | Advanced DNS query |
| `host` | Simple DNS query |
| `curl` | HTTP test/download |
| `wget` | Download files |
| `nc` | Port testing/data transfer |
| `telnet` | TCP port testing |
| `nmap` | Port scanner |
| `tcpdump` | Packet capture |
| `iftop` | Bandwidth per connection |
| `nload` | Bandwidth per interface |
| `iperf3` | Throughput testing |
| `route` | Routing table |
| `arp` | ARP/MAC table |
| `ethtool` | NIC hardware info |
| `whois` | Domain info |
 
---