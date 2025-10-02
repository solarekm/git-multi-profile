#!/bin/bash
# 🧹 GCM Credential Cleaner

clear_gcm_credentials() {
    local service="${1:-all}"

    echo "🧹 Clearing GCM credentials..."

    case "$service" in
        "github")
            echo "  🔹 Clearing GitHub credentials..."
            echo -e "protocol=https\nhost=github.com" | git-credential-manager erase
            echo -e "protocol=https\nhost=gist.github.com" | git-credential-manager erase
            ;;
        "gitlab")
            echo "  🔹 Clearing GitLab credentials..."
            echo -e "protocol=https\nhost=gitlab.com" | git-credential-manager erase
            ;;
        "bitbucket")
            echo "  🔹 Clearing Bitbucket credentials..."
            echo -e "protocol=https\nhost=bitbucket.org" | git-credential-manager erase
            ;;
        "all" | *)
            echo "  🔹 Clearing all credentials..."
            echo -e "protocol=https\nhost=github.com" | git-credential-manager erase 2>/dev/null || true
            echo -e "protocol=https\nhost=gist.github.com" | git-credential-manager erase 2>/dev/null || true
            echo -e "protocol=https\nhost=gitlab.com" | git-credential-manager erase 2>/dev/null || true
            echo -e "protocol=https\nhost=bitbucket.org" | git-credential-manager erase 2>/dev/null || true

            # Clear any GitHub accounts through provider
            if command -v git-credential-manager >/dev/null 2>&1; then
                git-credential-manager github list 2>/dev/null | while read -r account; do
                    if [[ -n "$account" ]]; then
                        echo "  🔹 Logging out GitHub account: $account"
                        git-credential-manager github logout "$account" 2>/dev/null || true
                    fi
                done
            fi
            ;;
    esac

    echo "✅ Credential cleanup completed"
}

# Show usage if called with --help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: clear_gcm_credentials [service]"
    echo ""
    echo "Services:"
    echo "  github     - Clear only GitHub credentials"
    echo "  gitlab     - Clear only GitLab credentials"
    echo "  bitbucket  - Clear only Bitbucket credentials"
    echo "  all        - Clear all credentials (default)"
    echo ""
    echo "Examples:"
    echo "  clear_gcm_credentials github"
    echo "  clear_gcm_credentials all"
    exit 0
fi

# Run the function
clear_gcm_credentials "$@"
