#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Restore Script
# =============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Diretórios
INSTALL_DIR="${HOME}/cyberghost-osint"
CONFIG_DIR="${HOME}/.cyberghost"
REPORTS_DIR="${HOME}/CyberGhost_Reports"
TEMP_DIR="/tmp/cyberghost_restore_$$"

# Banner
print_banner() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║          CYBERGHOST OSINT ULTIMATE - RESTORE                ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Listar backups disponíveis
list_backups() {
    echo -e "${BLUE}[*] Available backups:${NC}\n"
    
    local backups=()
    
    # Backups em tar.gz
    for backup in "$HOME"/cyberghost_backup_*.tar.gz; do
        if [[ -f "$backup" ]]; then
            backups+=("$backup")
        fi
    done
    
    # Backups em tar.gz.enc (criptografados)
    for backup in "$HOME"/cyberghost_backup_*.tar.gz.enc; do
        if [[ -f "$backup" ]]; then
            backups+=("$backup")
        fi
    done
    
    # Backups em diretório
    for backup in "$HOME"/cyberghost_backup_*/; do
        if [[ -d "$backup" ]]; then
            backups+=("${backup%/}")
        fi
    done
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        echo -e "${RED}[!] No backups found in $HOME${NC}"
        exit 1
    fi
    
    # Mostrar backups com data
    local i=1
    for backup in "${backups[@]}"; do
        local size
        local date
        
        if [[ -f "$backup" ]]; then
            size=$(du -h "$backup" | cut -f1)
            date=$(date -r "$backup" "+%Y-%m-%d %H:%M:%S")
            type="File"
        else
            size=$(du -sh "$backup" | cut -f1)
            date=$(date -r "$backup" "+%Y-%m-%d %H:%M:%S")
            type="Directory"
        fi
        
        echo -e "${GREEN}[$i]${NC} $backup"
        echo -e "    ${CYAN}Size:${NC} $size"
        echo -e "    ${CYAN}Date:${NC} $date"
        echo -e "    ${CYAN}Type:${NC} $type"
        echo ""
        
        ((i++))
    done
    
    BACKUP_LIST=("${backups[@]}")
}

# Selecionar backup
select_backup() {
    echo -e "${YELLOW}Select backup to restore (1-${#BACKUP_LIST[@]}):${NC}"
    read -r selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ $selection -lt 1 ]] || [[ $selection -gt ${#BACKUP_LIST[@]} ]]; then
        echo -e "${RED}[!] Invalid selection${NC}"
        exit 1
    fi
    
    SELECTED_BACKUP="${BACKUP_LIST[$((selection-1))]}"
    echo -e "${GREEN}[✓] Selected: $SELECTED_BACKUP${NC}"
}

# Descriptografar backup
decrypt_backup() {
    if [[ "$SELECTED_BACKUP" != *.enc ]]; then
        return
    fi
    
    echo -e "${BLUE}[*] Backup is encrypted${NC}"
    echo -n "Enter decryption password: "
    read -s password
    echo
    
    local decrypted_file="${SELECTED_BACKUP%.enc}"
    
    openssl enc -aes-256-cbc -d -in "$SELECTED_BACKUP" -out "$decrypted_file" -pass pass:"$password" 2>/dev/null
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}[!] Decryption failed. Wrong password?${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}[✓] Backup decrypted: $decrypted_file${NC}"
    SELECTED_BACKUP="$decrypted_file"
}

# Extrair backup
extract_backup() {
    if [[ -d "$SELECTED_BACKUP" ]]; then
        # Já é diretório
        RESTORE_DIR="$SELECTED_BACKUP"
        echo -e "${GREEN}[✓] Using backup directory: $RESTORE_DIR${NC}"
    elif [[ "$SELECTED_BACKUP" == *.tar.gz ]]; then
        # Arquivo tar.gz
        echo -e "${BLUE}[*] Extracting backup...${NC}"
        
        mkdir -p "$TEMP_DIR"
        tar -xzf "$SELECTED_BACKUP" -C "$TEMP_DIR"
        
        # Encontrar diretório extraído
        RESTORE_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "cyberghost_backup_*" | head -1)
        
        if [[ -z "$RESTORE_DIR" ]]; then
            echo -e "${RED}[!] Could not find extracted backup${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}[✓] Backup extracted to: $RESTORE_DIR${NC}"
    else
        echo -e "${RED}[!] Unknown backup format${NC}"
        exit 1
    fi
}

# Verificar manifesto
verify_manifest() {
    echo -e "${BLUE}[*] Verifying manifest...${NC}"
    
    if [[ -f "${RESTORE_DIR}/manifest.json" ]]; then
        local version
        version=$(jq -r '.version' "${RESTORE_DIR}/manifest.json")
        local date
        date=$(jq -r '.backup_date' "${RESTORE_DIR}/manifest.json")
        
        echo -e "${GREEN}[✓] Backup version: $version${NC}"
        echo -e "${GREEN}[✓] Backup date: $date${NC}"
        
        # Verificar compatibilidade
        if [[ -f "${INSTALL_DIR}/VERSION" ]]; then
            local current_version
            current_version=$(cat "${INSTALL_DIR}/VERSION")
            
            if [[ "$version" != "$current_version" ]]; then
                echo -e "${YELLOW}[!] Version mismatch: backup=$version, current=$current_version${NC}"
                echo -e "${YELLOW}Continue anyway? (y/N)${NC}"
                read -r answer
                if [[ ! "$answer" =~ ^[Yy]$ ]]; then
                    exit 1
                fi
            fi
        fi
    else
        echo -e "${YELLOW}[!] No manifest found${NC}"
    fi
}

# Restaurar configurações
restore_config() {
    echo -e "${BLUE}[*] Restoring configuration...${NC}"
    
    if [[ -d "${RESTORE_DIR}/config" ]]; then
        # Backup da configuração atual
        if [[ -d "$CONFIG_DIR" ]]; then
            mv "$CONFIG_DIR" "${CONFIG_DIR}.old"
        fi
        
        cp -r "${RESTORE_DIR}/config" "$CONFIG_DIR"
        echo -e "${GREEN}[✓] Configuration restored${NC}"
    else
        echo -e "${YELLOW}[!] No configuration in backup${NC}"
    fi
}

# Restaurar relatórios
restore_reports() {
    echo -e "${BLUE}[*] Restoring reports...${NC}"
    
    if [[ -d "${RESTORE_DIR}/reports" ]]; then
        # Mesclar com relatórios existentes
        mkdir -p "$REPORTS_DIR"
        cp -rn "${RESTORE_DIR}/reports"/* "$REPORTS_DIR"/ 2>/dev/null || true
        echo -e "${GREEN}[✓] Reports restored${NC}"
    else
        echo -e "${YELLOW}[!] No reports in backup${NC}"
    fi
}

# Restaurar bancos de dados
restore_databases() {
    echo -e "${BLUE}[*] Restoring databases...${NC}"
    
    if [[ -f "${RESTORE_DIR}/cyberghost.db" ]]; then
        cp "${RESTORE_DIR}/cyberghost.db" "$CONFIG_DIR/"
        echo -e "${GREEN}[✓] SQLite database restored${NC}"
    fi
    
    if [[ -d "${RESTORE_DIR}/databases" ]]; then
        mkdir -p "${INSTALL_DIR}/data/databases"
        cp -rn "${RESTORE_DIR}/databases"/* "${INSTALL_DIR}/data/databases"/ 2>/dev/null || true
        echo -e "${GREEN}[✓] Data databases restored${NC}"
    fi
}

# Restaurar wordlists
restore_wordlists() {
    echo -e "${BLUE}[*] Restoring wordlists...${NC}"
    
    if [[ -d "${RESTORE_DIR}/wordlists" ]]; then
        mkdir -p "${INSTALL_DIR}/data/wordlists"
        cp -rn "${RESTORE_DIR}/wordlists"/* "${INSTALL_DIR}/data/wordlists"/ 2>/dev/null || true
        echo -e "${GREEN}[✓] Wordlists restored${NC}"
    elif [[ -f "${RESTORE_DIR}/wordlists.txt" ]]; then
        echo -e "${YELLOW}[!] Wordlists index found. Wordlists need to be redownloaded.${NC}"
        echo -e "${YELLOW}Run 'cg update' to download wordlists.${NC}"
    else
        echo -e "${YELLOW}[!] No wordlists in backup${NC}"
    fi
}

# Restaurar logs
restore_logs() {
    echo -e "${BLUE}[*] Restoring logs...${NC}"
    
    if [[ -d "${RESTORE_DIR}/logs" ]]; then
        mkdir -p "${INSTALL_DIR}/logs"
        cp -rn "${RESTORE_DIR}/logs"/* "${INSTALL_DIR}/logs"/ 2>/dev/null || true
        echo -e "${GREEN}[✓] Logs restored${NC}"
    else
        echo -e "${YELLOW}[!] No logs in backup${NC}"
    fi
}

# Limpar
cleanup() {
    echo -e "${BLUE}[*] Cleaning up...${NC}"
    
    rm -rf "$TEMP_DIR"
    
    if [[ -d "${CONFIG_DIR}.old" ]]; then
        echo -e "${YELLOW}[!] Old configuration saved at: ${CONFIG_DIR}.old${NC}"
    fi
    
    echo -e "${GREEN}[✓] Cleanup completed${NC}"
}

# Função principal
main() {
    print_banner
    
    echo -e "\n${YELLOW}This will restore a backup of CYBERGHOST OSINT${NC}"
    echo -e "${YELLOW}Current installation may be overwritten${NC}\n"
    
    list_backups
    select_backup
    decrypt_backup
    extract_backup
    verify_manifest
    
    echo -e "\n${YELLOW}Proceed with restore? (y/N)${NC}"
    read -r answer
    
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Restore cancelled${NC}"
        cleanup
        exit 0
    fi
    
    echo -e "\n${BLUE}[*] Starting restore...${NC}\n"
    
    restore_config
    restore_reports
    restore_databases
    restore_wordlists
    restore_logs
    
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                 RESTORE COMPLETED SUCCESSFULLY!                ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e ""
    echo -e "${CYAN}Restored from: $SELECTED_BACKUP${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    
    cleanup
}

# Executar
main "$@"