{ config, lib, pkgs, ... }:

{
  # Quarto technical publishing system
  # Accessible via Tailscale network at https://quarto.vulcan.lan

  # Install Quarto and dependencies
  environment.systemPackages = with pkgs; [
    quarto
    pandoc
    texlive.combined.scheme-full # For PDF output
    R # For R integration
    python3 # For Python integration
    nodejs # For Observable JS
    deno # For Quarto extensions
  ];

  # Create Quarto service user
  users.users.quarto = {
    isSystemUser = true;
    group = "quarto";
    home = "/var/lib/quarto";
    createHome = true;
    description = "Quarto service user";
  };

  users.groups.quarto = { };

  # Create directories
  systemd.tmpfiles.rules = [
    "d /var/lib/quarto 0755 quarto quarto -"
    "d /var/lib/quarto/projects 0755 quarto quarto -"
    "d /var/lib/quarto/output 0755 quarto quarto -"
    "d /var/log/quarto 0755 quarto quarto -"
  ];

  # Quarto preview server service
  systemd.services.quarto = {
    description = "Quarto Publishing System Preview Server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "quarto";
      Group = "quarto";
      WorkingDirectory = "/var/lib/quarto/projects";

      # Start Quarto preview server
      # --host 0.0.0.0 allows Tailscale access
      # --port 4001 to avoid conflicts with Jekyll
      ExecStart = "${pkgs.quarto}/bin/quarto preview --host 0.0.0.0 --port 4001 --no-browser";

      Restart = "on-failure";
      RestartSec = "10s";

      # Environment
      Environment = [
        "HOME=/var/lib/quarto"
        "QUARTO_PRINT_STACK=true"
      ];

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/var/lib/quarto" "/var/log/quarto" ];

      # Logging
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  # Nginx reverse proxy configuration
  services.nginx.virtualHosts."quarto.vulcan.lan" = {
    forceSSL = true;
    sslCertificate = "/var/lib/nginx-certs/quarto.vulcan.lan.crt";
    sslCertificateKey = "/var/lib/nginx-certs/quarto.vulcan.lan.key";

    locations."/" = {
      proxyPass = "http://127.0.0.1:4001";
      proxyWebsockets = true; # For live preview
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support for live preview
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Increase timeout for long renders
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
      '';
    };
  };

  # Firewall: Only accessible via Tailscale/Nginx
  networking.firewall.allowedTCPPorts = [ ]; # Nginx handles external access

  # Certificate renewal for Quarto
  systemd.services.quarto-cert-renewal = {
    description = "Renew Quarto TLS Certificate";
    after = [ "step-ca.service" ];
    requires = [ "step-ca.service" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${config.security.sudo.package}/bin/sudo /etc/nixos/certs/renew-certificate.sh quarto.vulcan.lan -o /var/lib/nginx-certs -d 365 --owner nginx:nginx'";
    };
  };

  systemd.timers.quarto-cert-renewal = {
    description = "Timer for Quarto Certificate Renewal";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
      Unit = "quarto-cert-renewal.service";
    };
  };

  # Prometheus monitoring
  services.prometheus.scrapeConfigs = [
    {
      job_name = "quarto";
      static_configs = [{
        targets = [ "127.0.0.1:4001" ];
        labels = {
          service = "quarto";
          instance = "vulcan";
        };
      }];
      metrics_path = "/";
      scheme = "http";
    }
  ];
}
