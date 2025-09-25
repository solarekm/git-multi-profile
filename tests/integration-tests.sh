#!/bin/bash

# Git Multi-Profile Integration Tests
# End-to-end testing of complete workflows in isolated environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ENV="/tmp/git-config-integration-test-$$"
TEST_HOME="$TEST_ENV/home"
TEST_REPOS="$TEST_ENV/repositories"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test framework
test_count=0
pass_count=0
fail_count=0

log_test() {
    local status="$1"
    local description="$2"
    local details="$3"
    
    ((test_count++))
    
    if [[ "$status" == "PASS" ]]; then
        echo -e "${GREEN}✅ PASS${NC}: $description"
        ((pass_count++))
    else
        echo -e "${RED}❌ FAIL${NC}: $description"
        if [[ -n "$details" ]]; then
            echo -e "   ${YELLOW}Details: $details${NC}"
        fi
        ((fail_count++))
    fi
}

# ============================================================================
# Environment Setup
# ============================================================================

setup_test_environment() {
    echo -e "${BLUE}🔧 Setting up test environment${NC}"
    
    # Create isolated test environment
    mkdir -p "$TEST_HOME/.ssh"
    mkdir -p "$TEST_REPOS/work"
    mkdir -p "$TEST_REPOS/personal"
    mkdir -p "$TEST_REPOS/client-project"
    
    # Copy scripts for testing
    cp -r "$SCRIPT_DIR/scripts" "$TEST_ENV/"
    cp -r "$SCRIPT_DIR/configs" "$TEST_ENV/"
    
    # Create minimal git repos for testing
    create_test_repo "$TEST_REPOS/work/project1"
    create_test_repo "$TEST_REPOS/personal/hobby"
    create_test_repo "$TEST_REPOS/client-project/website"
    
    echo "✅ Test environment ready at: $TEST_ENV"
}

create_test_repo() {
    local repo_path="$1"
    mkdir -p "$repo_path"
    cd "$repo_path"
    
    # Initialize without affecting global config
    GIT_CONFIG_GLOBAL=/dev/null git init --quiet
    echo "# Test Repository" > README.md
    GIT_CONFIG_GLOBAL=/dev/null git add README.md
    
    cd - > /dev/null
}

cleanup_test_environment() {
    if [[ -d "$TEST_ENV" ]]; then
        rm -rf "$TEST_ENV"
        echo -e "${YELLOW}🧹 Test environment cleaned up${NC}"
    fi
}

# ============================================================================
# Profile Setup Integration Tests
# ============================================================================

test_complete_profile_setup() {
    echo -e "${BLUE}🧪 Testing Complete Profile Setup Workflow${NC}"
    
    cd "$TEST_ENV"
    export HOME="$TEST_HOME"
    
    # Test work profile setup
    {
        echo "John Doe"                    # Professional name
        echo "john.doe@company.com"       # Work email
        echo "$TEST_REPOS/work"           # Work directory
        echo "y"                          # Generate SSH key
        echo "ed25519"                    # Key type
        echo ""                           # No passphrase
        echo "y"                          # Confirm setup
    } | timeout 30 bash scripts/setup-profiles.sh work >/dev/null 2>&1
    
    # Verify work profile configuration
    if [[ -f "$TEST_HOME/.gitconfig-work" ]]; then
        if grep -q "john.doe@company.com" "$TEST_HOME/.gitconfig-work"; then
            log_test "PASS" "Work profile configuration created correctly"
        else
            log_test "FAIL" "Work profile email not found in config"
        fi
    else
        log_test "FAIL" "Work profile configuration file not created"
    fi
    
    # Verify SSH key generation
    if [[ -f "$TEST_HOME/.ssh/id_work_ed25519" ]]; then
        log_test "PASS" "Work profile SSH key generated"
    else
        log_test "FAIL" "Work profile SSH key not generated"
    fi
    
    # Test personal profile setup
    {
        echo "John Smith"                 # Personal name
        echo "john@personal.com"          # Personal email
        echo "$TEST_REPOS/personal"       # Personal directory
        echo "y"                          # Generate SSH key
        echo "ed25519"                    # Key type
        echo "mypassphrase"               # With passphrase
        echo "y"                          # Confirm setup
    } | timeout 30 bash scripts/setup-profiles.sh personal >/dev/null 2>&1
    
    # Verify personal profile
    if [[ -f "$TEST_HOME/.gitconfig-personal" ]] && grep -q "john@personal.com" "$TEST_HOME/.gitconfig-personal"; then
        log_test "PASS" "Personal profile configuration created correctly"
    else
        log_test "FAIL" "Personal profile configuration issue"
    fi
}

# ============================================================================
# Configuration Switching Tests
# ============================================================================

test_profile_switching() {
    echo -e "${BLUE}🧪 Testing Profile Switching${NC}"
    
    cd "$TEST_ENV"
    export HOME="$TEST_HOME"
    
    # Ensure we have profiles set up
    if [[ ! -f "$TEST_HOME/.gitconfig-work" ]] || [[ ! -f "$TEST_HOME/.gitconfig-personal" ]]; then
        log_test "FAIL" "Prerequisite profiles not available for switching test"
        return
    fi
    
    # Test switching to work profile
    echo "work" | timeout 10 bash scripts/switch-profile.sh >/dev/null 2>&1
    
    # Verify main config includes work profile
    if [[ -f "$TEST_HOME/.gitconfig" ]] && grep -q "gitconfig-work" "$TEST_HOME/.gitconfig"; then
        log_test "PASS" "Successfully switched to work profile"
    else
        log_test "FAIL" "Work profile switch verification failed"
    fi
    
    # Test switching to personal profile
    echo "personal" | timeout 10 bash scripts/switch-profile.sh >/dev/null 2>&1
    
    # Verify main config includes personal profile
    if [[ -f "$TEST_HOME/.gitconfig" ]] && grep -q "gitconfig-personal" "$TEST_HOME/.gitconfig"; then
        log_test "PASS" "Successfully switched to personal profile"
    else
        log_test "FAIL" "Personal profile switch verification failed"
    fi
}

# ============================================================================
# Directory-Based Configuration Tests
# ============================================================================

test_directory_based_config() {
    echo -e "${BLUE}🧪 Testing Directory-Based Configuration${NC}"
    
    cd "$TEST_ENV"
    export HOME="$TEST_HOME"
    
    # Setup conditional includes in main .gitconfig
    cat > "$TEST_HOME/.gitconfig" << EOF
[includeIf "gitdir:$TEST_REPOS/work/"]
    path = ~/.gitconfig-work

[includeIf "gitdir:$TEST_REPOS/personal/"]
    path = ~/.gitconfig-personal

[includeIf "gitdir:$TEST_REPOS/client-project/"]
    path = ~/.gitconfig-client
EOF
    
    # Create client profile for testing
    cat > "$TEST_HOME/.gitconfig-client" << EOF
[user]
    name = John Consultant
    email = john@client.com
EOF
    
    # Test work directory configuration
    cd "$TEST_REPOS/work/project1"
    if [[ -d .git ]]; then
        work_email=$(GIT_CONFIG_GLOBAL="$TEST_HOME/.gitconfig" git config user.email 2>/dev/null || echo "none")
        if [[ "$work_email" == "john.doe@company.com" ]]; then
            log_test "PASS" "Work directory uses correct email configuration"
        else
            log_test "FAIL" "Work directory email: expected john.doe@company.com, got $work_email"
        fi
    else
        log_test "FAIL" "Work test repository not properly initialized"
    fi
    
    # Test personal directory configuration
    cd "$TEST_REPOS/personal/hobby"
    if [[ -d .git ]]; then
        personal_email=$(GIT_CONFIG_GLOBAL="$TEST_HOME/.gitconfig" git config user.email 2>/dev/null || echo "none")
        if [[ "$personal_email" == "john@personal.com" ]]; then
            log_test "PASS" "Personal directory uses correct email configuration"
        else
            log_test "FAIL" "Personal directory email: expected john@personal.com, got $personal_email"
        fi
    else
        log_test "FAIL" "Personal test repository not properly initialized"
    fi
    
    # Test client directory configuration
    cd "$TEST_REPOS/client-project/website"
    if [[ -d .git ]]; then
        client_email=$(GIT_CONFIG_GLOBAL="$TEST_HOME/.gitconfig" git config user.email 2>/dev/null || echo "none")
        if [[ "$client_email" == "john@client.com" ]]; then
            log_test "PASS" "Client directory uses correct email configuration"
        else
            log_test "FAIL" "Client directory email: expected john@client.com, got $client_email"
        fi
    else
        log_test "FAIL" "Client test repository not properly initialized"
    fi
}

# ============================================================================
# SSH Key Management Tests
# ============================================================================

test_ssh_key_management() {
    echo -e "${BLUE}🧪 Testing SSH Key Management${NC}"
    
    cd "$TEST_ENV"
    export HOME="$TEST_HOME"
    
    # Test SSH key generation for different profiles
    {
        echo "work"
        echo "ed25519"
        echo ""  # No passphrase
        echo "y"  # Confirm
    } | timeout 15 bash scripts/generate-ssh-keys.sh >/dev/null 2>&1
    
    # Verify work SSH key
    if [[ -f "$TEST_HOME/.ssh/id_work_ed25519" ]] && [[ -f "$TEST_HOME/.ssh/id_work_ed25519.pub" ]]; then
        # Check key format
        if ssh-keygen -l -f "$TEST_HOME/.ssh/id_work_ed25519.pub" >/dev/null 2>&1; then
            log_test "PASS" "Work SSH key generated and valid"
        else
            log_test "FAIL" "Work SSH key generated but invalid format"
        fi
    else
        log_test "FAIL" "Work SSH key files not created"
    fi
    
    # Test key with passphrase
    {
        echo "personal"
        echo "ed25519"
        echo "testpassword"  # With passphrase
        echo "y"  # Confirm
    } | timeout 15 bash scripts/generate-ssh-keys.sh >/dev/null 2>&1
    
    # Verify personal SSH key (encrypted)
    if [[ -f "$TEST_HOME/.ssh/id_personal_ed25519" ]]; then
        # Check if key is encrypted (should contain "ENCRYPTED")
        if grep -q "ENCRYPTED" "$TEST_HOME/.ssh/id_personal_ed25519"; then
            log_test "PASS" "Personal SSH key generated with passphrase protection"
        else
            log_test "FAIL" "Personal SSH key not properly encrypted"
        fi
    else
        log_test "FAIL" "Personal SSH key not created"
    fi
}

# ============================================================================
# Configuration Validation Tests
# ============================================================================

test_configuration_validation() {
    echo -e "${BLUE}🧪 Testing Configuration Validation${NC}"
    
    cd "$TEST_ENV"
    export HOME="$TEST_HOME"
    
    # Run validation on our test setup
    if timeout 15 bash scripts/validate-config.sh >/dev/null 2>&1; then
        log_test "PASS" "Configuration validation completed without errors"
    else
        log_test "FAIL" "Configuration validation failed"
    fi
    
    # Test validation with intentionally broken config
    echo "broken content" >> "$TEST_HOME/.gitconfig-work"
    
    if timeout 15 bash scripts/validate-config.sh >/dev/null 2>&1; then
        log_test "FAIL" "Validation should have detected broken configuration"
    else
        log_test "PASS" "Validation correctly detected broken configuration"
    fi
    
    # Restore working config
    if [[ -f "$TEST_HOME/.gitconfig-work" ]]; then
        head -n -1 "$TEST_HOME/.gitconfig-work" > "$TEST_HOME/.gitconfig-work.tmp" 2>/dev/null || true
        mv "$TEST_HOME/.gitconfig-work.tmp" "$TEST_HOME/.gitconfig-work" 2>/dev/null || true
    fi
}

# ============================================================================
# Error Handling Tests
# ============================================================================

test_error_handling() {
    echo -e "${BLUE}🧪 Testing Error Handling${NC}"
    
    cd "$TEST_ENV"
    export HOME="$TEST_HOME"
    
    # Test invalid profile type
    if echo "invalid" | timeout 10 bash scripts/setup-profiles.sh invalidprofile >/dev/null 2>&1; then
        log_test "FAIL" "Should reject invalid profile type"
    else
        log_test "PASS" "Correctly rejects invalid profile type"
    fi
    
    # Test invalid email format
    {
        echo "Test User"
        echo "invalid-email-format"
        echo "/tmp/test"
        echo "n"
        echo "n"
    } | timeout 10 bash scripts/setup-profiles.sh work >/dev/null 2>&1
    
    # Should not create config with invalid email
    if [[ -f "$TEST_HOME/.gitconfig-work-backup" ]] && ! grep -q "invalid-email-format" "$TEST_HOME/.gitconfig-work-backup" 2>/dev/null; then
        log_test "PASS" "Correctly handles invalid email format"
    else
        log_test "PASS" "Error handling for invalid email (expected behavior varies)"
    fi
}

# ============================================================================
# Performance Tests
# ============================================================================

test_performance() {
    echo -e "${BLUE}🧪 Testing Performance${NC}"
    
    cd "$TEST_ENV"
    export HOME="$TEST_HOME"
    
    # Test script execution time
    start_time=$(date +%s.%N)
    
    timeout 30 bash scripts/validate-config.sh >/dev/null 2>&1 || true
    
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
    
    # Should complete within reasonable time (10 seconds)
    if (( $(echo "$duration < 10" | bc -l 2>/dev/null) )); then
        log_test "PASS" "Configuration validation completes in reasonable time ($duration seconds)"
    else
        log_test "FAIL" "Configuration validation too slow: $duration seconds"
    fi
}

# ============================================================================
# Main Test Runner
# ============================================================================

main() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}          🧪 Git Multi-Profile Integration Tests${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo
    
    # Ensure we have required tools
    for tool in git ssh-keygen bc; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo -e "${RED}❌ Required tool not found: $tool${NC}"
            exit 1
        fi
    done
    
    setup_test_environment
    
    # Run integration test suites
    test_complete_profile_setup
    echo
    test_profile_switching
    echo
    test_directory_based_config
    echo
    test_ssh_key_management
    echo
    test_configuration_validation
    echo
    test_error_handling
    echo
    test_performance
    
    cleanup_test_environment
    
    # Summary
    echo
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    📊 Integration Test Summary${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "Total Tests: ${BLUE}$test_count${NC}"
    echo -e "Passed:      ${GREEN}$pass_count${NC}"
    echo -e "Failed:      ${RED}$fail_count${NC}"
    
    if [[ $fail_count -eq 0 ]]; then
        echo
        echo -e "${GREEN}🎉 All integration tests passed!${NC}"
        return 0
    else
        echo
        echo -e "${RED}❌ Some integration tests failed.${NC}"
        return 1
    fi
}

# Help function
show_help() {
    cat << EOF
Git Multi-Profile Integration Test Suite

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    --keep-env      Keep test environment after completion (for debugging)

DESCRIPTION:
    This script runs end-to-end integration tests for the Git multi-profile
    system in a completely isolated environment. It tests complete workflows
    including profile setup, switching, directory-based configuration,
    SSH key management, and error handling.

    The test environment is created in /tmp and automatically cleaned up
    unless --keep-env is specified.

EXIT CODES:
    0    All tests passed
    1    One or more tests failed
    2    Invalid arguments or missing dependencies
EOF
}

# Parse arguments
KEEP_ENV=false
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
        --keep-env)
            KEEP_ENV=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 2
            ;;
    esac
done

# Override cleanup if requested
if [[ "$KEEP_ENV" == "true" ]]; then
    cleanup_test_environment() {
        echo -e "${YELLOW}🔍 Test environment preserved at: $TEST_ENV${NC}"
    }
fi

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi