{ config, lib, pkgs, ... }:

{
  # ZOHO API Integration Service
  # FastAPI service for interacting with ZOHO CRM, Mail, Desk, etc.
  # Accessible via Cloudflare Tunnel at api.example.com

  # Build ZOHO API container image
  # Container defined in /etc/nixos/containers/zoho-api/Containerfile

  # ZOHO API container using Quadlet
  virtualisation.quadlet.containers.zoho-api = {
    containerConfig = {
      # Use locally built image (build with: podman build -t localhost/zoho-api:latest ./containers/zoho-api/)
      image = "localhost/zoho-api:latest";

      # Port mapping - localhost only (Cloudflare Tunnel connects here)
      publishPorts = [ "127.0.0.1:4102:8080" ];

      # Environment variables from SOPS secrets
      environmentFiles = [ "/run/secrets/zoho-api-env" ];

      # Labels for monitoring
      labels = {
        service = "zoho-api";
        monitoring = "prometheus";
        access = "internet";
      };

      # Health check
      healthCmd = "curl -f http://localhost:8080/health || exit 1";
      healthInterval = "30s";
      healthTimeout = "10s";
      healthRetries = 3;
    };

    serviceConfig = {
      Restart = "always";
      RestartSec = "10s";
      TimeoutStartSec = "120";

      # Security: Run as unprivileged user
      User = "zoho-api";
      Group = "zoho-api";

      # Ensure environment file is ready
      After = [ "zoho-api-env-setup.service" ];
      Requires = [ "zoho-api-env-setup.service" ];
    };
  };

  # SOPS secrets for ZOHO OAuth
  sops.secrets."zoho-client-id" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets."zoho-client-secret" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets."zoho-refresh-token" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets."zoho-redirect-uri" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # Create ZOHO API environment file from SOPS secrets
  systemd.services.zoho-api-env-setup = {
    description = "Setup ZOHO API Environment File";
    before = [ "quadlet-zoho-api.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      mkdir -p /run/secrets
      cat > /run/secrets/zoho-api-env <<EOF
      ZOHO_CLIENT_ID=$(cat ${config.sops.secrets."zoho-client-id".path})
      ZOHO_CLIENT_SECRET=$(cat ${config.sops.secrets."zoho-client-secret".path})
      ZOHO_REFRESH_TOKEN=$(cat ${config.sops.secrets."zoho-refresh-token".path})
      ZOHO_REDIRECT_URI=$(cat ${config.sops.secrets."zoho-redirect-uri".path})
      ZOHO_API_DOMAIN=https://www.zohoapis.com
      ZOHO_ACCOUNTS_DOMAIN=https://accounts.zoho.com
      EOF
      chmod 600 /run/secrets/zoho-api-env
    '';
  };

  # Create ZOHO API service user
  users.users.zoho-api = {
    isSystemUser = true;
    group = "zoho-api";
    home = "/var/lib/zoho-api";
    createHome = true;
    description = "ZOHO API integration service user";
  };

  users.groups.zoho-api = { };

  # Create directories
  systemd.tmpfiles.rules = [
    "d /var/lib/zoho-api 0755 zoho-api zoho-api -"
    "d /var/log/zoho-api 0755 zoho-api zoho-api -"
  ];

  # Prometheus monitoring for ZOHO API service
  services.prometheus.scrapeConfigs = [
    {
      job_name = "zoho-api";
      static_configs = [{
        targets = [ "127.0.0.1:4102" ];
        labels = {
          service = "zoho-api";
          instance = "vulcan";
          access = "internet";
        };
      }];
      metrics_path = "/metrics";
      scheme = "http";
    }
  ];

  # Alertmanager rules for ZOHO API monitoring
  services.prometheus.rules = [
    ''
      groups:
        - name: zoho-api
          interval: 30s
          rules:
            # Alert if ZOHO API service is down
            - alert: ZOHOAPIDown
              expr: up{job="zoho-api"} == 0
              for: 2m
              labels:
                severity: critical
                service: zoho-api
              annotations:
                summary: "ZOHO API service is down"
                description: "ZOHO API integration service has been unreachable for more than 2 minutes."

            # Alert if ZOHO API has high error rate
            - alert: ZOHOAPIHighErrors
              expr: rate(zoho_api_requests_total{status="error"}[5m]) / rate(zoho_api_requests_total[5m]) > 0.1
              for: 5m
              labels:
                severity: warning
                service: zoho-api
              annotations:
                summary: "ZOHO API high error rate"
                description: "ZOHO API service is experiencing elevated error rates (>10%). Check logs with: journalctl -u quadlet-zoho-api -f"
    ''
  ];

  # Note: Actual internet access is provided by Cloudflare Tunnel
  # Configure in modules/services/cloudflared.nix
  # Example tunnel ingress:
  #   - hostname: api.example.com
  #     service: http://localhost:4102
}
