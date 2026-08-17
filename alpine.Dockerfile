FROM docker.io/library/alpine:latest

LABEL maintainer="github.com/0xf61"
LABEL org.opencontainers.image.source="https://github.com/0xf61/taka"
LABEL org.opencontainers.image.description="Dev container with security research tools (alpine)"

# Base Requirements for working with lazyvim
RUN apk add \
  alpine-sdk \
  bash \
  curl \
  fd \
  fish \
  fzf \
  gzip \
  lazygit \
  neovim \
  python3 \
  unzip \
  ripgrep

# Langs
RUN apk add \
  cargo \
  go \
  npm


# Install lazyvim
RUN git clone https://github.com/LazyVim/starter ~/.config/nvim && rm -rf ~/.config/nvim/.git

# Change working Dir
WORKDIR /root

# Cloud Build LazyVim
RUN nvim --headless "+Lazy! sync" +qa
