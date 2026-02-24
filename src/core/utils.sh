#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Utility Functions
# =============================================================================

# Gerar ID único
generate_id() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 2>/dev/null || \
    date +%s%N | sha256sum | base64 | head -c 16
}

# Validar domínio
validate_domain() {
    local domain="$1"
    
    # Regex para domínio válido
    local domain_regex='^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'
    
    if [[ "$domain" =~ $domain_regex ]]; then
        return 0
    else
        return 1
    fi
}

# Validar IP
validate_ip() {
    local ip="$1"
    
    # IPv4
    local ipv4_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ "$ip" =~ $ipv4_regex ]]; then
        # Verificar cada octeto
        IFS='.' read -r -a octets <<< "$ip"
        for octet in "${octets[@]}"; do
            if [[ $octet -gt 255 ]] || [[ $octet -lt 0 ]]; then
                return 1
            fi
        done
        return 0
    fi
    
    # IPv6 (simplificado)
    local ipv6_regex='^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$'
    if [[ "$ip" =~ $ipv6_regex ]]; then
        return 0
    fi
    
    return 1
}

# Validar email
validate_email() {
    local email="$1"
    
    local email_regex='^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    
    if [[ "$email" =~ $email_regex ]]; then
        return 0
    else
        return 1
    fi
}

# Validar URL
validate_url() {
    local url="$1"
    
    local url_regex='^(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
    
    if [[ "$url" =~ $url_regex ]]; then
        return 0
    else
        return 1
    fi
}

# Extrair domínio de URL
extract_domain() {
    local url="$1"
    
    # Remover protocolo
    local domain="${url#http://}"
    domain="${domain#https://}"
    domain="${domain#ftp://}"
    domain="${domain#file://}"
    
    # Remover path, query, fragment
    domain="${domain%%/*}"
    domain="${domain%%\?*}"
    domain="${domain%%#*}"
    
    # Remover porta
    domain="${domain%%:*}"
    
    echo "$domain"
}

# Extrair IPs de texto
extract_ips() {
    local text="$1"
    
    # IPv4
    echo "$text" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u
    
    # IPv6 (simplificado)
    echo "$text" | grep -oE '([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}' | sort -u
}

# Extrair emails de texto
extract_emails() {
    local text="$1"
    
    echo "$text" | grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u
}

# Extrair URLs de texto
extract_urls() {
    local text="$1"
    
    echo "$text" | grep -oE '(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]' | sort -u
}

# Converter para JSON
to_json() {
    local key="$1"
    local value="$2"
    
    jq -n --arg key "$key" --arg value "$value" '{$key: $value}'
}

# Converter de JSON
from_json() {
    local json="$1"
    local key="$2"
    
    echo "$json" | jq -r ".$key // empty"
}

# Timestamp atual
current_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Timestamp Unix
unix_timestamp() {
    date +%s
}

# Formatar tamanho de arquivo
format_size() {
    local size="$1"
    
    if [[ $size -lt 1024 ]]; then
        echo "${size}B"
    elif [[ $size -lt 1048576 ]]; then
        echo "$((size / 1024))KB"
    elif [[ $size -lt 1073741824 ]]; then
        echo "$((size / 1048576))MB"
    else
        echo "$((size / 1073741824))GB"
    fi
}

# Formatar tempo
format_duration() {
    local seconds="$1"
    
    local days=$((seconds / 86400))
    local hours=$(( (seconds % 86400) / 3600 ))
    local minutes=$(( (seconds % 3600) / 60 ))
    local secs=$((seconds % 60))
    
    if [[ $days -gt 0 ]]; then
        printf "%dd %02dh %02dm %02ds" $days $hours $minutes $secs
    elif [[ $hours -gt 0 ]]; then
        printf "%02dh %02dm %02ds" $hours $minutes $secs
    elif [[ $minutes -gt 0 ]]; then
        printf "%02dm %02ds" $minutes $secs
    else
        printf "%ds" $secs
    fi
}

# Verificar se porta está aberta
check_port() {
    local host="$1"
    local port="$2"
    local timeout="${3:-2}"
    
    timeout "$timeout" bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null && return 0 || return 1
}

# Scan de portas rápido
quick_port_scan() {
    local host="$1"
    local ports=(${2:-21,22,23,25,53,80,110,111,135,139,143,443,445,993,995,1723,3306,3389,5900,8080})
    
    local open_ports=()
    
    for port in "${ports[@]}"; do
        if check_port "$host" "$port"; then
            open_ports+=("$port")
        fi
    done
    
    echo "${open_ports[@]}"
}

# Resolver DNS
resolve_dns() {
    local host="$1"
    local type="${2:-A}"
    
    dig +short "$host" "$type" 2>/dev/null || \
    host -t "$type" "$host" 2>/dev/null | awk '{print $NF}' || \
    nslookup "$host" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}'
}

# Reverse DNS
reverse_dns() {
    local ip="$1"
    
    dig +short -x "$ip" 2>/dev/null || \
    host "$ip" 2>/dev/null | grep -oE '[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | head -1
}

# Whois lookup
whois_lookup() {
    local target="$1"
    
    whois "$target" 2>/dev/null
}

# HTTP request
http_request() {
    local url="$1"
    local method="${2:-GET}"
    local headers="${3:-}"
    local data="${4:-}"
    
    local curl_cmd=("curl" "-s" "-L" "-k" "-X" "$method")
    
    # Headers
    if [[ -n "$headers" ]]; then
        while IFS= read -r header; do
            curl_cmd+=("-H" "$header")
        done <<< "$headers"
    fi
    
    # User-Agent
    curl_cmd+=("-H" "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    
    # Data
    if [[ -n "$data" ]]; then
        curl_cmd+=("-d" "$data")
    fi
    
    # Timeout
    curl_cmd+=("--max-time" "10")
    
    # URL
    curl_cmd+=("$url")
    
    "${curl_cmd[@]}" 2>/dev/null
}

# Download file
download_file() {
    local url="$1"
    local output="$2"
    
    curl -s -L -k -o "$output" "$url" 2>/dev/null
}

# Extrair metadados de arquivo
extract_metadata() {
    local file="$1"
    
    if command -v exiftool &> /dev/null; then
        exiftool -json "$file" 2>/dev/null
    elif command -v identify &> /dev/null; then
        identify -verbose "$file" 2>/dev/null
    else
        echo "{}"
    fi
}

# Calcular hash
calculate_hash() {
    local file="$1"
    local algorithm="${2:-sha256}"
    
    case "$algorithm" in
        md5)
            md5sum "$file" 2>/dev/null | cut -d' ' -f1
            ;;
        sha1)
            sha1sum "$file" 2>/dev/null | cut -d' ' -f1
            ;;
        sha256)
            sha256sum "$file" 2>/dev/null | cut -d' ' -f1
            ;;
        *)
            sha256sum "$file" 2>/dev/null | cut -d' ' -f1
            ;;
    esac
}

# Codificar URL
url_encode() {
    local string="$1"
    
    echo -n "$string" | jq -sRr @uri
}

# Decodificar URL
url_decode() {
    local string="$1"
    
    echo -n "$string" | sed 's/+/ /g; s/%/\\x/g' | xargs -0 printf "%b"
}

# Codificar Base64
base64_encode() {
    local string="$1"
    
    echo -n "$string" | base64
}

# Decodificar Base64
base64_decode() {
    local string="$1"
    
    echo -n "$string" | base64 -d 2>/dev/null || echo "$string"
}

# Gerar senha aleatória
generate_password() {
    local length="${1:-16}"
    
    cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&*()_+' | fold -w "$length" | head -n 1 2>/dev/null || \
    openssl rand -base64 "$((length * 3/4))" | tr -d '\n' | cut -c1-"$length"
}

# Verificar se comando existe
check_command() {
    local cmd="$1"
    
    if command -v "$cmd" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Verificar versão de comando
check_version() {
    local cmd="$1"
    local min_version="$2"
    
    if ! check_command "$cmd"; then
        return 1
    fi
    
    local version
    version=$("$cmd" --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    
    if [[ -z "$version" ]]; then
        return 0  # Não conseguiu determinar versão
    fi
    
    # Comparar versões (simples)
    if [[ "$version" < "$min_version" ]]; then
        return 1
    fi
    
    return 0
}

# Matar processo por nome
kill_process() {
    local process="$1"
    local signal="${2:-TERM}"
    
    pkill -"$signal" -f "$process" 2>/dev/null
}

# Verificar se processo está rodando
check_process() {
    local pid="$1"
    
    kill -0 "$pid" 2>/dev/null
}

# Pegar PID por nome
get_pid() {
    local process="$1"
    
    pgrep -f "$process" | head -1
}

# Criar diretório se não existir
ensure_dir() {
    local dir="$1"
    
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi
}

# Remover arquivos temporários
cleanup_temp() {
    local pattern="${1:-*}"
    
    find "$TEMP_DIR" -name "$pattern" -type f -mmin +60 -delete 2>/dev/null
}

# Monitorar uso de memória
check_memory() {
    local pid="$1"
    
    if [[ -f "/proc/$pid/status" ]]; then
        grep VmRSS "/proc/$pid/status" | awk '{print $2}'
    else
        ps -o rss= -p "$pid" 2>/dev/null || echo 0
    fi
}

# Monitorar uso de CPU
check_cpu() {
    local pid="$1"
    
    ps -o pcpu= -p "$pid" 2>/dev/null || echo 0
}

# Executar com timeout
run_with_timeout() {
    local timeout="$1"
    shift
    local cmd=("$@")
    
    timeout "$timeout" "${cmd[@]}" 2>/dev/null
}

# Executar em paralelo
run_parallel() {
    local max_jobs="${1:-10}"
    shift
    local commands=("$@")
    
    local pids=()
    local running=0
    
    for cmd in "${commands[@]}"; do
        # Aguardar se atingir máximo
        if [[ $running -ge $max_jobs ]]; then
            wait -n 2>/dev/null || true
            ((running--))
        fi
        
        # Executar em background
        eval "$cmd" &
        pids+=($!)
        ((running++))
    done
    
    # Aguardar todos
    wait
}

# Retry com backoff
retry() {
    local max_attempts="${1:-3}"
    local delay="${2:-1}"
    shift 2
    local cmd=("$@")
    
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if "${cmd[@]}"; then
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            sleep $((delay * attempt))
        fi
        
        ((attempt++))
    done
    
    return 1
}

# Spinner de loading
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    
    while ps -p "$pid" > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Barra de progresso
progress_bar() {
    local current="$1"
    local total="$2"
    local width=50
    
    local percentage=$((current * 100 / total))
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    
    printf "["
    printf "%0.s#" $(seq 1 $filled)
    printf "%0.s-" $(seq 1 $empty)
    printf "] %d%%" $percentage
}

# Ler input com timeout
read_with_timeout() {
    local timeout="$1"
    local prompt="$2"
    
    if [[ -n "$prompt" ]]; then
        echo -n "$prompt"
    fi
    
    read -t "$timeout" input
    echo "$input"
}

# Confirmar ação
confirm_action() {
    local prompt="${1:-Continue?}"
    local default="${2:-n}"
    
    local yn
    read -p "$prompt (y/N): " yn
    
    case "$yn" in
        [Yy]*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Exportar funções
export -f generate_id validate_domain validate_ip validate_email validate_url
export -f extract_domain extract_ips extract_emails extract_urls
export -f to_json from_json current_timestamp unix_timestamp
export -f format_size format_duration
export -f check_port quick_port_scan resolve_dns reverse_dns whois_lookup
export -f http_request download_file extract_metadata calculate_hash
export -f url_encode url_decode base64_encode base64_decode generate_password
export -f check_command check_version kill_process check_process get_pid
export -f ensure_dir cleanup_temp check_memory check_cpu
export -f run_with_timeout run_parallel retry
export -f spinner progress_bar read_with_timeout confirm_action