{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    (import ../disk-layout.nix {
      # TODO: `ls -l /dev/disk/by-id/` on the installer
      device = "/dev/disk/by-id/CHANGE-ME";
      # TODO: at least the amount of RAM, needed for hibernate
      swapSize = "32G";
    })
  ];

  my = {
    gpu = "amd";
    laptop = {
      enable = true;
      chargeLimit = 80;
      # TODO: only if dongmyo has a fingerprint reader (lsusb | grep -i finger)
      fingerprint.enable = true;
    };
    secureBoot.enable = false;
  };
}
