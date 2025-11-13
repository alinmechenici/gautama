# Disaster Recovery Runbook

**Purpose**: Complete system recovery procedures for catastrophic failures.

**Last Updated**: 2024-11-13
**Owner**: System Administrator
**Classification**: Critical

## 📋 Table of Contents

- [Overview](#overview)
- [Disaster Scenarios](#disaster-scenarios)
- [Prerequisites](#prerequisites)
- [Recovery Procedures](#recovery-procedures)
- [Verification](#verification)
- [Post-Recovery](#post-recovery)

## 🚨 Overview

This runbook covers complete system recovery procedures for Gautama in case of:
- Total hardware failure
- Complete data loss
- System corruption
- Natural disaster

**Recovery Time Objective (RTO)**: 1-2 days
**Recovery Point Objective (RPO)**: 24 hours (last backup)

## 📊 Disaster Scenarios

| Scenario | Impact | Recovery Method | RTO |
|----------|--------|-----------------|-----|
| **Hardware Failure** | System down | Restore to new hardware | 1-2 days |
| **Disk Failure** | Data loss | Restore from backups | 8-24 hours |
| **ZFS Corruption** | Pool degraded/lost | Restore from Restic | 4-8 hours |
| **Ransomware** | Files encrypted | Restore from clean backup | 4-8 hours |
| **Natural Disaster** | Total loss | Full rebuild + restore | 1-2 days |
| **Configuration Corruption** | System unstable | Rollback NixOS generation | 5-30 min |

## ✅ Prerequisites

### Before Disaster Strikes

**Essential Backups** (verify these exist):
- [ ] Restic backups to Backblaze B2 (daily)
- [ ] ZFS snapshots (hourly/daily/weekly)
- [ ] PostgreSQL dumps (daily)
- [ ] Configuration in git
- [ ] SOPS age keys (stored securely offline)
- [ ] step-ca root CA certificates (backed up securely)

**Documentation** (keep offline copies):
- [ ] This runbook
- [ ] Backup credentials
- [ ] B2 bucket names and credentials
- [ ] Age encryption keys location
- [ ] Network configuration notes

**Hardware** (for full rebuild):
- [ ] Replacement Apple Silicon Mac
- [ ] Asahi Linux installer USB
- [ ] Network access

## 🔄 Recovery Procedures

### Scenario 1: Total System Loss (Complete Rebuild)

**Impact**: Everything is gone, need to rebuild from scratch

#### Step 1: Prepare New Hardware

```bash
# 1. Boot into macOS on new Mac
# 2. Download Asahi Linux installer
curl https://alx.sh | sh

# 3. Follow installer prompts:
# - Choose "NixOS" as distribution
# - Allocate 500GB+ for Linux partition
# - Create initial user account
# - Wait for installation (30-60 minutes)

# 4. Reboot into NixOS
# Select NixOS from boot menu
```

#### Step 2: Initial System Setup

```bash
# SSH into new system (or work locally)

# Install git
nix-shell -p git

# Create nixos directory
sudo mkdir -p /etc/nixos
cd /etc/nixos

# Clone configuration from backup or git
# Option A: From GitHub/Gitea
git clone https://github.com/yourusername/gautama.git .

# Option B: Restore from Restic backup first (see below)
```

#### Step 3: Restore SOPS Age Keys

```bash
# Copy your age key from secure offline storage
mkdir -p ~/.config/sops/age
# Manually copy your private key to:
# ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# Verify key works
age-keygen -y ~/.config/sops/age/keys.txt
# Should show your public key
```

#### Step 4: Configure Hardware

```bash
# Generate hardware configuration
sudo nixos-generate-config --show-hardware-config > /etc/nixos/hosts/vulcan/hardware-configuration.nix

# Review and adjust if needed
nano /etc/nixos/hosts/vulcan/hardware-configuration.nix

# Update hostname if different
nano /etc/nixos/hosts/vulcan/default.nix
```

#### Step 5: Initial Build (Minimal)

```bash
# Temporarily disable services that need data
# Comment out in hosts/vulcan/default.nix:
# - Services requiring large datasets
# - Services needing restored databases
# Keep only essential services for first boot

# Build and switch
sudo nixos-rebuild switch --flake .#vulcan

# This gives you a working base system
```

#### Step 6: Restore Data from Restic

```bash
# Install restic
nix-shell -p restic

# Set up Restic repository credentials
export RESTIC_REPOSITORY="b2:bucket-name"
export RESTIC_PASSWORD="your-restic-password"
export AWS_ACCESS_KEY_ID="your-b2-key-id"
export AWS_SECRET_ACCESS_KEY="your-b2-application-key"

# List available snapshots
restic snapshots

# Restore /etc/nixos if needed
restic restore latest --target /tmp/restore --include /etc/nixos
sudo cp -a /tmp/restore/etc/nixos/* /etc/nixos/

# Restore user home directories
restic restore latest --target / --include /home/johnw
restic restore latest --target / --include /home/assembly

# Restore important data directories
restic restore latest --target / --include /tank/Documents
restic restore latest --target / --include /tank/Projects
restic restore latest --target / --include /var/lib/hass
restic restore latest --target / --include /var/lib/jellyfin
```

#### Step 7: Restore PostgreSQL Databases

```bash
# Restore from Restic backup
restic restore latest --target /tmp/restore --include /tank/Backups/PostgreSQL

# Start PostgreSQL
sudo systemctl start postgresql

# Restore databases
for db in /tmp/restore/tank/Backups/PostgreSQL/*.sql; do
    dbname=$(basename "$db" .sql)
    sudo -u postgres createdb "$dbname"
    sudo -u postgres psql "$dbname" < "$db"
done

# Verify databases
sudo -u postgres psql -c '\l'
```

#### Step 8: Restore ZFS Pools (if applicable)

If you have ZFS pool backups or can recover disks:

```bash
# Import existing pools
sudo zpool import -f rpool
sudo zpool import -f tank
sudo zpool import -f gdrive

# Check pool status
sudo zpool status

# If pools are degraded, try to resilver
sudo zpool scrub poolname
```

If pools are lost, recreate:

```bash
# Create new pools (adjust device paths)
sudo zpool create -o ashift=12 tank /dev/disk-id

# Restore data from Restic (as above)
```

#### Step 9: Restore step-ca Certificates

```bash
# Restore step-ca directory from backup
restic restore latest --target / --include /var/lib/step-ca

# Or manually restore root CA certificates
# (Keep these in secure offline storage!)
sudo mkdir -p /var/lib/step-ca/certs
sudo cp /path/to/backup/root_ca.crt /var/lib/step-ca/certs/
sudo cp /path/to/backup/intermediate_ca.crt /var/lib/step-ca/certs/

# Restart step-ca
sudo systemctl restart step-ca
```

#### Step 10: Full System Rebuild

```bash
# Re-enable all services in configuration
nano /etc/nixos/hosts/vulcan/default.nix

# Rebuild with full configuration
sudo nixos-rebuild switch --flake .#vulcan

# This may take 30-60 minutes on first build
```

#### Step 11: Verify Services

```bash
# Run health check
/etc/nixos/scripts/health-check.sh

# Check critical services
sudo systemctl status nginx
sudo systemctl status postgresql
sudo systemctl status home-assistant
sudo systemctl status prometheus

# Check for failed units
systemctl --failed
```

### Scenario 2: Data Loss (ZFS Pool Failure)

**Impact**: Data lost but system boots

```bash
# 1. Check pool status
zpool status

# 2. If pool is DEGRADED but recoverable
zpool scrub poolname

# 3. If pool is completely lost
# Recreate pool
sudo zpool create -o ashift=12 tank /dev/new-disk

# Restore from Restic
export RESTIC_REPOSITORY="b2:bucket-name"
export RESTIC_PASSWORD="your-password"
export AWS_ACCESS_KEY_ID="your-b2-key"
export AWS_SECRET_ACCESS_KEY="your-b2-secret"

restic restore latest --target /

# 4. Restore PostgreSQL databases
# (See Step 7 above)
```

### Scenario 3: Configuration Corruption

**Impact**: System boots but broken configuration

```bash
# 1. Check current generation
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# 2. Boot into previous generation
# At boot: Select "NixOS - Configuration X" from GRUB

# Or rollback:
sudo nixos-rebuild switch --rollback

# 3. If still broken, restore from git
cd /etc/nixos
git fetch origin
git reset --hard origin/main

# 4. Rebuild
sudo nixos-rebuild switch --flake .#vulcan
```

### Scenario 4: Ransomware Attack

**Impact**: Files encrypted by malware

```bash
# DO NOT pay ransom!

# 1. Immediately disconnect from network
sudo systemctl stop NetworkManager

# 2. Identify last clean backup
restic snapshots

# Find snapshot before encryption
# Note the snapshot ID

# 3. Boot from live USB and restore
# Boot Asahi Linux installer

# 4. Mount ZFS pools
zpool import -f rpool
zpool import -f tank

# 5. Restore from clean backup
restic restore SNAPSHOT_ID --target /mnt

# 6. Scan for malware (if needed)
nix-shell -p clamav
clamscan -r /

# 7. Change all passwords
# Update all secrets in secrets.yaml

# 8. Rebuild system
nixos-rebuild switch --flake .#vulcan
```

## ✓ Verification Checklist

After recovery, verify:

### System Health
- [ ] System boots successfully
- [ ] No failed systemd units
- [ ] ZFS pools healthy
- [ ] Network connectivity works
- [ ] DNS resolution works
- [ ] Tailscale connected

### Services
- [ ] Nginx running and accessible
- [ ] PostgreSQL running with databases
- [ ] Home Assistant accessible
- [ ] Prometheus collecting metrics
- [ ] Grafana accessible
- [ ] step-ca issuing certificates

### Data Integrity
- [ ] User home directories intact
- [ ] Important documents accessible
- [ ] Project files restored
- [ ] Database data verified
- [ ] Email accessible
- [ ] Media library accessible

### Backups
- [ ] Restic backups resume
- [ ] ZFS snapshots creating
- [ ] PostgreSQL backups running
- [ ] All backup timers active

### Security
- [ ] Secrets decrypting correctly
- [ ] Certificates valid
- [ ] Firewall rules active
- [ ] SSH access works
- [ ] All passwords changed (if compromised)

## 📋 Post-Recovery Actions

### Immediate (Day 1)

1. **Document the incident**:
   ```bash
   # Create incident report
   cat > /var/log/incident-$(date +%Y%m%d).txt <<EOF
   Date: $(date)
   Incident: [Describe what happened]
   Recovery Actions: [What you did]
   Lessons Learned: [What to improve]
   EOF
   ```

2. **Verify all data**:
   - Check file integrity
   - Verify database contents
   - Test critical workflows

3. **Monitor closely**:
   - Watch logs for errors
   - Check metrics for anomalies
   - Verify backups complete

### Short-term (Week 1)

4. **Update documentation**:
   - Update this runbook with lessons learned
   - Document any changes made
   - Note any issues encountered

5. **Test backups**:
   - Verify new backups are working
   - Test restore of a few files
   - Confirm retention policies

6. **Security review** (if attack):
   - Review firewall logs
   - Check for unauthorized access
   - Update security measures

### Long-term (Month 1)

7. **Improve resilience**:
   - Add redundancy where needed
   - Improve backup frequency if needed
   - Update disaster recovery plan

8. **Test DR procedures**:
   - Schedule regular DR tests
   - Update runbooks
   - Train on procedures

## 🔐 Important Notes

### Keep Secure Offline

**Critical items to store securely offline:**
- Age encryption private keys
- step-ca root CA certificates
- B2 credentials and bucket names
- This runbook (printed or USB)
- Hardware documentation

### Regular Testing

**Test disaster recovery regularly:**
- Quarterly: Test Restic restore
- Annually: Full system rebuild test
- After changes: Verify backup coverage

### Contact Information

**Keep accessible:**
- Backblaze B2 support
- Hardware vendor support
- Network provider
- Insurance information (if applicable)

## 📊 Recovery Time Estimates

| Task | Estimated Time |
|------|---------------|
| Asahi Linux installation | 30-60 min |
| Initial NixOS setup | 15-30 min |
| Restore age keys | 5 min |
| First system build | 30-60 min |
| Restore data from Restic | 2-8 hours (depends on data size) |
| Restore databases | 30-60 min |
| Full system rebuild | 30-60 min |
| Verification | 1-2 hours |
| **Total** | **6-14 hours** |

Add time for:
- Hardware procurement (if needed): 1-7 days
- Travel to hardware (if remote)
- Troubleshooting issues: Variable

## 🆘 Emergency Contacts

**Document your emergency contacts:**
- [ ] Primary admin:
- [ ] Secondary admin:
- [ ] Hardware vendor:
- [ ] ISP support:
- [ ] Backblaze support: https://www.backblaze.com/help.html

---

**Remember**: Calm, methodical recovery is better than rushing.
**Take your time**, verify each step, and document as you go.

**This runbook is only useful if:**
1. ✅ You test it regularly
2. ✅ You keep it updated
3. ✅ You store copies offline
4. ✅ You maintain good backups

**Next Review Date**: [Set quarterly review]
