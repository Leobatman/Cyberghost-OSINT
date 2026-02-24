#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - CMS Detection Module
# =============================================================================

MODULE_NAME="CMS Detection"
MODULE_DESC="Detect Content Management Systems and their versions"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# CMS signatures
declare -A CMS_SIGNATURES=(
    # WordPress
    ["wordpress"]="wp-content|wp-includes|wp-json|wordpress"
    # Joomla
    ["joomla"]="joomla|Joomla|com_content|com_users"
    # Drupal
    ["drupal"]="drupal|Drupal|sites/all|core/misc"
    # Magento
    ["magento"]="magento|Magento|skin/frontend|js/mage"
    # Shopify
    ["shopify"]="shopify|myshopify|cdn.shopify"
    # PrestaShop
    ["prestashop"]="prestashop|PrestaShop|themes/default|js/tools"
    # OpenCart
    ["opencart"]="opencart|OpenCart|catalog/view|system/library"
    # Ghost
    ["ghost"]="ghost|Ghost|shared/ghost|content/images"
    # Wix
    ["wix"]="wix|Wix|static.wixstatic|wixsite"
    # Squarespace
    ["squarespace"]="squarespace|Squarespace|static.squarespace"
    # Weebly
    ["weebly"]="weebly|Weebly|weebly.com|weebly.net"
    # TYPO3
    ["typo3"]="typo3|TYPO3|typo3conf|typo3temp"
    # Concrete5
    ["concrete5"]="concrete5|concrete/core|packages/concrete"
    # Liferay
    ["liferay"]="liferay|Liferay|web/guest|html/themes"
    # SharePoint
    ["sharepoint"]="sharepoint|SharePoint|_layouts|_vti_bin"
    # DokuWiki
    ["dokuwiki"]="dokuwiki|DokuWiki|lib/exe|lib/plugins"
    # MediaWiki
    ["mediawiki"]="mediawiki|MediaWiki|wiki|index.php?title="
    # PHPBB
    ["phpbb"]="phpbb|phpBB|styles/prosilver|viewforum.php"
    # vBulletin
    ["vbulletin"]="vbulletin|vBulletin|clientscript|images/misc"
    # XenForo
    ["xenforo"]="xenforo|XenForo|js/xenforo|styles/default"
)

# Version detection patterns
declare -A VERSION_PATTERNS=(
    ["wordpress"]="<meta name=\"generator\" content=\"WordPress ([0-9.]+)\"|ver=([0-9.]+)"
    ["joomla"]="<meta name=\"generator\" content=\"Joomla! ([0-9.]+)\"|joomla-([0-9.]+).js"
    ["drupal"]="<meta name=\"generator\" content=\"Drupal ([0-9.]+)\"|Drupal.([0-9.]+).js"
    ["magento"]="Magento/([0-9.]+)|version/([0-9.]+)"
    ["prestashop"]="PrestaShop ([0-9.]+)|prestashop-([0-9.]+).js"
)

# Plugin/theme detection
declare -A PLUGIN_PATTERNS=(
    ["wordpress"]="wp-content/plugins/([^/]+)|wp-content/themes/([^/]+)"
    ["joomla"]="components/com_([^/]+)|templates/([^/]+)"
    ["drupal"]="sites/all/modules/([^/]+)|sites/all/themes/([^/]+)"
    ["magento"]="app/code/community/([^/]+)|app/design/frontend/([^/]+)"
)

# Inicializar módulo
init_cms_detection() {
    log "INFO" "Initializing CMS Detection module" "CMS"
    
    # Verificar dependências
    local deps=("curl" "grep" "sed" "awk" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "CMS"
        return 1
    fi
    
    return 0
}

# Função principal
detect_cms() {
    local target="$1"
    local output_dir="$2"
    
    log "WEB" "Starting CMS detection for: $target" "CMS"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/cms"
    mkdir -p "$results_dir"
    
    local results="{}"
    
    # Normalizar URL
    target=$(normalize_url "$target")
    results=$(echo "$results" | jq --arg url "$target" '.target = $url')
    
    # Baixar página principal
    log "INFO" "Fetching main page" "CMS"
    local html
    html=$(curl -s -L -A "Mozilla/5.0" --max-time 10 "$target" 2>/dev/null)
    
    if [[ -z "$html" ]]; then
        log "ERROR" "Failed to fetch target" "CMS"
        echo "{}"
        return
    fi
    
    # 1. Detectar CMS principal
    log "INFO" "Detecting CMS" "CMS"
    local detected_cms
    detected_cms=$(detect_cms_from_html "$html" "$target")
    results=$(echo "$results" | jq --argjson cms "$detected_cms" '.cms = $cms')
    
    # 2. Detectar versão
    log "INFO" "Detecting CMS version" "CMS"
    local version
    version=$(detect_cms_version "$html" "$detected_cms")
    results=$(echo "$results" | jq --argjson ver "$version" '.version = $ver')
    
    # 3. Detectar plugins/módulos
    log "INFO" "Detecting plugins and modules" "CMS"
    local plugins
    plugins=$(detect_plugins "$html" "$target" "$detected_cms")
    results=$(echo "$results" | jq --argjson plugins "$plugins" '.plugins = $plugins')
    
    # 4. Detectar temas
    log "INFO" "Detecting themes" "CMS"
    local themes
    themes=$(detect_themes "$html" "$target" "$detected_cms")
    results=$(echo "$results" | jq --argjson themes "$themes" '.themes = $themes')
    
    # 5. Detectar arquivos específicos do CMS
    log "INFO" "Checking CMS-specific files" "CMS"
    local cms_files
    cms_files=$(check_cms_files "$target" "$detected_cms")
    results=$(echo "$results" | jq --argjson files "$cms_files" '.cms_files = $files')
    
    # 6. Verificar vulnerabilidades conhecidas
    log "INFO" "Checking known vulnerabilities" "CMS"
    local vulnerabilities
    vulnerabilities=$(check_cms_vulnerabilities "$detected_cms" "$version")
    results=$(echo "$results" | jq --argjson vulns "$vulnerabilities" '.vulnerabilities = $vulns')
    
    # 7. Detectar usuários
    log "INFO" "Detecting users" "CMS"
    local users
    users=$(detect_cms_users "$target" "$detected_cms")
    results=$(echo "$results" | jq --argjson users "$users" '.users = $users')
    
    # 8. Detectar configurações expostas
    log "INFO" "Checking exposed configurations" "CMS"
    local exposed
    exposed=$(check_exposed_configs "$target" "$detected_cms")
    results=$(echo "$results" | jq --argjson exposed "$exposed" '.exposed_configs = $exposed')
    
    # 9. Headers específicos do CMS
    log "INFO" "Analyzing CMS headers" "CMS"
    local headers
    headers=$(check_cms_headers "$target")
    results=$(echo "$results" | jq --argjson headers "$headers" '.headers = $headers')
    
    # 10. Estatísticas
    log "INFO" "Generating statistics" "CMS"
    local stats
    stats=$(generate_cms_stats "$results")
    results=$(echo "$results" | jq --argjson stats "$stats" '.statistics = $stats')
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/cms.json"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local cms_name
    cms_name=$(echo "$detected_cms" | jq -r '.name // "Unknown"')
    
    log "SUCCESS" "CMS detection completed in ${duration}s - Detected: $cms_name" "CMS"
    
    echo "$results"
}

# Normalizar URL
normalize_url() {
    local url="$1"
    
    if [[ ! "$url" =~ ^https?:// ]]; then
        url="http://${url}"
    fi
    
    echo "$url"
}

# Detectar CMS a partir do HTML
detect_cms_from_html() {
    local html="$1"
    local url="$2"
    local detected="[]"
    local confidence=0
    
    for cms in "${!CMS_SIGNATURES[@]}"; do
        local signature="${CMS_SIGNATURES[$cms]}"
        local found=0
        
        # Verificar no HTML
        if echo "$html" | grep -q -i "$signature"; then
            found=1
        fi
        
        # Verificar em links de recursos
        local base_domain
        base_domain=$(echo "$url" | awk -F/ '{print $3}')
        
        local resource_urls
        resource_urls=$(echo "$html" | grep -o 'src="[^"]*"' | cut -d'"' -f2)
        resource_urls+=$(echo "$html" | grep -o 'href="[^"]*"' | cut -d'"' -f2)
        
        while IFS= read -r resource; do
            if [[ -n "$resource" ]]; then
                if echo "$resource" | grep -q -i "$signature"; then
                    found=1
                fi
            fi
        done <<< "$resource_urls"
        
        if [[ $found -eq 1 ]]; then
            confidence=$((confidence + 1))
            
            # Verificar outros indicadores
            if [[ -f "${DATABASES_DIR}/cms/${cms}_indicators.txt" ]]; then
                local indicator_count=0
                while IFS= read -r indicator; do
                    if [[ -n "$indicator" ]] && echo "$html" | grep -q -i "$indicator"; then
                        indicator_count=$((indicator_count + 1))
                    fi
                done < "${DATABASES_DIR}/cms/${cms}_indicators.txt"
                
                if [[ $indicator_count -gt 2 ]]; then
                    confidence=$((confidence + indicator_count))
                fi
            fi
            
            detected=$(echo "$detected" | jq \
                --arg name "$cms" \
                --argjson conf "$confidence" \
                '. += [{
                    "name": $name,
                    "confidence": $conf
                }]')
        fi
    done
    
    # Ordenar por confiança
    detected=$(echo "$detected" | jq 'sort_by(.confidence) | reverse')
    
    echo "$detected"
}

# Detectar versão do CMS
detect_cms_version() {
    local html="$1"
    local detected="$2"
    local version_info="{}"
    
    local primary_cms
    primary_cms=$(echo "$detected" | jq -r '.[0].name // empty')
    
    if [[ -n "$primary_cms" ]] && [[ -n "${VERSION_PATTERNS[$primary_cms]}" ]]; then
        local pattern="${VERSION_PATTERNS[$primary_cms]}"
        local version
        
        # Tentar extrair versão
        version=$(echo "$html" | grep -oE "$pattern" | head -1 | sed -E 's/.*( [0-9.]+).*/\1/' | tr -d ' ')
        
        if [[ -n "$version" ]]; then
            version_info=$(echo "$version_info" | jq --arg ver "$version" '.version = $ver')
            
            # Verificar se versão é antiga
            local current_year
            current_year=$(date +%Y)
            local version_year
            version_year=$(echo "$version" | cut -d'.' -f1)
            
            if [[ $version_year -lt $((current_year - 2)) ]]; then
                version_info=$(echo "$version_info" | jq '.outdated = true')
            else
                version_info=$(echo "$version_info" | jq '.outdated = false')
            fi
        fi
    fi
    
    echo "$version_info"
}

# Detectar plugins
detect_plugins() {
    local html="$1"
    local url="$2"
    local detected="$3"
    local plugins="[]"
    
    local primary_cms
    primary_cms=$(echo "$detected" | jq -r '.[0].name // empty')
    
    if [[ -n "$primary_cms" ]] && [[ -n "${PLUGIN_PATTERNS[$primary_cms]}" ]]; then
        local pattern="${PLUGIN_PATTERNS[$primary_cms]}"
        
        # Extrair plugins do HTML
        local found_plugins
        found_plugins=$(echo "$html" | grep -oE "$pattern" | sort -u)
        
        while IFS= read -r plugin; do
            if [[ -n "$plugin" ]]; then
                plugins=$(echo "$plugins" | jq --arg name "$plugin" '. += [{"name": $name}]')
            fi
        done <<< "$found_plugins"
    fi
    
    # Verificar plugins conhecidos
    if [[ -f "${DATABASES_DIR}/cms/${primary_cms}_plugins.txt" ]]; then
        while IFS= read -r plugin; do
            if [[ -n "$plugin" ]]; then
                local plugin_path
                case "$primary_cms" in
                    "wordpress")
                        plugin_path="wp-content/plugins/${plugin}/"
                        ;;
                    "joomla")
                        plugin_path="components/com_${plugin}/"
                        ;;
                    "drupal")
                        plugin_path="sites/all/modules/${plugin}/"
                        ;;
                esac
                
                local plugin_url="${url}${plugin_path}"
                local status
                status=$(curl -s -o /dev/null -w "%{http_code}" "$plugin_url" 2>/dev/null)
                
                if [[ "$status" == "200" ]] || [[ "$status" == "403" ]]; then
                    plugins=$(echo "$plugins" | jq --arg name "$plugin" --arg url "$plugin_url" \
                        '. += [{"name": $name, "url": $url, "status": "installed"}]')
                fi
            fi
        done < "${DATABASES_DIR}/cms/${primary_cms}_plugins.txt"
    fi
    
    echo "$plugins"
}

# Detectar temas
detect_themes() {
    local html="$1"
    local url="$2"
    local detected="$3"
    local themes="[]"
    
    local primary_cms
    primary_cms=$(echo "$detected" | jq -r '.[0].name // empty')
    
    if [[ -n "$primary_cms" ]]; then
        case "$primary_cms" in
            "wordpress")
                # Extrair tema do WordPress
                local theme
                theme=$(echo "$html" | grep -o "wp-content/themes/[^\"]*" | head -1 | cut -d'/' -f3)
                
                if [[ -n "$theme" ]]; then
                    themes=$(echo "$themes" | jq --arg name "$theme" '. += [{"name": $name}]')
                    
                    # Verificar versão do tema
                    local style_url="${url}wp-content/themes/${theme}/style.css"
                    local style
                    style=$(curl -s "$style_url" 2>/dev/null)
                    
                    if [[ -n "$style" ]]; then
                        local version
                        version=$(echo "$style" | grep "Version:" | head -1 | awk '{print $2}')
                        local author
                        author=$(echo "$style" | grep "Author:" | head -1 | sed 's/Author: //')
                        
                        if [[ -n "$version" ]]; then
                            themes=$(echo "$themes" | jq --arg ver "$version" '.[0].version = $ver')
                        fi
                        if [[ -n "$author" ]]; then
                            themes=$(echo "$themes" | jq --arg auth "$author" '.[0].author = $auth')
                        fi
                    fi
                fi
                ;;
                
            "joomla")
                # Extrair template do Joomla
                local template
                template=$(echo "$html" | grep -o "templates/[^\"]*" | head -1 | cut -d'/' -f2)
                
                if [[ -n "$template" ]]; then
                    themes=$(echo "$themes" | jq --arg name "$template" '. += [{"name": $name}]')
                fi
                ;;
                
            "drupal")
                # Extrair tema do Drupal
                local theme
                theme=$(echo "$html" | grep -o "themes/[^\"]*" | head -1 | cut -d'/' -f2)
                
                if [[ -n "$theme" ]]; then
                    themes=$(echo "$themes" | jq --arg name "$theme" '. += [{"name": $name}]')
                fi
                ;;
        esac
    fi
    
    echo "$themes"
}

# Verificar arquivos específicos do CMS
check_cms_files() {
    local url="$1"
    local detected="$2"
    local files="[]"
    
    local primary_cms
    primary_cms=$(echo "$detected" | jq -r '.[0].name // empty')
    
    if [[ -n "$primary_cms" ]]; then
        # Arquivos comuns por CMS
        local common_files=()
        
        case "$primary_cms" in
            "wordpress")
                common_files=(
                    "wp-config.php"
                    "wp-login.php"
                    "wp-admin/"
                    "xmlrpc.php"
                    "wp-content/debug.log"
                    "wp-content/uploads/"
                    "wp-includes/"
                    "wp-json/"
                    "wp-cron.php"
                    "wp-activate.php"
                    "wp-signup.php"
                    "wp-trackback.php"
                    "wp-mail.php"
                )
                ;;
                
            "joomla")
                common_files=(
                    "configuration.php"
                    "administrator/"
                    "components/"
                    "modules/"
                    "plugins/"
                    "templates/"
                    "language/"
                    "cache/"
                    "logs/"
                    "tmp/"
                )
                ;;
                
            "drupal")
                common_files=(
                    "sites/default/settings.php"
                    "core/"
                    "modules/"
                    "themes/"
                    "profiles/"
                    "sites/all/"
                    "sites/default/files/"
                    "update.php"
                    "install.php"
                )
                ;;
                
            "magento")
                common_files=(
                    "app/etc/local.xml"
                    "app/etc/config.php"
                    "downloader/"
                    "js/"
                    "skin/"
                    "media/"
                    "var/log/"
                    "var/report/"
                    "index.php"
                    "get.php"
                )
                ;;
        esac
        
        for file in "${common_files[@]}"; do
            local test_url="${url}${file}"
            local status
            status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$test_url" 2>/dev/null)
            
            if [[ "$status" == "200" ]] || [[ "$status" == "403" ]] || [[ "$status" == "401" ]]; then
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
    fi
    
    echo "$files"
}

# Verificar vulnerabilidades conhecidas
check_cms_vulnerabilities() {
    local detected="$1"
    local version_info="$2"
    local vulns="[]"
    
    local primary_cms
    primary_cms=$(echo "$detected" | jq -r '.[0].name // empty')
    local version
    version=$(echo "$version_info" | jq -r '.version // empty')
    
    if [[ -n "$primary_cms" ]] && [[ -n "$version" ]]; then
        # Verificar em banco de dados de vulnerabilidades
        local vuln_db="${DATABASES_DIR}/cve/${primary_cms}.json"
        
        if [[ -f "$vuln_db" ]]; then
            local matching_vulns
            matching_vulns=$(jq --arg ver "$version" '.[] | select(.versions | contains([$ver]))' "$vuln_db" 2>/dev/null)
            
            if [[ -n "$matching_vulns" ]]; then
                vulns=$(echo "$matching_vulns" | jq -s '.')
            fi
        fi
        
        # Vulnerabilidades conhecidas por versão
        case "$primary_cms" in
            "wordpress")
                if [[ "$version" < "4.9" ]]; then
                    vulns=$(echo "$vulns" | jq '. += [{
                        "cve": "CVE-2019-8942",
                        "description": "WordPress < 4.9 - Remote Code Execution",
                        "severity": "critical"
                    }]')
                fi
                if [[ "$version" < "5.2" ]]; then
                    vulns=$(echo "$vulns" | jq '. += [{
                        "cve": "CVE-2019-17671",
                        "description": "WordPress < 5.2 - Unauthenticated View Private Posts",
                        "severity": "high"
                    }]')
                fi
                ;;
                
            "joomla")
                if [[ "$version" < "3.9" ]]; then
                    vulns=$(echo "$vulns" | jq '. += [{
                        "cve": "CVE-2019-10998",
                        "description": "Joomla < 3.9 - SQL Injection",
                        "severity": "critical"
                    }]')
                fi
                ;;
        esac
    fi
    
    echo "$vulns"
}

# Detectar usuários do CMS
detect_cms_users() {
    local url="$1"
    local detected="$2"
    local users="[]"
    
    local primary_cms
    primary_cms=$(echo "$detected" | jq -r '.[0].name // empty')
    
    if [[ -n "$primary_cms" ]]; then
        case "$primary_cms" in
            "wordpress")
                # Detectar usuários via REST API
                local api_url="${url}wp-json/wp/v2/users"
                local response
                response=$(curl -s "$api_url" 2>/dev/null)
                
                if [[ -n "$response" ]] && [[ "$response" != "[]" ]]; then
                    users=$(echo "$response" | jq '[.[] | {
                        "id": .id,
                        "name": .name,
                        "slug": .slug,
                        "url": .link
                    }]')
                fi
                
                # Detectar via author archives
                for i in {1..10}; do
                    local author_url="${url}?author=${i}"
                    local status
                    status=$(curl -s -o /dev/null -w "%{http_code}" "$author_url" 2>/dev/null)
                    
                    if [[ "$status" == "200" ]]; then
                        users=$(echo "$users" | jq --argjson id "$i" '. += [{"id": $id, "method": "author_archive"}]')
                    fi
                done
                ;;
                
            "joomla")
                # Detectar usuários do Joomla
                for i in {62..70}; do
                    local user_url="${url}index.php?option=com_users&view=profile&user_id=${i}"
                    local status
                    status=$(curl -s -o /dev/null -w "%{http_code}" "$user_url" 2>/dev/null)
                    
                    if [[ "$status" == "200" ]]; then
                        users=$(echo "$users" | jq --argjson id "$i" '. += [{"id": $id}]')
                    fi
                done
                ;;
                
            "drupal")
                # Detectar usuários do Drupal
                for i in {1..10}; do
                    local user_url="${url}user/${i}"
                    local status
                    status=$(curl -s -o /dev/null -w "%{http_code}" "$user_url" 2>/dev/null)
                    
                    if [[ "$status" == "200" ]] || [[ "$status" == "403" ]]; then
                        users=$(echo "$users" | jq --argjson id "$i" '. += [{"id": $id}]')
                    fi
                done
                ;;
        esac
    fi
    
    echo "$users"
}

# Verificar configurações expostas
check_exposed_configs() {
    local url="$1"
    local detected="$2"
    local exposed="[]"
    
    local primary_cms
    primary_cms=$(echo "$detected" | jq -r '.[0].name // empty')
    
    if [[ -n "$primary_cms" ]]; then
        local config_files=()
        
        case "$primary_cms" in
            "wordpress")
                config_files=(
                    "wp-config.php"
                    "wp-content/debug.log"
                    ".htaccess"
                    "wp-config-sample.php"
                )
                ;;
                
            "joomla")
                config_files=(
                    "configuration.php"
                    "configuration.php-dist"
                    ".htaccess"
                    "htaccess.txt"
                )
                ;;
                
            "drupal")
                config_files=(
                    "sites/default/settings.php"
                    "sites/default/settings.local.php"
                    ".htaccess"
                    "sites/example.sites.php"
                )
                ;;
        esac
        
        for file in "${config_files[@]}"; do
            local test_url="${url}${file}"
            local response
            response=$(curl -s --max-time 5 "$test_url" 2>/dev/null)
            
            if [[ -n "$response" ]]; then
                # Verificar se contém configurações sensíveis
                if echo "$response" | grep -q "DB_PASSWORD\|password\|secret\|key"; then
                    exposed=$(echo "$exposed" | jq \
                        --arg file "$file" \
                        --arg url "$test_url" \
                        '. += [{
                            "file": $file,
                            "url": $url,
                            "sensitive": true
                        }]')
                fi
            fi
        done
    fi
    
    echo "$exposed"
}

# Verificar headers específicos do CMS
check_cms_headers() {
    local url="$1"
    local headers="{}"
    
    local response
    response=$(curl -s -I -L "$url" 2>/dev/null)
    
    if [[ -n "$response" ]]; then
        # X-Powered-By
        local powered_by
        powered_by=$(echo "$response" | grep -i "^x-powered-by:" | cut -d':' -f2- | sed 's/^ //')
        if [[ -n "$powered_by" ]]; then
            headers=$(echo "$headers" | jq --arg pb "$powered_by" '.x_powered_by = $pb')
        fi
        
        # X-Generator
        local generator
        generator=$(echo "$response" | grep -i "^x-generator:" | cut -d':' -f2- | sed 's/^ //')
        if [[ -n "$generator" ]]; then
            headers=$(echo "$headers" | jq --arg gen "$generator" '.x_generator = $gen')
        fi
        
        # Server
        local server
        server=$(echo "$response" | grep -i "^server:" | cut -d':' -f2- | sed 's/^ //')
        if [[ -n "$server" ]]; then
            headers=$(echo "$headers" | jq --arg srv "$server" '.server = $srv')
        fi
    fi
    
    echo "$headers"
}

# Gerar estatísticas
generate_cms_stats() {
    local results="$1"
    local stats="{}"
    
    local cms_count
    cms_count=$(echo "$results" | jq '.cms | length // 0')
    stats=$(echo "$stats" | jq --argjson count "$cms_count" '.cms_count = $count')
    
    local plugin_count
    plugin_count=$(echo "$results" | jq '.plugins | length // 0')
    stats=$(echo "$stats" | jq --argjson count "$plugin_count" '.plugins_count = $count')
    
    local theme_count
    theme_count=$(echo "$results" | jq '.themes | length // 0')
    stats=$(echo "$stats" | jq --argjson count "$theme_count" '.themes_count = $count')
    
    local vuln_count
    vuln_count=$(echo "$results" | jq '.vulnerabilities | length // 0')
    stats=$(echo "$stats" | jq --argjson count "$vuln_count" '.vulnerabilities_count = $count')
    
    local exposed_count
    exposed_count=$(echo "$results" | jq '.exposed_configs | length // 0')
    stats=$(echo "$stats" | jq --argjson count "$exposed_count" '.exposed_configs_count = $count')
    
    echo "$stats"
}

# Exportar funções
export -f init_cms_detection detect_cms