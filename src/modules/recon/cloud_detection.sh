#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Cloud Infrastructure Detection Module
# =============================================================================

MODULE_NAME="Cloud Detection"
MODULE_DESC="Detect cloud providers and services"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# Cloud providers and their IP ranges
declare -A CLOUD_PROVIDERS=(
    ["AWS"]="amazonaws.com ec2.amazonaws.com s3.amazonaws.com cloudfront.net"
    ["Azure"]="azurewebsites.net cloudapp.azure.com azureedge.net"
    ["GCP"]="googleapis.com appspot.com googlecloud.com"
    ["DigitalOcean"]="digitalocean.com do.co"
    ["Linode"]="linode.com linodeobjects.com"
    ["Vultr"]="vultr.com"
    ["Heroku"]="herokuapp.com herokudns.com"
    ["Cloudflare"]="cloudflare.com"
    ["Fastly"]="fastly.net"
    ["Akamai"]="akamai.net akamaiedge.net"
    ["Alibaba"]="alibabacloud.com aliyuncs.com"
    ["Oracle"]="oraclecloud.com"
    ["IBM"]="cloud.ibm.com"
    ["Rackspace"]="rackspace.com"
)

# Inicializar módulo
init_cloud_detection() {
    log "INFO" "Initializing Cloud Detection module" "CLOUD"
    
    # Verificar dependências
    local deps=("dig" "curl" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "CLOUD"
        return 1
    fi
    
    return 0
}

# Função principal
detect_cloud_infrastructure() {
    local target="$1"
    local output_dir="$2"
    
    log "RECON" "Starting cloud infrastructure detection for: $target" "CLOUD"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/cloud"
    mkdir -p "$results_dir"
    
    local results="{}"
    
    # 1. Detect cloud provider from DNS
    log "INFO" "Detecting cloud provider from DNS" "CLOUD"
    local dns_provider
    dns_provider=$(detect_provider_from_dns "$target")
    results=$(echo "$results" | jq --arg provider "$dns_provider" '.dns_provider = $provider')
    
    # 2. Detect cloud provider from IP
    log "INFO" "Detecting cloud provider from IP" "CLOUD"
    local ip_provider
    ip_provider=$(detect_provider_from_ip "$target")
    results=$(echo "$results" | jq --arg provider "$ip_provider" '.ip_provider = $ip_provider')
    
    # 3. Detect cloud services
    log "INFO" "Detecting cloud services" "CLOUD"
    local services
    services=$(detect_cloud_services "$target")
    results=$(echo "$results" | jq --argjson services "$services" '.services = $services')
    
    # 4. Detect cloud regions
    log "INFO" "Detecting cloud regions" "CLOUD"
    local regions
    regions=$(detect_cloud_regions "$target")
    results=$(echo "$results" | jq --argjson regions "$regions" '.regions = $regions')
    
    # 5. Check for cloud storage
    log "INFO" "Checking for cloud storage" "CLOUD"
    local storage
    storage=$(detect_cloud_storage "$target")
    results=$(echo "$results" | jq --argjson storage "$storage" '.storage = $storage')
    
    # 6. Check for serverless functions
    log "INFO" "Checking for serverless functions" "CLOUD"
    local serverless
    serverless=$(detect_serverless "$target")
    results=$(echo "$results" | jq --argjson serverless "$serverless" '.serverless = $serverless')
    
    # 7. Check for CDN usage
    log "INFO" "Checking for CDN usage" "CLOUD"
    local cdn
    cdn=$(detect_cdn_cloud "$target")
    results=$(echo "$results" | jq --argjson cdn "$cdn" '.cdn = $cdn')
    
    # 8. Get cloud metadata if available
    log "INFO" "Attempting to access cloud metadata" "CLOUD"
    local metadata
    metadata=$(get_cloud_metadata "$target")
    results=$(echo "$results" | jq --argjson metadata "$metadata" '.metadata = $metadata')
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/cloud.json"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "SUCCESS" "Cloud detection completed in ${duration}s" "CLOUD"
    
    echo "$results"
}

# Detectar provedor a partir de DNS
detect_provider_from_dns() {
    local target="$1"
    
    # Verificar CNAME
    local cname
    cname=$(dig +short "$target" CNAME 2>/dev/null | head -1)
    
    if [[ -n "$cname" ]]; then
        for provider in "${!CLOUD_PROVIDERS[@]}"; do
            local domains="${CLOUD_PROVIDERS[$provider]}"
            
            for domain in $domains; do
                if [[ "$cname" == *"$domain"* ]]; then
                    echo "$provider"
                    return 0
                fi
            done
        done
    fi
    
    # Verificar registros TXT (para verificação de domínio)
    local txt
    txt=$(dig +short "$target" TXT 2>/dev/null)
    
    if [[ -n "$txt" ]]; then
        for provider in "${!CLOUD_PROVIDERS[@]}"; do
            if echo "$txt" | grep -qi "$provider"; then
                echo "$provider"
                return 0
            fi
        done
    fi
    
    echo "Unknown"
}

# Detectar provedor a partir de IP
detect_provider_from_ip() {
    local target="$1"
    
    # Resolver IP
    local ip
    ip=$(dig +short "$target" A 2>/dev/null | head -1)
    
    if [[ -z "$ip" ]]; then
        ip="$target"
    fi
    
    # Verificar via whois
    local whois_info
    whois_info=$(whois "$ip" 2>/dev/null)
    
    for provider in "${!CLOUD_PROVIDERS[@]}"; do
        if echo "$whois_info" | grep -qi "$provider"; then
            echo "$provider"
            return 0
        fi
    done
    
    # Verificar ranges conhecidos (simplificado)
    if [[ "$ip" =~ ^(52|54)\.[0-9] ]]; then
        echo "AWS"
    elif [[ "$ip" =~ ^13\.[0-9] ]] || [[ "$ip" =~ ^40\.[0-9] ]]; then
        echo "Azure"
    elif [[ "$ip" =~ ^35\.[0-9] ]]; then
        echo "GCP"
    elif [[ "$ip" =~ ^(104|107|128|137|138|139|140|141|142|143|144|145|146|147|148|149|150|151|152|153|154|155|156|157|158|159|160)\.[0-9] ]]; then
        echo "DigitalOcean"
    else
        echo "Unknown/On-premise"
    fi
}

# Detectar serviços cloud
detect_cloud_services() {
    local target="$1"
    local services="{}"
    
    # S3 buckets
    if [[ "$target" == *"s3.amazonaws.com"* ]] || [[ "$target" == *"s3-website"* ]]; then
        services=$(echo "$services" | jq '.s3 = true')
    fi
    
    # EC2
    if [[ "$target" == *"ec2.amazonaws.com"* ]] || [[ "$target" == *"compute.amazonaws.com"* ]]; then
        services=$(echo "$services" | jq '.ec2 = true')
    fi
    
    # Lambda
    if [[ "$target" == *"lambda-url"* ]] || [[ "$target" == *"lambda.amazonaws.com"* ]]; then
        services=$(echo "$services" | jq '.lambda = true')
    fi
    
    # CloudFront
    if [[ "$target" == *"cloudfront.net"* ]]; then
        services=$(echo "$services" | jq '.cloudfront = true')
    fi
    
    # RDS
    if [[ "$target" == *"rds.amazonaws.com"* ]]; then
        services=$(echo "$services" | jq '.rds = true')
    fi
    
    # Azure App Service
    if [[ "$target" == *"azurewebsites.net"* ]]; then
        services=$(echo "$services" | jq '.app_service = true')
    fi
    
    # Azure Functions
    if [[ "$target" == *"azurewebsites.net"* ]] && [[ "$target" == *"api"* ]]; then
        services=$(echo "$services" | jq '.functions = true')
    fi
    
    # GCP App Engine
    if [[ "$target" == *"appspot.com"* ]]; then
        services=$(echo "$services" | jq '.app_engine = true')
    fi
    
    # GCP Cloud Functions
    if [[ "$target" == *"cloudfunctions.net"* ]]; then
        services=$(echo "$services" | jq '.cloud_functions = true')
    fi
    
    echo "$services"
}

# Detectar regiões cloud
detect_cloud_regions() {
    local target="$1"
    local regions="[]"
    
    # Extrair região de padrões conhecidos
    # AWS: us-east-1, eu-west-1, etc
    if [[ "$target" =~ us-east-[0-9] ]] || [[ "$target" =~ us-west-[0-9] ]] || \
       [[ "$target" =~ eu-(west|central|north)-[0-9] ]] || \
       [[ "$target" =~ ap-(southeast|northeast|south)-[0-9] ]]; then
        local region
        region=$(echo "$target" | grep -oE '(us|eu|ap|sa|ca)-(east|west|central|north|south|northeast|southeast)-[0-9]')
        regions=$(echo "$regions" | jq --arg region "$region" '. += [$region]')
    fi
    
    # Azure: westeurope, eastus, etc
    if [[ "$target" =~ (westeurope|eastus|westus|northeurope|southeastasia) ]]; then
        local region
        region=$(echo "$target" | grep -oE '(westeurope|eastus|westus|northeurope|southeastasia)')
        regions=$(echo "$regions" | jq --arg region "$region" '. += [$region]')
    fi
    
    # GCP: us-central1, europe-west1, etc
    if [[ "$target" =~ (us|europe|asia)-(central|west|east|north|south)[0-9] ]]; then
        local region
        region=$(echo "$target" | grep -oE '(us|europe|asia)-(central|west|east|north|south)[0-9]')
        regions=$(echo "$regions" | jq --arg region "$region" '. += [$region]')
    fi
    
    echo "$regions"
}

# Detectar cloud storage
detect_cloud_storage() {
    local target="$1"
    local storage="[]"
    
    # Tentar acessar buckets comuns
    local bucket_names=(
        "${target}-backup"
        "${target}-files"
        "${target}-static"
        "${target}-assets"
        "${target}-media"
        "${target}-uploads"
        "${target}-data"
        "${target}-storage"
        "backup-${target}"
        "files-${target}"
        "static-${target}"
    )
    
    # AWS S3
    for bucket in "${bucket_names[@]}"; do
        local url="https://${bucket}.s3.amazonaws.com"
        if curl -s -I "$url" 2>/dev/null | grep -q "200\|403\|404"; then
            storage=$(echo "$storage" | jq --arg bucket "$bucket" --arg url "$url" \
                '. += [{"provider": "AWS", "type": "s3", "bucket": $bucket, "url": $url}]')
        fi
    done
    
    # Azure Blob
    for bucket in "${bucket_names[@]}"; do
        local url="https://${bucket}.blob.core.windows.net"
        if curl -s -I "$url" 2>/dev/null | grep -q "200\|403\|404"; then
            storage=$(echo "$storage" | jq --arg bucket "$bucket" --arg url "$url" \
                '. += [{"provider": "Azure", "type": "blob", "container": $bucket, "url": $url}]')
        fi
    done
    
    # GCP Storage
    for bucket in "${bucket_names[@]}"; do
        local url="https://storage.googleapis.com/${bucket}"
        if curl -s -I "$url" 2>/dev/null | grep -q "200\|403\|404"; then
            storage=$(echo "$storage" | jq --arg bucket "$bucket" --arg url "$url" \
                '. += [{"provider": "GCP", "type": "storage", "bucket": $bucket, "url": $url}]')
        fi
    done
    
    echo "$storage"
}

# Detectar serverless functions
detect_serverless() {
    local target="$1"
    local serverless="[]"
    
    # AWS Lambda URLs
    if [[ "$target" == *"lambda-url"* ]] || [[ "$target" == *"lambda.amazonaws.com"* ]]; then
        serverless=$(echo "$serverless" | jq '. += [{"provider": "AWS", "type": "lambda", "endpoint": "'$target'"}]')
    fi
    
    # Azure Functions
    if [[ "$target" == *"azurewebsites.net"* ]] && [[ "$target" == *"api"* ]]; then
        serverless=$(echo "$serverless" | jq '. += [{"provider": "Azure", "type": "function", "endpoint": "'$target'"}]')
    fi
    
    # GCP Cloud Functions
    if [[ "$target" == *"cloudfunctions.net"* ]]; then
        serverless=$(echo "$serverless" | jq '. += [{"provider": "GCP", "type": "cloud_function", "endpoint": "'$target'"}]')
    fi
    
    # Vercel
    if [[ "$target" == *"vercel.app"* ]]; then
        serverless=$(echo "$serverless" | jq '. += [{"provider": "Vercel", "type": "serverless", "endpoint": "'$target'"}]')
    fi
    
    # Netlify
    if [[ "$target" == *"netlify.app"* ]]; then
        serverless=$(echo "$serverless" | jq '. += [{"provider": "Netlify", "type": "serverless", "endpoint": "'$target'"}]')
    fi
    
    echo "$serverless"
}

# Detectar CDN (versão cloud)
detect_cdn_cloud() {
    local target="$1"
    local cdn="{}"
    
    # Cloudflare
    local cloudflare_ip_ranges=(
        "103.21.244.0/22"
        "103.22.200.0/22"
        "103.31.4.0/22"
        "104.16.0.0/12"
        "108.162.192.0/18"
        "131.0.72.0/22"
        "141.101.64.0/18"
        "162.158.0.0/15"
        "172.64.0.0/13"
        "173.245.48.0/20"
        "188.114.96.0/20"
        "190.93.240.0/20"
        "197.234.240.0/22"
        "198.41.128.0/17"
    )
    
    # Verificar IP
    local ip
    ip=$(dig +short "$target" A 2>/dev/null | head -1)
    
    if [[ -n "$ip" ]]; then
        # Cloudflare
        for range in "${cloudflare_ip_ranges[@]}"; do
            if ip_in_range "$ip" "$range"; then
                cdn=$(echo "$cdn" | jq '.provider = "Cloudflare"')
                break
            fi
        done
        
        # Fastly
        if [[ "$ip" =~ ^(23\.235|151\.101) ]]; then
            cdn=$(echo "$cdn" | jq '.provider = "Fastly"')
        fi
        
        # Akamai
        if [[ "$ip" =~ ^(23|184|96)\. ]]; then
            cdn=$(echo "$cdn" | jq '.provider = "Akamai"')
        fi
    fi
    
    # Headers
    local headers
    headers=$(curl -s -I "http://${target}" 2>/dev/null)
    
    if [[ -n "$headers" ]]; then
        if echo "$headers" | grep -qi "cloudflare"; then
            cdn=$(echo "$cdn" | jq '.provider = "Cloudflare"')
        elif echo "$headers" | grep -qi "fastly"; then
            cdn=$(echo "$cdn" | jq '.provider = "Fastly"')
        elif echo "$headers" | grep -qi "akamai"; then
            cdn=$(echo "$cdn" | jq '.provider = "Akamai"')
        elif echo "$headers" | grep -qi "cloudfront"; then
            cdn=$(echo "$cdn" | jq '.provider = "CloudFront"')
        fi
    fi
    
    if [[ "$(echo "$cdn" | jq -r '.provider')" == "null" ]]; then
        cdn=$(echo "$cdn" | jq '.provider = "No CDN detected"')
    fi
    
    echo "$cdn"
}

# Obter metadata da cloud (tentativa de SSRF)
get_cloud_metadata() {
    local target="$1"
    local metadata="{}"
    
    # URLs de metadata por provedor
    local metadata_urls=(
        "http://169.254.169.254/latest/meta-data/"  # AWS
        "http://169.254.169.254/metadata/instance?api-version=2017-08-01"  # Azure
        "http://metadata.google.internal/computeMetadata/v1/"  # GCP
        "http://169.254.169.254/2009-04-04/meta-data/"  # OpenStack
        "http://100.100.100.200/latest/meta-data/"  # Alibaba
    )
    
    # Tentar acessar metadata via SSRF
    for url in "${metadata_urls[@]}"; do
        local response
        response=$(curl -s -L --max-time 3 -H "Metadata: true" "$url" 2>/dev/null)
        
        if [[ -n "$response" ]] && [[ ! "$response" == *"404"* ]]; then
            # Identificar provedor
            local provider="unknown"
            
            if [[ "$url" == *"169.254.169.254"* ]] && [[ "$url" == *"latest"* ]]; then
                provider="AWS"
            elif [[ "$url" == *"169.254.169.254"* ]] && [[ "$url" == *"metadata"* ]]; then
                provider="Azure"
            elif [[ "$url" == *"metadata.google"* ]]; then
                provider="GCP"
            fi
            
            metadata=$(echo "$metadata" | jq \
                --arg provider "$provider" \
                --arg url "$url" \
                --arg response "$(echo "$response" | head -5)" \
                '{
                    accessible: true,
                    provider: $provider,
                    url: $url,
                    sample: $response
                }')
            
            break
        fi
    done
    
    if [[ "$(echo "$metadata" | jq -r '.accessible')" == "null" ]]; then
        metadata=$(echo "$metadata" | jq '.accessible = false')
    fi
    
    echo "$metadata"
}

# Verificar se IP está em range CIDR (simplificado)
ip_in_range() {
    local ip="$1"
    local cidr="$2"
    
    # Implementação simplificada - em produção usar ipcalc ou similar
    if command -v ipcalc &> /dev/null; then
        ipcalc -c "$ip" "$cidr" &>/dev/null
        return $?
    fi
    
    # Fallback básico
    local network="${cidr%/*}"
    local mask="${cidr#*/}"
    
    if [[ "$ip" == "$network"* ]]; then
        return 0
    fi
    
    return 1
}

# Exportar funções
export -f init_cloud_detection detect_cloud_infrastructure