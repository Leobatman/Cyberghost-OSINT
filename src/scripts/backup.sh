#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Backup Script
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
BACKUP_DIR="${HOME}/cyberghost_backup_$(date +%Y%m%d_%H%M%S)"
TEMP_DIR="/tmp/cyberghost_backup_$$"

# Configurações
COMPRESS="${1:-true}"
ENCRYPT="${2:-false}"
ENCRYPT_PASSWORD=""

# Banner
print_banner() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║           CYBERGHOST OSINT ULTIMATE - BACKUP                ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Verificar diretórios
check_directories() {
    echo -e "${BLUE}[*] Checking directories...${NC}"
    
    local missing=0
    
    if [[ ! -d "$INSTALL_DIR" ]]; then
        echo -e "${YELLOW}[!] Installation directory not found: $INSTALL_DIR${NC}"
        missing=1
    fi
    
    if [[ ! -d "$CONFIG_DIR" ]]; then
        echo -e "${YELLOW}[!] Config directory not found: $CONFIG_DIR${NC}"
        missing=1
    fi
    
    if [[ ! -d "$REPORTS_DIR" ]]; then
        echo -e "${YELLOW}[!] Reports directory not found: $REPORTS_DIR${NC}"
        missing=1
    fi
    
    if [[ $missing -eq 1 ]]; then
        echo -e "${YELLOW}[!] Some directories are missing. Backup may be incomplete.${NC}"
        echo -e "${YELLOW}Continue anyway? (y/N)${NC}"
        read -r answer
        if [[ ! "$answer" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Criar diretório de backup
create_backup_dir() {
    echo -e "${BLUE}[*] Creating backup directory...${NC}"
    
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$TEMP_DIR"
    
    echo -e "${GREEN}[✓] Backup directory: $BACKUP_DIR${NC}"
}

# Backup de configurações
backup_config() {
    echo -e "${BLUE}[*] Backing up configuration...${NC}"
    
    if [[ -d "$CONFIG_DIR" ]]; then
        cp -r "$CONFIG_DIR" "${BACKUP_DIR}/config"
        echo -e "${GREEN}[✓] Config backed up${NC}"
    else
        echo -e "${YELLOW}[!] Config directory not found, skipping${NC}"
    fi
}

# Backup de relatórios
backup_reports() {
    echo -e "${BLUE}[*] Backing up reports...${NC}"
    
    if [[ -d "$REPORTS_DIR" ]]; then
        cp -r "$REPORTS_DIR" "${BACKUP_DIR}/reports"
        echo -e "${GREEN}[✓] Reports backed up${NC}"
    else
        echo -e "${YELLOW}[!] Reports directory not found, skipping${NC}"
    fi
}

# Backup de bancos de dados
backup_databases() {
    echo -e "${BLUE}[*] Backing up databases...${NC}"
    
    local db_found=false
    
    # SQLite database
    if [[ -f "${CONFIG_DIR}/cyberghost.db" ]]; then
        sqlite3 "${CONFIG_DIR}/cyberghost.db" ".backup '${BACKUP_DIR}/cyberghost.db'"
        echo -e "${GREEN}[✓] SQLite database backed up${NC}"
        db_found=true
    fi
    
    # Outros bancos
    if [[ -d "${INSTALL_DIR}/data/databases" ]]; then
        cp -r "${INSTALL_DIR}/data/databases" "${BACKUP_DIR}/databases"
        echo -e "${GREEN}[✓] Data databases backed up${NC}"
        db_found=true
    fi
    
    if [[ "$db_found" == "false" ]]; then
        echo -e "${YELLOW}[!] No databases found${NC}"
    fi
}

# Backup de wordlists
backup_wordlists() {
    echo -e "${BLUE}[*] Backing up wordlists...${NC}"
    
    if [[ -d "${INSTALL_DIR}/data/wordlists" ]]; then
        # Criar lista de wordlists (não copiar arquivos grandes)
        find "${INSTALL_DIR}/data/wordlists" -type f -name "*.txt" -exec basename {} \; > "${BACKUP_DIR}/wordlists.txt"
        echo -e "${GREEN}[✓] Wordlists index created${NC}"
        
        # Opcionalmente copiar wordlists pequenas
        local size=0
        while IFS= read -r file; do
            file_size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
            size=$((size + file_size))
        done < <(find "${INSTALL_DIR}/data/wordlists" -type f -name "*.txt")
        
        size=$((size / 1024 / 1024))  # MB
        
        if [[ $size -gt 100 ]]; then
            echo -e "${YELLOW}[!] Wordlists are large (${size}MB). Include in backup? (y/N)${NC}"
            read -r answer
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                cp -r "${INSTALL_DIR}/data/wordlists" "${BACKUP_DIR}/wordlists"
                echo -e "${GREEN}[✓] Wordlists backed up${NC}"
            fi
        else
            cp -r "${INSTALL_DIR}/data/wordlists" "${BACKUP_DIR}/wordlists"
            echo -e "${GREEN}[✓] Wordlists backed up${NC}"
        fi
    fi
}

# Backup de logs
backup_logs() {
    echo -e "${BLUE}[*] Backing up logs...${NC}"
    
    if [[ -d "${INSTALL_DIR}/logs" ]]; then
        cp -r "${INSTALL_DIR}/logs" "${BACKUP_DIR}/logs"
        echo -e "${GREEN}[✓] Logs backed up${NC}"
    else
        echo -e "${YELLOW}[!] Logs directory not found, skipping${NC}"
    fi
}

# Criar manifesto
create_manifest() {
    echo -e "${BLUE}[*] Creating manifest...${NC}"
    
    cat > "${BACKUP_DIR}/manifest.json" << EOF
{
    "backup_date": "$(date -Iseconds)",
    "version": "$(cat ${INSTALL_DIR}/VERSION 2>/dev/null || echo 'unknown')",
    "hostname": "$(hostname)",
    "user": "$(whoami)",
    "contents": {
        "config": $(if [[ -d "${BACKUP_DIR}/config" ]]; then echo "true"; else echo "false"; fi),
        "reports": $(if [[ -d "${BACKUP_DIR}/reports" ]]; then echo "true"; else echo "false"; fi),
        "databases": $(if [[ -f "${BACKUP_DIR}/cyberghost.db" ]] || [[ -d "${BACKUP_DIR}/databases" ]]; then echo "true"; else echo "false"; fi),
        "wordlists": $(if [[ -d "${BACKUP_DIR}/wordlists" ]]; then echo "true"; else echo "true (index)"; fi),
        "logs": $(if [[ -d "${BACKUP_DIR}/logs" ]]; then echo "true"; else echo "false"; fi)
    },
    "size": $(du -sb "$BACKUP_DIR" | cut -f1)
}
EOF
    
    echo -e "${GREEN}[✓] Manifest created${NC}"
}

# Comprimir backup
compress_backup() {
    if [[ "$COMPRESS" != "true" ]]; then
        return
    fi
    
    echo -e "${BLUE}[*] Compressing backup...${NC}"
    
    cd "$(dirname "$BACKUP_DIR")"
    local base_name=$(basename "$BACKUP_DIR")
    
    tar -czf "${base_name}.tar.gz" "$base_name"
    
    if [[ -f "${base_name}.tar.gz" ]]; then
        rm -rf "$BACKUP_DIR"
        BACKUP_FILE="$(pwd)/${base_name}.tar.gz"
        echo -e "${GREEN}[✓] Backup compressed: ${BACKUP_FILE}${NC}"
    fi
}

# Criptografar backup
encrypt_backup() {
    if [[ "$ENCRYPT" != "true" ]]; then
        return
    fi
    
    echo -e "${BLUE}[*] Encrypting backup...${NC}"
    
    if [[ -z "$ENCRYPT_PASSWORD" ]]; then
        echo -n "Enter encryption password: "
        read -s password
        echo
        echo -n "Confirm password: "
        read -s password2
        echo
        
        if [[ "$password" != "$password2" ]]; then
            echo -e "${RED}[!] Passwords do not match${NC}"
            return 1
        fi
        
        ENCRYPT_PASSWORD="$password"
    fi
    
    if [[ -f "$BACKUP_FILE" ]]; then
        openssl enc -aes-256-cbc -salt -in "$BACKUP_FILE" -out "${BACKUP_FILE}.enc" -pass pass:"$ENCRYPT_PASSWORD"
        
        if [[ -f "${BACKUP_FILE}.enc" ]]; then
            rm -f "$BACKUP_FILE"
            BACKUP_FILE="${BACKUP_FILE}.enc"
            echo -e "${GREEN}[✓] Backup encrypted: ${BACKUP_FILE}${NC}"
            
            # Salvar hash da senha
            echo -n "$ENCRYPT_PASSWORD" | sha256sum > "${BACKUP_FILE}.keyhash"
            echo -e "${YELLOW}[!] Key hash saved to: ${BACKUP_FILE}.keyhash${NC}"
        fi
    else
        echo -e "${RED}[!] Backup file not found for encryption${NC}"
    fi
}

# Verificar integridade
verify_backup() {
    echo -e "${BLUE}[*] Verifying backup integrity...${NC}"
    
    if [[ -f "$BACKUP_FILE" ]]; then
        if [[ "$BACKUP_FILE" == *.enc ]]; then
            echo -e "${YELLOW}[!] Encrypted backup, cannot verify contents${NC}"
        elif [[ "$BACKUP_FILE" == *.tar.gz ]]; then
            tar -tzf "$BACKUP_FILE" > /dev/null
            echo -e "${GREEN}[✓] Backup integrity verified${NC}"
        fi
    elif [[ -d "$BACKUP_DIR" ]]; then
        echo -e "${GREEN}[✓] Backup directory verified${NC}"
    else
        echo -e "${RED}[!] Backup not found${NC}"
        return 1
    fi
}

# Função principal
main() {
    print_banner
    
    echo -e "\n${YELLOW}This will create a backup of your CYBERGHOST installation${NC}\n"
    
    check_directories
    create_backup_dir
    
    echo -e "\n${BLUE}[*] Starting backup...${NC}\n"
    
    backup_config
    backup_reports
    backup_databases
    backup_wordlists
    backup_logs
    create_manifest
    
    compress_backup
    encrypt_backup
    verify_backup
    
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                 BACKUP COMPLETED SUCCESSFULLY!                 ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e ""
    echo -e "${CYAN}Backup location: ${BACKUP_FILE:-$BACKUP_DIR}${NC}"
    echo -e "${CYAN}Backup size: $(du -sh ${BACKUP_FILE:-$BACKUP_DIR} | cut -f1)${NC}"
    echo -e "${CYAN}Manifest: ${BACKUP_DIR}/manifest.json${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    
    # Limpar
    rm -rf "$TEMP_DIR"
}

# Executar
main "$@"