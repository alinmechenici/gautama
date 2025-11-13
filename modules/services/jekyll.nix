{ config, lib, pkgs, ... }:

{
  # Jekyll static site generator service
  # Accessible via Tailscale network at https://jekyll.vulcan.lan

  # Install Jekyll and dependencies
  environment.systemPackages = with pkgs; [
    jekyll
    ruby
    bundler
    nodejs # For some Jekyll plugins
  ];

  # Create Jekyll service user
  users.users.jekyll = {
    isSystemUser = true;
    group = "jekyll";
    home = "/var/lib/jekyll";
    createHome = true;
    description = "Jekyll service user";
  };

  users.groups.jekyll = { };

  # Create directories
  systemd.tmpfiles.rules = [
    "d /var/lib/jekyll 0755 jekyll jekyll -"
    "d /var/lib/jekyll/sites 0755 jekyll jekyll -"
    "d /var/log/jekyll 0755 jekyll jekyll -"
  ];

  # Jekyll development server service
  systemd.services.jekyll = {
    description = "Jekyll Static Site Generator Server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "jekyll";
      Group = "jekyll";
      WorkingDirectory = "/var/lib/jekyll/sites";

      # Start Jekyll server
      # Listens on all interfaces so Tailscale can reach it
      ExecStart = "${pkgs.jekyll}/bin/jekyll serve --host 0.0.0.0 --port 4000 --livereload --incremental";

      Restart = "on-failure";
      RestartSec = "10s";

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/var/lib/jekyll" "/var/log/jekyll" ];

      # Logging
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  # Nginx reverse proxy configuration
  services.nginx.virtualHosts."jekyll.vulcan.lan" = {
    forceSSL = true;
    sslCertificate = "/var/lib/nginx-certs/jekyll.vulcan.lan.crt";
    sslCertificateKey = "/var/lib/nginx-certs/jekyll.vulcan.lan.key";

    locations."/" = {
      proxyPass = "http://127.0.0.1:4000";
      proxyWebsockets = true; # For LiveReload
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # LiveReload support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
      '';
    };
  };

  # Firewall: Only accessible via Tailscale
  # Port 4000 not exposed to public, only via Nginx
  networking.firewall.allowedTCPPorts = [ ]; # Nginx handles external access

  # Certificate renewal for Jekyll
  systemd.services.jekyll-cert-renewal = {
    description = "Renew Jekyll TLS Certificate";
    after = [ "step-ca.service" ];
    requires = [ "step-ca.service" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${config.security.sudo.package}/bin/sudo /etc/nixos/certs/renew-certificate.sh jekyll.vulcan.lan -o /var/lib/nginx-certs -d 365 --owner nginx:nginx'";
    };
  };

  systemd.timers.jekyll-cert-renewal = {
    description = "Timer for Jekyll Certificate Renewal";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
      Unit = "jekyll-cert-renewal.service";
    };
  };

  # Prometheus monitoring (basic HTTP check)
  services.prometheus.scrapeConfigs = [
    {
      job_name = "jekyll";
      static_configs = [{
        targets = [ "127.0.0.1:4000" ];
        labels = {
          service = "jekyll";
          instance = "vulcan";
        };
      }];
      # Basic HTTP probe
      metrics_path = "/";
      scheme = "http";
    }
  ];
}
