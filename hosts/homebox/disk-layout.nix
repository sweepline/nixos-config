# The SATA SSD as ZFS pool `ssd`: the OS plus everything the containers write. App databases
# live here and not on the `storage` pool, because every ZFS commit there makes the hard
# drives seek (audible every few seconds). The SSD has no redundancy: ssd/appdata is
# snapshotted and copied nightly to storage/backup (see zfs.nix).
#
# The `storage` pool (raidz2 + NVMe special vdev) is not managed by disko: it already exists
# and is only imported (zfs.nix). disko never touches it, even with --mode destroy.
{
  disko.devices = {
    disk.ssd = {
      type = "disk";
      device = "/dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S6PYNM0T410222R";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "2G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "ssd";
            };
          };
        };
      };
    };

    zpool.ssd = {
      type = "zpool";
      options = {
        ashift = "12";
        autotrim = "on";
      };
      rootFsOptions = {
        compression = "zstd";
        atime = "off";
        xattr = "sa";
        # journald and container images need POSIX ACLs
        acltype = "posixacl";
        mountpoint = "none";
        canmount = "off";
      };

      datasets = {
        # The OS is rebuilt from this repo, so it is not snapshotted. Legacy mountpoints are
        # mounted by NixOS (fileSystems) in the right order during boot.
        root = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/";
        };
        nix = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/nix";
        };
        # Also holds rootless Podman's images (~/.local/share/containers), which can be
        # pulled again.
        home = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/home";
        };

        # Container data, one child dataset per app (created by the app's module), so each
        # can be snapshotted and rolled back on its own. ZFS-managed mountpoint: children
        # mount under /srv/appdata/<app> by themselves.
        appdata = {
          type = "zfs_fs";
          mountpoint = "/srv/appdata";
          options.recordsize = "64K";
        };
        # Re-creatable data (transcodes, ML models): never snapshotted or backed up.
        cache = {
          type = "zfs_fs";
          mountpoint = "/srv/cache";
        };

        # Keeps 20 GB free, so a full pool (ZFS gets very slow, and even deletes can fail)
        # is fixed with `zfs set refreservation=none ssd/reserved` instead of a rescue boot.
        reserved = {
          type = "zfs_fs";
          options = {
            mountpoint = "none";
            refreservation = "20G";
          };
        };
      };
    };
  };
}
