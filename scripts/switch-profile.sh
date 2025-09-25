#!/bin/bash

# Git Profile Switching Utility
# Manual profile switching for testing and one-off operations

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
    echo -e "${WHITE}           🔄 Git Profile Switcher${NC}"
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

# List available profiles
list_profiles() {
    echo -e "${WHITE}Available Profiles:${NC}"

    if [[ ! -d ~/.config/git/profiles ]]; then
        print_error "No profiles directory found at ~/.config/git/profiles"
        exit 1
    fi

    local profiles_found=false
    for profile in ~/.config/git/profiles/*; do
        if [[ -f "$profile" ]]; then
            profiles_found=true
            profile_name=$(basename "$profile")

            # Extract name and email from profile
            local name
            name=$(grep "name =" "$profile" 2>/dev/null | head -1 | cut -d'=' -f2 | xargs || echo "Not set")
            local email
            email=$(grep "email =" "$profile" 2>/dev/null | head -1 | cut -d'=' -f2 | xargs || echo "Not set")

            echo -e "  ${CYAN}$profile_name${NC}"
            echo -e "    Name:  $name"
            echo -e "    Email: $email"
            echo ""
        fi
    done

    if [[ "$profiles_found" == false ]]; then
        print_warning "No profiles found in ~/.config/git/profiles"
        print_info "Run setup-profiles.sh to create profiles"
        exit 1
    fi
}

# Show current profile
show_current_profile() {
    echo -e "${WHITE}Current Git Configuration:${NC}"

    local current_name
    current_name=$(git config user.name 2>/dev/null || echo "Not set")
    local current_email
    current_email=$(git config user.email 2>/dev/null || echo "Not set")
    local current_ssh
    current_ssh=$(git config core.sshCommand 2>/dev/null || echo "Default")
    local current_signing
    current_signing=$(git config commit.gpgsign 2>/dev/null || echo "false")

    echo -e "  ${CYAN}Name:${NC} $current_name"
    echo -e "  ${CYAN}Email:${NC} $current_email"
    echo -e "  ${CYAN}SSH Command:${NC} $current_ssh"
    echo -e "  ${CYAN}GPG Signing:${NC} $current_signing"
    echo ""

    # Try to determine which profile is active based on directory
    local current_dir
    current_dir=$(pwd)
    if [[ -f ~/.gitconfig ]] && grep -q "includeIf" ~/.gitconfig; then
        echo -e "${WHITE}Profile Detection (based on directory):${NC}"
        while IFS= read -r line; do
            if [[ "$line" =~ \[includeIf.*gitdir: ]]; then
                local dir_pattern
                dir_pattern=$(echo "$line" | sed 's/.*gitdir://;s/\].*//')
                local profile_line
                profile_line=$(grep -A1 "$line" ~/.gitconfig | tail -1)
                local profile_path
                profile_path=${profile_line#*path = }
                local profile_name
                profile_name=$(basename "$profile_path")

                # Expand tilde in directory pattern
                dir_pattern="${dir_pattern/#\~/$HOME}"

                if [[ "$current_dir"/ == "$dir_pattern"* ]]; then
                    print_success "Active profile: $profile_name (matches directory: $dir_pattern)"
                    return
                fi
            fi
        done <~/.gitconfig
        print_info "No profile matches current directory: $current_dir"
    else
        print_info "No conditional includes configured"
    fi
}

# Apply profile globally (temporary override)
apply_profile() {
    local profile_name=$1
    local profile_path="$HOME/.config/git/profiles/$profile_name"

    if [[ ! -f "$profile_path" ]]; then
        print_error "Profile not found: $profile_path"
        exit 1
    fi

    echo -e "${WHITE}Applying profile '$profile_name' globally...${NC}"

    # Extract configuration from profile
    local name
    name=$(grep "name =" "$profile_path" | head -1 | cut -d'=' -f2 | xargs)
    local email
    email=$(grep "email =" "$profile_path" | head -1 | cut -d'=' -f2 | xargs)
    local ssh_command
    ssh_command=$(grep "sshCommand =" "$profile_path" | head -1 | cut -d'=' -f2 | xargs)
    local signing_key
    signing_key=$(grep "signingkey =" "$profile_path" | head -1 | cut -d'=' -f2 | xargs)
    local gpg_sign
    gpg_sign=$(grep "gpgsign =" "$profile_path" | head -1 | cut -d'=' -f2 | xargs)

    # Apply configuration globally
    if [[ -n "$name" ]]; then
        git config --global user.name "$name"
        print_success "Set global name: $name"
    fi

    if [[ -n "$email" ]]; then
        git config --global user.email "$email"
        print_success "Set global email: $email"
    fi

    if [[ -n "$ssh_command" ]]; then
        git config --global core.sshCommand "$ssh_command"
        print_success "Set global SSH command: $ssh_command"
    fi

    if [[ -n "$signing_key" ]]; then
        git config --global user.signingkey "$signing_key"
        print_success "Set global signing key: $signing_key"
    fi

    if [[ -n "$gpg_sign" ]]; then
        git config --global commit.gpgsign "$gpg_sign"
        print_success "Set global GPG signing: $gpg_sign"
    fi

    echo ""
    print_success "Profile '$profile_name' applied globally"
    print_warning "This is a temporary override. Profile-specific directories will still use their configured profiles."
}

# Reset to default configuration
reset_to_default() {
    echo -e "${WHITE}Resetting to default configuration...${NC}"

    # Remove profile-specific settings
    git config --global --unset core.sshCommand 2>/dev/null || true
    git config --global --unset user.signingkey 2>/dev/null || true
    git config --global --unset commit.gpgsign 2>/dev/null || true

    print_success "Profile-specific settings removed"
    print_info "Global user.name and user.email remain as fallback defaults"
    print_info "Directory-based profiles will still work via conditional includes"
}

# Interactive profile selection
interactive_select() {
    list_profiles

    echo -e "${WHITE}Select a profile to apply globally:${NC}"

    local profiles
    mapfile -t profiles < <(ls ~/.config/git/profiles/ 2>/dev/null)
    if [[ ${#profiles[@]} -eq 0 ]]; then
        print_error "No profiles found"
        exit 1
    fi

    for i in "${!profiles[@]}"; do
        echo "$((i + 1))) ${profiles[i]}"
    done
    echo "$((${#profiles[@]} + 1))) Reset to default"
    echo "$((${#profiles[@]} + 2))) Cancel"

    echo ""
    read -r -p "Choose an option: " choice

    if [[ "$choice" -ge 1 && "$choice" -le "${#profiles[@]}" ]]; then
        selected_profile="${profiles[$((choice - 1))]}"
        apply_profile "$selected_profile"
    elif [[ "$choice" -eq $((${#profiles[@]} + 1)) ]]; then
        reset_to_default
    elif [[ "$choice" -eq $((${#profiles[@]} + 2)) ]]; then
        print_info "Operation cancelled"
    else
        print_error "Invalid selection"
        exit 1
    fi
}

# Test profile in current directory
test_profile() {
    echo -e "${WHITE}Testing profile in current directory...${NC}"

    local current_dir
    current_dir=$(pwd)

    # Initialize a temporary git repo if not in one
    local temp_repo=false
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        print_info "Creating temporary git repository for testing..."
        git init >/dev/null 2>&1
        temp_repo=true
    fi

    # Show effective configuration
    echo -e "${CYAN}Effective Git configuration in $(pwd):${NC}"
    echo -e "  Name: $(git config user.name 2>/dev/null || echo 'Not set')"
    echo -e "  Email: $(git config user.email 2>/dev/null || echo 'Not set')"
    echo -e "  SSH Command: $(git config core.sshCommand 2>/dev/null || echo 'Default')"
    echo -e "  GPG Signing: $(git config commit.gpgsign 2>/dev/null || echo 'false')"

    # Cleanup temporary repo
    if [[ "$temp_repo" == true ]]; then
        rm -rf .git
        print_info "Temporary git repository removed"
    fi
}

# Show help
show_help() {
    echo "Git Profile Switcher"
    echo ""
    echo "Usage: $0 [OPTIONS] [PROFILE_NAME]"
    echo ""
    echo "Options:"
    echo "  -l, --list         List available profiles"
    echo "  -s, --show         Show current configuration"
    echo "  -t, --test         Test profile in current directory"
    echo "  -r, --reset        Reset to default configuration"
    echo "  -i, --interactive  Interactive profile selection"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Arguments:"
    echo "  PROFILE_NAME       Apply specific profile globally"
    echo ""
    echo "Examples:"
    echo "  $0 --list                 # List all profiles"
    echo "  $0 --show                 # Show current config"
    echo "  $0 work                   # Apply work profile globally"
    echo "  $0 --reset               # Reset to defaults"
    echo "  $0 --interactive         # Interactive selection"
}

# Main execution
main() {
    case "${1:-}" in
        -l | --list)
            print_header
            list_profiles
            ;;
        -s | --show)
            print_header
            show_current_profile
            ;;
        -t | --test)
            print_header
            test_profile
            ;;
        -r | --reset)
            print_header
            reset_to_default
            ;;
        -i | --interactive)
            print_header
            interactive_select
            ;;
        -h | --help)
            show_help
            ;;
        "")
            print_header
            show_current_profile
            echo ""
            interactive_select
            ;;
        *)
            if [[ "$1" =~ ^- ]]; then
                echo "Unknown option: $1"
                show_help
                exit 1
            else
                # Treat as profile name
                print_header
                apply_profile "$1"
            fi
            ;;
    esac
}

main "$@"
