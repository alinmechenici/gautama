# Contributing to Gautama

Thank you for your interest in contributing to Gautama! This document provides guidelines and best practices for contributing to this NixOS configuration.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Documentation](#documentation)
- [Testing](#testing)

## 📜 Code of Conduct

This project follows a simple code of conduct:

- **Be respectful** and considerate in all interactions
- **Be constructive** with feedback and criticism
- **Be patient** with those learning NixOS or new to the project
- **Focus on the code**, not the person
- **Assume good intentions**

Unacceptable behavior includes harassment, discrimination, or any behavior that makes others feel unwelcome.

## 🚀 Getting Started

### Prerequisites

- NixOS installed (or Nix on another Linux distribution)
- Basic understanding of Nix language
- Git for version control
- Familiarity with the services you want to modify

### Setting Up Development Environment

1. **Fork and clone the repository**:
   ```bash
   git clone https://github.com/yourusername/gautama.git
   cd gautama
   ```

2. **Create a development branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Test your changes locally**:
   ```bash
   # Build without switching
   sudo nixos-rebuild build --flake .#vulcan

   # Test in a VM
   nixos-rebuild build-vm --flake .#vulcan
   ```

## 🤝 How to Contribute

### Reporting Bugs

**Before submitting a bug report:**
- Check existing issues to avoid duplicates
- Test on the latest version
- Gather relevant logs and error messages

**When submitting a bug report, include:**
- Clear, descriptive title
- Steps to reproduce
- Expected behavior
- Actual behavior
- System information (NixOS version, hardware, etc.)
- Relevant logs and error messages
- Configuration snippets (redact secrets!)

### Suggesting Enhancements

**Enhancement suggestions should include:**
- Clear use case and motivation
- Expected behavior
- Alternatives you've considered
- Examples from other projects (if applicable)

### Adding New Services

**When adding a new service:**
1. Create a new module in `modules/services/`
2. Follow the existing module structure
3. Add comprehensive documentation
4. Include monitoring configuration
5. Add to the module index
6. Update relevant documentation

**Module template:**
```nix
{ config, lib, pkgs, ... }:

{
  # Service configuration
  services.myservice = {
    enable = true;
    # Configuration options
  };

  # Secrets (if needed)
  sops.secrets."myservice-password" = {
    owner = "myservice";
    group = "myservice";
    mode = "0400";
  };

  # Networking
  networking.firewall.allowedTCPPorts = [ 1234 ];

  # Systemd services (if custom needed)
  systemd.services.myservice-helper = {
    # Service definition
  };

  # Monitoring
  services.prometheus.exporters.myservice = {
    enable = true;
    port = 9999;
  };
}
```

## 🔄 Development Workflow

### 1. Plan Your Changes

- Review existing issues and discussions
- Open an issue to discuss major changes before implementing
- Design your solution before coding

### 2. Make Your Changes

- Write clean, well-commented Nix code
- Follow existing patterns and conventions
- Keep changes focused and atomic
- Test thoroughly

### 3. Document Your Changes

- Update relevant documentation
- Add inline comments for complex logic
- Update the README if adding major features
- Create or update diagrams if architecture changes

### 4. Test Your Changes

- Build successfully: `nixos-rebuild build --flake .#vulcan`
- Test in VM if possible: `nixos-rebuild build-vm --flake .#vulcan`
- Verify services start correctly
- Check logs for errors
- Test rollback works

### 5. Submit Your Changes

- Format code: `nix fmt`
- Commit with clear messages
- Push to your fork
- Open a pull request

## 📐 Coding Standards

### Nix Code Style

**Formatting:**
- Use `nixfmt-rfc-style` (run `nix fmt`)
- 2 spaces for indentation
- No trailing whitespace
- Reasonable line length (80-100 characters when possible)

**Naming:**
- Use camelCase for variable names
- Use kebab-case for file names
- Use descriptive names

**Structure:**
- Group related options together
- Use `let` bindings for repeated expressions
- Extract common patterns to `lib/` functions

**Comments:**
- Document why, not what
- Explain non-obvious decisions
- Add links to relevant documentation

### Module Organization

**File structure:**
```
modules/
├── services/
│   ├── myservice.nix       # Service configuration
│   └── related-service.nix
├── containers/
│   └── mycontainer.nix     # Container definitions
├── lib/
│   └── helpers.nix         # Reusable functions
└── monitoring/
    └── alerts/
        └── myservice.yaml  # Prometheus alerts
```

**Module best practices:**
- One service per module
- Clear dependencies
- Minimal coupling
- Reusable components

## 📝 Commit Guidelines

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Test additions or changes
- `chore`: Maintenance tasks
- `ci`: CI/CD changes

**Scope:**
Examples: `nginx`, `home-assistant`, `monitoring`, `zfs`, `containers`

**Subject:**
- Use imperative mood ("add", not "added" or "adds")
- No period at the end
- Keep under 50 characters

**Body:**
- Explain what and why, not how
- Wrap at 72 characters
- Reference issues and PRs

**Examples:**

```
feat(monitoring): add PostgreSQL dashboard

Add comprehensive Grafana dashboard for PostgreSQL monitoring including
connection stats, query performance, and replication status.

Relates to #123
```

```
fix(nginx): correct certificate path for step-ca

The nginx configuration was looking for certificates in the wrong
directory, causing TLS errors on startup.

Fixes #456
```

## 🔍 Pull Request Process

### Before Submitting

- [ ] Code follows style guidelines
- [ ] All tests pass
- [ ] Documentation is updated
- [ ] Commits are well-formatted
- [ ] Changes are rebased on latest main
- [ ] No secrets in commits

### PR Description

Include:
- **What**: Brief description of changes
- **Why**: Motivation and context
- **How**: Technical implementation details
- **Testing**: How you tested the changes
- **Screenshots**: For UI changes
- **Breaking changes**: If any

**Template:**
```markdown
## Description
Brief description of the PR

## Motivation
Why this change is needed

## Changes
- Change 1
- Change 2

## Testing
- [ ] Built successfully
- [ ] Tested in VM
- [ ] Services start correctly
- [ ] No regressions

## Screenshots
(if applicable)

## Breaking Changes
(if any)

## Checklist
- [ ] Documentation updated
- [ ] Tests pass
- [ ] Follows coding standards
- [ ] Commits are well-formatted
```

### Review Process

1. **Automated checks** run on every PR
2. **Maintainer review** for code quality and design
3. **Testing** by reviewers if needed
4. **Approval** from at least one maintainer
5. **Merge** when all checks pass and approved

### After Merge

- **Delete your branch** (if not needed)
- **Close related issues** (if resolved)
- **Update documentation** (if needed)

## 📚 Documentation

### Types of Documentation

**Code documentation:**
- Inline comments for complex logic
- Module-level documentation
- Function documentation

**User documentation:**
- `docs/md/` - Detailed guides
- `README.md` - Overview and quick start
- `docs/d2/` - Architecture diagrams

**Operational documentation:**
- Runbooks for common operations
- Troubleshooting guides
- FAQ entries

### Documentation Standards

- **Be clear and concise**
- **Use examples** to illustrate concepts
- **Keep updated** with code changes
- **Test instructions** to ensure they work
- **Use proper formatting** (markdown, code blocks)

## 🧪 Testing

### Test Types

**Build testing:**
```bash
# Basic build
sudo nixos-rebuild build --flake .#vulcan

# Show trace on errors
sudo nixos-rebuild build --flake .#vulcan --show-trace

# Check flake
nix flake check
```

**VM testing:**
```bash
# Build VM
nixos-rebuild build-vm --flake .#vulcan

# Run VM
./result/bin/run-vulcan-vm
```

**Service testing:**
```bash
# Check service status
sudo systemctl status service-name

# View logs
sudo journalctl -u service-name -f

# Test service functionality
curl http://localhost:port
```

**Integration testing:**
- Verify service dependencies
- Check networking connectivity
- Validate monitoring metrics
- Test backup/restore procedures

### What to Test

- [ ] Configuration builds successfully
- [ ] Services start without errors
- [ ] No conflicts with existing services
- [ ] Monitoring exporters work
- [ ] Documentation is accurate
- [ ] Rollback works

## 🆘 Getting Help

**Resources:**
- **Documentation**: Check `docs/md/` first
- **Issues**: Search existing issues
- **Discussions**: Open a discussion for questions
- **NixOS Community**:
  - [NixOS Discourse](https://discourse.nixos.org/)
  - [NixOS Matrix](https://matrix.to/#/#nixos:nixos.org)
  - [r/NixOS](https://reddit.com/r/NixOS)

**How to Ask for Help:**
1. Search existing resources
2. Provide clear context
3. Include relevant information
4. Show what you've tried
5. Be patient and respectful

## 🎯 Good First Issues

Looking to contribute but don't know where to start? Look for issues tagged:
- `good first issue` - Simple, well-defined tasks
- `documentation` - Documentation improvements
- `help wanted` - Tasks needing contributors

## 🙏 Recognition

Contributors will be:
- Listed in release notes
- Credited in commit history
- Acknowledged in the community

Thank you for contributing to Gautama! Your efforts help make this project better for everyone.
