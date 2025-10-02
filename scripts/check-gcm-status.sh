#!/bin/bash
# 🔍 GCM Status Checker Script

echo "🔐 === GIT CREDENTIAL MANAGER STATUS ==="
echo ""

echo "📋 Version & Diagnostics:"
echo "  GCM Version: $(git-credential-manager --version)"
echo "  Store Type: $(git config --global credential.credentialStore)"
echo ""

echo "🌐 Authentication Methods:"
echo "  GitHub: $(git config --global credential.gitHubAuthModes)"
echo "  GitLab: $(git config --global credential.gitLabAuthModes)"
echo ""

echo "🔗 Active Credential Helpers:"
git config --list --show-origin | grep "credential.*helper" | while read -r line; do
    echo "  $line"
done
echo ""

echo "🧪 Test GitHub Connection:"
echo -n "  "
if timeout 10 git ls-remote https://github.com/solarekm/git-multi-profile.git >/dev/null 2>&1; then
    echo "✅ GitHub authentication working"
else
    echo "❌ GitHub authentication failed - run: git clone https://github.com/solarekm/git-multi-profile.git"
fi

echo ""
echo "📍 Where credentials are stored:"
case "$(git config --global credential.credentialStore)" in
    "cache")
        echo "  📍 Location: In memory (RAM)"
        echo "  ⏱️ Duration: Until reboot/logout"
        echo "  🔒 Security: High (not on disk)"
        ;;
    "secretservice")
        echo "  📍 Location: ~/.local/share/keyrings/"
        echo "  ⏱️ Duration: Persistent"
        echo "  🔒 Security: High (encrypted keyring)"
        ;;
    "plaintext")
        echo "  📍 Location: ~/.git-credentials"
        echo "  ⏱️ Duration: Persistent"
        echo "  ⚠️ Security: LOW (plain text file)"
        ;;
    "gpg")
        echo "  📍 Location: ~/.password-store/"
        echo "  ⏱️ Duration: Persistent"
        echo "  🔒 Security: Very High (GPG encrypted)"
        ;;
    *)
        echo "  ❓ Unknown store type"
        ;;
esac

echo ""
echo "🎯 Quick Commands:"
echo "  Test GitHub:           git ls-remote https://github.com/solarekm/git-multi-profile.git"
echo "  Test GitLab:           git ls-remote https://gitlab.com/gitlab-org/gitlab.git"
printf "  Check stored creds:    git credential fill <<<\$'protocol=https\\\\nhost=github.com\\\\n'\n"
echo "  Clear all credentials: ./scripts/clear-gcm-credentials.sh all"
echo "  Clear GitHub only:     ./scripts/clear-gcm-credentials.sh github"
echo "  Run diagnostics:      git-credential-manager diagnose"
echo ""
echo "🔐 Security Notes:"
echo "  ✅ Using GCM for secure credential storage"
echo "  ✅ No plain-text tokens visible"
echo "  ✅ Browser-based OAuth authentication"