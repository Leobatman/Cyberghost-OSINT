#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - WAF Detection Module
# =============================================================================

MODULE_NAME="WAF Detection"
MODULE_DESC="Detect Web Application Firewalls and security solutions"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# WAF signatures
declare -A WAF_SIGNATURES=(
    ["Cloudflare"]="cloudflare|__cfduid|cf-ray|cf-cache-status"
    ["Akamai"]="akamai|akamaighost|X-Akamai|AkamaiGHost"
    ["AWS WAF"]="awswaf|X-Amz-Cf-Id|X-Amz-Cf-Pop"
    ["F5 BIG-IP"]="BigIP|BIG-IP|F5|X-F5"
    ["Imperva"]="incapsula|X-Iinfo|X-CDN|Imperva"
    ["Sucuri"]="sucuri|Sucuri|X-Sucuri"
    ["Cloudbric"]="cloudbric|Cloudbric"
    ["Barracuda"]="barracuda|Barracuda"
    ["Citrix"]="citrix|Citrix|Netscaler"
    ["Fortinet"]="fortinet|FortiWeb|FortiGate"
    ["Radware"]="radware|Radware|AppWall"
    ["StackPath"]="stackpath|StackPath"
    ["Fastly"]="fastly|Fastly|X-Fastly"
    ["Varnish"]="varnish|Varnish"
    ["ModSecurity"]="mod_security|ModSecurity"
    ["NAXSI"]="naxsi|NAXSI"
    ["Shadow Daemon"]="shadowd|Shadow Daemon"
    ["WebKnight"]="webknight|WebKnight"
    ["dotDefender"]="dotdefender|dotDefender"
)

# WAF response patterns
declare -A WAF_RESPONSES=(
    ["Cloudflare"]="<title>Cloudflare</title>|<title>Access denied</title>"
    ["AWS WAF"]="<title>403 Forbidden</title>|Request blocked"
    ["F5 BIG-IP"]="<title>Big-IP</title>|The requested URL was rejected"
    ["Imperva"]="<title>Incapsula</title>|Invalid request"
    ["Sucuri"]="<title>Sucuri</title>|Sucuri WebSite Firewall"
)

# Test payloads
declare -a TEST_PAYLOADS=(
    "' OR '1'='1"
    "<script>alert(1)</script>"
    "../../../etc/passwd"
    "1=1--"
    "'; DROP TABLE users; --"
    "${IFS}ls${IFS}-la"
    "| cat /etc/passwd"
    "`id`"
    "$(id)"
    "UNION SELECT ALL FROM information_schema"
    "1' AND 1=1 UNION ALL SELECT 1,2,3,4"
    "<?php system('id'); ?>"
    "javascript:alert(document.cookie)"
    "\\x00\\x27\\x22"
    "%00'"
    "..\\..\\..\\windows\\win.ini"
)

# Inicializar módulo
init_waf_detection() {
    log "INFO" "Initializing WAF Detection module" "WAF"
    
    # Verificar dependências
    local deps=("curl" "grep" "sed" "awk" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "WAF"
        return 1
    fi
    
    return 0
}

# Função principal
detect_waf() {
    local target="$1"
    local output_dir="$2"
    
    log "WEB" "Starting WAF detection for: $target" "WAF"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/waf"
    mkdir -p "$results_dir"
    
    local results="{}"
    
    # Normalizar URL
    target=$(normalize_url "$target")
    results=$(echo "$results" | jq --arg url "$target" '.target = $url')
    
    # 1. Análise de headers
    log "INFO" "Analyzing HTTP headers" "WAF"
    local headers
    headers=$(analyze_waf_headers "$target")
    results=$(echo "$results" | jq --argjson headers "$headers" '.headers = $headers')
    
    # 2. Análise de cookies
    log "INFO" "Analyzing cookies" "WAF"
    local cookies
    cookies=$(analyze_waf_cookies "$target")
    results=$(echo "$results" | jq --argjson cookies "$cookies" '.cookies = $cookies')
    
    # 3. Testes com payloads maliciosos
    log "INFO" "Testing with malicious payloads" "WAF"
    local test_results
    test_results=$(test_waf_payloads "$target")
    results=$(echo "$results" | jq --argjson tests "$test_results" '.payload_tests = $tests')
    
    # 4. Análise de página de bloqueio
    log "INFO" "Analyzing block pages" "WAF"
    local block_pages
    block_pages=$(analyze_block_pages "$target")
    results=$(echo "$results" | jq --argjson block "$block_pages" '.block_pages = $block')
    
    # 5. Fingerprinting WAF
    log "INFO" "WAF fingerprinting" "WAF"
    local fingerprint
    fingerprint=$(fingerprint_waf "$headers" "$cookies" "$test_results" "$block_pages")
    results=$(echo "$results" | jq --argjson fp "$fingerprint" '.fingerprint = $fp')
    
    # 6. Testes de evasão
    log "INFO" "Testing evasion techniques" "WAF"
    local evasion
    evasion=$(test_waf_evasion "$target")
    results=$(echo "$results" | jq --argjson ev "$evasion" '.evasion_tests = $ev')
    
    # 7. Detectar WAF por IP
    log "INFO" "Checking WAF by IP" "WAF"
    local ip_waf
    ip_waf=$(detect_waf_by_ip "$target")
    results=$(echo "$results" | jq --argjson ip "$ip_waf" '.ip_based = $ip')
    
    # 8. Detectar WAF por DNS
    log "INFO" "Checking WAF by DNS" "WAF"
    local dns_waf
    dns_waf=$(detect_waf_by_dns "$target")
    results=$(echo "$results" | jq --argjson dns "$dns_waf" '.dns_based = $dns')
    
    # 9. Análise de rate limiting
    log "INFO" "Testing rate limiting" "WAF"
    local rate_limit
    rate_limit=$(test_rate_limiting "$target")
    results=$(echo "$results" | jq --argjson rate "$rate_limit" '.rate_limiting = $rate')
    
    # 10. Estatísticas e conclusão
    log "INFO" "Generating final results" "WAF"
    local summary
    summary=$(generate_waf_summary "$results")
    results=$(echo "$results" | jq --argjson sum "$summary" '.summary = $sum')
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/waf.json"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local waf_name
    waf_name=$(echo "$fingerprint" | jq -r '.name // "No WAF detected"')
    
    log "SUCCESS" "WAF detection completed in ${duration}s - Detected: $waf_name" "WAF"
    
    echo "$results"
}

# Normalizar URL
normalize_url() {
    local url="$1"
    
    if [[ ! "$url" =~ ^https?:// ]]; then
        url="http://${url}"
    fi
    
    echo "$url"
}

# Analisar headers em busca de WAF
analyze_waf_headers() {
    local url="$1"
    local headers_analysis="[]"
    
    local response
    response=$(curl -s -I -L "$url" 2>/dev/null)
    
    if [[ -n "$response" ]]; then
        for waf in "${!WAF_SIGNATURES[@]}"; do
            local signature="${WAF_SIGNATURES[$waf]}"
            
            # Verificar cada header
            while IFS= read -r line; do
                if [[ -n "$line" ]] && echo "$line" | grep -q -i "$signature"; then
                    headers_analysis=$(echo "$headers_analysis" | jq \
                        --arg waf "$waf" \
                        --arg header "$(echo "$line" | cut -d':' -f1)" \
                        '. += [{
                            "waf": $waf,
                            "type": "header",
                            "value": $header
                        }]')
                fi
            done <<< "$response"
        done
    fi
    
    echo "$headers_analysis"
}

# Analisar cookies em busca de WAF
analyze_waf_cookies() {
    local url="$1"
    local cookies_analysis="[]"
    
    local response
    response=$(curl -s -I -L "$url" 2>/dev/null)
    
    if [[ -n "$response" ]]; then
        # Extrair cookies
        local cookies
        cookies=$(echo "$response" | grep -i "^set-cookie:")
        
        for waf in "${!WAF_SIGNATURES[@]}"; do
            local signature="${WAF_SIGNATURES[$waf]}"
            
            if echo "$cookies" | grep -q -i "$signature"; then
                cookies_analysis=$(echo "$cookies_analysis" | jq \
                    --arg waf "$waf" \
                    '. += [{
                        "waf": $waf,
                        "type": "cookie"
                    }]')
            fi
        done
    fi
    
    echo "$cookies_analysis"
}

# Testar payloads maliciosos
test_waf_payloads() {
    local url="$1"
    local test_results="[]"
    
    local normal_response
    normal_response=$(curl -s "$url" 2>/dev/null)
    local normal_size=${#normal_response}
    local normal_status
    normal_status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    for payload in "${TEST_PAYLOADS[@]}"; do
        local test_url="${url}/?test=${payload}"
        local response
        response=$(curl -s -i "$test_url" 2>/dev/null)
        local status
        status=$(echo "$response" | head -1 | awk '{print $2}')
        local size=${#response}
        
        # Verificar diferenças
        if [[ "$status" != "$normal_status" ]] || [[ $((size * 10)) -lt $normal_size ]]; then
            # Possível WAF detectado
            local waf_detected=""
            
            # Verificar mensagens de bloqueio
            for waf in "${!WAF_RESPONSES[@]}"; do
                local pattern="${WAF_RESPONSES[$waf]}"
                if echo "$response" | grep -q -E "$pattern"; then
                    waf_detected="$waf"
                    break
                fi
            done
            
            test_results=$(echo "$test_results" | jq \
                --arg payload "$payload" \
                --arg code "$status" \
                --arg waf "$waf_detected" \
                '. += [{
                    "payload": $payload,
                    "status_code": $code,
                    "blocked": true,
                    "waf_detected": $waf
                }]')
        else
            test_results=$(echo "$test_results" | jq \
                --arg payload "$payload" \
                --arg code "$status" \
                '. += [{
                    "payload": $payload,
                    "status_code": $code,
                    "blocked": false
                }]')
        fi
        
        # Pequeno delay para evitar bloqueio
        sleep 0.5
    done
    
    echo "$test_results"
}

# Analisar páginas de bloqueio
analyze_block_pages() {
    local url="$1"
    local block_pages="[]"
    
    # Tentar acessar página de admin para provocar bloqueio
    local test_urls=(
        "${url}/admin"
        "${url}/wp-admin"
        "${url}/administrator"
        "${url}/phpmyadmin"
        "${url}/?id=1' OR '1'='1"
        "${url}/?q=<script>alert(1)</script>"
    )
    
    for test_url in "${test_urls[@]}"; do
        local response
        response=$(curl -s -i "$test_url" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            for waf in "${!WAF_RESPONSES[@]}"; do
                local pattern="${WAF_RESPONSES[$waf]}"
                if echo "$response" | grep -q -E "$pattern"; then
                    block_pages=$(echo "$block_pages" | jq \
                        --arg waf "$waf" \
                        --arg url "$test_url" \
                        '. += [{
                            "waf": $waf,
                            "url": $url,
                            "pattern_matched": $pattern
                        }]')
                    break
                fi
            done
        fi
    done
    
    echo "$block_pages"
}

# Fingerprinting WAF
fingerprint_waf() {
    local headers="$1"
    local cookies="$2"
    local test_results="$3"
    local block_pages="$4"
    local fingerprint="{}"
    
    local waf_scores="{}"
    
    # Pontuar baseado em headers
    echo "$headers" | jq -c '.[]' | while read -r item; do
        local waf
        waf=$(echo "$item" | jq -r '.waf')
        local score
        score=$(echo "$waf_scores" | jq -r ".[\"$waf\"] // 0")
        score=$((score + 10))
        waf_scores=$(echo "$waf_scores" | jq --arg waf "$waf" --argjson score "$score" '.[$waf] = $score')
    done
    
    # Pontuar baseado em cookies
    echo "$cookies" | jq -c '.[]' | while read -r item; do
        local waf
        waf=$(echo "$item" | jq -r '.waf')
        local score
        score=$(echo "$waf_scores" | jq -r ".[\"$waf\"] // 0")
        score=$((score + 10))
        waf_scores=$(echo "$waf_scores" | jq --arg waf "$waf" --argjson score "$score" '.[$waf] = $score')
    done
    
    # Pontuar baseado em testes
    echo "$test_results" | jq -c '.[] | select(.blocked == true)' | while read -r item; do
        local waf
        waf=$(echo "$item" | jq -r '.waf_detected // "unknown"')
        if [[ "$waf" != "unknown" ]] && [[ -n "$waf" ]]; then
            local score
            score=$(echo "$waf_scores" | jq -r ".[\"$waf\"] // 0")
            score=$((score + 20))
            waf_scores=$(echo "$waf_scores" | jq --arg waf "$waf" --argjson score "$score" '.[$waf] = $score')
        fi
    done
    
    # Pontuar baseado em block pages
    echo "$block_pages" | jq -c '.[]' | while read -r item; do
        local waf
        waf=$(echo "$item" | jq -r '.waf')
        local score
        score=$(echo "$waf_scores" | jq -r ".[\"$waf\"] // 0")
        score=$((score + 30))
        waf_scores=$(echo "$waf_scores" | jq --arg waf "$waf" --argjson score "$score" '.[$waf] = $score')
    done
    
    # Determinar WAF com maior score
    local top_waf
    top_waf=$(echo "$waf_scores" | jq -r 'to_entries | sort_by(.value) | reverse | .[0] // empty')
    
    if [[ -n "$top_waf" ]]; then
        local name
        name=$(echo "$top_waf" | jq -r '.key')
        local score
        score=$(echo "$top_waf" | jq -r '.value')
        
        fingerprint=$(echo "$fingerprint" | jq \
            --arg name "$name" \
            --argjson score "$score" \
            '{
                name: $name,
                confidence: $score,
                detected: true
            }')
    else
        fingerprint=$(echo "$fingerprint" | jq '{
            name: "No WAF detected",
            detected: false
        }')
    fi
    
    echo "$fingerprint"
}

# Testar técnicas de evasão
test_waf_evasion() {
    local url="$1"
    local evasion_results="[]"
    
    # Técnicas de evasão
    local evasion_techs=(
        "case:SelECt"
        "comment:/*!*/"
        "urlencode:%27%20OR%20%271%27%3D%271"
        "double_urlencode:%2527%2520OR%25201%253D1"
        "unicode:%u0027%u0020OR%u00201%u003D1"
        "hex:0x27204f5220313d31"
        "base64:JyBPUiAnMSc9JzE="
        "null_byte:%00'"
        "line_breaks:%0A"
        "tab:%09"
    )
    
    for tech in "${evasion_techs[@]}"; do
        IFS=':' read -r name payload <<< "$tech"
        
        local test_url="${url}/?id=${payload}"
        local status
        status=$(curl -s -o /dev/null -w "%{http_code}" "$test_url" 2>/dev/null)
        
        evasion_results=$(echo "$evasion_results" | jq \
            --arg name "$name" \
            --arg payload "$payload" \
            --arg code "$status" \
            '. += [{
                "technique": $name,
                "payload": $payload,
                "status_code": $code,
                "bypassed": [403,429,500] | contains([$code | tonumber]) | not
            }]')
    done
    
    echo "$evasion_results"
}

# Detectar WAF por IP
detect_waf_by_ip() {
    local url="$1"
    local ip_results="{}"
    
    # Resolver IP
    local domain
    domain=$(echo "$url" | awk -F/ '{print $3}')
    local ip
    ip=$(dig +short "$domain" 2>/dev/null | head -1)
    
    if [[ -n "$ip" ]]; then
        # Ranges de IP de WAFs conhecidos
        local cloudflare_ranges=("103.21.244.0/22" "103.22.200.0/22" "103.31.4.0/22" "104.16.0.0/12")
        local akamai_ranges=("2.16.0.0/13" "2.20.0.0/15" "23.0.0.0/12")
        local incapsula_ranges=("199.83.128.0/21" "198.143.32.0/19" "149.126.72.0/21")
        
        for range in "${cloudflare_ranges[@]}"; do
            if ip_in_range "$ip" "$range"; then
                ip_results=$(echo "$ip_results" | jq '.waf = "Cloudflare"')
                break
            fi
        done
        
        if [[ "$(echo "$ip_results" | jq -r '.waf')" == "null" ]]; then
            for range in "${akamai_ranges[@]}"; do
                if ip_in_range "$ip" "$range"; then
                    ip_results=$(echo "$ip_results" | jq '.waf = "Akamai"')
                    break
                fi
            done
        fi
        
        if [[ "$(echo "$ip_results" | jq -r '.waf')" == "null" ]]; then
            for range in "${incapsula_ranges[@]}"; do
                if ip_in_range "$ip" "$range"; then
                    ip_results=$(echo "$ip_results" | jq '.waf = "Imperva/Incapsula"')
                    break
                fi
            done
        fi
    fi
    
    echo "$ip_results"
}

# Detectar WAF por DNS
detect_waf_by_dns() {
    local url="$1"
    local dns_results="{}"
    
    local domain
    domain=$(echo "$url" | awk -F/ '{print $3}')
    
    # Verificar CNAME
    local cname
    cname=$(dig +short "$domain" CNAME 2>/dev/null | head -1)
    
    if [[ -n "$cname" ]]; then
        case "$cname" in
            *cloudflare*)
                dns_results=$(echo "$dns_results" | jq '.waf = "Cloudflare"')
                ;;
            *akamai*)
                dns_results=$(echo "$dns_results" | jq '.waf = "Akamai"')
                ;;
            *fastly*)
                dns_results=$(echo "$dns_results" | jq '.waf = "Fastly"')
                ;;
            *incapsula*)
                dns_results=$(echo "$dns_results" | jq '.waf = "Imperva/Incapsula"')
                ;;
            *sucuri*)
                dns_results=$(echo "$dns_results" | jq '.waf = "Sucuri"')
                ;;
        esac
    fi
    
    echo "$dns_results"
}

# Testar rate limiting
test_rate_limiting() {
    local url="$1"
    local rate_results="{}"
    
    local normal_status
    normal_status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    # Fazer várias requisições rápidas
    local status_codes=()
    local rate_limited=false
    
    for ((i=0; i<20; i++)); do
        local status
        status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
        status_codes+=("$status")
        
        if [[ "$status" == "429" ]] || [[ "$status" == "503" ]]; then
            rate_limited=true
        fi
        
        # Sem delay para testar rate limiting
    done
    
    rate_results=$(echo "$rate_results" | jq --argjson limited "$rate_limited" '.rate_limited = $limited')
    
    # Contar respostas diferentes
    local unique_codes
    unique_codes=$(printf '%s\n' "${status_codes[@]}" | sort -u | wc -l)
    
    if [[ $unique_codes -gt 1 ]]; then
        rate_results=$(echo "$rate_results" | jq '.behavior_changed = true')
    fi
    
    echo "$rate_results"
}

# Gerar sumário
generate_waf_summary() {
    local results="$1"
    local summary="{}"
    
    local fingerprint
    fingerprint=$(echo "$results" | jq -c '.fingerprint // {}')
    
    local detected
    detected=$(echo "$fingerprint" | jq -r '.detected // false')
    
    if [[ "$detected" == "true" ]]; then
        local name
        name=$(echo "$fingerprint" | jq -r '.name')
        local confidence
        confidence=$(echo "$fingerprint" | jq -r '.confidence')
        
        summary=$(echo "$summary" | jq \
            --arg name "$name" \
            --argjson conf "$confidence" \
            '{
                waf_detected: true,
                waf_name: $name,
                confidence: $conf
            }')
        
        # Nível de proteção
        local block_rate
        block_rate=$(echo "$results" | jq '[.payload_tests[] | select(.blocked == true)] | length')
        local total_tests
        total_tests=$(echo "$results" | jq '.payload_tests | length')
        
        if [[ $total_tests -gt 0 ]]; then
            local protection_level
            if [[ $block_rate -gt $((total_tests * 80 / 100)) ]]; then
                protection_level="high"
            elif [[ $block_rate -gt $((total_tests * 50 / 100)) ]]; then
                protection_level="medium"
            else
                protection_level="low"
            fi
            summary=$(echo "$summary" | jq --arg level "$protection_level" '.protection_level = $level')
        fi
    else
        summary=$(echo "$summary" | jq '{
            waf_detected: false
        }')
    fi
    
    echo "$summary"
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
export -f init_waf_detection detect_waf