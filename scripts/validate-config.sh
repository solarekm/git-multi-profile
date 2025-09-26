#!/bin/bash

# Git Configuration Validation Script
# Validates Git profile configurations and SSH key setup

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

# Skip SSH connectivity tests if requested
SKIP_SSH=false

# Extract SSH hosts from Git configuration
extract_ssh_hosts_from_config() {
    local ssh_hosts=()

    # Since we use core.sshCommand approach, detect hosts from existing SSH keys and common Git services
    # Look for profile-specific SSH keys that indicate which services are used
    if [[ -d ~/.ssh ]]; then
        for key_file in ~/.ssh/id_*; do
            [[ -f "$key_file" ]] || continue
            [[ "$key_file" == *".pub" ]] && continue

            # Extract profile name from key filename
            local key_name
            key_name=$(basename "$key_file")
            if [[ "$key_name" =~ _([^_]+)$ ]]; then
                local profile="${BASH_REMATCH[1]}"
                # Common Git hosting services - test these by default
                ssh_hosts+=("github.com")
                ssh_hosts+=("gitlab.com")
            fi
        done
    fi

    # Also check if there are any URL rewrites in Git config (legacy)
    if [[ -f ~/.gitconfig ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ git@([^:]+): ]]; then
                local host="${BASH_REMATCH[1]}"
                # Resolve SSH config aliases to real hosts
                local resolved_host
                resolved_host=$(resolve_ssh_host "$host")
                ssh_hosts+=("$resolved_host")
            fi
        done <~/.gitconfig
    fi

    # Check profile files for any URL rewrites (legacy)
    if [[ -d ~/.config/git/profiles ]]; then
        for profile_file in ~/.config/git/profiles/*; do
            # Skip template files and non-regular files
            if [[ -f "$profile_file" && ! "$(basename "$profile_file")" =~ -template$ ]]; then
                while IFS= read -r line; do
                    if [[ "$line" =~ git@([^:]+): ]]; then
                        local host="${BASH_REMATCH[1]}"
                        local resolved_host
                        resolved_host=$(resolve_ssh_host "$host")
                        ssh_hosts+=("$resolved_host")
                    fi
                done <"$profile_file"
            fi
        done
    fi

    # Remove duplicates and return
    printf '%s\n' "${ssh_hosts[@]}" | sort -u
}

# Resolve SSH host aliases to real hostnames
resolve_ssh_host() {
    local host="$1"

    # Check if SSH config exists and has an alias for this host
    if [[ -f ~/.ssh/config ]]; then
        local real_host
        real_host=$(ssh -G "$host" 2>/dev/null | grep "^hostname " | cut -d' ' -f2)
        if [[ -n "$real_host" && "$real_host" != "$host" ]]; then
            echo "$real_host"
            return
        fi
    fi

    # If it looks like a custom alias (contains dash/underscore after domain), warn about it
    if [[ "$host" =~ ^[a-z0-9.-]+\.[a-z]{2,}-[a-zA-Z0-9_-]+$ ]] || [[ "$host" =~ -[a-zA-Z0-9_-]+$ ]]; then
        # This looks like a custom SSH alias, check if it resolves
        if ! nslookup "$host" &>/dev/null && ! host "$host" &>/dev/null; then
            print_warning "Host '$host' appears to be an SSH alias but doesn't resolve. Check ~/.ssh/config"
            # Try to extract base domain
            local base_domain
            base_domain=$(echo "$host" | sed 's/-[^.]*$//')
            if [[ "$base_domain" =~ \.(com|org|net|io)$ ]]; then
                echo "$base_domain"
                return
            fi
        fi
    fi

    echo "$host"
}

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
    echo -e "${WHITE}Checking Git Installation:${NC}"

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
    local git_major git_minor
    git_major=$(echo "$GIT_VERSION" | cut -d. -f1)
    git_minor=$(echo "$GIT_VERSION" | cut -d. -f2)

    if [[ $git_major -gt 2 ]] || [[ $git_major -eq 2 && $git_minor -ge 13 ]]; then
        pass_check "Git version supports conditional includes"
    else
        fail_check "Git version too old for conditional includes (need 2.13+, have $GIT_VERSION)"
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
    if grep -q "includeIf" ~/.gitconfig 2>/dev/null; then
        pass_check "Conditional includes found in .gitconfig"

        # List all conditional includes
        echo -e "${CYAN}  Configured profiles:${NC}"

        # Read conditional includes properly
        local in_include_section=false
        local current_dir=""
        local current_profile=""

        while IFS= read -r line; do
            # Remove leading/trailing whitespace
            line=$(echo "$line" | xargs)

            if [[ "$line" =~ ^\[includeIf.*gitdir: ]]; then
                current_dir=$(echo "$line" | sed 's/.*gitdir://;s/"].*//;s/\].*//')
                in_include_section=true
            elif [[ "$in_include_section" == true && "$line" =~ ^path[[:space:]]*= ]]; then
                current_profile=$(echo "$line" | sed 's/.*path[[:space:]]*=[[:space:]]*//' | tr -d '"')

                echo -e "    ${BLUE}Directory:${NC} $current_dir"
                echo -e "    ${BLUE}Profile:${NC} $current_profile"

                # Check if directory exists (expand tilde)
                increment_check
                local expanded_dir_path="${current_dir/#\~/$HOME}"
                if [[ -d "$expanded_dir_path" ]]; then
                    pass_check "Directory exists: $current_dir"
                else
                    warn_check "Directory does not exist: $current_dir"
                fi

                # Check if profile file exists (expand tilde)
                increment_check
                local expanded_profile_path="${current_profile/#\~/$HOME}"
                if [[ -f "$expanded_profile_path" ]]; then
                    pass_check "Profile file exists: $current_profile"
                else
                    fail_check "Profile file missing: $current_profile"
                fi
                echo ""

                in_include_section=false
            elif [[ "$line" =~ ^\[ ]]; then
                in_include_section=false
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
                if grep -q "^[[:space:]]*name[[:space:]]*=" "$profile_file"; then
                    local profile_name_val
                    profile_name_val=$(grep "^[[:space:]]*name[[:space:]]*=" "$profile_file" | head -1 | cut -d'=' -f2 | xargs)
                    pass_check "Name configured: '$profile_name_val'"
                else
                    fail_check "Name not configured in profile"
                fi

                # Check user.email
                increment_check
                if grep -q "^[[:space:]]*email[[:space:]]*=" "$profile_file"; then
                    local profile_email
                    profile_email=$(grep "^[[:space:]]*email[[:space:]]*=" "$profile_file" | head -1 | cut -d'=' -f2 | xargs)
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
                local has_ssh_config=false
                if grep -q "^[[:space:]]*sshCommand" "$profile_file"; then
                    increment_check
                    local ssh_key_path
                    ssh_key_path=$(grep "^[[:space:]]*sshCommand" "$profile_file" | sed 's/.*-i //;s/ .*//' | head -1)
                    pass_check "SSH key configured: '$ssh_key_path'"
                    has_ssh_config=true

                    # Check if SSH key exists (expand tilde)
                    increment_check
                    local expanded_ssh_key_path="${ssh_key_path/#\~/$HOME}"
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
                fi

                # Check for URL rewrites (alternative SSH configuration)
                if grep -q "^\[url.*git@.*:\]" "$profile_file"; then
                    if [[ "$has_ssh_config" == false ]]; then
                        increment_check
                        pass_check "SSH URL rewrite configured (uses global SSH config)"
                        has_ssh_config=true
                    fi
                fi

                if [[ "$has_ssh_config" == false ]]; then
                    print_info "No SSH configuration found in profile (will use global SSH settings)"
                fi

                # Check GPG signing (only if actually enabled, not commented)
                if grep -q "^[[:space:]]*gpgsign[[:space:]]*=[[:space:]]*true" "$profile_file"; then
                    increment_check
                    if grep -q "^[[:space:]]*signingkey[[:space:]]*=" "$profile_file"; then
                        local signing_key
                        signing_key=$(grep "^[[:space:]]*signingkey[[:space:]]*=" "$profile_file" | head -1 | cut -d'=' -f2 | xargs)
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
    if [[ -f ~/.gitconfig ]] && grep -q "includeIf" ~/.gitconfig 2>/dev/null; then
        local in_include_section=false
        local current_dir=""
        local current_profile=""

        while IFS= read -r line; do
            line=$(echo "$line" | xargs)

            if [[ "$line" =~ ^\[includeIf.*gitdir: ]]; then
                current_dir=$(echo "$line" | sed 's/.*gitdir://;s/"].*//;s/\].*//')
                in_include_section=true
            elif [[ "$in_include_section" == true && "$line" =~ ^path[[:space:]]*= ]]; then
                current_profile=$(echo "$line" | sed 's/.*path[[:space:]]*=[[:space:]]*//' | tr -d '"')

                # Expand tilde for directory testing
                local expanded_dir_path="${current_dir/#\~/$HOME}"
                if [[ -d "$expanded_dir_path" ]]; then
                    echo -e "\n${CYAN}Testing directory: $current_dir${NC}"

                    # Create a temporary test directory
                    local test_dir="$expanded_dir_path/git-config-test-$$"
                    mkdir -p "$test_dir"

                    (
                        cd "$test_dir" || exit 1

                        # Initialize a git repo to test configuration
                        git init >/dev/null 2>&1

                        # Test user.name
                        increment_check
                        local current_name
                        current_name=$(git config user.name 2>/dev/null || echo "")
                        if [[ -n "$current_name" ]]; then
                            pass_check "Profile active - Name: '$current_name'"
                        else
                            fail_check "No name configured in this directory"
                        fi

                        # Test user.email
                        increment_check
                        local current_email
                        current_email=$(git config user.email 2>/dev/null || echo "")
                        if [[ -n "$current_email" ]]; then
                            pass_check "Profile active - Email: '$current_email'"
                        else
                            fail_check "No email configured in this directory"
                        fi
                    )

                    # Cleanup
                    rm -rf "$test_dir" 2>/dev/null || true
                fi

                in_include_section=false
            elif [[ "$line" =~ ^\[ ]]; then
                in_include_section=false
            fi
        done <~/.gitconfig
    fi
}

# Check SSH connectivity
check_ssh_connectivity() {
    if [[ "$SKIP_SSH" == true ]]; then
        print_info "SSH connectivity tests skipped (--quick mode)"
        return
    fi

    echo -e "\n${WHITE}Checking SSH Connectivity:${NC}"

    # Get SSH hosts from configuration
    local ssh_hosts
    readarray -t ssh_hosts < <(extract_ssh_hosts_from_config)

    if [[ ${#ssh_hosts[@]} -eq 0 ]]; then
        print_info "No SSH hosts configured in Git profiles - skipping SSH connectivity tests"
        return
    fi

    echo -e "${CYAN}  Testing SSH connectivity for configured hosts:${NC}"

    for service in "${ssh_hosts[@]}"; do
        [[ -z "$service" ]] && continue

        echo -e "    ${BLUE}Testing:${NC} $service"
        increment_check

        # Quick timeout test
        if timeout 5 ssh -T "git@$service" -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes 2>&1 | grep -q "successfully authenticated\|You've successfully authenticated"; then
            pass_check "SSH connection to $service: OK"
        else
            # Check if it's a key issue or connectivity issue
            local ssh_output
            ssh_output=$(timeout 5 ssh -T "git@$service" -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes 2>&1 || true)

            if echo "$ssh_output" | grep -q "Permission denied"; then
                warn_check "SSH connection to $service: Authentication failed (check SSH keys)"
            elif timeout 3 nc -z "$service" 22 2>/dev/null; then
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

    local SUCCESS_RATE=0
    if [[ $TOTAL_CHECKS -gt 0 ]]; then
        SUCCESS_RATE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    fi

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
