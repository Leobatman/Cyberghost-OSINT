#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Uninstall Script
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
BIN_LINKS=("/usr/local/bin/cg" "/usr/local/bin/cyberghost")

# Banner
print_banner() {
    clear
    echo -e "${RED}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║         CYBERGHOST OSINT ULTIMATE - UNINSTALL               ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Verificar instalação
check_installation() {
    echo -e "${BLUE}[*] Checking installation...${NC}"
    
    local found=false
    
    if [[ -d "$INSTALL_DIR" ]]; then
        echo -e "${GREEN}[✓] Found installation at: $INSTALL_DIR${NC}"
        found=true
    fi
    
    if [[ -d "$CONFIG_DIR" ]]; then
        echo -e "${GREEN}[✓] Found configuration at: $CONFIG_DIR${NC}"
        found=true
    fi
    
    if [[ "$found" == "false" ]]; then
        echo -e "${RED}[!] No CYBERGHOST installation found${NC}"
        exit 1
    fi
}

# Criar backup antes de desinstalar
create_backup() {
    local backup_dir="${HOME}/cyberghost_backup_$(date +%Y%m%d_%H%M%S)"
    
    echo -e "${YELLOW}[*] Creating backup before uninstall...${NC}"
    
    mkdir -p "$backup_dir"
    
    # Backup de configurações
    if [[ -d "$CONFIG_DIR" ]]; then
        cp -r "$CONFIG_DIR" "${backup_dir}/config"
        echo -e "${GREEN}[✓] Config backed up${NC}"
    fi
    
    # Backup de relatórios
    if [[ -d "$REPORTS_DIR" ]]; then
        cp -r "$REPORTS_DIR" "${backup_dir}/reports"
        echo -e "${GREEN}[✓] Reports backed up${NC}"
    fi
    
    echo -e "${GREEN}[✓] Backup created at: ${backup_dir}${NC}"
    echo "$backup_dir"
}

# Remover links simbólicos
remove_symlinks() {
    echo -e "${BLUE}[*] Removing symbolic links...${NC}"
    
    for link in "${BIN_LINKS[@]}"; do
        if [[ -L "$link" ]]; then
            sudo rm -f "$link"
            echo -e "${GREEN}[✓] Removed: $link${NC}"
        fi
    done
}

# Remover entrada do bashrc
remove_bashrc_entry() {
    echo -e "${BLUE}[*] Removing bashrc entries...${NC}"
    
    local bashrc="${HOME}/.bashrc"
    local zshrc="${HOME}/.zshrc"
    
    for rc in "$bashrc" "$zshrc"; do
        if [[ -f "$rc" ]]; then
            # Fazer backup
            cp "$rc" "${rc}.backup"
            
            # Remover linhas relacionadas ao CYBERGHOST
            sed -i '/# CYBERGHOST OSINT/d' "$rc"
            sed -i '/export CYBERGHOST/d' "$rc"
            sed -i '/alias cg=/d' "$rc"
            sed -i '/source.*cyberghost/d' "$rc"
            
            echo -e "${GREEN}[✓] Cleaned: $rc${NC}"
        fi
    done
}

# Remover arquivos de configuração
remove_config() {
    echo -e "${BLUE}[*] Removing configuration files...${NC}"
    
    if [[ -d "$CONFIG_DIR" ]]; then
        rm -rf "$CONFIG_DIR"
        echo -e "${GREEN}[✓] Removed: $CONFIG_DIR${NC}"
    fi
}

# Remover diretório de instalação
remove_installation() {
    echo -e "${BLUE}[*] Removing installation directory...${NC}"
    
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
        echo -e "${GREEN}[✓] Removed: $INSTALL_DIR${NC}"
    fi
}

# Perguntar sobre relatórios
ask_about_reports() {
    echo -e "${YELLOW}[?] Do you want to keep your scan reports? (Y/n)${NC}"
    read -r answer
    
    if [[ "$answer" =~ ^[Nn]$ ]]; then
        if [[ -d "$REPORTS_DIR" ]]; then
            rm -rf "$REPORTS_DIR"
            echo -e "${GREEN}[✓] Removed reports${NC}"
        fi
    else
        echo -e "${GREEN}[✓] Reports kept at: $REPORTS_DIR${NC}"
    fi
}

# Perguntar sobre backup
ask_about_backup() {
    echo -e "${YELLOW}[?] Do you want to keep the backup? (Y/n)${NC}"
    read -r answer
    
    if [[ "$answer" =~ ^[Nn]$ ]]; then
        if [[ -d "$BACKUP_DIR" ]]; then
            rm -rf "$BACKUP_DIR"
            echo -e "${GREEN}[✓] Backup removed${NC}"
        fi
    else
        echo -e "${GREEN}[✓] Backup kept at: $BACKUP_DIR${NC}"
    fi
}

# Função principal
main() {
    print_banner
    
    echo -e "\n${RED}WARNING: This will completely remove CYBERGHOST OSINT${NC}"
    echo -e "${RED}from your system. This action cannot be undone!${NC}\n"
    
    check_installation
    
    echo -e "\n${YELLOW}Are you sure you want to continue? (y/N)${NC}"
    read -r answer
    
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Uninstall cancelled${NC}"
        exit 0
    fi
    
    # Criar backup
    BACKUP_DIR=$(create_backup)
    
    echo -e "\n${YELLOW}Proceed with uninstall? (y/N)${NC}"
    read -r answer
    
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Uninstall cancelled${NC}"
        exit 0
    fi
    
    # Desinstalar
    echo -e "\n${BLUE}[*] Starting uninstall...${NC}\n"
    
    remove_symlinks
    remove_bashrc_entry
    remove_config
    remove_installation
    ask_about_reports
    ask_about_backup
    
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}           UNINSTALL COMPLETED SUCCESSFULLY!                    ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e ""
    echo -e "${YELLOW}Thank you for using CYBERGHOST OSINT!${NC}"
    echo -e "${CYAN}If you want to reinstall, run: curl -sSL https://cyberghost-osint.com/install | bash${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
}

# Executar
main "$@"