#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Advanced Logging System
# =============================================================================

# Níveis de log
declare -A LOG_LEVELS=(
    ["DEBUG"]=0
    ["INFO"]=1
    ["SUCCESS"]=1
    ["WARNING"]=2
    ["ERROR"]=3
    ["CRITICAL"]=4
    ["HACK"]=1
    ["STEALTH"]=1
    ["RECON"]=1
    ["INTEL"]=1
    ["DATA"]=1
    ["AI"]=1
)

# Cores (ANSI)
declare -A LOG_COLORS=(
    ["DEBUG"]="\033[0;36m"      # Cyan
    ["INFO"]="\033[0;32m"       # Green
    ["SUCCESS"]="\033[1;32m"    # Bold Green
    ["WARNING"]="\033[1;33m"    # Yellow
    ["ERROR"]="\033[0;31m"      # Red
    ["CRITICAL"]="\033[1;31m"   # Bold Red
    ["HACK"]="\033[1;35m"       # Purple
    ["STEALTH"]="\033[0;37m"    # Gray
    ["RECON"]="\033[0;34m"      # Blue
    ["INTEL"]="\033[1;36m"      # Bold Cyan
    ["DATA"]="\033[1;37m"       # White
    ["AI"]="\033[0;35m"         # Magenta
)

# Ícones
declare -A LOG_ICONS=(
    ["DEBUG"]="🐛"
    ["INFO"]="ℹ️"
    ["SUCCESS"]="✅"
    ["WARNING"]="⚠️"
    ["ERROR"]="❌"
    ["CRITICAL"]="🛑"
    ["HACK"]="⚡"
    ["STEALTH"]="👻"
    ["RECON"]="🔍"
    ["INTEL"]="📡"
    ["DATA"]="💾"
    ["AI"]="🤖"
)

# Arquivos de log
MAIN_LOG=""
ERROR_LOG=""
DEBUG_LOG=""
AUDIT_LOG=""
PERFORMANCE_LOG=""

# Inicializar sistema de logging
init_logging() {
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    
    MAIN_LOG="${LOG_DIR}/cyberghost_${timestamp}.log"
    ERROR_LOG="${LOG_DIR}/error_${timestamp}.log"
    DEBUG_LOG="${LOG_DIR}/debug_${timestamp}.log"
    AUDIT_LOG="${LOG_DIR}/audit_${timestamp}.log"
    PERFORMANCE_LOG="${LOG_DIR}/performance_${timestamp}.log"
    
    # Criar diretório de logs se não existir
    mkdir -p "${LOG_DIR}"
    
    # Inicializar arquivos de log
    for log_file in "$MAIN_LOG" "$ERROR_LOG" "$DEBUG_LOG" "$AUDIT_LOG" "$PERFORMANCE_LOG"; do
        touch "$log_file"
    done
    
    # Log inicial
    log "INFO" "Logging system initialized" "CORE"
    log "INFO" "Session ID: ${SESSION_ID:-$(uuidgen)}" "CORE"
}

# Função principal de logging
log() {
    local level="${1:-INFO}"
    local message="$2"
    local module="${3:-GENERAL}"
    local timestamp
    local pid
    
    timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    pid=$$
    
    # Verificar nível de log
    local current_level_num="${LOG_LEVELS[${LOG_LEVEL:-INFO}]:-1}"
    local msg_level_num="${LOG_LEVELS[$level]:-1}"
    
    # Não logar se nível for muito baixo
    if [[ $msg_level_num -lt $current_level_num ]]; then
        return
    fi
    
    # Formatar mensagem
    local color="${LOG_COLORS[$level]:-\033[0m}"
    local icon="${LOG_ICONS[$level]:-}"
    local reset="\033[0m"
    
    # Mensagem para console
    if [[ "${QUIET:-false}" != "true" ]]; then
        if [[ "${NO_COLOR:-false}" == "true" ]]; then
            echo "[$timestamp][$module] $level: $message"
        else
            echo -e "${color}${icon} [${timestamp}][${module}] ${level}: ${message}${reset}"
        fi
    fi
    
    # Log em arquivo (formato JSON)
    local log_entry
    log_entry=$(jq -n \
        --arg timestamp "$timestamp" \
        --arg level "$level" \
        --arg module "$module" \
        --arg message "$message" \
        --arg pid "$pid" \
        '{timestamp: $timestamp, level: $level, module: $module, message: $message, pid: $pid}')
    
    echo "$log_entry" >> "$MAIN_LOG"
    
    # Logs específicos
    case $level in
        ERROR|CRITICAL)
            echo "$log_entry" >> "$ERROR_LOG"
            ;;
        DEBUG)
            echo "$log_entry" >> "$DEBUG_LOG"
            ;;
    esac
    
    # Log de auditoria
    if [[ "${AUDIT_LOGGING:-true}" == "true" ]]; then
        local audit_entry
        audit_entry=$(jq -n \
            --arg timestamp "$timestamp" \
            --arg user "${USER:-unknown}" \
            --arg action "$module" \
            --arg target "$message" \
            '{timestamp: $timestamp, user: $user, action: $action, target: $message}')
        echo "$audit_entry" >> "$AUDIT_LOG"
    fi
}

# Log de performance
log_performance() {
    local operation="$1"
    local duration="$2"
    local metadata="$3"
    
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local perf_entry
    perf_entry=$(jq -n \
        --arg timestamp "$timestamp" \
        --arg operation "$operation" \
        --arg duration "$duration" \
        --argjson metadata "$metadata" \
        '{timestamp: $timestamp, operation: $operation, duration: $duration, metadata: $metadata}')
    
    echo "$perf_entry" >> "$PERFORMANCE_LOG"
    
    # Log se duração for muito alta
    if [[ $duration -gt 10 ]]; then
        log "WARNING" "Slow operation: $operation took ${duration}s" "PERFORMANCE"
    fi
}

# Log estruturado com dados
log_data() {
    local level="$1"
    local message="$2"
    local data="$3"
    local module="${4:-DATA}"
    
    # Converter data para JSON se for string
    if [[ ! "$data" =~ ^\{.*\}$ ]]; then
        data=$(jq -n --arg data "$data" '{data: $data}')
    fi
    
    local combined="{\"message\": \"$message\", \"data\": $data}"
    log "$level" "$combined" "$module"
}

# Log com progresso
log_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    local module="${4:-PROGRESS}"
    
    local percentage=$((current * 100 / total))
    local bar_size=50
    local filled=$((percentage * bar_size / 100))
    local empty=$((bar_size - filled))
    
    local bar
    bar=$(printf "%0.s█" $(seq 1 $filled))
    bar+=$(printf "%0.s░" $(seq 1 $empty))
    
    log "INFO" "[$bar] $percentage% - $message" "$module"
}

# Log de alerta (envia notificações)
log_alert() {
    local level="$1"
    local message="$2"
    local module="${3:-ALERT}"
    
    # Log normal
    log "$level" "$message" "$module"
    
    # Enviar notificações
    if [[ "${NOTIFY_ON_ERROR:-false}" == "true" ]] || [[ "$level" == "CRITICAL" ]]; then
        send_notification "$level" "$message"
    fi
}

# Rotacionar logs
rotate_logs() {
    local max_size="${LOG_MAX_SIZE:-100M}"
    local max_files="${LOG_MAX_FILES:-10}"
    
    # Converter para bytes
    local max_bytes
    case $max_size in
        *K) max_bytes=$((${max_size%K} * 1024)) ;;
        *M) max_bytes=$((${max_size%M} * 1024 * 1024)) ;;
        *G) max_bytes=$((${max_size%G} * 1024 * 1024 * 1024)) ;;
        *) max_bytes=$max_size ;;
    esac
    
    # Verificar cada arquivo de log
    for log_file in "$MAIN_LOG" "$ERROR_LOG" "$DEBUG_LOG" "$AUDIT_LOG" "$PERFORMANCE_LOG"; do
        if [[ -f "$log_file" ]] && [[ $(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null) -gt $max_bytes ]]; then
            # Rotacionar
            local base="${log_file%.*}"
            local ext="${log_file##*.}"
            local rotated="${base}_$(date '+%Y%m%d_%H%M%S').${ext}"
            
            mv "$log_file" "$rotated"
            touch "$log_file"
            
            # Comprimir se configurado
            if [[ "${LOG_COMPRESS:-true}" == "true" ]]; then
                gzip "$rotated"
            fi
            
            log "INFO" "Rotated log file: $log_file" "LOGGING"
        fi
    done
    
    # Limpar arquivos antigos
    find "${LOG_DIR}" -name "*.log*" -type f -mtime +"$max_files" -delete
}

# Exportar funções
export -f log log_performance log_data log_progress log_alert rotate_logs