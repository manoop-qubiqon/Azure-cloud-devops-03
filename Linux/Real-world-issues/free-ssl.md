# Free SSL Certificate Installation on Ubuntu Server
 
A step-by-step guide to install a free **Let's Encrypt SSL certificate** on an Ubuntu server using **Certbot**.
 
---
 
## Prerequisites
 
Before you start, make sure you have:
 
- An Ubuntu server (18.04 / 20.04 / 22.04 / 24.04)
- `sudo` or root access
- A registered domain name (e.g., `example.com`) with an **A record** pointing to your server's public IP
- A web server installed — **Nginx** or **Apache**
- Ports **80** and **443** open in your firewall
>  To check if your domain points to your server, run: `dig example.com +short`
 
---
 
## Step 1 — Update Your System
 
```bash
sudo apt update
sudo apt upgrade -y
```
 
---
 
## Step 2 — Open Firewall Ports
 
If you are using `ufw`, allow HTTP and HTTPS:
 
**For Nginx:**
```bash
sudo ufw allow 'Nginx Full'
```
 
**For Apache:**
```bash
sudo ufw allow 'Apache Full'
```
 
Verify:
```bash
sudo ufw status
```
 
---
 
## Step 3 — Install Certbot
 
Install Certbot and the plugin for your web server.
 
**For Nginx:**
```bash
sudo apt install certbot python3-certbot-nginx -y
```
 
**For Apache:**
```bash
sudo apt install certbot python3-certbot-apache -y
```
 
---
 
## Step 4 — Obtain the SSL Certificate
 
Replace `example.com` with your actual domain.
 
**For Nginx:**
```bash
sudo certbot --nginx -d example.com -d www.example.com
```
 
**For Apache:**
```bash
sudo certbot --apache -d example.com -d www.example.com
```
 
Certbot will:
 
1. Ask for your email (used for renewal notices)
2. Ask you to agree to the Terms of Service
3. Verify domain ownership
4. Install the certificate automatically
5. Offer to redirect all HTTP traffic to HTTPS — **choose option 2 (Redirect)**
---
 
## Step 5 — Verify the Installation
 
Open your site in a browser:
 
```
https://example.com
```
 
You should see a padlock  in the address bar.
 
You can also test from the terminal:
 
```bash
curl -I https://example.com
```
 
Or check the certificate details:
 
```bash
sudo certbot certificates
```
 
---
 
## Step 6 — Test Auto-Renewal
 
Let's Encrypt certificates expire every **90 days**, but Certbot installs an automatic renewal timer.
 
Test it with a dry run:
 
```bash
sudo certbot renew --dry-run
```
 
Check that the renewal timer is active:
 
```bash
sudo systemctl status certbot.timer
```
 
If it shows `active (waiting)`, you're all set — renewals will happen automatically.
 
---
 
## Useful Commands
 
| Task | Command |
|------|---------|
| List all certificates | `sudo certbot certificates` |
| Renew all certificates | `sudo certbot renew` |
| Force-renew a certificate | `sudo certbot renew --force-renewal` |
| Delete a certificate | `sudo certbot delete --cert-name example.com` |
| Reload Nginx | `sudo systemctl reload nginx` |
| Reload Apache | `sudo systemctl reload apache2` |
 
---
 
## Troubleshooting
 
** "DNS problem: NXDOMAIN" or "could not resolve host"**
Your domain isn't pointing to the server yet. Wait for DNS propagation (5–30 minutes) and retry.
 
** "Connection refused" on port 80**
- Make sure the web server is running: `sudo systemctl status nginx` (or `apache2`)
- Make sure port 80 is open in your firewall **and** in your cloud provider's security group (AWS, GCP, Oracle, Azure, etc.)
** Behind Cloudflare?**
Either temporarily disable the proxy (gray cloud) during issuance, or use the DNS-01 challenge:
```bash
sudo apt install python3-certbot-dns-cloudflare
```
 
** Certificate not renewing?**
Check the logs:
```bash
sudo journalctl -u certbot.timer
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```
 
---
 
## Notes
 
- Let's Encrypt certificates are **100% free** and trusted by all major browsers.
- Each certificate is valid for **90 days** and renews automatically.
- You can include multiple domains and subdomains in a single certificate using multiple `-d` flags.
- For a wildcard certificate (`*.example.com`), you must use the **DNS-01** challenge.
---
