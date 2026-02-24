#!/usr/bin/env bash
# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Unit Tests for Utils Module
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${PROJECT_ROOT}/src/core/utils.sh"

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

# ===== TESTES DE VALIDAÇÃO =====

test_validate_domain() {
    echo -e "\n${YELLOW}Testing domain validation...${NC}"
    
    assert 'validate_domain "example.com"' "Valid domain: example.com"
    assert 'validate_domain "sub.domain.co.uk"' "Valid domain with subdomain"
    assert 'validate_domain "my-site123.com.br"' "Valid domain with numbers and hyphen"
    
    assert '! validate_domain "invalid"' "Invalid domain: invalid"
    assert '! validate_domain ".com"' "Invalid domain: .com"
    assert '! validate_domain "http://example.com"' "Invalid domain with protocol"
}

test_validate_ip() {
    echo -e "\n${YELLOW}Testing IP validation...${NC}"
    
    assert 'validate_ip "192.168.1.1"' "Valid IPv4: 192.168.1.1"
    assert 'validate_ip "8.8.8.8"' "Valid IPv4: 8.8.8.8"
    assert 'validate_ip "2001:0db8:85a3:0000:0000:8a2e:0370:7334"' "Valid IPv6"
    
    assert '! validate_ip "256.256.256.256"' "Invalid IPv4: octet >255"
    assert '! validate_ip "192.168.1"' "Invalid IPv4: missing octet"
    assert '! validate_ip "invalid"' "Invalid IP: not an IP"
}

test_validate_email() {
    echo -e "\n${YELLOW}Testing email validation...${NC}"
    
    assert 'validate_email "user@example.com"' "Valid email: user@example.com"
    assert 'validate_email "first.last@domain.co.uk"' "Valid email with dots"
    assert 'validate_email "user+tag@example.com"' "Valid email with plus tag"
    
    assert '! validate_email "user@"' "Invalid email: missing domain"
    assert '! validate_email "@example.com"' "Invalid email: missing user"
    assert '! validate_email "user@.com"' "Invalid email: invalid domain"
}

test_validate_url() {
    echo -e "\n${YELLOW}Testing URL validation...${NC}"
    
    assert 'validate_url "http://example.com"' "Valid URL: http"
    assert 'validate_url "https://example.com/path?query=1"' "Valid URL: https with path"
    assert 'validate_url "ftp://ftp.example.com/file.txt"' "Valid URL: ftp"
    
    assert '! validate_url "example.com"' "Invalid URL: missing protocol"
    assert '! validate_url "http://"' "Invalid URL: empty host"
}

# ===== TESTES DE EXTRAÇÃO =====

test_extract_domain() {
    echo -e "\n${YELLOW}Testing domain extraction...${NC}"
    
    local result=$(extract_domain "https://www.example.com/path?query=1")
    assert '[[ "$result" == "www.example.com" ]]' "Extract domain from URL"
    
    result=$(extract_domain "http://sub.domain.co.uk:8080")
    assert '[[ "$result" == "sub.domain.co.uk" ]]' "Extract domain with port"
}

test_extract_ips() {
    echo -e "\n${YELLOW}Testing IP extraction...${NC}"
    
    local text="Server IP: 192.168.1.1, backup: 10.0.0.1"
    local result=$(extract_ips "$text")
    
    assert 'echo "$result" | grep -q "192.168.1.1"' "Extract first IP"
    assert 'echo "$result" | grep -q "10.0.0.1"' "Extract second IP"
}

test_extract_emails() {
    echo -e "\n${YELLOW}Testing email extraction...${NC}"
    
    local text="Contact: user@example.com or admin@domain.co.uk"
    local result=$(extract_emails "$text")
    
    assert 'echo "$result" | grep -q "user@example.com"' "Extract first email"
    assert 'echo "$result" | grep -q "admin@domain.co.uk"' "Extract second email"
}

test_extract_urls() {
    echo -e "\n${YELLOW}Testing URL extraction...${NC}"
    
    local text="Visit https://example.com and http://test.org/page"
    local result=$(extract_urls "$text")
    
    assert 'echo "$result" | grep -q "https://example.com"' "Extract first URL"
    assert 'echo "$result" | grep -q "http://test.org/page"' "Extract second URL"
}

# ===== TESTES DE FORMATAÇÃO =====

test_format_size() {
    echo -e "\n${YELLOW}Testing size formatting...${NC}"
    
    assert '[[ "$(format_size 500)" == "500B" ]]' "Format bytes"
    assert '[[ "$(format_size 2048)" == "2KB" ]]' "Format KB"
    assert '[[ "$(format_size 3145728)" == "3MB" ]]' "Format MB"
    assert '[[ "$(format_size 3221225472)" == "3GB" ]]' "Format GB"
}

test_format_duration() {
    echo -e "\n${YELLOW}Testing duration formatting...${NC}"
    
    assert '[[ "$(format_duration 30)" == "30s" ]]' "Format seconds"
    assert '[[ "$(format_duration 125)" == "02m 05s" ]]' "Format minutes"
    assert '[[ "$(format_duration 3665)" == "01h 01m 05s" ]]' "Format hours"
}

# ===== TESTES DE REDE =====

test_check_port() {
    echo -e "\n${YELLOW}Testing port checking...${NC}"
    
    # Teste com porta que deve estar aberta
    if command -v nc &>/dev/null; then
        nc -l -p 9999 &
        local pid=$!
        sleep 1
        
        assert 'check_port "localhost" "9999" 1' "Port check on listening port"
        kill $pid 2>/dev/null
    else
        echo -e "${YELLOW}⚠ Skipping port check test (nc not available)${NC}"
    fi
}

test_resolve_dns() {
    echo -e "\n${YELLOW}Testing DNS resolution...${NC}"
    
    local result=$(resolve_dns "google.com")
    assert '[[ -n "$result" ]]' "DNS resolution returns IP"
}

# ===== TESTES DE CRIPTOGRAFIA =====

test_generate_id() {
    echo -e "\n${YELLOW}Testing ID generation...${NC}"
    
    local id1=$(generate_id)
    local id2=$(generate_id)
    
    assert '[[ -n "$id1" ]]' "ID is not empty"
    assert '[[ ${#id1} -eq 16 ]]' "ID has correct length"
    assert '[[ "$id1" != "$id2" ]]' "IDs are unique"
}

test_generate_password() {
    echo -e "\n${YELLOW}Testing password generation...${NC}"
    
    local pass1=$(generate_password 20)
    local pass2=$(generate_password 20)
    
    assert '[[ ${#pass1} -eq 20 ]]' "Password has correct length"
    assert '[[ "$pass1" != "$pass2" ]]' "Passwords are unique"
}

test_base64() {
    echo -e "\n${YELLOW}Testing Base64 encoding/decoding...${NC}"
    
    local original="test string"
    local encoded=$(base64_encode "$original")
    local decoded=$(base64_decode "$encoded")
    
    assert '[[ "$decoded" == "$original" ]]' "Base64 encode/decode works"
}

test_url_encode_decode() {
    echo -e "\n${YELLOW}Testing URL encoding/decoding...${NC}"
    
    local original="hello world & more"
    local encoded=$(url_encode "$original")
    local decoded=$(url_decode "$encoded")
    
    assert '[[ "$decoded" == "$original" ]]' "URL encode/decode works"
}

# ===== TESTES DE UTILITÁRIOS =====

test_check_command() {
    echo -e "\n${YELLOW}Testing command checking...${NC}"
    
    assert 'check_command "bash"' "Existing command returns true"
    assert '! check_command "nonexistentcommand123"' "Non-existent command returns false"
}

test_ensure_dir() {
    echo -e "\n${YELLOW}Testing directory creation...${NC}"
    
    local test_dir="/tmp/cyberghost_test_dir/$$/nested"
    ensure_dir "$test_dir"
    
    assert '[[ -d "$test_dir" ]]' "Directory created"
    rm -rf "/tmp/cyberghost_test_dir"
}

# ===== EXECUTAR TESTES =====
run_tests() {
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}     Running Utils Module Tests        ${NC}"
    echo -e "${YELLOW}========================================${NC}"
    
    test_validate_domain
    test_validate_ip
    test_validate_email
    test_validate_url
    test_extract_domain
    test_extract_ips
    test_extract_emails
    test_extract_urls
    test_format_size
    test_format_duration
    test_check_port
    test_resolve_dns
    test_generate_id
    test_generate_password
    test_base64
    test_url_encode_decode
    test_check_command
    test_ensure_dir
    
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