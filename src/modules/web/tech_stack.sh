#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Technology Stack Detection Module
# =============================================================================

MODULE_NAME="Technology Stack Detection"
MODULE_DESC="Detect technologies, frameworks, and libraries used by websites"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# Categorias de tecnologia
declare -A TECH_CATEGORIES=(
    ["web_server"]="Web Server"
    ["programming_language"]="Programming Language"
    ["framework"]="Framework"
    ["cms"]="CMS"
    ["database"]="Database"
    ["javascript_library"]="JavaScript Library"
    ["css_framework"]="CSS Framework"
    ["analytics"]="Analytics"
    ["cdn"]="CDN"
    ["hosting"]="Hosting"
    ["os"]="Operating System"
    ["cache"]="Cache"
    ["proxy"]="Proxy"
    ["waf"]="WAF"
    ["payment"]="Payment"
    ["marketing"]="Marketing"
    ["social"]="Social"
    ["font"]="Font"
)

# Signatures de tecnologias
declare -A TECH_SIGNATURES=(
    # Web Servers
    ["Apache"]="apache|httpd"
    ["Nginx"]="nginx"
    ["IIS"]="iis|microsoft-iis"
    ["Tomcat"]="tomcat"
    ["Jetty"]="jetty"
    ["Caddy"]="caddy"
    ["Lighttpd"]="lighttpd"
    ["LiteSpeed"]="litespeed"
    
    # Programming Languages
    ["PHP"]="php|phpsessid"
    ["Python"]="python|django|flask|py"
    ["Ruby"]="ruby|rails|rack"
    ["Java"]="java|jsp|servlet|jsessionid"
    ["JavaScript"]="node|express|javascript"
    ["Go"]="golang|go"
    ["C#"]="asp.net|iis"
    ["Perl"]="perl|cgi"
    
    # Frameworks
    ["Django"]="django|csrfmiddlewaretoken"
    ["Flask"]="flask"
    ["Rails"]="rails|ruby"
    ["Laravel"]="laravel|livewire"
    ["Symfony"]="symfony"
    ["CodeIgniter"]="codeigniter"
    ["CakePHP"]="cakephp"
    ["Yii"]="yii"
    ["Zend"]="zend"
    ["Spring"]="spring|springframework"
    ["Express"]="express"
    ["Next.js"]="next.js|_next"
    ["Nuxt.js"]="nuxt"
    ["Gatsby"]="gatsby"
    ["Vue"]="vue.js|vuejs"
    ["React"]="react|reactjs"
    ["Angular"]="angular"
    ["Svelte"]="svelte"
    ["jQuery"]="jquery"
    ["Bootstrap"]="bootstrap"
    ["Tailwind"]="tailwind"
    ["Foundation"]="foundation"
    ["Bulma"]="bulma"
    
    # Databases
    ["MySQL"]="mysql"
    ["MariaDB"]="mariadb"
    ["PostgreSQL"]="postgresql|pgsql"
    ["MongoDB"]="mongodb"
    ["Redis"]="redis"
    ["Elasticsearch"]="elasticsearch"
    ["SQLite"]="sqlite"
    ["Oracle"]="oracle"
    ["SQL Server"]="mssql|sqlserver"
    
    # JavaScript Libraries
    ["React"]="react|reactjs"
    ["Vue"]="vue|vuejs"
    ["Angular"]="angular"
    ["jQuery"]="jquery"
    ["Lodash"]="lodash"
    ["Moment"]="moment"
    ["Axios"]="axios"
    ["D3"]="d3.js"
    ["Three.js"]="three.js"
    ["Chart.js"]="chart.js"
    ["Socket.io"]="socket.io"
    ["Alpine.js"]="alpine.js"
    ["HTMX"]="htmx"
    ["Stimulus"]="stimulus"
    
    # CSS Frameworks
    ["Bootstrap"]="bootstrap"
    ["Tailwind"]="tailwind"
    ["Foundation"]="foundation"
    ["Bulma"]="bulma"
    ["Materialize"]="materialize"
    ["Semantic UI"]="semantic-ui"
    ["UIKit"]="uikit"
    ["PureCSS"]="purecss"
    
    # Analytics
    ["Google Analytics"]="google-analytics|gtag|ga.js"
    ["Facebook Pixel"]="facebook-pixel|fbq"
    ["Hotjar"]="hotjar"
    ["Mixpanel"]="mixpanel"
    ["Segment"]="segment"
    ["Amplitude"]="amplitude"
    ["Matomo"]="matomo|piwik"
    ["Heap"]="heap"
    ["FullStory"]="fullstory"
    ["Crazy Egg"]="crazyegg"
    
    # CDN
    ["Cloudflare"]="cloudflare"
    ["Akamai"]="akamai"
    ["Fastly"]="fastly"
    ["CloudFront"]="cloudfront"
    ["StackPath"]="stackpath"
    ["KeyCDN"]="keycdn"
    ["BunnyCDN"]="bunnycdn"
    ["jsDelivr"]="jsdelivr"
    ["unpkg"]="unpkg"
    ["cdnjs"]="cdnjs"
    
    # Hosting
    ["AWS"]="amazonaws|ec2|s3"
    ["Azure"]="azure|windows.net"
    ["GCP"]="googleapis|googlecloud|gcp"
    ["Heroku"]="heroku"
    ["Netlify"]="netlify"
    ["Vercel"]="vercel"
    ["GitHub Pages"]="github.io"
    ["DigitalOcean"]="digitalocean"
    ["Linode"]="linode"
    
    # Cache
    ["Varnish"]="varnish"
    ["Memcached"]="memcached"
    ["Redis Cache"]="redis"
    
    # Proxy
    ["Nginx Proxy"]="nginx"
    ["HAProxy"]="haproxy"
    ["Traefik"]="traefik"
    
    # Payment
    ["Stripe"]="stripe"
    ["PayPal"]="paypal"
    ["Square"]="square"
    ["Braintree"]="braintree"
    ["Authorize.net"]="authorize.net"
    
    # Marketing
    ["Mailchimp"]="mailchimp"
    ["HubSpot"]="hubspot"
    ["Salesforce"]="salesforce"
    ["Marketo"]="marketo"
    
    # Social
    ["Twitter"]="twitter"
    ["Facebook"]="facebook"
    ["LinkedIn"]="linkedin"
    ["Instagram"]="instagram"
    ["Pinterest"]="pinterest"
    ["YouTube"]="youtube"
    
    # Fonts
    ["Google Fonts"]="fonts.googleapis"
    ["Adobe Fonts"]="typekit"
    ["Font Awesome"]="font-awesome|fontawesome"
    ["Ionicons"]="ionicons"
)

# Versões de tecnologias
declare -A VERSION_PATTERNS=(
    ["Apache"]="Apache/([0-9.]+)"
    ["Nginx"]="nginx/([0-9.]+)"
    ["IIS"]="Microsoft-IIS/([0-9.]+)"
    ["PHP"]="PHP/([0-9.]+)"
    ["Python"]="Python/([0-9.]+)"
    ["Ruby"]="Ruby/([0-9.]+)"
    ["jQuery"]="jQuery v([0-9.]+)|jquery-([0-9.]+).js"
    ["Bootstrap"]="bootstrap-([0-9.]+).min.css|Bootstrap v([0-9.]+)"
    ["React"]="react-([0-9.]+).js|React v([0-9.]+)"
    ["Vue"]="vue-([0-9.]+).js|Vue.js v([0-9.]+)"
    ["Angular"]="angular-([0-9.]+).js|Angular ([0-9.]+)"
)

# Inicializar módulo
init_tech_stack() {
    log "INFO" "Initializing Technology Stack Detection module" "TECH"
    
    # Verificar dependências
    local deps=("curl" "grep" "sed" "awk" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "TECH"
        return 1
    fi
    
    return 0
}

# Função principal
detect_tech_stack() {
    local target="$1"
    local output_dir="$2"
    
    log "WEB" "Starting technology stack detection for: $target" "TECH"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/tech_stack"
    mkdir -p "$results_dir"
    
    local results="{}"
    local tech_found="[]"
    
    # Normalizar URL
    target=$(normalize_url "$target")
    results=$(echo "$results" | jq --arg url "$target" '.target = $url')
    
    # Obter recursos da página
    log "INFO" "Fetching page resources" "TECH"
    local html
    local headers
    local resources
    
    html=$(curl -s -L -A "Mozilla/5.0" --max-time 10 "$target" 2>/dev/null)
    headers=$(curl -s -I -L -A "Mozilla/5.0" --max-time 10 "$target" 2>/dev/null)
    resources=$(extract_resources "$html" "$target")
    
    # 1. Detectar tecnologias por headers
    log "INFO" "Analyzing headers" "TECH"
    local header_tech
    header_tech=$(detect_from_headers "$headers")
    tech_found=$(echo "$tech_found" | jq --argjson tech "$header_tech" '. + $tech')
    
    # 2. Detectar tecnologias por HTML
    log "INFO" "Analyzing HTML" "TECH"
    local html_tech
    html_tech=$(detect_from_html "$html")
    tech_found=$(echo "$tech_found" | jq --argjson tech "$html_tech" '. + $tech')
    
    # 3. Detectar tecnologias por recursos (JS, CSS)
    log "INFO" "Analyzing resources" "TECH"
    local resource_tech
    resource_tech=$(detect_from_resources "$resources")
    tech_found=$(echo "$tech_found" | jq --argjson tech "$resource_tech" '. + $tech')
    
    # 4. Detectar tecnologias por cookies
    log "INFO" "Analyzing cookies" "TECH"
    local cookie_tech
    cookie_tech=$(detect_from_cookies "$headers")
    tech_found=$(echo "$tech_found" | jq --argjson tech "$cookie_tech" '. + $tech')
    
    # 5. Detectar versões
    log "INFO" "Detecting versions" "TECH"
    tech_found=$(detect_versions "$tech_found" "$headers" "$html" "$resources")
    
    # 6. Detectar por categorias
    log "INFO" "Categorizing technologies" "TECH"
    local categorized
    categorized=$(categorize_technologies "$tech_found")
    
    # 7. Detectar dependências
    log "INFO" "Analyzing dependencies" "TECH"
    local dependencies
    dependencies=$(analyze_dependencies "$tech_found")
    
    # 8. Detectar combinações comuns
    log "INFO" "Detecting common stacks" "TECH"
    local stacks
    stacks=$(detect_common_stacks "$tech_found")
    
    # 9. Estatísticas
    log "INFO" "Generating statistics" "TECH"
    local stats
    stats=$(generate_tech_stats "$tech_found")
    
    # Montar resultados
    results=$(echo "$results" | jq \
        --argjson tech "$tech_found" \
        --argjson cats "$categorized" \
        --argjson deps "$dependencies" \
        --argjson stacks "$stacks" \
        --argjson stats "$stats" \
        '{
            target: .target,
            technologies: $tech,
            categories: $cats,
            dependencies: $deps,
            common_stacks: $stacks,
            statistics: $stats
        }')
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/tech_stack.json"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local tech_count
    tech_count=$(echo "$tech_found" | jq 'length')
    
    log "SUCCESS" "Technology stack detection completed in ${duration}s - Found $tech_count technologies" "TECH"
    
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

# Extrair recursos da página
extract_resources() {
    local html="$1"
    local base_url="$2"
    local resources="[]"
    
    if [[ -z "$html" ]]; then
        echo "$resources"
        return
    fi
    
    # Extrair scripts
    local scripts
    scripts=$(echo "$html" | grep -o 'src="[^"]*\.js[^"]*"' | cut -d'"' -f2)
    
    while IFS= read -r script; do
        if [[ -n "$script" ]]; then
            # Resolver URL
            if [[ "$script" =~ ^http ]]; then
                resources=$(echo "$resources" | jq --arg url "$script" --arg type "js" '. += [{"url": $url, "type": "js"}]')
            elif [[ "$script" =~ ^// ]]; then
                resources=$(echo "$resources" | jq --arg url "https:$script" --arg type "js" '. += [{"url": $url, "type": "js"}]')
            else
                local full_url="${base_url}/${script}"
                resources=$(echo "$resources" | jq --arg url "$full_url" --arg type "js" '. += [{"url": $full_url, "type": "js"}]')
            fi
        fi
    done <<< "$scripts"
    
    # Extrair CSS
    local styles
    styles=$(echo "$html" | grep -o 'href="[^"]*\.css[^"]*"' | cut -d'"' -f2)
    
    while IFS= read -r style; do
        if [[ -n "$style" ]]; then
            if [[ "$style" =~ ^http ]]; then
                resources=$(echo "$resources" | jq --arg url "$style" --arg type "css" '. += [{"url": $url, "type": "css"}]')
            elif [[ "$style" =~ ^// ]]; then
                resources=$(echo "$resources" | jq --arg url "https:$style" --arg type "css" '. += [{"url": $url, "type": "css"}]')
            else
                local full_url="${base_url}/${style}"
                resources=$(echo "$resources" | jq --arg url "$full_url" --arg type "css" '. += [{"url": $full_url, "type": "css"}]')
            fi
        fi
    done <<< "$styles"
    
    # Extrair imagens (para CDN detection)
    local images
    images=$(echo "$html" | grep -o 'src="[^"]*\.\(png\|jpg\|jpeg\|gif\|svg\|webp\)[^"]*"' | cut -d'"' -f2)
    
    while IFS= read -r image; do
        if [[ -n "$image" ]]; then
            if [[ "$image" =~ ^http ]]; then
                resources=$(echo "$resources" | jq --arg url "$image" --arg type "image" '. += [{"url": $url, "type": "image"}]')
            fi
        fi
    done <<< "$images"
    
    echo "$resources"
}

# Detectar tecnologias por headers
detect_from_headers() {
    local headers="$1"
    local tech_found="[]"
    
    if [[ -z "$headers" ]]; then
        echo "$tech_found"
        return
    fi
    
    for tech in "${!TECH_SIGNATURES[@]}"; do
        local signature="${TECH_SIGNATURES[$tech]}"
        
        if echo "$headers" | grep -q -i "$signature"; then
            tech_found=$(echo "$tech_found" | jq \
                --arg name "$tech" \
                --arg source "header" \
                '. += [{
                    "name": $name,
                    "source": $source,
                    "confidence": 80
                }]')
        fi
    done
    
    echo "$tech_found"
}

# Detectar tecnologias por HTML
detect_from_html() {
    local html="$1"
    local tech_found="[]"
    
    if [[ -z "$html" ]]; then
        echo "$tech_found"
        return
    fi
    
    for tech in "${!TECH_SIGNATURES[@]}"; do
        local signature="${TECH_SIGNATURES[$tech]}"
        
        if echo "$html" | grep -q -i "$signature"; then
            tech_found=$(echo "$tech_found" | jq \
                --arg name "$tech" \
                --arg source "html" \
                '. += [{
                    "name": $name,
                    "source": $source,
                    "confidence": 70
                }]')
        fi
    done
    
    echo "$tech_found"
}

# Detectar tecnologias por recursos
detect_from_resources() {
    local resources="$1"
    local tech_found="[]"
    
    if [[ -z "$resources" ]] || [[ "$resources" == "[]" ]]; then
        echo "$tech_found"
        return
    fi
    
    echo "$resources" | jq -c '.[]' | while read -r resource; do
        local url
        url=$(echo "$resource" | jq -r '.url')
        local type
        type=$(echo "$resource" | jq -r '.type')
        
        for tech in "${!TECH_SIGNATURES[@]}"; do
            local signature="${TECH_SIGNATURES[$tech]}"
            
            if echo "$url" | grep -q -i "$signature"; then
                tech_found=$(echo "$tech_found" | jq \
                    --arg name "$tech" \
                    --arg source "resource" \
                    --arg url "$url" \
                    '. += [{
                        "name": $name,
                        "source": $source,
                        "url": $url,
                        "confidence": 90
                    }]')
            fi
        done
    done
    
    echo "$tech_found"
}

# Detectar tecnologias por cookies
detect_from_cookies() {
    local headers="$1"
    local tech_found="[]"
    
    if [[ -z "$headers" ]]; then
        echo "$tech_found"
        return
    fi
    
    # Extrair cookies
    local cookies
    cookies=$(echo "$headers" | grep -i "^set-cookie:")
    
    for tech in "${!TECH_SIGNATURES[@]}"; do
        local signature="${TECH_SIGNATURES[$tech]}"
        
        if echo "$cookies" | grep -q -i "$signature"; then
            tech_found=$(echo "$tech_found" | jq \
                --arg name "$tech" \
                --arg source "cookie" \
                '. += [{
                    "name": $name,
                    "source": $source,
                    "confidence": 85
                }]')
        fi
    done
    
    echo "$tech_found"
}

# Detectar versões
detect_versions() {
    local tech_found="$1"
    local headers="$2"
    local html="$3"
    local resources="$4"
    local result="[]"
    
    echo "$tech_found" | jq -c '.[]' | while read -r tech; do
        local name
        name=$(echo "$tech" | jq -r '.name')
        local version=""
        
        if [[ -n "${VERSION_PATTERNS[$name]}" ]]; then
            local pattern="${VERSION_PATTERNS[$name]}"
            
            # Procurar em headers
            if [[ -z "$version" ]] && [[ -n "$headers" ]]; then
                version=$(echo "$headers" | grep -oE "$pattern" | head -1 | sed -E 's/.*([0-9.]+).*/\1/')
            fi
            
            # Procurar em HTML
            if [[ -z "$version" ]] && [[ -n "$html" ]]; then
                version=$(echo "$html" | grep -oE "$pattern" | head -1 | sed -E 's/.*([0-9.]+).*/\1/')
            fi
            
            # Procurar em recursos
            if [[ -z "$version" ]] && [[ -n "$resources" ]]; then
                version=$(echo "$resources" | jq -r '.[].url' | grep -oE "$pattern" | head -1 | sed -E 's/.*([0-9.]+).*/\1/')
            fi
        fi
        
        if [[ -n "$version" ]]; then
            result=$(echo "$result" | jq --argjson t "$tech" --arg ver "$version" \
                '. += [$t + {"version": $ver}]')
        else
            result=$(echo "$result" | jq --argjson t "$tech" '. += [$t]')
        fi
    done
    
    echo "$result"
}

# Categorizar tecnologias
categorize_technologies() {
    local tech_found="$1"
    local categorized="{}"
    
    echo "$tech_found" | jq -c '.[]' | while read -r tech; do
        local name
        name=$(echo "$tech" | jq -r '.name')
        local category="unknown"
        
        # Determinar categoria
        if [[ -n "${TECH_CATEGORIES[$name]}" ]]; then
            category="${TECH_CATEGORIES[$name]}"
        else
            # Tentar inferir categoria
            for cat in "${!TECH_CATEGORIES[@]}"; do
                if [[ "$name" =~ $cat ]]; then
                    category="${TECH_CATEGORIES[$cat]}"
                    break
                fi
            done
        fi
        
        categorized=$(echo "$categorized" | jq --arg cat "$category" --argjson tech "$tech" \
            '.[$cat] += [$tech]')
    done
    
    echo "$categorized"
}

# Analisar dependências entre tecnologias
analyze_dependencies() {
    local tech_found="$1"
    local dependencies="[]"
    
    # Dependências conhecidas
    local known_deps=(
        "jQuery:React"
        "jQuery:Vue"
        "React:Next.js"
        "Vue:Nuxt.js"
        "PHP:Laravel"
        "PHP:Symfony"
        "Ruby:Rails"
        "Python:Django"
        "Python:Flask"
        "JavaScript:Node.js"
        "Node.js:Express"
        "Bootstrap:jQuery"
    )
    
    local tech_names
    tech_names=$(echo "$tech_found" | jq -r '.[].name')
    
    for dep in "${known_deps[@]}"; do
        IFS=':' read -r dep1 dep2 <<< "$dep"
        
        if echo "$tech_names" | grep -q "$dep1" && echo "$tech_names" | grep -q "$dep2"; then
            dependencies=$(echo "$dependencies" | jq \
                --arg dep1 "$dep1" \
                --arg dep2 "$dep2" \
                '. += [{
                    "technology": $dep1,
                    "depends_on": $dep2
                }]')
        fi
    done
    
    echo "$dependencies"
}

# Detectar stacks comuns
detect_common_stacks() {
    local tech_found="$1"
    local stacks="[]"
    
    # Stacks conhecidos
    local common_stacks=(
        "LAMP:Linux,Apache,MySQL,PHP"
        "LEMP:Linux,Nginx,MySQL,PHP"
        "MEAN:MongoDB,Express,Angular,Node.js"
        "MERN:MongoDB,Express,React,Node.js"
        "MEVN:MongoDB,Express,Vue,Node.js"
        "Laravel:PHP,Laravel,MySQL,Redis"
        "Django:Python,Django,PostgreSQL"
        "Ruby on Rails:Ruby,Rails,PostgreSQL"
        "JAMstack:JavaScript,APIs,Markup"
        "Serverless:AWS Lambda,API Gateway"
    )
    
    local tech_names
    tech_names=$(echo "$tech_found" | jq -r '.[].name' | tr '\n' ',')
    
    for stack in "${common_stacks[@]}"; do
        IFS=':' read -r name components <<< "$stack"
        IFS=',' read -ra comps <<< "$components"
        
        local found_all=true
        for comp in "${comps[@]}"; do
            if ! echo "$tech_names" | grep -q "$comp"; then
                found_all=false
                break
            fi
        done
        
        if [[ "$found_all" == "true" ]]; then
            stacks=$(echo "$stacks" | jq --arg name "$name" '. += [$name]')
        fi
    done
    
    echo "$stacks"
}

# Gerar estatísticas
generate_tech_stats() {
    local tech_found="$1"
    local stats="{}"
    
    # Total de tecnologias
    local total
    total=$(echo "$tech_found" | jq 'length')
    stats=$(echo "$stats" | jq --argjson total "$total" '.total = $total')
    
    # Tecnologias por categoria
    local categories="{}"
    echo "$tech_found" | jq -c '.[]' | while read -r tech; do
        local name
        name=$(echo "$tech" | jq -r '.name')
        local category="unknown"
        
        for cat in "${!TECH_CATEGORIES[@]}"; do
            if [[ "$name" == "$cat" ]]; then
                category="${TECH_CATEGORIES[$cat]}"
                break
            fi
        done
        
        categories=$(echo "$categories" | jq --arg cat "$category" '.[$cat] += 1')
    done
    
    stats=$(echo "$stats" | jq --argjson cats "$categories" '.by_category = $cats')
    
    # Confiança média
    local avg_confidence
    avg_confidence=$(echo "$tech_found" | jq '[.[].confidence] | add // 0 / length // 1')
    stats=$(echo "$stats" | jq --argjson conf "$avg_confidence" '.average_confidence = $conf')
    
    # Tecnologias mais recentes
    local current_year
    current_year=$(date +%Y)
    
    echo "$stats"
}

# Exportar funções
export -f init_tech_stack detect_tech_stack