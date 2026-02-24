#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Paste Sites Intelligence Module
# =============================================================================

MODULE_NAME="Paste Sites Intelligence"
MODULE_DESC="Search and analyze content from paste sites"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# Lista de paste sites
declare -A PASTE_SITES=(
    ["pastebin"]="https://pastebin.com"
    ["paste.ee"]="https://paste.ee"
    ["dpaste"]="https://dpaste.com"
    ["ghostbin"]="https://ghostbin.com"
    ["hastebin"]="https://hastebin.com"
    ["rentry"]="https://rentry.co"
    ["privatebin"]="https://privatebin.net"
    ["zerobin"]="https://zerobin.net"
    ["paste.ubuntu"]="https://paste.ubuntu.com"
    ["paste.debian"]="https://paste.debian.net"
    ["paste.opensuse"]="https://paste.opensuse.org"
    ["gist.github"]="https://gist.github.com"
    ["slexy"]="https://slexy.org"
    ["controlc"]="https://controlc.com"
    ["pastie"]="https://pastie.org"
    ["codepad"]="https://codepad.org"
    ["ideone"]="https://ideone.com"
    ["rextester"]="https://rextester.com"
    ["compiler"]="https://compiler.ph"
    ["onlinegdb"]="https://onlinegdb.com"
)

# APIs de busca para paste sites
declare -A PASTE_APIS=(
    ["pastebin"]="https://psbdmp.ws/api/search/%s"
    ["gist.github"]="https://api.github.com/search/code?q=%s"
    ["rentry"]="https://rentry.co/search/?q=%s"
)

# Inicializar módulo
init_paste_sites() {
    log "INFO" "Initializing Paste Sites Intelligence module" "PASTE"
    
    # Verificar dependências
    local deps=("curl" "jq" "grep" "sed")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "PASTE"
        return 1
    fi
    
    return 0
}

# Função principal
search_paste_sites() {
    local target="$1"
    local output_dir="$2"
    
    log "INTEL" "Starting paste sites search for: $target" "PASTE"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/pastes"
    mkdir -p "$results_dir"
    
    local results="{}"
    
    results=$(echo "$results" | jq --arg target "$target" '.target = $target')
    
    # 1. Buscar via APIs
    log "INFO" "Searching via APIs" "PASTE"
    local api_results
    api_results=$(search_via_apis "$target")
    results=$(echo "$results" | jq --argjson api "$api_results" '.api_results = $api')
    
    # 2. Buscar via Google
    log "INFO" "Searching via Google" "PASTE"
    local google_results
    google_results=$(search_via_google "$target")
    results=$(echo "$results" | jq --argjson google "$google_results" '.google_results = $google')
    
    # 3. Buscar via Bing
    log "INFO" "Searching via Bing" "PASTE"
    local bing_results
    bing_results=$(search_via_bing "$target")
    results=$(echo "$results" | jq --argjson bing "$bing_results" '.bing_results = $bing')
    
    # 4. Buscar via DuckDuckGo
    log "INFO" "Searching via DuckDuckGo" "PASTE"
    local ddg_results
    ddg_results=$(search_via_duckduckgo "$target")
    results=$(echo "$results" | jq --argjson ddg "$ddg_results" '.duckduckgo_results = $ddg')
    
    # 5. Buscar em sites específicos
    log "INFO" "Searching individual paste sites" "PASTE"
    local individual_results
    individual_results=$(search_individual_sites "$target")
    results=$(echo "$results" | jq --argjson ind "$individual_results" '.individual_sites = $ind')
    
    # 6. Coletar conteúdo dos pastes encontrados
    log "INFO" "Collecting paste contents" "PASTE"
    local paste_contents
    paste_contents=$(collect_paste_contents "$results")
    results=$(echo "$results" | jq --argjson contents "$paste_contents" '.paste_contents = $contents')
    
    # 7. Analisar padrões nos pastes
    log "INFO" "Analyzing patterns" "PASTE"
    local patterns
    patterns=$(analyze_paste_patterns "$paste_contents")
    results=$(echo "$results" | jq --argjson patterns "$patterns" '.patterns = $patterns')
    
    # 8. Extrair informações sensíveis
    log "INFO" "Extracting sensitive information" "PASTE"
    local sensitive
    sensitive=$(extract_sensitive_info "$paste_contents")
    results=$(echo "$results" | jq --argjson sensitive "$sensitive" '.sensitive_info = $sensitive')
    
    # 9. Verificar credenciais
    log "INFO" "Checking for credentials" "PASTE"
    local credentials
    credentials=$(extract_credentials "$paste_contents")
    results=$(echo "$results" | jq --argjson creds "$credentials" '.credentials = $creds')
    
    # 10. Extrair URLs e domínios
    log "INFO" "Extracting URLs and domains" "PASTE"
    local urls
    urls=$(extract_urls_from_pastes "$paste_contents")
    results=$(echo "$results" | jq --argjson urls "$urls" '.urls = $urls')
    
    # 11. Extrair hashes
    log "INFO" "Extracting hashes" "PASTE"
    local hashes
    hashes=$(extract_hashes "$paste_contents")
    results=$(echo "$results" | jq --argjson hashes "$hashes" '.hashes = $hashes')
    
    # 12. Extrair endereços IP
    log "INFO" "Extracting IP addresses" "PASTE"
    local ips
    ips=$(extract_ips_from_pastes "$paste_contents")
    results=$(echo "$results" | jq --argjson ips "$ips" '.ips = $ips')
    
    # 13. Análise de linguagem
    log "INFO" "Analyzing language patterns" "PASTE"
    local language
    language=$(analyze_paste_language "$paste_contents")
    results=$(echo "$results" | jq --argjson lang "$language" '.language_analysis = $lang')
    
    # 14. Linha do tempo
    log "INFO" "Generating timeline" "PASTE"
    local timeline
    timeline=$(generate_paste_timeline "$results")
    results=$(echo "$results" | jq --argjson timeline "$timeline" '.timeline = $timeline')
    
    # 15. Score de risco
    log "INFO" "Calculating risk score" "PASTE"
    local risk
    risk=$(calculate_paste_risk "$results")
    results=$(echo "$results" | jq --argjson risk "$risk" '.risk_score = $risk')
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/pastes.json"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local total_pastes
    total_pastes=$(echo "$results" | jq '[.api_results[].pastes[], .google_results[].pastes[], .bing_results[].pastes[], .individual_sites[].pastes[]] | length')
    
    log "SUCCESS" "Paste sites search completed in ${duration}s - Found $total_pastes pastes" "PASTE"
    
    echo "$results"
}

# Buscar via APIs
search_via_apis() {
    local target="$1"
    local results="[]"
    
    for site in "${!PASTE_APIS[@]}"; do
        local api_url
        api_url=$(printf "${PASTE_APIS[$site]}" "$target")
        
        log "DEBUG" "Querying API for $site: $api_url" "PASTE"
        
        local response
        response=$(curl -s -A "Mozilla/5.0" --max-time 10 "$api_url" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            case "$site" in
                "pastebin")
                    local pastes
                    pastes=$(echo "$response" | jq -c '[.[] | {
                        id: .id,
                        title: .title,
                        date: .date,
                        size: .size,
                        url: "https://pastebin.com/\(.id)"
                    }]' 2>/dev/null)
                    
                    if [[ "$pastes" != "[]" ]] && [[ -n "$pastes" ]]; then
                        results=$(echo "$results" | jq --arg site "$site" --argjson pastes "$pastes" \
                            '. += [{"site": $site, "pastes": $pastes}]')
                    fi
                    ;;
                    
                "gist.github")
                    local pastes
                    pastes=$(echo "$response" | jq -c '[.items[] | {
                        id: .id,
                        title: .name,
                        url: .html_url,
                        repo: .repository.full_name
                    }]' 2>/dev/null)
                    
                    if [[ "$pastes" != "[]" ]] && [[ -n "$pastes" ]]; then
                        results=$(echo "$results" | jq --arg site "$site" --argjson pastes "$pastes" \
                            '. += [{"site": $site, "pastes": $pastes}]')
                    fi
                    ;;
            esac
        fi
        
        # Evitar rate limiting
        sleep 1
    done
    
    echo "$results"
}

# Buscar via Google
search_via_google() {
    local target="$1"
    local results="[]"
    
    # Dorks para cada site
    for site in "${!PASTE_SITES[@]}"; do
        local domain
        domain=$(echo "${PASTE_SITES[$site]}" | cut -d'/' -f3)
        
        local query="site:${domain} \"${target}\""
        local url="https://www.google.com/search?q=${query// /+}"
        
        log "DEBUG" "Google search for $site: $url" "PASTE"
        
        local response
        response=$(curl -s -A "Mozilla/5.0" -L --max-time 10 "$url" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            # Extrair resultados
            local paste_urls
            paste_urls=$(echo "$response" | grep -o 'https://[^"]*'"$domain"'[^"]*' | head -10)
            
            local pastes="[]"
            
            while IFS= read -r paste_url; do
                if [[ -n "$paste_url" ]]; then
                    # Extrair título
                    local title
                    title=$(echo "$response" | grep -o '<h3 class="[^"]*">[^<]*' | head -1 | sed 's/<[^>]*>//g')
                    
                    pastes=$(echo "$pastes" | jq --arg url "$paste_url" --arg title "$title" \
                        '. += [{"url": $url, "title": $title}]')
                fi
            done <<< "$paste_urls"
            
            if [[ "$pastes" != "[]" ]]; then
                results=$(echo "$results" | jq --arg site "$site" --argjson pastes "$pastes" \
                    '. += [{"site": $site, "pastes": $pastes, "source": "google"}]')
            fi
        fi
        
        # Evitar bloqueio
        sleep 2
    done
    
    echo "$results"
}

# Buscar via Bing
search_via_bing() {
    local target="$1"
    local results="[]"
    
    for site in "${!PASTE_SITES[@]}"; do
        local domain
        domain=$(echo "${PASTE_SITES[$site]}" | cut -d'/' -f3)
        
        local query="site:${domain} \"${target}\""
        local url="https://www.bing.com/search?q=${query// /+}"
        
        log "DEBUG" "Bing search for $site: $url" "PASTE"
        
        local response
        response=$(curl -s -A "Mozilla/5.0" -L --max-time 10 "$url" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            # Extrair URLs
            local paste_urls
            paste_urls=$(echo "$response" | grep -o 'https://[^"]*'"$domain"'[^"]*' | head -10)
            
            local pastes="[]"
            
            while IFS= read -r paste_url; do
                if [[ -n "$paste_url" ]]; then
                    pastes=$(echo "$pastes" | jq --arg url "$paste_url" '. += [{"url": $url}]')
                fi
            done <<< "$paste_urls"
            
            if [[ "$pastes" != "[]" ]]; then
                results=$(echo "$results" | jq --arg site "$site" --argjson pastes "$pastes" \
                    '. += [{"site": $site, "pastes": $pastes, "source": "bing"}]')
            fi
        fi
        
        sleep 1
    done
    
    echo "$results"
}

# Buscar via DuckDuckGo
search_via_duckduckgo() {
    local target="$1"
    local results="[]"
    
    for site in "${!PASTE_SITES[@]}"; do
        local domain
        domain=$(echo "${PASTE_SITES[$site]}" | cut -d'/' -f3)
        
        local query="site:${domain} \"${target}\""
        local url="https://duckduckgo.com/html/?q=${query// /+}"
        
        log "DEBUG" "DuckDuckGo search for $site: $url" "PASTE"
        
        local response
        response=$(curl -s -A "Mozilla/5.0" -L --max-time 10 "$url" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            # Extrair URLs
            local paste_urls
            paste_urls=$(echo "$response" | grep -o 'https://[^"]*'"$domain"'[^"]*' | head -10)
            
            local pastes="[]"
            
            while IFS= read -r paste_url; do
                if [[ -n "$paste_url" ]]; then
                    pastes=$(echo "$pastes" | jq --arg url "$paste_url" '. += [{"url": $url}]')
                fi
            done <<< "$paste_urls"
            
            if [[ "$pastes" != "[]" ]]; then
                results=$(echo "$results" | jq --arg site "$site" --argjson pastes "$pastes" \
                    '. += [{"site": $site, "pastes": $pastes, "source": "duckduckgo"}]')
            fi
        fi
        
        sleep 1
    done
    
    echo "$results"
}

# Buscar em sites específicos
search_individual_sites() {
    local target="$1"
    local results="[]"
    
    for site in "${!PASTE_SITES[@]}"; do
        local base_url="${PASTE_SITES[$site]}"
        
        # Tentar busca direta (se o site suportar)
        case "$site" in
            "rentry")
                local search_url="https://rentry.co/search/?q=${target}"
                ;;
            "pastebin")
                local search_url="https://pastebin.com/search?q=${target}"
                ;;
            *)
                # Tentar URL padrão de busca
                local search_url="${base_url}/search?q=${target}"
                ;;
        esac
        
        log "DEBUG" "Direct search on $site: $search_url" "PASTE"
        
        local response
        response=$(curl -s -A "Mozilla/5.0" -L --max-time 10 "$search_url" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            # Procurar por links de pastes
            local paste_links
            paste_links=$(echo "$response" | grep -o 'href="[^"]*"' | grep -E 'paste|raw|view' | head -10)
            
            local pastes="[]"
            
            while IFS= read -r link; do
                if [[ -n "$link" ]]; then
                    local paste_url="${base_url}$(echo "$link" | cut -d'"' -f2)"
                    pastes=$(echo "$pastes" | jq --arg url "$paste_url" '. += [{"url": $url}]')
                fi
            done <<< "$paste_links"
            
            if [[ "$pastes" != "[]" ]]; then
                results=$(echo "$results" | jq --arg site "$site" --argjson pastes "$pastes" \
                    '. += [{"site": $site, "pastes": $pastes, "source": "direct"}]')
            fi
        fi
        
        sleep 1
    done
    
    echo "$results"
}

# Coletar conteúdo dos pastes
collect_paste_contents() {
    local search_results="$1"
    local contents="[]"
    
    # Extrair todas as URLs
    local all_urls
    all_urls=$(echo "$search_results" | jq -r '.api_results[].pastes[].url, .google_results[].pastes[].url, .bing_results[].pastes[].url, .individual_sites[].pastes[].url' 2>/dev/null | grep -v null | sort -u)
    
    local count=0
    while IFS= read -r url; do
        if [[ -n "$url" ]] && [[ $count -lt 50 ]]; then  # Limitar a 50 pastes
            log "DEBUG" "Fetching paste: $url" "PASTE"
            
            # Tentar obter raw content
            local raw_url
            
            # Converter para URL raw
            if [[ "$url" == *"pastebin.com"* ]]; then
                raw_url="${url/\/\//\/\/raw.}"
                [[ "$raw_url" != *"raw"* ]] && raw_url="${url}/raw"
            elif [[ "$url" == *"gist.github.com"* ]]; then
                raw_url="${url}.txt"
            elif [[ "$url" == *"rentry.co"* ]]; then
                raw_url="${url}/raw"
            else
                raw_url="$url"
            fi
            
            local content
            content=$(curl -s -L --max-time 10 "$raw_url" 2>/dev/null)
            
            if [[ -n "$content" ]]; then
                # Detectar data (se disponível)
                local date
                date=$(echo "$content" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
                
                contents=$(echo "$contents" | jq \
                    --arg url "$url" \
                    --arg content "$content" \
                    --arg date "$date" \
                    '. += [{
                        "url": $url,
                        "content": $content,
                        "date": $date,
                        "size": ($content | length)
                    }]')
                
                ((count++))
            fi
        fi
    done <<< "$all_urls"
    
    echo "$contents"
}

# Analisar padrões nos pastes
analyze_paste_patterns() {
    local paste_contents="$1"
    local patterns="[]"
    
    local pattern_list=(
        "password"
        "passwd"
        "credential"
        "login"
        "username"
        "email"
        "token"
        "api[_-]?key"
        "secret"
        "private[_-]?key"
        "ssh[_-]?key"
        "rsa[_-]?key"
        "aws[_-]?key"
        "azure[_-]?key"
        "gcp[_-]?key"
        "database"
        "connection[_-]?string"
        "jdbc"
        "mongodb"
        "mysql"
        "postgres"
        "redis"
        "elastic"
        "config"
        "configuration"
        "setting"
        "environment"
        ".env"
        "docker"
        "k8s"
        "kubernetes"
        "pod"
        "deployment"
    )
    
    echo "$paste_contents" | jq -c '.[]' | while read -r paste; do
        local url
        url=$(echo "$paste" | jq -r '.url')
        local content
        content=$(echo "$paste" | jq -r '.content')
        
        for pattern in "${pattern_list[@]}"; do
            if echo "$content" | grep -qi "$pattern"; then
                patterns=$(echo "$patterns" | jq \
                    --arg url "$url" \
                    --arg pattern "$pattern" \
                    '. += [{
                        "url": $url,
                        "pattern": $pattern,
                        "severity": "medium"
                    }]')
            fi
        done
    done
    
    echo "$patterns" | jq 'unique_by(.url)'
}

# Extrair informações sensíveis
extract_sensitive_info() {
    local paste_contents="$1"
    local sensitive="[]"
    
    echo "$paste_contents" | jq -c '.[]' | while read -r paste; do
        local url
        url=$(echo "$paste" | jq -r '.url')
        local content
        content=$(echo "$paste" | jq -r '.content')
        
        # Procurar por palavras-chave de alta sensibilidade
        if echo "$content" | grep -qi "confidential\|secret\|classified\|restricted\|internal only"; then
            sensitive=$(echo "$sensitive" | jq --arg url "$url" --arg type "confidential" \
                '. += [{"url": $url, "type": "confidential", "severity": "high"}]')
        fi
        
        # Procurar por dados financeiros
        if echo "$content" | grep -qE 'credit.?card|visa|mastercard|amex|paypal|bank.*account|routing.*number'; then
            sensitive=$(echo "$sensitive" | jq --arg url "$url" --arg type "financial" \
                '. += [{"url": $url, "type": "financial", "severity": "critical"}]')
        fi
        
        # Procurar por dados pessoais
        if echo "$content" | grep -qE 'ssn|social.?security|cpf|passport|driver.?s.?license|national.?id'; then
            sensitive=$(echo "$sensitive" | jq --arg url "$url" --arg type "pii" \
                '. += [{"url": $url, "type": "pii", "severity": "critical"}]')
        fi
        
        # Procurar por credenciais de banco de dados
        if echo "$content" | grep -qE 'mongodb://|mysql://|postgresql://|redis://|jdbc:'; then
            sensitive=$(echo "$sensitive" | jq --arg url "$url" --arg type "database_url" \
                '. += [{"url": $url, "type": "database_url", "severity": "high"}]')
        fi
    done
    
    echo "$sensitive"
}

# Extrair credenciais
extract_credentials() {
    local paste_contents="$1"
    local credentials="[]"
    
    echo "$paste_contents" | jq -c '.[]' | while read -r paste; do
        local url
        url=$(echo "$paste" | jq -r '.url')
        local content
        content=$(echo "$paste" | jq -r '.content')
        
        # Procurar por pares username:password
        local cred_pairs
        cred_pairs=$(echo "$content" | grep -oE '[a-zA-Z0-9._%+-]+:[a-zA-Z0-9!@#$%^&*()_+]+' | head -20)
        
        while IFS= read -r cred; do
            if [[ -n "$cred" ]]; then
                local username
                username=$(echo "$cred" | cut -d':' -f1)
                local password
                password=$(echo "$cred" | cut -d':' -f2)
                
                credentials=$(echo "$credentials" | jq \
                    --arg url "$url" \
                    --arg user "$username" \
                    --arg pass "$password" \
                    '. += [{
                        "url": $url,
                        "username": $user,
                        "password": $pass,
                        "type": "basic_auth"
                    }]')
            fi
        done <<< "$cred_pairs"
        
        # Procurar por strings no formato user@domain:password
        local email_pass
        email_pass=$(echo "$content" | grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}:[a-zA-Z0-9!@#$%^&*()_+]+' | head -10)
        
        while IFS= read -r cred; do
            if [[ -n "$cred" ]]; then
                local email
                email=$(echo "$cred" | cut -d':' -f1)
                local password
                password=$(echo "$cred" | cut -d':' -f2)
                
                credentials=$(echo "$credentials" | jq \
                    --arg url "$url" \
                    --arg email "$email" \
                    --arg pass "$password" \
                    '. += [{
                        "url": $url,
                        "email": $email,
                        "password": $pass,
                        "type": "email_auth"
                    }]')
            fi
        done <<< "$email_pass"
        
        # Procurar por tokens
        local tokens
        tokens=$(echo "$content" | grep -oE '[a-zA-Z0-9_-]{20,}' | head -20)
        
        while IFS= read -r token; do
            if [[ -n "$token" ]]; then
                credentials=$(echo "$credentials" | jq \
                    --arg url "$url" \
                    --arg token "$token" \
                    '. += [{
                        "url": $url,
                        "token": $token,
                        "type": "api_token"
                    }]')
            fi
        done <<< "$tokens"
    done
    
    echo "$credentials"
}

# Extrair URLs dos pastes
extract_urls_from_pastes() {
    local paste_contents="$1"
    local all_urls="[]"
    
    echo "$paste_contents" | jq -c '.[]' | while read -r paste; do
        local url
        url=$(echo "$paste" | jq -r '.url')
        local content
        content=$(echo "$paste" | jq -r '.content')
        
        # Extrair URLs
        local urls
        urls=$(echo "$content" | grep -oE 'https?://[a-zA-Z0-9./?=_-]+' | sort -u)
        
        while IFS= read -r extracted_url; do
            if [[ -n "$extracted_url" ]]; then
                all_urls=$(echo "$all_urls" | jq \
                    --arg source "$url" \
                    --arg found "$extracted_url" \
                    '. += [{
                        "source_paste": $source,
                        "url": $found
                    }]')
            fi
        done <<< "$urls"
    done
    
    echo "$all_urls"
}

# Extrair hashes
extract_hashes() {
    local paste_contents="$1"
    local all_hashes="[]"
    
    echo "$paste_contents" | jq -c '.[]' | while read -r paste; do
        local url
        url=$(echo "$paste" | jq -r '.url')
        local content
        content=$(echo "$paste" | jq -r '.content')
        
        # MD5
        local md5s
        md5s=$(echo "$content" | grep -oE '[a-fA-F0-9]{32}' | sort -u)
        
        while IFS= read -r hash; do
            if [[ -n "$hash" ]]; then
                all_hashes=$(echo "$all_hashes" | jq \
                    --arg source "$url" \
                    --arg hash "$hash" \
                    --arg type "md5" \
                    '. += [{
                        "source_paste": $source,
                        "hash": $hash,
                        "type": $type
                    }]')
            fi
        done <<< "$md5s"
        
        # SHA1
        local sha1s
        sha1s=$(echo "$content" | grep -oE '[a-fA-F0-9]{40}' | sort -u)
        
        while IFS= read -r hash; do
            if [[ -n "$hash" ]]; then
                all_hashes=$(echo "$all_hashes" | jq \
                    --arg source "$url" \
                    --arg hash "$hash" \
                    --arg type "sha1" \
                    '. += [{
                        "source_paste": $source,
                        "hash": $hash,
                        "type": $type
                    }]')
            fi
        done <<< "$sha1s"
        
        # SHA256
        local sha256s
        sha256s=$(echo "$content" | grep -oE '[a-fA-F0-9]{64}' | sort -u)
        
        while IFS= read -r hash; do
            if [[ -n "$hash" ]]; then
                all_hashes=$(echo "$all_hashes" | jq \
                    --arg source "$url" \
                    --arg hash "$hash" \
                    --arg type "sha256" \
                    '. += [{
                        "source_paste": $source,
                        "hash": $hash,
                        "type": $type
                    }]')
            fi
        done <<< "$sha256s"
    done
    
    echo "$all_hashes"
}

# Extrair IPs dos pastes
extract_ips_from_pastes() {
    local paste_contents="$1"
    local all_ips="[]"
    
    echo "$paste_contents" | jq -c '.[]' | while read -r paste; do
        local url
        url=$(echo "$paste" | jq -r '.url')
        local content
        content=$(echo "$paste" | jq -r '.content')
        
        # IPv4
        local ipv4s
        ipv4s=$(echo "$content" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u)
        
        while IFS= read -r ip; do
            if [[ -n "$ip" ]] && validate_ip "$ip"; then
                all_ips=$(echo "$all_ips" | jq \
                    --arg source "$url" \
                    --arg ip "$ip" \
                    '. += [{
                        "source_paste": $source,
                        "ip": $ip
                    }]')
            fi
        done <<< "$ipv4s"
    done
    
    echo "$all_ips"
}

# Analisar linguagem dos pastes
analyze_paste_language() {
    local paste_contents="$1"
    local analysis="{}"
    
    local total_size=0
    local total_pastes=0
    local programming_langs="{}"
    
    echo "$paste_contents" | jq -c '.[]' | while read -r paste; do
        local content
        content=$(echo "$paste" | jq -r '.content')
        local size
        size=$(echo "$paste" | jq -r '.size')
        
        total_size=$((total_size + size))
        total_pastes=$((total_pastes + 1))
        
        # Detectar linguagem de programação
        if echo "$content" | grep -qi "import\|def\|class\|print\|if __name__"; then
            programming_langs=$(echo "$programming_langs" | jq '.python += 1')
        elif echo "$content" | grep -qi "function\|var\|let\|const\|console.log\|document\|window"; then
            programming_langs=$(echo "$programming_langs" | jq '.javascript += 1')
        elif echo "$content" | grep -qi "public class\|private void\|System.out\|@Override"; then
            programming_langs=$(echo "$programming_langs" | jq '.java += 1')
        elif echo "$content" | grep -qi "#include\|int main\|cout\|printf\|scanf"; then
            programming_langs=$(echo "$programming_langs" | jq '.cpp += 1')
        elif echo "$content" | grep -qi "package main\|func main\|fmt\.Println"; then
            programming_langs=$(echo "$programming_langs" | jq '.go += 1')
        elif echo "$content" | grep -qi "require\|gem\|def\|end\|puts\|rails"; then
            programming_langs=$(echo "$programming_langs" | jq '.ruby += 1')
        elif echo "$content" | grep -qi "<?php\|echo\|function\$"; then
            programming_langs=$(echo "$programming_langs" | jq '.php += 1')
        fi
    done
    
    analysis=$(echo "$analysis" | jq \
        --argjson total "$total_pastes" \
        --argjson size "$total_size" \
        --argjson langs "$programming_langs" \
        '{
            total_pastes: $total,
            total_size: $size,
            programming_languages: $langs
        }')
    
    echo "$analysis"
}

# Gerar timeline de pastes
generate_paste_timeline() {
    local results="$1"
    local timeline="[]"
    
    # Extrair datas de todos os pastes
    local all_dates
    all_dates=$(echo "$results" | jq -r '.paste_contents[].date' 2>/dev/null | grep -v null)
    
    # Contar por mês
    while IFS= read -r date; do
        if [[ -n "$date" ]]; then
            local month
            month=$(echo "$date" | cut -d'-' -f1-2)
            
            timeline=$(echo "$timeline" | jq --arg month "$month" '.[] | select(.month == $month) | .count += 1')
            
            if [[ -z "$timeline" ]]; then
                timeline=$(echo "$timeline" | jq --arg month "$month" '. += [{"month": $month, "count": 1}]')
            fi
        fi
    done <<< "$all_dates"
    
    if [[ "$timeline" == "[]" ]]; then
        timeline=$(echo "$timeline" | jq '. += [{"note": "No dates available"}]')
    else
        timeline=$(echo "$timeline" | jq 'sort_by(.month)')
    fi
    
    echo "$timeline"
}

# Calcular score de risco
calculate_paste_risk() {
    local results="$1"
    local score=0
    
    # Número total de pastes
    local total_pastes
    total_pastes=$(echo "$results" | jq '.paste_contents | length // 0')
    score=$((score + total_pastes * 5))
    
    # Credenciais encontradas
    local cred_count
    cred_count=$(echo "$results" | jq '.credentials | length // 0')
    score=$((score + cred_count * 20))
    
    # Informações sensíveis
    local sensitive_count
    sensitive_count=$(echo "$results" | jq '.sensitive_info | length // 0')
    score=$((score + sensitive_count * 15))
    
    # Padrões suspeitos
    local pattern_count
    pattern_count=$(echo "$results" | jq '.patterns | length // 0')
    score=$((score + pattern_count * 10))
    
    # Hashes (possíveis senhas)
    local hash_count
    hash_count=$(echo "$results" | jq '.hashes | length // 0')
    score=$((score + hash_count * 8))
    
    # IPs expostos
    local ip_count
    ip_count=$(echo "$results" | jq '.ips | length // 0')
    score=$((score + ip_count * 5))
    
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
export -f init_paste_sites search_paste_sites