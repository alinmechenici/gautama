{ pkgs, lib, ... }:

# NixOS module that BUILDS Docker image for NIS2 Services app
# This demonstrates how NixOS can build Docker images directly

let
  appName = "nis2-services";
  appPort = "3101";  # Staging port
  rubyVersion = pkgs.ruby_3_2;

  # Build the Docker image using dockerTools
  serviceImage = pkgs.dockerTools.buildLayeredImage {
    name = appName;
    tag = "latest";

    contents = with pkgs; [
      rubyVersion
      postgresql
      nodejs
      yarn
      busybox  # For basic shell commands
      cacert   # For SSL
    ];

    config = {
      Cmd = [ "bundle" "exec" "rails" "server" "-b" "0.0.0.0" "-p" appPort ];
      WorkingDir = "/app";
      Env = [
        "RAILS_ENV=staging"
        "PORT=${appPort}"
      ];
      ExposedPorts = {
        "${appPort}/tcp" = {};
      };
    };

    # Copy application code
    # In real usage, this would copy from the actual app directory
    extraCommands = ''
      mkdir -p app
      # Copy app files here
      # cp -r ${../../services}/* app/ || true
    '';
  };

in

{
  # Build the image and make it available
  # Usage: nix-build -A nis2-services-image
  # Then: podman load < result

  # Or include in system configuration to auto-build
  system.build.nis2-services-image = serviceImage;

  # Also expose as a package
  environment.systemPackages = [ serviceImage ];
}
