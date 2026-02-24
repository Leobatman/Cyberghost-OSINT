#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Historical Data Module
# =============================================================================

MODULE_NAME="Historical Data"
MODULE_DESC="Gather historical data from various sources"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# Fontes de dados históricos
declare -A HISTORICAL_SOURCES=(
    ["wayback"]="https://archive.org/wayback/available"
    ["commoncrawl"]="https://index.commoncrawl.org/"
    ["securitytrails"]="https://api.securitytrails.com/v1/history"
    ["dnslytics"]="https://dnslytics.com/api"
    ["whois_history"]="https://whois-history.whoisxmlapi.com/api/v1"
    ["certspotter"]="https://certspotter.com/api/v0/certs"
    ["crtsh"]="https://crt.sh"
    ["otx"]="https://otx.alienvault.com/api/v1"
)

# Inicializar módulo
init_historical_data() {
    log "INFO" "Initializing Historical Data module" "HISTORICAL"
    
    # Verificar dependências
    local deps=("curl" "jq" "dig" "date")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "HISTORICAL"
        return 1
    fi
    
    return 0
}

# Função principal
gather_historical_data() {
    local target="$1"
    local output_dir="$2"
    
    log "WEB" "Starting historical data gathering for: $target" "HISTORICAL"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/historical"
    mkdir -p "$results_dir"
    
    local results="{}"
    
    # Determinar tipo de alvo
    local target_type
    if validate_domain "$target"; then
        target_type="domain"
    elif validate_ip "$target"; then
        target_type="ip"
    else
        target_type="unknown"
    fi
    
    results=$(echo "$results" | jq \
        --arg target "$target" \
        --arg type "$target_type" \
        '{
            target: $target,
            target_type: $type
        }')
    
    # 1. Wayback Machine
    log "INFO" "Checking Wayback Machine" "HISTORICAL"
    local wayback_data
    wayback_data=$(get_wayback_data "$target")
    results=$(echo "$results" | jq --argjson wb "$wayback_data" '.wayback_machine = $wb')
    
    # 2. Common Crawl
    log "INFO" "Checking Common Crawl" "HISTORICAL"
    local commoncrawl_data
    commoncrawl_data=$(get_commoncrawl_data "$target")
    results=$(echo "$results" | jq --argjson cc "$commoncrawl_data" '.common_crawl = $cc')
    
    # 3. Historical DNS
    log "INFO" "Checking historical DNS" "HISTORICAL"
    local dns_history
    dns_history=$(get_dns_history "$target")
    results=$(echo "$results" | jq --argjson dns "$dns_history" '.dns_history = $dns')
    
    # 4. Historical WHOIS
    log "INFO" "Checking historical WHOIS" "HISTORICAL"
    local whois_history
    whois_history=$(get_whois_history "$target")
    results=$(echo "$results" | jq --argjson whois "$whois_history" '.whois_history = $whois')
    
    # 5. Historical SSL certificates
    log "INFO" "Checking historical SSL certificates" "HISTORICAL"
    local ssl_history
    ssl_history=$(get_ssl_history "$target")
    results=$(echo "$results" | jq --argjson ssl "$ssl_history" '.ssl_history = $ssl')
    
    # 6. Historical subdomains
    log "INFO" "Checking historical subdomains" "HISTORICAL"
    local subdomain_history
    subdomain_history=$(get_subdomain_history "$target")
    results=$(echo "$results" | jq --argjson subs "$subdomain_history" '.subdomain_history = $subs')
    
    # 7. Historical IPs
    log "INFO" "Checking historical IP addresses" "HISTORICAL"
    local ip_history
    ip_history=$(get_ip_history "$target")
    results=$(echo "$results" | jq --argjson ips "$ip_history" '.ip_history = $ips')
    
    # 8. Historical technologies
    log "INFO" "Checking historical technologies" "HISTORICAL"
    local tech_history
    tech_history=$(get_tech_history "$target")
    results=$(echo "$results" | jq --argjson tech "$tech_history" '.tech_history = $tech')
    
    # 9. Historical content changes
    log "INFO" "Analyzing content changes" "HISTORICAL"
    local content_changes
    content_changes=$(analyze_content_changes "$target" "$wayback_data")
    results=$(echo "$results" | jq --argjson changes "$content_changes" '.content_changes = $changes')
    
    # 10. Historical screenshots (se disponível)
    log "INFO" "Checking historical screenshots" "HISTORICAL"
    local screenshots
    screenshots=$(get_historical_screenshots "$target")
    results=$(echo "$results" | jq --argjson shots "$screenshots" '.historical_screenshots = $shots')
    
    # 11. Timeline
    log "INFO" "Generating timeline" "HISTORICAL"
    local timeline
    timeline=$(generate_historical_timeline "$results")
    results=$(echo "$results" | jq --argjson timeline "$timeline" '.timeline = $timeline')
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/historical.json"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "SUCCESS" "Historical data gathering completed in ${duration}s" "HISTORICAL"
    
    echo "$results"
}

# Obter dados do Wayback Machine
get_wayback_data() {
    local target="$1"
    local data="{}"
    
    # Verificar snapshots disponíveis
    local url="http://archive.org/wayback/available?url=${target}"
    local response
    response=$(curl -s "$url" 2>/dev/null)
    
    if [[ -n "$response" ]]; then
        local closest
        closest=$(echo "$response" | jq -r '.archived_snapshots.closest // empty')
        
        if [[ -n "$closest" ]] && [[ "$closest" != "null" ]]; then
            local timestamp
            timestamp=$(echo "$response" | jq -r '.archived_snapshots.closest.timestamp')
            local archive_url
            archive_url=$(echo "$response" | jq -r '.archived_snapshots.closest.url')
            
            data=$(echo "$data" | jq \
                --arg ts "$timestamp" \
                --arg url "$archive_url" \
                '{
                    available: true,
                    closest: {
                        timestamp: $ts,
                        url: $url
                    }
                }')
        else
            data=$(echo "$data" | jq '.available = false')
        fi
    fi
    
    # Obter lista de snapshots
    local cdx_url="http://web.archive.org/cdx/search/cdx?url=${target}&output=json&fl=timestamp,original,mimetype,statuscode,digest"
    local cdx_response
    cdx_response=$(curl -s "$cdx_url" 2>/dev/null)
    
    if [[ -n "$cdx_response" ]] && [[ "$cdx_response" != "[]" ]]; then
        local snapshots
        snapshots=$(echo "$cdx_response" | jq -c '[.[1:][] | {
            timestamp: .[0],
            url: .[1],
            mime_type: .[2],
            status_code: .[3],
            digest: .[4]
        }]' 2>/dev/null)
        
        data=$(echo "$data" | jq --argjson snaps "$snapshots" '.snapshots = $snaps')
    fi
    
    echo "$data"
}

# Obter dados do Common Crawl
get_commoncrawl_data() {
    local target="$1"
    local data="[]"
    
    # Lista de índices disponíveis
    local indexes=("CC-MAIN-2023-50" "CC-MAIN-2023-40" "CC-MAIN-2023-23" "CC-MAIN-2023-14")
    
    for index in "${indexes[@]}"; do
        local url="https://index.commoncrawl.org/${index}-index?url=${target}&output=json"
        local response
        response=$(curl -s "$url" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            local entries
            entries=$(echo "$response" | jq -c --arg index "$index" '[inputs] | .[] | {
                index: $index,
                url: .url,
                timestamp: .timestamp,
                status: .status,
                mime: .mime,
                digest: .digest,
                filename: .filename
            }' 2>/dev/null)
            
            data=$(echo "$data" | jq --argjson entries "$entries" '. += $entries')
        fi
    done
    
    echo "$data"
}

# Obter histórico de DNS
get_dns_history() {
    local target="$1"
    local data="[]"
    
    # SecurityTrails API
    if [[ -n "$SECURITYTRAILS_API_KEY" ]]; then
        local url="https://api.securitytrails.com/v1/history/${target}/dns/a"
        local response
        response=$(curl -s -H "APIKEY: ${SECURITYTRAILS_API_KEY}" "$url" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            local records
            records=$(echo "$response" | jq -c '.records // []' 2>/dev/null)
            data=$(echo "$data" | jq --argjson rec "$records" '. += $rec')
        fi
    fi
    
    # DNS Dumpster (via scraping)
    local csrf
    csrf=$(curl -s -c cookies.txt "https://dnsdumpster.com/" | grep -o 'name="_csrf" value="[^"]*"' | cut -d'"' -f4)
    
    if [[ -n "$csrf" ]]; then
        local response
        response=$(curl -s -X POST -b cookies.txt \
            -F "targetip=${target}" \
            -F "_csrf=${csrf}" \
            "https://dnsdumpster.com/" 2>/dev/null)
        
        # Extrair tabelas de histórico
        local history_tables
        history_tables=$(echo "$response" | grep -o '<table class="table[^>]*>.*?</table>' | grep -i "history")
        
        if [[ -n "$history_tables" ]]; then
            data=$(echo "$data" | jq --arg tables "$history_tables" '.dnsdumpster = $tables')
        fi
        
        rm -f cookies.txt
    fi
    
    echo "$data"
}

# Obter histórico de WHOIS
get_whois_history() {
    local target="$1"
    local data="[]"
    
    # whois-history.whoisxmlapi.com
    if [[ -n "$WHOISXMLAPI_KEY" ]]; then
        local url="https://whois-history.whoisxmlapi.com/api/v1?apiKey=${WHOISXMLAPI_KEY}&domainName=${target}"
        local response
        response=$(curl -s "$url" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            local records
            records=$(echo "$response" | jq -c '.recordsList // []' 2>/dev/null)
            data=$(echo "$data" | jq --argjson rec "$records" '. += $rec')
        fi
    fi
    
    # WhoisXMLAPI alternativo
    if [[ -n "$WHOISXMLAPI_KEY" ]]; then
        local url="https://www.whoisxmlapi.com/whoisserver/WhoisService?apiKey=${WHOISXMLAPI_KEY}&domainName=${target}&outputFormat=JSON"
        local response
        response=$(curl -s "$url" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            local registrar
            registrar=$(echo "$response" | jq -r '.WhoisRecord.registrarName // empty')
            local created
            created=$(echo "$response" | jq -r '.WhoisRecord.createdDate // empty')
            local updated
            updated=$(echo "$response" | jq -r '.WhoisRecord.updatedDate // empty')
            local expires
            expires=$(echo "$response" | jq -r '.WhoisRecord.expiresDate // empty')
            
            if [[ -n "$registrar" ]] || [[ -n "$created" ]]; then
                data=$(echo "$data" | jq --argjson record "{
                    registrar: \"$registrar\",
                    created: \"$created\",
                    updated: \"$updated\",
                    expires: \"$expires\"
                }" '. += [$record]')
            fi
        fi
    fi
    
    echo "$data"
}

# Obter histórico de SSL
get_ssl_history() {
    local target="$1"
    local data="[]"
    
    # crt.sh
    local url="https://crt.sh/?q=%.${target}&output=json"
    local response
    response=$(curl -s "$url" 2>/dev/null)
    
    if [[ -n "$response" ]]; then
        local certs
        certs=$(echo "$response" | jq -c '[.[] | {
            id: .id,
            issuer: .issuer_name,
            name: .name_value,
            not_before: .not_before,
            not_after: .not_after,
            logged_at: .entry_timestamp
        }]' 2>/dev/null)
        
        data=$(echo "$data" | jq --argjson certs "$certs" '. += $certs')
    fi
    
    # CertSpotter
    local url="https://certspotter.com/api/v0/certs?domain=${target}"
    local response
    response=$(curl -s "$url" 2>/dev/null)
    
    if [[ -n "$response" ]]; then
        local certs
        certs=$(echo "$response" | jq -c '[.[] | {
            id: .id,
            issuer: .issuer,
            dns_names: .dns_names,
            not_before: .not_before,
            not_after: .not_after,
            seen: .seen
        }]' 2>/dev/null)
        
        data=$(echo "$data" | jq --argjson certs "$certs" '. += $certs')
    fi
    
    echo "$data"
}

# Obter histórico de subdomínios
get_subdomain_history() {
    local target="$1"
    local data="[]"
    
    # DNSlytics
    if [[ -n "$DNSLYTICS_API_KEY" ]]; then
        local url="https://dnslytics.com/api/v1/subdomains/${target}"
        local response
        response=$(curl -s -H "Authorization: Bearer ${DNSLYTICS_API_KEY}" "$url" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            local subs
            subs=$(echo "$response" | jq -c '.subdomains // []' 2>/dev/null)
            data=$(echo "$data" | jq --argjson subs "$subs" '. += $subs')
        fi
    fi
    
    # AlienVault OTX
    local url="https://otx.alienvault.com/api/v1/indicators/domain/${target}/passive_dns"
    local response
    response=$(curl -s "$url" 2>/dev/null)
    
    if [[ -n "$response" ]]; then
        local subs
        subs=$(echo "$response" | jq -c '.passive_dns[]? | {
            hostname: .hostname,
            address: .address,
            first: .first,
            last: .last,
            record_type: .record_type
        }' 2>/dev/null | jq -s '.')
        
        data=$(echo "$data" | jq --argjson subs "$subs" '. += $subs')
    fi
    
    echo "$data"
}

# Obter histórico de IPs
get_ip_history() {
    local target="$1"
    local data="[]"
    
    # Se for domínio, obter histórico de IPs
    if validate_domain "$target"; then
        # SecurityTrails
        if [[ -n "$SECURITYTRAILS_API_KEY" ]]; then
            local url="https://api.securitytrails.com/v1/history/${target}/dns/a"
            local response
            response=$(curl -s -H "APIKEY: ${SECURITYTRAILS_API_KEY}" "$url" 2>/dev/null)
            
            if [[ -n "$response" ]]; then
                local ips
                ips=$(echo "$response" | jq -c '.records[]? | {
                    ip: .values[]?,
                    first_seen: .first_seen,
                    last_seen: .last_seen,
                    organization: .organizations[]?
                }' 2>/dev/null | jq -s '.')
                
                data=$(echo "$data" | jq --argjson ips "$ips" '. += $ips')
            fi
        fi
    fi
    
    echo "$data"
}

# Obter histórico de tecnologias
get_tech_history() {
    local target="$1"
    local data="[]"
    
    # BuiltWith (se tiver API)
    if [[ -n "$BUILTWITH_API_KEY" ]]; then
        local url="https://api.builtwith.com/v21/api.json?KEY=${BUILTWITH_API_KEY}&LOOKUP=${target}&HISTORY=yes"
        local response
        response=$(curl -s "$url" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            local techs
            techs=$(echo "$response" | jq -c '.results[0].Result.Paths[0].Technologies[]? | {
                name: .Name,
                category: .Category,
                first_detected: .FirstDetected,
                last_detected: .LastDetected,
                is_current: .IsPremium
            }' 2>/dev/null | jq -s '.')
            
            data=$(echo "$data" | jq --argjson techs "$techs" '. += $techs')
        fi
    fi
    
    echo "$data"
}

# Analisar mudanças de conteúdo
analyze_content_changes() {
    local target="$1"
    local wayback_data="$2"
    local changes="[]"
    
    # Verificar se temos snapshots
    local snapshots
    snapshots=$(echo "$wayback_data" | jq -c '.snapshots[]? | {timestamp: .timestamp, url: .url}' 2>/dev/null)
    
    if [[ -n "$snapshots" ]]; then
        local previous_content=""
        local previous_timestamp=""
        
        echo "$snapshots" | jq -c 'sort_by(.timestamp)' | while read -r snapshot; do
            local timestamp
            timestamp=$(echo "$snapshot" | jq -r '.timestamp')
            local url
            url=$(echo "$snapshot" | jq -r '.url')
            
            # Baixar conteúdo
            local content
            content=$(curl -s -L --max-time 10 "$url" 2>/dev/null)
            
            if [[ -n "$content" ]] && [[ -n "$previous_content" ]]; then
                # Comparar com versão anterior
                local diff_size=$(( ${#content} - ${#previous_content} ))
                local similarity
                
                # Calcular similaridade (simplificada)
                local common_lines
                common_lines=$(comm -12 <(echo "$content" | sort) <(echo "$previous_content" | sort) | wc -l)
                local total_lines=$(( $(echo "$content" | wc -l) + $(echo "$previous_content" | wc -l) ))
                
                if [[ $total_lines -gt 0 ]]; then
                    similarity=$((common_lines * 200 / total_lines))
                else
                    similarity=0
                fi
                
                changes=$(echo "$changes" | jq \
                    --arg from "$previous_timestamp" \
                    --arg to "$timestamp" \
                    --argjson diff "$diff_size" \
                    --argjson sim "$similarity" \
                    '. += [{
                        from: $from,
                        to: $to,
                        size_difference: $diff,
                        similarity: $sim
                    }]')
            fi
            
            previous_content="$content"
            previous_timestamp="$timestamp"
        done
    fi
    
    echo "$changes"
}

# Obter screenshots históricos
get_historical_screenshots() {
    local target="$1"
    local data="[]"
    
    # Archive.org screenshots
    local url="http://archive.org/wayback/available?url=${target}"
    local response
    response=$(curl -s "$url" 2>/dev/null)
    
    if [[ -n "$response" ]]; then
        local snapshots
        snapshots=$(echo "$response" | jq -c '.archived_snapshots // {}')
        
        if [[ "$snapshots" != "{}" ]]; then
            local timestamp
            timestamp=$(echo "$snapshots" | jq -r '.closest.timestamp')
            local screenshot_url="http://web.archive.org/web/${timestamp}im_/${target}"
            
            data=$(echo "$data" | jq --arg url "$screenshot_url" --arg ts "$timestamp" \
                '. += [{
                    timestamp: $ts,
                    url: $url
                }]')
        fi
    fi
    
    # Screenshot.com (se tiver API)
    if [[ -n "$SCREENSHOT_API_KEY" ]]; then
        local url="https://api.screenshot.com/v1/history/${target}"
        local response
        response=$(curl -s -H "Authorization: Bearer ${SCREENSHOT_API_KEY}" "$url" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            local shots
            shots=$(echo "$response" | jq -c '.screenshots[]? | {
                timestamp: .timestamp,
                url: .url,
                thumbnail: .thumbnail
            }' 2>/dev/null | jq -s '.')
            
            data=$(echo "$data" | jq --argjson shots "$shots" '. += $shots')
        fi
    fi
    
    echo "$data"
}

# Gerar timeline histórica
generate_historical_timeline() {
    local results="$1"
    local timeline="[]"
    
    # Coletar todos os eventos com data
    local events="[]"
    
    # DNS history
    local dns_events
    dns_events=$(echo "$results" | jq -c '.dns_history[]? | {
        date: (.first_seen // .last_seen),
        type: "dns_change",
        details: "IP: \(.ip)"
    }' 2>/dev/null)
    events=$(echo "$events" | jq --argjson ev "$dns_events" '. + $ev')
    
    # SSL history
    local ssl_events
    ssl_events=$(echo "$results" | jq -c '.ssl_history[]? | {
        date: (.not_before // .logged_at),
        type: "ssl_certificate",
        details: "Issuer: \(.issuer)"
    }' 2>/dev/null)
    events=$(echo "$events" | jq --argjson ev "$ssl_events" '. + $ev')
    
    # WHOIS history
    local whois_events
    whois_events=$(echo "$results" | jq -c '.whois_history[]? | {
        date: .created,
        type: "domain_registration",
        details: "Registrar: \(.registrar)"
    }' 2>/dev/null)
    events=$(echo "$events" | jq --argjson ev "$whois_events" '. + $ev')
    
    # Content changes
    local content_events
    content_events=$(echo "$results" | jq -c '.content_changes[]? | {
        date: .to,
        type: "content_change",
        details: "Similarity: \(.similarity)%"
    }' 2>/dev/null)
    events=$(echo "$events" | jq --argjson ev "$content_events" '. + $ev')
    
    # Ordenar por data
    timeline=$(echo "$events" | jq 'sort_by(.date)')
    
    echo "$timeline"
}

# Exportar funções
export -f init_historical_data gather_historical_data