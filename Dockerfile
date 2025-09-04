FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set up base system
RUN apt-get update && apt-get install -y \
    # Core utilities
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    ca-certificates \
    gnupg \
    lsb-release \
    sudo \
    locales \
    # Development tools
    python3 \
    python3-pip \
    ripgrep \
    fd-find \
    fzf \
    tmux \
    unzip \
    # Required for Neovim
    ninja-build \
    gettext \
    libtool \
    libtool-bin \
    autoconf \
    automake \
    cmake \
    g++ \
    pkg-config \
    # Required for various tools
    zlib1g-dev \
    libssl-dev \
    libreadline-dev \
    libbz2-dev \
    libsqlite3-dev \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libffi-dev \
    liblzma-dev \
    # X11 support for GUI apps
    xauth \
    x11-apps \
    # Clean up
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create a non-root user
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Switch to non-root user
USER $USERNAME
WORKDIR /home/$USERNAME

# Install Zsh and Oh My Zsh
RUN sudo apt-get update && sudo apt-get install -y zsh \
    && sudo rm -rf /var/lib/apt/lists/* \
    && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && sudo chsh -s $(which zsh) $USERNAME

# Configure Zsh theme and plugins
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' ~/.zshrc \
    && sed -i 's/plugins=(git)/plugins=(git docker docker-compose kubectl npm node python pip sudo zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

# Install Zsh plugins
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Install NVM and Node.js
ENV NVM_DIR="/home/$USERNAME/.nvm"
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm use --lts \
    && nvm alias default node \
    && npm install -g yarn pnpm neovim tree-sitter-cli

# Add NVM to shell
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.zshrc

# Install Neovim from source (latest stable)
RUN cd /tmp \
    && git clone https://github.com/neovim/neovim.git \
    && cd neovim \
    && git checkout stable \
    && make CMAKE_BUILD_TYPE=Release \
    && sudo make install \
    && cd / \
    && rm -rf /tmp/neovim

# Create nvim directories
RUN mkdir -p ~/.config/nvim ~/.local/share/nvim ~/.cache/nvim

# Install LazyVim dependencies
RUN pip3 install --user pynvim

# Clone your Neovim configuration (you'll need to update this with your actual repo)
# Replace YOUR_GITHUB_USERNAME with your actual GitHub username
ARG NVIM_CONFIG_REPO=""
RUN if [ -n "$NVIM_CONFIG_REPO" ]; then \
        git clone $NVIM_CONFIG_REPO ~/.config/nvim; \
    else \
        echo "No Neovim config repo specified. Using LazyVim starter template." \
        && git clone https://github.com/LazyVim/starter ~/.config/nvim \
        && rm -rf ~/.config/nvim/.git; \
    fi

# Install Ghostty (if available as AppImage or binary)
# Note: Ghostty might not be available for Linux yet, so this is a placeholder
# You may need to build from source or wait for official Linux release
RUN echo "Ghostty installation placeholder - check for Linux availability"

# Install lazygit (architecture-aware)
RUN ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "arm64" ]; then LAZYGIT_ARCH="arm64"; else LAZYGIT_ARCH="x86_64"; fi \
    && LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') \
    && curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz" \
    && tar xf lazygit.tar.gz lazygit \
    && sudo install lazygit /usr/local/bin \
    && rm lazygit.tar.gz lazygit

# Install bottom (btm) for system monitoring (architecture-aware)
RUN ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "arm64" ]; then BTM_ARCH="aarch64-unknown-linux-gnu"; else BTM_ARCH="x86_64-unknown-linux-gnu"; fi \
    && curl -LO "https://github.com/ClementTsang/bottom/releases/download/0.9.6/bottom_${BTM_ARCH}.tar.gz" \
    && tar xf "bottom_${BTM_ARCH}.tar.gz" \
    && sudo install btm /usr/local/bin \
    && rm -f "bottom_${BTM_ARCH}.tar.gz" btm

# Set up working directory
WORKDIR /workspace

# Copy entrypoint script
COPY --chown=$USERNAME:$USERNAME entrypoint.sh /home/$USERNAME/entrypoint.sh
RUN chmod +x /home/$USERNAME/entrypoint.sh

# Set Zsh as the default shell
SHELL ["/bin/zsh", "-c"]

# Expose port for development servers
EXPOSE 3000 3001 4000 5000 5173 8000 8080 8888

# Set entrypoint
ENTRYPOINT ["/home/developer/entrypoint.sh"]
CMD ["/bin/zsh"]