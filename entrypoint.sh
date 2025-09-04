#!/bin/zsh

# Ensure proper terminal settings for nvim
export TERM=${TERM:-xterm-256color}
export COLORTERM=${COLORTERM:-truecolor}
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}

# Source NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Initialize LazyVim on first run if needed
if [ ! -f "$HOME/.config/nvim/.initialized" ]; then
    echo "Initializing Neovim/LazyVim configuration..."
    nvim --headless "+Lazy! sync" +qa
    touch "$HOME/.config/nvim/.initialized"
fi

# Set up Git config if not already configured
if ! git config --global user.name > /dev/null 2>&1; then
    echo "Git user.name not configured. Set it with:"
    echo "  git config --global user.name 'Your Name'"
fi

if ! git config --global user.email > /dev/null 2>&1; then
    echo "Git user.email not configured. Set it with:"
    echo "  git config --global user.email 'your.email@example.com'"
fi

# Welcome message
echo "🚀 Development Container Ready!"
echo "================================"
echo "• Neovim/LazyVim: nvim"
echo "• Node Version: $(node --version)"
echo "• Shell: Zsh with Oh My Zsh"
echo "• Tools: lazygit, ripgrep, fzf, tmux, bottom"
echo "================================"

# Execute the command passed to docker run
exec "$@"