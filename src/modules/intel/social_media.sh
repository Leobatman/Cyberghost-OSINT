#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Social Media Intelligence Module
# =============================================================================

MODULE_NAME="Social Media Intelligence"
MODULE_DESC="Gather intelligence from social media platforms"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# Plataformas de mídia social
declare -A SOCIAL_PLATFORMS=(
    ["twitter"]="Twitter"
    ["facebook"]="Facebook"
    ["instagram"]="Instagram"
    ["linkedin"]="LinkedIn"
    ["youtube"]="YouTube"
    ["tiktok"]="TikTok"
    ["snapchat"]="Snapchat"
    ["reddit"]="Reddit"
    ["pinterest"]="Pinterest"
    ["tumblr"]="Tumblr"
    ["flickr"]="Flickr"
    ["github"]="GitHub"
    ["gitlab"]="GitLab"
    ["bitbucket"]="BitBucket"
    ["medium"]="Medium"
    ["devto"]="Dev.to"
    ["hackernews"]="HackerNews"
    ["producthunt"]="ProductHunt"
    ["behance"]="Behance"
    ["dribbble"]="Dribbble"
    ["soundcloud"]="SoundCloud"
    ["spotify"]="Spotify"
    ["lastfm"]="Last.fm"
    ["goodreads"]="GoodReads"
    ["quora"]="Quora"
    ["stackoverflow"]="StackOverflow"
    ["keybase"]="Keybase"
    ["aboutme"]="About.me"
    ["angellist"]="AngelList"
    ["crunchbase"]="CrunchBase"
)

# URLs de busca por plataforma
declare -A PLATFORM_URLS=(
    ["twitter"]="https://twitter.com/%s"
    ["facebook"]="https://facebook.com/%s"
    ["instagram"]="https://instagram.com/%s"
    ["linkedin"]="https://linkedin.com/in/%s"
    ["youtube"]="https://youtube.com/@%s"
    ["tiktok"]="https://tiktok.com/@%s"
    ["snapchat"]="https://snapchat.com/add/%s"
    ["reddit"]="https://reddit.com/user/%s"
    ["pinterest"]="https://pinterest.com/%s"
    ["tumblr"]="https://%s.tumblr.com"
    ["flickr"]="https://flickr.com/people/%s"
    ["github"]="https://github.com/%s"
    ["gitlab"]="https://gitlab.com/%s"
    ["bitbucket"]="https://bitbucket.org/%s"
    ["medium"]="https://medium.com/@%s"
    ["devto"]="https://dev.to/%s"
    ["hackernews"]="https://news.ycombinator.com/user?id=%s"
    ["producthunt"]="https://producthunt.com/@%s"
    ["behance"]="https://behance.net/%s"
    ["dribbble"]="https://dribbble.com/%s"
    ["soundcloud"]="https://soundcloud.com/%s"
    ["spotify"]="https://open.spotify.com/user/%s"
    ["lastfm"]="https://last.fm/user/%s"
    ["goodreads"]="https://goodreads.com/%s"
    ["quora"]="https://quora.com/profile/%s"
    ["stackoverflow"]="https://stackoverflow.com/users/%s"
    ["keybase"]="https://keybase.io/%s"
    ["aboutme"]="https://about.me/%s"
    ["angellist"]="https://angel.co/u/%s"
    ["crunchbase"]="https://crunchbase.com/person/%s"
)

# APIs (quando disponíveis)
declare -A PLATFORM_APIS=(
    ["twitter"]="https://api.twitter.com/2/users/by/username/%s"
    ["github"]="https://api.github.com/users/%s"
    ["gitlab"]="https://gitlab.com/api/v4/users?username=%s"
    ["reddit"]="https://www.reddit.com/user/%s/about.json"
    ["instagram"]="https://www.instagram.com/%s/?__a=1&__d=dis"
)

# Inicializar módulo
init_social_media() {
    log "INFO" "Initializing Social Media Intelligence module" "SOCIAL"
    
    # Verificar dependências
    local deps=("curl" "jq" "dig")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "SOCIAL"
        return 1
    fi
    
    return 0
}

# Função principal
social_media_intel() {
    local username="$1"
    local output_dir="$2"
    
    log "INTEL" "Starting social media intelligence for: $username" "SOCIAL"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/social_media"
    mkdir -p "$results_dir"
    
    local results="{}"
    
    results=$(echo "$results" | jq --arg user "$username" '.username = $user')
    
    # 1. Verificar disponibilidade em plataformas
    log "INFO" "Checking username availability across platforms" "SOCIAL"
    local availability
    availability=$(check_platform_availability "$username")
    results=$(echo "$results" | jq --argjson avail "$availability" '.availability = $avail')
    
    # 2. Coletar perfis encontrados
    log "INFO" "Collecting profile information" "SOCIAL"
    local profiles
    profiles=$(collect_profiles "$username" "$availability")
    results=$(echo "$results" | jq --argjson profiles "$profiles" '.profiles = $profiles')
    
    # 3. Buscar por email associado
    log "INFO" "Searching for associated email addresses" "SOCIAL"
    local emails
    emails=$(find_associated_emails "$username" "$profiles")
    results=$(echo "$results" | jq --argjson emails "$emails" '.associated_emails = $emails')
    
    # 4. Buscar por nome real
    log "INFO" "Extracting real names" "SOCIAL"
    local names
    names=$(extract_real_names "$profiles")
    results=$(echo "$results" | jq --argjson names "$names" '.real_names = $names')
    
    # 5. Buscar por localização
    log "INFO" "Extracting location information" "SOCIAL"
    local locations
    locations=$(extract_locations "$profiles")
    results=$(echo "$results" | jq --argjson locs "$locations" '.locations = $locs')
    
    # 6. Buscar por bio/descrição
    log "INFO" "Extracting bios and descriptions" "SOCIAL"
    local bios
    bios=$(extract_bios "$profiles")
    results=$(echo "$results" | jq --argjson bios "$bios" '.bios = $bios')
    
    # 7. Buscar por URLs/links
    log "INFO" "Extracting URLs and links" "SOCIAL"
    local urls
    urls=$(extract_urls_from_profiles "$profiles")
    results=$(echo "$results" | jq --argjson urls "$urls" '.external_urls = $urls')
    
    # 8. Buscar por imagens/fotos
    log "INFO" "Extracting profile images" "SOCIAL"
    local images
    images=$(extract_profile_images "$profiles")
    results=$(echo "$results" | jq --argjson images "$images" '.profile_images = $images')
    
    # 9. Análise de posts/conteúdo (para plataformas com API)
    log "INFO" "Analyzing recent content" "SOCIAL"
    local content
    content=$(analyze_recent_content "$username" "$profiles")
    results=$(echo "$results" | jq --argjson content "$content" '.recent_content = $content')
    
    # 10. Verificar conexões/amigos
    log "INFO" "Checking connections and followers" "SOCIAL"
    local connections
    connections=$(check_connections "$profiles")
    results=$(echo "$results" | jq --argjson conn "$connections" '.connections = $conn')
    
    # 11. Verificar em mecanismos de busca
    log "INFO" "Searching in search engines" "SOCIAL"
    local search_results
    search_results=$(search_username "$username")
    results=$(echo "$results" | jq --argjson search "$search_results" '.search_engines = $search')
    
    # 12. Verificar em arquivos da internet
    log "INFO" "Checking internet archives" "SOCIAL"
    local archives
    archives=$(check_internet_archives "$username" "$profiles")
    results=$(echo "$results" | jq --argjson archives "$archives" '.internet_archives = $archives')
    
    # 13. Gerar linha do tempo
    log "INFO" "Generating timeline" "SOCIAL"
    local timeline
    timeline=$(generate_timeline "$profiles" "$content")
    results=$(echo "$results" | jq --argjson timeline "$timeline" '.timeline = $timeline')
    
    # 14. Análise de sentimentos (se houver conteúdo)
    log "INFO" "Performing sentiment analysis" "SOCIAL"
    local sentiment
    sentiment=$(analyze_sentiment "$content")
    results=$(echo "$results" | jq --argjson sentiment "$sentiment" '.sentiment = $sentiment')
    
    # 15. Verificar similaridade entre perfis
    log "INFO" "Checking profile similarity" "SOCIAL"
    local similarity
    similarity=$(check_profile_similarity "$profiles")
    results=$(echo "$results" | jq --argjson sim "$similarity" '.similarity_analysis = $sim')
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/social_media.json"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local profiles_found
    profiles_found=$(echo "$profiles" | jq 'length')
    
    log "SUCCESS" "Social media intelligence completed in ${duration}s - Found $profiles_found profiles" "SOCIAL"
    
    echo "$results"
}

# Verificar disponibilidade em plataformas
check_platform_availability() {
    local username="$1"
    local results="[]"
    
    log "DEBUG" "Checking username on ${#PLATFORM_URLS[@]} platforms" "SOCIAL"
    
    for platform in "${!PLATFORM_URLS[@]}"; do
        local url
        url=$(printf "${PLATFORM_URLS[$platform]}" "$username")
        
        log "DEBUG" "Checking $platform: $url" "SOCIAL"
        
        # Verificar se a URL existe
        local status
        status=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 5 "$url" 2>/dev/null)
        
        # Algumas plataformas retornam 200 mesmo para não encontrado
        local found=false
        
        if [[ "$status" == "200" ]]; then
            # Verificar conteúdo para confirmar
            local content
            content=$(curl -s -L --max-time 5 "$url" 2>/dev/null)
            
            case "$platform" in
                "twitter")
                    if [[ "$content" != *"This account doesn't exist"* ]] && \
                       [[ "$content" != *"This profile doesn't exist"* ]] && \
                       [[ "$content" != *"Page not found"* ]]; then
                        found=true
                    fi
                    ;;
                "instagram")
                    if [[ "$content" != *"Page Not Found"* ]] && \
                       [[ "$content" != *"page isn't available"* ]]; then
                        found=true
                    fi
                    ;;
                "facebook")
                    if [[ "$content" != *"Content Not Found"* ]] && \
                       [[ "$content" != *"This page isn't available"* ]]; then
                        found=true
                    fi
                    ;;
                "linkedin")
                    if [[ "$content" != *"Page not found"* ]] && \
                       [[ "$content" != *"Profile not found"* ]]; then
                        found=true
                    fi
                    ;;
                "github")
                    if [[ "$content" != *"404"* ]] && \
                       [[ "$content" != *"Not Found"* ]]; then
                        found=true
                    fi
                    ;;
                *)
                    # Verificação genérica: se não houver indicadores de não encontrado
                    if [[ "$content" != *"not found"* ]] && \
                       [[ "$content" != *"doesn't exist"* ]] && \
                       [[ "$content" != *"404"* ]] && \
                       [[ "$content" != *"no longer exists"* ]]; then
                        found=true
                    fi
                    ;;
            esac
        fi
        
        if [[ "$found" == "true" ]]; then
            results=$(echo "$results" | jq --arg platform "$platform" --arg url "$url" \
                '. += [{"platform": $platform, "url": $url, "status": "found"}]')
        else
            results=$(echo "$results" | jq --arg platform "$platform" --arg url "$url" \
                '. += [{"platform": $platform, "url": $url, "status": "not_found"}]')
        fi
    done
    
    echo "$results"
}

# Coletar informações de perfis encontrados
collect_profiles() {
    local username="$1"
    local availability="$2"
    local profiles="[]"
    
    # Filtrar apenas plataformas onde foi encontrado
    local found_platforms
    found_platforms=$(echo "$availability" | jq -c '[.[] | select(.status == "found")]')
    
    echo "$found_platforms" | jq -c '.[]' | while read -r platform_info; do
        local platform
        platform=$(echo "$platform_info" | jq -r '.platform')
        local url
        url=$(echo "$platform_info" | jq -r '.url')
        
        log "DEBUG" "Collecting data from $platform" "SOCIAL"
        
        local profile_data="{}"
        
        # Tentar usar API se disponível
        if [[ -n "${PLATFORM_APIS[$platform]}" ]]; then
            profile_data=$(get_profile_via_api "$platform" "$username")
        fi
        
        # Se não conseguiu via API, tentar scraping
        if [[ "$profile_data" == "{}" ]]; then
            profile_data=$(scrape_profile "$platform" "$url")
        fi
        
        # Adicionar informações básicas
        profile_data=$(echo "$profile_data" | jq \
            --arg platform "$platform" \
            --arg url "$url" \
            '.platform = $platform | .url = $url')
        
        profiles=$(echo "$profiles" | jq --argjson data "$profile_data" '. += [$data]')
    done
    
    echo "$profiles"
}

# Obter perfil via API
get_profile_via_api() {
    local platform="$1"
    local username="$2"
    local result="{}"
    
    case "$platform" in
        "github")
            if [[ -n "$GITHUB_API_KEY" ]]; then
                local url="https://api.github.com/users/${username}"
                local response
                response=$(curl -s -H "Authorization: token ${GITHUB_API_KEY}" "$url" 2>/dev/null)
                
                if [[ -n "$response" ]] && [[ "$response" != *"Not Found"* ]]; then
                    result=$(echo "$response" | jq '{
                        name: .name,
                        bio: .bio,
                        location: .location,
                        email: .email,
                        blog: .blog,
                        company: .company,
                        twitter: .twitter_username,
                        followers: .followers,
                        following: .following,
                        public_repos: .public_repos,
                        created_at: .created_at,
                        avatar_url: .avatar_url
                    }')
                fi
            fi
            ;;
            
        "gitlab")
            local url="https://gitlab.com/api/v4/users?username=${username}"
            local response
            response=$(curl -s "$url" 2>/dev/null)
            
            if [[ -n "$response" ]] && [[ "$response" != "[]" ]]; then
                result=$(echo "$response" | jq '.[0] | {
                    name: .name,
                    bio: .bio,
                    location: .location,
                    email: .public_email,
                    website: .website_url,
                    company: .organization,
                    twitter: .twitter,
                    followers: .followers_count,
                    following: .following_count,
                    public_repos: .project_count,
                    created_at: .created_at,
                    avatar_url: .avatar_url
                }')
            fi
            ;;
            
        "reddit")
            local url="https://www.reddit.com/user/${username}/about.json"
            local response
            response=$(curl -s -A "Mozilla/5.0" "$url" 2>/dev/null)
            
            if [[ -n "$response" ]] && [[ "$(echo "$response" | jq -r '.error')" != "404" ]]; then
                result=$(echo "$response" | jq '.data | {
                    name: .name,
                    created_utc: .created_utc,
                    link_karma: .link_karma,
                    comment_karma: .comment_karma,
                    is_gold: .is_gold,
                    is_mod: .is_mod,
                    has_verified_email: .has_verified_email,
                    icon_img: .icon_img
                }')
            fi
            ;;
    esac
    
    echo "$result"
}

# Scraping de perfil
scrape_profile() {
    local platform="$1"
    local url="$2"
    local result="{}"
    
    local content
    content=$(curl -s -L -A "Mozilla/5.0" --max-time 10 "$url" 2>/dev/null)
    
    if [[ -z "$content" ]]; then
        echo "{}"
        return
    fi
    
    case "$platform" in
        "twitter")
            # Extrair nome
            local name
            name=$(echo "$content" | grep -o '<meta property="og:title" content="[^"]*' | head -1 | cut -d'"' -f4)
            if [[ -n "$name" ]]; then
                result=$(echo "$result" | jq --arg name "$name" '.name = $name')
            fi
            
            # Extrair bio
            local bio
            bio=$(echo "$content" | grep -o '<meta property="og:description" content="[^"]*' | head -1 | cut -d'"' -f4)
            if [[ -n "$bio" ]]; then
                result=$(echo "$result" | jq --arg bio "$bio" '.bio = $bio')
            fi
            
            # Extrair imagem
            local image
            image=$(echo "$content" | grep -o '<meta property="og:image" content="[^"]*' | head -1 | cut -d'"' -f4)
            if [[ -n "$image" ]]; then
                result=$(echo "$result" | jq --arg img "$image" '.avatar = $img')
            fi
            ;;
            
        "instagram")
            # Tentar extrair dados JSON
            local json_data
            json_data=$(echo "$content" | grep -o 'window\._sharedData = [^<]*' | sed 's/window\._sharedData = //' | sed 's/;$//')
            
            if [[ -n "$json_data" ]]; then
                local user_data
                user_data=$(echo "$json_data" | jq '.entry_data.ProfilePage[0].graphql.user' 2>/dev/null)
                
                if [[ -n "$user_data" ]] && [[ "$user_data" != "null" ]]; then
                    local full_name
                    full_name=$(echo "$user_data" | jq -r '.full_name // empty')
                    local biography
                    biography=$(echo "$user_data" | jq -r '.biography // empty')
                    local followers
                    followers=$(echo "$user_data" | jq -r '.edge_followed_by.count // 0')
                    local following
                    following=$(echo "$user_data" | jq -r '.edge_follow.count // 0')
                    local posts
                    posts=$(echo "$user_data" | jq -r '.edge_owner_to_timeline_media.count // 0')
                    local avatar
                    avatar=$(echo "$user_data" | jq -r '.profile_pic_url_hd // .profile_pic_url // empty')
                    
                    result=$(echo "$result" | jq \
                        --arg name "$full_name" \
                        --arg bio "$biography" \
                        --argjson followers "$followers" \
                        --argjson following "$following" \
                        --argjson posts "$posts" \
                        --arg avatar "$avatar" \
                        '{
                            name: $name,
                            bio: $bio,
                            followers: $followers,
                            following: $following,
                            posts: $posts,
                            avatar: $avatar
                        }')
                fi
            fi
            ;;
            
        "linkedin")
            # Extrair nome
            local name
            name=$(echo "$content" | grep -o '<title>[^<]*' | head -1 | sed 's/<title>//' | sed 's/ | LinkedIn//')
            if [[ -n "$name" ]]; then
                result=$(echo "$result" | jq --arg name "$name" '.name = $name')
            fi
            
            # Extrair headline
            local headline
            headline=$(echo "$content" | grep -o 'og:description" content="[^"]*' | head -1 | cut -d'"' -f3)
            if [[ -n "$headline" ]]; then
                result=$(echo "$result" | jq --arg headline "$headline" '.headline = $headline')
            fi
            
            # Extrair localização
            local location
            location=$(echo "$content" | grep -o 'locality"[^>]*>[^<]*' | head -1 | sed 's/.*>//')
            if [[ -n "$location" ]]; then
                result=$(echo "$result" | jq --arg loc "$location" '.location = $loc')
            fi
            ;;
            
        "github")
            # Extrair nome
            local name
            name=$(echo "$content" | grep -o '<span class="p-name vcard-fullname d-block overflow-hidden">[^<]*' | sed 's/<[^>]*>//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
            if [[ -n "$name" ]]; then
                result=$(echo "$result" | jq --arg name "$name" '.name = $name')
            fi
            
            # Extrair bio
            local bio
            bio=$(echo "$content" | grep -o '<div class="p-note user-profile-bio mb-3 js-user-profile-bio f4">[^<]*' | sed 's/<[^>]*>//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
            if [[ -n "$bio" ]]; then
                result=$(echo "$result" | jq --arg bio "$bio" '.bio = $bio')
            fi
            
            # Extrair localização
            local location
            location=$(echo "$content" | grep -o '<span class="p-label">[^<]*' | head -1 | sed 's/<[^>]*>//g')
            if [[ -n "$location" ]]; then
                result=$(echo "$result" | jq --arg loc "$location" '.location = $loc')
            fi
            
            # Extrair stats
            local repos
            repos=$(echo "$content" | grep -o 'span class="Counter">[0-9,]*' | head -1 | sed 's/<[^>]*>//g' | sed 's/,//g')
            if [[ -n "$repos" ]]; then
                result=$(echo "$result" | jq --argjson repos "$repos" '.public_repos = $repos')
            fi
            
            local followers
            followers=$(echo "$content" | grep -o 'followers[^<]*' | head -1 | grep -o '[0-9,]*' | sed 's/,//g')
            if [[ -n "$followers" ]]; then
                result=$(echo "$result" | jq --argjson followers "$followers" '.followers = $followers')
            fi
            
            local following
            following=$(echo "$content" | grep -o 'following[^<]*' | head -1 | grep -o '[0-9,]*' | sed 's/,//g')
            if [[ -n "$following" ]]; then
                result=$(echo "$result" | jq --argjson following "$following" '.following = $following')
            fi
            ;;
    esac
    
    echo "$result"
}

# Encontrar emails associados
find_associated_emails() {
    local username="$1"
    local profiles="$2"
    local emails="[]"
    
    # De perfis
    echo "$profiles" | jq -c '.[]' | while read -r profile; do
        local platform
        platform=$(echo "$profile" | jq -r '.platform')
        local profile_email
        profile_email=$(echo "$profile" | jq -r '.email // empty')
        
        if [[ -n "$profile_email" ]] && [[ "$profile_email" != "null" ]]; then
            emails=$(echo "$emails" | jq --arg email "$profile_email" --arg platform "$platform" \
                '. += [{"email": $email, "source": $platform}]')
        fi
    done
    
    # Padrões comuns
    local common_patterns=(
        "${username}@gmail.com"
        "${username}@yahoo.com"
        "${username}@hotmail.com"
        "${username}@outlook.com"
        "${username}@protonmail.com"
        "${username}@mail.com"
    )
    
    for pattern in "${common_patterns[@]}"; do
        emails=$(echo "$emails" | jq --arg email "$pattern" \
            '. += [{"email": $email, "source": "pattern", "verified": false}]')
    done
    
    echo "$emails"
}

# Extrair nomes reais
extract_real_names() {
    local profiles="$1"
    local names="[]"
    
    echo "$profiles" | jq -c '.[]' | while read -r profile; do
        local platform
        platform=$(echo "$profile" | jq -r '.platform')
        local name
        name=$(echo "$profile" | jq -r '.name // empty')
        
        if [[ -n "$name" ]] && [[ "$name" != "null" ]]; then
            names=$(echo "$names" | jq --arg name "$name" --arg platform "$platform" \
                '. += [{"name": $name, "source": $platform}]')
        fi
    done
    
    echo "$names"
}

# Extrair localizações
extract_locations() {
    local profiles="$1"
    local locations="[]"
    
    echo "$profiles" | jq -c '.[]' | while read -r profile; do
        local platform
        platform=$(echo "$profile" | jq -r '.platform')
        local location
        location=$(echo "$profile" | jq -r '.location // empty')
        
        if [[ -n "$location" ]] && [[ "$location" != "null" ]]; then
            locations=$(echo "$locations" | jq --arg loc "$location" --arg platform "$platform" \
                '. += [{"location": $loc, "source": $platform}]')
        fi
    done
    
    echo "$locations"
}

# Extrair bios
extract_bios() {
    local profiles="$1"
    local bios="[]"
    
    echo "$profiles" | jq -c '.[]' | while read -r profile; do
        local platform
        platform=$(echo "$profile" | jq -r '.platform')
        local bio
        bio=$(echo "$profile" | jq -r '.bio // empty')
        
        if [[ -n "$bio" ]] && [[ "$bio" != "null" ]]; then
            bios=$(echo "$bios" | jq --arg bio "$bio" --arg platform "$platform" \
                '. += [{"bio": $bio, "source": $platform}]')
        fi
        
        local headline
        headline=$(echo "$profile" | jq -r '.headline // empty')
        if [[ -n "$headline" ]] && [[ "$headline" != "null" ]]; then
            bios=$(echo "$bios" | jq --arg bio "$headline" --arg platform "$platform" \
                '. += [{"bio": $bio, "source": $platform, "type": "headline"}]')
        fi
    done
    
    echo "$bios"
}

# Extrair URLs de perfis
extract_urls_from_profiles() {
    local profiles="$1"
    local urls="[]"
    
    echo "$profiles" | jq -c '.[]' | while read -r profile; do
        local platform
        platform=$(echo "$profile" | jq -r '.platform')
        
        # URL do perfil
        local profile_url
        profile_url=$(echo "$profile" | jq -r '.url // empty')
        if [[ -n "$profile_url" ]] && [[ "$profile_url" != "null" ]]; then
            urls=$(echo "$urls" | jq --arg url "$profile_url" --arg platform "$platform" \
                '. += [{"url": $url, "type": "profile", "source": $platform}]')
        fi
        
        # Blog/website
        local blog
        blog=$(echo "$profile" | jq -r '.blog // .website // empty')
        if [[ -n "$blog" ]] && [[ "$blog" != "null" ]]; then
            urls=$(echo "$urls" | jq --arg url "$blog" --arg platform "$platform" \
                '. += [{"url": $url, "type": "personal", "source": $platform}]')
        fi
        
        # Social links
        local twitter
        twitter=$(echo "$profile" | jq -r '.twitter // empty')
        if [[ -n "$twitter" ]] && [[ "$twitter" != "null" ]]; then
            urls=$(echo "$urls" | jq --arg url "https://twitter.com/$twitter" --arg platform "$platform" \
                '. += [{"url": $url, "type": "twitter", "source": $platform}]')
        fi
    done
    
    # Remover duplicatas
    echo "$urls" | jq 'unique_by(.url)'
}

# Extrair imagens de perfil
extract_profile_images() {
    local profiles="$1"
    local images="[]"
    
    echo "$profiles" | jq -c '.[]' | while read -r profile; do
        local platform
        platform=$(echo "$profile" | jq -r '.platform')
        local avatar
        avatar=$(echo "$profile" | jq -r '.avatar // .avatar_url // .icon_img // .profile_pic_url // empty')
        
        if [[ -n "$avatar" ]] && [[ "$avatar" != "null" ]]; then
            images=$(echo "$images" | jq --arg url "$avatar" --arg platform "$platform" \
                '. += [{"url": $url, "platform": $platform}]')
        fi
    done
    
    echo "$images"
}

# Analisar conteúdo recente
analyze_recent_content() {
    local username="$1"
    local profiles="$2"
    local content="[]"
    
    # GitHub (commits recentes)
    if echo "$profiles" | jq -e '.[] | select(.platform == "github")' > /dev/null; then
        if [[ -n "$GITHUB_API_KEY" ]]; then
            local events_url="https://api.github.com/users/${username}/events"
            local events
            events=$(curl -s -H "Authorization: token ${GITHUB_API_KEY}" "$events_url" 2>/dev/null)
            
            if [[ -n "$events" ]] && [[ "$events" != "[]" ]]; then
                local recent
                recent=$(echo "$events" | jq '[.[] | select(.type | contains("PushEvent")) | .payload.commits[]? | {message: .message, repo: .repo.name, date: .created_at}] | .[0:5]' 2>/dev/null)
                content=$(echo "$content" | jq --argjson github "$recent" '. += [{"platform": "github", "items": $github}]')
            fi
        fi
    fi
    
    # Twitter (tweets recentes) - se tiver API
    if [[ -n "$TWITTER_BEARER_TOKEN" ]] && echo "$profiles" | jq -e '.[] | select(.platform == "twitter")' > /dev/null; then
        local twitter_url="https://api.twitter.com/2/users/by/username/${username}?user.fields=description,public_metrics"
        local user_info
        user_info=$(curl -s -H "Authorization: Bearer ${TWITTER_BEARER_TOKEN}" "$twitter_url" 2>/dev/null)
        
        if [[ -n "$user_info" ]] && [[ "$(echo "$user_info" | jq -r '.errors')" == "null" ]]; then
            local user_id
            user_id=$(echo "$user_info" | jq -r '.data.id')
            
            local tweets_url="https://api.twitter.com/2/users/${user_id}/tweets?max_results=5&tweet.fields=created_at"
            local tweets
            tweets=$(curl -s -H "Authorization: Bearer ${TWITTER_BEARER_TOKEN}" "$tweets_url" 2>/dev/null)
            
            if [[ -n "$tweets" ]]; then
                local recent_tweets
                recent_tweets=$(echo "$tweets" | jq '[.data[]? | {text: .text, date: .created_at}]')
                content=$(echo "$content" | jq --argjson twitter "$recent_tweets" '. += [{"platform": "twitter", "items": $twitter}]')
            fi
        fi
    fi
    
    echo "$content"
}

# Verificar conexões
check_connections() {
    local profiles="$1"
    local connections="[]"
    
    echo "$profiles" | jq -c '.[]' | while read -r profile; do
        local platform
        platform=$(echo "$profile" | jq -r '.platform')
        
        case "$platform" in
            "github")
                local followers
                followers=$(echo "$profile" | jq -r '.followers // 0')
                local following
                following=$(echo "$profile" | jq -r '.following // 0')
                
                connections=$(echo "$connections" | jq \
                    --arg platform "$platform" \
                    --argjson followers "$followers" \
                    --argjson following "$following" \
                    '. += [{
                        "platform": $platform,
                        "followers": $followers,
                        "following": $following
                    }]')
                ;;
                
            "instagram")
                local followers
                followers=$(echo "$profile" | jq -r '.followers // 0')
                local following
                following=$(echo "$profile" | jq -r '.following // 0')
                
                connections=$(echo "$connections" | jq \
                    --arg platform "$platform" \
                    --argjson followers "$followers" \
                    --argjson following "$following" \
                    '. += [{
                        "platform": $platform,
                        "followers": $followers,
                        "following": $following
                    }]')
                ;;
                
            "reddit")
                local link_karma
                link_karma=$(echo "$profile" | jq -r '.link_karma // 0')
                local comment_karma
                comment_karma=$(echo "$profile" | jq -r '.comment_karma // 0')
                
                connections=$(echo "$connections" | jq \
                    --arg platform "$platform" \
                    --argjson link "$link_karma" \
                    --argjson comment "$comment_karma" \
                    '. += [{
                        "platform": $platform,
                        "link_karma": $link,
                        "comment_karma": $comment
                    }]')
                ;;
        esac
    done
    
    echo "$connections"
}

# Buscar username em mecanismos de busca
search_username() {
    local username="$1"
    local results="[]"
    
    local search_engines=(
        "https://www.google.com/search?q=%22%s%22"
        "https://www.bing.com/search?q=%22%s%22"
        "https://duckduckgo.com/?q=%22%s%22"
        "https://www.baidu.com/s?wd=%22%s%22"
        "https://yandex.com/search/?text=%22%s%22"
    )
    
    for engine in "${search_engines[@]}"; do
        local url
        url=$(printf "$engine" "$username")
        
        local response
        response=$(curl -s -A "Mozilla/5.0" -L --max-time 5 "$url" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            # Extrair número aproximado de resultados
            local result_count=0
            
            if [[ "$engine" == *"google"* ]]; then
                result_count=$(echo "$response" | grep -o 'About [0-9,]* results' | head -1 | grep -o '[0-9,]*' | sed 's/,//g')
            elif [[ "$engine" == *"bing"* ]]; then
                result_count=$(echo "$response" | grep -o '[0-9,]* results' | head -1 | grep -o '[0-9,]*' | sed 's/,//g')
            fi
            
            results=$(echo "$results" | jq --arg engine "$(echo "$engine" | cut -d'/' -f3)" --argjson count "${result_count:-0}" \
                '. += [{"engine": $engine, "url": $url, "result_count": $count}]')
        fi
    done
    
    echo "$results"
}

# Verificar internet archives
check_internet_archives() {
    local username="$1"
    local profiles="$2"
    local archives="[]"
    
    # Wayback Machine para cada perfil
    echo "$profiles" | jq -c '.[]' | while read -r profile; do
        local platform
        platform=$(echo "$profile" | jq -r '.platform')
        local profile_url
        profile_url=$(echo "$profile" | jq -r '.url')
        
        local wayback_url="http://archive.org/wayback/available?url=${profile_url}"
        local response
        response=$(curl -s "$wayback_url" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            local archived
            archived=$(echo "$response" | jq -r '.archived_snapshots.closest | {available: .available, url: .url, timestamp: .timestamp}')
            
            if [[ "$archived" != "null" ]]; then
                archives=$(echo "$archives" | jq --arg platform "$platform" --argjson data "$archived" \
                    '. += [{"platform": $platform, "archive": $data}]')
            fi
        fi
    done
    
    echo "$archives"
}

# Gerar timeline
generate_timeline() {
    local profiles="$1"
    local content="$2"
    local timeline="[]"
    
    # Datas de criação de perfis
    echo "$profiles" | jq -c '.[]' | while read -r profile; do
        local platform
        platform=$(echo "$profile" | jq -r '.platform')
        local created_at
        created_at=$(echo "$profile" | jq -r '.created_at // .created_utc // empty')
        
        if [[ -n "$created_at" ]] && [[ "$created_at" != "null" ]]; then
            # Converter formato se necessário
            if [[ "$created_at" =~ ^[0-9]+$ ]]; then
                # Unix timestamp
                created_at=$(date -d "@$created_at" +"%Y-%m-%d" 2>/dev/null || date -r "$created_at" +"%Y-%m-%d" 2>/dev/null)
            fi
            
            timeline=$(echo "$timeline" | jq --arg date "$created_at" --arg platform "$platform" --arg type "profile_created" \
                '. += [{"date": $date, "platform": $platform, "event": $type}]')
        fi
    done
    
    # Conteúdo recente
    echo "$content" | jq -c '.[]' | while read -r platform_content; do
        local platform
        platform=$(echo "$platform_content" | jq -r '.platform')
        
        echo "$platform_content" | jq -c '.items[]?' | while read -r item; do
            local date
            date=$(echo "$item" | jq -r '.date // .created_at // empty')
            local text
            text=$(echo "$item" | jq -r '.message // .text // empty')
            
            if [[ -n "$date" ]] && [[ -n "$text" ]]; then
                timeline=$(echo "$timeline" | jq --arg date "$date" --arg platform "$platform" --arg text "$text" \
                    '. += [{"date": $date, "platform": $platform, "event": "content", "content": $text}]')
            fi
        done
    done
    
    # Ordenar por data
    echo "$timeline" | jq 'sort_by(.date)'
}

# Análise de sentimentos
analyze_sentiment() {
    local content="$1"
    local result="{}"
    
    local positive_words=("good" "great" "excellent" "amazing" "love" "happy" "awesome" "fantastic" "wonderful" "best")
    local negative_words=("bad" "terrible" "awful" "hate" "angry" "sad" "worst" "horrible" "disappointing" "poor")
    
    local total_score=0
    local total_items=0
    
    echo "$content" | jq -c '.[]' | while read -r platform_content; do
        echo "$platform_content" | jq -c '.items[]?' | while read -r item; do
            local text
            text=$(echo "$item" | jq -r '.message // .text // ""' | tr '[:upper:]' '[:lower:]')
            
            if [[ -n "$text" ]]; then
                local score=0
                
                # Palavras positivas
                for word in "${positive_words[@]}"; do
                    if [[ "$text" == *"$word"* ]]; then
                        score=$((score + 1))
                    fi
                done
                
                # Palavras negativas
                for word in "${negative_words[@]}"; do
                    if [[ "$text" == *"$word"* ]]; then
                        score=$((score - 1))
                    fi
                done
                
                total_score=$((total_score + score))
                total_items=$((total_items + 1))
            fi
        done
    done
    
    if [[ $total_items -gt 0 ]]; then
        local avg_score=$((total_score * 10 / total_items))
        
        if [[ $avg_score -gt 5 ]]; then
            local sentiment="positive"
        elif [[ $avg_score -lt -5 ]]; then
            sentiment="negative"
            avg_score=$((avg_score * -1))
        else
            sentiment="neutral"
        fi
        
        result=$(echo "$result" | jq \
            --arg sent "$sentiment" \
            --argjson score "$avg_score" \
            '{
                sentiment: $sent,
                score: $score,
                samples_analyzed: $total_items
            }')
    fi
    
    echo "$result"
}

# Verificar similaridade entre perfis
check_profile_similarity() {
    local profiles="$1"
    local result="[]"
    
    local platforms
    platforms=$(echo "$profiles" | jq -r '.[].platform')
    
    for p1 in $platforms; do
        for p2 in $platforms; do
            if [[ "$p1" < "$p2" ]]; then
                local profile1
                profile1=$(echo "$profiles" | jq -c ".[] | select(.platform == \"$p1\")")
                local profile2
                profile2=$(echo "$profiles" | jq -c ".[] | select(.platform == \"$p2\")")
                
                local similarity_score=0
                local factors=0
                
                # Comparar nome
                local name1
                name1=$(echo "$profile1" | jq -r '.name // empty')
                local name2
                name2=$(echo "$profile2" | jq -r '.name // empty')
                
                if [[ -n "$name1" ]] && [[ -n "$name2" ]] && [[ "$name1" == "$name2" ]]; then
                    similarity_score=$((similarity_score + 30))
                    factors=$((factors + 1))
                fi
                
                # Comparar bio
                local bio1
                bio1=$(echo "$profile1" | jq -r '.bio // empty')
                local bio2
                bio2=$(echo "$profile2" | jq -r '.bio // empty')
                
                if [[ -n "$bio1" ]] && [[ -n "$bio2" ]] && [[ "$bio1" == "$bio2" ]]; then
                    similarity_score=$((similarity_score + 20))
                    factors=$((factors + 1))
                fi
                
                # Comparar localização
                local loc1
                loc1=$(echo "$profile1" | jq -r '.location // empty')
                local loc2
                loc2=$(echo "$profile2" | jq -r '.location // empty')
                
                if [[ -n "$loc1" ]] && [[ -n "$loc2" ]] && [[ "$loc1" == "$loc2" ]]; then
                    similarity_score=$((similarity_score + 20))
                    factors=$((factors + 1))
                fi
                
                # Comparar avatar (hash da imagem)
                local avatar1
                avatar1=$(echo "$profile1" | jq -r '.avatar // .avatar_url // empty')
                local avatar2
                avatar2=$(echo "$profile2" | jq -r '.avatar // .avatar_url // empty')
                
                if [[ -n "$avatar1" ]] && [[ -n "$avatar2" ]] && [[ "$avatar1" == "$avatar2" ]]; then
                    similarity_score=$((similarity_score + 30))
                    factors=$((factors + 1))
                fi
                
                if [[ $factors -gt 0 ]]; then
                    similarity_score=$((similarity_score / factors))
                    
                    result=$(echo "$result" | jq \
                        --arg p1 "$p1" \
                        --arg p2 "$p2" \
                        --argjson score "$similarity_score" \
                        '. += [{
                            "profile1": $p1,
                            "profile2": $p2,
                            "similarity_score": $score
                        }]')
                fi
            fi
        done
    done
    
    echo "$result"
}

# Exportar funções
export -f init_social_media social_media_intel