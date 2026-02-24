#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - EmailRep.io API Wrapper
# =============================================================================

ER_API_BASE="https://emailrep.io"

# Inicializar wrapper
init_emailrep() {
    if [[ -z "$EMAILREP_API_KEY" ]]; then
        log "WARNING" "EmailRep.io API key not configured" "EMAILREP"
        return 1
    fi
    
    log "INFO" "Initializing EmailRep.io wrapper" "EMAILREP"
    return 0
}

# Fazer requisição à API
emailrep_request() {
    local endpoint="$1"
    
    local url="${ER_API_BASE}${endpoint}"
    
    curl -s -X GET \
        -H "Key: ${EMAILREP_API_KEY}" \
        -H "User-Agent: CYBERGHOST-OSINT" \
        "$url" 2>/dev/null
}

# Consultar email
emailrep_query() {
    local email="$1"
    
    emailrep_request "/${email}"
}

# Consultar em lote
emailrep_bulk() {
    local emails="$1"
    
    local data
    data=$(jq -n --argjson emails "$emails" '{emails: $emails}')
    
    curl -s -X POST \
        -H "Key: ${EMAILREP_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$data" \
        "${ER_API_BASE}/bulk" 2>/dev/null
}

# Exportar funções
export -f init_emailrep emailrep_query emailrep_bulk