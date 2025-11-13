{ config, lib, pkgs, ... }:

{
  # Redmine project management system
  # Accessible via Tailscale network at https://redmine.vulcan.lan

  # PostgreSQL database for Redmine
  services.postgresql = {
    ensureDatabases = [ "redmine" ];
    ensureUsers = [
      {
        name = "redmine";
        ensureDBOwnership = true;
      }
    ];
  };

  # SOPS secret for Redmine database password
  sops.secrets."redmine-db-password" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # SOPS secret for Redmine secret key base
  sops.secrets."redmine-secret-key-base" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # Redmine container using Quadlet
  virtualisation.quadlet.containers.redmine = {
    containerConfig = {
      image = "docker.io/redmine:5-alpine"; # Latest stable Redmine
      autoUpdate = "registry";
      pull = "always";

      # Port mapping - internal only
      publishPorts = [ "127.0.0.1:4003:3000" ];

      # Volume mounts for persistent data
      volumes = [
        "/var/lib/redmine/files:/usr/src/redmine/files:Z"
        "/var/lib/redmine/plugins:/usr/src/redmine/plugins:Z"
        "/var/lib/redmine/themes:/usr/src/redmine/themes:Z"
      ];

      # Environment variables
      environmentFiles = [ "/run/secrets/redmine-env" ];

      # Labels
      labels = {
        service = "redmine";
        monitoring = "prometheus";
      };

      # Health check
      healthCmd = "curl -f http://localhost:3000/ || exit 1";
      healthInterval = "30s";
      healthTimeout = "10s";
      healthRetries = 3;
    };

    serviceConfig = {
      Restart = "always";
      RestartSec = "10s";
      TimeoutStartSec = "300";

      # Ensure PostgreSQL is ready
      After = [ "postgresql.service" ];
      Requires = [ "postgresql.service" ];
    };
  };

  # Create Redmine environment file from SOPS secrets
  systemd.services.redmine-env-setup = {
    description = "Setup Redmine Environment File";
    before = [ "quadlet-redmine.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      mkdir -p /run/secrets
      cat > /run/secrets/redmine-env <<EOF
      REDMINE_DB_POSTGRES=127.0.0.1
      REDMINE_DB_PORT=5432
      REDMINE_DB_DATABASE=redmine
      REDMINE_DB_USERNAME=redmine
      REDMINE_DB_PASSWORD=$(cat ${config.sops.secrets."redmine-db-password".path})
      REDMINE_SECRET_KEY_BASE=$(cat ${config.sops.secrets."redmine-secret-key-base".path})
      REDMINE_HTTPS=true
      REDMINE_RELATIVE_URL_ROOT=
      EOF
      chmod 600 /run/secrets/redmine-env
    '';
  };

  # Create directories for Redmine data
  systemd.tmpfiles.rules = [
    "d /var/lib/redmine 0755 root root -"
    "d /var/lib/redmine/files 0755 root root -"
    "d /var/lib/redmine/plugins 0755 root root -"
    "d /var/lib/redmine/themes 0755 root root -"
  ];

  # Nginx reverse proxy configuration
  services.nginx.virtualHosts."redmine.vulcan.lan" = {
    forceSSL = true;
    sslCertificate = "/var/lib/nginx-certs/redmine.vulcan.lan.crt";
    sslCertificateKey = "/var/lib/nginx-certs/redmine.vulcan.lan.key";

    locations."/" = {
      proxyPass = "http://127.0.0.1:4003";
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $host;

        # Redmine file uploads
        client_max_body_size 100M;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;

        # Disable buffering for large uploads
        proxy_request_buffering off;
      '';
    };
  };

  # Firewall: Only accessible via Tailscale/Nginx
  networking.firewall.allowedTCPPorts = [ ]; # Nginx handles access

  # Certificate renewal for Redmine
  systemd.services.redmine-cert-renewal = {
    description = "Renew Redmine TLS Certificate";
    after = [ "step-ca.service" ];
    requires = [ "step-ca.service" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${config.security.sudo.package}/bin/sudo /etc/nixos/certs/renew-certificate.sh redmine.vulcan.lan -o /var/lib/nginx-certs -d 365 --owner nginx:nginx'";
    };
  };

  systemd.timers.redmine-cert-renewal = {
    description = "Timer for Redmine Certificate Renewal";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
      Unit = "redmine-cert-renewal.service";
    };
  };

  # Prometheus monitoring via blackbox exporter
  services.prometheus.scrapeConfigs = [
    {
      job_name = "redmine-http";
      metrics_path = "/probe";
      params = {
        module = [ "http_2xx" ];
      };
      static_configs = [{
        targets = [ "https://redmine.vulcan.lan" ];
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
          replacement = "redmine";
        }
      ];
    }
  ];

  # Backup Redmine database daily
  services.postgresqlBackup = {
    databases = [ "redmine" ];
  };
}
