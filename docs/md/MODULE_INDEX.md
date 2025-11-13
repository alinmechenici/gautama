# Gautama Module Index

Complete reference of all NixOS modules in the Gautama configuration.

## 📋 Table of Contents

- [Overview](#overview)
- [Module Categories](#module-categories)
- [Core Modules](#core-modules)
- [Service Modules](#service-modules)
- [Container Modules](#container-modules)
- [Monitoring Modules](#monitoring-modules)
- [Storage Modules](#storage-modules)
- [Security Modules](#security-modules)
- [User Modules](#user-modules)
- [Maintenance Modules](#maintenance-modules)
- [Library Functions](#library-functions)
- [How to Use Modules](#how-to-use-modules)

## 📊 Overview

**Total Modules**: 80+
**Categories**: 11
**Services**: 66
**Containers**: 24

## 🗂️ Module Categories

| Category | Count | Purpose |
|----------|-------|---------|
| **Core** | 7 | System fundamentals (boot, networking, system) |
| **Services** | 66 | Application services |
| **Containers** | 24 | Containerized applications |
| **Monitoring** | 35+ | Observability and metrics |
| **Storage** | 5 | ZFS and backups |
| **Security** | 3 | Hardening and secrets |
| **Users** | 4 | User management |
| **Maintenance** | 2 | Timers and automation |
| **Library** | 5 | Reusable functions |
| **Options** | Multiple | Custom NixOS options |
| **Packages** | 10+ | Custom packages and overlays |

## 🔧 Core Modules

Located in `modules/core/`

| Module | File | Purpose |
|--------|------|---------|
| **Boot** | `boot.nix` | GRUB/EFI configuration, kernel parameters |
| **Networking** | `networking.nix` | NetworkManager, hostname, DNS |
| **Firewall** | `firewall.nix` | nftables firewall rules |
| **Nix** | `nix.nix` | Nix daemon, flakes, build settings |
| **System** | `system.nix` | System-level configuration, state version |
| **Programs** | `programs.nix` | System-wide programs and tools |
| **Systemd Rate Limit Fix** | `systemd-rate-limit-fix.nix` | Systemd rate limiting adjustments |

## 🌐 Service Modules

Located in `modules/services/`

### Web Services

| Module | File | Port | Purpose |
|--------|------|------|---------|
| **Nginx** | `web.nix` | 80, 443 | Reverse proxy, TLS termination |
| **Home Assistant** | `home-assistant.nix` | 8123 | Smart home automation |
| **Nextcloud** | `nextcloud.nix` | 80 | Cloud storage and collaboration |
| **Jellyfin** | `jellyfin.nix` | 8096 | Media server |
| **Gitea** | `gitea.nix` | 3001 | Self-hosted Git service |
| **Glance** | `glance.nix` | 8080 | Dashboard |
| **Roundcube** | `roundcube.nix` | 80 | Webmail client |
| **Cockpit** | `cockpit.nix` | 9090 | Server management UI |
| **pgAdmin** | `pgadmin.nix` | 5050 | PostgreSQL administration |

### Publishing & Documentation

| Module | File | Port | Purpose |
|--------|------|------|---------|
| **Jekyll** | `jekyll.nix` | 4000 | Static site generator |
| **Quarto** | `quarto.nix` | 4001 | Technical publishing |

### Databases

| Module | File | Port | Purpose |
|--------|------|------|---------|
| **PostgreSQL** | `databases.nix` | 5432 | Main database server |
| **Redis** | Multiple | 6379, 6380 | Key-value cache (LiteLLM, Nextcloud) |

### Mail Services

| Module | File | Port | Purpose |
|--------|------|------|---------|
| **Postfix** | `postfix.nix` | 25 | SMTP server |
| **Dovecot** | `dovecot.nix` | 143 | IMAP server with FTS |
| **mbsync** | `mbsync.nix` | - | Mail synchronization |
| **Rspamd** | `rspamd.nix` | - | Spam filtering |

### Monitoring & Metrics

| Module | File | Port | Purpose |
|--------|------|------|---------|
| **Prometheus** | `prometheus-monitoring.nix` | 9090 | Metrics collection |
| **Grafana** | `grafana.nix` | 3000 | Visualization |
| **Nagios** | `nagios.nix` | - | Legacy monitoring |
| **Alertmanager** | Included | 9093 | Alert routing |

### Infrastructure

| Module | File | Port | Purpose |
|--------|------|------|---------|
| **step-ca** | `certificates.nix` | 8443 | Private certificate authority |
| **Technitium DNS** | `technitium-dns.nix` | 53, 5380 | DNS server |
| **N8N** | `n8n.nix` | 5678 | Workflow automation |
| **Node-RED** | `node-red.nix` | 1880 | Visual automation |
| **Tailscale** | Network config | - | VPN mesh network |

### Other Services

| Module | File | Purpose |
|--------|------|---------|
| **Radicale** | `radicale.nix` | CalDAV/CardDAV |
| **Aria2** | `aria2.nix` | Download manager |
| **Paperless** | `paperless.nix` | Document management |
| **Samba** | `samba.nix` | File sharing |

## 🐳 Container Modules

Located in `modules/containers/`

### AI/ML Containers

| Module | File | Port | Purpose |
|--------|------|------|---------|
| **LiteLLM** | `litellm-quadlet.nix` | 4000 | LLM proxy and gateway |
| **Vanna AI** | `vanna-quadlet.nix` | 8084 | SQL code generation |
| **Silly Tavern** | `sillytavern-quadlet.nix` | 8000 | AI chat interface |
| **MindsDB** | `mindsdb-quadlet.nix` | 47334 | ML automation |
| **JupyterLab** | `jupyter-quadlet.nix` | 8888 | Data science notebooks |
| **Metabase** | `metabase-quadlet.nix` | 3000 | Business intelligence |

### Publishing & Project Management

| Module | File | Port | Purpose |
|--------|------|------|---------|
| **Typst** | `typst-quadlet.nix` | 4002 | Modern typesetting |
| **Redmine** | `redmine-quadlet.nix` | 4003 | Project management |

### Productivity Containers

| Module | File | Port | Purpose |
|--------|------|------|---------|
| **Wallabag** | `wallabag-quadlet.nix` | 80 | Article archiving |
| **Monica** | `monica-quadlet.nix` | 80 | Personal CRM |
| **Teable** | `teable-quadlet.nix` | 3000 | Spreadsheet database |
| **NoCo Base** | `noco-quadlet.nix` | 8080 | Database/CRM platform |
| **Paperless-AI** | `paperless-quadlet.nix` | 8000 | Document processing |
| **BudgetBoard** | `budgetboard-quadlet.nix` | 3000 | Finance dashboard |

### Infrastructure Containers

| Module | File | Port | Purpose |
|--------|------|------|---------|
| **OPNsense Exporter** | `opnsense-exporter-quadlet.nix` | 9233 | Firewall metrics |
| **OpenSpeedtest** | `speedtest-quadlet.nix` | 3000 | Network performance |
| **ChangeDetection** | `changedetection-quadlet.nix` | 5000 | Website monitoring |
| **Copyparty** | `copyparty-quadlet.nix` | 8088 | File sharing |
| **Secure Nginx** | `secure-nginx-quadlet.nix` | 443 | Isolated nginx |

### Platform

| Module | File | Purpose |
|--------|------|---------|
| **Quadlet Base** | `quadlet.nix` | Podman/Quadlet configuration |
| **Windows 11** | `windows-quadlet.nix` | VM container |

## 📊 Monitoring Modules

Located in `modules/monitoring/`

### Exporters

| Module | File | Port | Metrics |
|--------|------|------|---------|
| **Node Exporter** | Included | 9100 | System metrics |
| **PostgreSQL Exporter** | Included | 9187 | Database metrics |
| **Systemd Exporter** | Included | 9558 | Service status |
| **Postfix Exporter** | Included | 9154 | Mail queue stats |
| **ZFS Exporter** | Included | 9134 | ZFS pool health |
| **Blackbox Exporter** | Included | 9115 | HTTP/ICMP probes |
| **Nginx Exporter** | Included | 9113 | Nginx metrics |

### Custom Exporters

| Module | File | Purpose |
|--------|------|---------|
| **Home Assistant Exporter** | `services/ha-exporter.nix` | HA metrics |
| **Technitium DNS Exporter** | `services/technitium-exporter.nix` | DNS metrics |
| **Git Workspace Exporter** | `services/git-workspace-exporter.nix` | Repository metrics |
| **Container Health Exporter** | `services/container-health-exporter.nix` | Container status |

### Textfile Collectors

| Module | Purpose |
|--------|---------|
| **Restic Collector** | Backup metrics |
| **mbsync Collector** | Mail sync metrics |

### Alert Rules

Located in `modules/monitoring/alerts/`

| File | Alerts For |
|------|-----------|
| `system.yaml` | CPU, memory, disk |
| `systemd.yaml` | Service failures |
| `database.yaml` | PostgreSQL issues |
| `storage.yaml` | ZFS health |
| `certificates.yaml` | Certificate expiry |
| `network.yaml` | Network connectivity |
| `nextcloud.yaml` | Nextcloud-specific |

## 💾 Storage Modules

Located in `modules/storage/`

| Module | File | Purpose |
|--------|------|---------|
| **ZFS** | `zfs.nix` | ZFS pool configuration, ARC tuning |
| **Backups** | `backups.nix` | Restic cloud backups configuration |
| **Backup Monitoring** | `backup-monitoring.nix` | Backup metrics collection |
| **Sanoid** | Included in ZFS | Snapshot automation |

## 🔐 Security Modules

Located in `modules/security/`

| Module | File | Purpose |
|--------|------|---------|
| **Hardening** | `hardening.nix` | System security hardening |
| **SOPS Secrets** | Configured in host | Encrypted secrets management |
| **Step-CA** | In services | Private certificate authority |

## 👤 User Modules

Located in `modules/users/`

| Module | File | Purpose |
|--------|------|---------|
| **Base Users** | `default.nix` | Common user configuration |
| **johnw** | `johnw.nix` | Primary user account |
| **assembly** | `assembly.nix` | Secondary user account |
| **Home Manager** | `home-manager/` | User environment management |

## 🔧 Maintenance Modules

Located in `modules/maintenance/`

| Module | File | Purpose |
|--------|------|---------|
| **Timers** | `timers.nix` | 32+ scheduled tasks |
| **Logwatch** | Configured | Daily log reports |

## 📚 Library Functions

Located in `modules/lib/`

| Function | File | Purpose |
|----------|------|---------|
| **mkMbsyncModule** | `mkMbsyncModule.nix` | Create mail sync services |
| **mkQuadletService** | Various | Create container services |
| **mkPostgresUserSetup** | Various | PostgreSQL user creation |
| **bindTankModule** | Various | ZFS mount binding |

## 🎨 Custom Packages & Overlays

Located in `overlays/`

| Overlay | Purpose |
|---------|---------|
| **Claude Code** | Claude Code integration |
| **Custom Tools** | Modified or custom packages |
| **Check Systemd** | Systemd verification |
| **ZFS 16K** | ZFS page size for Apple Silicon |

## 📦 How to Use Modules

### Enabling a Module

Add to `hosts/vulcan/default.nix`:

```nix
{
  imports = [
    ../../modules/services/jekyll.nix
    ../../modules/containers/typst-quadlet.nix
  ];
}
```

### Disabling a Module

Comment out or remove the import:

```nix
{
  imports = [
    # ../../modules/services/jekyll.nix  # Disabled
  ];
}
```

### Module Dependencies

Some modules have dependencies:

- **Container modules** require `quadlet.nix`
- **Services using PostgreSQL** require `databases.nix`
- **Services with certificates** require `certificates.nix` (step-ca)
- **Monitored services** work with `prometheus-monitoring.nix`

### Creating a New Module

1. **Choose category**: Determine the appropriate directory
2. **Follow patterns**: Use existing modules as templates
3. **Include sections**:
   - Service configuration
   - Secrets (if needed)
   - Networking/firewall
   - Systemd service
   - Monitoring
4. **Test**: Build and verify
5. **Document**: Add to this index

### Module Template

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

  # Nginx reverse proxy (if needed)
  services.nginx.virtualHosts."myservice.vulcan.lan" = {
    forceSSL = true;
    sslCertificate = "/var/lib/nginx-certs/myservice.vulcan.lan.crt";
    sslCertificateKey = "/var/lib/nginx-certs/myservice.vulcan.lan.key";
    locations."/" = {
      proxyPass = "http://127.0.0.1:1234";
    };
  };

  # Monitoring (if needed)
  services.prometheus.scrapeConfigs = [
    {
      job_name = "myservice";
      static_configs = [{
        targets = [ "127.0.0.1:1234" ];
      }];
    }
  ];
}
```

## 🔍 Finding Modules

### By Service Name

Use `grep` to find modules:

```bash
# Find Jekyll module
grep -r "jekyll" modules/

# Find all PostgreSQL references
grep -r "postgresql" modules/
```

### By Function

Search for specific functionality:

```bash
# Find all services with Nginx reverse proxy
grep -r "virtualHosts" modules/services/

# Find all containerized services
ls modules/containers/*-quadlet.nix
```

### By Port

Find what's listening on a port:

```bash
# Find service on port 4000
grep -r "4000" modules/
```

## 📊 Module Statistics

| Category | Count |
|----------|-------|
| Total Nix files | 167 |
| Service modules | 66 |
| Container modules | 24 |
| Monitoring exporters | 35+ |
| Alert rule files | 7 |
| Library functions | 5 |
| Overlays | 10+ |

## 🔄 Module Updates

When updating modules:

1. **Test changes**: `nixos-rebuild build --flake .#vulcan`
2. **Check formatting**: `nix fmt`
3. **Update docs**: Update this index if needed
4. **Commit**: Follow conventional commits format
5. **Test in VM**: When possible

## 📚 Additional Resources

- [Module Documentation](../README.md) - Overview
- [Contributing Guide](../../CONTRIBUTING.md) - How to add modules
- [Architecture](../d2/) - D2 diagrams showing module relationships

---

**Last Updated**: 2024-11-13
**Total Modules**: 80+
**Categories**: 11
