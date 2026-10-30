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
  my.datasets."ssd/appdata/radarr" = { };
  my.proxy."radarr.i".port = 8102;

  home-manager.users.mikkel.virtualisation.quadlet.containers.radarr = apps.container {
    name = "radarr";
    image = "docker.io/linuxserver/radarr:latest";
    runAs = apps.runAs.linuxserver;
    ports = [ "8102:7878" ];
    networks = [ apps.network ];
    volumes = [
      "/srv/appdata/radarr:/config"
      # Root folder /media/movies, and SABnzbd's finished downloads in
      # /media/downloads/usenet/movies (same path as in SABnzbd).
      "/storage/media:/media"
    ];
  };
}
