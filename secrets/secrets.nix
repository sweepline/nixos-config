# agenix recipients: who can decrypt which secret.
#   - host keys (/etc/ssh/ssh_host_ed25519_key.pub) decrypt at boot
#   - user keys (~/.ssh/id_ed25519.pub) let you edit secrets with `agenix -e`
# After changing keys here, re-encrypt everything: `agenix -r` (in this folder).
let
  users = {
    mikkel-97 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAIdYiu934vjS4+OXYk4h5JZVxnt5Dyc7ZriQymDRkDE mikkel@97";
    # TODO: add the user keys from dongmyo and esa
  };
  hosts = {
    # TODO: from backup.sh output (97) and `cat /etc/ssh/ssh_host_ed25519_key.pub` (others)
    # "97" = "ssh-ed25519 AAAA... root@97";
    # dongmyo = "ssh-ed25519 AAAA... root@dongmyo";
    # esa = "ssh-ed25519 AAAA... root@esa";
  };
  allUsers = builtins.attrValues users;
  forHost = host: { publicKeys = allUsers ++ (if hosts ? ${host} then [ hosts.${host} ] else [ ]); };
in
{
  "wg0-97.age" = forHost "97";
  "wg0-dongmyo.age" = forHost "dongmyo";
  "wg0-esa.age" = forHost "esa";
}
