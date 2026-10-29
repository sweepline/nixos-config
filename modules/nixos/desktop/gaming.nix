{
  config,
  lib,
  pkgs,
  ...
}:
let
  # The GPU Screen Recorder overlay (ShadowPlay-style, controlled with gsr-ui-cli), built
  # against this system's own gpu-screen-recorder like NixOS's own module does: the recorder,
  # the overlay and the script on Mod+Shift+R then all share the same gsr-kms-server wrapper.
  # (programs.gpu-screen-recorder.ui.enable is not used: it also installs the
  # gsr-global-hotkeys wrapper, see below.)
  gsrUi = pkgs.gpu-screen-recorder-ui.override {
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
  # xone enables xpad-noone by default, but its package breaks the kernel modules build on
  # unstable (NixOS/nixpkgs#575192). Remove both lines below once that is fixed.
  hardware.xpad-noone.enable = false;
  # xone blacklists the kernel's xpad, which drives the wireless Xbox 360 receiver (Guitar
  # Hero controller) and the GameSir Kaleid (3537:1004). systemd-modules-load (boot.kernelModules)
  # now honours the blacklist, so load it with modprobe by name, which ignores it
  # (not mkForce on the blacklist: that would also drop e.g. NVIDIA's nouveau blacklist).
  systemd.services.load-xpad = {
    description = "Load xpad despite xone's blacklist";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.kmod}/bin/modprobe xpad";
    };
  };
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
  # modules/home/gaming.nix). Its own global hotkeys (Left Alt+Z, ...) are not set up: they need
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
