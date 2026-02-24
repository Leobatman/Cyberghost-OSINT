#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Metadata Extractor Module
# =============================================================================

MODULE_NAME="Metadata Extractor"
MODULE_DESC="Extract and analyze metadata from files"
MODULE_VERSION="1.0.0"
MODULE_AUTHOR="CyberGhost"

# Tipos de arquivo suportados
declare -A FILE_TYPES=(
    ["pdf"]="application/pdf"
    ["doc"]="application/msword"
    ["docx"]="application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    ["xls"]="application/vnd.ms-excel"
    ["xlsx"]="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    ["ppt"]="application/vnd.ms-powerpoint"
    ["pptx"]="application/vnd.openxmlformats-officedocument.presentationml.presentation"
    ["jpg"]="image/jpeg"
    ["jpeg"]="image/jpeg"
    ["png"]="image/png"
    ["gif"]="image/gif"
    ["tiff"]="image/tiff"
    ["bmp"]="image/bmp"
    ["mp3"]="audio/mpeg"
    ["mp4"]="video/mp4"
    ["avi"]="video/x-msvideo"
    ["mov"]="video/quicktime"
    ["zip"]="application/zip"
    ["tar"]="application/x-tar"
    ["gz"]="application/gzip"
)

# Ferramentas de extração
EXIFTOOL_CMD="exiftool"
PDFINFO_CMD="pdfinfo"
EXIV2_CMD="exiv2"
IDENTIFY_CMD="identify"
FFPROBE_CMD="ffprobe"

# Inicializar módulo
init_metadata_extractor() {
    log "INFO" "Initializing Metadata Extractor module" "METADATA"
    
    # Verificar dependências
    local deps=("curl" "file" "strings")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    # Verificar ferramentas opcionais
    if ! command -v "$EXIFTOOL_CMD" &> /dev/null; then
        log "WARNING" "exiftool not found. Some features will be limited" "METADATA"
    fi
    
    if ! command -v "$PDFINFO_CMD" &> /dev/null; then
        log "WARNING" "pdfinfo not found. PDF metadata extraction limited" "METADATA"
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing required dependencies: ${missing[*]}" "METADATA"
        return 1
    fi
    
    return 0
}

# Função principal
extract_metadata() {
    local target="$1"
    local output_dir="$2"
    
    log "INTEL" "Starting metadata extraction for: $target" "METADATA"
    
    local start_time
    start_time=$(date +%s)
    
    local results_dir="${output_dir}/metadata"
    mkdir -p "$results_dir" "$TEMP_DIR/metadata"
    
    local results="{}"
    
    results=$(echo "$results" | jq --arg target "$target" '.target = $target')
    
    # Se for URL, baixar arquivos primeiro
    if validate_url "$target"; then
        log "INFO" "Target is URL, downloading files" "METADATA"
        local downloaded_files
        downloaded_files=$(download_files_from_url "$target")
        results=$(echo "$results" | jq --argjson files "$downloaded_files" '.downloaded_files = $files')
        
        # Processar cada arquivo baixado
        local file_results="[]"
        
        echo "$downloaded_files" | jq -c '.[]' | while read -r file_info; do
            local file_path
            file_path=$(echo "$file_info" | jq -r '.path')
            
            if [[ -f "$file_path" ]]; then
                log "INFO" "Extracting metadata from: $file_path" "METADATA"
                local file_metadata
                file_metadata=$(extract_file_metadata "$file_path")
                
                file_results=$(echo "$file_results" | jq --argjson meta "$file_metadata" '. += [$meta]')
            fi
        done
        
        results=$(echo "$results" | jq --argjson files "$file_results" '.files = $files')
    else
        # Se for arquivo local
        if [[ -f "$target" ]]; then
            log "INFO" "Processing local file: $target" "METADATA"
            local file_metadata
            file_metadata=$(extract_file_metadata "$target")
            results=$(echo "$results" | jq --argjson file "$file_metadata" '.file = $file')
        elif [[ -d "$target" ]]; then
            # Se for diretório, processar todos os arquivos
            log "INFO" "Processing directory: $target" "METADATA"
            local dir_results="[]"
            
            find "$target" -type f | while read -r file; do
                log "DEBUG" "Processing file: $file" "METADATA"
                local file_metadata
                file_metadata=$(extract_file_metadata "$file")
                dir_results=$(echo "$dir_results" | jq --argjson meta "$file_metadata" '. += [$meta]')
            done
            
            results=$(echo "$results" | jq --argjson files "$dir_results" '.directory_files = $files')
        fi
    fi
    
    # Análise consolidada
    log "INFO" "Performing consolidated analysis" "METADATA"
    local analysis
    analysis=$(analyze_metadata_results "$results")
    results=$(echo "$results" | jq --argjson analysis "$analysis" '.analysis = $analysis')
    
    # Extrair informações de geolocalização
    log "INFO" "Extracting geolocation data" "METADATA"
    local geo_data
    geo_data=$(extract_geolocation "$results")
    results=$(echo "$results" | jq --argjson geo "$geo_data" '.geolocation = $geo')
    
    # Extrair informações de autoria
    log "INFO" "Extracting authorship information" "METADATA"
    local authors
    authors=$(extract_authorship "$results")
    results=$(echo "$results" | jq --argjson authors "$authors" '.authorship = $authors')
    
    # Extrair timestamps
    log "INFO" "Extracting timestamps" "METADATA"
    local timestamps
    timestamps=$(extract_timestamps "$results")
    results=$(echo "$results" | jq --argjson times "$timestamps" '.timestamps = $times')
    
    # Extrair software usado
    log "INFO" "Extracting software information" "METADATA"
    local software
    software=$(extract_software "$results")
    results=$(echo "$results" | jq --argjson sw "$software" '.software = $sw')
    
    # Gerar relatório final
    log "INFO" "Generating final report" "METADATA"
    local report
    report=$(generate_metadata_report "$results")
    results=$(echo "$results" | jq --argjson report "$report" '.report = $report')
    
    # Salvar resultados
    echo "$results" | jq '.' > "${results_dir}/metadata.json"
    
    # Salvar metadados brutos em formato legível
    echo "$results" | jq -r '.files[]?.metadata_raw' 2>/dev/null > "${results_dir}/metadata_raw.txt"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local file_count
    file_count=$(echo "$results" | jq '[.files[]?, .file?, .directory_files[]?] | length')
    
    log "SUCCESS" "Metadata extraction completed in ${duration}s - Processed $file_count files" "METADATA"
    
    echo "$results"
}

# Baixar arquivos de URL
download_files_from_url() {
    local url="$1"
    local results="[]"
    
    # Obter HTML da página
    local html
    html=$(curl -s -L -A "Mozilla/5.0" "$url" 2>/dev/null)
    
    if [[ -z "$html" ]]; then
        echo "[]"
        return
    fi
    
    # Extrair links de arquivos
    local file_links
    file_links=$(echo "$html" | grep -oE 'href="[^"]+\.(pdf|doc|docx|xls|xlsx|ppt|pptx|jpg|jpeg|png|gif|mp3|mp4|zip|tar|gz)"' | sed 's/href="//' | sed 's/"$//')
    
    local count=0
    while IFS= read -r file_link; do
        if [[ -n "$file_link" ]] && [[ $count -lt 10 ]]; then  # Limitar a 10 arquivos
            # Resolver URL completa
            if [[ "$file_link" =~ ^http ]]; then
                local file_url="$file_link"
            else
                local base_url
                base_url=$(echo "$url" | grep -oE 'https?://[^/]+')
                local file_url="${base_url}${file_link}"
            fi
            
            # Extrair nome do arquivo
            local filename
            filename=$(basename "$file_link" | cut -d'?' -f1)
            
            if [[ -z "$filename" ]] || [[ "$filename" == *"/"* ]]; then
                filename="file_${count}.bin"
            fi
            
            local file_path="${TEMP_DIR}/metadata/${filename}"
            
            log "DEBUG" "Downloading: $file_url" "METADATA"
            
            # Baixar arquivo
            if curl -s -L -o "$file_path" --max-time 30 "$file_url" 2>/dev/null; then
                # Detectar tipo real do arquivo
                local file_type
                file_type=$(file -b --mime-type "$file_path" 2>/dev/null)
                
                results=$(echo "$results" | jq \
                    --arg url "$file_url" \
                    --arg path "$file_path" \
                    --arg name "$filename" \
                    --arg type "$file_type" \
                    '. += [{
                        "url": $url,
                        "path": $path,
                        "filename": $name,
                        "mime_type": $type
                    }]')
                
                ((count++))
            fi
        fi
    done <<< "$file_links"
    
    echo "$results"
}

# Extrair metadados de arquivo
extract_file_metadata() {
    local file_path="$1"
    local metadata="{}"
    
    # Informações básicas do arquivo
    local filename
    filename=$(basename "$file_path")
    local file_size
    file_size=$(stat -c%s "$file_path" 2>/dev/null || stat -f%z "$file_path" 2>/dev/null)
    local file_type
    file_type=$(file -b --mime-type "$file_path" 2>/dev/null)
    
    metadata=$(echo "$metadata" | jq \
        --arg name "$filename" \
        --argjson size "$file_size" \
        --arg type "$file_type" \
        '{
            filename: $name,
            size: $size,
            mime_type: $type,
            path: $file_path
        }')
    
    # Usar exiftool se disponível
    if command -v "$EXIFTOOL_CMD" &> /dev/null; then
        local exif_data
        exif_data=$("$EXIFTOOL_CMD" -json "$file_path" 2>/dev/null | jq '.[0]')
        
        if [[ -n "$exif_data" ]] && [[ "$exif_data" != "null" ]]; then
            metadata=$(echo "$metadata" | jq --argjson exif "$exif_data" '.exif = $exif')
            metadata=$(echo "$metadata" | jq --argjson raw "$exif_data" '.metadata_raw = $exif')
        fi
    fi
    
    # Extração específica por tipo
    case "$file_type" in
        application/pdf)
            metadata=$(extract_pdf_metadata "$file_path" "$metadata")
            ;;
        image/*)
            metadata=$(extract_image_metadata "$file_path" "$metadata")
            ;;
        video/*|audio/*)
            metadata=$(extract_media_metadata "$file_path" "$metadata")
            ;;
        application/msword|application/vnd.openxmlformats-officedocument.*)
            metadata=$(extract_office_metadata "$file_path" "$metadata")
            ;;
    esac
    
    # Extrair strings para informações adicionais
    local strings_data
    strings_data=$(strings -n 8 "$file_path" 2>/dev/null | grep -E '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}|https?://[^ ]+' | head -20)
    
    if [[ -n "$strings_data" ]]; then
        local emails
        emails=$(echo "$strings_data" | grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u | jq -R -s -c 'split("\n")[:-1]')
        
        local urls
        urls=$(echo "$strings_data" | grep -oE 'https?://[^ ]+' | sort -u | jq -R -s -c 'split("\n")[:-1]')
        
        metadata=$(echo "$metadata" | jq \
            --argjson emails "$emails" \
            --argjson urls "$urls" \
            '{
                embedded_emails: $emails,
                embedded_urls: $urls
            }')
    fi
    
    echo "$metadata"
}

# Extrair metadados de PDF
extract_pdf_metadata() {
    local file_path="$1"
    local metadata="$2"
    
    if command -v "$PDFINFO_CMD" &> /dev/null; then
        local pdf_info
        pdf_info=$("$PDFINFO_CMD" "$file_path" 2>/dev/null)
        
        if [[ -n "$pdf_info" ]]; then
            local title
            title=$(echo "$pdf_info" | grep "^Title:" | cut -d':' -f2- | sed 's/^ //')
            local author
            author=$(echo "$pdf_info" | grep "^Author:" | cut -d':' -f2- | sed 's/^ //')
            local creator
            creator=$(echo "$pdf_info" | grep "^Creator:" | cut -d':' -f2- | sed 's/^ //')
            local producer
            producer=$(echo "$pdf_info" | grep "^Producer:" | cut -d':' -f2- | sed 's/^ //')
            local pages
            pages=$(echo "$pdf_info" | grep "^Pages:" | awk '{print $2}')
            
            metadata=$(echo "$metadata" | jq \
                --arg title "$title" \
                --arg author "$author" \
                --arg creator "$creator" \
                --arg producer "$producer" \
                --argjson pages "$pages" \
                '.pdf = {
                    title: $title,
                    author: $author,
                    creator: $creator,
                    producer: $producer,
                    pages: $pages
                }')
        fi
    fi
    
    echo "$metadata"
}

# Extrair metadados de imagem
extract_image_metadata() {
    local file_path="$1"
    local metadata="$2"
    
    if command -v "$IDENTIFY_CMD" &> /dev/null; then
        local identify_info
        identify_info=$("$IDENTIFY_CMD" -verbose "$file_path" 2>/dev/null)
        
        if [[ -n "$identify_info" ]]; then
            local dimensions
            dimensions=$(echo "$identify_info" | grep "Geometry:" | awk '{print $2}')
            local colorspace
            colorspace=$(echo "$identify_info" | grep "Colorspace:" | awk '{print $2}')
            local depth
            depth=$(echo "$identify_info" | grep "Depth:" | awk '{print $2}')
            
            metadata=$(echo "$metadata" | jq \
                --arg dim "$dimensions" \
                --arg cs "$colorspace" \
                --arg depth "$depth" \
                '.image = {
                    dimensions: $dim,
                    colorspace: $cs,
                    depth: $depth
                }')
        fi
    fi
    
    # Extrair geolocalização de imagens
    if command -v "$EXIFTOOL_CMD" &> /dev/null; then
        local gps_data
        gps_data=$("$EXIFTOOL_CMD" -gps:all -json "$file_path" 2>/dev/null | jq '.[0]')
        
        if [[ -n "$gps_data" ]] && [[ "$gps_data" != "null" ]]; then
            local lat
            lat=$(echo "$gps_data" | jq -r '.GPSLatitude // empty')
            local lon
            lon=$(echo "$gps_data" | jq -r '.GPSLongitude // empty')
            
            if [[ -n "$lat" ]] && [[ -n "$lon" ]]; then
                metadata=$(echo "$metadata" | jq \
                    --arg lat "$lat" \
                    --arg lon "$lon" \
                    '.geolocation = {
                        latitude: $lat,
                        longitude: $lon
                    }')
            fi
        fi
    fi
    
    echo "$metadata"
}

# Extrair metadados de mídia
extract_media_metadata() {
    local file_path="$1"
    local metadata="$2"
    
    if command -v "$FFPROBE_CMD" &> /dev/null; then
        local ffprobe_data
        ffprobe_data=$("$FFPROBE_CMD" -v quiet -print_format json -show_format -show_streams "$file_path" 2>/dev/null)
        
        if [[ -n "$ffprobe_data" ]]; then
            local duration
            duration=$(echo "$ffprobe_data" | jq -r '.format.duration // empty')
            local bitrate
            bitrate=$(echo "$ffprobe_data" | jq -r '.format.bit_rate // empty')
            local codec
            codec=$(echo "$ffprobe_data" | jq -r '.streams[0].codec_name // empty')
            
            metadata=$(echo "$metadata" | jq \
                --arg duration "$duration" \
                --arg bitrate "$bitrate" \
                --arg codec "$codec" \
                '.media = {
                    duration: $duration,
                    bitrate: $bitrate,
                    codec: $codec
                }')
        fi
    fi
    
    echo "$metadata"
}

# Extrair metadados de Office
extract_office_metadata() {
    local file_path="$1"
    local metadata="$2"
    
    # Para arquivos OOXML (docx, xlsx, pptx), são ZIP
    if [[ "$file_path" == *.docx ]] || [[ "$file_path" == *.xlsx ]] || [[ "$file_path" == *.pptx ]]; then
        local temp_dir="${TEMP_DIR}/office_$$"
        mkdir -p "$temp_dir"
        
        # Extrair arquivo ZIP
        unzip -q "$file_path" -d "$temp_dir" 2>/dev/null
        
        # Ler app.xml
        if [[ -f "${temp_dir}/docProps/app.xml" ]]; then
            local app_data
            app_data=$(cat "${temp_dir}/docProps/app.xml")
            
            local app_name
            app_name=$(echo "$app_data" | grep -o '<Application>[^<]*' | sed 's/<Application>//')
            local pages
            pages=$(echo "$app_data" | grep -o '<Pages>[0-9]*' | sed 's/<Pages>//')
            
            metadata=$(echo "$metadata" | jq \
                --arg app "$app_name" \
                --argjson pages "$pages" \
                '.office.application = $app | .office.pages = $pages')
        fi
        
        # Ler core.xml
        if [[ -f "${temp_dir}/docProps/core.xml" ]]; then
            local core_data
            core_data=$(cat "${temp_dir}/docProps/core.xml")
            
            local creator
            creator=$(echo "$core_data" | grep -o '<dc:creator>[^<]*' | sed 's/<dc:creator>//')
            local last_modified
            last_modified=$(echo "$core_data" | grep -o '<dcterms:modified>[^<]*' | sed 's/<dcterms:modified>//')
            
            metadata=$(echo "$metadata" | jq \
                --arg creator "$creator" \
                --arg modified "$last_modified" \
                '.office.creator = $creator | .office.last_modified = $modified')
        fi
        
        # Limpar
        rm -rf "$temp_dir"
    fi
    
    echo "$metadata"
}

# Analisar resultados de metadados
analyze_metadata_results() {
    local results="$1"
    local analysis="{}"
    
    # Estatísticas gerais
    local total_files
    total_files=$(echo "$results" | jq '[.files[]?, .file?, .directory_files[]?] | length')
    
    local total_size
    total_size=$(echo "$results" | jq '[.files[]?.size, .file?.size, .directory_files[]?.size] | add // 0')
    
    # Contar por tipo
    local types="{}"
    echo "$results" | jq -r '.files[]?.mime_type, .file?.mime_type, .directory_files[]?.mime_type' 2>/dev/null | while read -r mime; do
        if [[ -n "$mime" ]]; then
            local category
            category=$(echo "$mime" | cut -d'/' -f1)
            types=$(echo "$types" | jq --arg cat "$category" '.[$cat] += 1')
        fi
    done
    
    # Informações encontradas
    local has_geo=0
    local has_author=0
    local has_timestamps=0
    local has_software=0
    local has_emails=0
    local has_urls=0
    
    echo "$results" | jq -c '.files[]?, .file?, .directory_files[]?' 2>/dev/null | while read -r file; do
        if [[ "$(echo "$file" | jq -r '.geolocation // empty')" != "null" ]]; then
            has_geo=1
        fi
        if [[ "$(echo "$file" | jq -r '.pdf.author // .office.creator // .exif.Author // empty')" != "null" ]]; then
            has_author=1
        fi
        if [[ "$(echo "$file" | jq -r '.exif.CreateDate // .exif.ModifyDate // empty')" != "null" ]]; then
            has_timestamps=1
        fi
        if [[ "$(echo "$file" | jq -r '.pdf.creator // .pdf.producer // .office.application // empty')" != "null" ]]; then
            has_software=1
        fi
        if [[ "$(echo "$file" | jq -r '.embedded_emails // [] | length')" -gt 0 ]]; then
            has_emails=1
        fi
        if [[ "$(echo "$file" | jq -r '.embedded_urls // [] | length')" -gt 0 ]]; then
            has_urls=1
        fi
    done
    
    analysis=$(echo "$analysis" | jq \
        --argjson total "$total_files" \
        --argjson size "$total_size" \
        --argjson types "$types" \
        --argjson geo "$has_geo" \
        --argjson author "$has_author" \
        --argjson times "$has_timestamps" \
        --argjson sw "$has_software" \
        --argjson emails "$has_emails" \
        --argjson urls "$has_urls" \
        '{
            total_files: $total,
            total_size: $size,
            types: $types,
            findings: {
                geolocation: $geo,
                authorship: $author,
                timestamps: $times,
                software: $sw,
                emails: $emails,
                urls: $urls
            }
        }')
    
    echo "$analysis"
}

# Extrair geolocalização
extract_geolocation() {
    local results="$1"
    local geo_data="[]"
    
    echo "$results" | jq -c '.files[]?, .file?, .directory_files[]?' 2>/dev/null | while read -r file; do
        local lat
        lat=$(echo "$file" | jq -r '.geolocation.latitude // .exif.GPSLatitude // empty')
        local lon
        lon=$(echo "$file" | jq -r '.geolocation.longitude // .exif.GPSLongitude // empty')
        
        if [[ -n "$lat" ]] && [[ -n "$lon" ]]; then
            local filename
            filename=$(echo "$file" | jq -r '.filename')
            
            geo_data=$(echo "$geo_data" | jq \
                --arg file "$filename" \
                --arg lat "$lat" \
                --arg lon "$lon" \
                '. += [{
                    "file": $file,
                    "latitude": $lat,
                    "longitude": $lon
                }]')
        fi
    done
    
    echo "$geo_data"
}

# Extrair autoria
extract_authorship() {
    local results="$1"
    local authors="[]"
    
    echo "$results" | jq -c '.files[]?, .file?, .directory_files[]?' 2>/dev/null | while read -r file; do
        local author
        author=$(echo "$file" | jq -r '.pdf.author // .office.creator // .exif.Author // .exif.Artist // .exif.ByLine // empty')
        
        if [[ -n "$author" ]] && [[ "$author" != "null" ]]; then
            local filename
            filename=$(echo "$file" | jq -r '.filename')
            
            authors=$(echo "$authors" | jq \
                --arg file "$filename" \
                --arg author "$author" \
                '. += [{
                    "file": $file,
                    "author": $author
                }]')
        fi
    done
    
    echo "$authors"
}

# Extrair timestamps
extract_timestamps() {
    local results="$1"
    local timestamps="[]"
    
    echo "$results" | jq -c '.files[]?, .file?, .directory_files[]?' 2>/dev/null | while read -r file; do
        local created
        created=$(echo "$file" | jq -r '.exif.CreateDate // .exif.DateTimeOriginal // .pdf.creation_date // .office.created // empty')
        local modified
        modified=$(echo "$file" | jq -r '.exif.ModifyDate // .pdf.mod_date // .office.last_modified // empty')
        
        if [[ -n "$created" ]] || [[ -n "$modified" ]]; then
            local filename
            filename=$(echo "$file" | jq -r '.filename')
            
            timestamps=$(echo "$timestamps" | jq \
                --arg file "$filename" \
                --arg created "$created" \
                --arg modified "$modified" \
                '. += [{
                    "file": $file,
                    "created": $created,
                    "modified": $modified
                }]')
        fi
    done
    
    echo "$timestamps"
}

# Extrair software usado
extract_software() {
    local results="$1"
    local software="[]"
    
    echo "$results" | jq -c '.files[]?, .file?, .directory_files[]?' 2>/dev/null | while read -r file; do
        local creator
        creator=$(echo "$file" | jq -r '.pdf.creator // .pdf.producer // .office.application // .exif.Software // empty')
        
        if [[ -n "$creator" ]] && [[ "$creator" != "null" ]]; then
            local filename
            filename=$(echo "$file" | jq -r '.filename')
            
            software=$(echo "$software" | jq \
                --arg file "$filename" \
                --arg software "$creator" \
                '. += [{
                    "file": $file,
                    "software": $software
                }]')
        fi
    done
    
    echo "$software"
}

# Gerar relatório
generate_metadata_report() {
    local results="$1"
    local report="{}"
    
    # Resumo executivo
    local summary
    summary=$(echo "$results" | jq -r '.analysis // {}')
    
    # Arquivos com geolocalização
    local geo_files
    geo_files=$(echo "$results" | jq '.geolocation | length // 0')
    
    # Arquivos com autoria
    local author_files
    author_files=$(echo "$results" | jq '.authorship | length // 0')
    
    # Arquivos com timestamps
    local time_files
    time_files=$(echo "$results" | jq '.timestamps | length // 0')
    
    # Arquivos com software info
    local software_files
    software_files=$(echo "$results" | jq '.software | length // 0')
    
    report=$(echo "$report" | jq \
        --argjson summary "$summary" \
        --argjson geo "$geo_files" \
        --argjson author "$author_files" \
        --argjson time "$time_files" \
        --argjson sw "$software_files" \
        '{
            executive_summary: $summary,
            geolocation_count: $geo,
            authorship_count: $author,
            timestamp_count: $time,
            software_count: $sw
        }')
    
    echo "$report"
}

# Exportar funções
export -f init_metadata_extractor extract_metadata