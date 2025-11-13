# NIS2 Applications Architecture

**Purpose**: Complete architecture and setup guide for 4 Ruby on Rails + HTMX applications using Supabase.

**Last Updated**: 2025-11-13
**Stack**: Ruby on Rails 7.1+, HTMX 1.9+, Supabase, CSS (No JS frameworks)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Applications](#applications)
- [Environment Strategy](#environment-strategy)
- [Development Setup](#development-setup)
- [Deployment Architecture](#deployment-architecture)
- [Database Strategy](#database-strategy)

---

## 🌐 Overview

Four Ruby on Rails applications for NIS2 (Network and Information Security) services:

1. **NIS2 Services** - Service catalog and offerings
2. **NIS2 Events** - Event management and registration
3. **NIS2 News** - Blog platform for NIS2 updates
4. **NIS2 Academy** - Educational platform and courses

**Design Philosophy**:
- **Simple**: HTMX + CSS only, no JavaScript frameworks
- **Fast**: Server-side rendering, minimal client payload
- **Secure**: Tailscale for internal environments
- **Scalable**: Supabase for database, easy horizontal scaling

---

## 🛠️ Technology Stack

### Backend
- **Ruby**: 3.2+
- **Rails**: 7.1+ (API + Views mode)
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Devise + Supabase Auth (optional)
- **Background Jobs**: Sidekiq (for production)

### Frontend
- **HTMX**: 1.9+ (for dynamic interactions)
- **CSS**: Tailwind CSS (utility-first, no JS)
- **Forms**: Rails helpers + HTMX
- **No JavaScript frameworks** (React, Vue, etc.)

### Infrastructure
- **Development**: Local Rails servers + Supabase project
- **Testing**: RSpec + Capybara
- **Staging**: Tailscale-accessed containers on Gautama
- **Production**: Vultr/DigitalOcean VPS

---

## 📁 Project Structure

### Monorepo Layout

```
nis2-apps/
├── README.md
├── .gitignore
├── docker-compose.yml           # Local development
├── docker-compose.staging.yml   # Staging on Gautama
├── docker-compose.prod.yml      # Production deployment
│
├── shared/                      # Shared code and configs
│   ├── lib/                     # Shared Ruby modules
│   ├── config/                  # Shared configurations
│   │   ├── supabase.rb
│   │   └── htmx_helpers.rb
│   └── views/                   # Shared partials
│       ├── layouts/
│       └── components/
│
├── services/                    # NIS2 Services App
│   ├── Gemfile
│   ├── Gemfile.lock
│   ├── config/
│   │   ├── database.yml
│   │   ├── environments/
│   │   │   ├── development.rb
│   │   │   ├── test.rb
│   │   │   ├── staging.rb
│   │   │   └── production.rb
│   │   └── supabase.yml
│   ├── app/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── views/
│   │   ├── helpers/
│   │   └── assets/
│   ├── db/
│   │   ├── migrate/
│   │   └── seeds.rb
│   ├── spec/
│   ├── Dockerfile
│   └── .env.example
│
├── events/                      # NIS2 Events App
│   └── [same structure as services]
│
├── news/                        # NIS2 News Blog
│   └── [same structure as services]
│
├── academy/                     # NIS2 Academy
│   └── [same structure as services]
│
├── infrastructure/              # Deployment configurations
│   ├── gautama/                 # Gautama (staging) deployment
│   │   ├── quadlet/
│   │   │   ├── nis2-services.nix
│   │   │   ├── nis2-events.nix
│   │   │   ├── nis2-news.nix
│   │   │   └── nis2-academy.nix
│   │   └── nginx/
│   │       └── nis2-apps.conf
│   │
│   └── production/              # VPS deployment
│       ├── ansible/             # Ansible playbooks
│       │   ├── playbook.yml
│       │   └── roles/
│       ├── docker/
│       │   └── docker-compose.yml
│       └── nginx/
│           └── nis2-apps.conf
│
└── docs/                        # Documentation
    ├── SETUP.md
    ├── DEVELOPMENT.md
    ├── DEPLOYMENT.md
    └── API.md
```

---

## 🎯 Applications

### 1. NIS2 Services (`/services`)

**Purpose**: Service catalog, offerings, and customer inquiries.

**Features**:
- Service listing with categories
- Service detail pages
- Contact forms (HTMX-powered)
- Service comparison tool
- Quote requests

**Database Schema**:
```sql
-- Services
services (
  id uuid PRIMARY KEY,
  name text NOT NULL,
  description text,
  category text,
  price_range text,
  created_at timestamptz,
  updated_at timestamptz
)

-- Inquiries
inquiries (
  id uuid PRIMARY KEY,
  service_id uuid REFERENCES services(id),
  name text NOT NULL,
  email text NOT NULL,
  message text,
  status text DEFAULT 'new',
  created_at timestamptz
)
```

**URLs**:
- Dev: `http://localhost:3001`
- Staging: `https://services.nis2.vulcan.lan` (Tailscale)
- Production: `https://services.nis2.example.com`

---

### 2. NIS2 Events (`/events`)

**Purpose**: Event management, registration, and attendee tracking.

**Features**:
- Event calendar (HTMX-powered)
- Event registration forms
- Attendee management
- Email notifications
- Event search and filtering

**Database Schema**:
```sql
-- Events
events (
  id uuid PRIMARY KEY,
  title text NOT NULL,
  description text,
  event_date timestamptz NOT NULL,
  location text,
  capacity integer,
  status text DEFAULT 'upcoming',
  created_at timestamptz,
  updated_at timestamptz
)

-- Registrations
registrations (
  id uuid PRIMARY KEY,
  event_id uuid REFERENCES events(id),
  attendee_name text NOT NULL,
  attendee_email text NOT NULL,
  status text DEFAULT 'confirmed',
  registered_at timestamptz
)
```

**URLs**:
- Dev: `http://localhost:3002`
- Staging: `https://events.nis2.vulcan.lan` (Tailscale)
- Production: `https://events.nis2.example.com`

---

### 3. NIS2 News (`/news`)

**Purpose**: Blog platform for NIS2 news, updates, and articles.

**Features**:
- Article listing with pagination
- Article detail pages
- Categories and tags
- Author profiles
- RSS feed
- Comment system (HTMX)

**Database Schema**:
```sql
-- Articles
articles (
  id uuid PRIMARY KEY,
  title text NOT NULL,
  slug text UNIQUE NOT NULL,
  content text,
  excerpt text,
  author_id uuid,
  published_at timestamptz,
  status text DEFAULT 'draft',
  created_at timestamptz,
  updated_at timestamptz
)

-- Categories
categories (
  id uuid PRIMARY KEY,
  name text NOT NULL,
  slug text UNIQUE NOT NULL
)

-- Comments
comments (
  id uuid PRIMARY KEY,
  article_id uuid REFERENCES articles(id),
  author_name text NOT NULL,
  author_email text NOT NULL,
  content text,
  status text DEFAULT 'pending',
  created_at timestamptz
)
```

**URLs**:
- Dev: `http://localhost:3003`
- Staging: `https://news.nis2.vulcan.lan` (Tailscale)
- Production: `https://news.nis2.example.com`

---

### 4. NIS2 Academy (`/academy`)

**Purpose**: Educational platform with courses, lessons, and certifications.

**Features**:
- Course catalog
- Lesson viewer (video/text)
- Progress tracking
- Quizzes and assessments
- Certificate generation
- User enrollment

**Database Schema**:
```sql
-- Courses
courses (
  id uuid PRIMARY KEY,
  title text NOT NULL,
  description text,
  difficulty text,
  duration_hours integer,
  price decimal,
  published boolean DEFAULT false,
  created_at timestamptz,
  updated_at timestamptz
)

-- Lessons
lessons (
  id uuid PRIMARY KEY,
  course_id uuid REFERENCES courses(id),
  title text NOT NULL,
  content text,
  lesson_order integer,
  video_url text,
  duration_minutes integer
)

-- Enrollments
enrollments (
  id uuid PRIMARY KEY,
  user_id uuid,
  course_id uuid REFERENCES courses(id),
  progress integer DEFAULT 0,
  completed boolean DEFAULT false,
  enrolled_at timestamptz
)

-- Progress
lesson_progress (
  id uuid PRIMARY KEY,
  enrollment_id uuid REFERENCES enrollments(id),
  lesson_id uuid REFERENCES lessons(id),
  completed boolean DEFAULT false,
  completed_at timestamptz
)
```

**URLs**:
- Dev: `http://localhost:3004`
- Staging: `https://academy.nis2.vulcan.lan` (Tailscale)
- Production: `https://academy.nis2.example.com`

---

## 🌍 Environment Strategy

### Development (Local)

**Access**: `http://localhost:300X`
**Database**: Supabase project (dev environment)
**Purpose**: Local development with hot reload

**Characteristics**:
- Rails server with live reload
- Local PostgreSQL or Supabase dev project
- Debug tools enabled
- No authentication required (or basic auth)
- Asset pipeline in development mode

### Testing (CI/CD)

**Access**: Automated tests only
**Database**: Supabase test project or local PostgreSQL
**Purpose**: Automated testing in CI/CD pipeline

**Characteristics**:
- RSpec + Capybara for integration tests
- Database is reset between tests
- Fast test suite (<5 minutes)
- Code coverage tracking

### Staging (Gautama - Tailscale)

**Access**: `https://[app].nis2.vulcan.lan` (Tailscale only)
**Database**: Supabase staging project
**Purpose**: Pre-production testing with production-like setup

**Characteristics**:
- Containerized (Podman Quadlet)
- step-ca certificates
- Production-like data (anonymized)
- Accessible only via Tailscale
- Prometheus monitoring

### Production (VPS)

**Access**: `https://[app].nis2.example.com`
**Database**: Supabase production project
**Purpose**: Live public-facing applications

**Characteristics**:
- Containerized with auto-restart
- Cloudflare CDN (optional)
- Backups configured
- Monitoring and alerting
- SSL/TLS with Let's Encrypt

---

## 🚀 Development Setup

### Prerequisites

```bash
# Ruby 3.2+
ruby --version  # 3.2.0 or higher

# Rails 7.1+
rails --version  # 7.1.0 or higher

# PostgreSQL client (for Supabase)
psql --version

# Supabase CLI (optional)
supabase --version
```

### Initial Setup

```bash
# 1. Clone repository
git clone https://github.com/yourorg/nis2-apps.git
cd nis2-apps

# 2. Install dependencies for each app
for app in services events news academy; do
  cd $app
  bundle install
  cd ..
done

# 3. Configure Supabase credentials
# Copy .env.example to .env for each app
for app in services events news academy; do
  cp $app/.env.example $app/.env
  # Edit $app/.env with your Supabase credentials
done

# 4. Setup databases
for app in services events news academy; do
  cd $app
  RAILS_ENV=development bin/rails db:create
  RAILS_ENV=development bin/rails db:migrate
  RAILS_ENV=development bin/rails db:seed
  cd ..
done

# 5. Start development servers (in separate terminals)
cd services && bin/rails server -p 3001
cd events && bin/rails server -p 3002
cd news && bin/rails server -p 3003
cd academy && bin/rails server -p 3004
```

### Docker Development

```bash
# Start all apps with docker-compose
docker-compose up

# Apps will be available at:
# - Services: http://localhost:3001
# - Events: http://localhost:3002
# - News: http://localhost:3003
# - Academy: http://localhost:3004
```

---

## 🏗️ Deployment Architecture

### Staging (Gautama with Tailscale)

```
┌─────────────────────────────────────────────────────────────┐
│                    TAILSCALE NETWORK                         │
│  (Only accessible via VPN)                                   │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│                     GAUTAMA HOST                             │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │              Nginx (Reverse Proxy)                  │    │
│  │  • services.nis2.vulcan.lan → localhost:3101      │    │
│  │  • events.nis2.vulcan.lan → localhost:3102        │    │
│  │  • news.nis2.vulcan.lan → localhost:3103          │    │
│  │  • academy.nis2.vulcan.lan → localhost:3104       │    │
│  └───┬────────────┬────────────┬────────────┬─────────┘    │
│      │            │            │            │               │
│  ┌───▼──────┐ ┌──▼──────┐ ┌───▼─────┐ ┌───▼──────┐        │
│  │Services  │ │Events   │ │News     │ │Academy   │        │
│  │Container │ │Container│ │Container│ │Container │        │
│  │Port 3101 │ │Port 3102│ │Port 3103│ │Port 3104 │        │
│  └──────────┘ └─────────┘ └─────────┘ └──────────┘        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
              Supabase (Staging)
```

### Production (Vultr/DigitalOcean)

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│              Cloudflare (Optional CDN)                       │
│  • DDoS Protection  • SSL/TLS  • Caching                    │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│                VPS (Vultr/DigitalOcean)                      │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │           Nginx (Reverse Proxy + SSL)               │    │
│  │  • services.nis2.example.com → localhost:3001     │    │
│  │  • events.nis2.example.com → localhost:3002       │    │
│  │  • news.nis2.example.com → localhost:3003         │    │
│  │  • academy.nis2.example.com → localhost:3004      │    │
│  └───┬────────────┬────────────┬────────────┬─────────┘    │
│      │            │            │            │               │
│  ┌───▼──────┐ ┌──▼──────┐ ┌───▼─────┐ ┌───▼──────┐        │
│  │Services  │ │Events   │ │News     │ │Academy   │        │
│  │Container │ │Container│ │Container│ │Container │        │
│  │Port 3001 │ │Port 3002│ │Port 3003│ │Port 3004 │        │
│  └──────────┘ └─────────┘ └─────────┘ └──────────┘        │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │                 Redis (Sidekiq)                     │    │
│  └────────────────────────────────────────────────────┘    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
              Supabase (Production)
```

---

## 🗄️ Database Strategy

### Supabase Setup

**Projects**:
- **Development**: `nis2-dev` (shared by all apps)
- **Staging**: `nis2-staging` (shared by all apps)
- **Production**: `nis2-prod` (shared by all apps)

**Schema Isolation**:
Each app uses its own PostgreSQL schema:
- Services: `nis2_services`
- Events: `nis2_events`
- News: `nis2_news`
- Academy: `nis2_academy`

**Connection Configuration**:
```yaml
# config/database.yml
production:
  adapter: postgresql
  url: <%= ENV['SUPABASE_DATABASE_URL'] %>
  schema_search_path: <%= ENV['SUPABASE_SCHEMA'] %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

**Environment Variables**:
```bash
# Services app
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_DATABASE_URL=postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres
SUPABASE_SCHEMA=nis2_services

# Events app
SUPABASE_SCHEMA=nis2_events

# News app
SUPABASE_SCHEMA=nis2_news

# Academy app
SUPABASE_SCHEMA=nis2_academy
```

### Migrations

```bash
# Create migration
bin/rails generate migration CreateServices

# Run migrations
RAILS_ENV=production bin/rails db:migrate

# Supabase automatically handles migrations via SQL migrations
```

---

## 📊 Port Allocation

| App | Dev | Staging | Production |
|-----|-----|---------|------------|
| **Services** | 3001 | 3101 | 3001 |
| **Events** | 3002 | 3102 | 3002 |
| **News** | 3003 | 3103 | 3003 |
| **Academy** | 3004 | 3104 | 3004 |

---

## 🔒 Security

### Tailscale Access (Dev/Staging)

- All staging apps accessible only via Tailscale VPN
- step-ca certificates for HTTPS
- No public exposure

### Production Security

- Let's Encrypt SSL certificates
- Cloudflare DDoS protection (optional)
- Rate limiting per app
- Content Security Policy headers
- CORS configuration

---

## 📚 Next Steps

1. **Initialize Rails Apps**: Create each app with proper configuration
2. **Configure Supabase**: Set up projects and schemas
3. **Implement HTMX**: Add HTMX for dynamic interactions
4. **Create Containers**: Dockerize each application
5. **Deploy to Staging**: Test on Gautama with Tailscale
6. **Deploy to Production**: Set up VPS and deploy

See detailed guides in:
- `docs/SETUP.md` - Initial setup
- `docs/DEVELOPMENT.md` - Development workflow
- `docs/DEPLOYMENT.md` - Deployment procedures

---

**Last Updated**: 2025-11-13
**Maintained by**: Gautama System Administrator
