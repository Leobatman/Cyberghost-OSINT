#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Service Detection Module
# =============================================================================

MODULE_NAME="Service Detection"
MODULE_DESC="Advanced service fingerprinting and version detection"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# Banner grabbing patterns
declare -A SERVICE_PATTERNS=(
    ["http"]="HTTP/|Apache|nginx|IIS|Tomcat"
    ["ssh"]="SSH-|OpenSSH"
    ["ftp"]="FTP|vsFTPd|ProFTPD"
    ["smtp"]="SMTP|Postfix|Sendmail|Exchange"
    ["mysql"]="MySQL|MariaDB"
    ["postgresql"]="PostgreSQL"
    ["redis"]="Redis"
    ["mongodb"]="MongoDB"
    ["elasticsearch"]="Elasticsearch"
    ["docker"]="Docker"
    ["kubernetes"]="kube-apiserver"
)

# Inicializar módulo
init_service_detection() {
    log "INFO" "Initializing Service Detection module" "SERVICE_DETECT"
    
    # Verificar dependências
    local deps=("nmap" "nc" "curl" "timeout")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "SERVICE_DETECT"
        return 1
    fi
    
    return 0
}

# Função principal
detect_services() {
    local target="$1"
    local ports="$2"
    local output_dir="$3"
    
    log "RECON" "Starting service detection for: $target" "SERVICE_DETECT"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/services"
    mkdir -p "$results_dir"
    
    local results="[]"
    
    # Detectar serviços para cada porta
    if [[ -n "$ports" ]]; then
        # Se ports é um array JSON
        if echo "$ports" | jq -e . >/dev/null 2>&1; then
            local port_list
            port_list=$(echo "$ports" | jq -r '.[].port')
            
            while IFS= read -r port; do
                if [[ -n "$port" ]]; then
                    log "DEBUG" "Detecting service on port $port" "SERVICE_DETECT"
                    local service_info
                    service_info=$(detect_service_on_port "$target" "$port")
                    
                    if [[ -n "$service_info" ]] && [[ "$service_info" != "{}" ]]; then
                        results=$(echo "$results" | jq --argjson service "$service_info" '. += [$service]')
                    fi
                fi
            done <<< "$port_list"
        fi
    else
        # Scan de portas primeiro
        log "INFO" "No ports provided, performing quick port scan" "SERVICE_DETECT"
        local port_scan_results
        port_scan_results=$(quick_port_scan "$target")
        
        for port in $port_scan_results; do
            if [[ -n "$port" ]]; then
                local service_info
                service_info=$(detect_service_on_port "$target" "$port")
                
                if [[ -n "$service_info" ]] && [[ "$service_info" != "{}" ]]; then
                    results=$(echo "$results" | jq --argjson service "$service_info" '. += [$service]')
                fi
            fi
        done
    fi
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/services.json"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local service_count
    service_count=$(echo "$results" | jq 'length')
    
    log "SUCCESS" "Service detection completed in ${duration}s - Found $service_count services" "SERVICE_DETECT"
    
    echo "$results"
}

# Detectar serviço em porta específica
detect_service_on_port() {
    local target="$1"
    local port="$2"
    
    local service_info="{}"
    
    # Tentar diferentes métodos de detecção
    local banner
    local nmap_info
    
    # Método 1: Banner grabbing com netcat
    banner=$(grab_banner "$target" "$port")
    
    # Método 2: Nmap service detection
    nmap_info=$(nmap_service_detect "$target" "$port")
    
    # Método 3: HTTP service detection (se for porta 80/443/8080/etc)
    if [[ "$port" =~ ^(80|443|8080|8443|3000|5000|8000|8888)$ ]]; then
        local http_info
        http_info=$(detect_http_service "$target" "$port")
        if [[ -n "$http_info" ]] && [[ "$http_info" != "{}" ]]; then
            service_info=$(echo "$service_info" | jq --argjson http "$http_info" '.http = $http')
        fi
    fi
    
    # Método 4: SSL/TLS detection (se for porta 443/8443/etc)
    if [[ "$port" =~ ^(443|8443|465|993|995)$ ]]; then
        local ssl_info
        ssl_info=$(detect_ssl_service "$target" "$port")
        if [[ -n "$ssl_info" ]] && [[ "$ssl_info" != "{}" ]]; then
            service_info=$(echo "$service_info" | jq --argjson ssl "$ssl_info" '.ssl = $ssl')
        fi
    fi
    
    # Combinar informações
    if [[ -n "$banner" ]]; then
        local service_name
        service_name=$(identify_service_from_banner "$banner")
        
        service_info=$(echo "$service_info" | jq \
            --arg port "$port" \
            --arg banner "$banner" \
            --arg name "$service_name" \
            '{
                port: ($port | tonumber),
                protocol: "tcp",
                service: $name,
                banner: $banner
            }')
    elif [[ -n "$nmap_info" ]] && [[ "$nmap_info" != "null" ]]; then
        service_info=$(echo "$service_info" | jq --argjson nmap "$nmap_info" '. += $nmap')
    else
        # Fallback: apenas porta e protocolo
        service_info=$(echo "$service_info" | jq \
            --arg port "$port" \
            '{
                port: ($port | tonumber),
                protocol: "tcp",
                service: "unknown"
            }')
    fi
    
    echo "$service_info"
}

# Banner grabbing com netcat
grab_banner() {
    local target="$1"
    local port="$2"
    local timeout=5
    
    # Tentar conexão TCP e capturar banner
    local banner
    banner=$(timeout "$timeout" nc -vn "$target" "$port" 2>&1 < /dev/null)
    
    # Se não funcionou, tentar com echo
    if [[ -z "$banner" ]] || [[ "$banner" == *"timed out"* ]]; then
        banner=$(echo -e "HEAD / HTTP/1.0\r\n\r\n" | timeout "$timeout" nc -vn "$target" "$port" 2>&1)
    fi
    
    # Limpar banner
    banner=$(echo "$banner" | head -5 | tr -d '\0' | tr '\n' ' ' | sed 's/  / /g')
    
    echo "$banner"
}

# Detecção de serviço com nmap
nmap_service_detect() {
    local target="$1"
    local port="$2"
    
    local nmap_output
    nmap_output=$(nmap -p "$port" -sV --script=banner "$target" 2>/dev/null)
    
    if [[ -n "$nmap_output" ]]; then
        local service
        local version
        local product
        
        service=$(echo "$nmap_output" | grep -E "^$port/tcp" | awk '{print $3}')
        version=$(echo "$nmap_output" | grep -E "^$port/tcp" | awk '{print $4, $5, $6, $7, $8}' | sed 's/ //g')
        product=$(echo "$nmap_output" | grep -E "^$port/tcp" | awk '{print $4}')
        
        if [[ -n "$service" ]]; then
            echo "{\"port\": $port, \"service\": \"$service\", \"product\": \"$product\", \"version\": \"$version\"}"
        fi
    fi
}

# Detectar serviço HTTP
detect_http_service() {
    local target="$1"
    local port="$2"
    
    local protocol="http"
    [[ "$port" == "443" ]] || [[ "$port" == "8443" ]] && protocol="https"
    
    local url="${protocol}://${target}:${port}"
    local http_info="{}"
    
    # Headers HTTP
    local headers
    headers=$(curl -s -I -L --max-time 5 "$url" 2>/dev/null)
    
    if [[ -n "$headers" ]]; then
        # Server header
        local server
        server=$(echo "$headers" | grep -i "^server:" | head -1 | cut -d':' -f2- | sed 's/^[ \t]*//')
        
        if [[ -n "$server" ]]; then
            http_info=$(echo "$http_info" | jq --arg server "$server" '.server = $server')
        fi
        
        # Content-Type
        local content_type
        content_type=$(echo "$headers" | grep -i "^content-type:" | head -1 | cut -d':' -f2- | sed 's/^[ \t]*//')
        
        if [[ -n "$content_type" ]]; then
            http_info=$(echo "$http_info" | jq --arg type "$content_type" '.content_type = $type')
        fi
        
        # Powered-By
        local powered_by
        powered_by=$(echo "$headers" | grep -i "^x-powered-by:" | head -1 | cut -d':' -f2- | sed 's/^[ \t]*//')
        
        if [[ -n "$powered_by" ]]; then
            http_info=$(echo "$http_info" | jq --arg powered "$powered_by" '.x_powered_by = $powered')
        fi
        
        # Cookies
        local cookies
        cookies=$(echo "$headers" | grep -i "^set-cookie:" | head -3 | cut -d':' -f2- | sed 's/^[ \t]*//' | jq -R -s -c 'split("\n")[:-1]')
        
        if [[ "$cookies" != "[]" ]]; then
            http_info=$(echo "$http_info" | jq --argjson cookies "$cookies" '.cookies = $cookies')
        fi
    fi
    
    # Título da página
    local title
    title=$(curl -s -L --max-time 5 "$url" 2>/dev/null | grep -o '<title>[^<]*' | head -1 | sed 's/<title>//')
    
    if [[ -n "$title" ]]; then
        http_info=$(echo "$http_info" | jq --arg title "$title" '.title = $title')
    fi
    
    echo "$http_info"
}

# Detectar serviço SSL/TLS
detect_ssl_service() {
    local target="$1"
    local port="$2"
    
    local ssl_info="{}"
    
    # Certificado SSL
    local cert_info
    cert_info=$(echo | openssl s_client -servername "$target" -connect "${target}:${port}" 2>/dev/null | openssl x509 -text 2>/dev/null)
    
    if [[ -n "$cert_info" ]]; then
        # Common Name
        local cn
        cn=$(echo "$cert_info" | grep "Subject:" | grep -o 'CN=[^,]*' | cut -d'=' -f2)
        
        if [[ -n "$cn" ]]; then
            ssl_info=$(echo "$ssl_info" | jq --arg cn "$cn" '.common_name = $cn')
        fi
        
        # Issuer
        local issuer
        issuer=$(echo "$cert_info" | grep "Issuer:" | grep -o 'CN=[^,]*' | cut -d'=' -f2)
        
        if [[ -n "$issuer" ]]; then
            ssl_info=$(echo "$ssl_info" | jq --arg issuer "$issuer" '.issuer = $issuer')
        fi
        
        # Validity
        local not_before
        not_before=$(echo "$cert_info" | grep "Not Before" | sed 's/.*Not Before: //')
        local not_after
        not_after=$(echo "$cert_info" | grep "Not After" | sed 's/.*Not After: //')
        
        ssl_info=$(echo "$ssl_info" | jq \
            --arg before "$not_before" \
            --arg after "$not_after" \
            '.validity = {
                "not_before": $before,
                "not_after": $after
            }')
        
        # SAN
        local san
        san=$(echo "$cert_info" | grep -A1 "Subject Alternative Name" | tail -1 | sed 's/.*: //')
        
        if [[ -n "$san" ]]; then
            ssl_info=$(echo "$ssl_info" | jq --arg san "$san" '.subject_alt_names = $san')
        fi
        
        # Cipher suite
        local cipher
        cipher=$(echo | openssl s_client -servername "$target" -connect "${target}:${port}" 2>/dev/null | grep "Cipher" | head -1 | cut -d':' -f2- | sed 's/^ //')
        
        if [[ -n "$cipher" ]]; then
            ssl_info=$(echo "$ssl_info" | jq --arg cipher "$cipher" '.cipher = $cipher')
        fi
    fi
    
    # TLS versions
    local tls_versions="{}"
    
    # TLS 1.0
    if echo | openssl s_client -tls1 -connect "${target}:${port}" 2>&1 | grep -q "CONNECTED"; then
        tls_versions=$(echo "$tls_versions" | jq '.tls1_0 = true')
    fi
    
    # TLS 1.1
    if echo | openssl s_client -tls1_1 -connect "${target}:${port}" 2>&1 | grep -q "CONNECTED"; then
        tls_versions=$(echo "$tls_versions" | jq '.tls1_1 = true')
    fi
    
    # TLS 1.2
    if echo | openssl s_client -tls1_2 -connect "${target}:${port}" 2>&1 | grep -q "CONNECTED"; then
        tls_versions=$(echo "$tls_versions" | jq '.tls1_2 = true')
    fi
    
    # TLS 1.3
    if echo | openssl s_client -tls1_3 -connect "${target}:${port}" 2>&1 | grep -q "CONNECTED"; then
        tls_versions=$(echo "$tls_versions" | jq '.tls1_3 = true')
    fi
    
    ssl_info=$(echo "$ssl_info" | jq --argjson tls "$tls_versions" '.tls_versions = $tls')
    
    echo "$ssl_info"
}

# Identificar serviço a partir do banner
identify_service_from_banner() {
    local banner="$1"
    
    for service in "${!SERVICE_PATTERNS[@]}"; do
        local pattern="${SERVICE_PATTERNS[$service]}"
        
        if echo "$banner" | grep -qE "$pattern"; then
            echo "$service"
            return 0
        fi
    done
    
    echo "unknown"
}

# Scan rápido de portas
quick_port_scan() {
    local target="$1"
    local common_ports=(21 22 23 25 53 80 110 111 135 139 143 443 445 993 995 1723 3306 3389 5900 8080 8443)
    
    local open_ports=()
    
    for port in "${common_ports[@]}"; do
        if timeout 2 bash -c "echo >/dev/tcp/$target/$port" 2>/dev/null; then
            open_ports+=("$port")
        fi
    done
    
    echo "${open_ports[@]}"
}

# Detecção de vulnerabilidades conhecidas
check_service_vulnerabilities() {
    local service="$1"
    local version="$2"
    
    local vulns="[]"
    
    # Vulnerabilidades conhecidas por serviço
    case "$service" in
        "openssh")
            if [[ "$version" =~ 7\.[0-2] ]]; then
                vulns=$(echo "$vulns" | jq '. += [{"cve": "CVE-2016-6210", "description": "User enumeration via timing"}]')
            fi
            if [[ "$version" == "7.2p1" ]]; then
                vulns=$(echo "$vulns" | jq '. += [{"cve": "CVE-2016-0777", "description": "Roaming vulnerability"}]')
            fi
            ;;
        "apache")
            if [[ "$version" =~ 2\.4\.[0-9]+ ]] && [[ ${version#2.4.} -lt 49 ]]; then
                vulns=$(echo "$vulns" | jq '. += [{"cve": "CVE-2017-9798", "description": "Optionsbleed"}]')
            fi
            ;;
        "nginx")
            if [[ "$version" =~ 1\.[0-9]+\.[0-9]+ ]] && [[ ${version#1.} -lt 10 ]]; then
                vulns=$(echo "$vulns" | jq '. += [{"cve": "CVE-2017-7529", "description": "Integer overflow"}]')
            fi
            ;;
    esac
    
    echo "$vulns"
}

# Exportar funções
export -f init_service_detection detect_services