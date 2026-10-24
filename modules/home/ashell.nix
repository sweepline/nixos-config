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
            echo '{"text":"","alt":"on"}'
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
      last=""
      while true; do
        state=down
        if [[ -d /sys/class/net/wg0 ]] &&
          [[ "$(tailscale status --json 2>/dev/null | jq -r '.BackendState // empty')" == Running ]]; then
          state=up
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
      # Usage: vpn-info [wg|ts]; both when no argument
      which="''${1:-all}"
      lines=()

      if [[ "$which" != ts ]]; then
        if [[ -d /sys/class/net/wg0 ]]; then
          # wg needs root; polkit asks for the password. The absolute path is needed because
          # PATH only holds the tools above.
          if dump="$(/run/wrappers/bin/pkexec ${pkgs.wireguard-tools}/bin/wg show wg0 dump 2>/dev/null)"; then
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
            lines+=("WireGuard: up (authentication cancelled)")
          fi
        else
          lines+=("WireGuard: down")
        fi
      fi

      if [[ "$which" != wg ]]; then
        status="$(tailscale status --json 2>/dev/null || echo '{}')"
        if [[ "$(echo "$status" | jq -r '.BackendState // empty')" == Running ]]; then
          exit_node="$(echo "$status" | jq -r '[.Peer[]? | select(.ExitNode)] | first | .HostName // "none"')"
          lines+=("Tailscale: running, $(echo "$status" | jq -r '.Self.TailscaleIPs[0]'), exit node: $exit_node")

          expiry="$(echo "$status" | jq -r '.Self.KeyExpiry // empty')"
          if [[ -n "$expiry" && "$expiry" != 0001-* ]]; then
            left=$(($(date -d "$expiry" +%s) - $(date +%s)))
            if ((left <= 0)); then
              lines+=("  key expired on $(date -d "$expiry" +%F)")
            else
              lines+=("  key expires in $((left / 86400))d $((left % 86400 / 3600))h ($(date -d "$expiry" +%F))")
            fi
          else
            lines+=("  key does not expire")
          fi

          while read -r line; do
            lines+=("  $line")
          done < <(echo "$status" | jq -r '.Peer[]? | select(.Online) | "\(.HostName)  \(.TailscaleIPs[0])"')
        else
          lines+=("Tailscale: down")
        fi
      fi

      choice="$(printf '%s\n' "''${lines[@]}" | rofi -dmenu -p vpn)" || exit 0
      ip="$(echo "$choice" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1 || true)"
      [[ -n "$ip" ]] && wl-copy "$ip"
      exit 0
    '';
  };

  # ashell runs as a systemd user service, outside the login session, so polkit cannot find the
  # graphical agent for anything it starts directly. Let Hyprland start the popup instead.
  vpnClick = pkgs.writeShellApplication {
    name = "vpn-click";
    text = ''
      ${pkgs.hyprland}/bin/hyprctl eval "hl.dispatch(hl.dsp.exec_cmd(\"${vpnInfo}/bin/vpn-info $*\"))"
    '';
  };
in
{
  programs.ashell = {
    enable = true;
    systemd.enable = true;
    settings = {
      position = "Top";
      # Above windows (but not fullscreen), so the window resize border does not cover the bar
      layer = "Top";
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
            "vpn"
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
        # WireGuard + Tailscale: closed lock when both are up, open lock otherwise; click for details
        {
          name = "vpn";
          icon = "󱦚";
          command = "${vpnClick}/bin/vpn-click";
          listen_cmd = "${vpnWatch}/bin/vpn-watch";
          icons = {
            "up" = "󰦝";
            "down" = "󱦚";
          };
        }
        # Caps lock: always shown, filled key while on
        {
          name = "capslock";
          icon = "󰜹";
          listen_cmd = "${capsWatch}/bin/capslock-watch";
          icons = {
            "on" = "󰜸";
            "off" = "󰜹";
          };
        }
      ];

      # Colors and font come from stylix.
      appearance.style = "Islands";
    };
  };
}
