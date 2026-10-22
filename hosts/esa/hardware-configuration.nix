# PLACEHOLDER. Replace with the generated file during install:
#   nixos-generate-config --no-filesystems --root /mnt --show-hardware-config > hosts/esa/hardware-configuration.nix
# (File systems come from disk-layout.nix / disko, so --no-filesystems.)
{ lib, ... }:
{
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
