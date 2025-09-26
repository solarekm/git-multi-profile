# 🔧 Git Multi-Profile Configuration Manager

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey.svg)
![Git](https://img.shields.io/badge/Git-2.25%2B-red.svg)
![Shell](https://img.shields.io/badge/Shell-Bash%20%7C%20Zsh-green.svg)

A comprehensive guide and automation suite for configuring Git with multiple profiles for different repositories and organizations. This repository provides step-by-step instructions, configuration templates, and automation scripts to manage separate Git identities for work, personal projects, and different clients seamlessly.

## ✨ Features

### Profile Management
- ✅ **Multi-Identity Support** - Work, personal, client-specific configurations
- ✅ **Conditional Includes** - Automatic profile switching based on directory
- ✅ **SSH Key Management** - Multiple SSH keys for different services
- ✅ **GPG Signing** - Per-profile commit signing configuration
- ✅ **Custom Aliases** - Profile-specific Git aliases and shortcuts
- ✅ **Automated Setup** - Scripts for quick profile configuration
- ✅ **Cross-Platform** - Works on Linux, macOS, and Windows (WSL/Git Bash)

### Configuration Types
- 🏢 **Corporate Profiles** - Company email, SSH keys, and signing keys
- 🏠 **Personal Profiles** - Personal GitHub/GitLab configurations
- 👥 **Client Profiles** - Separate identities for freelance/consulting work
- 🔐 **Security-First** - Isolated SSH keys and GPG keys per profile
- 🎯 **Directory-Based** - Automatic switching based on repository location
- 📝 **Template System** - Reusable configuration templates

## 📋 Contents
- `configs/profiles/` - Git configuration templates
  - `global-template` - Main Git configuration template  
  - `work-template` - Work profile configuration template
  - `personal-template` - Personal profile configuration template
  - `client-template` - Client profile configuration template
- `scripts/` - Automation scripts for profile management
  - `setup-profiles.sh` - Interactive profile setup wizard (includes SSH key generation)
  - `validate-config.sh` - Configuration validation tool
- `docs/` - Comprehensive documentation and guides
  - `scripts.md` - Complete scripts documentation
  - `templates.md` - Templates guide and reference
  - `ssh-setup.md` - SSH key setup and management guide
  - `gpg-setup.md` - GPG signing configuration guide
  - `troubleshooting.md` - Common issues and solutions
- `examples/` - Real-world configuration examples
  - `corporate-setup/` - Enterprise environment examples

## 🚀 Quick Start

### Prerequisites
- Git 2.25+ (for conditional includes support)
- Bash or Zsh shell
- SSH client
- Text editor (nano, vim, or VS Code)

### Step 1: Repository Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/solarekm/git-config.git
   cd git-config
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x scripts/*.sh
   ```

### Step 2: Profile Configuration

1. **Run the interactive setup:**
   ```bash
   ./scripts/setup-profiles.sh
   ```
   
   **Setup Features:**
   - 🔄 **Interactive wizard** - Guided profile creation process
   - 📝 **Template generation** - Automatic config file creation
   - 🔑 **SSH key generation** - Optional SSH key pair creation
   - ✅ **Validation checks** - Verify configuration correctness
   - 🎨 **Color-coded output** - Clear success/warning/error indicators

2. **Configure directory structure:**
   ```bash
   # Example directory structure
   ~/repositories/
   ├── work/           # Corporate projects
   ├── personal/       # Personal projects
   └── clients/        # Client projects
       ├── client-a/
       └── client-b/
   ```

3. **Test profile switching:**
   ```bash
   # Navigate to different directories and check active profile
   cd ~/repositories/work
   git config user.email  # Should show work email
   
   cd ~/repositories/personal
   git config user.email  # Should show personal email
   ```

## � Documentation

### Comprehensive Guides
- **[Scripts Documentation](docs/scripts.md)** - Complete guide to all automation scripts
- **[Templates Guide](docs/templates.md)** - Understanding and customizing configuration templates
- **[SSH Setup Guide](docs/ssh-setup.md)** - SSH key management and configuration
- **[GPG Setup Guide](docs/gpg-setup.md)** - GPG signing configuration
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

### Quick References
- **Scripts:** Interactive setup, validation, manual switching, SSH key generation
- **Templates:** Global, work, personal, and client configuration templates
- **Security:** SSH key isolation, GPG signing per profile
- **Automation:** Backup creation, duplicate prevention, validation checks

## �🛠️ Configuration Profiles

### Work Profile Example
```ini
# ~/.config/git/profiles/work
[user]
    name = John Doe
    email = john.doe@company.com
    signingkey = ABC123DEF456

[core]
    sshCommand = ssh -i ~/.ssh/id_rsa_work

[commit]
    gpgsign = true

[alias]
    # Work-specific aliases
    standup = log --since='yesterday' --author='john.doe@company.com' --oneline
```

### Personal Profile Example
```ini
# ~/.config/git/profiles/personal
[user]
    name = John Doe
    email = john@personal-domain.com
    signingkey = XYZ789ABC123

[core]
    sshCommand = ssh -i ~/.ssh/id_rsa_personal

[commit]
    gpgsign = true

[alias]
    # Personal project aliases
    publish = !git push -u origin $(git branch --show-current)
```

## 🔧 Advanced Features

### Conditional Includes
```ini
# ~/.gitconfig
[includeIf "gitdir:~/repositories/work/"]
    path = ~/.config/git/profiles/work

[includeIf "gitdir:~/repositories/personal/"]
    path = ~/.config/git/profiles/personal

[includeIf "gitdir:~/repositories/clients/client-a/"]
    path = ~/.config/git/profiles/client-a
```

### SSH Key Management
- **🔑 Key Generation**: Automated SSH key pair creation per profile
- **🔐 Key Loading**: Automatic SSH agent configuration
- **🛡️ Security**: Separate keys prevent cross-contamination
- **📋 Key Mapping**: Clear documentation of key-to-service mapping

### GPG Signing Configuration
- **✍️ Per-Profile Signing**: Different GPG keys for different identities
- **🔒 Automatic Signing**: Commit signing enabled per profile
- **📜 Key Management**: GPG key generation and import guides

## 📖 Directory Structure

```
git-multi-profile/
├── README.md                    # This file
├── LICENSE                     # MIT License
├── .github/
│   └── workflows/
│       └── quality.yml         # CI/CD pipeline for automated testing
├── configs/
│   └── profiles/               # Configuration templates
│       ├── global-template     # Main Git configuration template
│       ├── work-template       # Work profile template
│       ├── personal-template   # Personal profile template
│       └── client-template     # Client profile template
├── scripts/                    # Automation and management scripts
│   ├── setup-profiles.sh       # Interactive profile setup wizard
│   ├── validate-config.sh      # Configuration validation tool
│   ├── switch-profile.sh       # Manual profile switching utility
│   └── generate-ssh-keys.sh    # SSH key generation utility
├── tests/                      # Comprehensive testing framework
│   ├── README.md              # Testing documentation
│   ├── run-local-tests.sh     # Main local test suite (safe, fast)
│   ├── unit-tests.sh          # Unit tests for individual functions
│   └── integration-tests.sh   # End-to-end integration tests
├── docs/                       # Comprehensive documentation
│   ├── scripts.md             # Scripts documentation
│   ├── templates.md           # Templates guide
│   ├── ssh-setup.md           # SSH setup guide
│   ├── gpg-setup.md           # GPG setup guide
│   └── troubleshooting.md     # Common issues and solutions
└── examples/                   # Real-world examples
    ├── corporate-setup/
    │   └── README.md          # Corporate setup examples
    └── oss-contributor/
        └── README.md          # Open source contributor setup
```

## 🧪 Testing & Quality Assurance

### Comprehensive Test Suite
The project includes a complete testing framework with multiple layers of validation:

```bash
# Quick local validation (recommended)
./tests/run-local-tests.sh

# Unit tests for individual components
./tests/unit-tests.sh

# End-to-end integration testing
./tests/integration-tests.sh
```

**Testing Features:**
- 🛡️ **Safe Testing**: Never modifies your actual Git configuration
- ⚡ **Fast Execution**: Complete local tests in under 30 seconds
- 🔍 **Comprehensive Coverage**: 15+ test categories including security, syntax, and logic
- 🤖 **CI/CD Integration**: Automated testing via GitHub Actions
- 📊 **Detailed Reporting**: Success rates and failure diagnostics

### Test Categories

#### Local Test Suite (`run-local-tests.sh`)
- **Script Syntax**: shellcheck validation, bash compatibility
- **Template Validation**: Git config format, placeholder consistency  
- **Security Scanning**: Path traversal, command injection prevention
- **Documentation**: Link validation, content accuracy
- **Integration**: Cross-component compatibility

#### Unit Tests (`unit-tests.sh`)
- **Email Validation**: RFC compliance testing
- **Path Sanitization**: Security and format validation
- **SSH Key Validation**: Ed25519/RSA format verification
- **Template Processing**: Placeholder replacement logic
- **Input Validation**: Boundary conditions and edge cases

#### Integration Tests (`integration-tests.sh`)
- **Complete Workflows**: Full profile setup and switching
- **Directory-Based Config**: Conditional include testing
- **SSH Key Management**: Key generation and validation
- **Error Handling**: Invalid input and recovery testing
- **Performance**: Execution time validation

### Profile Validation
```bash
# Comprehensive configuration validation
./scripts/validate-config.sh
```

**Validation Features:**
- ✅ **Configuration Syntax**: Verify Git config file syntax
- 🔑 **SSH Key Status**: Check SSH key accessibility
- 📧 **Email Validation**: Verify email format and domains
- 🎯 **Profile Mapping**: Confirm directory-to-profile mappings
- 📊 **Summary Report**: Color-coded validation results with success rates

### Manual Testing
```bash
# Test profile switching
cd ~/repositories/work
git config --list | grep user.email
git config --list | grep core.sshCommand

# Test SSH connectivity
ssh -T git@github.com
ssh -T git@gitlab.com

# Verify directory-based configuration
cd ~/repositories/personal
git config user.name  # Should show personal name
cd ~/repositories/work  
git config user.name   # Should show work name
```

### GitHub Actions CI/CD
Automated quality assurance runs on every commit and pull request:

- **Bash Quality**: shellcheck, syntax validation, formatting
- **Security Scanning**: Secret detection, path validation
- **Multi-Platform Testing**: Ubuntu 22.04, macOS latest
- **Documentation Quality**: Link validation, format checking
- **Template Validation**: Configuration syntax verification
- **Integration Testing**: Complete workflow validation

View test results at: `.github/workflows/quality.yml`

## 🎯 Use Cases

### 1. Corporate Developer
- Separate work and personal GitHub accounts
- Company-required GPG signing for work commits
- Different SSH keys for security compliance

### 2. Freelancer/Consultant
- Multiple client identities
- Client-specific email addresses
- Isolated SSH keys per client for security

### 3. Open Source Contributor
- Personal identity for personal projects
- Professional identity for work-related OSS contributions
- Consistent commit signing across projects

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Git development team for conditional includes feature
- GitHub and GitLab for excellent SSH key management
- Community contributors for configuration best practices

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/solarekm/git-multi-profile/issues)
- **Project**: [GitHub Repository](https://github.com/solarekm/git-multi-profile)
- **Documentation**: [Wiki Pages](https://github.com/solarekm/git-multi-profile/wiki)

## 🔗 Related Resources

- [Official Git Documentation](https://git-scm.com/docs)
- [GitHub SSH Key Setup](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [GitLab SSH Key Setup](https://docs.gitlab.com/ee/user/ssh.html)
- [GPG Signing Guide](https://docs.github.com/en/authentication/managing-commit-signature-verification)