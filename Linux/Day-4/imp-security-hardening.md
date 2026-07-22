#  Linux Server Hardening Guide
 
A practical, command-driven checklist for hardening a Linux server against common threats. Tested on Ubuntu/Debian and RHEL/CentOS/Rocky.
 
>  **Always test in a non-production environment first.** Some commands restrict access and may lock you out if misconfigured. Keep a backup root session open while applying changes.
 
---
 
## Table of Contents
 
1. [System Updates & Patch Management](#1-system-updates--patch-management)
2. [User Account Security](#2-user-account-security)
3. [SSH Hardening](#3-ssh-hardening)
4. [Firewall Configuration](#4-firewall-configuration)
5. [Fail2Ban (Brute-Force Protection)](#5-fail2ban-brute-force-protection)
6. [File & Directory Permissions](#6-file--directory-permissions)
7. [Disable Unused Services & Ports](#7-disable-unused-services--ports)
8. [Kernel Hardening (sysctl)](#8-kernel-hardening-sysctl)
9. [Auditing & Logging](#9-auditing--logging)
10. [Intrusion Detection (AIDE / rkhunter)](#10-intrusion-detection-aide--rkhunter)
11. [Automatic Security Updates](#11-automatic-security-updates)
12. [Time Synchronization](#12-time-synchronization)
13. [Mandatory Access Control (SELinux / AppArmor)](#13-mandatory-access-control-selinux--apparmor)
14. [Final Checklist](#14-final-checklist)
---
 
## 1. System Updates & Patch Management
 
The single most important hardening step — **keep packages patched**.
 
### Debian / Ubuntu
```bash
sudo apt update && sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove --purge -y
```
 
### RHEL / CentOS / Rocky / AlmaLinux
```bash
sudo dnf update -y
sudo dnf autoremove -y
```
 
### Check for pending reboots
```bash
# Debian/Ubuntu
[ -f /var/run/reboot-required ] && echo "Reboot required"
 
# RHEL-based
sudo dnf needs-restarting -r
```
 
---
 
## 2. User Account Security
 
### Audit existing users
 
```bash
# List all users
cut -d: -f1 /etc/passwd
 
# Find users with UID 0 (only root should be here!)
awk -F: '$3 == 0 {print $1}' /etc/passwd
 
# Find accounts with empty passwords (DANGER)
sudo awk -F: '($2 == "") {print $1}' /etc/shadow
 
# List users who can log in
grep -v '/usr/sbin/nologin\|/bin/false' /etc/passwd
```
 
### Lock or remove unused accounts
```bash
sudo passwd -l <username>          # lock
sudo usermod -L <username>         # lock (alternative)
sudo userdel -r <username>         # delete user + home dir
```
 
### Enforce strong password policy
 
Edit `/etc/login.defs`:
```bash
sudo nano /etc/login.defs
```
```
PASS_MAX_DAYS   90
PASS_MIN_DAYS   7
PASS_MIN_LEN    14
PASS_WARN_AGE   14
```
 
### Install password complexity module
```bash
# Debian/Ubuntu
sudo apt install libpam-pwquality -y
 
# RHEL-based
sudo dnf install libpwquality -y
```
 
Edit `/etc/security/pwquality.conf`:
```
minlen = 14
dcredit = -1     # at least 1 digit
ucredit = -1     # at least 1 uppercase
lcredit = -1     # at least 1 lowercase
ocredit = -1     # at least 1 special char
retry = 3
```
 
### Set account lockout after failed logins
 
Edit `/etc/pam.d/common-auth` (Debian) or `/etc/pam.d/system-auth` (RHEL):
```
auth required pam_tally2.so deny=5 unlock_time=900 onerr=fail
```
 
---
 
## 3. SSH Hardening
 
SSH is the #1 attack vector. Lock it down.
 
### Create a non-root sudo user first!
```bash
sudo adduser deploy
sudo usermod -aG sudo deploy        # Debian/Ubuntu
sudo usermod -aG wheel deploy       # RHEL-based
```
 
### Set up SSH key authentication
On your **local** machine:
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
ssh-copy-id deploy@server_ip
```
 
### Edit SSH config
```bash
sudo nano /etc/ssh/sshd_config
```
 
Recommended settings:
```
Port 2222                          # change from default 22
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 30
AllowUsers deploy                  # whitelist users
Protocol 2
```
 
### Test config & restart
```bash
sudo sshd -t                       # validate syntax
sudo systemctl restart sshd
```
 
> 💡 **Open a second SSH session before disconnecting** to verify you can still log in.
 
---
 
## 4. Firewall Configuration
 
### UFW (Ubuntu/Debian)
```bash
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp            # SSH on custom port
sudo ufw allow 80/tcp              # HTTP
sudo ufw allow 443/tcp             # HTTPS
sudo ufw enable
sudo ufw status verbose
```
 
### firewalld (RHEL/CentOS/Rocky)
```bash
sudo systemctl enable --now firewalld
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --remove-service=ssh   # if you changed port
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```
 
### iptables (low-level)
```bash
sudo iptables -L -v -n
```
 
---
 
## 5. Fail2Ban (Brute-Force Protection)
 
Automatically bans IPs that show malicious behavior.
 
### Install
```bash
# Debian/Ubuntu
sudo apt install fail2ban -y
 
# RHEL-based
sudo dnf install epel-release -y
sudo dnf install fail2ban -y
```
 
### Configure
```bash
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local
```
 
Key settings:
```ini
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd
 
[sshd]
enabled  = true
port     = 2222
logpath  = %(sshd_log)s
```
 
### Start & verify
```bash
sudo systemctl enable --now fail2ban
sudo fail2ban-client status
sudo fail2ban-client status sshd
```
 
### Manually unban an IP
```bash
sudo fail2ban-client set sshd unbanip <IP>
```
 
---
 
## 6. File & Directory Permissions
 
### Verify critical file permissions
```bash
sudo chmod 644 /etc/passwd
sudo chmod 640 /etc/shadow
sudo chmod 644 /etc/group
sudo chmod 640 /etc/gshadow
sudo chmod 440 /etc/sudoers
sudo chmod 600 /boot/grub/grub.cfg     # bootloader
```
 
### Find world-writable files (security risk)
```bash
sudo find / -xdev -type f -perm -0002 -print 2>/dev/null
```
 
### Find files with no owner
```bash
sudo find / -xdev \( -nouser -o -nogroup \) -print 2>/dev/null
```
 
### Find SUID/SGID binaries (audit these!)
```bash
sudo find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -print 2>/dev/null
```
 
### Secure `/tmp` (mount with restrictive options)
Edit `/etc/fstab`:
```
tmpfs   /tmp   tmpfs   defaults,nodev,nosuid,noexec   0 0
```
 
---
 
## 7. Disable Unused Services & Ports
 
### List enabled services
```bash
systemctl list-unit-files --state=enabled
```
 
### List listening ports
```bash
sudo ss -tulnp
sudo netstat -tulnp        # legacy
```
 
### Disable a service
```bash
sudo systemctl stop <service>
sudo systemctl disable <service>
sudo systemctl mask <service>     # prevent it from being started
```
 
### Common services to disable if unused
```bash
sudo systemctl disable --now avahi-daemon
sudo systemctl disable --now cups
sudo systemctl disable --now bluetooth
sudo systemctl disable --now rpcbind
```
 
---
 
## 8. Kernel Hardening (sysctl)
 
Edit `/etc/sysctl.d/99-hardening.conf`:
```bash
sudo nano /etc/sysctl.d/99-hardening.conf
```
 
```bash
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
 
# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1
 
# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
 
# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
 
# Block SYN attacks
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
 
# Log Martians
net.ipv4.conf.all.log_martians = 1
 
# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
 
# Disable IPv6 if not needed
# net.ipv6.conf.all.disable_ipv6 = 1
 
# Restrict kernel pointer exposure
kernel.kptr_restrict = 2
 
# Restrict dmesg access
kernel.dmesg_restrict = 1
 
# Disable core dumps
fs.suid_dumpable = 0
```
 
Apply:
```bash
sudo sysctl -p /etc/sysctl.d/99-hardening.conf
```
 
---
 
## 9. Auditing & Logging
 
### Install auditd
```bash
# Debian/Ubuntu
sudo apt install auditd audispd-plugins -y
 
# RHEL-based
sudo dnf install audit -y
```
 
```bash
sudo systemctl enable --now auditd
```
 
### Useful audit rules
Edit `/etc/audit/rules.d/hardening.rules`:
```
# Monitor user/group changes
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes
-w /etc/group  -p wa -k group_changes
-w /etc/sudoers -p wa -k sudoers_changes
 
# Monitor login records
-w /var/log/lastlog -p wa -k logins
-w /var/log/faillog -p wa -k logins
 
# Monitor system calls
-a always,exit -F arch=b64 -S execve -k exec
```
 
Reload:
```bash
sudo augenrules --load
sudo systemctl restart auditd
```
 
### Search audit logs
```bash
sudo ausearch -k passwd_changes
sudo aureport --summary
```
 
### Centralize logs (rsyslog)
```bash
sudo nano /etc/rsyslog.conf
# Add: *.* @logserver.example.com:514
sudo systemctl restart rsyslog
```
 
---
 
## 10. Intrusion Detection (AIDE / rkhunter)
 
### AIDE — File integrity monitoring
```bash
# Debian/Ubuntu
sudo apt install aide -y
sudo aideinit
 
# RHEL-based
sudo dnf install aide -y
sudo aide --init
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
```
 
Run a check:
```bash
sudo aide --check
```
 
Schedule daily checks via cron:
```bash
sudo crontab -e
```
```
0 3 * * * /usr/sbin/aide --check | mail -s "AIDE Report" admin@example.com
```
 
### rkhunter — Rootkit scanner
```bash
sudo apt install rkhunter -y
sudo rkhunter --update
sudo rkhunter --propupd
sudo rkhunter --check
```
 
### chkrootkit — Alternative rootkit scanner
```bash
sudo apt install chkrootkit -y
sudo chkrootkit
```
 
---
 
## 11. Automatic Security Updates
 
### Debian / Ubuntu
```bash
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades
```
 
Edit `/etc/apt/apt.conf.d/50unattended-upgrades` to enable security updates only.
 
### RHEL / Rocky / AlmaLinux
```bash
sudo dnf install dnf-automatic -y
sudo systemctl enable --now dnf-automatic.timer
```
 
Edit `/etc/dnf/automatic.conf`:
```
upgrade_type = security
apply_updates = yes
```
 
---
 
## 12. Time Synchronization
 
Accurate time is critical for logs and certificates.
 
```bash
sudo timedatectl set-timezone UTC
sudo timedatectl set-ntp true
timedatectl status
```
 
Or use chrony:
```bash
sudo apt install chrony -y          # Debian/Ubuntu
sudo dnf install chrony -y          # RHEL-based
sudo systemctl enable --now chronyd
chronyc tracking
```
 
---
 
## 13. Mandatory Access Control (SELinux / AppArmor)
 
### SELinux (RHEL-based)
```bash
sestatus                            # check status
sudo setenforce 1                   # enforce now
```
 
Edit `/etc/selinux/config`:
```
SELINUX=enforcing
```
 
### AppArmor (Debian/Ubuntu)
```bash
sudo apt install apparmor apparmor-utils -y
sudo systemctl enable --now apparmor
sudo aa-status
```
 
---
 
## 14. Final Checklist
 
| ✅ | Task |
|----|------|
| ☐ | System fully updated |
| ☐ | Root login disabled |
| ☐ | SSH on custom port + key-only auth |
| ☐ | Non-root sudo user created |
| ☐ | Strong password policy enforced |
| ☐ | Firewall enabled with minimal ports |
| ☐ | Fail2Ban running and tested |
| ☐ | Unused services disabled |
| ☐ | sysctl kernel hardening applied |
| ☐ | auditd installed and configured |
| ☐ | AIDE / rkhunter scheduled |
| ☐ | Automatic security updates enabled |
| ☐ | NTP/chrony time sync working |
| ☐ | SELinux/AppArmor in enforcing mode |
| ☐ | Backups configured and tested |
| ☐ | `/tmp` mounted with `noexec,nosuid,nodev` |
| ☐ | World-writable files audited |
| ☐ | SUID/SGID binaries audited |
 
---
 
## 🔍 Quick Audit One-Liners
 
```bash
# Show last 20 logins
last -n 20
 
# Failed login attempts
sudo lastb -n 20
 
# Currently logged-in users
who -a
 
# Users with sudo access
getent group sudo wheel 2>/dev/null
 
# Open ports
sudo ss -tulnp
 
# Active connections
sudo ss -tnp
 
# Top resource-using processes
ps aux --sort=-%mem | head
```
 
---
 
## 📚 References
 
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)
- [Lynis Security Auditing Tool](https://cisofy.com/lynis/)
- [Linux Server Hardening — DISA STIG](https://public.cyber.mil/stigs/)
- `man sshd_config`
- `man sysctl`
- `man auditctl`
### Bonus: Run a full audit with Lynis
```bash
sudo apt install lynis -y           # or: sudo dnf install lynis -y
sudo lynis audit system
```
 
---