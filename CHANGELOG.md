# Changelog

All notable changes to the Gautama NixOS configuration will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Jekyll static site generator service with Tailscale access
- Quarto technical publishing system with Tailscale access
- Typst modern typesetting system (containerized) with Tailscale access
- Redmine project management platform (containerized) with PostgreSQL backend
- Publishing Services comprehensive documentation guide
- Git Workflow guide for working with branches and merging
- Comprehensive Quick Start guide (~3,500 words)
- Troubleshooting guide covering all major components
- FAQ with 50+ questions and answers
- Contributing guide with detailed workflow
- GitHub Actions CI/CD workflow for Nix validation
- GitHub issue templates (bug report, feature request)
- Pull request template
- Health check script for system diagnostics
- Service status script for quick overview
- Network topology D2 diagram
- Badges for README (NixOS, platform, services, etc.)
- "Why Gautama?" section explaining philosophy and design decisions
- Quick Links section in README

### Changed
- Reorganized documentation into docs/md/, docs/sc/, docs/d2/ subdirectories
- Updated README with comprehensive service listings
- Enhanced architecture documentation with new diagrams
- Updated service counts (66 service modules, 24 containers, 64+ active services)
- Improved README organization and navigation

### Documentation
- 6 D2 architecture diagrams (system overview, layers, dependencies, monitoring, backup, network)
- 32+ markdown documentation files
- 15,000+ lines of documentation
- Complete operational guides

## [1.0.0] - 2024-11-13

### Added
- Initial Gautama configuration
- 62 service modules across 8 functional categories
- ZFS storage with Sanoid snapshots
- Restic cloud backups to Backblaze B2
- Prometheus monitoring stack with 35+ exporters
- Grafana dashboards and Alertmanager
- Home Assistant with 17+ device integrations
- PostgreSQL 17 with pgvector
- Nginx reverse proxy with step-ca certificates
- SOPS-nix secrets management
- Podman/Quadlet container orchestration
- 20+ containerized applications
- AI/ML platform (LiteLLM, Vanna AI, Silly Tavern, etc.)
- Complete mail stack (Postfix, Dovecot, mbsync)
- Comprehensive monitoring and alerting
- Multi-layer backup strategy
- Security hardening
- 32+ systemd timers for automation

### Infrastructure
- Apple Silicon (aarch64-linux) support via Asahi Linux
- ZFS on 64GB RAM system with tuned ARC
- NixOS 25.05 (unstable channel)
- Flake-based configuration
- Home Manager integration
- Modular architecture with 80+ modules

## Release Notes

### Version 1.0.0 - Initial Release

First production release of Gautama, a comprehensive self-hosted infrastructure platform running on Apple Silicon.

**Highlights:**
- 60+ services running reliably
- Complete observability stack
- Enterprise-grade backup strategy
- Professional documentation
- Security-first design

**Services Included:**
- Web: Nginx, Nextcloud, Jellyfin, Gitea, Home Assistant
- Databases: PostgreSQL, Redis
- Monitoring: Prometheus, Grafana, Nagios
- Containers: 20+ applications via Podman/Quadlet
- Mail: Full IMAP/SMTP stack with FTS
- AI/ML: LiteLLM, JupyterLab, MindsDB, Metabase
- Smart Home: Home Assistant with extensive integrations

**Infrastructure:**
- ZFS storage with automated snapshots
- Cloud backups to Backblaze B2
- Private CA for internal TLS
- SOPS-encrypted secrets in git
- Comprehensive monitoring (35+ exporters)
- Multi-layer disaster recovery

**Documentation:**
- Architecture diagrams
- Service-specific guides
- Troubleshooting documentation
- Setup instructions

---

## Unreleased Changes

Current development on `claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX` branch includes significant documentation improvements and new publishing services. See commit history for details.

## Guidelines for Updates

When updating this changelog:

1. **Keep it for humans**: Write for users, not developers
2. **Group changes**: Use Added, Changed, Deprecated, Removed, Fixed, Security
3. **Be specific**: Include module names, file paths, or service names
4. **Link issues**: Reference GitHub issues when applicable
5. **Date releases**: Use YYYY-MM-DD format
6. **Semantic versioning**: Follow semver for releases

## Categories

- **Added**: New features, services, or modules
- **Changed**: Changes to existing functionality
- **Deprecated**: Features that will be removed
- **Removed**: Removed features or services
- **Fixed**: Bug fixes
- **Security**: Security fixes or improvements
- **Documentation**: Documentation-only changes
- **Infrastructure**: Infrastructure or build changes
