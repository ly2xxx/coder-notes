#!/bin/bash
#
# Dotfiles Installation Script
# This script runs automatically when Coder applies dotfiles
#

set -e  # Exit on error

echo "======================================"
echo "🎉 Hello from Dotfiles! 🎉"
echo "======================================"
echo "Timestamp: $(date)"
echo "User: $(whoami)"
echo "Hostname: $(hostname)"
echo "======================================"
echo ""

# Get the directory where this script lives
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📂 Dotfiles directory: $DOTFILES_DIR"
echo ""

# Function to create symlink
link_file() {
    local src=$1
    local dest=$2
    
    if [ -e "$dest" ]; then
        echo "⚠️  $dest already exists, backing up..."
        mv "$dest" "${dest}.backup-$(date +%Y%m%d-%H%M%S)"
    fi
    
    echo "🔗 Linking $src -> $dest"
    ln -sf "$src" "$dest"
}

# Symlink dotfiles
echo "📝 Setting up dotfiles..."
link_file "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
echo ""

# Install Gemini CLI
echo "🤖 Installing Google Gemini CLI..."

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "⚠️  Python3 not found, installing..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3 python3-pip
    else
        echo "❌ Cannot install Python3 automatically. Please install manually."
        exit 1
    fi
fi

# Install Gemini CLI
echo "📦 Installing google-generativeai package..."
pip3 install --user --upgrade google-generativeai

# Add Python user bin to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

echo ""
echo "✅ Gemini CLI installed!"
echo ""

# Test Gemini installation
echo "🧪 Testing Gemini installation..."
if python3 -c "import google.generativeai as genai; print('✅ Gemini import successful!')" 2>/dev/null; then
    echo "✅ Gemini CLI is ready to use!"
else
    echo "⚠️  Gemini installed but import test failed (may need to restart shell)"
fi

echo ""
echo "======================================"
echo "✨ Dotfiles setup complete! ✨"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Restart your shell or run: source ~/.bashrc"
echo "2. Test Gemini: python3 -c 'import google.generativeai as genai; print(genai.__version__)'"
echo "3. Enjoy your personalized workspace!"
echo ""
