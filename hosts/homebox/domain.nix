# The server's domain is a secret (docs/HOMEBOX.md): it resolves to the home IP, and this repo
# may be public. It only exists in secrets/domain-homebox.age as a single line
#   DOMAIN=example.net
# and is read at runtime: by Caddy ({$DOMAIN}, caddy.nix) and by the containers that need
# their own URL. Never read it at evaluation time (it would end up in the Nix store).
{ lib, ... }:
let
  secret = ../../secrets/domain-homebox.age;
in
{
  # Owned by mikkel: the rootless containers run as him. Caddy gets it through systemd's
  # EnvironmentFile, which root reads.
  age.secrets.domain = lib.mkIf (builtins.pathExists secret) {
    file = secret;
    owner = "mikkel";
    mode = "0400";
  };
}
