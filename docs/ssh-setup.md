# 🔑 SSH Key Setup Guide

This guide explains how to set up and manage SSH keys for different Git profiles.

## Overview

When using multiple Git profiles, you'll typically want separate SSH keys for:
- **Work/Corporate** repositories (company GitHub/GitLab)
- **Personal** repositories (personal GitHub/GitLab)
- **Client** repositories (client-specific Git services)

## Why Separate SSH Keys?

- **Security**: Isolate access permissions between different contexts
- **Organization**: Clear separation of professional and personal identities
- **Compliance**: Meet corporate security requirements
- **Flexibility**: Different key types/sizes for different security levels

## Step-by-Step Setup

### 1. Generate SSH Key Pairs

For each profile, generate a separate SSH key pair:

```bash
# Work profile
ssh-keygen -t rsa -b 4096 -C "your.work@company.com" -f ~/.ssh/id_rsa_work

# Personal profile  
ssh-keygen -t rsa -b 4096 -C "your.personal@email.com" -f ~/.ssh/id_rsa_personal

# Client profile (replace 'client' with actual client name)
ssh-keygen -t rsa -b 4096 -C "your.email@client.com" -f ~/.ssh/id_rsa_client
```

**Key Generation Options:**
- `-t rsa`: Key type (RSA is widely supported)
- `-b 4096`: Key size (4096 bits for enhanced security)
- `-C "email"`: Comment (typically your email)
- `-f filename`: Output filename

### 2. Add SSH Keys to SSH Agent

```bash
# Start SSH agent
eval "$(ssh-agent -s)"

# Add keys to agent
ssh-add ~/.ssh/id_rsa_work
ssh-add ~/.ssh/id_rsa_personal
ssh-add ~/.ssh/id_rsa_client

# List loaded keys
ssh-add -l
```

### 3. Configure SSH Config File

Create or edit `~/.ssh/config` to define host aliases:

```ssh
# Work GitHub
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa_work
    IdentitiesOnly yes

# Personal GitHub
Host github.com-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa_personal
    IdentitiesOnly yes

# Client GitLab
Host gitlab.com-client
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_rsa_client
    IdentitiesOnly yes

# Default GitHub (fallback to personal)
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa_personal
    IdentitiesOnly yes
```

### 4. Add Public Keys to Git Services

Copy and add your public keys to the appropriate Git hosting services:

```bash
# Display public keys
cat ~/.ssh/id_rsa_work.pub
cat ~/.ssh/id_rsa_personal.pub
cat ~/.ssh/id_rsa_client.pub
```

#### GitHub:
1. Go to Settings → SSH and GPG keys
2. Click "New SSH key"
3. Paste the public key content
4. Give it a descriptive title (e.g., "Work Laptop - 2025")

#### GitLab:
1. Go to Preferences → SSH Keys
2. Paste the public key content
3. Add a title and optional expiration date

#### Bitbucket:
1. Go to Personal settings → SSH keys
2. Click "Add key"
3. Paste the public key content

### 5. Configure Git Profiles

In your Git profile configurations, specify which SSH key to use:

```ini
# Work profile (~/.config/git/profiles/work)
[core]
    sshCommand = ssh -i ~/.ssh/id_rsa_work -F /dev/null

[url "git@github.com-work:"]
    insteadOf = git@github.com:company-org/

# Personal profile (~/.config/git/profiles/personal)  
[core]
    sshCommand = ssh -i ~/.ssh/id_rsa_personal -F /dev/null

[url "git@github.com-personal:"]
    insteadOf = git@github.com:your-username/
```

## Testing SSH Connections

Test each SSH key configuration:

```bash
# Test work key
ssh -T git@github.com-work

# Test personal key
ssh -T git@github.com-personal

# Test client key
ssh -T git@gitlab.com-client
```

Expected responses:
- **GitHub**: "Hi username! You've successfully authenticated..."
- **GitLab**: "Welcome to GitLab, @username!"
- **Bitbucket**: "logged in as username"

## Troubleshooting

### Common Issues

#### 1. "Permission denied (publickey)"
```bash
# Check if key is loaded in SSH agent
ssh-add -l

# Add key if missing
ssh-add ~/.ssh/id_rsa_work

# Test with verbose output
ssh -T -v git@github.com-work
```

#### 2. Wrong key being used
```bash
# Check SSH config syntax
ssh -T -F ~/.ssh/config git@github.com-work

# Force specific identity file
ssh -T -i ~/.ssh/id_rsa_work git@github.com
```

#### 3. Key not recognized by service
- Ensure public key is correctly copied (no extra spaces/newlines)
- Verify key is added to correct account
- Check if key has expired (some services support expiration)

### Debugging Commands

```bash
# List all SSH keys
ls -la ~/.ssh/

# Check SSH agent status
ssh-add -l

# Test SSH connection with debug output
ssh -T -vvv git@github.com

# Verify Git is using correct SSH key
GIT_SSH_COMMAND="ssh -v" git clone git@github.com:user/repo.git
```

## Security Best Practices

### Key Management
- **Use strong passphrases** for SSH keys
- **Rotate keys regularly** (annually or per company policy)
- **Remove old keys** from Git services when no longer needed
- **Use different key sizes** based on security requirements

### File Permissions
Ensure correct permissions for SSH files:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa_*
chmod 644 ~/.ssh/id_rsa_*.pub
chmod 600 ~/.ssh/config
```

### Key Types and Sizes

| Key Type | Recommended Size | Use Case |
|----------|------------------|----------|
| RSA | 4096 bits | General use, maximum compatibility |
| Ed25519 | N/A (fixed) | Modern, faster, smaller keys |
| ECDSA | 521 bits | Corporate environments |

```bash
# Generate Ed25519 key (modern alternative)
ssh-keygen -t ed25519 -C "your.email@example.com" -f ~/.ssh/id_ed25519_work

# Generate ECDSA key (if required)
ssh-keygen -t ecdsa -b 521 -C "your.email@example.com" -f ~/.ssh/id_ecdsa_work
```

## Automation Scripts

### Auto-load SSH Keys on Login

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# Auto-start SSH agent and load keys
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent -t 1h > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi
if [[ ! "$SSH_AUTH_SOCK" ]]; then
    source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
fi

# Load SSH keys if not already loaded
ssh-add -l >/dev/null || {
    ssh-add ~/.ssh/id_rsa_work 2>/dev/null
    ssh-add ~/.ssh/id_rsa_personal 2>/dev/null
}
```

### SSH Key Generation Script

```bash
#!/bin/bash
# generate-ssh-key.sh

PROFILE=$1
EMAIL=$2

if [[ -z "$PROFILE" || -z "$EMAIL" ]]; then
    echo "Usage: $0 <profile_name> <email>"
    exit 1
fi

KEY_PATH="$HOME/.ssh/id_rsa_$PROFILE"

ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f "$KEY_PATH"
ssh-add "$KEY_PATH"

echo "Public key for $PROFILE profile:"
cat "$KEY_PATH.pub"
```

## Integration with Git Profiles

Your Git profile should reference the SSH configuration:

```ini
[core]
    sshCommand = ssh -i ~/.ssh/id_rsa_work -F /dev/null

# Alternative: use SSH config host aliases
[url "git@github.com-work:"]
    insteadOf = git@github.com:
```

This ensures that when Git operations are performed in directories using this profile, the correct SSH key is automatically used.

## Related Documentation

- [Git Configuration Guide](../README.md)
- [GPG Setup Guide](gpg-setup.md)
- [Troubleshooting Guide](troubleshooting.md)