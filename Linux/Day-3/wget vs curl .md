# wget vs curl
 
A practical cheat sheet comparing **`wget`** and **`curl`** — two of the most common command-line tools for transferring data over HTTP, HTTPS, and FTP.
 
---
 
## Overview
 
| Feature | `wget` | `curl` |
|---|---|---|
| Primary purpose | Downloading files | Transferring data (upload/download) |
| Default behavior | Saves file to disk with original name | Prints response to terminal (stdout) |
| Recursive download | ✅ Yes (mirrors entire sites) | ❌ No |
| Protocol support | HTTP, HTTPS, FTP | HTTP, HTTPS, FTP, SFTP, SCP, SMTP, IMAP, LDAP, and more |
| Resume downloads | ✅ Built-in (`-c`) | ✅ Supported (`-C -`) |
| API / REST calls | ❌ Limited | ✅ Excellent (POST, PUT, DELETE, headers, auth) |
| Follows redirects by default | ✅ Yes | ❌ No (must use `-L`) |
| Pre-installed on macOS | ❌ No | ✅ Yes |
| Pre-installed on most Linux | ✅ Often | ✅ Often |
 
**Rule of thumb:**
- Use **`wget`** when you just want to *grab a file* or mirror a site.
- Use **`curl`** when you need to *talk to an API*, send custom requests, or script HTTP interactions.
---
 
## 1. Downloading Files
 
### Text file
 
```bash
# wget — saves as iso_8859-1.txt automatically
wget https://www.w3.org/TR/PNG/iso_8859-1.txt
 
# curl — -O keeps the remote filename
curl -O https://www.w3.org/TR/PNG/iso_8859-1.txt
```
 
### Image file
 
```bash
wget https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png
curl -O https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png
```
 
### Zip file
 
```bash
wget https://file-examples.com/storage/fe3e3aef4dbf7d7f5c4ccaa/2017/02/zip_2MB.zip
curl -O https://file-examples.com/storage/fe3e3aef4dbf7d7f5c4ccaa/2017/02/zip_2MB.zip
```
 
### Save with a custom filename
 
```bash
wget -O myfile.txt https://www.w3.org/TR/PNG/iso_8859-1.txt
curl -o myfile.txt https://www.w3.org/TR/PNG/iso_8859-1.txt
```
 
> 💡 **Note:** `curl` lowercase `-o` lets you choose the filename, while uppercase `-O` keeps the URL's filename. With `wget`, both behaviors are handled by `-O`.
 
**Use case:** Downloading datasets, software installers, backup files, or any single asset from a known URL.
 
---
 
## 2. Following Redirects
 
Many short URLs (`bit.ly`, `t.co`) and CDN links redirect to the real file. By default `curl` does **not** follow these — `wget` does.
 
```bash
# curl — must explicitly enable redirects with -L
curl -L -o filename.zip http://bit.ly/2mTM3nY
 
# wget — already follows redirects; cap the chain with --max-redirect
wget --max-redirect=20 http://bit.ly/2mTM3nY
```
 
**Use case:** Fetching files behind URL shorteners, login pages that bounce to CDNs, or GitHub release assets that redirect to AWS S3.
 
---
 
## 3. Resuming Interrupted Downloads
 
Useful for large files on flaky connections.
 
```bash
# wget — -c continues from where it stopped
wget -c https://example.com/largefile.iso
 
# curl — -C - tells curl to auto-detect resume position
curl -C - -O https://example.com/largefile.iso
```
 
**Use case:** Downloading multi-GB files (Linux ISOs, Docker layers, ML model weights) when your connection drops mid-transfer.
 
---
 
## 4. APIs and REST Requests (`curl` shines here)
 
### GET request
 
```bash
curl https://jsonplaceholder.typicode.com/posts/1
```
 
### POST with JSON body
 
```bash
curl -X POST https://jsonplaceholder.typicode.com/posts \
  -H "Content-Type: application/json" \
  -d '{"title":"foo","body":"bar","userId":1}'
```
 
### PUT (update a resource)
 
```bash
curl -X PUT https://jsonplaceholder.typicode.com/posts/1 \
  -H "Content-Type: application/json" \
  -d '{"id":1,"title":"updated","body":"new content","userId":1}'
```
 
### DELETE
 
```bash
curl -X DELETE https://jsonplaceholder.typicode.com/posts/1
```
 
### Sending an Authorization header (Bearer token)
 
```bash
curl https://api.example.com/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```
 
**Use case:** Testing REST APIs, debugging webhooks, automating cloud services (AWS, GitHub API, Stripe), and scripting CI/CD pipelines.
 
---
 
## 5. Inspecting Headers and Debugging
 
```bash
# Show only response headers
curl -I https://www.github.com
 
# Verbose mode — full request + response trace
curl -v https://www.github.com
 
# wget equivalent — shows server response details
wget --server-response --spider https://www.github.com
```
 
**Use case:** Checking HTTP status codes, content-type, caching headers, or troubleshooting why an endpoint returns 4xx/5xx errors.
 
---
 
## 6. Authenticated Downloads
 
```bash
# Basic auth
wget --user=admin --password=secret https://example.com/private/file.zip
curl -u admin:secret -O https://example.com/private/file.zip
```
 
**Use case:** Pulling files from internal company servers, password-protected staging environments, or private FTP shares.
 
---
 
## 7. Recursive Download / Site Mirroring (`wget` only)
 
```bash
# Mirror an entire site for offline viewing
wget --mirror --convert-links --adjust-extension --page-requisites --no-parent https://example.com
```
 
**Use case:** Archiving documentation sites, scraping static content, or creating offline copies of a webpage with all its assets.
 
---
 
## 8. Uploading Files (`curl` only)
 
```bash
# Upload via multipart/form-data
curl -F "file=@/path/to/local.png" https://api.example.com/upload
 
# Upload raw file body
curl --upload-file local.txt https://example.com/destination/
```
 
**Use case:** Pushing files to S3 presigned URLs, uploading to image-hosting APIs, or testing file-upload endpoints.
 
---
 
## Quick Reference: Common Flags
 
| Task | `wget` | `curl` |
|---|---|---|
| Save with original name | (default) | `-O` |
| Save with custom name | `-O filename` | `-o filename` |
| Follow redirects | (default) | `-L` |
| Resume download | `-c` | `-C -` |
| Show headers only | `--spider` + `-S` | `-I` |
| Verbose output | `-v` | `-v` |
| Set User-Agent | `--user-agent="..."` | `-A "..."` |
| Add custom header | `--header="..."` | `-H "..."` |
| Limit speed | `--limit-rate=200k` | `--limit-rate 200k` |
| Quiet mode | `-q` | `-s` |
 
---
 
## When to Use Which?
 
**Reach for `wget` when you want to:**
- Download a single file with one short command.
- Mirror a website or directory recursively.
- Run unattended downloads in cron jobs that retry and resume automatically.
**Reach for `curl` when you want to:**
- Talk to a REST/GraphQL API (GET, POST, PUT, DELETE).
- Send custom headers, cookies, or auth tokens.
- Upload files to a server.
- Pipe response bodies directly into other tools (`jq`, `grep`, etc.).
- Work on macOS, where it ships by default.
---
 
## Installation
 
```bash
# Debian / Ubuntu
sudo apt install wget curl
 
# Fedora / RHEL
sudo dnf install wget curl
 
# macOS (curl is preinstalled; wget via Homebrew)
brew install wget
 
# Windows (via winget)
winget install wget
winget install curl
```
 
---