#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - PublicWWW API Wrapper
# =============================================================================

PW_API_BASE="https://publicwww.com/webservices"

# Inicializar wrapper
init_publicwww() {
    if [[ -z "$PUBLICWWW_API_KEY" ]]; then
        log "WARNING" "PublicWWW API key not configured" "PUBLICWWW"
        return 1
    fi
    
    log "INFO" "Initializing PublicWWW wrapper" "PUBLICWWW"
    return 0
}

# Fazer requisição à API
publicwww_request() {
    local query="$1"
    local page="${2:-1}"
    
    local url="${PW_API_BASE}/v1/search?query=${query}&page=${page}&key=${PUBLICWWW_API_KEY}"
    
    curl -s "$url" 2>/dev/null
}

# Buscar código
publicwww_code() {
    local code="$1"
    
    publicwww_request "${code}"
}

# Buscar por tecnologia
publicwww_tech() {
    local tech="$1"
    
    publicwww_request "\"${tech}\""
}

# Buscar por HTML
publicwww_html() {
    local tag="$1"
    local attr="${2:-}"
    
    if [[ -n "$attr" ]]; then
        publicwww_request "${tag}%20${attr}"
    else
        publicwww_request "${tag}"
    fi
}

# Exportar funções
export -f init_publicwww publicwww_code publicwww_tech publicwww_html