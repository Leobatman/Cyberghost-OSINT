#!/bin/bash

# =============================================================================
# CYBERGHOST OSINT - Bash Version for Kali Linux
# Desenvolvido por: Leonardo Pereira Pinheiro
# Código: Shadow Warrior | Alias: CyberGhost
# Licença: GPL-3.0 | Uso Ético e Legal Requerido
# =============================================================================

# Configuração de cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Emojis
INFO="ℹ️"
WARNING="⚠️"
ERROR="❌"
SUCCESS="✅"
HACK="⚡"
STEALTH="👻"
DATA="💾"
TARGET="🎯"
PORT="🔌"
WEB="🌐"
DOMAIN="🏷️"

# =============================================================================
# CONFIGURAÇÃO DO SISTEMA
# =============================================================================

VERSION="5.0"
AUTHOR="Leonardo Pereira Pinheiro"
ALIAS="CyberGhost"
CODENAME="Shadow Warrior"
SESSION_ID=$(date +%s%N | md5sum | head -c 8)
START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="cyberghost_${SESSION_ID}.log"
REPORTS_DIR="reports"

# Configuração de operação
MAX_THREADS=5
TIMEOUT=30
RETRIES=3
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 CyberGhost/5.0"

# =============================================================================
# FUNÇÕES DE LOGGING E UTILITÁRIAS
# =============================================================================

print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                                  ║"
    echo "║  ██████╗██╗   ██╗██████╗ ███████╗██████╗ ██╗  ██╗ ██████╗ ███████╗███████╗████████╗║"
    echo "║ ██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗██║  ██║██╔═══██╗██╔════╝██╔════╝╚══██╔══╝║"
    echo "║ ██║      ╚████╔╝ ██████╔╝█████╗  ██████╔╝███████║██║   ██║███████╗███████╗   ██║   ║"
    echo "║ ██║       ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗██╔══██║██║   ██║╚════██║╚════██║   ██║   ║"
    echo "║ ╚██████╗   ██║   ██████╔╝███████╗██║  ██║██║  ██║╚██████╔╝███████║███████║   ██║   ║"
    echo "║  ╚═════╝   ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝   ╚═╝   ║"
    echo "║                                                                                    ║"
    echo "║                    CYBERGHOST OSINT v${VERSION} - Shadow Warrior Edition                 ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Session ID: ${SESSION_ID}${NC}"
    echo -e "${GREEN}Start Time: ${START_TIME}${NC}"
    echo -e "${GREEN}Operator: ${AUTHOR}${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

log() {
    local level="$1"
    local message="$2"
    local module="${3:-CORE}"
    local timestamp=$(date '+%H:%M:%S')
    
    case "$level" in
        "info")
            local icon="$INFO"
            local color="$GREEN"
            ;;
        "warning")
            local icon="$WARNING"
            local color="$YELLOW"
            ;;
        "error")
            local icon="$ERROR"
            local color="$RED"
            ;;
        "success")
            local icon="$SUCCESS"
            local color="$GREEN"
            ;;
        "hack")
            local icon="$HACK"
            local color="$MAGENTA"
            ;;
        "stealth")
            local icon="$STEALTH"
            local color="$CYAN"
            ;;
        "data")
            local icon="$DATA"
            local color="$BLUE"
            ;;
        *)
            local icon="$INFO"
            local color="$WHITE"
            ;;
    esac
    
    local log_entry="[${timestamp}][${module}] ${message}"
    echo -e "${color}${icon} ${log_entry}${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ${module} - ${level} - ${message}" >> "$LOG_FILE"
}

check_dependencies() {
    log "info" "Checking system dependencies..."
    
    local missing_deps=()
    
    # Ferramentas essenciais
    declare -A essential_tools=(
        ["curl"]="curl"
        ["wget"]="wget"
        ["nmap"]="nmap"
        ["whois"]="whois"
        ["dig"]="dnsutils"
        ["host"]="dnsutils"
        ["nslookup"]="dnsutils"
        ["grep"]="grep"
        ["sed"]="sed"
        ["awk"]="awk"
        ["jq"]="jq"
    )
    
    for tool in "${!essential_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_deps+=("${essential_tools[$tool]}")
        fi
    done
    
    # Ferramentas recomendadas
    declare -A recommended_tools=(
        ["sublist3r"]="Sublist3r"
        ["amass"]="amass"
        ["theHarvester"]="theharvester"
        ["nikto"]="nikto"
        ["sqlmap"]="sqlmap"
        ["gobuster"]="gobuster"
        ["dirb"]="dirb"
        ["whatweb"]="whatweb"
        ["wafw00f"]="wafw00f"
    )
    
    local missing_rec=()
    for tool in "${!recommended_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_rec+=("${recommended_tools[$tool]}")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log "error" "Missing essential dependencies:"
        for dep in "${missing_deps[@]}"; do
            echo -e "  ${RED}•${NC} $dep"
        done
        echo ""
        echo -e "${YELLOW}Install with:${NC}"
        echo -e "  sudo apt update && sudo apt install ${missing_deps[*]}"
        exit 1
    fi
    
    if [ ${#missing_rec[@]} -gt 0 ]; then
        log "warning" "Some recommended tools are not installed:"
        for dep in "${missing_rec[@]}"; do
            echo -e "  ${YELLOW}•${NC} $dep"
        done
        echo ""
        echo -e "${YELLOW}Advanced features may be limited without these tools${NC}"
    fi
    
    log "success" "Dependencies check completed"
}

# =============================================================================
# MÓDULOS DE RECONHECIMENTO
# =============================================================================

enumerate_subdomains() {
    local domain="$1"
    local output_file="${REPORTS_DIR}/subdomains_${domain}.txt"
    
    log "hack" "Enumerating subdomains for ${domain}" "SUBDOMAIN"
    
    local subdomains=()
    
    # Método 1: Usando findomain (se disponível)
    if command -v findomain &> /dev/null; then
        log "info" "Using findomain for subdomain enumeration"
        findomain -t "$domain" -q -u "${output_file}_findomain.txt" 2>/dev/null
    fi
    
    # Método 2: Usando sublist3r (se disponível)
    if command -v sublist3r &> /dev/null; then
        log "info" "Using Sublist3r for subdomain enumeration"
        sublist3r -d "$domain" -o "${output_file}_sublist3r.txt" 2>/dev/null
    fi
    
    # Método 3: DNS brute force básico
    log "info" "Performing DNS brute force"
    local wordlist=("www" "mail" "ftp" "ssh" "admin" "api" "dev" "test" "staging" "prod" 
                   "web" "webmail" "portal" "blog" "shop" "store" "app" "mobile" "m" 
                   "support" "help" "docs" "wiki" "forum" "community" "status" "monitor")
    
    for sub in "${wordlist[@]}"; do
        local full_domain="${sub}.${domain}"
        if host "$full_domain" &>/dev/null; then
            subdomains+=("$full_domain")
            echo "$full_domain" >> "$output_file"
        fi
    done
    
    # Combina todos os resultados
    cat "${output_file}"* 2>/dev/null | sort -u > "$output_file"
    
    local count=$(wc -l < "$output_file" 2>/dev/null || echo 0)
    
    echo "{
        \"total_found\": $count,
        \"subdomains\": [$(if [ -s "$output_file" ]; then 
            while IFS= read -r line; do echo -n "\"$line\","; done < "$output_file" | sed 's/,$//'
        fi)],
        \"techniques\": [\"dns_lookup\", \"bruteforce\"]
    }"
}

port_scanning() {
    local target="$1"
    local output_file="${REPORTS_DIR}/ports_${target}.txt"
    
    log "hack" "Port scanning ${target}" "PORTSCAN"
    
    # Scan básico com nmap
    if command -v nmap &> /dev/null; then
        log "info" "Running basic Nmap scan"
        nmap -sS -T4 -p- --open "$target" -oG "$output_file" 2>/dev/null
        
        # Extrai portas abertas
        local open_ports=$(grep "Ports:" "$output_file" | cut -d: -f2 | tr '/' ',' | tr '\t' '\n' | grep open | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')
        
        echo "{
            \"open_ports\": [$open_ports],
            \"total_open\": $(echo "$open_ports" | tr ',' '\n' | wc -l)
        }"
    else
        # Scan básico com netcat
        log "warning" "Nmap not found, using basic port scan"
        local common_ports="80,443,22,21,25,110,143,445,3389,8080,8443"
        local open_ports=""
        
        IFS=',' read -ra ports <<< "$common_ports"
        for port in "${ports[@]}"; do
            if timeout 1 bash -c "cat < /dev/null > /dev/tcp/$target/$port" 2>/dev/null; then
                open_ports="${open_ports}${port},"
                log "info" "Port $port is open" "PORTSCAN"
            fi
        done
        
        open_ports=$(echo "$open_ports" | sed 's/,$//')
        
        echo "{
            \"open_ports\": [$open_ports],
            \"total_open\": $(if [ -n "$open_ports" ]; then echo "$open_ports" | tr ',' '\n' | wc -l; else echo 0; fi)
        }"
    fi
}

technology_fingerprinting() {
    local target="$1"
    local output_file="${REPORTS_DIR}/tech_${target}.txt"
    
    log "info" "Fingerprinting technologies for ${target}" "TECH"
    
    local technologies="{}"
    
    # Usa whatweb (se disponível)
    if command -v whatweb &> /dev/null; then
        log "info" "Using WhatWeb for technology detection"
        whatweb -a 3 "https://$target" 2>/dev/null | head -20 > "$output_file"
        
        # Parse básico dos resultados
        if [ -s "$output_file" ]; then
            technologies="{\"whatweb\": \"$(cat "$output_file" | tr '\n' ';' | sed 's/"/\\"/g')\"}"
        fi
    fi
    
    # Verifica HTTP headers
    log "info" "Checking HTTP headers"
    local headers_file="${REPORTS_DIR}/headers_${target}.txt"
    curl -I -s "https://$target" -m 5 > "$headers_file" 2>/dev/null || curl -I -s "http://$target" -m 5 > "$headers_file" 2>/dev/null
    
    if [ -s "$headers_file" ]; then
        local server=$(grep -i "^server:" "$headers_file" | head -1 | cut -d: -f2 | sed 's/^[[:space:]]*//')
        local powered_by=$(grep -i "^x-powered-by:" "$headers_file" | head -1 | cut -d: -f2 | sed 's/^[[:space:]]*//')
        
        echo "{
            \"server\": \"$server\",
            \"powered_by\": \"$powered_by\",
            \"headers_file\": \"$headers_file\"
        }"
    else
        echo "{\"error\": \"Could not fetch headers\"}"
    fi
}

whois_analysis() {
    local domain="$1"
    local output_file="${REPORTS_DIR}/whois_${domain}.txt"
    
    log "info" "WHOIS analysis for ${domain}" "WHOIS"
    
    if command -v whois &> /dev/null; then
        whois "$domain" > "$output_file" 2>/dev/null
        
        # Extrai informações importantes
        local registrar=$(grep -i "Registrar:" "$output_file" | head -1 | cut -d: -f2- | sed 's/^[[:space:]]*//')
        local creation_date=$(grep -i "Creation Date:" "$output_file" | head -1 | cut -d: -f2- | sed 's/^[[:space:]]*//')
        local expiration_date=$(grep -i "Expiration Date:" "$output_file" | head -1 | cut -d: -f2- | sed 's/^[[:space:]]*//')
        local name_servers=$(grep -i "Name Server:" "$output_file" | cut -d: -f2- | sed 's/^[[:space:]]*//' | tr '\n' ',' | sed 's/,$//')
        
        # Calcula idade do domínio
        local age_days="N/A"
        if [ -n "$creation_date" ]; then
            local creation_epoch=$(date -d "$creation_date" +%s 2>/dev/null || echo "")
            if [ -n "$creation_epoch" ]; then
                local now_epoch=$(date +%s)
                age_days=$(( (now_epoch - creation_epoch) / 86400 ))
            fi
        fi
        
        echo "{
            \"registrar\": \"$registrar\",
            \"creation_date\": \"$creation_date\",
            \"expiration_date\": \"$expiration_date\",
            \"name_servers\": [$(if [ -n "$name_servers" ]; then echo "$name_servers" | sed 's/,/\",\"/g' | sed 's/^/\"/' | sed 's/$/\"/'; fi)],
            \"age_days\": $age_days
        }"
    else
        echo "{\"error\": \"whois command not found\"}"
    fi
}

web_content_analysis() {
    local target="$1"
    local output_file="${REPORTS_DIR}/webcontent_${target}.txt"
    
    log "info" "Analyzing web content for ${target}" "WEB"
    
    # Tenta HTTPS primeiro, depois HTTP
    local content=""
    local status_code=""
    local content_type=""
    
    # Usa curl para obter informações
    local response=$(curl -s -I -L -m 10 -A "$USER_AGENT" "https://$target" 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$response" ]; then
        response=$(curl -s -I -L -m 10 -A "$USER_AGENT" "http://$target" 2>/dev/null)
    fi
    
    if [ -n "$response" ]; then
        status_code=$(echo "$response" | grep -i "^HTTP" | head -1 | awk '{print $2}')
        content_type=$(echo "$response" | grep -i "^content-type:" | head -1 | cut -d: -f2- | sed 's/^[[:space:]]*//')
        
        # Baixa conteúdo da página
        curl -s -L -m 10 -A "$USER_AGENT" "https://$target" 2>/dev/null > "$output_file" || \
        curl -s -L -m 10 -A "$USER_AGENT" "http://$target" 2>/dev/null > "$output_file"
        
        if [ -s "$output_file" ]; then
            # Extrai título
            local title=$(grep -i '<title>' "$output_file" | head -1 | sed 's/.*<title>//' | sed 's/<\/title>.*//')
            
            # Conta links
            local links_count=$(grep -i '<a href' "$output_file" | wc -l)
            
            # Conta palavras
            local word_count=$(cat "$output_file" | wc -w)
            
            # Verifica forms
            local has_forms=$(grep -i '<form' "$output_file" | wc -l)
            
            echo "{
                \"status\": $status_code,
                \"title\": \"$title\",
                \"links_count\": $links_count,
                \"word_count\": $word_count,
                \"has_forms\": $(if [ $has_forms -gt 0 ]; then echo "true"; else echo "false"; fi),
                \"content_type\": \"$content_type\"
            }"
        else
            echo "{\"error\": \"Could not download content\"}"
        fi
    else
        echo "{\"error\": \"Could not connect to target\"}"
    fi
}

# =============================================================================
# RECONHECIMENTO COMPLETO
# =============================================================================

full_reconnaissance() {
    local target="$1"
    
    log "info" "Initiating reconnaissance on ${target}" "RECON"
    
    # Cria diretório de relatórios
    mkdir -p "$REPORTS_DIR"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Executa todos os módulos
    log "info" "Starting subdomain enumeration..."
    local subdomains=$(enumerate_subdomains "$target")
    
    log "info" "Starting port scanning..."
    local ports=$(port_scanning "$target")
    
    log "info" "Starting technology fingerprinting..."
    local tech=$(technology_fingerprinting "$target")
    
    log "info" "Starting WHOIS analysis..."
    local whois_data=$(whois_analysis "$target")
    
    log "info" "Starting web content analysis..."
    local web_content=$(web_content_analysis "$target")
    
    # Combina resultados
    echo "{
        \"target\": \"$target\",
        \"timestamp\": \"$timestamp\",
        \"operator\": \"$ALIAS\",
        \"recon_data\": {
            \"enumerate_subdomains\": $subdomains,
            \"port_scanning\": $ports,
            \"technology_fingerprinting\": $tech,
            \"whois_analysis\": $whois_data,
            \"web_content_analysis\": $web_content
        }
    }"
}

# =============================================================================
# ANÁLISE DE INTELIGÊNCIA
# =============================================================================

analyze_threat_pattern() {
    local data="$1"
    
    # Extrai dados do JSON
    local sub_count=$(echo "$data" | jq -r '.recon_data.enumerate_subdomains.total_found // 0')
    local port_count=$(echo "$data" | jq -r '.recon_data.port_scanning.total_open // 0')
    
    # Calcula score de risco
    local risk_score=0
    
    # Subdomínios
    if [ "$sub_count" -gt 20 ]; then
        risk_score=$((risk_score + 3))
    elif [ "$sub_count" -gt 10 ]; then
        risk_score=$((risk_score + 2))
    elif [ "$sub_count" -gt 5 ]; then
        risk_score=$((risk_score + 1))
    fi
    
    # Portas abertas
    if [ "$port_count" -gt 15 ]; then
        risk_score=$((risk_score + 3))
    elif [ "$port_count" -gt 10 ]; then
        risk_score=$((risk_score + 2))
    elif [ "$port_count" -gt 5 ]; then
        risk_score=$((risk_score + 1))
    fi
    
    # Determina nível de risco
    local risk_level="LOW"
    if [ "$risk_score" -ge 5 ]; then
        risk_level="HIGH"
    elif [ "$risk_score" -ge 3 ]; then
        risk_level="MEDIUM"
    fi
    
    # Gera recomendações
    local recommendations="[]"
    if [ "$sub_count" -gt 20 ]; then
        recommendations=$(echo "$recommendations" | jq '. + [{"source": "System", "priority": "MEDIUM", "recommendation": "Review and clean up unused subdomains"}]')
    fi
    
    if [ "$port_count" -gt 15 ]; then
        recommendations=$(echo "$recommendations" | jq '. + [{"source": "System", "priority": "HIGH", "recommendation": "Close unnecessary open ports"}]')
    fi
    
    if [ "$(echo "$recommendations" | jq 'length')" -eq 0 ]; then
        recommendations=$(echo "$recommendations" | jq '. + [{"source": "System", "priority": "INFO", "recommendation": "Regular security audits recommended"}]')
    fi
    
    echo "{
        \"risk_prediction\": {
            \"score\": $risk_score,
            \"level\": \"$risk_level\",
            \"confidence\": 0.7
        },
        \"recommendations\": $recommendations
    }"
}

# =============================================================================
# SISTEMA DE RELATÓRIOS
# =============================================================================

generate_text_report() {
    local data="$1"
    local target=$(echo "$data" | jq -r '.target')
    local report_file="${REPORTS_DIR}/cyberghost_${target}_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
╔══════════════════════════════════════════════════════════════════════╗
║                        CYBERGHOST OSINT REPORT                       ║
║                     Target: $target
║                     Date: $(date '+%Y-%m-%d %H:%M:%S')
║                     Operator: $AUTHOR
╚══════════════════════════════════════════════════════════════════════╝

SUMMARY:
--------
Target: $target
Scan Time: $(date '+%Y-%m-%d %H:%M:%S')

FINDINGS:
---------
EOF
    
    # Subdomains
    local sub_count=$(echo "$data" | jq -r '.recon_data.enumerate_subdomains.total_found // 0')
    echo -e "\nSubdomains Found: $sub_count" >> "$report_file"
    
    if [ "$sub_count" -gt 0 ]; then
        echo "$data" | jq -r '.recon_data.enumerate_subdomains.subdomains[]?' | head -10 | while read -r sub; do
            echo "  • $sub" >> "$report_file"
        done
    fi
    
    # Ports
    local port_count=$(echo "$data" | jq -r '.recon_data.port_scanning.total_open // 0')
    echo -e "\nOpen Ports: $port_count" >> "$report_file"
    
    if [ "$port_count" -gt 0 ]; then
        echo "$data" | jq -r '.recon_data.port_scanning.open_ports[]?' | while read -r port; do
            echo "  • Port $port" >> "$report_file"
        done
    fi
    
    # WHOIS
    local registrar=$(echo "$data" | jq -r '.recon_data.whois_analysis.registrar // "N/A"')
    local creation_date=$(echo "$data" | jq -r '.recon_data.whois_analysis.creation_date // "N/A"')
    local age_days=$(echo "$data" | jq -r '.recon_data.whois_analysis.age_days // "N/A"')
    
    echo -e "\nWHOIS Information:" >> "$report_file"
    echo "  • Registrar: $registrar" >> "$report_file"
    echo "  • Created: $creation_date" >> "$report_file"
    echo "  • Age: $age_days days" >> "$report_file"
    
    # Recommendations
    local rec_count=$(echo "$data" | jq -r '.intelligence.recommendations | length // 0')
    if [ "$rec_count" -gt 0 ]; then
        echo -e "\nRECOMMENDATIONS:" >> "$report_file"
        for i in $(seq 0 $((rec_count - 1))); do
            local priority=$(echo "$data" | jq -r ".intelligence.recommendations[$i].priority")
            local recommendation=$(echo "$data" | jq -r ".intelligence.recommendations[$i].recommendation")
            echo "  • [$priority] $recommendation" >> "$report_file"
        done
    fi
    
    echo -e "\n$(printf '%.0s-' {1..60})" >> "$report_file"
    echo "Report generated by CYBERGHOST OSINT v$VERSION" >> "$report_file"
    echo "For ethical and legal use only" >> "$report_file"
    
    echo "$report_file"
}

generate_json_report() {
    local data="$1"
    local target=$(echo "$data" | jq -r '.target')
    local report_file="${REPORTS_DIR}/cyberghost_${target}_$(date +%Y%m%d_%H%M%S).json"
    
    echo "$data" | jq '.' > "$report_file"
    
    echo "$report_file"
}

# =============================================================================
# FUNÇÃO PRINCIPAL DE SCAN
# =============================================================================

ghost_scan() {
    local target="$1"
    local mode="${2:-stealth}"
    
    log "stealth" "Beginning ghost scan of $target"
    
    # Reconhecimento
    local recon_data=$(full_reconnaissance "$target")
    
    # Análise de IA
    local intel_data=$(analyze_threat_pattern "$recon_data")
    
    # Combina dados
    local full_data=$(echo "{}" | jq \
        --argjson recon "$recon_data" \
        --argjson intel "$intel_data" \
        --arg target "$target" \
        --arg mode "$mode" \
        --arg version "$VERSION" \
        --arg operator "$AUTHOR ($ALIAS)" \
        '. + $recon + {
            intelligence: $intel,
            metadata: {
                scan_id: "'$(uuidgen)'",
                timestamp: "'$(date -Iseconds)'",
                operator: $operator,
                mode: $mode,
                version: $version
            }
        }')
    
    # Gera relatórios
    log "info" "Generating reports..."
    local text_report=$(generate_text_report "$full_data")
    local json_report=$(generate_json_report "$full_data")
    
    # Log de conclusão
    local threat_level=$(echo "$intel_data" | jq -r '.risk_prediction.level // "UNKNOWN"')
    log "success" "Ghost scan completed for $target - Threat: $threat_level"
    
    # Imprime resumo
    print_scan_summary "$full_data" "$text_report" "$json_report"
    
    echo "{
        \"data\": $full_data,
        \"reports\": {
            \"txt\": \"$text_report\",
            \"json\": \"$json_report\"
        },
        \"success\": true
    }"
}

print_scan_summary() {
    local data="$1"
    local text_report="$2"
    local json_report="$3"
    
    local target=$(echo "$data" | jq -r '.target')
    local threat_level=$(echo "$data" | jq -r '.intelligence.risk_prediction.level // "N/A"')
    local sub_count=$(echo "$data" | jq -r '.recon_data.enumerate_subdomains.total_found // 0')
    local port_count=$(echo "$data" | jq -r '.recon_data.port_scanning.total_open // 0')
    local confidence=$(echo "$data" | jq -r '.intelligence.risk_prediction.confidence // 0')
    
    echo -e "\n${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN} CYBERGHOST SCAN SUMMARY - $target${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${WHITE}Target:${NC} $target"
    echo -e "${WHITE}Threat Level:${NC} $threat_level"
    echo -e "${WHITE}Subdomains Found:${NC} $sub_count"
    echo -e "${WHITE}Open Ports:${NC} $port_count"
    echo -e "${WHITE}Confidence:${NC} $(echo "$confidence * 100" | bc | cut -d. -f1)%"
    echo ""
    echo -e "${CYAN}Reports Generated:${NC}"
    echo -e "  ${GREEN}•${NC} TXT: $text_report"
    echo -e "  ${GREEN}•${NC} JSON: $json_report"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
}

# =============================================================================
# SCAN EM BATCH
# =============================================================================

ghost_batch() {
    local targets_file="$1"
    local concurrent="${2:-3}"
    
    if [ ! -f "$targets_file" ]; then
        log "error" "Targets file not found: $targets_file"
        exit 1
    fi
    
    local targets=()
    while IFS= read -r line || [ -n "$line" ]; do
        line=$(echo "$line" | xargs)
        if [ -n "$line" ] && [[ ! "$line" =~ ^# ]]; then
            targets+=("$line")
        fi
    done < "$targets_file"
    
    log "info" "Starting batch scan of ${#targets[@]} targets"
    
    local results=()
    local successful=0
    local failed=0
    
    # Cria diretório para resultados do batch
    local batch_dir="${REPORTS_DIR}/batch_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$batch_dir"
    
    # Processa cada alvo
    for target in "${targets[@]}"; do
        log "info" "Processing: $target"
        
        local result=$(ghost_scan "$target" "batch")
        
        if echo "$result" | jq -e '.success' > /dev/null 2>&1; then
            ((successful++))
            results+=("$result")
        else
            ((failed++))
            log "error" "Failed to scan: $target"
        fi
        
        echo "$result" > "${batch_dir}/${target//[^a-zA-Z0-9]/_}.json"
    done
    
    # Gera relatório consolidado
    generate_batch_report "$batch_dir" "$successful" "$failed" "${#targets[@]}"
    
    echo "{
        \"summary\": {
            \"total_targets\": ${#targets[@]},
            \"successful_scans\": $successful,
            \"failed_scans\": $failed,
            \"batch_dir\": \"$batch_dir\"
        }
    }"
}

generate_batch_report() {
    local batch_dir="$1"
    local successful="$2"
    local failed="$3"
    local total="$4"
    
    local report_file="${batch_dir}/batch_report.json"
    
    cat > "$report_file" << EOF
{
    "summary": {
        "total_targets": $total,
        "successful_scans": $successful,
        "failed_scans": $failed,
        "success_rate": $(echo "scale=2; $successful * 100 / $total" | bc),
        "completion_time": "$(date -Iseconds)"
    },
    "batch_directory": "$batch_dir"
}
EOF
    
    log "success" "Batch report saved: $report_file"
}

# =============================================================================
# INTERFACE DE COMANDOS
# =============================================================================

show_help() {
    echo -e "${GREEN}CYBERGHOST OSINT v${VERSION} - Advanced Cyber Intelligence Platform${NC}"
    echo ""
    echo -e "${CYAN}Usage:${NC}"
    echo "  $0 [command] [options]"
    echo ""
    echo -e "${CYAN}Commands:${NC}"
    echo "  scan <target>        Scan single target"
    echo "  batch <file>         Batch scan from file"
    echo "  help                 Show this help"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo "  $0 scan example.com"
    echo "  $0 batch targets.txt"
    echo ""
    echo -e "${YELLOW}Warning: Use only for ethical and legal purposes!${NC}"
    echo -e "${WHITE}Developer: $AUTHOR | Alias: $ALIAS${NC}"
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    # Inicialização
    print_banner
    check_dependencies
    
    # Verifica argumentos
    if [ $# -lt 1 ]; then
        show_help
        exit 1
    fi
    
    local command="$1"
    
    case "$command" in
        "scan")
            if [ $# -lt 2 ]; then
                log "error" "Usage: $0 scan <target>"
                exit 1
            fi
            ghost_scan "$2"
            ;;
            
        "batch")
            if [ $# -lt 2 ]; then
                log "error" "Usage: $0 batch <targets_file>"
                exit 1
            fi
            ghost_batch "$2"
            ;;
            
        "help"|"--help"|"-h")
            show_help
            ;;
            
        *)
            log "error" "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Tratamento de interrupção
trap 'echo -e "\n${YELLOW}[!] Operation terminated by user${NC}"; exit 1' INT

# Executa o script
main "$@"
