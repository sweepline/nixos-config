# Shared by every host, desktops and the server alike. Desktop-only modules and options are in
# ../desktop, which flake.nix adds for the desktop hosts.
{ inputs, ... }:
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.disko.nixosModules.disko

    ./base.nix
    ./boot.nix
    ./networking.nix
    ./users.nix
  ];
}
