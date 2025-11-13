#!/usr/bin/env bash
# Install desktop shortcuts for Gautama scripts

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Gautama Desktop Shortcuts Installer                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Determine user's desktop directory
DESKTOP_DIR="${XDG_DESKTOP_DIR:-$HOME/Desktop}"

# If Desktop doesn't exist, create it
if [ ! -d "$DESKTOP_DIR" ]; then
    echo -e "${YELLOW}Creating Desktop directory: $DESKTOP_DIR${NC}"
    mkdir -p "$DESKTOP_DIR"
fi

# Create shortcuts subdirectory
SHORTCUTS_DIR="$DESKTOP_DIR/Gautama Shortcuts"
echo -e "${BLUE}Installing to: $SHORTCUTS_DIR${NC}"
mkdir -p "$SHORTCUTS_DIR"

# Source directory
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Counter
installed=0

echo ""
echo "Installing shortcuts..."
echo ""

# Copy all .desktop files
for desktop_file in "$SOURCE_DIR"/*.desktop; do
    if [ -f "$desktop_file" ]; then
        filename=$(basename "$desktop_file")
        dest="$SHORTCUTS_DIR/$filename"

        cp "$desktop_file" "$dest"
        chmod +x "$dest"

        # Extract name from .desktop file
        name=$(grep "^Name=" "$desktop_file" | cut -d= -f2)
        echo -e "  ${GREEN}✓${NC} $name"

        ((installed++))
    fi
done

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Installed $installed shortcuts to:${NC}"
echo -e "${GREEN}  $SHORTCUTS_DIR${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""

# Instructions
echo "📋 Shortcuts created:"
echo ""
echo "  Documentation:"
echo "    • Build Documentation PDFs"
echo "    • Open LaTeX Documentation PDF"
echo "    • Open Typst Documentation PDF"
echo "    • Implementation Checklist"
echo ""
echo "  NIS2 Applications:"
echo "    • Initialize NIS2 Applications"
echo "    • Setup NIS2 Databases"
echo "    • Start NIS2 Services (Dev)"
echo "    • Start NIS2 Events (Dev)"
echo "    • Start NIS2 News (Dev)"
echo "    • Start NIS2 Academy (Dev)"
echo ""
echo "  System:"
echo "    • NixOS Rebuild Switch"
echo "    • Check System Status"
echo ""
echo -e "${BLUE}Tip:${NC} You can drag these shortcuts to your desktop for quick access!"
echo ""

# Offer to create symlinks on actual Desktop
if [ "$SHORTCUTS_DIR" != "$DESKTOP_DIR" ]; then
    read -p "Create quick access shortcuts on main Desktop? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Create symlinks for most used shortcuts
        ln -sf "$SHORTCUTS_DIR/build-documentation.desktop" "$DESKTOP_DIR/"
        ln -sf "$SHORTCUTS_DIR/open-implementation-checklist.desktop" "$DESKTOP_DIR/"
        ln -sf "$SHORTCUTS_DIR/nixos-rebuild-switch.desktop" "$DESKTOP_DIR/"
        echo -e "${GREEN}✓${NC} Created quick access shortcuts on Desktop"
    fi
fi

echo ""
echo -e "${GREEN}Installation complete!${NC} 🎉"
echo ""
