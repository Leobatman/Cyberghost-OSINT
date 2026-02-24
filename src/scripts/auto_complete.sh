#!/usr/bin/env bash
# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Auto Completion Script
# =============================================================================
# Instale com: source scripts/auto_complete.sh
# Ou adicione ao .bashrc: source /path/to/cyberghost-osint/scripts/auto_complete.sh

_cyberghost_completion() {
    local cur prev words cword
    _init_completion || return
    
    # Comandos principais
    local commands="scan report list config update help install uninstall web api worker"
    
    # Opções comuns
    local common_opts="--help --verbose --quiet --no-color --output --format"
    
    # Formatos de relatório
    local report_formats="html pdf json csv txt xml"
    
    # Tipos de scan
    local scan_types="full recon social email threat github intel geo business mobile dns metadata ai"
    
    # Módulos disponíveis
    local modules="subdomain dns infrastructure port service cloud cdn threat email social github darkweb paste breach metadata web directory cms waf tech historical wayback"
    
    case "${prev}" in
        scan)
            # Completar com tipos de scan
            COMPREPLY=($(compgen -W "${scan_types}" -- "${cur}"))
            return 0
            ;;
        report)
            # Completar com IDs de scan
            if command -v cg &>/dev/null; then
                local scans=$(cg list --quiet 2>/dev/null | awk '{print $1}')
                COMPREPLY=($(compgen -W "${scans}" -- "${cur}"))
            fi
            return 0
            ;;
        --format|-f)
            # Completar com formatos de relatório
            COMPREPLY=($(compgen -W "${report_formats}" -- "${cur}"))
            return 0
            ;;
        --module|-m)
            # Completar com módulos
            COMPREPLY=($(compgen -W "${modules}" -- "${cur}"))
            return 0
            ;;
        --output|-o)
            # Completar com diretórios
            COMPREPLY=($(compgen -A directory -- "${cur}"))
            return 0
            ;;
        *)
            # Se o comando atual é o primeiro argumento
            if [[ ${cword} -eq 1 ]]; then
                COMPREPLY=($(compgen -W "${commands}" -- "${cur}"))
                return 0
            fi
            
            # Opções gerais
            case "${cur}" in
                --*)
                    COMPREPLY=($(compgen -W "${common_opts}" -- "${cur}"))
                    return 0
                    ;;
                -*)
                    COMPREPLY=($(compgen -W "-h -v -q -o -f -m" -- "${cur}"))
                    return 0
                    ;;
            esac
            ;;
    esac
}

# Completar para o comando 'cg'
complete -F _cyberghost_completion cg
complete -F _cyberghost_completion cyberghost

# Alias para facilitar
alias cg-completion='source "${BASH_SOURCE[0]}"'

# Função para instalar completions permanentemente
cg-install-completion() {
    local bashrc="${HOME}/.bashrc"
    local zshrc="${HOME}/.zshrc"
    local script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/auto_complete.sh"
    
    echo "Installing CYBERGHOST auto-completion..."
    
    # Bash
    if [[ -f "$bashrc" ]]; then
        if ! grep -q "source.*auto_complete.sh" "$bashrc"; then
            echo "" >> "$bashrc"
            echo "# CYBERGHOST OSINT Auto-completion" >> "$bashrc"
            echo "source \"$script_path\"" >> "$bashrc"
            echo "✅ Added to $bashrc"
        else
            echo "✓ Already in $bashrc"
        fi
    fi
    
    # Zsh
    if [[ -f "$zshrc" ]]; then
        if ! grep -q "source.*auto_complete.sh" "$zshrc"; then
            echo "" >> "$zshrc"
            echo "# CYBERGHOST OSINT Auto-completion" >> "$zshrc"
            echo "source \"$script_path\"" >> "$zshrc"
            echo "✅ Added to $zshrc"
        else
            echo "✓ Already in $zshrc"
        fi
    fi
    
    echo ""
    echo "Auto-completion installed! Please restart your shell or run:"
    echo "  source ~/.bashrc  (for Bash)"
    echo "  source ~/.zshrc   (for Zsh)"
}

echo "✅ CYBERGHOST OSINT auto-completion loaded"
echo "   Use: cg [TAB][TAB] to see available commands"
echo "   Run: cg-install-completion to install permanently"