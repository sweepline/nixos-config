{
  description = "NixOS configuration for dongmyo, 97, esa and the home server homebox";

  inputs = {
    # Rolling: nixos-unstable only advances when the channel's tests pass, so what it points
    # to is built and cached. flake.lock pins the exact revision; update with `nh os switch --update`.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # The server (homebox) runs the stable release: fewer, smaller updates, and a kernel that
    # ZFS supports. Update it on its own with `nix flake update nixpkgs-stable home-manager-stable`.
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager must match the nixpkgs release it runs on.
    home-manager-stable = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    # Podman quadlets from Nix (homebox's rootless containers). Has no inputs of its own.
    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

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
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      ...
    }@inputs:
    let
      mkHost =
        hostName: nixpkgs: modules:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs hostName; };
          modules = [
            ./hosts/${hostName}
            ./modules/nixos/common
          ]
          ++ modules;
        };
      mkDesktop = hostName: mkHost hostName nixpkgs [ ./modules/nixos/desktop ];
    in
    {
      nixosConfigurations = {
        dongmyo = mkDesktop "dongmyo";
        "97" = mkDesktop "97";
        esa = mkDesktop "esa";
        # Everything server-specific is in hosts/homebox.
        homebox = mkHost "homebox" nixpkgs-stable [ ];
      };

      # homebox's migration from Ubuntu, run from the installer (docs/HOMEBOX-MIGRATION.md):
      # nix run .#homebox-restore -- --dry-run /mnt/storage/backup/migration
      packages.x86_64-linux.homebox-restore =
        self.nixosConfigurations.homebox.config.system.build.homeboxRestore;

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
    };
}
