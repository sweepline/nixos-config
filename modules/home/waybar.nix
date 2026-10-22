{ ... }:
let
  # Module settings (with Font Awesome glyphs) carried over from the old sway waybar config.
  modules = builtins.fromJSON (builtins.readFile ./waybar-modules.json);
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings.main = modules // {
      height = 30;
      spacing = 4;
      modules-left = [
        "hyprland/workspaces"
        "hyprland/submap"
      ];
      modules-center = [ "hyprland/window" ];
      modules-right = [
        "idle_inhibitor"
        "custom/theme"
        "pulseaudio"
        "network"
        "cpu"
        "memory"
        "temperature"
        "backlight"
        "power-profiles-daemon"
        "battery"
        "clock"
        "tray"
      ];

      "hyprland/workspaces" = {
        all-outputs = false;
        format = "{name}";
      };
      "hyprland/submap".format = "<span style=\"italic\">{}</span>";
      "hyprland/window".separate-outputs = true;

      "custom/theme" = {
        exec = "theme-toggle watch";
        return-type = "json";
        on-click = "theme-toggle";
        tooltip = true;
      };

      power-profiles-daemon = {
        format = "{profile}";
        tooltip-format = "Power profile: {profile}";
      };
    };
    style = ''
      #clock, #battery, #cpu, #memory, #temperature, #backlight, #network,
      #pulseaudio, #tray, #submap, #idle_inhibitor, #custom-theme,
      #power-profiles-daemon {
        padding: 0 10px;
      }
      #battery.critical:not(.charging) {
        color: @base08;
      }
    '';
  };
}
