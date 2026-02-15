# Testing Your Dotfiles

## Local Testing (Before Pushing to Git)

### 1. Make install.sh Executable

```bash
cd C:\code\coder-notes\dotfiles-example
chmod +x install.sh
```

### 2. Run Installation Script

```bash
./install.sh
```

**Expected output:**
```
======================================
🎉 Hello from Dotfiles! 🎉
======================================
Timestamp: [current date/time]
User: [your username]
Hostname: [your hostname]
======================================

📂 Dotfiles directory: /path/to/dotfiles-example

📝 Setting up dotfiles...
🔗 Linking .bashrc -> ~/.bashrc
🔗 Linking .gitconfig -> ~/.gitconfig

🤖 Installing Google Gemini CLI...
📦 Installing google-generativeai package...
✅ Gemini CLI installed!

🧪 Testing Gemini installation...
✅ Gemini import successful!
✅ Gemini CLI is ready to use!

======================================
✨ Dotfiles setup complete! ✨
======================================

Next steps:
1. Restart your shell or run: source ~/.bashrc
2. Test Gemini: python3 -c 'import google.generativeai...'
3. Enjoy your personalized workspace!
```

### 3. Verify Installation

```bash
# Reload shell config
source ~/.bashrc

# Should see custom greeting:
# ======================================
# 🚀 Welcome to your Coder Workspace!
# ======================================
# 📅 [date]
# 🤖 Gemini CLI: v[version]
# ======================================

# Test Gemini
gemini_test

# Test aliases
ll         # Should work
gs         # Git status alias
```

---

## Testing in Coder Workspace

### Method 1: CLI

```bash
# SSH into Coder workspace
coder ssh my-workspace

# Apply dotfiles
coder dotfiles /path/to/dotfiles-example
# Or if hosted on GitHub:
# coder dotfiles https://github.com/yourusername/dotfiles-example

# Restart shell
exec bash

# Verify
gemini_test
```

### Method 2: Template (Automatic)

1. **Update your template** (`main.tf`) with dotfiles module:
   ```hcl
   module "dotfiles" {
     source   = "registry.coder.com/modules/dotfiles/coder"
     version  = "1.0.15"
     agent_id = coder_agent.main.id
   }
   ```

2. **Create new workspace** → Enter dotfiles URL when prompted

3. **Wait for provisioning** → Dotfiles apply automatically

4. **Connect to workspace** → Custom greeting should appear!

---

## Verification Checklist

- [ ] Hello world message appears during install
- [ ] `.bashrc` symlinked to home directory
- [ ] `.gitconfig` symlinked to home directory
- [ ] Gemini CLI installed successfully
- [ ] `gemini_test` command works
- [ ] Custom bash prompt shows (green user@host)
- [ ] Aliases work (`ll`, `gs`, etc.)
- [ ] Welcome message on shell startup

---

## Troubleshooting

### Issue: "Permission denied" running install.sh

**Fix:**
```bash
chmod +x install.sh
```

### Issue: Gemini import fails

**Check Python:**
```bash
python3 --version
pip3 --version
```

**Reinstall:**
```bash
pip3 install --user --upgrade google-generativeai
```

### Issue: Dotfiles not applied

**Check location:**
```bash
ls -la ~/
# Should see .bashrc and .gitconfig symlinks
```

**Manually re-link:**
```bash
ln -sf ~/dotfiles/.bashrc ~/.bashrc
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig
```

---

## Next Steps

1. **Push to GitHub:**
   ```bash
   cd dotfiles-example
   git init
   git add .
   git commit -m "Initial dotfiles"
   git remote add origin https://github.com/yourusername/dotfiles-example.git
   git push -u origin main
   ```

2. **Use in Coder:**
   - Add to template
   - Or use `coder dotfiles https://github.com/yourusername/dotfiles-example`

3. **Customize:**
   - Add more tools to `install.sh`
   - Customize `.bashrc` with your aliases
   - Update `.gitconfig` with your name/email
