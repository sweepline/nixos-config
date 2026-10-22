# Shared disko layout: EFI partition + one LUKS2 container.
# Without swap:  LUKS -> ext4 /
# With swap:     LUKS -> LVM -> swap (for hibernate) + ext4 /
{
  device,
  swapSize ? null,
}:
let
  root = {
    type = "filesystem";
    format = "ext4";
    mountpoint = "/";
  };
  luks = {
    type = "luks";
    name = "cryptroot";
    settings = {
      allowDiscards = true;
      # TPM2 + PIN, enrolled after install (docs/INSTALL.md)
      crypttabExtraOpts = [ "tpm2-device=auto" ];
    };
    content =
      if swapSize == null then
        root
      else
        {
          type = "lvm_pv";
          vg = "pool";
        };
  };
in
{
  disko.devices = {
    disk.main = {
      type = "disk";
      inherit device;
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
          luks = {
            size = "100%";
            content = luks;
          };
        };
      };
    };
  }
  // (
    if swapSize == null then
      { }
    else
      {
        lvm_vg.pool = {
          type = "lvm_vg";
          lvs = {
            swap = {
              size = swapSize;
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
            root = {
              size = "100%FREE";
              content = root;
            };
          };
        };
      }
  );
}
