{ inputs, lib, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.nixosModules.stylix
    inputs.agenix.nixosModules.default
    inputs.disko.nixosModules.disko

    ./base.nix
    ./boot.nix
    ./desktop.nix
    ./hardware.nix
    ./networking.nix
    ./gaming.nix
    ./laptop.nix
    ./stylix.nix
    ./users.nix
  ];

  options.my = {
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/mikkel/nixos-config";
      description = "Where this repo is checked out (used by nh, the Neovim symlink and the update reminder).";
    };
    gpu = lib.mkOption {
      type = lib.types.enum [
        "amd"
        "intel"
        "nvidia"
      ];
      description = "Which GPU driver stack the host uses.";
    };
    laptop.enable = lib.mkEnableOption "laptop features (power profiles, hibernate, brightness)";
    gaming.enable = lib.mkEnableOption "Steam, Proton-GE, Lutris and friends";
    windowsDualBoot = {
      enable = lib.mkEnableOption "a boot menu entry for Windows on another disk";
      efiPartUuid = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "PARTUUID of the Windows EFI partition (blkid -s PARTUUID -o value /dev/...).";
      };
    };
  };
}
