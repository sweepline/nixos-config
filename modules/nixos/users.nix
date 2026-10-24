{
  inputs,
  hostName,
  pkgs,
  ...
}:
{
  users.users.mikkel = {
    isNormalUser = true;
    uid = 1000;
    description = "Mikkel";
    extraGroups = [
      "wheel"
      "video"
      "audio"
    ];
    shell = pkgs.bashInteractive;
    # Set with `passwd` after install (see docs/INSTALL.md).
    initialPassword = "changeme";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs hostName; };
    users.mikkel = {
      imports = [
        ../home
        ../../hosts/${hostName}/home.nix
      ];
    };
  };
}
