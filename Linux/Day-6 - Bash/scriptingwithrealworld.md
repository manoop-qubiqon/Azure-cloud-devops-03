 ---
 
## Case Study 1: Automating File Backup
 
**Objective:** Write a script to automate daily file backups using `rsync`.
 
```bash
#!/bin/bash
# Daily backup script
SRC="/source/directory"
DEST="/backup/directory"
LOG="/var/log/backup.log"
 
echo "Backup started at $(date)" >> $LOG
rsync -avz --delete $SRC $DEST >> $LOG 2>&1
echo "Backup completed at $(date)" >> $LOG
```
 
**Sample Output:**
```
Backup started at Sat May  9 09:00:01 IST 2026
sending incremental file list
./
file1.txt
file2.log
docs/report.pdf
sent 1,245,678 bytes  received 235 bytes  830,608.67 bytes/sec
total size is 1,243,210  speedup is 1.00
Backup completed at Sat May  9 09:00:08 IST 2026
```
 
---
 
## Case Study 2: Automating Server Maintenance
 
**Objective:** Automate server updates and reboots.
 
```bash
#!/bin/bash
# Server maintenance script
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get autoremove -y
sudo reboot
```
 
**Sample Output:**
```
Hit:1 http://archive.ubuntu.com/ubuntu jammy InRelease
Get:2 http://security.ubuntu.com/ubuntu jammy-security InRelease [110 kB]
Reading package lists... Done
Reading state information... Done
Calculating upgrade... Done
The following packages will be upgraded:
  curl libssl3 openssh-server openssh-client
4 upgraded, 0 newly installed, 0 to remove.
Setting up curl (7.81.0-1ubuntu1.15) ...
Broadcast message: The system is going down for reboot NOW!
```
 
---
 
## Case Study 3: Disk Usage Monitoring
 
**Objective:** Monitor disk usage and alert when usage exceeds 80%.
 
```bash
#!/bin/bash
# Disk usage alert script
THRESHOLD=80
df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }' | while read output;
do
  usage=$(echo $output | awk '{ print $1 }' | cut -d'%' -f1)
  partition=$(echo $output | awk '{ print $2 }')
  if [ $usage -ge $THRESHOLD ]; then
    echo "ALERT: Partition $partition is at ${usage}% usage" | \
      mail -s "Disk Alert: $partition" admin@example.com
  fi
done
```
 
**Sample Output:**
```
ALERT: Partition /dev/sda1 is at 87% usage
ALERT: Partition /dev/sdb1 is at 92% usage
Email sent to admin@example.com
```
 
---
 
## Case Study 4: Log File Rotation and Cleanup
 
**Objective:** Compress logs older than 7 days and delete logs older than 30 days.
 
```bash
#!/bin/bash
# Log rotation script
LOG_DIR="/var/log/myapp"
 
# Compress logs older than 7 days
find $LOG_DIR -type f -name "*.log" -mtime +7 ! -name "*.gz" -exec gzip {} \;
 
# Delete compressed logs older than 30 days
find $LOG_DIR -type f -name "*.gz" -mtime +30 -exec rm -f {} \;
 
echo "Log rotation completed on $(date)"
```
 
**Sample Output:**
```
Compressed: /var/log/myapp/app-2026-04-25.log -> app-2026-04-25.log.gz
Compressed: /var/log/myapp/app-2026-04-26.log -> app-2026-04-26.log.gz
Deleted: /var/log/myapp/app-2026-03-15.log.gz
Deleted: /var/log/myapp/app-2026-03-16.log.gz
Log rotation completed on Sat May  9 02:00:05 IST 2026
```
 
---
 
## Case Study 5: Bulk User Account Creation
 
**Objective:** Create multiple Linux user accounts from a text file.
 
```bash
#!/bin/bash
# Bulk user creation script
USER_FILE="users.txt"
 
while IFS=, read -r username fullname; do
  if id "$username" &>/dev/null; then
    echo "User $username already exists"
  else
    sudo useradd -m -c "$fullname" -s /bin/bash "$username"
    sudo passwd -e "$username"
    echo "Created user: $username ($fullname)"
  fi
done < "$USER_FILE"
```
 
**users.txt:**
```
alice,Alice Johnson
bob,Bob Smith
carol,Carol Davis
```
 
**Sample Output:**
```
Created user: alice (Alice Johnson)
Created user: bob (Bob Smith)
Created user: carol (Carol Davis)
```
 
---
 
## Case Study 6: System Health Check Report
 
**Objective:** Generate a daily system health report.
 
```bash
#!/bin/bash
# System health report
REPORT="/tmp/health_report_$(date +%F).txt"
 
{
  echo "===== SYSTEM HEALTH REPORT ====="
  echo "Date: $(date)"
  echo "Hostname: $(hostname)"
  echo "Uptime: $(uptime -p)"
  echo ""
  echo "----- CPU Load -----"
  uptime | awk -F'load average:' '{print $2}'
  echo ""
  echo "----- Memory Usage -----"
  free -h
  echo ""
  echo "----- Disk Usage -----"
  df -h | grep -v tmpfs
} > $REPORT
 
cat $REPORT
```
 
**Sample Output:**
```
===== SYSTEM HEALTH REPORT =====
Date: Sat May  9 08:30:00 IST 2026
Hostname: web-server-01
Uptime: up 12 days, 4 hours, 22 minutes
 
----- CPU Load -----
 0.45, 0.52, 0.48
 
----- Memory Usage -----
              total        used        free      shared
Mem:          7.7Gi       3.2Gi       2.1Gi       180Mi
Swap:         2.0Gi          0B       2.0Gi
 
----- Disk Usage -----
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        50G   28G   20G  59% /
```
 
---
 
## Case Study 7: Automated MySQL Database Backup
 
**Objective:** Backup MySQL databases with date-stamped filenames.
 
```bash
#!/bin/bash
# MySQL backup script
BACKUP_DIR="/backup/mysql"
DATE=$(date +%F_%H-%M)
DB_USER="backup_user"
DB_PASS="secure_password"
 
mkdir -p $BACKUP_DIR
 
databases=$(mysql -u $DB_USER -p$DB_PASS -e "SHOW DATABASES;" | grep -Ev "Database|information_schema|performance_schema|mysql|sys")
 
for db in $databases; do
  mysqldump -u $DB_USER -p$DB_PASS --databases $db | gzip > "$BACKUP_DIR/${db}_${DATE}.sql.gz"
  echo "Backed up: $db"
done
```
 
**Sample Output:**
```
Backed up: production_db
Backed up: staging_db
Backed up: analytics_db
Files saved in /backup/mysql:
production_db_2026-05-09_02-00.sql.gz
staging_db_2026-05-09_02-00.sql.gz
analytics_db_2026-05-09_02-00.sql.gz
```
 
---
 
## Case Study 8: Website Uptime Monitoring
 
**Objective:** Monitor websites and alert if any are down.
 
```bash
#!/bin/bash
# Website uptime monitor
SITES=("https://example.com" "https://api.example.com" "https://blog.example.com")
 
for site in "${SITES[@]}"; do
  STATUS=$(curl -o /dev/null -s -w "%{http_code}" --max-time 10 $site)
  if [ "$STATUS" -eq 200 ]; then
    echo "[OK] $site is UP (HTTP $STATUS)"
  else
    echo "[ALERT] $site is DOWN (HTTP $STATUS)"
    echo "$site returned $STATUS at $(date)" | mail -s "Site Down" admin@example.com
  fi
done
```
 
**Sample Output:**
```
[OK] https://example.com is UP (HTTP 200)
[ALERT] https://api.example.com is DOWN (HTTP 503)
[OK] https://blog.example.com is UP (HTTP 200)
```
 
---
 
## Case Study 9: SSL Certificate Expiry Check
 
**Objective:** Check SSL certificate expiration for domains.
 
```bash
#!/bin/bash
# SSL certificate expiry check
DOMAINS=("example.com" "api.example.com" "blog.example.com")
WARN_DAYS=30
 
for domain in "${DOMAINS[@]}"; do
  EXPIRY=$(echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null \
    | openssl x509 -noout -enddate | cut -d= -f2)
  EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
  NOW_EPOCH=$(date +%s)
  DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
 
  if [ $DAYS_LEFT -lt $WARN_DAYS ]; then
    echo "[WARNING] $domain expires in $DAYS_LEFT days"
  else
    echo "[OK] $domain expires in $DAYS_LEFT days"
  fi
done
```
 
**Sample Output:**
```
[OK] example.com expires in 87 days
[WARNING] api.example.com expires in 12 days
[OK] blog.example.com expires in 245 days
```
 
---
 
## Case Study 10: Failed SSH Login Analysis
 
**Objective:** Analyze authentication logs for failed SSH login attempts.
 
```bash
#!/bin/bash
# Failed SSH login analyzer
LOG="/var/log/auth.log"
 
echo "===== Top 10 IPs with Failed SSH Logins ====="
grep "Failed password" $LOG | awk '{print $(NF-3)}' | sort | uniq -c | sort -nr | head -10
 
echo ""
echo "===== Top Targeted Usernames ====="
grep "Failed password" $LOG | awk '{print $(NF-5)}' | sort | uniq -c | sort -nr | head -10
```
 
**Sample Output:**
```
===== Top 10 IPs with Failed SSH Logins =====
   1247 192.168.45.23
    892 203.0.113.45
    456 198.51.100.67
    234 45.33.22.11
    180 122.18.5.99
 
===== Top Targeted Usernames =====
   2341 root
    432 admin
    321 ubuntu
    198 test
    145 oracle
```
 
---
 
## Case Study 11: Memory Usage Alert
 
**Objective:** Alert when memory usage exceeds 85%.
 
```bash
#!/bin/bash
# Memory usage alert
THRESHOLD=85
USAGE=$(free | awk '/Mem:/ {printf("%.0f"), $3/$2 * 100}')
 
if [ $USAGE -ge $THRESHOLD ]; then
  echo "[ALERT] Memory usage is at ${USAGE}%"
  ps aux --sort=-%mem | head -6
  echo "Memory at ${USAGE}% on $(hostname)" | mail -s "Memory Alert" admin@example.com
else
  echo "[OK] Memory usage is at ${USAGE}%"
fi
```
 
**Sample Output:**
```
[ALERT] Memory usage is at 91%
USER       PID %CPU %MEM    VSZ   RSS COMMAND
mysql     1234  2.1 25.4 1245678 987654 mysqld
www-data  2345  1.8 18.2  876543 712345 apache2
java      3456  3.2 15.7  765432 645321 java
postgres  4567  0.9  8.4  543210 412345 postgres
```
 
---
 
## Case Study 12: CPU Usage Monitoring
 
**Objective:** Monitor CPU usage and log high-load processes.
 
```bash
#!/bin/bash
# CPU usage monitor
THRESHOLD=80
LOG="/var/log/cpu_monitor.log"
 
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | cut -d. -f1)
 
if [ $CPU_USAGE -ge $THRESHOLD ]; then
  {
    echo "===== HIGH CPU ALERT $(date) ====="
    echo "CPU Usage: ${CPU_USAGE}%"
    echo "Top processes:"
    ps aux --sort=-%cpu | head -6
  } >> $LOG
  echo "ALERT: CPU at ${CPU_USAGE}% - Logged to $LOG"
else
  echo "[OK] CPU usage is at ${CPU_USAGE}%"
fi
```
 
**Sample Output:**
```
===== HIGH CPU ALERT Sat May  9 10:15:23 IST 2026 =====
CPU Usage: 87%
Top processes:
USER       PID %CPU %MEM COMMAND
nginx     1543 45.2  3.1 nginx: worker
python    2876 28.6  8.4 python app.py
mysql     1234 12.1 25.4 mysqld
```
 
---
 
## Case Study 13: Automated File Compression and Archival
 
**Objective:** Compress files older than 30 days into a tarball.
 
```bash
#!/bin/bash
# Archive old files
SRC_DIR="/data/projects"
ARCHIVE_DIR="/data/archives"
DATE=$(date +%F)
 
mkdir -p $ARCHIVE_DIR
ARCHIVE_FILE="$ARCHIVE_DIR/archive_${DATE}.tar.gz"
 
find $SRC_DIR -type f -mtime +30 -print0 | tar -czvf $ARCHIVE_FILE --null -T -
 
if [ $? -eq 0 ]; then
  find $SRC_DIR -type f -mtime +30 -delete
  echo "Archive created: $ARCHIVE_FILE"
  echo "Old files removed from source"
fi
```
 
**Sample Output:**
```
/data/projects/old_report_2026-03-12.pdf
/data/projects/legacy_data_2026-02-28.csv
/data/projects/old_logs/app_2026-03-15.log
Archive created: /data/archives/archive_2026-05-09.tar.gz
Old files removed from source
Archive size: 245M
```
 
---
 
## Case Study 14: Bulk File Renaming
 
**Objective:** Rename all `.txt` files to `.bak` and add a date prefix.
 
```bash
#!/bin/bash
# Bulk file renamer
DIR="/path/to/files"
DATE=$(date +%F)
 
cd "$DIR" || exit 1
 
count=0
for file in *.txt; do
  [ -e "$file" ] || continue
  newname="${DATE}_${file%.txt}.bak"
  mv "$file" "$newname"
  echo "Renamed: $file -> $newname"
  count=$((count + 1))
done
 
echo "Total files renamed: $count"
```
 
**Sample Output:**
```
Renamed: report.txt -> 2026-05-09_report.bak
Renamed: notes.txt -> 2026-05-09_notes.bak
Renamed: meeting.txt -> 2026-05-09_meeting.bak
Renamed: todo.txt -> 2026-05-09_todo.bak
Total files renamed: 4
```
 
---
 
## Case Study 15: Network Connectivity Check
 
**Objective:** Ping multiple hosts and report connectivity status.
 
```bash
#!/bin/bash
# Network connectivity check
HOSTS=("google.com" "8.8.8.8" "github.com" "192.168.1.1" "internal-server.local")
 
echo "===== Network Connectivity Report - $(date) ====="
for host in "${HOSTS[@]}"; do
  if ping -c 2 -W 2 $host &>/dev/null; then
    LATENCY=$(ping -c 1 -W 2 $host | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')
    echo "[REACHABLE] $host - ${LATENCY}ms"
  else
    echo "[UNREACHABLE] $host"
  fi
done
```
 
**Sample Output:**
```
===== Network Connectivity Report - Sat May  9 11:00:00 IST 2026 =====
[REACHABLE] google.com - 14.2ms
[REACHABLE] 8.8.8.8 - 12.8ms
[REACHABLE] github.com - 28.5ms
[REACHABLE] 192.168.1.1 - 0.8ms
[UNREACHABLE] internal-server.local
```
 
---
 
## Case Study 16: Process Monitoring and Auto-Restart
 
**Objective:** Monitor a critical service and restart it if down.
 
```bash
#!/bin/bash
# Service monitor and restart
SERVICE="nginx"
LOG="/var/log/service_monitor.log"
 
if systemctl is-active --quiet $SERVICE; then
  echo "[$(date)] $SERVICE is running" >> $LOG
else
  echo "[$(date)] $SERVICE is DOWN - attempting restart" >> $LOG
  sudo systemctl restart $SERVICE
  sleep 5
 
  if systemctl is-active --quiet $SERVICE; then
    echo "[$(date)] $SERVICE restarted successfully" >> $LOG
    echo "$SERVICE was down and restarted on $(hostname)" | mail -s "Service Restart" admin@example.com
  else
    echo "[$(date)] $SERVICE restart FAILED" >> $LOG
    echo "$SERVICE could not be restarted on $(hostname)" | mail -s "URGENT: Service Down" admin@example.com
  fi
fi
```
 
**Sample Output:**
```
[Sat May  9 10:00:01 IST 2026] nginx is running
[Sat May  9 10:05:01 IST 2026] nginx is DOWN - attempting restart
[Sat May  9 10:05:07 IST 2026] nginx restarted successfully
[Sat May  9 10:10:01 IST 2026] nginx is running
```
 
---
 
## Case Study 17: Find and Delete Old Files
 
**Objective:** Find and delete temporary files older than 14 days.
 
```bash
#!/bin/bash
# Cleanup old temp files
DIRS=("/tmp" "/var/tmp" "/home/user/Downloads")
DAYS=14
 
for dir in "${DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo "Cleaning $dir (files older than $DAYS days)..."
    COUNT=$(find "$dir" -type f -mtime +$DAYS | wc -l)
    SIZE=$(find "$dir" -type f -mtime +$DAYS -exec du -ch {} + | tail -1 | awk '{print $1}')
    find "$dir" -type f -mtime +$DAYS -delete
    echo "  Deleted: $COUNT files, freed $SIZE"
  fi
done
```
 
**Sample Output:**
```
Cleaning /tmp (files older than 14 days)...
  Deleted: 245 files, freed 1.2G
Cleaning /var/tmp (files older than 14 days)...
  Deleted: 87 files, freed 342M
Cleaning /home/user/Downloads (files older than 14 days)...
  Deleted: 32 files, freed 856M
```
 
---
 
## Case Study 18: Automated Git Commit and Push
 
**Objective:** Auto-commit and push changes to a Git repository.
 
```bash
#!/bin/bash
# Auto Git commit and push
REPO_DIR="/home/user/projects/myrepo"
BRANCH="main"
 
cd $REPO_DIR || exit 1
 
if [ -z "$(git status --porcelain)" ]; then
  echo "No changes to commit"
  exit 0
fi
 
git add .
COMMIT_MSG="Automated commit: $(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "$COMMIT_MSG"
git push origin $BRANCH
 
if [ $? -eq 0 ]; then
  echo "Successfully pushed changes to $BRANCH"
else
  echo "Push failed - check connectivity or credentials"
fi
```
 
**Sample Output:**
```
[main 4f2a8b1] Automated commit: 2026-05-09 14:30:15
 3 files changed, 47 insertions(+), 12 deletions(-)
Counting objects: 5, done.
Compressing objects: 100% (3/3), done.
Writing objects: 100% (5/5), 1.42 KiB | 1.42 MiB/s, done.
To github.com:user/myrepo.git
   3a1b2c3..4f2a8b1  main -> main
Successfully pushed changes to main
```
 
---
 
## Case Study 19: Synchronize Two Directories
 
**Objective:** Two-way sync between local and remote directories using rsync.
 
```bash
#!/bin/bash
# Two-way directory sync
LOCAL_DIR="/home/user/documents"
REMOTE_USER="user"
REMOTE_HOST="backup.example.com"
REMOTE_DIR="/home/user/documents_backup"
LOG="/var/log/sync.log"
 
echo "===== Sync started: $(date) =====" >> $LOG
 
# Local to remote
rsync -avz --update --delete \
  $LOCAL_DIR/ ${REMOTE_USER}@${REMOTE_HOST}:$REMOTE_DIR/ >> $LOG 2>&1
 
# Remote to local
rsync -avz --update \
  ${REMOTE_USER}@${REMOTE_HOST}:$REMOTE_DIR/ $LOCAL_DIR/ >> $LOG 2>&1
 
echo "===== Sync completed: $(date) =====" >> $LOG
echo "Sync complete - check $LOG for details"
```
 
**Sample Output:**
```
===== Sync started: Sat May  9 15:00:00 IST 2026 =====
sending incremental file list
project_notes.md
new_design.png
sent 458,234 bytes  received 312 bytes  76,424.33 bytes/sec
 
receiving incremental file list
remote_changes.txt
sent 235 bytes  received 4,521 bytes  951.20 bytes/sec
===== Sync completed: Sat May  9 15:00:08 IST 2026 =====
Sync complete - check /var/log/sync.log for details
```
 
---
 
## Case Study 20: System Information Report Generator
 
**Objective:** Generate a comprehensive system information report.
 
```bash
#!/bin/bash
# System information report
REPORT="/tmp/sysinfo_$(hostname)_$(date +%F).txt"
 
{
  echo "============================================"
  echo "       SYSTEM INFORMATION REPORT            "
  echo "============================================"
  echo "Generated: $(date)"
  echo ""
  echo "----- System -----"
  echo "Hostname:    $(hostname)"
  echo "OS:          $(lsb_release -d | cut -f2)"
  echo "Kernel:      $(uname -r)"
  echo "Architecture: $(uname -m)"
  echo "Uptime:      $(uptime -p)"
  echo ""
  echo "----- Hardware -----"
  echo "CPU Model:   $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
  echo "CPU Cores:   $(nproc)"
  echo "Total RAM:   $(free -h | awk '/Mem:/ {print $2}')"
  echo ""
  echo "----- Network -----"
  echo "IP Address:  $(hostname -I | awk '{print $1}')"
  echo "Gateway:     $(ip route | grep default | awk '{print $3}')"
  echo ""
  echo "----- Storage -----"
  df -h | grep -v tmpfs
  echo ""
  echo "----- Top 5 Processes (Memory) -----"
  ps aux --sort=-%mem | head -6
} > $REPORT
 
cat $REPORT
echo ""
echo "Report saved to: $REPORT"
```
 
**Sample Output:**
```
============================================
       SYSTEM INFORMATION REPORT
============================================
Generated: Sat May  9 16:00:00 IST 2026
 
----- System -----
Hostname:    web-server-01
OS:          Ubuntu 24.04.2 LTS
Kernel:      6.8.0-45-generic
Architecture: x86_64
Uptime:      up 12 days, 6 hours
 
----- Hardware -----
CPU Model:   Intel(R) Xeon(R) CPU E5-2670 v3 @ 2.30GHz
CPU Cores:   8
Total RAM:   16Gi
 
----- Network -----
IP Address:  192.168.1.105
Gateway:     192.168.1.1
 
----- Storage -----
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       100G   45G   55G  46% /
/dev/sdb1       500G  120G  380G  24% /data
 
----- Top 5 Processes (Memory) -----
USER       PID %CPU %MEM COMMAND
mysql     1234  2.1 25.4 mysqld
java      2345  1.8 18.2 java -jar app.jar
nginx     3456  0.9  3.1 nginx: master process
postgres  4567  0.5  8.4 postgres
redis     5678  0.3  2.1 redis-server
 
Report saved to: /tmp/sysinfo_web-server-01_2026-05-09.txt
```
 
---
 
## Summary
 
| # | Case Study | Key Tool/Command |
|---|------------|------------------|
| 1 | File Backup | `rsync` |
| 2 | Server Maintenance | `apt-get`, `reboot` |
| 3 | Disk Usage Monitoring | `df`, `awk`, `mail` |
| 4 | Log Rotation | `find`, `gzip` |
| 5 | Bulk User Creation | `useradd`, `passwd` |
| 6 | System Health Check | `uptime`, `free`, `df` |
| 7 | MySQL Backup | `mysqldump`, `gzip` |
| 8 | Website Uptime | `curl` |
| 9 | SSL Certificate Check | `openssl` |
| 10 | SSH Login Analysis | `grep`, `awk`, `sort` |
| 11 | Memory Alert | `free`, `ps`, `mail` |
| 12 | CPU Monitoring | `top`, `ps` |
| 13 | File Archival | `tar`, `find` |
| 14 | Bulk File Rename | `mv` loops |
| 15 | Network Check | `ping` |
| 16 | Service Auto-Restart | `systemctl` |
| 17 | Cleanup Old Files | `find`, `-delete` |
| 18 | Auto Git Push | `git` |
| 19 | Directory Sync | `rsync` |
| 20 | System Info Report | `lsb_release`, `uname`, `ps` |
 
---
 
## How to Use These Scripts
 
1. **Save** each script to a `.sh` file (e.g., `backup.sh`).
2. **Make executable**: `chmod +x backup.sh`
3. **Test manually**: `./backup.sh`
4. **Schedule with cron** for automation:
   ```bash
   crontab -e
   # Example: Run backup daily at 2 AM
   0 2 * * * /path/to/backup.sh
   ```
5. **Monitor logs** to ensure scripts are running correctly.
---