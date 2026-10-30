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
  my.datasets."ssd/appdata/sabnzbd" = { };
  my.proxy."sabnzbd.i".port = 8104;

  home-manager.users.mikkel.virtualisation.quadlet.containers.sabnzbd = apps.container {
    name = "sabnzbd";
    image = "docker.io/linuxserver/sabnzbd:latest";
    runAs = apps.runAs.linuxserver;
    ports = [ "8104:8080" ];
    networks = [ apps.network ];
    # SABnzbd answers only to host names in its host_whitelist (Config → Special): it needs
    # "sabnzbd" (the other apps) and sabnzbd.i.<domain> (Caddy).
    volumes = [
      "/srv/appdata/sabnzbd:/config"
      # Downloads, one folder per category, at the same paths the *arr apps see them.
      "/storage/media/downloads/usenet:/media/downloads/usenet"
      # The music category lives in storage/music, next to Lidarr's library, so its imports
      # stay moves within one dataset. Mounted over the category folder, so SABnzbd's
      # settings and Lidarr's paths (/media/downloads/usenet/music) stay as they are.
      "/storage/music/downloads/usenet/music:/media/downloads/usenet/music"
    ];
  };
}
