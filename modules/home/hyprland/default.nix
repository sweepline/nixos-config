{ config, pkgs, ... }:
let
  hyprExit = pkgs.writeShellApplication {
    name = "hypr-exit";
    runtimeInputs = [ pkgs.hyprshutdown ];
    text = ''
      choice=$(printf 'No\nYes, exit Hyprland' | rofi -dmenu -p 'Exit Hyprland?')
      if [ "$choice" = "Yes, exit Hyprland" ]; then
        hyprshutdown
      fi
    '';
  };

  dndToggle = pkgs.writeShellApplication {
    name = "dnd-toggle";
    runtimeInputs = with pkgs; [
      mako
      libnotify
      gnugrep
      coreutils
    ];
    text = ''
      if makoctl mode | grep -q do-not-disturb; then
        makoctl mode -r do-not-disturb
        notify-send "Do Not Disturb off"
      else
        notify-send "Do Not Disturb on"
        sleep 2
        makoctl mode -a do-not-disturb
      fi
    '';
  };
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    # Use the packages from the NixOS module (programs.hyprland).
    package = null;
    portalPackage = null;
    configType = "lua";
    systemd.variables = [ "--all" ];

    # The config is plain Lua: ./hyprland.lua, then the host's own file. Home Manager adds
    # the stylix colors before it and the systemd startup hook after it.
    extraConfig = builtins.readFile ./hyprland.lua + "\n" + config.my.hyprland.hostConfig;
  };

  home.packages = with pkgs; [
    grimblast
    playerctl
    brightnessctl
    wl-clipboard
    hyprpicker
    hyprshutdown
    libnotify
    hyprExit
    dndToggle
  ];

  # Night light: warmer screen from 21:00 to 07:00
  services.hyprsunset = {
    enable = true;
    settings.profile = [
      {
        time = "7:00";
        identity = true;
      }
      {
        time = "21:00";
        temperature = 4000;
      }
    ];
  };

  services.hyprpolkitagent.enable = true;

  # Clipboard history (text and images), picker on Mod+Shift+V
  services.cliphist = {
    enable = true;
    allowImages = true;
  };
}
