{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.my.work.enable {
  # Scalgo's network is reached over Tailscale.
  services.tailscale.enable = true;

  # Over Tailscale only SSH is reachable; open more ports here when needed.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

  # Scalgo's root CA (copied from mono/scripts/ca/root.crt), so https://localhost.scalgo.com
  # dev servers and internal hosts are trusted by curl, OpenSSL, Python etc. Replaces
  # `pnpm run certinstall`, which only writes to NSS dbs. Browsers: see modules/home/work.nix.
  security.pki.certificateFiles = [ ../../certs/scalgo-root.crt ];

  # sadmin (simple-admin client); it reads its server from /etc/sadmin.json.
  environment.systemPackages = [ (pkgs.callPackage ../../pkgs/sadmin.nix { }) ];
  environment.etc."sadmin.json".text = builtins.toJSON {
    server_host = "sadmin.scalgo.com";
    server_port = 443;
  };
}
