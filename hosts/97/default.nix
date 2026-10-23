{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    (import ../disk-layout.nix {
      device = "/dev/disk/by-id/nvme-WDC_WDS100T2B0C-00PXH0_20427P452912";
    })
  ];

  my = {
    gpu = "nvidia";
    gaming.enable = true;
    windowsDualBoot = {
      enable = true;
      # EFI partition on the Windows disk (Force MP510, nvme0n1p1)
      efiPartUuid = "e5ff9359-7b36-4a21-bac0-80cac865baf2";
    };
  };

  # Overflow swap (16 GB RAM): used only after zram is full. Inside LUKS, so encrypted.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
      priority = 0;
    }
  ];

  # If a new kernel breaks the NVIDIA driver build, use the default kernel:
  # boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
}
