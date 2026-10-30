# Rootless containers, one module per app (docs/HOMEBOX.md, "Containers").
{ ... }:
{
  imports = [
    ./aurral.nix
    ./bazarr.nix
    ./immich.nix
    ./jellyfin.nix
    ./jellyseerr.nix
    ./joplin.nix
    ./lidarr.nix
    ./navidrome.nix
    ./prowlarr.nix
    ./radarr.nix
    ./rsgain.nix
    ./sabnzbd.nix
    ./slskd.nix
    ./sonarr.nix
    ./vaultwarden.nix
  ];

  home-manager.users.mikkel.virtualisation.quadlet = {
    # apps.network in lib.nix: apps on it reach each other by container name.
    networks.apps = { };

    autoUpdate = {
      enable = true;
      # Half an hour after sanoid's 04:00 snapshot of ssd/appdata (zfs.nix), so rolling back an
      # update that breaks an app's data loses at most 30 minutes. (The nightly syncoid copy
      # only matters if the SSD dies.) If an updated container does not start, podman
      # auto-update already goes back to the previous image by itself.
      calendar = "*-*-* 04:30:00";
    };
  };
}
