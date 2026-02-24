#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Advanced Port Scanner Module
# =============================================================================

MODULE_NAME="Port Scanner"
MODULE_DESC="Multi-threaded port scanning with service detection"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# Configurações
PORT_SCAN_TIMEOUT="${PORT_SCAN_TIMEOUT:-2}"
PORT_SCAN_THREADS="${PORT_SCAN_THREADS:-50}"
PORT_SCAN_RATE="${PORT_SCAN_RATE:-1000}"
PORT_SCAN_TOP_PORTS="${PORT_SCAN_TOP_PORTS:-1000}"

# Lista de portas comuns por serviço
declare -A COMMON_PORTS=(
    ["21"]="FTP"
    ["22"]="SSH"
    ["23"]="Telnet"
    ["25"]="SMTP"
    ["53"]="DNS"
    ["80"]="HTTP"
    ["110"]="POP3"
    ["111"]="RPC"
    ["135"]="RPC"
    ["139"]="NetBIOS"
    ["143"]="IMAP"
    ["443"]="HTTPS"
    ["445"]="SMB"
    ["993"]="IMAPS"
    ["995"]="POP3S"
    ["1723"]="PPTP"
    ["3306"]="MySQL"
    ["3389"]="RDP"
    ["5432"]="PostgreSQL"
    ["5900"]="VNC"
    ["6379"]="Redis"
    ["27017"]="MongoDB"
    ["9200"]="Elasticsearch"
    ["5601"]="Kibana"
    ["8080"]="HTTP-Alt"
    ["8443"]="HTTPS-Alt"
    ["9090"]="Prometheus"
    ["3000"]="Grafana"
    ["5000"]="Docker"
    ["2375"]="Docker-API"
    ["2376"]="Docker-TLS"
)

# Inicializar módulo
init_port_scanner() {
    log "INFO" "Initializing Port Scanner module" "PORT_SCAN"
    
    # Verificar dependências
    local deps=("nc" "nmap" "timeout")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "PORT_SCAN"
        return 1
    fi
    
    return 0
}

# Função principal
port_scanner() {
    local target="$1"
    local output_dir="$2"
    local scan_type="${3:-full}"  # full, quick, top, custom
    
    log "RECON" "Starting port scan on: $target ($scan_type)" "PORT_SCAN"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/port_scan"
    mkdir -p "$results_dir"
    
    local results="{}"
    
    # Validar alvo
    if validate_ip "$target"; then
        results=$(echo "$results" | jq --arg ip "$target" '.target_type = "ip"')
    elif validate_domain "$target"; then
        # Resolver domínio
        local ip
        ip=$(dig +short "$target" A 2>/dev/null | head -1)
        if [[ -n "$ip" ]]; then
            target="$ip"
            results=$(echo "$results" | jq --arg domain "$target" --arg ip "$ip" '.target_type = "domain" | .resolved_ip = $ip')
        else
            log "ERROR" "Could not resolve domain: $target" "PORT_SCAN"
            return 1
        fi
    else
        log "ERROR" "Invalid target: $target" "PORT_SCAN"
        return 1
    fi
    
    # Determinar portas a escanear
    local ports_to_scan=()
    
    case "$scan_type" in
        quick)
            # Portas mais comuns (top 20)
            ports_to_scan=(21 22 23 25 53 80 110 111 135 139 143 443 445 993 995 1723 3306 3389 5900 8080)
            ;;
        top)
            # Top N portas
            ports_to_scan=($(get_top_ports "$PORT_SCAN_TOP_PORTS"))
            ;;
        custom)
            # Portas personalizadas (serão passadas via config)
            ports_to_scan=(${CUSTOM_PORTS[@]})
            ;;
        full)
            # Todas as portas 1-65535
            ports_to_scan=($(seq 1 65535))
            ;;
    esac
    
    log "INFO" "Scanning ${#ports_to_scan[@]} ports" "PORT_SCAN"
    
    # Escolher método de scan
    if command -v masscan &> /dev/null && [[ $EUID -eq 0 ]] && [[ ${#ports_to_scan[@]} -gt 1000 ]]; then
        # Usar masscan para scans grandes
        results=$(masscan_scan "$target" "$ports_to_scan")
    elif command -v nmap &> /dev/null; then
        # Usar nmap para scans detalhados
        results=$(nmap_scan "$target" "$scan_type")
    else
        # Usar netcat para scans básicos
        results=$(nc_scan "$target" "$ports_to_scan")
    fi
    
    # Identificar serviços
    if [[ $(echo "$results" | jq '.open_ports | length') -gt 0 ]]; then
        log "INFO" "Identifying services on open ports" "PORT_SCAN"
        results=$(identify_services "$target" "$results")
    fi
    
    # Detectar SO
    log "INFO" "Attempting OS detection" "PORT_SCAN"
    results=$(detect_os "$target" "$results")
    
    # Verificar portas com vulnerabilidades conhecidas
    log "INFO" "Checking for vulnerable ports" "PORT_SCAN"
    results=$(check_vulnerable_ports "$results")
    
    # Gerar relatório
    local open_count
    open_count=$(echo "$results" | jq '.open_ports | length')
    local closed_count
    closed_count=$(echo "$results" | jq '.closed_ports | length')
    local filtered_count
    filtered_count=$(echo "$results" | jq '.filtered_ports | length')
    
    results=$(echo "$results" | jq \
        --argjson open "$open_count" \
        --argjson closed "$closed_count" \
        --argjson filtered "$filtered_count" \
        '.statistics = {
            "total_scanned": $open + $closed + $filtered,
            "open": $open,
            "closed": $closed,
            "filtered": $filtered
        }')
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/ports.json"
    
    # Gerar saída formatada
    generate_port_report "$results" "${results_dir}/ports.txt"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "SUCCESS" "Port scan completed in ${duration}s - Found $open_count open ports" "PORT_SCAN"
    
    echo "$results"
}

# Scan com masscan
masscan_scan() {
    local target="$1"
    local ports=($2)
    
    local temp_file="${TEMP_DIR}/masscan_$$.txt"
    
    # Converter array de portas para formato masscan
    local ports_str
    ports_str=$(printf "%s," "${ports[@]}" | sed 's/,$//')
    
    # Executar masscan
    masscan -p"$ports_str" --rate="$PORT_SCAN_RATE" -oG "$temp_file" "$target" &>/dev/null
    
    local results='{"open_ports": [], "closed_ports": [], "filtered_ports": []}'
    
    if [[ -f "$temp_file" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ Host:.*Ports:\ ([0-9]+)/open ]]; then
                local port="${BASH_REMATCH[1]}"
                local service="${COMMON_PORTS[$port]:-unknown}"
                
                results=$(echo "$results" | jq \
                    --arg port "$port" \
                    --arg service "$service" \
                    '.open_ports += [{
                        "port": $port|tonumber,
                        "protocol": "tcp",
                        "state": "open",
                        "service": $service
                    }]')
            fi
        done < "$temp_file"
        
        rm -f "$temp_file"
    fi
    
    echo "$results"
}

# Scan com nmap
nmap_scan() {
    local target="$1"
    local scan_type="$2"
    
    local temp_file="${TEMP_DIR}/nmap_$$.xml"
    local results='{"open_ports": [], "closed_ports": [], "filtered_ports": []}'
    
    # Determinar argumentos do nmap
    local nmap_args=()
    
    case "$scan_type" in
        quick)
            nmap_args=("-T4" "-F")
            ;;
        top)
            nmap_args=("-T4" "--top-ports" "$PORT_SCAN_TOP_PORTS")
            ;;
        full)
            nmap_args=("-T4" "-p-" "-sS")
            ;;
    esac
    
    # Executar nmap
    nmap "${nmap_args[@]}" -oX "$temp_file" "$target" &>/dev/null
    
    if [[ -f "$temp_file" ]]; then
        # Parse XML output
        while IFS= read -r line; do
            if [[ "$line" =~ \<port\ protocol=\"tcp\" portid=\"([0-9]+)\" ]]; then
                local port="${BASH_REMATCH[1]}"
                local state
                state=$(echo "$line" | grep -oE 'state="[^"]+"' | cut -d'"' -f2)
                local service
                service=$(echo "$line" | grep -oE 'service name="[^"]+"' | cut -d'"' -f2)
                
                if [[ "$state" == "open" ]]; then
                    results=$(echo "$results" | jq \
                        --arg port "$port" \
                        --arg service "$service" \
                        '.open_ports += [{
                            "port": $port|tonumber,
                            "protocol": "tcp",
                            "state": $state,
                            "service": $service
                        }]')
                elif [[ "$state" == "closed" ]]; then
                    results=$(echo "$results" | jq \
                        --arg port "$port" \
                        '.closed_ports += [{"port": $port|tonumber}]')
                elif [[ "$state" == "filtered" ]]; then
                    results=$(echo "$results" | jq \
                        --arg port "$port" \
                        '.filtered_ports += [{"port": $port|tonumber}]')
                fi
            fi
        done < "$temp_file"
        
        rm -f "$temp_file"
    fi
    
    echo "$results"
}

# Scan com netcat
nc_scan() {
    local target="$1"
    local ports=($2)
    
    local results='{"open_ports": [], "closed_ports": [], "filtered_ports": []}'
    local pids=()
    local temp_dir="${TEMP_DIR}/nc_scan_$$"
    mkdir -p "$temp_dir"
    
    # Função para scan de porta individual
    scan_port() {
        local port="$1"
        local out_file="$2"
        
        if timeout "$PORT_SCAN_TIMEOUT" nc -zv -w 1 "$target" "$port" 2>&1 | grep -q "succeeded"; then
            echo "$port" >> "$out_file"
        fi
    }
    export -f scan_port
    
    # Executar scans em paralelo
    local running=0
    for port in "${ports[@]}"; do
        local out_file="${temp_dir}/port_${port}.txt"
        scan_port "$port" "$out_file" &
        pids+=($!)
        ((running++))
        
        # Limitar paralelismo
        if [[ $running -ge $PORT_SCAN_THREADS ]]; then
            wait -n 2>/dev/null || true
            ((running--))
        fi
    done
    
    # Aguardar todos
    wait
    
    # Coletar resultados
    for port in "${ports[@]}"; do
        local out_file="${temp_dir}/port_${port}.txt"
        if [[ -f "$out_file" ]] && [[ -s "$out_file" ]]; then
            local service="${COMMON_PORTS[$port]:-unknown}"
            results=$(echo "$results" | jq \
                --arg port "$port" \
                --arg service "$service" \
                '.open_ports += [{
                    "port": $port|tonumber,
                    "protocol": "tcp",
                    "state": "open",
                    "service": $service
                }]')
        else
            results=$(echo "$results" | jq \
                --arg port "$port" \
                '.closed_ports += [{"port": $port|tonumber}]')
        fi
    done
    
    rm -rf "$temp_dir"
    
    echo "$results"
}

# Identificar serviços
identify_services() {
    local target="$1"
    local results="$2"
    
    # Banner grabbing para portas abertas
    echo "$results" | jq -c '.open_ports[]' | while read -r port_info; do
        local port
        port=$(echo "$port_info" | jq -r '.port')
        
        # Tentar obter banner
        local banner
        banner=$(get_banner "$target" "$port")
        
        if [[ -n "$banner" ]]; then
            # Atualizar informações da porta
            results=$(echo "$results" | jq \
                --arg port "$port" \
                --arg banner "$banner" \
                '(.open_ports[] | select(.port == ($port|tonumber))).banner = $banner')
            
            # Tentar identificar versão
            local version
            version=$(extract_version "$banner")
            if [[ -n "$version" ]]; then
                results=$(echo "$results" | jq \
                    --arg port "$port" \
                    --arg version "$version" \
                    '(.open_ports[] | select(.port == ($port|tonumber))).version = $version')
            fi
            
            # Tentar identificar produto
            local product
            product=$(extract_product "$banner")
            if [[ -n "$product" ]]; then
                results=$(echo "$results" | jq \
                    --arg port "$port" \
                    --arg product "$product" \
                    '(.open_ports[] | select(.port == ($port|tonumber))).product = $product')
            fi
        fi
    done
    
    echo "$results"
}

# Obter banner
get_banner() {
    local target="$1"
    local port="$2"
    
    local banner=""
    
    case "$port" in
        21) # FTP
            banner=$(timeout 3 nc -nv "$target" "$port" 2>&1 | head -1)
            ;;
        22) # SSH
            banner=$(timeout 3 nc -nv "$target" "$port" 2>&1 | head -1)
            ;;
        25|587) # SMTP
            banner=$(timeout 3 nc -nv "$target" "$port" 2>&1 | head -1)
            ;;
        80|8080|8888) # HTTP
            banner=$(timeout 3 curl -s -I "http://$target:$port" 2>/dev/null | head -1)
            ;;
        110) # POP3
            banner=$(timeout 3 nc -nv "$target" "$port" 2>&1 | head -1)
            ;;
        143) # IMAP
            banner=$(timeout 3 nc -nv "$target" "$port" 2>&1 | head -1)
            ;;
        443|8443) # HTTPS
            banner=$(timeout 3 curl -s -k -I "https://$target:$port" 2>/dev/null | head -1)
            ;;
        3306) # MySQL
            banner=$(timeout 3 nc -nv "$target" "$port" 2>&1 | head -1)
            ;;
        5432) # PostgreSQL
            banner=$(timeout 3 nc -nv "$target" "$port" 2>&1 | head -1)
            ;;
        6379) # Redis
            banner=$(echo "INFO" | timeout 3 nc -nv "$target" "$port" 2>&1 | head -1)
            ;;
        27017) # MongoDB
            banner=$(timeout 3 nc -nv "$target" "$port" 2>&1 | head -1)
            ;;
        *)
            # Tentativa genérica
            banner=$(timeout 3 nc -nv "$target" "$port" 2>&1 | head -1)
            ;;
    esac
    
    echo "$banner" | tr -d '\n\r' | sed 's/"/\\"/g'
}

# Extrair versão do banner
extract_version() {
    local banner="$1"
    
    # Padrões comuns de versão
    local version
    version=$(echo "$banner" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    
    echo "$version"
}

# Extrair produto do banner
extract_product() {
    local banner="$1"
    
    # Palavras comuns em banners
    local products=("Apache" "nginx" "IIS" "OpenSSH" "ProFTPD" "vsftpd" "MySQL" "PostgreSQL" "Redis" "MongoDB" "Elasticsearch" "Docker" "Tomcat" "Jetty" "Node.js" "Python" "PHP")
    
    for product in "${products[@]}"; do
        if echo "$banner" | grep -qi "$product"; then
            echo "$product"
            return
        fi
    done
    
    echo ""
}

# Detectar SO
detect_os() {
    local target="$1"
    local results="$2"
    
    local os_info="{}"
    
    # Usar nmap para detecção de OS
    if command -v nmap &> /dev/null; then
        local temp_file="${TEMP_DIR}/nmap_os_$$.txt"
        nmap -O --osscan-guess "$target" -oG "$temp_file" &>/dev/null
        
        if [[ -f "$temp_file" ]]; then
            local os_line
            os_line=$(grep "OS:" "$temp_file" 2>/dev/null | head -1)
            
            if [[ -n "$os_line" ]]; then
                local os_name
                os_name=$(echo "$os_line" | grep -oE "OS: [^,]*" | cut -d':' -f2- | sed 's/^ //')
                local accuracy
                accuracy=$(echo "$os_line" | grep -oE "Accuracy: [0-9]+%" | cut -d':' -f2 | sed 's/^ //')
                
                os_info=$(echo "$os_info" | jq \
                    --arg name "$os_name" \
                    --arg accuracy "$accuracy" \
                    '{name: $name, accuracy: $accuracy}')
            fi
            rm -f "$temp_file"
        fi
    fi
    
    results=$(echo "$results" | jq --argjson os "$os_info" '.os_detection = $os')
    echo "$results"
}

# Verificar portas vulneráveis
check_vulnerable_ports() {
    local results="$1"
    
    # Lista de portas vulneráveis conhecidas
    local vulnerable_ports=(
        "21:ftp-anonymous"
        "23:telnet-plaintext"
        "445:smb-vulnerable"
        "3389:rdp-weak"
        "5900:vnc-auth-none"
        "6379:redis-no-auth"
        "27017:mongodb-no-auth"
        "9200:elasticsearch-public"
        "5601:kibana-public"
        "5000:docker-api-public"
        "2375:docker-api-no-tls"
    )
    
    echo "$results" | jq -c '.open_ports[]' | while read -r port_info; do
        local port
        port=$(echo "$port_info" | jq -r '.port')
        
        for vuln in "${vulnerable_ports[@]}"; do
            local vuln_port="${vuln%%:*}"
            local vuln_name="${vuln#*:}"
            
            if [[ "$port" == "$vuln_port" ]]; then
                results=$(echo "$results" | jq \
                    --arg port "$port" \
                    --arg vuln "$vuln_name" \
                    '(.open_ports[] | select(.port == ($port|tonumber))).vulnerabilities += [$vuln]')
            fi
        done
    done
    
    echo "$results"
}

# Obter top portas
get_top_ports() {
    local count="$1"
    
    # Portas mais comuns (baseado em scans reais)
    local top_ports=(
        80 443 22 21 25 53 110 143 993 995 3306 3389 5900
        8080 8443 139 445 135 1433 1434 1521 1723 2082 2083
        2086 2087 2095 2096 2222 3307 3333 3389 4444 4445
        5432 5433 5901 5902 6000 6001 6666 6667 6668 6669
        7000 7001 7070 7071 8000 8001 8008 8009 8010 8020
        8081 8082 8083 8084 8085 8086 8087 8088 8089 8090
        8091 8092 8093 8094 8095 8096 8097 8098 8099 8888
        9000 9001 9002 9003 9004 9005 9006 9007 9008 9009
        9010 9011 9012 9013 9014 9015 9016 9017 9018 9019
        9020 9021 9022 9023 9024 9025 9026 9027 9028 9029
        9030 9031 9032 9033 9034 9035 9036 9037 9038 9039
        9040 9041 9042 9043 9044 9045 9046 9047 9048 9049
        9050 9051 9052 9053 9054 9055 9056 9057 9058 9059
        9060 9080 9090 9091 9092 9093 9094 9095 9096 9097
        9098 9099 9100 9200 9300 9400 9500 9600 9700 9800
        9900 10000 10001 10002 10003 10004 10005 10006 10007
        10008 10009 10010 10050 10051 10080 10081 10082 10083
        10084 10085 10086 10087 10088 10089 10090 10091 10092
        10093 10094 10095 10096 10097 10098 10099 10100 10101
    )
    
    # Pegar primeiros 'count' elementos
    printf "%s\n" "${top_ports[@]}" | head -n "$count"
}

# Gerar relatório de portas
generate_port_report() {
    local results="$1"
    local output_file="$2"
    
    {
        echo "========================================="
        echo "        PORT SCAN REPORT"
        echo "========================================="
        echo ""
        echo "Target: $(echo "$results" | jq -r '.resolved_ip // .target_type')"
        echo "Scan Date: $(date)"
        echo ""
        echo "STATISTICS:"
        echo "  Total Ports Scanned: $(echo "$results" | jq -r '.statistics.total_scanned')"
        echo "  Open Ports: $(echo "$results" | jq -r '.statistics.open')"
        echo "  Closed Ports: $(echo "$results" | jq -r '.statistics.closed')"
        echo "  Filtered Ports: $(echo "$results" | jq -r '.statistics.filtered')"
        echo ""
        echo "OPEN PORTS:"
        echo "-----------"
        
        echo "$results" | jq -r '.open_ports[] | "\(.port)/tcp  \(.service)  \(.version // "")  \(.banner // "")"' | while read -r line; do
            echo "  $line"
        done
        
        echo ""
        echo "VULNERABILITIES FOUND:"
        echo "----------------------"
        
        echo "$results" | jq -r '.open_ports[] | select(.vulnerabilities) | "Port \(.port): \(.vulnerabilities | join(", "))"' | while read -r line; do
            echo "  $line"
        done
        
        echo ""
        echo "OS DETECTION:"
        echo "-------------"
        echo "  $(echo "$results" | jq -r '.os_detection.name // "Unknown"')"
        
    } > "$output_file"
}

# Exportar funções
export -f init_port_scanner port_scanner