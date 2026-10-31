{
  config,
  lib,
  pkgs,
  ...
}:
let
  apps = import ./lib.nix { inherit config lib pkgs; };
  # Own user (isolated: reachable from the internet as stream.<domain>).
  uid = 3001;
  owner = apps.hostId uid;

  # The GPU for transcoding, by PCI address (`lspci`). The AMD iGPU (VAAPI) until the Intel
  # Arc A380 is in: then change this to the Arc's address (adding a card can also shift the
  # iGPU's), and switch Jellyfin to Intel QSV in Dashboard → Playback → Transcoding. The
  # device path in the container stays /dev/dri/renderD128.
  gpu = "0000:0a:00.0";
in
{
  my.datasets = {
    "ssd/appdata/jellyfin" = {
      inherit owner;
      group = owner;
      mode = "0700";
    };
    "ssd/cache".create = false;
    # Image cache and transcodes: re-created by Jellyfin, never backed up.
    "ssd/cache/jellyfin" = {
      inherit owner;
      group = owner;
      mode = "0700";
    };
  };

  my.proxy."jellyfin.i" = {
    port = 8096;
    maintenance = true;
  };
  my.proxy."stream" = {
    port = 8096;
    public = true;
    maintenance = true;
  };

  # Only Jellyfin may use the GPU: the render node gets Jellyfin's own group (its container
  # group 3001 is this GID on the host). The usual alternative, `--group-add keep-groups`,
  # would pass all of mikkel's groups into the container, media and music included, so a
  # breakout could write to the media and music trees.
  users.groups.jellyfin-gpu.gid = lib.toInt owner;
  # It also gets a fixed name without colons: podman splits a device argument at `:` (host
  # path, container path), so the by-path name with the PCI address cannot be passed directly
  # (found on the server: podman looked for /dev/dri/by-path/pci-0000).
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="renderD*", KERNELS=="${gpu}", GROUP="jellyfin-gpu", MODE="0660", SYMLINK+="dri/jellyfin-render"
  '';
  # To watch the GPU while transcoding (intel_gpu_top, once the Arc is in).
  environment.systemPackages = [ pkgs.intel-gpu-tools ];

  home-manager.users.mikkel.virtualisation.quadlet.containers.jellyfin = lib.mkMerge [
    (apps.container {
      name = "jellyfin";
      image = "docker.io/jellyfin/jellyfin:latest";
      runAs = apps.runAs.isolated uid;
      ports = [ "8096:8096" ];
      # Jellyseerr reaches it as http://jellyfin:8096.
      networks = [ apps.network ];
      volumes = [
        "/srv/appdata/jellyfin:/config"
        "/srv/cache/jellyfin:/cache"
        "/storage/media:/media:ro"
      ];
      domainEnv.JELLYFIN_PublishedServerUrl = "https://stream.@DOMAIN@";
    })
    {
      containerConfig.devices = [ "/dev/dri/jellyfin-render:/dev/dri/renderD128" ];
    }
  ];
}
