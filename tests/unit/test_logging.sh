#!/usr/bin/env bash
# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Unit Tests for Logging Module
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${PROJECT_ROOT}/src/core/logging.sh"

# Cores para testes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

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

setup() {
    export TEST_DIR="/tmp/cyberghost_test_$$"
    export LOG_DIR="${TEST_DIR}/logs"
    mkdir -p "$LOG_DIR"
    
    # Inicializar logging
    init_logging
}

cleanup() {
    rm -rf "$TEST_DIR"
}

# ===== TESTES =====

test_log_creation() {
    echo -e "\n${YELLOW}Testing log file creation...${NC}"
    
    assert '[[ -f "$MAIN_LOG" ]]' "Main log file created"
    assert '[[ -f "$ERROR_LOG" ]]' "Error log file created"
    assert '[[ -f "$DEBUG_LOG" ]]' "Debug log file created"
    assert '[[ -f "$AUDIT_LOG" ]]' "Audit log file created"
}

test_log_levels() {
    echo -e "\n${YELLOW}Testing log levels...${NC}"
    
    export LOG_LEVEL="INFO"
    
    log "DEBUG" "Debug message" "TEST"
    log "INFO" "Info message" "TEST"
    log "WARNING" "Warning message" "TEST"
    log "ERROR" "Error message" "TEST"
    
    # DEBUG não deve aparecer no log principal com nível INFO
    assert '! grep -q "Debug message" "$MAIN_LOG"' "DEBUG message filtered correctly"
    assert 'grep -q "Info message" "$MAIN_LOG"' "INFO message logged"
    assert 'grep -q "Warning message" "$MAIN_LOG"' "WARNING message logged"
    assert 'grep -q "Error message" "$MAIN_LOG"' "ERROR message logged"
}

test_log_format() {
    echo -e "\n${YELLOW}Testing log format...${NC}"
    
    export LOG_FORMAT="json"
    log "INFO" "JSON test message" "TEST"
    
    # Verificar formato JSON
    local last_line=$(tail -n 1 "$MAIN_LOG")
    assert 'echo "$last_line" | jq -e . >/dev/null 2>&1' "Log is valid JSON"
    assert 'echo "$last_line" | jq -e ".level == \"INFO\""' "JSON contains correct level"
    assert 'echo "$last_line" | jq -e ".module == \"TEST\""' "JSON contains correct module"
    assert 'echo "$last_line" | jq -e ".message | contains(\"JSON test\")"' "JSON contains correct message"
}

test_error_logging() {
    echo -e "\n${YELLOW}Testing error logging...${NC}"
    
    log "ERROR" "Test error message" "TEST"
    log "CRITICAL" "Test critical message" "TEST"
    
    assert 'grep -q "Test error message" "$ERROR_LOG"' "Error logged to error.log"
    assert 'grep -q "Test critical message" "$ERROR_LOG"' "Critical logged to error.log"
    assert '! grep -q "Test error message" "$DEBUG_LOG"' "Error not logged to debug.log"
}

test_audit_logging() {
    echo -e "\n${YELLOW}Testing audit logging...${NC}"
    
    export AUDIT_LOGGING=true
    
    log "INFO" "Test audit message" "AUDIT_TEST"
    
    assert 'grep -q "Test audit message" "$AUDIT_LOG"' "Audit message logged"
    assert 'grep -q "AUDIT_TEST" "$AUDIT_LOG"' "Audit module logged"
}

test_performance_logging() {
    echo -e "\n${YELLOW}Testing performance logging...${NC}"
    
    log_performance "test_operation" "5.2" '{"key": "value"}'
    
    assert 'grep -q "test_operation" "$PERFORMANCE_LOG"' "Performance operation logged"
    assert 'grep -q "5.2" "$PERFORMANCE_LOG"' "Performance duration logged"
    assert 'grep -q "key" "$PERFORMANCE_LOG"' "Performance metadata logged"
}

test_log_rotation() {
    echo -e "\n${YELLOW}Testing log rotation...${NC}"
    
    # Preencher log até passar do limite
    export LOG_MAX_SIZE="1K"
    
    for i in {1..100}; do
        log "INFO" "Test message $i with some extra content to increase size" "TEST"
    done
    
    rotate_logs
    
    # Verificar se houve rotação
    local rotated_count=$(find "$LOG_DIR" -name "*.log.gz" 2>/dev/null | wc -l)
    assert '[[ $rotated_count -gt 0 ]]' "Log files were rotated"
}

test_log_data() {
    echo -e "\n${YELLOW}Testing structured data logging...${NC}"
    
    local test_data='{"ip": "192.168.1.1", "port": 80}'
    log_data "INFO" "Test data message" "$test_data" "DATA_TEST"
    
    assert 'grep -q "Test data message" "$MAIN_LOG"' "Data message logged"
    assert 'grep -q "192.168.1.1" "$MAIN_LOG"' "Data content logged"
}

test_log_progress() {
    echo -e "\n${YELLOW}Testing progress logging...${NC}"
    
    log_progress 50 100 "Test progress" "PROGRESS_TEST"
    
    assert 'grep -q "50%" "$MAIN_LOG"' "Progress percentage logged"
    assert 'grep -q "Test progress" "$MAIN_LOG"' "Progress message logged"
}

# ===== EXECUTAR TESTES =====
run_tests() {
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}   Running Logging Module Tests        ${NC}"
    echo -e "${YELLOW}========================================${NC}"
    
    setup
    
    test_log_creation
    test_log_levels
    test_log_format
    test_error_logging
    test_audit_logging
    test_performance_logging
    test_log_rotation
    test_log_data
    test_log_progress
    
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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi