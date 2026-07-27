# Linux Logs & Ports — DevOps Engineer Cheatsheet
 
A practical reference for the log files and network ports every DevOps engineer should know.
 
---
 
##  Part 1 — Essential Linux Logs
 
Most logs live under `/var/log/`. On modern systemd-based distros, many are also accessible via `journalctl`.
 
###  System & Kernel Logs
 
| Log File | Description |
|----------|-------------|
| `/var/log/syslog` | General system activity (Debian/Ubuntu) |
| `/var/log/messages` | General system activity (RHEL/CentOS/Fedora) |
| `/var/log/kern.log` | Kernel messages and warnings |
| `/var/log/dmesg` | Boot-time kernel ring buffer messages |
| `/var/log/boot.log` | System boot logs |
| `/var/log/alternatives.log` | `update-alternatives` activity |
 
###  Authentication & Security Logs
 
| Log File | Description |
|----------|-------------|
| `/var/log/auth.log` | Authentication events (Debian/Ubuntu) — SSH, sudo, login |
| `/var/log/secure` | Authentication events (RHEL/CentOS) |
| `/var/log/faillog` | Failed login attempts |
| `/var/log/wtmp` | Successful login history (use `last`) |
| `/var/log/btmp` | Failed login attempts (use `lastb`) |
| `/var/log/lastlog` | Last login of each user (use `lastlog`) |
| `/var/log/audit/audit.log` | `auditd` logs (SELinux, system calls) |
 
###  Service & Application Logs
 
| Log File / Path | Description |
|-----------------|-------------|
| `/var/log/cron` or `/var/log/syslog` | Scheduled cron job execution |
| `/var/log/mail.log` | Mail server (Postfix, Sendmail) |
| `/var/log/apache2/` or `/var/log/httpd/` | Apache access & error logs |
| `/var/log/nginx/` | Nginx access & error logs |
| `/var/log/mysql/` or `/var/log/mariadb/` | MySQL/MariaDB logs |
| `/var/log/postgresql/` | PostgreSQL logs |
| `/var/log/redis/` | Redis logs |
| `/var/log/docker/` | Docker daemon logs (or via `journalctl -u docker`) |
| `/var/log/containers/` | Kubernetes container logs (on nodes) |
| `/var/log/pods/` | Kubernetes pod logs (on nodes) |
 
###  Package Management Logs
 
| Log File | Description |
|----------|-------------|
| `/var/log/dpkg.log` | Debian/Ubuntu package install/remove |
| `/var/log/apt/history.log` | APT command history |
| `/var/log/yum.log` | YUM history (RHEL/CentOS) |
| `/var/log/dnf.log` | DNF history (Fedora/RHEL 8+) |
 
###  systemd / journald
 
```bash
journalctl                    # all logs
journalctl -u nginx           # logs for a specific service
journalctl -f                 # follow (tail -f equivalent)
journalctl --since "1 hour ago"
journalctl -p err             # filter by priority (err, warning, info)
journalctl -k                 # kernel logs only
journalctl --disk-usage
```
 
###  Useful Log Commands
 
```bash
tail -f /var/log/syslog           # live tail
less /var/log/auth.log            # paged view
grep -i "error" /var/log/syslog   # search
zgrep "404" /var/log/nginx/*.gz   # search compressed logs
logrotate -d /etc/logrotate.conf  # test log rotation
dmesg | tail                      # recent kernel messages
last -a                           # login history
```
 
---
 
## 🌐 Part 2 — Essential Ports
 
###  Core Network Services
 
| Port | Protocol | Service |
|------|----------|---------|
| 20 | TCP | FTP (data) |
| 21 | TCP | FTP (control) |
| 22 | TCP | SSH / SCP / SFTP |
| 23 | TCP | Telnet (avoid in production) |
| 25 | TCP | SMTP |
| 53 | TCP/UDP | DNS |
| 67, 68 | UDP | DHCP (server, client) |
| 69 | UDP | TFTP |
| 80 | TCP | HTTP |
| 110 | TCP | POP3 |
| 123 | UDP | NTP |
| 143 | TCP | IMAP |
| 161, 162 | UDP | SNMP, SNMP Trap |
| 389 | TCP | LDAP |
| 443 | TCP | HTTPS |
| 465 | TCP | SMTPS |
| 514 | UDP | Syslog |
| 587 | TCP | SMTP (submission/TLS) |
| 636 | TCP | LDAPS |
| 873 | TCP | rsync |
| 993 | TCP | IMAPS |
| 995 | TCP | POP3S |
| 3389 | TCP | RDP |
| 5900 | TCP | VNC |
 
###  Databases
 
| Port | Service |
|------|---------|
| 1433 | Microsoft SQL Server |
| 1521 | Oracle DB |
| 3306 | MySQL / MariaDB |
| 5432 | PostgreSQL |
| 6379 | Redis |
| 7000, 7001 | Cassandra |
| 9042 | Cassandra (CQL) |
| 11211 | Memcached |
| 27017 | MongoDB |
 
### Message Brokers & Streaming
 
| Port | Service |
|------|---------|
| 1883 | MQTT |
| 4222 | NATS |
| 5672 | RabbitMQ (AMQP) |
| 9092 | Apache Kafka |
| 15672 | RabbitMQ Management UI |
| 2181 | Zookeeper |
 
###  Web & Application Servers
 
| Port | Service |
|------|---------|
| 3000 | Node.js / Grafana / React dev |
| 4200 | Angular dev server |
| 5000 | Flask / Docker Registry |
| 8000 | Django / Python HTTP |
| 8080 | HTTP alt / Tomcat / Jenkins |
| 8443 | HTTPS alt / Tomcat SSL |
| 8888 | Jupyter |
| 9000 | PHP-FPM / SonarQube / Portainer |
 
###  Containers & Orchestration
 
| Port | Service |
|------|---------|
| 2375 | Docker daemon (unencrypted — avoid) |
| 2376 | Docker daemon (TLS) |
| 2377 | Docker Swarm cluster management |
| 4789 | Docker overlay network (VXLAN) |
| 7946 | Docker Swarm node communication |
| 5000 | Docker Registry |
| 6443 | Kubernetes API server |
| 2379, 2380 | etcd (client, peer) |
| 10250 | Kubelet API |
| 10251 | kube-scheduler |
| 10252 | kube-controller-manager |
| 10256 | kube-proxy health |
| 30000–32767 | Kubernetes NodePort range |
 
###  Monitoring & Observability
 
| Port | Service |
|------|---------|
| 3000 | Grafana |
| 9090 | Prometheus |
| 9091 | Prometheus Pushgateway |
| 9093 | Alertmanager |
| 9100 | Node Exporter |
| 9115 | Blackbox Exporter |
| 9200 | Elasticsearch (HTTP) |
| 9300 | Elasticsearch (cluster) |
| 5601 | Kibana |
| 5044 | Logstash (Beats input) |
| 8086 | InfluxDB |
| 4317, 4318 | OpenTelemetry (gRPC, HTTP) |
 
###  DevOps Tools
 
| Port | Service |
|------|---------|
| 8080 | Jenkins (default) |
| 50000 | Jenkins agent |
| 8081 | Nexus Repository |
| 9000 | SonarQube |
| 8200 | HashiCorp Vault |
| 8500 | HashiCorp Consul |
| 8600 | Consul DNS |
| 4646 | HashiCorp Nomad |
| 8140 | Puppet |
| 80, 443 | GitLab / Gitea (web) |
| 22 | Git over SSH |
 
###  Useful Networking Commands
 
```bash
ss -tulnp                  # list listening TCP/UDP ports (modern)
netstat -tulnp             # legacy alternative
lsof -i :8080              # which process owns port 8080
nmap -p 1-1000 host        # port scan
nc -zv host 443            # test if a port is open
telnet host 22             # quick connectivity test
ufw status                 # firewall (Ubuntu)
firewall-cmd --list-all    # firewall (RHEL/CentOS)
iptables -L -n -v          # raw iptables rules
```
 
---
 
##  Quick Tips
 
- **Reserved range:** 0–1023 are well-known/privileged ports (require root to bind).
- **Registered range:** 1024–49151 are assigned by IANA.
- **Ephemeral range:** 49152–65535 are typically used for outgoing client connections.
- Always check `/etc/services` for the canonical port-name mapping on your system.
- Use `journalctl` first on systemd distros — many services no longer write to `/var/log/`.
- Configure **logrotate** for any custom application logs to prevent disk-full incidents.
- Never expose database, Docker daemon, or Kubelet ports directly to the internet.
---
