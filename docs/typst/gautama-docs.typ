// Gautama Documentation - Typst Book Template
// Modern, clean book layout for technical documentation

#set document(
  title: "Gautama System Documentation",
  author: "System Administrator",
  date: datetime.today(),
)

// ============================================================================
// Page Setup
// ============================================================================

#set page(
  paper: "a4",
  margin: (
    top: 2.5cm,
    bottom: 2.5cm,
    left: 3cm,
    right: 2.5cm,
  ),
  header: context {
    if counter(page).get().first() > 1 [
      #set text(9pt)
      #smallcaps[Gautama Documentation]
      #h(1fr)
      #emph(context heading.current().body)
    ]
  },
  footer: context {
    set text(9pt)
    set align(center)
    [Page #counter(page).display("1 of 1", both: true)]
  },
  numbering: "1",
)

// ============================================================================
// Typography
// ============================================================================

#set text(
  font: "Linux Libertine",
  size: 11pt,
  lang: "en",
)

#set par(
  justify: true,
  leading: 0.65em,
  spacing: 1.5em,
)

// ============================================================================
// Headings
// ============================================================================

#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  set text(size: 24pt, weight: "bold", fill: rgb("#1a5490"))
  block(above: 2em, below: 1.5em)[
    #counter(heading).display()
    #h(1em)
    #it.body
  ]
}

#show heading.where(level: 2): it => {
  set text(size: 18pt, weight: "bold", fill: rgb("#1a5490"))
  block(above: 1.5em, below: 1em)[
    #counter(heading).display()
    #h(0.5em)
    #it.body
  ]
}

#show heading.where(level: 3): it => {
  set text(size: 14pt, weight: "semibold", fill: rgb("#2c5aa0"))
  block(above: 1em, below: 0.8em)[
    #counter(heading).display()
    #h(0.5em)
    #it.body
  ]
}

// ============================================================================
// Code Blocks
// ============================================================================

#show raw.where(block: true): it => {
  set text(font: "Fira Code", size: 9pt)
  block(
    width: 100%,
    fill: rgb("#f5f5f5"),
    stroke: rgb("#cccccc"),
    inset: 10pt,
    radius: 4pt,
    breakable: true,
  )[#it]
}

#show raw.where(block: false): it => {
  set text(font: "Fira Code", size: 10pt)
  box(
    fill: rgb("#f5f5f5"),
    outset: (x: 2pt, y: 1pt),
    radius: 2pt,
  )[#it]
}

// ============================================================================
// Links
// ============================================================================

#show link: it => {
  set text(fill: rgb("#0066cc"))
  underline(it)
}

// ============================================================================
// Lists
// ============================================================================

#set list(indent: 1em, body-indent: 0.5em)
#set enum(indent: 1em, body-indent: 0.5em)

// ============================================================================
// Tables
// ============================================================================

#show table: it => {
  set table(
    stroke: (x, y) => (
      left: if x > 0 { 0.5pt } else { 1pt },
      right: 1pt,
      top: if y == 0 { 1pt } else { 0.5pt },
      bottom: 1pt,
    ),
  )
  block(breakable: true)[#it]
}

// ============================================================================
// Quotes
// ============================================================================

#show quote: it => {
  set text(style: "italic")
  block(
    width: 95%,
    inset: (left: 1em, rest: 0.5em),
    stroke: (left: 3pt + rgb("#1a5490")),
  )[#it]
}

// ============================================================================
// Custom Boxes
// ============================================================================

#let warning-box(content) = {
  block(
    width: 100%,
    fill: rgb("#fff3cd"),
    stroke: rgb("#ffc107"),
    inset: 10pt,
    radius: 4pt,
    breakable: true,
  )[
    #text(weight: "bold", fill: rgb("#856404"))[⚠ Warning]
    #v(0.5em)
    #content
  ]
}

#let info-box(content) = {
  block(
    width: 100%,
    fill: rgb("#d1ecf1"),
    stroke: rgb("#0dcaf0"),
    inset: 10pt,
    radius: 4pt,
    breakable: true,
  )[
    #text(weight: "bold", fill: rgb("#055160"))[ℹ Information]
    #v(0.5em)
    #content
  ]
}

#let tip-box(content) = {
  block(
    width: 100%,
    fill: rgb("#d1e7dd"),
    stroke: rgb("#198754"),
    inset: 10pt,
    radius: 4pt,
    breakable: true,
  )[
    #text(weight: "bold", fill: rgb("#0a3622"))[💡 Tip]
    #v(0.5em)
    #content
  ]
}

// ============================================================================
// Title Page
// ============================================================================

#align(center)[
  #v(3cm)

  // Logo would go here
  // #image("logo.png", width: 6cm)

  #v(2cm)

  #text(size: 32pt, weight: "bold", fill: rgb("#1a5490"))[
    Gautama
  ]

  #v(0.5cm)

  #text(size: 28pt, weight: "bold")[
    System Documentation
  ]

  #v(2cm)

  #text(size: 14pt)[
    System Administrator \
    #v(0.5cm)
    NixOS Production Infrastructure
  ]

  #v(3cm)

  #text(size: 12pt)[
    #datetime.today().display("[month repr:long] [day], [year]")
  ]
]

#pagebreak()

// ============================================================================
// Copyright Page
// ============================================================================

#v(1fr)

#align(center)[
  #text(weight: "bold", size: 12pt)[
    Gautama System Documentation
  ]

  #v(0.5cm)

  Copyright © #datetime.today().year() System Administrator

  #v(0.5cm)

  All rights reserved.

  #v(1cm)

  #text(style: "italic")[
    This documentation covers the complete Gautama NixOS infrastructure, \
    including all services, deployment procedures, and operational guidelines.
  ]

  #v(1cm)

  #grid(
    columns: 2,
    gutter: 1cm,
    [*Generated:*], [#datetime.today().display()],
    [*Version:*], [1.0],
    [*Format:*], [Typst PDF],
  )
]

#v(1fr)

#pagebreak()

// ============================================================================
// Table of Contents
// ============================================================================

#outline(
  title: "Table of Contents",
  indent: auto,
  depth: 3,
)

#pagebreak()

#outline(
  title: "List of Figures",
  target: figure.where(kind: image),
)

#pagebreak()

#outline(
  title: "List of Tables",
  target: figure.where(kind: table),
)

#pagebreak()

// ============================================================================
// Preface
// ============================================================================

#heading(numbering: none)[Preface]

This documentation provides comprehensive coverage of the Gautama NixOS infrastructure, a production-grade self-hosted system running on Apple Silicon hardware.

The system encompasses over 60 services, including databases, monitoring, networking, containers, and web applications, all managed declaratively through NixOS.

#info-box[
  *Key Features:*
  - Declarative configuration with NixOS flakes
  - Reproducible builds and deployments
  - Comprehensive monitoring with Prometheus and Grafana
  - Secure secret management with SOPS
  - Container orchestration with Podman Quadlet
  - Private certificate authority with step-ca
  - ZFS storage with automatic snapshots
  - Cloud backups to Backblaze B2
]

*Audience:*

This documentation is intended for system administrators, DevOps engineers, and technical users responsible for maintaining, deploying, or extending the Gautama infrastructure.

*Structure:*

The documentation is organized by topic, with each chapter covering a specific aspect of the system. Cross-references are provided throughout for related topics.

#pagebreak()

// ============================================================================
// Main Content
// ============================================================================

/// CONTENT WILL BE INSERTED HERE BY BUILD SCRIPT ///

// ============================================================================
// Colophon
// ============================================================================

#heading(numbering: none)[Colophon]

This book was typeset using Typst, a modern markup-based typesetting system designed for speed and ease of use.

*Tools Used:*
- *Typesetting:* Typst compiler
- *Conversion:* Pandoc for Markdown to Typst
- *Build System:* Nix with automatic rebuilds
- *Fonts:* Linux Libertine (text), Fira Code (code)
- *Graphics:* Inkscape, D2 diagrams

*Source:*

The source files for this documentation are maintained in Markdown format in the `/etc/nixos/docs/md/` directory and automatically converted to PDF during system rebuilds.

#v(1cm)

#align(center)[
  #text(style: "italic")[
    Built with Typst on NixOS
  ]
]
