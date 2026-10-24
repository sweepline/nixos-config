{ lib, hostName, ... }:
let
  envSecret = ../../secrets/env-${hostName}.age;
in
{
  # Per-host API tokens as KEY=value lines (each host has its own tokens, so one can be
  # revoked without touching the others). Bash loads them (modules/home/shell.nix).
  # Skipped until secrets/env-<host>.age exists, like the WireGuard secret.
  age.secrets.env = lib.mkIf (builtins.pathExists envSecret) {
    file = envSecret;
    owner = "mikkel";
    mode = "0400";
  };
}
