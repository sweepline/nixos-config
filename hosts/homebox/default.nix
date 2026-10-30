# Home server: ZFS (`ssd` pool on the SATA SSD for the OS and app data, `storage` raidz2 pool
# for media and photos), rootless Podman containers behind Caddy. Runs nixos-stable
# (flake.nix) and none of the desktop modules.
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-layout.nix
    ./zfs.nix
    ./users.nix
    ./domain.nix
    ./datasets.nix
    ./caddy.nix
    ./apps
  ];

  # Not signed: the server boots unattended and has no Windows or TPM unlock to protect.
  my.secureBoot.enable = false;

  # LAN only: the router forwards 443 and 50300 to this machine, never 22. From outside,
  # SSH goes through WireGuard (wg0, opened in modules/nixos/common/networking.nix).
  networking.firewall.interfaces.enp4s0.allowedTCPPorts = [ 22 ];
}
