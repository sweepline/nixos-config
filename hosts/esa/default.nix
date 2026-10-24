{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    (import ../disk-layout.nix {
      # TODO: `ls -l /dev/disk/by-id/` on the installer
      device = "/dev/disk/by-id/CHANGE-ME";
    })
  ];

  my = {
    gpu = "intel"; # dedicated Intel Arc card (the CPU is AMD)
  };

  # wayvnc (vncstart, see home.nix), only over Tailscale.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 5900 ];
}
