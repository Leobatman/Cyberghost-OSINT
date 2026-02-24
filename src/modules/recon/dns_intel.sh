#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Deep DNS Intelligence Module
# =============================================================================

MODULE_NAME="DNS Intelligence"
MODULE_DESC="Advanced DNS reconnaissance and analysis"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# Tipos de registro DNS
DNS_RECORD_TYPES=("A" "AAAA" "MX" "NS" "TXT" "SOA" "CNAME" "PTR" "SRV" "CAA" "NAPTR" "DS" "RRSIG" "DNSKEY")

# Inicializar módulo
init_dns_intel() {
    log "INFO" "Initializing DNS Intelligence module" "DNS_INTEL"
    
    # Verificar dependências
    local deps=("dig" "host" "nslookup" "whois")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "DNS_INTEL"
        return 1
    fi
    
    return 0
}

# Função principal
dns_intelligence() {
    local target="$1"
    local output_dir="$2"
    
    log "RECON" "Starting DNS intelligence for: $target" "DNS_INTEL"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/dns_intel"
    mkdir -p "$results_dir"
    
    local results="{}"
    
    # 1. Registros DNS básicos
    log "INFO" "Fetching DNS records" "DNS_INTEL"
    local dns_records
    dns_records=$(get_all_dns_records "$target")
    results=$(echo "$results" | jq --argjson records "$dns_records" '.dns_records = $records')
    
    # 2. Histórico DNS
    log "INFO" "Checking DNS history" "DNS_INTEL"
    local dns_history
    dns_history=$(get_dns_history "$target")
    results=$(echo "$results" | jq --argjson history "$dns_history" '.dns_history = $history')
    
    # 3. DNSSEC validation
    log "INFO" "Validating DNSSEC" "DNS_INTEL"
    local dnssec_status
    dnssec_status=$(check_dnssec "$target")
    results=$(echo "$results" | jq --argjson dnssec "$dnssec_status" '.dnssec = $dnssec')
    
    # 4. Subdomain takeover check
    log "INFO" "Checking for subdomain takeover" "DNS_INTEL"
    local takeover_vulns
    takeover_vulns=$(check_takeover "$target")
    results=$(echo "$results" | jq --argjson takeover "$takeover_vulns" '.takeover_vulnerabilities = $takeover')
    
    # 5. DNS cache snooping
    log "INFO" "Attempting DNS cache snooping" "DNS_INTEL"
    local cache_snooping
    cache_snooping=$(dns_cache_snooping "$target")
    results=$(echo "$results" | jq --argjson snooping "$cache_snooping" '.cache_snooping = $snooping')
    
    # 6. DNS zone transfer
    log "INFO" "Attempting zone transfer" "DNS_INTEL"
    local zone_transfer
    zone_transfer=$(attempt_zone_transfer "$target")
    results=$(echo "$results" | jq --argjson transfer "$zone_transfer" '.zone_transfer = $transfer')
    
    # 7. Reverse DNS
    log "INFO" "Performing reverse DNS" "DNS_INTEL"
    local reverse_dns
    reverse_dns=$(reverse_dns_lookup "$target")
    results=$(echo "$results" | jq --argjson reverse "$reverse_dns" '.reverse_dns = $reverse')
    
    # 8. WHOIS information
    log "INFO" "Fetching WHOIS info" "DNS_INTEL"
    local whois_info
    whois_info=$(get_whois_info "$target")
    results=$(echo "$results" | jq --argjson whois "$whois_info" '.whois = $whois')
    
    # 9. DNS amplification check
    log "INFO" "Checking DNS amplification potential" "DNS_INTEL"
    local amplification
    amplification=$(check_dns_amplification "$target")
    results=$(echo "$results" | jq --argjson amp "$amplification" '.amplification_potential = $amp')
    
    # 10. DNS over HTTPS support
    log "INFO" "Checking DoH support" "DNS_INTEL"
    local doh_support
    doh_support=$(check_doh_support "$target")
    results=$(echo "$results" | jq --argjson doh "$doh_support" '.doh_support = $doh')
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/dns_intel.json"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "SUCCESS" "DNS intelligence completed in ${duration}s" "DNS_INTEL"
    
    echo "$results"
}

# Obter todos os registros DNS
get_all_dns_records() {
    local domain="$1"
    local records="{}"
    
    for type in "${DNS_RECORD_TYPES[@]}"; do
        local result
        result=$(dig +short "$domain" "$type" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        
        if [[ -n "$result" ]]; then
            records=$(echo "$records" | jq --arg type "$type" --arg result "$result" '. + {($type): $result}')
        fi
    done
    
    echo "$records"
}

# Histórico DNS (via SecurityTrails)
get_dns_history() {
    local domain="$1"
    local history="{}"
    
    # SecurityTrails API
    if [[ -n "$SECURITYTRAILS_API_KEY" ]]; then
        local response
        response=$(curl -s "https://api.securitytrails.com/v1/history/${domain}/dns/a" \
            -H "APIKEY: ${SECURITYTRAILS_API_KEY}" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            history=$(echo "$response" | jq '.records // []' 2>/dev/null)
        fi
    fi
    
    echo "$history"
}

# Verificar DNSSEC
check_dnssec() {
    local domain="$1"
    
    local dnssec_info="{}"
    
    # Verificar registros DS
    local ds_records
    ds_records=$(dig +short "$domain" DS 2>/dev/null)
    
    if [[ -n "$ds_records" ]]; then
        dnssec_info=$(echo "$dnssec_info" | jq --arg ds "$ds_records" '.ds_records = $ds')
    fi
    
    # Verificar RRSIG
    local rrsig
    rrsig=$(dig +short "$domain" RRSIG 2>/dev/null)
    
    if [[ -n "$rrsig" ]]; then
        dnssec_info=$(echo "$dnssec_info" | jq --arg rrsig "$rrsig" '.rrsig = $rrsig')
    fi
    
    # Verificar DNSKEY
    local dnskey
    dnskey=$(dig +short "$domain" DNSKEY 2>/dev/null)
    
    if [[ -n "$dnskey" ]]; then
        dnssec_info=$(echo "$dnssec_info" | jq --arg dnskey "$dnskey" '.dnskey = $dnskey')
    fi
    
    # Status DNSSEC
    local status="disabled"
    if [[ -n "$ds_records" ]] || [[ -n "$rrsig" ]] || [[ -n "$dnskey" ]]; then
        status="enabled"
    fi
    
    dnssec_info=$(echo "$dnssec_info" | jq --arg status "$status" '.status = $status')
    
    echo "$dnssec_info"
}

# Verificar subdomain takeover
check_takeover() {
    local domain="$1"
    
    local takeover_results=()
    
    # Serviços vulneráveis comuns
    local services=(
        "github.com:github.io"
        "herokuapp.com:herokudns.com"
        "readme.io:readme.io"
        "squarespace.com:squarespace.com"
        "unbounce.com:unbounce.com"
        "tumblr.com:tumblr.com"
        "wordpress.com:wordpress.com"
        "shopify.com:myshopify.com"
        "instapage.com:instapage.com"
        "surge.sh:surge.sh"
        "bitbucket.io:bitbucket.io"
        "fastly.net:fastly.net"
        "azurewebsites.net:azurewebsites.net"
        "cloudapp.net:cloudapp.net"
        "aws.amazon.com:amazonaws.com"
    )
    
    for service in "${services[@]}"; do
        local service_name="${service%%:*}"
        local cname_pattern="${service#*:}"
        
        # Verificar CNAME
        local cname
        cname=$(dig +short "$domain" CNAME 2>/dev/null | head -1)
        
        if [[ "$cname" == *"$cname_pattern"* ]]; then
            # Verificar se o domínio alvo existe
            if ! host "$cname" &>/dev/null; then
                takeover_results+=("{\"service\": \"$service_name\", \"cname\": \"$cname\", \"vulnerable\": true}")
            fi
        fi
    done
    
    if [[ ${#takeover_results[@]} -gt 0 ]]; then
        printf '%s\n' "${takeover_results[@]}" | jq -s '.'
    else
        echo "[]"
    fi
}

# DNS cache snooping
dns_cache_snooping() {
    local domain="$1"
    local nameservers=("8.8.8.8" "1.1.1.1" "208.67.222.222")
    
    local results="[]"
    
    for ns in "${nameservers[@]}"; do
        local query_time
        query_time=$(dig @"$ns" +noall +stats "$domain" 2>/dev/null | grep "Query time" | awk '{print $4}')
        
        if [[ -n "$query_time" ]] && [[ $query_time -lt 10 ]]; then
            # Query time muito baixo pode indicar cache
            results=$(echo "$results" | jq --arg ns "$ns" --arg time "$query_time" \
                '. += [{"nameserver": $ns, "query_time": $time, "cached": true}]')
        fi
    done
    
    echo "$results"
}

# Tentar zone transfer
attempt_zone_transfer() {
    local domain="$1"
    
    local ns_servers
    ns_servers=$(dig NS "$domain" +short)
    
    local results="[]"
    
    for ns in $ns_servers; do
        local transfer
        transfer=$(dig AXFR "$domain" @"$ns" +short 2>/dev/null)
        
        if [[ -n "$transfer" ]]; then
            results=$(echo "$results" | jq --arg ns "$ns" --arg transfer "$transfer" \
                '. += [{"nameserver": $ns, "success": true, "records": $transfer}]')
        fi
    done
    
    if [[ $(echo "$results" | jq 'length') -eq 0 ]]; then
        results="{\"message\": \"Zone transfer failed or not permitted\"}"
    fi
    
    echo "$results"
}

# Reverse DNS lookup
reverse_dns_lookup() {
    local target="$1"
    
    # Se for IP, fazer reverse DNS
    if validate_ip "$target"; then
        local ptr
        ptr=$(dig +short -x "$target" 2>/dev/null)
        
        if [[ -n "$ptr" ]]; then
            echo "{\"ip\": \"$target\", \"ptr\": \"$ptr\"}"
        else
            echo "{\"ip\": \"$target\", \"ptr\": null}"
        fi
    else
        # Se for domínio, resolver IPs e fazer reverse
        local ips
        ips=$(dig +short "$target" A 2>/dev/null)
        
        local results="[]"
        while IFS= read -r ip; do
            if [[ -n "$ip" ]]; then
                local ptr
                ptr=$(dig +short -x "$ip" 2>/dev/null)
                results=$(echo "$results" | jq --arg ip "$ip" --arg ptr "$ptr" \
                    '. += [{"ip": $ip, "ptr": $ptr}]')
            fi
        done <<< "$ips"
        
        echo "$results"
    fi
}

# Obter WHOIS info
get_whois_info() {
    local target="$1"
    
    local whois_data
    whois_data=$(whois "$target" 2>/dev/null)
    
    if [[ -z "$whois_data" ]]; then
        echo "{}"
        return
    fi
    
    # Extrair informações relevantes
    local info="{}"
    
    # Registrar
    local registrar
    registrar=$(echo "$whois_data" | grep -i "^registrar:" | head -1 | cut -d':' -f2- | sed 's/^[ \t]*//')
    if [[ -n "$registrar" ]]; then
        info=$(echo "$info" | jq --arg registrar "$registrar" '.registrar = $registrar')
    fi
    
    # Data de criação
    local creation
    creation=$(echo "$whois_data" | grep -i "creation date:" | head -1 | cut -d':' -f2- | sed 's/^[ \t]*//')
    if [[ -n "$creation" ]]; then
        info=$(echo "$info" | jq --arg creation "$creation" '.creation_date = $creation')
    fi
    
    # Data de expiração
    local expiry
    expiry=$(echo "$whois_data" | grep -i "expir" | head -1 | cut -d':' -f2- | sed 's/^[ \t]*//')
    if [[ -n "$expiry" ]]; then
        info=$(echo "$info" | jq --arg expiry "$expiry" '.expiry_date = $expiry')
    fi
    
    # Name servers
    local nameservers
    nameservers=$(echo "$whois_data" | grep -i "name server" | head -5 | cut -d':' -f2- | sed 's/^[ \t]*//' | jq -R -s -c 'split("\n")[:-1]')
    if [[ "$nameservers" != "[]" ]]; then
        info=$(echo "$info" | jq --argjson ns "$nameservers" '.name_servers = $ns')
    fi
    
    # Informações de contato
    local tech_email
    tech_email=$(echo "$whois_data" | grep -i "tech email" | head -1 | cut -d':' -f2- | sed 's/^[ \t]*//')
    if [[ -n "$tech_email" ]]; then
        info=$(echo "$info" | jq --arg email "$tech_email" '.tech_email = $email')
    fi
    
    echo "$info"
}

# Verificar potencial de amplificação DNS
check_dns_amplification() {
    local domain="$1"
    
    local results="{}"
    
    # Tamanho da resposta vs requisição
    local query_size=44  # Tamanho típico de query ANY
    
    # Tentar query ANY
    local response
    response=$(dig +short ANY "$domain" 2>/dev/null)
    local response_size=${#response}
    
    if [[ $response_size -gt 0 ]]; then
        local amplification_factor=$((response_size / query_size))
        
        results=$(echo "$results" | jq \
            --argjson query_size "$query_size" \
            --argjson response_size "$response_size" \
            --argjson factor "$amplification_factor" \
            '{
                query_size: $query_size,
                response_size: $response_size,
                amplification_factor: $factor,
                vulnerable: ($factor > 10)
            }')
    fi
    
    echo "$results"
}

# Verificar suporte a DNS over HTTPS
check_doh_support() {
    local domain="$1"
    
    local doh_providers=(
        "https://cloudflare-dns.com/dns-query"
        "https://dns.google/dns-query"
        "https://doh.opendns.com/dns-query"
        "https://dns.quad9.net/dns-query"
    )
    
    local results="[]"
    
    for provider in "${doh_providers[@]}"; do
        local response
        response=$(curl -s -H "accept: application/dns-json" \
            "${provider}?name=${domain}&type=A" 2>/dev/null)
        
        if [[ -n "$response" ]] && [[ "$(echo "$response" | jq -r '.Status')" == "0" ]]; then
            results=$(echo "$results" | jq --arg provider "$provider" \
                '. += [{"provider": $provider, "supported": true}]')
        fi
    done
    
    echo "$results"
}

# Exportar funções
export -f init_dns_intel dns_intelligence