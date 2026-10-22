{ osConfig, pkgs, ... }:
let
  repo = osConfig.my.configDir;
  reminder = pkgs.writeShellScript "nixos-update-reminder" ''
    lock="${repo}/flake.lock"
    [ -f "$lock" ] || exit 0
    newest=$(${pkgs.jq}/bin/jq '[.nodes[] | .locked.lastModified? // 0] | max' "$lock")
    days=$(( ($(date +%s) - newest) / 86400 ))
    if [ "$days" -ge 7 ]; then
      ${pkgs.libnotify}/bin/notify-send -u normal "NixOS inputs are $days days old" \
        "Run: nh os switch --update (see docs/USAGE.md)"
    fi
  '';
in
{
  systemd.user.services.nixos-update-reminder = {
    Unit.Description = "Remind me to update the NixOS flake inputs";
    Service = {
      Type = "oneshot";
      ExecStart = "${reminder}";
    };
  };
  systemd.user.timers.nixos-update-reminder = {
    Unit.Description = "Weekly NixOS update reminder";
    Timer = {
      OnCalendar = "weekly";
      OnStartupSec = "10min";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
