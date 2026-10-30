{ ... }:
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
      "storage/backup/appdata" = {
        useTemplate = [ "appdata-copy" ];
        recursive = true;
      };
    };
  };

  # The SSD has no redundancy: copy the app data to the raidz2 pool every night. Only changed
  # blocks are sent, and the hard drives are only busy for that one burst. This copy also
  # goes to the external drive (homebox-backup on esa).
  services.syncoid = {
    enable = true;
    interval = "*-*-* 03:30:00";
    commands.appdata = {
      source = "ssd/appdata";
      target = "storage/backup/appdata";
      recursive = true;
      # Send up to sanoid's newest snapshot instead of creating syncoid snapshots.
      extraArgs = [ "--no-sync-snap" ];
      # syncoid runs without capabilities and cannot mount. The copy stays unmounted; to look
      # inside, clone a snapshot (`zfs clone storage/backup/appdata/<app>@... storage/restore`).
      recvOptions = "u o canmount=off";
    };
  };
}
