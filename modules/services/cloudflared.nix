{ config, lib, pkgs, ... }:

{
  # Cloudflare Tunnel (cloudflared) - Secure tunnel to Cloudflare Edge
  # Provides public internet access to local services without opening firewall ports
  # No inbound connections needed - tunnel establishes outbound connection to Cloudflare

  # Install cloudflared package
  environment.systemPackages = with pkgs; [
    cloudflared
  ];

  # SOPS secret for Cloudflare Tunnel credentials
  # Generated during tunnel creation: cloudflared tunnel create <name>
  sops.secrets."cloudflare-tunnel-credentials" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # SOPS secret for tunnel configuration
  # Contains tunnel ID and ingress rules
  sops.secrets."cloudflare-tunnel-config" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # Create cloudflared configuration directory
  systemd.tmpfiles.rules = [
    "d /etc/cloudflared 0755 root root -"
    "L+ /etc/cloudflared/credentials.json - - - - ${config.sops.secrets."cloudflare-tunnel-credentials".path}"
    "L+ /etc/cloudflared/config.yml - - - - ${config.sops.secrets."cloudflare-tunnel-config".path}"
  ];

  # Cloudflare Tunnel systemd service
  systemd.services.cloudflared = {
    description = "Cloudflare Tunnel";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "root"; # Required for binding to privileged ports if needed
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --config /etc/cloudflared/config.yml --metrics 127.0.0.1:2000 run";
      Restart = "always";
      RestartSec = "5s";
      TimeoutStopSec = "30s";

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/var/log" ];

      # Logging
      StandardOutput = "journal";
      StandardError = "journal";
      SyslogIdentifier = "cloudflared";
    };

    # Log output
    environment = {
      TUNNEL_METRICS = "127.0.0.1:2000";
      TUNNEL_LOGLEVEL = "info";
    };
  };

  # Prometheus monitoring for Cloudflare Tunnel
  services.prometheus.scrapeConfigs = [
    {
      job_name = "cloudflared";
      static_configs = [{
        targets = [ "127.0.0.1:2000" ]; # cloudflared metrics endpoint
        labels = {
          service = "cloudflared";
          instance = "vulcan";
        };
      }];
    }
  ];

  # Alertmanager rules for tunnel monitoring
  services.prometheus.rules = [
    ''
      groups:
        - name: cloudflared
          interval: 30s
          rules:
            # Alert if tunnel is down
            - alert: CloudflareTunnelDown
              expr: up{job="cloudflared"} == 0
              for: 2m
              labels:
                severity: critical
                service: cloudflared
              annotations:
                summary: "Cloudflare Tunnel is down"
                description: "Cloudflare Tunnel has been unreachable for more than 2 minutes. Public websites may be inaccessible."

            # Alert if tunnel has high error rate
            - alert: CloudflareTunnelHighErrors
              expr: rate(cloudflared_tunnel_request_errors_total[5m]) > 0.05
              for: 5m
              labels:
                severity: warning
                service: cloudflared
              annotations:
                summary: "Cloudflare Tunnel high error rate"
                description: "Cloudflare Tunnel is experiencing elevated error rates (>5%). Check logs with: journalctl -u cloudflared -f"

            # Alert if tunnel connection count is zero
            - alert: CloudflareTunnelNoConnections
              expr: cloudflared_tunnel_ha_connections < 1
              for: 5m
              labels:
                severity: critical
                service: cloudflared
              annotations:
                summary: "Cloudflare Tunnel has no active connections"
                description: "Cloudflare Tunnel has lost all connections to Cloudflare edge. Public access is unavailable."
    ''
  ];

  # No firewall rules needed - tunnel uses outbound connections only
  # This is the key benefit of Cloudflare Tunnel: no inbound ports required
}
