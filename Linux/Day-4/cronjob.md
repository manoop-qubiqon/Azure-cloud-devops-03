# Cron Jobs in Linux — A Beginner's Guide
 
A simple, easy-to-understand guide to scheduling tasks in Linux using **cron**. Learn the syntax, write your first job, and avoid the common mistakes.
 
---
 
## What is Cron?
 
**Cron** is a time-based scheduler built into Linux. It runs commands or scripts automatically at the times you specify.
 
A **cron job** is a single scheduled task. Examples:
-  Run a backup every night at 2 AM
-  Clean up temp files every Sunday
-  Send a daily report at 9 AM
-  Sync data every 15 minutes
Cron has been on Linux/Unix systems for decades. It's reliable, simple, and used everywhere in DevOps and system administration.
 
---
 
## The Crontab File
 
A **crontab** ("cron table") is the file where you list your scheduled jobs.
 
Each user has their own crontab. You don't edit it directly — you use the `crontab` command.
 
### Essential commands
 
```bash
crontab -e        # edit your crontab
crontab -l        # list (view) your crontab
crontab -r        # remove (delete) all your jobs — careful!
```
 
When you run `crontab -e` for the first time, it asks which editor to use (usually nano or vim — pick nano if you're new).
 
---
 
## The Cron Syntax — The Five Stars
 
Every cron job line has this format:
 
```
*  *  *  *  *  command-to-run
│  │  │  │  │
│  │  │  │  └─── Day of week  (0–6)   (Sunday = 0 or 7)
│  │  │  └────── Month        (1–12)
│  │  └───────── Day of month (1–31)
│  └──────────── Hour         (0–23)
└─────────────── Minute       (0–59)
```
 
### Read it left to right
**Minute → Hour → Day → Month → Weekday → Command**
 
### What does `*` mean?
A `*` means **"every"**. So `* * * * *` literally means *"every minute of every hour of every day of every month, every day of the week."*
 
---
 
## Simple Examples (Just Read These!)
 
| Cron Expression | When It Runs |
|---|---|
| `* * * * *` | Every minute |
| `0 * * * *` | Every hour (at minute 0) |
| `0 0 * * *` | Every day at midnight |
| `30 2 * * *` | Every day at 2:30 AM |
| `0 9 * * 1` | Every Monday at 9:00 AM |
| `0 0 1 * *` | First day of every month at midnight |
| `0 0 1 1 *` | January 1st at midnight (once a year) |
| `*/5 * * * *` | Every 5 minutes |
| `0 */2 * * *` | Every 2 hours |
| `0 9-17 * * 1-5` | Every hour from 9 AM to 5 PM, Mon–Fri |
| `0 0 * * 0,6` | Midnight on Saturday and Sunday |
 
---
 
## Special Characters
 
| Symbol | Meaning | Example |
|---|---|---|
| `*` | Every | `* * * * *` → every minute |
| `,` | List of values | `0 9,12,18 * * *` → 9 AM, noon, 6 PM |
| `-` | Range | `0 9-17 * * *` → every hour 9 AM to 5 PM |
| `/` | Step (interval) | `*/15 * * * *` → every 15 minutes |
 
---
 
## Shortcut Strings (Easier to Read)
 
Cron also accepts these friendly aliases:
 
| Shortcut | Equivalent | Meaning |
|---|---|---|
| `@reboot` | — | Run once at system startup |
| `@yearly` / `@annually` | `0 0 1 1 *` | Once a year |
| `@monthly` | `0 0 1 * *` | Once a month |
| `@weekly` | `0 0 * * 0` | Once a week (Sunday midnight) |
| `@daily` / `@midnight` | `0 0 * * *` | Once a day |
| `@hourly` | `0 * * * *` | Once an hour |
 
### Example
```cron
@daily /home/alice/scripts/backup.sh
@reboot /home/alice/scripts/start-services.sh
```
 
---
 
## Real-World Examples
 
### 1. Backup script every night at 2 AM
 
```cron
0 2 * * * /home/alice/scripts/backup.sh
```
 
### 2. Clear `/tmp` every Sunday at 3 AM
 
```cron
0 3 * * 0 rm -rf /tmp/*
```
 
### 3. Run a Python script every 10 minutes
 
```cron
*/10 * * * * /usr/bin/python3 /home/alice/scripts/check.py
```
 
### 4. Send a report at 9 AM on weekdays
 
```cron
0 9 * * 1-5 /home/alice/scripts/daily-report.sh
```
 
### 5. Restart a service every Sunday at midnight
 
```cron
0 0 * * 0 /usr/bin/systemctl restart myapp
```
 
### 6. Run something at boot (useful for VMs and Raspberry Pi)
 
```cron
@reboot /home/alice/scripts/startup.sh
```
 
---
 
## Capturing Output and Errors
 
By default, cron sends any output to the user's email. On most systems, that email goes nowhere — so output gets lost.
 
**Always redirect output to a log file** so you can debug problems.
 
```bash
# Send normal output AND errors to a log file
0 2 * * * /home/alice/scripts/backup.sh >> /home/alice/logs/backup.log 2>&1
 
# Discard all output (only do this if you're sure)
0 2 * * * /home/alice/scripts/backup.sh > /dev/null 2>&1
```
 
### What does `2>&1` mean?
- `>` redirects normal output (stdout)
- `2>` redirects errors (stderr)
- `2>&1` means **"send errors to the same place as normal output"**
So `>> backup.log 2>&1` means *"append everything (output and errors) to backup.log."*
 
---
 
## Step-by-Step: Your First Cron Job
 
Let's create a job that writes the current date to a file every minute.
 
### Step 1 — Create a simple script
 
```bash
mkdir -p ~/scripts
nano ~/scripts/log-date.sh
```
 
Paste this in:
```bash
#!/bin/bash
echo "Current time: $(date)" >> ~/scripts/date-log.txt
```
 
### Step 2 — Make it executable
 
```bash
chmod +x ~/scripts/log-date.sh
```
 
### Step 3 — Open your crontab
 
```bash
crontab -e
```
 
### Step 4 — Add this line
 
```cron
* * * * * /home/YOUR_USERNAME/scripts/log-date.sh
```
 
(Replace `YOUR_USERNAME` with your actual username — get it with `whoami`.)
 
### Step 5 — Save and exit
 
In **nano**: `Ctrl+O`, then `Enter`, then `Ctrl+X`.
 
### Step 6 — Watch it work
 
```bash
tail -f ~/scripts/date-log.txt
```
 
You'll see a new line appear every minute. 🎉
 
### Step 7 — Stop the job
 
```bash
crontab -e
```
Delete the line, save, and exit.
 
---
 
## Common Mistakes (and How to Avoid Them)
 
###  1. Using relative paths
```cron
# BAD — cron has a minimal PATH and doesn't know where you are
0 2 * * * backup.sh
```
 
```cron
# GOOD — always use full paths
0 2 * * * /home/alice/scripts/backup.sh
```
 
###  2. Forgetting to make scripts executable
```bash
chmod +x /home/alice/scripts/backup.sh
```
 
###  3. Assuming environment variables exist
Cron runs with a **minimal environment**. Variables like `$PATH`, `$JAVA_HOME`, etc. may not be set.
 
```cron
# BAD — `python` might not be found
0 2 * * * python myscript.py
 
# GOOD — full path to the interpreter
0 2 * * * /usr/bin/python3 /home/alice/myscript.py
```
 
You can also set variables at the top of the crontab:
```cron
SHELL=/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin
 
0 2 * * * backup.sh
```
 
###  4. Not capturing logs → silent failures
Always redirect to a log file. **A cron job that fails silently is the worst kind of bug.**
 
###  5. Forgetting the newline at the end of crontab
Some older cron implementations require a blank line at the end of the file. If your jobs aren't running, add an empty line.
 
###  6. Confusing weekday numbering
- Sunday is `0` **or** `7` in most systems
- Monday is `1`
- Don't mix this up with calendar conventions
---
 
## Checking If Cron Is Working
 
### Is the cron service running?
```bash
systemctl status cron      # Debian/Ubuntu
systemctl status crond     # RHEL/CentOS/Fedora
```
 
### View cron logs
```bash
# Debian/Ubuntu
grep CRON /var/log/syslog
 
# RHEL/CentOS
sudo tail -f /var/log/cron
```
 
### Check if your job ran
```bash
journalctl | grep CRON
```
 
---
 
## System-Wide Cron Files
 
Besides each user's crontab, there are system-level cron locations. You usually don't edit these as a beginner, but it helps to know they exist:
 
| Location | What it's for |
|---|---|
| `/etc/crontab` | System-wide crontab (has an extra `user` field) |
| `/etc/cron.d/` | Drop folder for system-managed cron files |
| `/etc/cron.hourly/` | Scripts that auto-run every hour |
| `/etc/cron.daily/` | Scripts that auto-run every day |
| `/etc/cron.weekly/` | Scripts that auto-run every week |
| `/etc/cron.monthly/` | Scripts that auto-run every month |
 
>  **Tip:** To run a daily job, you can simply drop an executable script into `/etc/cron.daily/` — no crontab editing needed.
 
---
 
## Tools to Help You
 
###  Crontab.guru
[**crontab.guru**](https://crontab.guru) is a free website that explains any cron expression in plain English. Paste in `*/15 9-17 * * 1-5` and it'll tell you exactly when it runs. **Use this every time you're unsure.**
 
### 🔄 Modern alternatives to cron
- **systemd timers** — more flexible, with better logging via `journalctl`
- **`anacron`** — runs missed jobs when a laptop is turned back on (cron skips them)
- **Kubernetes CronJobs** — same syntax, runs in containers
---
 
## Quick Reference
 
| Task | Command / Syntax |
|---|---|
| Edit your crontab | `crontab -e` |
| List your jobs | `crontab -l` |
| Remove all your jobs | `crontab -r` |
| Edit another user's crontab (root) | `sudo crontab -u alice -e` |
| Run every minute | `* * * * *` |
| Run every hour | `0 * * * *` |
| Run every day at 2 AM | `0 2 * * *` |
| Run every Sunday | `0 0 * * 0` |
| Run every 5 minutes | `*/5 * * * *` |
| Log output and errors | `>> file.log 2>&1` |
| Run at boot | `@reboot command` |
 
---