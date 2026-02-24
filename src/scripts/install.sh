#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Installation Script
# =============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Diretórios
INSTALL_DIR="${HOME}/cyberghost-osint"
BIN_DIR="/usr/local/bin"
CONFIG_DIR="${HOME}/.cyberghost"
DATA_DIR="${INSTALL_DIR}/data"

# Versões
GO_VERSION="1.21.0"
NODE_VERSION="18"
PYTHON_VERSION="3.11"

# Banner
print_banner() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                                                                           ║
    ║   ██████╗██╗   ██╗██████╗ ███████╗██████╗ ██╗  ██╗ ██████╗ ███████╗      ║
    ║  ██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗██║  ██║██╔═══██╗██╔════╝      ║
    ║  ██║      ╚████╔╝ ██████╔╝█████╗  ██████╔╝███████║██║   ██║███████╗      ║
    ║  ██║       ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗██╔══██║██║   ██║╚════██║      ║
    ║  ╚██████╗   ██║   ██████╔╝███████╗██║  ██║██║  ██║╚██████╔╝███████║      ║
    ║   ╚═════╝   ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝      ║
    ║                                                                           ║
    ║                    INSTALLATION SCRIPT v7.0                              ║
    ║                                                                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Verificar sistema operacional
check_os() {
    echo -e "\n${CYAN}[*] Checking operating system...${NC}"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/debian_version ]]; then
            OS="debian"
            echo -e "${GREEN}[+] Debian/Ubuntu detected${NC}"
        elif [[ -f /etc/redhat-release ]]; then
            OS="redhat"
            echo -e "${GREEN}[+] RedHat/CentOS detected${NC}"
        elif [[ -f /etc/arch-release ]]; then
            OS="arch"
            echo -e "${GREEN}[+] Arch Linux detected${NC}"
        else
            OS="linux"
            echo -e "${YELLOW}[!] Unknown Linux distribution${NC}"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        echo -e "${GREEN}[+] macOS detected${NC}"
    else:
        echo -e "${RED}[!] Unsupported operating system${NC}"
        exit 1
    fi
}

# Instalar dependências do sistema
install_system_deps() {
    echo -e "\n${CYAN}[*] Installing system dependencies...${NC}"
    
    case $OS in
        debian)
            sudo apt update
            sudo apt install -y \
                git curl wget jq python3 python3-pip python3-venv \
                golang-go build-essential libssl-dev libffi-dev \
                nmap whois dnsutils netcat-openbsd nikto sqlmap \
                hydra john aircrack-ng wireshark tshark \
                libpcap-dev libxml2-dev libxslt1-dev \
                ruby ruby-dev perl make cmake autoconf automake \
                libtool pkg-config zlib1g-dev libbz2-dev \
                libreadline-dev libsqlite3-dev libncurses5-dev \
                xz-utils tk-dev libxml2-dev libxmlsec1-dev \
                libffi-dev liblzma-dev
            ;;
            
        redhat)
            sudo yum install -y epel-release
            sudo yum install -y \
                git curl wget jq python3 python3-pip \
                golang gcc gcc-c++ make openssl-devel \
                nmap whois bind-utils nc nikto sqlmap \
                hydra john aircrack-ng wireshark \
                libpcap-devel libxml2-devel libxslt-devel \
                ruby ruby-devel perl perl-devel \
                autoconf automake libtool zlib-devel \
                bzip2-devel readline-devel sqlite-devel \
                ncurses-devel tk-devel libxml2-devel \
                libxmlsec1-devel libffi-devel
            ;;
            
        arch)
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm \
                git curl wget jq python python-pip \
                go base-devel openssl \
                nmap whois bind-tools gnu-netcat nikto sqlmap \
                hydra john aircrack-ng wireshark-qt \
                libpcap libxml2 libxslt ruby perl \
                autoconf automake libtool zlib \
                bzip2 readline sqlite ncurses tk
            ;;
            
        macos)
            if ! command -v brew &> /dev/null; then
                echo -e "${YELLOW}[!] Installing Homebrew...${NC}"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            brew update
            brew install \
                git curl wget jq python3 go \
                nmap whois bind libnetcdf \
                nikto sqlmap hydra john \
                aircrack-ng wireshark libpcap \
                libxml2 libxslt ruby perl \
                autoconf automake libtool
            ;;
    esac
    
    echo -e "${GREEN}[+] System dependencies installed${NC}"
}

# Instalar Go tools
install_go_tools() {
    echo -e "\n${CYAN}[*] Installing Go tools...${NC}"
    
    export GOPATH="${HOME}/go"
    export PATH="${PATH}:${GOPATH}/bin"
    
    # Recon tools
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
    go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
    go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
    go install -v github.com/projectdiscovery/mapcidr/cmd/mapcidr@latest
    go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
    go install -v github.com/projectdiscovery/chaos-client/cmd/chaos@latest
    
    # OSINT tools
    go install -v github.com/tomnomnom/assetfinder@latest
    go install -v github.com/tomnomnom/waybackurls@latest
    go install -v github.com/tomnomnom/gf@latest
    go install -v github.com/tomnomnom/unfurl@latest
    go install -v github.com/tomnomnom/qsreplace@latest
    go install -v github.com/tomnomnom/meg@latest
    
    # Web tools
    go install -v github.com/ffuf/ffuf@latest
    go install -v github.com/lc/gau/v2/cmd/gau@latest
    go install -v github.com/hakluke/hakrawler@latest
    go install -v github.com/hakluke/hakrevdns@latest
    
    # Misc tools
    go install -v github.com/d3mondev/puredns/v2@latest
    go install -v github.com/OJ/gobuster/v3@latest
    go install -v github.com/sensepost/gowitness@latest
    
    echo -e "${GREEN}[+] Go tools installed${NC}"
}

# Instalar Python tools
install_python_tools() {
    echo -e "\n${CYAN}[*] Installing Python tools...${NC}"
    
    # Criar virtual environment
    python3 -m venv "${INSTALL_DIR}/venv"
    source "${INSTALL_DIR}/venv/bin/activate"
    
    # Atualizar pip
    pip install --upgrade pip setuptools wheel
    
    # Instalar pacotes Python
    pip install \
        shodan \
        censys \
        vt-py \
        greynoise \
        hunterio \
        securitytrails \
        zoomeye \
        binaryedge \
        publicwww \
        haveibeenpwned \
        emailrep \
        requests \
        beautifulsoup4 \
        selenium \
        scrapy \
        pandas \
        numpy \
        matplotlib \
        seaborn \
        wordcloud \
        networkx \
        scikit-learn \
        tensorflow \
        torch \
        transformers \
        nltk \
        textblob \
        phonenumbers \
        folium \
        geopy \
        exifread \
        pyPDF2 \
        python-docx \
        openpyxl \
        yara-python \
        pefile \
        androguard \
        mobsf \
        frida-tools \
        objection \
        apkleaks
    
    # Ferramentas OSINT específicas
    pip install \
        theHarvester \
        recon-ng \
        sherlock \
        holehe \
        h8mail \
        twint \
        instalooter \
        youtube-dl \
        facebook-scraper \
        linkedin-scraper \
        telegram-scraper
    
    echo -e "${GREEN}[+] Python tools installed${NC}"
}

# Instalar ferramentas Ruby
install_ruby_tools() {
    echo -e "\n${CYAN}[*] Installing Ruby tools...${NC}"
    
    gem install \
        wpscan \
        metasploit-framework \
        evil-winrm \
        haiti-hash \
        zsteg
    
    echo -e "${GREEN}[+] Ruby tools installed${NC}"
}

# Clonar repositórios GitHub
clone_github_repos() {
    echo -e "\n${CYAN}[*] Cloning GitHub repositories...${NC}"
    
    mkdir -p "${INSTALL_DIR}/tools"
    cd "${INSTALL_DIR}/tools"
    
    # OSINT tools
    git clone https://github.com/sherlock-project/sherlock.git
    git clone https://github.com/laramies/theHarvester.git
    git clone https://github.com/lanmaster53/recon-ng.git
    git clone https://github.com/smicallef/spiderfoot.git
    git clone https://github.com/trustedsec/social-engineer-toolkit.git
    git clone https://github.com/s0md3v/Photon.git
    git clone https://github.com/s0md3v/Corsy.git
    git clone https://github.com/m4ll0k/SecretFinder.git
    git clone https://github.com/m4ll0k/Infoga.git
    git clone https://github.com/evilsocket/xray.git
    
    # Web tools
    git clone https://github.com/maurosoria/dirsearch.git
    git clone https://github.com/OJ/gobuster.git
    git clone https://github.com/ffuf/ffuf.git
    git clone https://github.com/projectdiscovery/nuclei-templates.git
    
    # Recon tools
    git clone https://github.com/aboul3la/Sublist3r.git
    git clone https://github.com/blechschmidt/massdns.git
    git clone https://github.com/guelfoweb/knock.git
    git clone https://github.com/darkoperator/dnsrecon.git
    
    # Wordlists
    git clone https://github.com/danielmiessler/SecLists.git
    git clone https://github.com/berzerk0/Probable-Wordlists.git
    
    # Frameworks
    git clone https://github.com/OWASP/Amass.git
    git clone https://github.com/byt3bl33d3r/CrackMapExec.git
    git clone https://github.com/SecureAuthCorp/impacket.git
    
    echo -e "${GREEN}[+] GitHub repositories cloned${NC}"
}

# Baixar wordlists
download_wordlists() {
    echo -e "\n${CYAN}[*] Downloading wordlists...${NC}"
    
    mkdir -p "${DATA_DIR}/wordlists"
    cd "${DATA_DIR}/wordlists"
    
    # Subdomain wordlists
    wget -q -O subdomains/all.txt "https://gist.githubusercontent.com/jhaddix/86a06c5dc309d08580a018c66354a056/raw/96f4e51d96b2203f19f6381c8c545b278eaa0837/all.txt"
    wget -q -O subdomains/commonspeak.txt "https://github.com/assetnote/commonspeak2-wordlists/raw/master/subdomains/subdomains.txt"
    wget -q -O subdomains/securitytrails.txt "https://raw.githubusercontent.com/securitytrails/subdomain-wordlist/main/list.txt"
    
    # Directory wordlists
    wget -q -O directories/common.txt "https://raw.githubusercontent.com/daviddias/node-dirbuster/master/lists/directory-list-2.3-medium.txt"
    wget -q -O directories/rails.txt "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/rails.txt"
    wget -q -O directories/spring.txt "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/spring-boot.txt"
    
    # Password wordlists
    wget -q -O passwords/rockyou.txt "https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt"
    wget -q -O passwords/common.txt "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10-million-password-list-top-10000.txt"
    
    # Username wordlists
    wget -q -O usernames/common.txt "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Usernames/top-usernames-shortlist.txt"
    wget -q -O usernames/names.txt "https://raw.githubusercontent.com/insidetrust/statistically-likely-usernames/master/john.txt"
    
    echo -e "${GREEN}[+] Wordlists downloaded${NC}"
}

# Configurar ambiente
setup_environment() {
    echo -e "\n${CYAN}[*] Setting up environment...${NC}"
    
    # Criar estrutura de diretórios
    mkdir -p "${CONFIG_DIR}"/{certs,logs,cache,db}
    mkdir -p "${INSTALL_DIR}"/{reports,temp,backups}
    
    # Configurar arquivo de ambiente
    cat > "${INSTALL_DIR}/.env" << EOF
# CYBERGHOST OSINT Environment Configuration
INSTALL_DIR="${INSTALL_DIR}"
CONFIG_DIR="${CONFIG_DIR}"
DATA_DIR="${DATA_DIR}"
LOG_DIR="${INSTALL_DIR}/logs"
TEMP_DIR="${INSTALL_DIR}/temp"
REPORTS_DIR="${INSTALL_DIR}/reports"

# Paths
export PATH="\${PATH}:${HOME}/go/bin:${INSTALL_DIR}/venv/bin"
EOF
    
    # Adicionar ao bashrc
    if ! grep -q "CYBERGHOST" "${HOME}/.bashrc"; then
        echo "" >> "${HOME}/.bashrc"
        echo "# CYBERGHOST OSINT" >> "${HOME}/.bashrc"
        echo "source ${INSTALL_DIR}/.env" >> "${HOME}/.bashrc"
        echo "alias cg='${INSTALL_DIR}/src/core/main.sh'" >> "${HOME}/.bashrc"
        echo "alias cg-scan='${INSTALL_DIR}/src/core/main.sh scan'" >> "${HOME}/.bashrc"
    fi
    
    echo -e "${GREEN}[+] Environment configured${NC}"
}

# Configurar APIs
configure_apis() {
    echo -e "\n${CYAN}[*] Configuring API keys...${NC}"
    
    cat > "${CONFIG_DIR}/api_keys.conf" << EOF
# CYBERGHOST OSINT - API Keys Configuration
# Get your API keys from the respective services

# Shodan - https://account.shodan.io/
SHODAN_API_KEY=""

# VirusTotal - https://www.virustotal.com/gui/my-apikey
VIRUSTOTAL_API_KEY=""

# Censys - https://censys.io/register
CENSYS_API_ID=""
CENSYS_API_SECRET=""

# GreyNoise - https://greynoise.io/
GREYNOISE_API_KEY=""

# Hunter.io - https://hunter.io/users/sign_up
HUNTER_API_KEY=""

# SecurityTrails - https://securitytrails.com/
SECURITYTRAILS_API_KEY=""

# ZoomEye - https://www.zoomeye.org/
ZOOMEYE_API_KEY=""

# BinaryEdge - https://www.binaryedge.io/
BINARYEDGE_API_KEY=""

# PublicWWW - https://publicwww.com/
PUBLICWWW_API_KEY=""

# Have I Been Pwned - https://haveibeenpwned.com/API/Key
HIBP_API_KEY=""

# EmailRep.io - https://emailrep.io/
EMAILREP_API_KEY=""

# GitHub - https://github.com/settings/tokens
GITHUB_API_KEY=""

# Google Custom Search - https://developers.google.com/custom-search/v1/overview
GOOGLE_API_KEY=""
GOOGLE_CX=""

# Twitter API - https://developer.twitter.com/
TWITTER_API_KEY=""
TWITTER_API_SECRET=""
TWITTER_ACCESS_TOKEN=""
TWITTER_ACCESS_SECRET=""

# LinkedIn API - https://www.linkedin.com/developers/
LINKEDIN_CLIENT_ID=""
LINKEDIN_CLIENT_SECRET=""

# Facebook API - https://developers.facebook.com/
FACEBOOK_APP_ID=""
FACEBOOK_APP_SECRET=""
EOF
    
    echo -e "${GREEN}[+] API configuration template created${NC}"
}

# Verificar instalação
verify_installation() {
    echo -e "\n${CYAN}[*] Verifying installation...${NC}"
    
    local errors=0
    
    # Verificar diretórios
    for dir in "${INSTALL_DIR}" "${CONFIG_DIR}" "${DATA_DIR}"; do
        if [[ -d "$dir" ]]; then
            echo -e "${GREEN}[✓] $dir exists${NC}"
        else
            echo -e "${RED}[✗] $dir missing${NC}"
            ((errors++))
        fi
    done
    
    # Verificar ferramentas principais
    local tools=("subfinder" "httpx" "nuclei" "ffuf" "gobuster" "amass" "nmap")
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "${GREEN}[✓] $tool installed${NC}"
        else
            echo -e "${YELLOW}[!] $tool not found${NC}"
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        echo -e "\n${GREEN}[+] Installation verified successfully!${NC}"
    else
        echo -e "\n${YELLOW}[!] Installation completed with $errors errors${NC}"
    fi
}

# Função principal
main() {
    print_banner
    
    echo -e "\n${YELLOW}This script will install CYBERGHOST OSINT Ultimate v7.0${NC}"
    echo -e "${YELLOW}Installation directory: ${INSTALL_DIR}${NC}"
    echo -e "${YELLOW}This may take a while. Continue? (y/N)${NC}"
    read -r answer
    
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation cancelled${NC}"
        exit 0
    fi
    
    # Executar instalação
    check_os
    install_system_deps
    install_go_tools
    install_python_tools
    install_ruby_tools
    clone_github_repos
    download_wordlists
    setup_environment
    configure_apis
    verify_installation
    
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                   CYBERGHOST OSINT INSTALLATION COMPLETE!                   ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e ""
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "  1. Edit API keys: ${CONFIG_DIR}/api_keys.conf"
    echo -e "  2. Run: source ~/.bashrc"
    echo -e "  3. Start CYBERGHOST: cg"
    echo -e ""
    echo -e "${CYAN}Documentation:${NC}"
    echo -e "  ${INSTALL_DIR}/docs/README.md"
    echo -e ""
    echo -e "${YELLOW}Remember: Use only for ethical and legal purposes!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════════${NC}"
}

# Executar
main "$@"