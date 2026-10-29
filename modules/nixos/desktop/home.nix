{ inputs, hostName, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs hostName; };
    users.mikkel = {
      imports = [
        inputs.nix-index-database.homeModules.nix-index
        ../../home
        ../../../hosts/${hostName}/home.nix
      ];
    };
  };
}
