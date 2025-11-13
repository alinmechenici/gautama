# NIS2 Applications

Monorepo for 4 Ruby on Rails + HTMX + Supabase applications for NIS2 services.

## 🎯 Applications

1. **Services** (`/services`) - Service catalog and offerings
2. **Events** (`/events`) - Event management and registration
3. **News** (`/news`) - Blog platform for NIS2 updates
4. **Academy** (`/academy`) - Educational platform and courses

## 🛠️ Tech Stack

- **Backend**: Ruby 3.2+, Rails 7.1+
- **Database**: Supabase (PostgreSQL)
- **Frontend**: HTMX 1.9+, Tailwind CSS
- **No JavaScript**: Pure HTMX + CSS only
- **Containers**: Podman/Docker
- **CI/CD**: GitHub Actions

## 🚀 Quick Start

### Prerequisites

```bash
# Install Ruby 3.2+
ruby --version

# Install Rails 7.1+
gem install rails

# Install PostgreSQL client
psql --version
```

### Setup

```bash
# 1. Initialize all apps
./scripts/init-apps.sh

# 2. Configure Supabase credentials
# Edit .env files in each app directory

# 3. Setup databases
./scripts/setup-databases.sh

# 4. Start development servers
./scripts/dev-servers.sh
```

## 📁 Structure

```
nis2-apps/
├── services/          # NIS2 Services app (port 3001)
├── events/            # NIS2 Events app (port 3002)
├── news/              # NIS2 News blog (port 3003)
├── academy/           # NIS2 Academy (port 3004)
├── shared/            # Shared code and configs
├── infrastructure/    # Deployment configs
└── docs/              # Documentation
```

## 🌐 Environments

| Environment | Access | Database |
|------------|--------|----------|
| **Development** | `localhost:300X` | Supabase Dev |
| **Testing** | CI/CD only | Supabase Test |
| **Staging** | `*.nis2.vulcan.lan` (Tailscale) | Supabase Staging |
| **Production** | `*.nis2.example.com` | Supabase Production |

## 📚 Documentation

- [Architecture](../docs/md/NIS2_APPS_ARCHITECTURE.md) - Complete architecture guide
- [Setup Guide](docs/SETUP.md) - Detailed setup instructions
- [Development](docs/DEVELOPMENT.md) - Development workflow
- [Deployment](docs/DEPLOYMENT.md) - Deployment procedures
- [HTMX Patterns](docs/HTMX_PATTERNS.md) - HTMX usage patterns

## 🔧 Development

### Start individual app

```bash
cd services
bin/rails server -p 3001
```

### Run tests

```bash
cd services
bundle exec rspec
```

### Docker development

```bash
docker-compose up
```

## 🚢 Deployment

### Staging (Gautama + Tailscale)

```bash
# Deploy via NixOS
cd /etc/nixos
sudo nixos-rebuild switch --flake '.#vulcan'
```

### Production (VPS)

```bash
# Deploy via Ansible
cd infrastructure/production/ansible
ansible-playbook -i inventory.yml playbook.yml
```

## 🔐 Secrets Management

- **Development**: `.env` files (gitignored)
- **Staging**: SOPS secrets in Gautama
- **Production**: Environment variables on VPS

## 📊 Monitoring

- **Staging**: Prometheus + Grafana on Gautama
- **Production**: VPS monitoring + Supabase dashboard

## 🤝 Contributing

1. Create feature branch
2. Make changes
3. Run tests: `bundle exec rspec`
4. Create pull request

## 📝 License

Proprietary - All Rights Reserved
