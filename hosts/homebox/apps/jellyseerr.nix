{
  config,
  lib,
  pkgs,
  ...
}:
let
  apps = import ./lib.nix { inherit config lib pkgs; };
  # The image runs as its own user `node` (1000). Without keep-id that is not mikkel but
  # host UID 100999, so it is isolated as it is (and its files already belong to that UID).
  owner = apps.hostId 1000;
in
{
  my.datasets."ssd/appdata/jellyseerr" = {
    inherit owner;
    group = owner;
    mode = "0700";
  };

  my.proxy."jellyseerr.i" = {
    port = 8100;
    maintenance = true;
  };
  my.proxy."request" = {
    port = 8100;
    public = true;
    maintenance = true;
  };

  home-manager.users.mikkel.virtualisation.quadlet.containers.jellyseerr = lib.mkMerge [
    (apps.container {
      name = "jellyseerr";
      image = "ghcr.io/seerr-team/seerr:latest";
      ports = [ "8100:5055" ];
      # Reaches Jellyfin, Sonarr and Radarr by name.
      networks = [ apps.network ];
      volumes = [ "/srv/appdata/jellyseerr:/app/config" ];
      environments.LOG_LEVEL = "debug";
    })
    {
      containerConfig = {
        noNewPrivileges = true;
        # Reaps the Node.js process's children (as `init: true` did in compose).
        runInit = true;
        healthCmd = "wget --no-verbose --tries=1 --spider http://localhost:5055/api/v1/settings/public || exit 1";
        healthStartPeriod = "20s";
        healthInterval = "15s";
        healthTimeout = "3s";
        healthRetries = 3;
      };
    }
  ];
}
