{ config, lib, pkgs, ... }:

{
  # Quarto Publishing System - Public Internet Access
  # Container-based deployment for public documentation/websites via Cloudflare Tunnel
  # Sites accessible at configured domains (e.g., docs.example.com)

  # Build Quarto container image
  # Container defined in /etc/nixos/containers/quarto/Containerfile

  # Quarto public container using Quadlet
  virtualisation.quadlet.containers.quarto-public = {
    containerConfig = {
      # Use locally built image (build with: podman build -t localhost/quarto:latest ./containers/quarto/)
      image = "localhost/quarto:latest";

      # Port mapping - localhost only (Cloudflare Tunnel connects here)
      publishPorts = [ "127.0.0.1:4101:4001" ];

      # Volume mounts for persistent project data
      volumes = [
        # Main projects directory - mount your Quarto projects here
        "/var/lib/quarto-public/projects:/projects:Z"
        # Cache directory for faster rendering
        "/var/lib/quarto-public/cache:/home/quarto/.cache:Z"
      ];

      # Environment variables
      environment = {
        TZ = "America/Los_Angeles";
        QUARTO_ENV = "production"; # Production mode
        QUARTO_PYTHON = "/usr/bin/python3";
        QUARTO_R = "/usr/bin/R";
      };

      # Labels for monitoring
      labels = {
        service = "quarto-public";
        monitoring = "prometheus";
        access = "internet";
      };

      # Health check
      healthCmd = "curl -f http://localhost:4001/ || exit 1";
      healthInterval = "30s";
      healthTimeout = "10s";
      healthRetries = 3;
    };

    serviceConfig = {
      Restart = "always";
      RestartSec = "10s";
      TimeoutStartSec = "180"; # Quarto can be slow to start

      # Security: Run as unprivileged user
      User = "quarto-public";
      Group = "quarto-public";
    };
  };

  # Create Quarto public service user
  users.users.quarto-public = {
    isSystemUser = true;
    group = "quarto-public";
    home = "/var/lib/quarto-public";
    createHome = true;
    description = "Quarto public website user";
  };

  users.groups.quarto-public = { };

  # Create directories for Quarto public projects
  systemd.tmpfiles.rules = [
    "d /var/lib/quarto-public 0755 quarto-public quarto-public -"
    "d /var/lib/quarto-public/projects 0755 quarto-public quarto-public -"
    "d /var/lib/quarto-public/cache 0755 quarto-public quarto-public -"
  ];

  # Prometheus monitoring for Quarto public container
  services.prometheus.scrapeConfigs = [
    {
      job_name = "quarto-public";
      static_configs = [{
        targets = [ "127.0.0.1:4101" ];
        labels = {
          service = "quarto-public";
          instance = "vulcan";
          access = "internet";
        };
      }];
      metrics_path = "/";
      scheme = "http";
    }
  ];

  # Note: Actual internet access is provided by Cloudflare Tunnel
  # Configure in modules/services/cloudflared.nix
  # Example tunnel ingress:
  #   - hostname: docs.example.com
  #     service: http://localhost:4101
}
