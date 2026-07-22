# Linux User Management & Privilege Escalation
 
A practical guide to understanding `sudo`, `/etc/sudoers`, `/etc/passwd`, and `/etc/shadow` in Linux systems.
 
---
 
## Table of Contents
 
1. [What is `sudo`?](#1-what-is-sudo)
2. [The `/etc/sudoers` File](#2-the-etcsudoers-file)
3. [The `/etc/passwd` File](#3-the-etcpasswd-file)
4. [The `/etc/shadow` File](#4-the-etcshadow-file)
5. [Quick Comparison](#5-quick-comparison)
---
 
## 1. What is `sudo`?
 
`sudo` (**S**uper**U**ser **DO**) is a command-line utility that allows a permitted user to execute a command as the **superuser** (root) or another user, as specified by the security policy.
 
### Why use `sudo`?
 
- Avoids logging in directly as `root` (safer).
- Provides an **audit trail** — every `sudo` command is logged in `/var/log/auth.log` (Debian/Ubuntu) or `/var/log/secure` (RHEL/CentOS).
- Allows **fine-grained** permission control (give specific users access to specific commands).
### Basic Syntax
 
```bash
sudo [options] <command>
```
 
### Examples
 
**Example 1:** Update package list (requires root)
```bash
sudo apt update
```
 
**Example 2:** Edit a system file
```bash
sudo nano /etc/hosts
```
 
**Example 3:** Run a command as another user
```bash
sudo -u www-data whoami
# Output: www-data
```
 
**Example 4:** Switch to root shell
```bash
sudo -i
# or
sudo su -
```
 
**Example 5:** Run the previous command with sudo
```bash
sudo !!
```
 
### Common Options
 
| Option | Description |
|--------|-------------|
| `-u <user>` | Run command as a specific user |
| `-i` | Start a login shell as root |
| `-s` | Start a non-login shell as root |
| `-l` | List allowed commands for the current user |
| `-k` | Invalidate cached credentials (force re-prompt) |
| `-v` | Extend sudo timeout without running a command |
 
---
 
## 2. The `/etc/sudoers` File
 
The `/etc/sudoers` file defines **who can run what** as which user, and from which terminal.
 
>  **WARNING:** Never edit `/etc/sudoers` directly with a regular text editor. Always use the `visudo` command — it validates syntax before saving and prevents you from locking yourself out.
 
```bash
sudo visudo
```
 
### Sudoers Syntax
 
```
user    host=(runas_user:runas_group)    commands
```
 
### Example Entries
 
**Example 1:** Allow user `alice` full root privileges
```
alice   ALL=(ALL:ALL) ALL
```
 
**Example 2:** Allow group `sysadmins` to run all commands
```
%sysadmins   ALL=(ALL) ALL
```
(The `%` prefix denotes a group.)
 
**Example 3:** Allow `bob` to restart Apache without a password
```
bob   ALL=(root) NOPASSWD: /usr/sbin/systemctl restart apache2
```
 
**Example 4:** Allow `dev` to run only specific commands
```
dev   ALL=(ALL) /usr/bin/apt update, /usr/bin/apt upgrade
```
 
**Example 5:** Deny dangerous commands using aliases
```
Cmnd_Alias DANGEROUS = /bin/rm, /sbin/shutdown, /sbin/reboot
intern     ALL=(ALL) ALL, !DANGEROUS
```
 
### Including Drop-in Files
 
Modern Linux uses `/etc/sudoers.d/` for modular config:
 
```bash
sudo visudo -f /etc/sudoers.d/myrules
```
 
This is preferred because package updates won't overwrite custom rules.
 
### Viewing Your Privileges
 
```bash
sudo -l
```
 
---
 
## 3. The `/etc/passwd` File
 
Stores **basic user account information**. World-readable (any user can view it).
 
```bash
cat /etc/passwd
```
 
### Format
 
Each line has **7 fields** separated by colons (`:`):
 
```
username:password:UID:GID:GECOS:home_directory:shell
```
 
### Example Entry
 
```
john:x:1001:1001:John Doe,Engineering,555-1234:/home/john:/bin/bash
```
 
### Field Breakdown
 
| # | Field | Example | Description |
|---|-------|---------|-------------|
| 1 | Username | `john` | Login name |
| 2 | Password | `x` | `x` means password is in `/etc/shadow` |
| 3 | UID | `1001` | User ID (`0` = root, `1-999` = system, `1000+` = regular) |
| 4 | GID | `1001` | Primary Group ID |
| 5 | GECOS | `John Doe,...` | Full name and contact info |
| 6 | Home dir | `/home/john` | User's home directory |
| 7 | Shell | `/bin/bash` | Login shell (`/usr/sbin/nologin` for service accounts) |
 
### Common UID Ranges
 
```
0           → root
1-99        → reserved system accounts
100-999     → system services (daemons)
1000-60000  → regular users
65534       → nobody
```
 
### Example: Service Account
 
```
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
```
Notice the shell is `/usr/sbin/nologin` — this account cannot log in interactively.
 
---
 
## 4. The `/etc/shadow` File
 
Stores **encrypted user passwords** and password aging info. Readable **only by root**.
 
```bash
sudo cat /etc/shadow
```
 
### Format
 
Each line has **9 fields** separated by colons (`:`):
 
```
username:password_hash:lastchange:min:max:warn:inactive:expire:reserved
```
 
### Example Entry
 
```
john:$6$xyz123$a7Hk9JmN2pQR.wEr8Yt5...:19567:0:99999:7:::
```
 
### Field Breakdown
 
| # | Field | Example | Description |
|---|-------|---------|-------------|
| 1 | Username | `john` | Must match `/etc/passwd` |
| 2 | Password hash | `$6$xyz...` | Hashed password (see formats below) |
| 3 | Last change | `19567` | Days since 1970-01-01 since password change |
| 4 | Min days | `0` | Minimum days between password changes |
| 5 | Max days | `99999` | Maximum days password is valid |
| 6 | Warn | `7` | Days before expiry to warn user |
| 7 | Inactive | (empty) | Days after expiry before account is locked |
| 8 | Expire | (empty) | Account expiration date (days since 1970) |
| 9 | Reserved | (empty) | Reserved for future use |
 
### Password Hash Prefixes
 
| Prefix | Algorithm |
|--------|-----------|
| `$1$` | MD5 (deprecated, insecure) |
| `$2a$` / `$2y$` | Blowfish (bcrypt) |
| `$5$` | SHA-256 |
| `$6$` | SHA-512 (most common today) |
| `$y$` | yescrypt (modern Linux default) |
 
### Special Password Field Values
 
- `*` or `!` → Account is **locked** (cannot log in with password)
- Empty → **No password required** (dangerous!)
- `*LK*` → Locked by administrator
### Useful Commands
 
**Lock a user account:**
```bash
sudo passwd -l john
```
 
**Unlock a user account:**
```bash
sudo passwd -u john
```
 
**Check password aging info:**
```bash
sudo chage -l john
```
 
**Force user to change password on next login:**
```bash
sudo chage -d 0 john
```
 
---
 
## 5. Quick Comparison
 
| Feature | `/etc/passwd` | `/etc/shadow` | `/etc/sudoers` |
|---------|---------------|---------------|----------------|
| **Purpose** | User account info | Password hashes & aging | Privilege rules |
| **Permissions** | `644` (world-readable) | `640` or `000` (root only) | `440` (root only) |
| **Owner** | `root:root` | `root:shadow` | `root:root` |
| **Edit with** | `useradd` / `usermod` | `passwd` | `visudo` |
| **Field separator** | `:` | `:` | space / `=` |
 
### Verify Permissions
 
```bash
ls -l /etc/passwd /etc/shadow /etc/sudoers
```
 
Expected output:
```
-rw-r--r-- 1 root root   /etc/passwd
-rw-r----- 1 root shadow /etc/shadow
-r--r----- 1 root root   /etc/sudoers
```
 
---
 
##  Security Best Practices
 
1. **Never** edit `/etc/sudoers` without `visudo`.
2. **Never** give blanket `NOPASSWD: ALL` rights unless absolutely necessary.
3. Use `/etc/sudoers.d/` for modular, easy-to-manage rules.
4. Regularly audit `/etc/passwd` for unexpected UID `0` accounts (besides root).
5. Ensure `/etc/shadow` permissions remain `640` or stricter.
6. Enforce strong password policies via `/etc/login.defs` and PAM.
7. Monitor `/var/log/auth.log` for suspicious sudo activity.
### Audit Example: Find all UID 0 accounts
 
```bash
awk -F: '$3 == 0 {print $1}' /etc/passwd
```
Only `root` should appear. Any other user with UID 0 is a security red flag.
 
---