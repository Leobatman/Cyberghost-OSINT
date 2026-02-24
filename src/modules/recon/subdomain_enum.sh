#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Advanced Subdomain Enumeration Module
# =============================================================================

MODULE_NAME="Subdomain Enumeration"
MODULE_DESC="Advanced subdomain discovery using multiple techniques"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# Configurações do módulo
SUBDOAMIN_THREADS=50
SUBDOMAIN_TIMEOUT=10
SUBDOMAIN_RESOLVERS="${DATA_DIR}/resolvers.txt"
SUBDOMAIN_WORDLIST="${WORDLISTS_DIR}/subdomains/all.txt"

# Inicializar módulo
init_subdomain_enum() {
    log "INFO" "Initializing Subdomain Enumeration module" "SUBDOMAIN"
    
    # Verificar dependências
    local deps=("dig" "host" "curl" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "SUBDOMAIN"
        return 1
    fi
    
    # Criar diretório de trabalho
    mkdir -p "${TEMP_DIR}/subdomain"
    
    return 0
}

# Enumeração principal
enumerate_subdomains() {
    local domain="$1"
    local output_dir="$2"
    
    log "RECON" "Starting subdomain enumeration for: $domain" "SUBDOMAIN"
    
    local start_time
    start_time=$(date +%s)
    
    # Criar diretórios
    local work_dir="${TEMP_DIR}/subdomain/${domain}"
    local results_dir="${output_dir}/subdomains"
    mkdir -p "$work_dir" "$results_dir"
    
    # Arrays para resultados
    declare -A results
    local all_subdomains=()
    
    # Fase 1: Passive enumeration
    log "INFO" "Phase 1: Passive enumeration" "SUBDOMAIN"
    passive_enum "$domain" "$work_dir" &
    local pid1=$!
    
    # Fase 2: Active enumeration
    log "INFO" "Phase 2: Active enumeration" "SUBDOMAIN"
    active_enum "$domain" "$work_dir" &
    local pid2=$!
    
    # Fase 3: Certificate transparency
    log "INFO" "Phase 3: Certificate transparency" "SUBDOMAIN"
    cert_enum "$domain" "$work_dir" &
    local pid3=$!
    
    # Fase 4: DNS brute force
    log "INFO" "Phase 4: DNS brute force" "SUBDOMAIN"
    dns_bruteforce "$domain" "$work_dir" &
    local pid4=$!
    
    # Aguardar processos
    wait $pid1 $pid2 $pid3 $pid4
    
    # Combinar resultados
    log "INFO" "Combining results from all sources" "SUBDOMAIN"
    combine_results "$domain" "$work_dir" "$results_dir"
    
    # Verificar subdomínios vivos
    log "INFO" "Checking live subdomains" "SUBDOMAIN"
    check_live_subdomains "${results_dir}/all_subdomains.txt" "${results_dir}/live_subdomains.txt"
    
    # Resolver IPs
    log "INFO" "Resolving IP addresses" "SUBDOMAIN"
    resolve_ips "${results_dir}/live_subdomains.txt" "${results_dir}/resolved_ips.txt"
    
    # Gerar relatório
    generate_subdomain_report "$domain" "$results_dir" "$output_dir"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local total=$(wc -l < "${results_dir}/all_subdomains.txt" 2>/dev/null || echo 0)
    local live=$(wc -l < "${results_dir}/live_subdomains.txt" 2>/dev/null || echo 0)
    
    log "SUCCESS" "Subdomain enumeration completed in ${duration}s" "SUBDOMAIN"
    log "SUCCESS" "Found ${total} subdomains (${live} live)" "SUBDOMAIN"
    
    # Retornar estatísticas
    echo "{
        \"domain\": \"$domain\",
        \"total_subdomains\": $total,
        \"live_subdomains\": $live,
        \"duration\": $duration,
        \"files\": {
            \"all\": \"${results_dir}/all_subdomains.txt\",
            \"live\": \"${results_dir}/live_subdomains.txt\",
            \"ips\": \"${results_dir}/resolved_ips.txt\"
        }
    }"
}

# Enumeração passiva
passive_enum() {
    local domain="$1"
    local work_dir="$2"
    
    log "DEBUG" "Starting passive enumeration" "SUBDOMAIN"
    
    # Fontes passivas
    local sources=(
        "https://crt.sh/?q=%.$domain&output=json"
        "https://api.hackertarget.com/hostsearch/?q=$domain"
        "https://api.threatminer.org/v2/domain.php?q=$domain&rt=5"
        "https://urlscan.io/api/v1/search/?q=domain:$domain"
        "https://jldc.me/anubis/subdomains/$domain"
        "https://dns.bufferover.run/dns?q=.$domain"
        "https://tls.bufferover.run/dns?q=.$domain"
        "https://sonar.omnisint.io/subdomains/$domain"
        "https://rapiddns.io/subdomain/$domain"
        "https://subdomainfinder.c99.nl/scans/$(date +%Y-%m-%d)/$domain"
    )
    
    local passive_file="${work_dir}/passive.txt"
    
    for source in "${sources[@]}"; do
        log "DEBUG" "Querying: $source" "SUBDOMAIN"
        
        local response
        response=$(curl -s -k -L --max-time 10 "$source" 2>/dev/null)
        
        # Extrair subdomínios (vários formatos)
        echo "$response" | grep -oE "[a-zA-Z0-9.-]+\.$domain" | sort -u >> "$passive_file" 2>/dev/null
        
        # Aguardar um pouco para não sobrecarregar
        sleep 0.5
    done
    
    # Ferramentas locais se disponíveis
    if command -v subfinder &> /dev/null; then
        log "DEBUG" "Running subfinder" "SUBDOMAIN"
        subfinder -d "$domain" -silent >> "$passive_file" 2>/dev/null
    fi
    
    if command -v assetfinder &> /dev/null; then
        log "DEBUG" "Running assetfinder" "SUBDOMAIN"
        assetfinder --subs-only "$domain" >> "$passive_file" 2>/dev/null
    fi
    
    # Limpar e ordenar
    sort -u -o "$passive_file" "$passive_file"
    
    local count=$(wc -l < "$passive_file" 2>/dev/null || echo 0)
    log "INFO" "Passive enumeration found $count subdomains" "SUBDOMAIN"
}

# Enumeração ativa
active_enum() {
    local domain="$1"
    local work_dir="$2"
    
    log "DEBUG" "Starting active enumeration" "SUBDOMAIN"
    
    local active_file="${work_dir}/active.txt"
    
    # Zone transfer check
    log "DEBUG" "Checking zone transfer" "SUBDOMAIN"
    local ns_servers
    ns_servers=$(dig NS "$domain" +short)
    
    for ns in $ns_servers; do
        dig AXFR "$domain" @"$ns" +short 2>/dev/null | grep -oE "[a-zA-Z0-9.-]+\.$domain" >> "$active_file"
    done
    
    # DNS recon
    log "DEBUG" "DNS reconnaissance" "SUBDOMAIN"
    dnsrecon -d "$domain" -t axfr 2>/dev/null | grep -oE "[a-zA-Z0-9.-]+\.$domain" >> "$active_file"
    
    sort -u -o "$active_file" "$active_file"
    
    local count=$(wc -l < "$active_file" 2>/dev/null || echo 0)
    log "INFO" "Active enumeration found $count subdomains" "SUBDOMAIN"
}

# Certificate transparency
cert_enum() {
    local domain="$1"
    local work_dir="$2"
    
    log "DEBUG" "Checking certificate transparency" "SUBDOMAIN"
    
    local cert_file="${work_dir}/cert.txt"
    
    # crt.sh
    local response
    response=$(curl -s "https://crt.sh/?q=%.$domain&output=json" 2>/dev/null)
    
    if [[ -n "$response" ]]; then
        echo "$response" | jq -r '.[].name_value' 2>/dev/null | grep -oE "[a-zA-Z0-9.-]+\.$domain" >> "$cert_file"
        echo "$response" | jq -r '.[].common_name' 2>/dev/null | grep -oE "[a-zA-Z0-9.-]+\.$domain" >> "$cert_file"
    fi
    
    # Certspotter
    response=$(curl -s "https://certspotter.com/api/v0/certs?domain=$domain" 2>/dev/null)
    if [[ -n "$response" ]]; then
        echo "$response" | jq -r '.[].dns_names[]' 2>/dev/null | grep -oE "[a-zA-Z0-9.-]+\.$domain" >> "$cert_file"
    fi
    
    sort -u -o "$cert_file" "$cert_file"
    
    local count=$(wc -l < "$cert_file" 2>/dev/null || echo 0)
    log "INFO" "Certificate transparency found $count subdomains" "SUBDOMAIN"
}

# DNS brute force
dns_bruteforce() {
    local domain="$1"
    local work_dir="$2"
    
    log "DEBUG" "Starting DNS brute force" "SUBDOMAIN"
    
    local brute_file="${work_dir}/bruteforce.txt"
    local wordlist="${SUBDOMAIN_WORDLIST}"
    
    if [[ ! -f "$wordlist" ]]; then
        log "WARNING" "Wordlist not found, using smaller default" "SUBDOMAIN"
        wordlist="${WORDLISTS_DIR}/subdomains/common.txt"
    fi
    
    # Usar ferramentas especializadas se disponíveis
    if command -v puredns &> /dev/null; then
        log "DEBUG" "Using puredns for brute force" "SUBDOMAIN"
        puredns bruteforce "$wordlist" "$domain" -r "${SUBDOMAIN_RESOLVERS}" -t "${SUBDOAMIN_THREADS}" >> "$brute_file" 2>/dev/null
    elif command -v massdns &> /dev/null; then
        log "DEBUG" "Using massdns for brute force" "SUBDOMAIN"
        massdns -r "${SUBDOMAIN_RESOLVERS}" -t A -o S -w /dev/stdout "$wordlist" 2>/dev/null | \
            grep -oE "[a-zA-Z0-9.-]+\.$domain" >> "$brute_file"
    else
        # Implementação simples em bash
        log "DEBUG" "Using bash implementation" "SUBDOMAIN"
        while read -r sub; do
            if host "${sub}.${domain}" &>/dev/null; then
                echo "${sub}.${domain}" >> "$brute_file"
            fi
        done < "$wordlist"
    fi
    
    sort -u -o "$brute_file" "$brute_file"
    
    local count=$(wc -l < "$brute_file" 2>/dev/null || echo 0)
    log "INFO" "DNS brute force found $count subdomains" "SUBDOMAIN"
}

# Combinar resultados
combine_results() {
    local domain="$1"
    local work_dir="$2"
    local results_dir="$3"
    
    local all_file="${results_dir}/all_subdomains.txt"
    
    # Combinar todos os arquivos
    cat "${work_dir}"/*.txt 2>/dev/null | sort -u > "$all_file"
    
    # Remover entradas inválidas
    sed -i '/^$/d' "$all_file"
    sed -i '/\*/d' "$all_file"
    
    # Contar
    local total=$(wc -l < "$all_file")
    log "INFO" "Combined $total unique subdomains" "SUBDOMAIN"
}

# Verificar subdomínios vivos
check_live_subdomains() {
    local input_file="$1"
    local output_file="$2"
    
    log "INFO" "Checking live subdomains (HTTP/HTTPS)" "SUBDOMAIN"
    
    if [[ ! -f "$input_file" ]]; then
        log "ERROR" "Input file not found" "SUBDOMAIN"
        return 1
    fi
    
    # Usar httpx se disponível
    if command -v httpx &> /dev/null; then
        httpx -l "$input_file" -silent -status-code -title -tech-detect -o "$output_file" 2>/dev/null
    else
        # Implementação simples
        while read -r sub; do
            if curl -s -k -L --max-time 5 "https://${sub}" &>/dev/null; then
                echo "$sub" >> "$output_file"
            elif curl -s -k -L --max-time 5 "http://${sub}" &>/dev/null; then
                echo "$sub" >> "$output_file"
            fi
        done < "$input_file"
    fi
    
    local live=$(wc -l < "$output_file" 2>/dev/null || echo 0)
    log "INFO" "Found $live live subdomains" "SUBDOMAIN"
}

# Resolver IPs
resolve_ips() {
    local input_file="$1"
    local output_file="$2"
    
    log "INFO" "Resolving IP addresses" "SUBDOMAIN"
    
    if [[ ! -f "$input_file" ]]; then
        log "ERROR" "Input file not found" "SUBDOMAIN"
        return 1
    fi
    
    > "$output_file"
    
    while read -r sub; do
        local ips
        ips=$(dig +short "$sub" A 2>/dev/null | grep -v "\.$")
        
        if [[ -n "$ips" ]]; then
            echo "$sub: $ips" >> "$output_file"
        fi
    done < "$input_file"
}

# Gerar relatório
generate_subdomain_report() {
    local domain="$1"
    local results_dir="$2"
    local output_dir="$3"
    
    log "INFO" "Generating subdomain report" "SUBDOMAIN"
    
    local report_file="${output_dir}/subdomains_report.json"
    
    # Coletar informações
    local all_count=$(wc -l < "${results_dir}/all_subdomains.txt" 2>/dev/null || echo 0)
    local live_count=$(wc -l < "${results_dir}/live_subdomains.txt" 2>/dev/null || echo 0)
    
    # Criar JSON
    cat > "$report_file" << EOF
{
    "module": "Subdomain Enumeration",
    "version": "$MODULE_VERSION",
    "target": "$domain",
    "timestamp": "$(date -Iseconds)",
    "statistics": {
        "total_subdomains": $all_count,
        "live_subdomains": $live_count
    },
    "files": {
        "all_subdomains": "all_subdomains.txt",
        "live_subdomains": "live_subdomains.txt",
        "resolved_ips": "resolved_ips.txt"
    },
    "subdomains": [
EOF
    
    # Adicionar subdomínios vivos
    if [[ -f "${results_dir}/live_subdomains.txt" ]]; then
        local first=true
        while IFS= read -r sub; do
            if [[ "$first" == true ]]; then
                first=false
            else
                echo "," >> "$report_file"
            fi
            
            # Resolver IP para este subdomínio
            local ips
            ips=$(dig +short "$sub" A 2>/dev/null | tr '\n' ',' | sed 's/,$//')
            
            cat >> "$report_file" << EOF
        {
            "subdomain": "$sub",
            "ips": "$ips",
            "status": "live"
        }
EOF
        done < "${results_dir}/live_subdomains.txt"
    fi
    
    # Fechar JSON
    cat >> "$report_file" << EOF
    ]
}
EOF
    
    log "SUCCESS" "Report generated: $report_file" "SUBDOMAIN"
}

# Exportar funções
export -f init_subdomain_enum enumerate_subdomains