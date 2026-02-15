# Coder Admin Quick Reference

**Your Deployment:** https://test.pit-1.try.coder.app  
**Local Server:** http://127.0.0.1:3000  

---

## 🚀 Quick Start Commands

### Start Coder Server
```bash
coder server
# Access at http://127.0.0.1:3000
# Or tunnel URL (shown in logs)
```

### Login to Deployment
```bash
coder login https://test.pit-1.try.coder.app
# Follow prompts to create session token
```

---

## 📋 Common CLI Tasks

### Templates
```bash
# List all templates
coder templates list

# Create template from directory
coder templates create my-template --directory ./my-template

# Update existing template
coder templates push my-template --directory ./my-template

# Delete template
coder templates delete my-template

# View template versions
coder templates versions list my-template
```

### Workspaces
```bash
# List your workspaces
coder list

# List ALL workspaces (admin)
coder list --all

# Create workspace
coder create my-workspace --template python-dev

# Start workspace
coder start my-workspace

# Stop workspace
coder stop my-workspace

# Delete workspace
coder delete my-workspace

# SSH into workspace
coder ssh my-workspace

# SSH into someone else's workspace (admin)
coder ssh username/workspace-name

# Execute command in workspace
coder ssh my-workspace -- ls -la

# Port forward from workspace
coder port-forward my-workspace --tcp 8080:8080
```

### Users
```bash
# List users
coder users list

# Create user
coder users create --username alice --email alice@example.com --password temp123

# Update user role
coder users update alice --role template-admin

# Set quota
coder users update alice --quota 1000

# Suspend user
coder users suspend alice

# Activate user
coder users activate alice

# Delete user
coder users delete alice
```

### Organizations (Premium)
```bash
# List organizations
coder organizations list

# Create organization
coder organizations create data-platform

# Add user to org
coder organizations members add data-platform alice
```

---

## 🌐 Web UI Navigation

### Admin Dashboard Routes

| Feature | URL Path |
|---------|----------|
| Workspaces | `/workspaces` |
| Templates | `/templates` |
| Users | `/deployment/users` |
| Audit Logs | `/deployment/audit` |
| Settings | `/deployment/general` |
| Your Profile | `/settings/account` |
| Insights | `/deployment/insights` |

**Quick Access:**
```
https://test.pit-1.try.coder.app/templates
https://test.pit-1.try.coder.app/deployment/users
https://test.pit-1.try.coder.app/deployment/audit
```

---

## 🛠️ Template Development

### Minimal Docker Template
```hcl
# main.tf
terraform {
  required_providers {
    coder = { source = "coder/coder" }
    docker = { source = "kreuzwerker/docker" }
  }
}

provider "docker" {}
provider "coder" {}

data "coder_workspace" "me" {}

resource "coder_agent" "main" {
  os   = "linux"
  arch = "amd64"
  
  startup_script = <<-EOT
    #!/bin/bash
    echo "Workspace ready!"
  EOT
}

resource "docker_image" "main" {
  name = "codercom/code-server:latest"
}

resource "docker_container" "workspace" {
  image = docker_image.main.name
  name  = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
  
  env = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]
  command = ["/bin/bash", "-c", coder_agent.main.init_script]
}
```

### Template with Parameters
```hcl
data "coder_parameter" "cpu_cores" {
  name        = "cpu_cores"
  description = "CPU cores"
  default     = "2"
  mutable     = true
  
  option {
    name  = "2 cores"
    value = "2"
  }
  option {
    name  = "4 cores"
    value = "4"
  }
}

resource "docker_container" "workspace" {
  # ...
  cpu_set = data.coder_parameter.cpu_cores.value
}
```

### Auto-Stop Configuration
```hcl
resource "coder_workspace" "me" {}

resource "coder_autostop" "default" {
  workspace_id = coder_workspace.me.id
  duration     = "8h"  # Stop after 8 hours
}
```

---

## ⚙️ Configuration

### Environment Variables

**Key settings for `coder server`:**

```bash
# Access URL (required for remote access)
export CODER_ACCESS_URL=https://coder.yourdomain.com

# Database (defaults to built-in PostgreSQL)
export CODER_PG_CONNECTION_URL=postgresql://user:pass@host:5432/coder

# Disable tunnel (use own domain)
export CODER_TUNNEL=false

# Wildcard access for workspace URLs
export CODER_WILDCARD_ACCESS_URL="*.coder.yourdomain.com"

# Prometheus metrics
export CODER_PROMETHEUS_ENABLE=true
export CODER_PROMETHEUS_ADDRESS="0.0.0.0:2112"

# Verbose logging
export CODER_VERBOSE=true
```

### Config File Location
```
Windows: ~user\AppData\Roaming\coderv2\
Linux: ~/.config/coderv2/
macOS: ~/Library/Application Support/coderv2/
```

---

## 🔐 Authentication Setup

### GitHub OAuth
1. Create OAuth App at: https://github.com/settings/developers
2. Set URLs:
   - Homepage: `https://test.pit-1.try.coder.app`
   - Callback: `https://test.pit-1.try.coder.app/api/v2/users/oauth2/github/callback`
3. Get Client ID + Secret
4. In Coder: Deployment → Settings → OAuth → Add GitHub
5. Paste credentials, save

### Google OAuth
Similar process via: https://console.cloud.google.com/apis/credentials

---

## 📊 Monitoring

### Prometheus Metrics Endpoint
```
http://localhost:2112/metrics
```

**Key metrics:**
- `coder_workspaces_total`
- `coder_workspace_builds_total{status="success"}`
- `coder_workspace_connection_latency_seconds`
- `coder_provisioner_job_timings_ms`

### Logs
```bash
# Server logs (if running as CLI)
coder server --verbose

# Workspace build logs
coder list --all  # Find workspace
# View in UI: Workspace → Builds tab
```

---

## 🚨 Troubleshooting

### Workspace Won't Start
```bash
# Check build logs
# In UI: Workspace → Builds → Latest build → View logs

# Rebuild workspace
coder restart my-workspace --build

# Delete and recreate
coder delete my-workspace
coder create my-workspace --template my-template
```

### Template Build Fails
```bash
# Dry-run template (test without creating)
coder templates create test --directory . --dry-run

# Check Terraform syntax
cd my-template
terraform init
terraform validate
```

### Can't Connect to Workspace
```bash
# Check agent status
coder ssh my-workspace -- coder agent --version

# Test connectivity
coder ping my-workspace

# Check tunnel status (if using)
# Look for "Using tunnel" in server logs
```

### Database Issues
```bash
# Check database connection
# In UI: Deployment → Settings → General → Database

# Backup database (PostgreSQL)
pg_dump -U coder coder > backup.sql

# Restore
psql -U coder coder < backup.sql
```

---

## 🎯 Daily Admin Checklist

### Morning (5 min)
- [ ] Check server status (`coder server` running?)
- [ ] Review overnight audit logs (any suspicious activity?)
- [ ] Check resource usage (any workspaces left running?)

### Ongoing
- [ ] Monitor template builds (any failures?)
- [ ] Respond to user requests (quota increases, access issues)
- [ ] Review new template changes (if team is pushing updates)

### Weekly (30 min)
- [ ] Review Insights dashboard (user engagement trends)
- [ ] Update base images (security patches)
- [ ] Clean up orphaned workspaces (deleted users)
- [ ] Backup database

### Monthly
- [ ] Review quotas (adjust based on usage)
- [ ] Audit user roles (remove inactive users)
- [ ] Update Coder version (check release notes)
- [ ] Review template library (archive unused templates)

---

## 🔗 Quick Links

| Resource | URL |
|----------|-----|
| **Your Deployment** | https://test.pit-1.try.coder.app |
| **Your Workspace** | https://test.pit-1.try.coder.app/@ly2xxx/aqua-wildebeest-88 |
| **Templates** | https://test.pit-1.try.coder.app/templates |
| **Users** | https://test.pit-1.try.coder.app/deployment/users |
| **Audit** | https://test.pit-1.try.coder.app/deployment/audit |
| **Docs** | https://coder.com/docs |
| **CLI Ref** | https://coder.com/docs/reference/cli |
| **Template Examples** | https://github.com/coder/coder/tree/main/examples/templates |
| **Discord** | https://discord.gg/coder |

---

## 💡 Pro Tips

1. **Use CLI for bulk operations** — Web UI is great for single tasks, CLI for automation
2. **Version templates in Git** — Track changes, enable rollbacks
3. **Test templates with dry-run** — Catch errors before users see them
4. **Set conservative quotas initially** — Easier to increase than explain overages
5. **Enable auto-stop globally** — Saves resources, users can override if needed
6. **Use workspace proxies** — If team is distributed globally
7. **Document template README** — Users will thank you
8. **Monitor audit logs** — Catch issues early
9. **Backup regularly** — PostgreSQL database is your source of truth
10. **Join Discord** — Community is helpful and responsive

---

**Last updated: 2026-02-15**
