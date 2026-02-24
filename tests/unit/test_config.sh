#!/usr/bin/env bash
# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Unit Tests for Config Module
# =============================================================================

set -e

# Carregar módulos necessários
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${PROJECT_ROOT}/src/core/config.sh"
source "${PROJECT_ROOT}/src/core/logging.sh"

# Cores para testes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Contadores de teste
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Função de assert
assert() {
    local condition="$1"
    local message="$2"
    
    ((TESTS_TOTAL++))
    
    if eval "$condition"; then
        echo -e "${GREEN}✓ PASS:${NC} $message"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL:${NC} $message"
        echo "  Condition: $condition"
        ((TESTS_FAILED++))
    fi
}

# Setup para testes
setup() {
    echo -e "${YELLOW}Setting up test environment...${NC}"
    
    # Criar diretórios temporários
    export TEST_DIR="/tmp/cyberghost_test_$$"
    export CONFIG_DIR="${TEST_DIR}/.cyberghost"
    export DATA_DIR="${TEST_DIR}/data"
    export LOG_DIR="${TEST_DIR}/logs"
    
    mkdir -p "$CONFIG_DIR" "$DATA_DIR" "$LOG_DIR"
    
    # Configurar variáveis de ambiente para teste
    export DB_TYPE="sqlite"
    export DB_PATH="${CONFIG_DIR}/test.db"
    export LOG_LEVEL="DEBUG"
    export LOG_FORMAT="json"
}

# Cleanup após testes
cleanup() {
    echo -e "${YELLOW}Cleaning up test environment...${NC}"
    rm -rf "$TEST_DIR"
}

# ===== TESTES =====

test_default_config() {
    echo -e "\n${YELLOW}Testing default configuration...${NC}"
    
    # Testar valores padrão
    assert '[[ -n "$VERSION" ]]' "VERSION is set"
    assert '[[ "$VERSION" == "7.0.0" ]]' "VERSION is 7.0.0"
    assert '[[ -n "$AUTHOR" ]]' "AUTHOR is set"
    assert '[[ "$AUTHOR" == "Leonardo Pereira Pinheiro" ]]' "AUTHOR is correct"
    
    # Testar diretórios
    assert '[[ -n "$CONFIG_DIR" ]]' "CONFIG_DIR is set"
    assert '[[ -n "$DATA_DIR" ]]' "DATA_DIR is set"
    assert '[[ -n "$LOG_DIR" ]]' "LOG_DIR is set"
    
    # Testar valores numéricos
    assert '[[ $DEFAULT_TIMEOUT -eq 30 ]]' "DEFAULT_TIMEOUT is 30"
    assert '[[ $MAX_RETRIES -eq 3 ]]' "MAX_RETRIES is 3"
    assert '[[ $PARALLEL_JOBS -eq 10 ]]' "PARALLEL_JOBS is 10"
}

test_config_loading() {
    echo -e "\n${YELLOW}Testing config loading...${NC}"
    
    # Criar arquivo de configuração de teste
    local config_file="${CONFIG_DIR}/settings.conf"
    
    cat > "$config_file" << EOF
LOG_LEVEL="DEBUG"
LOG_FORMAT="json"
PARALLEL_JOBS=20
SCAN_TIMEOUT=7200
EOF
    
    # Carregar configuração
    load_config
    
    # Testar valores carregados
    assert '[[ "$LOG_LEVEL" == "DEBUG" ]]' "LOG_LEVEL loaded correctly"
    assert '[[ "$LOG_FORMAT" == "json" ]]' "LOG_FORMAT loaded correctly"
    assert '[[ $PARALLEL_JOBS -eq 20 ]]' "PARALLEL_JOBS loaded correctly"
    assert '[[ $SCAN_TIMEOUT -eq 7200 ]]' "SCAN_TIMEOUT loaded correctly"
}

test_config_validation() {
    echo -e "\n${YELLOW}Testing config validation...${NC}"
    
    # Testar validação com valores inválidos
    export PARALLEL_JOBS="-1"
    export LOG_LEVEL="INVALID"
    
    validate_config
    
    assert '[[ $PARALLEL_JOBS -eq 10 ]]' "PARALLEL_JOBS reset to default"
    assert '[[ "$LOG_LEVEL" == "INFO" ]]' "LOG_LEVEL reset to default"
}

test_config_saving() {
    echo -e "\n${YELLOW}Testing config saving...${NC}"
    
    # Modificar configurações
    export PARALLEL_JOBS=15
    export LOG_LEVEL="WARNING"
    
    # Salvar configuração
    save_config
    
    # Verificar se arquivo foi criado
    assert '[[ -f "${CONFIG_DIR}/settings.conf" ]]' "Config file was created"
    
    # Carregar novamente e verificar
    unset PARALLEL_JOBS LOG_LEVEL
    source "${CONFIG_DIR}/settings.conf"
    
    assert '[[ $PARALLEL_JOBS -eq 15 ]]' "Saved config loaded correctly"
    assert '[[ "$LOG_LEVEL" == "WARNING" ]]' "Saved LOG_LEVEL loaded correctly"
}

test_api_config() {
    echo -e "\n${YELLOW}Testing API configuration...${NC}"
    
    # Criar arquivo de API keys
    local api_file="${CONFIG_DIR}/api_keys.conf"
    
    cat > "$api_file" << EOF
SHODAN_API_KEY="test_shodan_key"
VIRUSTOTAL_API_KEY="test_vt_key"
GITHUB_API_KEY="test_github_key"
EOF
    
    # Carregar APIs
    source "$api_file"
    
    assert '[[ "$SHODAN_API_KEY" == "test_shodan_key" ]]' "Shodan API key loaded"
    assert '[[ "$VIRUSTOTAL_API_KEY" == "test_vt_key" ]]' "VirusTotal API key loaded"
    assert '[[ "$GITHUB_API_KEY" == "test_github_key" ]]' "GitHub API key loaded"
    assert '[[ -z "${HUNTER_API_KEY:-}" ]]' "Unset API key remains empty"
}

# ===== EXECUTAR TESTES =====
run_tests() {
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}    Running Config Module Tests       ${NC}"
    echo -e "${YELLOW}========================================${NC}"
    
    setup
    
    test_default_config
    test_config_loading
    test_config_validation
    test_config_saving
    test_api_config
    
    cleanup
    
    echo -e "\n${YELLOW}========================================${NC}"
    echo -e "${YELLOW}            Test Results               ${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo -e "Total:  ${TESTS_TOTAL}"
    echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
    echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        return 1
    fi
}

# Executar testes se script for executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi