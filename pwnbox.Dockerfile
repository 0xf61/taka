# ---- Stage 1: toolchain builder ----
# go/rust/gcc/pipx only exist here; the final image never sees them (~800MB saved).
# NetExec's aardwolf dep needs cargo, pdtm refuses binaries outside $HOME (run as pwnbox).
FROM kalilinux/kali-bleeding-edge AS tools

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates cargo curl gcc git golang pipx python3 python3-dev && \
    useradd -m pwnbox

RUN go install github.com/bitquark/shortscan/cmd/shortscan@v0.9.2 && \
    go install github.com/ropnop/kerbrute@latest && \
    go install github.com/0xf61/iz@latest && \
    go install github.com/tomnomnom/waybackurls@latest && \
    go install github.com/tomnomnom/httprobe@latest && \
    go install github.com/tomnomnom/assetfinder@latest && \
    go install github.com/tomnomnom/meg@latest && \
    go install github.com/tomnomnom/qsreplace@latest && \
    go install github.com/tomnomnom/gf@latest && \
    go install github.com/lc/gau/v2/cmd/gau@latest && \
    go install github.com/rix4uni/unew@latest && \
    go clean -modcache

USER pwnbox
RUN go run github.com/projectdiscovery/pdtm/cmd/pdtm@latest \
    -i nuclei,subfinder,httpx \
    -bp /home/pwnbox/.local/bin -nc -duc && \
    PIPX_HOME=/home/pwnbox/.local/pipx PIPX_BIN_DIR=/home/pwnbox/.local/bin \
    pipx install --force "git+https://github.com/Pennyw0rth/NetExec.git@main" && \
    # first nxc run inits ~/.nxc and exits 1
    /home/pwnbox/.local/bin/nxc --version || true && \
    PIPX_HOME=/home/pwnbox/.local/pipx PIPX_BIN_DIR=/home/pwnbox/.local/bin \
    pipx install frida-tools && \
    pipx install impacket && \
    go clean -modcache && rm -rf /home/pwnbox/.cache

# ---- Stage 2: final image ----
FROM kalilinux/kali-bleeding-edge

LABEL maintainer="github.com/0xf61"
LABEL org.opencontainers.image.source="https://github.com/0xf61/taka"
LABEL org.opencontainers.image.description="Pentest container with VPN, RDP and security tooling"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Base + desktop + RDP. ssl-cert is explicit: the pwnbox user needs the group
# and it must not depend on xrdp's dependency chain.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    kali-linux-core \
    kali-desktop-xfce \
    dbus-x11 \
    ssl-cert \
    xorgxrdp \
    xrdp \
    xserver-xorg-core && \
    apt-get autoremove -y && apt-get clean && \
    rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/log/* \
           /usr/share/doc /usr/share/man /usr/share/locale/* /usr/share/info

# Security tooling + dev/CLI. No compilers or -dev headers: everything that
# needed them was built in the tools stage.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    adb \
    apktool \
    aria2 \
    bettercap \
    bloodyad \
    btop \
    burpsuite \
    caido \
    certipy-ad \
    chisel \
    coercer \
    curl \
    enum4linux-ng \
    evil-winrm \
    fastfetch \
    fd-find \
    feroxbuster \
    ffuf \
    fish \
    fzf \
    git \
    gzip \
    hashcat \
    iproute2 \
    iptables \
    iputils-ping \
    jq \
    lazygit \
    ligolo-ng \
    lsd \
    metasploit-framework \
    mitm6 \
    neovim \
    net-tools \
    nmap \
    openconnect \
    openresolv \
    openvpn \
    proxychains4 \
    python3 \
    python3-argcomplete \
    radare2 \
    responder \
    ripgrep \
    rlwrap \
    seclists \
    smbclient \
    sqlmap \
    sudo \
    tmux \
    tshark \
    unzip \
    wget \
    wireshark \
    wireguard \
    wpscan \
    zip && \
    # python3-impacket ships wrappers pointing into /usr/share/doc (which we
    # delete); remove the broken wrappers, upstream impacket is pipx-installed
    rm -f /usr/bin/impacket-* && \
    apt-get autoremove -y && apt-get clean && \
    rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/log/* \
           /usr/share/doc /usr/share/man /usr/share/locale/* /usr/share/info

RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends gh && \
    rm -rf /var/cache/apt /var/lib/apt/lists/*

# Netbird. Its own RUN so the || true can never mask an apt failure above.
RUN curl -fsSL https://pkgs.netbird.io/install.sh | sh || true

RUN useradd -m -s /usr/bin/fish -G sudo,ssl-cert pwnbox && \
    echo "pwnbox:pwnbox" | chpasswd && \
    echo "pwnbox ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN git clone --depth 1 https://github.com/1ndianl33t/Gf-Patterns /tmp/gfpatterns && \
    mkdir -p /home/pwnbox/.gf && \
    find /tmp/gfpatterns -maxdepth 1 -name '*.json' -exec cp {} /home/pwnbox/.gf/ \; && \
    rm -rf /tmp/gfpatterns && \
    chown -R pwnbox:pwnbox /home/pwnbox/.gf

RUN git clone --depth 1 https://github.com/six2dez/OneListForAll /usr/share/onelistforall && \
    rm -rf /usr/share/onelistforall/.git

# Go binaries + pipx venvs (venv python paths match: same base, same python3).
# Must come after useradd or --chown=pwnbox can't resolve and .local ends up root-owned.
COPY --from=tools /root/go/bin/shortscan /usr/local/bin/shortscan
COPY --from=tools /root/go/bin/kerbrute /usr/local/bin/kerbrute
COPY --from=tools /root/go/bin/iz /usr/local/bin/iz
COPY --from=tools /root/go/bin/waybackurls /usr/local/bin/waybackurls
COPY --from=tools /root/go/bin/httprobe /usr/local/bin/httprobe
COPY --from=tools /root/go/bin/assetfinder /usr/local/bin/assetfinder
COPY --from=tools /root/go/bin/meg /usr/local/bin/meg
COPY --from=tools /root/go/bin/qsreplace /usr/local/bin/qsreplace
COPY --from=tools /root/go/bin/gf /usr/local/bin/gf
COPY --from=tools /root/go/bin/gau /usr/local/bin/gau
COPY --from=tools /root/go/bin/unew /usr/local/bin/unew
COPY --from=tools --chown=pwnbox:pwnbox /home/pwnbox/.local /home/pwnbox/.local

RUN echo "fish_add_path -g /home/pwnbox/.local/bin" >> /etc/fish/config.fish
ENV PATH="/home/pwnbox/.local/bin:${PATH}"

# Fish tab-completion for nxc. Bakes argcomplete's wrapper into the pwnbox
# user's config; at completion time it invokes nxc itself, no runtime deps.
RUN mkdir -p /home/pwnbox/.config/fish && \
    register-python-argcomplete -s fish nxc >> /home/pwnbox/.config/fish/config.fish && \
    chown -R pwnbox:pwnbox /home/pwnbox/.config

RUN echo "startxfce4" > /home/pwnbox/.xsession && \
    chown pwnbox:pwnbox /home/pwnbox/.xsession

RUN sed -i 's/^test -x \/etc\/X11\/Xsession && exec \/etc\/X11\/Xsession/startxfce4/g' /etc/xrdp/startwm.sh && \
    sed -i 's/^exec \/bin\/sh \/etc\/X11\/Xsession/startxfce4/g' /etc/xrdp/startwm.sh

COPY tmux.conf /etc/tmux.conf
COPY pwnbox/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
