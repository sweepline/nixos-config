{ lib, ... }:
{
  imports = [
    ./hyprland
    ./idle-lock.nix
    ./ashell.nix
    ./mako.nix
    ./rofi.nix
    ./kitty.nix
    ./shell.nix
    ./ssh-git.nix
    ./firefox.nix
    ./neovim.nix
    ./opencode.nix
    ./packages.nix
    ./mimeapps.nix
    ./theme.nix
    ./wallpaper.nix
    ./screen-record.nix
    ./update-reminder.nix
    ./gaming.nix
    ./laptop.nix
    ./work.nix
  ];

  options.my.hyprland.hostConfig = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = "Host-specific Hyprland Lua (monitors, input devices, workspace and window rules).";
  };

  config = {
    home.username = "mikkel";
    home.homeDirectory = "/home/mikkel";
    home.stateVersion = "26.05";
    programs.home-manager.enable = true;

    xdg.enable = true;
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
