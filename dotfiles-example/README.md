# Sample Dotfiles Repository

**Purpose:** Example dotfiles repo for Coder workspace personalization.

## What This Does

When applied to a Coder workspace, this dotfiles repo will:

1. ✅ Print a hello world message
2. ✅ Install Gemini CLI (Google's AI CLI tool)
3. ✅ Apply custom shell configs (.bashrc)
4. ✅ Set up Git config (.gitconfig)

## How to Use

### Option 1: With Coder CLI

```bash
# In your Coder workspace
coder dotfiles https://github.com/yourusername/dotfiles-example

# Or if testing locally
./install.sh
```

### Option 2: With Coder Template

Add this to your template `main.tf`:

```hcl
module "dotfiles" {
  source   = "registry.coder.com/modules/dotfiles/coder"
  version  = "1.0.15"
  agent_id = coder_agent.main.id
}
```

When creating a workspace, paste your dotfiles repo URL when prompted.

### Option 3: Via ~/personalize Script

Create `~/personalize` in your workspace:

```bash
#!/bin/bash
coder dotfiles https://github.com/yourusername/dotfiles-example
```

## Files Included

- `install.sh` - Main setup script (runs automatically)
- `.bashrc` - Custom bash configuration
- `.gitconfig` - Git settings
- `README.md` - This file

## Testing Locally

```bash
cd dotfiles-example
chmod +x install.sh
./install.sh
```

Expected output:
- Hello world message with timestamp
- Gemini CLI installed
- Dotfiles symlinked to home directory

## Customization

Fork this repo and modify:
- Add your own tools to `install.sh`
- Customize `.bashrc` with aliases
- Update `.gitconfig` with your name/email

## Resources

- [Dotfiles Guide](https://dotfiles.github.io/)
- [Coder Dotfiles Docs](https://coder.com/docs/user-guides/workspace-dotfiles)
- [Gemini CLI Repo](https://github.com/google-gemini/generative-ai-python)
