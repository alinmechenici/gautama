# Complete Installation Guide

**Branch**: `claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX`
**Status**: Ready for deployment
**Total Commits**: 61
**New Features**: Internet Publishing, NIS2 Apps, PDF Documentation, Desktop Shortcuts

---

## 📋 Overview

This guide will help you:
1. Pull the latest changes to your local Gautama machine
2. Review and enable new modules
3. Configure secrets
4. Install desktop shortcuts
5. Build documentation PDFs
6. Test everything

---

## 🚀 Part 1: Pull Changes to Local Machine

### Step 1: SSH to Vulcan

```bash
ssh vulcan
# Or: ssh johnw@vulcan
```

### Step 2: Navigate to NixOS Configuration

```bash
cd /etc/nixos
```

### Step 3: Fetch Latest Changes

```bash
# Fetch all branches
git fetch origin

# Check what branches are available
git branch -a

# You should see:
# remotes/origin/claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX
```

### Step 4: Checkout Research Branch

```bash
# Create and checkout the research branch
git checkout -b claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX origin/claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# Or if branch already exists locally:
git checkout claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX
git pull origin claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX
```

### Step 5: Verify You Have Everything

```bash
# Check recent commits
git log --oneline -10

# You should see:
# 07ffd37 feat: Add desktop shortcuts for all Gautama scripts
# c904e22 docs: Add comprehensive implementation checklist
# 4736468 feat: Add professional documentation build system with LaTeX and Typst
# 6ab9dfb feat: Add complete NIS2 Rails applications infrastructure
# 7848a9d feat: Implement internet publishing with Cloudflare Tunnel and ZOHO API
# ...

# Check new files exist
ls -la desktop-shortcuts/
ls -la docs/latex/
ls -la docs/typst/
ls -la nis2-apps/
ls -la modules/services/documentation-builder.nix
ls -la modules/services/cloudflared.nix
ls -la modules/containers/*-quadlet.nix
```

---

## 🎯 Part 2: Choose What to Enable

You don't have to enable everything at once. Pick what you need:

### Option A: Just Documentation (Safest, Most Useful)

**What**: Build PDF books from markdown documentation

**Enable**: Documentation builder only

**Risk**: None - just builds PDFs

**Benefit**: Beautiful documentation in LaTeX and Typst formats

### Option B: Internet Publishing (Advanced)

**What**: Jekyll, Quarto, ZOHO API via Cloudflare Tunnel

**Enable**: Cloudflare + containers + ZOHO

**Risk**: Medium - requires external setup (Cloudflare, ZOHO)

**Benefit**: Public websites and contact forms

### Option C: NIS2 Rails Apps (Development)

**What**: 4 Ruby on Rails applications

**Enable**: NIS2 modules (later, after local dev)

**Risk**: Low - just containerized apps

**Benefit**: Development platform for NIS2 services

### Option D: Everything

**What**: All features at once

**Risk**: High - lots to configure

**Benefit**: Complete infrastructure

---

## 📝 Part 3: Enable Modules

### 3.1 Edit Host Configuration

```bash
cd /etc/nixos
sudo nano hosts/vulcan/default.nix
```

### 3.2 Add Modules to Imports

**For Documentation Only** (recommended first):

```nix
imports = [
  # ... existing imports ...

  # Documentation Builder (safe, useful)
  ../../modules/services/documentation-builder.nix
];
```

**For Internet Publishing** (requires secrets):

```nix
imports = [
  # ... existing imports ...

  # Documentation Builder
  ../../modules/services/documentation-builder.nix

  # Internet Publishing (Cloudflare Tunnel)
  ../../modules/services/cloudflared.nix
  ../../modules/containers/jekyll-public-quadlet.nix
  ../../modules/containers/quarto-public-quadlet.nix
  ../../modules/containers/zoho-api-quadlet.nix
];
```

**For Everything**:

```nix
imports = [
  # ... existing imports ...

  # Documentation Builder
  ../../modules/services/documentation-builder.nix

  # Internet Publishing
  ../../modules/services/cloudflared.nix
  ../../modules/containers/jekyll-public-quadlet.nix
  ../../modules/containers/quarto-public-quadlet.nix
  ../../modules/containers/zoho-api-quadlet.nix

  # NIS2 Applications (when ready)
  # ../../modules/containers/nis2-services-quadlet.nix
  # ../../modules/containers/nis2-events-quadlet.nix
  # ../../modules/containers/nis2-news-quadlet.nix
  # ../../modules/containers/nis2-academy-quadlet.nix
];
```

Save and exit: `Ctrl+X`, `Y`, `Enter`

---

## 🔐 Part 4: Configure Secrets (If Needed)

### 4.1 For Documentation Only

**No secrets needed!** Skip to Part 5.

### 4.2 For Internet Publishing

Edit secrets:

```bash
cd /etc/nixos
sops secrets.yaml
```

Add these secrets (see `secrets.yaml.example` for templates):

```yaml
# Cloudflare Tunnel
cloudflare-tunnel-credentials: |
  {
    "AccountTag": "your-account-id",
    "TunnelSecret": "your-secret",
    "TunnelID": "your-tunnel-id"
  }

cloudflare-tunnel-config: |
  tunnel: your-tunnel-id
  credentials-file: /etc/cloudflared/credentials.json
  ingress:
    - hostname: blog.example.com
      service: http://localhost:4100
    - hostname: docs.example.com
      service: http://localhost:4101
    - hostname: api.example.com
      service: http://localhost:4102
    - service: http_status:404

# ZOHO OAuth
zoho-client-id: "your-client-id"
zoho-client-secret: "your-client-secret"
zoho-refresh-token: "your-refresh-token"
zoho-redirect-uri: "http://localhost:8080/oauth/callback"
```

**Setup guides**:
- Cloudflare: See `docs/md/CLOUDFLARE_TUNNEL_GUIDE.md`
- ZOHO: See `docs/md/ZOHO_API_GUIDE.md`

Save and exit: `Ctrl+X`, `Y`

---

## 🏗️ Part 5: Build Container Images (If Needed)

### 5.1 For Documentation Only

**No images needed!** Skip to Part 6.

### 5.2 For Internet Publishing

Build the container images:

```bash
cd /etc/nixos

# Jekyll
cd containers/jekyll
podman build -t localhost/jekyll:latest .

# Quarto
cd ../quarto
podman build -t localhost/quarto:latest .

# ZOHO API
cd ../zoho-api
podman build -t localhost/zoho-api:latest .

# Return to nixos directory
cd /etc/nixos
```

---

## 🔄 Part 6: Rebuild NixOS

### 6.1 Test the Build First

```bash
cd /etc/nixos
sudo nixos-rebuild build --flake '.#vulcan'
```

If this succeeds, great! If errors, check:
- Module paths are correct
- Secrets are configured (if needed)
- Container images are built (if needed)

### 6.2 Apply the Changes

```bash
sudo nixos-rebuild switch --flake '.#vulcan'
```

This will:
- Enable new modules
- Start new services
- Build documentation PDFs (if enabled)
- Copy PDFs to `/home/gautama/docs/`

**Watch for**:
- Any errors during activation
- Services starting successfully
- Documentation build messages

---

## 🎨 Part 7: Install Desktop Shortcuts

### 7.1 Run the Installer

```bash
cd /etc/nixos/desktop-shortcuts
./install-shortcuts.sh
```

### 7.2 Verify Installation

Check that shortcuts are created:

```bash
ls -la ~/Desktop/Gautama\ Shortcuts/
```

You should see 12 `.desktop` files.

---

## ✅ Part 8: Verify Everything Works

### 8.1 Check Documentation

```bash
# List PDFs
ls -lh /home/gautama/docs/*.pdf

# Open LaTeX PDF
xdg-open /home/gautama/docs/gautama-docs-latex.pdf

# Open Typst PDF
xdg-open /home/gautama/docs/gautama-docs-typst.pdf
```

Or **double-click** desktop shortcuts:
- 📖 "Open LaTeX Documentation PDF"
- 📖 "Open Typst Documentation PDF"

### 8.2 Check Services (If Enabled)

```bash
# Check systemd services
systemctl status cloudflared
systemctl status build-documentation.timer

# Check containers
podman ps

# Check logs
journalctl -u cloudflared -n 50
journalctl -u build-documentation.service -n 50
```

### 8.3 Test Desktop Shortcuts

**Double-click** these to test:
- ✅ "Implementation Checklist"
- 📄 "Build Documentation PDFs"
- 📊 "Check System Status"

---

## 🎯 Part 9: Next Steps

### If You Enabled Documentation Only

✅ **You're done!** Enjoy your PDFs:
- `/home/gautama/docs/gautama-docs-latex.pdf`
- `/home/gautama/docs/gautama-docs-typst.pdf`

PDFs auto-rebuild:
- Weekly (systemd timer)
- On every `nixos-rebuild switch`
- Manually: Double-click "Build Documentation PDFs"

### If You Enabled Internet Publishing

1. **Setup Cloudflare Tunnel**:
   ```bash
   cloudflared tunnel login
   cloudflared tunnel create gautama-publishing
   # Copy credentials to SOPS
   ```

2. **Setup ZOHO OAuth**:
   - Create app at https://api-console.zoho.com/
   - Get Client ID, Secret, Refresh Token
   - Add to SOPS

3. **Rebuild**:
   ```bash
   sudo nixos-rebuild switch --flake '.#vulcan'
   ```

4. **Test**:
   ```bash
   curl https://blog.example.com
   curl https://api.example.com/health
   ```

### If You Want NIS2 Apps

1. **Create Supabase Projects**:
   - `nis2-dev`, `nis2-staging`, `nis2-prod`

2. **Initialize Apps**:
   ```bash
   cd /etc/nixos/nis2-apps
   ./scripts/init-apps.sh
   ```

3. **Configure .env Files**:
   - Add Supabase credentials

4. **Setup Databases**:
   ```bash
   ./scripts/setup-databases.sh
   ```

5. **Start Development**:
   ```bash
   cd services
   rails server -p 3001
   ```

---

## 🆘 Troubleshooting

### Issue: "No module named..."

**Cause**: Module path is wrong

**Fix**:
```bash
# Check module exists
ls -la /etc/nixos/modules/services/documentation-builder.nix

# Check path in imports (must be relative from hosts/vulcan/)
# Should be: ../../modules/services/documentation-builder.nix
```

### Issue: "Container image not found"

**Cause**: Image not built

**Fix**:
```bash
cd /etc/nixos/containers/jekyll
podman build -t localhost/jekyll:latest .
```

### Issue: "Secret not found"

**Cause**: Secret not in SOPS

**Fix**:
```bash
cd /etc/nixos
sops secrets.yaml
# Add missing secret
```

### Issue: "PDF build fails"

**Cause**: Missing dependencies

**Fix**:
```bash
# Install temporarily
nix-shell -p pandoc texlive.combined.scheme-full typst

# Or enable documentation-builder module (has all deps)
```

### Issue: "Desktop shortcuts don't work"

**Cause**: Not executable

**Fix**:
```bash
cd ~/Desktop/Gautama\ Shortcuts/
chmod +x *.desktop
```

---

## 📊 Summary Checklist

Use this to track your progress:

```
[ ] Part 1: Pulled changes to local machine
[ ] Part 2: Chose what to enable
[ ] Part 3: Enabled modules in hosts/vulcan/default.nix
[ ] Part 4: Configured secrets (if needed)
[ ] Part 5: Built container images (if needed)
[ ] Part 6: Ran nixos-rebuild switch successfully
[ ] Part 7: Installed desktop shortcuts
[ ] Part 8: Verified everything works
[ ] Part 9: Completed next steps

Documentation:
[ ] Can open gautama-docs-latex.pdf
[ ] Can open gautama-docs-typst.pdf
[ ] Desktop shortcuts work

Internet Publishing (optional):
[ ] Cloudflare Tunnel connected
[ ] Jekyll/Quarto/ZOHO containers running
[ ] Can access via public URLs

NIS2 Apps (optional):
[ ] Apps initialized
[ ] Databases configured
[ ] Can run locally
```

---

## 🎉 Success!

When everything works, you'll have:

✅ **Documentation**: Beautiful PDF books from markdown
✅ **Desktop Shortcuts**: One-click access to common tasks
✅ **Internet Publishing** (if enabled): Public websites via Cloudflare
✅ **ZOHO Integration** (if enabled): Contact forms and CRM
✅ **NIS2 Apps** (if setup): Rails development platform

---

## 📚 Additional Resources

- **Implementation Checklist**: `/etc/nixos/docs/IMPLEMENTATION_CHECKLIST.md`
- **Desktop Shortcuts**: `/etc/nixos/desktop-shortcuts/README.md`
- **Documentation Build**: `/etc/nixos/docs/README.md`
- **NIS2 Apps**: `/etc/nixos/nis2-apps/README.md`
- **Cloudflare Guide**: `/etc/nixos/docs/md/CLOUDFLARE_TUNNEL_GUIDE.md`
- **ZOHO Guide**: `/etc/nixos/docs/md/ZOHO_API_GUIDE.md`

---

**Last Updated**: 2025-11-13
**Branch**: `claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX`
**Status**: Ready for Production
