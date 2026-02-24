#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Censys API Wrapper
# =============================================================================

CENSYS_API_BASE="https://search.censys.io/api/v2"

# Inicializar wrapper
init_censys() {
    if [[ -z "$CENSYS_API_ID" ]] || [[ -z "$CENSYS_API_SECRET" ]]; then
        log "WARNING" "Censys API credentials not configured" "CENSYS"
        return 1
    fi
    
    log "INFO" "Initializing Censys wrapper" "CENSYS"
    return 0
}

# Fazer requisição à API
censys_request() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="${3:-}"
    
    local url="${CENSYS_API_BASE}${endpoint}"
    local auth
    auth=$(echo -n "${CENSYS_API_ID}:${CENSYS_API_SECRET}" | base64)
    
    if [[ "$method" == "POST" ]] && [[ -n "$data" ]]; then
        curl -s -X "$method" \
            -H "Authorization: Basic ${auth}" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$url" 2>/dev/null
    else
        curl -s -X "$method" \
            -H "Authorization: Basic ${auth}" \
            "$url" 2>/dev/null
    fi
}

# Buscar host IPv4
censys_host() {
    local ip="$1"
    censys_request "/hosts/${ip}"
}

# Buscar certificado
censys_cert() {
    local fingerprint="$1"
    censys_request "/certificates/${fingerprint}"
}

# Buscar por domínio
censys_search() {
    local query="$1"
    local per_page="${2:-100}"
    
    local data
    data=$(jq -n \
        --arg q "$query" \
        --argjson per "$per_page" \
        '{query: $q, per_page: $per}')
    
    censys_request "/hosts/search" "POST" "$data"
}

# Busca agregada
censys_aggregate() {
    local query="$1"
    local field="$2"
    
    local data
    data=$(jq -n \
        --arg q "$query" \
        --arg field "$field" \
        '{query: $q, field: $field}')
    
    censys_request "/hosts/aggregate" "POST" "$data"
}

# Exportar funções
export -f init_censys censys_host censys_cert censys_search censys_aggregate