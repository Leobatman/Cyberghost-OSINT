#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Data Breach Checker Module
# =============================================================================

MODULE_NAME="Data Breach Checker"
MODULE_DESC="Check if credentials have been exposed in data breaches"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# Bancos de dados de breaches conhecidas
declare -A BREACH_DATABASES=(
    ["haveibeenpwned"]="https://haveibeenpwned.com/api/v3"
    ["snusbase"]="https://snusbase.com/api"
    ["dehashed"]="https://api.dehashed.com"
    ["leakcheck"]="https://leakcheck.net/api"
    ["breachdirectory"]="https://breachdirectory.org/api"
    ["scatteredsecrets"]="https://scatteredsecrets.com/api"
)

# Breaches famosas
declare -A FAMOUS_BREACHES=(
    ["Adobe"]="2013-10-04"
    ["LinkedIn"]="2012-05-05"
    ["MySpace"]="2016-05-31"
    ["Dropbox"]="2012-07-01"
    ["Tumblr"]="2013-02-01"
    ["Last.fm"]="2012-03-22"
    ["Yahoo"]="2013-08-01"
    ["eBay"]="2014-05-21"
    ["Equifax"]="2017-05-01"
    ["Marriott"]="2018-11-30"
    ["Facebook"]="2019-09-01"
    ["Twitter"]="2018-05-01"
    ["Canva"]="2019-05-24"
    ["Dubsmash"]="2018-12-01"
    ["Collection1"]="2019-01-07"
    ["Collection2"]="2019-01-07"
    ["Collection3"]="2019-01-07"
    ["Collection4"]="2019-01-07"
    ["Collection5"]="2019-01-07"
    ["AntiPublic"]="2021-01-01"
    ["NZBV"]="2020-01-01"
    ["Exploit.in"]="2016-10-01"
)

# Inicializar módulo
init_breach_checker() {
    log "INFO" "Initializing Data Breach Checker module" "BREACH"
    
    # Verificar dependências
    local deps=("curl" "jq" "grep" "sed" "openssl")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "BREACH"
        return 1
    fi
    
    return 0
}

# Função principal
check_breaches() {
    local target="$1"
    local output_dir="$2"
    
    log "INTEL" "Starting data breach check for: $target" "BREACH"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/breaches"
    mkdir -p "$results_dir"
    
    local results="{}"
    
    results=$(echo "$results" | jq --arg target "$target" '.target = $target')
    
    # Determinar tipo de alvo (email, username, hash)
    local target_type
    target_type=$(determine_target_type "$target")
    results=$(echo "$results" | jq --arg type "$target_type" '.target_type = $type')
    
    # 1. Have I Been Pwned
    log "INFO" "Checking Have I Been Pwned" "BREACH"
    local hibp_results
    hibp_results=$(check_hibp_breaches "$target")
    results=$(echo "$results" | jq --argjson hibp "$hibp_results" '.haveibeenpwned = $hibp')
    
    # 2. Verificar em bancos de dados locais
    log "INFO" "Checking local breach databases" "BREACH"
    local local_results
    local_results=$(check_local_breaches "$target")
    results=$(echo "$results" | jq --argjson local "$local_results" '.local_databases = $local')
    
    # 3. Dehashed (se tiver API)
    log "INFO" "Checking Dehashed" "BREACH"
    local dehashed_results
    dehashed_results=$(check_dehashed "$target")
    results=$(echo "$results" | jq --argjson dehashed "$dehashed_results" '.dehashed = $dehashed')
    
    # 4. Snusbase (se tiver API)
    log "INFO" "Checking Snusbase" "BREACH"
    local snusbase_results
    snusbase_results=$(check_snusbase "$target")
    results=$(echo "$results" | jq --argjson snusbase "$snusbase_results" '.snusbase = $snusbase')
    
    # 5. LeakCheck (se tiver API)
    log "INFO" "Checking LeakCheck" "BREACH"
    local leakcheck_results
    leakcheck_results=$(check_leakcheck "$target")
    results=$(echo "$results" | jq --argjson leakcheck "$leakcheck_results" '.leakcheck = $leakcheck')
    
    # 6. BreachDirectory (se tiver API)
    log "INFO" "Checking BreachDirectory" "BREACH"
    local breachdir_results
    breachdir_results=$(check_breachdirectory "$target")
    results=$(echo "$results" | jq --argjson breachdir "$breachdir_results" '.breachdirectory = $breachdir')
    
    # 7. Verificar em famosas breaches
    log "INFO" "Checking famous breaches" "BREACH"
    local famous_results
    famous_results=$(check_famous_breaches "$target")
    results=$(echo "$results" | jq --argjson famous "$famous_results" '.famous_breaches = $famous')
    
    # 8. Verificar versões de senha (hash)
    if [[ "$target_type" == "hash" ]]; then
        log "INFO" "Checking hash against known passwords" "BREACH"
        local hash_results
        hash_results=$(check_hash_database "$target")
        results=$(echo "$results" | jq --argjson hash "$hash_results" '.hash_lookup = $hash')
    fi
    
    # 9. Verificar em paste sites
    log "INFO" "Checking paste sites for breaches" "BREACH"
    local paste_results
    paste_results=$(check_paste_breaches "$target")
    results=$(echo "$results" | jq --argjson paste "$paste_results" '.paste_breaches = $paste')
    
    # 10. Verificar em fóruns
    log "INFO" "Checking forum mentions" "BREACH"
    local forum_results
    forum_results=$(check_forum_breaches "$target")
    results=$(echo "$results" | jq --argjson forum "$forum_results" '.forum_breaches = $forum')
    
    # 11. Correlacionar dados
    log "INFO" "Correlating breach data" "BREACH"
    local correlation
    correlation=$(correlate_breaches "$results")
    results=$(echo "$results" | jq --argjson corr "$correlation" '.correlation = $corr')
    
    # 12. Extrair senhas se disponíveis
    log "INFO" "Extracting passwords" "BREACH"
    local passwords
    passwords=$(extract_passwords "$results")
    results=$(echo "$results" | jq --argjson pass "$passwords" '.passwords = $pass')
    
    # 13. Estatísticas
    log "INFO" "Generating statistics" "BREACH"
    local stats
    stats=$(generate_breach_stats "$results")
    results=$(echo "$results" | jq --argjson stats "$stats" '.statistics = $stats')
    
    # 14. Score de risco
    log "INFO" "Calculating risk score" "BREACH"
    local risk
    risk=$(calculate_breach_risk "$results")
    results=$(echo "$results" | jq --argjson risk "$risk" '.risk_score = $risk')
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/breaches.json"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local breach_count
    breach_count=$(echo "$results" | jq '.correlation.total_breaches // 0')
    
    log "SUCCESS" "Breach check completed in ${duration}s - Found in $breach_count breaches" "BREACH"
    
    echo "$results"
}

# Determinar tipo de alvo
determine_target_type() {
    local target="$1"
    
    # Email
    if validate_email "$target"; then
        echo "email"
    # Hash (MD5, SHA1, SHA256)
    elif [[ "$target" =~ ^[a-fA-F0-9]{32}$ ]]; then
        echo "md5"
    elif [[ "$target" =~ ^[a-fA-F0-9]{40}$ ]]; then
        echo "sha1"
    elif [[ "$target" =~ ^[a-fA-F0-9]{64}$ ]]; then
        echo "sha256"
    # Username (sem @ e sem .)
    elif [[ ! "$target" =~ [@.] ]] && [[ ${#target} -gt 3 ]]; then
        echo "username"
    else
        echo "unknown"
    fi
}

# Verificar Have I Been Pwned
check_hibp_breaches() {
    local target="$1"
    
    if [[ -z "$HIBP_API_KEY" ]]; then
        echo "{\"error\": \"No HIBP API key\"}"
        return
    fi
    
    local url="https://haveibeenpwned.com/api/v3/breachedaccount/${target}"
    local response
    response=$(curl -s -H "hibp-api-key: ${HIBP_API_KEY}" -H "user-agent: CYBERGHOST-OSINT" "$url" 2>/dev/null)
    
    if [[ -z "$response" ]] || [[ "$response" == *"404"* ]]; then
        echo "[]"
        return
    fi
    
    # Processar breaches
    local breaches
    breaches=$(echo "$response" | jq '[.[] | {
        name: .Name,
        domain: .Domain,
        breach_date: .BreachDate,
        added_date: .AddedDate,
        compromised_data: .DataClasses,
        description: .Description,
        logo: .LogoPath
    }]' 2>/dev/null)
    
    echo "$breaches"
}

# Verificar bancos de dados locais
check_local_breaches() {
    local target="$1"
    local results="[]"
    
    local breach_dir="${DATABASES_DIR}/breaches"
    
    if [[ ! -d "$breach_dir" ]]; then
        echo "[]"
        return
    fi
    
    # Verificar em cada arquivo de breach
    for breach_file in "$breach_dir"/*.txt; do
        if [[ -f "$breach_file" ]]; then
            local breach_name
            breach_name=$(basename "$breach_file" .txt)
            
            # Buscar target no arquivo
            if grep -q -i "$target" "$breach_file" 2>/dev/null; then
                # Extrair linha completa (se possível)
                local line
                line=$(grep -i "$target" "$breach_file" | head -1)
                
                results=$(echo "$results" | jq \
                    --arg name "$breach_name" \
                    --arg line "$line" \
                    '. += [{
                        "breach": $name,
                        "source": "local",
                        "matched_line": $line
                    }]')
            fi
        fi
    done
    
    echo "$results"
}

# Verificar Dehashed
check_dehashed() {
    local target="$1"
    
    if [[ -z "$DEHASHED_API_KEY" ]]; then
        echo "{\"error\": \"No Dehashed API key\"}"
        return
    fi
    
    local url="https://api.dehashed.com/search?query=${target}"
    local response
    response=$(curl -s -u "${DEHASHED_API_KEY}:" "$url" 2>/dev/null)
    
    if [[ -z "$response" ]] || [[ "$response" == *"error"* ]]; then
        echo "[]"
        return
    fi
    
    # Processar resultados
    local entries
    entries=$(echo "$response" | jq -c '.entries // []' 2>/dev/null)
    
    echo "$entries"
}

# Verificar Snusbase
check_snusbase() {
    local target="$1"
    
    if [[ -z "$SNUSBASE_API_KEY" ]]; then
        echo "{\"error\": \"No Snusbase API key\"}"
        return
    fi
    
    local url="https://snusbase.com/api/v1/search"
    local response
    response=$(curl -s -X POST -H "Authorization: ${SNUSBASE_API_KEY}" \
        -d "type=email&term=${target}" "$url" 2>/dev/null)
    
    if [[ -z "$response" ]] || [[ "$response" == *"error"* ]]; then
        echo "[]"
        return
    fi
    
    # Processar resultados
    local results
    results=$(echo "$response" | jq -c '.results // []' 2>/dev/null)
    
    echo "$results"
}

# Verificar LeakCheck
check_leakcheck() {
    local target="$1"
    
    if [[ -z "$LEAKCHECK_API_KEY" ]]; then
        echo "{\"error\": \"No LeakCheck API key\"}"
        return
    fi
    
    local url="https://leakcheck.net/api/public?key=${LEAKCHECK_API_KEY}&check=${target}"
    local response
    response=$(curl -s "$url" 2>/dev/null)
    
    if [[ -z "$response" ]] || [[ "$response" == *"error"* ]]; then
        echo "[]"
        return
    fi
    
    # Processar resultados
    local results
    results=$(echo "$response" | jq -c '{
        found: .success,
        sources: .sources,
        passwords: .found // []
    }' 2>/dev/null)
    
    echo "$results"
}

# Verificar BreachDirectory
check_breachdirectory() {
    local target="$1"
    
    if [[ -z "$BREACHDIRECTORY_API_KEY" ]]; then
        echo "{\"error\": \"No BreachDirectory API key\"}"
        return
    fi
    
    local url="https://breachdirectory.org/api/v1/search?query=${target}"
    local response
    response=$(curl -s -H "x-api-key: ${BREACHDIRECTORY_API_KEY}" "$url" 2>/dev/null)
    
    if [[ -z "$response" ]] || [[ "$response" == *"error"* ]]; then
        echo "[]"
        return
    fi
    
    # Processar resultados
    local results
    results=$(echo "$response" | jq -c '{
        found: .success,
        breaches: .result.breaches,
        passwords: .result.hashes
    }' 2>/dev/null)
    
    echo "$results"
}

# Verificar em famosas breaches
check_famous_breaches() {
    local target="$1"
    local results="[]"
    
    # Para cada breach famosa, verificar em arquivo local
    for breach in "${!FAMOUS_BREACHES[@]}"; do
        local breach_date="${FAMOUS_BREACHES[$breach]}"
        local breach_file="${DATABASES_DIR}/famous/${breach}.txt"
        
        if [[ -f "$breach_file" ]]; then
            if grep -q -i "$target" "$breach_file" 2>/dev/null; then
                results=$(echo "$results" | jq \
                    --arg breach "$breach" \
                    --arg date "$breach_date" \
                    '. += [{
                        "breach": $breach,
                        "date": $date,
                        "source": "famous"
                    }]')
            fi
        fi
    done
    
    echo "$results"
}

# Verificar banco de dados de hashes
check_hash_database() {
    local hash="$1"
    local results="{}"
    
    local hash_type
    if [[ ${#hash} -eq 32 ]]; then
        hash_type="md5"
    elif [[ ${#hash} -eq 40 ]]; then
        hash_type="sha1"
    elif [[ ${#hash} -eq 64 ]]; then
        hash_type="sha256"
    else
        echo "{}"
        return
    fi
    
    local hash_file="${DATABASES_DIR}/hashes/${hash_type}.txt"
    
    if [[ -f "$hash_file" ]]; then
        local found
        found=$(grep -i "$hash" "$hash_file" 2>/dev/null)
        
        if [[ -n "$found" ]]; then
            # Extrair senha (se disponível no formato hash:password)
            local password
            password=$(echo "$found" | cut -d':' -f2)
            
            results=$(echo "$results" | jq \
                --arg type "$hash_type" \
                --arg hash "$hash" \
                --arg pass "$password" \
                '{
                    found: true,
                    hash_type: $type,
                    hash: $hash,
                    password: $pass
                }')
        fi
    fi
    
    echo "$results"
}

# Verificar paste sites
check_paste_breaches() {
    local target="$1"
    local results="[]"
    
    # Usar funcionalidade do módulo paste_sites
    if [[ -f "${PROJECT_ROOT}/src/modules/intel/paste_sites.sh" ]]; then
        # shellcheck source=/dev/null
        source "${PROJECT_ROOT}/src/modules/intel/paste_sites.sh"
        
        local paste_results
        paste_results=$(search_paste_sites "$target" "$TEMP_DIR" 2>/dev/null)
        
        if [[ -n "$paste_results" ]]; then
            local sensitive
            sensitive=$(echo "$paste_results" | jq -c '.sensitive_info // []' 2>/dev/null)
            local credentials
            credentials=$(echo "$paste_results" | jq -c '.credentials // []' 2>/dev/null)
            
            results=$(echo "$results" | jq \
                --argjson sensitive "$sensitive" \
                --argjson creds "$credentials" \
                '{
                    sensitive_info: $sensitive,
                    credentials: $creds
                }')
        fi
    fi
    
    echo "$results"
}

# Verificar fóruns
check_forum_breaches() {
    local target="$1"
    local results="[]"
    
    # Lista de fóruns conhecidos por vazar dados
    local forums=(
        "breachforums"
        "raidforums"
        "cracked"
        "nulled"
        "hackforums"
        "sinister"
        "onibiji"
    )
    
    for forum in "${forums[@]}"; do
        # Buscar via Google
        local query="site:${forum}.is OR site:${forum}.to ${target}"
        local url="https://www.google.com/search?q=${query// /+}"
        
        local response
        response=$(curl -s -A "Mozilla/5.0" -L --max-time 10 "$url" 2>/dev/null)
        
        if [[ "$response" =~ "About [0-9,]+ results" ]]; then
            local count
            count=$(echo "$response" | grep -o 'About [0-9,]* results' | grep -o '[0-9,]*' | sed 's/,//g')
            
            if [[ $count -gt 0 ]]; then
                results=$(echo "$results" | jq --arg forum "$forum" --argjson count "$count" \
                    '. += [{"forum": $forum, "mentions": $count}]')
            fi
        fi
        
        sleep 1
    done
    
    echo "$results"
}

# Correlacionar dados de breaches
correlate_breaches() {
    local results="$1"
    local correlation="{}"
    
    # Coletar todas as breaches
    local all_breaches="[]"
    
    # HIBP
    local hibp_breaches
    hibp_breaches=$(echo "$results" | jq -c '.haveibeenpwned // []')
    all_breaches=$(echo "$all_breaches" | jq --argjson hibp "$hibp_breaches" '. + $hibp')
    
    # Local
    local local_breaches
    local_breaches=$(echo "$results" | jq -c '.local_databases // []')
    all_breaches=$(echo "$all_breaches" | jq --argjson local "$local_breaches" '. + $local')
    
    # Famous
    local famous_breaches
    famous_breaches=$(echo "$results" | jq -c '.famous_breaches // []')
    all_breaches=$(echo "$all_breaches" | jq --argjson famous "$famous_breaches" '. + $famous')
    
    # Contar
    local total
    total=$(echo "$all_breaches" | jq 'length')
    
    # Breaches por ano
    local by_year="{}"
    echo "$all_breaches" | jq -c '.[]' | while read -r breach; do
        local date
        date=$(echo "$breach" | jq -r '.breach_date // .date // empty')
        
        if [[ -n "$date" ]]; then
            local year
            year=$(echo "$date" | cut -d'-' -f1)
            
            by_year=$(echo "$by_year" | jq --arg year "$year" '.[$year] += 1')
        fi
    done
    
    # Tipos de dados comprometidos
    local data_types="{}"
    echo "$all_breaches" | jq -c '.[]' | while read -r breach; do
        local classes
        classes=$(echo "$breach" | jq -c '.compromised_data // []')
        
        echo "$classes" | jq -r '.[]' | while read -r class; do
            if [[ -n "$class" ]]; then
                data_types=$(echo "$data_types" | jq --arg class "$class" '.[$class] += 1')
            fi
        done
    done
    
    correlation=$(echo "$correlation" | jq \
        --argjson total "$total" \
        --argjson by_year "$by_year" \
        --argjson types "$data_types" \
        '{
            total_breaches: $total,
            breaches_by_year: $by_year,
            compromised_data_types: $types
        }')
    
    echo "$correlation"
}

# Extrair senhas
extract_passwords() {
    local results="$1"
    local passwords="[]"
    
    # Dehashed
    local dehashed_pass
    dehashed_pass=$(echo "$results" | jq -c '.dehashed[].password' 2>/dev/null | grep -v null)
    
    while IFS= read -r pass; do
        if [[ -n "$pass" ]]; then
            passwords=$(echo "$passwords" | jq --arg pass "$pass" --arg source "dehashed" \
                '. += [{"password": $pass, "source": $source}]')
        fi
    done <<< "$dehashed_pass"
    
    # Snusbase
    local snusbase_pass
    snusbase_pass=$(echo "$results" | jq -c '.snusbase[].password' 2>/dev/null | grep -v null)
    
    while IFS= read -r pass; do
        if [[ -n "$pass" ]]; then
            passwords=$(echo "$passwords" | jq --arg pass "$pass" --arg source "snusbase" \
                '. += [{"password": $pass, "source": $source}]')
        fi
    done <<< "$snusbase_pass"
    
    # Paste breaches
    local paste_pass
    paste_pass=$(echo "$results" | jq -c '.paste_breaches.credentials[].password' 2>/dev/null | grep -v null)
    
    while IFS= read -r pass; do
        if [[ -n "$pass" ]]; then
            passwords=$(echo "$passwords" | jq --arg pass "$pass" --arg source "paste" \
                '. += [{"password": $pass, "source": $source}]')
        fi
    done <<< "$paste_pass"
    
    # Remover duplicatas
    passwords=$(echo "$passwords" | jq 'unique_by(.password)')
    
    echo "$passwords"
}

# Gerar estatísticas
generate_breach_stats() {
    local results="$1"
    local stats="{}"
    
    # Fontes de dados
    local sources=(
        "haveibeenpwned"
        "local_databases"
        "dehashed"
        "snusbase"
        "leakcheck"
        "breachdirectory"
        "famous_breaches"
        "paste_breaches"
        "forum_breaches"
    )
    
    for source in "${sources[@]}"; do
        local count
        count=$(echo "$results" | jq ".${source} | length // 0")
        stats=$(echo "$stats" | jq --arg source "$source" --argjson count "$count" '.sources[$source] = $count')
    done
    
    # Primeira e última breach
    local all_dates
    all_dates=$(echo "$results" | jq -r '.haveibeenpwned[].breach_date, .famous_breaches[].date, .local_databases[].date' 2>/dev/null | grep -v null | sort)
    
    local first_date
    first_date=$(echo "$all_dates" | head -1)
    local last_date
    last_date=$(echo "$all_dates" | tail -1)
    
    stats=$(echo "$stats" | jq \
        --arg first "$first_date" \
        --arg last "$last_date" \
        '{
            first_breach: $first,
            last_breach: $last,
            sources: .sources
        }')
    
    echo "$stats"
}

# Calcular risco de breach
calculate_breach_risk() {
    local results="$1"
    local score=0
    
    # Número total de breaches
    local total_breaches
    total_breaches=$(echo "$results" | jq '.correlation.total_breaches // 0')
    score=$((score + total_breaches * 10))
    
    # Senhas expostas
    local passwords_count
    passwords_count=$(echo "$results" | jq '.passwords | length // 0')
    score=$((score + passwords_count * 20))
    
    # Breaches recentes
    local current_year
    current_year=$(date +%Y)
    
    local recent_count=0
    echo "$results" | jq -r '.correlation.breaches_by_year | to_entries[] | "\(.key):\(.value)"' 2>/dev/null | while IFS= read -r line; do
        local year
        year=$(echo "$line" | cut -d':' -f1)
        local count
        count=$(echo "$line" | cut -d':' -f2)
        
        if [[ $year -ge $((current_year - 2)) ]]; then
            recent_count=$((recent_count + count))
        fi
    done
    
    score=$((score + recent_count * 15))
    
    # Dados sensíveis comprometidos
    local sensitive_types=("Passwords" "Email addresses" "Credit cards" "SSN" "Bank accounts")
    
    for type in "${sensitive_types[@]}"; do
        local type_count
        type_count=$(echo "$results" | jq ".correlation.compromised_data_types[\"$type\"] // 0")
        score=$((score + type_count * 25))
    done
    
    # Limitar entre 0 e 100
    if [[ $score -gt 100 ]]; then
        score=100
    fi
    
    local level
    if [[ $score -ge 70 ]]; then
        level="critical"
    elif [[ $score -ge 40 ]]; then
        level="high"
    elif [[ $score -ge 20 ]]; then
        level="medium"
    else
        level="low"
    fi
    
    echo "{\"score\": $score, \"level\": \"$level\"}"
}

# Exportar funções
export -f init_breach_checker check_breaches