#!/usr/bin/env bash
# Back up a host before reinstalling it.
#
#   backup/backup.sh [host] [user@server:/path/]
#
# Reads backup/<host>.txt, warns about unpushed git work in ~/repos, creates an
# encrypted tar.zst.gpg (symmetric passphrase), uploads it with rsync and
# verifies the checksum on the server.
set -euo pipefail

host="${1:-$(hostname)}"
remote="${2:-mikkel@x.i.esmi.dk:/storage/backup/}"
here="$(cd "$(dirname "$0")" && pwd)"
list="$here/$host.txt"
work="${TMPDIR:-/tmp}/backup-$host"
archive="$work/${host}backup.tar.zst.gpg"

[[ -f "$list" ]] || { echo "No path list: $list" >&2; exit 1; }
for cmd in tar zstd gpg rsync ssh sha256sum sudo; do
    command -v "$cmd" >/dev/null || { echo "Missing: $cmd" >&2; exit 1; }
done

echo "==> Checking ~/repos and ~/nixos-config for work that is not on a remote"
dirty=0
shopt -s nullglob
for repo in "$HOME"/repos/*/ "$HOME/nixos-config/"; do
    [[ -d "$repo" ]] || continue
    [[ -d "$repo/.git" ]] || { echo "  NOT A GIT REPO: $repo"; dirty=1; continue; }
    git -C "$repo" remote | grep -q . || { echo "  NO REMOTE:      $repo"; dirty=1; }
    [[ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ]] && { echo "  UNCOMMITTED:    $repo"; dirty=1; }
    unpushed="$(git -C "$repo" log --branches --not --remotes --oneline 2>/dev/null | wc -l)"
    [[ "$unpushed" -gt 0 ]] && { echo "  UNPUSHED ($unpushed): $repo"; dirty=1; }
done
if [[ "$dirty" -eq 1 ]]; then
    read -rp "Repos above are NOT included in the backup. Continue anyway? [y/N] " ok
    [[ "$ok" == [yY] ]] || exit 1
fi

echo "==> Collecting paths from $list"
mkdir -p "$work"
paths=()
extra=()
while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    p="${line/#\~/$HOME}"
    if [[ "$p" == /etc/ssh/ssh_host_ed25519_key ]]; then
        if sudo test -e "$p"; then
            paths+=("etc/ssh/ssh_host_ed25519_key" "etc/ssh/ssh_host_ed25519_key.pub")
        else
            rm -rf "$work/keys" && mkdir -p "$work/keys/etc/ssh"
            ssh-keygen -q -t ed25519 -N "" -C "root@$host" -f "$work/keys/etc/ssh/ssh_host_ed25519_key"
            extra=(-C "$work/keys" etc/ssh)
            echo "  GENERATED new host key: $(cat "$work/keys/etc/ssh/ssh_host_ed25519_key.pub")"
            cp "$work/keys/etc/ssh/ssh_host_ed25519_key.pub" "$work/$host-host-key.pub"
        fi
        continue
    fi
    if sudo test -e "$p"; then
        paths+=("${p#/}")
        printf '  %8s  %s\n' "$(sudo du -sh "$p" | cut -f1)" "$p"
    else
        echo "  MISSING (skipped): $p"
    fi
done < "$list"
[[ ${#paths[@]} -gt 0 ]] || { echo "Nothing to back up" >&2; exit 1; }

echo "==> Creating $archive (you will be asked for an encryption passphrase)"
sudo tar --numeric-owner --acls --xattrs -C / -cf - "${paths[@]}" "${extra[@]}" \
    | zstd -T0 -10 \
    | gpg --symmetric --cipher-algo AES256 --pinentry-mode loopback -o "$archive"
# The generated private host key is now inside the encrypted archive only.
rm -rf "$work/keys"

sum="$(sha256sum "$archive" | cut -d' ' -f1)"
echo "$sum  $(basename "$archive")" > "$archive.sha256"
echo "  size: $(du -h "$archive" | cut -f1), sha256: $sum"

echo "==> Uploading to $remote"
rsync -av --partial --progress "$archive" "$archive.sha256" "$remote"

echo "==> Verifying on server"
server="${remote%%:*}"
dir="${remote#*:}"
remote_sum="$(ssh "$server" "sha256sum '${dir%/}/$(basename "$archive")'" | cut -d' ' -f1)"
if [[ "$remote_sum" == "$sum" ]]; then
    echo "OK: checksum matches. Local copy kept in $work"
    if [[ -f "$work/$host-host-key.pub" ]]; then
        echo "New host public key (put it in secrets/keys.nix):"
        cat "$work/$host-host-key.pub"
    fi
else
    echo "CHECKSUM MISMATCH: local $sum, remote $remote_sum" >&2
    exit 1
fi
