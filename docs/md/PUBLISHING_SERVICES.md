# Publishing & Project Management Services

Documentation for Jekyll, Quarto, Typst, and Redmine services configured in Gautama.

## 📋 Table of Contents

- [Overview](#overview)
- [Jekyll - Static Site Generator](#jekyll---static-site-generator)
- [Quarto - Technical Publishing](#quarto---technical-publishing)
- [Typst - Modern Typesetting](#typst---modern-typesetting)
- [Redmine - Project Management](#redmine---project-management)
- [Internet Publishing](#-internet-publishing)
- [Tailscale Access](#tailscale-access)
- [Troubleshooting](#troubleshooting)

## 🌐 Overview

Gautama provides both **internal** (Tailscale-only) and **public** (internet-accessible) publishing services.

### Service URLs

#### Internal Services (Tailscale Only)

| Service | URL | Port | Purpose |
|---------|-----|------|---------|
| **Jekyll** | https://jekyll.vulcan.lan | 4000 | Development/preview |
| **Quarto** | https://quarto.vulcan.lan | 4001 | Development/preview |
| **Typst** | https://typst.vulcan.lan | 4002 | Modern typesetting |
| **Redmine** | https://redmine.vulcan.lan | 4003 | Project management |

#### Public Services (Internet Accessible)

| Service | URL | Port | Purpose |
|---------|-----|------|---------|
| **Jekyll Public** | https://blog.example.com* | 4100 | Production blogs/sites |
| **Quarto Public** | https://docs.example.com* | 4101 | Production documentation |
| **ZOHO API** | https://api.example.com* | 4102 | Form integration |

\* *Configure your actual domains in Cloudflare Tunnel*

### Access Methods

**Internal Services** (Tailscale):
- ✅ Secure VPN access
- ✅ Development and preview
- ✅ Full control panel access
- ✅ Internal TLS certificates (step-ca)

**Public Services** (Cloudflare Tunnel):
- ✅ Public internet access
- ✅ Production websites
- ✅ No firewall ports needed
- ✅ DDoS protection
- ✅ CDN caching
- ✅ Free SSL certificates

See **[Internet Publishing](#-internet-publishing)** section below for details.

## 📝 Jekyll - Static Site Generator

### What is Jekyll?

Jekyll is a static site generator perfect for blogs, documentation, and project pages. It transforms Markdown and Liquid templates into a complete static website.

### Access

```bash
# From any machine on Tailscale network
open https://jekyll.vulcan.lan
```

### File Locations

```
/var/lib/jekyll/
├── sites/          # Your Jekyll projects go here
└── ...
```

### Creating a New Site

```bash
# SSH into Vulcan
ssh vulcan

# Switch to jekyll user
sudo -u jekyll -s

# Navigate to sites directory
cd /var/lib/jekyll/sites

# Create new Jekyll site
jekyll new my-blog

# Build and serve
cd my-blog
jekyll serve --host 0.0.0.0 --port 4000
```

### Features

- **Live Reload**: Automatic browser refresh on file changes
- **Incremental Build**: Faster rebuilds during development
- **Markdown Support**: Write content in Markdown
- **Themes**: Support for Jekyll themes
- **Plugins**: Extensible with Ruby gems

### Common Commands

```bash
# Create new site
jekyll new site-name

# Serve locally
jekyll serve

# Build for production
jekyll build

# Clean build artifacts
jekyll clean
```

### Service Management

```bash
# Check status
sudo systemctl status jekyll

# View logs
sudo journalctl -u jekyll -f

# Restart service
sudo systemctl restart jekyll
```

## 📊 Quarto - Technical Publishing

### What is Quarto?

Quarto is an open-source scientific and technical publishing system. Create dynamic content using Python, R, Julia, and Observable.

### Access

```bash
open https://quarto.vulcan.lan
```

### File Locations

```
/var/lib/quarto/
├── projects/       # Your Quarto projects
├── output/         # Rendered output
└── ...
```

### Creating a New Document

```bash
# SSH into Vulcan
ssh vulcan

# Switch to quarto user
sudo -u quarto -s

# Navigate to projects directory
cd /var/lib/quarto/projects

# Create new Quarto project
quarto create-project my-project

# Preview
cd my-project
quarto preview
```

### Supported Formats

- **Documents**: HTML, PDF, Word, Markdown
- **Presentations**: Reveal.js, PowerPoint, Beamer
- **Websites**: Multi-page sites with navigation
- **Books**: Full-length books with chapters
- **Dashboards**: Interactive dashboards

### Features

- **Multi-Language**: Python, R, Julia, Observable
- **Live Preview**: Real-time rendering
- **Code Execution**: Run code chunks inline
- **Citations**: BibTeX support
- **Cross-References**: Automatic figure/table numbering
- **Themes**: Customizable appearance

### Common Commands

```bash
# Create new project
quarto create-project my-project

# Render document
quarto render document.qmd

# Preview with live reload
quarto preview

# Publish to various platforms
quarto publish
```

### Service Management

```bash
# Check status
sudo systemctl status quarto

# View logs
sudo journalctl -u quarto -f

# Restart service
sudo systemctl restart quarto
```

## ✍️ Typst - Modern Typesetting

### What is Typst?

Typst is a new markup-based typesetting system designed to be as powerful as LaTeX while being much easier to learn and use.

### Access

```bash
open https://typst.vulcan.lan
```

### File Locations

```
/var/lib/typst/
├── documents/      # Your Typst documents
├── cache/          # Build cache
└── ...
```

### Creating Documents

The web interface provides:
- **Editor**: Syntax highlighting for Typst
- **Live Preview**: Real-time PDF rendering
- **Templates**: Pre-configured document templates

### Features

- **Fast Compilation**: Instant feedback
- **Modern Syntax**: Clean, readable markup
- **Math Support**: LaTeX-quality math typesetting
- **Scripting**: Built-in scripting language
- **Package System**: Reusable components
- **Web Interface**: No local installation needed

### Example Document

```typst
#set page(paper: "us-letter")
#set text(font: "Linux Libertine", size: 11pt)

= Introduction

This is a simple Typst document.

== Features

- Fast compilation
- Beautiful output
- Easy to learn

== Math

$ f(x) = integral_0^oo e^(-x^2) dif x $
```

### Service Management

```bash
# Check container status
sudo systemctl status quadlet-typst

# View logs
sudo journalctl -u quadlet-typst -f

# Restart container
sudo systemctl restart quadlet-typst
```

## 🎯 Redmine - Project Management

### What is Redmine?

Redmine is a flexible project management web application with:
- Issue tracking
- Project wikis
- Time tracking
- Gantt charts
- Calendars
- Forums

### Access

```bash
open https://redmine.vulcan.lan
```

### Initial Setup

1. **Access Redmine** at https://redmine.vulcan.lan
2. **Default credentials**:
   - Username: `admin`
   - Password: `admin`
3. **Change password immediately** after first login
4. **Configure**:
   - Administration → Settings
   - Create projects
   - Add users
   - Configure issue trackers

### File Locations

```
/var/lib/redmine/
├── files/          # Uploaded files
├── plugins/        # Redmine plugins
├── themes/         # Custom themes
└── ...
```

### Database

- **Type**: PostgreSQL
- **Database**: `redmine`
- **User**: `redmine`
- **Backups**: Included in daily PostgreSQL backups

### Features

- **Issue Tracking**: Bug reports, feature requests, tasks
- **Project Wiki**: Built-in documentation
- **Time Tracking**: Log work hours
- **Gantt Charts**: Project timelines
- **Calendars**: Event scheduling
- **Forums**: Team discussions
- **Email Integration**: Email notifications
- **Custom Fields**: Extend functionality
- **Plugins**: Extensive plugin ecosystem
- **REST API**: Programmatic access

### Common Tasks

**Create a Project:**
1. Administration → Projects → New project
2. Fill in project details
3. Enable modules (issues, wiki, time tracking, etc.)
4. Set permissions

**Create an Issue:**
1. Navigate to project
2. Issues → New issue
3. Fill in details (tracker, subject, description)
4. Assign to team member
5. Set due date and priority

**Install a Plugin:**
```bash
# SSH into Vulcan
ssh vulcan

# Copy plugin to plugins directory
sudo cp -r plugin-name /var/lib/redmine/plugins/

# Restart Redmine
sudo systemctl restart quadlet-redmine
```

### Service Management

```bash
# Check container status
sudo systemctl status quadlet-redmine

# View logs
sudo journalctl -u quadlet-redmine -f

# Restart container
sudo systemctl restart quadlet-redmine

# Backup database
sudo systemctl start postgresql-backup
```

## 🌍 Internet Publishing

### Overview

Jekyll and Quarto can be published to the public internet using **Cloudflare Tunnel**, a secure method that doesn't require opening firewall ports.

### Architecture

```
Internet → Cloudflare Edge → Cloudflare Tunnel → Local Containers → Your Content
```

**Key Benefits**:
- No inbound firewall rules needed
- Your public IP stays hidden
- Built-in DDoS protection
- Free SSL certificates from Cloudflare
- CDN caching for faster loads
- Works behind NAT/CGNAT

### Public Services

#### Jekyll Public (blog.example.com)

**Purpose**: Production blogs and static websites accessible to everyone.

**Features**:
- Containerized for security
- Production builds with optimizations
- CDN caching for fast loads
- Static file serving only
- Health monitoring

**File Location**: `/var/lib/jekyll-public/sites`

**Building the container**:
```bash
cd /etc/nixos/containers/jekyll
podman build -t localhost/jekyll:latest .
```

**Managing the service**:
```bash
# Check status
sudo systemctl status quadlet-jekyll-public

# View logs
sudo journalctl -u quadlet-jekyll-public -f

# Restart
sudo systemctl restart quadlet-jekyll-public

# Test locally
curl http://localhost:4100
```

#### Quarto Public (docs.example.com)

**Purpose**: Production documentation and technical content.

**Features**:
- Multi-language support (Python, R, Julia, Observable)
- Containerized rendering
- Production-optimized builds
- Interactive content support
- Health monitoring

**File Location**: `/var/lib/quarto-public/projects`

**Building the container**:
```bash
cd /etc/nixos/containers/quarto
podman build -t localhost/quarto:latest .
```

**Managing the service**:
```bash
# Check status
sudo systemctl status quadlet-quarto-public

# View logs
sudo journalctl -u quadlet-quarto-public -f

# Restart
sudo systemctl restart quadlet-quarto-public

# Test locally
curl http://localhost:4101
```

#### ZOHO API Service (api.example.com)

**Purpose**: REST API for integrating ZOHO services (CRM, Mail, Desk) with static websites.

**Features**:
- Contact form submissions → ZOHO CRM
- Newsletter signups → ZOHO Mail
- Support tickets → ZOHO Desk
- OAuth 2.0 authentication
- Rate limiting
- Prometheus metrics

**Building the container**:
```bash
cd /etc/nixos/containers/zoho-api
podman build -t localhost/zoho-api:latest .
```

**Managing the service**:
```bash
# Check status
sudo systemctl status quadlet-zoho-api

# View logs
sudo journalctl -u quadlet-zoho-api -f

# Health check
curl http://localhost:4102/health

# Test API
curl -X POST http://localhost:4102/api/crm/contact \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Test","last_name":"User","email":"test@example.com"}'
```

### Setup Guide

**Complete setup instructions**: See [`CLOUDFLARE_TUNNEL_GUIDE.md`](CLOUDFLARE_TUNNEL_GUIDE.md)

**Quick Start**:

1. **Install and authenticate cloudflared**:
   ```bash
   cloudflared tunnel login
   ```

2. **Create tunnel**:
   ```bash
   cloudflared tunnel create gautama-publishing
   ```

3. **Add credentials to SOPS**:
   ```bash
   sops /etc/nixos/secrets.yaml
   # Add cloudflare-tunnel-credentials and cloudflare-tunnel-config
   ```

4. **Enable modules**:
   ```nix
   # hosts/vulcan/default.nix
   imports = [
     ../../modules/services/cloudflared.nix
     ../../modules/containers/jekyll-public-quadlet.nix
     ../../modules/containers/quarto-public-quadlet.nix
     ../../modules/containers/zoho-api-quadlet.nix
   ];
   ```

5. **Rebuild system**:
   ```bash
   sudo nixos-rebuild switch --flake '.#vulcan'
   ```

6. **Configure DNS** (via cloudflared or Cloudflare Dashboard):
   ```bash
   cloudflared tunnel route dns gautama-publishing blog.example.com
   cloudflared tunnel route dns gautama-publishing docs.example.com
   cloudflared tunnel route dns gautama-publishing api.example.com
   ```

### ZOHO Integration

**Purpose**: Enable contact forms, newsletter signups, and support tickets on static websites.

**Setup Guide**: See [`ZOHO_API_GUIDE.md`](ZOHO_API_GUIDE.md)

**Example Contact Form** (Jekyll/Quarto):

```html
<form id="contact-form">
  <input type="text" name="first_name" placeholder="First Name" required>
  <input type="text" name="last_name" placeholder="Last Name" required>
  <input type="email" name="email" placeholder="Email" required>
  <textarea name="message" placeholder="Your message"></textarea>
  <button type="submit">Send</button>
  <div id="status"></div>
</form>

<script>
document.getElementById('contact-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const data = Object.fromEntries(new FormData(e.target));

  const response = await fetch('https://api.example.com/api/crm/contact', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  });

  if (response.ok) {
    document.getElementById('status').textContent = 'Thank you! We will contact you soon.';
    e.target.reset();
  } else {
    document.getElementById('status').textContent = 'Error. Please try again.';
  }
});
</script>
```

### Security Considerations

**Container Security**:
- All containers run as non-root users
- Rootless Podman for isolation
- Health checks for monitoring
- Resource limits enforced

**Network Security**:
- No inbound firewall ports needed
- Cloudflare Tunnel uses outbound-only connections
- DDoS protection at Cloudflare edge
- WAF rules for common attacks

**Cloudflare Security Features**:
- Enable SSL/TLS (Full strict mode)
- Enable WAF managed rules
- Configure rate limiting (100 req/min per IP)
- Enable Bot Fight Mode
- Use HTTPS-only (redirect HTTP → HTTPS)

### Monitoring

**Prometheus Metrics**:
- `cloudflared` tunnel health and connection status
- Container resource usage
- Request rates and response times
- Error rates

**Grafana Dashboards**:
- Tunnel connectivity
- Service uptime
- Request patterns
- ZOHO API usage

**Alerts**:
- Tunnel disconnection (critical)
- High error rates (warning)
- Container failures (critical)
- ZOHO API authentication failures (warning)

### Cost

**Free Tier** (recommended for personal use):
- Cloudflare Tunnel: Free
- Cloudflare CDN: Free (unlimited bandwidth)
- SSL Certificates: Free
- DDoS Protection: Free
- ZOHO CRM Free: 3 users, 5,000 records
- **Total: $0/month**

**Optional Upgrades**:
- Cloudflare Pro: $20/month (advanced features)
- ZOHO Mail: $1/user/month
- ZOHO CRM Standard: $14/user/month

### Troubleshooting Internet Publishing

**Tunnel not connecting**:
```bash
# Check cloudflared service
sudo systemctl status cloudflared
sudo journalctl -u cloudflared -f

# Verify credentials
sudo cat /etc/cloudflared/credentials.json

# Test configuration
cloudflared tunnel --config /etc/cloudflared/config.yml ingress validate
```

**502 Bad Gateway**:
```bash
# Check containers are running
podman ps | grep -E 'jekyll|quarto|zoho'

# Test local access
curl http://localhost:4100  # Jekyll
curl http://localhost:4101  # Quarto
curl http://localhost:4102/health  # ZOHO API

# Restart containers
sudo systemctl restart quadlet-jekyll-public
sudo systemctl restart quadlet-quarto-public
sudo systemctl restart quadlet-zoho-api
```

**ZOHO API not working**:
```bash
# Check service logs
sudo journalctl -u quadlet-zoho-api -n 50

# Test health
curl http://localhost:4102/health

# Verify secrets
sudo cat /run/secrets/zoho-api-env | grep -E 'CLIENT|TOKEN'

# Test manually
curl -X POST http://localhost:4102/api/crm/contact \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Test","last_name":"User","email":"test@example.com"}'
```

## 🔒 Tailscale Access

### Connecting to Services

All services are accessible only via Tailscale for security.

**From your machine:**

1. **Connect to Tailscale**:
   ```bash
   # macOS/Linux
   tailscale up

   # Check status
   tailscale status
   ```

2. **Verify connectivity**:
   ```bash
   # Ping Vulcan
   ping vulcan

   # Check DNS
   nslookup jekyll.vulcan.lan
   ```

3. **Access services**:
   ```bash
   # Open in browser
   open https://jekyll.vulcan.lan
   open https://quarto.vulcan.lan
   open https://typst.vulcan.lan
   open https://redmine.vulcan.lan
   ```

### DNS Configuration

Services use `.vulcan.lan` internal domain:
- Resolved by Technitium DNS on Vulcan
- Only accessible via Tailscale network
- TLS certificates from step-ca

### Troubleshooting Access

**Can't reach service:**

```bash
# Check Tailscale connection
tailscale status

# Verify DNS
nslookup jekyll.vulcan.lan

# Test connectivity
ping vulcan

# Check if service is running
ssh vulcan "systemctl status jekyll"
```

**Certificate errors:**

- Certificates are from internal step-ca
- Add Vulcan CA to your trust store
- Or accept the certificate in browser

## 🔧 Troubleshooting

### Jekyll Issues

**Service won't start:**
```bash
# Check logs
sudo journalctl -u jekyll -n 100

# Verify directory permissions
ls -la /var/lib/jekyll

# Test Jekyll manually
sudo -u jekyll jekyll --version
```

**Site not updating:**
```bash
# Clear Jekyll cache
sudo rm -rf /var/lib/jekyll/.jekyll-cache

# Restart service
sudo systemctl restart jekyll
```

### Quarto Issues

**Preview not working:**
```bash
# Check logs
sudo journalctl -u quarto -n 100

# Verify Quarto installation
quarto check

# Test manually
sudo -u quarto quarto preview --port 4001
```

### Typst Issues

**Container won't start:**
```bash
# Check container status
sudo systemctl status quadlet-typst

# View container logs
podman logs typst

# Restart container
sudo systemctl restart quadlet-typst
```

### Redmine Issues

**Database connection errors:**
```bash
# Check PostgreSQL
sudo systemctl status postgresql

# Verify database exists
sudo -u postgres psql -c "\l" | grep redmine

# Check environment file
sudo cat /run/secrets/redmine-env
```

**File upload issues:**
```bash
# Check directory permissions
ls -la /var/lib/redmine/files

# Ensure directory exists and is writable
sudo mkdir -p /var/lib/redmine/files
sudo chmod 755 /var/lib/redmine/files
```

### General Troubleshooting

**Check all services:**
```bash
# Run health check
/etc/nixos/scripts/health-check.sh

# Check service status
/etc/nixos/scripts/service-status.sh
```

**Certificate issues:**
```bash
# Verify certificate exists
ls -la /var/lib/nginx-certs/jekyll.vulcan.lan.*

# Renew certificate manually
sudo /etc/nixos/certs/renew-certificate.sh jekyll.vulcan.lan \
  -o /var/lib/nginx-certs -d 365 --owner nginx:nginx
```

**Network connectivity:**
```bash
# Test internal connectivity
curl -k https://127.0.0.1:4000  # Jekyll
curl -k https://127.0.0.1:4001  # Quarto
curl -k https://127.0.0.1:4002  # Typst
curl -k https://127.0.0.1:4003  # Redmine
```

## 📊 Monitoring

All services are monitored via Prometheus:

- **Jekyll**: HTTP endpoint monitoring
- **Quarto**: HTTP endpoint monitoring
- **Typst**: Blackbox exporter HTTP checks
- **Redmine**: Blackbox exporter HTTP checks + PostgreSQL metrics

**View metrics:**
```bash
# Access Prometheus
open https://prometheus.vulcan.lan

# Check targets
# Prometheus → Status → Targets
# Look for: jekyll, quarto, typst-http, redmine-http
```

**Access Grafana:**
```bash
open https://grafana.vulcan.lan
# Dashboards show service health and performance
```

## 🔄 Backups

**Redmine**:
- Database backed up daily via PostgreSQL backup service
- Files in `/var/lib/redmine/` included in Restic backups

**Other services**:
- Document directories included in Restic backups
- Manual backup recommended before major changes

## 📚 Additional Resources

### Jekyll
- [Official Documentation](https://jekyllrb.com/docs/)
- [Jekyll Themes](https://jekyllthemes.io/)
- [Jekyll Plugins](https://jekyllrb.com/docs/plugins/)

### Quarto
- [Official Documentation](https://quarto.org/)
- [Gallery](https://quarto.org/docs/gallery/)
- [Extensions](https://quarto.org/docs/extensions/)

### Typst
- [Official Documentation](https://typst.app/docs)
- [Typst Universe](https://typst.app/universe) - Package registry
- [Tutorial](https://typst.app/docs/tutorial/)

### Redmine
- [Official Documentation](https://www.redmine.org/projects/redmine/wiki/Guide)
- [Plugins Directory](https://www.redmine.org/plugins)
- [Themes](https://www.redmine.org/projects/redmine/wiki/Theme_List)
