#!/bin/bash

# 🔐 Git Credential Manager WSL Setup Script
# Automatyczna instalacja i konfiguracja GCM dla WSL (bez instalacji na Windows)

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m' # No Color

# Icons
readonly CHECK='✅'
readonly ERROR='❌'
readonly WARNING='⚠️'
readonly INFO='ℹ️'
readonly ROCKET='🚀'

# Variables
GCM_VERSION=""
GCM_PATH=""
PROFILES_DIR="$HOME/.config/git/profiles"
DRY_RUN=false
SKIP_INSTALL=false

# Print functions
print_header() {
    echo -e "\n${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}           ${ROCKET} Git Credential Manager WSL Setup${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${WARNING} $1${NC}"
}

print_error() {
    echo -e "${RED}${ERROR} $1${NC}"
}

print_info() {
    echo -e "${BLUE}${INFO} $1${NC}"
}

print_step() {
    echo -e "\n${WHITE}$1${NC}"
}

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Automatycznie instaluje i konfiguruje Git Credential Manager dla WSL"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -d, --dry-run       Show what would be done without making changes"
    echo "  -s, --skip-install  Skip GCM installation (assume already installed)"
    echo "  -v, --version VER   Install specific GCM version (e.g., 2.4.1)"
    echo ""
    echo "Examples:"
    echo "  $0                  # Install and configure GCM"
    echo "  $0 --dry-run        # Preview changes without applying"
    echo "  $0 --skip-install   # Only configure profiles (GCM already installed)"
}

# Check if running in WSL
check_wsl() {
    if ! grep -qi microsoft /proc/version 2>/dev/null; then
        print_error "This script is designed for WSL (Windows Subsystem for Linux)"
        print_info "Detected environment: $(uname -a)"
        exit 1
    fi
    print_success "WSL environment detected"
}

# Get latest GCM version from GitHub
get_latest_gcm_version() {
    print_info "Checking latest Git Credential Manager version..."
    
    if command -v curl >/dev/null 2>&1; then
        GCM_VERSION=$(curl -sL https://api.github.com/repos/GitCredentialManager/git-credential-manager/releases/latest | grep '"tag_name"' | sed 's/.*"tag_name": "v\?\([^"]*\)".*/\1/')
    elif command -v wget >/dev/null 2>&1; then
        GCM_VERSION=$(wget -qO- --max-redirect=5 https://api.github.com/repos/GitCredentialManager/git-credential-manager/releases/latest | grep '"tag_name"' | sed 's/.*"tag_name": "v\?\([^"]*\)".*/\1/')
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi

    if [[ -z "$GCM_VERSION" ]]; then
        print_warning "Could not fetch latest version. Using default: 2.4.1"
        GCM_VERSION="2.4.1"
    fi

    print_success "Latest GCM version: $GCM_VERSION"
}

# Check if GCM is already installed
check_gcm_installation() {
    if command -v git-credential-manager >/dev/null 2>&1; then
        GCM_PATH=$(which git-credential-manager)
        local installed_version
        installed_version=$(git-credential-manager --version 2>/dev/null | head -1 || echo "unknown")
        print_success "Git Credential Manager already installed: $GCM_PATH"
        print_info "Installed version: $installed_version"
        return 0
    else
        print_warning "Git Credential Manager not found"
        return 1
    fi
}

# Install Git Credential Manager
install_gcm() {
    if [[ "$SKIP_INSTALL" == true ]]; then
        print_info "Skipping GCM installation as requested"
        if ! check_gcm_installation; then
            print_error "GCM not found but --skip-install specified"
            exit 1
        fi
        return 0
    fi

    if check_gcm_installation; then
        echo -e "\n${YELLOW}Git Credential Manager is already installed.${NC}"
        read -p "Do you want to reinstall? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Using existing installation"
            return 0
        fi
    fi

    print_step "Installing Git Credential Manager v$GCM_VERSION..."

    local deb_file="gcm-linux_amd64.${GCM_VERSION}.deb"
    local download_url="https://github.com/GitCredentialManager/git-credential-manager/releases/download/v${GCM_VERSION}/${deb_file}"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would download: $download_url"
        print_info "[DRY RUN] Would install: $deb_file"
        GCM_PATH="/usr/local/bin/git-credential-manager"
        return 0
    fi

    # Download GCM
    print_info "Downloading GCM from: $download_url"
    cd /tmp
    if command -v curl >/dev/null 2>&1; then
        curl -LO "$download_url"
    elif command -v wget >/dev/null 2>&1; then
        wget "$download_url"
    fi

    if [[ ! -f "$deb_file" ]]; then
        print_error "Failed to download GCM package"
        exit 1
    fi

    # Install package
    print_info "Installing GCM package..."
    sudo dpkg -i "$deb_file" || {
        print_warning "dpkg failed, trying to fix dependencies..."
        sudo apt-get update
        sudo apt-get install -f -y
        sudo dpkg -i "$deb_file"
    }

    # Verify installation
    if check_gcm_installation; then
        print_success "Git Credential Manager installed successfully"
        rm -f "$deb_file"
    else
        print_error "GCM installation verification failed"
        exit 1
    fi
}

# Configure GCM global settings for WSL
configure_gcm_global() {
    print_step "Configuring GCM global settings for WSL..."

    local settings=(
        "credential.guiPrompt false"
        "credential.gitHubAuthModes browser" 
        "credential.gitLabAuthModes browser"
        "credential.autoDetectTimeout 0"
        "credential.credentialStore cache"
    )

    for setting in "${settings[@]}"; do
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY RUN] Would set: git config --global $setting"
        else
            git config --global $setting
            print_success "Set: $setting"
        fi
    done
}

# Get list of existing profiles
get_profiles() {
    local profiles=()
    if [[ -d "$PROFILES_DIR" ]]; then
        while IFS= read -r -d '' profile_file; do
            local profile_name
            profile_name=$(basename "$profile_file")
            # Skip template files
            if [[ ! "$profile_name" =~ -template$ ]]; then
                profiles+=("$profile_name")
            fi
        done < <(find "$PROFILES_DIR" -maxdepth 1 -type f -print0)
    fi
    echo "${profiles[@]}"
}

# Add GCM configuration to a profile
add_gcm_to_profile() {
    local profile_file="$1"
    local profile_name
    profile_name=$(basename "$profile_file")

    print_info "Configuring profile: $profile_name"

    # Check if profile already has credential configuration
    if grep -q "\[credential\]" "$profile_file" 2>/dev/null; then
        print_warning "Profile $profile_name already has credential configuration"
        read -p "Do you want to update it? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    local gcm_config="
# 🔐 Git Credential Manager Configuration
[credential]
    helper = $GCM_PATH

[credential \"https://github.com\"]
    provider = github
    helper = $GCM_PATH

[credential \"https://gitlab.com\"]
    provider = gitlab  
    helper = $GCM_PATH

[credential \"https://bitbucket.org\"]
    provider = bitbucket
    helper = $GCM_PATH"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would add GCM configuration to: $profile_file"
        echo -e "${GRAY}$gcm_config${NC}"
        return 0
    fi

    # Backup original file
    cp "$profile_file" "${profile_file}.backup.$(date +%Y%m%d_%H%M%S)"

    # Remove existing credential sections if updating
    if grep -q "\[credential" "$profile_file"; then
        print_info "Removing existing credential configuration..."
        # Create temp file without credential sections
        awk '/^\[credential/{skip=1} /^\[/ && !/^\[credential/{skip=0} !skip' "$profile_file" > "${profile_file}.tmp"
        mv "${profile_file}.tmp" "$profile_file"
    fi

    # Add GCM configuration
    echo "$gcm_config" >> "$profile_file"
    print_success "Added GCM configuration to $profile_name"
}

# Configure profiles  
configure_profiles() {
    print_step "Configuring Git profiles with GCM..."

    if [[ ! -d "$PROFILES_DIR" ]]; then
        print_error "Profiles directory not found: $PROFILES_DIR"
        print_info "Please run setup-profiles.sh first to create Git profiles"
        exit 1
    fi

    local profiles
    read -ra profiles <<< "$(get_profiles)"

    if [[ ${#profiles[@]} -eq 0 ]]; then
        print_warning "No Git profiles found in $PROFILES_DIR"
        print_info "Please run setup-profiles.sh first to create Git profiles"
        return 0
    fi

    print_info "Found ${#profiles[@]} profiles: ${profiles[*]}"
    echo ""

    for profile in "${profiles[@]}"; do
        local profile_file="$PROFILES_DIR/$profile"
        add_gcm_to_profile "$profile_file"
    done
}

# Test GCM configuration
test_gcm() {
    print_step "Testing GCM configuration..."

    # Test GCM binary
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would test: $GCM_PATH --version"
    else
        if git-credential-manager --version >/dev/null 2>&1; then
            print_success "GCM binary works correctly"
        else
            print_error "GCM binary test failed"
            return 1
        fi
    fi

    # Test profile configuration
    local profiles
    read -ra profiles <<< "$(get_profiles)"

    for profile in "${profiles[@]}"; do
        local profile_file="$PROFILES_DIR/$profile"
        if grep -q "git-credential-manager" "$profile_file" 2>/dev/null; then
            print_success "Profile $profile has GCM configuration"
        else
            print_warning "Profile $profile missing GCM configuration"
        fi
    done

    print_info "Test completed. Use 'git clone https://github.com/user/private-repo' to test authentication"
}

# Show summary
show_summary() {
    print_step "Configuration Summary"
    
    echo -e "${WHITE}Git Credential Manager:${NC}"
    echo -e "  Path: ${CYAN}$GCM_PATH${NC}"
    echo -e "  Version: ${CYAN}$(git-credential-manager --version 2>/dev/null | head -1 || echo 'Not available')${NC}"
    
    echo -e "\n${WHITE}Configured Profiles:${NC}"
    local profiles
    read -ra profiles <<< "$(get_profiles)"
    for profile in "${profiles[@]}"; do
        echo -e "  ${GREEN}${CHECK}${NC} $profile"
    done
    
    echo -e "\n${WHITE}Global Git Configuration:${NC}"
    local git_configs=(
        "credential.guiPrompt"
        "credential.gitHubAuthModes" 
        "credential.gitLabAuthModes"
        "credential.credentialStore"
    )
    
    for config in "${git_configs[@]}"; do
        local value
        value=$(git config --global --get "$config" 2>/dev/null || echo "not set")
        echo -e "  $config: ${CYAN}$value${NC}"
    done
    
    echo -e "\n${GREEN}${CHECK} Setup completed successfully!${NC}"
    echo -e "\n${WHITE}Next steps:${NC}"
    echo -e "1. ${YELLOW}Test authentication:${NC} git clone https://github.com/user/private-repo"
    echo -e "2. ${YELLOW}Browser will open${NC} for OAuth authentication"  
    echo -e "3. ${YELLOW}Tokens are stored${NC} securely by GCM"
    echo -e "\n${WHITE}Useful commands:${NC}"
    echo -e "  ${CYAN}git-credential-manager diagnose${NC}   # Check configuration"
    echo -e "  ${CYAN}git-credential-manager erase${NC}      # Remove stored credentials"
    echo -e "  ${CYAN}./scripts/setup-profiles.sh${NC}       # Manage Git profiles"
    echo -e "\n${WHITE}Profile management:${NC}"
    echo -e "  Remove backup files: ${CYAN}rm ~/.config/git/profiles/*.backup.*${NC}"
}

# Main function
main() {
    print_header
    
    # Check environment
    check_wsl
    
    # Get GCM version
    get_latest_gcm_version
    
    # Install GCM
    install_gcm
    
    # Configure GCM
    configure_gcm_global
    
    # Configure profiles
    configure_profiles
    
    # Test configuration
    test_gcm
    
    # Show summary
    show_summary
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -s|--skip-install)
            SKIP_INSTALL=true
            shift
            ;;
        -v|--version)
            GCM_VERSION="$2"
            shift 2
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main