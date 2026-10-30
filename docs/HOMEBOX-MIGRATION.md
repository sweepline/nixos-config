# homebox: migration runbook

Moving the home server from Ubuntu + podman-compose to NixOS (`hosts/homebox`). Decisions
and background: [HOMEBOX.md](HOMEBOX.md). Every command here is run by hand; nothing in the
repo changes the server by itself.

Expected downtime: 2–3 hours, mostly imaging the SSD (465 GB) and copying the music (83 GB).

`<disk>` below is the SSD: `/dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S6PYNM0T410222R`.
Check it with `ls -l /dev/disk/by-id/ | grep -v part` before every command that writes to it:
the other disks are the five pool HDDs and the two NVMe drives of the pool's special vdev.

## A. Before (days ahead, the server keeps running)

1. **Secrets** in `secrets/` (TODO.md): `caddy`, `domain`, `wg0`, `navidrome`, `joplin`,
   `immich` (`*-homebox.age`). Check that each decrypts to the expected keys:
   `cd secrets && for f in *-homebox.age; do echo "$f: $(agenix -d $f | cut -d= -f1 | tr '\n' ' ')"; done`
2. **DNS** for the new domain (TODO.md), any time before: the wildcard A record (UniFi DDNS)
   and the TXT on `i.` on Cloudflare, `*.i.<domain>` on the router, the WireGuard endpoint.
   Caddy needs the Cloudflare part on the first boot to get certificates.
3. **Build** on a desktop, to find any error in the config now and not in the installer, and
   push the repo (the installer clones it from GitHub). The installer does not reuse this
   build: it downloads from cache.nixos.org and builds the few custom parts itself (Caddy
   with its plugin, scripts), a few minutes.
   ```sh
   nix build .#nixosConfigurations.homebox.config.system.build.toplevel .#homebox-restore
   git push
   ```
4. **USB sticks**: the NixOS 26.05 ISO on one (`dd if=nixos-*.iso of=/dev/sdX bs=4M`), the
   other empty (ext4) for a second copy of the migration set.
5. Optional: lower DNS TTLs, tell the people who use Jellyfin.

## B. On the day, on Ubuntu

```sh
# 1. Stop every app. `down` removes containers and networks, not the named volumes.
for p in esmi_dk immich jellyfin joplin media_control music_control vaultwarden; do
  (cd ~/$p && podman-compose down)
done
podman ps -a                                   # must be empty
sudo systemctl stop caddy

# 2. The migration set: volumes (with numeric owners), the SSH host key, and the old
#    config for reference.
M=/storage/backup/migration
sudo install -d -m 700 $M $M/etc
sudo rsync -aHAX --numeric-ids ~/.local/share/containers/storage/volumes/ $M/volumes/
sudo cp -a /etc/ssh/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key.pub $M/
sudo cp -a /etc/caddy /etc/wireguard $M/etc/
sudo rsync -a ~/esmi_dk ~/immich ~/jellyfin ~/joplin ~/media_control ~/music_control \
  ~/vaultwarden ~/scripts ~/caddy $M/old-home/
sudo du -sh $M/volumes                         # ~12 GB plus the databases

# 3. A second copy on the USB stick (tar keeps the numeric owners on any filesystem)
sudo mount /dev/sdX1 /mnt
sudo tar --numeric-owner --acls --xattrs -cpf /mnt/homebox-migration.tar -C /storage/backup migration
sudo umount /mnt

# 4. The way back for the data pool: everything after this only changes storage on top of
#    this snapshot (the restore tool refuses to run without it).
sudo zfs snapshot -r storage@pre-migration

# 5. Hand the pool over cleanly (NixOS has the same host ID, the installer does not), then off.
cd / && sudo zpool export storage
sudo poweroff
```

## C. From the installer

Boot the NixOS ISO (UEFI). Ethernet is enough for network.

```sh
sudo -i
nix-shell -p git zstd
git clone https://github.com/sweepline/nixos-config /tmp/nixos-config && cd /tmp/nixos-config
export NIX_CONFIG="experimental-features = nix-command flakes"
D=/dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S6PYNM0T410222R
ls -l /dev/disk/by-id/ | grep -v part          # $D must be the 500 GB SSD

# 1. Image the Ubuntu SSD while it is not mounted (the way back for the OS and the old
#    volumes). The pool goes to a temporary place, because /mnt is about to be replaced.
zpool import -R /tmp/storage storage           # no -f: it was exported on Ubuntu
dd if=$D bs=16M status=progress | zstd -T0 -3 -o /tmp/storage/storage/backup/ubuntu-sda.img.zst
zpool export storage

# 2. The new SSD pool (wipes $D only; storage is not part of the disko config)
nix run github:nix-community/disko/latest -- --mode destroy,format,mount --flake .#homebox

# 3. The data pool under /mnt, then the restore: first see what it does, then do it.
zpool import -R /mnt storage
nix run .#homebox-restore -- --dry-run /mnt/storage/backup/migration
nix run .#homebox-restore -- /mnt/storage/backup/migration
# Errors are listed at the end; fix them and run it again (the copies resume).

# 4. Hardware config (replaces the hand-written one; compare, then keep a copy to commit)
nixos-generate-config --no-filesystems --root /mnt --show-hardware-config \
  > hosts/homebox/hardware-configuration.nix
git diff hosts/homebox/hardware-configuration.nix
git add -A
cp hosts/homebox/hardware-configuration.nix /mnt/storage/backup/migration/

# 5. The old SSH host key: agenix decrypts the secrets with it on the first boot.
install -d -m 755 /mnt/etc/ssh
install -m 600 /mnt/storage/backup/migration/ssh_host_ed25519_key /mnt/etc/ssh/
install -m 644 /mnt/storage/backup/migration/ssh_host_ed25519_key.pub /mnt/etc/ssh/

# 6. Install
nixos-install --flake .#homebox --no-root-passwd
nixos-enter --root /mnt -c 'passwd mikkel'

# 7. Export both pools. The installer has another host ID than the installed system;
#    a pool it did not export would not be imported at boot (forceImportRoot is off).
zpool export storage
umount -R /mnt
zpool export ssd
reboot
```

## D. First boot: checks

SSH in over the LAN (`ssh mikkel@192.168.10.2`) or WireGuard (`192.168.3.2`).

1. System: `systemctl --failed` (empty), `zpool status` (both pools ONLINE),
   `systemctl status datasets` (no errors), `systemctl status wg-quick-wg0`.
2. Containers: `systemctl --user --failed` (empty), `podman ps` (all 19 running). The first
   start pulls every image and can take a while (about 15 minutes in the VM test). While the
   apps start, a few `... healthcheck run ...` units can show as failed for a moment; they
   clear themselves once the containers are `healthy`.
3. Caddy: `journalctl -u caddy | grep -i "certificate obtained"` (the two wildcards).
4. Every app opens on its new name (HOMEBOX.md, ports table), from the LAN and WireGuard.
5. App settings that pointed to `*.i.esmi.dk` (HOMEBOX.md has the table): download clients,
   Prowlarr apps, Bazarr, Jellyseerr, Aurral, and SABnzbd's `host_whitelist`.
6. Function checks:
   - Jellyfin: play something that needs transcoding; Dashboard → Playback shows the GPU in
     the transcode log.
   - Immich: open the app, make a share link and open it on `photos.<domain>` from outside.
   - Lidarr: a search that downloads through SABnzbd and slskd, and its import into the library.
   - slskd: incoming connections (its web UI shows the listen port as reachable).
   - git: `git clone mikkel@192.168.3.2:/storage/git/<repo>.git` after creating one; git.i.
   - From outside (phone on mobile data): `stream.`, `request.`, `photos.` work; an internal
     name sent to the public IP is dropped:
     `curl -sv --resolve sonarr.i.<domain>:443:<public IP> https://sonarr.i.<domain>/`
7. Backups: `sudo systemctl start sanoid` then `zfs list -t snapshot | grep autosnap`;
   `sudo systemctl start syncoid-appdata` then `zfs list -r storage/backup/appdata` (the unit fails if a copy is behind).
8. Alerts: `echo test | sudo sendmail m@esmi.dk` arrives; `systemctl status smartd zfs-zed`;
   `sudo smartctl -H /dev/sda` (and the HDDs).
9. Restore test (HOMEBOX.md, "Snapshots and backups"), the next day after the first copy.
10. Reboot once more and repeat 1–2.
11. On a desktop: commit `hardware-configuration.nix` (from `/storage/backup/migration/`) and
   push. From now on: `nh os switch -H homebox --target-host mikkel@192.168.3.2`.

Later, once everything has run for a couple of weeks:
- Delete the old music copies in storage/media (`music`, `unmapped_music`,
  `downloads/usenet/music/*` (keep the empty folder: SABnzbd mounts over it), `downloads/slsk`,
  `downloads/bandcamp`, `downloads/aurral`).
- Delete the migration set, the SSD image and `storage@pre-migration`
  (`zfs destroy -r storage@pre-migration`).
- The snapshot cleanup in HOMEBOX.md.

## E. Rollback

From the installer, if the new system cannot be made to work. The order matters: the SSD
image lives in storage/backup, so it is written back before anything there changes.

```sh
sudo -i
D=/dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S6PYNM0T410222R
zpool import -f -R /mnt storage
# 1. Ubuntu back on the SSD (overwrites the new ssd pool)
zstd -dc /mnt/storage/backup/ubuntu-sda.img.zst | dd of=$D bs=16M status=progress
# 2. The data as it was: media and immich back to the snapshot, the new datasets away
zfs rollback -r storage/media@pre-migration
zfs rollback -r storage/immich@pre-migration
zfs destroy -r storage/music
zfs destroy -r storage/git 2>/dev/null || true
chmod 755 /mnt/storage/backup
zpool export storage
reboot
```
Then on Ubuntu: start the compose projects and Caddy again.
