# Using Dotfiles from a Subfolder

**Problem:** Coder expects dotfiles at repository root, but you want them in a subfolder of an existing repo.

**Solution:** Use a wrapper `install.sh` at the root that delegates to your subfolder.

---

## Repository Structure

```
my-configs/                        (github.com/yourusername/my-configs)
├── install.sh                     ← Wrapper (at root, for Coder)
├── dotfiles/                      ← Your actual dotfiles
│   ├── .bashrc
│   ├── .gitconfig
│   └── setup.sh                   ← Real install script
├── scripts/
├── notes/
└── other-stuff/
```

---

## Wrapper Script (install.sh at root)

Create `install.sh` at the **repository root**:

```bash
#!/bin/bash
#
# Wrapper script for Coder dotfiles
# Delegates to actual dotfiles in the 'dotfiles' subfolder
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

echo "🔄 Coder Dotfiles Wrapper"
echo "   Repository: $SCRIPT_DIR"
echo "   Dotfiles location: $DOTFILES_DIR"
echo ""

# Check if dotfiles subfolder exists
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "❌ Error: dotfiles subfolder not found at $DOTFILES_DIR"
    exit 1
fi

# Run the actual setup script from dotfiles subfolder
if [ -x "$DOTFILES_DIR/setup.sh" ]; then
    echo "✅ Running dotfiles/setup.sh..."
    cd "$DOTFILES_DIR"
    ./setup.sh
elif [ -x "$DOTFILES_DIR/install.sh" ]; then
    echo "✅ Running dotfiles/install.sh..."
    cd "$DOTFILES_DIR"
    ./install.sh
else
    echo "⚠️  No setup.sh or install.sh found in dotfiles/"
    echo "   Symlinking dotfiles manually..."
    
    # Fallback: symlink all dotfiles
    for file in "$DOTFILES_DIR"/.*; do
        if [ -f "$file" ] && [ "$(basename "$file")" != "." ] && [ "$(basename "$file")" != ".." ]; then
            target="$HOME/$(basename "$file")"
            echo "🔗 Linking $file -> $target"
            ln -sf "$file" "$target"
        fi
    done
fi

echo ""
echo "✅ Dotfiles setup complete!"
```

Make it executable:
```bash
chmod +x install.sh
```

---

## Your Actual Dotfiles (in dotfiles/ subfolder)

**dotfiles/setup.sh:**

```bash
#!/bin/bash
#
# Actual dotfiles installation script
# This is in the 'dotfiles' subfolder
#

set -e

echo "======================================"
echo "🎉 Hello from Dotfiles! 🎉"
echo "======================================"

# Get the dotfiles directory (current directory when called from wrapper)
DOTFILES_DIR="$(pwd)"

# Symlink dotfiles
ln -sf "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

# Install tools
echo "🤖 Installing Gemini CLI..."
pip3 install --user --upgrade google-generativeai

echo "✅ Dotfiles applied from subfolder!"
```

Make it executable:
```bash
chmod +x dotfiles/setup.sh
```

---

## Usage with Coder

```bash
# Coder clones the entire repo
coder dotfiles https://github.com/yourusername/my-configs

# What happens:
# 1. Coder clones my-configs (entire repo)
# 2. Runs install.sh (at root)
# 3. install.sh delegates to dotfiles/setup.sh
# 4. setup.sh applies the actual dotfiles
```

---

## Pros & Cons

### ✅ Pros
- Keep dotfiles in existing repo
- Don't need separate dotfiles repo
- Works with Coder's expectations
- Organized in subfolder

### ⚠️ Cons
- Clones entire repo (extra files)
- Extra wrapper script layer
- Slightly more complex

---

## Alternative: Git Sparse Checkout (Advanced)

**Not directly supported by Coder**, but your wrapper could use sparse checkout:

```bash
#!/bin/bash
# In wrapper install.sh at root

# Enable sparse checkout
git sparse-checkout init --cone
git sparse-checkout set dotfiles

# Now only dotfiles/ is checked out
cd dotfiles
./setup.sh
```

**Problem:** Coder clones with `git clone`, not sparse checkout by default.

---

## Recommendation

**If you control the repo:**
- **Best:** Move dotfiles to root (or dedicated repo)
- **Good:** Use wrapper script approach (shown above)

**If you don't control the repo:**
- Fork it and restructure
- Or use wrapper approach

---

## Testing

```bash
# Test locally first
cd my-configs
./install.sh

# Should run dotfiles/setup.sh and apply configs

# Then use with Coder
coder dotfiles https://github.com/yourusername/my-configs
```

---

**Bottom line:** Coder expects dotfiles at root, but the wrapper approach makes subfolder work! 🎯
