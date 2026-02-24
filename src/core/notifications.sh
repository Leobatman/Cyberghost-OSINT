#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Notification System
# =============================================================================

# Canais de notificação
NOTIFICATION_CHANNELS=("email" "slack" "discord" "telegram" "webhook" "pushover" "gotify")

# Configurações
NOTIFY_EMAIL="${NOTIFY_EMAIL:-}"
NOTIFY_SLACK_WEBHOOK="${NOTIFY_SLACK_WEBHOOK:-}"
NOTIFY_DISCORD_WEBHOOK="${NOTIFY_DISCORD_WEBHOOK:-}"
NOTIFY_TELEGRAM_BOT="${NOTIFY_TELEGRAM_BOT:-}"
NOTIFY_TELEGRAM_CHAT="${NOTIFY_TELEGRAM_CHAT:-}"
NOTIFY_WEBHOOK_URL="${NOTIFY_WEBHOOK_URL:-}"
NOTIFY_PUSHOVER_TOKEN="${NOTIFY_PUSHOVER_TOKEN:-}"
NOTIFY_PUSHOVER_USER="${NOTIFY_PUSHOVER_USER:-}"
NOTIFY_GOTIFY_URL="${NOTIFY_GOTIFY_URL:-}"
NOTIFY_GOTIFY_TOKEN="${NOTIFY_GOTIFY_TOKEN:-}"

# Enviar notificação
send_notification() {
    local level="$1"
    local message="$2"
    local module="${3:-GENERAL}"
    local data="${4:-{}}"
    
    log "DEBUG" "Sending notification: [$level] $message" "NOTIFY"
    
    # Formatar mensagem
    local formatted
    formatted=$(format_notification "$level" "$message" "$module" "$data")
    
    # Enviar para cada canal configurado
    local sent=0
    
    # Email
    if [[ -n "$NOTIFY_EMAIL" ]]; then
        send_email_notification "$level" "$message" "$formatted" && ((sent++))
    fi
    
    # Slack
    if [[ -n "$NOTIFY_SLACK_WEBHOOK" ]]; then
        send_slack_notification "$level" "$formatted" && ((sent++))
    fi
    
    # Discord
    if [[ -n "$NOTIFY_DISCORD_WEBHOOK" ]]; then
        send_discord_notification "$level" "$formatted" && ((sent++))
    fi
    
    # Telegram
    if [[ -n "$NOTIFY_TELEGRAM_BOT" ]] && [[ -n "$NOTIFY_TELEGRAM_CHAT" ]]; then
        send_telegram_notification "$formatted" && ((sent++))
    fi
    
    # Webhook
    if [[ -n "$NOTIFY_WEBHOOK_URL" ]]; then
        send_webhook_notification "$level" "$message" "$module" "$data" && ((sent++))
    fi
    
    # Pushover
    if [[ -n "$NOTIFY_PUSHOVER_TOKEN" ]] && [[ -n "$NOTIFY_PUSHOVER_USER" ]]; then
        send_pushover_notification "$level" "$message" && ((sent++))
    fi
    
    # Gotify
    if [[ -n "$NOTIFY_GOTIFY_URL" ]] && [[ -n "$NOTIFY_GOTIFY_TOKEN" ]]; then
        send_gotify_notification "$level" "$message" && ((sent++))
    fi
    
    if [[ $sent -gt 0 ]]; then
        log "DEBUG" "Notification sent via $sent channel(s)" "NOTIFY"
    fi
}

# Formatar notificação
format_notification() {
    local level="$1"
    local message="$2"
    local module="$3"
    local data="$4"
    
    local emoji
    case "$level" in
        "CRITICAL") emoji="🛑" ;;
        "ERROR") emoji="❌" ;;
        "WARNING") emoji="⚠️" ;;
        "SUCCESS") emoji="✅" ;;
        "INFO") emoji="ℹ️" ;;
        *) emoji="📝" ;;
    esac
    
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat << EOF
$emoji *CYBERGHOST OSINT Alert* $emoji

*Level:* $level
*Module:* $module
*Time:* $timestamp
*Message:* $message

$data
EOF
}

# Enviar email
send_email_notification() {
    local level="$1"
    local subject="$2"
    local body="$3"
    
    if ! command -v mail &> /dev/null; then
        log "WARNING" "mail command not found" "NOTIFY"
        return 1
    fi
    
    echo "$body" | mail -s "[CYBERGHOST] $level: $subject" "$NOTIFY_EMAIL"
    
    log "DEBUG" "Email notification sent to $NOTIFY_EMAIL" "NOTIFY"
    return 0
}

# Enviar Slack
send_slack_notification() {
    local level="$1"
    local message="$2"
    
    local color
    case "$level" in
        "CRITICAL") color="danger" ;;
        "ERROR") color="danger" ;;
        "WARNING") color="warning" ;;
        "SUCCESS") color="good" ;;
        *) color="#808080" ;;
    esac
    
    local payload
    payload=$(jq -n \
        --arg text "$message" \
        --arg color "$color" \
        '{
            attachments: [{
                color: $color,
                text: $text,
                mrkdwn_in: ["text"]
            }]
        }')
    
    curl -s -X POST -H "Content-Type: application/json" \
        -d "$payload" "$NOTIFY_SLACK_WEBHOOK" &>/dev/null
    
    log "DEBUG" "Slack notification sent" "NOTIFY"
    return 0
}

# Enviar Discord
send_discord_notification() {
    local level="$1"
    local message="$2"
    
    local color
    case "$level" in
        "CRITICAL") color=15158332 ;;
        "ERROR") color=15158332 ;;
        "WARNING") color=16776960 ;;
        "SUCCESS") color=3066993 ;;
        *) color=9807270 ;;
    esac
    
    local payload
    payload=$(jq -n \
        --arg description "$message" \
        --argjson color "$color" \
        '{
            embeds: [{
                title: "CYBERGHOST OSINT Alert",
                description: $description,
                color: $color,
                timestamp: (now | todate)
            }]
        }')
    
    curl -s -X POST -H "Content-Type: application/json" \
        -d "$payload" "$NOTIFY_DISCORD_WEBHOOK" &>/dev/null
    
    log "DEBUG" "Discord notification sent" "NOTIFY"
    return 0
}

# Enviar Telegram
send_telegram_notification() {
    local message="$1"
    
    local url="https://api.telegram.org/bot${NOTIFY_TELEGRAM_BOT}/sendMessage"
    
    curl -s -X POST "$url" \
        -d "chat_id=${NOTIFY_TELEGRAM_CHAT}" \
        -d "text=${message}" \
        -d "parse_mode=Markdown" &>/dev/null
    
    log "DEBUG" "Telegram notification sent" "NOTIFY"
    return 0
}

# Enviar webhook genérico
send_webhook_notification() {
    local level="$1"
    local message="$2"
    local module="$3"
    local data="$4"
    
    local payload
    payload=$(jq -n \
        --arg level "$level" \
        --arg message "$message" \
        --arg module "$module" \
        --arg timestamp "$(date -Iseconds)" \
        --argjson data "$data" \
        '{
            event: "cyberghost_alert",
            level: $level,
            message: $message,
            module: $module,
            timestamp: $timestamp,
            data: $data
        }')
    
    curl -s -X POST -H "Content-Type: application/json" \
        -d "$payload" "$NOTIFY_WEBHOOK_URL" &>/dev/null
    
    log "DEBUG" "Webhook notification sent" "NOTIFY"
    return 0
}

# Enviar Pushover
send_pushover_notification() {
    local level="$1"
    local message="$2"
    
    local priority
    case "$level" in
        "CRITICAL") priority=1 ;;
        "ERROR") priority=1 ;;
        "WARNING") priority=0 ;;
        *) priority=-1 ;;
    esac
    
    local sound
    case "$level" in
        "CRITICAL") sound="persistent" ;;
        "ERROR") sound="pushover" ;;
        "WARNING") sound="intermission" ;;
        *) sound="pushover" ;;
    esac
    
    curl -s -X POST "https://api.pushover.net/1/messages.json" \
        -d "token=${NOTIFY_PUSHOVER_TOKEN}" \
        -d "user=${NOTIFY_PUSHOVER_USER}" \
        -d "title=CYBERGHOST OSINT" \
        -d "message=${message}" \
        -d "priority=${priority}" \
        -d "sound=${sound}" &>/dev/null
    
    log "DEBUG" "Pushover notification sent" "NOTIFY"
    return 0
}

# Enviar Gotify
send_gotify_notification() {
    local level="$1"
    local message="$2"
    
    local priority
    case "$level" in
        "CRITICAL") priority=8 ;;
        "ERROR") priority=8 ;;
        "WARNING") priority=5 ;;
        "SUCCESS") priority=3 ;;
        *) priority=0 ;;
    esac
    
    curl -s -X POST "${NOTIFY_GOTIFY_URL}/message" \
        -H "X-Gotify-Key: ${NOTIFY_GOTIFY_TOKEN}" \
        -F "title=CYBERGHOST OSINT" \
        -F "message=${message}" \
        -F "priority=${priority}" &>/dev/null
    
    log "DEBUG" "Gotify notification sent" "NOTIFY"
    return 0
}

# Notificar scan completo
notify_scan_complete() {
    local target="$1"
    local scan_dir="$2"
    local duration="$3"
    local findings="$4"
    
    local message="Scan completed for *${target}* in ${duration}s with ${findings} findings"
    local data="{\"target\": \"$target\", \"scan_dir\": \"$scan_dir\", \"duration\": $duration, \"findings\": $findings}"
    
    send_notification "SUCCESS" "$message" "SCAN" "$data"
}

# Notificar erro
notify_error() {
    local module="$1"
    local error="$2"
    local details="${3:-{}}"
    
    send_notification "ERROR" "Error in $module: $error" "$module" "$details"
}

# Notificar descoberta crítica
notify_critical_finding() {
    local target="$1"
    local finding="$2"
    local details="$3"
    
    local message="Critical finding discovered for *${target}*: ${finding}"
    
    send_notification "CRITICAL" "$message" "FINDING" "$details"
}

# Testar notificações
test_notifications() {
    log "INFO" "Testing notification channels" "NOTIFY"
    
    local test_message="This is a test notification from CYBERGHOST OSINT"
    
    send_notification "INFO" "$test_message" "TEST" '{"test": true}'
    
    log "SUCCESS" "Test notifications sent" "NOTIFY"
}

# Exportar funções
export -f send_notification notify_scan_complete notify_error notify_critical_finding test_notifications