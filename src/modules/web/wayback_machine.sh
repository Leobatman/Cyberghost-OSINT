#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Wayback Machine Module
# =============================================================================

MODULE_NAME="Wayback Machine"
MODULE_DESC="Extract historical data from Internet Archive's Wayback Machine"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# Endpoints da Wayback Machine
WAYBACK_CDX="http://web.archive.org/cdx/search/cdx"
WAYBACK_AVAILABLE="http://archive.org/wayback/available"
WAYBACK_SAVE="https://web.archive.org/save"

# Inicializar módulo
init_wayback() {
    log "INFO" "Initializing Wayback Machine module" "WAYBACK"
    
    # Verificar dependências
    local deps=("curl" "jq" "date")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "WAYBACK"
        return 1
    fi
    
    return 0
}

# Função principal
query_wayback() {
    local target="$1"
    local output_dir="$2"
    
    log "WEB" "Starting Wayback Machine query for: $target" "WAYBACK"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/wayback"
    mkdir -p "$results_dir"
    
    local results="{}"
    
    # 1. Verificar snapshots disponíveis
    log "INFO" "Checking available snapshots" "WAYBACK"
    local available
    available=$(check_available_snapshots "$target")
    results=$(echo "$results" | jq --argjson avail "$available" '.available = $avail')
    
    # 2. Listar todos os snapshots
    log "INFO" "Listing all snapshots" "WAYBACK"
    local snapshots
    snapshots=$(list_snapshots "$target")
    results=$(echo "$results" | jq --argjson snaps "$snapshots" '.snapshots = $snaps')
    
    # 3. Extrair URLs únicas
    log "INFO" "Extracting unique URLs" "WAYBACK"
    local unique_urls
    unique_urls=$(extract_unique_urls "$snapshots")
    results=$(echo "$results" | jq --argjson urls "$unique_urls" '.unique_urls = $urls')
    
    # 4. Extrair arquivos
    log "INFO" "Extracting files" "WAYBACK"
    local files
    files=$(extract_files "$snapshots")
    results=$(echo "$results" | jq --argjson files "$files" '.files = $files')
    
    # 5. Linha do tempo
    log "INFO" "Generating timeline" "WAYBACK"
    local timeline
    timeline=$(generate_wayback_timeline "$snapshots")
    results=$(echo "$results" | jq --argjson timeline "$timeline" '.timeline = $timeline')
    
    # 6. Estatísticas
    log "INFO" "Generating statistics" "WAYBACK"
    local stats
    stats=$(generate_wayback_stats "$snapshots")
    results=$(echo "$results" | jq --argjson stats "$stats" '.statistics = $stats')
    
    # 7. Comparar versões
    log "INFO" "Comparing versions" "WAYBACK"
    local comparisons
    comparisons=$(compare_versions "$snapshots")
    results=$(echo "$results" | jq --argjson comp "$comparisons" '.comparisons = $comp')
    
    # 8. Salvar URLs no Wayback
    log "INFO" "Saving current URL to Wayback" "WAYBACK"
    local save_result
    save_result=$(save_to_wayback "$target")
    results=$(echo "$results" | jq --argjson save "$save_result" '.save_attempt = $save')
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/wayback.json"
    
    # Salvar lista de URLs
    echo "$unique_urls" | jq -r '.[]' > "${results_dir}/urls.txt"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local snapshot_count
    snapshot_count=$(echo "$snapshots" | jq 'length')
    
    log "SUCCESS" "Wayback Machine query completed in ${duration}s - Found $snapshot_count snapshots" "WAYBACK"
    
    echo "$results"
}

# Verificar snapshots disponíveis
check_available_snapshots() {
    local target="$1"
    local result="{}"
    
    local url="${WAYBACK_AVAILABLE}?url=${target}"
    local response
    response=$(curl -s "$url" 2>/dev/null)
    
    if [[ -n "$response" ]]; then
        local closest
        closest=$(echo "$response" | jq -r '.archived_snapshots.closest // empty')
        
        if [[ -n "$closest" ]] && [[ "$closest" != "null" ]]; then
            local timestamp
            timestamp=$(echo "$response" | jq -r '.archived_snapshots.closest.timestamp')
            local archive_url
            archive_url=$(echo "$response" | jq -r '.archived_snapshots.closest.url')
            
            result=$(echo "$result" | jq \
                --arg ts "$timestamp" \
                --arg url "$archive_url" \
                '{
                    available: true,
                    closest: {
                        timestamp: $ts,
                        url: $url
                    }
                }')
        else
            result=$(echo "$result" | jq '.available = false')
        fi
    fi
    
    echo "$result"
}

# Listar todos os snapshots
list_snapshots() {
    local target="$1"
    local snapshots="[]"
    
    # Parâmetros da consulta CDX
    local params=(
        "url=${target}"
        "output=json"
        "fl=timestamp,original,mimetype,statuscode,digest,length"
        "collapse=urlkey"
        "limit=100000"
    )
    
    local url="${WAYBACK_CDX}?$(IFS='&'; echo "${params[*]}")"
    local response
    response=$(curl -s "$url" 2>/dev/null)
    
    if [[ -n "$response" ]] && [[ "$response" != "[]" ]]; then
        snapshots=$(echo "$response" | jq -c '[.[1:][] | {
            timestamp: .[0],
            url: .[1],
            mime_type: .[2],
            status_code: .[3],
            digest: .[4],
            length: (.[5] // "0")
        }]' 2>/dev/null)
    fi
    
    echo "$snapshots"
}

# Extrair URLs únicas
extract_unique_urls() {
    local snapshots="$1"
    local urls="[]"
    
    urls=$(echo "$snapshots" | jq '[.[].url] | unique')
    
    echo "$urls"
}

# Extrair arquivos
extract_files() {
    local snapshots="$1"
    local files="[]"
    
    # Tipos de arquivo de interesse
    local file_types=("pdf" "doc" "docx" "xls" "xlsx" "ppt" "pptx" "zip" "tar" "gz" "rar" "7z")
    
    for ext in "${file_types[@]}"; do
        local matching
        matching=$(echo "$snapshots" | jq --arg ext "$ext" '[.[] | select(.url | endswith("." + $ext))]')
        
        if [[ "$matching" != "[]" ]]; then
            files=$(echo "$files" | jq --arg ext "$ext" --argjson matches "$matching" \
                '. += [{"type": $ext, "count": ($matches | length)}]')
        fi
    done
    
    echo "$files"
}

# Gerar timeline
generate_wayback_timeline() {
    local snapshots="$1"
    local timeline="[]"
    
    # Agrupar por ano
    local years
    years=$(echo "$snapshots" | jq -r '.[].timestamp[0:4]' | sort -u)
    
    while IFS= read -r year; do
        if [[ -n "$year" ]]; then
            local count
            count=$(echo "$snapshots" | jq --arg year "$year" '[.[] | select(.timestamp | startswith($year))] | length')
            
            timeline=$(echo "$timeline" | jq \
                --arg year "$year" \
                --argjson count "$count" \
                '. += [{
                    "year": $year,
                    "snapshots": $count
                }]')
        fi
    done <<< "$years"
    
    echo "$timeline" | jq 'sort_by(.year)'
}

# Gerar estatísticas
generate_wayback_stats() {
    local snapshots="$1"
    local stats="{}"
    
    # Total de snapshots
    local total
    total=$(echo "$snapshots" | jq 'length')
    stats=$(echo "$stats" | jq --argjson total "$total" '.total_snapshots = $total')
    
    # Primeiro snapshot
    local first
    first=$(echo "$snapshots" | jq -r 'min_by(.timestamp).timestamp // empty')
    if [[ -n "$first" ]]; then
        stats=$(echo "$stats" | jq --arg first "$first" '.first_snapshot = $first')
    fi
    
    # Último snapshot
    local last
    last=$(echo "$snapshots" | jq -r 'max_by(.timestamp).timestamp // empty')
    if [[ -n "$last" ]]; then
        stats=$(echo "$stats" | jq --arg last "$last" '.last_snapshot = $last')
    fi
    
    # Status codes
    local status_codes
    status_codes=$(echo "$snapshots" | jq 'group_by(.status_code) | map({(.[0].status_code): length}) | add')
    stats=$(echo "$stats" | jq --argjson codes "$status_codes" '.status_codes = $codes')
    
    # MIME types
    local mime_types
    mime_types=$(echo "$snapshots" | jq 'group_by(.mime_type) | map({(.[0].mime_type): length}) | add')
    stats=$(echo "$stats" | jq --argjson mimes "$mime_types" '.mime_types = $mimes')
    
    # Tamanho total
    local total_size
    total_size=$(echo "$snapshots" | jq '[.[].length | tonumber] | add // 0')
    stats=$(echo "$stats" | jq --argjson size "$total_size" '.total_size_bytes = $size')
    
    echo "$stats"
}

# Comparar versões
compare_versions() {
    local snapshots="$1"
    local comparisons="[]"
    
    # Pegar amostras a cada 5 anos
    local years=("2010" "2015" "2020" "2023")
    
    for year in "${years[@]}"; do
        local snapshot
        snapshot=$(echo "$snapshots" | jq --arg year "$year" '[.[] | select(.timestamp | startswith($year))] | first')
        
        if [[ -n "$snapshot" ]] && [[ "$snapshot" != "null" ]]; then
            local timestamp
            timestamp=$(echo "$snapshot" | jq -r '.timestamp')
            local url
            url=$(echo "$snapshot" | jq -r '.url')
            local archive_url="https://web.archive.org/web/${timestamp}/${url}"
            
            comparisons=$(echo "$comparisons" | jq \
                --arg year "$year" \
                --arg ts "$timestamp" \
                --arg url "$archive_url" \
                '. += [{
                    "year": $year,
                    "timestamp": $ts,
                    "archive_url": $url
                }]')
        fi
    done
    
    echo "$comparisons"
}

# Salvar URL atual no Wayback
save_to_wayback() {
    local target="$1"
    local result="{}"
    
    local url="${WAYBACK_SAVE}/${target}"
    local response
    response=$(curl -s -I "$url" 2>/dev/null)
    
    if [[ -n "$response" ]]; then
        local status
        status=$(echo "$response" | head -1 | awk '{print $2}')
        
        if [[ "$status" == "200" ]]; then
            result=$(echo "$result" | jq '.success = true')
            
            # Extrair URL do job
            local job_url
            job_url=$(echo "$response" | grep -i "location:" | awk '{print $2}' | tr -d '\r')
            
            if [[ -n "$job_url" ]]; then
                result=$(echo "$result" | jq --arg url "$job_url" '.job_url = $url')
            fi
        else
            result=$(echo "$result" | jq --arg code "$status" '.success = false | .status_code = $code')
        fi
    fi
    
    echo "$result"
}

# Buscar URLs específicas
search_urls() {
    local target="$1"
    local pattern="$2"
    local results="[]"
    
    local url="${WAYBACK_CDX}?url=${target}&output=json&filter=original:${pattern}"
    local response
    response=$(curl -s "$url" 2>/dev/null)
    
    if [[ -n "$response" ]] && [[ "$response" != "[]" ]]; then
        results=$(echo "$response" | jq -c '[.[1:][] | {
            timestamp: .[0],
            url: .[1],
            original: .[2]
        }]' 2>/dev/null)
    fi
    
    echo "$results"
}

# Buscar por tipo de arquivo
search_by_filetype() {
    local target="$1"
    local filetype="$2"
    local results="[]"
    
    local url="${WAYBACK_CDX}?url=${target}&output=json&filter=mimetype:.*${filetype}"
    local response
    response=$(curl -s "$url" 2>/dev/null)
    
    if [[ -n "$response" ]] && [[ "$response" != "[]" ]]; then
        results=$(echo "$response" | jq -c '[.[1:][] | {
            timestamp: .[0],
            url: .[1],
            mime: .[2],
            digest: .[4]
        }]' 2>/dev/null)
    fi
    
    echo "$results"
}

# Baixar snapshot
download_snapshot() {
    local timestamp="$1"
    local url="$2"
    local output_file="$3"
    
    local archive_url="https://web.archive.org/web/${timestamp}/${url}"
    
    curl -s -L -o "$output_file" "$archive_url" 2>/dev/null
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        echo "{\"success\": true, \"file\": \"$output_file\"}"
    else
        echo "{\"success\": false, \"error\": \"Download failed\"}"
    fi
}

# Exportar funções
export -f init_wayback query_wayback search_urls search_by_filetype download_snapshot