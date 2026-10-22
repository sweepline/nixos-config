{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    (import ../disk-layout.nix {
      # SK Hynix 256 GB (nvme0n1)
      device = "/dev/disk/by-id/nvme-SKHynix_HFS256GDE9X081N_FYB4N046411904T8H";
      # Same as RAM (32 GB), needed for hibernate
      swapSize = "32G";
    })
  ];

  my = {
    gpu = "amd";
    laptop = {
      enable = true;
      chargeLimit = 80; # BAT0 supports charge_control_end_threshold
      # TODO: check for a reader with `nix-shell -p usbutils --run lsusb`; set false if none
      fingerprint.enable = true;
    };
    secureBoot.enable = false;
  };
}
