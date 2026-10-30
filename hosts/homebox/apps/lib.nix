# Shared pieces for the app modules in this folder. Each app module does
#   let apps = import ./lib.nix { inherit config lib pkgs; }; in
# and defines its container with apps.container (rootless, in mikkel's Home Manager).
{
  config,
  lib,
  pkgs,
}:
rec {
  # Host UID/GID of container UID/GID n (n >= 1001) in mikkel's subordinate range
  # (100000:65536). The same with and without keep-id (docs/HOMEBOX.md).
  hostId = n: toString (100000 + n - 1);

  # The shared network for apps that talk to each other (apps/default.nix). By container
  # name instead of through Caddy and the domain, so these connections do not depend on
  # Caddy, TLS, DNS or the domain.
  network = "apps.network";

  # Container GIDs of the shared groups; on the host they are hostId of these (datasets.nix).
  groups = {
    media = 2001;
    music = 2002;
  };

  # Who a container runs as (docs/HOMEBOX.md, "Ownership and permissions").
  runAs = rec {
    # Images that run as root inside: rootless Podman maps container root to mikkel, so
    # their files are mikkel's without any options.
    root = { };
    # linuxserver.io images start their init as root and then switch to PUID/PGID. With
    # keep-id, container 1000 is mikkel; user=0:0 is needed because keep-id otherwise starts
    # the init as 1000 too, which puts linuxserver into its less supported non-root mode.
    # Container root is then mikkel's first subordinate UID, not mikkel and not host root.
    # PGID 1000 is mikkel's primary group (keep-id maps only that group to itself).
    linuxserver = linuxserverGroup 1000;
    # The same with another primary group, e.g. groups.music for apps that must change files
    # other users wrote in the shared music tree. (GroupAdd does not work here: the init
    # drops supplementary groups when it switches to the app user.)
    linuxserverGroup = gid: {
      userns = "keep-id";
      user = "0:0";
      environments = {
        PUID = "1000";
        PGID = toString gid;
        # Group-writable files in the shared media/music trees.
        UMASK = "002";
      };
    };
    # Images that run their app directly as a configurable user.
    mikkel = {
      userns = "keep-id";
      user = "1000:1000";
    };
    # Internet-facing apps: their own UID, so a container breakout does not land as mikkel
    # (who owns all other app data). Their files on the host belong to hostId uid.
    isolated = uid: isolatedGroup uid uid;
    # The same with another group, e.g. groups.music for slskd's downloads.
    isolatedGroup = uid: gid: {
      user = "${toString uid}:${toString gid}";
      noNewPrivileges = true;
    };
  };

  domainFile = config.age.secrets.domain.path or "/run/agenix/domain";

  # Writes an env file from a template with @DOMAIN@ placeholders, filled in from the domain
  # secret just before the container starts. The real domain never enters the Nix store.
  # Without the secret (VM test) the domain is "invalid", like in Caddy.
  domainEnvScript =
    name: vars:
    let
      template = pkgs.writeText "${name}-env-template" (
        lib.concatLines (lib.mapAttrsToList (k: v: "${k}=${v}") vars)
      );
    in
    pkgs.writeShellScript "${name}-domain-env" ''
      set -eu
      out=$1
      domain=invalid
      if [ -r ${domainFile} ]; then
        domain=$(${pkgs.gnused}/bin/sed -n 's/^DOMAIN=//p' ${domainFile} | ${pkgs.coreutils}/bin/head -n1)
      fi
      case "$domain" in
        "" | *[!a-zA-Z0-9.-]*)
          echo "invalid DOMAIN in ${domainFile}" >&2
          exit 1
          ;;
      esac
      ${pkgs.coreutils}/bin/mkdir -p -m 700 "$(${pkgs.coreutils}/bin/dirname "$out")"
      umask 077
      ${pkgs.gnused}/bin/sed "s/@DOMAIN@/$domain/g" ${template} > "$out"
    '';

  # A rootless container in mikkel's Home Manager (quadlet-nix). Anything not covered here
  # can be added next to it with lib.mkMerge (devices, networks, ...).
  container =
    {
      name,
      image,
      runAs ? { },
      # "HOSTPORT:CONTAINERPORT", published on 127.0.0.1 only (Caddy proxies to them).
      ports ? [ ],
      # The same, but on all interfaces (forwarded by the router; open them in the firewall).
      publicPorts ? [ ],
      volumes ? [ ],
      environments ? { },
      # Env vars that contain the domain, as "...@DOMAIN@..." (see domainEnvScript).
      domainEnv ? { },
      # Further env files, e.g. agenix secrets owned by mikkel.
      environmentFiles ? [ ],
      # Quadlet networks to join, e.g. [ apps.network ]: apps on the same network reach each
      # other by container name (http://sonarr:8989).
      networks ? [ ],
      # podman auto-update pulls a new image for the same tag. Off for pinned versions.
      autoUpdate ? true,
    }:
    let
      envFile = "%t/apps/${name}.env";
    in
    {
      autoStart = true;
      containerConfig = lib.mkMerge [
        runAs
        {
          inherit
            image
            volumes
            environments
            networks
            ;
          # The container's own name, which is also how the others on its network reach it.
          # (SABnzbd, for one, only answers to host names it knows.)
          hostname = name;
          publishPorts = map (p: "127.0.0.1:${p}") ports ++ publicPorts;
          timezone = "local";
          autoUpdate = lib.mkIf autoUpdate "registry";
          environmentFiles = lib.optional (domainEnv != { }) envFile ++ environmentFiles;
        }
      ];
      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
        # The first start pulls the image, which can take a while for the big ones.
        TimeoutStartSec = "900";
      }
      // lib.optionalAttrs (domainEnv != { }) {
        ExecStartPre = "${domainEnvScript name domainEnv} ${envFile}";
      };
    };
}
