{
  lib,
  pkgs,
  hostName,
  ...
}:
let
  hasWg = builtins.pathExists ../../../secrets/wg0-${hostName}.age;
in
{
  # Wi-Fi: iwd. Addresses still come from systemd-networkd (../common/networking.nix).
  networking.wireless.iwd = {
    enable = true;
    settings = {
      General.EnableNetworkConfiguration = false;
      Settings.AutoConnect = true;
    };
  };

  # pkexec only runs with polkit's authorization when it is setuid, and NixOS only creates
  # that wrapper if asked (desktop environments do so via their modules; Hyprland does not).
  # Without it /run/wrappers/bin/pkexec does not exist at all.
  security.polkit.enablePkexecWrapper = lib.mkIf hasWg true;

  # The ashell WireGuard popup (modules/home/ashell.nix) reads peer details with `wg show`,
  # which needs root. Allow exactly that command (same store path) without a password prompt.
  security.polkit.extraConfig = lib.mkIf hasWg ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.policykit.exec" &&
          subject.user == "mikkel" &&
          action.lookup("command_line") == "${pkgs.wireguard-tools}/bin/wg show wg0 dump") {
        return polkit.Result.YES;
      }
    });
  '';
}
