# NIS2 Development Workflow

Complete guide for developing locally and deploying through all stages.

---

## 📁 Directory Structure

### Local Development

```
/home/gautama/dev/
├── nis2-services/        # Services app development
├── nis2-events/          # Events app development
├── nis2-news/            # News app development
└── nis2-academy/         # Academy app development
```

### Deployment Locations

| Stage | Location | Access |
|-------|----------|--------|
| **Development** | `/home/gautama/dev/nis2-*` | Local |
| **Testing** | CI/CD (GitHub Actions) | Automated |
| **Staging** | `/var/lib/nis2-apps/*` on Gautama | Tailscale |
| **Production** | `/home/deploy/nis2-apps/*` on VPS | Internet |

---

## 🔄 Complete Workflow Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                    LOCAL DEVELOPMENT                          │
│              /home/gautama/dev/nis2-*/                        │
│                                                               │
│  1. Code changes                                             │
│  2. Test locally                                             │
│  3. Commit to git                                            │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     │ git push origin feature-branch
                     ▼
┌──────────────────────────────────────────────────────────────┐
│                     GIT REPOSITORY                            │
│                 (GitHub/Gitea/GitLab)                        │
│                                                               │
│  - Feature branches                                          │
│  - Pull requests/Merge requests                              │
│  - CI/CD triggers                                            │
└──┬────────────────────────────┬──────────────────────────────┘
   │                            │
   │ PR merged to 'staging'     │ PR merged to 'main'
   ▼                            ▼
┌──────────────────────┐    ┌──────────────────────┐
│  STAGING DEPLOYMENT   │    │ PRODUCTION DEPLOYMENT │
│  (Gautama/Tailscale)  │    │    (VPS/Internet)     │
│                       │    │                       │
│  Auto-deploy from     │    │  Manual deploy or     │
│  'staging' branch     │    │  auto from 'main'     │
└───────────────────────┘    └───────────────────────┘
```

---

## 🏗️ Setup Development Environment

### Step 1: Create Development Directories

```bash
# Create development workspace
mkdir -p /home/gautama/dev
cd /home/gautama/dev

# Clone each app repository
git clone https://github.com/yourorg/nis2-services.git
git clone https://github.com/yourorg/nis2-events.git
git clone https://github.com/yourorg/nis2-news.git
git clone https://github.com/yourorg/nis2-academy.git

# Or if using monorepo:
git clone https://github.com/yourorg/nis2-apps.git
cd nis2-apps
ln -s $PWD/services /home/gautama/dev/nis2-services
ln -s $PWD/events /home/gautama/dev/nis2-events
ln -s $PWD/news /home/gautama/dev/nis2-news
ln -s $PWD/academy /home/gautama/dev/nis2-academy
```

### Step 2: Configure Each App

```bash
# For each app, set up environment
cd /home/gautama/dev/nis2-services
cp .env.example .env
nano .env  # Add your Supabase dev credentials

# Install dependencies
bundle install

# Setup database
rails db:create db:migrate db:seed

# Start development server
rails server -p 3001
```

Repeat for all 4 apps.

---

## 📝 Daily Development Workflow

### 1. Start Local Servers

**Option A: Manual Start**

```bash
# Terminal 1
cd /home/gautama/dev/nis2-services
rails server -p 3001

# Terminal 2
cd /home/gautama/dev/nis2-events
rails server -p 3002

# Terminal 3
cd /home/gautama/dev/nis2-news
rails server -p 3003

# Terminal 4
cd /home/gautama/dev/nis2-academy
rails server -p 3004
```

**Option B: tmux Script**

```bash
#!/bin/bash
# /home/gautama/dev/start-all.sh

tmux new-session -d -s nis2-dev

# Services
tmux send-keys -t nis2-dev "cd /home/gautama/dev/nis2-services && rails server -p 3001" Enter
tmux split-window -t nis2-dev -h

# Events
tmux send-keys -t nis2-dev "cd /home/gautama/dev/nis2-events && rails server -p 3002" Enter
tmux split-window -t nis2-dev -v

# News
tmux send-keys -t nis2-dev "cd /home/gautama/dev/nis2-news && rails server -p 3003" Enter
tmux split-window -t nis2-dev -h

# Academy
tmux send-keys -t nis2-dev "cd /home/gautama/dev/nis2-academy && rails server -p 3004" Enter

tmux attach -t nis2-dev
```

Usage:
```bash
chmod +x /home/gautama/dev/start-all.sh
/home/gautama/dev/start-all.sh
```

**Option C: systemd User Services**

Create `~/.config/systemd/user/nis2-services.service`:

```ini
[Unit]
Description=NIS2 Services Development Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/home/gautama/dev/nis2-services
ExecStart=/usr/bin/env rails server -p 3001
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
```

Repeat for all apps, then:

```bash
systemctl --user enable nis2-services
systemctl --user start nis2-services
systemctl --user status nis2-services
```

### 2. Make Changes

```bash
cd /home/gautama/dev/nis2-services

# Create feature branch
git checkout -b feature/add-service-catalog

# Make your changes
# Edit files, add features, etc.

# Run tests
bundle exec rspec

# Commit changes
git add .
git commit -m "feat: Add service catalog page"
```

### 3. Test Locally

```bash
# Access in browser
open http://localhost:3001

# Run full test suite
bundle exec rspec

# Check code quality
rubocop
```

### 4. Push to Repository

```bash
# Push feature branch
git push origin feature/add-service-catalog

# Create pull request (via GitHub/Gitea web interface)
# Request review from team
```

---

## 🚀 Deployment to Staging (Gautama)

### Automatic Deployment

**Setup Git Hook on Gautama:**

```bash
# On Gautama
cd /var/lib/nis2-apps

# Create post-receive hook
cat > .git/hooks/post-receive <<'EOF'
#!/bin/bash
# Auto-deploy to staging when 'staging' branch is pushed

while read oldrev newrev refname; do
    branch=$(git rev-parse --symbolic --abbrev-ref $refname)

    if [ "$branch" = "staging" ]; then
        echo "🚀 Deploying to staging..."

        # Update code
        git --work-tree=/var/lib/nis2-apps --git-dir=/var/lib/nis2-apps/.git checkout -f staging

        # Reload containers (NixOS rebuild)
        sudo systemctl restart quadlet-nis2-services
        sudo systemctl restart quadlet-nis2-events
        sudo systemctl restart quadlet-nis2-news
        sudo systemctl restart quadlet-nis2-academy

        echo "✅ Staging deployment complete!"
    fi
done
EOF

chmod +x .git/hooks/post-receive
```

**Deploy from Local:**

```bash
# On your dev machine
cd /home/gautama/dev/nis2-services

# Merge feature to staging branch
git checkout staging
git merge feature/add-service-catalog

# Push to staging
git push origin staging

# This triggers auto-deployment to Gautama!
```

### Manual Deployment to Staging

```bash
# SSH to Gautama
ssh vulcan

# Pull latest from staging branch
cd /var/lib/nis2-apps/services
git pull origin staging

# Restart container
sudo systemctl restart quadlet-nis2-services

# Check status
sudo systemctl status quadlet-nis2-services

# View logs
sudo journalctl -u quadlet-nis2-services -f
```

### Verify Staging Deployment

```bash
# From machine connected to Tailscale
curl https://services.nis2.vulcan.lan/health

# Open in browser
open https://services.nis2.vulcan.lan
```

---

## 🌍 Deployment to Production (VPS)

### Preparation

```bash
# Merge staging to main (after testing)
git checkout main
git merge staging

# Tag release
git tag -a v1.0.0 -m "Release version 1.0.0"

# Push to repository
git push origin main
git push origin --tags
```

### Automatic Deployment (GitHub Actions)

Create `.github/workflows/deploy-production.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Deploy to VPS
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USERNAME }}
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            cd /home/deploy/nis2-apps
            git pull origin main
            docker-compose -f docker-compose.prod.yml build
            docker-compose -f docker-compose.prod.yml up -d
            docker-compose -f docker-compose.prod.yml exec -T services bundle exec rails db:migrate
            docker-compose -f docker-compose.prod.yml exec -T events bundle exec rails db:migrate
            docker-compose -f docker-compose.prod.yml exec -T news bundle exec rails db:migrate
            docker-compose -f docker-compose.prod.yml exec -T academy bundle exec rails db:migrate
```

### Manual Deployment to Production

```bash
# SSH to VPS
ssh deploy@your-vps-ip

# Pull latest code
cd /home/deploy/nis2-apps
git pull origin main

# Rebuild and restart containers
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d

# Run migrations
docker-compose -f docker-compose.prod.yml exec services bundle exec rails db:migrate
docker-compose -f docker-compose.prod.yml exec events bundle exec rails db:migrate
docker-compose -f docker-compose.prod.yml exec news bundle exec rails db:migrate
docker-compose -f docker-compose.prod.yml exec academy bundle exec rails db:migrate

# Verify deployment
docker ps
curl https://services.nis2.example.com/health
```

### Deployment Script

Create `/home/gautama/dev/deploy-production.sh`:

```bash
#!/bin/bash
# Deploy to production VPS

set -e

VPS_HOST="your-vps-ip"
VPS_USER="deploy"

echo "🚀 Deploying to production..."

# Ensure we're on main branch
if [ $(git branch --show-current) != "main" ]; then
    echo "❌ Error: Must be on 'main' branch"
    exit 1
fi

# Ensure working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ Error: Working directory not clean"
    exit 1
fi

# Push to repository
echo "📤 Pushing to repository..."
git push origin main

# Deploy to VPS
echo "🚢 Deploying to VPS..."
ssh $VPS_USER@$VPS_HOST << 'ENDSSH'
    cd /home/deploy/nis2-apps
    git pull origin main

    # Rebuild containers
    docker-compose -f docker-compose.prod.yml build

    # Run migrations
    docker-compose -f docker-compose.prod.yml run --rm services bundle exec rails db:migrate
    docker-compose -f docker-compose.prod.yml run --rm events bundle exec rails db:migrate
    docker-compose -f docker-compose.prod.yml run --rm news bundle exec rails db:migrate
    docker-compose -f docker-compose.prod.yml run --rm academy bundle exec rails db:migrate

    # Restart services
    docker-compose -f docker-compose.prod.yml up -d

    # Health check
    sleep 10
    curl -f https://services.nis2.example.com/health || exit 1
    curl -f https://events.nis2.example.com/health || exit 1
    curl -f https://news.nis2.example.com/health || exit 1
    curl -f https://academy.nis2.example.com/health || exit 1
ENDSSH

echo "✅ Production deployment complete!"
echo "🔗 Verify at:"
echo "   - https://services.nis2.example.com"
echo "   - https://events.nis2.example.com"
echo "   - https://news.nis2.example.com"
echo "   - https://academy.nis2.example.com"
```

Usage:
```bash
chmod +x /home/gautama/dev/deploy-production.sh
/home/gautama/dev/deploy-production.sh
```

---

## 🔄 Sync Scripts

### Sync Local to Staging

Create `/home/gautama/dev/sync-to-staging.sh`:

```bash
#!/bin/bash
# Rsync local changes to Gautama staging

set -e

APP=$1
if [ -z "$APP" ]; then
    echo "Usage: $0 <app-name>"
    echo "Example: $0 services"
    exit 1
fi

LOCAL_DIR="/home/gautama/dev/nis2-$APP"
REMOTE_HOST="vulcan"
REMOTE_DIR="/var/lib/nis2-apps/$APP"

echo "📦 Syncing $APP to staging..."

# Rsync with exclusions
rsync -avz --delete \
    --exclude '.git' \
    --exclude 'tmp/' \
    --exclude 'log/' \
    --exclude '.env' \
    --exclude 'node_modules/' \
    $LOCAL_DIR/ $REMOTE_HOST:$REMOTE_DIR/

# Restart container on Gautama
ssh $REMOTE_HOST "sudo systemctl restart quadlet-nis2-$APP"

echo "✅ $APP synced to staging!"
```

Usage:
```bash
chmod +x /home/gautama/dev/sync-to-staging.sh
./sync-to-staging.sh services
```

### Watch and Auto-Sync (Development Mode)

Create `/home/gautama/dev/watch-and-sync.sh`:

```bash
#!/bin/bash
# Watch for changes and auto-sync to staging

APP=$1
if [ -z "$APP" ]; then
    echo "Usage: $0 <app-name>"
    exit 1
fi

LOCAL_DIR="/home/gautama/dev/nis2-$APP"

echo "👀 Watching $APP for changes..."

# Install fswatch if not present
# apt install fswatch

fswatch -o $LOCAL_DIR | while read change; do
    echo "📝 Changes detected, syncing..."
    ./sync-to-staging.sh $APP
done
```

---

## 📊 Complete Workflow Summary

### Development → Staging → Production

```
1. LOCAL DEVELOPMENT
   Location: /home/gautama/dev/nis2-*
   ├─ Edit code
   ├─ Test locally (localhost:300X)
   ├─ Commit to feature branch
   └─ Push to repository

2. CODE REVIEW
   ├─ Create pull request
   ├─ Team review
   └─ Automated tests run

3. STAGING DEPLOYMENT
   Location: /var/lib/nis2-apps/* on Gautama
   ├─ Merge PR to 'staging' branch
   ├─ Auto-deploy to Gautama (or manual)
   ├─ Test via Tailscale (*.nis2.vulcan.lan)
   └─ Verify functionality

4. PRODUCTION DEPLOYMENT
   Location: /home/deploy/nis2-apps/* on VPS
   ├─ Merge 'staging' to 'main'
   ├─ Tag release version
   ├─ Deploy to VPS (auto or manual)
   ├─ Run migrations
   └─ Verify via public URLs (*.nis2.example.com)
```

---

## 🔧 Troubleshooting

### Changes Not Appearing

```bash
# Check if code synced
ssh vulcan "ls -la /var/lib/nis2-apps/services"

# Check container status
ssh vulcan "sudo systemctl status quadlet-nis2-services"

# View logs
ssh vulcan "sudo journalctl -u quadlet-nis2-services -f"

# Force restart
ssh vulcan "sudo systemctl restart quadlet-nis2-services"
```

### Database Out of Sync

```bash
# Run migrations on staging
ssh vulcan "cd /var/lib/nis2-apps/services && rails db:migrate"

# Run migrations on production
ssh deploy@vps "cd /home/deploy/nis2-apps && docker-compose -f docker-compose.prod.yml exec services bundle exec rails db:migrate"
```

---

## 📚 Quick Reference

### Common Commands

```bash
# Start local development
cd /home/gautama/dev/nis2-services
rails server -p 3001

# Sync to staging
./sync-to-staging.sh services

# Deploy to production
./deploy-production.sh

# Check staging status (via Tailscale)
curl https://services.nis2.vulcan.lan/health

# Check production status
curl https://services.nis2.example.com/health
```

---

**Last Updated**: 2025-11-13
