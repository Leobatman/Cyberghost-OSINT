#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Web Scanner Module
# =============================================================================

MODULE_NAME="Web Scanner"
MODULE_DESC="Comprehensive web application scanning and analysis"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# Configurações
WEB_SCAN_THREADS="${WEB_SCAN_THREADS:-10}"
WEB_SCAN_TIMEOUT="${WEB_SCAN_TIMEOUT:-10}"
WEB_SCAN_USER_AGENT="${WEB_SCAN_USER_AGENT:-Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36}"
WEB_SCAN_FOLLOW_REDIRECTS="${WEB_SCAN_FOLLOW_REDIRECTS:-true}"

# Inicializar módulo
init_web_scanner() {
    log "INFO" "Initializing Web Scanner module" "WEB"
    
    # Verificar dependências
    local deps=("curl" "grep" "sed" "awk" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "WEB"
        return 1
    fi
    
    return 0
}

# Função principal
scan_website() {
    local target="$1"
    local output_dir="$2"
    
    log "WEB" "Starting web scan for: $target" "WEB"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/web_scan"
    mkdir -p "$results_dir"
    
    local results="{}"
    
    # Normalizar URL
    target=$(normalize_url "$target")
    results=$(echo "$results" | jq --arg url "$target" '.url = $url')
    
    # 1. Informações básicas do servidor
    log "INFO" "Gathering server information" "WEB"
    local server_info
    server_info=$(get_server_info "$target")
    results=$(echo "$results" | jq --argjson info "$server_info" '.server_info = $info')
    
    # 2. Headers HTTP
    log "INFO" "Analyzing HTTP headers" "WEB"
    local headers
    headers=$(analyze_headers "$target")
    results=$(echo "$results" | jq --argjson headers "$headers" '.headers = $headers')
    
    # 3. Tecnologias detectadas
    log "INFO" "Detecting technologies" "WEB"
    local technologies
    technologies=$(detect_technologies "$target")
    results=$(echo "$results" | jq --argjson tech "$technologies" '.technologies = $tech')
    
    # 4. Mapeamento de diretórios
    log "INFO" "Mapping directories" "WEB"
    local directories
    directories=$(map_directories "$target")
    results=$(echo "$results" | jq --argjson dirs "$directories" '.directories = $dirs')
    
    # 5. Arquivos interessantes
    log "INFO" "Searching for interesting files" "WEB"
    local interesting_files
    interesting_files=$(find_interesting_files "$target")
    results=$(echo "$results" | jq --argjson files "$interesting_files" '.interesting_files = $files')
    
    # 6. Parâmetros URL
    log "INFO" "Analyzing URL parameters" "WEB"
    local parameters
    parameters=$(analyze_parameters "$target")
    results=$(echo "$results" | jq --argjson params "$parameters" '.parameters = $params')
    
    # 7. Formulários
    log "INFO" "Analyzing forms" "WEB"
    local forms
    forms=$(analyze_forms "$target")
    results=$(echo "$results" | jq --argjson forms "$forms" '.forms = $forms')
    
    # 8. Links externos
    log "INFO" "Extracting external links" "WEB"
    local external_links
    external_links=$(extract_external_links "$target")
    results=$(echo "$results" | jq --argjson links "$external_links" '.external_links = $links')
    
    # 9. JavaScript analysis
    log "INFO" "Analyzing JavaScript files" "WEB"
    local js_analysis
    js_analysis=$(analyze_javascript "$target")
    results=$(echo "$results" | jq --argjson js "$js_analysis" '.javascript = $js')
    
    # 10. Cookies
    log "INFO" "Analyzing cookies" "WEB"
    local cookies
    cookies=$(analyze_cookies "$target")
    results=$(echo "$results" | jq --argjson cookies "$cookies" '.cookies = $cookies')
    
    # 11. Verificar métodos HTTP
    log "INFO" "Checking HTTP methods" "WEB"
    local http_methods
    http_methods=$(check_http_methods "$target")
    results=$(echo "$results" | jq --argjson methods "$http_methods" '.http_methods = $methods')
    
    # 12. Verificar vulnerabilidades comuns
    log "INFO" "Checking for common vulnerabilities" "WEB"
    local vulnerabilities
    vulnerabilities=$(check_vulnerabilities "$target")
    results=$(echo "$results" | jq --argjson vulns "$vulnerabilities" '.vulnerabilities = $vulns')
    
    # 13. Sitemap e robots.txt
    log "INFO" "Checking sitemap and robots.txt" "WEB"
    local sitemap_info
    sitemap_info=$(check_sitemap_robots "$target")
    results=$(echo "$results" | jq --argjson sitemap "$sitemap_info" '.sitemap_robots = $sitemap')
    
    # 14. Certificado SSL
    log "INFO" "Checking SSL certificate" "WEB"
    local ssl_info
    ssl_info=$(check_ssl_certificate "$target")
    results=$(echo "$results" | jq --argjson ssl "$ssl_info" '.ssl = $ssl')
    
    # 15. Performance e tempo de resposta
    log "INFO" "Measuring performance" "WEB"
    local performance
    performance=$(measure_performance "$target")
    results=$(echo "$results" | jq --argjson perf "$performance" '.performance = $perf')
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/web_scan.json"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "SUCCESS" "Web scan completed in ${duration}s" "WEB"
    
    echo "$results"
}

# Normalizar URL
normalize_url() {
    local url="$1"
    
    # Adicionar protocolo se não tiver
    if [[ ! "$url" =~ ^https?:// ]]; then
        url="http://${url}"
    fi
    
    # Remover barra final
    url="${url%/}"
    
    echo "$url"
}

# Fazer requisição HTTP
http_request() {
    local url="$1"
    local method="${2:-GET}"
    local data="${3:-}"
    local headers="${4:-}"
    
    local curl_cmd=("curl" "-s" "-L" "-k" "--max-time" "$WEB_SCAN_TIMEOUT" "-A" "$WEB_SCAN_USER_AGENT")
    
    # Método
    curl_cmd+=("-X" "$method")
    
    # Headers adicionais
    if [[ -n "$headers" ]]; then
        while IFS= read -r header; do
            if [[ -n "$header" ]]; then
                curl_cmd+=("-H" "$header")
            fi
        done <<< "$headers"
    fi
    
    # Dados
    if [[ -n "$data" ]]; then
        curl_cmd+=("-d" "$data")
    fi
    
    # URL
    curl_cmd+=("$url")
    
    "${curl_cmd[@]}" 2>/dev/null
}

# Obter informações do servidor
get_server_info() {
    local url="$1"
    local info="{}"
    
    local response
    response=$(http_request "$url" "HEAD")
    
    if [[ -n "$response" ]]; then
        # Extrair status code
        local status_code
        status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
        info=$(echo "$info" | jq --arg code "$status_code" '.status_code = $code')
        
        # Server header
        local server
        server=$(echo "$response" | grep -i "^server:" | cut -d':' -f2- | sed 's/^ //')
        if [[ -n "$server" ]]; then
            info=$(echo "$info" | jq --arg server "$server" '.server = $server')
        fi
        
        # Content-Type
        local content_type
        content_type=$(echo "$response" | grep -i "^content-type:" | cut -d':' -f2- | sed 's/^ //')
        if [[ -n "$content_type" ]]; then
            info=$(echo "$info" | jq --arg type "$content_type" '.content_type = $type')
        fi
        
        # X-Powered-By
        local powered_by
        powered_by=$(echo "$response" | grep -i "^x-powered-by:" | cut -d':' -f2- | sed 's/^ //')
        if [[ -n "$powered_by" ]]; then
            info=$(echo "$info" | jq --arg powered "$powered_by" '.x_powered_by = $powered')
        fi
    fi
    
    echo "$info"
}

# Analisar headers HTTP
analyze_headers() {
    local url="$1"
    local headers_analysis="{}"
    
    local response
    response=$(http_request "$url" "HEAD")
    
    if [[ -n "$response" ]]; then
        # Headers de segurança
        local security_headers=(
            "Strict-Transport-Security"
            "Content-Security-Policy"
            "X-Frame-Options"
            "X-Content-Type-Options"
            "X-XSS-Protection"
            "Referrer-Policy"
            "Feature-Policy"
            "Permissions-Policy"
        )
        
        for header in "${security_headers[@]}"; do
            local value
            value=$(echo "$response" | grep -i "^$header:" | cut -d':' -f2- | sed 's/^ //')
            
            if [[ -n "$value" ]]; then
                headers_analysis=$(echo "$headers_analysis" | jq --arg header "$header" --arg value "$value" '.security[$header] = $value')
            else
                headers_analysis=$(echo "$headers_analysis" | jq --arg header "$header" '.missing += [$header]')
            fi
        done
        
        # Cookies
        local cookies
        cookies=$(echo "$response" | grep -i "^set-cookie:" | cut -d':' -f2- | sed 's/^ //')
        if [[ -n "$cookies" ]]; then
            headers_analysis=$(echo "$headers_analysis" | jq --arg cookies "$cookies" '.cookies_present = true')
        fi
        
        # Caching headers
        local cache_control
        cache_control=$(echo "$response" | grep -i "^cache-control:" | cut -d':' -f2- | sed 's/^ //')
        if [[ -n "$cache_control" ]]; then
            headers_analysis=$(echo "$headers_analysis" | jq --arg cache "$cache_control" '.cache_control = $cache')
        fi
    fi
    
    echo "$headers_analysis"
}

# Detectar tecnologias
detect_technologies() {
    local url="$1"
    local technologies="{}"
    
    local html
    html=$(http_request "$url")
    
    if [[ -n "$html" ]]; then
        # Frameworks frontend
        if echo "$html" | grep -q "react" || echo "$html" | grep -q "React" || echo "$html" | grep -q "reactjs"; then
            technologies=$(echo "$technologies" | jq '.frontend += ["React"]')
        fi
        
        if echo "$html" | grep -q "vue" || echo "$html" | grep -q "Vue"; then
            technologies=$(echo "$technologies" | jq '.frontend += ["Vue.js"]')
        fi
        
        if echo "$html" | grep -q "angular" || echo "$html" | grep -q "Angular"; then
            technologies=$(echo "$technologies" | jq '.frontend += ["Angular"]')
        fi
        
        if echo "$html" | grep -q "jquery" || echo "$html" | grep -q "jQuery"; then
            technologies=$(echo "$technologies" | jq '.frontend += ["jQuery"]')
        fi
        
        if echo "$html" | grep -q "bootstrap" || echo "$html" | grep -q "Bootstrap"; then
            technologies=$(echo "$technologies" | jq '.frontend += ["Bootstrap"]')
        fi
        
        # Frameworks backend (por cookies ou headers)
        local headers
        headers=$(http_request "$url" "HEAD")
        
        if echo "$headers" | grep -q "PHPSESSID"; then
            technologies=$(echo "$technologies" | jq '.backend += ["PHP"]')
        fi
        
        if echo "$headers" | grep -q "JSESSIONID"; then
            technologies=$(echo "$technologies" | jq '.backend += ["Java/JSP"]')
        fi
        
        if echo "$headers" | grep -q "ASP.NET" || echo "$headers" | grep -q "ASPSESSIONID"; then
            technologies=$(echo "$technologies" | jq '.backend += ["ASP.NET"]')
        fi
        
        if echo "$headers" | grep -q "Rails" || echo "$headers" | grep -q "_session"; then
            technologies=$(echo "$technologies" | jq '.backend += ["Ruby on Rails"]')
        fi
        
        if echo "$headers" | grep -q "laravel_session"; then
            technologies=$(echo "$technologies" | jq '.backend += ["Laravel"]')
        fi
        
        if echo "$headers" | grep -q "django" || echo "$html" | grep -q "csrfmiddlewaretoken"; then
            technologies=$(echo "$technologies" | jq '.backend += ["Django"]')
        fi
        
        # Servidores web
        local server
        server=$(echo "$headers" | grep -i "^server:" | cut -d':' -f2- | sed 's/^ //' | tr '[:upper:]' '[:lower:]')
        
        case "$server" in
            *apache*)
                technologies=$(echo "$technologies" | jq '.server += ["Apache"]')
                ;;
            *nginx*)
                technologies=$(echo "$technologies" | jq '.server += ["Nginx"]')
                ;;
            *iis*)
                technologies=$(echo "$technologies" | jq '.server += ["IIS"]')
                ;;
            *tomcat*)
                technologies=$(echo "$technologies" | jq '.server += ["Tomcat"]')
                ;;
            *jetty*)
                technologies=$(echo "$technologies" | jq '.server += ["Jetty"]')
                ;;
            *caddy*)
                technologies=$(echo "$technologies" | jq '.server += ["Caddy"]')
                ;;
        esac
        
        # Analytics
        if echo "$html" | grep -q "google-analytics" || echo "$html" | grep -q "gtag"; then
            technologies=$(echo "$technologies" | jq '.analytics += ["Google Analytics"]')
        fi
        
        if echo "$html" | grep -q "facebook.net" || echo "$html" | grep -q "fbq"; then
            technologies=$(echo "$technologies" | jq '.analytics += ["Facebook Pixel"]')
        fi
        
        if echo "$html" | grep -q "hotjar"; then
            technologies=$(echo "$technologies" | jq '.analytics += ["Hotjar"]')
        fi
        
        if echo "$html" | grep -q "mixpanel"; then
            technologies=$(echo "$technologies" | jq '.analytics += ["Mixpanel"]')
        fi
    fi
    
    echo "$technologies"
}

# Mapear diretórios
map_directories() {
    local url="$1"
    local directories="[]"
    
    # Lista de diretórios comuns
    local common_dirs=(
        "admin"
        "login"
        "wp-admin"
        "wp-content"
        "wp-includes"
        "uploads"
        "images"
        "css"
        "js"
        "assets"
        "static"
        "public"
        "private"
        "backup"
        "backups"
        "temp"
        "tmp"
        "logs"
        "log"
        "config"
        "configuration"
        "settings"
        "data"
        "database"
        "db"
        "sql"
        "phpmyadmin"
        "phpPgAdmin"
        "api"
        "v1"
        "v2"
        "rest"
        "graphql"
        "docs"
        "documentation"
        "help"
        "support"
        "forum"
        "community"
        "blog"
        "news"
        "about"
        "contact"
        "terms"
        "privacy"
        "sitemap"
        "robots.txt"
        "crossdomain.xml"
        "clientaccesspolicy.xml"
        ".well-known"
        "server-status"
        "server-info"
    )
    
    local count=0
    for dir in "${common_dirs[@]}"; do
        local test_url="${url}/${dir}"
        local status
        status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$test_url" 2>/dev/null)
        
        if [[ "$status" == "200" ]] || [[ "$status" == "301" ]] || [[ "$status" == "302" ]] || [[ "$status" == "401" ]] || [[ "$status" == "403" ]]; then
            directories=$(echo "$directories" | jq \
                --arg dir "$dir" \
                --arg url "$test_url" \
                --arg code "$status" \
                '. += [{
                    "directory": $dir,
                    "url": $url,
                    "status": $code
                }]')
            ((count++))
        fi
        
        # Evitar sobrecarga
        if [[ $((count % 10)) -eq 0 ]]; then
            sleep 0.1
        fi
    done
    
    echo "$directories"
}

# Encontrar arquivos interessantes
find_interesting_files() {
    local url="$1"
    local files="[]"
    
    # Lista de arquivos interessantes
    local interesting=(
        ".env"
        ".git/HEAD"
        ".git/config"
        ".svn/entries"
        ".hg/"
        "composer.json"
        "composer.lock"
        "package.json"
        "package-lock.json"
        "yarn.lock"
        "Gemfile"
        "Gemfile.lock"
        "requirements.txt"
        "Pipfile"
        "Pipfile.lock"
        "web.config"
        ".htaccess"
        ".htpasswd"
        "wp-config.php"
        "wp-config.txt"
        "config.php"
        "config.inc.php"
        "configuration.php"
        "settings.php"
        "database.yml"
        "database.php"
        "db.php"
        "sql.php"
        "backup.sql"
        "dump.sql"
        "dump.rdb"
        "error_log"
        "debug.log"
        "access.log"
        "error.log"
        "install.php"
        "setup.php"
        "phpinfo.php"
        "info.php"
        "test.php"
        "shell.php"
        "cmd.php"
        "exec.php"
        "upload.php"
        "filemanager.php"
        "elfinder.php"
        "cron.php"
        "cron.yaml"
        "docker-compose.yml"
        "Dockerfile"
        "k8s.yml"
        "kubernetes.yml"
        "travis.yml"
        ".travis.yml"
        "jenkins.yml"
        ".jenkins"
        ".circleci"
        ".gitlab-ci.yml"
    )
    
    for file in "${interesting[@]}"; do
        local test_url="${url}/${file}"
        local status
        status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$test_url" 2>/dev/null)
        
        if [[ "$status" == "200" ]] || [[ "$status" == "401" ]] || [[ "$status" == "403" ]]; then
            files=$(echo "$files" | jq \
                --arg file "$file" \
                --arg url "$test_url" \
                --arg code "$status" \
                '. += [{
                    "file": $file,
                    "url": $url,
                    "status": $code
                }]')
        fi
    done
    
    echo "$files"
}

# Analisar parâmetros URL
analyze_parameters() {
    local url="$1"
    local params="[]"
    
    local html
    html=$(http_request "$url")
    
    if [[ -n "$html" ]]; then
        # Parâmetros em links
        local href_params
        href_params=$(echo "$html" | grep -o 'href="[^"]*?[^"]*=[^"]*"' | grep -o '?[^"]*' | sed 's/?//')
        
        while IFS= read -r param_str; do
            if [[ -n "$param_str" ]]; then
                IFS='&' read -ra param_pairs <<< "$param_str"
                for pair in "${param_pairs[@]}"; do
                    local param_name
                    param_name=$(echo "$pair" | cut -d'=' -f1)
                    
                    params=$(echo "$params" | jq --arg name "$param_name" '. += [$name]')
                done
            fi
        done <<< "$href_params"
    fi
    
    # Remover duplicatas
    params=$(echo "$params" | jq 'unique')
    
    echo "$params"
}

# Analisar formulários
analyze_forms() {
    local url="$1"
    local forms="[]"
    
    local html
    html=$(http_request "$url")
    
    if [[ -n "$html" ]]; then
        # Extrair formulários
        local form_pattern='<form[^>]*>(.*?)</form>'
        
        # Usar grep para encontrar formulários (simplificado)
        local form_count=0
        while IFS= read -r form_html; do
            if [[ -n "$form_html" ]]; then
                local form_info="{}"
                
                # Method
                local method
                method=$(echo "$form_html" | grep -o 'method="[^"]*"' | cut -d'"' -f2 | tr '[:upper:]' '[:lower:]')
                form_info=$(echo "$form_info" | jq --arg method "${method:-get}" '.method = $method')
                
                # Action
                local action
                action=$(echo "$form_html" | grep -o 'action="[^"]*"' | cut -d'"' -f2)
                form_info=$(echo "$form_info" | jq --arg action "$action" '.action = $action')
                
                # Inputs
                local inputs="[]"
                local input_fields
                input_fields=$(echo "$form_html" | grep -o '<input[^>]*>' | grep -o 'name="[^"]*"' | cut -d'"' -f2)
                
                while IFS= read -r input_name; do
                    if [[ -n "$input_name" ]]; then
                        inputs=$(echo "$inputs" | jq --arg name "$input_name" '. += [$name]')
                    fi
                done <<< "$input_fields"
                
                form_info=$(echo "$form_info" | jq --argjson inputs "$inputs" '.inputs = $inputs')
                
                # File uploads
                if echo "$form_html" | grep -q 'type="file"'; then
                    form_info=$(echo "$form_info" | jq '.has_file_upload = true')
                fi
                
                forms=$(echo "$forms" | jq --argjson form "$form_info" '. += [$form]')
                ((form_count++))
            fi
        done <<< "$(echo "$html" | grep -o '<form[^>]*>')"
    fi
    
    echo "$forms"
}

# Extrair links externos
extract_external_links() {
    local url="$1"
    local links="[]"
    
    local html
    html=$(http_request "$url")
    
    if [[ -n "$html" ]]; then
        local domain
        domain=$(echo "$url" | awk -F/ '{print $3}')
        
        # Extrair hrefs
        local hrefs
        hrefs=$(echo "$html" | grep -o 'href="https\?://[^"]*"' | cut -d'"' -f2)
        
        while IFS= read -r link; do
            if [[ -n "$link" ]]; then
                # Verificar se é externo
                if [[ "$link" != *"$domain"* ]]; then
                    links=$(echo "$links" | jq --arg url "$link" '. += [$url]')
                fi
            fi
        done <<< "$hrefs"
    fi
    
    # Remover duplicatas
    links=$(echo "$links" | jq 'unique')
    
    echo "$links"
}

# Analisar JavaScript
analyze_javascript() {
    local url="$1"
    local js_analysis="{}"
    
    local html
    html=$(http_request "$url")
    
    if [[ -n "$html" ]]; then
        # Extrair links para JS
        local js_files
        js_files=$(echo "$html" | grep -o 'src="[^"]*\.js[^"]*"' | cut -d'"' -f2)
        
        local js_list="[]"
        local count=0
        
        while IFS= read -r js_file; do
            if [[ -n "$js_file" ]] && [[ $count -lt 10 ]]; then
                # Resolver URL
                if [[ "$js_file" =~ ^http ]]; then
                    local js_url="$js_file"
                else
                    local base_url
                    base_url=$(echo "$url" | grep -oE 'https?://[^/]+')
                    local js_url="${base_url}${js_file}"
                fi
                
                # Baixar JS
                local js_content
                js_content=$(http_request "$js_url")
                
                if [[ -n "$js_content" ]]; then
                    # Procurar por informações sensíveis
                    local sensitive
                    sensitive=$(echo "$js_content" | grep -oE 'api[_-]?key["\s:=]+[a-zA-Z0-9_\-\.]+|secret["\s:=]+[a-zA-Z0-9_\-\.]+|token["\s:=]+[a-zA-Z0-9_\-\.]+|password["\s:=]+[a-zA-Z0-9_\-\.]+' | head -10)
                    
                    js_list=$(echo "$js_list" | jq \
                        --arg url "$js_url" \
                        --arg sens "$sensitive" \
                        '. += [{
                            "url": $url,
                            "sensitive_found": ($sens != "")
                        }]')
                fi
                
                ((count++))
            fi
        done <<< "$js_files"
        
        js_analysis=$(echo "$js_analysis" | jq --argjson files "$js_list" '.files = $files')
    fi
    
    echo "$js_analysis"
}

# Analisar cookies
analyze_cookies() {
    local url="$1"
    local cookies="[]"
    
    local response
    response=$(http_request "$url" "HEAD")
    
    if [[ -n "$response" ]]; then
        # Extrair cookies dos headers
        local cookie_lines
        cookie_lines=$(echo "$response" | grep -i "^set-cookie:")
        
        while IFS= read -r cookie_line; do
            if [[ -n "$cookie_line" ]]; then
                local cookie_info="{}"
                
                # Nome e valor
                local cookie_name
                cookie_name=$(echo "$cookie_line" | cut -d':' -f2- | sed 's/^ //' | cut -d'=' -f1)
                local cookie_value
                cookie_value=$(echo "$cookie_line" | cut -d':' -f2- | sed 's/^ //' | cut -d'=' -f2- | cut -d';' -f1)
                
                cookie_info=$(echo "$cookie_info" | jq \
                    --arg name "$cookie_name" \
                    --arg value "$cookie_value" \
                    '.name = $name | .value = $value')
                
                # HttpOnly
                if echo "$cookie_line" | grep -qi "httponly"; then
                    cookie_info=$(echo "$cookie_info" | jq '.httponly = true')
                fi
                
                # Secure
                if echo "$cookie_line" | grep -qi "secure"; then
                    cookie_info=$(echo "$cookie_info" | jq '.secure = true')
                fi
                
                # SameSite
                if echo "$cookie_line" | grep -qi "samesite"; then
                    local samesite
                    samesite=$(echo "$cookie_line" | grep -oi "samesite=[a-z]*" | cut -d'=' -f2)
                    cookie_info=$(echo "$cookie_info" | jq --arg samesite "$samesite" '.samesite = $samesite')
                fi
                
                cookies=$(echo "$cookies" | jq --argjson cookie "$cookie_info" '. += [$cookie]')
            fi
        done <<< "$cookie_lines"
    fi
    
    echo "$cookies"
}

# Verificar métodos HTTP
check_http_methods() {
    local url="$1"
    local methods="[]"
    
    local common_methods=("GET" "HEAD" "POST" "PUT" "DELETE" "OPTIONS" "PATCH" "TRACE" "CONNECT")
    
    for method in "${common_methods[@]}"; do
        local status
        status=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" --max-time 5 "$url" 2>/dev/null)
        
        if [[ -n "$status" ]] && [[ "$status" != "405" ]] && [[ "$status" != "501" ]]; then
            methods=$(echo "$methods" | jq --arg method "$method" --arg code "$status" \
                '. += [{
                    "method": $method,
                    "status": $code
                }]')
        fi
    done
    
    echo "$methods"
}

# Verificar vulnerabilidades comuns
check_vulnerabilities() {
    local url="$1"
    local vulns="[]"
    
    # Path traversal
    local traversal_payloads=(
        "../../../etc/passwd"
        "..\\..\\..\\windows\\win.ini"
        "%2e%2e%2fetc%2fpasswd"
        "....//....//....//etc/passwd"
    )
    
    for payload in "${traversal_payloads[@]}"; do
        local test_url="${url}/${payload}"
        local response
        response=$(http_request "$test_url" "GET")
        
        if [[ "$response" == *"root:"* ]] || [[ "$response" == *"[fonts]"* ]]; then
            vulns=$(echo "$vulns" | jq \
                --arg type "path_traversal" \
                --arg url "$test_url" \
                '. += [{
                    "type": $type,
                    "url": $url,
                    "severity": "high"
                }]')
            break
        fi
    done
    
    # XSS
    local xss_payload="<script>alert('XSS')</script>"
    local test_url="${url}?q=${xss_payload}"
    local response
    response=$(http_request "$test_url" "GET")
    
    if [[ "$response" == *"$xss_payload"* ]]; then
        vulns=$(echo "$vulns" | jq \
            --arg type "xss" \
            --arg url "$test_url" \
            '. += [{
                "type": $type,
                "severity": "medium"
            }]')
    fi
    
    # SQL Injection
    local sql_payloads=("'" "\"" "1' OR '1'='1" "1\" OR \"1\"=\"1")
    
    for payload in "${sql_payloads[@]}"; do
        local test_url="${url}?id=${payload}"
        local response
        response=$(http_request "$test_url" "GET")
        
        if [[ "$response" == *"SQL syntax"* ]] || [[ "$response" == *"mysql_fetch"* ]] || [[ "$response" == *"ORA-"* ]]; then
            vulns=$(echo "$vulns" | jq \
                --arg type "sql_injection" \
                --arg url "$test_url" \
                '. += [{
                    "type": $type,
                    "severity": "critical"
                }]')
            break
        fi
    done
    
    echo "$vulns"
}

# Verificar sitemap e robots.txt
check_sitemap_robots() {
    local url="$1"
    local info="{}"
    
    local base_url
    base_url=$(echo "$url" | grep -oE 'https?://[^/]+')
    
    # robots.txt
    local robots_url="${base_url}/robots.txt"
    local robots_status
    robots_status=$(curl -s -o /dev/null -w "%{http_code}" "$robots_url" 2>/dev/null)
    
    if [[ "$robots_status" == "200" ]]; then
        local robots_content
        robots_content=$(http_request "$robots_url" "GET")
        info=$(echo "$info" | jq --arg content "$robots_content" '.robots_txt = $content')
        
        # Extrair sitemaps do robots.txt
        local sitemaps
        sitemaps=$(echo "$robots_content" | grep -i "^sitemap:" | cut -d':' -f2- | sed 's/^ //')
        
        if [[ -n "$sitemaps" ]]; then
            info=$(echo "$info" | jq --arg sitemaps "$sitemaps" '.sitemaps_from_robots = $sitemaps')
        fi
    fi
    
    # sitemap.xml
    local sitemap_url="${base_url}/sitemap.xml"
    local sitemap_status
    sitemap_status=$(curl -s -o /dev/null -w "%{http_code}" "$sitemap_url" 2>/dev/null)
    
    if [[ "$sitemap_status" == "200" ]]; then
        local sitemap_content
        sitemap_content=$(http_request "$sitemap_url" "GET")
        info=$(echo "$info" | jq --arg content "$sitemap_content" '.sitemap_xml = $content')
    fi
    
    echo "$info"
}

# Verificar certificado SSL
check_ssl_certificate() {
    local url="$1"
    local ssl_info="{}"
    
    # Verificar se é HTTPS
    if [[ "$url" =~ ^https ]]; then
        local domain
        domain=$(echo "$url" | awk -F/ '{print $3}')
        
        # Usar openssl para obter informações do certificado
        local cert_info
        cert_info=$(echo | openssl s_client -servername "$domain" -connect "${domain}:443" 2>/dev/null | openssl x509 -text 2>/dev/null)
        
        if [[ -n "$cert_info" ]]; then
            # Issuer
            local issuer
            issuer=$(echo "$cert_info" | grep "Issuer:" | head -1 | sed 's/.*Issuer: //')
            ssl_info=$(echo "$ssl_info" | jq --arg issuer "$issuer" '.issuer = $issuer')
            
            # Subject
            local subject
            subject=$(echo "$cert_info" | grep "Subject:" | head -1 | sed 's/.*Subject: //')
            ssl_info=$(echo "$ssl_info" | jq --arg subject "$subject" '.subject = $subject')
            
            # Validade
            local not_before
            not_before=$(echo "$cert_info" | grep "Not Before" | sed 's/.*Not Before: //')
            local not_after
            not_after=$(echo "$cert_info" | grep "Not After" | sed 's/.*Not After: //')
            
            ssl_info=$(echo "$ssl_info" | jq \
                --arg before "$not_before" \
                --arg after "$not_after" \
                '.validity = {
                    "not_before": $before,
                    "not_after": $after
                }')
            
            # Verificar expiração
            local expiry_epoch
            expiry_epoch=$(date -d "$not_after" +%s 2>/dev/null)
            local current_epoch
            current_epoch=$(date +%s)
            
            if [[ $expiry_epoch -lt $current_epoch ]]; then
                ssl_info=$(echo "$ssl_info" | jq '.expired = true')
            else
                local days_left=$(( (expiry_epoch - current_epoch) / 86400 ))
                ssl_info=$(echo "$ssl_info" | jq --argjson days "$days_left" '.days_until_expiry = $days')
            fi
            
            # SAN
            local san
            san=$(echo "$cert_info" | grep -A1 "Subject Alternative Name" | tail -1 | sed 's/.*: //')
            if [[ -n "$san" ]]; then
                ssl_info=$(echo "$ssl_info" | jq --arg san "$san" '.subject_alt_names = $san')
            fi
        fi
    fi
    
    echo "$ssl_info"
}

# Medir performance
measure_performance() {
    local url="$1"
    local perf="{}"
    
    # Tempo de resposta
    local start_time
    start_time=$(date +%s%N)
    
    curl -s -o /dev/null --max-time 10 "$url" 2>/dev/null
    
    local end_time
    end_time=$(date +%s%N)
    local response_time=$(( (end_time - start_time) / 1000000 ))
    
    perf=$(echo "$perf" | jq --argjson time "$response_time" '.response_time_ms = $time')
    
    # Tamanho da página
    local size
    size=$(curl -s -o /dev/null -w "%{size_download}" --max-time 10 "$url" 2>/dev/null)
    perf=$(echo "$perf" | jq --argjson size "$size" '.page_size_bytes = $size')
    
    # Número de redirecionamentos
    local redirects
    redirects=$(curl -s -o /dev/null -w "%{num_redirects}" --max-time 10 "$url" 2>/dev/null)
    perf=$(echo "$perf" | jq --argjson redirects "$redirects" '.redirect_count = $redirects')
    
    echo "$perf"
}

# Exportar funções
export -f init_web_scanner scan_website