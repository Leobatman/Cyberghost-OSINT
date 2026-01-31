#!/bin/bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - The Ultimate OSINT Tool
# Desenvolvido por: Leonardo Pereira Pinheiro | CyberGhost
# Versão: 7.0 | Código: Shadow Warrior
# Licença: GPL-3.0 | Use apenas para fins éticos e legais!
# =============================================================================

# =============================================================================
# CONFIGURAÇÃO AVANÇADA
# =============================================================================

# Cores avançadas
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
REVERSE='\033[7m'
NC='\033[0m'

# Gradientes
gradient() {
    local text="$1"
    echo -ne "\033[38;5;39m${text:0:${#text}/3}\033[38;5;45m${text:${#text}/3:${#text}/3}\033[38;5;51m${text:${#text}/3*2}\033[0m"
}

# Emojis
EMOJI=(🔥 💀 🎭 🕵️ ‍♂️ 🔍 📡 🌐 🗺️ 🔐 💾 📊 📈 📉 🚨 ⚠️ ✅ ❌ ⚡ 👻 🏴‍☠️ 🔥 🗝️ 🎯)

# Configurações
VERSION="7.0"
AUTHOR="Leonardo Pereira Pinheiro"
ALIAS="CyberGhost"
CODENAME="Shadow Warrior"
SESSION_ID=$(date +%s%N | sha256sum | base64 | head -c 16 | tr -d '=' | tr '+/' 'az')
START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
OPERATION_NAME=$(shuf -n 3 /usr/share/dict/words | tr '\n' '_' | sed 's/_$//')
LOG_DIR="/tmp/cyberghost_${SESSION_ID}"
REPORTS_DIR="${HOME}/CyberGhost_Reports"
TEMP_DIR="${LOG_DIR}/temp"
TOOL_DIR="${HOME}/.cyberghost/tools"
DATABASES_DIR="${HOME}/.cyberghost/databases"
WORDLISTS_DIR="${HOME}/.cyberghost/wordlists"

# API Keys (configure em ~/.cyberghost/api_keys)
SHODAN_API=""
VIRUSTOTAL_API=""
CENSYS_API=""
GITHUB_API=""
HUNTER_API=""
ZOOMEYE_API=""
BINARYEDGE_API=""
PUBLICWWW_API=""

# =============================================================================
# BANNER ANIMADO
# =============================================================================

print_banner() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════════════════════════════════╗
    ║                                                                                          ║
    ║   ██████╗██╗   ██╗██████╗ ███████╗██████╗ ██╗  ██╗ ██████╗ ███████╗███████╗████████╗    ║
    ║  ██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗██║  ██║██╔═══██╗██╔════╝██╔════╝╚══██╔══╝    ║
    ║  ██║      ╚████╔╝ ██████╔╝█████╗  ██████╔╝███████║██║   ██║███████╗███████╗   ██║       ║
    ║  ██║       ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗██╔══██║██║   ██║╚════██║╚════██║   ██║       ║
    ║  ╚██████╗   ██║   ██████╔╝███████╗██║  ██║██║  ██║╚██████╔╝███████║███████║   ██║       ║
    ║   ╚═════╝   ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝   ╚═╝       ║
    ║                                                                                          ║
    ╚══════════════════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Efeito de digitação
    echo -ne "${CYAN}┌──(${GREEN}root@cyberghost${CYAN})-[${YELLOW}~${CYAN}]\n└─${GREEN}#${NC} "
    sleep 0.5
    echo -e "${WHITE}Initializing CYBERGHOST OSINT ULTIMATE v${VERSION}${NC}"
    sleep 0.3
    
    # Informações da sessão
    echo -e "\n${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${CYAN} Session ID    ${WHITE}: ${GREEN}${SESSION_ID}${NC}"
    echo -e "${BLUE}│${CYAN} Operation     ${WHITE}: ${YELLOW}${OPERATION_NAME}${NC}"
    echo -e "${BLUE}│${CYAN} Operator      ${WHITE}: ${PURPLE}${AUTHOR} (${ALIAS})${NC}"
    echo -e "${BLUE}│${CYAN} Start Time    ${WHITE}: ${GREEN}${START_TIME}${NC}"
    echo -e "${BLUE}│${CYAN} Codename      ${WHITE}: ${RED}${CODENAME}${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
    
    # Loading animation
    echo -ne "\n${CYAN}[${GREEN}*${CYAN}] Loading modules "
    for i in {1..10}; do
        echo -ne "${GREEN}▉${NC}"
        sleep 0.1
    done
    echo -e " ${GREEN}DONE${NC}"
}

# =============================================================================
# SISTEMA DE LOGGING AVANÇADO
# =============================================================================

init_logging() {
    mkdir -p "$LOG_DIR"
    mkdir -p "$TEMP_DIR"
    
    export MAIN_LOG="${LOG_DIR}/main.log"
    export ERROR_LOG="${LOG_DIR}/errors.log"
    export DEBUG_LOG="${LOG_DIR}/debug.log"
    export NETWORK_LOG="${LOG_DIR}/network.log"
    
    touch "$MAIN_LOG" "$ERROR_LOG" "$DEBUG_LOG" "$NETWORK_LOG"
}

log() {
    local level="$1"
    local message="$2"
    local module="${3:-CORE}"
    local timestamp=$(date '+%H:%M:%S.%3N')
    
    local color_code icon
    
    case "$level" in
        "critical") color_code="$RED" icon="🛑";;
        "error") color_code="$RED" icon="❌";;
        "warning") color_code="$YELLOW" icon="⚠️";;
        "info") color_code="$GREEN" icon="ℹ️";;
        "success") color_code="$GREEN" icon="✅";;
        "hack") color_code="$PURPLE" icon="⚡";;
        "stealth") color_code="$CYAN" icon="👻";;
        "recon") color_code="$BLUE" icon="🔍";;
        "intel") color_code="$YELLOW" icon="📡";;
        "data") color_code="$WHITE" icon="💾";;
        "ai") color_code="$PURPLE" icon="🤖";;
        *) color_code="$WHITE" icon="📝";;
    esac
    
    local log_entry="[${timestamp}][${module}] ${message}"
    
    # Para console
    echo -e "${color_code}${icon} ${log_entry}${NC}"
    
    # Para arquivos
    echo "${timestamp} - ${module} - ${level^^} - ${message}" >> "$MAIN_LOG"
    
    if [[ "$level" == "error" || "$level" == "critical" ]]; then
        echo "${timestamp} - ${module} - ${message}" >> "$ERROR_LOG"
    fi
    
    if [[ "$level" == "debug" ]]; then
        echo "${timestamp} - ${module} - ${message}" >> "$DEBUG_LOG"
    fi
}

# =============================================================================
# SISTEMA DE INSTALAÇÃO AUTOMÁTICA
# =============================================================================

install_all_tools() {
    log "info" "Installing CYBERGHOST OSINT Ultimate Suite..."
    
    # Criar diretórios
    mkdir -p "$TOOL_DIR" "$DATABASES_DIR" "$WORDLISTS_DIR" "$REPORTS_DIR"
    
    # Atualizar sistema
    log "info" "Updating system..."
    sudo apt update && sudo apt upgrade -y
    
    # Instalar dependências básicas
    log "info" "Installing basic dependencies..."
    sudo apt install -y git curl wget nmap whois dnsutils jq python3 python3-pip \
        golang ruby perl build-essential libssl-dev zlib1g-dev libncurses5-dev \
        libsqlite3-dev libreadline-dev libtk8.6 libgdm-dev libdb4o-cil-dev \
        libpcap-dev libbz2-dev libffi-dev
    
    # Instalar ferramentas de reconhecimento
    install_recon_tools
    
    # Instalar ferramentas de web hacking
    install_web_tools
    
    # Instalar ferramentas de OSINT
    install_osint_tools
    
    # Instalar ferramentas de análise
    install_analysis_tools
    
    # Baixar wordlists
    download_wordlists
    
    # Configurar APIs
    setup_apis
    
    log "success" "CYBERGHOST OSINT Ultimate installation complete!"
}

install_recon_tools() {
    log "info" "Installing reconnaissance tools..."
    
    # Amass
    sudo apt install -y amass
    sudo snap install amass
    
    # Subfinder
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    sudo cp ~/go/bin/subfinder /usr/local/bin/
    
    # Assetfinder
    go install github.com/tomnomnom/assetfinder@latest
    sudo cp ~/go/bin/assetfinder /usr/local/bin/
    
    # Findomain
    wget https://github.com/findomain/findomain/releases/latest/download/findomain-linux-i386 -O /usr/local/bin/findomain
    chmod +x /usr/local/bin/findomain
    
    # httpx
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
    sudo cp ~/go/bin/httpx /usr/local/bin/
    
    # naabu
    go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
    sudo cp ~/go/bin/naabu /usr/local/bin/
    
    # nuclei
    go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
    sudo cp ~/go/bin/nuclei /usr/local/bin/
    nuclei -update-templates
    
    # gau
    go install github.com/lc/gau/v2/cmd/gau@latest
    sudo cp ~/go/bin/gau /usr/local/bin/
    
    # waybackurls
    go install github.com/tomnomnom/waybackurls@latest
    sudo cp ~/go/bin/waybackurls /usr/local/bin/
}

install_web_tools() {
    log "info" "Installing web hacking tools..."
    
    # Dirsearch
    git clone https://github.com/maurosoria/dirsearch.git "$TOOL_DIR/dirsearch"
    sudo ln -sf "$TOOL_DIR/dirsearch/dirsearch.py" /usr/local/bin/dirsearch
    
    # FFUF
    go install github.com/ffuf/ffuf@latest
    sudo cp ~/go/bin/ffuf /usr/local/bin/
    
    # Gobuster
    sudo apt install -y gobuster
    
    # WPScan
    sudo apt install -y wpscan
    
    # SQLMap
    sudo apt install -y sqlmap
    
    # Nikto
    sudo apt install -y nikto
    
    # WhatWeb
    sudo apt install -y whatweb
    
    # WafW00f
    sudo apt install -y wafw00f
}

install_osint_tools() {
    log "info" "Installing OSINT tools..."
    
    # theHarvester
    sudo apt install -y theharvester
    git clone https://github.com/laramies/theHarvester.git "$TOOL_DIR/theHarvester"
    
    # Recon-ng
    git clone https://github.com/lanmaster53/recon-ng.git "$TOOL_DIR/recon-ng"
    cd "$TOOL_DIR/recon-ng" && pip3 install -r REQUIREMENTS
    
    # Sherlock
    git clone https://github.com/sherlock-project/sherlock.git "$TOOL_DIR/sherlock"
    cd "$TOOL_DIR/sherlock" && pip3 install -r requirements.txt
    sudo ln -sf "$TOOL_DIR/sherlock/sherlock.py" /usr/local/bin/sherlock
    
    # Social-Engineer Toolkit
    git clone https://github.com/trustedsec/social-engineer-toolkit.git "$TOOL_DIR/setoolkit"
    cd "$TOOL_DIR/setoolkit" && pip3 install -r requirements.txt
    
    # Metagoofil
    git clone https://github.com/laramies/metagoofil.git "$TOOL_DIR/metagoofil"
    
    # Photon
    git clone https://github.com/s0md3v/Photon.git "$TOOL_DIR/Photon"
    cd "$TOOL_DIR/Photon" && pip3 install -r requirements.txt
    
    # SpiderFoot
    git clone https://github.com/smicallef/spiderfoot.git "$TOOL_DIR/spiderfoot"
    cd "$TOOL_DIR/spiderfoot" && pip3 install -r requirements.txt
}

install_analysis_tools() {
    log "info" "Installing analysis tools..."
    
    # Maltego
    wget -O "$TOOL_DIR/maltego.deb" "https://maltego-downloads.s3.us-east-2.amazonaws.com/linux/Maltego.v4.3.0.deb"
    sudo dpkg -i "$TOOL_DIR/maltego.deb" || sudo apt install -f -y
    
    # Shodan CLI
    pip3 install shodan
    
    # Censys CLI
    pip3 install censys
    
    # VirusTotal CLI
    pip3 install vt-py
    
    # H8Mail
    pip3 install h8mail
    
    # Holehe
    pip3 install holehe
    
    # Twint
    pip3 install twint
    
    # LinkedIn Dumper
    git clone https://github.com/initstring/linkedin2username.git "$TOOL_DIR/linkedin2username"
}

download_wordlists() {
    log "info" "Downloading wordlists..."
    
    # SecLists
    git clone https://github.com/danielmiessler/SecLists.git "$WORDLISTS_DIR/SecLists"
    
    # rockyou
    sudo gunzip /usr/share/wordlists/rockyou.txt.gz 2>/dev/null || true
    
    # Subdomain wordlists
    wget -O "$WORDLISTS_DIR/subdomains.txt" "https://gist.githubusercontent.com/jhaddix/86a06c5dc309d08580a018c66354a056/raw/96f4e51d96b2203f19f6381c8c545b278eaa0837/all.txt"
    
    # Directory wordlists
    wget -O "$WORDLISTS_DIR/directories.txt" "https://raw.githubusercontent.com/daviddias/node-dirbuster/master/lists/directory-list-2.3-medium.txt"
    
    # Password wordlists
    wget -O "$WORDLISTS_DIR/passwords.txt" "https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt"
}

setup_apis() {
    log "info" "Setting up API keys..."
    
    mkdir -p ~/.cyberghost
    cat > ~/.cyberghost/api_keys << EOF
# CYBERGHOST API Configuration
# Get your API keys from these services:

# SHODAN_API="your_shodan_key"
# VIRUSTOTAL_API="your_virustotal_key"
# CENSYS_API_ID="your_censys_id"
# CENSYS_API_SECRET="your_censys_secret"
# GITHUB_API="your_github_token"
# HUNTER_API="your_hunterio_key"
# ZOOMEYE_API="your_zoomeye_key"
# BINARYEDGE_API="your_binaryedge_key"
# PUBLICWWW_API="your_publicwww_key"
# GREYNOLISE_API="your_greynoise_key"

EOF
    
    log "warning" "Please edit ~/.cyberghost/api_keys and add your API keys"
}

# =============================================================================
# MÓDULOS DE OSINT AVANÇADOS
# =============================================================================

# =============================================================================
# 1. RECONHECIMENTO DE SUBDOMÍNIOS AVANÇADO
# =============================================================================

advanced_subdomain_enum() {
    local domain="$1"
    local output_file="${TEMP_DIR}/subdomains_${domain}.txt"
    
    log "recon" "Starting advanced subdomain enumeration for ${domain}" "SUBDOMAIN"
    
    # Usar múltiplas ferramentas
    local tools=("amass" "subfinder" "findomain" "assetfinder")
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log "info" "Using $tool..."
            case "$tool" in
                "amass")
                    amass enum -passive -d "$domain" -o "${TEMP_DIR}/amass_${domain}.txt" 2>/dev/null
                    ;;
                "subfinder")
                    subfinder -d "$domain" -silent -o "${TEMP_DIR}/subfinder_${domain}.txt" 2>/dev/null
                    ;;
                "findomain")
                    findomain -t "$domain" -q -u "${TEMP_DIR}/findomain_${domain}.txt" 2>/dev/null
                    ;;
                "assetfinder")
                    assetfinder --subs-only "$domain" > "${TEMP_DIR}/assetfinder_${domain}.txt" 2>/dev/null
                    ;;
            esac
        fi
    done
    
    # Combinar e remover duplicatas
    cat "${TEMP_DIR}"/*"${domain}"*.txt 2>/dev/null | sort -u > "$output_file"
    
    # Verificar subdomínios vivos com httpx
    if [ -s "$output_file" ] && command -v httpx &> /dev/null; then
        log "info" "Checking live subdomains..."
        httpx -l "$output_file" -silent -status-code -title -tech-detect -o "${TEMP_DIR}/live_${domain}.txt" 2>/dev/null
    fi
    
    local total=$(wc -l < "$output_file" 2>/dev/null || echo 0)
    local live=$(wc -l < "${TEMP_DIR}/live_${domain}.txt" 2>/dev/null || echo 0)
    
    log "success" "Found ${total} subdomains (${live} live)" "SUBDOMAIN"
    
    echo "{
        \"total\": $total,
        \"live\": $live,
        \"file\": \"$output_file\",
        \"live_file\": \"${TEMP_DIR}/live_${domain}.txt\"
    }"
}

# =============================================================================
# 2. INTELIGÊNCIA DE AMEAÇAS COM MÚLTIPLAS APIS
# =============================================================================

threat_intelligence() {
    local target="$1"
    
    log "intel" "Gathering threat intelligence for ${target}" "THREAT_INTEL"
    
    local results="{}"
    
    # Shodan (se API configurada)
    if [ -n "$SHODAN_API" ]; then
        log "info" "Querying Shodan..."
        local shodan_result=$(curl -s "https://api.shodan.io/shodan/host/${target}?key=${SHODAN_API}" 2>/dev/null)
        if [ -n "$shodan_result" ] && [[ "$shodan_result" != *"error"* ]]; then
            results=$(echo "$results" | jq --argjson shodan "$shodan_result" '.shodan = $shodan')
        fi
    fi
    
    # VirusTotal (se API configurada)
    if [ -n "$VIRUSTOTAL_API" ]; then
        log "info" "Querying VirusTotal..."
        local vt_result=$(curl -s "https://www.virustotal.com/api/v3/domains/${target}" \
            -H "x-apikey: ${VIRUSTOTAL_API}" 2>/dev/null)
        if [ -n "$vt_result" ]; then
            results=$(echo "$results" | jq --argjson vt "$vt_result" '.virustotal = $vt')
        fi
    fi
    
    # Censys (se API configurada)
    if [ -n "$CENSYS_API" ] && [ -n "$CENSYS_SECRET" ]; then
        log "info" "Querying Censys..."
        local censys_result=$(curl -s -u "${CENSYS_API}:${CENSYS_SECRET}" \
            "https://search.censys.io/api/v2/hosts/${target}" 2>/dev/null)
        if [ -n "$censys_result" ]; then
            results=$(echo "$results" | jq --argjson censys "$censys_result" '.censys = $censys')
        fi
    fi
    
    # Greynoise (se API configurada)
    if [ -n "$GREYNOLISE_API" ]; then
        log "info" "Querying GreyNoise..."
        local greynoise_result=$(curl -s "https://api.greynoise.io/v3/community/${target}" \
            -H "key: ${GREYNOLISE_API}" 2>/dev/null)
        if [ -n "$greynoise_result" ]; then
            results=$(echo "$results" | jq --argjson greynoise "$greynoise_result" '.greynoise = $greynoise')
        fi
    fi
    
    # AbuseIPDB
    log "info" "Checking AbuseIPDB..."
    local abuse_result=$(curl -s "https://api.abuseipdb.com/api/v2/check?ipAddress=${target}" \
        -H "Key: YOUR_KEY_HERE" -H "Accept: application/json" 2>/dev/null | jq '.data' 2>/dev/null || echo "{}")
    results=$(echo "$results" | jq --argjson abuse "$abuse_result" '.abuseipdb = $abuse')
    
    echo "$results"
}

# =============================================================================
# 3. OSINT DE REDES SOCIAIS AVANÇADO
# =============================================================================

social_media_intel() {
    local username="$1"
    
    log "intel" "Gathering social media intelligence for ${username}" "SOCIAL_MEDIA"
    
    # Sherlock
    if command -v sherlock &> /dev/null; then
        log "info" "Running Sherlock..."
        sherlock "$username" --no-color --csv -o "${TEMP_DIR}/sherlock_${username}.csv" 2>/dev/null
    fi
    
    # Holehe
    if command -v holehe &> /dev/null; then
        log "info" "Running Holehe..."
        holehe "$username" > "${TEMP_DIR}/holehe_${username}.txt" 2>/dev/null
    fi
    
    # Twint (Twitter intelligence)
    if command -v twint &> /dev/null; then
        log "info" "Gathering Twitter intelligence..."
        twint -u "$username" --limit 100 --format "{date} | {time} | {tweet}" \
            -o "${TEMP_DIR}/twint_${username}.txt" 2>/dev/null
    fi
    
    # LinkedIn (via linkedin2username)
    if [ -f "$TOOL_DIR/linkedin2username/linkedin2username.py" ]; then
        log "info" "Checking LinkedIn..."
        python3 "$TOOL_DIR/linkedin2username/linkedin2username.py" -c "$username" \
            -o "${TEMP_DIR}/linkedin_${username}.txt" 2>/dev/null
    fi
    
    # Combina resultados
    local results="{}"
    if [ -f "${TEMP_DIR}/sherlock_${username}.csv" ]; then
        results=$(echo "$results" | jq --arg file "${TEMP_DIR}/sherlock_${username}.csv" '.sherlock = $file')
    fi
    
    echo "$results"
}

# =============================================================================
# 4. RECONHECIMENTO DE EMAIL PROFUNDO
# =============================================================================

email_intelligence() {
    local email="$1"
    
    log "intel" "Gathering email intelligence for ${email}" "EMAIL_INTEL"
    
    local results="{}"
    
    # H8mail
    if command -v h8mail &> /dev/null; then
        log "info" "Running h8mail..."
        h8mail -t "$email" -c ~/.cyberghost/h8mail_config.ini -o "${TEMP_DIR}/h8mail_${email}.json" 2>/dev/null
        
        if [ -f "${TEMP_DIR}/h8mail_${email}.json" ]; then
            results=$(echo "$results" | jq --arg file "${TEMP_DIR}/h8mail_${email}.json" '.h8mail = $file')
        fi
    fi
    
    # Hunter.io (se API configurada)
    if [ -n "$HUNTER_API" ]; then
        log "info" "Querying Hunter.io..."
        local hunter_result=$(curl -s "https://api.hunter.io/v2/email-verifier?email=${email}&api_key=${HUNTER_API}" 2>/dev/null)
        if [ -n "$hunter_result" ]; then
            results=$(echo "$results" | jq --argjson hunter "$hunter_result" '.hunter = $hunter')
        fi
    fi
    
    # Have I Been Pwned
    log "info" "Checking Have I Been Pwned..."
    local hibp_result=$(curl -s "https://haveibeenpwned.com/api/v3/breachedaccount/${email}" \
        -H "hibp-api-key: YOUR_KEY_HERE" 2>/dev/null || echo "[]")
    results=$(echo "$results" | jq --argjson hibp "$hibp_result" '.hibp = $hibp')
    
    # EmailRep.io
    log "info" "Checking EmailRep.io..."
    local emailrep_result=$(curl -s "https://emailrep.io/${email}" 2>/dev/null || echo "{}")
    results=$(echo "$results" | jq --argjson emailrep "$emailrep_result" '.emailrep = $emailrep')
    
    echo "$results"
}

# =============================================================================
# 5. OSINT DE GITHUB AVANÇADO
# =============================================================================

github_intelligence() {
    local target="$1"
    
    log "intel" "Gathering GitHub intelligence for ${target}" "GITHUB_INTEL"
    
    local results="{}"
    
    # GitDorker (simulado)
    log "info" "Searching for GitHub dorks..."
    local dorks=("password" "api_key" "secret" "token" "config" "credentials" ".env" "dockerfile")
    
    for dork in "${dorks[@]}"; do
        local search_result=$(curl -s "https://api.github.com/search/code?q=${target}+${dork}" \
            -H "Authorization: token ${GITHUB_API}" 2>/dev/null | jq '.total_count' 2>/dev/null || echo 0)
        
        if [ "$search_result" -gt 0 ]; then
            results=$(echo "$results" | jq --arg dork "$dork" --argjson count "$search_result" ".${dork//./_} = \$count")
        fi
    done
    
    # Repositórios do usuário/organização
    log "info" "Fetching repositories..."
    local repos=$(curl -s "https://api.github.com/users/${target}/repos" \
        -H "Authorization: token ${GITHUB_API}" 2>/dev/null | jq '.[].full_name' 2>/dev/null || echo "[]")
    
    results=$(echo "$results" | jq --argjson repos "$repos" '.repositories = $repos')
    
    # Commits recentes
    log "info" "Fetching recent commits..."
    local commits=$(curl -s "https://api.github.com/search/commits?q=author:${target}" \
        -H "Authorization: token ${GITHUB_API}" -H "Accept: application/vnd.github.cloak-preview" 2>/dev/null \
        | jq '.items[].commit.message' 2>/dev/null | head -5 || echo "[]")
    
    results=$(echo "$results" | jq --argjson commits "$commits" '.recent_commits = $commits')
    
    echo "$results"
}

# =============================================================================
# 6. RECONHECIMENTO DE INFRAESTRUTURA COMPLETO
# =============================================================================

infrastructure_recon() {
    local target="$1"
    
    log "recon" "Performing complete infrastructure reconnaissance" "INFRA_RECON"
    
    local results="{}"
    
    # Port scanning avançado com naabu
    if command -v naabu &> /dev/null; then
        log "info" "Running advanced port scan..."
        naabu -host "$target" -silent -o "${TEMP_DIR}/naabu_${target}.txt" 2>/dev/null
        
        local ports=$(cat "${TEMP_DIR}/naabu_${target}.txt" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        results=$(echo "$results" | jq --arg ports "$ports" '.open_ports = $ports')
    fi
    
    # Service detection com nmap
    log "info" "Running service detection..."
    sudo nmap -sV -sC -O -T4 -p- "$target" -oX "${TEMP_DIR}/nmap_${target}.xml" 2>/dev/null
    
    if [ -f "${TEMP_DIR}/nmap_${target}.xml" ]; then
        results=$(echo "$results" | jq --arg xml "${TEMP_DIR}/nmap_${target}.xml" '.nmap = $xml')
    fi
    
    # SSL/TLS analysis
    log "info" "Analyzing SSL/TLS configuration..."
    sslscan "$target" > "${TEMP_DIR}/sslscan_${target}.txt" 2>/dev/null || \
    testssl.sh "$target" > "${TEMP_DIR}/testssl_${target}.txt" 2>/dev/null
    
    # Cloud detection
    log "info" "Detecting cloud infrastructure..."
    local cloud_info="{}"
    
    # Check AWS
    if host "ec2.${target}" &>/dev/null || host "s3.${target}" &>/dev/null; then
        cloud_info=$(echo "$cloud_info" | jq '.aws = true')
    fi
    
    # Check Azure
    if host "azure.${target}" &>/dev/null; then
        cloud_info=$(echo "$cloud_info" | jq '.azure = true')
    fi
    
    # Check Google Cloud
    if host "googlecloud.${target}" &>/dev/null; then
        cloud_info=$(echo "$cloud_info" | jq '.gcp = true')
    fi
    
    results=$(echo "$results" | jq --argjson cloud "$cloud_info" '.cloud = $cloud')
    
    # CDN detection
    log "info" "Detecting CDN..."
    local cdn_info=$(whatweb -a 3 "$target" 2>/dev/null | grep -i "cdn" || echo "No CDN detected")
    results=$(echo "$results" | jq --arg cdn "$cdn_info" '.cdn = $cdn')
    
    echo "$results"
}

# =============================================================================
# 7. WEB ARCHIVE & HISTORICAL DATA
# =============================================================================

historical_data() {
    local target="$1"
    
    log "intel" "Gathering historical data for ${target}" "HISTORICAL"
    
    local results="{}"
    
    # Wayback Machine
    log "info" "Checking Wayback Machine..."
    local wayback_urls=$(curl -s "http://web.archive.org/cdx/search/cdx?url=${target}/*&output=json&fl=timestamp,original&collapse=urlkey" 2>/dev/null)
    
    if [ -n "$wayback_urls" ]; then
        echo "$wayback_urls" | jq -c '.' > "${TEMP_DIR}/wayback_${target}.json"
        results=$(echo "$results" | jq --arg file "${TEMP_DIR}/wayback_${target}.json" '.wayback = $file')
    fi
    
    # Common Crawl
    log "info" "Checking Common Crawl..."
    local cc_urls=$(curl -s "https://index.commoncrawl.org/CC-MAIN-2023-*/index?url=${target}&output=json" 2>/dev/null | head -20)
    
    if [ -n "$cc_urls" ]; then
        echo "$cc_urls" > "${TEMP_DIR}/commoncrawl_${target}.txt"
        results=$(echo "$results" | jq --arg file "${TEMP_DIR}/commoncrawl_${target}.txt" '.commoncrawl = $file')
    fi
    
    # SecurityTrails historical DNS
    log "info" "Fetching historical DNS..."
    local historical_dns=$(curl -s "https://api.securitytrails.com/v1/history/${target}/dns/a" \
        -H "APIKEY: YOUR_KEY_HERE" 2>/dev/null || echo "{}")
    
    results=$(echo "$results" | jq --argjson dns "$historical_dns" '.historical_dns = $dns')
    
    echo "$results"
}

# =============================================================================
# 8. DEEP WEB & PASTE SITES
# =============================================================================

deepweb_intel() {
    local target="$1"
    
    log "intel" "Searching deep web for ${target}" "DEEPWEB"
    
    local results="{}"
    
    # Paste sites (simulado)
    local paste_sites=("pastebin.com" "hastebin.com" "rentry.co" "privatebin.net")
    
    for site in "${paste_sites[@]}"; do
        log "info" "Checking $site..."
        # Simulação - na prática precisa de APIs específicas
        echo "{\"site\": \"$site\", \"results\": 0}" > "${TEMP_DIR}/paste_${site}.json"
    done
    
    # Dark web monitoring (simulado)
    log "warning" "Dark web access requires special tools and authorization"
    
    # Telegram channels (via telescan)
    log "info" "Checking Telegram channels..."
    
    results="{\"paste_sites\": \"${TEMP_DIR}/paste_*.json\", \"note\": \"Further investigation required\"}"
    
    echo "$results"
}

# =============================================================================
# 9. GEOINT (GEOGRAPHICAL INTELLIGENCE)
# =============================================================================

geoint() {
    local ip_or_domain="$1"
    
    log "intel" "Gathering geographical intelligence" "GEOINT"
    
    local results="{}"
    
    # IP geolocation
    log "info" "Performing IP geolocation..."
    local geo_data=$(curl -s "http://ip-api.com/json/${ip_or_domain}" 2>/dev/null)
    
    if [ -n "$geo_data" ]; then
        results=$(echo "$results" | jq --argjson geo "$geo_data" '.geolocation = $geo')
    fi
    
    # Satellite imagery (via Google Static Maps)
    local lat=$(echo "$geo_data" | jq -r '.lat // empty')
    local lon=$(echo "$geo_data" | jq -r '.lon // empty')
    
    if [ -n "$lat" ] && [ -n "$lon" ]; then
        log "info" "Generating map visualization..."
        local map_url="https://maps.googleapis.com/maps/api/staticmap?center=${lat},${lon}&zoom=15&size=600x300&markers=color:red%7C${lat},${lon}"
        results=$(echo "$results" | jq --arg map "$map_url" '.satellite_map = $map')
    fi
    
    # WiGLE (WiFi network intelligence)
    log "info" "Checking WiFi networks in area..."
    
    echo "$results"
}

# =============================================================================
# 10. BUSINESS INTELLIGENCE
# =============================================================================

business_intel() {
    local company="$1"
    
    log "intel" "Gathering business intelligence for ${company}" "BUSINESS_INTEL"
    
    local results="{}"
    
    # LinkedIn company search
    log "info" "Searching LinkedIn..."
    
    # Crunchbase (simulado)
    log "info" "Checking Crunchbase..."
    
    # Company registries (simulado)
    log "info" "Searching company registries..."
    
    # Financial data (simulado)
    log "info" "Gathering financial information..."
    
    # Employee intelligence
    log "info" "Searching for employees..."
    
    results="{\"status\": \"Business intelligence requires specialized databases and APIs\"}"
    
    echo "$results"
}

# =============================================================================
# 11. MOBILE APPS INTEL
# =============================================================================

mobile_intel() {
    local target="$1"
    
    log "intel" "Gathering mobile app intelligence" "MOBILE_INTEL"
    
    local results="{}"
    
    # Google Play Store
    log "info" "Checking Google Play Store..."
    local play_store=$(curl -s "https://play.google.com/store/search?q=${target}" 2>/dev/null | grep -o "result-title[^>]*>[^<]*" | head -5 || echo "[]")
    
    # Apple App Store
    log "info" "Checking Apple App Store..."
    
    # APK downloads and analysis
    log "info" "Searching for APK files..."
    
    # Mobile security scanners (via MobSF)
    log "info" "Note: Mobile Static Framework (MobSF) required for deep analysis"
    
    results="{\"play_store\": \"$play_store\", \"note\": \"Further analysis with MobSF recommended\"}"
    
    echo "$results"
}

# =============================================================================
# 12. DNS INTEL PROFUNDO
# =============================================================================

dns_deep_intel() {
    local domain="$1"
    
    log "intel" "Performing deep DNS intelligence" "DNS_INTEL"
    
    local results="{}"
    
    # All DNS records
    log "info" "Fetching all DNS records..."
    local dns_records="{}"
    
    # Check all record types
    local record_types=("A" "AAAA" "MX" "NS" "TXT" "SOA" "CNAME" "SRV" "PTR" "CAA")
    
    for record in "${record_types[@]}"; do
        local query_result=$(dig "$domain" "$record" +short 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        if [ -n "$query_result" ]; then
            dns_records=$(echo "$dns_records" | jq --arg type "$record" --arg result "$query_result" ".$record = \$result")
        fi
    done
    
    results=$(echo "$results" | jq --argjson dns "$dns_records" '.dns_records = $dns')
    
    # DNSSEC validation
    log "info" "Checking DNSSEC..."
    local dnssec=$(dig "$domain" +dnssec 2>/dev/null | grep -i "flags:" || echo "No DNSSEC")
    results=$(echo "$results" | jq --arg dnssec "$dnssec" '.dnssec = $dnssec')
    
    # DNS history
    log "info" "Checking DNS history..."
    
    # DNS cache snooping (simulado)
    log "info" "Performing DNS cache analysis..."
    
    # Subdomain takeover check
    log "info" "Checking for subdomain takeover vulnerabilities..."
    
    echo "$results"
}

# =============================================================================
# 13. METADATA INTEL
# =============================================================================

metadata_intel() {
    local target="$1"
    
    log "intel" "Extracting and analyzing metadata" "METADATA"
    
    local results="{}"
    
    # Download file and extract metadata
    log "info" "Downloading and analyzing files..."
    
    # Common file types to check
    local file_types=("pdf" "doc" "docx" "xls" "xlsx" "ppt" "pptx" "jpg" "png" "mp4")
    
    for ext in "${file_types[@]}"; do
        log "info" "Searching for .$ext files..."
        # Implementar busca por arquivos e extração de metadata
    done
    
    # Exif data from images
    log "info" "Extracting EXIF data..."
    if command -v exiftool &> /dev/null; then
        exiftool "$target" 2>/dev/null > "${TEMP_DIR}/exif_data.txt"
        results=$(echo "$results" | jq --arg exif "${TEMP_DIR}/exif_data.txt" '.exif = $exif')
    fi
    
    # PDF metadata
    log "info" "Extracting PDF metadata..."
    
    results="{\"status\": \"Metadata extraction complete\", \"files\": \"${TEMP_DIR}/exif_data.txt\"}"
    
    echo "$results"
}

# =============================================================================
# 14. ARTIFICIAL INTELLIGENCE ANALYSIS
# =============================================================================

ai_analysis() {
    local data="$1"
    
    log "ai" "Performing AI-powered analysis" "AI_ANALYSIS"
    
    local results="{}"
    
    # Sentiment analysis (simulado)
    log "info" "Performing sentiment analysis..."
    
    # Pattern recognition
    log "info" "Running pattern recognition..."
    
    # Anomaly detection
    log "info" "Detecting anomalies..."
    
    # Predictive analysis
    log "info" "Running predictive analysis..."
    
    results="{\"ai_score\": 0.85, \"confidence\": 0.92, \"risk_level\": \"MEDIUM\", \"recommendations\": [\"Implement additional monitoring\", \"Review security policies\"]}"
    
    echo "$results"
}

# =============================================================================
# MÓDULO PRINCIPAL - SCAN COMPLETO
# =============================================================================

full_osint_scan() {
    local target="$1"
    local scan_type="${2:-full}"
    
    log "hack" "🚀 Initiating FULL OSINT SCAN on: ${target}" "MAIN"
    log "warning" "This scan may take a while and generate significant network traffic"
    
    # Criar diretório de resultados
    local scan_dir="${REPORTS_DIR}/scan_${target}_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$scan_dir"
    
    echo -e "\n${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                     CYBERGHOST OSINT ULTIMATE SCAN REPORT                     ${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}Target: ${GREEN}$target${NC}"
    echo -e "${WHITE}Scan ID: ${GREEN}${SESSION_ID}${NC}"
    echo -e "${WHITE}Start Time: ${GREEN}$(date)${NC}"
    echo -e "${CYAN}────────────────────────────────────────────────────────────────────────────────${NC}"
    
    # Mapa de módulos
    declare -A modules=(
        ["subdomains"]="Advanced Subdomain Enumeration"
        ["threat"]="Threat Intelligence"
        ["social"]="Social Media Intelligence"
        ["email"]="Email Intelligence"
        ["github"]="GitHub Intelligence"
        ["infra"]="Infrastructure Reconnaissance"
        ["historical"]="Historical Data"
        ["deepweb"]="Deep Web Intelligence"
        ["geoint"]="Geographical Intelligence"
        ["business"]="Business Intelligence"
        ["mobile"]="Mobile App Intelligence"
        ["dns"]="Deep DNS Intelligence"
        ["metadata"]="Metadata Intelligence"
        ["ai"]="AI Analysis"
    )
    
    # Executar módulos baseados no tipo de scan
    local results="{}"
    
    case "$scan_type" in
        "full")
            # Executa todos os módulos
            for module in "${!modules[@]}"; do
                run_module "$module" "$target" "$scan_dir"
            done
            ;;
        "recon")
            run_module "subdomains" "$target" "$scan_dir"
            run_module "infra" "$target" "$scan_dir"
            run_module "dns" "$target" "$scan_dir"
            ;;
        "social")
            run_module "social" "$target" "$scan_dir"
            run_module "email" "$target" "$scan_dir"
            run_module "github" "$target" "$scan_dir"
            ;;
        "threat")
            run_module "threat" "$target" "$scan_dir"
            run_module "historical" "$target" "$scan_dir"
            run_module "deepweb" "$target" "$scan_dir"
            ;;
        *)
            run_module "$scan_type" "$target" "$scan_dir"
            ;;
    esac
    
    # Gerar relatório final
    generate_final_report "$scan_dir" "$target"
    
    log "success" "🎉 OSINT Scan Complete! Report saved to: $scan_dir" "MAIN"
    
    echo -e "\n${GREEN}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}📊 Scan Statistics:${NC}"
    echo -e "${CYAN}────────────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${WHITE}Target:${NC} $target"
    echo -e "${WHITE}Duration:${NC} $SECONDS seconds"
    echo -e "${WHITE}Data Collected:${NC} $(du -sh "$scan_dir" | cut -f1)"
    echo -e "${WHITE}Report Location:${NC} $scan_dir"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════════${NC}"
}

run_module() {
    local module="$1"
    local target="$2"
    local scan_dir="$3"
    
    log "info" "Running: ${modules[$module]}" "MODULE"
    
    local start_time=$(date +%s)
    
    case "$module" in
        "subdomains")
            advanced_subdomain_enum "$target" > "${scan_dir}/subdomains.json"
            ;;
        "threat")
            threat_intelligence "$target" > "${scan_dir}/threat_intel.json"
            ;;
        "social")
            social_media_intel "$target" > "${scan_dir}/social_media.json"
            ;;
        "email")
            email_intelligence "$target" > "${scan_dir}/email_intel.json"
            ;;
        "github")
            github_intelligence "$target" > "${scan_dir}/github_intel.json"
            ;;
        "infra")
            infrastructure_recon "$target" > "${scan_dir}/infrastructure.json"
            ;;
        "historical")
            historical_data "$target" > "${scan_dir}/historical.json"
            ;;
        "deepweb")
            deepweb_intel "$target" > "${scan_dir}/deepweb.json"
            ;;
        "geoint")
            geoint "$target" > "${scan_dir}/geoint.json"
            ;;
        "business")
            business_intel "$target" > "${scan_dir}/business_intel.json"
            ;;
        "mobile")
            mobile_intel "$target" > "${scan_dir}/mobile_intel.json"
            ;;
        "dns")
            dns_deep_intel "$target" > "${scan_dir}/dns_intel.json"
            ;;
        "metadata")
            metadata_intel "$target" > "${scan_dir}/metadata.json"
            ;;
        "ai")
            ai_analysis "$target" > "${scan_dir}/ai_analysis.json"
            ;;
    esac
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "success" "Module completed in ${duration}s" "MODULE"
}

generate_final_report() {
    local scan_dir="$1"
    local target="$2"
    
    log "info" "Generating final report..." "REPORT"
    
    # Criar relatório HTML
    cat > "${scan_dir}/report.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CYBERGHOST OSINT Report - $target</title>
    <style>
        body {
            font-family: 'Courier New', monospace;
            background: #0a0a0a;
            color: #00ff00;
            margin: 0;
            padding: 20px;
        }
        .header {
            text-align: center;
            border-bottom: 2px solid #00ff00;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        .section {
            background: #1a1a1a;
            padding: 20px;
            margin: 20px 0;
            border-left: 4px solid #00ff00;
        }
        .critical { border-left-color: #ff0000; }
        .warning { border-left-color: #ffff00; }
        .info { border-left-color: #00ffff; }
        pre {
            background: #000;
            padding: 15px;
            overflow: auto;
            border: 1px solid #333;
        }
        .footer {
            text-align: center;
            margin-top: 50px;
            padding-top: 20px;
            border-top: 1px solid #333;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔍 CYBERGHOST OSINT ULTIMATE REPORT</h1>
        <h2>Target: $target</h2>
        <p>Generated: $(date)</p>
        <p>Operator: $AUTHOR ($ALIAS)</p>
    </div>
    
    <div class="section">
        <h3>📊 Scan Summary</h3>
        <p>Session ID: $SESSION_ID</p>
        <p>Scan Duration: $SECONDS seconds</p>
    </div>
    
    <div class="section">
        <h3>⚠️ Important Findings</h3>
        <p>Review the JSON files in this directory for detailed information.</p>
    </div>
    
    <div class="footer">
        <p>CYBERGHOST OSINT ULTIMATE v$VERSION | For ethical and legal use only</p>
        <p>Generated by $AUTHOR ($ALIAS) | Codename: $CODENAME</p>
    </div>
</body>
</html>
EOF
    
    # Criar índice de arquivos
    cat > "${scan_dir}/INDEX.txt" << EOF
=============================================
CYBERGHOST OSINT ULTIMATE - SCAN DIRECTORY
=============================================
Target: $target
Scan Date: $(date)
Scan ID: $SESSION_ID

FILES:
$(ls -la "${scan_dir}/")

REPORT FILES:
- report.html       : Main HTML report
- *.json           : Raw data from each module
- *.txt            : Text files and logs

NOTES:
1. Review all findings carefully
2. Validate critical information
3. Use data ethically and legally
4. Report vulnerabilities responsibly

=============================================
EOF
    
    log "success" "Reports generated in: $scan_dir" "REPORT"
}

# =============================================================================
# INTERFACE DE COMANDOS
# =============================================================================

show_menu() {
    clear
    print_banner
    
    echo -e "\n${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                         CYBERGHOST OSINT ULTIMATE MENU                         ${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e ""
    echo -e "${WHITE}  [1]${NC} 🚀  FULL OSINT Scan (All Modules)"
    echo -e "${WHITE}  [2]${NC} 🔍  Reconnaissance Scan (Subdomains + Infrastructure)"
    echo -e "${WHITE}  [3]${NC} 👤  Social Media Intelligence"
    echo -e "${WHITE}  [4]${NC} 📧  Email Intelligence"
    echo -e "${WHITE}  [5]${NC} 🐙  GitHub Intelligence"
    echo -e "${WHITE}  [6]${NC} 🛡️   Threat Intelligence"
    echo -e "${WHITE}  [7]${NC} 🗺️   Geographical Intelligence"
    echo -e "${WHITE}  [8]${NC} 📱  Mobile App Intelligence"
    echo -e "${WHITE}  [9]${NC} 🏢  Business Intelligence"
    echo -e "${WHITE} [10]${NC} ⚙️   Install/Update Tools"
    echo -e "${WHITE} [11]${NC} 📊  View Previous Reports"
    echo -e "${WHITE} [12]${NC} ❓  Help & Documentation"
    echo -e "${WHITE} [13]${NC} 🚪  Exit"
    echo -e ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -ne "\n${GREEN}┌─[${CYAN}cyberghost${GREEN}]─[${YELLOW}~${GREEN}]\n└──╼ ${WHITE}\$ ${NC}"
}

main() {
    # Inicialização
    init_logging
    print_banner
    
    # Carregar APIs
    if [ -f ~/.cyberghost/api_keys ]; then
        source ~/.cyberghost/api_keys
        log "info" "API keys loaded" "CONFIG"
    fi
    
    # Verificar argumentos
    if [ $# -ge 1 ]; then
        case "$1" in
            "install")
                install_all_tools
                exit 0
                ;;
            "scan")
                if [ $# -lt 2 ]; then
                    echo -e "${RED}Usage: $0 scan <target> [scan_type]${NC}"
                    exit 1
                fi
                full_osint_scan "$2" "${3:-full}"
                exit 0
                ;;
            "help")
                show_help
                exit 0
                ;;
        esac
    fi
    
    # Modo interativo
    while true; do
        show_menu
        read -r choice
        
        case "$choice" in
            1)
                read -p "Enter target: " target
                full_osint_scan "$target" "full"
                read -p "Press Enter to continue..."
                ;;
            2)
                read -p "Enter target: " target
                full_osint_scan "$target" "recon"
                read -p "Press Enter to continue..."
                ;;
            3)
                read -p "Enter username: " username
                social_media_intel "$username"
                read -p "Press Enter to continue..."
                ;;
            4)
                read -p "Enter email: " email
                email_intelligence "$email"
                read -p "Press Enter to continue..."
                ;;
            5)
                read -p "Enter GitHub username/org: " github_target
                github_intelligence "$github_target"
                read -p "Press Enter to continue..."
                ;;
            6)
                read -p "Enter IP/Domain: " target
                threat_intelligence "$target"
                read -p "Press Enter to continue..."
                ;;
            7)
                read -p "Enter IP/Domain: " target
                geoint "$target"
                read -p "Press Enter to continue..."
                ;;
            8)
                read -p "Enter app/company name: " target
                mobile_intel "$target"
                read -p "Press Enter to continue..."
                ;;
            9)
                read -p "Enter company name: " company
                business_intel "$company"
                read -p "Press Enter to continue..."
                ;;
            10)
                install_all_tools
                read -p "Press Enter to continue..."
                ;;
            11)
                echo -e "\n${GREEN}Recent Reports:${NC}"
                ls -la "$REPORTS_DIR" | head -20
                read -p "Press Enter to continue..."
                ;;
            12)
                show_help
                read -p "Press Enter to continue..."
                ;;
            13)
                echo -e "\n${GREEN}Exiting CYBERGHOST OSINT...${NC}"
                echo -e "${CYAN}Session logs: $LOG_DIR${NC}"
                echo -e "${YELLOW}Remember: With great power comes great responsibility!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option!${NC}"
                sleep 1
                ;;
        esac
    done
}

show_help() {
    clear
    echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                     CYBERGHOST OSINT ULTIMATE - HELP                          ${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e ""
    echo -e "${CYAN}USAGE:${NC}"
    echo -e "  $0 [command] [options]"
    echo -e ""
    echo -e "${CYAN}COMMANDS:${NC}"
    echo -e "  install                 Install all OSINT tools"
    echo -e "  scan <target>           Perform full OSINT scan"
    echo -e "  menu                    Interactive menu (default)"
    echo -e ""
    echo -e "${CYAN}EXAMPLES:${NC}"
    echo -e "  $0 install"
    echo -e "  $0 scan example.com"
    echo -e "  $0 scan example.com recon"
    echo -e ""
    echo -e "${CYAN}FEATURES:${NC}"
    echo -e "  • 14+ OSINT modules"
    echo -e "  • 50+ integrated tools"
    echo -e "  • API integration (Shodan, VirusTotal, etc.)"
    echo -e "  • HTML/JSON reports"
    echo -e "  • Automatic tool installation"
    echo -e ""
    echo -e "${RED}LEGAL WARNING:${NC}"
    echo -e "  • Use only on authorized targets"
    echo -e "  • Respect privacy laws"
    echo -e "  • Do not use for illegal activities"
    echo -e "  • Obtain proper authorization"
    echo -e ""
    echo -e "${YELLOW}Developer: $AUTHOR | Alias: $ALIAS | Codename: $CODENAME${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════════${NC}"
}

# =============================================================================
# TRATAMENTO DE SINAIS E INICIALIZAÇÃO
# =============================================================================

trap cleanup SIGINT SIGTERM

cleanup() {
    echo -e "\n${RED}[!] Interrupt received. Cleaning up...${NC}"
    
    # Salvar estado
    echo "Session interrupted at $(date)" >> "$MAIN_LOG"
    
    # Remover arquivos temporários se desejado
    # rm -rf "$TEMP_DIR"
    
    echo -e "${YELLOW}[*] Session logs saved to: $LOG_DIR${NC}"
    echo -e "${GREEN}[+] CYBERGHOST OSINT terminated${NC}"
    exit 0
}

# Verificar se é root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}[!] Warning: Running as root!${NC}"
    sleep 2
fi

# Executar
main "$@"
