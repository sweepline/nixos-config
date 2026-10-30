{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Every period is set explicitly: sanoid fills unset ones from its own defaults
  # (hourly = 48, daily = 90, monthly = 6), which would quietly keep far more.
  retention =
    {
      hourly ? 0,
      daily ? 0,
      weekly ? 0,
      monthly ? 0,
    }:
    {
      frequently = 0;
      inherit
        hourly
        daily
        weekly
        monthly
        ;
      yearly = 0;
    };

  # The nightly copy of the app data (syncoid-appdata below).
  copyTarget = "storage/backup/appdata";

  syncoidCheck = pkgs.writeShellScript "syncoid-appdata-check" ''
    zfs=${config.boot.zfs.package}/bin/zfs
    failed=0
    for src in $($zfs list -H -r -o name ssd/appdata); do
      dst="${copyTarget}''${src#ssd/appdata}"
      newest() { $zfs list -H -t snapshot -o name -s createtxg "$1" 2>/dev/null | tail -n 1 | cut -d@ -f2; }
      want=$(newest "$src")
      have=$(newest "$dst")
      if [ -n "$want" ] && [ "$want" != "$have" ]; then
        echo "$dst: newest snapshot is '$have', expected '$want'" >&2
        failed=1
      fi
    done
    exit $failed
  '';
in
{
  boot.supportedFilesystems = [ "zfs" ];
  # The pools remember the host ID that imported them last. Keeping the Ubuntu install's ID
  # lets NixOS import `storage` without `zpool import -f`.
  networking.hostId = "61ba3ff7";
  # Never force-import the root pool: if another system had it imported, stop instead.
  boot.zfs.forceImportRoot = false;
  # The existing data pool (raidz2 of the five HDDs + the NVMe mirror as special vdev).
  boot.zfs.extraPools = [ "storage" ];

  services.zfs.autoScrub = {
    enable = true;
    interval = "monthly";
  };
  services.zfs.trim.enable = true;

  # Snapshots. The old zfs-auto-snap_* snapshots from Ubuntu are not touched (sanoid only
  # manages its own autosnap_* ones) and can be deleted by hand once these have history.
  services.sanoid = {
    enable = true;
    templates = {
      appdata = retention {
        hourly = 24;
        daily = 7;
      };
      photos = retention {
        hourly = 24;
        daily = 31;
        weekly = 8;
        monthly = 12;
      };
      # The curated library; media itself can mostly be downloaded again.
      music = retention {
        daily = 7;
        weekly = 4;
        monthly = 12;
      };
      media = retention {
        daily = 7;
        weekly = 4;
      };
      backup = retention {
        weekly = 4;
        monthly = 6;
      };
      # The nightly copy of ssd/appdata (syncoid below) is only pruned here, with a longer
      # history than on the SSD.
      appdata-copy =
        retention {
          daily = 31;
          weekly = 8;
          monthly = 12;
        }
        // {
          autosnap = false;
        };
    };
    datasets = {
      "ssd/appdata" = {
        useTemplate = [ "appdata" ];
        recursive = true;
      };
      "storage/immich".useTemplate = [ "photos" ];
      # Own repos, some only here: same history as the photos.
      "storage/git".useTemplate = [ "photos" ];
      "storage/music".useTemplate = [ "music" ];
      "storage/media".useTemplate = [ "media" ];
      "storage/backup".useTemplate = [ "backup" ];
      ${copyTarget} = {
        useTemplate = [ "appdata-copy" ];
        recursive = true;
      };
    };
  };

  # The SSD has no redundancy: copy the app data to the raidz2 pool every night. Only changed
  # blocks are sent, and the hard drives are only busy for that one burst. This copy also
  # goes to the external drive (homebox-backup on esa).
  #
  # Our own service instead of services.syncoid: in that module's sandbox (an unprivileged
  # user with delegated ZFS permissions, in a chroot) syncoid silently stopped after the top
  # dataset and could not set canmount on receive, and exited successfully either way (found
  # in the VM test). As root it copies everything; the copy is local, so this service gets
  # no network and a read-only view of the system.
  systemd.services.syncoid-appdata = {
    description = "Nightly copy of ssd/appdata to ${copyTarget}";
    after = [
      "zfs-mount.service"
      "zfs-import.target"
    ];
    path = [
      config.boot.zfs.package
      pkgs.mbuffer
      pkgs.pv
      pkgs.lzop
      pkgs.procps
      pkgs.which
    ];
    serviceConfig = {
      Type = "oneshot";
      # Up to sanoid's newest snapshot (no syncoid snapshots of its own). The copy is
      # received unmounted and never mounted (canmount=off); to look inside, clone a snapshot:
      # zfs clone ${copyTarget}/<app>@<snapshot> storage/restore
      ExecStart = lib.escapeShellArgs [
        "${pkgs.sanoid}/bin/syncoid"
        "--recursive"
        "--no-sync-snap"
        "--recvoptions"
        "u o canmount=off"
        "ssd/appdata"
        copyTarget
      ];
      # syncoid exits 0 even when receives fail: compare every app's newest snapshot with its
      # copy; a mismatch fails the unit (systemctl --failed).
      ExecStartPost = syncoidCheck;
      # A failing receive can leave syncoid's pipeline (send | mbuffer | pv | receive) hanging
      # instead of exiting (found in the VM test with a full dataset). A normal night takes
      # minutes; after this the run is stopped and counts as failed.
      TimeoutStartSec = "2h";
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateNetwork = true;
      NoNewPrivileges = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      Nice = 10;
      IOSchedulingClass = "idle";
    };
  };
  systemd.timers.syncoid-appdata = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:30:00";
      Persistent = true;
    };
  };
}
