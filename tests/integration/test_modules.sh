#!/usr/bin/env bash
# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Integration Tests for Modules
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${PROJECT_ROOT}/src/core/main.sh"
source "${PROJECT_ROOT}/src/core/logging.sh"

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
    export TEST_DIR="/tmp/cyberghost_integration_$$"
    export OUTPUT_DIR="${TEST_DIR}/output"
    mkdir -p "$OUTPUT_DIR"
    
    # Carregar módulos
    source "${PROJECT_ROOT}/src/modules/recon/subdomain_enum.sh"
    source "${PROJECT_ROOT}/src/modules/recon/dns_intel.sh"
    source "${PROJECT_ROOT}/src/modules/intel/threat_intel.sh"
}

cleanup() {
    rm -rf "$TEST_DIR"
}

# ===== TESTES DE MÓDULOS =====

test_subdomain_enumeration() {
    echo -e "\n${YELLOW}Testing subdomain enumeration module...${NC}"
    
    # Usar um domínio de teste conhecido
    local test_domain="example.com"
    local results
    
    results=$(enumerate_subdomains "$test_domain" "$OUTPUT_DIR")
    
    assert '[[ -n "$results" ]]' "Module returned results"
    assert '[[ -f "${OUTPUT_DIR}/subdomains/all_subdomains.txt" ]]' "Subdomain file created"
    
    local subdomain_count=$(wc -l < "${OUTPUT_DIR}/subdomains/all_subdomains.txt")
    assert '[[ $subdomain_count -gt 0 ]]' "Found some subdomains"
}

test_dns_intelligence() {
    echo -e "\n${YELLOW}Testing DNS intelligence module...${NC}"
    
    local test_domain="google.com"
    local results
    
    results=$(dns_intelligence "$test_domain" "$OUTPUT_DIR")
    
    assert '[[ -n "$results" ]]' "Module returned results"
    assert '[[ -f "${OUTPUT_DIR}/dns_intel/dns_intel.json" ]]' "DNS intel file created"
    
    # Verificar se encontrou registros DNS
    local record_count=$(jq '.dns_records | length' "${OUTPUT_DIR}/dns_intel/dns_intel.json")
    assert '[[ $record_count -gt 0 ]]' "Found DNS records"
}

test_threat_intelligence() {
    echo -e "\n${YELLOW}Testing threat intelligence module...${NC}"
    
    # Usar IP de teste (Google DNS)
    local test_ip="8.8.8.8"
    local results
    
    results=$(gather_threat_intel "$test_ip" "$OUTPUT_DIR")
    
    assert '[[ -n "$results" ]]' "Module returned results"
    assert '[[ -f "${OUTPUT_DIR}/threat_intel/threat_intel.json" ]]' "Threat intel file created"
}

test_module_integration() {
    echo -e "\n${YELLOW}Testing module integration...${NC}"
    
    local test_domain="example.com"
    
    # Executar múltiplos módulos sequencialmente
    enumerate_subdomains "$test_domain" "$OUTPUT_DIR" > /dev/null
    dns_intelligence "$test_domain" "$OUTPUT_DIR" > /dev/null
    
    # Verificar se dados podem ser correlacionados
    local subdomains_file="${OUTPUT_DIR}/subdomains/all_subdomains.txt"
    local dns_file="${OUTPUT_DIR}/dns_intel/dns_intel.json"
    
    assert '[[ -f "$subdomains_file" ]]' "Subdomains file exists"
    assert '[[ -f "$dns_file" ]]' "DNS file exists"
}

# ===== EXECUTAR TESTES =====
run_tests() {
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}   Running Module Integration Tests    ${NC}"
    echo -e "${YELLOW}========================================${NC}"
    
    setup
    
    test_subdomain_enumeration
    test_dns_intelligence
    test_threat_intelligence
    test_module_integration
    
    cleanup
    
    echo -e "\n${YELLOW}========================================${NC}"
    echo -e "${YELLOW}            Test Results               ${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo -e "Total:  ${TESTS_TOTAL}"
    echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
    echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All integration tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some integration tests failed!${NC}"
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi