#!/bin/bash
# Quarto Container Entrypoint Script

set -e

echo "Quarto Container Starting..."
echo "Working directory: $(pwd)"
echo "User: $(whoami)"
echo "Quarto version: $(quarto --version)"

# Check if there are any .qmd or .ipynb files
if [ -z "$(find . -maxdepth 2 -name '*.qmd' -o -name '*.ipynb' 2>/dev/null)" ]; then
    echo "Warning: No Quarto documents (.qmd or .ipynb) found in /projects"
    echo "Creating example project..."

    # Create example quarto project
    cat > index.qmd <<'EOF'
---
title: "Welcome to Quarto"
format: html
---

## Hello Quarto

This is a Quarto document. You can use:

- **Markdown** for text
- Code blocks for Python, R, Julia
- Math equations with LaTeX

```{python}
print("Hello from Python!")
```

Edit this file to get started!
EOF

    echo "Created example index.qmd"
fi

# Render all projects if in production mode
if [ "$QUARTO_ENV" = "production" ]; then
    echo "Rendering projects for production..."
    quarto render
fi

# Start Quarto preview server
echo "Starting Quarto preview server on port 4001..."
exec "$@"
