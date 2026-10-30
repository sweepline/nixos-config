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
  my.datasets."ssd/appdata/prowlarr" = { };
  my.proxy."prowlarr.i".port = 8103;

  home-manager.users.mikkel.virtualisation.quadlet.containers.prowlarr = apps.container {
    name = "prowlarr";
    image = "docker.io/linuxserver/prowlarr:latest";
    runAs = apps.runAs.linuxserver;
    ports = [ "8103:9696" ];
    networks = [ apps.network ];
    volumes = [ "/srv/appdata/prowlarr:/config" ];
  };
}
