#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - CDN Detection Module
# =============================================================================

MODULE_NAME="CDN Detection"
MODULE_DESC="Detect Content Delivery Networks and reverse proxies"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# CDN providers and their signatures
declare -A CDN_PROVIDERS=(
    ["Cloudflare"]="cloudflare"
    ["Akamai"]="akamai"
    ["Fastly"]="fastly"
    ["Amazon CloudFront"]="cloudfront"
    ["Microsoft Azure"]="azure"
    ["Google Cloud CDN"]="google"
    ["StackPath"]="stackpath"
    ["KeyCDN"]="keycdn"
    ["CDN77"]="cdn77"
    ["BunnyCDN"]="bunnycdn"
    ["CacheFly"]="cachefly"
    ["MaxCDN"]="maxcdn"
    ["Limelight"]="limelight"
    ["EdgeCast"]="edgecast"
    ["Incapsula"]="incapsula"
    ["Sucuri"]="sucuri"
    ["Imperva"]="imperva"
    ["Cloudbric"]="cloudbric"
    ["Reblaze"]="reblaze"
    ["Varnish"]="varnish"
    ["Nginx"]="nginx"
    ["Apache"]="apache"
)

# CDN IP ranges (simplificado)
declare -A CDN_IP_RANGES=(
    ["Cloudflare"]="103.21.244.0/22 103.22.200.0/22 103.31.4.0/22 104.16.0.0/12 108.162.192.0/18 131.0.72.0/22 141.101.64.0/18 162.158.0.0/15 172.64.0.0/13 173.245.48.0/20 188.114.96.0/20 190.93.240.0/20 197.234.240.0/22 198.41.128.0/17"
    ["Fastly"]="23.235.32.0/20 43.249.72.0/22 103.244.50.0/24 103.245.222.0/23 103.245.224.0/24 104.156.80.0/20 146.75.0.0/16 151.101.0.0/16 157.52.64.0/18 167.82.0.0/17 167.82.128.0/20 172.111.64.0/18 185.31.16.0/22 199.27.128.0/21"
    ["Akamai"]="2.16.0.0/13 2.20.0.0/15 23.0.0.0/12 23.32.0.0/11 23.64.0.0/14 23.72.0.0/13 23.192.0.0/11 23.208.0.0/12 63.208.0.0/14 63.216.0.0/13 65.198.0.0/15 69.192.0.0/16 72.246.0.0/16 88.221.0.0/16 92.122.0.0/15 95.100.0.0/15 96.6.0.0/15 104.64.0.0/10"
)

# Inicializar módulo
init_cdn_detection() {
    log "INFO" "Initializing CDN Detection module" "CDN"
    
    # Verificar dependências
    local deps=("dig" "curl" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "CDN"
        return 1
    fi
    
    return 0
}

# Função principal
detect_cdn() {
    local target="$1"
    local output_dir="$2"
    
    log "RECON" "Starting CDN detection for: $target" "CDN"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/cdn"
    mkdir -p "$results_dir"
    
    local results="{}"
    
    # 1. Detect from DNS
    log "INFO" "Detecting CDN from DNS" "CDN"
    local dns_info
    dns_info=$(detect_cdn_from_dns "$target")
    results=$(echo "$results" | jq --argjson dns "$dns_info" '.dns = $dns')
    
    # 2. Detect from IP
    log "INFO" "Detecting CDN from IP" "CDN"
    local ip_info
    ip_info=$(detect_cdn_from_ip "$target")
    results=$(echo "$results" | jq --argjson ip "$ip_info" '.ip = $ip')
    
    # 3. Detect from HTTP headers
    log "INFO" "Detecting CDN from HTTP headers" "CDN"
    local headers_info
    headers_info=$(detect_cdn_from_headers "$target")
    results=$(echo "$results" | jq --argjson headers "$headers_info" '.headers = $headers')
    
    # 4. Detect from response
    log "INFO" "Detecting CDN from response patterns" "CDN"
    local response_info
    response_info=$(detect_cdn_from_response "$target")
    results=$(echo "$results" | jq --argjson response "$response_info" '.response = $response')
    
    # 5. Detect from cookies
    log "INFO" "Detecting CDN from cookies" "CDN"
    local cookies_info
    cookies_info=$(detect_cdn_from_cookies "$target")
    results=$(echo "$results" | jq --argjson cookies "$cookies_info" '.cookies = $cookies')
    
    # 6. Check for WAF
    log "INFO" "Checking for WAF presence" "CDN"
    local waf_info
    waf_info=$(check_waf_presence "$target")
    results=$(echo "$results" | jq --argjson waf "$waf_info" '.waf = $waf')
    
    # 7. Determine final CDN
    local final_provider
    final_provider=$(determine_cdn_provider "$results")
    results=$(echo "$results" | jq --arg provider "$final_provider" '.provider = $provider')
    
    # 8. Get CDN configuration
    log "INFO" "Getting CDN configuration hints" "CDN"
    local config_info
    config_info=$(get_cdn_configuration "$target" "$final_provider")
    results=$(echo "$results" | jq --argjson config "$config_info" '.configuration = $config')
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/cdn.json"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "SUCCESS" "CDN detection completed in ${duration}s - Provider: $final_provider" "CDN"
    
    echo "$results"
}

# Detectar CDN a partir de DNS
detect_cdn_from_dns() {
    local target="$1"
    local dns_info="{}"
    
    # Verificar CNAME
    local cname
    cname=$(dig +short "$target" CNAME 2>/dev/null | head -1)
    
    if [[ -n "$cname" ]]; then
        dns_info=$(echo "$dns_info" | jq --arg cname "$cname" '.cname = $cname')
        
        for provider in "${!CDN_PROVIDERS[@]}"; do
            local signature="${CDN_PROVIDERS[$provider]}"
            
            if echo "$cname" | grep -qi "$signature"; then
                dns_info=$(echo "$dns_info" | jq --arg provider "$provider" '.cname_provider = $provider')
                break
            fi
        done
    fi
    
    # Verificar registros A/AAAA
    local ips
    ips=$(dig +short "$target" A 2>/dev/null)
    local ip_list="[]"
    
    while IFS= read -r ip; do
        if [[ -n "$ip" ]]; then
            ip_list=$(echo "$ip_list" | jq --arg ip "$ip" '. += [$ip]')
        fi
    done <<< "$ips"
    
    if [[ "$ip_list" != "[]" ]]; then
        dns_info=$(echo "$dns_info" | jq --argjson ips "$ip_list" '.ips = $ips')
    fi
    
    # Verificar múltiplos IPs (round-robin)
    local ip_count
    ip_count=$(echo "$ip_list" | jq 'length')
    
    if [[ $ip_count -gt 1 ]]; then
        dns_info=$(echo "$dns_info" | jq '.round_robin = true')
    fi
    
    echo "$dns_info"
}

# Detectar CDN a partir de IP
detect_cdn_from_ip() {
    local target="$1"
    local ip_info="{}"
    
    # Resolver IP
    local ip
    ip=$(dig +short "$target" A 2>/dev/null | head -1)
    
    if [[ -n "$ip" ]]; then
        ip_info=$(echo "$ip_info" | jq --arg ip "$ip" '.ip = $ip')
        
        # Verificar ranges
        for provider in "${!CDN_IP_RANGES[@]}"; do
            local ranges="${CDN_IP_RANGES[$provider]}"
            
            for range in $ranges; do
                if ip_in_range "$ip" "$range"; then
                    ip_info=$(echo "$ip_info" | jq --arg provider "$provider" '.ip_provider = $provider')
                    break 2
                fi
            done
        done
        
        # Geolocalização do IP
        local geo_info
        geo_info=$(curl -s "http://ip-api.com/json/${ip}" 2>/dev/null)
        
        if [[ -n "$geo_info" ]]; then
            local country
            country=$(echo "$geo_info" | jq -r '.country // empty')
            local city
            city=$(echo "$geo_info" | jq -r '.city // empty')
            local org
            org=$(echo "$geo_info" | jq -r '.org // empty')
            
            if [[ -n "$country" ]]; then
                ip_info=$(echo "$ip_info" | jq --arg country "$country" '.country = $country')
            fi
            if [[ -n "$city" ]]; then
                ip_info=$(echo "$ip_info" | jq --arg city "$city" '.city = $city')
            fi
            if [[ -n "$org" ]]; then
                ip_info=$(echo "$ip_info" | jq --arg org "$org" '.org = $org')
            fi
        fi
    fi
    
    echo "$ip_info"
}

# Detectar CDN a partir de headers HTTP
detect_cdn_from_headers() {
    local target="$1"
    local headers_info="{}"
    
    # Headers HTTP
    local headers
    headers=$(curl -s -I -L "http://${target}" 2>/dev/null)
    
    if [[ -n "$headers" ]]; then
        # Server header
        local server
        server=$(echo "$headers" | grep -i "^server:" | head -1 | cut -d':' -f2- | sed 's/^[ \t]*//')
        
        if [[ -n "$server" ]]; then
            headers_info=$(echo "$headers_info" | jq --arg server "$server" '.server = $server')
            
            # Identificar provider pelo server header
            for provider in "${!CDN_PROVIDERS[@]}"; do
                if echo "$server" | grep -qi "${CDN_PROVIDERS[$provider]}"; then
                    headers_info=$(echo "$headers_info" | jq --arg provider "$provider" '.server_provider = $provider')
                    break
                fi
            done
        fi
        
        # Via header
        local via
        via=$(echo "$headers" | grep -i "^via:" | head -1 | cut -d':' -f2- | sed 's/^[ \t]*//')
        
        if [[ -n "$via" ]]; then
            headers_info=$(echo "$headers_info" | jq --arg via "$via" '.via = $via')
            
            # Cloudflare
            if echo "$via" | grep -qi "cloudflare"; then
                headers_info=$(echo "$headers_info" | jq '.via_provider = "Cloudflare"')
            # Fastly
            elif echo "$via" | grep -qi "fastly"; then
                headers_info=$(echo "$headers_info" | jq '.via_provider = "Fastly"')
            # Akamai
            elif echo "$via" | grep -qi "akamai"; then
                headers_info=$(echo "$headers_info" | jq '.via_provider = "Akamai"')
            fi
        fi
        
        # X-Cache header
        local x_cache
        x_cache=$(echo "$headers" | grep -i "^x-cache:" | head -1 | cut -d':' -f2- | sed 's/^[ \t]*//')
        
        if [[ -n "$x_cache" ]]; then
            headers_info=$(echo "$headers_info" | jq --arg cache "$x_cache" '.x_cache = $cache')
            
            if echo "$x_cache" | grep -qi "cloudflare"; then
                headers_info=$(echo "$headers_info" | jq '.cache_provider = "Cloudflare"')
            elif echo "$x_cache" | grep -qi "fastly"; then
                headers_info=$(echo "$headers_info" | jq '.cache_provider = "Fastly"')
            fi
        fi
        
        # CF-Ray header (Cloudflare)
        local cf_ray
        cf_ray=$(echo "$headers" | grep -i "^cf-ray:" | head -1)
        
        if [[ -n "$cf_ray" ]]; then
            headers_info=$(echo "$headers_info" | jq '.cf_ray = true')
            headers_info=$(echo "$headers_info" | jq '.provider = "Cloudflare"')
        fi
        
        # X-Amz-Cf-* headers (CloudFront)
        local cf_headers
        cf_headers=$(echo "$headers" | grep -i "^x-amz-cf-" | head -1)
        
        if [[ -n "$cf_headers" ]]; then
            headers_info=$(echo "$headers_info" | jq '.cloudfront = true')
            headers_info=$(echo "$headers_info" | jq '.provider = "CloudFront"')
        fi
        
        # X-Azure-* headers
        local azure_headers
        azure_headers=$(echo "$headers" | grep -i "^x-azure-" | head -1)
        
        if [[ -n "$azure_headers" ]]; then
            headers_info=$(echo "$headers_info" | jq '.azure = true')
            headers_info=$(echo "$headers_info" | jq '.provider = "Azure"')
        fi
        
        # X-GUploader-UploadID (Google)
        local google_headers
        google_headers=$(echo "$headers" | grep -i "^x-guploader" | head -1)
        
        if [[ -n "$google_headers" ]]; then
            headers_info=$(echo "$headers_info" | jq '.google = true')
            headers_info=$(echo "$headers_info" | jq '.provider = "Google"')
        fi
    fi
    
    # Tentar HTTPS também
    local headers_https
    headers_https=$(curl -s -I -L "https://${target}" 2>/dev/null)
    
    if [[ -n "$headers_https" ]] && [[ "$headers_https" != "$headers" ]]; then
        headers_info=$(echo "$headers_info" | jq --arg https "$headers_https" '.https_headers = $https')
    fi
    
    echo "$headers_info"
}

# Detectar CDN a partir de padrões na resposta
detect_cdn_from_response() {
    local target="$1"
    local response_info="{}"
    
    # Obter página principal
    local response
    response=$(curl -s -L "http://${target}" 2>/dev/null)
    
    if [[ -n "$response" ]]; then
        # Cloudflare challenge page
        if echo "$response" | grep -qi "cloudflare"; then
            response_info=$(echo "$response_info" | jq '.cloudflare_challenge = true')
            response_info=$(echo "$response_info" | jq '.provider = "Cloudflare"')
        fi
        
        # DDoS protection pages
        if echo "$response" | grep -qi "ddos protection"; then
            response_info=$(echo "$response_info" | jq '.ddos_protection = true')
        fi
        
        # Incapsula
        if echo "$response" | grep -qi "incapsula"; then
            response_info=$(echo "$response_info" | jq '.incapsula = true')
            response_info=$(echo "$response_info" | jq '.provider = "Incapsula"')
        fi
        
        # Sucuri
        if echo "$response" | grep -qi "sucuri"; then
            response_info=$(echo "$response_info" | jq '.sucuri = true')
            response_info=$(echo "$response_info" | jq '.provider = "Sucuri"')
        fi
        
        # Cloudbric
        if echo "$response" | grep -qi "cloudbric"; then
            response_info=$(echo "$response_info" | jq '.cloudbric = true')
            response_info=$(echo "$response_info" | jq '.provider = "Cloudbric"')
        fi
    fi
    
    echo "$response_info"
}

# Detectar CDN a partir de cookies
detect_cdn_from_cookies() {
    local target="$1"
    local cookies_info="{}"
    
    # Headers com cookies
    local headers
    headers=$(curl -s -I -L "http://${target}" 2>/dev/null)
    
    if [[ -n "$headers" ]]; then
        local cookies
        cookies=$(echo "$headers" | grep -i "^set-cookie:" | cut -d':' -f2- | sed 's/^[ \t]*//')
        
        if [[ -n "$cookies" ]]; then
            # Cloudflare
            if echo "$cookies" | grep -qi "__cfduid\|cf_clearance"; then
                cookies_info=$(echo "$cookies_info" | jq '.cloudflare = true')
                cookies_info=$(echo "$cookies_info" | jq '.provider = "Cloudflare"')
            fi
            
            # Akamai
            if echo "$cookies" | grep -qi "akamai"; then
                cookies_info=$(echo "$cookies_info" | jq '.akamai = true')
                cookies_info=$(echo "$cookies_info" | jq '.provider = "Akamai"')
            fi
            
            # Incapsula
            if echo "$cookies" | grep -qi "incap_ses\|visid_incap"; then
                cookies_info=$(echo "$cookies_info" | jq '.incapsula = true')
                cookies_info=$(echo "$cookies_info" | jq '.provider = "Incapsula"')
            fi
            
            # Sucuri
            if echo "$cookies" | grep -qi "sucuri"; then
                cookies_info=$(echo "$cookies_info" | jq '.sucuri = true')
                cookies_info=$(echo "$cookies_info" | jq '.provider = "Sucuri"')
            fi
        fi
    fi
    
    echo "$cookies_info"
}

# Verificar presença de WAF
check_waf_presence() {
    local target="$1"
    local waf_info="{}"
    
    # Payloads de teste
    local test_payloads=(
        "' OR '1'='1"
        "<script>alert(1)</script>"
        "../../../etc/passwd"
        "UNION SELECT ALL FROM information_schema"
        "1=1--"
        "'; DROP TABLE users; --"
        "${IFS}ls${IFS}-la"
        "| cat /etc/passwd"
        "`id`"
        "$(id)"
    )
    
    for payload in "${test_payloads[@]}"; do
        local url="http://${target}/?test=${payload}"
        local response
        response=$(curl -s -I "$url" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            # Verificar status code (alguns WAFs retornam 403/406)
            local status
            status=$(echo "$response" | head -1 | awk '{print $2}')
            
            if [[ "$status" == "403" ]] || [[ "$status" == "406" ]] || [[ "$status" == "429" ]]; then
                waf_info=$(echo "$waf_info" | jq '.detected = true')
                waf_info=$(echo "$waf_info" | jq --arg status "$status" '.block_status = $status')
                
                # Verificar headers de WAF
                if echo "$response" | grep -qi "cloudflare"; then
                    waf_info=$(echo "$waf_info" | jq '.waf = "Cloudflare"')
                elif echo "$response" | grep -qi "akamai"; then
                    waf_info=$(echo "$waf_info" | jq '.waf = "Akamai"')
                elif echo "$response" | grep -qi "incapsula"; then
                    waf_info=$(echo "$waf_info" | jq '.waf = "Incapsula"')
                elif echo "$response" | grep -qi "sucuri"; then
                    waf_info=$(echo "$waf_info" | jq '.waf = "Sucuri"')
                elif echo "$response" | grep -qi "mod_security"; then
                    waf_info=$(echo "$waf_info" | jq '.waf = "ModSecurity"')
                fi
                
                break
            fi
        fi
    done
    
    if [[ "$(echo "$waf_info" | jq -r '.detected')" != "true" ]]; then
        waf_info=$(echo "$waf_info" | jq '.detected = false')
    fi
    
    echo "$waf_info"
}

# Determinar provedor CDN final
determine_cdn_provider() {
    local results="$1"
    
    # Prioridade: headers > cookies > IP > DNS
    local provider
    
    # Headers
    provider=$(echo "$results" | jq -r '.headers.provider // empty')
    if [[ -n "$provider" ]] && [[ "$provider" != "null" ]]; then
        echo "$provider"
        return 0
    fi
    
    # Cookies
    provider=$(echo "$results" | jq -r '.cookies.provider // empty')
    if [[ -n "$provider" ]] && [[ "$provider" != "null" ]]; then
        echo "$provider"
        return 0
    fi
    
    # IP
    provider=$(echo "$results" | jq -r '.ip.ip_provider // empty')
    if [[ -n "$provider" ]] && [[ "$provider" != "null" ]]; then
        echo "$provider"
        return 0
    fi
    
    # DNS
    provider=$(echo "$results" | jq -r '.dns.cname_provider // empty')
    if [[ -n "$provider" ]] && [[ "$provider" != "null" ]]; then
        echo "$provider"
        return 0
    fi
    
    echo "No CDN detected"
}

# Obter configuração do CDN
get_cdn_configuration() {
    local target="$1"
    local provider="$2"
    local config="{}"
    
    case "$provider" in
        "Cloudflare")
            # Verificar configurações Cloudflare
            local headers
            headers=$(curl -s -I "http://${target}" 2>/dev/null)
            
            # Cache status
            local cache_status
            cache_status=$(echo "$headers" | grep -i "cf-cache-status" | cut -d':' -f2- | sed 's/^[ \t]*//')
            if [[ -n "$cache_status" ]]; then
                config=$(echo "$config" | jq --arg status "$cache_status" '.cache_status = $status')
            fi
            
            # Ray ID
            local ray_id
            ray_id=$(echo "$headers" | grep -i "cf-ray" | cut -d':' -f2- | sed 's/^[ \t]*//')
            if [[ -n "$ray_id" ]]; then
                config=$(echo "$config" | jq --arg ray "$ray_id" '.ray_id = $ray')
            fi
            
            # Política de cache
            if [[ "$cache_status" == "HIT" ]]; then
                config=$(echo "$config" | jq '.caching = "enabled"')
            else
                config=$(echo "$config" | jq '.caching = "disabled"')
            fi
            ;;
            
        "CloudFront")
            # Verificar configurações CloudFront
            local headers
            headers=$(curl -s -I "http://${target}" 2>/dev/null)
            
            # CloudFront ID
            local cf_id
            cf_id=$(echo "$headers" | grep -i "x-amz-cf-id" | cut -d':' -f2- | sed 's/^[ \t]*//')
            if [[ -n "$cf_id" ]]; then
                config=$(echo "$config" | jq --arg id "$cf_id" '.cloudfront_id = $id')
            fi
            
            # POP
            local pop
            pop=$(echo "$headers" | grep -i "x-amz-cf-pop" | cut -d':' -f2- | sed 's/^[ \t]*//')
            if [[ -n "$pop" ]]; then
                config=$(echo "$config" | jq --arg pop "$pop" '.pop = $pop')
            fi
            ;;
            
        "Fastly")
            # Verificar configurações Fastly
            local headers
            headers=$(curl -s -I "http://${target}" 2>/dev/null)
            
            # Fastly headers
            local fastly_headers
            fastly_headers=$(echo "$headers" | grep -i "^x-fastly-" | cut -d':' -f1)
            if [[ -n "$fastly_headers" ]]; then
                config=$(echo "$config" | jq '.fastly_headers_present = true')
            fi
            
            # Cache status
            local cache_hit
            cache_hit=$(echo "$headers" | grep -i "x-cache" | grep -i "hit")
            if [[ -n "$cache_hit" ]]; then
                config=$(echo "$config" | jq '.cache_hit = true')
            fi
            ;;
    esac
    
    echo "$config"
}

# Verificar se IP está em range CIDR
ip_in_range() {
    local ip="$1"
    local cidr="$2"
    
    if command -v ipcalc &> /dev/null; then
        ipcalc -c "$ip" "$cidr" &>/dev/null
        return $?
    fi
    
    # Implementação simplificada
    local network="${cidr%/*}"
    local mask="${cidr#*/}"
    
    IFS='.' read -r i1 i2 i3 i4 <<< "$ip"
    IFS='.' read -r n1 n2 n3 n4 <<< "$network"
    
    local ip_num=$(( (i1 << 24) + (i2 << 16) + (i3 << 8) + i4 ))
    local net_num=$(( (n1 << 24) + (n2 << 16) + (n3 << 8) + n4 ))
    local mask_num=$(( 0xffffffff << (32 - mask) ))
    
    if [[ $((ip_num & mask_num)) -eq $((net_num & mask_num)) ]]; then
        return 0
    fi
    
    return 1
}

# Exportar funções
export -f init_cdn_detection detect_cdn