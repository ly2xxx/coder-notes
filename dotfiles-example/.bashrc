# Custom .bashrc for Coder Workspaces
# Applied via dotfiles automation

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Colorful prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# Useful aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias cls='clear'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'

# Python aliases
alias py='python3'
alias pip='pip3'

# Custom greeting
echo "======================================"
echo "🚀 Welcome to your Coder Workspace!"
echo "======================================"
echo "📅 $(date)"
echo "🤖 Gemini CLI: $(python3 -c 'import google.generativeai as genai; print("v" + genai.__version__)' 2>/dev/null || echo 'Not installed')"
echo "======================================"

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

# Check window size after each command
shopt -s checkwinsize

# Custom function: Quick Gemini test
gemini_test() {
    python3 -c "
import google.generativeai as genai
print('✅ Gemini CLI is installed!')
print('Version:', genai.__version__)
print('Ready to use!')
"
}

# Welcome helper
dotfiles_info() {
    echo "📝 Dotfiles Info:"
    echo "  - Location: ~/.bashrc, ~/.gitconfig"
    echo "  - Gemini: $(python3 -c 'import google.generativeai as genai; print(genai.__version__)' 2>/dev/null || echo 'Not installed')"
    echo "  - Test Gemini: gemini_test"
}
