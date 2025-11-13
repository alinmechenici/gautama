# Internet Publishing Setup

**Purpose**: Design document for exposing Jekyll and Quarto websites to the public internet with Cloudflare integration and ZOHO API interaction.

**Status**: Planning Document
**Last Updated**: 2025-11-13
**Owner**: System Administrator

---

## 📋 Table of Contents

- [Current State](#current-state)
- [Requirements](#requirements)
- [Architecture Options](#architecture-options)
- [Recommended Solution](#recommended-solution)
- [Security Considerations](#security-considerations)
- [Cloudflare Integration](#cloudflare-integration)
- [ZOHO API Integration](#zoho-api-integration)
- [Implementation Plan](#implementation-plan)
- [File Structure](#file-structure)

---

## 🔍 Current State

### Existing Setup

Currently, Jekyll and Quarto are configured as **internal-only services**:

- **Jekyll**: `https://jekyll.vulcan.lan` (port 4000)
- **Quarto**: `https://quarto.vulcan.lan` (port 4001)

**Access Method**: Tailscale VPN only
**Certificates**: Internal step-ca certificates for `.vulcan.lan` domain
**Architecture**: Native systemd services with Nginx reverse proxy

**Limitations**:
- Not accessible from public internet
- Requires Tailscale connection
- Internal TLS certificates not trusted by public browsers
- Limited to development/preview mode

---

## 📝 Requirements

### Functional Requirements

1. **Public Internet Access**: Jekyll and Quarto websites must be accessible without Tailscale
2. **Containerization**: Services must run in containers for isolation and portability
3. **Cloudflare Integration**: Use Cloudflare for DNS and CDN services
4. **ZOHO API Integration**: System must interact with ZOHO APIs (Mail, CRM, etc.)
5. **Multiple Sites**: Support hosting multiple Jekyll/Quarto sites simultaneously

### Non-Functional Requirements

1. **Security**: DDoS protection, rate limiting, secure authentication
2. **Performance**: Fast page loads with Cloudflare CDN caching
3. **Reliability**: High availability with automatic container restarts
4. **Monitoring**: Prometheus metrics and health checks
5. **SSL/TLS**: Valid public certificates via Let's Encrypt or Cloudflare

---

## 🏗️ Architecture Options

### Option A: Direct Internet Exposure with Cloudflare Proxy

**Architecture**:
```
Internet → Cloudflare CDN → Your Public IP → Nginx → Container
```

**Pros**:
- Simple to implement
- Cloudflare handles DDoS protection
- Free SSL certificates from Cloudflare
- CDN caching for static content
- Full control over traffic routing

**Cons**:
- Requires port 80/443 open on firewall
- Your public IP is known to Cloudflare (but hidden from public)
- Need dynamic DNS if IP changes
- Direct connection to your network

**Best For**:
- Sites with predictable traffic
- When you have a static public IP
- Maximum performance requirements

---

### Option B: Cloudflare Tunnel (Recommended)

**Architecture**:
```
Internet → Cloudflare CDN → Cloudflare Tunnel → Container
```

**How it works**:
- Cloudflare `cloudflared` daemon runs on your system
- Creates secure tunnel to Cloudflare edge
- No inbound ports required on your firewall
- Cloudflare routes traffic through tunnel to your containers

**Pros**:
- ✅ **No firewall changes needed** (outbound only)
- ✅ **Your public IP stays hidden**
- ✅ **Works behind NAT/CGNAT**
- ✅ **Built-in DDoS protection**
- ✅ **Zero Trust security model**
- ✅ **Free for personal use**
- ✅ **Automatic failover**

**Cons**:
- Additional latency through tunnel (~10-50ms)
- Dependent on Cloudflare infrastructure
- Limited to Cloudflare's tunnel policies

**Best For**:
- Home networks behind NAT
- Maximum security requirements
- Dynamic IP addresses
- Sites that don't need ultra-low latency

---

### Option C: Hybrid Approach

Use **Cloudflare Tunnel** for Jekyll/Quarto, keep **Tailscale** for admin access.

**Benefits**:
- Public websites via secure tunnel
- Administrative access via Tailscale VPN
- Separation of public and private services
- Multiple layers of security

---

## ✅ Recommended Solution

**Use Option B: Cloudflare Tunnel** for the following reasons:

1. **Security**: No inbound firewall rules needed
2. **Simplicity**: Works with dynamic IPs and NAT
3. **Cost**: Free for personal use
4. **Integration**: Native Cloudflare DNS management
5. **Flexibility**: Easy to add/remove sites

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│                   CLOUDFLARE EDGE                            │
│  • DDoS Protection  • CDN Caching  • SSL/TLS                │
│  • WAF Rules        • Rate Limiting • DNS Management         │
└────────────────────┬────────────────────────────────────────┘
                     │ Cloudflare Tunnel (Encrypted)
┌────────────────────▼────────────────────────────────────────┐
│                     VULCAN HOST                              │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         cloudflared (Tunnel Daemon)                 │    │
│  └───────┬──────────────────────┬─────────────────────┘    │
│          │                      │                           │
│  ┌───────▼──────────┐   ┌───────▼──────────┐              │
│  │  Jekyll Container│   │ Quarto Container  │              │
│  │  Port: 4000      │   │  Port: 4001       │              │
│  │  Sites: /sites   │   │  Projects: /proj  │              │
│  └──────────────────┘   └───────────────────┘              │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           ZOHO API Integration Service                │  │
│  │  • Mail API  • CRM API  • Books API                  │  │
│  └──────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

### Traffic Flow

1. **User** visits `https://blog.example.com`
2. **Cloudflare DNS** resolves to Cloudflare edge server
3. **Cloudflare Edge** checks cache, applies WAF rules
4. **Cloudflare Tunnel** routes request through encrypted tunnel to `cloudflared` daemon
5. **cloudflared** forwards to **Jekyll container** on port 4000
6. **Jekyll** serves static content
7. Response travels back through tunnel to user

---

## 🔒 Security Considerations

### Network Security

**Cloudflare Tunnel Security**:
- All traffic encrypted end-to-end (TLS 1.3)
- No inbound firewall rules required
- DDoS protection at Cloudflare edge
- Tunnel credentials stored in SOPS secrets

**Container Isolation**:
- Rootless Podman containers
- No privileged containers
- Read-only container filesystems where possible
- Limited resource allocation (CPU, memory)

**Access Control**:
- Cloudflare Access for authentication (optional)
- Rate limiting per IP address
- Geographic restrictions if needed
- Bot protection enabled

### Application Security

**Static Site Security** (Jekyll/Quarto):
- No server-side code execution
- Static file serving only
- Content Security Policy headers
- X-Frame-Options, X-Content-Type-Options headers

**ZOHO API Security**:
- API credentials in SOPS secrets
- OAuth 2.0 authentication where supported
- API rate limiting
- Separate service account for API access

### Monitoring & Alerting

**Prometheus Metrics**:
- Tunnel connection status
- Request rates per site
- Response times
- Error rates
- Container health

**Alertmanager Rules**:
- Alert if tunnel disconnects
- Alert on high error rates (>5%)
- Alert on slow responses (>2s)
- Alert on container failures

---

## ☁️ Cloudflare Integration

### DNS Configuration

**Example DNS Records**:
```
blog.example.com     CNAME   tunnel-id.cfargotunnel.com   (Proxied)
docs.example.com     CNAME   tunnel-id.cfargotunnel.com   (Proxied)
```

**Configuration**:
- Enable Cloudflare proxy (orange cloud)
- SSL/TLS mode: Full (strict)
- Always use HTTPS: Enabled
- Automatic HTTPS Rewrites: Enabled

### Cloudflare Tunnel Setup

**Install cloudflared**:
```nix
environment.systemPackages = [ pkgs.cloudflared ];
```

**Authenticate**:
```bash
cloudflared tunnel login
```

**Create Tunnel**:
```bash
cloudflared tunnel create gautama-publishing
# Saves credentials to: ~/.cloudflared/tunnel-id.json
```

**Configure Tunnel** (`/etc/cloudflared/config.yml`):
```yaml
tunnel: gautama-publishing
credentials-file: /run/secrets/cloudflare-tunnel-credentials

ingress:
  # Jekyll sites
  - hostname: blog.example.com
    service: http://localhost:4000

  # Quarto sites
  - hostname: docs.example.com
    service: http://localhost:4001

  # Catch-all rule (required)
  - service: http_status:404
```

**Route DNS**:
```bash
cloudflared tunnel route dns gautama-publishing blog.example.com
cloudflared tunnel route dns gautama-publishing docs.example.com
```

**Run as systemd service**:
```bash
cloudflared service install
systemctl start cloudflared
systemctl enable cloudflared
```

### Cloudflare Features to Enable

**Performance**:
- Auto Minify (CSS, JS, HTML)
- Brotli compression
- HTTP/2, HTTP/3 support
- Cache Everything page rule for static assets

**Security**:
- Managed Challenge for suspected bots
- Rate Limiting (configurable per path)
- WAF rules for common vulnerabilities
- Bot Fight Mode

**Reliability**:
- Always Online (serve cached version if origin down)
- Load Balancing (if multiple origins)

---

## 📧 ZOHO API Integration

### ZOHO Services Available

ZOHO offers APIs for multiple services:

1. **ZOHO Mail** - Email management, send/receive emails programmatically
2. **ZOHO CRM** - Customer relationship management, contacts, deals
3. **ZOHO Books** - Accounting and invoicing
4. **ZOHO Desk** - Customer support tickets
5. **ZOHO Projects** - Project management
6. **ZOHO Sign** - Digital signature workflow
7. **ZOHO Analytics** - Data analytics and reporting

### Use Cases for Integration

**Scenario 1: Contact Form on Jekyll Site**
- User submits contact form on static Jekyll site
- JavaScript posts to ZOHO CRM API
- Creates new lead/contact in ZOHO CRM
- Sends notification email via ZOHO Mail API

**Scenario 2: Newsletter Signup**
- User subscribes to newsletter
- Add contact to ZOHO Campaigns mailing list
- Send welcome email via ZOHO Mail

**Scenario 3: Documentation Feedback**
- User submits feedback on Quarto docs
- Create ticket in ZOHO Desk
- Notify support team

**Scenario 4: Blog Post Publishing**
- Publish new blog post in Jekyll
- Trigger webhook to ZOHO service
- Send announcement to mailing list
- Create social media posts

### Authentication Methods

**OAuth 2.0** (Recommended):
- User grants permission to app
- Refresh token stored securely
- Access tokens auto-refreshed

**API Token**:
- Generate token in ZOHO console
- Store in SOPS secrets
- Simpler but less secure

### API Integration Service

Create dedicated service for ZOHO API interactions:

**File**: `modules/services/zoho-api.nix`

**Features**:
- REST API proxy for ZOHO services
- Rate limiting and retry logic
- Credential management via SOPS
- Prometheus metrics
- Health checks

**Architecture**:
```
Jekyll/Quarto → Webhook/Form → ZOHO API Service → ZOHO Cloud
```

**Technologies**:
- **Python FastAPI** or **Node.js Express**
- Runs in container
- Connects to ZOHO APIs
- Exposes internal REST endpoints

**Endpoints**:
```
POST /api/crm/contact       - Create CRM contact
POST /api/mail/send         - Send email via ZOHO Mail
POST /api/desk/ticket       - Create support ticket
GET  /api/health            - Health check
GET  /api/metrics           - Prometheus metrics
```

### Security for ZOHO Integration

**Credentials**:
- OAuth tokens in SOPS secrets
- Automatic token refresh
- Separate service account

**Rate Limiting**:
- Respect ZOHO API rate limits
- Queue requests if needed
- Exponential backoff on errors

**Input Validation**:
- Validate all form inputs
- Sanitize data before sending to ZOHO
- CSRF protection on forms

---

## 🚀 Implementation Plan

### Phase 1: Containerization

**Objective**: Convert Jekyll and Quarto to containers

**Tasks**:
1. Create Containerfile for Jekyll with production build
2. Create Containerfile for Quarto with dependencies
3. Convert systemd services to Quadlet definitions
4. Mount site content from ZFS datasets
5. Test containers locally

**Files to Create**:
- `modules/containers/jekyll-public-quadlet.nix`
- `modules/containers/quarto-public-quadlet.nix`
- `containers/jekyll/Containerfile`
- `containers/quarto/Containerfile`

**Estimated Time**: 4-6 hours

---

### Phase 2: Cloudflare Tunnel Setup

**Objective**: Set up Cloudflare Tunnel for public access

**Tasks**:
1. Install cloudflared package
2. Authenticate with Cloudflare account
3. Create tunnel with unique name
4. Configure tunnel ingress rules
5. Create systemd service for cloudflared
6. Store tunnel credentials in SOPS
7. Configure DNS records in Cloudflare
8. Test public access

**Files to Create**:
- `modules/services/cloudflared.nix`
- `secrets.yaml` (add cloudflare-tunnel-credentials)

**Configuration**:
```nix
# modules/services/cloudflared.nix
{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.cloudflared ];

  # Tunnel credentials from SOPS
  sops.secrets."cloudflare-tunnel-credentials" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  systemd.services.cloudflared = {
    description = "Cloudflare Tunnel";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --config /etc/cloudflared/config.yml run";
      Restart = "always";
      RestartSec = "5s";
    };
  };

  # Prometheus monitoring
  services.prometheus.scrapeConfigs = [{
    job_name = "cloudflared";
    static_configs = [{
      targets = [ "localhost:2000" ]; # cloudflared metrics
      labels = { service = "cloudflared"; };
    }];
  }];
}
```

**Estimated Time**: 2-4 hours

---

### Phase 3: ZOHO API Integration

**Objective**: Create service for ZOHO API interactions

**Tasks**:
1. Create ZOHO API service (Python FastAPI)
2. Implement authentication (OAuth 2.0)
3. Create API endpoints for common operations
4. Containerize the service
5. Add Prometheus metrics
6. Create contact form example for Jekyll
7. Store ZOHO credentials in SOPS
8. Test API integration

**Files to Create**:
- `modules/containers/zoho-api-quadlet.nix`
- `containers/zoho-api/Containerfile`
- `containers/zoho-api/app.py` (FastAPI application)
- `containers/zoho-api/requirements.txt`
- Example form in Jekyll site

**API Service Code** (Python FastAPI):
```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
import httpx

app = FastAPI()

ZOHO_CLIENT_ID = os.getenv("ZOHO_CLIENT_ID")
ZOHO_CLIENT_SECRET = os.getenv("ZOHO_CLIENT_SECRET")
ZOHO_REFRESH_TOKEN = os.getenv("ZOHO_REFRESH_TOKEN")

class ContactRequest(BaseModel):
    name: str
    email: str
    message: str

@app.post("/api/crm/contact")
async def create_contact(contact: ContactRequest):
    # Get access token
    access_token = await get_zoho_access_token()

    # Create CRM contact
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://www.zohoapis.com/crm/v2/Contacts",
            headers={
                "Authorization": f"Zoho-oauthtoken {access_token}",
                "Content-Type": "application/json"
            },
            json={
                "data": [{
                    "First_Name": contact.name,
                    "Email": contact.email,
                    "Description": contact.message
                }]
            }
        )

    if response.status_code != 201:
        raise HTTPException(status_code=500, detail="Failed to create contact")

    return {"status": "success", "id": response.json()["data"][0]["id"]}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
```

**Estimated Time**: 6-8 hours

---

### Phase 4: Testing & Monitoring

**Objective**: Ensure everything works and is monitored

**Tasks**:
1. Test public access to Jekyll/Quarto sites
2. Test ZOHO API integration
3. Configure Prometheus alerts
4. Set up Grafana dashboards
5. Test failover scenarios
6. Load testing with simple tools
7. Document troubleshooting procedures

**Grafana Dashboard Panels**:
- Cloudflare tunnel status
- Request rate per site
- Response times (p50, p95, p99)
- Error rates
- ZOHO API call success/failure
- Container resource usage

**Estimated Time**: 3-4 hours

---

### Phase 5: Documentation & Runbooks

**Objective**: Document everything for future reference

**Tasks**:
1. Update PUBLISHING_SERVICES.md with internet access info
2. Create CLOUDFLARE_TUNNEL_GUIDE.md
3. Create ZOHO_API_GUIDE.md
4. Add troubleshooting section
5. Document DNS configuration
6. Create runbook for tunnel failures

**Files to Update/Create**:
- `docs/md/PUBLISHING_SERVICES.md` (update)
- `docs/md/CLOUDFLARE_TUNNEL_GUIDE.md` (new)
- `docs/md/ZOHO_API_GUIDE.md` (new)
- `docs/md/RUNBOOK_CLOUDFLARE_TUNNEL.md` (new)

**Estimated Time**: 2-3 hours

---

## 📁 File Structure

After implementation, the structure will be:

```
/etc/nixos/
├── modules/
│   ├── containers/
│   │   ├── jekyll-public-quadlet.nix       # Jekyll for public internet
│   │   ├── quarto-public-quadlet.nix       # Quarto for public internet
│   │   └── zoho-api-quadlet.nix            # ZOHO API integration service
│   └── services/
│       └── cloudflared.nix                 # Cloudflare Tunnel daemon
│
├── containers/
│   ├── jekyll/
│   │   ├── Containerfile                   # Jekyll container image
│   │   └── entrypoint.sh                   # Container startup script
│   ├── quarto/
│   │   ├── Containerfile                   # Quarto container image
│   │   └── entrypoint.sh                   # Container startup script
│   └── zoho-api/
│       ├── Containerfile                   # ZOHO API service image
│       ├── app.py                          # FastAPI application
│       ├── requirements.txt                # Python dependencies
│       └── config.py                       # Configuration management
│
├── docs/md/
│   ├── PUBLISHING_SERVICES.md              # Updated with internet access
│   ├── CLOUDFLARE_TUNNEL_GUIDE.md          # Cloudflare setup guide
│   ├── ZOHO_API_GUIDE.md                   # ZOHO integration guide
│   └── RUNBOOK_CLOUDFLARE_TUNNEL.md        # Troubleshooting runbook
│
└── secrets.yaml                            # Add ZOHO and Cloudflare secrets
    # New secrets to add:
    # - cloudflare-tunnel-credentials
    # - zoho-client-id
    # - zoho-client-secret
    # - zoho-refresh-token
```

**ZFS Datasets**:
```
tank/Projects/jekyll-sites       # Jekyll site content
tank/Projects/quarto-projects    # Quarto project files
```

---

## 📊 Cost Analysis

### Cloudflare

**Free Tier** (recommended):
- Unlimited bandwidth
- DDoS protection
- SSL certificates
- Cloudflare Tunnel (up to 50)
- Basic WAF rules
- **Cost**: $0/month

**Pro Tier** ($20/month):
- Advanced WAF rules
- Image optimization
- Mobile optimization
- 20+ page rules
- **Cost**: $20/month per zone

**Recommendation**: Start with Free tier, upgrade if needed.

### ZOHO

**ZOHO CRM Free** (up to 3 users):
- Basic CRM functionality
- API access included
- **Cost**: $0/month

**ZOHO Mail** (5 users):
- $1/user/month
- API access included
- **Cost**: $5/month

**Total Estimated Cost**: $0-25/month depending on features needed

---

## ⚠️ Risks & Mitigations

### Risk 1: Cloudflare Tunnel Failure

**Impact**: Sites become inaccessible
**Probability**: Low
**Mitigation**:
- Prometheus alerting on tunnel disconnect
- Automatic restart via systemd
- Fallback to Tailscale access for emergency maintenance
- Document manual recovery procedures

### Risk 2: DDoS Attack

**Impact**: High bandwidth usage, potential downtime
**Probability**: Medium (public sites)
**Mitigation**:
- Cloudflare DDoS protection (automatic)
- Rate limiting per IP
- Challenge pages for suspected bots
- Geographic restrictions if needed

### Risk 3: ZOHO API Rate Limits

**Impact**: API requests fail, form submissions lost
**Probability**: Low (generous limits)
**Mitigation**:
- Request queuing in API service
- Exponential backoff on errors
- Monitoring of API usage
- Email fallback if ZOHO unavailable

### Risk 4: Static Site Build Failures

**Impact**: Outdated content, broken links
**Probability**: Medium
**Mitigation**:
- CI/CD validation before deployment
- Health checks on container startup
- Rollback capability
- Build logs in journald

---

## 🎯 Success Criteria

Implementation is considered successful when:

- ✅ Jekyll and Quarto sites accessible from public internet without Tailscale
- ✅ Sites load in <2 seconds (first byte)
- ✅ Cloudflare Tunnel remains connected 99.9%+ uptime
- ✅ ZOHO API integration successfully creates CRM contacts
- ✅ Prometheus monitoring shows all metrics
- ✅ No security vulnerabilities in external scan
- ✅ Documentation complete and accurate
- ✅ Zero inbound firewall rules required

---

## 📚 References

- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [ZOHO CRM API Documentation](https://www.zoho.com/crm/developer/docs/api/v2/)
- [ZOHO Mail API Documentation](https://www.zoho.com/mail/help/api/)
- [Jekyll Documentation](https://jekyllrb.com/docs/)
- [Quarto Documentation](https://quarto.org/docs/guide/)
- [Podman Quadlet](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)

---

## ✅ Next Steps

After reviewing this document:

1. **Get user approval** on the architecture choice
2. **Confirm ZOHO services** needed (CRM, Mail, others?)
3. **Obtain Cloudflare account** if not already available
4. **Begin Phase 1**: Containerization of Jekyll/Quarto
5. **Set up Cloudflare Tunnel** in test environment first
6. **Develop ZOHO API service** based on specific requirements
7. **Test end-to-end** before production deployment
8. **Create monitoring dashboards**
9. **Document everything**

---

**Questions for User**:

1. Which ZOHO services do you need to integrate with? (CRM, Mail, Books, Desk, etc.)
2. Do you have a Cloudflare account already, or need to create one?
3. What are your domain names for the Jekyll and Quarto sites?
4. Do you need authentication on the sites, or are they fully public?
5. Any specific rate limiting or geographic restrictions needed?
6. Should we start with Phase 1 (containerization) first?

---

**Ready to implement once approved!**
