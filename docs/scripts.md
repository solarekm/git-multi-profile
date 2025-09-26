# Git Multi-Profile Scripts Documentation

This document provides comprehensive documentation for all scripts in the Git multi-profile configuration system.

## Scripts Overview

All scripts are located in the `scripts/` directory:

```
scripts/
├── setup-profiles.sh      # Interactive profile setup wizard (includes SSH key generation)
└── validate-config.sh     # Configuration validation tool
```

**Note**: This project was simplified - removed separate scripts for SSH key generation and manual profile switching as their functionality is integrated into the main setup wizard.

## Script Details

### 1. `setup-profiles.sh` - Main Setup Wizard

**Purpose:** Interactive wizard for complete Git multi-profile setup and management.

**Features:**
- Prerequisites checking (Git version, SSH client)
- Global Git configuration setup
- Profile creation and management
- SSH key generation with type selection
- Conditional includes management
- Configuration cleanup
- Backup creation

**Usage:**
```bash
./scripts/setup-profiles.sh              # Interactive mode
./scripts/setup-profiles.sh -h           # Show help
```

**Menu Options:**
1. **Set up work profile** - Create/update work profile
2. **Set up personal profile** - Create/update personal profile  
3. **Set up client profile** - Create/update client profile
4. **Clean unused entries** - Remove obsolete .gitconfig entries
5. **Test current configuration** - Validate profile switching
6. **Exit** - Complete setup

**Workflow:**
1. Check prerequisites (Git 2.13+, SSH client)
2. Backup existing `.gitconfig`
3. Configure/verify global Git settings
4. Present interactive menu
5. Process user selections
6. Create profiles and SSH keys as needed
7. Update `.gitconfig` with conditional includes

**SSH Key Features:**
- **Key Type Selection:** Ed25519 (recommended) or RSA 4096
- **Passphrase Option:** Optional passphrase protection
- **Automatic Integration:** SSH config added to profile automatically
- **Duplicate Prevention:** Checks for existing keys
- **Public Key Display:** Shows key for adding to Git hosting services

**Profile Management:**
- **Template-Based:** Uses profile templates from `configs/profiles/`
- **Variable Substitution:** Replaces placeholders with user input
- **Duplicate Prevention:** Checks for existing conditional includes
- **Path Validation:** Creates directories if they don't exist
- **Dynamic Examples:** Shows appropriate directory examples per profile type

**Configuration Backup:**
- Automatic backup before any changes
- Timestamped backup files: `.gitconfig.backup.YYYYMMDD_HHMMSS`
- Restore instructions provided if needed

### 2. `validate-config.sh` - Configuration Validator

**Purpose:** Comprehensive validation of Git multi-profile configuration.

**Features:**
- Git installation and version checking
- Global configuration validation
- Conditional includes verification
- Profile configuration analysis
- SSH key existence checking
- SSH connectivity testing
- Summary report with success rate

**Usage:**
```bash
./scripts/validate-config.sh             # Full validation
./scripts/validate-config.sh -q          # Quick mode (skip SSH connectivity)
./scripts/validate-config.sh -h          # Show help
```

**Validation Categories:**

#### System Checks
- ✅ Git installation and version (requires 2.13+ for conditional includes)
- ✅ SSH client availability
- ✅ Directory permissions

#### Global Configuration
- ✅ `.gitconfig` file exists and is readable
- ✅ Global `user.name` and `user.email` configured
- ✅ Basic Git settings validation

#### Conditional Includes
- ✅ Conditional include syntax validation
- ✅ Directory existence checking (with tilde expansion)
- ✅ Profile file existence verification
- ✅ Path mapping correctness

#### Profile Analysis
- ✅ Required fields: `user.name`, `user.email`
- ✅ Email format validation (regex pattern matching)
- ✅ SSH configuration detection and validation
- ✅ SSH key file existence (private and public)
- ℹ️ GPG configuration detection (only if actually enabled)
- ℹ️ SSH configuration optional (if user skipped generation)

#### SSH Connectivity (Optional)
- ⚠️ GitHub, GitLab, Bitbucket connectivity tests
- ⚠️ Authentication status checking
- ℹ️ Service reachability testing

#### Profile Switching Tests
- ✅ Real-world profile activation in configured directories
- ✅ Identity verification per directory
- ✅ SSH configuration application

**Output Format:**
- Color-coded results with emojis
- Detailed success/failure messages
- Summary statistics with success percentage
- Actionable recommendations

**Success Rate Interpretation:**
- 90%+ → ✅ Configuration looks excellent!
- 70-89% → ⚠️ Configuration is mostly good, but some issues need attention
- <70% → ❌ Configuration needs significant improvements

### 3. Manual Operations

**Profile Switching**: Profiles are automatically activated based on repository directory (conditional includes). No manual switching needed.

**SSH Key Generation**: Integrated into `setup-profiles.sh` with interactive key type selection and automatic configuration.

**Key Features:**
- Ed25519 (recommended) and RSA 4096 support
- Profile-specific key naming: `~/.ssh/id_ed25519_{profile}`
- Interactive passphrase setting with confirmation
- Automatic `core.sshCommand` configuration
- Public key display for easy copying to Git services

## Common Usage Patterns

### Initial Setup Workflow

1. **Clone repository:**
   ```bash
   git clone <repository-url> git-multi-profile
   cd git-multi-profile
   ```

2. **Run setup wizard:**
   ```bash
   ./scripts/setup-profiles.sh
   ```

3. **Configure global settings** (first time only)

4. **Create profiles** as needed:
   - Work profile → Configure work identity and directory
   - Personal profile → Configure personal identity and directory
   - Client profiles → Configure per client needs

5. **Generate SSH keys** when prompted

6. **Validate configuration:**
   ```bash
   ./scripts/validate-config.sh
   ```

### Maintenance Workflow

1. **Regular validation:**
   ```bash
   ./scripts/validate-config.sh -q
   ```

2. **Clean unused entries:**
   ```bash
   ./scripts/setup-profiles.sh  # Choose option 4
   ```

3. **Add new profiles** as needed

4. **Update SSH keys** when they expire:
   ```bash
   ./scripts/setup-profiles.sh  # Choose existing profile to update keys
   ```

### Troubleshooting Workflow

1. **Run validation:**
   ```bash
   ./scripts/validate-config.sh
   ```

2. **Check specific issues:**
   - Profile switching problems → Test in configured directories
   - SSH authentication failures → Verify keys with Git hosting services
   - Configuration conflicts → Use cleanup function

3. **Emergency profile switching:**
   ```bash
   ./scripts/switch-profile.sh
   ```

## Script Dependencies

### System Requirements
- **Bash 4.0+**: All scripts use bash-specific features
- **Git 2.13+**: Required for conditional includes
- **SSH client**: Required for SSH key operations
- **Basic utilities**: sed, grep, cat, mkdir, etc.

### File Dependencies
- `configs/profiles/` - Template files
- `~/.gitconfig` - Global Git configuration
- `~/.config/git/profiles/` - Profile configurations
- `~/.ssh/` - SSH key storage

### Cross-Script Integration
- `setup-profiles.sh` calls functions from other scripts internally
- `validate-config.sh` can be called independently or from setup
- SSH key generation is integrated into setup-profiles.sh
- All scripts respect the same configuration structure

## Error Handling

### Common Error Scenarios

1. **Missing Git installation**
   - Detection: Prerequisites check
   - Resolution: Install Git 2.13+

2. **Insufficient permissions**
   - Detection: File operation failures
   - Resolution: Check directory permissions

3. **Corrupted configuration**
   - Detection: Validation failures
   - Resolution: Restore from backup or reconfigure

4. **SSH key conflicts**
   - Detection: Existing key warnings
   - Resolution: Backup or overwrite options provided

### Backup and Recovery

All scripts create backups before making changes:
- `.gitconfig` backups: `~/.gitconfig.backup.{timestamp}`
- Profile backups: Created during cleanup operations
- SSH key backups: User prompted before overwrite

Recovery procedures documented in script help output and error messages.

## Advanced Configuration

### Custom Profile Types

To add new profile types:
1. Create new template in `configs/profiles/{type}-template`
2. Add case statement in `setup-profiles.sh` 
3. Update menu options and help text
4. Test with validation script

### Integration with CI/CD

Scripts can be used in automated environments:
```bash
# Non-interactive profile creation
echo -e "1\nJohn Smith\njohn@company.com\n/workspace/work\ny\n1\n\n6" | ./scripts/setup-profiles.sh

# Validation in CI pipeline
./scripts/validate-config.sh -q && echo "Git configuration valid"
```

### Custom SSH Key Types

To support additional key types:
1. Update SSH key generation in `setup-profiles.sh`
2. Add case statement for new type
3. Update validation logic in `validate-config.sh`
4. Test key generation and validation

This documentation should be updated when scripts are modified or new features are added.