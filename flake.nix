{
  description = "NixOS configuration for dongmyo, 97 and esa";

  inputs = {
    # Rolling: nixos-unstable only advances when the channel's tests pass, so what it points
    # to is built and cached. flake.lock pins the exact revision; update with `nh os switch --update`.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # opencode 2.x is only published as git tags (nixpkgs has 2.0.x). Upstream's flake builds
    # a tag with its own maintained hashes. To update, change the tag here and run
    # `nix flake update opencode`.
    opencode = {
      url = "github:anomalyco/opencode/v2.1.4";
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

    # Prebuilt nix-index database (nix-locate, command-not-found, comma), updated with the lock.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
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
