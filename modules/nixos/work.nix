{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.my.work.enable {
  # Scalgo's network is reached over Tailscale.
  services.tailscale.enable = true;

  # Over Tailscale only SSH and HTTP(S) are reachable; open more ports here when needed.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    22
    80
    443
  ];

  # sadmin (simple-admin client); it reads its server from /etc/sadmin.json.
  environment.systemPackages = [ (pkgs.callPackage ../../pkgs/sadmin.nix { }) ];
  environment.etc."sadmin.json".text = builtins.toJSON {
    server_host = "sadmin.scalgo.com";
    server_port = 443;
  };
}
