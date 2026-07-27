# DevOps Linux — Common Network Issues & Troubleshooting Guide
 
A practical, scenario-based guide for DevOps engineers to diagnose and resolve real-world network issues in Linux-based production environments.
 
---
 
## Table of Contents
 
1. [Cannot Connect to Remote Server (SSH)](#1-cannot-connect-to-remote-server-ssh)
2. [DNS Resolution Failure](#2-dns-resolution-failure)
3. [Website / Application Not Loading](#3-website--application-not-loading)
4. [Slow Network / High Latency](#4-slow-network--high-latency)
5. [Port Not Accessible / Service Not Reachable](#5-port-not-accessible--service-not-reachable)
6. [No Internet Connectivity on Server](#6-no-internet-connectivity-on-server)
7. [Firewall Blocking Traffic](#7-firewall-blocking-traffic)
8. [Docker Container Networking Issues](#8-docker-container-networking-issues)
9. [Kubernetes Pod Cannot Reach Service](#9-kubernetes-pod-cannot-reach-service)
10. [High Bandwidth Usage / Network Saturation](#10-high-bandwidth-usage--network-saturation)
11. [Packet Loss Between Servers](#11-packet-loss-between-servers)
12. [SSL/TLS Certificate Errors](#12-ssltls-certificate-errors)
13. [Load Balancer Not Distributing Traffic](#13-load-balancer-not-distributing-traffic)
14. [Reverse Proxy (Nginx) 502/504 Errors](#14-reverse-proxy-nginx-502504-errors)
15. [VPN Connection Issues](#15-vpn-connection-issues)
16. [MTU / Fragmentation Issues](#16-mtu--fragmentation-issues)
17. [Connection Timeouts in Applications](#17-connection-timeouts-in-applications)
18. [Too Many Open Connections (TIME_WAIT)](#18-too-many-open-connections-time_wait)
19. [Cloud Instance Cannot Reach Another VPC](#19-cloud-instance-cannot-reach-another-vpc)
20. [ARP Issues / Duplicate IP](#20-arp-issues--duplicate-ip)
---
 
## 1. Cannot Connect to Remote Server (SSH)
 
### Symptoms
- `ssh user@server` hangs or returns "Connection refused" / "Connection timed out".
- Cannot log into a production server.
### Common Causes
- SSH service is down on the target server.
- Firewall blocking port 22.
- Wrong IP address or hostname.
- Server is offline or network unreachable.
- Public key authentication misconfigured.
### Troubleshooting Steps
 
```bash
# 1. Check if the host is reachable
ping -c 4 server_ip
 
# 2. Test if SSH port is open
nc -zv server_ip 22
telnet server_ip 22
 
# 3. Trace the network path
mtr server_ip
 
# 4. Verbose SSH for detailed errors
ssh -vvv user@server_ip
 
# 5. On the server (via console): check SSH service
sudo systemctl status sshd
sudo systemctl restart sshd
 
# 6. Check listening port
sudo ss -tlnp | grep :22
 
# 7. Check firewall rules
sudo iptables -L -n | grep 22
sudo ufw status
```
 
### Resolution
- Restart `sshd` if service is down.
- Open port 22 in firewall: `sudo ufw allow 22/tcp`.
- Verify cloud security group / network ACLs allow SSH from your IP.
- Check `/etc/ssh/sshd_config` for `PermitRootLogin`, `AllowUsers`, etc.
---
 
## 2. DNS Resolution Failure
 
### Symptoms
- `ping google.com` fails but `ping 8.8.8.8` works.
- Applications fail with "Name or service not known".
- Slow application startup.
### Common Causes
- `/etc/resolv.conf` misconfigured or empty.
- DNS server unreachable.
- `systemd-resolved` issues.
- Corporate/internal DNS down.
### Troubleshooting Steps
 
```bash
# 1. Check current DNS config
cat /etc/resolv.conf
 
# 2. Test DNS resolution
dig google.com
nslookup google.com
 
# 3. Try with a public DNS server
dig @8.8.8.8 google.com
 
# 4. Check systemd-resolved status
systemctl status systemd-resolved
resolvectl status
 
# 5. Flush DNS cache
sudo systemd-resolve --flush-caches
# or
sudo resolvectl flush-caches
```
 
### Resolution
 
```bash
# Set DNS servers temporarily
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
 
# For systemd-resolved (permanent)
sudo nano /etc/systemd/resolved.conf
# Set: DNS=8.8.8.8 1.1.1.1
sudo systemctl restart systemd-resolved
```
 
---
 
## 3. Website / Application Not Loading
 
### Symptoms
- Browser shows "This site can't be reached".
- `curl` returns timeout or error.
- App was working before.
### Troubleshooting Steps
 
```bash
# 1. Test basic connectivity
ping example.com
 
# 2. Check DNS
dig example.com
 
# 3. Test HTTP/HTTPS
curl -I https://example.com
curl -v https://example.com
 
# 4. Check if service is listening on the server
sudo ss -tlnp | grep -E ':80|:443'
 
# 5. Check application logs
sudo journalctl -u nginx -n 50
sudo tail -f /var/log/nginx/error.log
 
# 6. Verify backend is running
sudo systemctl status nginx
sudo systemctl status myapp
 
# 7. Test from inside the server
curl http://localhost
curl http://127.0.0.1:8080
```
 
### Resolution
- Restart web server: `sudo systemctl restart nginx`.
- Check backend app for crashes.
- Verify DNS records (A, CNAME) point to correct IP.
- Inspect security group / firewall rules.
---
 
## 4. Slow Network / High Latency
 
### Symptoms
- Applications respond slowly.
- `ping` shows high RTT or packet loss.
- File transfers are slow.
### Troubleshooting Steps
 
```bash
# 1. Measure latency
ping -c 20 destination_host
 
# 2. Find where slowness occurs
mtr destination_host
 
# 3. Measure bandwidth (between two hosts)
# Server: iperf3 -s
# Client: iperf3 -c server_ip
 
# 4. Check interface errors/drops
ip -s link show eth0
ethtool -S eth0 | grep -E 'error|drop'
 
# 5. Check current bandwidth usage
sudo iftop -i eth0
nload eth0
 
# 6. Check link speed / duplex
sudo ethtool eth0
```
 
### Resolution
- Fix duplex mismatch: `sudo ethtool -s eth0 speed 1000 duplex full autoneg off`.
- Replace bad cable / NIC if errors are climbing.
- Investigate ISP / cloud provider for upstream issues.
- Identify and throttle bandwidth-heavy processes.
---
 
## 5. Port Not Accessible / Service Not Reachable
 
### Symptoms
- "Connection refused" on a specific port.
- App listens but external clients can't connect.
### Troubleshooting Steps
 
```bash
# 1. Confirm service is listening
sudo ss -tlnp | grep :8080
sudo netstat -tlnp | grep :8080
 
# 2. Test from localhost
curl http://localhost:8080
nc -zv localhost 8080
 
# 3. Test from another machine
nc -zv server_ip 8080
 
# 4. Check firewall
sudo iptables -L -n -v
sudo ufw status verbose
sudo firewall-cmd --list-all
 
# 5. Check if app is bound to correct interface
# Bound to 127.0.0.1 (localhost only) vs 0.0.0.0 (all interfaces)
sudo ss -tlnp | grep :8080
```
 
### Resolution
- Bind service to `0.0.0.0` instead of `127.0.0.1` in app config.
- Open port in firewall:
  ```bash
  sudo ufw allow 8080/tcp
  sudo firewall-cmd --add-port=8080/tcp --permanent && sudo firewall-cmd --reload
  ```
- Update cloud security groups.
---
 
## 6. No Internet Connectivity on Server
 
### Symptoms
- Cannot reach external sites.
- `apt update` / `yum update` fails.
- Cannot pull Docker images.
### Troubleshooting Steps
 
```bash
# 1. Check interfaces
ip a
 
# 2. Check default gateway
ip route show
ip route get 8.8.8.8
 
# 3. Test gateway
ping <gateway_ip>
 
# 4. Test public IP
ping 8.8.8.8
 
# 5. Test DNS
ping google.com
 
# 6. Check NetworkManager (if used)
nmcli device status
nmcli connection show
```
 
### Resolution
 
```bash
# Add default gateway
sudo ip route add default via 192.168.1.1
 
# Restart networking
sudo systemctl restart NetworkManager
sudo systemctl restart networking
sudo netplan apply         # Ubuntu
 
# Verify NAT / proxy settings if in corporate network
echo $http_proxy
echo $https_proxy
```
 
---
 
## 7. Firewall Blocking Traffic
 
### Symptoms
- Service was working, suddenly not reachable.
- Specific IP ranges blocked.
### Troubleshooting Steps
 
```bash
# 1. Check iptables rules
sudo iptables -L -n -v --line-numbers
sudo iptables -S
 
# 2. Check nftables
sudo nft list ruleset
 
# 3. Check UFW
sudo ufw status numbered
 
# 4. Check firewalld (RHEL/CentOS)
sudo firewall-cmd --list-all
sudo firewall-cmd --list-services
sudo firewall-cmd --list-ports
 
# 5. Trace packet flow (with verbose iptables)
sudo iptables -L -v -n
```
 
### Resolution
 
```bash
# UFW
sudo ufw allow from 192.168.1.0/24 to any port 3306
 
# firewalld
sudo firewall-cmd --add-port=3306/tcp --permanent
sudo firewall-cmd --add-source=192.168.1.0/24 --zone=trusted --permanent
sudo firewall-cmd --reload
 
# iptables
sudo iptables -I INPUT -p tcp --dport 3306 -s 192.168.1.0/24 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```
 
---
 
## 8. Docker Container Networking Issues
 
### Symptoms
- Container cannot reach internet.
- Cannot reach service from host.
- Containers can't talk to each other.
### Troubleshooting Steps
 
```bash
# 1. List Docker networks
docker network ls
 
# 2. Inspect a network
docker network inspect bridge
 
# 3. Check container's network settings
docker inspect container_name | grep -A 20 NetworkSettings
 
# 4. Run a debug container
docker run --rm -it --network=host nicolaka/netshoot
 
# 5. Inside container, test connectivity
docker exec -it container_name sh
ping 8.8.8.8
nslookup google.com
curl http://other-container:8080
 
# 6. Check if container port is exposed
docker port container_name
 
# 7. Check iptables for Docker rules
sudo iptables -t nat -L -n
```
 
### Resolution
 
```bash
# Restart Docker daemon
sudo systemctl restart docker
 
# Enable IP forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
 
# Use custom bridge network for inter-container DNS
docker network create mynet
docker run --network mynet --name app1 myapp
docker run --network mynet --name app2 myapp
# Now: app1 can reach app2 by name
```
 
---
 
## 9. Kubernetes Pod Cannot Reach Service
 
### Symptoms
- Pod fails to connect to other pods/services.
- DNS resolution fails inside pod.
- `kubectl exec` shows connectivity issues.
### Troubleshooting Steps
 
```bash
# 1. Get pod status
kubectl get pods -A
kubectl describe pod <pod-name>
 
# 2. Check pod logs
kubectl logs <pod-name>
 
# 3. Exec into pod
kubectl exec -it <pod-name> -- /bin/sh
 
# Inside the pod:
nslookup kubernetes.default
nslookup my-service
curl http://my-service:8080
cat /etc/resolv.conf
 
# 4. Check services and endpoints
kubectl get svc
kubectl get endpoints
kubectl describe svc my-service
 
# 5. Check CoreDNS
kubectl get pods -n kube-system | grep coredns
kubectl logs -n kube-system <coredns-pod>
 
# 6. Check network policies
kubectl get networkpolicies -A
 
# 7. Check CNI plugin
kubectl get pods -n kube-system | grep -E 'calico|flannel|weave|cilium'
```
 
### Resolution
- Restart CoreDNS: `kubectl rollout restart deployment/coredns -n kube-system`.
- Verify service selector matches pod labels.
- Confirm NetworkPolicy allows required traffic.
- Ensure CNI pods are running on all nodes.
---
 
## 10. High Bandwidth Usage / Network Saturation
 
### Symptoms
- Server is slow.
- Bandwidth bills spike.
- Other services suffer.
### Troubleshooting Steps
 
```bash
# 1. Check current traffic
sudo iftop -i eth0
nload eth0
 
# 2. See which processes use bandwidth
sudo nethogs eth0
 
# 3. Check connection count per IP
sudo ss -tn | awk 'NR>1 {print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head
 
# 4. Capture top talkers
sudo tcpdump -i eth0 -nn -c 1000 | awk '{print $3}' | sort | uniq -c | sort -nr | head
 
# 5. Check interface counters over time
ip -s link show eth0
```
 
### Resolution
- Identify rogue process / runaway script and kill it.
- Implement rate limiting (`tc`, Nginx `limit_req`, app-level throttling).
- Block abusive IPs:
  ```bash
  sudo iptables -A INPUT -s 203.0.113.45 -j DROP
  ```
- Investigate DDoS — engage cloud provider's protection (AWS Shield, Cloudflare).
---
 
## 11. Packet Loss Between Servers
 
### Symptoms
- Intermittent connection failures.
- Slow file transfers, retransmissions.
- Database replication lag.
### Troubleshooting Steps
 
```bash
# 1. Verify packet loss
ping -c 100 destination | tail
 
# 2. Continuous traceroute showing loss per hop
mtr -r -c 100 destination
 
# 3. Check interface drops/errors
ip -s link show eth0
ethtool -S eth0 | grep -iE 'drop|error|discard'
 
# 4. Check ring buffer
ethtool -g eth0
 
# 5. Check kernel network stats
netstat -s | grep -iE 'retransmit|loss|drop'
```
 
### Resolution
 
```bash
# Increase ring buffer if drops occur
sudo ethtool -G eth0 rx 4096 tx 4096
 
# Tune TCP buffer sizes
sudo sysctl -w net.core.rmem_max=16777216
sudo sysctl -w net.core.wmem_max=16777216
sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216"
sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216"
```
 
- Contact ISP / cloud provider if loss occurs upstream.
- Replace physical hardware (cable, NIC, switch port).
---
 
## 12. SSL/TLS Certificate Errors
 
### Symptoms
- `curl` returns "SSL certificate problem".
- Browser shows "Your connection is not private".
- Cert expired.
### Troubleshooting Steps
 
```bash
# 1. Check certificate details
openssl s_client -connect example.com:443 -servername example.com < /dev/null
 
# 2. Check certificate expiry
echo | openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -noout -dates
 
# 3. Verify cert chain
openssl s_client -connect example.com:443 -showcerts
 
# 4. Check Nginx/Apache cert config
sudo nginx -t
sudo apachectl configtest
 
# 5. Use curl to debug
curl -vI https://example.com
```
 
### Resolution
 
```bash
# Renew Let's Encrypt cert
sudo certbot renew
sudo certbot renew --dry-run
 
# Restart web server
sudo systemctl reload nginx
 
# Verify intermediate cert is included in chain
cat domain.crt intermediate.crt > fullchain.crt
```
 
---
 
## 13. Load Balancer Not Distributing Traffic
 
### Symptoms
- One backend gets all traffic.
- Backend marked unhealthy.
- Uneven CPU/memory across nodes.
### Troubleshooting Steps
 
```bash
# 1. Check LB health check endpoint from LB to each backend
curl http://backend1:8080/health
curl http://backend2:8080/health
 
# 2. Check backend logs for health checks
sudo tail -f /var/log/nginx/access.log | grep health
 
# 3. Verify backend listening on right port
sudo ss -tlnp | grep 8080
 
# 4. Check HAProxy/Nginx status
sudo systemctl status haproxy
echo "show stat" | sudo socat stdio /var/run/haproxy.sock
 
# 5. Nginx upstream status
curl http://localhost/nginx_status
```
 
### Resolution
- Fix health check path / port / expected status code.
- Ensure backend returns 200 on health endpoint.
- Verify session stickiness if not needed (can cause uneven distribution).
- Check LB algorithm (round-robin vs least-conn).
---
 
## 14. Reverse Proxy (Nginx) 502/504 Errors
 
### Symptoms
- Nginx returns 502 Bad Gateway or 504 Gateway Timeout.
### Troubleshooting Steps
 
```bash
# 1. Check Nginx error log
sudo tail -f /var/log/nginx/error.log
 
# 2. Verify upstream is reachable
curl http://backend_ip:8080
 
# 3. Test from Nginx server
sudo -u www-data curl http://backend_ip:8080
 
# 4. Check SELinux (RHEL/CentOS)
sudo getenforce
sudo setsebool -P httpd_can_network_connect 1
 
# 5. Check upstream timeout
grep -E 'proxy_(connect|read|send)_timeout' /etc/nginx/nginx.conf
```
 
### Resolution
 
```nginx
# Increase timeouts in nginx.conf
location / {
    proxy_pass http://backend;
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
}
```
 
- Scale up backend if it's overloaded.
- Fix SELinux booleans on RHEL/CentOS.
---
 
## 15. VPN Connection Issues
 
### Symptoms
- Cannot connect to VPN.
- Connected but no traffic flows.
- DNS not working over VPN.
### Troubleshooting Steps
 
```bash
# 1. Check VPN service
sudo systemctl status openvpn@client
sudo systemctl status wg-quick@wg0
 
# 2. Check tunnel interface
ip a show tun0
ip a show wg0
 
# 3. Check routing through VPN
ip route show
 
# 4. Check VPN logs
sudo journalctl -u openvpn@client -f
 
# 5. Test DNS over VPN
dig @<vpn_dns_ip> internal.company.com
```
 
### Resolution
- Verify VPN config: keys, certs, server address.
- Add route for VPN traffic: `sudo ip route add 10.10.0.0/16 dev tun0`.
- Push correct DNS from VPN server.
- Check MTU — sometimes VPNs need MTU lowered to 1400.
---
 
## 16. MTU / Fragmentation Issues
 
### Symptoms
- Small packets work (ping, SSH login).
- Large transfers hang (HTTP, SCP).
- Common over VPN, cloud, GRE tunnels.
### Troubleshooting Steps
 
```bash
# 1. Find max working MTU
ping -M do -s 1472 destination          # 1472 + 28 = 1500
ping -M do -s 1400 destination
ping -M do -s 1372 destination          # 1372 + 28 = 1400
 
# 2. Check current MTU
ip link show eth0 | grep mtu
 
# 3. Check path MTU discovery
tracepath destination
```
 
### Resolution
 
```bash
# Set MTU lower
sudo ip link set dev eth0 mtu 1400
 
# Persistent (Ubuntu netplan)
# Edit /etc/netplan/01-netcfg.yaml
#   ethernets:
#     eth0:
#       mtu: 1400
sudo netplan apply
 
# TCP MSS clamping (for routers/firewalls)
sudo iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN \
  -j TCPMSS --clamp-mss-to-pmtu
```
 
---
 
## 17. Connection Timeouts in Applications
 
### Symptoms
- Apps log "connection timeout" or "read timeout".
- Database connections drop.
- Microservices fail under load.
### Troubleshooting Steps
 
```bash
# 1. Check current TCP connections
ss -tan state established
 
# 2. Check timeout settings
sysctl net.ipv4.tcp_keepalive_time
sysctl net.ipv4.tcp_keepalive_intvl
sysctl net.ipv4.tcp_keepalive_probes
 
# 3. Check connection tracking limits
sudo sysctl net.netfilter.nf_conntrack_max
sudo sysctl net.netfilter.nf_conntrack_count
cat /proc/sys/net/netfilter/nf_conntrack_count
 
# 4. Check application timeouts in code/config
```
 
### Resolution
 
```bash
# Tune TCP keepalive
sudo sysctl -w net.ipv4.tcp_keepalive_time=600
sudo sysctl -w net.ipv4.tcp_keepalive_intvl=60
sudo sysctl -w net.ipv4.tcp_keepalive_probes=3
 
# Increase conntrack table
sudo sysctl -w net.netfilter.nf_conntrack_max=524288
 
# Make permanent
echo "net.ipv4.tcp_keepalive_time=600" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```
 
---
 
## 18. Too Many Open Connections (TIME_WAIT)
 
### Symptoms
- "Cannot assign requested address" errors.
- App cannot create new outbound connections.
- `netstat` shows thousands of TIME_WAIT.
### Troubleshooting Steps
 
```bash
# 1. Count connections by state
ss -tan | awk 'NR>1 {print $1}' | sort | uniq -c
 
# 2. Show TIME_WAIT count
ss -tan state time-wait | wc -l
 
# 3. Check ephemeral port range
sysctl net.ipv4.ip_local_port_range
```
 
### Resolution
 
```bash
# Reuse TIME_WAIT sockets
sudo sysctl -w net.ipv4.tcp_tw_reuse=1
 
# Widen ephemeral port range
sudo sysctl -w net.ipv4.ip_local_port_range="1024 65535"
 
# Reduce FIN_WAIT timeout
sudo sysctl -w net.ipv4.tcp_fin_timeout=15
 
# Make persistent
sudo tee -a /etc/sysctl.conf <<EOF
net.ipv4.tcp_tw_reuse=1
net.ipv4.ip_local_port_range=1024 65535
net.ipv4.tcp_fin_timeout=15
EOF
sudo sysctl -p
```
 
- Application fix: use connection pooling (HikariCP, pgbouncer, etc.).
---
 
## 19. Cloud Instance Cannot Reach Another VPC
 
### Symptoms
- EC2/VM in one VPC cannot ping/connect to another VPC.
- Cross-region/cross-account traffic fails.
### Troubleshooting Steps
 
```bash
# 1. Test connectivity
ping target_private_ip
nc -zv target_private_ip 22
 
# 2. Check routing on source
ip route show
 
# 3. Verify the source can resolve target
dig target.internal.company.com
 
# 4. Check for asymmetric routing (tcpdump on both sides)
sudo tcpdump -i eth0 host target_ip
```
 
### Resolution
- Confirm **VPC peering** / **Transit Gateway** is active.
- Ensure **route tables** on both sides point to the peering.
- Open required ports in **security groups** AND **network ACLs**.
- For overlapping CIDR ranges — peering won't work; use NAT or readdress.
---
 
## 20. ARP Issues / Duplicate IP
 
### Symptoms
- Intermittent connectivity.
- "Duplicate IP detected" in syslog.
- One host loses connection randomly.
### Troubleshooting Steps
 
```bash
# 1. Check ARP table
ip neigh show
arp -a
 
# 2. Look for duplicate MAC for same IP
arping -I eth0 192.168.1.100
 
# 3. Check kernel logs
sudo dmesg | grep -i 'duplicate\|arp'
sudo journalctl -k | grep -i arp
 
# 4. Capture ARP packets
sudo tcpdump -i eth0 arp
```
 
### Resolution
 
```bash
# Flush ARP table
sudo ip neigh flush all
 
# Force ARP re-announcement
sudo arping -U -I eth0 192.168.1.100 -c 3
 
# Find and reassign the duplicate IP
# (check both hosts and DHCP server)
```
 
---
 
## General Troubleshooting Methodology
 
When facing any network issue, follow this **layered (OSI bottom-up) approach**:
 
| Layer | What to Check | Commands |
|-------|---------------|----------|
| **L1 — Physical** | Cable, link light, NIC | `ethtool eth0` |
| **L2 — Data Link** | MAC, ARP, VLAN | `ip neigh`, `arp -a` |
| **L3 — Network** | IP, routing, ICMP | `ip a`, `ip route`, `ping`, `mtr` |
| **L4 — Transport** | Ports, TCP/UDP | `ss`, `netstat`, `nc`, `nmap` |
| **L5–L7 — App** | DNS, HTTP, TLS | `dig`, `curl`, `openssl s_client` |
 
---
 
## Top 10 Commands Every DevOps Engineer Should Know
 
| Command | Purpose |
|---------|---------|
| `ip a` | View interfaces / IPs |
| `ip route` | View routing |
| `ping` | Test reachability |
| `mtr` | Path + loss analysis |
| `ss -tlnp` | Listening sockets |
| `dig` | DNS queries |
| `curl -v` | HTTP debugging |
| `tcpdump` | Packet capture |
| `nc -zv` | Port test |
| `journalctl` | Read system/service logs |
 
---
 
## Pro Tips for DevOps Engineers
 
1. **Always check logs first** — `journalctl -u <service> -f` saves hours.
2. **Capture before changing** — `tcpdump -w issue.pcap` so you can analyze later.
3. **Document IP / port maps** of your infrastructure.
4. **Use monitoring** (Prometheus + Grafana, Datadog, Zabbix) to spot trends.
5. **Test in staging** — never tune `sysctl` directly in prod without testing.
6. **Automate health checks** — set alerts before users notice.
7. **Keep a runbook** — your future self will thank you at 3 AM.
8. **Know your cloud provider's networking quirks** (security groups, NACLs, peering, Transit Gateway).
9. **Use `netshoot` container** for in-cluster Kubernetes debugging:
   ```bash
   kubectl run tmp-shell --rm -it --image=nicolaka/netshoot -- /bin/bash
   ```
10. **Version control your network configs** — `/etc/network/`, `/etc/netplan/`, firewall rules, etc.
---
 
## Useful One-liners
 
```bash
# Find the process using a port
sudo lsof -i :8080
sudo ss -tlnp | grep :8080
 
# Show top 10 IPs hitting your server
sudo tail -1000 /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head
 
# Show all TCP connections grouped by state
ss -tan | awk 'NR>1 {print $1}' | sort | uniq -c
 
# Monitor connection count to your service
watch -n 1 'ss -tan | grep :443 | wc -l'
 
# Quick port scan of local services
sudo nmap -sT -p- localhost
 
# Get external IP
curl -s ifconfig.me
 
# Continuous ping with timestamps
ping google.com | while read line; do echo "$(date): $line"; done
 
# Tail multiple log files
sudo tail -f /var/log/nginx/error.log /var/log/syslog
```
 
---
 
## Quick Reference: Service Restart Cheat Sheet
 
```bash
# Network
sudo systemctl restart networking          # Debian/Ubuntu
sudo systemctl restart NetworkManager      # NetworkManager-based
sudo netplan apply                         # Ubuntu netplan
 
# DNS
sudo systemctl restart systemd-resolved
sudo resolvectl flush-caches
 
# Web servers
sudo systemctl reload nginx                # graceful reload
sudo systemctl restart nginx
sudo systemctl restart apache2
 
# Firewall
sudo systemctl restart ufw
sudo systemctl restart firewalld
 
# Docker
sudo systemctl restart docker
 
# SSH
sudo systemctl restart sshd
```
 
---