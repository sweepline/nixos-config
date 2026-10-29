{ pkgs, ... }:
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
    # My user keys from every host, so SSH between my machines works right after an install.
    openssh.authorizedKeys.keys = builtins.attrValues (import ../../../secrets/keys.nix).users;
    # Set with `passwd` after install (see docs/INSTALL.md).
    initialPassword = "changeme";
  };
}
