# 🔑 SSH Key Setup Guide

This guide explains the modern SSH key setup for Git multi-profile system.

## Overview

This project uses **core.sshCommand** approach - a simplified and reliable method that doesn't require SSH config files or URL rewriting.

## Why This Approach?

### ✅ Benefits of core.sshCommand:
- **Universal**: Works with all Git hosting services (GitHub, GitLab, Bitbucket, etc.)
- **Simple**: No complex SSH config files to maintain
- **Reliable**: No conflicts between different SSH configurations
- **Automatic**: Per-profile SSH key selection handled by Git
- **Clean**: No URL rewriting or aliases needed

### ❌ Problems with old SSH config approach:
- Complex ~/.ssh/config files
- SSH aliases (github.com-work, gitlab.com-personal)
- URL rewrite rules needed
- Hard to troubleshoot conflicts

## Automated Setup

The `setup-profiles.sh` script handles everything automatically:

```bash
# Run the interactive setup wizard
./scripts/setup-profiles.sh
```

## What the Script Does

1. **Generates SSH Keys**: Creates Ed25519 or RSA keys per profile
2. **Configures Git Profiles**: Adds `core.sshCommand` to each profile
3. **Shows Public Keys**: Displays keys to add to Git hosting services
4. **Tests Configuration**: Validates the setup works correctly

## Manual Key Management

If you need to check your keys manually:

```bash
# List generated keys
ls ~/.ssh/id_*

# View public key (copy this to GitHub/GitLab)
cat ~/.ssh/id_ed25519_work.pub
cat ~/.ssh/id_ed25519_personal.pub
```

### SSH Key Generation Commands

If you need to generate keys manually:

```bash
# Work profile
ssh-keygen -t ed25519 -C "your.work@company.com" -f ~/.ssh/id_ed25519_work

# Personal profile
ssh-keygen -t ed25519 -C "your.personal@email.com" -f ~/.ssh/id_ed25519_personal

# Client profile (replace 'client' with actual client name)
ssh-keygen -t ed25519 -C "your.email@client.com" -f ~/.ssh/id_ed25519_client
```

**Key Generation Options:**
- `-t ed25519`: Modern, secure key type (recommended)
- `-t rsa -b 4096`: Alternative RSA key with 4096 bits
- `-C "email"`: Comment (typically your email)
- `-f filename`: Output filename

### Add SSH Keys to SSH Agent

```bash
# Start SSH agent
eval "$(ssh-agent -s)"

# Add keys to agent
ssh-add ~/.ssh/id_ed25519_work
ssh-add ~/.ssh/id_ed25519_personal

# List loaded keys
ssh-add -l
```

## How It Works

When you're in a directory configured for a specific profile:

1. **Git reads profile config** from `~/.config/git/profiles/work`
2. **Finds core.sshCommand** setting pointing to your work SSH key
3. **Uses that key automatically** for all Git operations
4. **No manual switching needed** - it's automatic based on directory

Example configuration in profile:
```gitconfig
[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_work -o IdentitiesOnly=yes
```

## Adding Keys to Git Hosting Services

### GitHub

1. Copy your public key:
   ```bash
   cat ~/.ssh/id_ed25519_work.pub
   ```

2. Go to GitHub → Settings → SSH and GPG keys
3. Click "New SSH key"
4. Paste the public key content
5. Give it a descriptive name (e.g., "Work Laptop - Ed25519")

### GitLab

1. Copy your public key:
   ```bash
   cat ~/.ssh/id_ed25519_personal.pub
   ```

2. Go to GitLab → Preferences → SSH Keys
3. Paste the key in the "Key" field
4. Set expiration date (optional but recommended)
5. Give it a descriptive title

### Testing SSH Connection

Test your setup:

```bash
# Test GitHub connection
ssh -T git@github.com

# Test GitLab connection  
ssh -T git@gitlab.com

# Test with specific key
ssh -T -i ~/.ssh/id_ed25519_work git@github.com
```

Expected responses:
- **GitHub**: "Hi username! You've successfully authenticated..."
- **GitLab**: "Welcome to GitLab, @username!"

## Troubleshooting

### Key Not Found

```bash
# Check if key exists
ls -la ~/.ssh/id_ed25519_*

# Generate if missing
ssh-keygen -t ed25519 -C "your.email@example.com" -f ~/.ssh/id_ed25519_profilename
```

### Permission Denied

```bash
# Check key permissions
chmod 600 ~/.ssh/id_ed25519_*
chmod 644 ~/.ssh/id_ed25519_*.pub

# Check SSH agent
ssh-add -l
ssh-add ~/.ssh/id_ed25519_work
```

### Wrong Key Being Used

Check your Git profile configuration:

```bash
# In your work directory
cd ~/repositories/work
git config --list | grep sshCommand

# Should show: core.sshcommand=ssh -i ~/.ssh/id_ed25519_work -o IdentitiesOnly=yes
```

### Debug SSH Connection

```bash
# Verbose SSH connection
ssh -T -v git@github.com

# Test specific key
ssh -T -i ~/.ssh/id_ed25519_work -o IdentitiesOnly=yes git@github.com
```

## Security Best Practices

### Key Management
- **Use Ed25519** keys (modern, secure, faster)
- **Set passphrases** on private keys
- **Regular rotation** (annually or when compromised)
- **Unique keys** per profile/device combination

### File Permissions
```bash
# Set correct permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519_*
chmod 644 ~/.ssh/id_ed25519_*.pub
```

### Key Storage
- **Never share** private keys
- **Backup securely** (encrypted storage)
- **Remove unused** keys from services
- **Monitor key usage** in Git hosting service logs

## Advanced Configuration

### Multiple Keys for Same Service

If you need multiple GitHub accounts:

```bash
# Generate keys with descriptive names
ssh-keygen -t ed25519 -C "work@company.com" -f ~/.ssh/id_ed25519_github_work  
ssh-keygen -t ed25519 -C "personal@email.com" -f ~/.ssh/id_ed25519_github_personal
```

Configure in profiles:
```gitconfig
# Work profile
[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_github_work -o IdentitiesOnly=yes

# Personal profile  
[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_github_personal -o IdentitiesOnly=yes
```

### Key Expiration

Set up key rotation reminders:

```bash
# Check key age
stat ~/.ssh/id_ed25519_work

# Set calendar reminder to rotate keys annually
```

## Migration from SSH Config Approach

If you're migrating from the old SSH config method:

1. **Backup existing setup**:
   ```bash
   cp ~/.ssh/config ~/.ssh/config.backup
   ```

2. **Run setup script** - it will configure core.sshCommand approach

3. **Test thoroughly** before removing old SSH config

4. **Remove SSH aliases** once confirmed working:
   ```bash
   # Remove lines like:
   # Host github.com-work
   #   HostName github.com
   #   User git
   #   IdentityFile ~/.ssh/id_ed25519_work
   ```

The new approach is cleaner and more reliable than SSH config aliases.