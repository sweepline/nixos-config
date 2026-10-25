{ pkgs, ... }:
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
    work.enable = true;
    windowsDualBoot = {
      enable = true;
      # EFI partition on the Windows disk (Force MP510, nvme0n1p1)
      efiPartUuid = "e5ff9359-7b36-4a21-bac0-80cac865baf2";
    };
  };

  # fbcon sizes the console to the smallest connected screen (DP-2, 1920x1080), which leaves
  # the console and Ly in the top-left corner of the 3440x1440 ultrawide. Expand the visible
  # area to the full framebuffer size once the DRM framebuffer is up.
  systemd.services.display-manager.serviceConfig.ExecStartPre =
    "${pkgs.fbset}/bin/fbset -fb /dev/fb0 -xres 3440 -yres 1440";

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
