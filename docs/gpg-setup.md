# 🔐 GPG Setup Guide

This guide explains how to set up GPG (GNU Privacy Guard) signing for different Git profiles to ensure commit authenticity and integrity.

## Overview

GPG signing provides:
- **Commit Authentication**: Proves commits were made by the key holder
- **Integrity Verification**: Ensures commits haven't been tampered with
- **Trust Chain**: Builds trust through key verification
- **Compliance**: Meets corporate security requirements

## Why Use GPG with Multiple Profiles?

- **Identity Separation**: Different keys for work vs personal commits
- **Security**: Isolate keys based on security requirements
- **Compliance**: Meet different organizational policies
- **Trust Management**: Control which keys are trusted in different contexts

## Prerequisites

### Install GPG
```bash
# Ubuntu/Debian
sudo apt install gnupg2

# macOS
brew install gnupg

# CentOS/RHEL
sudo yum install gnupg2

# Verify installation
gpg --version
```

### Configure GPG (if first time)
```bash
# Create GPG directory with correct permissions
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg

# Set secure permissions for GPG config
touch ~/.gnupg/gpg.conf
chmod 600 ~/.gnupg/gpg.conf
```

## Step-by-Step Setup

### 1. Generate GPG Keys for Each Profile

#### Work Profile GPG Key
```bash
# Generate work GPG key
gpg --full-generate-key
```

**Key Generation Settings:**
```
Please select what kind of key you want:
   (1) RSA and RSA (default)
   
What keysize do you want? (3072) 4096

Please specify how long the key should be valid.
   0 = key does not expire (recommended for work keys)

Real name: Your Professional Name
Email address: your.work@company.com
Comment: Work GPG key for company commits

# Set a strong passphrase when prompted
```

#### Personal Profile GPG Key
```bash
# Generate personal GPG key
gpg --full-generate-key
```

**Settings for personal key:**
```
Real name: Your Name  
Email address: your.personal@email.com
Comment: Personal GPG key for personal projects
```

#### Client Profile GPG Key (if needed)
```bash
# Generate client-specific GPG key
gpg --full-generate-key
```

**Settings for client key:**
```
Real name: Your Professional Name
Email address: your.name@client-domain.com
Comment: GPG key for ClientName projects
```

### 2. List and Identify Your Keys

```bash
# List all GPG keys with key IDs
gpg --list-secret-keys --keyid-format=long

# Example output:
# sec   rsa4096/1A2B3C4D5E6F7890 2025-09-25 [SC]
#       Key fingerprint = ABCD EFGH IJKL MNOP QRST UVWX 1A2B 3C4D 5E6F 7890
# uid                 [ultimate] Your Name (Work) <your.work@company.com>
# ssb   rsa4096/9Z8Y7X6W5V4U3210 2025-09-25 [E]
```

**Key ID Identification:**
- **Full fingerprint**: `ABCD EFGH IJKL MNOP QRST UVWX 1A2B 3C4D 5E6F 7890`
- **Long key ID**: `1A2B3C4D5E6F7890` (use this for Git configuration)
- **Short key ID**: `5E6F7890` (avoid using, less secure)

### 3. Export Public Keys

#### Export to Clipboard (for GitHub/GitLab)
```bash
# Export work public key
gpg --armor --export 1A2B3C4D5E6F7890

# Export personal public key  
gpg --armor --export 9Z8Y7X6W5V4U3210
```

#### Save to Files
```bash
# Create directory for public keys
mkdir -p ~/gpg-public-keys

# Export work public key to file
gpg --armor --export 1A2B3C4D5E6F7890 > ~/gpg-public-keys/work-public.asc

# Export personal public key to file
gpg --armor --export 9Z8Y7X6W5V4U3210 > ~/gpg-public-keys/personal-public.asc
```

### 4. Add Public Keys to Git Services

#### GitHub
1. Go to **Settings** → **SSH and GPG keys**
2. Click **New GPG key**
3. Paste the public key content
4. Add descriptive title (e.g., "Work Laptop GPG - 2025")

#### GitLab
1. Go to **Preferences** → **GPG Keys**
2. Paste the public key content
3. Click **Add key**

#### Bitbucket
1. Go to **Personal settings** → **GPG Keys**
2. Click **Add key**
3. Paste the public key content

### 5. Configure Git Profiles with GPG Signing

#### Work Profile Configuration
```ini
# ~/.config/git/profiles/work
[user]
    name = Your Professional Name
    email = your.work@company.com
    signingkey = 1A2B3C4D5E6F7890

[commit]
    gpgsign = true

[tag]
    gpgSign = true
```

#### Personal Profile Configuration
```ini
# ~/.config/git/profiles/personal
[user]
    name = Your Name
    email = your.personal@email.com
    signingkey = 9Z8Y7X6W5V4U3210

[commit]
    gpgsign = true

[tag]
    gpgSign = true
```

### 6. Test GPG Signing

#### Test in Work Directory
```bash
cd ~/repositories/work

# Check GPG configuration
git config user.signingkey
git config commit.gpgsign

# Test commit signing
git init test-gpg-work
cd test-gpg-work
echo "test" > test.txt
git add test.txt
git commit -m "Test GPG signing for work profile"

# Verify signature
git log --show-signature
```

#### Test in Personal Directory
```bash
cd ~/repositories/personal

# Test signing with personal key
git init test-gpg-personal
cd test-gpg-personal
echo "test" > test.txt
git add test.txt
git commit -m "Test GPG signing for personal profile"

# Verify signature
git log --show-signature
```

## Advanced Configuration

### GPG Agent Configuration

Create or edit `~/.gnupg/gpg-agent.conf`:
```bash
# Cache passphrase for 8 hours
default-cache-ttl 28800
max-cache-ttl 28800

# Use pinentry for passphrase input
pinentry-program /usr/bin/pinentry-gtk-2

# Enable SSH support (optional)
enable-ssh-support
```

**Restart GPG agent:**
```bash
gpg-connect-agent reloadagent /bye
```

### Conditional GPG Signing

You can configure GPG signing to be conditional based on the repository:

#### Global Configuration with Selective Signing
```ini
# ~/.gitconfig
[user]
    name = Your Name
    email = your.default@email.com

# Default: no signing
[commit]
    gpgsign = false

# Work profile: always sign
[includeIf "gitdir:~/repositories/work/"]
    path = ~/.config/git/profiles/work-with-signing

# Personal profile: always sign  
[includeIf "gitdir:~/repositories/personal/"]
    path = ~/.config/git/profiles/personal-with-signing
```

### Multiple GPG Keys per Profile

For complex setups with multiple clients:

```ini
# Client A profile
[user]
    name = Your Name
    email = your.name@client-a.com
    signingkey = AAAA1111BBBB2222

# Client B profile  
[user]
    name = Your Name
    email = your.name@client-b.com
    signingkey = CCCC3333DDDD4444
```

## Key Management

### Key Backup and Recovery

#### Export Private Keys (Backup)
```bash
# Export private key (KEEP SECURE!)
gpg --armor --export-secret-keys 1A2B3C4D5E6F7890 > work-private-key-backup.asc

# Store in secure location (encrypted drive, password manager, etc.)
```

#### Import Keys (Recovery)
```bash
# Import private key
gpg --import work-private-key-backup.asc

# Trust the imported key
gpg --edit-key 1A2B3C4D5E6F7890
# At gpg> prompt: trust
# Select trust level: 5 = I trust ultimately
# At gpg> prompt: quit
```

### Key Rotation

#### Generate New Key
```bash
# Generate replacement key
gpg --full-generate-key

# Export new public key
gpg --armor --export NEW_KEY_ID > new-work-public.asc
```

#### Update Git Configuration
```bash
# Update signing key in profile
git config user.signingkey NEW_KEY_ID

# Update service (GitHub/GitLab)
# Add new public key to service
# Remove old public key from service
```

#### Revoke Old Key
```bash
# Generate revocation certificate
gpg --gen-revoke OLD_KEY_ID > revocation-cert.asc

# Import and publish revocation
gpg --import revocation-cert.asc
gpg --send-keys OLD_KEY_ID  # If using keyserver
```

## Verification and Validation

### Verify Commit Signatures

#### Check Individual Commits
```bash
# Show signature for specific commit
git show --show-signature HEAD

# Log with signature verification
git log --show-signature --oneline -10
```

#### Verify All Commits in Branch
```bash
# Verify all commits since main
git log --show-signature main..feature-branch

# Check signature status
git verify-commit HEAD
```

### Validate GPG Setup

#### Quick GPG Test
```bash
# Test GPG functionality
echo "GPG test" | gpg --clearsign --default-key 1A2B3C4D5E6F7890

# Test with specific key
gpg --sign --armor --default-key 1A2B3C4D5E6F7890 --output test.sig test.txt
gpg --verify test.sig
```

## Troubleshooting

### Common Issues

#### "gpg: signing failed: No secret key"
```bash
# Check if key exists
gpg --list-secret-keys

# Check Git signing key configuration
git config user.signingkey

# Fix: Set correct signing key
git config user.signingkey CORRECT_KEY_ID
```

#### "gpg: signing failed: Inappropriate ioctl for device"
```bash
# Set GPG_TTY environment variable
export GPG_TTY=$(tty)

# Add to shell profile (~/.bashrc or ~/.zshrc)
echo 'export GPG_TTY=$(tty)' >> ~/.bashrc
```

#### Passphrase Caching Issues
```bash
# Clear GPG agent cache
gpg-connect-agent reloadagent /bye

# Test passphrase prompt
gpg --sign --armor --default-key YOUR_KEY_ID --output test.sig test.txt
```

#### Wrong Key Being Used
```bash
# Check effective configuration
git config --get-regexp "user\.signing|commit\.gpg"

# Force specific key for commit
git commit -S KEY_ID -m "Commit message"
```

### GPG Agent Issues

#### Start GPG Agent
```bash
# Start agent manually
gpg-agent --daemon

# Or restart
gpgconf --kill gpg-agent
gpg-agent --daemon
```

#### Reset GPG Agent
```bash
# Kill all GPG processes
gpgconf --kill all

# Restart GPG agent
gpg-agent --daemon --enable-ssh-support
```

## Security Best Practices

### Key Security
- **Use strong passphrases** (12+ characters, mixed case, numbers, symbols)
- **Set key expiration dates** (1-2 years for work keys)
- **Backup private keys securely** (encrypted storage)
- **Use different keys for different contexts** (work/personal separation)

### Passphrase Management
- **Use password manager** for GPG passphrases
- **Set reasonable cache timeouts** (not too long for security)
- **Disable passphrase caching** on shared systems

### Key Distribution
- **Verify key fingerprints** before trusting
- **Use secure channels** for key exchange
- **Publish public keys** to keyservers for verification
- **Maintain revocation certificates** for compromised keys

## Integration with Development Workflow

### Automated Signing
```bash
# Enable signing for all commits in a repository
git config commit.gpgsign true

# Sign specific commit
git commit -S -m "Signed commit message"

# Sign tag
git tag -s v1.0.0 -m "Signed release v1.0.0"
```

### CI/CD Integration
```bash
# Verify signatures in CI pipeline
git verify-commit HEAD

# Check all commits in PR
git log --show-signature origin/main..HEAD
```

## Related Documentation

- [SSH Setup Guide](ssh-setup.md)
- [Troubleshooting Guide](troubleshooting.md)
- [Main README](../README.md)
- [GNU Privacy Guard Documentation](https://gnupg.org/documentation/)