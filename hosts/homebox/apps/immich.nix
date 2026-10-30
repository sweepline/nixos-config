{
  config,
  lib,
  pkgs,
  ...
}:
let
  apps = import ./lib.nix { inherit config lib pkgs; };
  # DB_PASSWORD=... (server) and POSTGRES_PASSWORD=... (database), the same value.
  secret = ../../../secrets/immich-homebox.age;
  passwordFile = lib.optional (config.age.secrets ? immich) config.age.secrets.immich.path;
  # Immich's own network: database, Redis and machine learning are only reachable from the
  # Immich server (and the public proxy reaches the server).
  network = "immich.network";

  # Pinned to the version running before the migration (2.7.5), so moving to NixOS does not
  # also upgrade Immich. Upgrade afterwards on purpose, following Immich's release notes
  # (server and machine learning together).
  version = "v2.7.5";
  # Proxy for public share links (photos.<domain>). Major version 3: 4.x requires Immich 3.
  # Move to 4 together with the Immich 3 upgrade.
  proxyUid = 3003;
in
{
  # Postgres requires its data directory to belong to its own user (999 in the container)
  # with mode 0700. 16K records: Postgres writes 8K pages, larger records would rewrite more.
  my.datasets."ssd/appdata/immich-db" = {
    owner = apps.hostId 999;
    group = apps.hostId 999;
    mode = "0700";
    properties.recordsize = "16K";
  };
  # Downloaded models: re-created, never backed up.
  my.datasets."ssd/cache/immich-ml" = { };

  my.proxy."immich.i".port = 2283;
  my.proxy."photos" = {
    port = 8300;
    public = true;
  };

  age.secrets.immich = lib.mkIf (builtins.pathExists secret) {
    file = secret;
    owner = "mikkel";
    mode = "0400";
  };

  home-manager.users.mikkel.virtualisation.quadlet = {
    networks.immich = { };

    containers.immich-postgres = lib.mkMerge [
      (apps.container {
        name = "immich-postgres";
        # Immich's own Postgres build (vector search extensions), by digest as in Immich's
        # compose file. Only change it as Immich's release notes say.
        image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
        autoUpdate = false;
        networks = [ network ];
        volumes = [ "/srv/appdata/immich-db:/var/lib/postgresql/data" ];
        environments = {
          POSTGRES_USER = "postgres";
          POSTGRES_DB = "immich";
          POSTGRES_INITDB_ARGS = "--data-checksums";
        };
        environmentFiles = passwordFile;
      })
      { containerConfig.shmSize = "128m"; }
    ];

    containers.immich-redis = lib.mkMerge [
      (apps.container {
        name = "immich-redis";
        image = "docker.io/valkey/valkey:9@sha256:fb8d272e529ea567b9bf1302245796f21a2672b8368ca3fcb938ac334e613c8f";
        autoUpdate = false;
        networks = [ network ];
      })
      { containerConfig.healthCmd = "redis-cli ping || exit 1"; }
    ];

    containers.immich-machine-learning = apps.container {
      # The server finds it under this name (its default IMMICH_MACHINE_LEARNING_URL).
      name = "immich-machine-learning";
      image = "ghcr.io/immich-app/immich-machine-learning:${version}";
      autoUpdate = false;
      networks = [ network ];
      volumes = [ "/srv/cache/immich-ml:/cache" ];
    };

    containers.immich-server = lib.mkMerge [
      (apps.container {
        name = "immich-server";
        image = "ghcr.io/immich-app/immich-server:${version}";
        autoUpdate = false;
        ports = [ "2283:2283" ];
        networks = [ network ];
        # Photos and videos, thumbnails, encoded videos and Immich's own database dumps.
        volumes = [ "/storage/immich:/data" ];
        environments = {
          DB_HOSTNAME = "immich-postgres";
          DB_USERNAME = "postgres";
          DB_DATABASE_NAME = "immich";
          REDIS_HOSTNAME = "immich-redis";
        };
        environmentFiles = passwordFile;
      })
      {
        unitConfig = {
          Requires = [
            "immich-postgres.service"
            "immich-redis.service"
          ];
          After = [
            "immich-postgres.service"
            "immich-redis.service"
          ];
        };
      }
    ];

    containers.immich-public-proxy = apps.container {
      name = "immich-public-proxy";
      image = "ghcr.io/alangrainger/immich-public-proxy:3";
      # Isolated: reachable from the internet, and it needs no files at all.
      runAs = apps.runAs.isolated proxyUid;
      ports = [ "8300:3000" ];
      networks = [ network ];
      environments.IMMICH_URL = "http://immich-server:2283";
      domainEnv.PUBLIC_BASE_URL = "https://photos.@DOMAIN@";
    };
  };
}
