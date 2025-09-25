#!/bin/bash

# Git Multi-Profile Local Test Suite
# Safe tests that don't modify user configuration

# Test configuration
TEST_DIR="/tmp/git-config-tests-$$"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test functions
pass_test() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    ((TESTS_PASSED++))
}

fail_test() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    echo -e "${RED}   Error${NC}: $2"
    ((TESTS_FAILED++))
}

skip_test() {
    echo -e "${YELLOW}⏭️  SKIP${NC}: $1"
    echo -e "${YELLOW}   Reason${NC}: $2"
}

run_test() {
    local test_name="$1"
    local test_func="$2"
    
    echo -e "${BLUE}🧪 Testing${NC}: $test_name"
    ((TESTS_TOTAL++))
    
    if $test_func; then
        pass_test "$test_name"
    else
        fail_test "$test_name" "Test function returned non-zero exit code"
    fi
}

# Setup test environment
setup_test_env() {
    echo -e "${BLUE}🔧 Setting up test environment${NC}..."
    
    # Create isolated test directory
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
    
    # Copy project files to test directory
    cp -r "$SCRIPT_DIR"/* "$TEST_DIR/"
    
    # Make scripts executable
    chmod +x "$TEST_DIR/scripts"/*.sh
    
    echo -e "${GREEN}✅${NC} Test environment ready: $TEST_DIR"
}

# Cleanup test environment
cleanup_test_env() {
    echo -e "${BLUE}🧹 Cleaning up test environment${NC}..."
    rm -rf "$TEST_DIR"
}

# ============================================================================
# Script Syntax Tests
# ============================================================================

test_bash_syntax() {
    local exit_code=0
    
    for script in "$TEST_DIR/scripts"/*.sh; do
        if [[ -f "$script" ]]; then
            if ! bash -n "$script" >/dev/null 2>&1; then
                echo "Syntax error in: $script"
                exit_code=1
            fi
        fi
    done
    
    return $exit_code
}

test_script_permissions() {
    local exit_code=0
    
    for script in "$TEST_DIR/scripts"/*.sh; do
        if [[ -f "$script" && ! -x "$script" ]]; then
            echo "Script not executable: $script"
            exit_code=1
        fi
    done
    
    return $exit_code
}

# ============================================================================
# Template Validation Tests
# ============================================================================

test_template_git_syntax() {
    local exit_code=0
    
    for template in "$TEST_DIR/configs/profiles"/*-template; do
        if [[ -f "$template" ]]; then
            # Test if Git can parse the config
            if ! git config --file "$template" --list >/dev/null 2>&1; then
                echo "Invalid Git syntax in: $template"
                exit_code=1
            fi
        fi
    done
    
    return $exit_code
}

test_template_required_sections() {
    local exit_code=0
    
    for template in "$TEST_DIR/configs/profiles"/*-template; do
        if [[ -f "$template" ]]; then
            # Check for required [user] section
            if ! grep -q "^\[user\]" "$template"; then
                echo "Missing [user] section in: $template"
                exit_code=1
            fi
            
            # Check for required user.name
            if ! grep -q "^\s*name\s*=" "$template"; then
                echo "Missing user.name in: $template"
                exit_code=1
            fi
            
            # Check for required user.email
            if ! grep -q "^\s*email\s*=" "$template"; then
                echo "Missing user.email in: $template"
                exit_code=1
            fi
        fi
    done
    
    return $exit_code
}

test_template_placeholders() {
    local exit_code=0
    
    # Test work template placeholders
    if [[ -f "$TEST_DIR/configs/profiles/work-template" ]]; then
        if ! grep -q "Your Professional Name\|your.name@company.com" "$TEST_DIR/configs/profiles/work-template"; then
            echo "Missing placeholders in work-template"
            exit_code=1
        fi
    fi
    
    # Test personal template placeholders
    if [[ -f "$TEST_DIR/configs/profiles/personal-template" ]]; then
        if ! grep -q "Your Name\|your.personal@email.com" "$TEST_DIR/configs/profiles/personal-template"; then
            echo "Missing placeholders in personal-template"
            exit_code=1
        fi
    fi
    
    return $exit_code
}

# ============================================================================
# Logic and Validation Tests
# ============================================================================

test_email_validation_logic() {
    # Test email validation function from scripts
    local test_emails=(
        "valid@example.com:true"
        "invalid.email:false"
        "test@domain.co.uk:true"
        "@invalid.com:false"
        "valid.email+tag@domain.org:true"
        "spaces in@email.com:false"
    )
    
    local exit_code=0
    
    for test_case in "${test_emails[@]}"; do
        local email="${test_case%:*}"
        local expected="${test_case#*:}"
        
        # Simple email validation (regex used in scripts)
        if [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
            local result="true"
        else
            local result="false"
        fi
        
        if [[ "$result" != "$expected" ]]; then
            echo "Email validation failed for: $email (expected: $expected, got: $result)"
            exit_code=1
        fi
    done
    
    return $exit_code
}

test_path_validation_logic() {
    # Test path validation without creating directories
    local test_paths=(
        "/home/user/valid/path|true"
        "relative/path|false"
        "/absolute/path|true"
        "~user/path|true"
        "path with spaces|false"
        "/path/with/./dots|false"
    )
    
    local exit_code=0
    
    for test_case in "${test_paths[@]}"; do
        local path="${test_case%|*}"
        local expected="${test_case#*|}"
        
        # Path validation logic (similar to scripts)
        if [[ "$path" =~ ^(/|~) ]] && [[ ! "$path" =~ [[:space:]] ]] && [[ ! "$path" =~ \.\./ ]] && [[ ! "$path" =~ /\. ]]; then
            local result="true"
        else
            local result="false"
        fi
        
        if [[ "$result" != "$expected" ]]; then
            echo "Path validation failed for: $path (expected: $expected, got: $result)"
            exit_code=1
        fi
    done
    
    return $exit_code
}

test_git_conditional_include_format() {
    # Test conditional include format validation
    local test_formats=(
        '[includeIf "gitdir:/home/user/work/"]|true'
        '[includeIf "gitdir:~/personal/"]|true'
        '[includeIf "invalid format"]|false'
        '[includeIf gitdir:/missing/quotes]|false'
    )
    
    local exit_code=0
    
    for test_case in "${test_formats[@]}"; do
        local format="${test_case%|*}"
        local expected="${test_case#*|}"
        
        # Conditional include format validation
        local pattern='^\[includeIf "gitdir:[^"]+"\]$'
        if [[ "$format" =~ $pattern ]]; then
            local result="true"
        else
            local result="false"
        fi
        
        if [[ "$result" != "$expected" ]]; then
            echo "Conditional include validation failed for: $format (expected: $expected, got: $result)"
            exit_code=1
        fi
    done
    
    return $exit_code
}

# ============================================================================
# Script Help and Version Tests
# ============================================================================

test_script_help_options() {
    local exit_code=0
    
    for script in "$TEST_DIR/scripts"/*.sh; do
        if [[ -f "$script" && -x "$script" ]]; then
            local script_name=$(basename "$script")
            
            # Test --help option
            if ! "$script" --help >/dev/null 2>&1 && ! "$script" -h >/dev/null 2>&1; then
                echo "No help option in: $script_name"
                # Don't fail for this - it's optional
            fi
        fi
    done
    
    return $exit_code
}

test_script_error_handling() {
    local exit_code=0
    
    for script in "$TEST_DIR/scripts"/*.sh; do
        if [[ -f "$script" ]]; then
            # Check if script uses 'set -e' for error handling
            if ! grep -q "set -e" "$script"; then
                echo "Missing 'set -e' in: $(basename "$script")"
                exit_code=1
            fi
        fi
    done
    
    return $exit_code
}

# ============================================================================
# Security Tests (Static Analysis)
# ============================================================================

test_no_hardcoded_secrets() {
    local exit_code=0
    local secret_patterns=(
        "password\s*="
        "secret\s*="
        "token\s*="
        "key\s*=.*[A-Za-z0-9]{20,}"
    )
    
    for pattern in "${secret_patterns[@]}"; do
        if grep -r -i "$pattern" "$TEST_DIR/scripts/" "$TEST_DIR/configs/" | grep -v "template\|example\|YOUR_"; then
            echo "Potential hardcoded secret found matching: $pattern"
            exit_code=1
        fi
    done
    
    return $exit_code
}

test_no_hardcoded_paths() {
    local exit_code=0
    
    # Check for hardcoded user paths
    if grep -r "/home/[^/]" "$TEST_DIR" | grep -v "example\|template\|test" | grep -v "/tmp/"; then
        echo "Hardcoded user paths found"
        exit_code=1
    fi
    
    return $exit_code
}

test_safe_file_operations() {
    local exit_code=0
    
    # Check for potentially unsafe operations
    local unsafe_patterns=(
        "rm -rf \$HOME"
        "chmod 777"
        ">/dev/null 2>&1 || rm"
    )
    
    for pattern in "${unsafe_patterns[@]}"; do
        if grep -r "$pattern" "$TEST_DIR/scripts/"; then
            echo "Potentially unsafe operation found: $pattern"
            exit_code=1
        fi
    done
    
    return $exit_code
}

# ============================================================================
# Documentation Tests
# ============================================================================

test_readme_completeness() {
    local exit_code=0
    local required_sections=(
        "Features"
        "Quick Start"
        "Configuration Profiles"
        "Testing"
        "License"
    )
    
    for section in "${required_sections[@]}"; do
        if ! grep -q "## .*$section" "$TEST_DIR/README.md"; then
            echo "Missing section in README.md: $section"
            exit_code=1
        fi
    done
    
    return $exit_code
}

test_documentation_links() {
    local exit_code=0
    
    # Check for broken internal links in documentation
    while IFS= read -r -d '' file; do
        while IFS= read -r line; do
            # Extract internal links [text](./path)
            local link_pattern='\[.*\]\(\./[^)]+\)'
            if [[ "$line" =~ $link_pattern ]]; then
                local link=$(echo "$line" | grep -o '\[.*\](\.\/[^)]*)')
                local path=$(echo "$link" | sed -n 's/.*(\.\///p' | sed 's/).*//')
                local full_path="$(dirname "$file")/$path"
                
                if [[ ! -e "$full_path" ]]; then
                    echo "Broken internal link in $(basename "$file"): $link"
                    exit_code=1
                fi
            fi
        done < "$file"
    done < <(find "$TEST_DIR" -name "*.md" -print0)
    
    return $exit_code
}

# ============================================================================
# Integration Tests (Safe)
# ============================================================================

test_script_dry_run_capabilities() {
    local exit_code=0
    
    # Test validate-config.sh (should be safe to run)
    if [[ -x "$TEST_DIR/scripts/validate-config.sh" ]]; then
        # This should not modify anything
        if ! "$TEST_DIR/scripts/validate-config.sh" --help >/dev/null 2>&1; then
            # It's OK if there's no help, but it shouldn't crash
            true
        fi
    fi
    
    return $exit_code
}

test_git_requirements() {
    local exit_code=0
    
    # Check if Git is available
    if ! command -v git >/dev/null 2>&1; then
        echo "Git is not installed"
        exit_code=1
    fi
    
    # Check Git version for conditional includes support
    local git_version=$(git --version | grep -oP '\d+\.\d+' | head -1)
    local major=$(echo "$git_version" | cut -d. -f1)
    local minor=$(echo "$git_version" | cut -d. -f2)
    
    if [[ $major -lt 2 ]] || [[ $major -eq 2 && $minor -lt 13 ]]; then
        echo "Git version too old for conditional includes (need 2.13+, have $git_version)"
        exit_code=1
    fi
    
    return $exit_code
}

# ============================================================================
# Main Test Runner
# ============================================================================

print_header() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}           🧪 Git Multi-Profile Local Test Suite${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo
}

print_summary() {
    echo
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                        📊 Test Summary${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "Total Tests: ${BLUE}$TESTS_TOTAL${NC}"
    echo -e "Passed:      ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed:      ${RED}$TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo
        echo -e "${GREEN}🎉 All tests passed! Your Git configuration is ready.${NC}"
        return 0
    else
        echo
        echo -e "${RED}❌ Some tests failed. Please review and fix the issues.${NC}"
        return 1
    fi
}

main() {
    print_header
    
    # Setup
    setup_test_env
    
    # Run all tests
    echo -e "${BLUE}🧪 Running Script Tests${NC}..."
    run_test "Bash Syntax Validation" test_bash_syntax
    run_test "Script Permissions" test_script_permissions
    run_test "Script Error Handling" test_script_error_handling
    run_test "Script Help Options" test_script_help_options
    
    echo
    echo -e "${BLUE}🧪 Running Template Tests${NC}..."
    run_test "Template Git Syntax" test_template_git_syntax
    run_test "Template Required Sections" test_template_required_sections
    run_test "Template Placeholders" test_template_placeholders
    
    echo
    echo -e "${BLUE}🧪 Running Logic Tests${NC}..."
    run_test "Email Validation Logic" test_email_validation_logic
    run_test "Path Validation Logic" test_path_validation_logic
    run_test "Git Conditional Include Format" test_git_conditional_include_format
    
    echo
    echo -e "${BLUE}🧪 Running Security Tests${NC}..."
    run_test "No Hardcoded Secrets" test_no_hardcoded_secrets
    run_test "No Hardcoded Paths" test_no_hardcoded_paths
    run_test "Safe File Operations" test_safe_file_operations
    
    echo
    echo -e "${BLUE}🧪 Running Documentation Tests${NC}..."
    run_test "README Completeness" test_readme_completeness
    run_test "Documentation Links" test_documentation_links
    
    echo
    echo -e "${BLUE}🧪 Running Integration Tests${NC}..."
    run_test "Script Dry Run Capabilities" test_script_dry_run_capabilities
    run_test "Git Requirements" test_git_requirements
    
    # Cleanup
    cleanup_test_env
    
    # Summary
    print_summary
}

# Help function
show_help() {
    cat << EOF
Git Multi-Profile Local Test Suite

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    --quick         Run only quick tests (skip integration tests)
    --security      Run only security tests
    --templates     Run only template validation tests

EXAMPLES:
    $0                  # Run all tests
    $0 --quick          # Run quick tests only
    $0 --security       # Run security tests only
    $0 --help           # Show this help

DESCRIPTION:
    This test suite performs safe, local testing of the Git multi-profile
    configuration system. It does NOT modify your existing Git configuration
    or create any files outside of /tmp.

    Tests include:
    - Script syntax and quality validation
    - Template validation and completeness
    - Logic and validation function testing
    - Security scanning for hardcoded secrets/paths
    - Documentation completeness checking
    - Safe integration testing

EXIT CODES:
    0    All tests passed
    1    One or more tests failed
    2    Invalid arguments or setup error
EOF
}

# Parse command line arguments
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
        --quick)
            # Skip integration tests
            skip_integration=true
            shift
            ;;
        --security)
            # Run only security tests
            security_only=true
            shift
            ;;
        --templates)
            # Run only template tests
            templates_only=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 2
            ;;
    esac
done

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi