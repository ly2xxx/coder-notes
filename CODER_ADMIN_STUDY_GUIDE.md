# Coder Admin Study Guide

**Version:** 2026.02.15  
**Your Deployment:** https://test.pit-1.try.coder.app  
**Your Workspace:** aqua-wildebeest-88  

---

## 📚 Study Plan Overview

This guide covers essential Coder admin features and concepts for day-to-day learning and mastery.

**Recommended Study Order:**
1. Core Concepts (30 min) — Understand the mental model
2. Admin Dashboard Tour (30 min) — Navigate the UI
3. Templates Deep Dive (1-2 hours) — Master workspace provisioning
4. User Management (30 min) — Control access and quotas
5. Advanced Features (1-2 hours) — Automation, monitoring, scaling

---

## 🎯 Core Concepts (Study First!)

### The Coder Mental Model

**Hierarchy:**
```
Coder Deployment (Control Plane)
  ├── Users (Developers)
  ├── Templates (Infrastructure Definitions)
  │   ├── Base Image (OS + packages)
  │   ├── Startup Scripts (Provisioning logic)
  │   └── Resource Definitions (Docker, K8s, VMs)
  └── Workspaces (User Instances)
      ├── One per user per template
      ├── Fully isolated environments
      └── Connect via VS Code / Terminal / JetBrains
```

### Key Terms

| Term | What It Is | Who Manages It |
|------|------------|----------------|
| **Base Image** | Docker/container image with OS + tools | External (Docker Hub, your registry) |
| **Template** | Infrastructure definition (Terraform) | Template Admins |
| **Startup Script** | Commands run when workspace starts | Template Admins |
| **Workspace** | Running dev environment for one user | End Users (Developers) |
| **Dev Container** | VCS-tracked devcontainer.json spec | Dev Teams |
| **Dotfiles** | Personal shell/editor configs | Individual Users |

**Example Flow:**
1. Admin creates a "Python Dev" template (base image: `python:3.11`, startup script: install Poetry)
2. User creates workspace "my-python-project" from that template
3. Coder provisions a Docker container with the defined specs
4. User connects via VS Code and starts coding
5. User stops workspace when done (saves resources)

---

## 🖥️ Admin Dashboard Tour

### Main Navigation Areas

Access your deployment: **https://test.pit-1.try.coder.app**

#### 1. **Workspaces** (User View)
- See all your workspaces
- Create new from templates
- Start/stop/delete workspaces
- Connect via Terminal, VS Code, SSH

**Try Now:**
- Visit your workspace: `@ly2xxx/aqua-wildebeest-88`
- Click "Terminal" → opens web-based terminal
- Click "VS Code Desktop" → opens local VS Code connected to workspace
- Explore the "Resources" tab → see Docker container details

#### 2. **Templates** (Admin View) - https://coder.com/docs/@v2.30.1/tutorials/template-from-scratch 
- **Location:** Top nav → Templates
- Create/edit/version templates
- See template usage stats
- Set default parameters
- Configure auto-stop timers

**Try Now:**
- Click "Templates" → see the template used for `aqua-wildebeest-88`
- Click template name → view README, parameters, versions
- Click "Edit" → see the Terraform code

#### 3. **Users** (Admin View)
- **Location:** Top nav → Deployment → Users
- Add/remove users
- Assign roles (Admin, Template Admin, Member)
- Set quotas (budget limits)
- Suspend/activate accounts

**Try Now:**
- Go to Deployment → Users
- See your admin account
- Click "Create User" → understand the process (don't create yet)

#### 4. **Audit Log** (Admin View)
- **Location:** Deployment → Audit
- Track all actions (workspace created, template updated, user login)
- Filter by user, action type, date
- Export for compliance

**Try Now:**
- Go to Deployment → Audit
- Filter by "workspace" actions
- See when your workspace was created

#### 5. **Deployment Settings** (Admin View)
- **Location:** Deployment → Settings (gear icon)
- Access URL configuration
- Authentication (OAuth, OIDC, SAML)
- Workspace proxy settings
- Experiments/feature flags

**Try Now:**
- Go to Deployment → Settings
- Review current Access URL (should show tunnel URL)
- Check Authentication settings (local for now)

---

## 🏗️ Templates Deep Dive

### What is a Template?

**A template is Terraform code** that defines:
1. What infrastructure to provision (Docker container, K8s pod, EC2 instance)
2. What base image to use
3. What startup scripts to run
4. What parameters users can customize

### Anatomy of a Template

**Example: Docker-based Python Template**

```hcl
# main.tf (simplified)

terraform {
  required_providers {
    coder = { source = "coder/coder" }
    docker = { source = "kreuzwerker/docker" }
  }
}

# Define the Coder agent (runs inside workspace)
resource "coder_agent" "main" {
  os   = "linux"
  arch = "amd64"
  
  # Startup script (runs on every start)
  startup_script = <<-EOT
    #!/bin/bash
    pip install --upgrade pip poetry
    code-server --install-extension ms-python.python
  EOT
}

# Docker image to use
resource "docker_image" "python" {
  name = "python:3.11-slim"
}

# Docker container (the workspace)
resource "docker_container" "workspace" {
  image = docker_image.python.name
  name  = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
  
  # Inject Coder agent
  env = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]
  command = ["/bin/bash", "-c", coder_agent.main.init_script]
}
```

### Template Components

1. **Providers:** What infrastructure backend (Docker, Kubernetes, AWS, etc.)
2. **Parameters:** User-configurable options (RAM, CPU, disk size)
3. **Resources:** Actual infrastructure (containers, VMs, volumes)
4. **Agent:** Coder's connection agent (runs inside workspace)
5. **Metadata:** Display name, description, icon

### Template Parameters

**Allow users to customize their workspace:**

```hcl
data "coder_parameter" "cpu_cores" {
  name        = "cpu_cores"
  description = "CPU cores for workspace"
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

**User sees dropdown when creating workspace.**

### Template Versioning

**Every template edit creates a new version:**
- Users can upgrade their workspace to latest version
- Or stay on older version (if needed)
- Track changes via Git

**Try Now:**
1. Go to Templates → [Your template]
2. Click "Versions" tab
3. See version history
4. Click a version → view Terraform diff

### Template Best Practices

✅ **DO:**
- Use semantic versioning (v1.0.0, v1.1.0)
- Add README.md with usage instructions
- Set default auto-stop timer (e.g., 8 hours)
- Use `.terraform.lock.hcl` for reproducibility
- Test template changes before pushing to prod

❌ **DON'T:**
- Hardcode secrets (use Coder parameters or external secrets)
- Create templates without resource limits
- Skip startup script documentation
- Use `:latest` tags (pin versions!)

---

## 👥 User Management

### User Roles

| Role | Permissions |
|------|-------------|
| **Admin** | Full access (users, templates, settings, audit) |
| **Template Admin** | Create/edit templates, view usage |
| **Member** | Create/manage own workspaces, use templates |
| **Auditor** | Read-only access to audit logs |

### Creating Users

**Two methods:**

#### 1. Manual Creation (Small Teams)
- Deployment → Users → Create User
- Set username, email, password
- Assign role
- User receives invitation email

#### 2. OAuth/SAML (Enterprise)
- Configure GitHub/Google/Azure AD
- Users auto-provision on first login
- No manual account creation needed

**Try Now:**
1. Go to Deployment → Users → Create User
2. Don't actually create (unless needed)
3. Note the role dropdown

### Quotas (Budget Control)

**Quotas prevent runaway costs** by assigning budgets to users.

**How it works:**
1. Admin assigns "cost" to each template (e.g., 100 credits/day)
2. Admin assigns quota to user/group (e.g., 500 credits/day)
3. User can't exceed their daily budget

**Example:**
- Template "Python Dev" costs 10 credits/hour
- User quota: 80 credits/day
- User can run workspace max 8 hours/day

**Configure Quotas:**
1. Deployment → Users → [Select User]
2. Click "Quota" tab
3. Set daily allowance
4. User sees warning when approaching limit

**Try Now:**
1. Go to Deployment → Users → [Your user]
2. Check if quota is set (likely unlimited for admin)

---

## 🔐 Authentication & Security

### Auth Methods

| Method | Best For | Setup Difficulty |
|--------|----------|------------------|
| **Built-in** | Testing, small teams | Easy |
| **OAuth (GitHub)** | Teams using GitHub | Medium |
| **Google OAuth** | G Suite orgs | Medium |
| **OIDC** | Enterprise SSO | Hard |
| **SAML** | Enterprise (Okta, Azure AD) | Hard |

### Setting Up OAuth (GitHub Example)

**Steps:**
1. Create GitHub OAuth App
   - Go to GitHub → Settings → Developer → OAuth Apps → New
   - Homepage URL: `https://test.pit-1.try.coder.app`
   - Callback URL: `https://test.pit-1.try.coder.app/api/v2/users/oauth2/github/callback`
   - Get Client ID + Secret

2. Configure Coder
   - Deployment → Settings → OAuth
   - Add GitHub provider
   - Paste Client ID + Secret
   - Save

3. Users can now login with "Sign in with GitHub"

**Try Later:** (Requires production URL, not tunnel)

### Security Best Practices

✅ **Enable:**
- OAuth/SAML for production
- Audit logging (already enabled)
- Workspace auto-stop (save resources + costs)
- Template approval workflow (review before publish)

✅ **Restrict:**
- Docker socket access (only trusted templates)
- Sudo permissions in workspaces (if possible)
- Public workspace access (use VPN/Tailscale)

✅ **Monitor:**
- Audit logs for suspicious activity
- Resource usage (prevent crypto mining)
- Template changes (review commits)

---

## 📊 Monitoring & Insights

### Built-in Metrics

**Deployment → Insights**

Track:
- Active users (daily/weekly/monthly)
- Workspace starts/stops
- Template usage
- Connection time (how long users stay connected)
- Resource utilization

**Use Case:** Justify Coder investment to leadership
- "Developers save 30 min/day on environment setup"
- "99.5% workspace uptime"

### Prometheus Metrics

**For advanced monitoring:**

If you enabled Prometheus during setup:
```yaml
environment:
  CODER_PROMETHEUS_ENABLE: true
  CODER_PROMETHEUS_ADDRESS: "0.0.0.0:2112"
```

Access metrics: `http://localhost:2112/metrics`

**Key metrics:**
- `coder_workspaces_total` — Total workspaces
- `coder_workspace_builds_total` — Build success/failure
- `coder_workspace_connection_latency_seconds` — User experience

**Try Now:**
1. If Prometheus enabled, visit metrics URL
2. Search for `coder_` metrics
3. Set up Grafana dashboard (optional)

### Logs

**Access logs:**
```bash
# If running as server
coder server --verbose

# Or check deployment logs
Deployment → Logs (if available in UI)
```

**What to monitor:**
- Template build failures
- User authentication errors
- Resource provisioning issues

---

## 🛠️ CLI Automation

### Coder CLI

**You already have it installed:**
```bash
coder version
# Coder v2.30.1
```

### Common Admin Tasks

#### 1. Login to Deployment
```bash
coder login https://test.pit-1.try.coder.app
# Follow prompts to generate token
```

#### 2. List Templates
```bash
coder templates list
```

#### 3. Create Template from Directory
```bash
cd my-template/
coder templates create python-dev --directory .
```

#### 4. Update Template
```bash
coder templates push python-dev --directory .
```

#### 5. List All Workspaces (Admin)
```bash
coder list --all
# Shows ALL users' workspaces
```

#### 6. SSH into Any Workspace (Admin)
```bash
coder ssh username/workspace-name
```

#### 7. Create User (Scripting)
```bash
coder users create \
  --username alice \
  --email alice@example.com \
  --password temp123
```

#### 8. Assign Quota
```bash
coder users update alice --quota 1000
```

### Template Development Workflow

**Best practice:**
```bash
# 1. Create template directory
mkdir my-template && cd my-template

# 2. Write Terraform
vim main.tf

# 3. Test locally (dry-run)
coder templates create my-template --directory . --dry-run

# 4. Push to Coder
coder templates create my-template --directory .

# 5. Create test workspace
coder create test-workspace --template my-template

# 6. Verify, then update
coder templates push my-template --directory .
```

**Try Now:**
1. Login to your deployment via CLI
2. Run `coder list` to see your workspace
3. Try `coder ssh aqua-wildebeest-88` (connects to workspace terminal!)

---

## 🚀 Advanced Features

### 1. Workspace Auto-Stop

**Save resources when idle:**

In template `main.tf`:
```hcl
resource "coder_workspace" "me" {}

resource "coder_autostop" "eight_hours" {
  workspace_id = coder_workspace.me.id
  duration     = "8h"
}
```

**Users can override:** Deployment → Settings → Max TTL

**Try Now:**
1. Edit a template
2. Add autostop resource
3. Create workspace → see auto-stop timer

### 2. Dotfiles Support

**Auto-apply user dotfiles on workspace creation:**

Users add dotfiles repo in: Profile → Dotfiles

Coder runs:
```bash
git clone <dotfiles-repo>
./install.sh  # or other setup script
```

**Use cases:**
- Shell aliases (`.bashrc`)
- Vim config (`.vimrc`)
- Git config (`.gitconfig`)

**Try Now:**
1. Profile → Dotfiles
2. Add a GitHub repo with dotfiles
3. Create new workspace → dotfiles auto-applied

### 3. Dev Containers Support

**Coder can use `.devcontainer/devcontainer.json`:**

```json
{
  "name": "Python Dev",
  "image": "python:3.11",
  "postCreateCommand": "pip install -r requirements.txt",
  "customizations": {
    "vscode": {
      "extensions": ["ms-python.python"]
    }
  }
}
```

**Coder template reads this and provisions accordingly.**

### 4. Workspace Proxies

**For distributed teams:**

Deploy Coder proxies in multiple regions:
- US East
- EU West
- Asia Pacific

**Users connect to nearest proxy** → lower latency.

**Advanced:** Requires additional infrastructure.

### 5. Git Integration

**Auto-clone repos on workspace creation:**

In template:
```hcl
resource "coder_agent" "main" {
  startup_script = <<-EOT
    git clone https://github.com/yourorg/repo.git ~/project
    cd ~/project
    npm install
  EOT
}
```

**Or use Coder parameters** for dynamic repo URL.

### 6. Prebuilt Workspaces

**Reduce workspace start time:**

Instead of building on-demand:
1. Coder pre-builds workspace image
2. User starts workspace instantly (from cache)

**Use case:** Large Docker images (5+ GB), slow builds

**Setup:** Requires Premium plan + prebuild configuration.

---

## 🎓 Learning Path (Hands-On)

### Week 1: Foundations
- [ ] Explore your workspace (`aqua-wildebeest-88`)
  - Connect via Terminal
  - Connect via VS Code
  - Stop/Start workspace
- [ ] Review the template used
  - Read Terraform code
  - Understand resource definitions
- [ ] Browse Admin Dashboard
  - Users, Templates, Audit, Settings
- [ ] Install Coder CLI
  - `coder login`
  - `coder list`
  - `coder ssh <workspace>`

### Week 2: Template Mastery
- [ ] Create your first template
  - Use Docker provider
  - Add startup script (install tools)
  - Add parameter (CPU cores)
- [ ] Version your template
  - Make a change
  - Push new version
  - Upgrade workspace to new version
- [ ] Add autostop to template
  - Set 8-hour limit
  - Test auto-stop behavior

### Week 3: User Management
- [ ] Create a test user
  - Assign "Member" role
  - Set quota (100 credits/day)
- [ ] Test user experience
  - Login as test user
  - Create workspace
  - Hit quota limit
- [ ] Review audit logs
  - Track test user actions

### Week 4: Advanced Features
- [ ] Set up dotfiles support
  - Create dotfiles repo
  - Test auto-provisioning
- [ ] Explore workspace proxies (read docs)
- [ ] Set up Prometheus monitoring
  - Enable metrics
  - Create Grafana dashboard
- [ ] Automate with CLI
  - Script template updates
  - Script user creation

---

## 📖 Reference Links

### Official Docs
- **Admin Guide:** https://coder.com/docs/admin
- **Templates:** https://coder.com/docs/admin/templates
- **User Management:** https://coder.com/docs/admin/users
- **Quotas:** https://coder.com/docs/admin/users/quotas
- **CLI Reference:** https://coder.com/docs/reference/cli
- **API Docs:** https://coder.com/docs/reference/api

### Template Examples
- **GitHub Repo:** https://github.com/coder/coder/tree/main/examples/templates
- **Community Templates:** https://registry.coder.com

### Support
- **Discord:** https://discord.gg/coder
- **GitHub Issues:** https://github.com/coder/coder/issues
- **Discussions:** https://github.com/coder/coder/discussions

---

## ❓ Common Questions

### Q: Can I use Kubernetes instead of Docker?
**A:** Yes! Coder supports Kubernetes, AWS EC2, GCP VMs, Azure VMs. Template uses different Terraform provider.

### Q: How much does Coder cost?
**A:** Open-source version is **free forever**. Premium adds multi-org, custom roles, prebuilds. See pricing: https://coder.com/pricing

### Q: Can workspaces access the internet?
**A:** Yes (unless you restrict with firewall/network policies).

### Q: Can I use Coder offline (air-gapped)?
**A:** Yes, with proper setup. See docs: https://coder.com/docs/admin/setup/offline

### Q: How do I back up Coder?
**A:** Backup PostgreSQL database + template Git repos. See setup guide's backup section.

### Q: Can I use Coder with my own domain?
**A:** Yes! Set `CODER_ACCESS_URL=https://coder.yourdomain.com` and configure reverse proxy (Caddy/Nginx).

---

## 🎯 Daily Practice Tips

**Spend 15-30 min/day:**
1. **Morning:** Create a new workspace → try a different template
2. **Afternoon:** Edit a template → add a new tool to startup script
3. **Evening:** Review audit logs → see what actions happened today

**Weekly:**
- Read one template example from GitHub
- Watch a Coder YouTube tutorial
- Ask a question in Discord

**Monthly:**
- Create a new template from scratch
- Write a blog post about your Coder workflow
- Contribute to Coder docs (fix typos, add examples)

---

**Good luck with your Coder learning journey! 🚀**

*Last updated: 2026-02-15*
