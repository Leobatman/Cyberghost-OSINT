#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - BinaryEdge API Wrapper
# =============================================================================

BE_API_BASE="https://api.binaryedge.io/v2"

# Inicializar wrapper
init_binaryedge() {
    if [[ -z "$BINARYEDGE_API_KEY" ]]; then
        log "WARNING" "BinaryEdge API key not configured" "BINARYEDGE"
        return 1
    fi
    
    log "INFO" "Initializing BinaryEdge wrapper" "BINARYEDGE"
    return 0
}

# Fazer requisição à API
binaryedge_request() {
    local endpoint="$1"
    
    local url="${BE_API_BASE}${endpoint}"
    
    curl -s -X GET \
        -H "X-Key: ${BINARYEDGE_API_KEY}" \
        "$url" 2>/dev/null
}

# Buscar IP
binaryedge_ip() {
    local ip="$1"
    
    binaryedge_request "/query/ip/${ip}"
}

# Buscar domínio
binaryedge_domain() {
    local domain="$1"
    
    binaryedge_request "/query/domain/${domain}"
}

# Busca por email
binaryedge_email() {
    local email="$1"
    
    binaryedge_request "/query/email/${email}"
}

# Busca por CVE
binaryedge_cve() {
    local cve="$1"
    
    binaryedge_request "/query/cve/${cve}"
}

# Torrents
binaryedge_torrent() {
    local ip="$1"
    
    binaryedge_request "/query/torrent/ip/${ip}"
}

# Exportar funções
export -f init_binaryedge binaryedge_ip binaryedge_domain binaryedge_email binaryedge_cve binaryedge_torrent