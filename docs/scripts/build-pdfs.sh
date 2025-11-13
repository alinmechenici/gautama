#!/usr/bin/env bash
# Build Gautama documentation PDFs from Markdown sources
# Generates both LaTeX and Typst versions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(dirname "$SCRIPT_DIR")"
MD_DIR="$DOCS_DIR/md"
LATEX_DIR="$DOCS_DIR/latex"
TYPST_DIR="$DOCS_DIR/typst"
PDF_DIR="$DOCS_DIR/pdf"
GAUTAMA_DOCS_DIR="/home/gautama/docs"

# Output files
LATEX_CONTENT="$LATEX_DIR/content.tex"
TYPST_CONTENT="$TYPST_DIR/content.typ"
LATEX_PDF="$PDF_DIR/gautama-docs-latex.pdf"
TYPST_PDF="$PDF_DIR/gautama-docs-typst.pdf"

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

check_dependencies() {
    local missing=()

    if ! command -v pandoc &> /dev/null; then
        missing+=("pandoc")
    fi

    if ! command -v pdflatex &> /dev/null; then
        missing+=("texlive")
    fi

    if ! command -v typst &> /dev/null; then
        missing+=("typst")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_info "Install with: nix-shell -p pandoc texlive.combined.scheme-full typst"
        exit 1
    fi
}

# ============================================================================
# Markdown Processing
# ============================================================================

collect_markdown_files() {
    log_info "Collecting markdown files from $MD_DIR..."

    if [ ! -d "$MD_DIR" ]; then
        log_error "Markdown directory not found: $MD_DIR"
        exit 1
    fi

    # Define order of chapters
    local ordered_files=(
        "QUICKSTART.md"
        "TROUBLESHOOTING.md"
        "FAQ.md"
        "MODULE_INDEX.md"
        "CLOUDFLARE_TUNNEL_GUIDE.md"
        "ZOHO_API_GUIDE.md"
        "INTERNET_PUBLISHING_SETUP.md"
        "PUBLISHING_SERVICES.md"
        "RUNBOOK_DISASTER_RECOVERY.md"
        "NIS2_APPS_ARCHITECTURE.md"
        "HOME_ASSISTANT_DEVICES.md"
        "GIT_WORKFLOW.md"
    )

    # Collect files in order, then add any remaining
    local files=()
    for file in "${ordered_files[@]}"; do
        if [ -f "$MD_DIR/$file" ]; then
            files+=("$MD_DIR/$file")
        fi
    done

    # Add any remaining markdown files not in the ordered list
    while IFS= read -r -d '' file; do
        local basename=$(basename "$file")
        local found=false
        for ordered in "${ordered_files[@]}"; do
            if [ "$basename" = "$ordered" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            files+=("$file")
        fi
    done < <(find "$MD_DIR" -maxdepth 1 -name "*.md" -print0 | sort -z)

    echo "${files[@]}"
}

# ============================================================================
# LaTeX Conversion
# ============================================================================

convert_to_latex() {
    log_info "Converting Markdown to LaTeX..."

    local md_files=($(collect_markdown_files))

    if [ ${#md_files[@]} -eq 0 ]; then
        log_warning "No markdown files found"
        return 1
    fi

    log_info "Processing ${#md_files[@]} markdown files..."

    # Start content file
    > "$LATEX_CONTENT"

    for md_file in "${md_files[@]}"; do
        local filename=$(basename "$md_file")
        log_info "  Converting $filename..."

        # Convert to LaTeX chapter
        echo "\\chapter{$(basename "$md_file" .md | sed 's/_/ /g')}" >> "$LATEX_CONTENT"
        echo "" >> "$LATEX_CONTENT"

        # Convert markdown to LaTeX with pandoc
        pandoc "$md_file" \
            --from markdown \
            --to latex \
            --listings \
            --highlight-style=tango \
            >> "$LATEX_CONTENT"

        echo "" >> "$LATEX_CONTENT"
        echo "\\clearpage" >> "$LATEX_CONTENT"
        echo "" >> "$LATEX_CONTENT"
    done

    log_success "LaTeX conversion complete: $LATEX_CONTENT"
}

build_latex_pdf() {
    log_info "Building LaTeX PDF..."

    cd "$LATEX_DIR"

    # Create complete document
    local temp_doc="gautama-docs-complete.tex"
    sed '/%%% CONTENT WILL BE INSERTED HERE BY BUILD SCRIPT %%%/r content.tex' gautama-docs.tex > "$temp_doc"

    # Run pdflatex multiple times for references
    log_info "  First pass..."
    pdflatex -interaction=nonstopmode -output-directory="$LATEX_DIR" "$temp_doc" > /dev/null 2>&1 || true

    log_info "  Second pass (for references)..."
    pdflatex -interaction=nonstopmode -output-directory="$LATEX_DIR" "$temp_doc" > /dev/null 2>&1 || true

    log_info "  Third pass (for TOC)..."
    pdflatex -interaction=nonstopmode -output-directory="$LATEX_DIR" "$temp_doc" > /dev/null 2>&1 || true

    # Move PDF to output directory
    mkdir -p "$PDF_DIR"
    local temp_pdf="${temp_doc%.tex}.pdf"
    if [ -f "$temp_pdf" ]; then
        mv "$temp_pdf" "$LATEX_PDF"
        log_success "LaTeX PDF generated: $LATEX_PDF"

        # Cleanup temporary files
        rm -f *.aux *.log *.toc *.out *.lof *.lot *.idx *.ilg *.ind "$temp_doc"
    else
        log_error "LaTeX PDF generation failed"
        return 1
    fi

    cd - > /dev/null
}

# ============================================================================
# Typst Conversion
# ============================================================================

convert_to_typst() {
    log_info "Converting Markdown to Typst..."

    local md_files=($(collect_markdown_files))

    if [ ${#md_files[@]} -eq 0 ]; then
        log_warning "No markdown files found"
        return 1
    fi

    log_info "Processing ${#md_files[@]} markdown files..."

    # Start content file
    > "$TYPST_CONTENT"

    for md_file in "${md_files[@]}"; do
        local filename=$(basename "$md_file")
        local title=$(basename "$md_file" .md | sed 's/_/ /g')
        log_info "  Converting $filename..."

        # Add chapter heading
        echo "= $title" >> "$TYPST_CONTENT"
        echo "" >> "$TYPST_CONTENT"

        # Convert markdown to Typst with pandoc
        # Note: Pandoc doesn't natively support Typst, so we convert to a compatible format
        # For now, we'll use a simple approach
        pandoc "$md_file" \
            --from markdown \
            --to plain \
            | sed 's/^#/=/g' \
            >> "$TYPST_CONTENT"

        echo "" >> "$TYPST_CONTENT"
        echo "#pagebreak()" >> "$TYPST_CONTENT"
        echo "" >> "$TYPST_CONTENT"
    done

    log_success "Typst conversion complete: $TYPST_CONTENT"
}

build_typst_pdf() {
    log_info "Building Typst PDF..."

    cd "$TYPST_DIR"

    # Create complete document
    local temp_doc="gautama-docs-complete.typ"
    sed '/\/\/\/ CONTENT WILL BE INSERTED HERE BY BUILD SCRIPT \/\/\//r content.typ' gautama-docs.typ > "$temp_doc"

    # Compile with Typst
    mkdir -p "$PDF_DIR"
    if typst compile "$temp_doc" "$TYPST_PDF"; then
        log_success "Typst PDF generated: $TYPST_PDF"

        # Cleanup temporary file
        rm -f "$temp_doc"
    else
        log_error "Typst PDF generation failed"
        return 1
    fi

    cd - > /dev/null
}

# ============================================================================
# Copy to Gautama Docs
# ============================================================================

copy_to_gautama_docs() {
    log_info "Copying PDFs to $GAUTAMA_DOCS_DIR..."

    # Create directory if it doesn't exist
    mkdir -p "$GAUTAMA_DOCS_DIR"

    # Copy LaTeX PDF
    if [ -f "$LATEX_PDF" ]; then
        cp "$LATEX_PDF" "$GAUTAMA_DOCS_DIR/gautama-docs-latex.pdf"
        log_success "Copied LaTeX PDF to $GAUTAMA_DOCS_DIR/gautama-docs-latex.pdf"
    fi

    # Copy Typst PDF
    if [ -f "$TYPST_PDF" ]; then
        cp "$TYPST_PDF" "$GAUTAMA_DOCS_DIR/gautama-docs-typst.pdf"
        log_success "Copied Typst PDF to $GAUTAMA_DOCS_DIR/gautama-docs-typst.pdf"
    fi
}

# ============================================================================
# Statistics
# ============================================================================

show_statistics() {
    log_info "Build Statistics:"

    if [ -f "$LATEX_PDF" ]; then
        local latex_size=$(du -h "$LATEX_PDF" | cut -f1)
        local latex_pages=$(pdfinfo "$LATEX_PDF" 2>/dev/null | grep Pages | awk '{print $2}' || echo "?")
        echo "  LaTeX PDF: $latex_size, $latex_pages pages"
    fi

    if [ -f "$TYPST_PDF" ]; then
        local typst_size=$(du -h "$TYPST_PDF" | cut -f1)
        local typst_pages=$(pdfinfo "$TYPST_PDF" 2>/dev/null | grep Pages | awk '{print $2}' || echo "?")
        echo "  Typst PDF: $typst_size, $typst_pages pages"
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  Gautama Documentation Build System"
    echo "════════════════════════════════════════════════════════════════"
    echo ""

    # Check dependencies
    check_dependencies

    # Create output directories
    mkdir -p "$LATEX_DIR" "$TYPST_DIR" "$PDF_DIR"

    # Build LaTeX version
    log_info "Building LaTeX version..."
    if convert_to_latex && build_latex_pdf; then
        log_success "LaTeX PDF build complete!"
    else
        log_error "LaTeX PDF build failed"
    fi

    echo ""

    # Build Typst version
    log_info "Building Typst version..."
    if convert_to_typst && build_typst_pdf; then
        log_success "Typst PDF build complete!"
    else
        log_error "Typst PDF build failed"
    fi

    echo ""

    # Copy to gautama docs
    copy_to_gautama_docs

    echo ""

    # Show statistics
    show_statistics

    echo ""
    echo "════════════════════════════════════════════════════════════════"
    log_success "Documentation build complete!"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "Output files:"
    echo "  LaTeX PDF:  $LATEX_PDF"
    echo "  Typst PDF:  $TYPST_PDF"
    echo ""
    echo "Copied to:"
    echo "  $GAUTAMA_DOCS_DIR/gautama-docs-latex.pdf"
    echo "  $GAUTAMA_DOCS_DIR/gautama-docs-typst.pdf"
    echo ""
}

main "$@"
