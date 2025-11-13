#!/bin/sh
# Jekyll Container Entrypoint Script

set -e

echo "Jekyll Container Starting..."
echo "Working directory: $(pwd)"
echo "User: $(whoami)"

# Check if Gemfile exists
if [ -f "Gemfile" ]; then
    echo "Found Gemfile, installing bundle dependencies..."
    bundle install
fi

# Check if _config.yml exists
if [ ! -f "_config.yml" ]; then
    echo "Warning: No _config.yml found in /site"
    echo "Creating default Jekyll site..."
    jekyll new . --force --skip-bundle
    bundle install
fi

# Build the site first (for production)
if [ "$JEKYLL_ENV" = "production" ]; then
    echo "Building site for production..."
    JEKYLL_ENV=production bundle exec jekyll build
fi

# Start Jekyll server
echo "Starting Jekyll server on port 4000..."
exec "$@"
