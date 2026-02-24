#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Have I Been Pwned API Wrapper
# =============================================================================

HIBP_API_BASE="https://haveibeenpwned.com/api/v3"

# Inicializar wrapper
init_hibp() {
    if [[ -z "$HIBP_API_KEY" ]]; then
        log "WARNING" "HIBP API key not configured" "HIBP"
        return 1
    fi
    
    log "INFO" "Initializing HIBP wrapper" "HIBP"
    return 0
}

# Fazer requisição à API
hibp_request() {
    local endpoint="$1"
    
    local url="${HIBP_API_BASE}${endpoint}"
    
    curl -s -X GET \
        -H "hibp-api-key: ${HIBP_API_KEY}" \
        -H "user-agent: CYBERGHOST-OSINT" \
        "$url" 2>/dev/null
}

# Verificar conta
hibp_account() {
    local email="$1"
    local truncate="${2:-true}"
    
    hibp_request "/breachedaccount/${email}?truncateResponse=${truncate}"
}

# Verificar pastes
hibp_pastes() {
    local email="$1"
    
    hibp_request "/pasteaccount/${email}"
}

# Listar breaches
hibp_breaches() {
    local domain="${1:-}"
    
    if [[ -n "$domain" ]]; then
        hibp_request "/breaches?domain=${domain}"
    else
        hibp_request "/breaches"
    fi
}

# Obter breach específica
hibp_breach() {
    local name="$1"
    
    hibp_request "/breach/${name}"
}

# Classes de dados
hibp_classes() {
    hibp_request "/dataclasses"
}

# Exportar funções
export -f init_hibp hibp_account hibp_pastes hibp_breaches hibp_breach hibp_classes