{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    (import ../disk-layout.nix {
      # SK Hynix 256 GB (nvme0n1)
      device = "/dev/disk/by-id/nvme-SKHynix_HFS256GDE9X081N_FYB4N046411904T8H";
    })
  ];

  # Swapfile for hibernate (at least the size of RAM: 32 GB). systemd stores its
  # location in an EFI variable when hibernating, so no resume= settings are needed.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024;
      priority = 0;
    }
  ];

  my = {
    gpu = "amd";
    work.enable = true;
    laptop = {
      enable = true;
      chargeLimit = 80; # BAT0 supports charge_control_end_threshold
      # TODO: check for a reader with `nix shell nixpkgs#usbutils -c lsusb`; set false if none
      fingerprint.enable = true;
    };
  };
}
