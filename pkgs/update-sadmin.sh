#!/usr/bin/env bash
# Bump pkgs/sadmin.nix to the newest simple-admin release (version and hash), then
# rebuild with `nh os switch`. Run it when sadmin says it is out of date.
set -euo pipefail

file="$(cd "$(dirname "$0")" && pwd)/sadmin.nix"
release="$(curl -fsSL https://api.github.com/repos/antialize/simple-admin/releases/latest)"
version="$(jq -r '.tag_name | ltrimstr("v")' <<<"$release")"
digest="$(jq -r '.assets[] | select(.name == "sadmin-client.zip") | .digest | ltrimstr("sha256:")' <<<"$release")"
[[ -n "$version" && -n "$digest" ]] || { echo "Could not read the latest release" >&2; exit 1; }

current="$(sed -n 's/^  version = "\(.*\)";/\1/p' "$file")"
if [[ "$version" == "$current" ]]; then
    echo "sadmin is already at $version"
    exit 0
fi

hash="$(nix hash convert --hash-algo sha256 --to sri "$digest")"
sed -i -e "s|^  version = \".*\";|  version = \"$version\";|" \
       -e "s|^    hash = \".*\";|    hash = \"$hash\";|" "$file"
echo "sadmin: $current -> $version. Now run: nh os switch"
