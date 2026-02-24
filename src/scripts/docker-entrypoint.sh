#!/bin/sh
# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Docker Entrypoint Script
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║           CYBERGHOST OSINT ULTIMATE - DOCKER                ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Função para log
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO") echo -e "${GREEN}[${timestamp}] INFO: ${message}${NC}" ;;
        "WARN") echo -e "${YELLOW}[${timestamp}] WARN: ${message}${NC}" ;;
        "ERROR") echo -e "${RED}[${timestamp}] ERROR: ${message}${NC}" ;;
        "DEBUG") echo -e "${CYAN}[${timestamp}] DEBUG: ${message}${NC}" ;;
        *) echo -e "[${timestamp}] ${message}" ;;
    esac
}

# Verificar variáveis de ambiente
check_env() {
    log "INFO" "Checking environment variables..."
    
    # Diretórios necessários
    export CYBERGHOST_HOME="${CYBERGHOST_HOME:-/opt/cyberghost}"
    export CONFIG_DIR="${CONFIG_DIR:-/home/cyberghost/.cyberghost}"
    export DATA_DIR="${DATA_DIR:-${CYBERGHOST_HOME}/data}"
    export LOG_DIR="${LOG_DIR:-${CYBERGHOST_HOME}/logs}"
    export REPORTS_DIR="${REPORTS_DIR:-${CYBERGHOST_HOME}/reports}"
    
    # Criar diretórios
    for dir in "$CYBERGHOST_HOME" "$CONFIG_DIR" "$DATA_DIR" "$LOG_DIR" "$REPORTS_DIR" \
               "${DATA_DIR}/wordlists" "${DATA_DIR}/databases" "${DATA_DIR}/templates"; do
        mkdir -p "$dir"
        log "DEBUG" "Created directory: $dir"
    done
    
    # Configurações padrão
    export LOG_LEVEL="${LOG_LEVEL:-INFO}"
    export LOG_FORMAT="${LOG_FORMAT:-json}"
    export DB_TYPE="${DB_TYPE:-sqlite}"
    export DB_PATH="${DB_PATH:-${CONFIG_DIR}/cyberghost.db}"
    
    log "INFO" "Environment check completed"
}

# Configurar Tor (se habilitado)
setup_tor() {
    if [ "${ENABLE_TOR:-false}" = "true" ]; then
        log "INFO" "Setting up Tor..."
        
        # Configurar Tor
        cat > /etc/tor/torrc << EOF
SOCKSPort 0.0.0.0:9050
ControlPort 9051
CookieAuthentication 1
DataDirectory /var/lib/tor
EOF
        
        # Iniciar Tor em background
        tor &
        TOR_PID=$!
        
        log "INFO" "Tor started with PID: $TOR_PID"
        
        # Aguardar Tor iniciar
        sleep 5
    else
        log "INFO" "Tor is disabled"
    fi
}

# Configurar banco de dados
setup_database() {
    log "INFO" "Setting up database..."
    
    case "$DB_TYPE" in
        sqlite)
            log "INFO" "Using SQLite database: $DB_PATH"
            # SQLite não precisa de configuração adicional
            ;;
        postgresql)
            log "INFO" "Using PostgreSQL database"
            # Aguardar PostgreSQL estar pronto
            until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER"; do
                log "WARN" "Waiting for PostgreSQL to be ready..."
                sleep 2
            done
            log "INFO" "PostgreSQL is ready"
            ;;
        mysql)
            log "INFO" "Using MySQL database"
            # Aguardar MySQL estar pronto
            until mysqladmin ping -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" --silent; do
                log "WARN" "Waiting for MySQL to be ready..."
                sleep 2
            done
            log "INFO" "MySQL is ready"
            ;;
        mongodb)
            log "INFO" "Using MongoDB database"
            # Aguardar MongoDB estar pronto
            until mongosh --host "$DB_HOST" --port "$DB_PORT" --eval "db.adminCommand('ping')" >/dev/null 2>&1; do
                log "WARN" "Waiting for MongoDB to be ready..."
                sleep 2
            done
            log "INFO" "MongoDB is ready"
            ;;
        *)
            log "ERROR" "Unknown database type: $DB_TYPE"
            exit 1
            ;;
    esac
    
    log "INFO" "Database setup completed"
}

# Configurar API keys
setup_api_keys() {
    log "INFO" "Setting up API keys..."
    
    local api_file="${CONFIG_DIR}/api_keys.conf"
    
    # Criar arquivo de API keys se não existir
    if [ ! -f "$api_file" ]; then
        cat > "$api_file" << EOF
# CYBERGHOST OSINT - API Keys Configuration
# Configure suas chaves de API aqui

SHODAN_API_KEY="${SHODAN_API_KEY:-}"
VIRUSTOTAL_API_KEY="${VIRUSTOTAL_API_KEY:-}"
CENSYS_API_ID="${CENSYS_API_ID:-}"
CENSYS_API_SECRET="${CENSYS_API_SECRET:-}"
GREYNOISE_API_KEY="${GREYNOISE_API_KEY:-}"
HUNTER_API_KEY="${HUNTER_API_KEY:-}"
SECURITYTRAILS_API_KEY="${SECURITYTRAILS_API_KEY:-}"
GITHUB_API_KEY="${GITHUB_API_KEY:-}"
HIBP_API_KEY="${HIBP_API_KEY:-}"
EMAILREP_API_KEY="${EMAILREP_API_KEY:-}"
ZOOMEYE_API_KEY="${ZOOMEYE_API_KEY:-}"
BINARYEDGE_API_KEY="${BINARYEDGE_API_KEY:-}"
PUBLICWWW_API_KEY="${PUBLICWWW_API_KEY:-}"
EOF
        log "INFO" "API keys template created"
    fi
    
    # Carregar variáveis de ambiente para APIs
    if [ -f "$api_file" ]; then
        set -a
        source "$api_file"
        set +a
        log "INFO" "API keys loaded"
    fi
}

# Inicializar wordlists
init_wordlists() {
    log "INFO" "Initializing wordlists..."
    
    local wordlist_dir="${DATA_DIR}/wordlists"
    
    # Baixar wordlists básicas se não existirem
    if [ ! -f "${wordlist_dir}/subdomains.txt" ]; then
        log "INFO" "Downloading subdomain wordlist..."
        wget -q -O "${wordlist_dir}/subdomains.txt" \
            "https://gist.githubusercontent.com/jhaddix/86a06c5dc309d08580a018c66354a056/raw/96f4e51d96b2203f19f6381c8c545b278eaa0837/all.txt"
    fi
    
    if [ ! -f "${wordlist_dir}/directories.txt" ]; then
        log "INFO" "Downloading directory wordlist..."
        wget -q -O "${wordlist_dir}/directories.txt" \
            "https://raw.githubusercontent.com/daviddias/node-dirbuster/master/lists/directory-list-2.3-medium.txt"
    fi
    
    log "INFO" "Wordlists initialized"
}

# Iniciar serviços
start_services() {
    local service="$1"
    
    case "$service" in
        web)
            log "INFO" "Starting web dashboard..."
            cd /opt/cyberghost
            python3 src/ui/web_dashboard.py &
            WEB_PID=$!
            log "INFO" "Web dashboard started with PID: $WEB_PID"
            ;;
            
        api)
            log "INFO" "Starting API server..."
            cd /opt/cyberghost
            python3 src/ui/api_server.py &
            API_PID=$!
            log "INFO" "API server started with PID: $API_PID"
            ;;
            
        worker)
            log "INFO" "Starting Celery worker..."
            cd /opt/cyberghost
            celery -A src.tasks worker --loglevel=info &
            WORKER_PID=$!
            log "INFO" "Worker started with PID: $WORKER_PID"
            ;;
            
        beat)
            log "INFO" "Starting Celery beat..."
            cd /opt/cyberghost
            celery -A src.tasks beat --loglevel=info &
            BEAT_PID=$!
            log "INFO" "Beat started with PID: $BEAT_PID"
            ;;
            
        all)
            log "INFO" "Starting all services..."
            start_services web
            start_services api
            start_services worker
            start_services beat
            ;;
            
        cli)
            log "INFO" "Starting CLI mode..."
            exec /bin/bash
            ;;
            
        *)
            log "ERROR" "Unknown service: $service"
            exit 1
            ;;
    esac
}

# Função de cleanup
cleanup() {
    log "INFO" "Cleaning up..."
    
    # Matar processos em background
    for pid in $TOR_PID $WEB_PID $API_PID $WORKER_PID $BEAT_PID; do
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            log "DEBUG" "Killing process $pid"
            kill "$pid" 2>/dev/null
        fi
    done
    
    log "INFO" "Cleanup completed"
    exit 0
}

# Trap signals
trap cleanup INT TERM

# Processar argumentos
process_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            web|api|worker|beat|all|cli)
                COMMAND="$1"
                shift
                ;;
            --help|-h)
                cat << EOF
Usage: docker-entrypoint.sh [COMMAND] [OPTIONS]

Commands:
  web       Start web dashboard
  api       Start API server
  worker    Start Celery worker
  beat      Start Celery beat
  all       Start all services
  cli       Start CLI mode (bash)
  help      Show this help

Environment Variables:
  ENABLE_TOR          Enable Tor proxy (default: false)
  DB_TYPE             Database type (sqlite, postgresql, mysql, mongodb)
  LOG_LEVEL           Log level (DEBUG, INFO, WARNING, ERROR)
  SHODAN_API_KEY      Shodan API key
  VIRUSTOTAL_API_KEY  VirusTotal API key
  ... and more API keys
EOF
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# ===== MAIN =====
main() {
    log "INFO" "Starting CYBERGHOST OSINT Docker container"
    
    # Processar argumentos
    COMMAND="${COMMAND:-all}"
    
    # Configurações
    check_env
    setup_tor
    setup_database
    setup_api_keys
    init_wordlists
    
    # Iniciar serviço solicitado
    start_services "$COMMAND"
    
    # Manter container rodando
    log "INFO" "All services started. Container is running."
    
    # Aguardar processos
    wait
}

# Executar
main "$@"