{ inputs, ... }:
{
  imports = [
    inputs.home-manager-stable.nixosModules.home-manager
    # System side of rootless quadlets: Podman's systemd generator. The containers themselves
    # are defined per user in Home Manager (home-manager.users.mikkel below).
    inputs.quadlet-nix.nixosModules.quadlet
  ];

  # IDs match the Ubuntu install, because the existing data is owned by them:
  # - files written as root inside a container belong to mikkel:mikkel (1000:1000) on the
  #   host. Rootless Podman maps the container's group 0 to the user's *primary* group, so it
  #   must stay `mikkel` (1000) instead of NixOS's default `users` (100).
  # - every other container user maps into mikkel's subordinate range: container uid N
  #   = host uid 100000 + N - 1 (media files are 101000, linuxserver's abc is 100910, postgres
  #   100998/100999). A different range would leave all of that owned by "nobody".
  users.groups.mikkel.gid = 1000;
  users.users.mikkel = {
    group = "mikkel";
    # The render node (/dev/dri/renderD128) is passed to Jellyfin for VAAPI transcoding.
    extraGroups = [ "render" ];
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
    # Start mikkel's systemd user manager (and with it the containers) at boot, without a login.
    linger = true;
  };

  virtualisation.quadlet.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs; };
    users.mikkel = {
      imports = [ inputs.quadlet-nix.homeManagerModules.quadlet ];
      home.stateVersion = "26.05";
    };
  };
}
