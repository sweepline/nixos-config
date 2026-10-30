{
  config,
  lib,
  pkgs,
  ...
}:
let
  apps = import ./lib.nix { inherit config lib pkgs; };
in
{
  my.datasets."ssd/appdata/vaultwarden" = { };
  my.proxy."vaultwarden.i".port = 8000;

  home-manager.users.mikkel.virtualisation.quadlet.containers.vaultwarden = apps.container {
    name = "vaultwarden";
    image = "docker.io/vaultwarden/server:latest";
    runAs = apps.runAs.root;
    ports = [ "8000:80" ];
    volumes = [ "/srv/appdata/vaultwarden:/data" ];
    # Used for links in emails and for WebAuthn/passkeys, so it must match the URL in use.
    domainEnv.DOMAIN = "https://vaultwarden.i.@DOMAIN@";
  };
}
