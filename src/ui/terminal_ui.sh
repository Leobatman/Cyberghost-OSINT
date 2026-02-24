#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Terminal UI
# =============================================================================

# Carregar cores e animações
source "${PROJECT_ROOT}/src/lib/colors.sh"
source "${PROJECT_ROOT}/src/lib/animations.sh"

# Variáveis de UI
UI_WIDTH=80
UI_PROGRESS_CHAR="█"
UI_EMPTY_CHAR="░"

# Inicializar UI
init_terminal_ui() {
    # Verificar suporte a cores
    if [[ -t 1 ]] && [[ "$TERM" != "dumb" ]]; then
        USE_COLORS=true
    else
        USE_COLORS=false
    fi
    
    # Verificar tamanho do terminal
    if [[ -t 1 ]]; then
        UI_WIDTH=$(tput cols 2>/dev/null || echo 80)
    fi
    
    # Configurar trap para restaurar cursor
    trap restore_cursor EXIT INT TERM
}

# Restaurar cursor
restore_cursor() {
    echo -en "\033[?25h"
    tput cnorm 2>/dev/null
}

# Limpar linha
clear_line() {
    echo -en "\r\033[K"
}

# Mover cursor
move_cursor() {
    local row="$1"
    local col="${2:-0}"
    
    echo -en "\033[${row};${col}H"
}

# Salvar posição do cursor
save_cursor() {
    echo -en "\033[s"
}

# Restaurar posição do cursor
restore_cursor_pos() {
    echo -en "\033[u"
}

# Ocultar cursor
hide_cursor() {
    echo -en "\033[?25l"
}

# Mostrar cursor
show_cursor() {
    echo -en "\033[?25h"
}

# Desenhar linha horizontal
draw_line() {
    local char="${1:--}"
    local width="${2:-$UI_WIDTH}"
    
    printf '%*s' "$width" | tr ' ' "$char"
    echo
}

# Desenhar caixa
draw_box() {
    local title="$1"
    local width="${2:-$UI_WIDTH}"
    local padding=2
    
    local title_len=${#title}
    local box_width=$((width - 4))
    
    # Linha superior
    echo -n "╔"
    printf '═%.0s' $(seq 1 $box_width)
    echo "╗"
    
    # Linha do título
    echo -n "║"
    if [[ -n "$title" ]]; then
        local left_padding=$(( (box_width - title_len) / 2 ))
        local right_padding=$((box_width - title_len - left_padding))
        
        printf '%*s' $left_padding ''
        echo -n "$title"
        printf '%*s' $right_padding ''
    else
        printf '%*s' $box_width ''
    fi
    echo "║"
    
    # Linha inferior
    echo -n "╚"
    printf '═%.0s' $(seq 1 $box_width)
    echo "╝"
}

# Desenhar tabela
draw_table() {
    local headers=("$@")
    local data="${headers[-1]}"
    unset 'headers[-1]'
    
    # Calcular larguras das colunas
    local col_widths=()
    for header in "${headers[@]}"; do
        col_widths+=(${#header})
    done
    
    # Atualizar larguras baseado nos dados
    while IFS= read -r row; do
        IFS='|' read -ra fields <<< "$row"
        for i in "${!fields[@]}"; do
            local field_len=${#fields[$i]}
            if [[ $field_len -gt ${col_widths[$i]:-0} ]]; then
                col_widths[$i]=$field_len
            fi
        done
    done <<< "$data"
    
    # Adicionar padding
    for i in "${!col_widths[@]}"; do
        col_widths[$i]=$((col_widths[$i] + 2))
    done
    
    # Linha superior
    echo -n "┌"
    for width in "${col_widths[@]}"; do
        printf '─%.0s' $(seq 1 $width)
        echo -n "┬"
    done
    echo -e "\b┐"
    
    # Headers
    echo -n "│"
    for i in "${!headers[@]}"; do
        local header="${headers[$i]}"
        local width="${col_widths[$i]}"
        printf " %-*s │" $((width - 2)) "$header"
    done
    echo
    
    # Linha divisória
    echo -n "├"
    for width in "${col_widths[@]}"; do
        printf '─%.0s' $(seq 1 $width)
        echo -n "┼"
    done
    echo -e "\b┤"
    
    # Dados
    while IFS= read -r row; do
        IFS='|' read -ra fields <<< "$row"
        echo -n "│"
        for i in "${!fields[@]}"; do
            local field="${fields[$i]}"
            local width="${col_widths[$i]}"
            printf " %-*s │" $((width - 2)) "$field"
        done
        echo
    done <<< "$data"
    
    # Linha inferior
    echo -n "└"
    for width in "${col_widths[@]}"; do
        printf '─%.0s' $(seq 1 $width)
        echo -n "┴"
    done
    echo -e "\b┘"
}

# Menu interativo
show_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    local selected=0
    local key
    
    hide_cursor
    
    while true; do
        clear
        draw_box "$title"
        echo
        
        for i in "${!options[@]}"; do
            if [[ $i -eq $selected ]]; then
                echo -e "${GREEN}→ ${options[$i]}${NC}"
            else
                echo "  ${options[$i]}"
            fi
        done
        
        echo
        echo -e "${CYAN}Use ↑/↓ to navigate, Enter to select, Esc to cancel${NC}"
        
        # Ler tecla
        read -rsn1 key
        if [[ "$key" == $'\x1b' ]]; then
            read -rsn2 key
            case "$key" in
                '[A') # Seta para cima
                    if [[ $selected -gt 0 ]]; then
                        ((selected--))
                    fi
                    ;;
                '[B') # Seta para baixo
                    if [[ $selected -lt $((${#options[@]} - 1)) ]]; then
                        ((selected++))
                    fi
                    ;;
            esac
        elif [[ "$key" == "" ]]; then # Enter
            show_cursor
            return $selected
        fi
    done
}

# Input com validação
prompt_input() {
    local prompt="$1"
    local default="$2"
    local validator="$3"
    
    local input
    
    while true; do
        echo -n "$prompt"
        if [[ -n "$default" ]]; then
            echo -n " [$default]: "
        else
            echo -n ": "
        fi
        
        read -r input
        
        if [[ -z "$input" ]] && [[ -n "$default" ]]; then
            input="$default"
        fi
        
        if [[ -n "$validator" ]]; then
            if eval "$validator \"$input\""; then
                break
            else
                echo -e "${RED}Invalid input. Please try again.${NC}"
            fi
        else
            break
        fi
    done
    
    echo "$input"
}

# Confirmar ação
confirm_action() {
    local prompt="$1"
    local default="${2:-n}"
    
    local yn
    read -p "$prompt (y/N): " yn
    
    case "$yn" in
        [Yy]*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Barra de progresso
show_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    
    local percent=$((current * 100 / total))
    local filled=$((percent * UI_WIDTH / 100))
    local empty=$((UI_WIDTH - filled))
    
    printf "\r${message} ["
    printf "${UI_PROGRESS_CHAR}%.0s" $(seq 1 $filled)
    printf "${UI_EMPTY_CHAR}%.0s" $(seq 1 $empty)
    printf "] %d%%" $percent
}

# Spinner animado
show_spinner() {
    local pid="$1"
    local message="${2:-Processing...}"
    
    local spin='-\|/'
    local i=0
    
    hide_cursor
    
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf "\r${message} ${spin:$i:1}"
        sleep 0.1
    done
    
    printf "\r${message} ${GREEN}✓${NC}\n"
    show_cursor
}

# Exibir notificação
show_notification() {
    local type="$1"
    local message="$2"
    
    case "$type" in
        success)
            echo -e "${GREEN}✓${NC} $message"
            ;;
        error)
            echo -e "${RED}✗${NC} $message"
            ;;
        warning)
            echo -e "${YELLOW}⚠${NC} $message"
            ;;
        info)
            echo -e "${CYAN}ℹ${NC} $message"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Exibir painel de status
show_status_panel() {
    local title="$1"
    shift
    local items=("$@")
    
    draw_box "$title"
    
    for item in "${items[@]}"; do
        IFS=':' read -r label value status <<< "$item"
        
        case "$status" in
            success)
                echo -e " ${GREEN}●${NC} $label: $value"
                ;;
            error)
                echo -e " ${RED}●${NC} $label: $value"
                ;;
            warning)
                echo -e " ${YELLOW}●${NC} $label: $value"
                ;;
            info)
                echo -e " ${CYAN}●${NC} $label: $value"
                ;;
            *)
                echo -e " ${WHITE}●${NC} $label: $value"
                ;;
        esac
    done
}

# Exibir resultados em formato de árvore
show_tree() {
    local data="$1"
    local prefix="${2:-}"
    
    while IFS= read -r line; do
        if [[ "$line" == *"├──"* ]] || [[ "$line" == *"└──"* ]]; then
            echo "${prefix}${line}"
        else
            echo "${prefix}├── ${line}"
        fi
    done <<< "$data"
}

# Paginação
show_paginated() {
    local data="$1"
    local lines_per_page="${2:-10}"
    
    local lines=()
    while IFS= read -r line; do
        lines+=("$line")
    done <<< "$data"
    
    local total_lines=${#lines[@]}
    local current_page=0
    local total_pages=$(( (total_lines + lines_per_page - 1) / lines_per_page ))
    
    while true; do
        clear
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        
        local start=$((current_page * lines_per_page))
        local end=$((start + lines_per_page))
        
        for ((i=start; i<end && i<total_lines; i++)); do
            echo "${lines[$i]}"
        done
        
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "Page $((current_page + 1)) of $total_pages (${total_lines} items)"
        echo
        echo -e "${WHITE}[N]ext | [P]revious | [G]oto | [Q]uit${NC}"
        
        read -rsn1 key
        case "$key" in
            n|N)
                if [[ $current_page -lt $((total_pages - 1)) ]]; then
                    ((current_page++))
                fi
                ;;
            p|P)
                if [[ $current_page -gt 0 ]]; then
                    ((current_page--))
                fi
                ;;
            g|G)
                echo -n "Go to page: "
                read -r page
                if [[ "$page" =~ ^[0-9]+$ ]] && [[ $page -ge 1 ]] && [[ $page -le $total_pages ]]; then
                    current_page=$((page - 1))
                fi
                ;;
            q|Q)
                break
                ;;
        esac
    done
}

# Exibir ajuda
show_help() {
    cat << EOF
${CYBERGHOST_BANNER}

${GREEN}USAGE:${NC}
    cg [command] [options]

${GREEN}COMMANDS:${NC}
    ${WHITE}scan${NC} <target>      Run OSINT scan on target
    ${WHITE}report${NC} <id>        Generate report from scan ID
    ${WHITE}list${NC}               List all scans
    ${WHITE}config${NC}              Configure settings
    ${WHITE}update${NC}              Update tools and databases
    ${WHITE}help${NC}                Show this help

${GREEN}OPTIONS:${NC}
    ${WHITE}-o, --output${NC} <dir>  Output directory
    ${WHITE}-f, --format${NC} <fmt>   Report format (html|pdf|json)
    ${WHITE}-v, --verbose${NC}        Verbose output
    ${WHITE}-q, --quiet${NC}          Quiet mode
    ${WHITE}-h, --help${NC}           Show help

${GREEN}EXAMPLES:${NC}
    ${CYAN}cg scan example.com${NC}
    ${CYAN}cg scan 192.168.1.1 -o ./reports${NC}
    ${CYAN}cg list${NC}
    ${CYAN}cg report 12345 -f pdf${NC}

${GREEN}For more information, visit: ${BLUE}https://cyberghost-osint.com${NC}
EOF
}

# Exportar funções
export -f init_terminal_ui show_menu prompt_input confirm_action show_progress show_spinner show_notification show_status_panel show_tree show_paginated show_help