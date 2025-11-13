{ config, lib, pkgs, ... }:

{
  # Jekyll Static Site Generator - Public Internet Access
  # Container-based deployment for public websites via Cloudflare Tunnel
  # Sites accessible at configured domains (e.g., blog.example.com)

  # Build Jekyll container image
  # Container defined in /etc/nixos/containers/jekyll/Containerfile

  # Jekyll public container using Quadlet
  virtualisation.quadlet.containers.jekyll-public = {
    containerConfig = {
      # Use locally built image (build with: podman build -t localhost/jekyll:latest ./containers/jekyll/)
      image = "localhost/jekyll:latest";

      # Port mapping - localhost only (Cloudflare Tunnel connects here)
      publishPorts = [ "127.0.0.1:4100:4000" ];

      # Volume mounts for persistent site data
      volumes = [
        # Main sites directory - mount your Jekyll sites here
        "/var/lib/jekyll-public/sites:/site:Z"
        # Optional: Bundle cache for faster builds
        "/var/lib/jekyll-public/bundle:/usr/local/bundle:Z"
      ];

      # Environment variables
      environment = {
        TZ = "America/Los_Angeles";
        JEKYLL_ENV = "production"; # Production mode
      };

      # Labels for monitoring
      labels = {
        service = "jekyll-public";
        monitoring = "prometheus";
        access = "internet";
      };

      # Health check
      healthCmd = "wget --no-verbose --tries=1 --spider http://localhost:4000/ || exit 1";
      healthInterval = "30s";
      healthTimeout = "10s";
      healthRetries = 3;
    };

    serviceConfig = {
      Restart = "always";
      RestartSec = "10s";
      TimeoutStartSec = "120";

      # Security: Run as unprivileged user
      User = "jekyll-public";
      Group = "jekyll-public";
    };
  };

  # Create Jekyll public service user
  users.users.jekyll-public = {
    isSystemUser = true;
    group = "jekyll-public";
    home = "/var/lib/jekyll-public";
    createHome = true;
    description = "Jekyll public website user";
  };

  users.groups.jekyll-public = { };

  # Create directories for Jekyll public sites
  systemd.tmpfiles.rules = [
    "d /var/lib/jekyll-public 0755 jekyll-public jekyll-public -"
    "d /var/lib/jekyll-public/sites 0755 jekyll-public jekyll-public -"
    "d /var/lib/jekyll-public/bundle 0755 jekyll-public jekyll-public -"
  ];

  # Prometheus monitoring for Jekyll public container
  services.prometheus.scrapeConfigs = [
    {
      job_name = "jekyll-public";
      static_configs = [{
        targets = [ "127.0.0.1:4100" ];
        labels = {
          service = "jekyll-public";
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
  #   - hostname: blog.example.com
  #     service: http://localhost:4100
}
