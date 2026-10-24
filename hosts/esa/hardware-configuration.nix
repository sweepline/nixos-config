# PLACEHOLDER. Replace with the generated file during install:
#   nixos-generate-config --no-filesystems --root /mnt --show-hardware-config > hosts/esa/hardware-configuration.nix
# (File systems come from disk-layout.nix / disko, so --no-filesystems.)
{ config, lib, ... }:
{
  # Disappears when the file is replaced by the generated one.
  warnings = [
    "hosts/esa/hardware-configuration.nix is a placeholder; generate it during install (docs/INSTALL.md 2.4)."
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-amd" ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
