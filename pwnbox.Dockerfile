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
    go install github.com/0xf61/iz@latest && \
    go clean -modcache

USER pwnbox
RUN go run github.com/projectdiscovery/pdtm/cmd/pdtm@latest \
    -i nuclei,subfinder,httpx \
    -bp /home/pwnbox/.local/bin -nc -duc && \
    PIPX_HOME=/home/pwnbox/.local/pipx PIPX_BIN_DIR=/home/pwnbox/.local/bin \
    pipx install --force "git+https://github.com/Pennyw0rth/NetExec.git@main" && \
    # first nxc run inits ~/.nxc and exits 1
    /home/pwnbox/.local/bin/nxc --version || true && \
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
    aria2 \
    btop \
    burpsuite \
    caido \
    curl \
    fastfetch \
    fd-find \
    feroxbuster \
    ffuf \
    fish \
    fzf \
    git \
    gzip \
    iproute2 \
    iptables \
    iputils-ping \
    jq \
    lazygit \
    lsd \
    metasploit-framework \
    neovim \
    net-tools \
    nmap \
    openconnect \
    openresolv \
    openvpn \
    python3 \
    python3-argcomplete \
    ripgrep \
    rlwrap \
    seclists \
    sqlmap \
    sudo \
    tmux \
    unzip \
    wget \
    wireguard \
    zip && \
    apt-get autoremove -y && apt-get clean && \
    rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/log/* \
           /usr/share/doc /usr/share/man /usr/share/locale/* /usr/share/info

# Netbird. Its own RUN so the || true can never mask an apt failure above.
RUN curl -fsSL https://pkgs.netbird.io/install.sh | sh || true

RUN useradd -m -s /usr/bin/fish -G sudo,ssl-cert pwnbox && \
    echo "pwnbox:pwnbox" | chpasswd && \
    echo "pwnbox ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Go binaries + pipx venvs (venv python paths match: same base, same python3).
# Must come after useradd or --chown=pwnbox can't resolve and .local ends up root-owned.
COPY --from=tools /root/go/bin/shortscan /usr/local/bin/shortscan
COPY --from=tools /root/go/bin/iz /usr/local/bin/iz
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
