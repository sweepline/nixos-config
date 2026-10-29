{
  config,
  lib,
  pkgs,
  ...
}:
let
  sadmin = pkgs.callPackage ../../../pkgs/sadmin.nix { };
in
lib.mkIf config.my.work.enable {
  # Scalgo's network is reached over Tailscale.
  services.tailscale.enable = true;

  # Over Tailscale only SSH is reachable; open more ports here when needed.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

  # Scalgo's root CA (copied from mono/scripts/ca/root.crt), so https://localhost.scalgo.com
  # dev servers and internal hosts are trusted by curl, OpenSSL, Python etc. Replaces
  # `pnpm run certinstall`, which only writes to NSS dbs. Browsers: see modules/home/work.nix.
  security.pki.certificateFiles = [ ../../../certs/scalgo-root.crt ];

  # Pin the work web UI to its Tailscale address: public DNS also returns a
  # public IPv4 and an IPv6 address whose path fails (bypassing tailscale0).
  # resolved suppresses the DNS A/AAAA lookups for names in /etc/hosts, so
  # this entry also keeps the name off IPv6.
  networking.extraHosts = ''
    100.79.163.123 i.scalgo.com
  '';

  # sadmin (simple-admin client); it reads its server from /etc/sadmin.json.
  # mono's deploy scripts prefer buildah when present: they read the pushed image digest
  # from `buildah push --digestfile`, while podman's docker shim prints no digest to parse.
  environment.systemPackages = [
    sadmin
    pkgs.buildah
  ];
  environment.etc."sadmin.json".text = builtins.toJSON {
    server_host = "sadmin.scalgo.com";
    server_port = 443;
  };

  # vanta-setup saves credentials before trying to write units into our read-only
  # /etc/systemd/system. Own the units here, keeping ExecStart on the packaged
  # version across upgrades. Registration credentials stay outside the Nix store.
  systemd.services.simpleadmin-vanta = {
    description = "SimpleAdmin Vanta compliance scan";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    unitConfig.ConditionPathExists = "/etc/simpleadmin/vanta.conf";
    # Probes run as root without an interactive PATH. Only expose the configured
    # firewall backend: an empty nft ruleset would mask an active iptables firewall.
    # Matches the commands the scanner runs (sadmin 0.1.13): findmnt/lsblk, pgrep,
    # loginctl/systemctl, nft/iptables; NixOS adds coreutils for `date`. gsettings and
    # xset are only used for GNOME and light-locker, not Hyprland. Recheck on updates.
    path = [
      config.networking.firewall.package
      pkgs.procps
      pkgs.systemd
      pkgs.util-linux
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe sadmin} vanta-scan-and-report";
      StateDirectory = "simpleadmin";
      UMask = "0077";
    };
  };

  systemd.timers.simpleadmin-vanta = {
    description = "SimpleAdmin Vanta compliance scan";
    wantedBy = [ "timers.target" ];
    # Upstream's unit uses OnBootSec=5min + OnUnitActiveSec=1d, where Persistent does
    # nothing. Calendar time instead: the monotonic clock stops during suspend, so machines
    # that sleep overnight would drift by days. Persistent catches up missed runs.
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };
}
