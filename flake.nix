{
  description = "NixOS configuration for dongmyo, 97 and esa";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Only for packages that are not in 26.05 yet (the GPU Screen Recorder overlay, see
    # modules/nixos/gaming.nix).
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ly-community = {
      url = "git+https://codeberg.org/fairyglade/ly-community";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      mkHost =
        hostName:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs hostName; };
          modules = [
            ./hosts/${hostName}
            ./modules/nixos
          ];
        };
    in
    {
      nixosConfigurations = {
        dongmyo = mkHost "dongmyo";
        "97" = mkHost "97";
        esa = mkHost "esa";
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
    };
}
