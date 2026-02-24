#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Email Intelligence Module
# =============================================================================

MODULE_NAME="Email Intelligence"
MODULE_DESC="Gather intelligence from email addresses"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# Serviços de email
declare -A EMAIL_SERVICES=(
    ["gmail.com"]="Google"
    ["yahoo.com"]="Yahoo"
    ["outlook.com"]="Microsoft"
    ["hotmail.com"]="Microsoft"
    ["live.com"]="Microsoft"
    ["aol.com"]="AOL"
    ["protonmail.com"]="ProtonMail"
    ["mail.com"]="Mail.com"
    ["gmx.com"]="GMX"
    ["yandex.com"]="Yandex"
    ["icloud.com"]="Apple"
    ["zoho.com"]="Zoho"
)

# Breach databases
declare -A BREACH_DBS=(
    ["haveibeenpwned"]="Have I Been Pwned"
    ["scylla"]="Scylla"
    ["dehashed"]="DeHashed"
    ["snusbase"]="SnusBase"
    ["leakcheck"]="LeakCheck"
)

# Inicializar módulo
init_email_intel() {
    log "INFO" "Initializing Email Intelligence module" "EMAIL"
    
    # Verificar dependências
    local deps=("curl" "jq" "dig")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "EMAIL"
        return 1
    fi
    
    return 0
}

# Função principal
email_intelligence() {
    local email="$1"
    local output_dir="$2"
    
    log "INTEL" "Starting email intelligence for: $email" "EMAIL"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/email_intel"
    mkdir -p "$results_dir"
    
    local results="{}"
    
    # Extrair domínio e usuário
    local domain
    domain=$(echo "$email" | cut -d'@' -f2)
    local username
    username=$(echo "$email" | cut -d'@' -f1)
    
    results=$(echo "$results" | jq \
        --arg email "$email" \
        --arg domain "$domain" \
        --arg user "$username" \
        '{
            email: $email,
            domain: $domain,
            username: $user
        }')
    
    # 1. Verificar formato e validade
    log "INFO" "Validating email format" "EMAIL"
    local valid_format
    if validate_email "$email"; then
        valid_format=true
    else
        valid_format=false
    fi
    results=$(echo "$results" | jq --argjson valid "$valid_format" '.valid_format = $valid')
    
    # 2. Identificar provedor
    log "INFO" "Identifying email provider" "EMAIL"
    local provider
    provider=$(identify_provider "$domain")
    results=$(echo "$results" | jq --arg provider "$provider" '.provider = $provider')
    
    # 3. Verificar deliverabilidade
    log "INFO" "Checking email deliverability" "EMAIL"
    local deliverable
    deliverable=$(check_deliverability "$domain")
    results=$(echo "$results" | jq --argjson deliv "$deliverable" '.deliverable = $deliv')
    
    # 4. Verificar em breaches (Have I Been Pwned)
    log "INFO" "Checking Have I Been Pwned" "EMAIL"
    local hibp_results
    hibp_results=$(check_hibp "$email")
    results=$(echo "$results" | jq --argjson hibp "$hibp_results" '.haveibeenpwned = $hibp')
    
    # 5. Verificar em outras breaches
    log "INFO" "Checking other breach databases" "EMAIL"
    local breaches
    breaches=$(check_breaches "$email")
    results=$(echo "$results" | jq --argjson breaches "$breaches" '.breaches = $breaches')
    
    # 6. Verificar em redes sociais
    log "INFO" "Checking social media presence" "EMAIL"
    local social
    social=$(check_social_media "$email")
    results=$(echo "$results" | jq --argjson social "$social" '.social_media = $social')
    
    # 7. Verificar em GitHub
    log "INFO" "Checking GitHub" "EMAIL"
    local github
    github=$(check_github_email "$email")
    results=$(echo "$results" | jq --argjson github "$github" '.github = $github')
    
    # 8. Verificar gravatar
    log "INFO" "Checking Gravatar" "EMAIL"
    local gravatar
    gravatar=$(check_gravatar "$email")
    results=$(echo "$results" | jq --argjson gravatar "$gravatar" '.gravatar = $gravatar')
    
    # 9. Verificar PGP key
    log "INFO" "Checking PGP keys" "EMAIL"
    local pgp
    pgp=$(check_pgp_key "$email")
    results=$(echo "$results" | jq --argjson pgp "$pgp" '.pgp_key = $pgp')
    
    # 10. Verificar em paste sites
    log "INFO" "Checking paste sites" "EMAIL"
    local pastes
    pastes=$(check_paste_sites "$email")
    results=$(echo "$results" | jq --argjson pastes "$pastes" '.pastes = $pastes')
    
    # 11. Verificar documentos e metadados
    log "INFO" "Checking document metadata" "EMAIL"
    local docs
    docs=$(check_document_metadata "$email")
    results=$(echo "$results" | jq --argjson docs "$docs" '.documents = $docs')
    
    # 12. EmailRep.io
    log "INFO" "Checking EmailRep.io" "EMAIL"
    local emailrep
    emailrep=$(check_emailrep "$email")
    results=$(echo "$results" | jq --argjson emailrep "$emailrep" '.emailrep = $emailrep')
    
    # 13. Hunter.io
    log "INFO" "Checking Hunter.io" "EMAIL"
    local hunter
    hunter=$(check_hunter "$email")
    results=$(echo "$results" | jq --argjson hunter "$hunter" '.hunter = $hunter')
    
    # 14. Verificar se é disposable
    log "INFO" "Checking if disposable email" "EMAIL"
    local disposable
    disposable=$(check_disposable "$domain")
    results=$(echo "$results" | jq --argjson disposable "$disposable" '.disposable = $disposable')
    
    # 15. Verificar padrões de nome de usuário
    log "INFO" "Analyzing username patterns" "EMAIL"
    local name_info
    name_info=$(analyze_username "$username")
    results=$(echo "$results" | jq --argjson name "$name_info" '.username_analysis = $name')
    
    # Calcular risco
    log "INFO" "Calculating risk score" "EMAIL"
    local risk
    risk=$(calculate_email_risk "$results")
    results=$(echo "$results" | jq --argjson risk "$risk" '.risk = $risk')
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/email_intel.json"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local breach_count
    breach_count=$(echo "$breaches" | jq 'length')
    
    log "SUCCESS" "Email intelligence completed in ${duration}s - Found $breach_count breaches" "EMAIL"
    
    echo "$results"
}

# Identificar provedor de email
identify_provider() {
    local domain="$1"
    
    if [[ -n "${EMAIL_SERVICES[$domain]}" ]]; then
        echo "${EMAIL_SERVICES[$domain]}"
    else
        # Verificar MX records
        local mx
        mx=$(dig +short MX "$domain" 2>/dev/null | head -1)
        
        if [[ -n "$mx" ]]; then
            if echo "$mx" | grep -qi "google"; then
                echo "Google (Custom)"
            elif echo "$mx" | grep -qi "microsoft\|outlook"; then
                echo "Microsoft (Custom)"
            elif echo "$mx" | grep -qi "yahoo"; then
                echo "Yahoo (Custom)"
            else
                echo "Custom/Other"
            fi
        else
            echo "Unknown"
        fi
    fi
}

# Verificar deliverabilidade
check_deliverability() {
    local domain="$1"
    
    # Verificar MX records
    local mx
    mx=$(dig +short MX "$domain" 2>/dev/null)
    
    if [[ -n "$mx" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Verificar Have I Been Pwned
check_hibp() {
    local email="$1"
    
    if [[ -z "$HIBP_API_KEY" ]]; then
        echo "{\"error\": \"No API key\"}"
        return
    fi
    
    local url="https://haveibeenpwned.com/api/v3/breachedaccount/${email}"
    local response
    response=$(curl -s -H "hibp-api-key: ${HIBP_API_KEY}" "$url" 2>/dev/null)
    
    if [[ -z "$response" ]] || [[ "$response" == *"404"* ]]; then
        echo "[]"
        return
    fi
    
    # Processar breaches
    echo "$response" | jq -c 'map({
        name: .Name,
        domain: .Domain,
        breach_date: .BreachDate,
        added_date: .AddedDate,
        compromised_data: .DataClasses,
        description: .Description
    })' 2>/dev/null || echo "[]"
}

# Verificar outras breaches
check_breaches() {
    local email="$1"
    local breaches="[]"
    
    # SnusBase (se tiver API)
    if [[ -n "$SNUSBASE_API_KEY" ]]; then
        local url="https://snusbase.com/api/v1/search"
        local response
        response=$(curl -s -X POST -H "Authorization: ${SNUSBASE_API_KEY}" \
            -d "type=email&term=$email" "$url" 2>/dev/null)
        
        if [[ -n "$response" ]] && [[ "$response" != *"error"* ]]; then
            breaches=$(echo "$breaches" | jq --argjson data "$response" '. += $data')
        fi
    fi
    
    # DeHashed (se tiver API)
    if [[ -n "$DEHASHED_API_KEY" ]]; then
        local url="https://api.dehashed.com/search?query=email:$email"
        local response
        response=$(curl -s -u "${DEHASHED_API_KEY}:" "$url" 2>/dev/null)
        
        if [[ -n "$response" ]] && [[ "$response" != *"error"* ]]; then
            breaches=$(echo "$breaches" | jq --argjson data "$response" '. += $data.entries')
        fi
    fi
    
    # LeakCheck (se tiver API)
    if [[ -n "$LEAKCHECK_API_KEY" ]]; then
        local url="https://leakcheck.net/api/public?key=${LEAKCHECK_API_KEY}&check=$email"
        local response
        response=$(curl -s "$url" 2>/dev/null)
        
        if [[ -n "$response" ]] && [[ "$response" != *"error"* ]]; then
            breaches=$(echo "$breaches" | jq --argjson data "$response" '. += $data')
        fi
    fi
    
    echo "$breaches"
}

# Verificar redes sociais
check_social_media() {
    local email="$1"
    local results="[]"
    
    # Facebook
    local fb_url="https://www.facebook.com/search/top?q=$email"
    local fb_response
    fb_response=$(curl -s -L "$fb_url" 2>/dev/null)
    
    if [[ "$fb_response" != *"No results"* ]]; then
        results=$(echo "$results" | jq '. += [{"platform": "facebook", "found": true}]')
    fi
    
    # Twitter
    local twitter_url="https://twitter.com/search?q=$email"
    local twitter_response
    twitter_response=$(curl -s -L "$twitter_url" 2>/dev/null)
    
    if [[ "$twitter_response" != *"No results"* ]]; then
        results=$(echo "$results" | jq '. += [{"platform": "twitter", "found": true}]')
    fi
    
    # LinkedIn
    local linkedin_url="https://www.linkedin.com/pub/dir?first=&last=&search=$email"
    local linkedin_response
    linkedin_response=$(curl -s -L "$linkedin_url" 2>/dev/null)
    
    if [[ "$linkedin_response" != *"No results"* ]]; then
        results=$(echo "$results" | jq '. += [{"platform": "linkedin", "found": true}]')
    fi
    
    # Instagram
    local instagram_url="https://www.instagram.com/web/search/topsearch/?query=$email"
    local instagram_response
    instagram_response=$(curl -s "$instagram_url" 2>/dev/null)
    
    if [[ "$instagram_response" != *"\"users\":[]"* ]]; then
        results=$(echo "$results" | jq '. += [{"platform": "instagram", "found": true}]')
    fi
    
    echo "$results"
}

# Verificar GitHub
check_github_email() {
    local email="$1"
    local results="[]"
    
    # Buscar commits com este email
    local url="https://api.github.com/search/commits?q=author-email:${email}"
    local response
    response=$(curl -s -H "Authorization: token ${GITHUB_API_KEY}" "$url" 2>/dev/null)
    
    if [[ -n "$response" ]]; then
        local total_count
        total_count=$(echo "$response" | jq -r '.total_count // 0')
        
        if [[ $total_count -gt 0 ]]; then
            local items
            items=$(echo "$response" | jq -c '.items | map({
                repo: .repository.full_name,
                commit: .commit.message,
                date: .commit.author.date,
                url: .html_url
            })' 2>/dev/null)
            
            results=$(echo "$results" | jq --argjson items "$items" '.commits = $items')
        fi
    fi
    
    # Buscar usuários com este email
    local user_url="https://api.github.com/search/users?q=${email}"
    local user_response
    user_response=$(curl -s -H "Authorization: token ${GITHUB_API_KEY}" "$user_url" 2>/dev/null)
    
    if [[ -n "$user_response" ]]; then
        local user_count
        user_count=$(echo "$user_response" | jq -r '.total_count // 0')
        
        if [[ $user_count -gt 0 ]]; then
            local users
            users=$(echo "$user_response" | jq -c '.items | map({
                login: .login,
                id: .id,
                type: .type,
                url: .html_url
            })' 2>/dev/null)
            
            results=$(echo "$results" | jq --argjson users "$users" '.users = $users')
        fi
    fi
    
    echo "$results"
}

# Verificar Gravatar
check_gravatar() {
    local email="$1"
    local results="{}"
    
    # Gerar hash MD5 do email
    local hash
    hash=$(echo -n "$email" | md5sum | cut -d' ' -f1)
    
    # Verificar se existe Gravatar
    local url="https://www.gravatar.com/avatar/${hash}?d=404"
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [[ "$status" == "200" ]]; then
        results=$(echo "$results" | jq --arg hash "$hash" '.exists = true | .hash = $hash')
        
        # Obter perfil
        local profile_url="https://www.gravatar.com/${hash}.json"
        local profile
        profile=$(curl -s "$profile_url" 2>/dev/null)
        
        if [[ -n "$profile" ]]; then
            local display_name
            display_name=$(echo "$profile" | jq -r '.entry[0].displayName // empty')
            local about
            about=$(echo "$profile" | jq -r '.entry[0].aboutMe // empty')
            local urls
            urls=$(echo "$profile" | jq -c '.entry[0].urls // []' 2>/dev/null)
            
            results=$(echo "$results" | jq \
                --arg name "$display_name" \
                --arg about "$about" \
                --argjson urls "$urls" \
                '{
                    display_name: $name,
                    about: $about,
                    urls: $urls
                }')
        fi
    else
        results=$(echo "$results" | jq '.exists = false')
    fi
    
    echo "$results"
}

# Verificar PGP key
check_pgp_key() {
    local email="$1"
    local results="[]"
    
    # MIT PGP Key Server
    local url="https://pgp.mit.edu/pks/lookup?search=${email}&op=index&options=mr"
    local response
    response=$(curl -s "$url" 2>/dev/null)
    
    if [[ -n "$response" ]] && [[ "$response" != *"No results"* ]]; then
        # Extrair key IDs
        local key_ids
        key_ids=$(echo "$response" | grep -o 'keyid=[A-F0-9]\{16\}' | cut -d'=' -f2)
        
        while IFS= read -r key_id; do
            if [[ -n "$key_id" ]]; then
                results=$(echo "$results" | jq --arg key "$key_id" '. += [{"key_id": $key, "server": "pgp.mit.edu"}]')
            fi
        done <<< "$key_ids"
    fi
    
    # OpenPGP Key Server
    local url2="https://keys.openpgp.org/vks/v1/by-email/${email}"
    local response2
    response2=$(curl -s "$url2" 2>/dev/null)
    
    if [[ -n "$response2" ]] && [[ "$response2" != *"Not Found"* ]]; then
        results=$(echo "$results" | jq '. += [{"server": "keys.openpgp.org", "found": true}]')
    fi
    
    echo "$results"
}

# Verificar paste sites
check_paste_sites() {
    local email="$1"
    local results="[]"
    
    # Pastebin
    local pastebin_url="https://psbdmp.ws/api/search/${email}"
    local pastebin_response
    pastebin_response=$(curl -s "$pastebin_url" 2>/dev/null)
    
    if [[ -n "$pastebin_response" ]]; then
        local count
        count=$(echo "$pastebin_response" | jq -r '.count // 0')
        
        if [[ $count -gt 0 ]]; then
            results=$(echo "$results" | jq --argjson count "$count" '. += [{"site": "pastebin", "count": $count}]')
        fi
    fi
    
    # Google search for pastes
    local google_url="https://www.google.com/search?q=site:pastebin.com+${email}"
    local google_response
    google_response=$(curl -s -A "Mozilla/5.0" "$google_url" 2>/dev/null)
    
    if [[ "$google_response" =~ "About [0-9,]+ results" ]]; then
        results=$(echo "$results" | jq '. += [{"site": "google_pastes", "found": true}]')
    fi
    
    echo "$results"
}

# Verificar documentos com metadados
check_document_metadata() {
    local email="$1"
    local results="[]"
    
    # Google Dorks para documentos
    local dorks=(
        "filetype:pdf $email"
        "filetype:doc $email"
        "filetype:docx $email"
        "filetype:xls $email"
        "filetype:xlsx $email"
        "filetype:ppt $email"
        "filetype:pptx $email"
    )
    
    for dork in "${dorks[@]}"; do
        local url="https://www.google.com/search?q=${dork// /+}"
        local response
        response=$(curl -s -A "Mozilla/5.0" "$url" 2>/dev/null)
        
        if [[ "$response" =~ "About [0-9,]+ results" ]]; then
            local filetype
            filetype=$(echo "$dork" | cut -d':' -f2 | cut -d' ' -f1)
            results=$(echo "$results" | jq --arg type "$filetype" '. += [{"filetype": $type, "found": true}]')
        fi
    done
    
    echo "$results"
}

# Verificar EmailRep.io
check_emailrep() {
    local email="$1"
    
    local url="https://emailrep.io/${email}"
    local response
    response=$(curl -s -H "Key: ${EMAILREP_API_KEY}" "$url" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo "{}"
        return
    fi
    
    local result="{}"
    
    local reputation
    reputation=$(echo "$response" | jq -r '.reputation // "unknown"')
    local suspicious
    suspicious=$(echo "$response" | jq -r '.suspicious // false')
    local references
    references=$(echo "$response" | jq -r '.references // 0')
    local details
    details=$(echo "$response" | jq -c '.details // {}' 2>/dev/null)
    
    result=$(echo "$result" | jq \
        --arg rep "$reputation" \
        --argjson susp "$suspicious" \
        --argjson refs "$references" \
        --argjson det "$details" \
        '{
            reputation: $rep,
            suspicious: $susp,
            references: $refs,
            details: $det
        }')
    
    echo "$result"
}

# Verificar Hunter.io
check_hunter() {
    local email="$1"
    
    if [[ -z "$HUNTER_API_KEY" ]]; then
        echo "{\"error\": \"No API key\"}"
        return
    fi
    
    local url="https://api.hunter.io/v2/email-verifier?email=${email}&api_key=${HUNTER_API_KEY}"
    local response
    response=$(curl -s "$url" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo "{}"
        return
    fi
    
    local result="{}"
    
    local status
    status=$(echo "$response" | jq -r '.data.status // empty')
    local score
    score=$(echo "$response" | jq -r '.data.score // 0')
    local disposable
    disposable=$(echo "$response" | jq -r '.data.disposable // false')
    local webmail
    webmail=$(echo "$response" | jq -r '.data.webmail // false')
    local mx_records
    mx_records=$(echo "$response" | jq -r '.data.mx_records // false')
    
    result=$(echo "$result" | jq \
        --arg status "$status" \
        --argjson score "$score" \
        --argjson disp "$disposable" \
        --argjson web "$webmail" \
        --argjson mx "$mx_records" \
        '{
            status: $status,
            score: $score,
            disposable: $disp,
            webmail: $web,
            mx_records: $mx
        }')
    
    echo "$result"
}

# Verificar se é disposable email
check_disposable() {
    local domain="$1"
    
    # Lista de domínios disposable
    local disposable_domains=(
        "10minutemail.com"
        "guerrillamail.com"
        "mailinator.com"
        "yopmail.com"
        "temp-mail.org"
        "throwawaymail.com"
        "sharklasers.com"
        "grr.la"
        "spam4.me"
        "mailcatch.com"
        "tempinbox.com"
        "mintemail.com"
    )
    
    for d in "${disposable_domains[@]}"; do
        if [[ "$domain" == "$d" ]]; then
            echo "true"
            return
        fi
    done
    
    echo "false"
}

# Analisar padrões de nome de usuário
analyze_username() {
    local username="$1"
    local result="{}"
    
    # Extrair possíveis nome e sobrenome
    local possible_name
    possible_name=$(echo "$username" | sed 's/[0-9]//g' | sed 's/[._-]/ /g')
    
    result=$(echo "$result" | jq --arg name "$possible_name" '.possible_name = $name')
    
    # Verificar padrões
    if [[ "$username" =~ ^[a-z]+\.[a-z]+$ ]]; then
        result=$(echo "$result" | jq '.pattern = "first.last"')
    elif [[ "$username" =~ ^[a-z]+_[a-z]+$ ]]; then
        result=$(echo "$result" | jq '.pattern = "first_last"')
    elif [[ "$username" =~ ^[a-z]+[0-9]+$ ]]; then
        result=$(echo "$result" | jq '.pattern = "name+numbers"')
    elif [[ "$username" =~ ^[a-z]{1}\.[a-z]+$ ]]; then
        result=$(echo "$result" | jq '.pattern = "initial.last"')
    else
        result=$(echo "$result" | jq '.pattern = "custom"')
    fi
    
    # Contar números
    local numbers
    numbers=$(echo "$username" | grep -o '[0-9]' | wc -l)
    result=$(echo "$result" | jq --argjson nums "$numbers" '.number_count = $nums')
    
    echo "$result"
}

# Calcular risco do email
calculate_email_risk() {
    local results="$1"
    local score=0
    
    # Breaches
    local breach_count
    breach_count=$(echo "$results" | jq -r '.breaches | length // 0')
    score=$((score + breach_count * 20))
    
    # HIBP
    local hibp_count
    hibp_count=$(echo "$results" | jq -r '.haveibeenpwned | length // 0')
    score=$((score + hibp_count * 15))
    
    # EmailRep
    local suspicious
    suspicious=$(echo "$results" | jq -r '.emailrep.suspicious // false')
    if [[ "$suspicious" == "true" ]]; then
        score=$((score + 30))
    fi
    
    # Disposable
    local disposable
    disposable=$(echo "$results" | jq -r '.disposable // false')
    if [[ "$disposable" == "true" ]]; then
        score=$((score + 50))
    fi
    
    # Social media presence (reduz risco)
    local social_count
    social_count=$(echo "$results" | jq -r '.social_media | length // 0')
    if [[ $social_count -gt 0 ]]; then
        score=$((score - 10))
    fi
    
    # GitHub presence
    local github_commits
    github_commits=$(echo "$results" | jq -r '.github.commits | length // 0')
    if [[ $github_commits -gt 0 ]]; then
        score=$((score - 5))
    fi
    
    # Limitar entre 0 e 100
    if [[ $score -gt 100 ]]; then
        score=100
    elif [[ $score -lt 0 ]]; then
        score=0
    fi
    
    local level
    if [[ $score -ge 70 ]]; then
        level="high"
    elif [[ $score -ge 40 ]]; then
        level="medium"
    else
        level="low"
    fi
    
    echo "{\"score\": $score, \"level\": \"$level\"}"
}

# Exportar funções
export -f init_email_intel email_intelligence