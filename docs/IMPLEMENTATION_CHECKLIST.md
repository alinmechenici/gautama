# Implementation Checklist - What's Missing

This document tracks what needs to be done to complete the implementation of all new features.

---

## 📊 Status Overview

| Feature | Status | Next Steps |
|---------|--------|------------|
| **Internet Publishing (Cloudflare Tunnel)** | ⚠️ Created, Not Enabled | Add modules to config, add secrets |
| **ZOHO API Integration** | ⚠️ Created, Not Enabled | Add module, configure OAuth |
| **NIS2 Rails Applications** | ⚠️ Planned, Not Built | Run init scripts, setup Supabase |
| **Documentation PDFs** | ⚠️ Created, Not Enabled | Add module, test build |
| **Container Images** | ⚠️ Defined, Not Built | Build images with Nix |
| **Secrets Configuration** | ⚠️ Templates Created | Add actual secrets to SOPS |

---

## 🔴 CRITICAL - Must Do Before Use

### 1. Enable New Modules in Host Configuration

**File**: `/etc/nixos/hosts/vulcan/default.nix`

**Add these imports**:

```nix
imports = [
  # ... existing imports ...

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

  # Documentation Builder
  ../../modules/services/documentation-builder.nix
];
```

**Status**: ❌ NOT DONE

---

### 2. Add Secrets to SOPS

**File**: `/etc/nixos/secrets.yaml`

**Missing Secrets**:

```yaml
# Cloudflare Tunnel
cloudflare-tunnel-credentials: |
  {
    "AccountTag": "YOUR_ACCOUNT_ID",
    "TunnelSecret": "YOUR_TUNNEL_SECRET",
    "TunnelID": "YOUR_TUNNEL_UUID"
  }

cloudflare-tunnel-config: |
  tunnel: YOUR_TUNNEL_UUID
  credentials-file: /etc/cloudflared/credentials.json

  ingress:
    - hostname: blog.example.com
      service: http://localhost:4100
    - hostname: docs.example.com
      service: http://localhost:4101
    - hostname: api.example.com
      service: http://localhost:4102
    - service: http_status:404

# ZOHO API
zoho-client-id: "YOUR_CLIENT_ID"
zoho-client-secret: "YOUR_CLIENT_SECRET"
zoho-refresh-token: "YOUR_REFRESH_TOKEN"
zoho-redirect-uri: "http://localhost:8080/oauth/callback"

# NIS2 Applications (when ready)
# nis2-services-supabase-url: "https://xxxxx.supabase.co"
# nis2-services-supabase-key: "eyJhbGc..."
# nis2-services-database-url: "postgresql://..."
# nis2-services-secret-key-base: "$(rails secret)"
# (repeat for events, news, academy)
```

**How to add**:
```bash
cd /etc/nixos
sops secrets.yaml
# Add the secrets above
```

**Status**: ❌ NOT DONE

---

### 3. Build Container Images

**Jekyll Public**:
```bash
cd /etc/nixos/containers/jekyll
podman build -t localhost/jekyll:latest .
```

**Quarto Public**:
```bash
cd /etc/nixos/containers/quarto
podman build -t localhost/quarto:latest .
```

**ZOHO API**:
```bash
cd /etc/nixos/containers/zoho-api
podman build -t localhost/zoho-api:latest .
```

**NIS2 Apps** (later):
```bash
# Build with Nix
nix-build -A system.build.nis2-services-image
podman load < result
```

**Status**: ❌ NOT DONE

---

### 4. Setup Cloudflare Tunnel

**Steps**:
```bash
# 1. Authenticate
cloudflared tunnel login

# 2. Create tunnel
cloudflared tunnel create gautama-publishing

# 3. Copy credentials to SOPS
cat ~/.cloudflared/<tunnel-id>.json
# Add to secrets.yaml

# 4. Configure DNS
cloudflared tunnel route dns gautama-publishing blog.example.com
cloudflared tunnel route dns gautama-publishing docs.example.com
cloudflared tunnel route dns gautama-publishing api.example.com
```

**Status**: ❌ NOT DONE

---

### 5. Setup ZOHO OAuth

**Steps**:
```bash
# 1. Create Self Client at https://api-console.zoho.com/
# 2. Note Client ID and Secret
# 3. Generate authorization code:
#    https://accounts.zoho.com/oauth/v2/auth?
#      scope=ZohoCRM.modules.contacts.CREATE
#      &client_id=YOUR_ID
#      &response_type=code
#      &access_type=offline
#      &redirect_uri=http://localhost:8080/oauth/callback
# 4. Exchange code for refresh token:
curl -X POST https://accounts.zoho.com/oauth/v2/token \
  -d "code=YOUR_CODE" \
  -d "client_id=YOUR_ID" \
  -d "client_secret=YOUR_SECRET" \
  -d "redirect_uri=http://localhost:8080/oauth/callback" \
  -d "grant_type=authorization_code"

# 5. Add refresh_token to SOPS secrets.yaml
```

**Status**: ❌ NOT DONE

---

### 6. Initialize NIS2 Rails Applications

**Steps**:
```bash
cd /home/user/gautama/nis2-apps

# 1. Run initialization script
./scripts/init-apps.sh

# 2. Configure Supabase credentials
# Edit .env files for each app:
cd services && nano .env
cd ../events && nano .env
cd ../news && nano .env
cd ../academy && nano .env

# 3. Setup databases
./scripts/setup-databases.sh

# 4. Test locally
cd services && rails server -p 3001
```

**Status**: ❌ NOT DONE

---

### 7. Test Documentation Build

**Steps**:
```bash
cd /etc/nixos/docs

# Test build manually
./scripts/build-pdfs.sh

# Check output
ls -lh pdf/*.pdf
ls -lh /home/gautama/docs/*.pdf
```

**Status**: ❌ NOT DONE

---

## 🟡 OPTIONAL - Nice to Have

### 8. Create Directories

```bash
# Create documentation directories
mkdir -p /home/gautama/docs

# Create NIS2 app directories
mkdir -p /var/lib/nis2-apps/{services,events,news,academy}
mkdir -p /home/gautama/dev

# Create Jekyll/Quarto public directories
mkdir -p /var/lib/jekyll-public/sites
mkdir -p /var/lib/quarto-public/projects
```

**Status**: ⚠️ Partial (some created)

---

### 9. Setup Supabase Projects

**Create 3 Supabase projects**:
1. `nis2-dev` (Development)
2. `nis2-staging` (Staging)
3. `nis2-prod` (Production)

**Create schemas in each**:
```sql
CREATE SCHEMA IF NOT EXISTS nis2_services;
CREATE SCHEMA IF NOT EXISTS nis2_events;
CREATE SCHEMA IF NOT EXISTS nis2_news;
CREATE SCHEMA IF NOT EXISTS nis2_academy;

GRANT ALL ON SCHEMA nis2_services TO postgres;
GRANT ALL ON SCHEMA nis2_events TO postgres;
GRANT ALL ON SCHEMA nis2_news TO postgres;
GRANT ALL ON SCHEMA nis2_academy TO postgres;
```

**Status**: ❌ NOT DONE

---

### 10. Setup Development Environment

```bash
# Clone NIS2 apps to dev directory
cd /home/gautama/dev
git clone /path/to/nis2-apps services
git clone /path/to/nis2-apps events
git clone /path/to/nis2-apps news
git clone /path/to/nis2-apps academy

# Or create symlinks
ln -s /path/to/nis2-apps/services /home/gautama/dev/nis2-services
ln -s /path/to/nis2-apps/events /home/gautama/dev/nis2-events
ln -s /path/to/nis2-apps/news /home/gautama/dev/nis2-news
ln -s /home/gautama/dev/nis2-apps/academy /home/gautama/dev/nis2-academy
```

**Status**: ❌ NOT DONE

---

### 11. Test Internet Publishing

**After enabling modules and adding secrets**:

```bash
# Check services
sudo systemctl status cloudflared
sudo systemctl status quadlet-jekyll-public
sudo systemctl status quadlet-quarto-public
sudo systemctl status quadlet-zoho-api

# Test locally
curl http://localhost:4100  # Jekyll
curl http://localhost:4101  # Quarto
curl http://localhost:4102/health  # ZOHO API

# Test via Cloudflare Tunnel
curl https://blog.example.com
curl https://docs.example.com
curl https://api.example.com/health
```

**Status**: ❌ NOT DONE

---

### 12. Deploy to VPS (Production)

**For production deployment**:

```bash
# Setup VPS
ssh root@your-vps-ip

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Clone repository
cd /home/deploy
git clone https://github.com/yourorg/nis2-apps.git

# Configure environment
cd nis2-apps
nano services/.env  # Add production Supabase credentials

# Deploy with Docker Compose
docker-compose -f docker-compose.prod.yml up -d --build
```

**Status**: ❌ NOT DONE

---

## ✅ COMPLETED

### Documentation Created

- ✅ NIS2_APPS_ARCHITECTURE.md (8,000+ words)
- ✅ QUICKSTART.md
- ✅ SETUP.md (5,000+ words)
- ✅ DEVELOPMENT_WORKFLOW.md (6,500+ words)
- ✅ DEPLOYMENT.md (6,000+ words)
- ✅ CLOUDFLARE_TUNNEL_GUIDE.md (8,000+ words)
- ✅ ZOHO_API_GUIDE.md (7,500+ words)
- ✅ INTERNET_PUBLISHING_SETUP.md
- ✅ docs/README.md (PDF build system)

### Modules Created

- ✅ modules/services/cloudflared.nix
- ✅ modules/containers/jekyll-public-quadlet.nix
- ✅ modules/containers/quarto-public-quadlet.nix
- ✅ modules/containers/zoho-api-quadlet.nix
- ✅ modules/containers/nis2-services-quadlet.nix
- ✅ modules/services/documentation-builder.nix

### Container Definitions

- ✅ containers/jekyll/Containerfile
- ✅ containers/quarto/Containerfile
- ✅ containers/zoho-api/Containerfile + app.py

### Templates

- ✅ docs/latex/gautama-docs.tex
- ✅ docs/typst/gautama-docs.typ
- ✅ secrets.yaml.example

### Scripts

- ✅ nis2-apps/scripts/init-apps.sh
- ✅ nis2-apps/scripts/setup-databases.sh
- ✅ docs/scripts/build-pdfs.sh

---

## 📋 Quick Action Checklist

Copy this checklist and work through it:

```
Internet Publishing Setup:
[ ] 1. Add cloudflared module to hosts/vulcan/default.nix
[ ] 2. Add Jekyll/Quarto/ZOHO modules to hosts/vulcan/default.nix
[ ] 3. Build container images (Jekyll, Quarto, ZOHO)
[ ] 4. Setup Cloudflare Tunnel (login, create, configure)
[ ] 5. Setup ZOHO OAuth (create app, get refresh token)
[ ] 6. Add secrets to SOPS secrets.yaml
[ ] 7. Run: sudo nixos-rebuild switch --flake '.#vulcan'
[ ] 8. Test services via Tailscale and internet

Documentation PDFs:
[ ] 1. Add documentation-builder module to hosts/vulcan/default.nix
[ ] 2. Run: sudo nixos-rebuild switch --flake '.#vulcan'
[ ] 3. Check PDFs at /home/gautama/docs/*.pdf
[ ] 4. Test manual build: build-gautama-docs

NIS2 Rails Apps:
[ ] 1. Create Supabase projects (dev, staging, prod)
[ ] 2. Create schemas in Supabase
[ ] 3. Run: cd nis2-apps && ./scripts/init-apps.sh
[ ] 4. Configure .env files with Supabase credentials
[ ] 5. Run: ./scripts/setup-databases.sh
[ ] 6. Test locally: cd services && rails server -p 3001
[ ] 7. Setup development environment at /home/gautama/dev/
[ ] 8. When ready, add NIS2 modules to host config
[ ] 9. Deploy to staging on Gautama
[ ] 10. Deploy to production on VPS

Merge to Main:
[ ] 1. Review all changes on claude/research-* branch
[ ] 2. Test critical features
[ ] 3. Merge to main branch
[ ] 4. Tag release: git tag -a v1.0.0 -m "Complete infrastructure"
```

---

## 🚨 Common Issues to Watch For

### Issue 1: Cloudflare Tunnel Not Connecting

**Symptoms**: `cloudflared` service fails

**Fix**:
```bash
# Check credentials
sudo cat /run/secrets/cloudflare-tunnel-credentials

# Validate config
cloudflared tunnel --config /etc/cloudflared/config.yml ingress validate

# View logs
sudo journalctl -u cloudflared -f
```

### Issue 2: Container Won't Start

**Symptoms**: Quadlet service fails

**Fix**:
```bash
# Check image exists
podman images | grep jekyll

# Rebuild image
cd /etc/nixos/containers/jekyll
podman build -t localhost/jekyll:latest .

# Restart service
sudo systemctl restart quadlet-jekyll-public
```

### Issue 3: ZOHO API Authentication Fails

**Symptoms**: 401 errors from ZOHO

**Fix**:
```bash
# Verify secrets
sudo cat /run/secrets/zoho-api-env

# Test token refresh manually
curl -X POST https://accounts.zoho.com/oauth/v2/token \
  -d "refresh_token=YOUR_TOKEN" \
  -d "client_id=YOUR_ID" \
  -d "client_secret=YOUR_SECRET" \
  -d "grant_type=refresh_token"
```

### Issue 4: PDF Build Fails

**Symptoms**: Documentation build errors

**Fix**:
```bash
# Check dependencies
which pandoc pdflatex typst

# Run manually with verbose output
cd /etc/nixos/docs
./scripts/build-pdfs.sh

# Check logs
journalctl -u build-documentation.service
```

---

## 📊 Priority Order

**Do these first**:
1. ✅ Enable documentation-builder (easiest, most useful)
2. ⚠️ Setup Cloudflare Tunnel (for internet publishing)
3. ⚠️ Setup ZOHO API (for contact forms)
4. ⚠️ Initialize NIS2 apps (for development)

**Do these later**:
5. Deploy NIS2 apps to staging
6. Deploy NIS2 apps to production
7. Merge everything to main

---

## 🎯 Next Immediate Steps

**Right now, you should**:

1. **Enable documentation builder** (safest, most useful):
   ```bash
   cd /etc/nixos
   nano hosts/vulcan/default.nix
   # Add: ../../modules/services/documentation-builder.nix
   sudo nixos-rebuild switch --flake '.#vulcan'
   # Check: ls /home/gautama/docs/*.pdf
   ```

2. **Review secrets.yaml.example**:
   ```bash
   cat /etc/nixos/secrets.yaml.example
   # Note what secrets you need
   ```

3. **Decide on Cloudflare/ZOHO**:
   - Do you want internet publishing?
   - Do you need ZOHO integration?
   - If yes, follow setup guides

4. **Start NIS2 apps**:
   - Create Supabase account
   - Run initialization script
   - Begin development

---

**Last Updated**: 2025-11-13
**Status**: Implementation phase - modules created, not yet enabled
