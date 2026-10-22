{
  config,
  lib,
  hostName,
  ...
}:
let
  wgSecret = ../../secrets/wg0-${hostName}.age;
  hasWg = builtins.pathExists wgSecret;
in
{
  networking.hostName = hostName;

  networking.networkmanager = {
    enable = true;
    unmanaged = [ "wg0" ];
  };

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
  };

  services.tailscale.enable = true;

  # sshd mainly exists for the host key, which agenix uses to decrypt secrets.
  # It is only reachable over Tailscale.
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

  # The secret only exists once the host key is in secrets/secrets.nix
  # (see docs/INSTALL.md), so the first install works without it.
  age.secrets.wg0 = lib.mkIf hasWg { file = wgSecret; };
  networking.wg-quick.interfaces.wg0 = lib.mkIf hasWg {
    configFile = config.age.secrets.wg0.path;
    autostart = true;
  };
}
