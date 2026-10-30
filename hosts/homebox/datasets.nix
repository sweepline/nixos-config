# ZFS datasets, their owners and modes, and the shared groups (docs/HOMEBOX.md,
# "Ownership and permissions").
#
#   my.datasets."ssd/appdata/sonarr" = { };                     # mikkel:mikkel 0750
#   my.datasets."storage/media" = { create = false; group = "media"; mode = "2775"; };
#
# A root service creates missing datasets (never deletes or changes existing ones apart from
# owner and mode of their top directory) before mikkel's user manager starts, so containers
# never start on a missing or root-owned directory. Only the top directory is touched; the
# contents keep their owners (set once by the restore script, then by the apps themselves).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.datasets;
  # The UID that runs the containers (the lingering user manager to start after the datasets).
  inherit (config.users.users.mikkel) uid;

  # ensure <dataset> <create: 1|0> <owner:group> <mode> [-o property=value ...]
  ensureFunction = ''
    ensure() {
      ds=$1 create=$2 own=$3 mode=$4
      shift 4
      if ! zfs list -H -o name "$ds" >/dev/null 2>&1; then
        if [ "$create" != 1 ]; then
          echo "skipping $ds: does not exist" >&2
          return 0
        fi
        echo "creating $ds"
        zfs create -p "$@" "$ds"
      fi
      mnt=$(zfs get -H -o value mountpoint "$ds")
      if [ ! -d "$mnt" ]; then
        echo "skipping $ds: not mounted ($mnt)" >&2
        return 0
      fi
      chown "$own" "$mnt"
      chmod "$mode" "$mnt"
    }
  '';

  ensureCall =
    name: ds:
    lib.escapeShellArgs (
      [
        "ensure"
        name
        (if ds.create then "1" else "0")
        "${ds.owner}:${ds.group}"
        ds.mode
      ]
      ++ lib.concatLists (
        lib.mapAttrsToList (k: v: [
          "-o"
          "${k}=${v}"
        ]) ds.properties
      )
    );
in
{
  options.my.datasets = lib.mkOption {
    description = "ZFS datasets to create (if missing) and the owner and mode of their top directory.";
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          create = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Create the dataset if it is missing. Off for datasets that hold existing data.";
          };
          properties = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            example = {
              recordsize = "16K";
            };
            description = "ZFS properties, only used when creating the dataset.";
          };
          owner = lib.mkOption {
            type = lib.types.str;
            default = "mikkel";
            description = "User name or numeric host UID owning the top directory.";
          };
          group = lib.mkOption {
            type = lib.types.str;
            default = "mikkel";
            description = "Group name or numeric host GID of the top directory.";
          };
          mode = lib.mkOption {
            type = lib.types.str;
            default = "0750";
            description = "Mode of the top directory. Private data must not be world-readable.";
          };
        };
      }
    );
  };

  config = {
    # Shared, group-writable trees. The GIDs are those of container GIDs 2001 and 2002 in
    # mikkel's subordinate range (host GID = 100000 + N - 1, with and without keep-id), so the
    # same group is seen inside every container and on the host. mikkel is a member, so he can
    # work on the files directly.
    users.groups.media.gid = 102000;
    users.groups.music.gid = 102001;
    users.users.mikkel.extraGroups = [
      "media"
      "music"
    ];

    my.datasets = {
      # From disko (disk-layout.nix). Each app sees only its own child through its mount.
      "ssd/appdata".create = false;
      "storage/immich".create = false;
      "storage/media" = {
        create = false;
        group = "media";
        mode = "2775";
      };
      "storage/music" = {
        create = false;
        group = "music";
        mode = "2775";
      };
    };

    systemd.services.datasets = {
      description = "Create app datasets and set their owners and modes";
      after = [
        "zfs-import.target"
        "zfs-mount.service"
      ];
      wants = [ "zfs-mount.service" ];
      # Not a hard requirement: if this fails, mikkel's other containers and logins still work.
      before = [ "user@${toString uid}.service" ];
      wantedBy = [
        "multi-user.target"
        "user@${toString uid}.service"
      ];
      path = [
        config.boot.zfs.package
        pkgs.coreutils
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = lib.concatLines ([ ensureFunction ] ++ lib.mapAttrsToList ensureCall cfg);
    };
  };
}
