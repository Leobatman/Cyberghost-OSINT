#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Directory Bruteforce Module
# =============================================================================

MODULE_NAME="Directory Bruteforce"
MODULE_DESC="Bruteforce directories and files on web servers"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# Configurações
DIR_THREADS="${DIR_THREADS:-50}"
DIR_TIMEOUT="${DIR_TIMEOUT:-5}"
DIR_DELAY="${DIR_DELAY:-0.1}"
DIR_FOLLOW_REDIRECTS="${DIR_FOLLOW_REDIRECTS:-true}"
DIR_RECURSIVE="${DIR_RECURSIVE:-false}"
DIR_RECURSIVE_DEPTH="${DIR_RECURSIVE_DEPTH:-2}"
DIR_EXTENSIONS="${DIR_EXTENSIONS:-php,asp,aspx,jsp,do,action,html,htm,txt,json,xml}"
DIR_STATUS_CODES="${DIR_STATUS_CODES:-200,204,301,302,307,401,403}"

# Wordlists padrão
DIR_WORDLIST="${WORDLISTS_DIR}/directories/common.txt"
DIR_EXTENSIONS_WORDLIST="${WORDLISTS_DIR}/directories/extensions.txt"

# Inicializar módulo
init_directory_bruteforce() {
    log "INFO" "Initializing Directory Bruteforce module" "DIRBRUTE"
    
    # Verificar dependências
    local deps=("curl" "grep" "sed" "awk")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "DIRBRUTE"
        return 1
    fi
    
    # Verificar wordlist
    if [[ ! -f "$DIR_WORDLIST" ]]; then
        log "WARNING" "Directory wordlist not found: $DIR_WORDLIST" "DIRBRUTE"
    fi
    
    return 0
}

# Função principal
bruteforce_directories() {
    local target="$1"
    local output_dir="$2"
    local wordlist="${3:-$DIR_WORDLIST}"
    local extensions="${4:-$DIR_EXTENSIONS}"
    
    log "WEB" "Starting directory bruteforce for: $target" "DIRBRUTE"
    log "INFO" "Using wordlist: $wordlist" "DIRBRUTE"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/directory_bruteforce"
    mkdir -p "$results_dir" "$TEMP_DIR/dirbrute"
    
    local results="{}"
    
    # Normalizar URL
    target=$(normalize_url "$target")
    results=$(echo "$results" | jq --arg url "$target" '.target = $url')
    
    # Carregar wordlist
    if [[ ! -f "$wordlist" ]]; then
        log "ERROR" "Wordlist not found: $wordlist" "DIRBRUTE"
        return 1
    fi
    
    local total_entries
    total_entries=$(wc -l < "$wordlist")
    results=$(echo "$results" | jq --argjson total "$total_entries" '.wordlist.total = $total')
    
    # Separar wordlist para processamento paralelo
    split_wordlist "$wordlist" "$DIR_THREADS"
    
    # Executar bruteforce
    log "INFO" "Starting bruteforce with $DIR_THREADS threads" "DIRBRUTE"
    
    local found_dirs="[]"
    local temp_results="${TEMP_DIR}/dirbrute/results.txt"
    
    # Processar em paralelo
    for ((i=0; i<DIR_THREADS; i++)); do
        local chunk_file="${TEMP_DIR}/dirbrute/chunk_${i}.txt"
        
        if [[ -f "$chunk_file" ]]; then
            (
                while IFS= read -r dir; do
                    if [[ -n "$dir" ]]; then
                        # Testar sem extensão
                        test_directory "$target" "$dir" >> "$temp_results" &
                        
                        # Testar com extensões
                        IFS=',' read -ra ext_array <<< "$extensions"
                        for ext in "${ext_array[@]}"; do
                            test_directory "$target" "${dir}.${ext}" >> "$temp_results" &
                        done
                        
                        # Delay para evitar sobrecarga
                        sleep "$DIR_DELAY"
                    fi
                done < "$chunk_file"
            ) &
        fi
    done
    
    # Aguardar todos os processos
    wait
    
    # Processar resultados
    if [[ -f "$temp_results" ]]; then
        found_dirs=$(process_results "$temp_results")
    fi
    
    results=$(echo "$results" | jq --argjson dirs "$found_dirs" '.found = $dirs')
    
    # Estatísticas
    local found_count
    found_count=$(echo "$found_dirs" | jq 'length')
    results=$(echo "$results" | jq --argjson found "$found_count" '.statistics.found = $found')
    
    # Se recursivo, escanear subdiretórios encontrados
    if [[ "$DIR_RECURSIVE" == "true" ]] && [[ $found_count -gt 0 ]]; then
        log "INFO" "Starting recursive scan (depth: $DIR_RECURSIVE_DEPTH)" "DIRBRUTE"
        
        local recursive_results="[]"
        recursive_results=$(scan_recursive "$target" "$found_dirs" 1)
        
        results=$(echo "$results" | jq --argjson recursive "$recursive_results" '.recursive = $recursive')
    fi
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/directories.json"
    
    # Salvar lista de diretórios encontrados
    echo "$found_dirs" | jq -r '.[].url' > "${results_dir}/found_urls.txt"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "SUCCESS" "Directory bruteforce completed in ${duration}s - Found $found_count directories/files" "DIRBRUTE"
    
    echo "$results"
}

# Normalizar URL
normalize_url() {
    local url="$1"
    
    # Adicionar protocolo se não tiver
    if [[ ! "$url" =~ ^https?:// ]]; then
        url="http://${url}"
    fi
    
    # Garantir barra no final
    if [[ ! "$url" =~ /$ ]]; then
        url="${url}/"
    fi
    
    echo "$url"
}

# Dividir wordlist para processamento paralelo
split_wordlist() {
    local wordlist="$1"
    local threads="$2"
    
    local total_lines
    total_lines=$(wc -l < "$wordlist")
    local lines_per_file=$(( (total_lines + threads - 1) / threads ))
    
    split -l "$lines_per_file" "$wordlist" "${TEMP_DIR}/dirbrute/chunk_"
    
    # Renomear arquivos
    local i=0
    for chunk in "${TEMP_DIR}/dirbrute/chunk_"*; do
        if [[ -f "$chunk" ]]; then
            mv "$chunk" "${TEMP_DIR}/dirbrute/chunk_${i}.txt"
            ((i++))
        fi
    done
}

# Testar diretório
test_directory() {
    local base_url="$1"
    local dir="$2"
    
    # Construir URL
    local url="${base_url}${dir}"
    
    # Fazer requisição
    local status
    local size
    local redirect
    
    # Usar curl para obter informações
    local curl_output
    curl_output=$(curl -s -o /dev/null \
        -w "%{http_code},%{size_download},%{redirect_url}" \
        --max-time "$DIR_TIMEOUT" \
        ${DIR_FOLLOW_REDIRECTS:+-L} \
        "$url" 2>/dev/null)
    
    if [[ -n "$curl_output" ]]; then
        IFS=',' read -r status size redirect <<< "$curl_output"
        
        # Verificar se status code está na lista permitida
        if is_status_allowed "$status"; then
            echo "{\"url\":\"$url\",\"status\":$status,\"size\":$size,\"redirect\":\"$redirect\"}"
        fi
    fi
}

# Verificar se status code é permitido
is_status_allowed() {
    local status="$1"
    
    IFS=',' read -ra allowed <<< "$DIR_STATUS_CODES"
    
    for code in "${allowed[@]}"; do
        if [[ "$status" == "$code" ]]; then
            return 0
        fi
    done
    
    return 1
}

# Processar resultados
process_results() {
    local results_file="$1"
    
    if [[ ! -f "$results_file" ]]; then
        echo "[]"
        return
    fi
    
    # Ordenar e remover duplicatas
    sort -u "$results_file" | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            echo "$line"
        fi
    done | jq -s '.'
}

# Escanear recursivamente
scan_recursive() {
    local base_url="$1"
    local found_dirs="$2"
    local current_depth="$3"
    local results="[]"
    
    if [[ $current_depth -gt $DIR_RECURSIVE_DEPTH ]]; then
        echo "$results"
        return
    fi
    
    echo "$found_dirs" | jq -c '.[]' | while read -r dir_info; do
        local url
        url=$(echo "$dir_info" | jq -r '.url')
        
        # Verificar se é diretório (termina com /)
        if [[ "$url" == */ ]]; then
            log "DEBUG" "Recursive scan on: $url (depth $current_depth)" "DIRBRUTE"
            
            # Executar bruteforce no subdiretório
            local sub_results
            sub_results=$(bruteforce_directories "$url" "$TEMP_DIR/recursive" "$DIR_WORDLIST" "$DIR_EXTENSIONS" 2>/dev/null)
            
            if [[ -n "$sub_results" ]]; then
                local sub_found
                sub_found=$(echo "$sub_results" | jq '.found // []')
                
                if [[ "$(echo "$sub_found" | jq 'length')" -gt 0 ]]; then
                    results=$(echo "$results" | jq --argjson sub "$sub_found" '. += $sub')
                    
                    # Recursão adicional
                    local deeper
                    deeper=$(scan_recursive "$url" "$sub_found" $((current_depth + 1)))
                    results=$(echo "$results" | jq --argjson deep "$deeper" '. += $deep')
                fi
            fi
        fi
    done
    
    echo "$results"
}

# Exportar funções
export -f init_directory_bruteforce bruteforce_directories