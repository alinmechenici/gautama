# Gautama Troubleshooting Guide

Common issues and their solutions for the Gautama NixOS configuration.

## 📑 Table of Contents

- [System Build Issues](#system-build-issues)
- [Service Failures](#service-failures)
- [Storage & ZFS Issues](#storage--zfs-issues)
- [Networking Problems](#networking-problems)
- [Container Issues](#container-issues)
- [Backup Problems](#backup-problems)
- [Monitoring Issues](#monitoring-issues)
- [Security & Secrets](#security--secrets)
- [Performance Problems](#performance-problems)
- [Recovery Procedures](#recovery-procedures)

## 🔨 System Build Issues

### Build Fails with Evaluation Error

**Symptoms**: `nix flake check` or `nixos-rebuild` fails with evaluation errors

**Solutions**:

```bash
# Show detailed error trace
sudo nixos-rebuild build --flake .#vulcan --show-trace

# Check for syntax errors
nix fmt  # This will also validate syntax

# Verify flake inputs
nix flake metadata

# Update outdated inputs
nix flake update

# Check for circular dependencies
nix flake show
```

**Common Causes**:
- Missing imports in module files
- Typos in option names
- Circular dependencies between modules
- Incompatible flake input versions

### Hash Mismatch Errors

**Symptoms**: `hash mismatch` errors during build

**Solutions**:

```bash
# Update flake lock
nix flake lock --update-input nixpkgs

# Clear Nix cache
nix-collect-garbage -d

# Rebuild with fresh fetch
sudo nixos-rebuild switch --flake .#vulcan --refresh
```

### Out of Disk Space During Build

**Symptoms**: Build fails with "No space left on device"

**Solutions**:

```bash
# Check disk usage
df -h

# Clean Nix store
sudo nix-collect-garbage -d

# Delete old generations
sudo nix-env --delete-generations old

# Optimize Nix store (deduplicate)
nix-store --optimise

# Check for large build artifacts
du -sh /nix/store/* | sort -h | tail -20
```

## ⚙️ Service Failures

### Service Won't Start

**Symptoms**: `systemctl status` shows service as failed

**Diagnosis**:

```bash
# Check service status and recent logs
sudo systemctl status service-name
sudo journalctl -u service-name -n 100 --no-pager

# Check service dependencies
systemctl list-dependencies service-name

# View full service configuration
systemctl cat service-name

# Check if conflicting service is running
systemctl list-units --state=running | grep service
```

**Common Fixes**:

```bash
# Restart the service
sudo systemctl restart service-name

# Check for port conflicts
sudo ss -tulpn | grep :PORT

# Verify file permissions
ls -la /path/to/service/files

# Check if required directories exist
sudo systemctl cat service-name | grep -E "WorkingDirectory|StateDirectory"
```

### PostgreSQL Won't Start

**Symptoms**: PostgreSQL service fails to start

**Solutions**:

```bash
# Check PostgreSQL logs
sudo journalctl -u postgresql -n 200 --no-pager

# Verify data directory ownership
ls -la /var/lib/postgresql/

# Check disk space
df -h /var/lib/postgresql

# Verify port availability
sudo ss -tulpn | grep :5432

# Start in recovery mode if needed
sudo -u postgres postgres --single -D /var/lib/postgresql/17/data
```

**Common Issues**:
- Corrupted data directory
- Insufficient disk space
- Port 5432 already in use
- Wrong permissions on data directory

### Nginx Configuration Error

**Symptoms**: Nginx fails to reload or start

**Solutions**:

```bash
# Test nginx configuration
sudo nginx -t

# Check nginx error log
sudo journalctl -u nginx -n 100 --no-pager

# Verify certificate files exist
ls -la /var/lib/nginx-certs/

# Check port conflicts
sudo ss -tulpn | grep -E ':(80|443)'

# Validate upstream targets
curl -I http://upstream-service:port
```

### Home Assistant Fails to Start

**Symptoms**: Home Assistant service won't start

**Solutions**:

```bash
# Check logs
sudo journalctl -u home-assistant -n 200 --no-pager

# Verify configuration
sudo -u hass hass --script check_config -c /var/lib/hass

# Check database connectivity
sudo -u postgres psql -c "\l" | grep homeassistant

# Clear cache and restart
sudo rm -rf /var/lib/hass/.storage/*cache*
sudo systemctl restart home-assistant

# Restore from backup if needed
sudo systemctl stop home-assistant
sudo cp -r /var/lib/hass/.storage.backup /var/lib/hass/.storage
sudo systemctl start home-assistant
```

## 💾 Storage & ZFS Issues

### ZFS Pool Degraded

**Symptoms**: `zpool status` shows DEGRADED state

**Diagnosis**:

```bash
# Check pool status
zpool status -v

# Check disk health
sudo smartctl -a /dev/disk-id

# View ZFS events
zpool events
```

**Solutions**:

```bash
# If disk is failing, replace it
zpool offline tank /dev/old-disk
# Physical disk replacement
zpool replace tank /dev/old-disk /dev/new-disk

# Clear errors if temporary
zpool clear tank

# Scrub the pool
zpool scrub tank
```

### ZFS Out of Space

**Symptoms**: "No space left on device" with ZFS

**Solutions**:

```bash
# Check pool usage
zpool list
zfs list -o space

# Find large directories
du -sh /tank/* | sort -h | tail -20

# Delete old snapshots
zfs list -t snapshot -o name,used,creation | grep old-snapshot
zfs destroy tank/dataset@snapshot-name

# Clean up old Sanoid snapshots
sudo sanoid --cron
sudo sanoid --prune-snapshots

# Increase pool size (add disk)
zpool add tank /dev/new-disk
```

### Snapshot Issues

**Symptoms**: Snapshots not being created or deleted

**Solutions**:

```bash
# Check Sanoid status
sudo systemctl status sanoid.timer
sudo journalctl -u sanoid -n 50

# Manually create snapshot
sudo zfs snapshot tank/dataset@manual-$(date +%Y%m%d-%H%M%S)

# List all snapshots
zfs list -t snapshot

# Prune old snapshots manually
sudo sanoid --prune-snapshots --verbose
```

## 🌐 Networking Problems

### Can't Access Web Services

**Symptoms**: Services not accessible via browser

**Diagnosis**:

```bash
# Check if nginx is running
sudo systemctl status nginx

# Verify DNS resolution
dig vulcan.lan
ping grafana.vulcan.lan

# Check firewall rules
sudo nft list ruleset | grep -E "(80|443)"

# Test locally first
curl -k https://localhost/
curl http://localhost:9090  # Prometheus
```

**Solutions**:

```bash
# Restart nginx
sudo systemctl restart nginx

# Check certificate validity
openssl s_client -connect grafana.vulcan.lan:443 -servername grafana.vulcan.lan

# Verify upstream services are running
curl http://localhost:3000  # Grafana backend
curl http://localhost:8123  # Home Assistant

# Check nginx access logs
sudo journalctl -u nginx -f
```

### DNS Not Resolving

**Symptoms**: Domain names don't resolve

**Solutions**:

```bash
# Check Technitium DNS service
sudo systemctl status technitium-dns

# Verify DNS server setting
cat /etc/resolv.conf

# Test DNS directly
dig @127.0.0.1 vulcan.lan

# Check zone files
# Access Technitium web UI at http://localhost:5380

# Restart DNS service
sudo systemctl restart technitium-dns
```

### VPN Not Connecting

**Symptoms**: Tailscale or Cloudflare tunnels down

**Solutions**:

```bash
# Tailscale
sudo systemctl status tailscaled
sudo tailscale status
sudo tailscale up

# Cloudflare tunnels
sudo systemctl status cloudflared
sudo journalctl -u cloudflared -n 50

# Check network connectivity
ping 1.1.1.1
ping google.com
```

## 🐳 Container Issues

### Podman Container Won't Start

**Symptoms**: Quadlet container service fails

**Diagnosis**:

```bash
# Check container logs
sudo journalctl -u quadlet-container-name -n 100

# List containers
podman ps -a

# Inspect container
podman inspect container-name

# Check for image issues
podman images
```

**Solutions**:

```bash
# Restart container service
sudo systemctl restart quadlet-container-name

# Pull latest image
podman pull image:tag

# Remove and recreate
sudo systemctl stop quadlet-container-name
podman rm container-name
sudo systemctl start quadlet-container-name

# Check resource limits
podman stats container-name
```

### Container Network Issues

**Symptoms**: Container can't reach other services

**Solutions**:

```bash
# Check container network
podman network ls
podman network inspect podman

# Test from within container
podman exec container-name ping -c 3 host.containers.internal
podman exec container-name curl http://service:port

# Restart network
podman network disconnect podman container-name
podman network connect podman container-name

# Check firewall rules for container network
sudo nft list ruleset | grep podman
```

## 💼 Backup Problems

### Restic Backup Failing

**Symptoms**: Restic backup service fails

**Diagnosis**:

```bash
# Check backup status
sudo journalctl -u restic-backups-home -n 100

# Verify Restic repository
sudo -u root restic -r b2:bucket-name snapshots

# Check B2 credentials
cat /run/secrets/aws-keys

# Test B2 connectivity
curl -I https://api.backblazeb2.com
```

**Solutions**:

```bash
# Unlock repository if locked
sudo -u root restic -r b2:bucket-name unlock

# Rebuild repository index
sudo -u root restic -r b2:bucket-name rebuild-index

# Repair repository
sudo -u root restic -r b2:bucket-name repair snapshots

# Check repository integrity
sudo -u root restic -r b2:bucket-name check

# Manual backup run
sudo systemctl start restic-backups-home.service
```

### ZFS Snapshots Not Running

**Symptoms**: Sanoid not creating snapshots

**Solutions**:

```bash
# Check Sanoid timer
sudo systemctl status sanoid.timer
sudo systemctl list-timers | grep sanoid

# Run Sanoid manually
sudo sanoid --cron --verbose

# Check Sanoid configuration
sudo sanoid --monitor-snapshots

# View Sanoid logs
sudo journalctl -u sanoid -n 100
```

## 📊 Monitoring Issues

### Prometheus Not Scraping Targets

**Symptoms**: Targets show as down in Prometheus

**Diagnosis**:

```bash
# Check Prometheus status
sudo systemctl status prometheus
curl http://localhost:9090/-/healthy

# View targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'

# Check exporter directly
curl http://localhost:9100/metrics  # Node exporter
curl http://localhost:9187/metrics  # PostgreSQL exporter
```

**Solutions**:

```bash
# Restart Prometheus
sudo systemctl restart prometheus

# Reload configuration
sudo systemctl reload prometheus

# Check scrape configs
sudo journalctl -u prometheus -n 100 | grep -i error

# Verify exporter services are running
systemctl list-units '*exporter*'
```

### Grafana Dashboard Not Loading

**Symptoms**: Grafana shows "No data"

**Solutions**:

```bash
# Check Grafana logs
sudo journalctl -u grafana -n 100

# Verify data source connection
curl -u admin:password http://localhost:3000/api/datasources

# Check Prometheus query
curl 'http://localhost:9090/api/v1/query?query=up'

# Restart Grafana
sudo systemctl restart grafana

# Reset admin password if needed
sudo -u grafana grafana-cli admin reset-admin-password newpassword
```

## 🔐 Security & Secrets

### Secrets Not Decrypting

**Symptoms**: Services can't access `/run/secrets/`

**Diagnosis**:

```bash
# Check if secrets are deployed
ls -la /run/secrets/

# Verify age key exists
ls -la ~/.config/sops/age/keys.txt

# Check SOPS configuration
cat .sops.yaml

# Test decryption manually
sops -d secrets.yaml
```

**Solutions**:

```bash
# Ensure age key has correct permissions
chmod 600 ~/.config/sops/age/keys.txt

# Re-deploy secrets
sudo nixos-rebuild switch --flake .#vulcan

# Check service permissions
stat /run/secrets/secret-name

# Verify service has access
sudo -u service-user cat /run/secrets/secret-name
```

### step-ca Certificate Issues

**Symptoms**: Services can't get TLS certificates

**Solutions**:

```bash
# Check step-ca status
sudo systemctl status step-ca
sudo journalctl -u step-ca -n 50

# Verify CA is healthy
step ca health --ca-url https://localhost:8443

# List certificates
step certificate inspect /var/lib/step-ca/certs/root_ca.crt

# Renew certificate manually
/etc/nixos/certs/renew-certificate.sh domain.lan -o /output/dir

# Check certificate expiry
openssl x509 -in /path/to/cert.crt -noout -dates
```

## 🚀 Performance Problems

### High Memory Usage

**Symptoms**: System using excessive RAM

**Diagnosis**:

```bash
# Check memory usage
free -h
htop

# Find memory-hungry processes
ps aux --sort=-%mem | head -20

# Check ZFS ARC usage
cat /proc/spl/kstat/zfs/arcstats | grep -E "^size|^c_max|^c_min"
```

**Solutions**:

```bash
# Adjust ZFS ARC limits
# Edit modules/storage/zfs.nix
# boot.kernelParams = [ "zfs.zfs_arc_max=34359738368" ];  # 32GB

# Restart high-memory services
sudo systemctl restart service-name

# Clear filesystem caches
sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
```

### High CPU Usage

**Symptoms**: CPU constantly at 100%

**Diagnosis**:

```bash
# Check CPU usage
top
htop

# Find CPU-hungry processes
ps aux --sort=-%cpu | head -20

# Check for runaway containers
podman stats

# Monitor systemd services
systemd-cgtop
```

**Solutions**:

```bash
# Restart problematic service
sudo systemctl restart service-name

# Check for infinite loops in scripts
sudo journalctl -u service-name -f

# Limit container resources
# Add to quadlet file:
# CPUQuota=50%
# MemoryLimit=1G
```

### Slow Disk I/O

**Symptoms**: High disk wait times

**Diagnosis**:

```bash
# Check I/O stats
iostat -x 1

# Monitor ZFS I/O
zpool iostat -v 1

# Check for scrub/resilver
zpool status

# Find processes doing I/O
iotop
```

**Solutions**:

```bash
# Pause ZFS scrub if running
zpool scrub -p tank

# Check for failing disks
sudo smartctl -a /dev/disk-id

# Adjust ZFS parameters
# Edit modules/storage/zfs.nix

# Clear I/O cache
sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
```

## 🔄 Recovery Procedures

### Rollback to Previous Configuration

**Symptoms**: New configuration breaks system

**Solution**:

```bash
# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or boot into previous generation from GRUB menu
# Select "NixOS - Configuration X" from boot menu
```

### Restore from ZFS Snapshot

**Symptoms**: Accidental file deletion or corruption

**Solution**:

```bash
# List snapshots
zfs list -t snapshot | grep dataset-name

# Rollback to snapshot (destructive, loses newer data)
sudo zfs rollback tank/dataset@snapshot-name

# Or clone snapshot and copy files (non-destructive)
sudo zfs clone tank/dataset@snapshot-name tank/recovery
# Copy files from /tank/recovery
sudo zfs destroy tank/recovery
```

### Restore from Restic Backup

**Symptoms**: Need to restore files from cloud backup

**Solution**:

```bash
# List snapshots
restic-snapshots

# List files in snapshot
restic -r b2:bucket ls snapshot-id

# Restore specific files
restic -r b2:bucket restore snapshot-id --target /restore-location --include /path/to/file

# Restore entire snapshot
restic -r b2:bucket restore latest --target /restore-location
```

### Emergency Boot Recovery

**Symptoms**: System won't boot

**Solution**:

1. **Boot from Asahi Linux installer USB**
2. **Mount NixOS partitions**:
   ```bash
   sudo mount /dev/nvme0n1p5 /mnt
   sudo mount /dev/nvme0n1p1 /mnt/boot
   ```
3. **Chroot into system**:
   ```bash
   sudo nixos-enter --root /mnt
   ```
4. **Fix issue and rebuild**:
   ```bash
   cd /etc/nixos
   nixos-rebuild switch --flake .#vulcan
   ```
5. **Exit and reboot**:
   ```bash
   exit
   sudo reboot
   ```

## 📞 Getting More Help

If these solutions don't resolve your issue:

1. **Check Documentation**: Review `docs/md/` for service-specific guides
2. **Search Issues**: Look for similar issues on GitHub
3. **Enable Debug Logging**: Add `--verbose` or `--debug` flags to commands
4. **Ask for Help**:
   - NixOS Discourse: https://discourse.nixos.org/
   - NixOS Matrix: #nixos:nixos.org
   - r/NixOS: https://reddit.com/r/NixOS
5. **Open an Issue**: Provide logs, configuration snippets, and steps to reproduce

## 📋 Diagnostic Data Collection

When reporting issues, collect:

```bash
# System information
nixos-version
uname -a
nix flake metadata

# Service logs
sudo journalctl -u service-name -n 200 --no-pager > service.log

# System status
systemctl --failed > failed-services.txt
zpool status -v > zpool-status.txt
df -h > disk-usage.txt

# Configuration (redact secrets!)
nix flake show > flake-info.txt
```
