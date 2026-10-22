#!/usr/bin/env bash
# Restore a backup made by backup.sh.
#
#   backup/restore.sh <archive.tar.zst.gpg> [root]
#
# root defaults to / (use /mnt from the installer, before nixos-install).
# Everything is unpacked to <root>/home/mikkel/restore-<host>/ first. Then
# ~/.ssh and the SSH host keys are put in place, and Pictures/Videos are moved
# home. Game saves stay in the restore folder: copy them after the game has
# been started once (see docs/INSTALL.md).
set -euo pipefail

archive="${1:?usage: restore.sh <archive.tar.zst.gpg> [root]}"
root="${2:-/}"
user=mikkel
uid=1000
gid=100
name="$(basename "$archive")"
stage="$root/home/$user/restore-${name%%backup*}"
home_rel="home/$user"

mkdir -p "$stage"
echo "==> Unpacking into $stage"
gpg --decrypt --pinentry-mode loopback "$archive" | zstd -d | tar --numeric-owner -C "$stage" -xpf -

src_home="$(find "$stage/home" -mindepth 1 -maxdepth 1 -type d | head -1)"

if [[ -d "$stage/etc/ssh" ]]; then
    echo "==> Installing SSH host keys"
    mkdir -p "$root/etc/ssh"
    install -m600 -o0 -g0 "$stage/etc/ssh/ssh_host_ed25519_key" "$root/etc/ssh/"
    install -m644 -o0 -g0 "$stage/etc/ssh/ssh_host_ed25519_key.pub" "$root/etc/ssh/"
fi

for d in .ssh Pictures Videos; do
    if [[ -d "$src_home/$d" ]]; then
        echo "==> Restoring ~/$d"
        mkdir -p "$root/$home_rel"
        cp -a "$src_home/$d" "$root/$home_rel/"
        rm -rf "${src_home:?}/$d"
    fi
done
chmod 700 "$root/$home_rel/.ssh" 2>/dev/null || true
chown -R "$uid:$gid" "$root/$home_rel"

echo "Done. Remaining files (game saves) are in $stage"
