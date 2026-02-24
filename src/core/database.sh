#!/usr/bin/env bash

# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Database Manager
# =============================================================================

# Tipos de banco de dados suportados
DB_TYPES=("sqlite" "postgresql" "mysql" "mongodb")

# Configurações padrão
DB_TYPE="${DB_TYPE:-sqlite}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-cyberghost}"
DB_USER="${DB_USER:-cyberghost}"
DB_PASS="${DB_PASS:-}"
DB_PATH="${DB_PATH:-${CONFIG_DIR}/cyberghost.db}"

# Inicializar banco de dados
init_database() {
    log "INFO" "Initializing database (${DB_TYPE})" "DATABASE"
    
    case "$DB_TYPE" in
        sqlite)
            init_sqlite
            ;;
        postgresql)
            init_postgresql
            ;;
        mysql)
            init_mysql
            ;;
        mongodb)
            init_mongodb
            ;;
        *)
            log "ERROR" "Unsupported database type: $DB_TYPE" "DATABASE"
            return 1
            ;;
    esac
    
    # Criar tabelas básicas
    create_tables
    
    log "SUCCESS" "Database initialized successfully" "DATABASE"
}

# Inicializar SQLite
init_sqlite() {
    local db_dir
    db_dir=$(dirname "$DB_PATH")
    mkdir -p "$db_dir"
    
    # Verificar se SQLite3 está instalado
    if ! command -v sqlite3 &> /dev/null; then
        log "ERROR" "SQLite3 not installed" "DATABASE"
        return 1
    fi
    
    # Testar conexão
    sqlite3 "$DB_PATH" "SELECT 1;" &>/dev/null || {
        log "ERROR" "Failed to create SQLite database" "DATABASE"
        return 1
    }
    
    export DB_CONN="sqlite3 $DB_PATH"
}

# Inicializar PostgreSQL
init_postgresql() {
    if ! command -v psql &> /dev/null; then
        log "ERROR" "PostgreSQL client not installed" "DATABASE"
        return 1
    fi
    
    # Testar conexão
    PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" &>/dev/null || {
        log "WARNING" "Database doesn't exist, attempting to create" "DATABASE"
        PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME;" &>/dev/null || {
            log "ERROR" "Failed to create database" "DATABASE"
            return 1
        }
    }
    
    export DB_CONN="PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"
}

# Inicializar MySQL
init_mysql() {
    if ! command -v mysql &> /dev/null; then
        log "ERROR" "MySQL client not installed" "DATABASE"
        return 1
    fi
    
    # Testar conexão
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME;" 2>/dev/null || {
        log "WARNING" "Database doesn't exist, attempting to create" "DATABASE"
        mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE $DB_NAME;" 2>/dev/null || {
            log "ERROR" "Failed to create database" "DATABASE"
            return 1
        }
    }
    
    export DB_CONN="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME"
}

# Inicializar MongoDB
init_mongodb() {
    if ! command -v mongosh &> /dev/null; then
        log "ERROR" "MongoDB shell not installed" "DATABASE"
        return 1
    fi
    
    export DB_CONN="mongosh --host $DB_HOST --port $DB_PORT -u $DB_USER -p $DB_PASS $DB_NAME"
}

# Criar tabelas
create_tables() {
    log "DEBUG" "Creating database tables" "DATABASE"
    
    case "$DB_TYPE" in
        sqlite)
            create_tables_sqlite
            ;;
        postgresql|mysql)
            create_tables_sql
            ;;
        mongodb)
            create_collections_mongodb
            ;;
    esac
}

# Criar tabelas SQLite
create_tables_sqlite() {
    sqlite3 "$DB_PATH" << 'EOF'
-- Scans table
CREATE TABLE IF NOT EXISTS scans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scan_id TEXT UNIQUE NOT NULL,
    target TEXT NOT NULL,
    scan_type TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    start_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    end_time DATETIME,
    duration INTEGER,
    results TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Modules table
CREATE TABLE IF NOT EXISTS modules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    version TEXT,
    enabled BOOLEAN DEFAULT 1,
    config TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Results table
CREATE TABLE IF NOT EXISTS results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scan_id TEXT NOT NULL,
    module TEXT NOT NULL,
    data TEXT NOT NULL,
    severity TEXT DEFAULT 'info',
    tags TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (scan_id) REFERENCES scans(scan_id)
);

-- Targets table
CREATE TABLE IF NOT EXISTS targets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    target TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL,
    first_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_scanned DATETIME,
    scan_count INTEGER DEFAULT 0,
    notes TEXT,
    tags TEXT
);

-- API keys table
CREATE TABLE IF NOT EXISTS api_keys (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    service TEXT UNIQUE NOT NULL,
    api_key TEXT NOT NULL,
    enabled BOOLEAN DEFAULT 1,
    last_used DATETIME,
    usage_count INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Alerts table
CREATE TABLE IF NOT EXISTS alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,
    severity TEXT NOT NULL,
    message TEXT NOT NULL,
    data TEXT,
    acknowledged BOOLEAN DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Cache table
CREATE TABLE IF NOT EXISTS cache (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    expires_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_scans_target ON scans(target);
CREATE INDEX IF NOT EXISTS idx_scans_status ON scans(status);
CREATE INDEX IF NOT EXISTS idx_results_scan_id ON results(scan_id);
CREATE INDEX IF NOT EXISTS idx_results_severity ON results(severity);
CREATE INDEX IF NOT EXISTS idx_targets_last_scanned ON targets(last_scanned);
CREATE INDEX IF NOT EXISTS idx_cache_expires ON cache(expires_at);
EOF
}

# Criar tabelas SQL (PostgreSQL/MySQL)
create_tables_sql() {
    local sql="
-- Scans table
CREATE TABLE IF NOT EXISTS scans (
    id SERIAL PRIMARY KEY,
    scan_id VARCHAR(64) UNIQUE NOT NULL,
    target TEXT NOT NULL,
    scan_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    duration INTEGER,
    results JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Modules table
CREATE TABLE IF NOT EXISTS modules (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    version VARCHAR(20),
    enabled BOOLEAN DEFAULT TRUE,
    config JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Results table
CREATE TABLE IF NOT EXISTS results (
    id SERIAL PRIMARY KEY,
    scan_id VARCHAR(64) NOT NULL,
    module VARCHAR(100) NOT NULL,
    data JSONB NOT NULL,
    severity VARCHAR(20) DEFAULT 'info',
    tags TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (scan_id) REFERENCES scans(scan_id)
);

-- Targets table
CREATE TABLE IF NOT EXISTS targets (
    id SERIAL PRIMARY KEY,
    target TEXT UNIQUE NOT NULL,
    type VARCHAR(50) NOT NULL,
    first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_scanned TIMESTAMP,
    scan_count INTEGER DEFAULT 0,
    notes TEXT,
    tags TEXT[]
);

-- API keys table
CREATE TABLE IF NOT EXISTS api_keys (
    id SERIAL PRIMARY KEY,
    service VARCHAR(50) UNIQUE NOT NULL,
    api_key TEXT NOT NULL,
    enabled BOOLEAN DEFAULT TRUE,
    last_used TIMESTAMP,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_scans_target ON scans(target);
CREATE INDEX IF NOT EXISTS idx_scans_status ON scans(status);
CREATE INDEX IF NOT EXISTS idx_results_scan_id ON results(scan_id);
CREATE INDEX IF NOT EXISTS idx_targets_last_scanned ON targets(last_scanned);
"
    
    echo "$sql" | eval "$DB_CONN"
}

# Criar coleções MongoDB
create_collections_mongodb() {
    eval "$DB_CONN" << 'EOF'
db.createCollection("scans");
db.scans.createIndex({ "scan_id": 1 }, { unique: true });
db.scans.createIndex({ "target": 1 });
db.scans.createIndex({ "status": 1 });

db.createCollection("modules");
db.modules.createIndex({ "name": 1 }, { unique: true });

db.createCollection("results");
db.results.createIndex({ "scan_id": 1 });
db.results.createIndex({ "severity": 1 });

db.createCollection("targets");
db.targets.createIndex({ "target": 1 }, { unique: true });
db.targets.createIndex({ "last_scanned": 1 });

db.createCollection("api_keys");
db.api_keys.createIndex({ "service": 1 }, { unique: true });

db.createCollection("alerts");
db.alerts.createIndex({ "created_at": 1 });

db.createCollection("cache");
db.cache.createIndex({ "expires_at": 1 }, { expireAfterSeconds: 0 });
EOF
}

# Salvar scan
save_scan() {
    local scan_id="$1"
    local target="$2"
    local scan_type="$3"
    local status="${4:-pending}"
    
    log "DEBUG" "Saving scan: $scan_id" "DATABASE"
    
    case "$DB_TYPE" in
        sqlite)
            sqlite3 "$DB_PATH" "INSERT INTO scans (scan_id, target, scan_type, status) VALUES ('$scan_id', '$target', '$scan_type', '$status');"
            ;;
        postgresql|mysql)
            eval "$DB_CONN" -c "INSERT INTO scans (scan_id, target, scan_type, status) VALUES ('$scan_id', '$target', '$scan_type', '$status');"
            ;;
        mongodb)
            eval "$DB_CONN" << EOF
db.scans.insertOne({
    scan_id: "$scan_id",
    target: "$target",
    scan_type: "$scan_type",
    status: "$status",
    start_time: new Date()
});
EOF
            ;;
    esac
}

# Atualizar scan
update_scan() {
    local scan_id="$1"
    local data="$2"
    
    log "DEBUG" "Updating scan: $scan_id" "DATABASE"
    
    case "$DB_TYPE" in
        sqlite)
            local set_clause=""
            for key in $(echo "$data" | jq -r 'keys[]'); do
                local value
                value=$(echo "$data" | jq -r ".$key")
                set_clause="$set_clause, $key='$value'"
            done
            set_clause="${set_clause#,}"
            sqlite3 "$DB_PATH" "UPDATE scans SET $set_clause, updated_at=CURRENT_TIMESTAMP WHERE scan_id='$scan_id';"
            ;;
        postgresql|mysql)
            local set_clause=""
            for key in $(echo "$data" | jq -r 'keys[]'); do
                local value
                value=$(echo "$data" | jq -r ".$key")
                set_clause="$set_clause, $key='$value'"
            done
            set_clause="${set_clause#,}"
            eval "$DB_CONN" -c "UPDATE scans SET $set_clause, updated_at=CURRENT_TIMESTAMP WHERE scan_id='$scan_id';"
            ;;
        mongodb)
            eval "$DB_CONN" << EOF
db.scans.updateOne(
    { scan_id: "$scan_id" },
    { \$set: $(echo "$data" | jq -c '. += {updated_at: new Date()}') }
);
EOF
            ;;
    esac
}

# Salvar resultado
save_result() {
    local scan_id="$1"
    local module="$2"
    local data="$3"
    local severity="${4:-info}"
    local tags="${5:-[]}"
    
    log "DEBUG" "Saving result for scan: $scan_id, module: $module" "DATABASE"
    
    case "$DB_TYPE" in
        sqlite)
            local data_escaped
            data_escaped=$(echo "$data" | sqlite3_escape)
            sqlite3 "$DB_PATH" "INSERT INTO results (scan_id, module, data, severity, tags) VALUES ('$scan_id', '$module', '$data_escaped', '$severity', '$tags');"
            ;;
        postgresql|mysql)
            eval "$DB_CONN" -c "INSERT INTO results (scan_id, module, data, severity, tags) VALUES ('$scan_id', '$module', '$data'::jsonb, '$severity', '$tags'::text[]);"
            ;;
        mongodb)
            eval "$DB_CONN" << EOF
db.results.insertOne({
    scan_id: "$scan_id",
    module: "$module",
    data: $(echo "$data" | jq -c .),
    severity: "$severity",
    tags: $(echo "$tags" | jq -c .),
    created_at: new Date()
});
EOF
            ;;
    esac
}

# Buscar scan
get_scan() {
    local scan_id="$1"
    
    case "$DB_TYPE" in
        sqlite)
            sqlite3 "$DB_PATH" "SELECT * FROM scans WHERE scan_id='$scan_id';"
            ;;
        postgresql|mysql)
            eval "$DB_CONN" -c "SELECT * FROM scans WHERE scan_id='$scan_id';"
            ;;
        mongodb)
            eval "$DB_CONN" "db.scans.findOne({ scan_id: '$scan_id' });"
            ;;
    esac
}

# Buscar resultados
get_results() {
    local scan_id="$1"
    local severity="${2:-}"
    
    case "$DB_TYPE" in
        sqlite)
            if [[ -n "$severity" ]]; then
                sqlite3 "$DB_PATH" "SELECT * FROM results WHERE scan_id='$scan_id' AND severity='$severity' ORDER BY created_at;"
            else
                sqlite3 "$DB_PATH" "SELECT * FROM results WHERE scan_id='$scan_id' ORDER BY created_at;"
            fi
            ;;
        postgresql|mysql)
            if [[ -n "$severity" ]]; then
                eval "$DB_CONN" -c "SELECT * FROM results WHERE scan_id='$scan_id' AND severity='$severity' ORDER BY created_at;"
            else
                eval "$DB_CONN" -c "SELECT * FROM results WHERE scan_id='$scan_id' ORDER BY created_at;"
            fi
            ;;
        mongodb)
            if [[ -n "$severity" ]]; then
                eval "$DB_CONN" "db.results.find({ scan_id: '$scan_id', severity: '$severity' }).sort({ created_at: 1 });"
            else
                eval "$DB_CONN" "db.results.find({ scan_id: '$scan_id' }).sort({ created_at: 1 });"
            fi
            ;;
    esac
}

# Salvar target
save_target() {
    local target="$1"
    local type="$2"
    local notes="${3:-}"
    local tags="${4:-[]}"
    
    log "DEBUG" "Saving target: $target" "DATABASE"
    
    case "$DB_TYPE" in
        sqlite)
            sqlite3 "$DB_PATH" "INSERT OR IGNORE INTO targets (target, type, notes, tags) VALUES ('$target', '$type', '$notes', '$tags');"
            sqlite3 "$DB_PATH" "UPDATE targets SET last_scanned=CURRENT_TIMESTAMP, scan_count=scan_count+1 WHERE target='$target';"
            ;;
        postgresql|mysql)
            eval "$DB_CONN" -c "INSERT INTO targets (target, type, notes, tags) VALUES ('$target', '$type', '$notes', '$tags'::text[]) ON CONFLICT (target) DO UPDATE SET last_scanned=CURRENT_TIMESTAMP, scan_count=targets.scan_count+1;"
            ;;
        mongodb)
            eval "$DB_CONN" << EOF
db.targets.updateOne(
    { target: "$target" },
    { 
        \$setOnInsert: { 
            target: "$target",
            type: "$type",
            notes: "$notes",
            tags: $(echo "$tags" | jq -c .),
            first_seen: new Date()
        },
        \$set: { last_scanned: new Date() },
        \$inc: { scan_count: 1 }
    },
    { upsert: true }
);
EOF
            ;;
    esac
}

# Salvar cache
set_cache() {
    local key="$1"
    local value="$2"
    local ttl="${3:-3600}"
    
    local expires
    expires=$(date -d "+$ttl seconds" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || date -v+"$ttl"S +"%Y-%m-%d %H:%M:%S" 2>/dev/null)
    
    case "$DB_TYPE" in
        sqlite)
            sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO cache (key, value, expires_at) VALUES ('$key', '$value', '$expires');"
            ;;
        postgresql|mysql)
            eval "$DB_CONN" -c "INSERT INTO cache (key, value, expires_at) VALUES ('$key', '$value', '$expires'::timestamp) ON CONFLICT (key) DO UPDATE SET value='$value', expires_at='$expires'::timestamp;"
            ;;
        mongodb)
            eval "$DB_CONN" << EOF
db.cache.updateOne(
    { key: "$key" },
    { 
        \$set: { 
            value: $(echo "$value" | jq -c .),
            expires_at: new Date(Date.now() + $ttl * 1000)
        }
    },
    { upsert: true }
);
EOF
            ;;
    esac
}

# Buscar cache
get_cache() {
    local key="$1"
    
    case "$DB_TYPE" in
        sqlite)
            sqlite3 "$DB_PATH" "SELECT value FROM cache WHERE key='$key' AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP);"
            ;;
        postgresql|mysql)
            eval "$DB_CONN" -t -c "SELECT value FROM cache WHERE key='$key' AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP);" | head -n 2 | tail -n 1
            ;;
        mongodb)
            eval "$DB_CONN" "db.cache.findOne({ key: '$key', expires_at: { \$gt: new Date() } }).value;"
            ;;
    esac
}

# Criar alerta
create_alert() {
    local type="$1"
    local severity="$2"
    local message="$3"
    local data="${4:-{}}"
    
    log "WARNING" "Alert: [$severity] $message" "ALERT"
    
    case "$DB_TYPE" in
        sqlite)
            local data_escaped
            data_escaped=$(echo "$data" | sqlite3_escape)
            sqlite3 "$DB_PATH" "INSERT INTO alerts (type, severity, message, data) VALUES ('$type', '$severity', '$message', '$data_escaped');"
            ;;
        postgresql|mysql)
            eval "$DB_CONN" -c "INSERT INTO alerts (type, severity, message, data) VALUES ('$type', '$severity', '$message', '$data'::jsonb);"
            ;;
        mongodb)
            eval "$DB_CONN" << EOF
db.alerts.insertOne({
    type: "$type",
    severity: "$severity",
    message: "$message",
    data: $(echo "$data" | jq -c .),
    acknowledged: false,
    created_at: new Date()
});
EOF
            ;;
    esac
}

# Backup database
backup_database() {
    local backup_file="${1:-${BACKUP_DIR}/cyberghost_$(date +%Y%m%d_%H%M%S).bak}"
    
    log "INFO" "Creating database backup: $backup_file" "DATABASE"
    
    mkdir -p "$(dirname "$backup_file")"
    
    case "$DB_TYPE" in
        sqlite)
            sqlite3 "$DB_PATH" ".backup '$backup_file'"
            ;;
        postgresql)
            PGPASSWORD="$DB_PASS" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" > "$backup_file"
            ;;
        mysql)
            mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$backup_file"
            ;;
        mongodb)
            mongodump --host "$DB_HOST" --port "$DB_PORT" -u "$DB_USER" -p "$DB_PASS" --db "$DB_NAME" --archive="$backup_file"
            ;;
    esac
    
    # Comprimir
    gzip "$backup_file"
    
    log "SUCCESS" "Backup created: ${backup_file}.gz" "DATABASE"
}

# Restore database
restore_database() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        log "ERROR" "Backup file not found: $backup_file" "DATABASE"
        return 1
    fi
    
    log "INFO" "Restoring database from: $backup_file" "DATABASE"
    
    # Descomprimir se necessário
    if [[ "$backup_file" == *.gz ]]; then
        gunzip -c "$backup_file" > "${backup_file%.gz}"
        backup_file="${backup_file%.gz}"
    fi
    
    case "$DB_TYPE" in
        sqlite)
            sqlite3 "$DB_PATH" ".restore '$backup_file'"
            ;;
        postgresql)
            PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"
            PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME;"
            PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" < "$backup_file"
            ;;
        mysql)
            mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -e "DROP DATABASE IF EXISTS $DB_NAME; CREATE DATABASE $DB_NAME;"
            mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$backup_file"
            ;;
        mongodb)
            mongorestore --host "$DB_HOST" --port "$DB_PORT" -u "$DB_USER" -p "$DB_PASS" --db "$DB_NAME" --drop --archive="$backup_file"
            ;;
    esac
    
    # Limpar
    rm -f "$backup_file"
    
    log "SUCCESS" "Database restored successfully" "DATABASE"
}

# Utilitário para escapar strings para SQLite
sqlite3_escape() {
    sed "s/'/''/g"
}

# Exportar funções
export -f init_database save_scan update_scan save_result get_scan get_results save_target set_cache get_cache create_alert backup_database restore_database