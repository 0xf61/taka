FROM kalilinux/kali-bleeding-edge

LABEL maintainer="github.com/0xf61"

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
    neovim \
    nmap \
    netexec \
    net-tools \
    openconnect \
    openresolv \
    openvpn \
    pipx \
    python3 \
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
    xserver-xorg-core && \
    # ProjectDiscovery tools
    wget -q https://github.com/projectdiscovery/nuclei/releases/download/v3.3.9/nuclei_3.3.9_linux_amd64.zip -O /tmp/nuclei.zip && \
    wget -q https://github.com/projectdiscovery/subfinder/releases/download/v2.6.8/subfinder_2.6.8_linux_amd64.zip -O /tmp/subfinder.zip && \
    wget -q https://github.com/projectdiscovery/httpx/releases/download/v1.6.9/httpx_1.6.9_linux_amd64.zip -O /tmp/httpx.zip && \
    unzip -q /tmp/nuclei.zip -d /usr/local/bin nuclei && \
    unzip -q /tmp/subfinder.zip -d /usr/local/bin subfinder && \
    unzip -q /tmp/httpx.zip -d /usr/local/bin httpx && \
    rm -f /tmp/*.zip && \
    # Tailscale
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && apt-get install -y --no-install-recommends tailscale && \
    # Netbird
    curl -fsSL https://pkgs.netbird.io/install.sh | sh || true && \
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

RUN echo "startxfce4" > /home/pwnbox/.xsession && \
    chown pwnbox:pwnbox /home/pwnbox/.xsession

RUN sed -i 's/^test -x \/etc\/X11\/Xsession && exec \/etc\/X11\/Xsession/startxfce4/g' /etc/xrdp/startwm.sh && \
    sed -i 's/^exec \/bin\/sh \/etc\/X11\/Xsession/startxfce4/g' /etc/xrdp/startwm.sh

COPY pwnbox/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
