{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # The GPU Screen Recorder overlay (ShadowPlay-style, controlled with gsr-ui-cli) is not in
  # NixOS 26.05. It comes from nixos-unstable but is built against this system's own
  # gpu-screen-recorder, like NixOS's own module does: the recorder, the overlay and the
  # script on Mod+Shift+R then all share the same gsr-kms-server wrapper.
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  gsrUi = unstable.gpu-screen-recorder-ui.override {
    gpu-screen-recorder = config.programs.gpu-screen-recorder.package;
    inherit (config.security) wrapperDir;
  };
in
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

  environment.systemPackages =
    with pkgs;
    [
      lutris
      heroic
      protonup-qt
      wineWow64Packages.staging
      winetricks
    ]
    ++ [ gsrUi ];

  # The overlay runs in the background and is controlled with `gsr-ui-cli` (Hyprland binds in
  # hosts/97/hyprland.lua). Its own global hotkeys (Left Alt+Z, ...) are not set up: they need
  # gsr-global-hotkeys, which grabs every keyboard and re-emits the keys through a virtual
  # keyboard, so Hyprland's per-keyboard options (Caps as Ctrl, Alt/Win swap) would stop
  # applying. To get them anyway, add a security.wrappers."gsr-global-hotkeys" entry
  # (capabilities "cap_setuid+ep", source = lib.getExe' gsrUi "gsr-global-hotkeys").
  systemd.user.services.gsr-ui = {
    description = "GPU Screen Recorder overlay";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe' gsrUi "gsr-ui"} launch-daemon";
      Restart = "on-failure";
    };
  };

  users.users.mikkel.extraGroups = [ "gamemode" ];
}
