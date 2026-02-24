# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Dockerfile
# =============================================================================

# Estágio 1: Builder
FROM golang:1.21-alpine AS builder

LABEL maintainer="CyberGhost <cyberghost@protonmail.com>"
LABEL version="7.0"
LABEL description="CYBERGHOST OSINT Ultimate - Advanced OSINT Framework"

# Instalar dependências do builder
RUN apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    libc-dev \
    libffi-dev \
    openssl-dev

# Configurar Go
ENV GOPATH=/go
ENV PATH=$PATH:$GOPATH/bin
WORKDIR /build

# Instalar ferramentas Go
RUN go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest && \
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest && \
    go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest && \
    go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest && \
    go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest && \
    go install -v github.com/tomnomnom/assetfinder@latest && \
    go install -v github.com/tomnomnom/waybackurls@latest && \
    go install -v github.com/ffuf/ffuf@latest && \
    go install -v github.com/lc/gau/v2/cmd/gau@latest && \
    go install -v github.com/hakluke/hakrawler@latest && \
    go install -v github.com/OJ/gobuster/v3@latest && \
    go install -v github.com/d3mondev/puredns/v2@latest

# Estágio 2: Python builder
FROM python:3.11-slim AS python-builder

WORKDIR /build

# Instalar dependências Python
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Estágio 3: Final
FROM alpine:3.19

# Instalar dependências do sistema
RUN apk add --no-cache \
    bash \
    curl \
    wget \
    jq \
    nmap \
    whois \
    bind-tools \
    netcat-openbsd \
    nikto \
    sqlmap \
    hydra \
    john \
    aircrack-ng \
    wireshark \
    tshark \
    libpcap \
    libxml2 \
    libxslt \
    ruby \
    perl \
    make \
    cmake \
    autoconf \
    automake \
    libtool \
    pkgconfig \
    zlib \
    bzip2 \
    readline \
    sqlite \
    ncurses \
    tk \
    libffi \
    openssl \
    ca-certificates \
    git \
    nmap \
    masscan \
    python3 \
    py3-pip \
    go \
    nodejs \
    npm \
    yarn \
    tor \
    proxychains-ng \
    && rm -rf /var/cache/apk/*

# Copiar binários Go do builder
COPY --from=builder /go/bin/* /usr/local/bin/

# Copiar Python packages
COPY --from=python-builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH

# Criar usuário não-root
RUN addgroup -g 1000 -S cyberghost && \
    adduser -u 1000 -S cyberghost -G cyberghost

# Criar estrutura de diretórios
RUN mkdir -p /opt/cyberghost \
    /opt/cyberghost/data \
    /opt/cyberghost/logs \
    /opt/cyberghost/reports \
    /opt/cyberghost/temp \
    /opt/cyberghost/config \
    /opt/cyberghost/wordlists \
    /opt/cyberghost/tools \
    /home/cyberghost/.cyberghost \
    && chown -R cyberghost:cyberghost /opt/cyberghost /home/cyberghost

# Copiar código fonte
COPY --chown=cyberghost:cyberghost . /opt/cyberghost/

# Configurar ambiente
WORKDIR /opt/cyberghost

# Configurar PATH
ENV PATH=/opt/cyberghost/src/core:$PATH
ENV PATH=/opt/cyberghost/scripts:$PATH
ENV CYBERGHOST_HOME=/opt/cyberghost
ENV CONFIG_DIR=/home/cyberghost/.cyberghost

# Tornar scripts executáveis
RUN chmod +x /opt/cyberghost/src/core/*.sh \
    /opt/cyberghost/scripts/*.sh

# Configurar Tor
RUN echo "SOCKSPort 9050" > /etc/tor/torrc && \
    echo "ControlPort 9051" >> /etc/tor/torrc && \
    echo "CookieAuthentication 1" >> /etc/tor/torrc

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep tor > /dev/null || exit 1

# Volumes
VOLUME ["/opt/cyberghost/data", "/opt/cyberghost/reports", "/opt/cyberghost/config"]

# Portas
EXPOSE 9050 9051 8080 8443

# Usuário não-root
USER cyberghost

# Entrypoint
ENTRYPOINT ["/opt/cyberghost/scripts/docker-entrypoint.sh"]

# Comando padrão
CMD ["cg"]