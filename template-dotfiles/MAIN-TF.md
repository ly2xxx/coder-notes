# Main.tf Explanation

This `main.tf` file is a Coder template that defines a Docker-based development environment with specific support for **dotfiles** and **code-server**.

## Section-by-Section Breakdown

### 1. Terraform & Providers (Lines 1–10, 19–23)
```hcl
terraform {
  required_providers {
    coder = { source = "coder/coder" }
    docker = { source = "kreuzwerker/docker" }
  }
}

provider "docker" {}
provider "coder" {}
```
This blocks tell Terraform which plugins (providers) are needed. 
- **`coder`**: Used to interact with Coder's internal APIs (creating agents, apps, etc.).
- **`docker`**: Used to manage the Docker containers, images, and volumes on the host.

### 2. Locals & Data Sources (Lines 12–30)
```hcl
locals {
  username = data.coder_workspace_owner.me.name
}

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}
```
- **`locals`**: Sets a reusable `username` variable based on the Coder user.
- **`data` sources**: Fetch context about the current environment, such as the architecture (`arch`), the workspace name, and the user's email/name.

### 3. Dotfiles Module (Lines 32–36)
```hcl
module "dotfiles" {
  source   = "registry.coder.com/modules/dotfiles/coder"
  version  = "1.0.15"
  agent_id = coder_agent.main.id
}
```
This is a pre-built Coder module. It automatically handles cloning and installing a user's dotfiles (like `.bashrc` or `.vimrc`) into the workspace when it starts up.

### 4. Coder Agent (Lines 38–71)
The **`coder_agent`** is the heart of the workspace. It is a binary that runs inside the container and communicates back to Coder.

```hcl
resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os = "linux"
  startup_script = <<-EOT
    set -e

    # install and start code-server
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server
    /tmp/code-server/bin/code-server --auth none --port 3000 >/tmp/code-server.log 2>&1 &
  EOT

  env = {
    GIT_AUTHOR_NAME = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL = "${data.coder_workspace_owner.me.email}"
    GIT_COMMITTER_NAME = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL = "${data.coder_workspace_owner.me.email}"
  }

  metadata {
    display_name = "CPU Usage"
    key = "0_cpu_usage"
    script = "coder stat cpu"
    interval = 10
    timeout = 1
  }

  metadata {
    display_name = "RAM Usage"
    key = "1_ram_usage"
    script = "coder stat mem"
    interval = 10
    timeout = 1
  }
}
```

- **`startup_script`**: Installs `code-server` (VS Code in the browser) in a standalone mode and starts it on port 3000.
- **`env`**: Injects Git configuration (name and email) so the user is ready to commit code immediately.
- **`metadata`**: Adds real-time monitoring to the Coder dashboard for CPU and RAM usage.

### 5. Coder Apps (Lines 73–95)
```hcl
resource "coder_app" "code-server" {
  url = "http://localhost:3000/?folder=/home/${local.username}"
  # ... healthcheck ...
}
```
These resources create buttons in the Coder UI:
- **`code-server`**: A direct link to the VS Code web interface.
- **`coder-server-doc`**: An external link to documentation.
The `healthcheck` ensures the "Open" button only appears once the server is actually responding.

### 6. Docker Resources (Lines 97–116)
```hcl
resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.id}-home"
  # Protect the volume from being deleted due to changes in attributes.
  lifecycle {
    ignore_changes = all
  }
}

resource "docker_image" "main" {
  name = "coder-${data.coder_workspace.me.id}"
  build {
    context = "./build"
    build_args = {
      USER = local.username
    }
  }
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "build/*") : filesha1(f)]))
  }
}
```

- **`docker_volume`**: Creates a persistent volume named after the workspace ID. This ensures your files in `/home` survive if the container is deleted or restarted.
- **`docker_image`**: Builds a custom image using the `./build/Dockerfile`. It uses a `sha1` trigger so that the image is automatically rebuilt whenever files in the `build/` directory change.

### 7. Docker Container (Lines 118–139)
This is the final step where everything comes together to run the container.

```hcl
resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = docker_image.main.name
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = data.coder_workspace.me.name
  # Use the docker gateway if the access URL is 127.0.0.1
  entrypoint = ["sh", "-c", replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]
  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
  ]
  host {
    host = "host.docker.internal"
    ip = "host-gateway"
  }
  volumes {
    container_path = "/home/${local.username}"
    volume_name = docker_volume.home_volume.name
    read_only = false
  }
}
```

- **`count`**: Controlled by `data.coder_workspace.me.start_count`. If the workspace is stopped in the UI, the container is destroyed; if started, it's recreated.
- **`entrypoint`**: Runs the Coder Agent's init script, which connects the container to the Coder control plane.
- **`volumes`**: Mounts the persistent home volume to `/home/${username}`.
- **`host`**: Maps `host.docker.internal` so the container can reach services running on the Docker host if necessary.

