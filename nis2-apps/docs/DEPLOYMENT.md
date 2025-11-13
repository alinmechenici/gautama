# NIS2 Applications Deployment Guide

Complete deployment instructions for staging (Gautama) and production (VPS).

---

## 📋 Deployment Overview

### Environments

| Environment | Access | Method | Database |
|------------|--------|--------|----------|
| **Development** | localhost | Rails server | Supabase Dev |
| **Staging** | Tailscale | Quadlet containers on Gautama | Supabase Staging |
| **Production** | Internet | Docker on VPS | Supabase Production |

---

## 🏗️ Staging Deployment (Gautama + Tailscale)

### Prerequisites

- Gautama configured with NixOS
- Tailscale running
- step-ca for certificates
- SOPS for secrets

### Step 1: Prepare Application Code

```bash
# On your development machine
cd nis2-apps

# Commit latest changes
git add .
git commit -m "feat: Ready for staging deployment"
git push
```

### Step 2: Setup on Gautama

```bash
# SSH into Gautama
ssh vulcan

# Clone repository
cd /var/lib/nis2-apps
git clone https://github.com/yourorg/nis2-apps.git .

# Or pull latest
git pull origin main
```

### Step 3: Build Docker Images with Nix

```bash
# Build all images
nis2-build-images

# Or manually for each app:
nix-build '<nixpkgs/nixos>' -A system.build.nis2-services-image -o /tmp/nis2-services-image
podman load < /tmp/nis2-services-image

# Repeat for events, news, academy
```

### Step 4: Configure Secrets

```bash
cd /etc/nixos
sops secrets.yaml
```

Add secrets for each app:

```yaml
# NIS2 Services
nis2-services-supabase-url: "https://xxxxx.supabase.co"
nis2-services-supabase-key: "eyJhbGc..."
nis2-services-database-url: "postgresql://..."
nis2-services-secret-key-base: "$(rails secret)"

# NIS2 Events
nis2-events-supabase-url: "https://xxxxx.supabase.co"
nis2-events-supabase-key: "eyJhbGc..."
nis2-events-database-url: "postgresql://..."
nis2-events-secret-key-base: "$(rails secret)"

# NIS2 News
nis2-news-supabase-url: "https://xxxxx.supabase.co"
nis2-news-supabase-key: "eyJhbGc..."
nis2-news-database-url: "postgresql://..."
nis2-news-secret-key-base: "$(rails secret)"

# NIS2 Academy
nis2-academy-supabase-url: "https://xxxxx.supabase.co"
nis2-academy-supabase-key: "eyJhbGc..."
nis2-academy-database-url: "postgresql://..."
nis2-academy-secret-key-base: "$(rails secret)"
```

### Step 5: Enable NixOS Modules

```bash
cd /etc/nixos
nano hosts/vulcan/default.nix
```

Add modules:

```nix
{
  imports = [
    # ... other imports ...
    ../../modules/containers/nis2-services-quadlet.nix
    ../../modules/containers/nis2-events-quadlet.nix
    ../../modules/containers/nis2-news-quadlet.nix
    ../../modules/containers/nis2-academy-quadlet.nix
  ];
}
```

### Step 6: Deploy

```bash
cd /etc/nixos
sudo nixos-rebuild switch --flake '.#vulcan'
```

### Step 7: Verify Deployment

```bash
# Check container status
podman ps | grep nis2

# Check systemd services
sudo systemctl status quadlet-nis2-services
sudo systemctl status quadlet-nis2-events
sudo systemctl status quadlet-nis2-news
sudo systemctl status quadlet-nis2-academy

# View logs
sudo journalctl -u quadlet-nis2-services -f
```

### Step 8: Test Access via Tailscale

```bash
# From your machine (connected to Tailscale)
curl https://services.nis2.vulcan.lan
curl https://events.nis2.vulcan.lan
curl https://news.nis2.vulcan.lan
curl https://academy.nis2.vulcan.lan

# Or open in browser
open https://services.nis2.vulcan.lan
```

---

## 🌍 Production Deployment (VPS)

### Prerequisites

- VPS account (Vultr/DigitalOcean)
- Domain names configured
- SSH access to VPS

### Step 1: Provision VPS

#### Vultr

```bash
# Create VPS via Vultr dashboard or CLI
# Recommended specs:
# - 4 GB RAM
# - 2 CPU cores
# - 80 GB SSD
# - Ubuntu 22.04 LTS
```

#### DigitalOcean

```bash
# Create Droplet via DO dashboard or doctl
doctl compute droplet create nis2-prod \
  --region nyc1 \
  --size s-2vcpu-4gb \
  --image ubuntu-22-04-x64 \
  --ssh-keys YOUR_SSH_KEY_ID
```

### Step 2: Initial Server Setup

```bash
# SSH into VPS
ssh root@your-vps-ip

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt install docker-compose -y

# Create deployment user
adduser deploy
usermod -aG docker deploy
usermod -aG sudo deploy
```

### Step 3: Setup Application Directory

```bash
# As deploy user
su - deploy

# Create app directory
mkdir -p /home/deploy/nis2-apps
cd /home/deploy/nis2-apps

# Clone repository
git clone https://github.com/yourorg/nis2-apps.git .
```

### Step 4: Configure Environment Variables

```bash
# Create .env file for each app
nano services/.env
```

```bash
# Production environment
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_DATABASE_URL=postgresql://...
SUPABASE_SCHEMA=nis2_services
SECRET_KEY_BASE=$(rails secret)
RAILS_ENV=production
PORT=3001
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true
```

Repeat for all 4 apps.

### Step 5: Create Docker Compose Configuration

```bash
nano docker-compose.prod.yml
```

```yaml
version: '3.8'

services:
  services:
    build:
      context: ./services
      dockerfile: Dockerfile
    image: nis2-services:production
    container_name: nis2-services
    env_file:
      - ./services/.env
    ports:
      - "3001:3001"
    restart: always
    volumes:
      - ./services:/app
      - services-log:/app/log
      - services-tmp:/app/tmp
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  events:
    build:
      context: ./events
      dockerfile: Dockerfile
    image: nis2-events:production
    container_name: nis2-events
    env_file:
      - ./events/.env
    ports:
      - "3002:3002"
    restart: always
    volumes:
      - ./events:/app
      - events-log:/app/log
      - events-tmp:/app/tmp

  news:
    build:
      context: ./news
      dockerfile: Dockerfile
    image: nis2-news:production
    container_name: nis2-news
    env_file:
      - ./news/.env
    ports:
      - "3003:3003"
    restart: always
    volumes:
      - ./news:/app
      - news-log:/app/log
      - news-tmp:/app/tmp

  academy:
    build:
      context: ./academy
      dockerfile: Dockerfile
    image: nis2-academy:production
    container_name: nis2-academy
    env_file:
      - ./academy/.env
    ports:
      - "3004:3004"
    restart: always
    volumes:
      - ./academy:/app
      - academy-log:/app/log
      - academy-tmp:/app/tmp

  redis:
    image: redis:7-alpine
    container_name: nis2-redis
    restart: always
    volumes:
      - redis-data:/data

  nginx:
    image: nginx:alpine
    container_name: nis2-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./infrastructure/production/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./infrastructure/production/nginx/conf.d:/etc/nginx/conf.d:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
    depends_on:
      - services
      - events
      - news
      - academy
    restart: always

volumes:
  services-log:
  services-tmp:
  events-log:
  events-tmp:
  news-log:
  news-tmp:
  academy-log:
  academy-tmp:
  redis-data:
```

### Step 6: Setup Nginx

```bash
mkdir -p infrastructure/production/nginx/conf.d
nano infrastructure/production/nginx/conf.d/nis2-apps.conf
```

```nginx
# Services
server {
    listen 80;
    server_name services.nis2.example.com;

    location / {
        proxy_pass http://services:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Events
server {
    listen 80;
    server_name events.nis2.example.com;

    location / {
        proxy_pass http://events:3002;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# News
server {
    listen 80;
    server_name news.nis2.example.com;

    location / {
        proxy_pass http://news:3003;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Academy
server {
    listen 80;
    server_name academy.nis2.example.com;

    location / {
        proxy_pass http://academy:3004;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Step 7: Setup SSL with Let's Encrypt

```bash
# Install Certbot
apt install certbot python3-certbot-nginx -y

# Get certificates for all domains
certbot --nginx -d services.nis2.example.com
certbot --nginx -d events.nis2.example.com
certbot --nginx -d news.nis2.example.com
certbot --nginx -d academy.nis2.example.com
```

### Step 8: Run Database Migrations

```bash
# For each app
cd services
docker-compose -f ../docker-compose.prod.yml run --rm services bundle exec rails db:migrate
cd ..

cd events
docker-compose -f ../docker-compose.prod.yml run --rm events bundle exec rails db:migrate
cd ..

# Repeat for news and academy
```

### Step 9: Start Production Services

```bash
# Build and start all containers
docker-compose -f docker-compose.prod.yml up -d --build

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

### Step 10: Verify Production Deployment

```bash
# Check container status
docker ps

# Test endpoints
curl https://services.nis2.example.com
curl https://events.nis2.example.com
curl https://news.nis2.example.com
curl https://academy.nis2.example.com

# Check logs
docker logs nis2-services
docker logs nis2-events
docker logs nis2-news
docker logs nis2-academy
```

---

## 🔄 Continuous Deployment

### Automated Deployment Script

```bash
#!/bin/bash
# deploy.sh - Deploy to production

set -e

echo "🚀 Deploying NIS2 applications..."

# Pull latest code
git pull origin main

# Rebuild containers
docker-compose -f docker-compose.prod.yml build

# Stop old containers
docker-compose -f docker-compose.prod.yml down

# Run migrations
for app in services events news academy; do
  docker-compose -f docker-compose.prod.yml run --rm $app bundle exec rails db:migrate
done

# Start new containers
docker-compose -f docker-compose.prod.yml up -d

# Wait for health checks
sleep 30

# Verify deployment
for app in services events news academy; do
  docker-compose -f docker-compose.prod.yml ps $app
done

echo "✅ Deployment complete!"
```

---

## 📊 Monitoring

### Health Checks

```bash
# Check all apps
curl https://services.nis2.example.com/health
curl https://events.nis2.example.com/health
curl https://news.nis2.example.com/health
curl https://academy.nis2.example.com/health
```

### Container Stats

```bash
# View resource usage
docker stats
```

### Logs

```bash
# View logs for specific app
docker logs -f nis2-services

# View all logs
docker-compose -f docker-compose.prod.yml logs -f
```

---

## 🔧 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs nis2-services

# Check environment
docker-compose -f docker-compose.prod.yml config

# Restart container
docker-compose -f docker-compose.prod.yml restart services
```

### Database Connection Error

```bash
# Check database credentials
docker-compose -f docker-compose.prod.yml run --rm services env | grep SUPABASE

# Test database connection
docker-compose -f docker-compose.prod.yml run --rm services bundle exec rails db:migrate:status
```

### SSL Certificate Issues

```bash
# Renew certificates
certbot renew

# Test renewal
certbot renew --dry-run
```

---

## 🔐 Security

### Firewall Setup

```bash
# Allow SSH, HTTP, HTTPS
ufw allow ssh
ufw allow http
ufw allow https
ufw enable
```

### Regular Updates

```bash
# Update system
apt update && apt upgrade -y

# Update containers
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

---

## 📚 Additional Resources

- [Setup Guide](SETUP.md) - Initial setup
- [Development Guide](DEVELOPMENT.md) - Development workflow
- [Architecture](../docs/md/NIS2_APPS_ARCHITECTURE.md) - System architecture

---

**Last Updated**: 2025-11-13
