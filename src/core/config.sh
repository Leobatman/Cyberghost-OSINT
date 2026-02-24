#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Global Configuration
# =============================================================================

# Versão
VERSION="7.0.0"
CODENAME="Shadow Warrior"
BUILD_DATE="2024-01-15"

# Autor
AUTHOR="Leonardo Pereira Pinheiro"
ALIAS="CyberGhost"
EMAIL="cyberghost@protonmail.com"
GITHUB="https://github.com/cyberghost"
WEBSITE="https://cyberghost-osint.com"

# Diretórios
PROJECT_ROOT="${PROJECT_ROOT:-}"
CONFIG_DIR="${HOME}/.cyberghost"
DATA_DIR="${PROJECT_ROOT}/data"
LOG_DIR="${PROJECT_ROOT}/logs"
TEMP_DIR="/tmp/cyberghost_$$"
REPORTS_DIR="${HOME}/CyberGhost_Reports"
PLUGINS_DIR="${PROJECT_ROOT}/plugins"
MODULES_DIR="${PROJECT_ROOT}/src/modules"
WORDLISTS_DIR="${DATA_DIR}/wordlists"
DATABASES_DIR="${DATA_DIR}/databases"

# Configurações de rede
DEFAULT_TIMEOUT=30
MAX_RETRIES=3
PARALLEL_JOBS=10
RATE_LIMIT=100
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
PROXY=""
USE_TOR=false
TOR_PORT=9050
TOR_CONTROL_PORT=9051

# Configurações de API
API_RETRY_DELAY=5
API_CACHE_TTL=3600
API_RATE_LIMIT_ENABLED=true
API_CONCURRENT_REQUESTS=5

# Configurações de banco de dados
DB_TYPE="sqlite"
DB_HOST="localhost"
DB_PORT=5432
DB_NAME="cyberghost"
DB_USER="cyberghost"
DB_PASS=""
DB_PATH="${CONFIG_DIR}/cyberghost.db"

# Configurações de logging
LOG_LEVEL="INFO"
LOG_FORMAT="json"
LOG_MAX_SIZE="100M"
LOG_MAX_FILES=10
LOG_COMPRESS=true

# Configurações de relatório
REPORT_FORMAT="html"
REPORT_TEMPLATE="modern"
REPORT_COMPRESS=true
REPORT_ENCRYPT=false
REPORT_PASSWORD=""

# Configurações de segurança
ENCRYPT_CONFIG=false
ENCRYPT_KEY=""
AUDIT_LOGGING=true
AUDIT_LOG="${LOG_DIR}/audit.log"
MAX_SCAN_DURATION=86400
RATE_LIMIT_ENABLED=true

# Configurações de scan
SCAN_TIMEOUT=3600
SCAN_DEPTH="full"
SCAN_THREADS=50
SCAN_DELAY=0.1
FOLLOW_REDIRECTS=true
VERIFY_SSL=false
COLLECT_METADATA=true
DETECT_HONEYPOTS=true

# Configurações de wordlists
WORDLIST_SUBDOMAINS="${WORDLISTS_DIR}/subdomains/all.txt"
WORDLIST_DIRECTORIES="${WORDLISTS_DIR}/directories/common.txt"
WORDLIST_PASSWORDS="${WORDLISTS_DIR}/passwords/rockyou.txt"
WORDLIST_USERNAMES="${WORDLISTS_DIR}/usernames/common.txt"

# Features
ENABLE_AI_ANALYSIS=true
ENABLE_MACHINE_LEARNING=true
ENABLE_DARKWEB=true
ENABLE_BLOCKCHAIN=false
ENABLE_IOT_SCANNING=true
ENABLE_CLOUD_DETECTION=true
ENABLE_CDN_DETECTION=true
ENABLE_WAF_DETECTION=true

# Notificações
NOTIFY_EMAIL=""
NOTIFY_SLACK_WEBHOOK=""
NOTIFY_DISCORD_WEBHOOK=""
NOTIFY_TELEGRAM_BOT=""
NOTIFY_TELEGRAM_CHAT=""
NOTIFY_ON_COMPLETE=true
NOTIFY_ON_ERROR=true

# Performance
CACHE_ENABLED=true
CACHE_DIR="${CONFIG_DIR}/cache"
CACHE_MAX_SIZE="1G"
CACHE_TTL=86400
MEMORY_LIMIT="512M"
CPU_LIMIT=80

# Load configuration from file
load_config() {
    local config_file="${CONFIG_DIR}/settings.conf"
    
    if [[ -f "$config_file" ]]; then
        # shellcheck source=/dev/null
        source "$config_file"
        log "debug" "Loaded configuration from $config_file" "CONFIG"
    else
        log "warning" "Configuration file not found, using defaults" "CONFIG"
        create_default_config
    fi
    
    # Validar configurações
    validate_config
}

# Criar configuração padrão
create_default_config() {
    mkdir -p "${CONFIG_DIR}"
    
    cat > "${CONFIG_DIR}/settings.conf" << EOF
# CYBERGHOST OSINT Configuration File
# Generated: $(date)

# Core Settings
VERSION="${VERSION}"
LOG_LEVEL="INFO"
LOG_FORMAT="json"

# Network Settings
DEFAULT_TIMEOUT=30
MAX_RETRIES=3
PARALLEL_JOBS=10
RATE_LIMIT=100

# Security Settings
AUDIT_LOGGING=true
ENCRYPT_CONFIG=false

# Scan Settings
SCAN_TIMEOUT=3600
SCAN_THREADS=50
FOLLOW_REDIRECTS=true
VERIFY_SSL=false

# Features
ENABLE_AI_ANALYSIS=true
ENABLE_DARKWEB=true
ENABLE_IOT_SCANNING=true

# Performance
CACHE_ENABLED=true
MEMORY_LIMIT="512M"
CPU_LIMIT=80

EOF
    
    log "info" "Created default configuration at ${config_file}" "CONFIG"
}

# Validar configurações
validate_config() {
    local errors=0
    
    # Verificar diretórios
    for dir in LOG_DIR TEMP_DIR REPORTS_DIR CONFIG_DIR; do
        if [[ -n "${!dir}" ]]; then
            mkdir -p "${!dir}" 2>/dev/null || {
                log "error" "Cannot create directory: ${!dir}" "CONFIG"
                ((errors++))
            }
        fi
    done
    
    # Validar números
    if [[ ! "$PARALLEL_JOBS" =~ ^[0-9]+$ ]] || [[ "$PARALLEL_JOBS" -lt 1 ]]; then
        log "warning" "Invalid PARALLEL_JOBS, setting to 10" "CONFIG"
        PARALLEL_JOBS=10
    fi
    
    if [[ ! "$SCAN_TIMEOUT" =~ ^[0-9]+$ ]] || [[ "$SCAN_TIMEOUT" -lt 60 ]]; then
        log "warning" "Invalid SCAN_TIMEOUT, setting to 3600" "CONFIG"
        SCAN_TIMEOUT=3600
    fi
    
    # Validar formatos
    if [[ ! "$REPORT_FORMAT" =~ ^(html|pdf|json|csv|txt)$ ]]; then
        log "warning" "Invalid REPORT_FORMAT, setting to html" "CONFIG"
        REPORT_FORMAT="html"
    fi
    
    if [[ ! "$LOG_LEVEL" =~ ^(DEBUG|INFO|WARNING|ERROR|CRITICAL)$ ]]; then
        log "warning" "Invalid LOG_LEVEL, setting to INFO" "CONFIG"
        LOG_LEVEL="INFO"
    fi
    
    if [[ $errors -gt 0 ]]; then
        log "error" "Configuration validation failed with $errors errors" "CONFIG"
        return 1
    fi
    
    log "debug" "Configuration validated successfully" "CONFIG"
    return 0
}

# Salvar configuração
save_config() {
    local config_file="${CONFIG_DIR}/settings.conf"
    
    # Backup do arquivo atual
    if [[ -f "$config_file" ]]; then
        cp "$config_file" "${config_file}.bak"
    fi
    
    # Salvar variáveis principais
    {
        echo "# CYBERGHOST OSINT Configuration File"
        echo "# Saved: $(date)"
        echo ""
        echo "# Core Settings"
        echo "VERSION=\"${VERSION}\""
        echo "LOG_LEVEL=\"${LOG_LEVEL}\""
        echo "LOG_FORMAT=\"${LOG_FORMAT}\""
        echo ""
        echo "# Network Settings"
        echo "DEFAULT_TIMEOUT=${DEFAULT_TIMEOUT}"
        echo "MAX_RETRIES=${MAX_RETRIES}"
        echo "PARALLEL_JOBS=${PARALLEL_JOBS}"
        echo "RATE_LIMIT=${RATE_LIMIT}"
        echo ""
        echo "# Security Settings"
        echo "AUDIT_LOGGING=${AUDIT_LOGGING}"
        echo "ENCRYPT_CONFIG=${ENCRYPT_CONFIG}"
        echo ""
        echo "# Scan Settings"
        echo "SCAN_TIMEOUT=${SCAN_TIMEOUT}"
        echo "SCAN_THREADS=${SCAN_THREADS}"
        echo "FOLLOW_REDIRECTS=${FOLLOW_REDIRECTS}"
        echo "VERIFY_SSL=${VERIFY_SSL}"
        echo ""
        echo "# Features"
        echo "ENABLE_AI_ANALYSIS=${ENABLE_AI_ANALYSIS}"
        echo "ENABLE_DARKWEB=${ENABLE_DARKWEB}"
        echo "ENABLE_IOT_SCANNING=${ENABLE_IOT_SCANNING}"
        echo ""
        echo "# Performance"
        echo "CACHE_ENABLED=${CACHE_ENABLED}"
        echo "MEMORY_LIMIT=\"${MEMORY_LIMIT}\""
        echo "CPU_LIMIT=${CPU_LIMIT}"
    } > "$config_file"
    
    log "info" "Configuration saved to ${config_file}" "CONFIG"
}

# Exportar variáveis
export VERSION CODENAME AUTHOR ALIAS
export CONFIG_DIR DATA_DIR LOG_DIR TEMP_DIR REPORTS_DIR
export DEFAULT_TIMEOUT MAX_RETRIES PARALLEL_JOBS RATE_LIMIT
export LOG_LEVEL LOG_FORMAT
export REPORT_FORMAT
export AUDIT_LOGGING
export SCAN_TIMEOUT SCAN_THREADS
export ENABLE_AI_ANALYSIS ENABLE_DARKWEB
export CACHE_ENABLED