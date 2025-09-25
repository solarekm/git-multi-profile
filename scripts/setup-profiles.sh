#!/bin/bash

# Git Multi-Profile Setup Script
# Interactive wizard for configuring Git profiles

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Emoji for better UX
CHECK="✅"
WARNING="⚠️ "
ERROR="❌"
INFO="ℹ️ "
ROCKET="🚀"
GEAR="🔧"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

print_header() {
	echo -e "\n${PURPLE}════════════════════════════════════════════════════════════════${NC}"
	echo -e "${WHITE}           🔧 Git Multi-Profile Configuration Manager${NC}"
	echo -e "${PURPLE}════════════════════════════════════════════════════════════════${NC}\n"
}

print_step() {
	echo -e "${CYAN}${GEAR} $1${NC}"
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

# Check prerequisites
check_prerequisites() {
	print_step "Checking prerequisites..."

	# Check Git version
	if ! command -v git &>/dev/null; then
		print_error "Git is not installed. Please install Git first."
		exit 1
	fi

	GIT_VERSION=$(git --version | cut -d' ' -f3)
	print_success "Git version $GIT_VERSION found"

	# Check if SSH is available
	if ! command -v ssh &>/dev/null; then
		print_warning "SSH client not found. SSH key management will be limited."
	else
		print_success "SSH client found"
	fi

	# Create necessary directories
	mkdir -p ~/.config/git/profiles
	mkdir -p ~/.ssh

	print_success "Prerequisites check completed"
}

# Backup existing configuration
backup_existing_config() {
	print_step "Backing up existing Git configuration..."

	if [[ -f ~/.gitconfig ]]; then
		BACKUP_FILE="$HOME/.gitconfig.backup.$(date +%Y%m%d_%H%M%S)"
		cp ~/.gitconfig "$BACKUP_FILE"
		print_success "Existing .gitconfig backed up to: $BACKUP_FILE"
	else
		print_info "No existing .gitconfig found"
	fi
}

# Configure global Git settings
configure_global() {
	print_step "Configuring global Git settings..."

	# Check if global config already exists and is valid
	if git config --global user.name >/dev/null 2>&1 && git config --global user.email >/dev/null 2>&1; then
		CURRENT_NAME=$(git config --global user.name)
		CURRENT_EMAIL=$(git config --global user.email)
		print_info "Current global configuration: $CURRENT_NAME <$CURRENT_EMAIL>"

		read -p "Keep current global configuration? (Y/n): " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Nn]$ ]]; then
			print_success "Keeping existing global configuration"
			return
		fi
	fi

	echo -e "${WHITE}Global Git Configuration:${NC}"
	echo "This will be your default identity when no profile matches."
	echo ""

	read -r -p "Enter your default name: " DEFAULT_NAME
	read -r -p "Enter your default email: " DEFAULT_EMAIL

	# Copy and customize global config
	cp "$PROJECT_DIR/configs/profiles/global-template" ~/.gitconfig.tmp

	# Replace placeholders
	sed -i "s/Your Name/$DEFAULT_NAME/g" ~/.gitconfig.tmp
	sed -i "s/your.email@example.com/$DEFAULT_EMAIL/g" ~/.gitconfig.tmp

	mv ~/.gitconfig.tmp ~/.gitconfig

	print_success "Global Git configuration created"
}

# Generate SSH key with preferences
generate_ssh_key() {
	local PROFILE_TYPE=$1
	local EMAIL=$2

	print_step "Generating SSH key for $PROFILE_TYPE profile..."

	# Ask for key type preference
	echo ""
	echo "Select SSH key type:"
	echo "1) Ed25519 (recommended - modern, secure, fast)"
	echo "2) RSA 4096 (traditional, widely compatible)"
	read -r -p "Choose key type (1-2) [1]: " KEY_CHOICE

	case "${KEY_CHOICE:-1}" in
	1)
		KEY_TYPE="ed25519"
		SSH_KEY_PATH="$HOME/.ssh/id_ed25519_$PROFILE_TYPE"
		;;
	2)
		KEY_TYPE="rsa"
		SSH_KEY_PATH="$HOME/.ssh/id_rsa_$PROFILE_TYPE"
		;;
	*)
		print_error "Invalid choice, using Ed25519"
		KEY_TYPE="ed25519"
		SSH_KEY_PATH="$HOME/.ssh/id_ed25519_$PROFILE_TYPE"
		;;
	esac

	if [[ -f "$SSH_KEY_PATH" ]]; then
		print_warning "SSH key already exists: $SSH_KEY_PATH"
		read -p "Overwrite existing key? (y/n): " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			return
		fi
	fi

	# Ask for passphrase
	echo ""
	read -p "Set passphrase for SSH key? (Y/n): " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Nn]$ ]]; then
		PASSPHRASE=""
	else
		read -r -s -p "Enter passphrase (leave empty for no passphrase): " PASSPHRASE
		echo
		if [[ -n "$PASSPHRASE" ]]; then
			read -r -s -p "Confirm passphrase: " PASSPHRASE_CONFIRM
			echo
			if [[ "$PASSPHRASE" != "$PASSPHRASE_CONFIRM" ]]; then
				print_error "Passphrases don't match, using no passphrase"
				PASSPHRASE=""
			fi
		fi
	fi

	# Generate key based on type
	if [[ "$KEY_TYPE" == "ed25519" ]]; then
		if [[ -n "$PASSPHRASE" ]]; then
			ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY_PATH" -N "$PASSPHRASE"
		else
			ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY_PATH" -N ""
		fi
	else
		if [[ -n "$PASSPHRASE" ]]; then
			ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f "$SSH_KEY_PATH" -N "$PASSPHRASE"
		else
			ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f "$SSH_KEY_PATH" -N ""
		fi
	fi

	print_success "SSH key generated: $SSH_KEY_PATH"
	print_info "Public key: ${SSH_KEY_PATH}.pub"

	# Add SSH configuration to profile
	local PROFILE_CONFIG="$HOME/.config/git/profiles/$PROFILE_TYPE"
	if [[ -f "$PROFILE_CONFIG" ]]; then
		# Add SSH command after the core section comment
		sed -i "/# SSH configuration will be added automatically if SSH key is generated/a\\    sshCommand = ssh -i $SSH_KEY_PATH -F /dev/null" "$PROFILE_CONFIG"
		print_success "SSH configuration added to profile"
	fi

	# Show public key
	echo ""
	echo -e "${WHITE}Public Key (add this to your Git hosting service):${NC}"
	echo -e "${CYAN}════════════════════════════════════════════════${NC}"
	cat "${SSH_KEY_PATH}.pub"
	echo -e "${CYAN}════════════════════════════════════════════════${NC}"
}

# Setup profile
setup_profile() {
	local PROFILE_TYPE=$1
	local TEMPLATE_FILE="$PROJECT_DIR/configs/profiles/${PROFILE_TYPE}-template"

	print_step "Setting up $PROFILE_TYPE profile..."

	echo -e "${WHITE}$PROFILE_TYPE Profile Configuration:${NC}"

	read -r -p "Enter name for $PROFILE_TYPE profile: " PROFILE_NAME
	read -r -p "Enter email for $PROFILE_TYPE profile: " PROFILE_EMAIL
	read -r -p "Enter directory path for $PROFILE_TYPE repositories (e.g., ~/repositories/$PROFILE_TYPE): " PROFILE_DIR

	# Expand tilde
	PROFILE_DIR="${PROFILE_DIR/#\~/$HOME}"

	# Create directory if it doesn't exist
	mkdir -p "$PROFILE_DIR"

	# Generate profile config
	local PROFILE_CONFIG="$HOME/.config/git/profiles/$PROFILE_TYPE"
	cp "$TEMPLATE_FILE" "$PROFILE_CONFIG"

	# Replace placeholders
	case $PROFILE_TYPE in
	"work")
		sed -i "s/Your Professional Name/$PROFILE_NAME/g" "$PROFILE_CONFIG"
		sed -i "s/your.name@company.com/$PROFILE_EMAIL/g" "$PROFILE_CONFIG"
		;;
	"personal")
		sed -i "s/Your Name/$PROFILE_NAME/g" "$PROFILE_CONFIG"
		sed -i "s/your.personal@email.com/$PROFILE_EMAIL/g" "$PROFILE_CONFIG"
		;;
	"client")
		sed -i "s/Your Professional Name/$PROFILE_NAME/g" "$PROFILE_CONFIG"
		sed -i "s/your.name@client-domain.com/$PROFILE_EMAIL/g" "$PROFILE_CONFIG"
		;;
	esac

	# Update global config with conditional include (avoid duplicates)
	if ! grep -q "gitdir:$PROFILE_DIR/\]" ~/.gitconfig; then
		echo "" >>~/.gitconfig
		echo "[includeIf \"gitdir:$PROFILE_DIR/\"]" >>~/.gitconfig
		echo "    path = ~/.config/git/profiles/$PROFILE_TYPE" >>~/.gitconfig
		print_success "Added conditional include for $PROFILE_DIR"
	else
		print_warning "Conditional include for $PROFILE_DIR already exists"
		# Update the path in case profile type changed
		# Escape the profile directory for sed
		local escaped_profile_dir="$PROFILE_DIR"
		escaped_profile_dir=${escaped_profile_dir//\[/\\[}
		escaped_profile_dir=${escaped_profile_dir//]/\\]}
		escaped_profile_dir=${escaped_profile_dir//./\\.}
		escaped_profile_dir=${escaped_profile_dir//*/\\*}
		escaped_profile_dir=${escaped_profile_dir//^/\\^}
		escaped_profile_dir=${escaped_profile_dir//$/\\$}
		escaped_profile_dir=${escaped_profile_dir//(/\\(}
		escaped_profile_dir=${escaped_profile_dir//)/\\)}
		escaped_profile_dir=${escaped_profile_dir//+/\\+}
		escaped_profile_dir=${escaped_profile_dir//\?/\\?}
		escaped_profile_dir=${escaped_profile_dir//{/\\{}
		escaped_profile_dir=${escaped_profile_dir//|/\\|}
		sed -i "/gitdir:${escaped_profile_dir}\//,+1s|path.*|    path = ~/.config/git/profiles/$PROFILE_TYPE|" ~/.gitconfig
		print_info "Updated profile path to ~/.config/git/profiles/$PROFILE_TYPE"
	fi

	print_success "$PROFILE_TYPE profile created at: $PROFILE_CONFIG"
	print_info "Profile will be active for repositories in: $PROFILE_DIR"

	# Ask about SSH key generation
	echo ""
	read -p "Do you want to generate SSH key for $PROFILE_TYPE profile? (y/n): " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		generate_ssh_key "$PROFILE_TYPE" "$PROFILE_EMAIL"
	fi
}

# Clean unused entries from .gitconfig
clean_unused_entries() {
	print_step "Cleaning unused entries from .gitconfig..."

	local BACKUP_FILE
	BACKUP_FILE="$HOME/.gitconfig.backup.$(date +%Y%m%d_%H%M%S)"
	cp ~/.gitconfig "$BACKUP_FILE"
	print_info "Backup created: $BACKUP_FILE"

	local ENTRIES_REMOVED=0

	# Check each includeIf entry
	while IFS= read -r line; do
		if [[ "$line" =~ ^\[includeIf.*gitdir:.*\] ]] && [[ ! "$line" =~ ^# ]]; then
			dir_path=$(echo "$line" | sed 's/.*gitdir://;s/".*//' | sed 's/\].*//')
			expanded_dir_path="${dir_path/#\~/$HOME}"

			if [[ ! -d "$expanded_dir_path" ]]; then
				print_warning "Removing entry for non-existent directory: $dir_path"
				# Escape special characters for sed
				escaped_line=${line//[/\\[}
				escaped_line=${escaped_line//]/\\]}
				escaped_line=${escaped_line//./\\.}
				escaped_line=${escaped_line//*/\\*}
				escaped_line=${escaped_line//^/\\^}
				escaped_line=${escaped_line//$/\\$}
				escaped_line=${escaped_line//(/\\(}
				escaped_line=${escaped_line//)/\\)}
				escaped_line=${escaped_line//+/\\+}
				escaped_line=${escaped_line//\?/\\?}
				escaped_line=${escaped_line//{/\\{}
				escaped_line=${escaped_line//|/\\|}
				# Remove the includeIf line and the following path line
				# Additional escaping for closing brackets
				local final_escaped_line="$escaped_line"
				final_escaped_line=${final_escaped_line//]/\\]}
				sed -i "/^${final_escaped_line}/,+1d" ~/.gitconfig
				((ENTRIES_REMOVED++))
			fi
		fi
	done <"$BACKUP_FILE"

	if [[ $ENTRIES_REMOVED -gt 0 ]]; then
		print_success "Removed $ENTRIES_REMOVED unused entries"
		print_info "You can restore from backup if needed: $BACKUP_FILE"
	else
		print_success "No unused entries found"
		rm "$BACKUP_FILE" # Remove backup if no changes made
	fi
}

# Test configuration
test_configuration() {
	print_step "Testing configuration..."

	echo -e "${WHITE}Configuration Test Results:${NC}"
	echo ""

	# Test global config
	echo -e "${CYAN}Global Configuration:${NC}"
	git config --global user.name
	git config --global user.email
	echo ""

	# Test profiles in their directories
	for profile_config in ~/.config/git/profiles/*; do
		if [[ -f "$profile_config" ]]; then
			profile_name=$(basename "$profile_config")
			echo -e "${CYAN}$profile_name Profile:${NC}"

			# Find the directory for this profile from .gitconfig
			profile_dir=$(grep -B1 "path.*profiles/$profile_name" ~/.gitconfig | grep "includeIf" | sed 's/.*gitdir://;s/".*//' | sed 's/\].*//' | tail -1)

			if [[ -n "$profile_dir" ]]; then
				# Expand tilde to full path
				profile_dir_expanded="${profile_dir/#\~/$HOME}"

				if [[ -d "$profile_dir_expanded" ]]; then
					echo "  Directory: $profile_dir ✅"
					# Test in a git repository within that directory
					local test_repo="$profile_dir_expanded/git-test-$$"
					mkdir -p "$test_repo"
					cd "$test_repo"
					git init >/dev/null 2>&1
					echo "  Name: $(git config user.name 2>/dev/null || echo 'Not configured')"
					echo "  Email: $(git config user.email 2>/dev/null || echo 'Not configured')"
					echo "  SSH Key: $(git config core.sshCommand 2>/dev/null || echo 'Default')"
					cd - >/dev/null
					rm -rf "$test_repo"
				else
					echo "  Directory not found: $profile_dir ❌"
				fi
			else
				echo "  No directory configuration found ⚠️"
			fi
			echo ""
		fi
	done

	print_success "Configuration test completed"
}

# Main menu
main_menu() {
	while true; do
		echo -e "\n${WHITE}What would you like to do?${NC}"
		echo "1) Set up work profile"
		echo "2) Set up personal profile"
		echo "3) Set up client profile"
		echo "4) Clean unused entries"
		echo "5) Test current configuration"
		echo "6) Exit"
		echo ""

		read -r -p "Choose an option (1-6): " choice

		case $choice in
		1)
			setup_profile "work"
			;;
		2)
			setup_profile "personal"
			;;
		3)
			setup_profile "client"
			;;
		4)
			clean_unused_entries
			;;
		5)
			test_configuration
			;;
		6)
			print_success "Setup completed! ${ROCKET}"
			break
			;;
		*)
			print_error "Invalid option. Please choose 1-6."
			;;
		esac
	done
}

# Main execution
main() {
	print_header

	check_prerequisites
	backup_existing_config
	configure_global

	main_menu

	echo -e "\n${GREEN}${ROCKET} Git multi-profile setup completed successfully!${NC}"
	echo -e "${BLUE}${INFO} Remember to add your SSH public keys to your Git hosting services.${NC}"
	echo -e "${BLUE}${INFO} Test your setup by creating repositories in the configured directories.${NC}\n"
}

# Help function
show_help() {
	echo "Git Multi-Profile Setup Script"
	echo ""
	echo "Usage: $0 [OPTIONS]"
	echo ""
	echo "Options:"
	echo "  -h, --help     Show this help message"
	echo "  -t, --test     Test current configuration only"
	echo ""
	echo "This script helps you set up multiple Git profiles with conditional includes."
}

# Command line argument parsing
case "${1:-}" in
-h | --help)
	show_help
	exit 0
	;;
-t | --test)
	test_configuration
	exit 0
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
