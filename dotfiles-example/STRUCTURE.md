# Dotfiles Example - File Structure

```
dotfiles-example/
├── README.md           # Overview and usage instructions
├── TESTING.md          # Step-by-step testing guide
├── STRUCTURE.md        # This file - explains the structure
├── install.sh          # Main installation script (runs automatically)
├── .bashrc             # Custom bash configuration
└── .gitconfig          # Git configuration

```

## File Descriptions

### `install.sh` ⭐ (Auto-runs)
**Purpose:** Main setup script that Coder runs automatically

**What it does:**
1. Prints hello world message with timestamp
2. Symlinks `.bashrc` and `.gitconfig` to home directory
3. Installs Python3 (if missing)
4. Installs Gemini CLI (`google-generativeai`)
5. Tests the installation
6. Shows next steps

**Exit codes:**
- `0` = Success
- `1` = Error (missing dependencies, install failed)

---

### `.bashrc`
**Purpose:** Custom shell configuration

**Features:**
- Colorful prompt (green user@host)
- Useful aliases (`ll`, `gs`, `gc`, etc.)
- Custom greeting on shell startup
- Shows Gemini CLI version
- Helper function `gemini_test` to verify installation
- `dotfiles_info` command for info

**Loads automatically** when you start a shell in the workspace.

---

### `.gitconfig`
**Purpose:** Git configuration settings

**Settings:**
- User name/email (placeholder - update with yours)
- Default editor (vim)
- Color settings (auto)
- Useful git aliases (`st`, `co`, `br`, `lg`)
- Default branch: `main`

---

### `README.md`
**Purpose:** Documentation for users

**Sections:**
- What this does
- How to use (3 methods)
- Files included
- Testing instructions
- Customization guide

---

### `TESTING.md`
**Purpose:** Step-by-step testing guide

**Sections:**
- Local testing (before Coder)
- Testing in Coder workspace
- Verification checklist
- Troubleshooting
- Next steps (push to GitHub)

---

## How Coder Uses These Files

### 1. Automatic Discovery
When you run `coder dotfiles <repo>`, Coder:
1. Clones the repo
2. Looks for an install script in this order:
   - `install.sh` ✅ (we have this)
   - `install`
   - `bootstrap.sh`
   - `bootstrap`
   - `script/bootstrap`
   - `setup.sh`
   - `setup`
   - `script/setup`

3. Runs the **first match** it finds

### 2. Install Script Requirements
- Must be **executable** (`chmod +x install.sh`)
- Should be **idempotent** (safe to run multiple times)
- Should **exit 0** on success
- Should handle **missing dependencies** gracefully

### 3. Symlink Pattern
```bash
ln -sf /path/to/dotfiles/.bashrc ~/.bashrc
```
- `-s` = symbolic link
- `-f` = force (overwrite if exists)
- Links dotfile → home directory

---

## Customization Guide

### Add More Tools

Edit `install.sh`:
```bash
# Add after Gemini installation
echo "🛠️ Installing [your tool]..."
# Add your commands here
```

### Add More Dotfiles

1. Create new dotfile (e.g., `.vimrc`)
2. Add to `install.sh`:
   ```bash
   link_file "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
   ```

### Change Aliases

Edit `.bashrc`:
```bash
# Add your custom aliases
alias myalias='command'
```

---

## Quick Start

```bash
# 1. Make executable
chmod +x install.sh

# 2. Test locally
./install.sh

# 3. Push to GitHub
git init
git add .
git commit -m "My dotfiles"
git remote add origin https://github.com/yourusername/dotfiles.git
git push -u origin main

# 4. Use in Coder
coder dotfiles https://github.com/yourusername/dotfiles
```

---

**Ready to use! 🚀**
