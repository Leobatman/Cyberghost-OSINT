#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Report Generator
# =============================================================================

# Formatos suportados
REPORT_FORMATS=("html" "pdf" "json" "csv" "txt" "markdown" "xml")

# Templates
REPORT_TEMPLATES_DIR="${PROJECT_ROOT}/data/templates"
REPORT_OUTPUT_DIR="${REPORTS_DIR}"

# Gerar relatório
generate_report() {
    local scan_dir="$1"
    local target="$2"
    local format="${3:-${REPORT_FORMAT}}"
    
    log "INFO" "Generating report for $target in $format format" "REPORT"
    
    local report_file="${scan_dir}/report.${format}"
    
    case "$format" in
        html)
            generate_html_report "$scan_dir" "$target" "$report_file"
            ;;
        pdf)
            generate_pdf_report "$scan_dir" "$target" "$report_file"
            ;;
        json)
            generate_json_report "$scan_dir" "$target" "$report_file"
            ;;
        csv)
            generate_csv_report "$scan_dir" "$target" "$report_file"
            ;;
        txt)
            generate_txt_report "$scan_dir" "$target" "$report_file"
            ;;
        markdown)
            generate_markdown_report "$scan_dir" "$target" "$report_file"
            ;;
        xml)
            generate_xml_report "$scan_dir" "$target" "$report_file"
            ;;
        *)
            log "ERROR" "Unsupported format: $format" "REPORT"
            return 1
            ;;
    esac
    
    log "SUCCESS" "Report generated: $report_file" "REPORT"
    
    # Comprimir se configurado
    if [[ "${REPORT_COMPRESS:-false}" == "true" ]]; then
        gzip "$report_file"
        log "INFO" "Report compressed: ${report_file}.gz" "REPORT"
    fi
    
    # Criptografar se configurado
    if [[ "${REPORT_ENCRYPT:-false}" == "true" ]]; then
        encrypt_report "$report_file"
    fi
}

# Gerar relatório HTML
generate_html_report() {
    local scan_dir="$1"
    local target="$2"
    local output_file="$3"
    
    log "DEBUG" "Generating HTML report" "REPORT"
    
    local template="${REPORT_TEMPLATES_DIR}/report_template.html"
    local css="${REPORT_TEMPLATES_DIR}/style.css"
    
    # Usar template padrão se não existir
    if [[ ! -f "$template" ]]; then
        template=$(create_default_html_template)
    else
        template=$(cat "$template")
    fi
    
    # Coletar dados
    local scan_data
    scan_data=$(collect_scan_data "$scan_dir" "$target")
    
    # Substituir variáveis
    local report
    report=$(echo "$template" | sed \
        -e "s/{{TARGET}}/$target/g" \
        -e "s/{{DATE}}/$(date)/g" \
        -e "s/{{VERSION}}/$VERSION/g" \
        -e "s/{{AUTHOR}}/$AUTHOR/g" \
        -e "s/{{SCAN_DATA}}/$(echo "$scan_data" | jq -c .)/g" \
    )
    
    # Adicionar CSS inline
    if [[ -f "$css" ]]; then
        local css_content
        css_content=$(cat "$css")
        report=$(echo "$report" | sed "s/{{CSS}}/$css_content/g")
    fi
    
    echo "$report" > "$output_file"
    
    # Copiar assets
    if [[ -d "${REPORT_TEMPLATES_DIR}/assets" ]]; then
        cp -r "${REPORT_TEMPLATES_DIR}/assets" "$(dirname "$output_file")/"
    fi
}

# Gerar relatório PDF
generate_pdf_report() {
    local scan_dir="$1"
    local target="$2"
    local output_file="$3"
    
    log "DEBUG" "Generating PDF report" "REPORT"
    
    # Gerar HTML temporário
    local temp_html="${TEMP_DIR}/report_$$.html"
    generate_html_report "$scan_dir" "$target" "$temp_html"
    
    # Converter para PDF
    if command -v wkhtmltopdf &> /dev/null; then
        wkhtmltopdf --enable-local-file-access "$temp_html" "$output_file" 2>/dev/null
    elif command -v pandoc &> /dev/null; then
        pandoc "$temp_html" -o "$output_file"
    elif command -v prince &> /dev/null; then
        prince "$temp_html" -o "$output_file"
    else
        log "WARNING" "No PDF converter found, saving as HTML" "REPORT"
        cp "$temp_html" "${output_file%.pdf}.html"
    fi
    
    # Limpar
    rm -f "$temp_html"
}

# Gerar relatório JSON
generate_json_report() {
    local scan_dir="$1"
    local target="$2"
    local output_file="$3"
    
    log "DEBUG" "Generating JSON report" "REPORT"
    
    local scan_data
    scan_data=$(collect_scan_data "$scan_dir" "$target")
    
    # Adicionar metadados
    local report
    report=$(jq -n \
        --arg target "$target" \
        --arg date "$(date -Iseconds)" \
        --arg version "$VERSION" \
        --argjson data "$scan_data" \
        '{
            metadata: {
                target: $target,
                generated: $date,
                version: $version,
                tool: "CYBERGHOST OSINT"
            },
            data: $data
        }')
    
    echo "$report" | jq '.' > "$output_file"
}

# Gerar relatório CSV
generate_csv_report() {
    local scan_dir="$1"
    local target="$2"
    local output_file="$3"
    
    log "DEBUG" "Generating CSV report" "REPORT"
    
    # Cabeçalho
    echo "Module,Type,Value,Severity,Tags,Timestamp" > "$output_file"
    
    # Processar cada módulo
    for json_file in "$scan_dir"/modules/*.json; do
        if [[ -f "$json_file" ]]; then
            local module
            module=$(basename "$json_file" .json)
            
            # Extrair dados para CSV
            jq -r --arg module "$module" '
                if type == "object" then
                    paths(scalars) as $p |
                    [$module, ($p | join(".")), .[($p | join("."))], "", "", now] |
                    @csv
                elif type == "array" then
                    .[] | [$module, "item", ., "", "", now] | @csv
                else
                    [$module, "value", ., "", "", now] | @csv
                end
            ' "$json_file" >> "$output_file" 2>/dev/null
        fi
    done
}

# Gerar relatório TXT
generate_txt_report() {
    local scan_dir="$1"
    local target="$2"
    local output_file="$3"
    
    log "DEBUG" "Generating TXT report" "REPORT"
    
    {
        echo "========================================="
        echo "   CYBERGHOST OSINT ULTIMATE REPORT"
        echo "========================================="
        echo ""
        echo "Target: $target"
        echo "Generated: $(date)"
        echo "Version: $VERSION"
        echo "Author: $AUTHOR"
        echo ""
        echo "========================================="
        echo "SCAN SUMMARY"
        echo "========================================="
        echo ""
        
        # Listar módulos
        for json_file in "$scan_dir"/modules/*.json; do
            if [[ -f "$json_file" ]]; then
                local module
                module=$(basename "$json_file" .json | tr '[:lower:]' '[:upper:]')
                local count
                count=$(jq '. | length' "$json_file" 2>/dev/null || echo 0)
                
                echo "■ $module: $count findings"
            fi
        done
        
        echo ""
        echo "========================================="
        echo "DETAILED FINDINGS"
        echo "========================================="
        echo ""
        
        # Detalhes por módulo
        for json_file in "$scan_dir"/modules/*.json; do
            if [[ -f "$json_file" ]]; then
                local module
                module=$(basename "$json_file" .json | tr '[:lower:]' '[:upper:]')
                
                echo ""
                echo "▶ $module"
                echo "-----------------------------------------"
                
                # Formatar conteúdo
                jq -r '
                    if type == "object" then
                        to_entries[] | "  \(.key): \(.value)"
                    elif type == "array" then
                        .[] | "  - \(.)"
                    else
                        "  \(.)"
                    end
                ' "$json_file" 2>/dev/null | head -50
                
                if [[ $(jq '. | length' "$json_file" 2>/dev/null) -gt 50 ]]; then
                    echo "  ... and more"
                fi
                
                echo ""
            fi
        done
        
        echo ""
        echo "========================================="
        echo "END OF REPORT"
        echo "========================================="
        
    } > "$output_file"
}

# Gerar relatório Markdown
generate_markdown_report() {
    local scan_dir="$1"
    local target="$2"
    local output_file="$3"
    
    log "DEBUG" "Generating Markdown report" "REPORT"
    
    {
        echo "# CYBERGHOST OSINT Report"
        echo ""
        echo "## Target: $target"
        echo ""
        echo "| Metadata | |"
        echo "|----------|-|"
        echo "| Generated | $(date) |"
        echo "| Version | $VERSION |"
        echo "| Author | $AUTHOR |"
        echo ""
        echo "## Scan Summary"
        echo ""
        
        # Tabela de módulos
        echo "| Module | Findings |"
        echo "|--------|----------|"
        
        for json_file in "$scan_dir"/modules/*.json; do
            if [[ -f "$json_file" ]]; then
                local module
                module=$(basename "$json_file" .json | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
                local count
                count=$(jq '. | length' "$json_file" 2>/dev/null || echo 0)
                
                echo "| $module | $count |"
            fi
        done
        
        echo ""
        echo "## Detailed Findings"
        echo ""
        
        # Detalhes por módulo
        for json_file in "$scan_dir"/modules/*.json; do
            if [[ -f "$json_file" ]]; then
                local module
                module=$(basename "$json_file" .json | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
                
                echo "### $module"
                echo ""
                echo '```json'
                cat "$json_file"
                echo '```'
                echo ""
            fi
        done
        
    } > "$output_file"
}

# Gerar relatório XML
generate_xml_report() {
    local scan_dir="$1"
    local target="$2"
    local output_file="$3"
    
    log "DEBUG" "Generating XML report" "REPORT"
    
    {
        echo '<?xml version="1.0" encoding="UTF-8"?>'
        echo '<cyberghost-report>'
        echo "  <metadata>"
        echo "    <target>$target</target>"
        echo "    <generated>$(date -Iseconds)</generated>"
        echo "    <version>$VERSION</version>"
        echo "    <author>$AUTHOR</author>"
        echo "  </metadata>"
        echo "  <scan>"
        
        # Módulos
        for json_file in "$scan_dir"/modules/*.json; do
            if [[ -f "$json_file" ]]; then
                local module
                module=$(basename "$json_file" .json)
                
                echo "    <module name=\"$module\">"
                
                # Converter JSON para XML (simples)
                jq -r --arg module "$module" '
                    if type == "object" then
                        to_entries[] | 
                        "      <\(.key)>\(.value)</\(.key)>"
                    elif type == "array" then
                        .[] | 
                        "      <item>\(.)</item>"
                    else
                        "      <value>\(.)</value>"
                    end
                ' "$json_file" 2>/dev/null
                
                echo "    </module>"
            fi
        done
        
        echo "  </scan>"
        echo '</cyberghost-report>'
        
    } > "$output_file"
}

# Coletar dados do scan
collect_scan_data() {
    local scan_dir="$1"
    local target="$2"
    
    local data="{}"
    
    # Adicionar informações do scan
    data=$(echo "$data" | jq \
        --arg target "$target" \
        --arg start_time "$(cat "${scan_dir}/start_time" 2>/dev/null)" \
        --arg end_time "$(date -Iseconds)" \
        '. + {
            target: $target,
            start_time: $start_time,
            end_time: $end_time
        }')
    
    # Adicionar resultados dos módulos
    for json_file in "$scan_dir"/modules/*.json; do
        if [[ -f "$json_file" ]]; then
            local module
            module=$(basename "$json_file" .json)
            local content
            content=$(cat "$json_file")
            
            data=$(echo "$data" | jq --arg module "$module" --argjson content "$content" \
                '.modules[$module] = $content')
        fi
    done
    
    # Adicionar estatísticas
    local total_findings=0
    for json_file in "$scan_dir"/modules/*.json; do
        if [[ -f "$json_file" ]]; then
            local count
            count=$(jq '. | length' "$json_file" 2>/dev/null || echo 0)
            total_findings=$((total_findings + count))
        fi
    done
    
    data=$(echo "$data" | jq --argjson total "$total_findings" \
        '.statistics.total_findings = $total')
    
    echo "$data"
}

# Criptografar relatório
encrypt_report() {
    local report_file="$1"
    
    log "INFO" "Encrypting report: $report_file" "REPORT"
    
    local password="${REPORT_PASSWORD:-$(openssl rand -base64 32)}"
    local encrypted_file="${report_file}.enc"
    
    # Salvar senha em arquivo seguro
    echo "$password" > "${report_file}.key"
    chmod 600 "${report_file}.key"
    
    # Criptografar
    openssl enc -aes-256-cbc -salt -in "$report_file" -out "$encrypted_file" -pass pass:"$password"
    
    # Remover original
    rm -f "$report_file"
    
    log "INFO" "Report encrypted: $encrypted_file" "REPORT"
    log "INFO" "Encryption key: ${report_file}.key" "REPORT"
}

# Criar template HTML padrão
create_default_html_template() {
    cat << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CYBERGHOST OSINT Report - {{TARGET}}</title>
    <style>
        {{CSS}}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 CYBERGHOST OSINT ULTIMATE REPORT</h1>
            <h2>{{TARGET}}</h2>
            <div class="metadata">
                <p>Generated: {{DATE}}</p>
                <p>Version: {{VERSION}}</p>
                <p>Operator: {{AUTHOR}}</p>
            </div>
        </div>
        
        <div class="summary">
            <h3>📊 Scan Summary</h3>
            <div id="summary-stats"></div>
        </div>
        
        <div class="findings">
            <h3>🔎 Findings by Module</h3>
            <div id="modules-list"></div>
        </div>
        
        <div class="footer">
            <p>CYBERGHOST OSINT v{{VERSION}} | For authorized use only</p>
        </div>
    </div>
    
    <script>
        const scanData = {{SCAN_DATA}};
        
        // Render summary
        const summary = document.getElementById('summary-stats');
        summary.innerHTML = `
            <div class="stat-grid">
                <div class="stat-card">
                    <div class="stat-value">${scanData.statistics?.total_findings || 0}</div>
                    <div class="stat-label">Total Findings</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">${Object.keys(scanData.modules || {}).length}</div>
                    <div class="stat-label">Modules Run</div>
                </div>
            </div>
        `;
        
        // Render modules
        const modulesList = document.getElementById('modules-list');
        for (const [module, data] of Object.entries(scanData.modules || {})) {
            const moduleDiv = document.createElement('div');
            moduleDiv.className = 'module';
            moduleDiv.innerHTML = `
                <h4>${module.replace(/_/g, ' ').toUpperCase()}</h4>
                <pre>${JSON.stringify(data, null, 2)}</pre>
            `;
            modulesList.appendChild(moduleDiv);
        }
    </script>
</body>
</html>
EOF
}

# Exportar funções
export -f generate_report