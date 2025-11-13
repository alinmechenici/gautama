# NIS2 Apps - Quick Start Guide

Get up and running with NIS2 applications in under 15 minutes.

---

## 🎯 What You're Building

4 Ruby on Rails applications for NIS2 services:
1. **Services** - Service catalog
2. **Events** - Event management
3. **News** - News blog
4. **Academy** - Educational platform

**Tech Stack**: Ruby on Rails + HTMX + Supabase + Tailwind CSS (NO JavaScript frameworks!)

---

## ⚡ Quick Setup (5 Steps)

### 1. Prerequisites

```bash
# Check you have Ruby 3.2+
ruby --version

# Check you have Rails 7.1+
rails --version

# If not, install:
gem install rails
```

### 2. Initialize Apps

```bash
# Navigate to project
cd nis2-apps

# Run initialization script
./scripts/init-apps.sh
```

This creates 4 Rails apps with Supabase integration, HTMX, Tailwind CSS, and RSpec testing.

### 3. Configure Supabase

Get your Supabase credentials from https://supabase.com

```bash
# Configure each app
cd services
nano .env  # Add your Supabase credentials

cd ../events
nano .env

cd ../news
nano .env

cd ../academy
nano .env
```

Required environment variables:
```bash
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_DATABASE_URL=postgresql://...
SUPABASE_SCHEMA=nis2_services  # or events, news, academy
```

### 4. Setup Databases

```bash
# From nis2-apps root
./scripts/setup-databases.sh
```

### 5. Start Development Servers

```bash
./scripts/dev-servers.sh
```

Or manually:
```bash
cd services && rails server -p 3001 &
cd events && rails server -p 3002 &
cd news && rails server -p 3003 &
cd academy && rails server -p 3004 &
```

### 6. Verify

Open in browser:
- Services: http://localhost:3001
- Events: http://localhost:3002
- News: http://localhost:3003
- Academy: http://localhost:3004

You should see the welcome pages with HTMX and Tailwind CSS!

---

## 🚀 Development Workflow

### Local Development

```bash
# Start working in /home/gautama/dev/
mkdir -p /home/gautama/dev
cd /home/gautama/dev

# Link or clone your apps
ln -s /path/to/nis2-apps/services nis2-services
ln -s /path/to/nis2-apps/events nis2-events
ln -s /path/to/nis2-apps/news nis2-news
ln -s /path/to/nis2-apps/academy nis2-academy

# Make changes
cd nis2-services
# Edit code, test locally

# Commit and push
git add .
git commit -m "feat: Add feature"
git push origin feature-branch
```

### Deploy to Staging (Gautama + Tailscale)

```bash
# Merge to staging branch
git checkout staging
git merge feature-branch
git push origin staging

# Auto-deploys to Gautama!
# Access via Tailscale: https://services.nis2.vulcan.lan
```

### Deploy to Production (VPS)

```bash
# Merge to main
git checkout main
git merge staging
git push origin main

# Run deployment script
./deploy-production.sh

# Or manually deploy via SSH
ssh deploy@your-vps
cd /home/deploy/nis2-apps
git pull
docker-compose -f docker-compose.prod.yml up -d --build
```

---

## 📁 Key Files

| File | Purpose |
|------|---------|
| `scripts/init-apps.sh` | Initialize all 4 apps |
| `scripts/setup-databases.sh` | Setup Supabase databases |
| `scripts/dev-servers.sh` | Start all development servers |
| `docs/SETUP.md` | Detailed setup instructions |
| `docs/DEVELOPMENT_WORKFLOW.md` | Complete development workflow |
| `docs/DEPLOYMENT.md` | Deployment guide |

---

## 🔧 Common Tasks

### Run Tests

```bash
cd services
bundle exec rspec
```

### Add a New Feature

```bash
# Generate model
rails generate model Service name:string description:text

# Generate controller
rails generate controller Services index show

# Run migration
rails db:migrate

# Create views with HTMX (see docs/HTMX_PATTERNS.md)
```

### Sync to Staging

```bash
./sync-to-staging.sh services
```

---

## 🎓 Next Steps

1. **Read the Architecture**: [docs/md/NIS2_APPS_ARCHITECTURE.md](../docs/md/NIS2_APPS_ARCHITECTURE.md)
2. **Setup Complete Workflow**: [docs/DEVELOPMENT_WORKFLOW.md](docs/DEVELOPMENT_WORKFLOW.md)
3. **Deploy to Staging**: [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)
4. **Learn HTMX Patterns**: docs/HTMX_PATTERNS.md (coming soon)

---

## 🆘 Troubleshooting

### App Won't Start

```bash
# Check logs
cd services
tail -f log/development.log

# Check database connection
rails console
> ActiveRecord::Base.connection.execute("SELECT 1")
```

### Port Already in Use

```bash
# Find and kill process
lsof -i :3001
kill -9 <PID>
```

### Database Connection Error

```bash
# Verify Supabase credentials
cat services/.env | grep SUPABASE

# Test connection
psql $SUPABASE_DATABASE_URL -c "SELECT 1"
```

---

## 📚 Documentation

- **[Architecture](../docs/md/NIS2_APPS_ARCHITECTURE.md)** - Complete system architecture
- **[Setup Guide](docs/SETUP.md)** - Detailed setup instructions
- **[Development Workflow](docs/DEVELOPMENT_WORKFLOW.md)** - Complete development workflow from local to production
- **[Deployment Guide](docs/DEPLOYMENT.md)** - Deploy to staging and production

---

## ✅ Checklist

- [x] Ruby 3.2+ installed
- [x] Rails 7.1+ installed
- [x] Supabase account created
- [x] Apps initialized
- [x] Databases configured
- [x] Development servers running
- [x] Can access all apps at localhost:300X

**You're ready to start developing!** 🎉

---

**Questions?** Check the [full documentation](docs/SETUP.md) or open an issue.

**Last Updated**: 2025-11-13
