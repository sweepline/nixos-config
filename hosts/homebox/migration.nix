# Migration from Ubuntu (docs/HOMEBOX-MIGRATION.md): the restore tool, run from the NixOS
# installer after disko, with both pools imported under /mnt:
#   nix run .#homebox-restore -- [--dry-run] /mnt/storage/backup/migration
#
# It copies the old Podman volumes into the app datasets (mapping their owners to the new
# scheme, docs/HOMEBOX.md "Ownership and permissions"), copies the music folders into
# storage/music, and sets owners and modes on the storage trees. It does not delete anything:
# the old music folders stay in storage/media until they are removed by hand. Undo is
# `zfs rollback` to storage@pre-migration (taken on Ubuntu), which the tool requires.
#
# Built from this config, so the datasets and owners cannot drift from what the apps expect.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Numeric IDs: the installer has none of these users and groups.
  mikkel = toString config.users.users.mikkel.uid;
  mikkelGroup = toString config.users.groups.mikkel.gid;
  media = toString config.users.groups.media.gid;
  music = toString config.users.groups.music.gid;
  numeric =
    name:
    if config.users.users ? ${name} && config.users.users.${name}.uid != null then
      toString config.users.users.${name}.uid
    else if config.users.groups ? ${name} && config.users.groups.${name}.gid != null then
      toString config.users.groups.${name}.gid
    else
      name;

  # Old owners (host IDs on Ubuntu): 101000 = container 1001 (PUID/user 1001), 100910 =
  # linuxserver's default abc (911), 1000 = container root. Unlisted IDs stay as they are
  # (100998 = Postgres, 100999 = Jellyseerr's node).
  toMikkel = {
    "101000" = mikkel;
    "100910" = mikkel;
  };
  toMikkelGroup = {
    "101000" = mikkelGroup;
    "100910" = mikkelGroup;
  };
  toMusicGroup = {
    "101000" = music;
    "100910" = music;
  };
  jellyfin = {
    "101000" = "103000";
    "1000" = "103000";
  };

  # Old volume → app dataset (ssd/appdata/<app>) and owner mapping.
  volumes = [
    {
      volume = "vaultwarden_vaultwarden";
      app = "vaultwarden";
    }
    {
      volume = "media_control_sonarr";
      app = "sonarr";
      uids = toMikkel;
      gids = toMikkelGroup;
    }
    {
      volume = "media_control_radarr";
      app = "radarr";
      uids = toMikkel;
      gids = toMikkelGroup;
    }
    {
      volume = "media_control_prowlarr";
      app = "prowlarr";
      uids = toMikkel;
      gids = toMikkelGroup;
    }
    {
      volume = "media_control_sabnzbd";
      app = "sabnzbd";
      uids = toMikkel;
      gids = toMikkelGroup;
    }
    {
      volume = "media_control_bazarr";
      app = "bazarr";
      uids = toMikkel;
      gids = toMikkelGroup;
    }
    {
      volume = "media_control_jellyseerr";
      app = "jellyseerr";
    }
    {
      volume = "music_control_lidarr";
      app = "lidarr";
      uids = toMikkel;
      gids = toMusicGroup;
    }
    {
      volume = "music_control_aurral";
      app = "aurral";
      uids = toMikkel;
      gids = toMusicGroup;
    }
    {
      volume = "music_control_navidrome";
      app = "navidrome";
      uids = toMikkel;
      gids = toMikkelGroup;
    }
    {
      volume = "music_control_slskd";
      app = "slskd";
      uids."101000" = "103003";
      gids."101000" = music;
    }
    {
      volume = "jellyfin_config";
      app = "jellyfin";
      uids = jellyfin;
      gids = jellyfin;
    }
    {
      volume = "immich_db";
      app = "immich-db";
    }
    {
      volume = "joplin_db";
      app = "joplin-db";
    }
  ];

  appDataset = v: "ssd/appdata/${v.app}";

  # The datasets the tool creates and sets up: the app datasets that receive a volume, and
  # storage/music. The rest (empty app datasets, storage/git, caches) are created by the
  # datasets service at the first boot.
  datasets = map appDataset volumes ++ [ "storage/music" ];

  ensureCall =
    name:
    let
      ds = config.my.datasets.${name};
    in
    lib.escapeShellArgs (
      [
        "ensure"
        name
        "${numeric ds.owner}:${numeric ds.group}"
        ds.mode
      ]
      ++ lib.concatLists (
        lib.mapAttrsToList (k: v: [
          "-o"
          "${k}=${v}"
        ]) ds.properties
      )
    );

  idMap = m: lib.concatStringsSep "," (lib.mapAttrsToList (old: new: "${old}:${new}") m);

  copyVolume =
    v:
    lib.escapeShellArgs (
      [
        "copy_volume"
        v.volume
        (appDataset v)
        (idMap (v.uids or { }))
        (idMap (v.gids or { }))
      ]
      ++ [
        "${numeric config.my.datasets.${appDataset v}.owner}:${
          numeric config.my.datasets.${appDataset v}.group
        }"
      ]
      ++ [ config.my.datasets.${appDataset v}.mode ]
    );

  restore = pkgs.writeShellApplication {
    name = "homebox-restore";
    runtimeInputs = [
      config.boot.zfs.package
      pkgs.coreutils
      pkgs.findutils
      pkgs.rsync
    ];
    text = ''
      dry=0
      any_mount=0
      while [ $# -gt 0 ]; do
        case "$1" in
          --dry-run) dry=1 ;;
          # VM test only: the pools are mounted as on the running system, not under /mnt.
          --any-mount) any_mount=1 ;;
          *) break ;;
        esac
        shift
      done
      if [ $# -ne 1 ]; then
        echo "usage: homebox-restore [--dry-run] MIGRATION_SET   (e.g. /mnt/storage/backup/migration)" >&2
        exit 2
      fi
      src=$1
      errors=0

      # Prints the command in a dry run, runs it otherwise.
      run() {
        if [ "$dry" = 1 ]; then
          printf '  +'
          printf ' %q' "$@"
          printf '\n'
        else
          "$@"
        fi
      }
      fail() {
        echo "ERROR: $*" >&2
        errors=$((errors + 1))
      }
      mountpoint_of() { zfs get -H -o value mountpoint "$1"; }
      # set_top <what> <dir> <uid:gid> <mode>
      set_top() {
        if ! run chown "$3" "$2" || ! run chmod "$4" "$2"; then
          fail "$1: could not set owner/mode of $2"
        fi
      }

      echo "== checks"
      [ "$(id -u)" = 0 ] || { echo "run as root" >&2; exit 1; }
      [ -d "$src/volumes" ] || { echo "$src/volumes does not exist" >&2; exit 1; }
      for ds in ssd/appdata storage/media storage/immich storage/backup; do
        zfs list -H -o name "$ds" >/dev/null 2>&1 || { echo "$ds is not imported" >&2; exit 1; }
      done
      # The way back: everything below only changes the storage pool after this snapshot.
      zfs list -H -t snapshot -o name storage@pre-migration >/dev/null 2>&1 ||
        { echo "storage@pre-migration is missing (take it on Ubuntu first, see the runbook)" >&2; exit 1; }
      storage=$(mountpoint_of storage)
      case "$storage" in
        /mnt/*) ;;
        *)
          if [ "$any_mount" != 1 ]; then
            echo "storage is mounted at $storage, expected under /mnt (zpool import -R /mnt)" >&2
            exit 1
          fi
          ;;
      esac
      echo "ok: migration set $src, storage at $storage"

      # ensure <dataset> <uid:gid> <mode> [-o property=value ...]: create if missing, then
      # owner and mode of the top directory.
      ensure() {
        local ds=$1 own=$2 mode=$3
        shift 3
        if ! zfs list -H -o name "$ds" >/dev/null 2>&1; then
          echo "$ds: creating"
          run zfs create -p "$@" "$ds" || { fail "$ds: could not create"; return 0; }
        fi
        if [ "$dry" = 1 ] && ! zfs list -H -o name "$ds" >/dev/null 2>&1; then
          return 0
        fi
        local mnt
        mnt=$(mountpoint_of "$ds")
        set_top "$ds" "$mnt" "$own" "$mode"
      }

      # copy_volume <volume> <dataset> <uid map> <gid map> <top uid:gid> <top mode>
      copy_volume() {
        local volume=$1 ds=$2 uids=$3 gids=$4 own=$5 mode=$6
        local from="$src/volumes/$volume/_data"
        if [ ! -d "$from" ]; then
          fail "$volume: not in the migration set ($from)"
          return 0
        fi
        local to
        to=$(mountpoint_of "$ds" 2>/dev/null) || to="(new $ds)"
        echo "$volume -> $ds ($to)''${uids:+, owners $uids}''${gids:+, groups $gids}"
        local args=(-aHAX --numeric-ids --info=stats1)
        [ -n "$uids" ] && args+=("--usermap=$uids")
        [ -n "$gids" ] && args+=("--groupmap=$gids")
        run rsync "''${args[@]}" "$from/" "$to/" || { fail "$volume: rsync failed"; return 0; }
        # rsync gives the top directory the old owner and mode; the app expects these.
        set_top "$ds" "$to" "$own" "$mode"
      }

      echo
      echo "== datasets"
      ${lib.concatLines (map ensureCall datasets)}

      echo
      echo "== app data"
      ${lib.concatLines (map copyVolume volumes)}

      echo
      echo "== music: copied into storage/music (the originals in storage/media stay)"
      music=$(mountpoint_of storage/music 2>/dev/null) || music="$storage/music"
      copy_tree() {
        if [ -d "$1" ]; then
          echo "$1 -> $2"
          run mkdir -p "$2"
          run rsync -aHAX --info=stats1 "$1/" "$2/" || fail "copying $1 failed"
        else
          echo "$1: does not exist, skipped"
        fi
      }
      copy_tree "$storage/media/music" "$music/library"
      copy_tree "$storage/media/unmapped_music" "$music/unmapped"
      copy_tree "$storage/media/downloads/usenet/music" "$music/downloads/usenet/music"
      copy_tree "$storage/media/downloads/slsk" "$music/downloads/slsk"
      copy_tree "$storage/media/downloads/bandcamp" "$music/downloads/bandcamp"
      copy_tree "$storage/media/downloads/aurral" "$music/downloads/aurral"

      echo
      echo "== owners and modes of the shared trees"
      # Everything mikkel's, in the shared group; setgid directories so new files get the
      # group, group-writable so the other apps in the group can move and delete.
      run chown -R ${mikkel}:${media} "$storage/media" || fail "chown media"
      run find "$storage/media" -type d -exec chmod g+ws {} + || fail "chmod media"
      run chown -R ${mikkel}:${music} "$music" || fail "chown music"
      run chmod -R g+w "$music" || fail "chmod music"
      run find "$music" -type d -exec chmod g+s {} + || fail "chmod music dirs"
      # Top directories as the datasets service sets them at every boot.
      for top in media:${media}:2775 music:${music}:2775 immich:${mikkelGroup}:0750 backup:${mikkelGroup}:0750; do
        IFS=: read -r name group mode <<<"$top"
        set_top "storage/$name" "$storage/$name" "${mikkel}:$group" "$mode"
      done

      echo
      if [ "$errors" -gt 0 ]; then
        echo "FINISHED WITH $errors ERROR(S): fix them, then run again (copies are resumable)." >&2
        exit 1
      fi
      if [ "$dry" = 1 ]; then
        echo "done (dry run: nothing was changed)"
      else
        echo "done"
      fi
    '';
  };
in
{
  assertions = map (v: {
    assertion = config.my.datasets ? ${appDataset v};
    message = "migration.nix: volume ${v.volume} goes to ${appDataset v}, which no app module declares.";
  }) volumes;

  system.build.homeboxRestore = restore;
}
