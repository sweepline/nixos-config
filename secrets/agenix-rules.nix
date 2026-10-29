# agenix recipients: who can decrypt which secret. The keys themselves are in keys.nix.
# After changing keys, re-encrypt everything: `agenix -r` (in this folder).
#
# User keys can edit all files, but host keys can only edit their devices files.
let
  inherit (import ./keys.nix) users hosts;
  allUsers = builtins.attrValues users;
  forHost = host: { publicKeys = allUsers ++ (if hosts ? ${host} then [ hosts.${host} ] else [ ]); };
in
{
  "wg0-97.age" = forHost "97";
  "wg0-dongmyo.age" = forHost "dongmyo";
  "wg0-esa.age" = forHost "esa";
  "wg0-homebox.age" = forHost "homebox";
  # API tokens (KEY=value lines), one set per host
  "env-97.age" = forHost "97";
  "env-dongmyo.age" = forHost "dongmyo";
  "env-esa.age" = forHost "esa";
}
