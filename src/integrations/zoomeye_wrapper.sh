#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - ZoomEye API Wrapper
# =============================================================================

ZOOMEYE_API_BASE="https://api.zoomeye.org"

# Inicializar wrapper
init_zoomeye() {
    if [[ -z "$ZOOMEYE_API_KEY" ]]; then
        log "WARNING" "ZoomEye API key not configured" "ZOOMEYE"
        return 1
    fi
    
    log "INFO" "Initializing ZoomEye wrapper" "ZOOMEYE"
    return 0
}

# Fazer requisição à API
zoomeye_request() {
    local endpoint="$1"
    
    local url="${ZOOMEYE_API_BASE}${endpoint}"
    
    curl -s -X GET \
        -H "API-KEY: ${ZOOMEYE_API_KEY}" \
        "$url" 2>/dev/null
}

# Busca host
zoomeye_host() {
    local query="$1"
    local page="${2:-1}"
    
    zoomeye_request "/host/search?query=${query}&page=${page}"
}

# Busca web
zoomeye_web() {
    local query="$1"
    local page="${2:-1}"
    
    zoomeye_request "/web/search?query=${query}&page=${page}"
}

# Informações da conta
zoomeye_info() {
    zoomeye_request "/resources-info"
}

# Exportar funções
export -f init_zoomeye zoomeye_host zoomeye_web zoomeye_info