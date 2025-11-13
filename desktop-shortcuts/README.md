# Gautama Desktop Shortcuts

Quick access shortcuts for common Gautama operations.

---

## 🚀 Installation

Run the installer script:

```bash
cd /home/user/gautama/desktop-shortcuts
./install-shortcuts.sh
```

This will:
- Copy all shortcuts to `~/Desktop/Gautama Shortcuts/`
- Make them executable
- Optionally create quick-access links on your desktop

---

## 📋 Available Shortcuts

### Documentation

**Build Documentation PDFs**
- Generates LaTeX and Typst PDFs from markdown documentation
- Output: `/home/gautama/docs/*.pdf`
- Takes: ~30-60 seconds

**Open LaTeX Documentation PDF**
- Opens the professionally formatted LaTeX PDF
- 300-page book with all documentation

**Open Typst Documentation PDF**
- Opens the modern Typst PDF
- Fast-built alternative to LaTeX

**Implementation Checklist**
- View what needs to be done to complete setup
- Track progress on all features

---

### NIS2 Applications

**Initialize NIS2 Applications**
- Creates all 4 Rails applications
- Installs dependencies
- Sets up basic structure
- Takes: 5-10 minutes

**Setup NIS2 Databases**
- Creates Supabase schemas
- Runs migrations
- Seeds initial data

**Start NIS2 Services (Dev)**
- Starts Services app on port 3001
- Development server with hot reload
- Access: http://localhost:3001

**Start NIS2 Events (Dev)**
- Starts Events app on port 3002
- Access: http://localhost:3002

**Start NIS2 News (Dev)**
- Starts News app on port 3003
- Access: http://localhost:3003

**Start NIS2 Academy (Dev)**
- Starts Academy app on port 3004
- Access: http://localhost:3004

---

### System

**NixOS Rebuild Switch**
- Rebuilds NixOS configuration
- Switches to new generation
- Requires sudo password
- Takes: 2-5 minutes

**Check System Status**
- Shows running containers
- Lists failed services
- Quick system health overview

---

## 🎨 Customization

### Edit a Shortcut

```bash
cd /home/user/gautama/desktop-shortcuts
nano shortcut-name.desktop
```

### Desktop Entry Format

```ini
[Desktop Entry]
Name=Shortcut Name
Comment=Description of what it does
Exec=command to run
Icon=icon-name
Terminal=true/false
Type=Application
Categories=Category1;Category2;
```

### Common Icons

- `document` - Documentation
- `application-x-executable` - Scripts
- `database` - Database operations
- `media-playback-start` - Start services
- `system-software-update` - System operations
- `application-pdf` - PDF files
- `dialog-information` - Information/Status

---

## 📦 Adding New Shortcuts

1. Create a new `.desktop` file:

```bash
nano /home/user/gautama/desktop-shortcuts/my-shortcut.desktop
```

2. Add content:

```ini
[Desktop Entry]
Name=My Shortcut
Comment=Does something useful
Exec=x-terminal-emulator -e bash -c 'my-command; read'
Icon=icon-name
Terminal=true
Type=Application
Categories=Development;
```

3. Make executable:

```bash
chmod +x my-shortcut.desktop
```

4. Re-run installer:

```bash
./install-shortcuts.sh
```

---

## 🔧 Troubleshooting

### Shortcut Doesn't Work

**Check permissions**:
```bash
ls -la *.desktop
# Should show: -rwxr-xr-x
```

**Make executable**:
```bash
chmod +x shortcut-name.desktop
```

### Terminal Doesn't Open

Try changing `Exec` line to use specific terminal:

```ini
# For GNOME Terminal
Exec=gnome-terminal -- bash -c 'command; read'

# For Konsole
Exec=konsole -e bash -c 'command; read'

# For xterm
Exec=xterm -e bash -c 'command; read'
```

### Icon Not Showing

Check available icons:
```bash
find /usr/share/icons -name "*.png" | grep icon-name
```

Or use absolute path:
```ini
Icon=/usr/share/pixmaps/my-icon.png
```

### Permission Denied

Shortcuts run as your user. For sudo commands:
```ini
Exec=x-terminal-emulator -e bash -c 'sudo command; read'
```

---

## 📍 File Locations

| Item | Location |
|------|----------|
| **Shortcuts** | `~/Desktop/Gautama Shortcuts/` |
| **Source** | `/home/user/gautama/desktop-shortcuts/` |
| **Installer** | `/home/user/gautama/desktop-shortcuts/install-shortcuts.sh` |

---

## 🎯 Quick Tips

### Run Without Opening Desktop

```bash
# Run shortcut directly
gtk-launch shortcut-name.desktop

# Or use gio
gio open shortcut-name.desktop
```

### Pin to Panel/Dock

Right-click shortcut → "Add to Favorites" or "Pin to Panel"

### Create Keyboard Shortcuts

System Settings → Keyboard → Custom Shortcuts
- Command: Path to .desktop file
- Keybinding: Your choice (e.g., Ctrl+Alt+D)

---

## 📚 Documentation

For detailed information on what each script does:

- **Documentation**: See `/etc/nixos/docs/README.md`
- **NIS2 Apps**: See `/home/user/gautama/nis2-apps/README.md`
- **Implementation**: See `/home/user/gautama/docs/IMPLEMENTATION_CHECKLIST.md`

---

**Last Updated**: 2025-11-13
**Total Shortcuts**: 12
