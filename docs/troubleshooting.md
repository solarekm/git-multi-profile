# 🚨 Troubleshooting Guide

This guide helps resolve common issues when setting up and using Git multi-profile configurations.

## Common Issues and Solutions

### 1. Profile Not Switching Automatically

**Problem**: Git is not using the expected profile in a specific directory.

**Symptoms**:
- Wrong email/name shown in `git config user.email`
- Commits using incorrect identity
- SSH key not matching expected profile

**Solutions**:

#### Check Conditional Include Syntax
```bash
# Verify conditional includes in ~/.gitconfig
cat ~/.gitconfig | grep -A1 "includeIf"
```

Expected format:
```ini
[includeIf "gitdir:~/repositories/work/"]
    path = ~/.config/git/profiles/work
```

**Common mistakes**:
- Missing trailing slash in directory path
- Incorrect path expansion (use `~/` not `$HOME/`)
- Typo in profile path

#### Verify Directory Structure
```bash
# Check if you're in the correct directory
pwd
# Should match the gitdir pattern in ~/.gitconfig

# Test profile activation
git config user.email
```

#### Debug Profile Loading
```bash
# Show all effective Git config in current directory
git config --list --show-origin

# Check which files are being loaded
git config --list --show-scope
```

**Fix**:
```bash
# Correct the path in ~/.gitconfig
[includeIf "gitdir:/full/path/to/work/"]  # Use absolute path if relative doesn't work
    path = ~/.config/git/profiles/work
```

### 2. SSH Authentication Failures

**Problem**: Git operations fail with "Permission denied (publickey)" errors.

**Symptoms**:
- Cannot clone, push, or pull repositories
- SSH connection test fails
- Wrong SSH key being used

**Solutions**:

#### Check SSH Key Loading
```bash
# List loaded SSH keys
ssh-add -l

# Add missing key
ssh-add ~/.ssh/id_rsa_work

# Test SSH connection
ssh -T git@github.com
```

#### Verify SSH Config
```bash
# Check SSH config syntax
cat ~/.ssh/config

# Test specific host
ssh -T git@github.com-work
```

**Common SSH config issues**:
```bash
# Wrong: Missing IdentitiesOnly
Host github.com-work
    HostName github.com
    IdentityFile ~/.ssh/id_rsa_work

# Correct: Include IdentitiesOnly
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa_work
    IdentitiesOnly yes
```

#### Debug SSH Connection
```bash
# Verbose SSH connection test
ssh -vvv git@github.com-work

# Test with specific identity file
ssh -i ~/.ssh/id_rsa_work -T git@github.com
```

### 3. Wrong SSH Key Being Used

**Problem**: Git uses incorrect SSH key despite profile configuration.

**Solutions**:

#### Check Git SSH Command
```bash
# In the problematic directory
git config core.sshCommand
# Should show: ssh -i ~/.ssh/id_rsa_work -F /dev/null
```

#### Verify Profile Configuration
```bash
# Check profile file
cat ~/.config/git/profiles/work
```

Should contain:
```ini
[core]
    sshCommand = ssh -i ~/.ssh/id_rsa_work -F /dev/null
```

#### Clear SSH Agent (if needed)
```bash
# Remove all keys from agent
ssh-add -D

# Add only the needed key
ssh-add ~/.ssh/id_rsa_work

# Test connection
ssh -T git@github.com
```

### 4. GPG Signing Issues

**Problem**: Commits fail with GPG signing errors.

**Symptoms**:
- "gpg: signing failed: No secret key"
- "error: gpg failed to sign the data"
- Commits not getting signed

**Solutions**:

#### Check GPG Key Configuration
```bash
# List GPG keys
gpg --list-secret-keys

# Check Git signing key
git config user.signingkey
```

#### Verify GPG Key Exists
```bash
# Test GPG signing
echo "test" | gpg --clearsign --default-key YOUR_KEY_ID
```

#### Fix GPG Configuration
```bash
# Set correct signing key
git config user.signingkey YOUR_CORRECT_KEY_ID

# Enable GPG signing
git config commit.gpgsign true

# Test commit signing
git commit --allow-empty -m "Test GPG signing"
```

### 5. Profile File Not Found

**Problem**: Git reports profile file doesn't exist.

**Symptoms**:
- Warning messages about missing include files
- Profile settings not applying

**Solutions**:

#### Check Profile File Path
```bash
# Verify file exists
ls -la ~/.config/git/profiles/

# Check exact path in gitconfig
grep "path =" ~/.gitconfig
```

#### Create Missing Profile
```bash
# Create profile directory
mkdir -p ~/.config/git/profiles

# Copy template
cp configs/profiles/work-template ~/.config/git/profiles/work
```

### 6. Git Version Compatibility

**Problem**: Conditional includes not working on older Git versions.

**Symptoms**:
- Profile switching doesn't work
- No error messages about includeIf

**Solutions**:

#### Check Git Version
```bash
git --version
# Need Git 2.13+ for conditional includes
```

#### Update Git
```bash
# Ubuntu/Debian
sudo add-apt-repository ppa:git-core/ppa
sudo apt update && sudo apt install git

# macOS
brew install git

# CentOS/RHEL
sudo yum install git
```

### 7. Repository Clone Issues

**Problem**: Cannot clone repositories using profile-specific SSH keys.

**Solutions**:

#### Use Correct SSH Host Alias
```bash
# Wrong
git clone git@github.com:company/repo.git

# Correct (for work profile)
git clone git@github.com-work:company/repo.git
```

#### Alternative: Set SSH Command
```bash
# Clone with specific SSH key
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_rsa_work" git clone git@github.com:company/repo.git
```

### 8. Multiple GitHub Accounts

**Problem**: Managing multiple GitHub accounts with different SSH keys.

**Solutions**:

#### Set up URL rewrites in Git profiles
```ini
# In work profile
[url "git@github.com-work:"]
    insteadOf = git@github.com:company-org/

# In personal profile
[url "git@github.com-personal:"]
    insteadOf = git@github.com:personal-username/
```

#### Use directory-specific SSH configs
```ssh
# ~/.ssh/config
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa_work
    IdentitiesOnly yes

Host github.com-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa_personal
    IdentitiesOnly yes
```

## Diagnostic Commands

### Profile Status Check
```bash
# Run validation script
./scripts/validate-config.sh

# Check current profile status
cd /path/to/repository && git config user.email
```

### Git Configuration Debug
```bash
# Show all Git config with sources
git config --list --show-origin

# Show effective config in current directory
git config --get-regexp "user\.|core\.ssh|commit\.gpg"

# Test SSH connectivity
ssh -T git@github.com
ssh -T git@gitlab.com
```

### SSH Debug
```bash
# Verbose SSH connection
ssh -vvv git@github.com-work

# List SSH agent keys
ssh-add -l

# Test key file directly
ssh -i ~/.ssh/id_rsa_work -T git@github.com
```

## Prevention Tips

### 1. Always Test After Setup
```bash
# Test each profile directory
cd ~/repositories/work
git config user.email  # Should show work email

cd ~/repositories/personal  
git config user.email  # Should show personal email
```

### 2. Use Validation Scripts
```bash
# Run after any configuration changes
./scripts/validate-config.sh

# Regular health checks
./scripts/validate-config.sh --quick
```

### 3. Backup Configuration
```bash
# Backup Git config
cp ~/.gitconfig ~/.gitconfig.backup

# Backup SSH config
cp ~/.ssh/config ~/.ssh/config.backup

# Backup profiles
tar -czf git-profiles-backup.tar.gz ~/.config/git/profiles/
```

### 4. Document Your Setup
Keep a record of:
- Which SSH keys belong to which services
- Directory structure and profile mappings
- GPG key IDs for each profile
- Service-specific configurations

## Emergency Recovery

### Reset All Git Configuration
```bash
# Backup current config
mv ~/.gitconfig ~/.gitconfig.broken

# Start fresh
git config --global user.name "Your Name"
git config --global user.email "your@email.com"

# Re-run setup
./scripts/setup-profiles.sh
```

### Reset SSH Configuration
```bash
# Backup SSH config
mv ~/.ssh/config ~/.ssh/config.broken

# Clear SSH agent
ssh-add -D

# Re-add keys manually
ssh-add ~/.ssh/id_rsa_work
ssh-add ~/.ssh/id_rsa_personal
```

## Getting Help

### Git Credential Manager Issues

For GCM-specific troubleshooting, see the dedicated [GCM Management Guide](gcm-management.md).

**Quick GCM diagnostics:**
```bash
# Check GCM status
./scripts/check-gcm-status.sh

# Clear problematic credentials
./scripts/clear-gcm-credentials.sh

# Verify GCM installation
git-credential-manager --version
git-credential-manager diagnose
```

**Common GCM issues:**
- **"No credential store has been selected"** → Run `git config --global credential.credentialStore cache`
- **Browser authentication not working in WSL** → Check `$DISPLAY` variable or use device flow
- **Hanging erase command** → Use `./scripts/clear-gcm-credentials.sh` instead
- **Multiple account conflicts** → Clear credentials and use directory-based profile switching

### Log Issues with Details
When reporting issues, include:

1. **Git version**: `git --version`
2. **Operating system**: `uname -a`
3. **Directory structure**: `ls -la ~/repositories/`
4. **Git config**: `git config --list --show-origin`
5. **SSH config**: `cat ~/.ssh/config`
6. **SSH agent status**: `ssh-add -l`
7. **Error messages**: Full error output
8. **Steps to reproduce**: Exact commands that cause the issue

### Useful Debug Commands
```bash
# Complete system info
./scripts/validate-config.sh > debug-report.txt 2>&1

# Git environment
git config --list --show-origin >> debug-report.txt

# SSH environment  
ssh-add -l >> debug-report.txt
ls -la ~/.ssh/ >> debug-report.txt
```

## Related Documentation

- [SSH Setup Guide](ssh-setup.md)
- [GPG Setup Guide](gpg-setup.md)
- [GCM Management Guide](gcm-management.md)
- [GCM Quick Start](gcm-quick-start.md)
- [Git Credential Manager WSL Setup](git-credential-manager-wsl.md)
- [Main README](../README.md)