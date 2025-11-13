# Cloudflare Tunnel Setup Guide

**Purpose**: Complete guide for setting up Cloudflare Tunnel to expose Jekyll and Quarto websites to the public internet.

**Last Updated**: 2025-11-13
**Prerequisites**: Cloudflare account, domain name

---

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Tunnel Configuration](#tunnel-configuration)
- [DNS Configuration](#dns-configuration)
- [Testing](#testing)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Security](#security)

---

## 🔍 Overview

**Cloudflare Tunnel** (formerly Argo Tunnel) creates a secure, outbound-only connection from your server to Cloudflare's edge network. This allows you to expose services to the internet without opening any inbound firewall ports.

### How It Works

```
Internet → Cloudflare Edge → Cloudflare Tunnel → Your Server
```

**Benefits**:
- ✅ No inbound firewall rules needed
- ✅ Your public IP stays hidden
- ✅ Works behind NAT/CGNAT
- ✅ Built-in DDoS protection
- ✅ Free SSL certificates
- ✅ CDN caching included

**Use Cases in Gautama**:
- Jekyll static sites (blog.example.com)
- Quarto documentation (docs.example.com)
- ZOHO API integration (api.example.com)

---

## ✅ Prerequisites

### 1. Cloudflare Account

**Create account** (if you don't have one):
1. Go to https://dash.cloudflare.com/sign-up
2. Verify your email
3. Add your domain to Cloudflare
4. Update nameservers at your domain registrar

### 2. Domain Configuration

**Add domain to Cloudflare**:
1. Log in to Cloudflare dashboard
2. Click "Add a Site"
3. Enter your domain (e.g., `example.com`)
4. Choose Free plan
5. Copy nameservers provided
6. Update nameservers at your domain registrar
7. Wait for DNS propagation (can take 24-48 hours)

### 3. Install cloudflared

On Gautama, cloudflared is installed via the NixOS module:

```nix
# modules/services/cloudflared.nix
environment.systemPackages = with pkgs; [
  cloudflared
];
```

After enabling the module:
```bash
sudo nixos-rebuild switch --flake '.#vulcan'
```

Verify installation:
```bash
cloudflared --version
```

---

## 🚀 Initial Setup

### Step 1: Authenticate with Cloudflare

Run the login command to authenticate:

```bash
cloudflared tunnel login
```

This will:
1. Open your browser
2. Ask you to select your domain
3. Authorize cloudflared
4. Save credentials to `~/.cloudflared/cert.pem`

**Output**:
```
You have successfully logged in.
If you wish to copy your credentials to a server, they have been saved to:
/home/johnw/.cloudflared/cert.pem
```

### Step 2: Create Tunnel

Create a named tunnel:

```bash
cloudflared tunnel create gautama-publishing
```

**Output**:
```
Tunnel credentials written to /home/johnw/.cloudflared/<tunnel-id>.json
Created tunnel gautama-publishing with id <tunnel-id>
```

**Note the Tunnel ID** - you'll need this later!

### Step 3: Copy Tunnel Credentials

The credentials file contains sensitive information. We'll store it in SOPS secrets.

```bash
# View the credentials
cat ~/.cloudflared/<tunnel-id>.json
```

Copy the entire JSON content. It looks like:
```json
{
  "AccountTag": "abc123...",
  "TunnelSecret": "xyz789...",
  "TunnelID": "uuid-here"
}
```

### Step 4: Add Credentials to SOPS

Edit your secrets file:

```bash
sops /etc/nixos/secrets.yaml
```

Add the tunnel credentials:

```yaml
cloudflare-tunnel-credentials: |
  {
    "AccountTag": "your-account-tag",
    "TunnelSecret": "your-tunnel-secret",
    "TunnelID": "your-tunnel-id"
  }
```

---

## ⚙️ Tunnel Configuration

### Step 1: Create Configuration

Create tunnel configuration in SOPS:

```bash
sops /etc/nixos/secrets.yaml
```

Add the tunnel configuration:

```yaml
cloudflare-tunnel-config: |
  tunnel: your-tunnel-id-here
  credentials-file: /etc/cloudflared/credentials.json

  # Ingress rules - route domains to local services
  ingress:
    # Jekyll blog
    - hostname: blog.example.com
      service: http://localhost:4100
      originRequest:
        connectTimeout: 30s
        noTLSVerify: false

    # Quarto documentation
    - hostname: docs.example.com
      service: http://localhost:4101
      originRequest:
        connectTimeout: 30s
        noTLSVerify: false

    # ZOHO API integration
    - hostname: api.example.com
      service: http://localhost:4102
      originRequest:
        connectTimeout: 30s
        noTLSVerify: false

    # Catch-all (required as last rule)
    - service: http_status:404

  # Optional: Logging
  loglevel: info
  transport-loglevel: warn
```

**Important Configuration Options**:

- `hostname`: The domain that will route to this service
- `service`: The local URL to proxy to
- `originRequest.connectTimeout`: How long to wait for backend connection
- `originRequest.noTLSVerify`: Whether to verify backend TLS (use false for production)

### Step 2: Enable Module

Edit your host configuration:

```nix
# hosts/vulcan/default.nix
{
  imports = [
    # ... other imports ...
    ../../modules/services/cloudflared.nix
    ../../modules/containers/jekyll-public-quadlet.nix
    ../../modules/containers/quarto-public-quadlet.nix
    ../../modules/containers/zoho-api-quadlet.nix
  ];
}
```

### Step 3: Rebuild System

```bash
cd /etc/nixos
sudo nixos-rebuild switch --flake '.#vulcan'
```

### Step 4: Verify Tunnel Service

```bash
# Check service status
sudo systemctl status cloudflared

# View logs
sudo journalctl -u cloudflared -f
```

Expected output:
```
INF Connection established connIndex=0 location=SFO
INF Connection established connIndex=1 location=LAX
```

---

## 🌐 DNS Configuration

### Method 1: Using cloudflared CLI (Recommended)

Route DNS for each hostname:

```bash
# Jekyll blog
cloudflared tunnel route dns gautama-publishing blog.example.com

# Quarto docs
cloudflared tunnel route dns gautama-publishing docs.example.com

# ZOHO API
cloudflared tunnel route dns gautama-publishing api.example.com
```

**Output**:
```
Successfully created CNAME record for blog.example.com
```

### Method 2: Manual DNS Configuration

1. Go to Cloudflare Dashboard → DNS
2. Add CNAME records:

| Type | Name | Target | Proxy Status |
|------|------|--------|--------------|
| CNAME | blog | tunnel-id.cfargotunnel.com | Proxied (orange) |
| CNAME | docs | tunnel-id.cfargotunnel.com | Proxied (orange) |
| CNAME | api | tunnel-id.cfargotunnel.com | Proxied (orange) |

**Important**: Always enable "Proxied" (orange cloud icon) to use Cloudflare's security and caching features.

---

## 🧪 Testing

### Step 1: DNS Propagation

Wait a few minutes for DNS to propagate, then test:

```bash
# Check DNS resolution
dig blog.example.com
nslookup blog.example.com

# Should return Cloudflare IPs (104.x.x.x or 172.x.x.x)
```

### Step 2: HTTP/HTTPS Access

Test access in browser:

```bash
# Jekyll blog
curl -I https://blog.example.com

# Quarto docs
curl -I https://docs.example.com

# ZOHO API health check
curl https://api.example.com/health
```

Expected response:
```
HTTP/2 200
server: cloudflare
...
```

### Step 3: Local Container Status

Verify containers are running:

```bash
# Check container status
podman ps | grep -E 'jekyll|quarto|zoho'

# Test local access
curl http://localhost:4100  # Jekyll
curl http://localhost:4101  # Quarto
curl http://localhost:4102/health  # ZOHO API
```

---

## 📊 Monitoring

### Prometheus Metrics

The cloudflared service exposes Prometheus metrics at `http://localhost:2000/metrics`.

**Key Metrics**:
- `cloudflared_tunnel_ha_connections` - Number of active connections
- `cloudflared_tunnel_total_requests` - Total requests proxied
- `cloudflared_tunnel_request_errors_total` - Failed requests

### Grafana Dashboard

Create dashboard with these queries:

```promql
# Tunnel connection status
up{job="cloudflared"}

# Request rate
rate(cloudflared_tunnel_total_requests[5m])

# Error rate
rate(cloudflared_tunnel_request_errors_total[5m])

# Active connections
cloudflared_tunnel_ha_connections
```

### Logs

View real-time logs:

```bash
# Cloudflared daemon logs
sudo journalctl -u cloudflared -f

# Container logs
sudo journalctl -u quadlet-jekyll-public -f
sudo journalctl -u quadlet-quarto-public -f
sudo journalctl -u quadlet-zoho-api -f
```

### Alerting

Prometheus alerts are configured in the module:

- **CloudflareTunnelDown**: Triggers if tunnel is unreachable for 2+ minutes
- **CloudflareTunnelHighErrors**: Triggers if error rate >5% for 5+ minutes
- **CloudflareTunnelNoConnections**: Triggers if all connections are lost

Check alerts:
```bash
# View Prometheus alerts
curl http://localhost:9090/api/v1/alerts | jq
```

---

## 🔧 Troubleshooting

### Issue: Tunnel Not Connecting

**Symptoms**: `cloudflared` service fails to start or connect

**Solutions**:

1. **Check credentials**:
   ```bash
   # Verify credentials file exists
   ls -la /etc/cloudflared/credentials.json

   # Check SOPS secret
   sudo cat /run/secrets/cloudflare-tunnel-credentials
   ```

2. **Check configuration**:
   ```bash
   # Verify config file
   sudo cat /etc/cloudflared/config.yml

   # Test configuration
   cloudflared tunnel --config /etc/cloudflared/config.yml ingress validate
   ```

3. **Check network connectivity**:
   ```bash
   # Test Cloudflare API
   curl https://api.cloudflare.com/client/v4/accounts

   # Check firewall (outbound should be allowed)
   sudo iptables -L OUTPUT -n
   ```

4. **View detailed logs**:
   ```bash
   sudo journalctl -u cloudflared -n 100 --no-pager
   ```

### Issue: 502 Bad Gateway

**Symptoms**: Cloudflare returns 502 error when accessing site

**Causes**:
- Backend container not running
- Backend listening on wrong port
- Ingress rule misconfigured

**Solutions**:

1. **Check container status**:
   ```bash
   podman ps
   sudo systemctl status quadlet-jekyll-public
   ```

2. **Test local access**:
   ```bash
   curl http://localhost:4100  # Should work
   ```

3. **Check ingress rules**:
   ```bash
   cloudflared tunnel --config /etc/cloudflared/config.yml ingress validate
   cloudflared tunnel --config /etc/cloudflared/config.yml ingress rule blog.example.com
   ```

4. **Restart services**:
   ```bash
   sudo systemctl restart quadlet-jekyll-public
   sudo systemctl restart cloudflared
   ```

### Issue: Slow Response Times

**Symptoms**: Pages load slowly

**Solutions**:

1. **Enable caching in Cloudflare**:
   - Dashboard → Caching → Configuration
   - Cache Level: Standard or Aggressive
   - Browser Cache TTL: 4 hours+

2. **Add page rules**:
   - Dashboard → Rules → Page Rules
   - Pattern: `*.example.com/*`
   - Settings: Cache Level = Cache Everything

3. **Check backend performance**:
   ```bash
   # Test local response time
   time curl http://localhost:4100

   # Check container resources
   podman stats jekyll-public
   ```

4. **Monitor tunnel metrics**:
   ```bash
   curl http://localhost:2000/metrics | grep duration
   ```

### Issue: DNS Not Resolving

**Symptoms**: Domain doesn't resolve or points to wrong IP

**Solutions**:

1. **Check DNS records**:
   ```bash
   dig blog.example.com
   nslookup blog.example.com @1.1.1.1
   ```

2. **Verify CNAME target**:
   - Should point to `<tunnel-id>.cfargotunnel.com`
   - Check in Cloudflare Dashboard → DNS

3. **Check proxy status**:
   - Must be "Proxied" (orange cloud)
   - If "DNS only" (gray cloud), change to Proxied

4. **Wait for propagation**:
   ```bash
   # Can take up to 5 minutes
   watch -n 10 'dig blog.example.com +short'
   ```

---

## 🔒 Security

### Cloudflare Security Features

**Enable these in Cloudflare Dashboard**:

1. **SSL/TLS Settings** (SSL/TLS → Overview):
   - Mode: Full (strict)
   - Always Use HTTPS: On
   - Minimum TLS Version: 1.2

2. **Firewall Rules** (Security → WAF):
   - Enable Managed Rules
   - OWASP Core Ruleset: On
   - Cloudflare Managed Ruleset: On

3. **Rate Limiting** (Security → WAF → Rate limiting rules):
   - Create rule: 100 requests/minute per IP
   - Action: Challenge or Block

4. **DDoS Protection** (automatic):
   - HTTP DDoS Attack Protection: On
   - Network-layer DDoS Attack Protection: On

5. **Bot Fight Mode** (Security → Bots):
   - Bot Fight Mode: On
   - Definitely Automated: Challenge

### Tunnel Security Best Practices

1. **Keep credentials secure**:
   - Store in SOPS secrets only
   - Never commit to git
   - Rotate if compromised

2. **Limit ingress rules**:
   - Only expose necessary services
   - Use specific hostnames (not wildcards)

3. **Monitor access logs**:
   ```bash
   sudo journalctl -u cloudflared | grep "request"
   ```

4. **Regular updates**:
   ```bash
   # Update cloudflared (rebuild system)
   nix flake update
   sudo nixos-rebuild switch --flake '.#vulcan'
   ```

---

## 📚 Additional Resources

- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Ingress Rules Reference](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/local/local-management/ingress/)
- [Cloudflare API Documentation](https://developers.cloudflare.com/api/)
- [NixOS Cloudflared Package](https://search.nixos.org/packages?query=cloudflared)

---

## 🎯 Quick Reference

### Common Commands

```bash
# Service management
sudo systemctl start cloudflared
sudo systemctl stop cloudflared
sudo systemctl restart cloudflared
sudo systemctl status cloudflared

# View logs
sudo journalctl -u cloudflared -f
sudo journalctl -u cloudflared --since "10 minutes ago"

# Test configuration
cloudflared tunnel --config /etc/cloudflared/config.yml ingress validate

# Test ingress rule
cloudflared tunnel --config /etc/cloudflared/config.yml ingress rule blog.example.com

# List tunnels
cloudflared tunnel list

# Delete tunnel (if needed)
cloudflared tunnel delete gautama-publishing
```

### Configuration Locations

| Item | Location |
|------|----------|
| Tunnel credentials | `/etc/cloudflared/credentials.json` (symlink to SOPS secret) |
| Tunnel config | `/etc/cloudflared/config.yml` (symlink to SOPS secret) |
| Module | `/etc/nixos/modules/services/cloudflared.nix` |
| Secrets | `/etc/nixos/secrets.yaml` (encrypted) |
| Metrics | `http://localhost:2000/metrics` |
| Logs | `journalctl -u cloudflared` |

---

**Last Updated**: 2025-11-13
**Maintained by**: Gautama System Administrator
