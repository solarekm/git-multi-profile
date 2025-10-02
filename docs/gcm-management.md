# 🔐 Git Credential Manager - Management Guide

This guide covers advanced Git Credential Manager (GCM) usage, troubleshooting, and management for the git-multi-profile system.

## 📋 Overview

Git Credential Manager provides secure credential storage and authentication for Git operations. This guide focuses on management utilities and troubleshooting for WSL environments.

## 🛠️ Management Scripts

### `check-gcm-status.sh` - Status Monitoring

**Purpose:** Comprehensive GCM status monitoring and diagnostics

**What it checks:**
- ✅ GCM version and installation
- ✅ Credential store configuration
- ✅ Authentication methods (browser vs device flow)
- ✅ Active credential helpers
- ✅ Provider connectivity (GitHub, GitLab, Bitbucket)
- ✅ Real-time authentication testing

**Usage:**
```bash
./scripts/check-gcm-status.sh
```

**Sample Output:**
```
🔐 === GIT CREDENTIAL MANAGER STATUS ===

📋 Version & Diagnostics:
  GCM Version: 2.6.1
  Store Type: cache

🌐 Authentication Methods:
  GitHub: browser
  GitLab: browser

🔗 Active Credential Helpers:
  file:~/.config/git/profiles/work  credential.helper=/usr/local/bin/git-credential-manager

🧪 Test GitHub Connection:
  ✅ GitHub authentication working
```

### `clear-gcm-credentials.sh` - Credential Cleanup

**Purpose:** Safe and controlled credential removal

**Features:**
- Provider-specific clearing (GitHub, GitLab, Bitbucket)
- Bulk credential removal
- Non-hanging erase operations
- Error handling for missing credentials

**Usage:**
```bash
# Clear all stored credentials
./scripts/clear-gcm-credentials.sh

# Clear specific provider
./scripts/clear-gcm-credentials.sh github
./scripts/clear-gcm-credentials.sh gitlab
./scripts/clear-gcm-credentials.sh bitbucket

# Interactive mode with confirmation
./scripts/clear-gcm-credentials.sh --interactive
```

**When to use:**
- 🔄 Before switching between different accounts
- 🧹 When experiencing authentication issues
- 🔒 For security cleanup when leaving work environment
- 🚀 Before testing new credential configurations

## 🔧 Advanced Configuration

### Credential Store Types

GCM supports different credential storage backends:

#### Cache Store (Default for WSL)
```bash
git config --global credential.credentialStore cache
```
- ✅ **Pros:** Simple, no external dependencies
- ✅ **Fast:** In-memory storage
- ⚠️ **Cons:** Credentials expire after timeout (default 15 minutes)

#### SecretService Store (Linux Desktop)
```bash
git config --global credential.credentialStore secretservice
```
- ✅ **Pros:** Persistent storage, integrated with desktop keyring
- ✅ **Secure:** Encrypted storage
- ⚠️ **Cons:** Requires desktop environment

### Authentication Modes

#### Browser Authentication (Recommended)
```bash
git config --global credential.gitHubAuthModes browser
git config --global credential.gitLabAuthModes browser
```
- ✅ **Pros:** Native OAuth flow, supports 2FA
- ✅ **User-friendly:** Uses default browser
- ⚠️ **Cons:** Requires GUI environment

#### Device Flow Authentication
```bash
git config --global credential.gitHubAuthModes device
```
- ✅ **Pros:** Works in headless environments
- ✅ **Secure:** No browser required
- ⚠️ **Cons:** Manual device code entry required

## 🧪 Testing and Validation

### Quick Authentication Test
```bash
# Test GitHub authentication
git ls-remote https://github.com/username/repo.git

# Test GitLab authentication  
git ls-remote https://gitlab.com/username/repo.git

# Test corporate GitLab
git ls-remote https://gitlab.company.com/group/repo.git
```

### Manual Credential Testing
```bash
# Check if credentials are stored
git-credential-manager get <<< "protocol=https
host=github.com"

# Store new credentials manually
git-credential-manager store <<< "protocol=https
host=github.com
username=your-username
password=your-token"
```

### Debugging Authentication Issues

1. **Check GCM installation:**
   ```bash
   git-credential-manager --version
   which git-credential-manager
   ```

2. **Verify credential helper configuration:**
   ```bash
   git config --list | grep credential.helper
   ```

3. **Test specific provider:**
   ```bash
   git-credential-manager diagnose
   ```

4. **Clear and re-authenticate:**
   ```bash
   ./scripts/clear-gcm-credentials.sh github
   git clone https://github.com/your-username/test-repo.git
   ```

## 🔒 Security Best Practices

### Credential Isolation
- 🔐 **Use different Git hosting accounts** for work vs personal
- 🔑 **Generate separate tokens** for different environments
- 🎯 **Configure directory-based profiles** to prevent cross-contamination

### Token Management
```bash
# Use fine-grained personal access tokens (GitHub)
# Scope: repo, read:user, read:email

# Use project access tokens (GitLab)
# Scope: read_repository, write_repository

# Regularly rotate tokens
./scripts/clear-gcm-credentials.sh github
# Then re-authenticate with new token
```

### WSL Security Considerations
- 🔒 **Cache store** credentials are only accessible to your user
- ⏰ **Credentials expire** automatically after timeout
- 🧹 **Clear credentials** when switching contexts

## 🐛 Troubleshooting

### Common Issues

#### Issue: "No credential store has been selected"
```bash
# Solution: Configure credential store
git config --global credential.credentialStore cache
```

#### Issue: git-credential-manager erase hangs
```bash
# Solution: Use the cleanup script instead
./scripts/clear-gcm-credentials.sh
```

#### Issue: Browser authentication not working in WSL
```bash
# Solution: Check if browser is accessible
echo $DISPLAY  # Should show :0 or similar

# Alternative: Use device flow
git config --global credential.gitHubAuthModes device
```

#### Issue: Multiple GitHub accounts conflict
```bash
# Solution: Clear credentials and use profile-specific setup
./scripts/clear-gcm-credentials.sh github

# Then clone in appropriate directory for profile switching
cd ~/repositories/work
git clone https://github.com/work-account/repo.git

cd ~/repositories/personal  
git clone https://github.com/personal-account/repo.git
```

### Diagnostic Commands

```bash
# Full GCM diagnostics
git-credential-manager diagnose

# Check active credential helpers
git config --list --show-origin | grep credential.helper

# Verify profile-specific configuration
cd ~/repositories/work
git config user.email  # Should show work email

cd ~/repositories/personal
git config user.email  # Should show personal email
```

### Log Analysis

GCM logs can be found in:
- WSL: Check system logs with `journalctl`
- Verbose mode: `GCM_TRACE=1 git clone <repo>`

## 🔄 Maintenance

### Regular Maintenance Tasks

1. **Weekly:** Check credential status
   ```bash
   ./scripts/check-gcm-status.sh
   ```

2. **Monthly:** Clear unused credentials
   ```bash
   ./scripts/clear-gcm-credentials.sh --interactive
   ```

3. **Before major changes:** Backup configuration
   ```bash
   cp ~/.gitconfig ~/.gitconfig.backup.$(date +%Y%m%d)
   ```

### Profile Integration

GCM works seamlessly with git-multi-profile:

```bash
# Setup sequence
./scripts/setup-gcm-wsl.sh      # Install and configure GCM
./scripts/setup-profiles.sh     # Setup Git profiles  
./scripts/validate-config.sh    # Verify everything works
./scripts/check-gcm-status.sh   # Final status check
```

Each profile can have its own credential configuration while sharing the same GCM installation.

## 📚 Additional Resources

- [Official GCM Documentation](https://github.com/GitCredentialManager/git-credential-manager)
- [WSL Authentication Guide](docs/git-credential-manager-wsl.md)
- [Quick Start Guide](docs/gcm-quick-start.md)
- [Troubleshooting Guide](docs/troubleshooting.md)