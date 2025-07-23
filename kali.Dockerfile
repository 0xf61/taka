FROM docker.io/kalilinux/kali-bleeding-edge:latest

LABEL maintainer="github.com/0xf61"

# Base Requirements for working with lazyvim
RUN apt -y update && apt -y upgrade && \
  DEBIAN_FRONTEND=noninteractive apt -yq install \
  curl \
  fd-find \
  fish \
  fzf \
  gcc \
  git \
  gzip \
  lazygit \
  neovim \
  python3 \
  ripgrep \
  unzip

RUN curl -fsSL https://pkgs.netbird.io/install.sh | sh

# Install lazyvim
RUN git clone https://github.com/LazyVim/starter ~/.config/nvim && rm -rf ~/.config/nvim/.git

# Change working Dir
WORKDIR /root

# Cloud Build LazyVim
RUN nvim --headless "+Lazy! sync" +qa
