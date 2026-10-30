# A VM of homebox for testing before the migration (docs/HOMEBOX-MIGRATION.md):
#   nix build .#nixosConfigurations.homebox.config.system.build.vmWithDisko
#   QEMU_KERNEL_PARAMS=console=ttyS0 ./result/bin/disko-vm -nographic
#   ssh -p 2222 mikkel@localhost
# The disks are disko's (the real ssd pool layout) plus a small fake `storage` pool; every
# run starts from fresh copy-on-write images and leaves nothing behind. Only this VM is
# changed below; the real system is not affected.
{ lib, ... }:
let
  testSecret = name: lib.mkForce ./vm/secrets/${name}.age;
in
{
  virtualisation.vmVariantWithDisko = {
    virtualisation = {
      memorySize = 7168;
      cores = 8;
      forwardPorts = [
        {
          from = "host";
          host.port = 2222;
          guest.port = 22;
        }
      ];
    };

    disko.devices = {
      disk.ssd.imageSize = "40G";
      # Stands in for the raidz2 pool, with the datasets that exist on the server today.
      disk.storage = {
        type = "disk";
        device = "/dev/vdb";
        imageSize = "16G";
        content = {
          type = "gpt";
          partitions.zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "storage";
            };
          };
        };
      };
      zpool.storage = {
        type = "zpool";
        mountpoint = "/storage";
        rootFsOptions = {
          compression = "lz4";
          atime = "off";
          xattr = "sa";
          acltype = "posixacl";
        };
        datasets = {
          media = {
            type = "zfs_fs";
            mountpoint = "/storage/media";
          };
          immich = {
            type = "zfs_fs";
            mountpoint = "/storage/immich";
          };
          backup = {
            type = "zfs_fs";
            mountpoint = "/storage/backup";
          };
        };
      };
    };

    # Test secrets (vm/secrets, DOMAIN=example.test, test passwords), encrypted for a test key
    # that only exists for this VM. The real secrets cannot be decrypted here.
    age.identityPaths = lib.mkForce [ "${./vm/age.key}" ];
    age.secrets = {
      caddy.file = testSecret "caddy";
      domain.file = testSecret "domain";
      navidrome.file = testSecret "navidrome";
      joplin.file = testSecret "joplin";
      immich.file = testSecret "immich";
      wg0.file = testSecret "wg0";
      smtp.file = testSecret "smtp";
    };

    # Caddy's own CA instead of Let's Encrypt via Cloudflare (no real domain here).
    services.caddy.globalConfig = lib.mkForce ''
      local_certs
      skip_install_trust
    '';

    # No GPU in the VM.
    home-manager.users.mikkel.virtualisation.quadlet.containers.jellyfin.containerConfig.devices =
      lib.mkForce
        [ ];

    # The VM's mounts come from disko's VM support (virtualisation.fileSystems), which replaces
    # fileSystems; repeat the early /home mount from default.nix here.
    virtualisation.fileSystems."/home".neededForBoot = true;

    # SSH from the host (port 2222) and sudo without a password, for the test only.
    networking.firewall.allowedTCPPorts = [ 22 ];
    security.sudo.wheelNeedsPassword = false;
  };
}
