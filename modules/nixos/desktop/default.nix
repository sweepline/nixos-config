# Desktop hosts (97, dongmyo, esa): Hyprland session, Home Manager, stylix, and the
# per-machine options below.
{ inputs, lib, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.nixosModules.stylix

    ./base.nix
    ./checks.nix
    ./env-secrets.nix
    ./gaming.nix
    ./hardware.nix
    ./home.nix
    ./input.nix
    ./laptop.nix
    ./networking.nix
    ./session.nix
    ./stylix.nix
    ./work.nix
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
    theme = lib.mkOption {
      type = lib.types.enum [
        "dark"
        "light"
      ];
      default = "dark";
      description = "Theme a rebuild starts in; the ashell button switches to the other one at runtime.";
    };
    laptop.enable = lib.mkEnableOption "laptop features (power profiles, hibernate, brightness)";
    gaming.enable = lib.mkEnableOption "Steam, Proton-GE, Lutris and friends";
    work.enable = lib.mkEnableOption "Scalgo work setup (Tailscale, sadmin, SSH hosts, git aliases and email)";
  };
}
