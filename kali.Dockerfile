FROM docker.io/kalilinux/kali-bleeding-edge:latest

# Pin the Kali CDN mirror: http.kali.org redirects to geo mirrors that
# intermittently return HTTP 500 on CI runners and break the build.
# Plain HTTP is fine for apt (release files are GPG-signed); the base image
# ships without ca-certificates, so https would fail certificate verification.
RUN printf '%s\n' \
    'Types: deb' \
    'URIs: http://kali.download/kali/' \
    'Suites: kali-rolling kali-bleeding-edge' \
    'Components: main contrib non-free non-free-firmware' \
    'Signed-By: /usr/share/keyrings/kali-archive-keyring.gpg' \
    > /etc/apt/sources.list.d/kali.sources

LABEL maintainer="github.com/0xf61"
LABEL org.opencontainers.image.source="https://github.com/0xf61/taka"
LABEL org.opencontainers.image.description="Dev container with security research tools (kali)"

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
  tmux \
  unzip \
  zip

COPY tmux.conf /etc/tmux.conf

RUN curl -fsSL https://pkgs.netbird.io/install.sh | sh

# Install lazyvim
RUN git clone https://github.com/LazyVim/starter ~/.config/nvim && rm -rf ~/.config/nvim/.git

# Change working Dir
WORKDIR /root

# Cloud Build LazyVim
RUN nvim --headless "+Lazy! sync" +qa
