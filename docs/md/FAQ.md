# Frequently Asked Questions (FAQ)

Common questions about the Gautama NixOS configuration.

## General Questions

### What is Gautama?

Gautama is a production-grade NixOS configuration for self-hosted infrastructure running on Apple Silicon hardware. It provides a complete stack including web services, databases, monitoring, AI/ML platforms, smart home automation, containerized applications, and comprehensive backup strategies—all managed declaratively with NixOS.

### Why is it called "Gautama"?

Named after Siddhartha Gautama (the Buddha), this configuration embodies the principles of enlightenment applied to infrastructure: mindful architecture, the path to simplicity through declarative design, continuous improvement, and disciplined practice of best practices.

### Who is this for?

- **Self-hosters** wanting a production-quality home infrastructure
- **NixOS enthusiasts** looking for real-world configuration examples
- **DevOps professionals** wanting to practice infrastructure-as-code
- **Privacy advocates** who want complete control over their data
- **Learners** studying modern infrastructure patterns

### Can I use this for my own setup?

Yes! Gautama is designed to be adapted. Fork it, customize it, remove services you don't need, add your own. The modular architecture makes it easy to pick and choose components.

## NixOS Questions

### Why NixOS instead of Ubuntu/Debian/Arch?

**Declarative Configuration**: Your entire system is defined in code—no hidden state, no configuration drift.

**Atomic Upgrades**: System changes are all-or-nothing. If an upgrade fails, you still have a working system.

**Reproducibility**: Rebuild the exact same system anywhere. Disaster recovery becomes trivial.

**Rollbacks**: Boot into any previous system generation from the GRUB menu.

**Development-Production Parity**: Test changes in a VM before deploying to production.

### Is NixOS difficult to learn?

NixOS has a steeper learning curve than traditional Linux distributions, but:
- The benefits are worth it for infrastructure management
- The Gautama configuration serves as a learning resource
- Once you understand the patterns, it's very powerful
- The community is helpful and growing

### Can I run this on regular x86_64 hardware?

Yes, but you'd need to:
- Remove Apple Silicon-specific modules (Asahi Linux)
- Adjust hardware configuration
- Modify boot configuration (GRUB/systemd-boot)
- Update ZFS page size settings

The core services and architecture are portable.

## Hardware Questions

### Why Apple Silicon?

- **Energy Efficient**: Low power consumption for 24/7 operation
- **Powerful**: Excellent performance for the power draw
- **Quiet**: Fanless or very quiet operation
- **Asahi Linux Support**: Excellent and improving Linux support
- **Value**: Good performance per dollar for the use case

### Do I need 64GB RAM?

Not necessarily. RAM requirements depend on your workload:
- **16GB**: Minimal services (web, mail, basic monitoring)
- **32GB**: Most services, limited containers
- **64GB**: All services + many containers + ZFS ARC

ZFS ARC can be tuned to work with available RAM.

### Can I use a different filesystem than ZFS?

Yes, but you'd lose:
- Snapshot functionality
- Compression
- Data integrity checking
- Many backup features

You could use ext4/btrfs, but you'd need to rewrite the storage modules.

### What about running this in a VM?

Absolutely! You can:
- Test in a VM: `nixos-rebuild build-vm --flake .#vulcan`
- Run permanently in a VM on any hypervisor
- Use for development and testing
- Create multiple environments

## Service Questions

### How many services are included?

- 60+ native systemd services
- 20+ containerized applications
- 35+ Prometheus exporters
- 32+ scheduled timer jobs

You don't have to run all of them—disable what you don't need.

### Can I add my own services?

Yes! The modular architecture makes it easy:
1. Create a new module in `modules/services/`
2. Import it in `hosts/vulcan/default.nix`
3. Rebuild the system

See existing modules for patterns to follow.

### Which services are most resource-intensive?

**Heaviest**:
- Home Assistant (with many integrations)
- PostgreSQL (with large databases)
- Jellyfin (during transcoding)
- AI/ML containers (LiteLLM, Jupyter, etc.)

**Lightest**:
- Nginx
- Prometheus exporters
- Most monitoring tools
- DNS, mail forwarding

### Can I disable services I don't need?

Yes! Edit `hosts/vulcan/default.nix` and comment out module imports you don't want. The system will rebuild without them.

## Container Questions

### Why Podman instead of Docker?

- **Rootless by default**: Better security
- **Systemd integration**: Native service management via Quadlet
- **No daemon**: Simpler architecture
- **OCI compliant**: Works with Docker images
- **NixOS integration**: Better fit with NixOS philosophy

### Can I use Docker instead?

Yes, NixOS supports Docker. You'd need to:
- Enable `virtualisation.docker.enable = true;`
- Remove Quadlet configurations
- Rewrite container definitions for Docker
- Adjust networking

### How do I add a new container?

1. Create a quadlet file in `modules/containers/`
2. Use the `mkQuadletService` library function
3. Define image, ports, volumes, environment
4. Import in `hosts/vulcan/default.nix`
5. Rebuild

See existing container modules for examples.

## Backup Questions

### How are backups handled?

**Three layers**:
1. **ZFS Snapshots**: Hourly/daily/weekly/monthly local snapshots
2. **PostgreSQL Dumps**: Daily database-specific backups
3. **Restic Cloud Backups**: Daily encrypted backups to Backblaze B2

### How much does Backblaze B2 cost?

**Approximate costs** (depends on data size):
- Storage: $0.005/GB/month
- Download: $0.01/GB
- API calls: Mostly free

For 500GB backup: ~$2.50/month
For 1TB backup: ~$5/month

Much cheaper than Dropbox, Google Drive, etc.

### Can I use a different backup provider?

Yes! Restic supports many backends:
- Amazon S3
- Google Cloud Storage
- Azure Blob Storage
- Local filesystems
- SFTP/SSH
- And more

Edit `modules/storage/backups.nix` to change the backend.

### How do I restore from backup?

**ZFS snapshot**: `sudo zfs rollback dataset@snapshot`
**Restic**: `restic restore snapshot-id --target /restore/path`
**PostgreSQL**: `psql database < backup.sql`

See `docs/md/TROUBLESHOOTING.md` for detailed procedures.

## Monitoring Questions

### Why so many exporters?

**Comprehensive visibility**: You can't fix what you can't see.
- System health (CPU, RAM, disk, network)
- Service health (databases, web servers, containers)
- Application metrics (Home Assistant, Git, backups)
- Storage metrics (ZFS, disk space, I/O)

Better to have too much data than too little.

### Can I reduce the monitoring overhead?

Yes:
- Increase scrape intervals (default: 15s)
- Disable exporters you don't need
- Reduce Prometheus retention (default: 15 days)
- Use VictoriaMetrics for more efficient storage

### How do I access Grafana?

`https://grafana.vulcan.lan` (default login: admin/admin - change immediately!)

You can also access via:
- Tailscale VPN
- Cloudflare Tunnels
- Local network IP

### What dashboards are included?

Dashboards for:
- System overview (node exporter)
- PostgreSQL databases
- ZFS pools
- Container metrics
- Service-specific metrics
- Custom application metrics

## Security Questions

### How are secrets managed?

**SOPS-nix**: Secrets are encrypted with age/PGP keys and stored in git.
- Encrypted at rest in `secrets.yaml`
- Decrypted at system activation
- Available at runtime in `/run/secrets/`
- Never stored in plain text

### Is it safe to store secrets in git?

Yes, when using SOPS:
- Secrets are encrypted before committing
- Only holders of the age private key can decrypt
- Git history doesn't expose secrets
- You can safely push to public repositories

Keep your age key safe and backed up securely!

### What about network security?

**Multiple layers**:
- NixOS firewall (nftables)
- TLS encryption for all services (step-ca)
- Rootless containers
- SOPS-encrypted secrets
- Security hardening module
- Regular security updates via nixpkgs

### How do I secure remote access?

**Options**:
1. **Tailscale VPN**: Encrypted mesh network (recommended)
2. **Cloudflare Tunnels**: Zero-trust access without port forwarding
3. **Nebula VPN**: Self-hosted overlay network
4. **WireGuard**: Traditional VPN (requires configuration)

Never expose services directly to the internet without authentication.

## Mail Questions

### Why self-host email?

- **Privacy**: Your emails aren't scanned for ads
- **Control**: You control retention, backups, access
- **Learning**: Understand how email infrastructure works
- **Independence**: Not dependent on email providers

### Do I need to run my own mail server?

No! Gautama's mail setup is **pull-only**:
- mbsync pulls from external providers (Fastmail, Gmail)
- Dovecot provides local IMAP access
- Postfix handles local delivery only

You don't need to deal with spam fighting, deliverability, etc.

### Can I send email from Gautama?

Currently configured for **receiving only**. To send:
- Use your external provider's SMTP
- Configure Postfix as a smarthost relay
- Set up SPF/DKIM/DMARC if running a full mail server

Sending mail requires more setup and deliverability work.

## Performance Questions

### What's the expected resource usage?

**Idle** (most services running):
- CPU: 5-15%
- RAM: 16-32GB (including ZFS ARC)
- Disk I/O: Minimal

**Active** (backup, transcoding, heavy AI work):
- CPU: 50-100%
- RAM: up to configured limit
- Disk I/O: Heavy during backups

### How can I reduce resource usage?

1. **Disable unused services**
2. **Reduce ZFS ARC size**
3. **Limit container resources**
4. **Increase scrape intervals**
5. **Reduce backup frequency**
6. **Use lighter alternatives** (if available)

### Can this run on a Raspberry Pi?

Not recommended for the full configuration:
- Too many services for Pi's resources
- ZFS requires more RAM than Pi has
- Containers would be slow

You could run a **minimal subset** of services on a Pi.

## Cost Questions

### What does it cost to run Gautama?

**Initial Hardware** (example):
- Mac Mini M2: $599-$1,200 (depending on RAM/storage)
- External drives (optional): $100-$300

**Monthly Operating Costs**:
- Electricity: ~$5-10/month (very efficient)
- Backblaze B2: ~$3-10/month (depends on data size)
- Domain names (optional): ~$10-20/year
- Total: ~$10-20/month

**Compare to cloud alternatives**:
- Similar services on AWS/GCP: $200-500+/month
- Managed services: $50-200+/month

**Break-even**: 6-12 months

### Is it worth the effort?

**Pros**:
- Complete control and privacy
- Excellent learning experience
- Cost-effective long-term
- Fun and rewarding
- Impressive portfolio piece

**Cons**:
- Significant initial time investment
- Ongoing maintenance responsibility
- Hardware failure risk (mitigated by backups)
- Not "someone else's problem"

Worth it if you value privacy, learning, and control!

## Maintenance Questions

### How much maintenance does it require?

**Weekly**: Check monitoring dashboards (5 minutes)
**Monthly**: Review logs, update packages (30-60 minutes)
**Quarterly**: Test backups, review security (2-4 hours)
**As needed**: Fix issues, add services, optimize

Total: ~2-5 hours/month average

### How do I update the system?

```bash
# Update flake inputs
nix flake update

# Test build
sudo nixos-rebuild build --flake .#vulcan

# Apply updates
sudo nixos-rebuild switch --flake .#vulcan
```

### What if an update breaks something?

**Rollback** to previous generation:
```bash
sudo nixos-rebuild switch --rollback
```

Or select previous generation from GRUB menu at boot.

This is why NixOS is great!

## Migration Questions

### Can I migrate from my existing server?

Yes! You can:
1. **Parallel migration**: Run Gautama alongside existing server, migrate services incrementally
2. **Direct migration**: Export data, rebuild on Gautama, import data
3. **Hybrid approach**: Some services on Gautama, some on old server

Data export/import varies by service.

### How do I migrate to different hardware?

1. **Update hardware configuration**:
   ```bash
   nixos-generate-config --show-hardware-config > hosts/vulcan/hardware-configuration.nix
   ```
2. **Adjust hardware-specific settings** (ZFS, boot, etc.)
3. **Rebuild system**
4. **Restore data** from backups

The beauty of NixOS: configuration is portable!

### Can I migrate from Docker Compose?

Yes! For each service:
1. Export Docker volumes/data
2. Create equivalent Quadlet configuration
3. Import data to new locations
4. Test service functionality
5. Decommission Docker container

See `docs/md/quadlet-guide.md` for container migration patterns.

## Contributing Questions

### How can I contribute?

- **Report bugs**: Open issues for problems you find
- **Suggest improvements**: Ideas for better patterns or services
- **Submit PRs**: Bug fixes, new services, documentation
- **Share your config**: Show how you've customized Gautama
- **Write guides**: Document your experiences

See `CONTRIBUTING.md` for guidelines.

### Can I use this commercially?

This configuration is for **personal use**. You can:
- Learn from it
- Adapt it for your own infrastructure
- Use patterns in your projects

For commercial use, ensure licenses of all components allow it.

### How do I report security issues?

**Do not** open public issues for security vulnerabilities.

Email security concerns to the maintainer privately (see `SECURITY.md`).

## Getting Help

### Where can I get help?

1. **Documentation**: Check `docs/md/` for detailed guides
2. **Troubleshooting**: See `docs/md/TROUBLESHOOTING.md`
3. **Issues**: Search existing GitHub issues
4. **NixOS Community**:
   - [NixOS Discourse](https://discourse.nixos.org/)
   - [NixOS Matrix](https://matrix.to/#/#nixos:nixos.org)
   - [r/NixOS](https://reddit.com/r/NixOS)
5. **Open an issue**: Provide details and logs

### How do I ask good questions?

Include:
- What you're trying to do
- What you expected to happen
- What actually happened
- Relevant logs and error messages
- Steps to reproduce
- Your environment (NixOS version, hardware, etc.)

See `docs/md/TROUBLESHOOTING.md` for diagnostic data to collect.

### Is there a community around Gautama?

Currently, Gautama is primarily a reference implementation. You can:
- Open issues for discussion
- Share your customizations
- Connect with other NixOS self-hosters
- Join the broader NixOS community

---

**Have a question not answered here?**

[Open an issue](https://github.com/yourusername/gautama/issues) and we'll add it to the FAQ!
