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
    # Turn on after enrolling keys (docs/INSTALL.md, step "Secure Boot").
    secureBoot.enable = false;
    windowsDualBoot = {
      enable = true;
      # EFI partition on the Windows disk (Force MP510, nvme0n1p1)
      efiPartUuid = "e5ff9359-7b36-4a21-bac0-80cac865baf2";
    };
  };

  # If a new kernel breaks the NVIDIA driver build, use the default kernel:
  # boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
}
