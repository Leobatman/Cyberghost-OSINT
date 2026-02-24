#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - GitHub Intelligence Module
# =============================================================================

MODULE_NAME="GitHub Intelligence"
MODULE_DESC="Gather intelligence from GitHub repositories and users"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# GitHub API base
GITHUB_API="https://api.github.com"

# Inicializar módulo
init_github_intel() {
    log "INFO" "Initializing GitHub Intelligence module" "GITHUB"
    
    # Verificar dependências
    local deps=("curl" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing[*]}" "GITHUB"
        return 1
    fi
    
    return 0
}

# Função principal
github_intelligence() {
    local target="$1"
    local output_dir="$2"
    
    log "INTEL" "Starting GitHub intelligence for: $target" "GITHUB"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/github_intel"
    mkdir -p "$results_dir"
    
    local results="{}"
    
    # Determinar se é usuário ou organização
    local type
    type=$(determine_github_type "$target")
    results=$(echo "$results" | jq --arg type "$type" '.type = $type')
    
    # 1. Informações básicas do perfil
    log "INFO" "Fetching profile information" "GITHUB"
    local profile
    profile=$(get_github_profile "$target" "$type")
    results=$(echo "$results" | jq --argjson profile "$profile" '.profile = $profile')
    
    # 2. Repositórios
    log "INFO" "Fetching repositories" "GITHUB"
    local repos
    repos=$(get_github_repos "$target" "$type")
    results=$(echo "$results" | jq --argjson repos "$repos" '.repositories = $repos')
    
    # 3. Commits recentes
    log "INFO" "Fetching recent commits" "GITHUB"
    local commits
    commits=$(get_recent_commits "$target" "$repos")
    results=$(echo "$results" | jq --argjson commits "$commits" '.commits = $commits')
    
    # 4. Issues e Pull Requests
    log "INFO" "Fetching issues and PRs" "GITHUB"
    local issues
    issues=$(get_issues_prs "$target" "$repos")
    results=$(echo "$results" | jq --argjson issues "$issues" '.issues_prs = $issues')
    
    # 5. Gists
    log "INFO" "Fetching gists" "GITHUB"
    local gists
    gists=$(get_github_gists "$target")
    results=$(echo "$results" | jq --argjson gists "$gists" '.gists = $gists')
    
    # 6. Organizações (se for usuário)
    if [[ "$type" == "user" ]]; then
        log "INFO" "Fetching organizations" "GITHUB"
        local orgs
        orgs=$(get_user_orgs "$target")
        results=$(echo "$results" | jq --argjson orgs "$orgs" '.organizations = $orgs')
    fi
    
    # 7. Seguidores e seguindo
    log "INFO" "Fetching followers/following" "GITHUB"
    local social
    social=$(get_social_stats "$target")
    results=$(echo "$results" | jq --argjson social "$social" '.social = $social')
    
    # 8. Emails encontrados
    log "INFO" "Searching for emails" "GITHUB"
    local emails
    emails=$(find_github_emails "$target" "$repos" "$commits")
    results=$(echo "$results" | jq --argjson emails "$emails" '.emails = $emails')
    
    # 9. Chaves SSH e GPG
    log "INFO" "Fetching SSH and GPG keys" "GITHUB"
    local keys
    keys=$(get_user_keys "$target")
    results=$(echo "$results" | jq --argjson keys "$keys" '.keys = $keys')
    
    # 10. Tokens e segredos expostos
    log "INFO" "Searching for exposed secrets" "GITHUB"
    local secrets
    secrets=$(search_exposed_secrets "$target" "$repos")
    results=$(echo "$results" | jq --argjson secrets "$secrets" '.exposed_secrets = $secrets')
    
    # 11. Dependências e vulnerabilidades
    log "INFO" "Checking dependencies" "GITHUB"
    local deps
    deps=$(check_dependencies "$repos")
    results=$(echo "$results" | jq --argjson deps "$deps" '.dependencies = $deps')
    
    # 12. Contribuições
    log "INFO" "Analyzing contributions" "GITHUB"
    local contributions
    contributions=$(analyze_contributions "$target" "$repos")
    results=$(echo "$results" | jq --argjson contrib "$contributions" '.contributions = $contrib')
    
    # 13. Forks e stars
    log "INFO" "Analyzing forks and stars" "GITHUB"
    local popularity
    popularity=$(analyze_popularity "$repos")
    results=$(echo "$results" | jq --argjson pop "$popularity" '.popularity = $pop')
    
    # 14. Linguagens mais usadas
    log "INFO" "Analyzing languages" "GITHUB"
    local languages
    languages=$(analyze_languages "$repos")
    results=$(echo "$results" | jq --argjson langs "$languages" '.languages = $langs')
    
    # 15. Atividade ao longo do tempo
    log "INFO" "Analyzing activity timeline" "GITHUB"
    local timeline
    timeline=$(analyze_timeline "$repos" "$commits" "$issues")
    results=$(echo "$results" | jq --argjson timeline "$timeline" '.timeline = $timeline')
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/github_intel.json"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local repo_count
    repo_count=$(echo "$repos" | jq 'length')
    
    log "SUCCESS" "GitHub intelligence completed in ${duration}s - Found $repo_count repositories" "GITHUB"
    
    echo "$results"
}

# Determinar tipo (user ou org)
determine_github_type() {
    local target="$1"
    
    local url="${GITHUB_API}/users/${target}"
    local response
    response=$(github_api_request "$url")
    
    if [[ -n "$response" ]] && [[ "$response" != "null" ]]; then
        local type
        type=$(echo "$response" | jq -r '.type // "User"' | tr '[:upper:]' '[:lower:]')
        echo "$type"
    else
        # Tentar como organização
        local org_url="${GITHUB_API}/orgs/${target}"
        local org_response
        org_response=$(github_api_request "$org_url")
        
        if [[ -n "$org_response" ]] && [[ "$org_response" != "null" ]]; then
            echo "organization"
        else
            echo "unknown"
        fi
    fi
}

# Fazer requisição à API do GitHub
github_api_request() {
    local url="$1"
    
    local headers=()
    
    if [[ -n "$GITHUB_API_KEY" ]]; then
        headers+=("-H" "Authorization: token ${GITHUB_API_KEY}")
    fi
    
    headers+=("-H" "Accept: application/vnd.github.v3+json")
    headers+=("-H" "User-Agent: CYBERGHOST-OSINT")
    
    local response
    response=$(curl -s "${headers[@]}" "$url" 2>/dev/null)
    
    # Verificar rate limit
    if [[ "$response" == *"API rate limit exceeded"* ]]; then
        log "WARNING" "GitHub API rate limit exceeded" "GITHUB"
        return 1
    fi
    
    echo "$response"
}

# Obter perfil do GitHub
get_github_profile() {
    local target="$1"
    local type="$2"
    
    local url
    if [[ "$type" == "user" ]] || [[ "$type" == "User" ]]; then
        url="${GITHUB_API}/users/${target}"
    else
        url="${GITHUB_API}/orgs/${target}"
    fi
    
    local response
    response=$(github_api_request "$url")
    
    if [[ -z "$response" ]] || [[ "$response" == "null" ]]; then
        echo "{}"
        return
    fi
    
    # Extrair informações relevantes
    local profile
    profile=$(echo "$response" | jq '{
        login: .login,
        name: .name,
        company: .company,
        blog: .blog,
        location: .location,
        email: .email,
        bio: .bio,
        twitter: .twitter_username,
        public_repos: .public_repos,
        public_gists: .public_gists,
        followers: .followers,
        following: .following,
        created_at: .created_at,
        updated_at: .updated_at,
        avatar_url: .avatar_url,
        html_url: .html_url
    }')
    
    echo "$profile"
}

# Obter repositórios
get_github_repos() {
    local target="$1"
    local type="$2"
    
    local url
    if [[ "$type" == "user" ]] || [[ "$type" == "User" ]]; then
        url="${GITHUB_API}/users/${target}/repos?per_page=100&sort=updated"
    else
        url="${GITHUB_API}/orgs/${target}/repos?per_page=100&sort=updated"
    fi
    
    local response
    response=$(github_api_request "$url")
    
    if [[ -z "$response" ]] || [[ "$response" == "null" ]]; then
        echo "[]"
        return
    fi
    
    # Processar repositórios
    local repos
    repos=$(echo "$response" | jq '[.[] | {
        name: .name,
        full_name: .full_name,
        description: .description,
        fork: .fork,
        created_at: .created_at,
        updated_at: .updated_at,
        pushed_at: .pushed_at,
        homepage: .homepage,
        size: .size,
        stargazers_count: .stargazers_count,
        watchers_count: .watchers_count,
        forks_count: .forks_count,
        open_issues_count: .open_issues_count,
        language: .language,
        default_branch: .default_branch,
        visibility: .visibility,
        url: .html_url,
        has_issues: .has_issues,
        has_wiki: .has_wiki,
        has_pages: .has_pages,
        has_downloads: .has_downloads,
        archived: .archived,
        disabled: .disabled
    }]')
    
    echo "$repos"
}

# Obter commits recentes
get_recent_commits() {
    local target="$1"
    local repos="$2"
    local all_commits="[]"
    
    echo "$repos" | jq -c '.[]' | while read -r repo; do
        local repo_name
        repo_name=$(echo "$repo" | jq -r '.full_name')
        
        # Pegar últimos 10 commits do repositório
        local url="${GITHUB_API}/repos/${repo_name}/commits?per_page=10"
        local response
        response=$(github_api_request "$url")
        
        if [[ -n "$response" ]] && [[ "$response" != "null" ]]; then
            local commits
            commits=$(echo "$response" | jq --arg repo "$repo_name" '[.[] | {
                repo: $repo,
                sha: .sha[0:8],
                message: .commit.message,
                author: .commit.author.name,
                email: .commit.author.email,
                date: .commit.author.date,
                url: .html_url
            }]')
            
            all_commits=$(echo "$all_commits" | jq --argjson new "$commits" '. + $new')
        fi
        
        # Evitar rate limiting
        sleep 0.5
    done
    
    echo "$all_commits" | jq 'sort_by(.date) | reverse | .[0:100]'
}

# Obter issues e pull requests
get_issues_prs() {
    local target="$1"
    local repos="$2"
    local all_issues="[]"
    
    echo "$repos" | jq -c '.[]' | while read -r repo; do
        local repo_name
        repo_name=$(echo "$repo" | jq -r '.full_name')
        
        # Issues abertas
        local issues_url="${GITHUB_API}/repos/${repo_name}/issues?state=all&per_page=10"
        local response
        response=$(github_api_request "$issues_url")
        
        if [[ -n "$response" ]] && [[ "$response" != "null" ]]; then
            local issues
            issues=$(echo "$response" | jq --arg repo "$repo_name" '[.[] | {
                repo: $repo,
                number: .number,
                title: .title,
                state: .state,
                user: .user.login,
                created_at: .created_at,
                updated_at: .updated_at,
                comments: .comments,
                pull_request: .pull_request != null,
                url: .html_url
            }]')
            
            all_issues=$(echo "$all_issues" | jq --argjson new "$issues" '. + $new')
        fi
        
        sleep 0.5
    done
    
    echo "$all_issues" | jq 'sort_by(.created_at) | reverse | .[0:100]'
}

# Obter gists
get_github_gists() {
    local target="$1"
    
    local url="${GITHUB_API}/users/${target}/gists?per_page=100"
    local response
    response=$(github_api_request "$url")
    
    if [[ -z "$response" ]] || [[ "$response" == "null" ]]; then
        echo "[]"
        return
    fi
    
    local gists
    gists=$(echo "$response" | jq '[.[] | {
        id: .id,
        description: .description,
        public: .public,
        created_at: .created_at,
        updated_at: .updated_at,
        files: [.files | keys[]],
        url: .html_url
    }]')
    
    echo "$gists"
}

# Obter organizações do usuário
get_user_orgs() {
    local target="$1"
    
    local url="${GITHUB_API}/users/${target}/orgs"
    local response
    response=$(github_api_request "$url")
    
    if [[ -z "$response" ]] || [[ "$response" == "null" ]]; then
        echo "[]"
        return
    fi
    
    local orgs
    orgs=$(echo "$response" | jq '[.[] | {
        login: .login,
        description: .description,
        url: .html_url
    }]')
    
    echo "$orgs"
}

# Obter estatísticas sociais
get_social_stats() {
    local target="$1"
    local social="{}"
    
    # Seguidores
    local followers_url="${GITHUB_API}/users/${target}/followers?per_page=100"
    local followers_response
    followers_response=$(github_api_request "$followers_url")
    
    if [[ -n "$followers_response" ]] && [[ "$followers_response" != "null" ]]; then
        local followers
        followers=$(echo "$followers_response" | jq '[.[] | {login: .login, avatar: .avatar_url}]')
        social=$(echo "$social" | jq --argjson followers "$followers" '.followers = $followers')
    fi
    
    # Seguindo
    local following_url="${GITHUB_API}/users/${target}/following?per_page=100"
    local following_response
    following_response=$(github_api_request "$following_url")
    
    if [[ -n "$following_response" ]] && [[ "$following_response" != "null" ]]; then
        local following
        following=$(echo "$following_response" | jq '[.[] | {login: .login, avatar: .avatar_url}]')
        social=$(echo "$social" | jq --argjson following "$following" '.following = $following')
    fi
    
    echo "$social"
}

# Encontrar emails
find_github_emails() {
    local target="$1"
    local repos="$2"
    local commits="$3"
    local emails="[]"
    
    # Email do perfil
    local profile_url="${GITHUB_API}/users/${target}"
    local profile_response
    profile_response=$(github_api_request "$profile_url")
    
    if [[ -n "$profile_response" ]] && [[ "$profile_response" != "null" ]]; then
        local profile_email
        profile_email=$(echo "$profile_response" | jq -r '.email // empty')
        if [[ -n "$profile_email" ]] && [[ "$profile_email" != "null" ]]; then
            emails=$(echo "$emails" | jq --arg email "$profile_email" --arg source "profile" \
                '. += [{"email": $email, "source": $source, "verified": true}]')
        fi
    fi
    
    # Emails de commits
    echo "$commits" | jq -c '.[]' | while read -r commit; do
        local commit_email
        commit_email=$(echo "$commit" | jq -r '.email // empty')
        
        if [[ -n "$commit_email" ]] && [[ "$commit_email" != "null" ]]; then
            local repo
            repo=$(echo "$commit" | jq -r '.repo')
            
            # Verificar se já existe
            local exists
            exists=$(echo "$emails" | jq --arg email "$commit_email" 'any(.[]; .email == $email)')
            
            if [[ "$exists" == "false" ]]; then
                emails=$(echo "$emails" | jq --arg email "$commit_email" --arg repo "$repo" \
                    '. += [{"email": $email, "source": "commit", "repo": $repo, "verified": true}]')
            fi
        fi
    done
    
    # Buscar em issues e PRs
    local issues_url="${GITHUB_API}/search/issues?q=in:comment+${target}"
    local issues_response
    issues_response=$(github_api_request "$issues_url")
    
    if [[ -n "$issues_response" ]] && [[ "$issues_response" != "null" ]]; then
        local issue_emails
        issue_emails=$(echo "$issues_response" | jq -r '.items[].body' 2>/dev/null | grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u)
        
        while IFS= read -r email; do
            if [[ -n "$email" ]]; then
                emails=$(echo "$emails" | jq --arg email "$email" --arg source "issues" \
                    '. += [{"email": $email, "source": $source, "verified": false}]')
            fi
        done <<< "$issue_emails"
    fi
    
    echo "$emails"
}

# Obter chaves SSH e GPG
get_user_keys() {
    local target="$1"
    local keys="{}"
    
    # SSH keys
    local ssh_url="${GITHUB_API}/users/${target}/keys"
    local ssh_response
    ssh_response=$(github_api_request "$ssh_url")
    
    if [[ -n "$ssh_response" ]] && [[ "$ssh_response" != "null" ]]; then
        local ssh_keys
        ssh_keys=$(echo "$ssh_response" | jq '[.[] | {
            id: .id,
            key: .key[0:50] + "..."
        }]')
        keys=$(echo "$keys" | jq --argjson ssh "$ssh_keys" '.ssh = $ssh')
    fi
    
    # GPG keys
    local gpg_url="${GITHUB_API}/users/${target}/gpg_keys"
    local gpg_response
    gpg_response=$(github_api_request "$gpg_url")
    
    if [[ -n "$gpg_response" ]] && [[ "$gpg_response" != "null" ]]; then
        local gpg_keys
        gpg_keys=$(echo "$gpg_response" | jq '[.[] | {
            id: .id,
            key_id: .key_id,
            email: .emails[0].email,
            verified: .emails[0].verified
        }]')
        keys=$(echo "$keys" | jq --argjson gpg "$gpg_keys" '.gpg = $gpg')
    fi
    
    echo "$keys"
}

# Buscar segredos expostos
search_exposed_secrets() {
    local target="$1"
    local repos="$2"
    local secrets="[]"
    
    # Padrões de segredos
    local patterns=(
        "api[_-]?key"
        "secret"
        "token"
        "password"
        "aws[_-]?access"
        "azure[_-]?key"
        "gcp[_-]?key"
        "github[_-]?token"
        "slack[_-]?token"
        "discord[_-]?token"
        "telegram[_-]?token"
        "mongodb[_-]?uri"
        "mysql[_-]?password"
        "postgres[_-]?password"
        "redis[_-]?password"
        "private[_-]?key"
        "BEGIN RSA"
        "BEGIN DSA"
        "BEGIN EC"
        "BEGIN PGP"
    )
    
    echo "$repos" | jq -c '.[]' | while read -r repo; do
        local repo_name
        repo_name=$(echo "$repo" | jq -r '.full_name')
        local default_branch
        default_branch=$(echo "$repo" | jq -r '.default_branch // "main"')
        
        # Buscar em arquivos de configuração comuns
        local files=(".env" ".env.example" "config.js" "settings.py" "secrets.yml" "credentials.json")
        
        for file in "${files[@]}"; do
            local url="${GITHUB_API}/repos/${repo_name}/contents/${file}?ref=${default_branch}"
            local response
            response=$(github_api_request "$url" 2>/dev/null)
            
            if [[ -n "$response" ]] && [[ "$response" != "null" ]]; then
                # Verificar conteúdo (se for base64 encoded)
                local content
                content=$(echo "$response" | jq -r '.content // empty')
                
                if [[ -n "$content" ]] && [[ "$content" != "null" ]]; then
                    # Decodificar base64
                    local decoded
                    decoded=$(echo "$content" | base64 -d 2>/dev/null)
                    
                    # Procurar padrões
                    for pattern in "${patterns[@]}"; do
                        if echo "$decoded" | grep -qi "$pattern"; then
                            secrets=$(echo "$secrets" | jq \
                                --arg repo "$repo_name" \
                                --arg file "$file" \
                                --arg pattern "$pattern" \
                                '. += [{
                                    "repo": $repo,
                                    "file": $file,
                                    "pattern": $pattern,
                                    "risk": "high"
                                }]')
                            break
                        fi
                    done
                fi
            fi
        done
        
        sleep 0.5
    done
    
    echo "$secrets"
}

# Verificar dependências
check_dependencies() {
    local repos="$1"
    local deps="[]"
    
    echo "$repos" | jq -c '.[]' | while read -r repo; do
        local repo_name
        repo_name=$(echo "$repo" | jq -r '.full_name')
        local default_branch
        default_branch=$(echo "$repo" | jq -r '.default_branch // "main"')
        
        # package.json (Node.js)
        local package_url="${GITHUB_API}/repos/${repo_name}/contents/package.json?ref=${default_branch}"
        local package_response
        package_response=$(github_api_request "$package_url" 2>/dev/null)
        
        if [[ -n "$package_response" ]] && [[ "$package_response" != "null" ]]; then
            local content
            content=$(echo "$package_response" | jq -r '.content // empty')
            
            if [[ -n "$content" ]]; then
                local decoded
                decoded=$(echo "$content" | base64 -d 2>/dev/null)
                
                local packages
                packages=$(echo "$decoded" | jq -c '{dependencies: .dependencies, devDependencies: .devDependencies}' 2>/dev/null)
                
                if [[ -n "$packages" ]] && [[ "$packages" != "null" ]]; then
                    deps=$(echo "$deps" | jq --arg repo "$repo_name" --argjson pkgs "$packages" \
                        '. += [{"repo": $repo, "type": "npm", "packages": $pkgs}]')
                fi
            fi
        fi
        
        # requirements.txt (Python)
        local req_url="${GITHUB_API}/repos/${repo_name}/contents/requirements.txt?ref=${default_branch}"
        local req_response
        req_response=$(github_api_request "$req_url" 2>/dev/null)
        
        if [[ -n "$req_response" ]] && [[ "$req_response" != "null" ]]; then
            local content
            content=$(echo "$req_response" | jq -r '.content // empty')
            
            if [[ -n "$content" ]]; then
                local decoded
                decoded=$(echo "$content" | base64 -d 2>/dev/null)
                
                deps=$(echo "$deps" | jq --arg repo "$repo_name" --arg req "$decoded" \
                    '. += [{"repo": $repo, "type": "pip", "packages": $req}]')
            fi
        fi
        
        # go.mod (Go)
        local go_url="${GITHUB_API}/repos/${repo_name}/contents/go.mod?ref=${default_branch}"
        local go_response
        go_response=$(github_api_request "$go_url" 2>/dev/null)
        
        if [[ -n "$go_response" ]] && [[ "$go_response" != "null" ]]; then
            local content
            content=$(echo "$go_response" | jq -r '.content // empty')
            
            if [[ -n "$content" ]]; then
                local decoded
                decoded=$(echo "$content" | base64 -d 2>/dev/null)
                
                deps=$(echo "$deps" | jq --arg repo "$repo_name" --arg go "$decoded" \
                    '. += [{"repo": $repo, "type": "go", "packages": $go}]')
            fi
        fi
        
        sleep 0.5
    done
    
    echo "$deps"
}

# Analisar contribuições
analyze_contributions() {
    local target="$1"
    local repos="$2"
    local contrib="{}"
    
    # Total de commits
    local total_commits=0
    local repos_with_commits=0
    
    echo "$repos" | jq -c '.[]' | while read -r repo; do
        local repo_name
        repo_name=$(echo "$repo" | jq -r '.full_name')
        
        local url="${GITHUB_API}/repos/${repo_name}/contributors"
        local response
        response=$(github_api_request "$url" 2>/dev/null)
        
        if [[ -n "$response" ]] && [[ "$response" != "null" ]]; then
            local user_contrib
            user_contrib=$(echo "$response" | jq --arg target "$target" '.[] | select(.login == $target) | .contributions')
            
            if [[ -n "$user_contrib" ]] && [[ "$user_contrib" != "null" ]]; then
                total_commits=$((total_commits + user_contrib))
                repos_with_commits=$((repos_with_commits + 1))
            fi
        fi
        
        sleep 0.5
    done
    
    contrib=$(echo "$contrib" | jq \
        --argjson total "$total_commits" \
        --argjson repos "$repos_with_commits" \
        '{
            total_commits: $total,
            repositories_contributed: $repos
        }')
    
    echo "$contrib"
}

# Analisar popularidade
analyze_popularity() {
    local repos="$1"
    local pop="{}"
    
    local total_stars=0
    local total_forks=0
    local total_watchers=0
    local repo_count
    repo_count=$(echo "$repos" | jq 'length')
    
    echo "$repos" | jq -c '.[]' | while read -r repo; do
        local stars
        stars=$(echo "$repo" | jq -r '.stargazers_count // 0')
        local forks
        forks=$(echo "$repo" | jq -r '.forks_count // 0')
        local watchers
        watchers=$(echo "$repo" | jq -r '.watchers_count // 0')
        
        total_stars=$((total_stars + stars))
        total_forks=$((total_forks + forks))
        total_watchers=$((total_watchers + watchers))
    done
    
    pop=$(echo "$pop" | jq \
        --argjson stars "$total_stars" \
        --argjson forks "$total_forks" \
        --argjson watchers "$total_watchers" \
        --argjson repos "$repo_count" \
        '{
            total_stars: $stars,
            total_forks: $forks,
            total_watchers: $watchers,
            average_stars: ($stars / $repos),
            average_forks: ($forks / $repos)
        }')
    
    echo "$pop"
}

# Analisar linguagens
analyze_languages() {
    local repos="$1"
    local lang_stats="{}"
    
    echo "$repos" | jq -c '.[]' | while read -r repo; do
        local language
        language=$(echo "$repo" | jq -r '.language // "Unknown"')
        
        if [[ "$language" != "null" ]] && [[ -n "$language" ]]; then
            lang_stats=$(echo "$lang_stats" | jq --arg lang "$language" '.[$lang] += 1')
        fi
    done
    
    echo "$lang_stats"
}

# Analisar timeline
analyze_timeline() {
    local repos="$1"
    local commits="$2"
    local issues="$3"
    local timeline="[]"
    
    # Anos de atividade
    local years=()
    
    # Repositórios criados
    echo "$repos" | jq -c '.[]' | while read -r repo; do
        local created
        created=$(echo "$repo" | jq -r '.created_at' | cut -d'-' -f1)
        
        if [[ -n "$created" ]]; then
            years+=("$created")
        fi
    done
    
    # Commits
    echo "$commits" | jq -c '.[]' | while read -r commit; do
        local date
        date=$(echo "$commit" | jq -r '.date' | cut -d'-' -f1)
        
        if [[ -n "$date" ]]; then
            years+=("$date")
        fi
    done
    
    # Issues
    echo "$issues" | jq -c '.[]' | while read -r issue; do
        local created
        created=$(echo "$issue" | jq -r '.created_at' | cut -d'-' -f1)
        
        if [[ -n "$created" ]]; then
            years+=("$created")
        fi
    done
    
    # Contar por ano
    printf '%s\n' "${years[@]}" | sort -u | while read -r year; do
        if [[ -n "$year" ]]; then
            local count
            count=$(printf '%s\n' "${years[@]}" | grep -c "$year")
            
            timeline=$(echo "$timeline" | jq --arg year "$year" --argjson count "$count" \
                '. += [{"year": $year, "activity_count": $count}]')
        fi
    done
    
    echo "$timeline" | jq 'sort_by(.year)'
}

# Exportar funções
export -f init_github_intel github_intelligence