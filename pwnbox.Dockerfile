FROM kalilinux/kali-bleeding-edge

LABEL maintainer="github.com/0xf61"
LABEL org.opencontainers.image.source="https://github.com/0xf61/taka"
LABEL org.opencontainers.image.description="Pentest container with VPN, RDP and security tooling"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    kali-linux-core \
    kali-desktop-xfce \
    adb \
    aria2 \
    btop \
    burpsuite \
    caido \
    cargo \
    curl \
    dbus-x11 \
    fastfetch \
    feroxbuster \
    fd-find \
    ffuf \
    fish \
    fzf \
    gcc \
    git \
    golang \
    gzip \
    iproute2 \
    iptables \
    iputils-ping \
    lazygit \
    lsd \
    metasploit-framework \
    neovim \
    nmap \
    net-tools \
    openconnect \
    openresolv \
    openvpn \
    pipx \
    python3 \
    python3-dev \
    ripgrep \
    rlwrap \
    seclists \
    sudo \
    sqlmap \
    tmux \
    unzip \
    wget \
    wireguard \
    xorgxrdp \
    xrdp \
    xserver-xorg-core \
    zip && \
    # Netbird
    curl -fsSL https://pkgs.netbird.io/install.sh | sh || true && \
    # ShortScanner
    go install github.com/bitquark/shortscan/cmd/shortscan@v0.9.2 && mv ~/go/bin/shortscan /usr/local/bin && \
    # Atuin+Asciinema Alternative (no tags/release in repo, @latest is the only ref)
    go install github.com/0xf61/iz@latest && mv ~/go/bin/iz /usr/local/bin && \
    # Cleanup
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /root/go /root/.cache /tmp/* \
           /var/cache/apt /var/lib/apt/lists/* \
           /var/log/* /usr/share/doc /usr/share/man \
           /usr/share/locale/* /usr/share/info

RUN useradd -m -s /usr/bin/fish -G sudo,ssl-cert pwnbox && \
    echo "pwnbox:pwnbox" | chpasswd && \
    echo "pwnbox ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# NetExec: Kali's apt release lags far behind upstream, so install the latest
# from git main. pipx is broken when run as root, hence the pwnbox user.
# pdtm (via go run, nothing kept) fetches the latest nuclei/subfinder/httpx
# into ~/.local/bin which is already on PATH. Pre-run nxc once to init ~/.nxc.
USER pwnbox
RUN PIPX_HOME=/home/pwnbox/.local/pipx PIPX_BIN_DIR=/home/pwnbox/.local/bin \
    pipx install --force "git+https://github.com/Pennyw0rth/NetExec.git@main" && \
    /home/pwnbox/.local/bin/nxc --version || true && \
    go run github.com/projectdiscovery/pdtm/cmd/pdtm@latest \
        -i nuclei,subfinder,httpx \
        -bp /home/pwnbox/.local/bin -nc -duc && \
    go clean -modcache && \
    rm -rf /home/pwnbox/.cache /home/pwnbox/go /home/pwnbox/.config/pdtm
USER root
RUN echo "fish_add_path -g /home/pwnbox/.local/bin" >> /etc/fish/config.fish
ENV PATH="/home/pwnbox/.local/bin:${PATH}"

RUN echo "startxfce4" > /home/pwnbox/.xsession && \
    chown pwnbox:pwnbox /home/pwnbox/.xsession

RUN sed -i 's/^test -x \/etc\/X11\/Xsession && exec \/etc\/X11\/Xsession/startxfce4/g' /etc/xrdp/startwm.sh && \
    sed -i 's/^exec \/bin\/sh \/etc\/X11\/Xsession/startxfce4/g' /etc/xrdp/startwm.sh

COPY pwnbox/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
