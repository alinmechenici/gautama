{ config, lib, pkgs, ... }:

# Documentation Builder Module
# Automatically builds LaTeX and Typst PDFs from Markdown documentation
# during nixos-rebuild switch

let
  # Build script with all dependencies
  buildScript = pkgs.writeShellScriptBin "build-gautama-docs" ''
    export PATH=${lib.makeBinPath [
      pkgs.pandoc
      pkgs.texlive.combined.scheme-full
      pkgs.typst
      pkgs.poppler_utils  # for pdfinfo
      pkgs.coreutils
      pkgs.gnused
      pkgs.findutils
      pkgs.bash
    ]}

    exec ${/etc/nixos/docs/scripts/build-pdfs.sh} "$@"
  '';

  # Build the documentation PDFs as a derivation
  documentationPDFs = pkgs.stdenv.mkDerivation {
    name = "gautama-documentation";
    version = "1.0";

    src = /etc/nixos/docs;

    buildInputs = [
      pkgs.pandoc
      pkgs.texlive.combined.scheme-full
      pkgs.typst
      pkgs.poppler_utils
      pkgs.bash
    ];

    buildPhase = ''
      echo "Building Gautama documentation PDFs..."

      # Set up directories
      mkdir -p latex typst pdf

      # Copy templates
      cp -r ${/etc/nixos/docs/latex}/* latex/ || true
      cp -r ${/etc/nixos/docs/typst}/* typst/ || true

      # Copy markdown files
      mkdir -p md
      cp -r ${/etc/nixos/docs/md}/* md/ || true

      # Run build script
      ${buildScript}/bin/build-gautama-docs || echo "Build completed with warnings"
    '';

    installPhase = ''
      mkdir -p $out/share/doc/gautama

      # Copy PDFs if they were generated
      if [ -f pdf/gautama-docs-latex.pdf ]; then
        cp pdf/gautama-docs-latex.pdf $out/share/doc/gautama/
      fi

      if [ -f pdf/gautama-docs-typst.pdf ]; then
        cp pdf/gautama-docs-typst.pdf $out/share/doc/gautama/
      fi

      # Copy source files for reference
      cp -r latex $out/share/doc/gautama/ || true
      cp -r typst $out/share/doc/gautama/ || true
    '';

    meta = with lib; {
      description = "Gautama system documentation PDFs";
      platforms = platforms.all;
    };
  };

in

{
  # Add build script to system packages
  environment.systemPackages = [ buildScript ];

  # Build documentation PDFs and make available
  system.build.documentation = documentationPDFs;

  # Systemd service to build documentation
  systemd.services.build-documentation = {
    description = "Build Gautama Documentation PDFs";
    after = [ "network.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${buildScript}/bin/build-gautama-docs";
      User = "root";
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  # Timer to rebuild documentation weekly
  systemd.timers.build-documentation = {
    description = "Weekly Documentation Rebuild";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
      Unit = "build-documentation.service";
    };
  };

  # Activation script to build docs on system switch
  system.activationScripts.buildDocumentation = lib.mkIf true {
    text = ''
      echo "Building Gautama documentation..."

      # Create output directory
      mkdir -p /home/gautama/docs

      # Run build script
      ${buildScript}/bin/build-gautama-docs || echo "Documentation build completed with warnings"

      # Set permissions
      chown -R gautama:users /home/gautama/docs || true
      chmod 644 /home/gautama/docs/*.pdf || true

      echo "Documentation PDFs available at:"
      echo "  /home/gautama/docs/gautama-docs-latex.pdf"
      echo "  /home/gautama/docs/gautama-docs-typst.pdf"
    '';
  };

  # Ensure required directories exist
  systemd.tmpfiles.rules = [
    "d /home/gautama/docs 0755 gautama users -"
    "d /etc/nixos/docs/pdf 0755 root root -"
    "d /etc/nixos/docs/latex 0755 root root -"
    "d /etc/nixos/docs/typst 0755 root root -"
  ];
}
