#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Update Script
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
BACKUP_DIR="${HOME}/cyberghost_backup_$(date +%Y%m%d_%H%M%S)"
CONFIG_DIR="${HOME}/.cyberghost"
TEMP_DIR="/tmp/cyberghost_update_$$"

# Banner
print_banner() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║           CYBERGHOST OSINT ULTIMATE - UPDATE                ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Verificar versão atual
check_current_version() {
    local version_file="${INSTALL_DIR}/VERSION"
    
    if [[ -f "$version_file" ]]; then
        CURRENT_VERSION=$(cat "$version_file")
        echo -e "${GREEN}[+] Current version: ${CURRENT_VERSION}${NC}"
    else
        echo -e "${YELLOW}[!] No version file found${NC}"
        CURRENT_VERSION="0.0.0"
    fi
}

# Verificar última versão
check_latest_version() {
    echo -e "${BLUE}[*] Checking latest version...${NC}"
    
    # Tentar GitHub
    LATEST_VERSION=$(curl -s https://api.github.com/repos/cyberghost/cyberghost-osint/releases/latest 2>/dev/null | jq -r '.tag_name' 2>/dev/null)
    
    if [[ -z "$LATEST_VERSION" ]] || [[ "$LATEST_VERSION" == "null" ]]; then
        # Fallback para arquivo de versão
        LATEST_VERSION=$(curl -s https://raw.githubusercontent.com/cyberghost/cyberghost-osint/main/VERSION 2>/dev/null)
    fi
    
    if [[ -z "$LATEST_VERSION" ]]; then
        echo -e "${RED}[!] Could not determine latest version${NC}"
        return 1
    fi
    
    echo -e "${GREEN}[+] Latest version: ${LATEST_VERSION}${NC}"
}

# Comparar versões
compare_versions() {
    if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
        echo -e "${GREEN}[✓] You have the latest version${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}[!] Update available: ${CURRENT_VERSION} -> ${LATEST_VERSION}${NC}"
    return 1
}

# Criar backup
create_backup() {
    echo -e "${BLUE}[*] Creating backup...${NC}"
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup de configurações
    if [[ -d "$CONFIG_DIR" ]]; then
        cp -r "$CONFIG_DIR" "${BACKUP_DIR}/config"
        echo -e "${GREEN}[✓] Config backed up${NC}"
    fi
    
    # Backup de dados
    if [[ -d "${INSTALL_DIR}/data" ]]; then
        cp -r "${INSTALL_DIR}/data" "${BACKUP_DIR}/data"
        echo -e "${GREEN}[✓] Data backed up${NC}"
    fi
    
    # Backup de relatórios
    if [[ -d "${HOME}/CyberGhost_Reports" ]]; then
        cp -r "${HOME}/CyberGhost_Reports" "${BACKUP_DIR}/reports"
        echo -e "${GREEN}[✓] Reports backed up${NC}"
    fi
    
    # Backup de bancos de dados
    if [[ -f "${CONFIG_DIR}/cyberghost.db" ]]; then
        cp "${CONFIG_DIR}/cyberghost.db" "${BACKUP_DIR}/"
        echo -e "${GREEN}[✓] Database backed up${NC}"
    fi
    
    echo -e "${GREEN}[✓] Backup created at: ${BACKUP_DIR}${NC}"
}

# Atualizar código
update_code() {
    echo -e "${BLUE}[*] Updating code...${NC}"
    
    cd "$INSTALL_DIR"
    
    # Verificar se é repositório git
    if [[ -d ".git" ]]; then
        git fetch --all
        git reset --hard origin/main
        echo -e "${GREEN}[✓] Code updated via git${NC}"
    else
        # Download do zip
        local zip_url="https://github.com/cyberghost/cyberghost-osint/archive/refs/heads/main.zip"
        wget -q -O "${TEMP_DIR}/main.zip" "$zip_url"
        
        if [[ -f "${TEMP_DIR}/main.zip" ]]; then
            unzip -q "${TEMP_DIR}/main.zip" -d "$TEMP_DIR"
            rsync -a "${TEMP_DIR}/cyberghost-osint-main/" "$INSTALL_DIR/"
            echo -e "${GREEN}[✓] Code updated via zip${NC}"
        else
            echo -e "${RED}[!] Failed to download update${NC}"
            return 1
        fi
    fi
}

# Atualizar dependências
update_dependencies() {
    echo -e "${BLUE}[*] Updating dependencies...${NC}"
    
    # Go tools
    if command -v go &> /dev/null; then
        echo -e "${YELLOW}[*] Updating Go tools...${NC}"
        go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
        go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
        go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
        go install -v github.com/tomnomnom/assetfinder@latest
        go install -v github.com/ffuf/ffuf@latest
    fi
    
    # Python tools
    if [[ -d "${INSTALL_DIR}/venv" ]]; then
        echo -e "${YELLOW}[*] Updating Python tools...${NC}"
        source "${INSTALL_DIR}/venv/bin/activate"
        pip install --upgrade -r "${INSTALL_DIR}/requirements.txt"
    fi
    
    # Nuclei templates
    if command -v nuclei &> /dev/null; then
        nuclei -update-templates
    fi
    
    echo -e "${GREEN}[✓] Dependencies updated${NC}"
}

# Atualizar wordlists
update_wordlists() {
    echo -e "${BLUE}[*] Updating wordlists...${NC}"
    
    local wordlist_dir="${INSTALL_DIR}/data/wordlists"
    mkdir -p "$wordlist_dir"
    
    # SecLists
    if [[ ! -d "${wordlist_dir}/SecLists" ]]; then
        echo -e "${YELLOW}[*] Downloading SecLists...${NC}"
        git clone --depth 1 https://github.com/danielmiessler/SecLists.git "${wordlist_dir}/SecLists"
    else
        cd "${wordlist_dir}/SecLists" && git pull
    fi
    
    # Assetnote wordlists
    echo -e "${YELLOW}[*] Downloading AssetNote wordlists...${NC}"
    wget -q -O "${wordlist_dir}/subdomains.txt" "https://wordlists-cdn.assetnote.io/data/manual/best-dns-wordlist.txt"
    
    echo -e "${GREEN}[✓] Wordlists updated${NC}"
}

# Atualizar bancos de dados
update_databases() {
    echo -e "${BLUE}[*] Updating databases...${NC}"
    
    local db_dir="${INSTALL_DIR}/data/databases"
    mkdir -p "$db_dir"
    
    # CVE database
    echo -e "${YELLOW}[*] Updating CVE database...${NC}"
    wget -q -O "${db_dir}/cve.json" "https://cve.circl.lu/api/last"
    
    # Exploit database
    echo -e "${YELLOW}[*] Updating exploit database...${NC}"
    if [[ ! -d "${db_dir}/exploitdb" ]]; then
        git clone --depth 1 https://github.com/offensive-security/exploitdb.git "${db_dir}/exploitdb"
    else
        cd "${db_dir}/exploitdb" && git pull
    fi
    
    echo -e "${GREEN}[✓] Databases updated${NC}"
}

# Atualizar configurações
update_config() {
    echo -e "${BLUE}[*] Updating configuration...${NC}"
    
    # Mesclar configurações antigas com novas
    if [[ -f "${CONFIG_DIR}/settings.conf" ]]; then
        cp "${CONFIG_DIR}/settings.conf" "${CONFIG_DIR}/settings.conf.old"
    fi
    
    # Criar nova configuração padrão se necessário
    if [[ ! -f "${CONFIG_DIR}/settings.conf" ]]; then
        cp "${INSTALL_DIR}/data/config/settings.conf.example" "${CONFIG_DIR}/settings.conf"
        echo -e "${GREEN}[✓] New configuration created${NC}"
    fi
    
    # Atualizar API keys
    if [[ -f "${CONFIG_DIR}/api_keys.conf" ]]; then
        # Manter chaves existentes
        echo -e "${GREEN}[✓] API keys preserved${NC}"
    else
        cp "${INSTALL_DIR}/data/config/api_keys.conf.example" "${CONFIG_DIR}/api_keys.conf"
        echo -e "${YELLOW}[!] Please configure your API keys in ${CONFIG_DIR}/api_keys.conf${NC}"
    fi
}

# Verificar instalação
verify_installation() {
    echo -e "${BLUE}[*] Verifying installation...${NC}"
    
    local errors=0
    
    # Verificar executáveis principais
    local main_scripts=(
        "${INSTALL_DIR}/src/core/main.sh"
        "${INSTALL_DIR}/scripts/install.sh"
        "${INSTALL_DIR}/scripts/update.sh"
    )
    
    for script in "${main_scripts[@]}"; do
        if [[ -f "$script" ]] && [[ -x "$script" ]]; then
            echo -e "${GREEN}[✓] $(basename "$script")${NC}"
        else
            echo -e "${RED}[✗] $(basename "$script")${NC}"
            ((errors++))
        fi
    done
    
    # Verificar diretórios
    local dirs=(
        "$INSTALL_DIR"
        "$CONFIG_DIR"
        "${INSTALL_DIR}/data"
        "${INSTALL_DIR}/data/wordlists"
        "${INSTALL_DIR}/data/databases"
        "${HOME}/CyberGhost_Reports"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            echo -e "${GREEN}[✓] $(basename "$dir") directory${NC}"
        else
            echo -e "${RED}[✗] $(basename "$dir") directory${NC}"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        echo -e "${GREEN}[✓] All checks passed${NC}"
    else
        echo -e "${RED}[!] $errors errors found${NC}"
    fi
    
    return $errors
}

# Restaurar backup (se necessário)
restore_backup() {
    echo -e "${YELLOW}[!] Update failed. Do you want to restore backup? (y/N)${NC}"
    read -r answer
    
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}[*] Restoring backup...${NC}"
        
        if [[ -d "$BACKUP_DIR" ]]; then
            # Restaurar configurações
            if [[ -d "${BACKUP_DIR}/config" ]]; then
                rm -rf "$CONFIG_DIR"
                cp -r "${BACKUP_DIR}/config" "$CONFIG_DIR"
            fi
            
            # Restaurar dados
            if [[ -d "${BACKUP_DIR}/data" ]]; then
                rm -rf "${INSTALL_DIR}/data"
                cp -r "${BACKUP_DIR}/data" "${INSTALL_DIR}/data"
            fi
            
            # Restaurar banco de dados
            if [[ -f "${BACKUP_DIR}/cyberghost.db" ]]; then
                cp "${BACKUP_DIR}/cyberghost.db" "$CONFIG_DIR/"
            fi
            
            echo -e "${GREEN}[✓] Backup restored${NC}"
        else
            echo -e "${RED}[!] Backup directory not found${NC}"
        fi
    fi
}

# Função principal
main() {
    print_banner
    
    echo -e "\n${YELLOW}This will update CYBERGHOST OSINT to the latest version${NC}"
    echo -e "${YELLOW}A backup will be created before updating${NC}\n"
    
    # Verificar versões
    check_current_version
    check_latest_version
    
    if compare_versions; then
        echo -e "\n${GREEN}No update needed. Exiting.${NC}"
        exit 0
    fi
    
    echo -e "\n${YELLOW}Proceed with update? (y/N)${NC}"
    read -r answer
    
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Update cancelled${NC}"
        exit 0
    fi
    
    # Criar diretório temporário
    mkdir -p "$TEMP_DIR"
    
    # Criar backup
    create_backup
    
    # Atualizar
    update_code || {
        echo -e "${RED}[!] Code update failed${NC}"
        restore_backup
        exit 1
    }
    
    update_dependencies
    update_wordlists
    update_databases
    update_config
    verify_installation
    
    # Atualizar versão no arquivo
    echo "$LATEST_VERSION" > "${INSTALL_DIR}/VERSION"
    
    # Limpar
    rm -rf "$TEMP_DIR"
    
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}              UPDATE COMPLETED SUCCESSFULLY!                    ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e ""
    echo -e "${CYAN}Updated from ${CURRENT_VERSION} to ${LATEST_VERSION}${NC}"
    echo -e "${CYAN}Backup saved to: ${BACKUP_DIR}${NC}"
    echo -e ""
    echo -e "${YELLOW}Please restart CYBERGHOST to apply changes${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
}

# Executar
main "$@"