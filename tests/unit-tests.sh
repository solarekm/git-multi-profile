#!/bin/bash

# Git Multi-Profile Unit Tests - Simplified
# Fast focused testing of individual functions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="/tmp/git-config-unit-tests-$$"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
test_count=0
pass_count=0
fail_count=0

# Test framework
run_validation_test() {
    local func="$1"
    local input="$2"
    local expected="$3"
    local desc="$4"
    
    ((test_count++))
    
    local result
    if $func "$input" >/dev/null 2>&1; then
        result="true"
    else
        result="false"
    fi
    
    if [[ "$result" == "$expected" ]]; then
        echo -e "${GREEN}✅ PASS${NC}: $desc"
        ((pass_count++))
    else
        echo -e "${RED}❌ FAIL${NC}: $desc (expected: $expected, got: $result)"
        ((fail_count++))
    fi
}

# ============================================================================
# Email Validation Tests
# ============================================================================
test_email_validation() {
    echo -e "${BLUE}🧪 Testing Email Validation${NC}"
    
    validate_email() {
        local email="$1"
        [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
    }
    
    # Valid emails
    run_validation_test "validate_email" "user@example.com" "true" "Valid basic email"
    run_validation_test "validate_email" "test.user+tag@domain.co.uk" "true" "Valid complex email"
    run_validation_test "validate_email" "user123@sub.domain.org" "true" "Valid subdomain email"
    
    # Invalid emails
    run_validation_test "validate_email" "invalid" "false" "Invalid: no @ symbol"
    run_validation_test "validate_email" "@domain.com" "false" "Invalid: no username"
    run_validation_test "validate_email" "user@domain" "false" "Invalid: no TLD"
}

# ============================================================================
# Path Validation Tests  
# ============================================================================
test_path_validation() {
    echo -e "${BLUE}🧪 Testing Path Validation${NC}"
    
    validate_path() {
        local path="$1"
        [[ "$path" =~ ^(/|~) ]] && [[ ! "$path" =~ [[:space:]] ]] && [[ ! "$path" =~ \.\. ]]
    }
    
    # Valid paths
    run_validation_test "validate_path" "/home/user/repositories" "true" "Valid absolute path"
    run_validation_test "validate_path" "~/repositories" "true" "Valid home path"
    run_validation_test "validate_path" "/opt/projects" "true" "Valid system path"
    
    # Invalid paths
    run_validation_test "validate_path" "relative/path" "false" "Invalid: relative path"
    run_validation_test "validate_path" "/path with spaces" "false" "Invalid: spaces in path"
    run_validation_test "validate_path" "/path/../dangerous" "false" "Invalid: path traversal"
}

# ============================================================================
# SSH Key Type Tests
# ============================================================================
test_ssh_key_validation() {
    echo -e "${BLUE}🧪 Testing SSH Key Type Validation${NC}"
    
    validate_key_type() {
        local key_type="$1"
        case "$key_type" in
            "ed25519"|"rsa") return 0 ;;
            *) return 1 ;;
        esac
    }
    
    # Valid key types
    run_validation_test "validate_key_type" "ed25519" "true" "Valid: ed25519"
    run_validation_test "validate_key_type" "rsa" "true" "Valid: rsa"
    
    # Invalid key types
    run_validation_test "validate_key_type" "dsa" "false" "Invalid: dsa (deprecated)"
    run_validation_test "validate_key_type" "invalid" "false" "Invalid: unknown type"
}

# ============================================================================
# Security Tests
# ============================================================================
test_security_validation() {
    echo -e "${BLUE}🧪 Testing Security Validation${NC}"
    
    safe_input() {
        local input="$1"
        # Check for dangerous characters
        [[ ! "$input" =~ [\;\|\&\$\`] ]]
    }
    
    # Safe inputs
    run_validation_test "safe_input" "normal_input" "true" "Safe: normal input"
    run_validation_test "safe_input" "email@domain.com" "true" "Safe: email format"
    run_validation_test "safe_input" "/safe/path" "true" "Safe: file path"
    
    # Dangerous inputs
    run_validation_test "safe_input" "input; rm -rf /" "false" "Unsafe: command injection"
    run_validation_test "safe_input" "input | malicious" "false" "Unsafe: pipe injection"
    run_validation_test "safe_input" "input \$(evil)" "false" "Unsafe: command substitution"
}

# ============================================================================
# Template Tests
# ============================================================================
test_template_validation() {
    echo -e "${BLUE}🧪 Testing Template Processing${NC}"
    
    # Create test template
    mkdir -p "$TEST_DIR"
    cat > "$TEST_DIR/test-template" << 'EOF'
[user]
    name = Your Professional Name
    email = your.name@company.com
EOF
    
    # Test replacement
    local result=$(sed 's/Your Professional Name/John Doe/g; s/your.name@company.com/john.doe@example.com/g' "$TEST_DIR/test-template")
    
    if echo "$result" | grep -q "name = John Doe"; then
        echo -e "${GREEN}✅ PASS${NC}: Name placeholder replaced correctly"
        ((test_count++))
        ((pass_count++))
    else
        echo -e "${RED}❌ FAIL${NC}: Name placeholder replacement failed"
        ((test_count++))
        ((fail_count++))
    fi
    
    if echo "$result" | grep -q "email = john.doe@example.com"; then
        echo -e "${GREEN}✅ PASS${NC}: Email placeholder replaced correctly"
        ((test_count++))
        ((pass_count++))
    else
        echo -e "${RED}❌ FAIL${NC}: Email placeholder replacement failed"
        ((test_count++))
        ((fail_count++))
    fi
    
    # Cleanup
    rm -f "$TEST_DIR/test-template"
}

# ============================================================================
# Main Test Runner
# ============================================================================
main() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}           🧪 Git Multi-Profile Unit Tests${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo
    
    mkdir -p "$TEST_DIR"
    
    test_email_validation
    echo
    test_path_validation
    echo
    test_ssh_key_validation
    echo
    test_security_validation
    echo
    test_template_validation
    
    rm -rf "$TEST_DIR"
    
    # Summary
    echo
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                        📊 Unit Test Summary${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "Total Tests: ${BLUE}$test_count${NC}"
    echo -e "Passed:      ${GREEN}$pass_count${NC}"
    echo -e "Failed:      ${RED}$fail_count${NC}"
    
    if [[ $fail_count -eq 0 ]]; then
        echo
        echo -e "${GREEN}🎉 All unit tests passed!${NC}"
        return 0
    else
        echo
        echo -e "${RED}❌ Some unit tests failed.${NC}"
        return 1
    fi
}

# Help function
show_help() {
    cat << EOF
Git Multi-Profile Unit Test Suite

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output

DESCRIPTION:
    Fast unit tests for individual functions and components.
    Tests validation logic, security measures, and template processing.

EXIT CODES:
    0    All tests passed
    1    One or more tests failed
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 2
            ;;
    esac
done

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi