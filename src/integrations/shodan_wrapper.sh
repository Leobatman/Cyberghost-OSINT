#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Shodan API Wrapper
# =============================================================================

SHODAN_API_BASE="https://api.shodan.io"

# Inicializar wrapper
init_shodan() {
    if [[ -z "$SHODAN_API_KEY" ]]; then
        log "WARNING" "Shodan API key not configured" "SHODAN"
        return 1
    fi
    
    log "INFO" "Initializing Shodan wrapper" "SHODAN"
    return 0
}

# Fazer requisição à API
shodan_request() {
    local endpoint="$1"
    local params="${2:-}"
    
    local url="${SHODAN_API_BASE}${endpoint}?key=${SHODAN_API_KEY}${params:+&${params}}"
    
    curl -s "$url" 2>/dev/null
}

# Buscar host
shodan_host() {
    local ip="$1"
    local history="${2:-false}"
    
    local params=""
    [[ "$history" == "true" ]] && params="history=true"
    
    shodan_request "/shodan/host/${ip}" "$params"
}

# Buscar por DNS
shodan_dns() {
    local domain="$1"
    shodan_request "/dns/resolve" "hostnames=${domain}"
}

# Buscar portas
shodan_ports() {
    local ip="$1"
    shodan_request "/shodan/host/${ip}" | jq -r '.ports[]?'
}

# Buscar vulnerabilidades
shodan_vulns() {
    local ip="$1"
    shodan_request "/shodan/host/${ip}" | jq -c '.vulns // {}'
}

# Buscar serviços
shodan_services() {
    local ip="$1"
    shodan_request "/shodan/host/${ip}" | jq -c '.data[]? | {
        port: .port,
        transport: .transport,
        product: .product,
        version: .version,
        banner: .data
    }'
}

# Busca genérica
shodan_search() {
    local query="$1"
    local page="${2:-1}"
    
    shodan_request "/shodan/host/search" "query=${query}&page=${page}"
}

# Contar resultados
shodan_count() {
    local query="$1"
    shodan_request "/shodan/host/count" "query=${query}"
}

# My IP
shodan_my_ip() {
    shodan_request "/tools/myip"
}

# API info
shodan_info() {
    shodan_request "/api-info"
}

# Exportar funções
export -f init_shodan shodan_host shodan_dns shodan_ports shodan_vulns shodan_services shodan_search shodan_count shodan_my_ip shodan_info