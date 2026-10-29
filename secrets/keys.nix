# Public SSH keys, shared by agenix-rules.nix (who can decrypt) and modules/nixos/common/users.nix
# (which user keys may log in as mikkel).
#   - host keys (/etc/ssh/ssh_host_ed25519_key.pub) decrypt secrets at boot
#   - user keys (~/.ssh/id_ed25519.pub) edit secrets with `agenix -e` and log in over SSH
{
  users = {
    mikkel-97 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAIdYiu934vjS4+OXYk4h5JZVxnt5Dyc7ZriQymDRkDE mikkel@97";
    mikkel-dongmyo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJpeNyLzRqLEhYUC2Mrsup9EjQGtrEf1dC9lKCGwUs8h mikkel@dongmyo";
    mikkel-esa = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINk0MhqudF8yyTQztWhG139NnI12+7wIZA9NuIXB3OO6 mikkel@esa";
  };
  hosts = {
    "97" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAjihOUzskazYyFfPVUtte1ur3K3+Uw3LAUBr9Y5Ux4P root@97";
    dongmyo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGi7nDvIomxVJGR9s02adq5Rzw1nq3cHl4gAyromyGlN root@dongmyo";
    esa = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIALopaNQ/q+QaplmkE6Fk6tL67NxApgCfVcmLeEpTZBE root@esa";
    # Host key of the Ubuntu install, kept for the NixOS reinstall (docs/INSTALL.md 2.5), so
    # secrets work on the first boot.
    homebox = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8svOVgyLcPuuK/0ZDmPZlKv/kpHYC5nZj1p0CpZ4bm root@homebox";
  };
}
