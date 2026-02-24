#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Threat Intelligence Module
# =============================================================================

MODULE_NAME="Threat Intelligence"
MODULE_DESC="Gather threat intelligence from multiple sources"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# Threat intelligence sources
declare -A THREAT_SOURCES=(
    ["virustotal"]="VirusTotal"
    ["abuseipdb"]="AbuseIPDB"
    ["greynoise"]="GreyNoise"
    ["alienvault"]="AlienVault OTX"
    ["ibm_xforce"]="IBM X-Force"
    ["threatcrowd"]="ThreatCrowd"
    ["threatminer"]="ThreatMiner"
    ["shodan"]="Shodan"
    ["censys"]="Censys"
    ["securitytrails"]="SecurityTrails"
)

# IOCs tipos
IOC_TYPES=("ip" "domain" "url" "hash" "email")

# Inicializar módulo
init_threat_intel() {
    log "INFO" "Initializing Threat Intelligence module" "THREAT"
    
    # Verificar dependências
    local deps=("curl" "jq" "dig")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "THREAT"
        return 1
    fi
    
    return 0
}

# Função principal
gather_threat_intel() {
    local target="$1"
    local output_dir="$2"
    
    log "INTEL" "Starting threat intelligence gathering for: $target" "THREAT"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/threat_intel"
    mkdir -p "$results_dir"
    
    local results="{}"
    
    # Determinar tipo de IOC
    local ioc_type
    ioc_type=$(determine_ioc_type "$target")
    results=$(echo "$results" | jq --arg type "$ioc_type" '.ioc_type = $type')
    
    # 1. VirusTotal
    log "INFO" "Checking VirusTotal" "THREAT"
    local vt_results
    vt_results=$(check_virustotal "$target" "$ioc_type")
    results=$(echo "$results" | jq --argjson vt "$vt_results" '.virustotal = $vt')
    
    # 2. AbuseIPDB
    if [[ "$ioc_type" == "ip" ]]; then
        log "INFO" "Checking AbuseIPDB" "THREAT"
        local abuse_results
        abuse_results=$(check_abuseipdb "$target")
        results=$(echo "$results" | jq --argjson abuse "$abuse_results" '.abuseipdb = $abuse')
    fi
    
    # 3. GreyNoise
    log "INFO" "Checking GreyNoise" "THREAT"
    local gn_results
    gn_results=$(check_greynoise "$target" "$ioc_type")
    results=$(echo "$results" | jq --argjson gn "$gn_results" '.greynoise = $gn')
    
    # 4. AlienVault OTX
    log "INFO" "Checking AlienVault OTX" "THREAT"
    local otx_results
    otx_results=$(check_alienvault "$target")
    results=$(echo "$results" | jq --argjson otx "$otx_results" '.alienvault = $otx')
    
    # 5. ThreatCrowd
    log "INFO" "Checking ThreatCrowd" "THREAT"
    local tc_results
    tc_results=$(check_threatcrowd "$target" "$ioc_type")
    results=$(echo "$results" | jq --argjson tc "$tc_results" '.threatcrowd = $tc')
    
    # 6. ThreatMiner
    log "INFO" "Checking ThreatMiner" "THREAT"
    local tm_results
    tm_results=$(check_threatminer "$target" "$ioc_type")
    results=$(echo "$results" | jq --argjson tm "$tm_results" '.threatminer = $tm')
    
    # 7. IBM X-Force
    log "INFO" "Checking IBM X-Force" "THREAT"
    local xforce_results
    xforce_results=$(check_ibm_xforce "$target" "$ioc_type")
    results=$(echo "$results" | jq --argjson xforce "$xforce_results" '.ibm_xforce = $xforce')
    
    # 8. URLhaus (se for URL)
    if [[ "$ioc_type" == "url" ]]; then
        log "INFO" "Checking URLhaus" "THREAT"
        local urlhaus_results
        urlhaus_results=$(check_urlhaus "$target")
        results=$(echo "$results" | jq --argjson urlhaus "$urlhaus_results" '.urlhaus = $urlhaus')
    fi
    
    # 9. PhishTank (se for URL)
    if [[ "$ioc_type" == "url" ]]; then
        log "INFO" "Checking PhishTank" "THREAT"
        local pt_results
        pt_results=$(check_phishtank "$target")
        results=$(echo "$results" | jq --argjson pt "$pt_results" '.phishtank = $pt')
    fi
    
    # 10. Shodan (se for IP)
    if [[ "$ioc_type" == "ip" ]] && [[ -n "$SHODAN_API_KEY" ]]; then
        log "INFO" "Checking Shodan" "THREAT"
        local shodan_results
        shodan_results=$(check_shodan "$target")
        results=$(echo "$results" | jq --argjson shodan "$shodan_results" '.shodan = $shodan')
    fi
    
    # Calcular score de reputação
    log "INFO" "Calculating reputation score" "THREAT"
    local reputation
    reputation=$(calculate_reputation_score "$results")
    results=$(echo "$results" | jq --argjson rep "$reputation" '.reputation = $rep')
    
    # Verificar se é malicioso
    local malicious_votes
    malicious_votes=$(echo "$results" | jq '[.virustotal.malicious, .abuseipdb.abuseConfidenceScore, .greynoise.classification] | map(select(. != null and . != "")) | length')
    
    if [[ $malicious_votes -gt 2 ]]; then
        results=$(echo "$results" | jq '.malicious = true')
        
        # Criar alerta
        create_alert "threat" "high" "Malicious IOC detected: $target" "$results"
    else
        results=$(echo "$results" | jq '.malicious = false')
    fi
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/threat_intel.json"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local malicious
    malicious=$(echo "$results" | jq -r '.malicious')
    
    log "SUCCESS" "Threat intelligence completed in ${duration}s - Malicious: $malicious" "THREAT"
    
    echo "$results"
}

# Determinar tipo de IOC
determine_ioc_type() {
    local target="$1"
    
    # IP
    if validate_ip "$target"; then
        echo "ip"
    # Domain
    elif validate_domain "$target"; then
        echo "domain"
    # URL
    elif validate_url "$target"; then
        echo "url"
    # Hash (MD5, SHA1, SHA256)
    elif [[ "$target" =~ ^[a-fA-F0-9]{32}$ ]] || [[ "$target" =~ ^[a-fA-F0-9]{40}$ ]] || [[ "$target" =~ ^[a-fA-F0-9]{64}$ ]]; then
        echo "hash"
    # Email
    elif validate_email "$target"; then
        echo "email"
    else
        echo "unknown"
    fi
}

# Verificar VirusTotal
check_virustotal() {
    local target="$1"
    local ioc_type="$2"
    
    if [[ -z "$VIRUSTOTAL_API_KEY" ]]; then
        echo "{\"error\": \"No API key\"}"
        return
    fi
    
    local endpoint
    case "$ioc_type" in
        "ip") endpoint="ip_address" ;;
        "domain") endpoint="domains" ;;
        "url") endpoint="urls" ;;
        "hash") endpoint="files" ;;
        *) echo "{}"; return ;;
    esac
    
    local url="https://www.virustotal.com/api/v3/${endpoint}/${target}"
    local response
    response=$(curl -s -H "x-apikey: ${VIRUSTOTAL_API_KEY}" "$url" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo "{}"
        return
    fi
    
    # Extrair informações relevantes
    local result="{}"
    
    # Estatísticas
    local malicious
    malicious=$(echo "$response" | jq -r '.data.attributes.last_analysis_stats.malicious // 0')
    local suspicious
    suspicious=$(echo "$response" | jq -r '.data.attributes.last_analysis_stats.suspicious // 0')
    local harmless
    harmless=$(echo "$response" | jq -r '.data.attributes.last_analysis_stats.harmless // 0')
    local undetected
    undetected=$(echo "$response" | jq -r '.data.attributes.last_analysis_stats.undetected // 0')
    
    result=$(echo "$result" | jq \
        --argjson malicious "$malicious" \
        --argjson suspicious "$suspicious" \
        --argjson harmless "$harmless" \
        --argjson undetected "$undetected" \
        '{
            malicious: $malicious,
            suspicious: $suspicious,
            harmless: $harmless,
            undetected: $undetected,
            total: ($malicious + $suspicious + $harmless + $undetected)
        }')
    
    # Reputação
    local reputation
    reputation=$(echo "$response" | jq -r '.data.attributes.reputation // 0')
    result=$(echo "$result" | jq --argjson rep "$reputation" '.reputation = $rep')
    
    # Detecções
    local detections
    detections=$(echo "$response" | jq -c '.data.attributes.last_analysis_results | to_entries | map({engine: .key, result: .value.result, category: .value.category}) | .[] | select(.result != "undetected" and .result != "harmless")' 2>/dev/null | jq -s '.')
    
    if [[ "$detections" != "[]" ]] && [[ -n "$detections" ]]; then
        result=$(echo "$result" | jq --argjson detections "$detections" '.detections = $detections')
    fi
    
    # Times (para domain/ip)
    local last_analysis_date
    last_analysis_date=$(echo "$response" | jq -r '.data.attributes.last_analysis_date // empty')
    if [[ -n "$last_analysis_date" ]]; then
        result=$(echo "$result" | jq --arg date "$last_analysis_date" '.last_analysis = $date')
    fi
    
    echo "$result"
}

# Verificar AbuseIPDB
check_abuseipdb() {
    local ip="$1"
    
    if [[ -z "$ABUSEIPDB_API_KEY" ]]; then
        echo "{\"error\": \"No API key\"}"
        return
    fi
    
    local url="https://api.abuseipdb.com/api/v2/check"
    local response
    response=$(curl -s -G --data-urlencode "ipAddress=$ip" \
        -H "Key: ${ABUSEIPDB_API_KEY}" \
        -H "Accept: application/json" \
        "$url" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo "{}"
        return
    fi
    
    local result="{}"
    
    local abuse_score
    abuse_score=$(echo "$response" | jq -r '.data.abuseConfidenceScore // 0')
    local country
    country=$(echo "$response" | jq -r '.data.countryCode // empty')
    local total_reports
    total_reports=$(echo "$response" | jq -r '.data.totalReports // 0')
    local last_reported
    last_reported=$(echo "$response" | jq -r '.data.lastReportedAt // empty')
    
    result=$(echo "$result" | jq \
        --argjson score "$abuse_score" \
        --arg country "$country" \
        --argjson reports "$total_reports" \
        --arg last "$last_reported" \
        '{
            abuseConfidenceScore: $score,
            country: $country,
            totalReports: $reports,
            lastReported: $last
        }')
    
    # Categorias de abuso
    local categories
    categories=$(echo "$response" | jq -c '.data.reports | map(.categories[]) | unique' 2>/dev/null)
    if [[ "$categories" != "[]" ]] && [[ -n "$categories" ]]; then
        result=$(echo "$result" | jq --argjson cats "$categories" '.categories = $cats')
    fi
    
    echo "$result"
}

# Verificar GreyNoise
check_greynoise() {
    local target="$1"
    local ioc_type="$2"
    
    if [[ "$ioc_type" != "ip" ]]; then
        echo "{}"
        return
    fi
    
    if [[ -z "$GREYNOISE_API_KEY" ]]; then
        echo "{\"error\": \"No API key\"}"
        return
    fi
    
    local url="https://api.greynoise.io/v3/community/${target}"
    local response
    response=$(curl -s -H "key: ${GREYNOISE_API_KEY}" "$url" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo "{}"
        return
    fi
    
    local result="{}"
    
    local noise
    noise=$(echo "$response" | jq -r '.noise // false')
    local riot
    riot=$(echo "$response" | jq -r '.riot // false')
    local classification
    classification=$(echo "$response" | jq -r '.classification // "unknown"')
    local name
    name=$(echo "$response" | jq -r '.name // empty')
    local last_seen
    last_seen=$(echo "$response" | jq -r '.last_seen // empty')
    
    result=$(echo "$result" | jq \
        --argjson noise "$noise" \
        --argjson riot "$riot" \
        --arg class "$classification" \
        --arg name "$name" \
        --arg last "$last_seen" \
        '{
            noise: $noise,
            riot: $riot,
            classification: $class,
            name: $name,
            last_seen: $last
        }')
    
    echo "$result"
}

# Verificar AlienVault OTX
check_alienvault() {
    local target="$1"
    
    local url="https://otx.alienvault.com/api/v1/indicators/domain/${target}/general"
    local response
    response=$(curl -s "$url" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo "{}"
        return
    fi
    
    local result="{}"
    
    local pulse_count
    pulse_count=$(echo "$response" | jq -r '.pulse_info.count // 0')
    local pulses
    pulses=$(echo "$response" | jq -c '.pulse_info.pulses | map({name: .name, description: .description, tags: .tags})' 2>/dev/null)
    
    result=$(echo "$result" | jq \
        --argjson count "$pulse_count" \
        --argjson pulses "$pulses" \
        '{
            pulse_count: $count,
            pulses: $pulses
        }')
    
    # Validação
    local validation
    validation=$(echo "$response" | jq -r '.validation // empty')
    if [[ -n "$validation" ]]; then
        result=$(echo "$result" | jq --arg val "$validation" '.validation = $val')
    fi
    
    echo "$result"
}

# Verificar ThreatCrowd
check_threatcrowd() {
    local target="$1"
    local ioc_type="$2"
    
    local endpoint
    case "$ioc_type" in
        "ip") endpoint="ip" ;;
        "domain") endpoint="domain" ;;
        *) echo "{}"; return ;;
    esac
    
    local url="https://www.threatcrowd.org/searchApi/v2/${endpoint}/report/?${endpoint}=${target}"
    local response
    response=$(curl -s "$url" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo "{}"
        return
    fi
    
    local result="{}"
    
    local resolution_count
    resolution_count=$(echo "$response" | jq -r '.resolutions | length // 0')
    local subdomains
    subdomains=$(echo "$response" | jq -c '.subdomains // []' 2>/dev/null)
    local hashes
    hashes=$(echo "$response" | jq -c '.hashes // []' 2>/dev/null)
    local references
    references=$(echo "$response" | jq -c '.references // []' 2>/dev/null)
    local votes
    votes=$(echo "$response" | jq -r '.votes // 0')
    
    result=$(echo "$result" | jq \
        --argjson resolutions "$resolution_count" \
        --argjson subdomains "$subdomains" \
        --argjson hashes "$hashes" \
        --argjson refs "$references" \
        --argjson votes "$votes" \
        '{
            resolution_count: $resolutions,
            subdomains: $subdomains,
            hashes: $hashes,
            references: $refs,
            votes: $votes
        }')
    
    echo "$result"
}

# Verificar ThreatMiner
check_threatminer() {
    local target="$1"
    local ioc_type="$2"
    
    local endpoint
    case "$ioc_type" in
        "ip") endpoint="host" ;;
        "domain") endpoint="domain" ;;
        *) echo "{}"; return ;;
    esac
    
    local url="https://api.threatminer.org/v2/${endpoint}.php?q=${target}&rt=2"
    local response
    response=$(curl -s "$url" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo "{}"
        return
    fi
    
    local result="{}"
    
    local status
    status=$(echo "$response" | jq -r '.status_code // empty')
    if [[ "$status" == "200" ]]; then
        local results
        results=$(echo "$response" | jq -c '.results // []' 2>/dev/null)
        result=$(echo "$result" | jq --argjson results "$results" '.results = $results')
    fi
    
    echo "$result"
}

# Verificar IBM X-Force
check_ibm_xforce() {
    local target="$1"
    local ioc_type="$2"
    
    if [[ -z "$IBM_XFORCE_API_KEY" ]] || [[ -z "$IBM_XFORCE_API_PASSWORD" ]]; then
        echo "{\"error\": \"No API credentials\"}"
        return
    fi
    
    local endpoint
    case "$ioc_type" in
        "ip") endpoint="ipr" ;;
        "domain") endpoint="url" ;;
        "hash") endpoint="malware" ;;
        *) echo "{}"; return ;;
    esac
    
    local url="https://api.xforce.ibmcloud.com/${endpoint}/${target}"
    local response
    response=$(curl -s -u "${IBM_XFORCE_API_KEY}:${IBM_XFORCE_API_PASSWORD}" "$url" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo "{}"
        return
    fi
    
    local result="{}"
    
    # Score
    local score
    score=$(echo "$response" | jq -r '.score // 0')
    result=$(echo "$result" | jq --argjson score "$score" '.score = $score')
    
    # Categorias
    local categories
    categories=$(echo "$response" | jq -c '.cats | keys' 2>/dev/null)
    if [[ "$categories" != "[]" ]] && [[ -n "$categories" ]]; then
        result=$(echo "$result" | jq --argjson cats "$categories" '.categories = $cats')
    fi
    
    # Malware family (para hashes)
    local family
    family=$(echo "$response" | jq -r '.family[0].name // empty')
    if [[ -n "$family" ]]; then
        result=$(echo "$result" | jq --arg family "$family" '.family = $family')
    fi
    
    echo "$result"
}

# Verificar URLhaus
check_urlhaus() {
    local url="$1"
    
    # URL encode
    local encoded_url
    encoded_url=$(url_encode "$url")
    
    local api_url="https://urlhaus-api.abuse.ch/v1/url/"
    local response
    response=$(curl -s -X POST -d "url=$url" "$api_url" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo "{}"
        return
    fi
    
    local result="{}"
    
    local query_status
    query_status=$(echo "$response" | jq -r '.query_status // "no_results"')
    
    if [[ "$query_status" == "ok" ]]; then
        local url_status
        url_status=$(echo "$response" | jq -r '.url_status // empty')
        local threat
        threat=$(echo "$response" | jq -r '.threat // empty')
        local tags
        tags=$(echo "$response" | jq -c '.tags // []' 2>/dev/null)
        local date_added
        date_added=$(echo "$response" | jq -r '.date_added // empty')
        
        result=$(echo "$result" | jq \
            --arg status "$url_status" \
            --arg threat "$threat" \
            --argjson tags "$tags" \
            --arg date "$date_added" \
            '{
                status: $status,
                threat: $threat,
                tags: $tags,
                date_added: $date
            }')
    fi
    
    echo "$result"
}

# Verificar PhishTank
check_phishtank() {
    local url="$1"
    
    local api_url="http://checkurl.phishtank.com/checkurl/"
    local response
    response=$(curl -s -X POST -d "url=$url&format=json" "$api_url" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo "{}"
        return
    fi
    
    local result="{}"
    
    local in_database
    in_database=$(echo "$response" | jq -r '.results.in_database // false')
    local valid
    valid=$(echo "$response" | jq -r '.results.valid // false')
    local verified_at
    verified_at=$(echo "$response" | jq -r '.results.verified_at // empty')
    
    result=$(echo "$result" | jq \
        --argjson in_db "$in_database" \
        --argjson valid "$valid" \
        --arg verified "$verified_at" \
        '{
            in_database: $in_db,
            valid: $valid,
            verified_at: $verified
        }')
    
    echo "$result"
}

# Verificar Shodan
check_shodan() {
    local ip="$1"
    
    local url="https://api.shodan.io/shodan/host/${ip}?key=${SHODAN_API_KEY}"
    local response
    response=$(curl -s "$url" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo "{}"
        return
    fi
    
    local result="{}"
    
    local ports
    ports=$(echo "$response" | jq -c '.ports // []' 2>/dev/null)
    local vulns
    vulns=$(echo "$response" | jq -c '.vulns // []' 2>/dev/null)
    local hostnames
    hostnames=$(echo "$response" | jq -c '.hostnames // []' 2>/dev/null)
    local country
    country=$(echo "$response" | jq -r '.country_name // empty')
    local city
    city=$(echo "$response" | jq -r '.city // empty')
    local org
    org=$(echo "$response" | jq -r '.org // empty')
    local os
    os=$(echo "$response" | jq -r '.os // empty')
    
    result=$(echo "$result" | jq \
        --argjson ports "$ports" \
        --argjson vulns "$vulns" \
        --argjson hosts "$hostnames" \
        --arg country "$country" \
        --arg city "$city" \
        --arg org "$org" \
        --arg os "$os" \
        '{
            open_ports: $ports,
            vulnerabilities: $vulns,
            hostnames: $hosts,
            location: {
                country: $country,
                city: $city
            },
            organization: $org,
            operating_system: $os
        }')
    
    # Informações de serviços
    local data
    data=$(echo "$response" | jq -c '.data | map({port: .port, service: ._shodan.module, banner: .data})' 2>/dev/null)
    if [[ "$data" != "[]" ]] && [[ -n "$data" ]]; then
        result=$(echo "$result" | jq --argjson data "$data" '.services = $data')
    fi
    
    echo "$result"
}

# Calcular score de reputação
calculate_reputation_score() {
    local results="$1"
    
    local score=0
    local max_score=100
    
    # VirusTotal
    local vt_malicious
    vt_malicious=$(echo "$results" | jq -r '.virustotal.malicious // 0')
    local vt_total
    vt_total=$(echo "$results" | jq -r '.virustotal.total // 1')
    
    if [[ $vt_total -gt 0 ]]; then
        local vt_score=$((vt_malicious * 100 / vt_total))
        score=$((score + vt_score))
    fi
    
    # AbuseIPDB
    local abuse_score
    abuse_score=$(echo "$results" | jq -r '.abuseipdb.abuseConfidenceScore // 0')
    score=$((score + abuse_score))
    
    # GreyNoise
    local gn_class
    gn_class=$(echo "$results" | jq -r '.greynoise.classification // "unknown"')
    if [[ "$gn_class" == "malicious" ]]; then
        score=$((score + 80))
    elif [[ "$gn_class" == "suspicious" ]]; then
        score=$((score + 40))
    fi
    
    # AlienVault
    local pulse_count
    pulse_count=$(echo "$results" | jq -r '.alienvault.pulse_count // 0')
    if [[ $pulse_count -gt 0 ]]; then
        score=$((score + pulse_count * 10))
    fi
    
    # Média
    score=$((score / 4))
    
    # Limitar entre 0 e 100
    if [[ $score -gt 100 ]]; then
        score=100
    elif [[ $score -lt 0 ]]; then
        score=0
    fi
    
    # Nível de risco
    local risk_level
    if [[ $score -ge 70 ]]; then
        risk_level="high"
    elif [[ $score -ge 40 ]]; then
        risk_level="medium"
    else
        risk_level="low"
    fi
    
    echo "{\"score\": $score, \"risk_level\": \"$risk_level\"}"
}

# Exportar funções
export -f init_threat_intel gather_threat_intel