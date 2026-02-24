#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Task Scheduler
# =============================================================================

# Diretórios
SCHEDULER_DIR="${CONFIG_DIR}/scheduler"
SCHEDULER_JOBS_DIR="${SCHEDULER_DIR}/jobs"
SCHEDULER_LOGS_DIR="${LOG_DIR}/scheduler"
SCHEDULER_PID_FILE="${SCHEDULER_DIR}/scheduler.pid"

# Configurações
SCHEDULER_INTERVAL="${SCHEDULER_INTERVAL:-60}"
SCHEDULER_MAX_JOBS="${SCHEDULER_MAX_JOBS:-10}"
SCHEDULER_RETRY_COUNT="${SCHEDULER_RETRY_COUNT:-3}"
SCHEDULER_RETRY_DELAY="${SCHEDULER_RETRY_DELAY:-300}"

# Inicializar scheduler
init_scheduler() {
    log "INFO" "Initializing task scheduler" "SCHEDULER"
    
    mkdir -p "$SCHEDULER_DIR" "$SCHEDULER_JOBS_DIR" "$SCHEDULER_LOGS_DIR"
    
    # Carregar jobs existentes
    load_scheduled_jobs
}

# Carregar jobs agendados
load_scheduled_jobs() {
    SCHEDULED_JOBS=()
    
    for job_file in "$SCHEDULER_JOBS_DIR"/*.json; do
        if [[ -f "$job_file" ]]; then
            local job_name
            job_name=$(basename "$job_file" .json)
            SCHEDULED_JOBS+=("$job_name")
        fi
    done
    
    log "DEBUG" "Loaded ${#SCHEDULED_JOBS[@]} scheduled jobs" "SCHEDULER"
}

# Adicionar job agendado
add_scheduled_job() {
    local name="$1"
    local schedule="$2"
    local target="$3"
    local module="${4:-full}"
    local config="${5:-{}}"
    
    log "INFO" "Adding scheduled job: $name" "SCHEDULER"
    
    local job_file="${SCHEDULER_JOBS_DIR}/${name}.json"
    
    # Validar schedule (cron format)
    if ! validate_cron_schedule "$schedule"; then
        log "ERROR" "Invalid schedule format: $schedule" "SCHEDULER"
        return 1
    fi
    
    # Criar job
    cat > "$job_file" << EOF
{
    "name": "$name",
    "schedule": "$schedule",
    "target": "$target",
    "module": "$module",
    "config": $config,
    "enabled": true,
    "created": "$(date -Iseconds)",
    "last_run": null,
    "next_run": "$(calculate_next_run "$schedule")",
    "runs": 0,
    "successful_runs": 0,
    "failed_runs": 0
}
EOF
    
    log "SUCCESS" "Job added: $name" "SCHEDULER"
    
    # Recarregar jobs
    load_scheduled_jobs
}

# Remover job agendado
remove_scheduled_job() {
    local name="$1"
    
    log "INFO" "Removing scheduled job: $name" "SCHEDULER"
    
    local job_file="${SCHEDULER_JOBS_DIR}/${name}.json"
    
    if [[ -f "$job_file" ]]; then
        rm -f "$job_file"
        log "SUCCESS" "Job removed: $name" "SCHEDULER"
    else
        log "ERROR" "Job not found: $name" "SCHEDULER"
        return 1
    fi
    
    # Recarregar jobs
    load_scheduled_jobs
}

# Iniciar scheduler (daemon)
start_scheduler() {
    log "INFO" "Starting scheduler daemon" "SCHEDULER"
    
    # Verificar se já está rodando
    if [[ -f "$SCHEDULER_PID_FILE" ]]; then
        local pid
        pid=$(cat "$SCHEDULER_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log "WARNING" "Scheduler already running (PID: $pid)" "SCHEDULER"
            return 1
        fi
    fi
    
    # Iniciar em background
    (
        echo $$ > "$SCHEDULER_PID_FILE"
        
        while true; do
            run_scheduler_cycle
            sleep "$SCHEDULER_INTERVAL"
        done
    ) &
    
    log "SUCCESS" "Scheduler started (PID: $!)" "SCHEDULER"
}

# Parar scheduler
stop_scheduler() {
    log "INFO" "Stopping scheduler daemon" "SCHEDULER"
    
    if [[ -f "$SCHEDULER_PID_FILE" ]]; then
        local pid
        pid=$(cat "$SCHEDULER_PID_FILE")
        kill "$pid" 2>/dev/null
        rm -f "$SCHEDULER_PID_FILE"
        log "SUCCESS" "Scheduler stopped" "SCHEDULER"
    else
        log "WARNING" "Scheduler not running" "SCHEDULER"
    fi
}

# Executar ciclo do scheduler
run_scheduler_cycle() {
    log "DEBUG" "Running scheduler cycle" "SCHEDULER"
    
    local current_time
    current_time=$(date +%s)
    
    # Processar cada job
    for job_name in "${SCHEDULED_JOBS[@]}"; do
        local job_file="${SCHEDULER_JOBS_DIR}/${job_name}.json"
        
        if [[ ! -f "$job_file" ]]; then
            continue
        fi
        
        local job_data
        job_data=$(cat "$job_file")
        
        local enabled
        enabled=$(echo "$job_data" | jq -r '.enabled')
        
        if [[ "$enabled" != "true" ]]; then
            continue
        fi
        
        local next_run
        next_run=$(echo "$job_data" | jq -r '.next_run')
        local next_run_epoch
        next_run_epoch=$(date -d "$next_run" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "$next_run" +%s 2>/dev/null)
        
        if [[ $current_time -ge $next_run_epoch ]]; then
            # Executar job
            execute_scheduled_job "$job_name" &
            
            # Atualizar próximo run
            local schedule
            schedule=$(echo "$job_data" | jq -r '.schedule')
            local new_next_run
            new_next_run=$(calculate_next_run "$schedule")
            
            local runs
            runs=$(echo "$job_data" | jq -r '.runs')
            runs=$((runs + 1))
            
            # Atualizar job
            echo "$job_data" | jq \
                --arg next_run "$new_next_run" \
                --argjson runs "$runs" \
                '.next_run = $next_run | .runs = $runs' > "$job_file"
        fi
    done
}

# Executar job agendado
execute_scheduled_job() {
    local job_name="$1"
    local job_file="${SCHEDULER_JOBS_DIR}/${job_name}.json"
    
    log "INFO" "Executing scheduled job: $job_name" "SCHEDULER"
    
    local job_data
    job_data=$(cat "$job_file")
    
    local target
    target=$(echo "$job_data" | jq -r '.target')
    
    local module
    module=$(echo "$job_data" | jq -r '.module')
    
    local config
    config=$(echo "$job_data" | jq -c '.config')
    
    local log_file="${SCHEDULER_LOGS_DIR}/${job_name}_$(date +%Y%m%d_%H%M%S).log"
    
    # Executar scan
    {
        echo "=== Job Execution: $job_name ==="
        echo "Started: $(date)"
        echo "Target: $target"
        echo "Module: $module"
        echo "Config: $config"
        echo ""
        
        # Executar módulo apropriado
        local start_time
        start_time=$(date +%s)
        
        case "$module" in
            full)
                full_osint_scan "$target" >> "$log_file" 2>&1
                ;;
            recon)
                advanced_subdomain_enum "$target" >> "$log_file" 2>&1
                ;;
            threat)
                threat_intelligence "$target" >> "$log_file" 2>&1
                ;;
            social)
                social_media_intel "$target" >> "$log_file" 2>&1
                ;;
            email)
                email_intelligence "$target" >> "$log_file" 2>&1
                ;;
            *)
                log "ERROR" "Unknown module: $module" "SCHEDULER"
                ;;
        esac
        
        local exit_code=$?
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo ""
        echo "Completed: $(date)"
        echo "Duration: ${duration}s"
        echo "Exit Code: $exit_code"
        
    } >> "$log_file" 2>&1
    
    # Atualizar estatísticas
    if [[ $exit_code -eq 0 ]]; then
        local successful_runs
        successful_runs=$(echo "$job_data" | jq -r '.successful_runs')
        successful_runs=$((successful_runs + 1))
        
        echo "$job_data" | jq \
            --arg last_run "$(date -Iseconds)" \
            --argjson successful_runs "$successful_runs" \
            '.last_run = $last_run | .successful_runs = $successful_runs' > "$job_file"
        
        log "SUCCESS" "Job $job_name completed successfully" "SCHEDULER"
    else
        local failed_runs
        failed_runs=$(echo "$job_data" | jq -r '.failed_runs')
        failed_runs=$((failed_runs + 1))
        
        echo "$job_data" | jq \
            --arg last_run "$(date -Iseconds)" \
            --argjson failed_runs "$failed_runs" \
            '.last_run = $last_run | .failed_runs = $failed_runs' > "$job_file"
        
        log "ERROR" "Job $job_name failed (exit code: $exit_code)" "SCHEDULER"
        
        # Tentar novamente se configurado
        if [[ $failed_runs -lt $SCHEDULER_RETRY_COUNT ]]; then
            log "INFO" "Scheduling retry for job $job_name" "SCHEDULER"
            sleep "$SCHEDULER_RETRY_DELAY"
            execute_scheduled_job "$job_name"
        fi
    fi
}

# Validar formato cron
validate_cron_schedule() {
    local schedule="$1"
    
    # Formato: minuto hora dia mês dia_semana
    local pattern='^(@(annually|yearly|monthly|weekly|daily|hourly|reboot))|(((0?[0-9]|[1-5][0-9]|\*) (0?[0-9]|1[0-9]|2[0-3]|\*) (([1-9]|[12][0-9]|3[01])|\*) (([1-9]|1[012])|\*) (([0-6])|\*)))$'
    
    if [[ "$schedule" =~ $pattern ]]; then
        return 0
    else
        return 1
    fi
}

# Calcular próximo run baseado no cron
calculate_next_run() {
    local schedule="$1"
    
    # Implementação simples - em produção usar lib como 'when'
    case "$schedule" in
        "@hourly")
            date -d "next hour" -Iseconds 2>/dev/null || date -v+1H -Iseconds 2>/dev/null
            ;;
        "@daily")
            date -d "tomorrow 00:00:00" -Iseconds 2>/dev/null || date -v+1d -v0H -v0M -v0S -Iseconds 2>/dev/null
            ;;
        "@weekly")
            date -d "next monday 00:00:00" -Iseconds 2>/dev/null || date -v+1w -v0H -v0M -v0S -Iseconds 2>/dev/null
            ;;
        "@monthly")
            date -d "next month 1 00:00:00" -Iseconds 2>/dev/null || date -v+1m -v1d -v0H -v0M -v0S -Iseconds 2>/dev/null
            ;;
        "@yearly")
            date -d "next year jan 1 00:00:00" -Iseconds 2>/dev/null || date -v+1y -v1m -v1d -v0H -v0M -v0S -Iseconds 2>/dev/null
            ;;
        *)
            # Próximo minuto (simplificado)
            date -d "next minute" -Iseconds 2>/dev/null || date -v+1M -Iseconds 2>/dev/null
            ;;
    esac
}

# Listar jobs
list_jobs() {
    log "INFO" "Listing scheduled jobs" "SCHEDULER"
    
    printf "%-20s %-15s %-30s %-10s %-10s %-10s\n" "NAME" "SCHEDULE" "TARGET" "RUNS" "SUCCESS" "FAILED"
    printf "%s\n" "----------------------------------------------------------------------------------------"
    
    for job_name in "${SCHEDULED_JOBS[@]}"; do
        local job_file="${SCHEDULER_JOBS_DIR}/${job_name}.json"
        
        if [[ -f "$job_file" ]]; then
            local job_data
            job_data=$(cat "$job_file")
            
            local schedule
            schedule=$(echo "$job_data" | jq -r '.schedule')
            
            local target
            target=$(echo "$job_data" | jq -r '.target')
            
            local runs
            runs=$(echo "$job_data" | jq -r '.runs')
            
            local successful
            successful=$(echo "$job_data" | jq -r '.successful_runs')
            
            local failed
            failed=$(echo "$job_data" | jq -r '.failed_runs')
            
            printf "%-20s %-15s %-30s %-10s %-10s %-10s\n" "$job_name" "$schedule" "$target" "$runs" "$successful" "$failed"
        fi
    done
}

# Exportar funções
export -f init_scheduler add_scheduled_job remove_scheduled_job start_scheduler stop_scheduler list_jobs