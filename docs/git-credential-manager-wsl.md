# 🔐 Git Credential Manager for WSL - Step-by-Step Guide

> **Complete guide for configuring Git Credential Manager in WSL only (without Windows installation)**

## 📋 Requirements

- ✅ WSL2 with Ubuntu/Debian (or other Linux distribution)
- ✅ Git installed in WSL
- ✅ Internet access
- ✅ Existing Git profiles in `~/.config/git/profiles/`

## 🚀 Step 1: Install Git Credential Manager in WSL

### 1.1 Download the latest GCM version

```bash
# Check the latest version
curl -s https://api.github.com/repos/GitCredentialManager/git-credential-manager/releases/latest | grep "tag_name" | cut -d '"' -f 4

# Download for Linux (current version may differ)
cd /tmp
wget https://github.com/GitCredentialManager/git-credential-manager/releases/latest/download/gcm-linux_amd64.2.4.1.deb

# Alternatively - check available files:
# https://github.com/GitCredentialManager/git-credential-manager/releases/latest
```

### 1.2 Install the package

```bash
# Install from .deb
sudo dpkg -i gcm-linux_amd64.*.deb

# If there are dependency issues:
sudo apt-get update
sudo apt-get install -f

# Verify installation
git-credential-manager --version
```

### 1.3 Check installation path

```bash
# Find where GCM was installed
which git-credential-manager

# Typical locations:
# /usr/local/bin/git-credential-manager
# /usr/bin/git-credential-manager

# Zapisz ścieżkę - będzie potrzebna w konfiguracji
GCM_PATH=$(which git-credential-manager)
echo "GCM Path: $GCM_PATH"
```

## 🔧 Step 2: Configure Git Credential Manager

### 2.1 Set up credential helper

```bash
# Set GCM as default credential helper (globally)
git config --global credential.helper "$GCM_PATH"

# Or only for specific domains:
git config --global credential.https://github.com.helper "$GCM_PATH"
git config --global credential.https://gitlab.com.helper "$GCM_PATH"
```

### 2.2 WSL-specific configuration

```bash
# WSL has special requirements for GUI
git config --global credential.guiPrompt false
git config --global credential.gitHubAuthModes browser
git config --global credential.gitLabAuthModes browser

# Optional - disable automatic updates
git config --global credential.autoDetectTimeout 0
```

## 📁 Step 3: Configure Git profiles

### 3.1 Personal profile (GitHub)

Edit the file `~/.config/git/profiles/personal`:

```ini
[user]
    name = Your Name
    email = your.email@personal.com

[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_personal

# 🔐 CREDENTIAL MANAGER - ADD THIS:
[credential]
    helper = /usr/local/bin/git-credential-manager

[credential "https://github.com"]

## 📁 Krok 3: Konfiguracja profili Git

### 3.1 Profil Personal (GitHub)

Edytuj plik `~/.config/git/profiles/personal`:

```ini
[user]
    name = Twoja Nazwa
    email = twoj.email@personal.com

[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_personal

# 🔐 CREDENTIAL MANAGER - DODAJ TO:
[credential]
    helper = /usr/local/bin/git-credential-manager

[credential "https://github.com"]
    provider = github
    helper = /usr/local/bin/git-credential-manager

# Optional - other services
[credential "https://gist.github.com"]  
    provider = github
    helper = /usr/local/bin/git-credential-manager
```

### 3.2 Work profile (GitLab Enterprise)

Edit the file `~/.config/git/profiles/work`:

```ini
[user]
    name = Work Name
    email = name@company.com

[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_work

# 🔐 CREDENTIAL MANAGER - ADD THIS:
[credential]
    helper = /usr/local/bin/git-credential-manager

[credential "https://gitlab.com"]
    provider = gitlab
    helper = /usr/local/bin/git-credential-manager

# Enterprise GitLab (example)    
[credential "https://gitlab.company.com"]
    provider = gitlab
    helper = /usr/local/bin/git-credential-manager

# Company GitHub (if you use)
[credential "https://github.com"]
    provider = github  
    helper = /usr/local/bin/git-credential-manager
```

### 3.3 Client profile (Multiple services)

Edit the file `~/.config/git/profiles/client`:

```ini
[user]
    name = {{USER_NAME}}
    email = {{USER_EMAIL}}

[core] 
    sshCommand = ssh -i ~/.ssh/{{SSH_KEY}}

# 🔐 CREDENTIAL MANAGER - UNIVERSAL:
[credential]
    helper = /usr/local/bin/git-credential-manager

# Support for all popular services
[credential "https://github.com"]
    provider = github
    helper = /usr/local/bin/git-credential-manager

[credential "https://gitlab.com"]
    provider = gitlab
    helper = /usr/local/bin/git-credential-manager
    
[credential "https://bitbucket.org"]
    provider = bitbucket
    helper = /usr/local/bin/git-credential-manager

# Azure DevOps (if needed)
[credential "https://dev.azure.com"]
    provider = azure-repos  
    helper = /usr/local/bin/git-credential-manager
```

## 🧪 Step 4: Test configuration

### 4.1 Basic test

```bash
# Go to directory with appropriate profile
cd ~/repositories/personal/some-project

# Check active profile
git config --get user.name
git config --get user.email
git config --get credential.helper

# Test connection
git credential-manager version
```

### 4.2 Test with real repository

```bash
# Clone private repo (will require authorization)
git clone https://github.com/your-name/private-repo.git

# GCM should:
# 1. Open browser for OAuth
# 2. Request authorization  
# 3. Save token automatically
# 4. Use it for subsequent operations
```

### 4.3 Check saved credentials

```bash
# List saved credentials
git-credential-manager get

# Or check configuration
git config --list | grep credential

# WSL credential store location (usually):
ls ~/.gcm/
```

## 🔒 Step 5: Security and token management

### 5.1 Token management

```bash
# Remove saved credentials for specific service
git-credential-manager erase

# Logout from all services
git-credential-manager logout

# Check authorization status
git-credential-manager status
```

### 5.2 Per-repository configuration

```bash
# In specific repository you can override settings
cd ~/repositories/work/project
git config credential.helper "/usr/local/bin/git-credential-manager"
git config credential.provider "gitlab"
```

## 🛠️ Troubleshooting

### Problem 1: "credential helper not found"

```bash
# Check installation
which git-credential-manager
git-credential-manager --version

# Update path in profiles
# Change from:
# helper = /usr/local/bin/git-credential-manager  
# To actual path from `which`
```

### Problem 1a: "No credential store has been selected"

```bash
# Configure credential store (required in GCM 2.6+)
git config --global credential.credentialStore cache

# Alternative options:
# git config --global credential.credentialStore secretservice  # requires libsecret-1
# git config --global credential.credentialStore plaintext      # unsecured
# git config --global credential.credentialStore gpg           # requires pass + GPG
```

### Problem 2: "Browser doesn't open"

```bash
# WSL needs browser configuration
export BROWSER=/mnt/c/Program\ Files/Google/Chrome/Application/chrome.exe

# Or add to ~/.bashrc:
echo 'export BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"' >> ~/.bashrc
source ~/.bashrc
```

### Problem 3: "Permission denied despite authorization"

```bash
# Check if token is saved
git config --get-urlmatch credential https://github.com/user/repo

# Force re-authorization  
git-credential-manager erase
git clone https://github.com/user/repo.git
```

## ⚡ Step 6: Automation with Git aliases

Add practical aliases to your profiles:

```ini
# In each profile add:
[alias]
    # Credential management
    cred-status = !git-credential-manager status
    cred-logout = !git-credential-manager logout  
    cred-erase = !git-credential-manager erase
    
    # Quick auth test
    auth-test = !echo "Testing auth for: $(git remote get-url origin)" && git ls-remote
```

## 📊 Summary

After completing these steps you will have:

✅ **Git Credential Manager installed only in WSL**  
✅ **Git profiles configured with GCM support**  
✅ **Automatic authorization through browser**  
✅ **Secure token storage**  
✅ **Support for GitHub, GitLab, Bitbucket, Azure DevOps**

---

## 🚀 Next steps

1. **Run the automated script**: `./scripts/setup-gcm-wsl.sh`
2. **Test with real repositories**  
3. **Configure additional services if needed**

---

*Author: Git Multi-Profile System*  
*Date: $(date +%Y-%m-%d)*