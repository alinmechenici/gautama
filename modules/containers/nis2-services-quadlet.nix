{ config, lib, pkgs, ... }:

{
  # NIS2 Services Application - Staging on Gautama
  # This module BUILDS the Docker image using Nix and runs it with Quadlet
  # Accessible via Tailscale at https://services.nis2.vulcan.lan

  # Build Docker image using NixOS dockerTools
  system.build.nis2-services-image = pkgs.dockerTools.buildLayeredImage {
    name = "nis2-services";
    tag = "staging";

    contents = with pkgs; [
      ruby_3_2
      postgresql
      nodejs
      yarn
      git
      busybox
      cacert
    ];

    config = {
      WorkingDir = "/app";
      Env = [
        "RAILS_ENV=staging"
        "PORT=3101"
        "RAILS_LOG_TO_STDOUT=true"
      ];
      ExposedPorts = {
        "3101/tcp" = {};
      };
    };

    extraCommands = ''
      mkdir -p app
      mkdir -p tmp
      mkdir -p log
    '';
  };

  # SOPS secrets for Supabase
  sops.secrets."nis2-services-supabase-url" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets."nis2-services-supabase-key" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets."nis2-services-database-url" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets."nis2-services-secret-key-base" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # Create environment file from SOPS secrets
  systemd.services.nis2-services-env-setup = {
    description = "Setup NIS2 Services Environment File";
    before = [ "quadlet-nis2-services.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      mkdir -p /run/secrets
      cat > /run/secrets/nis2-services-env <<EOF
      SUPABASE_URL=$(cat ${config.sops.secrets."nis2-services-supabase-url".path})
      SUPABASE_ANON_KEY=$(cat ${config.sops.secrets."nis2-services-supabase-key".path})
      SUPABASE_DATABASE_URL=$(cat ${config.sops.secrets."nis2-services-database-url".path})
      SUPABASE_SCHEMA=nis2_services
      SECRET_KEY_BASE=$(cat ${config.sops.secrets."nis2-services-secret-key-base".path})
      RAILS_ENV=staging
      PORT=3101
      RAILS_LOG_TO_STDOUT=true
      EOF
      chmod 600 /run/secrets/nis2-services-env
    '';
  };

  # NIS2 Services container using Quadlet
  virtualisation.quadlet.containers.nis2-services = {
    containerConfig = {
      # Use the Nix-built image
      # After building: podman load < /nix/store/...-docker-image-nis2-services.tar.gz
      image = "localhost/nis2-services:staging";

      # Port mapping - localhost only (Nginx proxies)
      publishPorts = [ "127.0.0.1:3101:3101" ];

      # Volume mounts
      volumes = [
        # App code (mount from git checkout)
        "/var/lib/nis2-apps/services:/app:Z"
        # Logs
        "/var/lib/nis2-services/log:/app/log:Z"
        # Tmp files
        "/var/lib/nis2-services/tmp:/app/tmp:Z"
      ];

      # Environment from secrets
      environmentFiles = [ "/run/secrets/nis2-services-env" ];

      # Labels
      labels = {
        service = "nis2-services";
        monitoring = "prometheus";
        access = "tailscale";
      };

      # Health check
      healthCmd = "curl -f http://localhost:3101/health || exit 1";
      healthInterval = "30s";
      healthTimeout = "10s";
      healthRetries = 3;
    };

    serviceConfig = {
      Restart = "always";
      RestartSec = "10s";
      TimeoutStartSec = "300";  # Rails can be slow to start

      # Run as service user
      User = "nis2-services";
      Group = "nis2-services";

      # Dependencies
      After = [ "nis2-services-env-setup.service" ];
      Requires = [ "nis2-services-env-setup.service" ];
    };
  };

  # Create service user
  users.users.nis2-services = {
    isSystemUser = true;
    group = "nis2-services";
    home = "/var/lib/nis2-services";
    createHome = true;
    description = "NIS2 Services application user";
  };

  users.groups.nis2-services = { };

  # Create directories
  systemd.tmpfiles.rules = [
    "d /var/lib/nis2-services 0755 nis2-services nis2-services -"
    "d /var/lib/nis2-services/log 0755 nis2-services nis2-services -"
    "d /var/lib/nis2-services/tmp 0755 nis2-services nis2-services -"
    "d /var/lib/nis2-apps 0755 nis2-services nis2-services -"
    "d /var/lib/nis2-apps/services 0755 nis2-services nis2-services -"
  ];

  # Nginx reverse proxy configuration
  services.nginx.virtualHosts."services.nis2.vulcan.lan" = {
    forceSSL = true;
    sslCertificate = "/var/lib/nginx-certs/services.nis2.vulcan.lan.crt";
    sslCertificateKey = "/var/lib/nginx-certs/services.nis2.vulcan.lan.key";

    locations."/" = {
      proxyPass = "http://127.0.0.1:3101";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Rails file uploads
        client_max_body_size 100M;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
      '';
    };
  };

  # Certificate renewal
  systemd.services.nis2-services-cert-renewal = {
    description = "Renew NIS2 Services TLS Certificate";
    after = [ "step-ca.service" ];
    requires = [ "step-ca.service" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${config.security.sudo.package}/bin/sudo /etc/nixos/certs/renew-certificate.sh services.nis2.vulcan.lan -o /var/lib/nginx-certs -d 365 --owner nginx:nginx'";
    };
  };

  systemd.timers.nis2-services-cert-renewal = {
    description = "Timer for NIS2 Services Certificate Renewal";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
      Unit = "nis2-services-cert-renewal.service";
    };
  };

  # Prometheus monitoring
  services.prometheus.scrapeConfigs = [
    {
      job_name = "nis2-services";
      static_configs = [{
        targets = [ "127.0.0.1:3101" ];
        labels = {
          service = "nis2-services";
          instance = "vulcan";
          environment = "staging";
        };
      }];
      metrics_path = "/health";
      scheme = "http";
    }
  ];

  # Build script to create and load the image
  # Run: nix-build -A system.build.nis2-services-image
  # Then: podman load < result
  # Or create a helper script:

  environment.systemPackages = [
    (pkgs.writeScriptBin "nis2-build-images" ''
      #!/bin/sh
      echo "Building NIS2 Docker images with Nix..."

      # Build the image
      nix-build '<nixpkgs/nixos>' -A system.build.nis2-services-image -o /tmp/nis2-services-image

      # Load into Podman
      podman load < /tmp/nis2-services-image

      echo "Image loaded successfully!"
      echo "Start container with: systemctl start quadlet-nis2-services"
    '')
  ];
}
