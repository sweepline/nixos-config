{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.my.gaming.enable {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = true;

  # Xbox wireless adapter (dongle) for controllers
  hardware.xone.enable = true;
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  environment.systemPackages = with pkgs; [
    lutris
    heroic
    mangohud
    protonup-qt
    wineWow64Packages.staging
    winetricks
  ];

  users.users.mikkel.extraGroups = [ "gamemode" ];
}
