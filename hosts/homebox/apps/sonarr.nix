{
  config,
  lib,
  pkgs,
  ...
}:
let
  apps = import ./lib.nix { inherit config lib pkgs; };
in
{
  my.datasets."ssd/appdata/sonarr" = { };
  my.proxy."sonarr.i".port = 8101;

  home-manager.users.mikkel.virtualisation.quadlet.containers.sonarr = apps.container {
    name = "sonarr";
    image = "docker.io/linuxserver/sonarr:latest";
    runAs = apps.runAs.linuxserver;
    ports = [ "8101:8989" ];
    networks = [ apps.network ];
    volumes = [
      "/srv/appdata/sonarr:/config"
      # Root folders /media/shows and /media/anime, and SABnzbd's finished downloads in
      # /media/downloads/usenet/{shows,anime} (same path as in SABnzbd).
      "/storage/media:/media"
    ];
  };
}
