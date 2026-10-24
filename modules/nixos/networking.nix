{
  config,
  lib,
  pkgs,
  hostName,
  ...
}:
let
  wgSecret = ../../secrets/wg0-${hostName}.age;
  hasWg = builtins.pathExists wgSecret;
in
{
  networking.hostName = hostName;

  # Wi-Fi: iwd. Addresses (wired and wireless): systemd-networkd. DNS: systemd-resolved.
  networking.wireless.iwd = {
    enable = true;
    settings = {
      General.EnableNetworkConfiguration = false;
      Settings.AutoConnect = true;
    };
  };
  networking.useNetworkd = true;
  networking.useDHCP = true;
  systemd.network.wait-online.anyInterface = true;
  services.resolved.enable = true;
  # mDNS (.local, printer discovery) is avahi's job (modules/nixos/base.nix): CUPS and
  # the GTK print dialog browse through it. Two mDNS stacks make it unreliable.
  services.resolved.settings.Resolve = {
    MulticastDNS = false;
    LLMNR = false;
  };

  networking.firewall.enable = true;

  # sshd mainly exists for the host key, which agenix uses to decrypt secrets.
  # It is reachable between my own machines over WireGuard (below) and, with
  # my.work.enable, over Tailscale (modules/nixos/work.nix).
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # The secret only exists once the host key is in secrets/agenix-rules.nix
  # (see docs/INSTALL.md), so the first install works without it.
  age.secrets.wg0 = lib.mkIf hasWg { file = wgSecret; };
  networking.wg-quick.interfaces.wg0 = lib.mkIf hasWg {
    configFile = config.age.secrets.wg0.path;
    autostart = true;
  };
  networking.firewall.interfaces.wg0.allowedTCPPorts = lib.mkIf hasWg [ 22 ];

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
