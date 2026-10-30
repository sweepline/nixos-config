{
  config,
  lib,
  pkgs,
  ...
}:
let
  apps = import ./lib.nix { inherit config lib pkgs; };
  # Own user (isolated: Soulseek peers talk to it directly), group music so Lidarr and Aurral
  # can move and delete what it downloads.
  uid = 3004;
in
{
  my.datasets."ssd/appdata/slskd" = {
    owner = apps.hostId uid;
    group = apps.hostId uid;
    mode = "0700";
  };
  my.proxy."slskd.i".port = 8201;

  # Incoming Soulseek connections (forwarded by the router).
  networking.firewall.allowedTCPPorts = [ 50300 ];

  home-manager.users.mikkel.virtualisation.quadlet.containers.slskd = apps.container {
    name = "slskd";
    image = "docker.io/slskd/slskd:latest";
    runAs = apps.runAs.isolatedGroup uid apps.groups.music;
    ports = [ "8201:5030" ];
    publicPorts = [ "50300:50300" ];
    # Lidarr and Aurral use it as a download client (http://slskd:5030).
    networks = [ apps.network ];
    volumes = [
      "/srv/appdata/slskd:/app"
      # Downloads, at the path Lidarr expects them (/media/downloads/slsk/music).
      "/storage/music/downloads/slsk:/media/downloads/slsk"
      # Shared with other Soulseek users, read-only.
      "/storage/music/library:/media/music:ro"
    ];
    environments = {
      SLSKD_REMOTE_CONFIGURATION = "true";
      # The image sets this umask itself (default 0022) when it runs with a fixed user;
      # downloads must be group-writable for music.
      SLSKD_UMASK = "0002";
    };
  };
}
