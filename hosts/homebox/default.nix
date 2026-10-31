# Home server: ZFS (`ssd` pool on the SATA SSD for the OS and app data, `storage` raidz2 pool
# for media and photos), rootless Podman containers behind Caddy. Runs nixos-stable
# (flake.nix) and none of the desktop modules.
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-layout.nix
    ./zfs.nix
    ./alerts.nix
    ./users.nix
    ./domain.nix
    ./datasets.nix
    ./caddy.nix
    ./apps
    ./migration.nix
    ./vm.nix
  ];

  # Not signed: the server boots unattended and has no Windows or TPM unlock to protect.
  my.secureBoot.enable = false;

  # /home is its own dataset (disk-layout.nix). NixOS creates home directories early in the
  # boot, before systemd mounts the other filesystems, so without this /home/mikkel would be
  # created on the hidden root underneath, and Home Manager (with every container) would fail.
  # Found in the VM test.
  fileSystems."/home".neededForBoot = true;

  # LAN only: the router forwards 443 and 50300 to this machine, never 22. From outside,
  # SSH goes through WireGuard (wg0, opened in modules/nixos/common/networking.nix).
  networking.firewall.interfaces.enp8s0.allowedTCPPorts = [ 22 ];
}
