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
    work.enable = true;
  };

  # wayvnc (vncstart, see home.nix) for the meeting room, only over Tailscale (my.work.enable).
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 5900 ];
}
