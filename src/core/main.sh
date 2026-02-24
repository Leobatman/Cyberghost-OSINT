#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Main Entry Point
# =============================================================================
# Desenvolvido por: Leonardo Pereira Pinheiro | CyberGhost
# Versão: 7.0 | Código: Shadow Warrior
# Licença: GPL-3.0
# =============================================================================

# Configurações globais
set -euo pipefail
IFS=$'\n\t'

# Diretório base
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Carregar core modules
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/logging.sh"
source "${SCRIPT_DIR}/utils.sh"
source "${SCRIPT_DIR}/database.sh"
source "${SCRIPT_DIR}/api_manager.sh"
source "${SCRIPT_DIR}/report_generator.sh"

# Trap para limpeza
trap cleanup EXIT INT TERM

cleanup() {
    log "info" "Cleaning up resources..." "MAIN"
    
    # Finalizar processos em background
    jobs -p | xargs -r kill
    
    # Salvar estado
    save_session_state
    
    # Remover arquivos temporários se configurado
    if [[ "${CLEANUP_TEMP:-true}" == "true" ]]; then
        rm -rf "${TEMP_DIR:?}"/*
    fi
    
    log "success" "Cleanup completed" "MAIN"
}

# Inicialização
init_cyberghost() {
    local start_time
    start_time=$(date +%s)
    
    # Criar diretórios necessários
    mkdir -p "${LOG_DIR}" "${TEMP_DIR}" "${REPORTS_DIR}" "${CONFIG_DIR}"
    
    # Inicializar logging
    init_logging
    
    # Carregar configurações
    load_config
    
    # Carregar APIs
    load_api_keys
    
    # Verificar dependências
    check_dependencies
    
    # Inicializar banco de dados
    init_database
    
    # Mostrar banner
    print_banner
    
    log "info" "CYBERGHOST OSINT initialized" "MAIN"
    log "debug" "Startup time: $(( $(date +%s) - start_time ))s" "MAIN"
}

# Verificação de dependências
check_dependencies() {
    local deps=("curl" "wget" "jq" "nmap" "whois" "dig" "python3" "git")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "warning" "Missing dependencies: ${missing[*]}" "MAIN"
        log "info" "Run './scripts/install.sh' to install dependencies" "MAIN"
    fi
}

# Processar argumentos da linha de comando
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--target)
                TARGET="$2"
                shift 2
                ;;
            -m|--module)
                MODULES+=("$2")
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -f|--format)
                REPORT_FORMAT="$2"
                shift 2
                ;;
            --api-key)
                API_KEY="$2"
                shift 2
                ;;
            --proxy)
                PROXY="$2"
                shift 2
                ;;
            --tor)
                USE_TOR=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --debug)
                DEBUG=true
                shift
                ;;
            --quiet)
                QUIET=true
                shift
                ;;
            --no-color)
                NO_COLOR=true
                shift
                ;;
            --scheduled)
                SCHEDULED=true
                shift
                ;;
            --daemon)
                DAEMON_MODE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "CYBERGHOST OSINT v${VERSION}"
                exit 0
                ;;
            *)
                log "error" "Unknown option: $1" "MAIN"
                show_help
                exit 1
                ;;
        esac
    done
}

# Modo interativo
interactive_mode() {
    while true; do
        clear
        show_menu
        
        read -rp "Select option: " choice
        
        case $choice in
            1) run_full_scan ;;
            2) run_recon_scan ;;
            3) run_social_media_scan ;;
            4) run_email_scan ;;
            5) run_github_scan ;;
            6) run_threat_scan ;;
            7) run_geoint_scan ;;
            8) run_mobile_scan ;;
            9) run_business_scan ;;
            10) install_tools ;;
            11) view_reports ;;
            12) show_help ;;
            13) configure_settings ;;
            14) 
                log "info" "Exiting..." "MAIN"
                exit 0
                ;;
            *)
                log "warning" "Invalid option" "MAIN"
                sleep 1
                ;;
        esac
    done
}

# Executar scan completo
run_full_scan() {
    read -rp "Enter target: " target
    
    if [[ -z "$target" ]]; then
        log "error" "Target cannot be empty" "MAIN"
        return 1
    fi
    
    log "hack" "Starting FULL OSINT scan on: $target" "MAIN"
    
    # Criar diretório do scan
    local scan_dir
    scan_dir="${REPORTS_DIR}/scan_${target}_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$scan_dir"
    
    # Carregar módulos
    source "${SCRIPT_DIR}/../modules/module_loader.sh"
    
    # Executar todos os módulos
    run_all_modules "$target" "$scan_dir"
    
    # Gerar relatório
    generate_report "$scan_dir" "$target"
    
    log "success" "Scan completed! Report saved to: $scan_dir" "MAIN"
    
    read -rp "Press Enter to continue..."
}

# Modo daemon (serviço contínuo)
daemon_mode() {
    log "info" "Starting CYBERGHOST in daemon mode" "DAEMON"
    
    # Fork para background
    if [[ "$1" != "--forked" ]]; then
        "$0" "$@" --forked &
        exit 0
    fi
    
    # Loop principal do daemon
    while true; do
        # Verificar tarefas agendadas
        check_scheduled_tasks
        
        # Monitorar fila de scans
        process_scan_queue
        
        # Verificar atualizações
        check_updates
        
        # Coletar métricas
        collect_metrics
        
        sleep "${DAEMON_INTERVAL:-60}"
    done
}

# Ponto de entrada principal
main() {
    local start_time
    start_time=$(date +%s)
    
    # Inicializar
    init_cyberghost
    
    # Parse arguments
    if [[ $# -gt 0 ]]; then
        parse_arguments "$@"
    fi
    
    # Modo daemon
    if [[ "${DAEMON_MODE:-false}" == "true" ]]; then
        daemon_mode "$@"
        exit 0
    fi
    
    # Modo interativo ou comando único
    if [[ -n "${TARGET:-}" ]]; then
        # Modo comando único
        if [[ ${#MODULES[@]} -eq 0 ]]; then
            MODULES=("all")
        fi
        
        run_scan "$TARGET" "${MODULES[@]}"
    else
        # Modo interativo
        interactive_mode
    fi
    
    local end_time
    end_time=$(date +%s)
    log "info" "Total execution time: $((end_time - start_time))s" "MAIN"
}

# Executar se não estiver sendo sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi