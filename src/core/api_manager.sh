#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - API Manager
# =============================================================================

# Arquivo de configuração de APIs
API_CONFIG="${CONFIG_DIR}/api_keys.conf"
API_CACHE_DIR="${CONFIG_DIR}/api_cache"
API_STATS_FILE="${CONFIG_DIR}/api_stats.json"

# Declarar APIs suportadas
declare -A API_NAMES=(
    ["shodan"]="Shodan"
    ["virustotal"]="VirusTotal"
    ["censys"]="Censys"
    ["greynoise"]="GreyNoise"
    ["hunter"]="Hunter.io"
    ["securitytrails"]="SecurityTrails"
    ["zoomeye"]="ZoomEye"
    ["binaryedge"]="BinaryEdge"
    ["publicwww"]="PublicWWW"
    ["haveibeenpwned"]="Have I Been Pwned"
    ["emailrep"]="EmailRep.io"
    ["github"]="GitHub"
    ["google"]="Google"
    ["twitter"]="Twitter"
    ["linkedin"]="LinkedIn"
    ["facebook"]="Facebook"
)

declare -A API_ENDPOINTS=(
    ["shodan"]="https://api.shodan.io"
    ["virustotal"]="https://www.virustotal.com/api/v3"
    ["censys"]="https://search.censys.io/api"
    ["greynoise"]="https://api.greynoise.io"
    ["hunter"]="https://api.hunter.io/v2"
    ["securitytrails"]="https://api.securitytrails.com/v1"
    ["zoomeye"]="https://api.zoomeye.org"
    ["binaryedge"]="https://api.binaryedge.io/v2"
    ["publicwww"]="https://publicwww.com/webservices"
    ["haveibeenpwned"]="https://haveibeenpwned.com/api/v3"
    ["emailrep"]="https://emailrep.io"
    ["github"]="https://api.github.com"
)

declare -A API_RATE_LIMITS=(
    ["shodan"]="100"
    ["virustotal"]="4"
    ["censys"]="120"
    ["greynoise"]="60"
    ["hunter"]="100"
    ["securitytrails"]="50"
    ["zoomeye"]="100"
    ["binaryedge"]="100"
    ["publicwww"]="100"
    ["haveibeenpwned"]="10"
    ["emailrep"]="10"
    ["github"]="60"
)

# Carregar chaves de API
load_api_keys() {
    if [[ -f "$API_CONFIG" ]]; then
        # shellcheck source=/dev/null
        source "$API_CONFIG"
        log "INFO" "API keys loaded from $API_CONFIG" "API"
    else
        log "WARNING" "API configuration not found" "API"
        create_api_config_template
    fi
    
    # Criar diretório de cache
    mkdir -p "$API_CACHE_DIR"
    
    # Inicializar estatísticas
    init_api_stats
}

# Criar template de configuração de API
create_api_config_template() {
    cat > "$API_CONFIG" << 'EOF'
# CYBERGHOST OSINT - API Keys Configuration
# Get your API keys from the respective services

# Shodan - https://account.shodan.io/
SHODAN_API_KEY=""

# VirusTotal - https://www.virustotal.com/gui/my-apikey
VIRUSTOTAL_API_KEY=""

# Censys - https://censys.io/register
CENSYS_API_ID=""
CENSYS_API_SECRET=""

# GreyNoise - https://greynoise.io/
GREYNOISE_API_KEY=""

# Hunter.io - https://hunter.io/users/sign_up
HUNTER_API_KEY=""

# SecurityTrails - https://securitytrails.com/
SECURITYTRAILS_API_KEY=""

# ZoomEye - https://www.zoomeye.org/
ZOOMEYE_API_KEY=""

# BinaryEdge - https://www.binaryedge.io/
BINARYEDGE_API_KEY=""

# PublicWWW - https://publicwww.com/
PUBLICWWW_API_KEY=""

# Have I Been Pwned - https://haveibeenpwned.com/API/Key
HIBP_API_KEY=""

# EmailRep.io - https://emailrep.io/
EMAILREP_API_KEY=""

# GitHub - https://github.com/settings/tokens
GITHUB_API_KEY=""

# Google Custom Search - https://developers.google.com/custom-search/v1/overview
GOOGLE_API_KEY=""
GOOGLE_CX=""

EOF
    
    log "INFO" "API configuration template created at $API_CONFIG" "API"
}

# Inicializar estatísticas de API
init_api_stats() {
    if [[ ! -f "$API_STATS_FILE" ]]; then
        echo '{}' > "$API_STATS_FILE"
    fi
}

# Atualizar estatísticas de API
update_api_stats() {
    local api="$1"
    local endpoint="$2"
    local status="$3"
    local duration="$4"
    
    local stats
    stats=$(jq --arg api "$api" \
        --arg endpoint "$endpoint" \
        --arg status "$status" \
        --arg duration "$duration" \
        '.[$api] = (.[$api] // {}) | 
         .[$api][$endpoint] = (.[$api][$endpoint] // {}) |
         .[$api][$endpoint].total_calls = ((.[$api][$endpoint].total_calls // 0) + 1) |
         .[$api][$endpoint].last_call = now |
         .[$api][$endpoint].last_status = $status |
         .[$api][$endpoint].avg_duration = ((.[$api][$endpoint].avg_duration // $duration | tonumber) + (($duration | tonumber) - (.[$api][$endpoint].avg_duration // $duration | tonumber)) / (.[$api][$endpoint].total_calls // 1))' \
        "$API_STATS_FILE")
    
    echo "$stats" > "$API_STATS_FILE"
}

# Verificar rate limit
check_rate_limit() {
    local api="$1"
    local limit="${API_RATE_LIMITS[$api]:-60}"
    local window=60  # 1 minuto
    
    local calls_in_window
    calls_in_window=$(jq --arg api "$api" \
        '[.[$api][]? | select(.timestamp > now - 60)] | length' \
        "$API_STATS_FILE" 2>/dev/null || echo 0)
    
    if [[ $calls_in_window -ge $limit ]]; then
        log "WARNING" "Rate limit exceeded for $api" "API"
        return 1
    fi
    
    return 0
}

# Fazer requisição à API com retry
api_request() {
    local api="$1"
    local endpoint="$2"
    local method="${3:-GET}"
    local data="$4"
    local params="$5"
    
    local api_key_var="${api}_API_KEY"
    local api_key="${!api_key_var}"
    
    # Verificar se API tem configuração específica
    case $api in
        censys)
            api_request_censys "$endpoint" "$method" "$data" "$params"
            return $?
            ;;
        *)
            # Requisição padrão
            api_request_generic "$api" "$endpoint" "$method" "$data" "$params"
            return $?
            ;;
    esac
}

# Requisição genérica
api_request_generic() {
    local api="$1"
    local endpoint="$2"
    local method="$3"
    local data="$4"
    local params="$5"
    
    local base_url="${API_ENDPOINTS[$api]}"
    local api_key_var="${api}_API_KEY"
    local api_key="${!api_key_var}"
    
    if [[ -z "$api_key" ]]; then
        log "ERROR" "No API key for $api" "API"
        return 1
    fi
    
    # Verificar rate limit
    if ! check_rate_limit "$api"; then
        sleep "${API_RETRY_DELAY:-5}"
    fi
    
    # Construir URL
    local url="${base_url}/${endpoint}"
    if [[ -n "$params" ]]; then
        url="${url}?${params}"
    fi
    
    # Headers padrão
    local headers=(
        "-H" "User-Agent: CYBERGHOST-OSINT/${VERSION}"
    )
    
    # Headers específicos por API
    case $api in
        virustotal)
            headers+=("-H" "x-apikey: ${api_key}")
            ;;
        shodan)
            url="${url}?key=${api_key}&${params}"
            ;;
        securitytrails)
            headers+=("-H" "APIKEY: ${api_key}")
            ;;
        github)
            headers+=("-H" "Authorization: token ${api_key}")
            ;;
        haveibeenpwned)
            headers+=("-H" "hibp-api-key: ${api_key}")
            ;;
        emailrep)
            headers+=("-H" "Key: ${api_key}")
            ;;
        *)
            headers+=("-H" "Authorization: Bearer ${api_key}")
            ;;
    esac
    
    # Fazer requisição com retry
    local response
    local status_code
    local start_time
    local end_time
    
    start_time=$(date +%s%N)
    
    for ((i=1; i<=MAX_RETRIES; i++)); do
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            "${headers[@]}" \
            ${data:+-d "$data"} \
            "$url" 2>/dev/null || true)
        
        status_code=$(echo "$response" | tail -n1)
        response=$(echo "$response" | sed '$d')
        
        end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 ))
        
        # Atualizar estatísticas
        update_api_stats "$api" "$endpoint" "$status_code" "$duration"
        
        if [[ $status_code -ge 200 ]] && [[ $status_code -lt 300 ]]; then
            log "DEBUG" "API request to $api successful (${status_code})" "API"
            echo "$response"
            return 0
        elif [[ $status_code -eq 429 ]] || [[ $status_code -ge 500 ]]; then
            # Rate limit ou erro do servidor, tentar novamente
            log "WARNING" "API request failed (${status_code}), retry $i/$MAX_RETRIES" "API"
            sleep $((i * API_RETRY_DELAY))
        else:
            # Erro permanente
            log "ERROR" "API request failed permanently (${status_code})" "API"
            echo "{}"
            return 1
        fi
    done
    
    log "ERROR" "API request failed after $MAX_RETRIES retries" "API"
    echo "{}"
    return 1
}

# Requisição Censys (autenticação especial)
api_request_censys() {
    local endpoint="$1"
    local method="$2"
    local data="$3"
    local params="$4"
    
    local base_url="${API_ENDPOINTS[censys]}"
    
    if [[ -z "$CENSYS_API_ID" ]] || [[ -z "$CENSYS_API_SECRET" ]]; then
        log "ERROR" "No Censys credentials" "API"
        return 1
    fi
    
    local url="${base_url}/${endpoint}"
    if [[ -n "$params" ]]; then
        url="${url}?${params}"
    fi
    
    local auth
    auth=$(echo -n "${CENSYS_API_ID}:${CENSYS_API_SECRET}" | base64)
    
    local response
    response=$(curl -s -X "$method" \
        -H "Authorization: Basic ${auth}" \
        -H "Content-Type: application/json" \
        ${data:+-d "$data"} \
        "$url" 2>/dev/null)
    
    echo "$response"
}

# Buscar em cache
get_cached() {
    local key="$1"
    local cache_file="${API_CACHE_DIR}/$(echo -n "$key" | md5sum | cut -d' ' -f1).cache"
    
    if [[ -f "$cache_file" ]] && [[ "${CACHE_ENABLED:-true}" == "true" ]]; then
        local file_age=$(( $(date +%s) - $(stat -c%Y "$cache_file" 2>/dev/null || stat -f%m "$cache_file" 2>/dev/null) ))
        
        if [[ $file_age -lt "${API_CACHE_TTL:-3600}" ]]; then
            cat "$cache_file"
            return 0
        fi
    fi
    
    return 1
}

# Salvar em cache
set_cached() {
    local key="$1"
    local data="$2"
    
    if [[ "${CACHE_ENABLED:-true}" == "true" ]]; then
        local cache_file="${API_CACHE_DIR}/$(echo -n "$key" | md5sum | cut -d' ' -f1).cache"
        echo "$data" > "$cache_file"
    fi
}

# Verificar status das APIs
check_api_status() {
    log "INFO" "Checking API status..." "API"
    
    local results="{}"
    
    for api in "${!API_NAMES[@]}"; do
        local api_key_var="${api}_API_KEY"
        local api_key="${!api_key_var}"
        
        if [[ -n "$api_key" ]]; then
            results=$(echo "$results" | jq --arg api "$api" --arg name "${API_NAMES[$api]}" \
                '.[$api] = {"name": $name, "status": "configured"}')
        else
            results=$(echo "$results" | jq --arg api "$api" --arg name "${API_NAMES[$api]}" \
                '.[$api] = {"name": $name, "status": "missing"}')
        fi
    done
    
    echo "$results" | jq '.'
}

# Exportar funções
export -f load_api_keys api_request check_api_status