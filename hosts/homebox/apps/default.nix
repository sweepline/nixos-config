# Rootless containers, one module per app (docs/HOMEBOX.md, "Containers").
{ ... }:
{
  imports = [
    ./vaultwarden.nix
  ];

  home-manager.users.mikkel.virtualisation.quadlet.autoUpdate = {
    enable = true;
    # After the nightly copy of the app data (syncoid at 03:30, zfs.nix), so an update that
    # breaks an app's data can be rolled back to a fresh snapshot.
    calendar = "*-*-* 04:30:00";
  };
}
