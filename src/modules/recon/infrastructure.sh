#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Infrastructure Reconnaissance Module
# =============================================================================

MODULE_NAME="Infrastructure Recon"
MODULE_DESC="Complete infrastructure mapping and analysis"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# Inicializar módulo
init_infrastructure() {
    log "INFO" "Initializing Infrastructure Recon module" "INFRA"
    
    # Verificar dependências
    local deps=("nmap" "masscan" "curl" "whois" "dig")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "INFRA"
        return 1
    fi
    
    return 0
}

# Função principal
infrastructure_recon() {
    local target="$1"
    local output_dir="$2"
    
    log "RECON" "Starting infrastructure reconnaissance for: $target" "INFRA"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/infrastructure"
    mkdir -p "$results_dir"
    
    local results="{}"
    
    # 1. Port scanning
    log "INFO" "Performing port scan" "INFRA"
    local port_scan
    port_scan=$(port_scan "$target")
    results=$(echo "$results" | jq --argjson ports "$port_scan" '.port_scan = $ports')
    
    # 2. Service detection
    log "INFO" "Detecting services" "INFRA"
    local services
    services=$(service_detection "$target" "$port_scan")
    results=$(echo "$results" | jq --argjson services "$services" '.services = $services')
    
    # 3. OS fingerprinting
    log "INFO" "OS fingerprinting" "INFRA"
    local os_info
    os_info=$(os_fingerprinting "$target")
    results=$(echo "$results" | jq --argjson os "$os_info" '.os = $os')
    
    # 4. Cloud detection
    log "INFO" "Detecting cloud infrastructure" "INFRA"
    local cloud_info
    cloud_info=$(detect_cloud "$target")
    results=$(echo "$results" | jq --argjson cloud "$cloud_info" '.cloud = $cloud')
    
    # 5. CDN detection
    log "INFO" "Detecting CDN" "INFRA"
    local cdn_info
    cdn_info=$(detect_cdn "$target")
    results=$(echo "$results" | jq --argjson cdn "$cdn_info" '.cdn = $cdn')
    
    # 6. WAF detection
    log "INFO" "Detecting WAF" "INFRA"
    local waf_info
    waf_info=$(detect_waf "$target")
    results=$(echo "$results" | jq --argjson waf "$waf_info" '.waf = $waf')
    
    # 7. SSL/TLS analysis
    log "INFO" "Analyzing SSL/TLS" "INFRA"
    local ssl_info
    ssl_info=$(ssl_analysis "$target")
    results=$(echo "$results" | jq --argjson ssl "$ssl_info" '.ssl = $ssl')
    
    # 8. Network mapping
    log "INFO" "Mapping network topology" "INFRA"
    local network_map
    network_map=$(network_mapping "$target")
    results=$(echo "$results" | jq --argjson network "$network_map" '.network = $network')
    
    # 9. ASN information
    log "INFO" "Gathering ASN info" "INFRA"
    local asn_info
    asn_info=$(get_asn_info "$target")
    results=$(echo "$results" | jq --argjson asn "$asn_info" '.asn = $asn')
    
    # 10. Historical IPs
    log "INFO" "Checking historical IPs" "INFRA"
    local historical_ips
    historical_ips=$(historical_ips "$target")
    results=$(echo "$results" | jq --argjson history "$historical_ips" '.historical_ips = $history')
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/infrastructure.json"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "SUCCESS" "Infrastructure recon completed in ${duration}s" "INFRA"
    
    echo "$results"
}

# Port scanning
port_scan() {
    local target="$1"
    
    local ports="[]"
    
    # Usar masscan para scan rápido (se disponível e root)
    if command -v masscan &> /dev/null && [[ $EUID -eq 0 ]]; then
        local masscan_output="${TEMP_DIR}/masscan_$$.txt"
        masscan -p1-65535 --rate=1000 -oG "$masscan_output" "$target" &>/dev/null
        
        if [[ -f "$masscan_output" ]]; then
            while IFS= read -r line; do
                if [[ "$line" =~ Host:.*Ports:\ ([0-9]+)/open ]]; then
                    local port="${BASH_REMATCH[1]}"
                    ports=$(echo "$ports" | jq --arg port "$port" '. += [{"port": $port|tonumber, "protocol": "tcp", "state": "open"}]')
                fi
            done < "$masscan_output"
            rm -f "$masscan_output"
        fi
    fi
    
    # Se não encontrou portas, usar nmap para portas comuns
    if [[ $(echo "$ports" | jq 'length') -eq 0 ]]; then
        local nmap_output="${TEMP_DIR}/nmap_$$.txt"
        nmap -T4 -F -oG "$nmap_output" "$target" &>/dev/null
        
        if [[ -f "$nmap_output" ]]; then
            while IFS= read -r line; do
                if [[ "$line" =~ ([0-9]+)/open/([a-zA-Z0-9]+) ]]; then
                    local port="${BASH_REMATCH[1]}"
                    local service="${BASH_REMATCH[2]}"
                    ports=$(echo "$ports" | jq --arg port "$port" --arg service "$service" \
                        '. += [{"port": $port|tonumber, "protocol": "tcp", "state": "open", "service": $service}]')
                fi
            done < "$nmap_output"
            rm -f "$nmap_output"
        fi
    fi
    
    echo "$ports"
}

# Service detection
service_detection() {
    local target="$1"
    local port_data="$2"
    
    local services="[]"
    
    # Para cada porta aberta, detectar serviço
    echo "$port_data" | jq -c '.[]' | while read -r port_info; do
        local port
        port=$(echo "$port_info" | jq -r '.port')
        
        # Usar nmap para detecção de versão
        local nmap_output="${TEMP_DIR}/nmap_service_$$_${port}.txt"
        nmap -p "$port" -sV -T4 "$target" -oG "$nmap_output" &>/dev/null
        
        if [[ -f "$nmap_output" ]]; then
            local line
            line=$(grep -E "$port/open" "$nmap_output" 2>/dev/null | head -1)
            
            if [[ -n "$line" ]]; then
                # Extrair informações
                local service
                service=$(echo "$line" | grep -oE '[^/]+/[^/]+/[^/]+/[^/]+/[^/]+' | cut -d'/' -f5)
                
                local version
                version=$(echo "$line" | grep -oE '[^/]+/[^/]+/[^/]+/[^/]+/[^/]+' | cut -d'/' -f7)
                
                local product
                product=$(echo "$line" | grep -oE '[^/]+/[^/]+/[^/]+/[^/]+/[^/]+' | cut -d'/' -f3)
                
                services=$(echo "$services" | jq --arg port "$port" \
                    --arg service "$service" \
                    --arg version "$version" \
                    --arg product "$product" \
                    '. += [{
                        "port": $port|tonumber,
                        "service": $service,
                        "product": $product,
                        "version": $version
                    }]')
            fi
            rm -f "$nmap_output"
        fi
    done
    
    echo "$services"
}

# OS fingerprinting
os_fingerprinting() {
    local target="$1"
    
    local os_info="{}"
    
    # Usar nmap para detecção de OS
    local nmap_output="${TEMP_DIR}/nmap_os_$$.txt"
    nmap -O --osscan-guess "$target" -oG "$nmap_output" &>/dev/null
    
    if [[ -f "$nmap_output" ]]; then
        local os_line
        os_line=$(grep "OS:" "$nmap_output" 2>/dev/null | head -1)
        
        if [[ -n "$os_line" ]]; then
            # Extrair informações
            local os_name
            os_name=$(echo "$os_line" | grep -oE "OS: [^,]*" | cut -d':' -f2- | sed 's/^ //')
            
            local accuracy
            accuracy=$(echo "$os_line" | grep -oE "Accuracy: [0-9]+%" | cut -d':' -f2 | sed 's/^ //')
            
            os_info=$(echo "$os_info" | jq \
                --arg name "$os_name" \
                --arg accuracy "$accuracy" \
                '{
                    name: $name,
                    accuracy: $accuracy
                }')
        fi
        rm -f "$nmap_output"
    fi
    
    echo "$os_info"
}

# Cloud detection
detect_cloud() {
    local target="$1"
    
    local cloud_info="{}"
    
    # Resolver IP
    local ip
    ip=$(dig +short "$target" A 2>/dev/null | head -1)
    
    if [[ -z "$ip" ]]; then
        ip="$target"
    fi
    
    # Ranges de IPs de clouds
    local aws_ranges=("52.94" "54.239" "54.240" "52.216" "52.217" "52.218" "52.219")
    local azure_ranges=("13.64" "13.65" "13.66" "13.67" "13.68" "13.69" "13.70" "13.71")
    local gcp_ranges=("35.184" "35.185" "35.186" "35.187" "35.188" "35.189" "35.190" "35.191")
    local digitalocean_ranges=("104.131" "104.236" "107.170" "128.199" "137.184" "138.68" "138.197")
    local linode_ranges=("45.33" "45.56" "45.79" "50.116" "66.175" "69.164" "72.14")
    
    # Verificar AWS
    for range in "${aws_ranges[@]}"; do
        if [[ "$ip" == "$range"* ]]; then
            cloud_info=$(echo "$cloud_info" | jq '.provider = "AWS"')
            break
        fi
    done
    
    # Verificar Azure
    if [[ "$(echo "$cloud_info" | jq -r '.provider')" == "null" ]]; then
        for range in "${azure_ranges[@]}"; do
            if [[ "$ip" == "$range"* ]]; then
                cloud_info=$(echo "$cloud_info" | jq '.provider = "Azure"')
                break
            fi
        done
    fi
    
    # Verificar GCP
    if [[ "$(echo "$cloud_info" | jq -r '.provider')" == "null" ]]; then
        for range in "${gcp_ranges[@]}"; do
            if [[ "$ip" == "$range"* ]]; then
                cloud_info=$(echo "$cloud_info" | jq '.provider = "GCP"')
                break
            fi
        done
    fi
    
    # Verificar DigitalOcean
    if [[ "$(echo "$cloud_info" | jq -r '.provider')" == "null" ]]; then
        for range in "${digitalocean_ranges[@]}"; do
            if [[ "$ip" == "$range"* ]]; then
                cloud_info=$(echo "$cloud_info" | jq '.provider = "DigitalOcean"')
                break
            fi
        done
    fi
    
    # Verificar Linode
    if [[ "$(echo "$cloud_info" | jq -r '.provider')" == "null" ]]; then
        for range in "${linode_ranges[@]}"; do
            if [[ "$ip" == "$range"* ]]; then
                cloud_info=$(echo "$cloud_info" | jq '.provider = "Linode"')
                break
            fi
        done
    fi
    
    # Se não encontrou, verificar via whois
    if [[ "$(echo "$cloud_info" | jq -r '.provider')" == "null" ]]; then
        local whois_info
        whois_info=$(whois "$ip" 2>/dev/null)
        
        if echo "$whois_info" | grep -qi "amazon\|aws"; then
            cloud_info=$(echo "$cloud_info" | jq '.provider = "AWS"')
        elif echo "$whois_info" | grep -qi "microsoft\|azure"; then
            cloud_info=$(echo "$cloud_info" | jq '.provider = "Azure"')
        elif echo "$whois_info" | grep -qi "google\|gcp"; then
            cloud_info=$(echo "$cloud_info" | jq '.provider = "GCP"')
        elif echo "$whois_info" | grep -qi "digitalocean"; then
            cloud_info=$(echo "$cloud_info" | jq '.provider = "DigitalOcean"')
        elif echo "$whois_info" | grep -qi "linode"; then
            cloud_info=$(echo "$cloud_info" | jq '.provider = "Linode"')
        else
            cloud_info=$(echo "$cloud_info" | jq '.provider = "Unknown/On-premise"')
        fi
    fi
    
    # Adicionar IP
    cloud_info=$(echo "$cloud_info" | jq --arg ip "$ip" '.ip = $ip')
    
    echo "$cloud_info"
}

# CDN detection
detect_cdn() {
    local target="$1"
    
    local cdn_info="{}"
    
    # Headers HTTP
    local headers
    headers=$(curl -s -I -L "http://${target}" 2>/dev/null)
    
    if [[ -n "$headers" ]]; then
        # Cloudflare
        if echo "$headers" | grep -qi "cloudflare"; then
            cdn_info=$(echo "$cdn_info" | jq '.provider = "Cloudflare"')
        
        # Akamai
        elif echo "$headers" | grep -qi "akamai"; then
            cdn_info=$(echo "$cdn_info" | jq '.provider = "Akamai"')
        
        # Fastly
        elif echo "$headers" | grep -qi "fastly"; then
            cdn_info=$(echo "$cdn_info" | jq '.provider = "Fastly"')
        
        # Amazon CloudFront
        elif echo "$headers" | grep -qi "cloudfront"; then
            cdn_info=$(echo "$cdn_info" | jq '.provider = "CloudFront"')
        
        # Incapsula
        elif echo "$headers" | grep -qi "incapsula"; then
            cdn_info=$(echo "$cdn_info" | jq '.provider = "Incapsula"')
        
        # Sucuri
        elif echo "$headers" | grep -qi "sucuri"; then
            cdn_info=$(echo "$cdn_info" | jq '.provider = "Sucuri"')
        
        # StackPath
        elif echo "$headers" | grep -qi "stackpath"; then
            cdn_info=$(echo "$cdn_info" | jq '.provider = "StackPath"')
        
        else
            cdn_info=$(echo "$cdn_info" | jq '.provider = "No CDN detected"')
        fi
    fi
    
    # Verificar via DNS
    local cname
    cname=$(dig +short "$target" CNAME 2>/dev/null | head -1)
    
    if [[ -n "$cname" ]]; then
        if [[ "$cname" == *"cloudflare"* ]]; then
            cdn_info=$(echo "$cdn_info" | jq '.provider = "Cloudflare"')
        elif [[ "$cname" == *"akamai"* ]]; then
            cdn_info=$(echo "$cdn_info" | jq '.provider = "Akamai"')
        elif [[ "$cname" == *"fastly"* ]]; then
            cdn_info=$(echo "$cdn_info" | jq '.provider = "Fastly"')
        elif [[ "$cname" == *"cloudfront"* ]]; then
            cdn_info=$(echo "$cdn_info" | jq '.provider = "CloudFront"')
        fi
    fi
    
    echo "$cdn_info"
}

# WAF detection
detect_waf() {
    local target="$1"
    
    local waf_info="{}"
    
    # Headers HTTP
    local headers
    headers=$(curl -s -I -L "http://${target}" 2>/dev/null)
    
    if [[ -n "$headers" ]]; then
        # Cloudflare
        if echo "$headers" | grep -qi "cloudflare"; then
            waf_info=$(echo "$waf_info" | jq '.waf = "Cloudflare"')
        
        # AWS WAF
        elif echo "$headers" | grep -qi "awswaf"; then
            waf_info=$(echo "$waf_info" | jq '.waf = "AWS WAF"')
        
        # ModSecurity
        elif echo "$headers" | grep -qi "mod_security\|modsecurity"; then
            waf_info=$(echo "$waf_info" | jq '.waf = "ModSecurity"')
        
        # F5 BIG-IP
        elif echo "$headers" | grep -qi "big-ip"; then
            waf_info=$(echo "$waf_info" | jq '.waf = "F5 BIG-IP"')
        
        # Barracuda
        elif echo "$headers" | grep -qi "barracuda"; then
            waf_info=$(echo "$waf_info" | jq '.waf = "Barracuda"')
        
        # Citrix
        elif echo "$headers" | grep -qi "citrix"; then
            waf_info=$(echo "$waf_info" | jq '.waf = "Citrix"')
        
        # Imperva
        elif echo "$headers" | grep -qi "imperva"; then
            waf_info=$(echo "$waf_info" | jq '.waf = "Imperva"')
        
        # Sucuri
        elif echo "$headers" | grep -qi "sucuri"; then
            waf_info=$(echo "$waf_info" | jq '.waf = "Sucuri"')
        
        else
            waf_info=$(echo "$waf_info" | jq '.waf = "No WAF detected"')
        fi
    fi
    
    echo "$waf_info"
}

# SSL/TLS analysis
ssl_analysis() {
    local target="$1"
    
    local ssl_info="{}"
    
    # Verificar se HTTPS está disponível
    if curl -s -I "https://${target}" &>/dev/null; then
        ssl_info=$(echo "$ssl_info" | jq '.https_available = true')
        
        # Obter informações do certificado
        local cert_info
        cert_info=$(echo | openssl s_client -servername "$target" -connect "${target}:443" 2>/dev/null | openssl x509 -text 2>/dev/null)
        
        if [[ -n "$cert_info" ]]; then
            # Issuer
            local issuer
            issuer=$(echo "$cert_info" | grep "Issuer:" | head -1 | sed 's/.*Issuer: //')
            ssl_info=$(echo "$ssl_info" | jq --arg issuer "$issuer" '.certificate.issuer = $issuer')
            
            # Subject
            local subject
            subject=$(echo "$cert_info" | grep "Subject:" | head -1 | sed 's/.*Subject: //')
            ssl_info=$(echo "$ssl_info" | jq --arg subject "$subject" '.certificate.subject = $subject')
            
            # Validity
            local not_before
            not_before=$(echo "$cert_info" | grep "Not Before" | sed 's/.*Not Before: //')
            local not_after
            not_after=$(echo "$cert_info" | grep "Not After" | sed 's/.*Not After: //')
            
            ssl_info=$(echo "$ssl_info" | jq \
                --arg not_before "$not_before" \
                --arg not_after "$not_after" \
                '.certificate.validity = {
                    "not_before": $not_before,
                    "not_after": $not_after
                }')
            
            # SAN
            local san
            san=$(echo "$cert_info" | grep -A1 "Subject Alternative Name" | tail -1 | sed 's/.*: //')
            if [[ -n "$san" ]]; then
                ssl_info=$(echo "$ssl_info" | jq --arg san "$san" '.certificate.san = $san')
            fi
            
            # Algorithm
            local algo
            algo=$(echo "$cert_info" | grep "Signature Algorithm" | head -1 | sed 's/.*Signature Algorithm: //')
            ssl_info=$(echo "$ssl_info" | jq --arg algo "$algo" '.certificate.signature_algorithm = $algo')
        fi
        
        # Versões TLS suportadas
        local tls_versions="{}"
        
        # TLS 1.0
        if echo | openssl s_client -tls1 -connect "${target}:443" 2>&1 | grep -q "CONNECTED"; then
            tls_versions=$(echo "$tls_versions" | jq '.tls1_0 = true')
        fi
        
        # TLS 1.1
        if echo | openssl s_client -tls1_1 -connect "${target}:443" 2>&1 | grep -q "CONNECTED"; then
            tls_versions=$(echo "$tls_versions" | jq '.tls1_1 = true')
        fi
        
        # TLS 1.2
        if echo | openssl s_client -tls1_2 -connect "${target}:443" 2>&1 | grep -q "CONNECTED"; then
            tls_versions=$(echo "$tls_versions" | jq '.tls1_2 = true')
        fi
        
        # TLS 1.3
        if echo | openssl s_client -tls1_3 -connect "${target}:443" 2>&1 | grep -q "CONNECTED"; then
            tls_versions=$(echo "$tls_versions" | jq '.tls1_3 = true')
        fi
        
        ssl_info=$(echo "$ssl_info" | jq --argjson tls "$tls_versions" '.tls_versions = $tls')
        
    else
        ssl_info=$(echo "$ssl_info" | jq '.https_available = false')
    fi
    
    echo "$ssl_info"
}

# Network mapping
network_mapping() {
    local target="$1"
    
    local network_info="{}"
    
    # Resolver IP
    local ip
    ip=$(dig +short "$target" A 2>/dev/null | head -1)
    
    if [[ -z "$ip" ]]; then
        ip="$target"
    fi
    
    network_info=$(echo "$network_info" | jq --arg ip "$ip" '.ip = $ip')
    
    # Traceroute
    local traceroute_output
    traceroute_output=$(traceroute -n -m 15 "$ip" 2>/dev/null | grep -v "traceroute to" | sed 's/  / /g')
    
    if [[ -n "$traceroute_output" ]]; then
        local hops=()
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*([0-9]+)[[:space:]]+([0-9.]+) ]]; then
                local hop_num="${BASH_REMATCH[1]}"
                local hop_ip="${BASH_REMATCH[2]}"
                
                if [[ "$hop_ip" != "*" ]]; then
                    hops+=("{\"hop\": $hop_num, \"ip\": \"$hop_ip\"}")
                fi
            fi
        done <<< "$traceroute_output"
        
        if [[ ${#hops[@]} -gt 0 ]]; then
            local hops_json
            hops_json=$(printf '%s\n' "${hops[@]}" | jq -s '.')
            network_info=$(echo "$network_info" | jq --argjson hops "$hops_json" '.traceroute = $hops')
        fi
    fi
    
    # Neighbors (whois)
    local whois_info
    whois_info=$(whois "$ip" 2>/dev/null)
    
    # ASN
    local asn
    asn=$(echo "$whois_info" | grep -i "origin" | grep -oE 'AS[0-9]+' | head -1)
    if [[ -n "$asn" ]]; then
        network_info=$(echo "$network_info" | jq --arg asn "$asn" '.asn = $asn')
    fi
    
    # CIDR
    local cidr
    cidr=$(echo "$whois_info" | grep -i "cidr" | grep -oE '[0-9.]+/[0-9]+' | head -1)
    if [[ -n "$cidr" ]]; then
        network_info=$(echo "$network_info" | jq --arg cidr "$cidr" '.cidr = $cidr')
    fi
    
    echo "$network_info"
}

# ASN information
get_asn_info() {
    local target="$1"
    
    local asn_info="{}"
    
    # Resolver IP
    local ip
    ip=$(dig +short "$target" A 2>/dev/null | head -1)
    
    if [[ -z "$ip" ]]; then
        ip="$target"
    fi
    
    # Consulta whois
    local whois_info
    whois_info=$(whois "$ip" 2>/dev/null)
    
    # Extrair ASN
    local asn
    asn=$(echo "$whois_info" | grep -i "origin" | grep -oE 'AS[0-9]+' | head -1)
    
    if [[ -n "$asn" ]]; then
        asn_info=$(echo "$asn_info" | jq --arg asn "$asn" '.asn = $asn')
        
        # Nome do AS
        local as_name
        as_name=$(echo "$whois_info" | grep -i "as-name" | cut -d':' -f2- | sed 's/^ //' | head -1)
        if [[ -z "$as_name" ]]; then
            as_name=$(echo "$whois_info" | grep -i "descr" | cut -d':' -f2- | sed 's/^ //' | head -1)
        fi
        
        if [[ -n "$as_name" ]]; then
            asn_info=$(echo "$asn_info" | jq --arg name "$as_name" '.name = $name')
        fi
        
        # País
        local country
        country=$(echo "$whois_info" | grep -i "country" | cut -d':' -f2- | sed 's/^ //' | head -1)
        if [[ -n "$country" ]]; then
            asn_info=$(echo "$asn_info" | jq --arg country "$country" '.country = $country')
        fi
        
        # CIDR ranges
        local cidrs
        cidrs=$(whois -h whois.radb.net -- "-i origin $asn" 2>/dev/null | grep -E '^route:' | awk '{print $2}' | head -5 | jq -R -s -c 'split("\n")[:-1]')
        if [[ "$cidrs" != "[]" ]]; then
            asn_info=$(echo "$asn_info" | jq --argjson cidrs "$cidrs" '.cidrs = $cidrs')
        fi
    fi
    
    echo "$asn_info"
}

# Historical IPs
historical_ips() {
    local target="$1"
    
    local historical="[]"
    
    # SecurityTrails API
    if [[ -n "$SECURITYTRAILS_API_KEY" ]]; then
        local response
        response=$(curl -s "https://api.securitytrails.com/v1/history/${target}/dns/a" \
            -H "APIKEY: ${SECURITYTRAILS_API_KEY}" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            historical=$(echo "$response" | jq '.records // []' 2>/dev/null)
        fi
    fi
    
    # Se não tem API, usar DNS histórico público
    if [[ "$historical" == "[]" ]]; then
        # DNS Dumpster
        local response
        response=$(curl -s "https://dnsdumpster.com/" 2>/dev/null)
        
        # Extrair CSRF token
        local csrf
        csrf=$(echo "$response" | grep -oE 'name="_csrf" value="[^"]+"' | cut -d'"' -f4)
        
        if [[ -n "$csrf" ]]; then
            # Fazer requisição
            local result
            result=$(curl -s -X POST -d "targetip=${target}&_csrf=${csrf}" \
                -H "Referer: https://dnsdumpster.com/" \
                -H "User-Agent: Mozilla/5.0" \
                "https://dnsdumpster.com/" 2>/dev/null)
            
            # Extrair IPs históricos (simplificado)
            local ips
            ips=$(echo "$result" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u | head -10)
            
            if [[ -n "$ips" ]]; then
                local count=0
                while IFS= read -r ip; do
                    if [[ -n "$ip" ]]; then
                        historical=$(echo "$historical" | jq --arg ip "$ip" \
                            '. += [{"ip": $ip, "source": "dnsdumpster", "date": "unknown"}]')
                        ((count++))
                        if [[ $count -ge 5 ]]; then
                            break
                        fi
                    fi
                done <<< "$ips"
            fi
        fi
    fi
    
    echo "$historical"
}

# Exportar funções
export -f init_infrastructure infrastructure_recon