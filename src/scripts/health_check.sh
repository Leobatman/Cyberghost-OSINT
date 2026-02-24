#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Health Check Script
# =============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Diretórios
INSTALL_DIR="${HOME}/cyberghost-osint"
CONFIG_DIR="${HOME}/.cyberghost"
REPORTS_DIR="${HOME}/CyberGhost_Reports"
LOG_DIR="${INSTALL_DIR}/logs"

# Configurações
CHECK_API="${1:-true}"
CHECK_DEPENDENCIES="${2:-true}"
CHECK_DISK="${3:-true}"
CHECK_PERFORMANCE="${4:-true}"

# Banner
print_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║        CYBERGHOST OSINT ULTIMATE - HEALTH CHECK             ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Verificar sistema operacional
check_os() {
    echo -e "\n${BLUE}[*] Checking Operating System...${NC}"
    
    local os="Unknown"
    local kernel=$(uname -r)
    local arch=$(uname -m)
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        os="$NAME $VERSION"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os="macOS $(sw_vers -productVersion)"
    fi
    
    echo -e "${GREEN}[✓] OS:${NC} $os"
    echo -e "${GREEN}[✓] Kernel:${NC} $kernel"
    echo -e "${GREEN}[✓] Architecture:${NC} $arch"
}

# Verificar espaço em disco
check_disk() {
    if [[ "$CHECK_DISK" != "true" ]]; then
        return
    fi
    
    echo -e "\n${BLUE}[*] Checking disk space...${NC}"
    
    local warn_threshold=90
    local critical_threshold=95
    
    # Verificar partições
    df -h | grep -E '^/dev/' | while read -r line; do
        local usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        local mount=$(echo "$line" | awk '{print $6}')
        local available=$(echo "$line" | awk '{print $4}')
        
        if [[ $usage -ge $critical_threshold ]]; then
            echo -e "${RED}[✗] $mount: ${usage}% used (CRITICAL) - Available: $available${NC}"
        elif [[ $usage -ge $warn_threshold ]]; then
            echo -e "${YELLOW}[!] $mount: ${usage}% used (WARNING) - Available: $available${NC}"
        else
            echo -e "${GREEN}[✓] $mount: ${usage}% used - Available: $available${NC}"
        fi
    done
    
    # Verificar diretórios específicos
    echo -e "\n${CYAN}Directory usage:${NC}"
    
    local dirs=(
        "$INSTALL_DIR"
        "$CONFIG_DIR"
        "$REPORTS_DIR"
        "$LOG_DIR"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            echo -e "  ${GREEN}$dir:${NC} $size"
        fi
    done
}

# Verificar dependências
check_dependencies() {
    if [[ "$CHECK_DEPENDENCIES" != "true" ]]; then
        return
    fi
    
    echo -e "\n${BLUE}[*] Checking dependencies...${NC}"
    
    # Dependências principais
    local main_deps=(
        "curl"
        "wget"
        "jq"
        "git"
        "python3"
        "pip3"
        "nmap"
        "whois"
        "dig"
        "openssl"
    )
    
    echo -e "\n${CYAN}Main dependencies:${NC}"
    for dep in "${main_deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            local version
            version=$("$dep" --version 2>&1 | head -1 | cut -d' ' -f2- | cut -d',' -f1)
            echo -e "  ${GREEN}[✓]${NC} $dep: $version"
        else
            echo -e "  ${RED}[✗]${NC} $dep: Not installed"
        fi
    done
    
    # Ferramentas Go
    echo -e "\n${CYAN}Go tools:${NC}"
    local go_tools=(
        "subfinder"
        "httpx"
        "nuclei"
        "assetfinder"
        "ffuf"
    )
    
    for tool in "${go_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            local version
            version=$("$tool" -version 2>&1 | head -1 | cut -d' ' -f2-)
            echo -e "  ${GREEN}[✓]${NC} $tool: $version"
        else
            echo -e "  ${RED}[✗]${NC} $tool: Not installed"
        fi
    done
    
    # Ferramentas Python
    echo -e "\n${CYAN}Python tools:${NC}"
    local py_tools=(
        "shodan"
        "censys"
        "theHarvester"
        "sherlock"
    )
    
    if [[ -d "${INSTALL_DIR}/venv" ]]; then
        source "${INSTALL_DIR}/venv/bin/activate"
    fi
    
    for tool in "${py_tools[@]}"; do
        if pip show "$tool" &> /dev/null; then
            local version
            version=$(pip show "$tool" | grep Version | cut -d' ' -f2)
            echo -e "  ${GREEN}[✓]${NC} $tool: $version"
        else
            echo -e "  ${RED}[✗]${NC} $tool: Not installed"
        fi
    done
    
    if [[ -n "$VIRTUAL_ENV" ]]; then
        deactivate
    fi
}

# Verificar APIs
check_apis() {
    if [[ "$CHECK_API" != "true" ]]; then
        return
    fi
    
    echo -e "\n${BLUE}[*] Checking API keys...${NC}"
    
    if [[ ! -f "${CONFIG_DIR}/api_keys.conf" ]]; then
        echo -e "${YELLOW}[!] API configuration file not found${NC}"
        return
    fi
    
    # Carregar APIs
    source "${CONFIG_DIR}/api_keys.conf"
    
    # Verificar cada API
    local apis=(
        "SHODAN_API_KEY:Shodan"
        "VIRUSTOTAL_API_KEY:VirusTotal"
        "CENSYS_API_ID:Censys"
        "GREYNOISE_API_KEY:GreyNoise"
        "HUNTER_API_KEY:Hunter.io"
        "SECURITYTRAILS_API_KEY:SecurityTrails"
        "GITHUB_API_KEY:GitHub"
        "HIBP_API_KEY:Have I Been Pwned"
    )
    
    for api in "${apis[@]}"; do
        IFS=':' read -r var name <<< "$api"
        
        if [[ -n "${!var}" ]]; then
            echo -e "  ${GREEN}[✓]${NC} $name: Configured"
            
            # Testar API (opcional)
            if [[ "$var" == "SHODAN_API_KEY" ]]; then
                if curl -s "https://api.shodan.io/api-info?key=${!var}" | grep -q "usage"; then
                    echo -e "      ${GREEN}[✓]${NC} API test passed"
                else
                    echo -e "      ${RED}[✗]${NC} API test failed"
                fi
            fi
        else
            echo -e "  ${YELLOW}[!]${NC} $name: Not configured"
        fi
    done
}

# Verificar serviços
check_services() {
    echo -e "\n${BLUE}[*] Checking services...${NC}"
    
    # Tor
    if pgrep -x "tor" > /dev/null; then
        echo -e "  ${GREEN}[✓]${NC} Tor: Running"
    else
        echo -e "  ${YELLOW}[!]${NC} Tor: Not running"
    fi
    
    # PostgreSQL (se configurado)
    if pgrep -x "postgres" > /dev/null; then
        echo -e "  ${GREEN}[✓]${NC} PostgreSQL: Running"
    fi
    
    # Redis (se configurado)
    if pgrep -x "redis-server" > /dev/null; then
        echo -e "  ${GREEN}[✓]${NC} Redis: Running"
    fi
    
    # Web dashboard (se configurado)
    if pgrep -f "python.*web_dashboard.py" > /dev/null; then
        echo -e "  ${GREEN}[✓]${NC} Web Dashboard: Running"
        
        # Testar conexão
        if curl -s http://localhost:8080/api/status | grep -q "online"; then
            echo -e "      ${GREEN}[✓]${NC} Dashboard API: Responding"
        else
            echo -e "      ${RED}[✗]${NC} Dashboard API: Not responding"
        fi
    fi
}

# Verificar wordlists
check_wordlists() {
    echo -e "\n${BLUE}[*] Checking wordlists...${NC}"
    
    local wordlist_dir="${INSTALL_DIR}/data/wordlists"
    
    if [[ ! -d "$wordlist_dir" ]]; then
        echo -e "${YELLOW}[!] Wordlists directory not found${NC}"
        return
    fi
    
    local required_wordlists=(
        "subdomains.txt"
        "directories.txt"
        "passwords.txt"
        "usernames.txt"
    )
    
    for wl in "${required_wordlists[@]}"; do
        if [[ -f "${wordlist_dir}/${wl}" ]] || [[ -f "${wordlist_dir}/$wl" ]]; then
            local size=$(du -h "${wordlist_dir}/${wl}" 2>/dev/null | cut -f1)
            echo -e "  ${GREEN}[✓]${NC} $wl: $size"
        else
            echo -e "  ${YELLOW}[!]${NC} $wl: Not found"
        fi
    done
    
    # SecLists
    if [[ -d "${wordlist_dir}/SecLists" ]]; then
        local size=$(du -sh "${wordlist_dir}/SecLists" | cut -f1)
        echo -e "  ${GREEN}[✓]${NC} SecLists: $size"
    fi
}

# Verificar logs
check_logs() {
    echo -e "\n${BLUE}[*] Checking logs...${NC}"
    
    if [[ ! -d "$LOG_DIR" ]]; then
        echo -e "${YELLOW}[!] Logs directory not found${NC}"
        return
    fi
    
    # Tamanho total dos logs
    local total_size=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)
    echo -e "  ${GREEN}[✓]${NC} Total log size: $total_size"
    
    # Verificar erros recentes
    if [[ -f "${LOG_DIR}/error.log" ]]; then
        local error_count=$(grep -c "ERROR" "${LOG_DIR}/error.log" 2>/dev/null || echo 0)
        local critical_count=$(grep -c "CRITICAL" "${LOG_DIR}/error.log" 2>/dev/null || echo 0)
        
        echo -e "  ${CYAN}Error count:${NC} $error_count"
        echo -e "  ${RED}Critical count:${NC} $critical_count"
        
        # Mostrar últimos erros
        if [[ $error_count -gt 0 ]]; then
            echo -e "\n${YELLOW}Last 5 errors:${NC}"
            grep "ERROR" "${LOG_DIR}/error.log" | tail -5 | while read -r line; do
                echo "    $line"
            done
        fi
    fi
}

# Verificar performance
check_performance() {
    if [[ "$CHECK_PERFORMANCE" != "true" ]]; then
        return
    fi
    
    echo -e "\n${BLUE}[*] Checking performance...${NC}"
    
    # CPU load
    local load=$(uptime | awk -F'load average:' '{print $2}')
    echo -e "  ${GREEN}[✓]${NC} Load average:$load"
    
    # Memory
    if [[ -f /proc/meminfo ]]; then
        local mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        local mem_free=$(grep MemFree /proc/meminfo | awk '{print $2}')
        local mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        
        mem_total=$((mem_total / 1024))
        mem_free=$((mem_free / 1024))
        mem_available=$((mem_available / 1024))
        
        echo -e "  ${GREEN}[✓]${NC} Memory: Total=${mem_total}MB, Free=${mem_free}MB, Available=${mem_available}MB"
    fi
    
    # Network connectivity
    echo -e "\n${CYAN}Network connectivity:${NC}"
    
    local hosts=("8.8.8.8" "1.1.1.1" "github.com")
    
    for host in "${hosts[@]}"; do
        if ping -c 1 -W 2 "$host" &> /dev/null; then
            local time=$(ping -c 1 "$host" 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | cut -d' ' -f1)
            echo -e "  ${GREEN}[✓]${NC} $host: ${time}ms"
        else
            echo -e "  ${RED}[✗]${NC} $host: Unreachable"
        fi
    done
}

# Gerar relatório
generate_report() {
    local report_file="${LOG_DIR}/health_check_$(date +%Y%m%d_%H%M%S).json"
    
    echo -e "\n${BLUE}[*] Generating health report...${NC}"
    
    # Coletar informações
    cat > "$report_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "user": "$(whoami)",
    "version": "$(cat ${INSTALL_DIR}/VERSION 2>/dev/null || echo 'unknown')",
    "checks": {
        "os": "$(uname -a)",
        "disk": $(df -h --output=source,size,used,avail,pcent,target 2>/dev/null | jq -R -s -c 'split("\n")'),
        "dependencies": $(check_dependencies_json),
        "apis": $(check_apis_json),
        "services": $(check_services_json),
        "performance": {
            "load": "$(uptime)",
            "memory": $(free -j 2>/dev/null | jq -R -s -c 'split("\n")')
        }
    }
}
EOF
    
    echo -e "${GREEN}[✓] Report saved to: $report_file${NC}"
}

# Funções auxiliares para JSON (simplificadas)
check_dependencies_json() {
    echo "{}"
}

check_apis_json() {
    echo "{}"
}

check_services_json() {
    echo "{}"
}

# Função principal
main() {
    print_banner
    
    echo -e "\n${CYAN}Starting comprehensive health check...${NC}"
    echo -e "${CYAN}This may take a few moments${NC}\n"
    
    check_os
    check_disk
    check_dependencies
    check_apis
    check_services
    check_wordlists
    check_logs
    check_performance
    
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                 HEALTH CHECK COMPLETED!                        ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    
    # Perguntar se quer gerar relatório
    echo -e "\n${YELLOW}Generate detailed JSON report? (y/N)${NC}"
    read -r answer
    
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        generate_report
    fi
}

# Executar
main "$@"