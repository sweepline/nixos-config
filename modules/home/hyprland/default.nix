{
  config,
  lib,
  pkgs,
  ...
}:
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

  reloadDesktop = pkgs.writeShellApplication {
    name = "reload-desktop";
    runtimeInputs = with pkgs; [
      systemd
      procps
      libnotify
    ];
    text = ''
      hyprctl reload
      # try-restart skips units that are not running
      systemctl --user try-restart ashell mako hyprpaper hyprsunset hypridle
      pkill -USR1 kitty || true
      notify-send -t 2000 "Desktop reloaded"
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
    reloadDesktop
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

  # Bluetooth pairing agent (PIN/confirm prompts) and tray icon. Normally started from XDG
  # autostart, which Hyprland does not run.
  services.blueman-applet.enable = true;

  # Clipboard history (text and images), picker on Mod+Shift+V
  services.cliphist = {
    enable = true;
    allowImages = true;
  };

  # Keep passwords copied from Bitwarden out of the history. The Firefox extension sets no
  # "x-kde-passwordManagerHint" mimetype and its popup is not a window of its own, so neither can
  # be used to recognise it. What does differ is the offered mimetypes: it offers plain text plus
  # SAVE_TARGETS and no text/html, unlike a copy from a web page. This also drops copies from
  # Firefox's URL bar and input fields. Only text is filtered; the image watcher is left alone.
  systemd.user.services.cliphist.Service.ExecStart = lib.mkForce (
    let
      store = pkgs.writeShellScript "cliphist-store" ''
        types=$(${pkgs.wl-clipboard}/bin/wl-paste -l)
        case "$types" in
          *text/html*) ;;
          *SAVE_TARGETS*) exit 0 ;;
        esac
        ${pkgs.cliphist}/bin/cliphist -max-dedupe-search 10 -max-items 500 store
      '';
    in
    "${pkgs.wl-clipboard}/bin/wl-paste --watch ${store}"
  );
}
