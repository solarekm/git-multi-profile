#!/bin/bash

# Git Configuration Validation Script
# Validates Git profile configurations and SSH key setup

set -e

# Colors and emojis
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

CHECK="✅"
WARNING="⚠️ "
ERROR="❌"
INFO="ℹ️ "
GEAR="🔧"

print_header() {
    echo -e "\n${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}           🔍 Git Configuration Validator${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${WARNING}$1${NC}"
}

print_error() {
    echo -e "${RED}${ERROR} $1${NC}"
}

print_info() {
    echo -e "${BLUE}${INFO} $1${NC}"
}

# Validation counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNINGS=0

increment_check() {
    ((TOTAL_CHECKS++))
}

pass_check() {
    ((PASSED_CHECKS++))
    print_success "$1"
}

warn_check() {
    ((WARNINGS++))
    print_warning "$1"
}

fail_check() {
    print_error "$1"
}

# Check if Git is properly configured
check_git_installation() {
    increment_check
    if command -v git &>/dev/null; then
        GIT_VERSION=$(git --version | cut -d' ' -f3)
        pass_check "Git installed (version $GIT_VERSION)"
    else
        fail_check "Git is not installed"
        return 1
    fi

    # Check Git version supports conditional includes (2.13+)
    increment_check
    if git config --help | grep -q "includeIf" 2>/dev/null; then
        pass_check "Git version supports conditional includes"
    else
        fail_check "Git version too old for conditional includes (need 2.13+)"
    fi
}

# Check global Git configuration
check_global_config() {
    echo -e "\n${WHITE}Checking Global Configuration:${NC}"

    increment_check
    if [[ -f ~/.gitconfig ]]; then
        pass_check "Global .gitconfig exists"
    else
        fail_check "Global .gitconfig not found"
        return 1
    fi

    # Check basic configuration
    increment_check
    if git config --global user.name >/dev/null 2>&1; then
        USER_NAME=$(git config --global user.name)
        pass_check "Global user.name set: '$USER_NAME'"
    else
        warn_check "Global user.name not set"
    fi

    increment_check
    if git config --global user.email >/dev/null 2>&1; then
        USER_EMAIL=$(git config --global user.email)
        pass_check "Global user.email set: '$USER_EMAIL'"
    else
        warn_check "Global user.email not set"
    fi
}

# Check conditional includes
check_conditional_includes() {
    echo -e "\n${WHITE}Checking Conditional Includes:${NC}"

    increment_check
    if grep -q "includeIf" ~/.gitconfig; then
        pass_check "Conditional includes found in .gitconfig"

        # List all conditional includes
        echo -e "${CYAN}  Configured profiles:${NC}"
        while IFS= read -r line; do
            if [[ "$line" =~ ^\[includeIf.*gitdir:.*\] ]] && [[ ! "$line" =~ ^# ]]; then
                dir_path=$(echo "$line" | sed 's/.*gitdir://;s/".*//' | sed 's/\].*//')
                # Read next non-empty line for path
                read -r profile_line
                while [[ -z "$profile_line" || "$profile_line" =~ ^[[:space:]]*# ]]; do
                    read -r profile_line
                done
                profile_path=$(echo "$profile_line" | sed 's/.*path[[:space:]]*=[[:space:]]*//' | tr -d '"')
                echo -e "    ${BLUE}Directory:${NC} $dir_path"
                echo -e "    ${BLUE}Profile:${NC} $profile_path"

                # Check if directory exists (expand tilde)
                increment_check
                expanded_dir_path="${dir_path/#\~/$HOME}"
                if [[ -d "$expanded_dir_path" ]]; then
                    pass_check "Directory exists: $dir_path"
                else
                    warn_check "Directory does not exist: $dir_path"
                fi

                # Check if profile file exists (expand tilde)
                increment_check
                expanded_profile_path="${profile_path/#\~/$HOME}"
                if [[ -f "$expanded_profile_path" ]]; then
                    pass_check "Profile file exists: $profile_path"
                else
                    fail_check "Profile file missing: $profile_path"
                fi
                echo ""
            fi
        done <~/.gitconfig
    else
        warn_check "No conditional includes found"
    fi
}

# Check profile configurations
check_profiles() {
    echo -e "\n${WHITE}Checking Profile Configurations:${NC}"

    if [[ -d ~/.config/git/profiles ]]; then
        for profile_file in ~/.config/git/profiles/*; do
            if [[ -f "$profile_file" ]]; then
                profile_name=$(basename "$profile_file")
                echo -e "\n${CYAN}Profile: $profile_name${NC}"

                # Check user.name
                increment_check
                if grep -q "name =" "$profile_file"; then
                    profile_name_val=$(grep "name =" "$profile_file" | head -1 | cut -d'=' -f2 | xargs)
                    pass_check "Name configured: '$profile_name_val'"
                else
                    fail_check "Name not configured in profile"
                fi

                # Check user.email
                increment_check
                if grep -q "email =" "$profile_file"; then
                    profile_email=$(grep "email =" "$profile_file" | head -1 | cut -d'=' -f2 | xargs)
                    pass_check "Email configured: '$profile_email'"

                    # Validate email format
                    increment_check
                    if [[ "$profile_email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                        pass_check "Email format is valid"
                    else
                        warn_check "Email format may be invalid: '$profile_email'"
                    fi
                else
                    fail_check "Email not configured in profile"
                fi

                # Check SSH configuration (only if configured)
                if grep -q "sshCommand" "$profile_file"; then
                    increment_check
                    ssh_key_path=$(grep "sshCommand" "$profile_file" | sed 's/.*-i //;s/ .*//')
                    pass_check "SSH key configured: '$ssh_key_path'"

                    # Check if SSH key exists (expand tilde)
                    increment_check
                    expanded_ssh_key_path="${ssh_key_path/#\~/$HOME}"
                    if [[ -f "$expanded_ssh_key_path" ]]; then
                        pass_check "SSH private key exists: $ssh_key_path"
                    else
                        warn_check "SSH private key not found: $ssh_key_path"
                    fi

                    # Check if SSH public key exists (expand tilde)
                    increment_check
                    if [[ -f "${expanded_ssh_key_path}.pub" ]]; then
                        pass_check "SSH public key exists: ${ssh_key_path}.pub"
                    else
                        warn_check "SSH public key not found: ${ssh_key_path}.pub"
                    fi
                else
                    print_info "No SSH key configured (skipped by user)"
                fi

                # Check GPG signing (only if actually enabled, not commented)
                if grep -q "^[[:space:]]*gpgsign[[:space:]]*=[[:space:]]*true" "$profile_file"; then
                    increment_check
                    if grep -q "^[[:space:]]*signingkey[[:space:]]*=" "$profile_file"; then
                        signing_key=$(grep "^[[:space:]]*signingkey[[:space:]]*=" "$profile_file" | cut -d'=' -f2 | xargs)
                        pass_check "GPG signing enabled with key: $signing_key"
                    else
                        warn_check "GPG signing enabled but no signing key specified"
                    fi
                else
                    print_info "GPG signing not enabled (optional)"
                fi
            fi
        done
    else
        warn_check "No profiles directory found at ~/.config/git/profiles"
    fi
}

# Test profile switching in directories
test_profile_switching() {
    echo -e "\n${WHITE}Testing Profile Switching:${NC}"

    # Find conditional include directories from .gitconfig
    if [[ -f ~/.gitconfig ]] && grep -q "includeIf" ~/.gitconfig; then
        grep "includeIf" ~/.gitconfig | grep -v "^#" | while read -r line; do
            dir_path=$(echo "$line" | sed 's/.*gitdir://;s/".*//' | sed 's/\].*//')
            profile_line=$(grep -A1 "$line" ~/.gitconfig | tail -1)
            profile_path=$(echo "$profile_line" | sed 's/.*path = //' | tr -d '"')

            # Expand tilde for directory testing
            expanded_dir_path="${dir_path/#\~/$HOME}"
            if [[ -d "$expanded_dir_path" ]]; then
                echo -e "\n${CYAN}Testing directory: $dir_path${NC}"

                # Create a temporary test directory
                test_dir="$expanded_dir_path/git-config-test-$$"
                mkdir -p "$test_dir"
                cd "$test_dir"

                # Initialize a git repo to test configuration
                git init >/dev/null 2>&1

                # Test user.name
                increment_check
                current_name=$(git config user.name 2>/dev/null || echo "")
                if [[ -n "$current_name" ]]; then
                    pass_check "Profile active - Name: '$current_name'"
                else
                    fail_check "No name configured in this directory"
                fi

                # Test user.email
                increment_check
                current_email=$(git config user.email 2>/dev/null || echo "")
                if [[ -n "$current_email" ]]; then
                    pass_check "Profile active - Email: '$current_email'"
                else
                    fail_check "No email configured in this directory"
                fi

                # Cleanup
                cd - >/dev/null
                rm -rf "$test_dir"
            fi
        done
    fi
}

# Check SSH connectivity
check_ssh_connectivity() {
    echo -e "\n${WHITE}Checking SSH Connectivity:${NC}"

    # Test common Git hosting services
    services=("github.com" "gitlab.com" "bitbucket.org")

    for service in "${services[@]}"; do
        increment_check
        if ssh -T "git@$service" -o ConnectTimeout=5 -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated\|You've successfully authenticated"; then
            pass_check "SSH connection to $service: OK"
        else
            # Try to determine if it's a key issue or service issue
            if timeout 5 ssh -T "git@$service" -o ConnectTimeout=5 2>&1 | grep -q "Permission denied"; then
                warn_check "SSH connection to $service: Authentication failed (check SSH keys)"
            elif timeout 5 nc -z "$service" 22 2>/dev/null; then
                warn_check "SSH connection to $service: Service reachable but authentication failed"
            else
                print_info "SSH connection to $service: Not tested (service unreachable or not configured)"
            fi
        fi
    done
}

# Generate summary report
generate_summary() {
    echo -e "\n${WHITE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                    VALIDATION SUMMARY${NC}"
    echo -e "${WHITE}════════════════════════════════════════════════════════════════${NC}"

    SUCCESS_RATE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

    echo -e "${CYAN}Total Checks:${NC} $TOTAL_CHECKS"
    echo -e "${GREEN}Passed:${NC} $PASSED_CHECKS"
    echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
    echo -e "${RED}Failed:${NC} $((TOTAL_CHECKS - PASSED_CHECKS))"
    echo -e "${BLUE}Success Rate:${NC} $SUCCESS_RATE%"

    echo ""

    if [[ $SUCCESS_RATE -ge 90 ]]; then
        echo -e "${GREEN}${CHECK} Configuration looks excellent!${NC}"
    elif [[ $SUCCESS_RATE -ge 70 ]]; then
        echo -e "${YELLOW}${WARNING}Configuration is mostly good, but some issues need attention.${NC}"
    else
        echo -e "${RED}${ERROR} Configuration needs significant improvements.${NC}"
    fi

    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}${INFO} Review warnings above for optional improvements.${NC}"
    fi
}

# Main execution
main() {
    print_header

    check_git_installation
    check_global_config
    check_conditional_includes
    check_profiles
    test_profile_switching
    check_ssh_connectivity

    generate_summary
}

# Help function
show_help() {
    echo "Git Configuration Validation Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -q, --quick    Quick validation (skip SSH connectivity tests)"
    echo ""
    echo "This script validates your Git multi-profile configuration."
}

# Command line argument parsing
case "${1:-}" in
    -h | --help)
        show_help
        exit 0
        ;;
    -q | --quick)
        SKIP_SSH=true
        main
        ;;
    "")
        main
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
