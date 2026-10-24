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

  # WireGuard (wg-quick, systemd unit wg-quick-wg0) and Tailscale status. ashell's own VPN
  # indicator only knows NetworkManager. Polls, but only prints on change.
  vpnWatch = pkgs.writeShellApplication {
    name = "vpn-watch";
    runtimeInputs = with pkgs; [
      coreutils
      jq
      tailscale
    ];
    text = ''
      # Usage: vpn-watch wg|ts
      which="''${1:?wg or ts}"
      last=""
      while true; do
        state=down
        if [[ "$which" == wg ]]; then
          [[ -d /sys/class/net/wg0 ]] && state=up
        else
          [[ "$(tailscale status --json 2>/dev/null | jq -r '.BackendState // empty')" == Running ]] && state=up
        fi
        if [[ "$state" != "$last" ]]; then
          echo "{\"text\":\"\",\"alt\":\"$state\"}"
          last="$state"
        fi
        sleep 3
      done
    '';
  };

  # Details for the vpn module: shown in rofi, picking a line copies its IP address.
  vpnInfo = pkgs.writeShellApplication {
    name = "vpn-info";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnugrep
      jq
      tailscale
      rofi
      wl-clipboard
    ];
    text = ''
      lines=()

      if [[ -d /sys/class/net/wg0 ]]; then
        # wg needs root; polkit asks for the password.
        if dump="$(pkexec ${pkgs.wireguard-tools}/bin/wg show wg0 dump 2>/dev/null)"; then
          now="$(date +%s)"
          lines+=("WireGuard: up")
          while read -r endpoint allowed handshake; do
            if [[ "$handshake" == 0 ]]; then
              ago="no handshake yet"
            else
              ago="handshake $((now - handshake))s ago"
            fi
            lines+=("  peer $endpoint, $allowed, $ago")
          done < <(echo "$dump" | tail -n +2 | awk -F'\t' '{print $3, $4, $5}')
        else
          lines+=("WireGuard: up (details need authentication)")
        fi
      else
        lines+=("WireGuard: down")
      fi

      status="$(tailscale status --json 2>/dev/null || echo '{}')"
      if [[ "$(echo "$status" | jq -r '.BackendState // empty')" == Running ]]; then
        exit_node="$(echo "$status" | jq -r '[.Peer[]? | select(.ExitNode)] | first | .HostName // "none"')"
        lines+=("Tailscale: running, $(echo "$status" | jq -r '.Self.TailscaleIPs[0]'), exit node: $exit_node")
        while read -r line; do
          lines+=("  $line")
        done < <(echo "$status" | jq -r '.Peer[]? | select(.Online) | "\(.HostName)  \(.TailscaleIPs[0])"')
      else
        lines+=("Tailscale: down")
      fi

      choice="$(printf '%s\n' "''${lines[@]}" | rofi -dmenu -p vpn)" || exit 0
      ip="$(echo "$choice" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1 || true)"
      [[ -n "$ip" ]] && wl-copy "$ip"
      exit 0
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
          "MediaPlayer"
          "WindowTitle"
          "KeyboardSubmap"
        ];
        center = [
          "Workspaces"
        ];
        right = [
          "SystemInfo"
          [
            "capslock"
            "wg"
            "ts"
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
        # WireGuard and Tailscale status (red dot when down); click for details
        {
          name = "wg";
          icon = "";
          command = "${vpnInfo}/bin/vpn-info";
          listen_cmd = "${vpnWatch}/bin/vpn-watch wg";
          icons."up|down" = "";
          alert = "down";
        }
        {
          name = "ts";
          icon = "󱗼";
          command = "${vpnInfo}/bin/vpn-info";
          listen_cmd = "${vpnWatch}/bin/vpn-watch ts";
          icons."up|down" = "󱗼";
          alert = "down";
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
