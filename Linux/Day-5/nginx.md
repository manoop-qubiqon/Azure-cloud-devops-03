# What is Nginx?
 
A simple guide to understanding **Nginx** (pronounced *"engine-x"*) — what it is, why it's used, and where you'll meet it in real projects.
 
---
 
## 1. What is Nginx?
 
**Nginx** is a free, open-source, high-performance **web server**. It also works as a:
 
- Reverse proxy
- Load balancer
- HTTP cache
- Mail proxy
It was created by **Igor Sysoev** in 2004 to solve the **C10K problem** — handling 10,000+ simultaneous connections on a single server. Today it powers a huge chunk of the internet, including sites like Netflix, Dropbox, WordPress.com, and GitHub.
 
> Think of Nginx as a **smart traffic controller** standing in front of your application — receiving requests from users and deciding what to do with them.
 
---
 
## 2. Why Nginx? (vs Apache)
 
| Feature | Nginx | Apache |
|---------|-------|--------|
| Architecture | Event-driven (async) | Process/thread-based |
| Performance under load | Excellent | Drops with many users |
| Memory usage | Very low | Higher |
| Static content | Super fast | Fast |
| Configuration | Simple, clean | Flexible, more complex |
 
**Bottom line:** Nginx handles thousands of concurrent connections using very little memory. That's why it's the go-to choice for modern web apps.
 
---
 
## 3. Main Uses of Nginx
 
### 🔹 a) Web Server
Serves static files (HTML, CSS, JS, images) directly to the browser — fast.
 
```
User → Nginx → returns index.html
```
 
### 🔹 b) Reverse Proxy
Sits in front of your app (Node.js, Django, Flask, etc.) and forwards requests to it.
 
```
User → Nginx → Node.js app (port 3000)
```
 
**Why use it?**
- Hides the real backend
- Adds SSL/HTTPS easily
- Handles slow clients without burdening the app
### 🔹 c) Load Balancer
Distributes incoming traffic across multiple backend servers so no single server gets overwhelmed.
 
```
              ┌──→ Server 1
User → Nginx ─┼──→ Server 2
              └──→ Server 3
```
 
**Common methods:**
- Round-robin (default)
- Least connections
- IP hash (sticky sessions)
### 🔹 d) SSL/TLS Termination
Handles HTTPS encryption so your backend app doesn't have to.
 
```
User (HTTPS) → Nginx (decrypts) → App (HTTP)
```
 
### 🔹 e) Caching
Stores frequently requested responses to speed up delivery and reduce backend load.
 
### 🔹 f) API Gateway
Routes different URL paths to different microservices.
 
```
/api/users  → Users service
/api/orders → Orders service
/api/auth   → Auth service
```
 
---
 
## 4. Real-World Example
 
You build a Node.js app running on `localhost:3000`. To make it production-ready:
 
1. **Domain points to your server** → `mysite.com`
2. **Nginx listens on port 80/443** (HTTP/HTTPS)
3. **Nginx forwards requests** to your Node app on port 3000
4. **Static files** (images, CSS) are served directly by Nginx — never even reaching Node
Result: faster site, free HTTPS, easy to scale later by adding more Node instances.
 
---
 
## 5. Basic Nginx Config Example
 
A simple reverse proxy config:
 
```nginx
server {
    listen 80;
    server_name mysite.com;
 
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
 
    location /static/ {
        root /var/www/mysite;
    }
}
```
 
**What this does:**
- Listens on port 80 for `mysite.com`
- Forwards all requests to your Node app on port 3000
- Serves files in `/static/` directly from disk
---
 
## 6. Common Nginx Commands (Ubuntu)
 
```bash
# Install
sudo apt install nginx
 
# Start / stop / restart
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
 
# Reload after config changes (no downtime)
sudo systemctl reload nginx
 
# Test configuration for errors
sudo nginx -t
 
# Check status
sudo systemctl status nginx
 
# View logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```
 
**Important paths:**
```
/etc/nginx/nginx.conf           → main config
/etc/nginx/sites-available/     → site configs (you write these)
/etc/nginx/sites-enabled/       → active sites (symlinks)
/var/www/html/                  → default web root
/var/log/nginx/                 → logs
```
 
---
 
## 7. Where Nginx Shines
 
-  Hosting static websites
-  Production deployments of Node, Python, PHP apps
-  Microservices and API gateways
-  High-traffic sites (millions of users)
-  Adding HTTPS to any app quickly (with Let's Encrypt + Certbot)
-  CDN-like caching for slow backends
---
 
## 8. Things to Remember
 
- Always run `sudo nginx -t` **before** reloading — catches config errors early.
- Use `reload`, not `restart`, when possible — zero downtime.
- Default web root is `/var/www/html` — drop your files there for a quick test.
- Keep one config file per site in `sites-available/`, then symlink into `sites-enabled/`.
- Pair with **Certbot** for free auto-renewing HTTPS certificates.
- Nginx logs everything — `access.log` for traffic, `error.log` for problems.
---
 
## 9. Quick Cheatsheet
 
```
Web server      →  serves files
Reverse proxy   →  forwards requests to your app
Load balancer   →  spreads traffic across servers
SSL terminator  →  handles HTTPS
Cache           →  speeds up repeated requests
```
 
---
 
*Nginx is one of those tools you set up once, then forget — until it saves you during a traffic spike.
