# Open Source Contributor Setup Example

This example demonstrates how to configure Git profiles for an active open source contributor who maintains separate identities for different types of contributions.

## Scenario

- **Developer**: Sarah Chen
- **Personal GitHub**: sarah-chen-dev
- **Professional GitHub**: s.chen@techcorp.com (for work-related OSS contributions)
- **OSS Maintainer**: sarah@opensourceproject.org (for projects she maintains)
- **Directory Structure**:
  ```
  ~/repositories/
  ├── work/              # Corporate projects (company identity)
  ├── personal/          # Personal projects (personal identity)  
  ├── oss-contrib/       # Contributing to other OSS projects (personal identity)
  ├── oss-maintain/      # OSS projects she maintains (maintainer identity)
  └── experiments/       # Quick experiments (personal identity)
  ```

## Configuration Files

### Global Git Config (`~/.gitconfig`)

```ini
[user]
    # Default identity (personal)
    name = Sarah Chen
    email = sarah.chen.dev@gmail.com
    signingkey = ABC123DEF456  # Personal GPG key

[init]
    defaultBranch = main

[core]
    editor = nvim
    autocrlf = input
    filemode = true
    pager = delta

[commit]
    gpgsign = true  # Always sign commits for OSS work

[pull]
    rebase = true  # Cleaner history for OSS projects

[push]
    default = simple
    autoSetupRemote = true
    followTags = true  # Important for release management

[merge]
    tool = vimdiff
    conflictstyle = diff3

[diff]
    colorMoved = default
    algorithm = patience

[alias]
    # OSS contributor focused aliases
    st = status --short --branch
    co = checkout
    br = branch -vv
    ci = commit -S  # Always sign
    amend = commit --amend --no-edit -S
    
    # History and analysis
    lg = log --oneline --graph --decorate --all
    contributors = log --format='%aN <%aE>' --reverse | sort -u
    release-notes = log --pretty=format:'- %s (%an)' --no-merges
    
    # OSS workflow helpers
    upstream = remote add upstream
    sync-upstream = !git fetch upstream && git checkout main && git merge upstream/main
    pr-branch = checkout -b feature/
    cleanup-merged = !git branch --merged main | grep -v main | xargs git branch -d
    
    # Contribution analysis
    my-commits = log --author='sarah.chen.dev@gmail.com' --oneline --no-merges
    weekly-contrib = log --author='sarah.chen.dev@gmail.com' --since='1 week ago' --oneline
    monthly-stats = log --author='sarah.chen.dev@gmail.com' --since='1 month ago' --oneline --stat

[url "git@github.com:"]
    insteadOf = https://github.com/

# Conditional includes for different project types
[includeIf "gitdir:~/repositories/work/"]
    path = ~/.config/git/profiles/work

[includeIf "gitdir:~/repositories/oss-maintain/"]
    path = ~/.config/git/profiles/oss-maintainer
```

### Work Profile (`~/.config/git/profiles/work`)

```ini
# Professional OSS contributions (company-sponsored work)
[user]
    name = Sarah Chen
    email = s.chen@techcorp.com
    signingkey = XYZ789ABC123  # Company GPG key

[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_work -F /dev/null

[commit]
    gpgsign = true

[alias]
    # Work-focused aliases
    work-log = log --author='s.chen@techcorp.com' --since='1 week ago' --oneline
    standup = log --since='yesterday' --author='s.chen@techcorp.com' --oneline --no-merges

[url "git@github-work:"]
    insteadOf = git@github.com:
```

### OSS Maintainer Profile (`~/.config/git/profiles/oss-maintainer`)

```ini
# Identity for projects she maintains
[user]
    name = Sarah Chen
    email = sarah@opensourceproject.org
    signingkey = ABC123DEF456  # Same personal GPG key

[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_oss -F /dev/null

[commit]
    gpgsign = true
    template = ~/.config/git/commit-template-maintainer

[tag]
    gpgsign = true  # Sign release tags

[alias]
    # Maintainer workflow aliases
    release-prep = !git fetch --tags && git log --oneline $(git describe --tags --abbrev=0)..HEAD
    tag-release = tag -s -m "Release version"
    security-log = log --grep="security\|CVE\|vulnerability" --oneline
    
    # Review helpers
    review-branch = log --oneline --graph origin/main..HEAD
    files-changed = diff --name-only origin/main..HEAD
    
    # Community management
    first-time-contributors = log --format='%aN' --reverse | sort | uniq -c | sort -n | grep "^ *1 "
```

## SSH Configuration (`~/.ssh/config`)

```ssh
# Default personal GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal
    IdentitiesOnly yes

# Work GitHub (company projects)
Host github-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work
    IdentitiesOnly yes

# OSS projects maintained
Host github-oss
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_oss
    IdentitiesOnly yes

# GitLab for some OSS projects
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal
    IdentitiesOnly yes

# Codeberg for privacy-focused projects
Host codeberg.org
    HostName codeberg.org
    User git
    IdentityFile ~/.ssh/id_ed25519_personal
    IdentitiesOnly yes
```

## GPG Configuration

### Multiple GPG Keys for Different Contexts

```bash
# List GPG keys
gpg --list-secret-keys --keyid-format=long

# Personal key (for personal and maintained projects)
sec   ed25519/ABC123DEF456 2024-01-01 [SC] [expires: 2026-01-01]
uid   [ultimate] Sarah Chen <sarah.chen.dev@gmail.com>
uid   [ultimate] Sarah Chen <sarah@opensourceproject.org>
ssb   cv25519/DEF456GHI789 2024-01-01 [E] [expires: 2026-01-01]

# Work key (for company OSS contributions)
sec   ed25519/XYZ789ABC123 2024-01-01 [SC] [expires: 2025-12-31]
uid   [ultimate] Sarah Chen <s.chen@techcorp.com>
ssb   cv25519/GHI789JKL012 2024-01-01 [E] [expires: 2025-12-31]
```

## Commit Message Templates

### Personal/Contrib Template (`~/.config/git/commit-template-default`)

```
# Type: Brief description (50 chars max)
#
# Detailed explanation (wrap at 72 chars)
# - Why this change is needed
# - What it solves or improves
# - Any breaking changes
#
# Closes #issue-number
# Co-authored-by: Name <email@example.com>
```

### Maintainer Template (`~/.config/git/commit-template-maintainer`)

```
# [TYPE] Brief description (50 chars max)
#
# Types: feat, fix, docs, style, refactor, test, chore, security
#
# Detailed explanation (wrap at 72 chars)
# - Impact on users/API
# - Breaking changes (if any)
# - Migration notes (if needed)
#
# Fixes #issue-number
# Closes #pr-number
# Reviewed-by: Name <email@example.com>
# Signed-off-by: Sarah Chen <sarah@opensourceproject.org>
```

## Workflow Examples

### Contributing to External OSS Project

```bash
# Clone and set up for contribution
cd ~/repositories/oss-contrib/
git clone https://github.com/external/awesome-project.git
cd awesome-project

# Verify correct identity (should use personal email)
git config user.email  # Should show: sarah.chen.dev@gmail.com

# Set up upstream and create feature branch
git upstream https://github.com/external/awesome-project.git
git pr-branch fix-memory-leak

# Make changes, commit with signature
git add .
git ci -m "fix: resolve memory leak in data processing

- Fixed buffer overflow in process_data() function
- Added bounds checking for input validation
- Includes regression test for edge cases

Fixes #1234"

# Push and create PR
git push origin feature/fix-memory-leak
```

### Maintaining Own OSS Project

```bash
# Work on maintained project
cd ~/repositories/oss-maintain/my-cli-tool

# Verify maintainer identity
git config user.email  # Should show: sarah@opensourceproject.org

# Prepare release
git release-prep
git tag-release v2.1.0

# Security patch workflow
git security-log  # Review security-related commits
git log --grep="CVE-2024" --oneline
```

### Company OSS Contribution

```bash
# Work project with company identity
cd ~/repositories/work/company-oss-contrib

# Verify work identity
git config user.email  # Should show: s.chen@techcorp.com
git config core.sshCommand  # Should show work SSH key

# Company contribution workflow
git work-log  # See this week's work contributions
```

## Automation Scripts

### Daily OSS Workflow Script (`~/bin/oss-daily`)

```bash
#!/bin/bash
# Daily OSS maintenance routine

echo "🔍 OSS Contribution Summary"
echo "=========================="

# Check contributions across all repos
for repo in ~/repositories/oss-contrib/*/; do
    if [[ -d "$repo/.git" ]]; then
        cd "$repo"
        commits=$(git my-commits --since='1 day ago' | wc -l)
        if [[ $commits -gt 0 ]]; then
            echo "📝 $repo: $commits commits"
        fi
    fi
done

# Check maintained projects for issues/PRs
echo -e "\n🛠️  Maintained Projects Status"
echo "============================="

for repo in ~/repositories/oss-maintain/*/; do
    if [[ -d "$repo/.git" ]]; then
        cd "$repo"
        echo "📂 $(basename "$repo")"
        
        # Check for new commits since last check
        new_commits=$(git log --since='1 day ago' --oneline | wc -l)
        echo "  New commits: $new_commits"
        
        # Check if ahead of origin
        ahead=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "0")
        if [[ $ahead -gt 0 ]]; then
            echo "  ⚡ $ahead commits ahead of origin"
        fi
    fi
done

echo -e "\n✨ Happy contributing!"
```

## Security Considerations

### GPG Key Management
- **Separate keys** for work and personal contributions
- **Key expiration** set appropriately (1-2 years)
- **Backup keys** stored securely offline
- **Subkeys** for different purposes (signing, encryption)

### SSH Key Security
- **Ed25519 keys** for better security
- **Different keys** per context (work/personal/maintained projects)
- **SSH agent** configured with appropriate timeouts
- **Key passphrases** stored in secure password manager

### Email Privacy
- **Separate emails** for different contribution contexts
- **GitHub email privacy** enabled for personal contributions
- **Work email** only for company-sponsored OSS work
- **Project-specific emails** for maintained projects

## Contribution Guidelines Integration

### Pre-commit Hooks Setup

```bash
# Install pre-commit (if using)
pip install pre-commit

# Example .pre-commit-config.yaml for maintained projects
cat > .pre-commit-config.yaml << EOF
repos:
- repo: https://github.com/pre-commit/pre-commit-hooks
  rev: v4.4.0
  hooks:
  - id: trailing-whitespace
  - id: end-of-file-fixer
  - id: check-merge-conflict
  - id: check-case-conflict

- repo: https://github.com/commitizen-tools/commitizen
  rev: v3.2.0
  hooks:
  - id: commitizen
EOF

pre-commit install
```

### Conventional Commits for Maintained Projects

```bash
# Set up commitizen for consistent commit messages
pip install commitizen

# Configure in maintained projects
cat > .cz.yaml << EOF
commitizen:
  name: cz_conventional_commits
  tag_format: v$major.$minor.$patch
  version_scheme: semver
  version_provider: git
  update_changelog_on_bump: true
EOF
```

## Community Engagement

### Issue Templates for Maintained Projects

Create `.github/ISSUE_TEMPLATE/` with standardized templates:
- Bug reports
- Feature requests  
- Security vulnerabilities
- Documentation improvements

### Pull Request Templates

```markdown
<!-- .github/pull_request_template.md -->
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change)
- [ ] New feature (non-breaking change)  
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tests pass locally
- [ ] New tests added for new functionality
- [ ] Documentation updated

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] No new warnings introduced
```

This setup enables Sarah to:
- ✅ **Maintain clear identity separation** between personal, work, and maintained projects
- ✅ **Contribute effectively** to external OSS projects with proper attribution
- ✅ **Manage her own projects** with maintainer-level workflows
- ✅ **Sign all commits** for authenticity and security
- ✅ **Use appropriate SSH keys** for different contexts
- ✅ **Follow OSS best practices** for community engagement