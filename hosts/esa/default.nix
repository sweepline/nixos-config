{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    (import ../disk-layout.nix {
      # TODO: `ls -l /dev/disk/by-id/` on the installer
      device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL21T0HCLR-00B00_S676NU0W123595";
    })
  ];

  my = {
    gpu = "intel"; # dedicated Intel Arc card (the CPU is AMD)
    work.enable = true;
    theme = "light";
  };
}
