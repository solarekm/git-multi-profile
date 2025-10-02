# 🔐 Git Credential Manager for WSL - Quick Start

> **Quick start guide for Git Credential Manager in WSL**

## 🚀 Option 1: Automated installation (RECOMMENDED)

```bash
# Go to git-multi-profile directory
cd git-multi-profile

# Preview changes (without execution)
./scripts/setup-gcm-wsl.sh --dry-run

# Automated installation and configuration
./scripts/setup-gcm-wsl.sh
```

**What the script does:**
- ✅ Downloads and installs the latest Git Credential Manager
- ✅ Configures WSL settings for GCM  
- ✅ Adds GCM configuration to all Git profiles
- ✅ Performs configuration tests

---

## ⚙️ Option 2: Manual configuration

### Step 1: Install GCM
```bash
# Download latest version
wget https://github.com/GitCredentialManager/git-credential-manager/releases/latest/download/gcm-linux_amd64.2.6.1.deb

# Install
sudo dpkg -i gcm-linux_amd64.2.6.1.deb
```

### Step 2: Configure WSL
```bash
# Global settings for WSL
git config --global credential.guiPrompt false
git config --global credential.gitHubAuthModes browser
git config --global credential.gitLabAuthModes browser
```

### Step 3: Add to Git profiles

Add to each `~/.config/git/profiles/profile-name` file:

```ini
# 🔐 Git Credential Manager Configuration  
[credential]
    helper = /usr/local/bin/git-credential-manager

[credential "https://github.com"]
    provider = github
    helper = /usr/local/bin/git-credential-manager

[credential "https://gitlab.com"]
    provider = gitlab
    helper = /usr/local/bin/git-credential-manager

[credential "https://bitbucket.org"]
    provider = bitbucket
    helper = /usr/local/bin/git-credential-manager
```

---

## 🧪 Test configuration

```bash
# Go to directory with profile (e.g. personal)
cd ~/repositories/personal/some-project

# Test with private repo
git clone https://github.com/your-name/private-repo.git

# GCM should:
# 1. Open browser
# 2. Request OAuth login  
# 3. Save token automatically
```

---

## 🔧 Useful commands

```bash
# Check authorization status
git-credential-manager status

# Logout from all services  
git-credential-manager logout

# Remove saved tokens
git-credential-manager erase

# Check version
git-credential-manager --version

# Test operation in current directory
git ls-remote
```

---

## 🐛 Troubleshooting

### Problem: Browser doesn't open

# Set browser for WSL
export BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"

# Add to ~/.bashrc for persistence
echo 'export BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"' >> ~/.bashrc
```

### Problem: "Permission denied" despite authorization

```bash
# Force new authorization
git-credential-manager erase
git clone https://github.com/user/repo.git
```

### Problem: GCM not found

```bash
# Check installation
which git-credential-manager

# Update path in profiles if different from /usr/local/bin/git-credential-manager
```

---

## 📁 File structure after installation

```
~/.config/git/profiles/
├── personal              # ← GCM added
├── work                 # ← GCM added  
└── client               # ← GCM added

~/.gcm/                  # ← GCM token storage
```

---

## 💡 Pro tips

1. **Different profiles = different tokens**: GCM automatically manages tokens per profile
2. **OAuth > Personal Access Tokens**: Use OAuth flow when possible  
3. **2FA support**: GCM supports two-factor authentication
4. **Enterprise**: Works with GitHub Enterprise, GitLab Enterprise, Azure DevOps

---

**🚀 Done!** Now you have professional Git token management in WSL without installing anything on Windows!

*Documentation: [git-credential-manager-wsl.md](git-credential-manager-wsl.md)*