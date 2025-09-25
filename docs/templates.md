# Git Configuration Templates Guide

This document describes all template files used in the Git multi-profile setup system.

## Template Files Location

All template files are located in `configs/profiles/` directory:

```
configs/profiles/
├── global-template      # Global Git configuration
├── work-template       # Work profile template
├── personal-template   # Personal profile template
└── client-template     # Client profile template
```

## Template Files Overview

### 1. Global Template (`global-template`)

**Purpose:** Base Git configuration that applies globally with conditional includes for profiles.

**Key Features:**
- Default user identity (fallback when no profile matches)
- Global Git settings (init.defaultBranch, core.editor, etc.)
- Pull/push/merge/diff configurations
- Common aliases available across all profiles
- Placeholder for conditional includes (added by setup script)

**Usage:** Copied to `~/.gitconfig` during initial setup with user's default name/email.

**Template Variables:**
- `Your Name` → User's default name
- `your.email@example.com` → User's default email

### 2. Work Profile Template (`work-template`)

**Purpose:** Professional/work environment Git configuration.

**Key Features:**
- Work-specific user identity placeholder
- SSH configuration placeholder (added if SSH key generated)
- GPG signing configuration (commented by default)
- Work-focused aliases:
  - `standup` - Shows yesterday's commits by work email
  - `work-log` - Shows week's work commits
  - `review` - Shows staged changes
- URL rewriting for work repositories
- Professional tag and branch configurations

**Template Variables:**
- `Your Professional Name` → User's work name
- `your.name@company.com` → User's work email

**Dynamic Content:**
- SSH configuration added only if user generates SSH key
- SSH key type (RSA/Ed25519) determined by user choice

### 3. Personal Profile Template (`personal-template`)

**Purpose:** Personal projects Git configuration.

**Key Features:**
- Personal user identity placeholder
- SSH configuration placeholder (added if SSH key generated)
- GPG signing configuration (commented by default)
- Personal-focused aliases:
  - `publish` - Push current branch with upstream tracking
  - `save` - Quick commit with "WIP: saved progress" message
  - `undo` - Soft reset to previous commit
  - `cleanup` - Remove merged branches (excluding main/master)
- URL rewriting for personal repositories
- Personal workflow configurations (push.default, branch.autoSetupRebase)

**Template Variables:**
- `Your Name` → User's personal name
- `your.personal@email.com` → User's personal email

**Dynamic Content:**
- SSH configuration added only if user generates SSH key
- SSH key type (RSA/Ed25519) determined by user choice

### 4. Client Profile Template (`client-template`)

**Purpose:** Template for client-specific Git configurations.

**Key Features:**
- Client-specific user identity placeholder
- SSH configuration placeholder (added if SSH key generated)
- GPG signing configuration (commented, can be enabled per client requirements)
- Client-focused aliases and configurations
- Flexible structure for customization per client
- URL rewriting placeholder for client repositories

**Template Variables:**
- `Your Professional Name` → User's name for client work
- `your.name@client-domain.com` → User's client-specific email
- `CLIENT_SPECIFIC_GPG_KEY_ID` → Client's GPG key if required
- `client_name` → Actual client identifier

**Usage Note:** This is a template for creating multiple client profiles. Copy and customize for each client with specific settings.

## Template Processing

### Setup Script Behavior

1. **Template Selection:** Based on profile type (work/personal/client)
2. **Variable Replacement:** Replaces template variables with user input
3. **SSH Integration:** Adds SSH configuration only if user generates SSH key
4. **Dynamic Content:** Adapts to user choices (key type, directories, etc.)

### SSH Configuration Logic

Templates contain placeholder comment:
```gitconfig
[core]
    # SSH configuration will be added automatically if SSH key is generated
```

If user chooses to generate SSH key, the setup script adds:
```gitconfig
[core]
    # SSH configuration will be added automatically if SSH key is generated
    sshCommand = ssh -i /path/to/key -F /dev/null
```

Key path depends on user's choice:
- Ed25519: `~/.ssh/id_ed25519_profiletype`
- RSA 4096: `~/.ssh/id_rsa_profiletype`

### GPG Configuration

All templates include commented GPG configuration:
```gitconfig
[user]
    # Uncomment and set your GPG signing key
    # signingkey = YOUR_GPG_KEY_ID

[commit]
    # Enable GPG signing (uncomment if needed)
    # gpgsign = true
```

Users can manually uncomment and configure GPG signing as needed.

## Customization Guidelines

### Adding New Profile Templates

1. Create new template file in `configs/profiles/`
2. Follow naming convention: `{profiletype}-template`
3. Include standard sections: `[user]`, `[core]`, `[commit]`, `[alias]`
4. Use template variables for dynamic content
5. Add SSH placeholder comment in `[core]` section
6. Update setup script to handle new profile type

### Template Best Practices

1. **Variables:** Use descriptive placeholder names
2. **Comments:** Include helpful comments for optional features
3. **Aliases:** Choose aliases that don't conflict between profiles
4. **URLs:** Use profile-specific URL rewriting when possible
5. **Flexibility:** Keep templates generic enough for various use cases

### Template Validation

The `validate-config.sh` script checks:
- ✅ Profile file exists and is readable
- ✅ Required sections ([user]) are present
- ✅ Email format is valid
- ✅ SSH keys exist (if configured)
- ℹ️ GPG configuration (optional)
- ℹ️ No SSH configuration (if user skipped)

## Examples

### Creating Work Profile from Template

1. User runs setup script, chooses "work profile"
2. Script copies `work-template` to `~/.config/git/profiles/work`
3. Replaces `Your Professional Name` with user input
4. Replaces `your.name@company.com` with user input
5. If SSH key generated, adds SSH configuration
6. Adds conditional include to `~/.gitconfig`

### Result:
```gitconfig
[user]
    name = John Smith
    email = john.smith@company.com

[core]
    # SSH configuration will be added automatically if SSH key is generated
    sshCommand = ssh -i ~/.ssh/id_ed25519_work -F /dev/null

[alias]
    standup = log --since='yesterday' --author='john.smith@company.com' --oneline --no-merges
```

This documentation should be updated whenever template files are modified or new templates are added.