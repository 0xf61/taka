FROM docker.io/archlinux/archlinux:latest

LABEL maintainer="github.com/0xf61"
LABEL org.opencontainers.image.source="https://github.com/0xf61/taka"
LABEL org.opencontainers.image.description="Dev container with security research tools (arch)"

# Base Requirements for working with lazyvim
RUN pacman -Syu --noconfirm \
  bash \
  curl \
  fd \
  fish \
  fzf \
  git \
  gzip \
  lazygit \
  neovim \
  python3 \
  unzip \
  ripgrep \
  zip

# Langs
RUN pacman -S --noconfirm \
  cargo \
  go \
  npm

# Install lazyvim
RUN git clone https://github.com/LazyVim/starter ~/.config/nvim && rm -rf ~/.config/nvim/.git

# Change working Dir
WORKDIR /root

# Cloud Build LazyVim
RUN nvim --headless "+Lazy! sync" +qa
