#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Hunter.io API Wrapper
# =============================================================================

HUNTER_API_BASE="https://api.hunter.io/v2"

# Inicializar wrapper
init_hunter() {
    if [[ -z "$HUNTER_API_KEY" ]]; then
        log "WARNING" "Hunter.io API key not configured" "HUNTER"
        return 1
    fi
    
    log "INFO" "Initializing Hunter.io wrapper" "HUNTER"
    return 0
}

# Fazer requisição à API
hunter_request() {
    local endpoint="$1"
    local params="${2:-}"
    
    local url="${HUNTER_API_BASE}${endpoint}?api_key=${HUNTER_API_KEY}${params:+&${params}}"
    
    curl -s "$url" 2>/dev/null
}

# Buscar emails de domínio
hunter_domain() {
    local domain="$1"
    local limit="${2:-10}"
    
    hunter_request "/domain-search" "domain=${domain}&limit=${limit}"
}

# Verificar email
hunter_verify() {
    local email="$1"
    hunter_request "/email-verifier" "email=${email}"
}

# Buscar por nome
hunter_name() {
    local domain="$1"
    local first_name="$2"
    local last_name="$3"
    
    hunter_request "/email-finder" "domain=${domain}&first_name=${first_name}&last_name=${last_name}"
}

# Contar emails
hunter_count() {
    local domain="$1"
    hunter_request "/email-count" "domain=${domain}"
}

# Exportar funções
export -f init_hunter hunter_domain hunter_verify hunter_name hunter_count