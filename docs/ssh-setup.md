# 🔑 SSH Key Setup Guide# 🔑 SSH Key Setup Guide



This guide explains the modern SSH key setup for Git multi-profile system.This guide explains the modern SSH key setup for Git multi-profile system.



## Overview## Overview



This project uses **core.sshCommand** approach - a simplified and reliable method that doesn't require SSH config files or URL rewriting.This project uses **core.sshCommand** approach - a simplified and reliable method that doesn't require SSH config files or URL rewriting.



## Why This Approach?## Why This Approach?



### ✅ Benefits of core.sshCommand:### ✅ Benefits of core.sshCommand:

- **Universal**: Works with all Git hosting services (GitHub, GitLab, Bitbucket, etc.)- **Universal**: Works with all Git hosting services (GitHub, GitLab, Bitbucket, etc.)

- **Simple**: No complex SSH config files to maintain- **Simple**: No complex SSH config files to maintain

- **Reliable**: No conflicts between different SSH configurations  - **Reliable**: No conflicts between different SSH configurations  

- **Automatic**: Per-profile SSH key selection handled by Git- **Automatic**: Per-profile SSH key selection handled by Git

- **Clean**: No URL rewriting or aliases needed- **Clean**: No URL rewriting or aliases needed



### ❌ Problems with old SSH config approach:### ❌ Problems with old SSH config approach:

- Complex ~/.ssh/config files- Complex ~/.ssh/config files

- SSH aliases (github.com-work, gitlab.com-personal)- SSH aliases (github.com-work, gitlab.com-personal)

- URL rewrite rules needed- URL rewrite rules needed

- Hard to troubleshoot conflicts- Hard to troubleshoot conflicts



## Automated Setup## Automated Setup



The `setup-profiles.sh` script handles everything automatically:The `setup-profiles.sh` script handles everything automatically:



```bash```bash

# Run the interactive setup wizard# Run the interactive setup wizard

./scripts/setup-profiles.sh./scripts/setup-profiles.sh

```

# Client profile (replace 'client' with actual client name)

## What the Script Doesssh-keygen -t rsa -b 4096 -C "your.email@client.com" -f ~/.ssh/id_rsa_client

```

1. **Generates SSH Keys**: Creates Ed25519 or RSA keys per profile

2. **Configures Git Profiles**: Adds `core.sshCommand` to each profile  **Key Generation Options:**

3. **Shows Public Keys**: Displays keys to add to Git hosting services- `-t rsa`: Key type (RSA is widely supported)

4. **Tests Configuration**: Validates the setup works correctly- `-b 4096`: Key size (4096 bits for enhanced security)

- `-C "email"`: Comment (typically your email)

## Manual Key Management- `-f filename`: Output filename



If you need to check your keys manually:### 2. Add SSH Keys to SSH Agent



```bash```bash

# List generated keys# Start SSH agent

ls ~/.ssh/id_*eval "$(ssh-agent -s)"



# View public key (copy this to GitHub/GitLab)# Add keys to agent

cat ~/.ssh/id_ed25519_work.pubssh-add ~/.ssh/id_rsa_work

cat ~/.ssh/id_ed25519_personal.pubssh-add ~/.ssh/id_rsa_personal

```ssh-add ~/.ssh/id_rsa_client



## How It Works# List loaded keys

ssh-add -l

Each Git profile gets its own SSH configuration:```



```ini### 3. Configure SSH Config File

# Example: ~/.config/git/profiles/work

[user]Create or edit `~/.ssh/config` to define host aliases:

    name = Your Name

    email = work@company.com```ssh

# Work GitHub

[core]Host github.com-work

    sshCommand = ssh -i ~/.ssh/id_ed25519_work -o IdentitiesOnly=yes    HostName github.com

    User git

# Example: ~/.config/git/profiles/personal      IdentityFile ~/.ssh/id_rsa_work

[user]    IdentitiesOnly yes

    name = Your Name

    email = personal@email.com# Personal GitHub

Host github.com-personal

[core]    HostName github.com

    sshCommand = ssh -i ~/.ssh/id_ed25519_personal -o IdentitiesOnly=yes    User git

```    IdentityFile ~/.ssh/id_rsa_personal

    IdentitiesOnly yes

## Adding Keys to Git Hosting Services

# Client GitLab

### GitHubHost gitlab.com-client

1. Copy your public key: `cat ~/.ssh/id_ed25519_work.pub`    HostName gitlab.com

2. Go to GitHub → Settings → SSH and GPG keys    User git

3. Click "New SSH key" and paste the public key## What the Script Does



### GitLab1. **Generates SSH Keys**: Creates Ed25519 or RSA keys per profile

1. Copy your public key: `cat ~/.ssh/id_ed25519_personal.pub`2. **Configures Git Profiles**: Adds `core.sshCommand` to each profile  

2. Go to GitLab → Preferences → SSH Keys  3. **Shows Public Keys**: Displays keys to add to Git hosting services

3. Paste the key and give it a title4. **Tests Configuration**: Validates the setup works correctly



### Testing SSH Connection## Manual Key Management



```bashIf you need to check your keys manually:

# Test connection (will use the appropriate key automatically)

ssh -T git@github.com```bash

ssh -T git@gitlab.com# List generated keys

```ls ~/.ssh/id_*



## Troubleshooting# View public key (copy this to GitHub/GitLab)

cat ~/.ssh/id_ed25519_work.pub

### Key Not Foundcat ~/.ssh/id_ed25519_personal.pub

```bash```

# Verify key exists

ls -la ~/.ssh/id_ed25519_*#### GitHub:

1. Go to Settings → SSH and GPG keys

# Check permissions2. Click "New SSH key"

chmod 600 ~/.ssh/id_ed25519_*3. Paste the public key content

chmod 644 ~/.ssh/id_ed25519_*.pub4. Give it a descriptive title (e.g., "Work Laptop - 2025")

```

#### GitLab:

### Connection Issues1. Go to Preferences → SSH Keys

```bash2. Paste the public key content

# Test with verbose output3. Add a title and optional expiration date

ssh -vT git@github.com

#### Bitbucket:

# Check which key Git is trying to use1. Go to Personal settings → SSH keys

GIT_SSH_COMMAND="ssh -v" git ls-remote origin2. Click "Add key"

```3. Paste the public key content



### Multiple Keys Conflict### 5. Configure Git Profiles

The `IdentitiesOnly=yes` option ensures only the specified key is used, preventing conflicts.

In your Git profile configurations, specify which SSH key to use:

## Security Best Practices

```ini

- **Use Ed25519 keys** (modern, secure, fast)# Work profile (~/.config/git/profiles/work)

- **Set passphrases** on private keys[core]

- **Use ssh-agent** for convenience    sshCommand = ssh -i ~/.ssh/id_rsa_work -F /dev/null

- **Separate keys per context** (work/personal/client)

- **Regular key rotation** (annually recommended)[url "git@github.com-work:"]

    insteadOf = git@github.com:company-org/

## Migration from SSH Config

# Personal profile (~/.config/git/profiles/personal)  

If you're migrating from the old SSH config approach:[core]

    sshCommand = ssh -i ~/.ssh/id_rsa_personal -F /dev/null

```bash

# 1. Remove old SSH config entries[url "git@github.com-personal:"]

# Edit ~/.ssh/config and remove Host aliases    insteadOf = git@github.com:your-username/

```

# 2. Remove URL rewrites from Git configs  

# Check: git config --list | grep url## Testing SSH Connections



# 3. Run the setup script to configure core.sshCommandTest each SSH key configuration:

./scripts/setup-profiles.sh

```bash

# 4. Validate the new setup# Test work key

./scripts/validate-config.shssh -T git@github.com-work

```

# Test personal key

This modern approach is simpler, more reliable, and works universally with all Git hosting services.ssh -T git@github.com-personal

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