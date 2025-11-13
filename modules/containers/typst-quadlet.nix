{ config, lib, pkgs, ... }:

{
  # Typst typesetting system as a web service
  # Using typst-live for web-based editing
  # Accessible via Tailscale network at https://typst.vulcan.lan

  # Install Typst CLI for local use
  environment.systemPackages = with pkgs; [
    typst
  ];

  # Typst web service using container (typst-live alternative)
  virtualisation.quadlet.containers.typst = {
    containerConfig = {
      image = "docker.io/mtshiba/typst-jp:latest"; # Typst with web interface
      autoUpdate = "registry";
      pull = "always";

      # Port mapping
      publishPorts = [ "127.0.0.1:4002:3000" ]; # Internal only, Nginx proxies

      # Volume mounts for persistent data
      volumes = [
        "/var/lib/typst/documents:/workspace:Z"
        "/var/lib/typst/cache:/cache:Z"
      ];

      # Environment variables
      environment = {
        TZ = "America/Los_Angeles";
      };

      # Labels for monitoring
      labels = {
        service = "typst";
        monitoring = "prometheus";
      };
    };

    serviceConfig = {
      Restart = "always";
      RestartSec = "10s";
      TimeoutStartSec = "300";
    };
  };

  # Create directories for Typst
  systemd.tmpfiles.rules = [
    "d /var/lib/typst 0755 root root -"
    "d /var/lib/typst/documents 0755 root root -"
    "d /var/lib/typst/cache 0755 root root -"
  ];

  # Nginx reverse proxy configuration
  services.nginx.virtualHosts."typst.vulcan.lan" = {
    forceSSL = true;
    sslCertificate = "/var/lib/nginx-certs/typst.vulcan.lan.crt";
    sslCertificateKey = "/var/lib/nginx-certs/typst.vulcan.lan.key";

    locations."/" = {
      proxyPass = "http://127.0.0.1:4002";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Increase timeouts for large document compilation
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
        client_max_body_size 50M;
      '';
    };
  };

  # Certificate renewal for Typst
  systemd.services.typst-cert-renewal = {
    description = "Renew Typst TLS Certificate";
    after = [ "step-ca.service" ];
    requires = [ "step-ca.service" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${config.security.sudo.package}/bin/sudo /etc/nixos/certs/renew-certificate.sh typst.vulcan.lan -o /var/lib/nginx-certs -d 365 --owner nginx:nginx'";
    };
  };

  systemd.timers.typst-cert-renewal = {
    description = "Timer for Typst Certificate Renewal";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
      Unit = "typst-cert-renewal.service";
    };
  };

  # Prometheus monitoring via blackbox exporter
  services.prometheus.scrapeConfigs = [
    {
      job_name = "typst-http";
      metrics_path = "/probe";
      params = {
        module = [ "http_2xx" ];
      };
      static_configs = [{
        targets = [ "https://typst.vulcan.lan" ];
      }];
      relabel_configs = [
        {
          source_labels = [ "__address__" ];
          target_label = "__param_target";
        }
        {
          source_labels = [ "__param_target" ];
          target_label = "instance";
        }
        {
          target_label = "__address__";
          replacement = "127.0.0.1:9115"; # Blackbox exporter
        }
        {
          target_label = "service";
          replacement = "typst";
        }
      ];
    }
  ];
}
