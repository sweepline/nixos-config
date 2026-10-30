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
  my.datasets."ssd/appdata/bazarr" = { };
  my.proxy."bazarr.i".port = 8105;

  home-manager.users.mikkel.virtualisation.quadlet.containers.bazarr = apps.container {
    name = "bazarr";
    image = "docker.io/linuxserver/bazarr:latest";
    runAs = apps.runAs.linuxserver;
    ports = [ "8105:6767" ];
    networks = [ apps.network ];
    volumes = [
      "/srv/appdata/bazarr:/config"
      # Subtitles are written next to the videos, at the paths Sonarr and Radarr report.
      "/storage/media:/media"
    ];
  };
}
