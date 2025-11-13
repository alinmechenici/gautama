# NIS2 Applications Setup Guide

Complete setup instructions for all 4 NIS2 Rails applications.

---

## 📋 Prerequisites

### Required Software

```bash
# Ruby 3.2+
ruby --version  # Should be 3.2.0 or higher

# Rails 7.1+
rails --version  # Should be 7.1.0 or higher

# PostgreSQL client (for Supabase)
psql --version

# Git
git --version

# Optional: Docker/Podman for containerization
docker --version
# or
podman --version
```

### Supabase Account

1. Create account at https://supabase.com
2. Create 3 projects:
   - `nis2-dev` (Development)
   - `nis2-staging` (Staging)
   - `nis2-prod` (Production)
3. Note the credentials for each project

---

## 🚀 Quick Setup

### 1. Clone Repository

```bash
git clone https://github.com/yourorg/nis2-apps.git
cd nis2-apps
```

### 2. Initialize All Apps

```bash
chmod +x scripts/*.sh
./scripts/init-apps.sh
```

This creates 4 Rails applications with:
- Supabase integration
- HTMX configuration
- Tailwind CSS
- RSpec testing
- Docker configuration

### 3. Configure Supabase

For each app, edit the `.env` file:

```bash
# Example for services app
cd services
nano .env
```

Add your Supabase credentials:

```bash
# Supabase Configuration
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_DATABASE_URL=postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres
SUPABASE_SCHEMA=nis2_services

# Rails
RAILS_ENV=development
SECRET_KEY_BASE=$(rails secret)

# App-specific
PORT=3001
```

Repeat for all 4 apps:
- `services` - port 3001, schema `nis2_services`
- `events` - port 3002, schema `nis2_events`
- `news` - port 3003, schema `nis2_news`
- `academy` - port 3004, schema `nis2_academy`

### 4. Setup Databases

```bash
./scripts/setup-databases.sh
```

This will:
- Create schemas in Supabase
- Run migrations
- Seed initial data

### 5. Start Development Servers

```bash
./scripts/dev-servers.sh
```

Or manually:

```bash
# Terminal 1
cd services && bin/rails server -p 3001

# Terminal 2
cd events && bin/rails server -p 3002

# Terminal 3
cd news && bin/rails server -p 3003

# Terminal 4
cd academy && bin/rails server -p 3004
```

### 6. Verify Setup

Open in browser:
- Services: http://localhost:3001
- Events: http://localhost:3002
- News: http://localhost:3003
- Academy: http://localhost:3004

Each should show the welcome page.

---

## 🗄️ Database Schema Setup

### Create Schemas in Supabase

For each app, create a dedicated PostgreSQL schema:

```sql
-- In Supabase SQL Editor

-- Services schema
CREATE SCHEMA IF NOT EXISTS nis2_services;

-- Events schema
CREATE SCHEMA IF NOT EXISTS nis2_events;

-- News schema
CREATE SCHEMA IF NOT EXISTS nis2_news;

-- Academy schema
CREATE SCHEMA IF NOT EXISTS nis2_academy;
```

### Grant Permissions

```sql
-- Grant access to postgres role
GRANT ALL ON SCHEMA nis2_services TO postgres;
GRANT ALL ON SCHEMA nis2_events TO postgres;
GRANT ALL ON SCHEMA nis2_news TO postgres;
GRANT ALL ON SCHEMA nis2_academy TO postgres;
```

---

## 🧪 Testing Setup

### Install Test Dependencies

Already included in `bundle install` from init script.

### Run Tests

```bash
cd services
bundle exec rspec

# Or for all apps
for app in services events news academy; do
  cd $app
  bundle exec rspec
  cd ..
done
```

---

## 🐳 Docker Setup (Optional)

### Build Images

```bash
# Build individual app
cd services
docker build -t nis2-services:dev .

# Or use docker-compose for all apps
docker-compose build
```

### Run with Docker Compose

```bash
docker-compose up

# Or in background
docker-compose up -d
```

Apps will be available at the same ports (3001-3004).

---

## 🔐 Secrets Management

### Development

Use `.env` files (gitignored):

```bash
services/.env
events/.env
news/.env
academy/.env
```

### Staging (Gautama)

Use SOPS secrets:

```bash
cd /etc/nixos
sops secrets.yaml

# Add secrets for each app:
# nis2-services-supabase-url
# nis2-services-supabase-key
# nis2-services-database-url
# nis2-services-secret-key-base
# (repeat for events, news, academy)
```

### Production (VPS)

Use environment variables on the VPS:

```bash
# In /etc/environment or via Docker Compose
export SUPABASE_URL=...
export SUPABASE_ANON_KEY=...
# etc.
```

---

## 📝 Creating Your First Feature

### Example: Add a Service in NIS2 Services App

```bash
cd services

# Generate model
rails generate model Service name:string description:text category:string price_range:string

# Run migration
rails db:migrate

# Generate controller
rails generate controller Services index show new create

# Update routes
# config/routes.rb
resources :services

# Create views with HTMX
# app/views/services/index.html.erb
```

Example HTMX view:

```erb
<div class="container mx-auto">
  <h1 class="text-3xl font-bold mb-6">Our Services</h1>

  <div id="services-list">
    <%= render @services %>
  </div>

  <button
    hx-get="<%= services_path(page: @next_page) %>"
    hx-target="#services-list"
    hx-swap="beforeend"
    class="btn btn-primary">
    Load More
  </button>
</div>
```

---

## 🚢 Deployment Setup

### Staging (Gautama)

See [DEPLOYMENT.md](DEPLOYMENT.md) for full instructions.

Quick version:

```bash
# On Gautama
cd /etc/nixos

# Add NIS2 modules
nano hosts/vulcan/default.nix
# Add: ../../modules/containers/nis2-services-quadlet.nix

# Add secrets to SOPS
sops secrets.yaml

# Rebuild
sudo nixos-rebuild switch --flake '.#vulcan'
```

### Production (VPS)

See [DEPLOYMENT.md](DEPLOYMENT.md) for Ansible playbooks and deployment procedures.

---

## 🔧 Troubleshooting

### App Won't Start

```bash
# Check logs
cd services
tail -f log/development.log

# Check database connection
rails console
> ActiveRecord::Base.connection.execute("SELECT 1")
```

### Database Connection Error

```bash
# Verify credentials
cat .env | grep SUPABASE

# Test connection
psql $SUPABASE_DATABASE_URL -c "SELECT 1"
```

### HTMX Not Working

1. Check browser console for errors
2. Verify HTMX is loaded: `console.log(htmx)`
3. Check network tab for AJAX requests

### Port Already in Use

```bash
# Find process using port
lsof -i :3001

# Kill process
kill -9 <PID>
```

---

## 📚 Next Steps

- [Development Workflow](DEVELOPMENT.md) - Daily development practices
- [HTMX Patterns](HTMX_PATTERNS.md) - Common HTMX patterns
- [Deployment Guide](DEPLOYMENT.md) - Deploy to staging/production
- [Architecture](../docs/md/NIS2_APPS_ARCHITECTURE.md) - System architecture

---

## 🆘 Getting Help

- Check logs: `tail -f app/log/development.log`
- Rails console: `rails console`
- Database console: `rails dbconsole`
- Run tests: `bundle exec rspec`

---

**Last Updated**: 2025-11-13
