#!/bin/bash
# Setup databases for all NIS2 apps

set -e

echo "🗄️  Setting up databases..."
echo

GREEN='\033[0;32m'
NC='\033[0m'

APPS=("services" "events" "news" "academy")

for app in "${APPS[@]}"; do
    echo "📦 Setting up $app database..."

    cd $app

    # Load environment
    if [ -f .env ]; then
        export $(cat .env | grep -v '^#' | xargs)
    fi

    # Create database and run migrations
    RAILS_ENV=development bin/rails db:create || true
    RAILS_ENV=development bin/rails db:migrate
    RAILS_ENV=development bin/rails db:seed || true

    cd ..

    echo -e "${GREEN}✓${NC} $app database ready"
    echo
done

echo -e "${GREEN}🎉 All databases setup complete!${NC}"
