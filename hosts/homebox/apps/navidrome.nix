{
  config,
  lib,
  pkgs,
  ...
}:
let
  apps = import ./lib.nix { inherit config lib pkgs; };
  secret = ../../../secrets/navidrome-homebox.age;
in
{
  my.datasets."ssd/appdata/navidrome" = { };
  my.proxy."navidrome.i".port = 8204;

  # ND_LASTFM_APIKEY=... and ND_LASTFM_SECRET=... (scrobbling and artist info).
  age.secrets.navidrome = lib.mkIf (builtins.pathExists secret) {
    file = secret;
    owner = "mikkel";
    mode = "0400";
  };

  home-manager.users.mikkel.virtualisation.quadlet.containers.navidrome = apps.container {
    name = "navidrome";
    image = "docker.io/deluan/navidrome:latest";
    runAs = apps.runAs.mikkel;
    ports = [ "8204:4533" ];
    networks = [ apps.network ];
    volumes = [
      "/srv/appdata/navidrome:/data"
      # Only reads music (world-readable), so no music group needed.
      "/storage/music/library:/media/music:ro"
      "/storage/music/unmapped:/media/unmapped_music:ro"
    ];
    environments = {
      ND_MUSICFOLDER = "/media/music";
      ND_ENABLETRANSCODINGCONFIG = "true";
    };
    environmentFiles = lib.optional (config.age.secrets ? navidrome) config.age.secrets.navidrome.path;
  };
}
