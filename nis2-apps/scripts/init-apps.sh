#!/bin/bash
# Initialize all 4 NIS2 Rails applications

set -e

echo "🚀 Initializing NIS2 Applications..."
echo

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Apps configuration
declare -A APPS
APPS[services]=3001
APPS[events]=3002
APPS[news]=3003
APPS[academy]=3004

# Check prerequisites
check_prerequisites() {
    echo "📋 Checking prerequisites..."

    if ! command -v ruby &> /dev/null; then
        echo "❌ Ruby is not installed. Please install Ruby 3.2+"
        exit 1
    fi

    if ! command -v rails &> /dev/null; then
        echo "❌ Rails is not installed. Installing..."
        gem install rails
    fi

    if ! command -v psql &> /dev/null; then
        echo "⚠️  PostgreSQL client not found. Install for database operations."
    fi

    echo -e "${GREEN}✓${NC} Prerequisites check complete"
    echo
}

# Initialize single Rails app
init_app() {
    local app_name=$1
    local port=$2

    echo -e "${BLUE}📦 Initializing ${app_name} app...${NC}"

    if [ -d "$app_name/app" ]; then
        echo "  ⚠️  App already exists, skipping..."
        return
    fi

    # Create Rails app without default database (we'll use Supabase)
    rails new $app_name \
        --database=postgresql \
        --css=tailwind \
        --skip-javascript \
        --skip-jbuilder \
        --skip-action-mailbox \
        --skip-action-text \
        --skip-active-storage \
        --skip-action-cable \
        --skip-test

    cd $app_name

    # Add required gems
    cat >> Gemfile <<EOF

# Supabase integration
gem 'supabase-rb', '~> 0.3.0'

# HTMX Rails helpers
gem 'turbo-rails'  # We'll use Turbo for HTMX-like behavior
# Or use: gem 'htmx-rails' if available

# Environment variables
gem 'dotenv-rails', groups: [:development, :test]

# Testing
group :development, :test do
  gem 'rspec-rails', '~> 6.0'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'capybara'
  gem 'selenium-webdriver'
end

# Production
group :production do
  gem 'puma', '~> 6.0'
  gem 'sidekiq', '~> 7.0'
  gem 'redis', '~> 5.0'
end
EOF

    bundle install

    # Initialize RSpec
    rails generate rspec:install

    # Create .env.example
    cat > .env.example <<EOF
# Supabase Configuration
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_KEY=eyJhbGc...
SUPABASE_DATABASE_URL=postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres
SUPABASE_SCHEMA=nis2_${app_name}

# Rails
RAILS_ENV=development
SECRET_KEY_BASE=\$(rails secret)

# App-specific
PORT=${port}
EOF

    # Create .env (gitignored)
    cp .env.example .env

    # Create Supabase initializer
    mkdir -p config/initializers
    cat > config/initializers/supabase.rb <<'EOF'
require 'supabase'

SUPABASE = Supabase::Client.new(
  url: ENV['SUPABASE_URL'],
  key: ENV['SUPABASE_ANON_KEY']
)

# Database connection with schema
ActiveRecord::Base.connection.execute(
  "SET search_path TO #{ENV['SUPABASE_SCHEMA']}, public"
)
EOF

    # Update database.yml for Supabase
    cat > config/database.yml <<EOF
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  url: <%= ENV['SUPABASE_DATABASE_URL'] %>
  schema_search_path: <%= ENV['SUPABASE_SCHEMA'] %>,public

development:
  <<: *default

test:
  <<: *default
  database: nis2_${app_name}_test

staging:
  <<: *default

production:
  <<: *default
EOF

    # Create HTMX layout
    cat > app/views/layouts/application.html.erb <<'EOF'
<!DOCTYPE html>
<html>
  <head>
    <title><%= content_for?(:title) ? yield(:title) : "NIS2 ${APP_NAME}" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>

    <!-- HTMX -->
    <script src="https://unpkg.com/htmx.org@1.9.10"></script>

    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
  </head>

  <body class="bg-gray-50">
    <nav class="bg-white shadow-lg">
      <div class="max-w-7xl mx-auto px-4">
        <div class="flex justify-between h-16">
          <div class="flex items-center">
            <span class="text-xl font-bold">NIS2 ${APP_NAME}</span>
          </div>
        </div>
      </div>
    </nav>

    <main class="max-w-7xl mx-auto px-4 py-8">
      <%= yield %>
    </main>
  </body>
</html>
EOF

    # Create home controller
    rails generate controller Home index

    # Update routes
    cat > config/routes.rb <<EOF
Rails.application.routes.draw do
  root 'home#index'

  # Health check
  get '/health', to: proc { [200, {}, ['OK']] }
end
EOF

    # Update home index view
    cat > app/views/home/index.html.erb <<EOF
<div class="bg-white rounded-lg shadow-lg p-8">
  <h1 class="text-4xl font-bold mb-4">Welcome to NIS2 ${app_name^}</h1>
  <p class="text-gray-600 mb-6">
    This application is built with Ruby on Rails, HTMX, and Supabase.
  </p>

  <div class="space-y-4">
    <div class="p-4 bg-blue-50 rounded">
      <h2 class="font-semibold text-blue-900">HTMX Enabled</h2>
      <p class="text-blue-700">Dynamic interactions without JavaScript frameworks</p>
    </div>

    <div class="p-4 bg-green-50 rounded">
      <h2 class="font-semibold text-green-900">Supabase Connected</h2>
      <p class="text-green-700">PostgreSQL database with real-time capabilities</p>
    </div>

    <div class="p-4 bg-purple-50 rounded">
      <h2 class="font-semibold text-purple-900">Tailwind CSS</h2>
      <p class="text-purple-700">Utility-first styling with no custom JavaScript</p>
    </div>
  </div>
</div>
EOF

    # Create Dockerfile
    cat > Dockerfile <<EOF
FROM ruby:3.2-alpine

# Install dependencies
RUN apk add --no-cache \\
    build-base \\
    postgresql-dev \\
    tzdata \\
    nodejs \\
    yarn

WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy app
COPY . .

# Precompile assets (if needed)
RUN RAILS_ENV=production bundle exec rails assets:precompile || true

# Expose port
EXPOSE ${port}

# Start server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "${port}"]
EOF

    # Create .dockerignore
    cat > .dockerignore <<EOF
.git
.env
tmp/
log/
.bundle/
node_modules/
EOF

    cd ..

    echo -e "${GREEN}✓${NC} ${app_name} initialized"
    echo
}

# Main execution
main() {
    check_prerequisites

    for app in "${!APPS[@]}"; do
        init_app "$app" "${APPS[$app]}"
    done

    echo -e "${GREEN}🎉 All apps initialized successfully!${NC}"
    echo
    echo "Next steps:"
    echo "1. Configure Supabase credentials in each app's .env file"
    echo "2. Run: ./scripts/setup-databases.sh"
    echo "3. Run: ./scripts/dev-servers.sh"
}

main
