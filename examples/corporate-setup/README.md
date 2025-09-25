# Corporate Git Setup Example

This example shows how to configure Git profiles for a corporate environment with separate work and personal identities.

## Scenario

- **Developer**: John Doe
- **Company**: TechCorp Inc.
- **Personal GitHub**: john-doe-personal
- **Corporate GitHub**: john.doe@techcorp.com (part of TechCorp GitHub organization)
- **Directory Structure**:
  ```
  ~/repositories/
  ├── work/           # Corporate projects
  ├── personal/       # Personal projects
  └── oss/           # Open source contributions
  ```

## Configuration Files

### Global Git Config (`~/.gitconfig`)

```ini
[user]
    # Default identity (personal)
    name = John Doe
    email = john@personal-domain.com

[init]
    defaultBranch = main

[core]
    editor = code --wait
    autocrlf = input

[pull]
    rebase = false

[push]
    default = simple
    autoSetupRemote = true

[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    lg = log --oneline --graph --decorate --all

# Conditional includes
[includeIf "gitdir:~/repositories/work/"]
    path = ~/.config/git/profiles/work

[includeIf "gitdir:~/repositories/personal/"]
    path = ~/.config/git/profiles/personal

[includeIf "gitdir:~/repositories/oss/"]
    path = ~/.config/git/profiles/oss
```

### Work Profile (`~/.config/git/profiles/work`)

```ini
[user]
    name = John Doe
    email = john.doe@techcorp.com
    signingkey = 1A2B3C4D5E6F7890  # Corporate GPG key

[core]
    sshCommand = ssh -i ~/.ssh/id_rsa_work -F /dev/null

[commit]
    gpgsign = true  # Corporate requirement

[alias]
    # Work-specific aliases
    standup = log --since='yesterday' --author='john.doe@techcorp.com' --oneline --no-merges
    work-log = log --author='john.doe@techcorp.com' --since='1 week ago' --oneline
    review = diff --cached
    company-clone = clone git@github.com-work:techcorp/

[url "git@github.com-work:"]
    # Route TechCorp repos through work SSH key
    insteadOf = git@github.com:techcorp/

[tag]
    sort = version:refname

[branch]
    autoSetupMerge = always
```

### Personal Profile (`~/.config/git/profiles/personal`)

```ini
[user]
    name = John Doe
    email = john@personal-domain.com
    signingkey = 9Z8Y7X6W5V4U3210  # Personal GPG key

[core]
    sshCommand = ssh -i ~/.ssh/id_rsa_personal -F /dev/null

[commit]
    gpgsign = true

[alias]
    # Personal project aliases
    publish = !git push -u origin $(git branch --show-current)
    save = commit -am "WIP: saved progress"
    undo = reset --soft HEAD~1
    cleanup = !git branch --merged | grep -v '\\*\\|main\\|master' | xargs -n 1 git branch -d

[url "git@github.com-personal:"]
    insteadOf = git@github.com:john-doe-personal/

[push]
    default = upstream

[branch]
    autoSetupRebase = always
```

### Open Source Profile (`~/.config/git/profiles/oss`)

```ini
[user]
    name = John Doe
    email = john.doe.oss@gmail.com  # Separate OSS email
    signingkey = 9Z8Y7X6W5V4U3210  # Personal GPG key

[core]
    sshCommand = ssh -i ~/.ssh/id_rsa_personal -F /dev/null

[commit]
    gpgsign = true

[alias]
    # OSS contribution aliases
    fork-clone = !gh repo fork --clone=true
    pr-create = !gh pr create --web
    contribute = !git checkout -b feature/$(date +%Y%m%d)-
```

## SSH Configuration (`~/.ssh/config`)

```ssh
# Work GitHub (TechCorp)
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

# Default GitHub (routes to personal)
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa_personal
    IdentitiesOnly yes

# Corporate GitLab (if used)
Host gitlab.techcorp.com
    HostName gitlab.techcorp.com
    User git
    IdentityFile ~/.ssh/id_rsa_work
    IdentitiesOnly yes
    Port 22
```

## SSH Key Setup

```bash
# Generate work SSH key
ssh-keygen -t rsa -b 4096 -C "john.doe@techcorp.com" -f ~/.ssh/id_rsa_work

# Generate personal SSH key  
ssh-keygen -t rsa -b 4096 -C "john@personal-domain.com" -f ~/.ssh/id_rsa_personal

# Add keys to SSH agent
ssh-add ~/.ssh/id_rsa_work
ssh-add ~/.ssh/id_rsa_personal

# Test connections
ssh -T git@github.com-work    # Should authenticate as TechCorp employee
ssh -T git@github.com-personal # Should authenticate as personal account
```

## Directory Structure and Testing

```bash
# Create directory structure
mkdir -p ~/repositories/{work,personal,oss}

# Test work profile
cd ~/repositories/work
git config user.email  # Should show: john.doe@techcorp.com
git config user.name   # Should show: John Doe

# Test personal profile  
cd ~/repositories/personal
git config user.email  # Should show: john@personal-domain.com

# Test OSS profile
cd ~/repositories/oss
git config user.email  # Should show: john.doe.oss@gmail.com
```

## Workflow Examples

### Corporate Project Workflow

```bash
# Work on corporate project
cd ~/repositories/work

# Clone corporate repository (uses work SSH key automatically)
git clone git@github.com:techcorp/secret-project.git
cd secret-project

# Verify correct identity
git config user.email  # john.doe@techcorp.com

# Make commits (will be signed with corporate GPG key)
git add .
git commit -m "Implement feature X"  # Auto-signed

# View work activity
git standup  # Custom alias for daily standup
```

### Personal Project Workflow

```bash
# Work on personal project
cd ~/repositories/personal

# Clone personal repository
git clone git@github.com:john-doe-personal/my-project.git
cd my-project

# Verify correct identity  
git config user.email  # john@personal-domain.com

# Quick save work in progress
git save  # Custom alias: commit -am "WIP: saved progress"

# Publish feature branch
git checkout -b new-feature
git add .
git commit -m "Add new feature"
git publish  # Custom alias: push -u origin current-branch
```

### Open Source Contribution Workflow

```bash
# Contribute to open source project
cd ~/repositories/oss

# Fork and clone project
gh repo fork awesome-project/main --clone=true
cd main

# Verify OSS identity
git config user.email  # john.doe.oss@gmail.com

# Create contribution branch
git contribute  # Custom alias creates timestamped branch
git add .
git commit -m "Fix issue #123"

# Create pull request
git push origin feature/20250925-fix-issue-123
git pr-create  # Opens web interface for PR creation
```

## Corporate Compliance Features

### Required GPG Signing

All work commits are automatically signed with the corporate GPG key:

```bash
# Verify signatures
git log --show-signature

# Check signing key
git config user.signingkey  # In work directory: 1A2B3C4D5E6F7890
```

### Audit Trail

Corporate profile maintains clear audit trail:

```bash
# View all work commits by author
git work-log

# Generate weekly report
git log --author='john.doe@techcorp.com' --since='1 week ago' --pretty=format:'%h - %s (%ar)'
```

### SSH Key Isolation

Work SSH key is completely separate from personal key:
- Different key files (`id_rsa_work` vs `id_rsa_personal`)
- Different SSH host aliases (`github.com-work` vs `github.com-personal`) 
- Corporate key can be managed/rotated independently
- Personal projects never use corporate credentials

## Security Benefits

1. **Identity Isolation**: Work and personal identities never cross-contaminate
2. **Key Separation**: Separate SSH keys prevent unauthorized access
3. **Audit Compliance**: Clear trail of corporate vs personal contributions
4. **Selective Signing**: Different GPG keys for different contexts
5. **Access Control**: Corporate repositories only accessible with work credentials

This setup ensures compliance with corporate policies while maintaining developer productivity and clear separation of concerns.