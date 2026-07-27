# Real-World Linux Issues DevOps Engineers Face
 
A practical guide to the most common Linux problems DevOps engineers encounter in production — with symptoms, diagnostic commands, root causes, and fixes. Written for students and junior engineers who want to understand what real on-call life looks like.
 
---
 
## Table of Contents
 
1. [Server Slow or Down — CPU, Memory, Disk](#1-server-slow-or-down--cpu-memory-disk)
2. ["It Works on My Machine" — Permissions & Environment](#2-it-works-on-my-machine--permissions--environment)
3. [Disk Full but Files are Missing](#3-disk-full-but-files-are-missing)
4. [Service Won't Start — systemd Issues](#4-service-wont-start--systemd-issues)
5. [Can't SSH into the Server](#5-cant-ssh-into-the-server)
6. [Deployment Broke Production](#6-deployment-broke-production)
7. [Container Keeps Crashing — Docker / Kubernetes](#7-container-keeps-crashing--docker--kubernetes)
8. [DNS Isn't Working](#8-dns-isnt-working)
9. [Mystery Process Eating CPU — Possible Hack](#9-mystery-process-eating-cpu--possible-hack)
10. [Universal Troubleshooting Mindset](#10-universal-troubleshooting-mindset)
---
 
## 1. Server Slow or Down — CPU, Memory, Disk
 
### 🔥 Scenario
Website suddenly slow at 3 AM. Users complain. Monitoring alerts fire.
 
### Diagnostic Commands (the "first 4")
```bash
uptime              # check load average — high values mean overloaded system
top                 # who's eating CPU/memory?
free -h             # is memory exhausted?
df -h               # is the disk full?
```
 
### Real Causes Engineers See
- A log file grew to 50 GB and **filled the disk** → app can't write → crashes
- A **memory leak** in the app → swap thrashing → everything slows to a crawl
- A backup script ran at the wrong time and used **100% CPU**
- A `cron` job got stuck and spawned **thousands of zombie processes**
### The Fix
Identify the process, kill it or restart the service, then **add monitoring and log rotation** so it doesn't repeat.
 
> 💡 **Lesson:** The first commands in any incident are almost always `uptime`, `top`, `df -h`, `free -h`. Make them muscle memory.
 
---
 
## 2. "It Works on My Machine" — Permissions & Environment
 
### 🔥 Scenario
Deployment succeeds but the app won't start in production.
Logs show `Permission denied` or `command not found`.
 
### Common Real Causes
- Script runs fine as `root` in dev but as `appuser` in prod → missing permissions
- A file owned by `root:root` that the app user can't read
- `PATH` differs — `/usr/local/bin/node` exists for the engineer but not for the systemd service
- File has Windows line endings (`\r\n`) → `bash: ./script.sh: /bin/bash^M: bad interpreter`
### Diagnostic Commands
```bash
ls -la /path/to/file        # check ownership and permissions
sudo -u appuser whoami      # confirm which user the app runs as
sudo -u appuser ./script.sh # try running as the actual user
file script.sh              # check for line-ending issues
```
 
### The Fix
```bash
sudo chown appuser:appuser /path/to/file
sudo chmod 644 /path/to/file
dos2unix script.sh          # fix line endings
```
 
---
 
## 3. Disk Full but Files are Missing
 
### 🔥 Scenario
`df -h` says 100% full, but `du` shows you only have 20 GB of files. **Where did the space go?**
 
### Why This Is Sneaky
A process can hold a **deleted file** open. The disk space isn't freed until the process closes that file.
 
**Real example:** An engineer deleted a live log file with `rm` to "free space." Disk usage didn't go down, because the app still had it open.
 
### Diagnostic Commands
```bash
df -h                                       # confirm full
du -sh /* 2>/dev/null | sort -rh | head     # find biggest dirs
sudo lsof | grep deleted                    # find deleted-but-open files
```
 
### The Fix
Restart the process holding the file, **OR** truncate the file properly without deleting it:
```bash
# DON'T do this on a live log file:
# rm /var/log/app.log
 
# DO this instead — truncates to zero bytes:
> /var/log/app.log
 
# Or with sudo:
sudo truncate -s 0 /var/log/app.log
```
 
---
 
## 4. Service Won't Start — systemd Issues
 
### 🔥 Scenario
After a deploy, `systemctl start myapp` fails silently.
 
### Diagnostic Commands
```bash
systemctl status myapp           # quick status + last few log lines
journalctl -u myapp -n 50        # last 50 log lines for the service
journalctl -u myapp -f           # follow logs live
journalctl -xe                   # explanations + recent errors
```
 
### Real Causes
- **Port already in use** (another instance still running)
- Config file **syntax error**
- Database not reachable yet (app started before DB was ready)
- Missing **environment variable**
### Finding the Port Conflict
```bash
sudo lsof -i :8080
sudo ss -tulpn | grep 8080
```
 
---
 
## 5. Can't SSH into the Server
 
### 🔥 Scenario
Server appears "up" in monitoring but SSH times out.
 
**The classic fear:** You changed `sshd_config`, restarted SSH, and got disconnected. Now you can't reconnect. (Almost every engineer does this once. 😅)
 
### How to Diagnose Without SSH
- Check cloud provider console (AWS EC2, GCP, Azure)
- Use the provider's **serial console** or rescue mode
- Check security groups / firewall rules
### Common Real Causes
- Firewall blocking port 22 (`ufw`, `iptables`, cloud security group)
- SSH service crashed
- **Disk is full** → SSH can't write to log → refuses connections
- Server ran out of memory → **OOM killer** killed `sshd`
### Pro Tip Every Senior Learns the Hard Way
> Before changing SSH config, open a **second SSH session** and keep it connected. If your change breaks SSH, you still have a way in to fix it.
 
---
 
## 6. Deployment Broke Production
 
### 🔥 Scenario
A `git push` triggered a deploy and the site went down.
 
### Real Causes
- Migration ran but had a bug → database in inconsistent state
- New version requires an env variable that wasn't set in prod
- Image was built for `linux/amd64` but server is `arm64`
- Someone merged untested code straight to `main`
### What Engineers Actually Do
1. **Rollback first, debug later** — get the site back up
2. Check deploy logs in Jenkins / GitHub Actions / GitLab
3. Compare what changed:
   ```bash
   git log --oneline main..HEAD
   git diff HEAD~1 HEAD
   ```
4. Check container/app logs:
   ```bash
   docker logs <container>
   kubectl logs <pod>
   ```
 
> 💡 **Lesson:** Always have a rollback plan **before** deploying. "How do I undo this?" should be the first question.
 
---
 
## 7. Container Keeps Crashing — Docker / Kubernetes
 
### 🔥 Scenario
Pod stuck in `CrashLoopBackOff` status.
 
### Diagnostic Commands
```bash
kubectl get pods                          # see status
kubectl describe pod <pod-name>           # events + reasons
kubectl logs <pod-name>                   # current container logs
kubectl logs <pod-name> --previous        # previous container's logs (key for crashes!)
 
# Docker equivalents
docker ps -a                              # see stopped containers too
docker logs <container-id>
docker inspect <container-id>
```
 
### Common Causes
- App needs **more memory** than the pod limit → OOMKilled
- **Healthcheck** endpoint isn't ready yet → Kubernetes thinks it's dead → restart loop
- Wrong command in Dockerfile (`CMD` typo)
- ConfigMap / Secret not mounted correctly
---
 
## 8. DNS Isn't Working
 
### 🔥 Scenario
App can reach `8.8.8.8` (Google's DNS) but not `google.com`.
 
### Diagnostic Commands
```bash
ping 8.8.8.8                # network connectivity OK?
ping google.com             # DNS resolution OK?
nslookup google.com         # DNS lookup details
dig google.com              # more detailed DNS query
cat /etc/resolv.conf        # which DNS server are we using?
```
 
### Real Causes
- `/etc/resolv.conf` got overwritten and points to a dead DNS server
- Corporate VPN dropped DNS settings on disconnect
- Inside a Docker container, DNS uses the host's `/etc/resolv.conf` — if the host is broken, **every container is broken too**
> 💡 **Engineer's saying:** *"It's always DNS."* — and embarrassingly often, it is.
 
---
 
## 9. Mystery Process Eating CPU — Possible Hack
 
### 🔥 Scenario
CPU pinned at 100%, no idea why. `top` shows a strange process name like `kdevtmpfsi` or `xmrig`.
 
**Real cause:** The server has been compromised. Someone planted a crypto miner.
 
### How to Investigate
```bash
ps auxf                              # full process tree — find the parent
ls -l /proc/<PID>/exe                # location of the actual binary
ls -l /proc/<PID>/cwd                # working directory
sudo netstat -tulpn | grep <PID>     # network connections
last                                 # recent logins
sudo tail -50 /var/log/auth.log      # SSH login history
sudo cat /etc/crontab                # check for malicious cron jobs
crontab -l                           # check current user's cron
```
 
### The Fix
1. **Isolate the server** — block external traffic
2. Don't just kill the process — find how they got in
3. **Change all credentials** (SSH keys, passwords, API tokens)
4. **Restore from a known-good backup** — never trust a compromised system
5. Patch the entry point (likely a weak SSH password or unpatched service)
---
 
## 10. Universal Troubleshooting Mindset
 
Real DevOps engineers follow a pattern. Internalize this and you'll handle 80% of incidents calmly.
 
### The 5 Rules
 
1. **What changed?**
   Deploys, configs, traffic patterns, time of day. **90% of incidents follow a recent change.**
2. **Read the logs first**
   `journalctl`, `/var/log/`, app logs, container logs. Don't guess.
3. **Stop the bleeding first**
   Restart, rollback, scale up. Fix the *root cause* after the site is back.
4. **One change at a time**
   If you change three things and it works, you don't know **what** fixed it.
5. **Document it**
   Write a postmortem. Future-you (and your teammates) will thank you.
---
 
## Quick Reference — The DevOps Engineer's Toolkit
 
| Need to check... | Command |
|---|---|
| System load | `uptime` |
| CPU & memory live | `top` / `htop` |
| Memory usage | `free -h` |
| Disk space | `df -h` |
| Largest directories | `du -sh /* \| sort -rh \| head` |
| Open files / ports | `lsof -i :PORT` / `ss -tulpn` |
| Service status | `systemctl status SERVICE` |
| Service logs | `journalctl -u SERVICE -f` |
| Recent system errors | `journalctl -xe` |
| Process tree | `ps auxf` / `pstree -p` |
| Network connectivity | `ping`, `traceroute`, `mtr` |
| DNS resolution | `dig`, `nslookup` |
| Container logs | `docker logs` / `kubectl logs` |
| Recent logins | `last`, `/var/log/auth.log` |
 
---