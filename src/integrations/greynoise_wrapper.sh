#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - GreyNoise API Wrapper
# =============================================================================

GN_API_BASE="https://api.greynoise.io/v3"

# Inicializar wrapper
init_greynoise() {
    if [[ -z "$GREYNOISE_API_KEY" ]]; then
        log "WARNING" "GreyNoise API key not configured" "GREYNOISE"
        return 1
    fi
    
    log "INFO" "Initializing GreyNoise wrapper" "GREYNOISE"
    return 0
}

# Fazer requisição à API
greynoise_request() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="${3:-}"
    
    local url="${GN_API_BASE}${endpoint}"
    local headers=("-H" "key: ${GREYNOISE_API_KEY}")
    
    if [[ "$method" == "POST" ]] && [[ -n "$data" ]]; then
        headers+=("-H" "Content-Type: application/json")
        curl -s -X "$method" "${headers[@]}" -d "$data" "$url" 2>/dev/null
    else
        curl -s -X "$method" "${headers[@]}" "$url" 2>/dev/null
    fi
}

# Consultar IP
greynoise_ip() {
    local ip="$1"
    greynoise_request "/community/${ip}"
}

# Consultar IP (detalhado)
greynoise_ip_detailed() {
    local ip="$1"
    greynoise_request "/noise/context/${ip}"
}

# Consultar múltiplos IPs
greynoise_multi() {
    local ips="$1"
    local data
    data=$(jq -n --argjson ips "$ips" '{ips: $ips}')
    greynoise_request "/noise/multi" "POST" "$data"
}

# Consultar por CIDR
greynoise_cidr() {
    local cidr="$1"
    greynoise_request "/noise/quick/${cidr}"
}

# Estatísticas
greynoise_stats() {
    local query="$1"
    local data
    data=$(jq -n --arg q "$query" '{query: $q}')
    greynoise_request "/experimental/stats" "POST" "$data"
}

# Exportar funções
export -f init_greynoise greynoise_ip greynoise_ip_detailed greynoise_multi greynoise_cidr greynoise_stats