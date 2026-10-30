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
  my.datasets."ssd/appdata/aurral" = { };
  my.proxy."aurral.i".port = 8203;

  home-manager.users.mikkel.virtualisation.quadlet.containers.aurral = apps.container {
    name = "aurral";
    image = "ghcr.io/lklynet/aurral:latest";
    # Starts as root and switches to PUID/PGID like the linuxserver images; primary group
    # music because it works in the shared music tree.
    runAs = apps.runAs.linuxserverGroup apps.groups.music;
    ports = [ "8203:3001" ];
    networks = [ apps.network ];
    volumes = [
      "/srv/appdata/aurral:/config"
      "/storage/music/library:/media/music"
      "/storage/music/downloads:/media/downloads"
    ];
  };
}
