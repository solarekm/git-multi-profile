#!/bin/bash

# SSH Key Generation Utility for Git Profiles
# Generates SSH key pairs for different Git profiles

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
KEY="🔑"
GEAR="🔧"

print_header() {
	echo -e "\n${CYAN}════════════════════════════════════════════════════════════════${NC}"
	echo -e "${WHITE}           🔑 SSH Key Generation Utility${NC}"
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

# Check prerequisites
check_prerequisites() {
	if ! command -v ssh-keygen &>/dev/null; then
		print_error "ssh-keygen not found. Please install OpenSSH client."
		exit 1
	fi

	if ! command -v ssh-add &>/dev/null; then
		print_error "ssh-add not found. Please install OpenSSH client."
		exit 1
	fi

	# Create SSH directory if it doesn't exist
	mkdir -p ~/.ssh
	chmod 700 ~/.ssh

	print_success "Prerequisites check passed"
}

# Generate SSH key pair
generate_key() {
	local profile_name="$1"
	local email="$2"
	local key_type="${3:-rsa}"
	local key_size="${4:-4096}"
	local passphrase="${5:-}"

	local key_path="$HOME/.ssh/id_${key_type}_${profile_name}"

	echo -e "${WHITE}Generating SSH key for profile: ${CYAN}$profile_name${NC}"
	echo -e "  Type: $key_type"
	echo -e "  Size: $key_size bits"
	echo -e "  Email: $email"
	echo -e "  Path: $key_path"
	echo ""

	# Check if key already exists
	if [[ -f "$key_path" ]]; then
		print_warning "SSH key already exists: $key_path"
		read -p "Overwrite existing key? (y/N): " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			print_info "Key generation cancelled"
			return 0
		fi

		# Backup existing key
		local backup_path
		backup_path="${key_path}.backup.$(date +%Y%m%d_%H%M%S)"
		mv "$key_path" "$backup_path"
		mv "${key_path}.pub" "${backup_path}.pub" 2>/dev/null || true
		print_info "Existing key backed up to: $backup_path"
	fi

	# Generate key based on type
	case "$key_type" in
	rsa)
		if [[ -n "$passphrase" ]]; then
			ssh-keygen -t rsa -b "$key_size" -C "$email" -f "$key_path" -N "$passphrase"
		else
			ssh-keygen -t rsa -b "$key_size" -C "$email" -f "$key_path"
		fi
		;;
	ed25519)
		if [[ -n "$passphrase" ]]; then
			ssh-keygen -t ed25519 -C "$email" -f "$key_path" -N "$passphrase"
		else
			ssh-keygen -t ed25519 -C "$email" -f "$key_path"
		fi
		;;
	ecdsa)
		if [[ -n "$passphrase" ]]; then
			ssh-keygen -t ecdsa -b "$key_size" -C "$email" -f "$key_path" -N "$passphrase"
		else
			ssh-keygen -t ecdsa -b "$key_size" -C "$email" -f "$key_path"
		fi
		;;
	*)
		print_error "Unsupported key type: $key_type"
		return 1
		;;
	esac

	# Set correct permissions
	chmod 600 "$key_path"
	chmod 644 "${key_path}.pub"

	print_success "SSH key pair generated successfully"
	print_info "Private key: $key_path"
	print_info "Public key: ${key_path}.pub"

	# Show public key
	echo ""
	echo -e "${WHITE}Public Key (add this to your Git hosting service):${NC}"
	echo -e "${CYAN}════════════════════════════════════════════════${NC}"
	cat "${key_path}.pub"
	echo -e "${CYAN}════════════════════════════════════════════════${NC}"

	# Offer to add to SSH agent
	echo ""
	read -p "Add key to SSH agent? (Y/n): " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Nn]$ ]]; then
		add_to_agent "$key_path"
	fi

	# Offer to update SSH config
	echo ""
	read -p "Update SSH config with host alias? (Y/n): " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Nn]$ ]]; then
		update_ssh_config "$profile_name" "$key_path"
	fi
}

# Add key to SSH agent
add_to_agent() {
	local key_path="$1"

	# Start SSH agent if not running
	if ! pgrep -u "$USER" ssh-agent >/dev/null; then
		print_info "Starting SSH agent..."
		eval "$(ssh-agent -s)"
	fi

	# Add key to agent
	if ssh-add "$key_path"; then
		print_success "Key added to SSH agent"
	else
		print_error "Failed to add key to SSH agent"
	fi
}

# Update SSH config
update_ssh_config() {
	local profile_name="$1"
	local key_path="$2"

	local ssh_config="$HOME/.ssh/config"

	echo -e "${WHITE}Updating SSH config...${NC}"

	# Create SSH config if it doesn't exist
	touch "$ssh_config"
	chmod 600 "$ssh_config"

	# Check if host alias already exists
	local host_alias="github.com-${profile_name}"
	if grep -q "Host $host_alias" "$ssh_config"; then
		print_warning "SSH config entry for $host_alias already exists"
		read -p "Update existing entry? (y/N): " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			print_info "SSH config update skipped"
			return 0
		fi

		# Remove existing entry
		sed -i "/^Host $host_alias$/,/^$/d" "$ssh_config"
	fi

	# Add new SSH config entry
	cat >>"$ssh_config" <<EOF

# $profile_name profile
Host $host_alias
    HostName github.com
    User git
    IdentityFile $key_path
    IdentitiesOnly yes

EOF

	print_success "SSH config updated with host alias: $host_alias"
	print_info "Use this host in Git URLs: git@${host_alias}:user/repo.git"
}

# List existing SSH keys
list_keys() {
	echo -e "${WHITE}Existing SSH Keys:${NC}"
	echo ""

	local keys_found=false
	for key_file in ~/.ssh/id_*; do
		if [[ -f "$key_file" && ! "$key_file" =~ \.pub$ ]]; then
			keys_found=true
			local key_name
			key_name=$(basename "$key_file")
			local key_type
			key_type=$(ssh-keygen -l -f "$key_file" 2>/dev/null | awk '{print $4}' | tr -d '()' || echo "unknown")
			local key_size
			key_size=$(ssh-keygen -l -f "$key_file" 2>/dev/null | awk '{print $1}' || echo "unknown")

			echo -e "  ${CYAN}$key_name${NC}"
			echo -e "    Type: $key_type"
			echo -e "    Size: $key_size bits"
			echo -e "    Path: $key_file"

			# Check if key is in SSH agent
			if ssh-add -l 2>/dev/null | grep -q "$key_file"; then
				echo -e "    Status: ${GREEN}Loaded in SSH agent${NC}"
			else
				echo -e "    Status: ${YELLOW}Not in SSH agent${NC}"
			fi

			# Show public key fingerprint if available
			if [[ -f "${key_file}.pub" ]]; then
				local fingerprint
				fingerprint=$(ssh-keygen -l -f "${key_file}.pub" 2>/dev/null | awk '{print $2}' || echo "unknown")
				echo -e "    Fingerprint: $fingerprint"
			fi
			echo ""
		fi
	done

	if [[ "$keys_found" == false ]]; then
		print_info "No SSH keys found in ~/.ssh/"
	fi
}

# Interactive key generation
interactive_generate() {
	echo -e "${WHITE}SSH Key Generation Wizard${NC}"
	echo ""

	# Get profile name
	read -r -p "Enter profile name (e.g., work, personal, client): " profile_name
	if [[ -z "$profile_name" ]]; then
		print_error "Profile name cannot be empty"
		exit 1
	fi

	# Get email
	read -r -p "Enter email address for this key: " email
	if [[ -z "$email" ]]; then
		print_error "Email address cannot be empty"
		exit 1
	fi

	# Get key type
	echo ""
	echo "Select key type:"
	echo "1) RSA (recommended for compatibility)"
	echo "2) Ed25519 (modern, faster)"
	echo "3) ECDSA (corporate environments)"
	echo ""
	read -r -p "Choose key type (1-3) [1]: " key_choice

	case "${key_choice:-1}" in
	1)
		key_type="rsa"
		key_size="4096"
		;;
	2)
		key_type="ed25519"
		key_size=""
		;;
	3)
		key_type="ecdsa"
		key_size="521"
		;;
	*)
		print_error "Invalid choice"
		exit 1
		;;
	esac

	# Ask about passphrase
	echo ""
	read -p "Set passphrase for key? (Y/n): " -n 1 -r
	echo
	local passphrase=""
	if [[ ! $REPLY =~ ^[Nn]$ ]]; then
		read -r -s -p "Enter passphrase (empty for no passphrase): " passphrase
		echo
		if [[ -n "$passphrase" ]]; then
			read -r -s -p "Confirm passphrase: " passphrase_confirm
			echo
			if [[ "$passphrase" != "$passphrase_confirm" ]]; then
				print_error "Passphrases don't match"
				exit 1
			fi
		fi
	fi

	# Generate the key
	echo ""
	generate_key "$profile_name" "$email" "$key_type" "$key_size" "$passphrase"
}

# Test SSH connectivity
test_connection() {
	local host="${1:-github.com}"

	echo -e "${WHITE}Testing SSH connection to $host...${NC}"

	if ssh -T -o ConnectTimeout=10 -o StrictHostKeyChecking=no "git@$host" 2>&1 | grep -q "successfully authenticated"; then
		print_success "SSH connection to $host: OK"
	else
		print_warning "SSH connection to $host: Failed or not configured"
		print_info "Make sure your public key is added to $host"
	fi
}

# Show help
show_help() {
	echo "SSH Key Generation Utility for Git Profiles"
	echo ""
	echo "Usage: $0 [OPTIONS] [PROFILE_NAME] [EMAIL]"
	echo ""
	echo "Options:"
	echo "  -l, --list              List existing SSH keys"
	echo "  -i, --interactive       Interactive key generation"
	echo "  -t, --test [HOST]       Test SSH connection (default: github.com)"
	echo "  --type TYPE             Key type (rsa, ed25519, ecdsa) [rsa]"
	echo "  --size SIZE             Key size in bits [4096 for RSA, 521 for ECDSA]"
	echo "  --passphrase PASS       Set passphrase (empty for no passphrase)"
	echo "  -h, --help              Show this help message"
	echo ""
	echo "Arguments:"
	echo "  PROFILE_NAME            Name of the profile (e.g., work, personal)"
	echo "  EMAIL                   Email address for the key"
	echo ""
	echo "Examples:"
	echo "  $0 --interactive                    # Interactive wizard"
	echo "  $0 --list                          # List existing keys"
	echo "  $0 work john@company.com           # Generate RSA key for work"
	echo "  $0 --type ed25519 personal john@me.com  # Generate Ed25519 key"
	echo "  $0 --test github.com-work          # Test connection"
}

# Main execution
main() {
	local profile_name=""
	local email=""
	local key_type="rsa"
	local key_size="4096"
	local passphrase=""
	local test_host=""

	while [[ $# -gt 0 ]]; do
		case $1 in
		-l | --list)
			print_header
			list_keys
			exit 0
			;;
		-i | --interactive)
			print_header
			check_prerequisites
			interactive_generate
			exit 0
			;;
		-t | --test)
			test_host="${2:-github.com}"
			shift
			print_header
			test_connection "$test_host"
			exit 0
			;;
		--type)
			key_type="$2"
			shift
			;;
		--size)
			key_size="$2"
			shift
			;;
		--passphrase)
			passphrase="$2"
			shift
			;;
		-h | --help)
			show_help
			exit 0
			;;
		*)
			if [[ -z "$profile_name" ]]; then
				profile_name="$1"
			elif [[ -z "$email" ]]; then
				email="$1"
			else
				echo "Unknown argument: $1"
				show_help
				exit 1
			fi
			;;
		esac
		shift
	done

	print_header
	check_prerequisites

	if [[ -z "$profile_name" || -z "$email" ]]; then
		print_info "Missing arguments. Starting interactive mode..."
		echo ""
		interactive_generate
	else
		# Set default key size for ed25519
		if [[ "$key_type" == "ed25519" ]]; then
			key_size=""
		elif [[ "$key_type" == "ecdsa" && "$key_size" == "4096" ]]; then
			key_size="521"
		fi

		generate_key "$profile_name" "$email" "$key_type" "$key_size" "$passphrase"
	fi
}

main "$@"
