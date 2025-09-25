# Git Multi-Profile Testing Framework

This directory contains comprehensive testing infrastructure for the Git multi-profile system, providing multiple layers of testing to ensure reliability, security, and correctness.

## 📁 Test Structure

```
tests/
├── README.md               # This file
├── run-local-tests.sh     # Main local test suite runner
├── unit-tests.sh          # Unit tests for individual functions
└── integration-tests.sh   # End-to-end integration tests
```

## 🧪 Test Types

### 1. Local Test Suite (`run-local-tests.sh`)
**Primary testing tool for development and validation**

- **Safe Testing**: Does not modify your actual Git configuration
- **Comprehensive Coverage**: 15+ test categories including syntax, security, documentation
- **Development Friendly**: Perfect for local development and pre-commit validation
- **Fast Execution**: Typically completes in under 30 seconds

```bash
# Run all local tests
./tests/run-local-tests.sh

# Run specific test category
./tests/run-local-tests.sh --category syntax

# Verbose output for debugging
./tests/run-local-tests.sh --verbose
```

#### Test Categories:
- **Script Syntax**: shellcheck, bash syntax validation
- **Template Validation**: Git config format, placeholder consistency
- **Logic Testing**: Function behavior, conditional logic
- **Security Scanning**: Path traversal, command injection prevention
- **Documentation**: Link validation, content accuracy
- **Integration**: Cross-component compatibility

### 2. Unit Tests (`unit-tests.sh`)
**Focused testing of individual functions and components**

- **Function-Level Testing**: Email validation, path sanitization, SSH key validation
- **Security Testing**: Command injection prevention, path traversal protection
- **Input Validation**: Boundary conditions, edge cases, malformed input
- **Logic Verification**: Template replacement, conditional includes

```bash
# Run all unit tests
./tests/unit-tests.sh

# Help and options
./tests/unit-tests.sh --help
```

#### Test Coverage:
- Email format validation (RFC compliance)
- Path validation and sanitization
- SSH key type validation (Ed25519/RSA)
- Git conditional include format
- Template placeholder replacement
- Security input validation
- Configuration syntax validation

### 3. Integration Tests (`integration-tests.sh`)
**End-to-end testing in isolated environment**

- **Complete Workflows**: Full profile setup, switching, and validation
- **Isolated Environment**: Uses `/tmp` sandbox, no system impact
- **Real Scenarios**: Actual Git repositories, SSH key generation
- **Error Handling**: Invalid inputs, edge cases, failure recovery
- **Performance Testing**: Execution time validation

```bash
# Run all integration tests
./tests/integration-tests.sh

# Keep test environment for debugging
./tests/integration-tests.sh --keep-env

# Verbose mode
./tests/integration-tests.sh --verbose
```

#### Integration Scenarios:
- Complete profile setup workflow (work/personal/client)
- Profile switching and validation
- Directory-based configuration switching
- SSH key generation and management
- Configuration validation processes
- Error handling and recovery
- Performance benchmarking

## 🚀 Quick Start

### Run All Tests
```bash
# Complete test suite (recommended)
./tests/run-local-tests.sh

# Quick validation
./tests/unit-tests.sh

# Full integration testing
./tests/integration-tests.sh
```

### Pre-Commit Testing
```bash
# Fast pre-commit validation
./tests/run-local-tests.sh --category "syntax security"

# Complete pre-commit suite
./tests/run-local-tests.sh && ./tests/unit-tests.sh
```

### Development Testing
```bash
# During development - safe and fast
./tests/run-local-tests.sh --verbose

# Test specific changes
./tests/unit-tests.sh

# Validate complete workflow
./tests/integration-tests.sh
```

## 🔧 Test Configuration

### Environment Variables
- `SCRIPT_DIR`: Automatically detected project root
- `TEST_DIR`: Temporary directory for test artifacts
- `HOME`: Overridden in integration tests for isolation

### Dependencies
- **Required**: `bash`, `git`, `ssh-keygen`
- **Optional**: `shellcheck`, `bc`, `realpath`
- **CI/CD**: Additional tools for GitHub Actions

### Safety Features
- **No System Modification**: Tests never modify your actual Git config
- **Isolated Environments**: Integration tests use temporary directories
- **Automatic Cleanup**: Test artifacts automatically removed
- **Fail-Safe Design**: Tests fail gracefully without system impact

## 📊 Test Output

### Success Example
```
🧪 Git Multi-Profile Local Tests
════════════════════════════════════════════════════════════════

✅ Script Syntax Tests
✅ Template Validation Tests  
✅ Logic Tests
✅ Security Tests
✅ Documentation Tests
✅ Integration Tests

📊 Test Summary
════════════════════════════════════════════════════════════════
Total Tests: 47
Passed: 47
Failed: 0

🎉 All local tests passed! Success rate: 100%
```

### Failure Example
```
❌ FAIL: Template syntax validation
   Details: Invalid placeholder in work-template

📊 Test Summary  
════════════════════════════════════════════════════════════════
Total Tests: 47
Passed: 46
Failed: 1

❌ Some tests failed. Success rate: 97.9%
```

## 🔍 Debugging Tests

### Verbose Mode
```bash
# Enable detailed output
./tests/run-local-tests.sh --verbose

# Bash debugging
bash -x ./tests/unit-tests.sh
```

### Test Environment Inspection
```bash
# Keep integration test environment
./tests/integration-tests.sh --keep-env
# Environment preserved at: /tmp/git-config-integration-test-XXXXX
```

### Manual Test Execution
```bash
# Run individual test categories
./tests/run-local-tests.sh --category syntax
./tests/run-local-tests.sh --category security
./tests/run-local-tests.sh --category documentation
```

## 🤖 CI/CD Integration

The testing framework integrates with GitHub Actions through `.github/workflows/quality.yml`:

### Automated Testing
- **Bash Quality**: shellcheck, syntax validation, formatting
- **Security Scanning**: Secret detection, path validation
- **Multi-Platform**: Ubuntu 22.04, macOS latest
- **Documentation**: Link validation, format checking
- **Integration Testing**: Complete workflow validation

### Local CI Simulation
```bash
# Simulate CI environment locally
./tests/run-local-tests.sh --ci-mode

# Complete CI test suite
./tests/run-local-tests.sh && ./tests/unit-tests.sh && ./tests/integration-tests.sh
```

## 📋 Test Maintenance

### Adding New Tests
1. **Unit Tests**: Add functions to `unit-tests.sh`
2. **Integration Tests**: Add scenarios to `integration-tests.sh`
3. **Local Tests**: Add categories to `run-local-tests.sh`

### Test Best Practices
- **Isolation**: Each test should be independent
- **Cleanup**: Always clean up test artifacts
- **Documentation**: Comment complex test logic
- **Error Handling**: Handle failures gracefully
- **Performance**: Keep tests fast for development workflow

### Updating Tests
When adding new features or scripts:
1. Update relevant test files
2. Add new test categories if needed
3. Update documentation
4. Verify CI/CD pipeline compatibility

## 🛡️ Security Considerations

### Safe Testing Practices
- **No Credential Exposure**: Tests never use real credentials
- **Isolated Execution**: Tests run in sandboxed environments
- **Input Validation**: All test inputs are validated
- **Cleanup Guaranteed**: Test artifacts are always removed

### Security Test Coverage
- Path traversal prevention
- Command injection protection
- Input sanitization validation
- SSH key security practices
- Configuration file permissions

## 📈 Performance Guidelines

### Test Performance Targets
- **Local Tests**: < 30 seconds
- **Unit Tests**: < 15 seconds  
- **Integration Tests**: < 60 seconds
- **CI Pipeline**: < 5 minutes total

### Optimization Tips
- Use parallel testing where safe
- Cache test dependencies
- Minimize file I/O operations
- Use efficient test patterns

## 🆘 Troubleshooting

### Common Issues

#### Permission Errors
```bash
# Fix permissions
chmod +x tests/*.sh
```

#### Missing Dependencies
```bash
# Install shellcheck (Ubuntu/Debian)
sudo apt-get install shellcheck

# Install shellcheck (macOS)
brew install shellcheck
```

#### Test Failures
```bash
# Run with verbose output
./tests/run-local-tests.sh --verbose

# Check specific category
./tests/run-local-tests.sh --category security
```

### Getting Help
1. Check test output for specific error messages
2. Run tests in verbose mode for detailed information
3. Examine test environment if integration tests fail
4. Review documentation for expected behavior

---

This testing framework ensures the Git multi-profile system is reliable, secure, and maintainable. For questions or issues, refer to the main project documentation or create an issue in the repository.