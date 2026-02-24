#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - SecurityTrails API Wrapper
# =============================================================================

ST_API_BASE="https://api.securitytrails.com/v1"

# Inicializar wrapper
init_securitytrails() {
    if [[ -z "$SECURITYTRAILS_API_KEY" ]]; then
        log "WARNING" "SecurityTrails API key not configured" "ST"
        return 1
    fi
    
    log "INFO" "Initializing SecurityTrails wrapper" "ST"
    return 0
}

# Fazer requisição à API
st_request() {
    local endpoint="$1"
    local method="${2:-GET}"
    
    local url="${ST_API_BASE}${endpoint}"
    
    curl -s -X "$method" \
        -H "APIKEY: ${SECURITYTRAILS_API_KEY}" \
        -H "Content-Type: application/json" \
        "$url" 2>/dev/null
}

# DNS history
st_dns_history() {
    local domain="$1"
    local type="${2:-a}"
    
    st_request "/history/${domain}/dns/${type}"
}

# Subdomínios
st_subdomains() {
    local domain="$1"
    
    st_request "/domain/${domain}/subdomains"
}

# WHOIS
st_whois() {
    local domain="$1"
    
    st_request "/domain/${domain}/whois"
}

# IP neighbors
st_neighbors() {
    local ip="$1"
    
    st_request "/ips/nearby/${ip}"
}

# Search
st_search() {
    local query="$1"
    local data
    data=$(jq -n --arg q "$query" '{query: $q}')
    
    curl -s -X POST \
        -H "APIKEY: ${SECURITYTRAILS_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$data" \
        "${ST_API_BASE}/search/list" 2>/dev/null
}

# Exportar funções
export -f init_securitytrails st_dns_history st_subdomains st_whois st_neighbors st_search