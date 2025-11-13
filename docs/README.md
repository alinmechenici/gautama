# Gautama Documentation Build System

Automatically generates beautiful PDF books from Markdown documentation using both LaTeX and Typst.

---

## 📚 Overview

This system converts all Markdown documentation in `docs/md/` into professional PDF books in two formats:
- **LaTeX**: Traditional, highly polished academic book layout
- **Typst**: Modern, fast, clean technical documentation style

**Output**:
- `docs/pdf/gautama-docs-latex.pdf` - LaTeX-generated PDF
- `docs/pdf/gautama-docs-typst.pdf` - Typst-generated PDF
- `/home/gautama/docs/gautama-docs-latex.pdf` - Copy for easy access
- `/home/gautama/docs/gautama-docs-typst.pdf` - Copy for easy access

---

## 🏗️ Structure

```
docs/
├── md/                          # Source markdown files
│   ├── QUICKSTART.md
│   ├── TROUBLESHOOTING.md
│   ├── FAQ.md
│   ├── MODULE_INDEX.md
│   ├── CLOUDFLARE_TUNNEL_GUIDE.md
│   ├── ZOHO_API_GUIDE.md
│   ├── INTERNET_PUBLISHING_SETUP.md
│   ├── PUBLISHING_SERVICES.md
│   ├── RUNBOOK_DISASTER_RECOVERY.md
│   ├── NIS2_APPS_ARCHITECTURE.md
│   ├── HOME_ASSISTANT_DEVICES.md
│   └── GIT_WORKFLOW.md
│
├── latex/                       # LaTeX templates and build
│   ├── gautama-docs.tex        # Main LaTeX template
│   └── content.tex             # Generated content (build artifact)
│
├── typst/                       # Typst templates and build
│   ├── gautama-docs.typ        # Main Typst template
│   └── content.typ             # Generated content (build artifact)
│
├── pdf/                         # Generated PDFs
│   ├── gautama-docs-latex.pdf
│   └── gautama-docs-typst.pdf
│
└── scripts/
    └── build-pdfs.sh           # Main build script
```

---

## 🚀 Quick Start

### Manual Build

```bash
# Build both PDFs
cd /etc/nixos/docs
./scripts/build-pdfs.sh

# Output:
# - docs/pdf/gautama-docs-latex.pdf
# - docs/pdf/gautama-docs-typst.pdf
# - /home/gautama/docs/gautama-docs-latex.pdf
# - /home/gautama/docs/gautama-docs-typst.pdf
```

### Automatic Build (NixOS)

The documentation is automatically built during `nixos-rebuild switch`:

```bash
cd /etc/nixos
sudo nixos-rebuild switch --flake '.#vulcan'

# Documentation PDFs are automatically generated and copied to /home/gautama/docs/
```

### Weekly Rebuild

A systemd timer automatically rebuilds the documentation weekly:

```bash
# Check timer status
systemctl status build-documentation.timer

# Manually trigger rebuild
systemctl start build-documentation.service

# View logs
journalctl -u build-documentation.service
```

---

## 🎨 LaTeX Template

**File**: `docs/latex/gautama-docs.tex`

**Features**:
- Professional book layout with chapters and sections
- Syntax-highlighted code blocks
- Custom boxes for warnings, info, tips
- Table of contents, list of figures, list of tables
- Index generation
- Headers and footers
- Cross-references
- Modern typography with microtype

**Fonts**:
- Text: Latin Modern
- Code: Inconsolata

**Colors**:
- Headings: Midnight Blue
- Links: Blue
- Code background: Light gray

---

## ✨ Typst Template

**File**: `docs/typst/gautama-docs.typ`

**Features**:
- Clean, modern book layout
- Fast compilation (seconds vs minutes for LaTeX)
- Syntax-highlighted code blocks
- Custom boxes for warnings, info, tips
- Automatic table of contents
- Beautiful typography
- Responsive tables and figures

**Fonts**:
- Text: Linux Libertine
- Code: Fira Code

**Colors**:
- Headings: Blue gradient
- Links: Blue
- Code background: Light gray

---

## 🔧 Build Process

### 1. Collect Markdown Files

The build script collects all `.md` files from `docs/md/` in a defined order:

1. QUICKSTART.md
2. TROUBLESHOOTING.md
3. FAQ.md
4. MODULE_INDEX.md
5. CLOUDFLARE_TUNNEL_GUIDE.md
6. ZOHO_API_GUIDE.md
7. INTERNET_PUBLISHING_SETUP.md
8. PUBLISHING_SERVICES.md
9. RUNBOOK_DISASTER_RECOVERY.md
10. NIS2_APPS_ARCHITECTURE.md
11. HOME_ASSISTANT_DEVICES.md
12. GIT_WORKFLOW.md
13. (any other .md files found)

### 2. Convert to LaTeX

```bash
# For each markdown file:
pandoc input.md \
    --from markdown \
    --to latex \
    --listings \
    --highlight-style=tango \
    >> content.tex
```

Each file becomes a chapter in the book.

### 3. Build LaTeX PDF

```bash
# Insert content into template
sed '/%%% CONTENT WILL BE INSERTED HERE %%%/r content.tex' \
    gautama-docs.tex > complete.tex

# Compile (3 passes for references and TOC)
pdflatex -interaction=nonstopmode complete.tex
pdflatex -interaction=nonstopmode complete.tex
pdflatex -interaction=nonstopmode complete.tex
```

### 4. Convert to Typst

```bash
# For each markdown file:
pandoc input.md \
    --from markdown \
    --to plain \
    | sed 's/^#/=/g' \
    >> content.typ
```

Each file becomes a section in the book.

### 5. Build Typst PDF

```bash
# Insert content into template
sed '///CONTENT WILL BE INSERTED HERE///r content.typ' \
    gautama-docs.typ > complete.typ

# Compile (single pass!)
typst compile complete.typ gautama-docs-typst.pdf
```

### 6. Copy to /home/gautama/docs/

Both PDFs are copied to `/home/gautama/docs/` for easy access.

---

## 📦 Dependencies

### Required Packages

- **pandoc**: Markdown to LaTeX/Typst conversion
- **texlive-full**: LaTeX distribution for PDF generation
- **typst**: Modern typesetting system
- **poppler-utils**: PDF utilities (pdfinfo)

### NixOS Installation

These are automatically available when using the NixOS module:

```nix
# In your configuration
imports = [
  ./modules/services/documentation-builder.nix
];
```

### Manual Installation

```bash
nix-shell -p pandoc texlive.combined.scheme-full typst poppler_utils
```

---

## 🎯 Usage

### Build Manually

```bash
# From /etc/nixos/docs
./scripts/build-pdfs.sh

# Or from anywhere
build-gautama-docs
```

### Build During NixOS Rebuild

```bash
cd /etc/nixos
sudo nixos-rebuild switch --flake '.#vulcan'
```

The documentation is automatically built during activation.

### View Output

```bash
# View LaTeX PDF
xdg-open /home/gautama/docs/gautama-docs-latex.pdf

# View Typst PDF
xdg-open /home/gautama/docs/gautama-docs-typst.pdf

# Compare file sizes
ls -lh /home/gautama/docs/*.pdf
```

---

## 📊 Output Statistics

After building, the script shows:

```
Build Statistics:
  LaTeX PDF: 2.3M, 147 pages
  Typst PDF: 1.8M, 147 pages
```

**Typical Build Times**:
- LaTeX: ~30-60 seconds (3 passes)
- Typst: ~2-5 seconds (single pass)

---

## 🎨 Customization

### Adding Custom Styling (LaTeX)

Edit `docs/latex/gautama-docs.tex`:

```latex
% Change colors
\definecolor{linkcolor}{RGB}{0,102,204}

% Change fonts
\usepackage{lmodern}

% Customize headers
\fancyhead[LE]{\nouppercase{\leftmark}}
```

### Adding Custom Styling (Typst)

Edit `docs/typst/gautama-docs.typ`:

```typst
// Change colors
#let primary-color = rgb("#1a5490")

// Change fonts
#set text(font: "Linux Libertine")

// Customize headings
#show heading.where(level: 1): it => {
  set text(size: 24pt, fill: primary-color)
  it
}
```

---

## 🔍 Troubleshooting

### LaTeX Build Fails

**Error**: `! LaTeX Error: File 'xyz.sty' not found`

**Solution**: Install full LaTeX distribution:
```bash
nix-shell -p texlive.combined.scheme-full
```

### Typst Build Fails

**Error**: `error: failed to load file`

**Solution**: Check Typst is installed:
```bash
typst --version
nix-shell -p typst
```

### Pandoc Conversion Issues

**Error**: `pandoc: unrecognized option`

**Solution**: Update pandoc:
```bash
nix-shell -p pandoc
pandoc --version  # Should be 3.0+
```

### PDFs Not Copied

**Error**: PDFs not appearing in `/home/gautama/docs/`

**Solution**: Check permissions:
```bash
ls -la /home/gautama/docs/
sudo chown -R gautama:users /home/gautama/docs/
```

---

## 📚 Adding New Documentation

### 1. Create Markdown File

```bash
cd /etc/nixos/docs/md
nano NEW_GUIDE.md
```

### 2. Write Content

```markdown
# New Guide Title

## Section 1

Content here...

## Section 2

More content...
```

### 3. Rebuild

```bash
cd /etc/nixos/docs
./scripts/build-pdfs.sh
```

The new file is automatically included in the next build!

---

## 🔄 Automatic Updates

### On System Rebuild

Documentation is automatically rebuilt when you run:

```bash
sudo nixos-rebuild switch --flake '.#vulcan'
```

### Weekly Timer

A systemd timer rebuilds documentation every week:

```bash
# Check next run time
systemctl list-timers | grep build-documentation

# Force immediate rebuild
systemctl start build-documentation.service
```

### Manual Trigger

```bash
# From anywhere
build-gautama-docs

# Or directly
/etc/nixos/docs/scripts/build-pdfs.sh
```

---

## 📖 Book Structure

### Front Matter

- Title page
- Copyright page
- Table of contents
- List of figures
- List of tables
- Preface

### Main Chapters

Each Markdown file becomes a chapter, in order:

1. Quick Start Guide
2. Troubleshooting Guide
3. Frequently Asked Questions
4. Module Index
5. Cloudflare Tunnel Guide
6. ZOHO API Guide
7. Internet Publishing Setup
8. Publishing Services
9. Disaster Recovery Runbook
10. NIS2 Apps Architecture
11. Home Assistant Devices
12. Git Workflow
13. (Additional guides)

### Back Matter

- Index (LaTeX only)
- Colophon

---

## 🎓 Tips

### Best Practices

- Keep markdown files focused on one topic
- Use clear, descriptive headings
- Include code examples in fenced code blocks
- Add tables for structured data
- Use lists for step-by-step instructions

### Code Blocks

````markdown
```bash
# This will be syntax highlighted
echo "Hello World"
```
````

### Tables

```markdown
| Column 1 | Column 2 |
|----------|----------|
| Data 1   | Data 2   |
```

### Images

```markdown
![Alt text](path/to/image.png)
```

---

## 🔗 Integration with NixOS

The documentation builder integrates seamlessly with NixOS:

**Module**: `modules/services/documentation-builder.nix`

**Features**:
- Automatic build on system switch
- Weekly rebuild timer
- Build script available system-wide
- Proper dependency management
- Error handling and logging

**Enable**:

```nix
# In your configuration
imports = [
  ./modules/services/documentation-builder.nix
];
```

---

## 📊 Comparison: LaTeX vs Typst

| Feature | LaTeX | Typst |
|---------|-------|-------|
| **Build Time** | 30-60 seconds | 2-5 seconds |
| **Output Quality** | Excellent | Excellent |
| **Customization** | Extensive | Good |
| **Learning Curve** | Steep | Gentle |
| **File Size** | Larger | Smaller |
| **Compile Passes** | 3 (for refs) | 1 |
| **Best For** | Academic/Professional | Technical/Modern |

**Recommendation**: Use both! LaTeX for formal documents, Typst for quick iterations.

---

## 🆘 Getting Help

- Check logs: `journalctl -u build-documentation.service`
- View build output: `build-gautama-docs`
- Test manually: `cd /etc/nixos/docs && ./scripts/build-pdfs.sh`

---

## 📝 License

Part of Gautama NixOS Configuration. All rights reserved.

---

**Last Updated**: 2025-11-13
**Maintained by**: Gautama System Administrator
