{
  config,
  lib,
  pkgs,
  ...
}:
let
  apps = import ./lib.nix { inherit config lib pkgs; };
  # POSTGRES_PASSWORD=... (used by both containers).
  secret = ../../../secrets/joplin-homebox.age;
  passwordFile = lib.optional (config.age.secrets ? joplin) config.age.secrets.joplin.path;
  # Joplin's own network: the database is only reachable from the Joplin server.
  network = "joplin.network";
in
{
  # Postgres requires its data directory to belong to its own user (999 in the container)
  # with mode 0700. 16K records: Postgres writes 8K pages, larger records would rewrite more.
  my.datasets."ssd/appdata/joplin-db" = {
    owner = apps.hostId 999;
    group = apps.hostId 999;
    mode = "0700";
    properties.recordsize = "16K";
  };
  my.proxy."joplin.i".port = 22300;

  age.secrets.joplin = lib.mkIf (builtins.pathExists secret) {
    file = secret;
    owner = "mikkel";
    mode = "0400";
  };

  home-manager.users.mikkel.virtualisation.quadlet = {
    networks.joplin = { };

    containers.joplin-db = apps.container {
      name = "joplin-db";
      # The major version is fixed: a new major needs a dump and restore of the data.
      image = "docker.io/library/postgres:17";
      networks = [ network ];
      volumes = [ "/srv/appdata/joplin-db:/var/lib/postgresql/data" ];
      environments = {
        POSTGRES_USER = "joplin";
        POSTGRES_DB = "joplin";
      };
      environmentFiles = passwordFile;
    };

    containers.joplin = lib.mkMerge [
      (apps.container {
        name = "joplin";
        image = "docker.io/joplin/server:latest";
        ports = [ "22300:22300" ];
        networks = [ network ];
        environments = {
          APP_PORT = "22300";
          DB_CLIENT = "pg";
          POSTGRES_HOST = "joplin-db";
          POSTGRES_PORT = "5432";
          POSTGRES_USER = "joplin";
          POSTGRES_DATABASE = "joplin";
        };
        environmentFiles = passwordFile;
        domainEnv.APP_BASE_URL = "https://joplin.i.@DOMAIN@";
      })
      {
        unitConfig = {
          Requires = [ "joplin-db.service" ];
          After = [ "joplin-db.service" ];
        };
      }
    ];
  };
}
