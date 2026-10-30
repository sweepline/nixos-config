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
  my.datasets."ssd/appdata/lidarr" = { };
  my.proxy."lidarr.i".port = 8202;

  home-manager.users.mikkel.virtualisation.quadlet.containers.lidarr = apps.container {
    name = "lidarr";
    # Nightly on purpose: newer Lidarr releases than the stable channel.
    image = "lscr.io/linuxserver/lidarr:nightly";
    # Primary group music: Lidarr moves, retags and deletes files that slskd (another user)
    # downloaded into the shared music tree.
    runAs = apps.runAs.linuxserverGroup apps.groups.music;
    ports = [ "8202:8686" ];
    networks = [ apps.network ];
    volumes = [
      "/srv/appdata/lidarr:/config"
      # Root folder /media/music.
      "/storage/music/library:/media/music"
      # Finished downloads at the paths SABnzbd and slskd report:
      # /media/downloads/usenet/music, /media/downloads/slsk/music, /media/downloads/bandcamp.
      "/storage/music/downloads:/media/downloads"
    ];
  };
}
