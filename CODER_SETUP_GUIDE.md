# Coder Setup Guide — Self-Hosted Dev Environments

**Version:** 2026.02.14  
**Target:** Home lab / personal use  
**Platform:** Docker (Linux, WSL2, macOS with limitations)

---

## 🎯 What is Coder?

**Coder** is an open-source platform for provisioning secure, cloud-based development environments. Think "VS Code in the cloud" but for entire dev workspaces that can run on Docker, Kubernetes, AWS, GCP, or Azure.

**Use cases:**
- Consistent dev environments across machines
- Powerful cloud workspaces from any device
- Auto-shutdown idle environments (save resources)
- Template-based provisioning (Docker, K8s, VMs)
- Browser-based coding (works on tablets/Chromebooks)

**License:** MIT (free forever, even for commercial use)

---

## 📋 Prerequisites

### Required

- **Docker** — installed and running
  - Linux: [Install Docker Engine](https://docs.docker.com/engine/install/)
  - Windows: WSL2 + Docker Desktop
  - macOS: Docker Desktop (limited; prefer standalone binary)
  
- **Docker Compose** — for easy setup
  ```bash
  docker compose version
  # If missing: https://docs.docker.com/compose/install/
  ```

- **System resources:**
  - 2+ CPU cores
  - 4+ GB RAM free
  - 10+ GB disk space

### Recommended

- **Linux machine or WSL2** (Coder Docker install works best on Linux)
- **Static IP or domain** (for remote access)
- **Firewall configured** (if exposing publicly)

---

## 🚀 Installation Methods

### Option 1: Docker Compose (Recommended)

**Easiest setup** — includes Coder + PostgreSQL + persistent storage.

#### Step 1: Download compose file

```bash
# Create a Coder directory
mkdir -p ~/coder && cd ~/coder

# Download official docker-compose.yaml
curl -fsSL https://raw.githubusercontent.com/coder/coder/main/compose.yaml -o docker-compose.yaml
```

#### Step 2: Configure Docker group

Coder needs access to Docker socket. Get your Docker group ID:

```bash
getent group docker | cut -d: -f3
```

**Edit `docker-compose.yaml`** and update the `group_add` line:

```yaml
services:
  coder:
    # ...
    group_add:
      - "999"  # Replace 999 with your docker group gid from above
```

#### Step 3: Set access URL (optional but recommended)

**For local testing:**
```bash
# Add to docker-compose.yaml environment section:
environment:
  CODER_ACCESS_URL: http://localhost:3000
```

**For remote access:**
```bash
environment:
  CODER_ACCESS_URL: http://your-server-ip:3000
  # Or: https://coder.yourdomain.com (requires reverse proxy)
```

#### Step 4: Start Coder

```bash
docker compose up -d
```

**Check status:**
```bash
docker compose ps
docker compose logs -f coder
```

#### Step 5: Access Coder

Open your browser:
```
http://localhost:3000
```

**First-time setup:**
1. Create admin account
2. Set up your first template
3. Provision a workspace

---

### Option 2: Docker Run (Manual)

**More control** but requires separate PostgreSQL setup.

#### With SQLite (testing only)

```bash
docker run -d \
  --name=coder \
  --restart=unless-stopped \
  -p 3000:3000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/.config/coder:/home/coder/.config \
  --group-add $(getent group docker | cut -d: -f3) \
  -e CODER_ACCESS_URL=http://localhost:3000 \
  ghcr.io/coder/coder:latest
```

**Windows (PowerShell):**
```powershell
docker run -d `
  --name coder `
  --restart unless-stopped `
  -p 3000:3000 `
  -v /var/run/docker.sock:/var/run/docker.sock `
  -v ${env:APPDATA}/coder:/home/coder/.config `
  -e CODER_ACCESS_URL=http://localhost:3000 `
  ghcr.io/coder/coder:latest
```

#### With PostgreSQL (production)

```bash
# 1. Start PostgreSQL
docker run -d \
  --name=coder-db \
  --restart=unless-stopped \
  -e POSTGRES_USER=coder \
  -e POSTGRES_PASSWORD=coder \
  -e POSTGRES_DB=coder \
  -v coder-db:/var/lib/postgresql/data \
  postgres:15

# 2. Start Coder
docker run -d \
  --name=coder \
  --restart=unless-stopped \
  --link coder-db:postgres \
  -p 3000:3000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/.config/coder:/home/coder/.config \
  --group-add $(getent group docker | cut -d: -f3) \
  -e CODER_ACCESS_URL=http://localhost:3000 \
  -e CODER_PG_CONNECTION_URL=postgres://coder:coder@postgres:5432/coder?sslmode=disable \
  ghcr.io/coder/coder:latest
```

---

### Option 3: Standalone Binary (macOS/Linux/Windows)

**Best for macOS** (Docker on Mac has limitations with docker.sock binding).

```bash
# Download latest Coder binary
curl -fsSL https://coder.com/install.sh | sh

# Start Coder
coder server
```

#### Windows (Winget)

```powershell
# Install Coder
winget install -e --id Coder.Coder

# Start Coder
coder server
```

Access at `http://localhost:3000`

---

## ⚙️ Configuration

### Environment Variables

Key settings (add to `docker-compose.yaml` or `docker run`):

```yaml
environment:
  # Required: External URL for Coder
  CODER_ACCESS_URL: http://localhost:3000
  
  # Database (if using PostgreSQL)
  CODER_PG_CONNECTION_URL: postgres://coder:password@postgres:5432/coder?sslmode=disable
  
  # Optional: Tunnel (for testing without domain)
  CODER_TUNNEL: true
  
  # Optional: Wildcard access URL (for workspace URLs)
  CODER_WILDCARD_ACCESS_URL: "*.coder.yourdomain.com"
  
  # Optional: Prometheus metrics
  CODER_PROMETHEUS_ENABLE: true
  CODER_PROMETHEUS_ADDRESS: "0.0.0.0:2112"
  
  # Optional: Logging
  CODER_VERBOSE: true
  CODER_LOG_HUMAN: true
```

Full config reference: https://coder.com/docs/admin/setup

---

## 🏗️ Create Your First Template

**Templates** define what kind of workspaces Coder can provision.

### Quick Start: Docker Template

1. **Log in to Coder** (http://localhost:3000)
2. Click **Templates** → **Create Template**
3. Choose **Docker** starter template
4. Customize (or use defaults)
5. Click **Create Template**

### Example: Simple Docker Workspace

Create a file `main.tf`:

```hcl
terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
    }
    docker = {
      source  = "kreuzwerker/docker"
    }
  }
}

provider "coder" {
}

provider "docker" {
}

data "coder_workspace" "me" {
}

resource "coder_agent" "main" {
  os   = "linux"
  arch = "amd64"
}

resource "docker_image" "main" {
  name = "codercom/code-server:latest"
}

resource "docker_container" "workspace" {
  image = docker_image.main.name
  name  = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
  env   = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]
  command = ["/bin/bash", "-c", coder_agent.main.init_script]
}
```

**Push to Coder:**
```bash
coder templates create docker-basic --directory ./
```

---

## 🖥️ Create a Workspace

1. Go to **Workspaces** → **New Workspace**
2. Select your template
3. Choose a name
4. Click **Create**
5. Wait for provisioning (~30s-2min)
6. Click **Open in VS Code** or **Terminal**

---

## 🌐 Remote Access Setup

### Option 1: Coder Tunnel (Easy, Testing Only)

Built-in cloudflare tunnel for quick access:

```yaml
environment:
  CODER_TUNNEL: true
```

Restart Coder → Check logs for tunnel URL:
```bash
docker compose logs coder | grep tunnel
# Output: https://random-id.coder.app
```

**Limitations:** Not for production, URL changes on restart.

### Option 2: Reverse Proxy (Production)

**Using Caddy (automatic HTTPS):**

```bash
# Install Caddy
sudo apt install caddy

# Configure /etc/caddy/Caddyfile
coder.yourdomain.com {
  reverse_proxy localhost:3000
}

# Restart Caddy
sudo systemctl restart caddy
```

**Using Nginx:**

```nginx
server {
    listen 80;
    server_name coder.yourdomain.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Then set:
```yaml
environment:
  CODER_ACCESS_URL: https://coder.yourdomain.com
```

### Option 3: Tailscale (Secure, No Port Forwarding)

```bash
# Install Tailscale on Coder host
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Access via Tailscale IP
CODER_ACCESS_URL: http://100.x.y.z:3000
```

---

## 🔐 Security Hardening

### 1. Change Default Passwords

```bash
# First login: use strong password for admin account
```

### 2. Enable HTTPS

**Always use HTTPS in production:**
- Use reverse proxy (Caddy/Nginx) with Let's Encrypt
- Or configure Coder TLS directly (see docs)

### 3. Restrict Access

**Firewall rules:**
```bash
# Only allow from specific IPs
sudo ufw allow from YOUR_IP to any port 3000
```

**Or use VPN/Tailscale** for zero-trust access.

### 4. Regular Updates

```bash
# Pull latest image
docker compose pull

# Restart
docker compose down && docker compose up -d
```

---

## 🛠️ Management Commands

### Docker Compose

```bash
# Start Coder
docker compose up -d

# Stop Coder
docker compose down

# View logs
docker compose logs -f coder

# Restart
docker compose restart

# Update to latest version
docker compose pull && docker compose up -d

# Access Coder shell
docker compose exec coder /bin/sh
```

### Coder CLI

```bash
# Login to Coder
coder login http://localhost:3000

# List workspaces
coder list

# SSH into workspace
coder ssh my-workspace

# Stop workspace
coder stop my-workspace

# Delete workspace
coder delete my-workspace

# List templates
coder templates list

# Create template from directory
coder templates create my-template --directory ./template
```

---

## 🐛 Troubleshooting

### Issue: Cannot access Coder at localhost:3000

**Check if running:**
```bash
docker compose ps
```

**Check logs:**
```bash
docker compose logs coder
```

**Common fix:** Ensure port 3000 is not in use:
```bash
sudo lsof -i :3000
```

### Issue: "Permission denied" connecting to Docker socket

**Fix:** Add user to docker group:
```bash
sudo usermod -aG docker $USER
newgrp docker
```

**Verify:**
```bash
docker ps
```

### Issue: Workspace stuck in "Connecting..."

**Problem:** CODER_ACCESS_URL not externally reachable.

**Fix:** Set correct access URL:
```yaml
environment:
  CODER_ACCESS_URL: http://YOUR_ACTUAL_IP:3000
```

### Issue: Docker-based workspace fails to provision

**Check:** Coder has docker.sock access:
```bash
docker compose exec coder ls -l /var/run/docker.sock
```

**Should show:** `srw-rw----` with docker group.

**Fix:** Update group_add in docker-compose.yaml.

### Issue: Database connection errors

**For PostgreSQL:**
```bash
# Check PostgreSQL is running
docker compose ps postgres

# Check connection string
docker compose exec coder env | grep CODER_PG
```

---

## 📊 Monitoring

### Built-in Metrics

Coder exposes Prometheus metrics:

```yaml
environment:
  CODER_PROMETHEUS_ENABLE: true
  CODER_PROMETHEUS_ADDRESS: "0.0.0.0:2112"
```

Access metrics:
```
http://localhost:2112/metrics
```

### Resource Usage

```bash
# Container stats
docker stats coder

# Disk usage
docker system df
```

---

## 🔄 Backup & Recovery

### Backup Database

**PostgreSQL:**
```bash
docker compose exec postgres pg_dump -U coder coder > coder-backup-$(date +%Y%m%d).sql
```

**SQLite:**
```bash
docker compose exec coder cp /home/coder/.config/coderv2.db /tmp/
docker cp coder:/tmp/coderv2.db ./coder-backup-$(date +%Y%m%d).db
```

### Backup Configuration

```bash
# Backup docker-compose.yaml
cp docker-compose.yaml docker-compose.yaml.backup

# Backup Coder data volume
docker run --rm -v coder_coder_data:/data -v $(pwd):/backup alpine tar czf /backup/coder-data-backup.tar.gz /data
```

### Restore Database

```bash
docker compose exec -T postgres psql -U coder coder < coder-backup-YYYYMMDD.sql
```

---

## 🚀 Next Steps

After setup:

1. **Create more templates** (Python, Node.js, Go, Kubernetes)
2. **Configure auto-stop** for idle workspaces (save resources)
3. **Set up Git integration** (GitHub/GitLab)
4. **Add team members** (if using)
5. **Explore template marketplace** (community templates)

---

## 📚 Resources

- **Official Docs:** https://coder.com/docs
- **Docker Install Guide:** https://coder.com/docs/install/docker
- **Template Examples:** https://github.com/coder/coder/tree/main/examples/templates
- **GitHub Repo:** https://github.com/coder/coder
- **Discord Community:** https://discord.gg/coder
- **Template Registry:** https://registry.coder.com

---

## 💡 Pro Tips

1. **Use template versioning** — git-track your templates
2. **Set resource limits** in templates (CPU/RAM caps)
3. **Enable workspace auto-stop** — e.g., after 4 hours idle
4. **Use dotfiles** — auto-configure new workspaces
5. **Pre-build images** — faster workspace starts
6. **Monitor costs** — if using cloud VMs (AWS/GCP)

---

## ⚠️ Common Gotchas

1. **macOS + Docker Desktop:** Limited functionality with docker.sock binding → use standalone binary
2. **Firewall rules:** Ensure 3000 accessible (or configured port)
3. **Access URL mismatch:** Must match how you access Coder externally
4. **Database persistence:** Use volumes or external PostgreSQL for production
5. **Docker group permissions:** Critical for Docker template provisioning

---

**Setup time:** 10-30 minutes  
**Difficulty:** Intermediate  
**Maintenance:** Low (mostly Docker updates)

---

*Happy coding in the cloud! 🦞*
