{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    (import ../disk-layout.nix {
      # TODO: `ls -l /dev/disk/by-id/` on the installer
      device = "/dev/disk/by-id/CHANGE-ME";
    })
  ];

  my = {
    gpu = "intel";
    secureBoot.enable = false;
  };
}
