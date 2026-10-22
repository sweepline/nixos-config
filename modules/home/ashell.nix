{ pkgs, ... }:
let
  # Caps lock state from the keyboard LEDs. Polls, but only prints on change.
  capsWatch = pkgs.writeShellApplication {
    name = "capslock-watch";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      last=""
      while true; do
        state=off
        for led in /sys/class/leds/*::capslock/brightness; do
          [[ -r "$led" && "$(cat "$led")" != 0 ]] && state=on
        done
        if [[ "$state" != "$last" ]]; then
          if [[ "$state" == on ]]; then
            echo '{"text":"CAPS","alt":"on"}'
          else
            echo '{"text":"","alt":"off"}'
          fi
          last="$state"
        fi
        sleep 0.3
      done
    '';
  };
in
{
  programs.ashell = {
    enable = true;
    systemd.enable = true;
    settings = {
      position = "Top";
      modules = {
        left = [
          "Workspaces"
          "KeyboardSubmap"
        ];
        center = [
          "WindowTitle"
          "MediaPlayer"
        ];
        right = [
          "SystemInfo"
          [
            "capslock"
            "theme"
            "Tray"
            "Tempo"
            "Privacy"
            "Settings"
          ]
        ];
      };

      workspaces = {
        visibility_mode = "MonitorSpecific";
        enable_workspace_filling = false;
      };

      window_title.truncate_title_after_length = 100;

      tempo.clock_format = "%Y-%m-%d %H:%M";

      settings = {
        lock_cmd = "playerctl -a pause; loginctl lock-session";
        audio_sinks_more_cmd = "pavucontrol -t 3";
        audio_sources_more_cmd = "pavucontrol -t 4";
        wifi_more_cmd = "kitty -e impala";
        bluetooth_more_cmd = "blueman-manager";
        battery_format = "IconAndPercentage";
        indicators = [
          "IdleInhibitor"
          "PowerProfile"
          "Audio"
          "Microphone"
          "Bluetooth"
          "Network"
          "Vpn"
          "Battery"
          "Brightness"
        ];
      };

      # Light/dark toggle (see theme.nix)
      CustomModule = [
        {
          name = "theme";
          icon = "";
          command = "theme-toggle";
          listen_cmd = "theme-toggle watch";
          icons = {
            "dark" = "";
            "light" = "";
          };
        }
        # Shows "CAPS" while caps lock is on, nothing otherwise
        {
          name = "capslock";
          type = "Text";
          listen_cmd = "${capsWatch}/bin/capslock-watch";
        }
      ];

      # Colors and font come from stylix.
      appearance.style = "Islands";
    };
  };
}
