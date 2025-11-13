# Gautama Quick Start Guide

This guide walks you through setting up a Gautama-based NixOS system from scratch.

## ⏱️ Estimated Time

- **Basic Installation**: 2-4 hours
- **Service Configuration**: 4-8 hours
- **Complete Setup with Secrets**: 1-2 days

## ✅ Prerequisites Checklist

### Hardware Requirements

- [ ] **Apple Silicon Mac** (M1, M2, M3 series)
- [ ] **Minimum 32GB RAM** (64GB recommended for ZFS)
- [ ] **500GB+ Storage** (1TB+ recommended)
- [ ] **Stable Internet Connection**
- [ ] **External USB Drive** (for Asahi Linux installer)

### Knowledge Requirements

- [ ] Basic Linux command-line experience
- [ ] Understanding of networking concepts
- [ ] Familiarity with git and version control
- [ ] Basic understanding of systemd services

### Before You Begin

- [ ] **Backup your Mac** - The installation will repartition your disk
- [ ] **Download Asahi Linux installer**
- [ ] **Create Backblaze B2 account** (for cloud backups, optional)
- [ ] **Prepare age encryption keys** (for SOPS secrets)

## 📋 Installation Steps

### Step 1: Install Asahi Linux

**Duration: 30-60 minutes**

1. **Run the Asahi Linux installer** from macOS:
   ```bash
   curl https://alx.sh | sh
   ```

2. **Follow the installer prompts:**
   - Choose "NixOS" as your distribution
   - Allocate at least 500GB for the Linux partition
   - Create a user account
   - Wait for the installation to complete

3. **Reboot into NixOS**:
   - Hold down the power button during boot
   - Select the NixOS boot option
   - Log in with your user credentials

### Step 2: Clone the Gautama Configuration

**Duration: 10 minutes**

1. **Install git** (if not already installed):
   ```bash
   nix-shell -p git
   ```

2. **Clone the repository**:
   ```bash
   # Using HTTPS
   git clone https://github.com/yourusername/gautama.git /etc/nixos

   # Or using SSH (if you have keys set up)
   git clone git@github.com:yourusername/gautama.git /etc/nixos
   ```

3. **Navigate to the configuration**:
   ```bash
   cd /etc/nixos
   ```

### Step 3: Configure Hardware Settings

**Duration: 15-30 minutes**

1. **Generate hardware configuration**:
   ```bash
   sudo nixos-generate-config --show-hardware-config > hosts/vulcan/hardware-configuration.nix
   ```

2. **Review and adjust hardware settings**:
   ```bash
   nano hosts/vulcan/hardware-configuration.nix
   ```

3. **Update the hostname** (if different from "vulcan"):
   ```bash
   nano hosts/vulcan/default.nix
   # Change networking.hostName = "vulcan"; to your desired hostname
   ```

### Step 4: Set Up SOPS Secrets

**Duration: 30-60 minutes**

1. **Generate age encryption keys**:
   ```bash
   nix-shell -p age --run "age-keygen -o ~/.config/sops/age/keys.txt"
   ```

2. **Get your age public key**:
   ```bash
   age-keygen -y ~/.config/sops/age/keys.txt
   ```

3. **Create `.sops.yaml` configuration**:
   ```yaml
   keys:
     - &admin_yourname age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   creation_rules:
     - path_regex: secrets\.yaml$
       key_groups:
         - age:
             - *admin_yourname
   ```

4. **Create and edit secrets**:
   ```bash
   nix-shell -p sops --run "sops secrets.yaml"
   ```

5. **Add required secrets** (see `secrets.yaml.example` for template):
   - `step-ca-password`
   - `restic-password`
   - `aws-keys` (Backblaze B2 credentials)
   - Database passwords
   - Mail account passwords
   - API keys

### Step 5: Customize Your Configuration

**Duration: 1-2 hours**

1. **Review and modify user settings**:
   ```bash
   nano modules/users/johnw.nix
   # Change username, email, SSH keys, etc.
   ```

2. **Adjust service configurations**:
   - Disable services you don't need
   - Modify domain names and URLs
   - Update email addresses and notification targets

3. **Configure ZFS pools** (if needed):
   ```bash
   nano modules/storage/zfs.nix
   # Adjust pool names and dataset structure
   ```

### Step 6: Initial System Build

**Duration: 30-60 minutes (first build downloads lots of packages)**

1. **Validate the configuration**:
   ```bash
   sudo nix flake check
   ```

2. **Build without switching** (test for errors):
   ```bash
   sudo nixos-rebuild build --flake .#vulcan
   ```

3. **Review the build output**:
   - Check for any warnings or errors
   - Verify no unexpected packages are being built

4. **Switch to the new configuration**:
   ```bash
   sudo nixos-rebuild switch --flake .#vulcan
   ```

### Step 7: Post-Installation Setup

**Duration: 30-60 minutes**

1. **Set up ZFS pools** (if not using existing):
   ```bash
   # Create pool (example)
   sudo zpool create -o ashift=12 tank /dev/disk/by-id/xxx

   # Create datasets
   sudo zfs create tank/Documents
   sudo zfs create tank/Projects
   ```

2. **Initialize step-ca**:
   ```bash
   sudo systemctl start step-ca
   sudo systemctl status step-ca
   ```

3. **Set up PostgreSQL databases**:
   ```bash
   sudo systemctl start postgresql
   # Databases will be auto-created by modules
   ```

4. **Index Dovecot mailboxes** (after mail sync):
   ```bash
   # After first mbsync run
   sudo -u dovecot doveadm index -u youruser '*'
   ```

5. **Verify services are running**:
   ```bash
   sudo systemctl status nginx
   sudo systemctl status home-assistant
   sudo systemctl status prometheus
   ```

### Step 8: Configure Backups

**Duration: 30 minutes**

1. **Initialize Restic repositories**:
   ```bash
   # Initialize each backup fileset
   sudo systemctl start restic-backups-home.service
   sudo systemctl start restic-backups-documents.service
   # ... repeat for other filesets
   ```

2. **Verify backup configuration**:
   ```bash
   restic-snapshots
   ```

3. **Test a backup**:
   ```bash
   sudo systemctl start restic-backups-home.service
   journalctl -u restic-backups-home.service -f
   ```

### Step 9: Set Up Monitoring

**Duration: 15-30 minutes**

1. **Access Grafana**:
   ```
   https://grafana.vulcan.lan
   # Default login: admin/admin (change immediately)
   ```

2. **Import dashboards**:
   - Node Exporter Full
   - PostgreSQL Database
   - ZFS Dashboard

3. **Configure Alertmanager**:
   ```bash
   nano modules/monitoring/alerts/system.yaml
   # Adjust alert thresholds for your hardware
   ```

4. **Test alerting**:
   ```bash
   # Trigger a test alert
   sudo systemctl stop nginx
   # Check Alertmanager UI
   # Restart nginx
   sudo systemctl start nginx
   ```

### Step 10: Configure Home Assistant (Optional)

**Duration: 1-2 hours**

1. **Access Home Assistant**:
   ```
   https://hass.vulcan.lan
   ```

2. **Complete initial setup**:
   - Create admin account
   - Set location
   - Configure time zone

3. **Add integrations**:
   - Follow the guides in `docs/md/HOME_ASSISTANT_*.md`
   - Configure devices and automations

## 🎯 Verification Steps

After installation, verify everything is working:

### System Health

```bash
# Check system status
systemctl --failed

# Verify ZFS pools
zpool status

# Check disk usage
df -h

# Verify ZFS ARC
cat /proc/spl/kstat/zfs/arcstats | grep "^size"
```

### Service Health

```bash
# Check critical services
sudo systemctl status nginx
sudo systemctl status postgresql
sudo systemctl status dovecot
sudo systemctl status postfix
sudo systemctl status prometheus
sudo systemctl status grafana
```

### Network Connectivity

```bash
# Test DNS resolution
dig vulcan.lan

# Test internal services
curl -k https://grafana.vulcan.lan
curl -k https://prometheus.vulcan.lan

# Check firewall rules
sudo nft list ruleset
```

### Monitoring & Metrics

```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq

# Verify exporters
curl http://localhost:9100/metrics  # Node exporter
curl http://localhost:9187/metrics  # PostgreSQL exporter
```

### Backups

```bash
# Check ZFS snapshots
zfs list -t snapshot

# Verify Restic backups
restic-snapshots

# Check backup timers
systemctl list-timers | grep restic
```

## 🚨 Common Issues

### Build Failures

**Issue**: Evaluation error or build fails
```bash
# Show detailed error trace
sudo nixos-rebuild build --flake .#vulcan --show-trace

# Check flake lock
nix flake check

# Update flake inputs if needed
nix flake update
```

### Service Won't Start

**Issue**: Service fails to start
```bash
# Check service logs
sudo journalctl -u service-name -n 100 --no-pager

# Check service dependencies
systemctl list-dependencies service-name

# Verify configuration
systemctl cat service-name
```

### Secrets Not Decrypting

**Issue**: Services can't read secrets
```bash
# Verify age key is in place
ls -la ~/.config/sops/age/keys.txt

# Check secret permissions
ls -la /run/secrets/

# Re-decrypt secrets
sudo systemctl restart sops-nix
```

## 📚 Next Steps

1. **Read the documentation**:
   - Review all docs in `docs/md/`
   - Study the D2 architecture diagrams

2. **Customize services**:
   - Enable/disable services as needed
   - Adjust resource limits
   - Configure notifications

3. **Set up external access**:
   - Configure Cloudflare Tunnels
   - Set up VPN access
   - Configure DNS records

4. **Test disaster recovery**:
   - Practice ZFS rollbacks
   - Test Restic restore
   - Document your recovery procedures

5. **Join the community**:
   - Open issues for bugs or questions
   - Contribute improvements
   - Share your modifications

## 🆘 Getting Help

- **Documentation**: Check `docs/md/` for detailed guides
- **Troubleshooting**: See `docs/md/TROUBLESHOOTING.md`
- **FAQ**: See `docs/md/FAQ.md`
- **Issues**: Open an issue on GitHub
- **NixOS Community**:
  - [NixOS Discourse](https://discourse.nixos.org/)
  - [NixOS Wiki](https://nixos.wiki/)
  - [r/NixOS](https://reddit.com/r/NixOS)

## ⚡ Quick Commands Reference

```bash
# Rebuild system
sudo nixos-rebuild switch --flake .#vulcan

# Update flake inputs
nix flake update

# Format Nix code
nix fmt

# Check configuration
nix flake check

# View system logs
journalctl -f

# List failed services
systemctl --failed

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Clean old generations
sudo nix-collect-garbage -d

# View ZFS snapshots
zfs list -t snapshot

# Check backup status
restic-snapshots

# Monitor system resources
htop
```

## 🎓 Learning Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [SOPS-nix](https://github.com/Mic92/sops-nix)
- [Asahi Linux](https://asahilinux.org/)
- [ZFS on Linux](https://openzfs.github.io/openzfs-docs/)

---

**Congratulations!** You now have a production-grade NixOS infrastructure platform running on Apple Silicon. 🎉
