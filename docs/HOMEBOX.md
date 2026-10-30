# homebox: migration to NixOS

Plan and decisions for moving the home server from Ubuntu + podman-compose to this flake.
Status at the bottom. The server is reached as `x.i.esmi.dk` (LAN `192.168.10.2`, WireGuard
`192.168.3.2`); see AGENTS.md for what may be run on it.

## The server today (Ubuntu 26.04)

- Ryzen 5 5600GT (AMD iGPU, `/dev/dri/renderD128`, used by Jellyfin for VAAPI), 62 GB RAM,
  UEFI, NIC `enp4s0` (DHCP), ZFS hostid `61ba3ff7`.
- `sda` Samsung 870 EVO 500 GB: Ubuntu (ext4 on LVM), rootless Podman storage and all named
  volumes (~11 GB app data + Postgres). **Wiped by the install.**
- Pool `storage`: raidz2 of 5x 10 TB + mirrored NVMe special vdev (`special_small_blocks=128K`,
  `recordsize=512K`). Datasets `backup`, `immich`, `joplin` (unused), `media`. Untouched by
  the install, only imported.
- System Caddy (Cloudflare DNS challenge), ufw, wg-quick `wg0`, zfs-auto-snapshot (cron),
  `~/scripts/backup.sh` (root cron: volume tar exports to `storage/backup/homebox`).
- Containers (podman-compose, rootless, user `mikkel`): see the ports table below.

## Decisions

### OS and repo
- homebox is a host in this flake on **nixos-26.05** (`nixpkgs-stable`, `home-manager-stable`),
  without the desktop modules. Deployed from a desktop:
  `nh os switch -H homebox --target-host mikkel@x.i.esmi.dk` (nh asks for the sudo password).
- The Ubuntu SSH host key is reused (`secrets/keys.nix`, `hosts.homebox`), so agenix secrets
  work on the first boot. The private key must be copied before the wipe.

### Disks
- `sda` becomes ZFS pool `ssd` (disko, `hosts/homebox/disk-layout.nix`): `root`, `nix`, `home`,
  `appdata` (`/srv/appdata`, one child dataset per app), `cache` (`/srv/cache`, never backed
  up), `reserved` (20 GB refreservation).
- App data lives on the SSD, not on `storage`: every ZFS commit on `storage` makes the hard
  drives seek, which is audible every few seconds.
- New dataset `storage/music` with `library/`, `unmapped/`, `downloads/` (from
  `media/music`, `media/unmapped_music`, music downloads). Library and downloads share one
  dataset so Lidarr's imports stay moves, not copies. No separate downloads dataset for media
  (would make every *arr import a copy).

### Snapshots and backups
- sanoid (`hosts/homebox/zfs.nix`), every period set explicitly:
  `ssd/appdata` hourly 24 / daily 7; `storage/immich` hourly 24 / daily 31 / weekly 8 /
  monthly 12; `storage/music` daily 7 / weekly 4 / monthly 12; `storage/media` daily 7 /
  weekly 4; `storage/backup` weekly 4 / monthly 6.
- syncoid nightly 03:30: `ssd/appdata` → `storage/backup/appdata` (unmounted copy, pruned by
  sanoid to daily 31 / weekly 8 / monthly 12).
- External drive (manual, from esa): replace the old script with a `homebox-backup` command
  in this repo: syncoid pull of `storage` with `--no-sync-snap`, excluding media, then sanoid
  pruning on the drive. Server side only needs `zfs allow mikkel send storage`.
- Later: restic to a Hetzner Storage Box (BX11, 1 TB): `immich`, `backup/appdata`,
  `music/library`, daily, from a snapshot; Storage Box snapshots on (protects against a
  compromised server).
- Retired: `backup.sh`, `joplin/backup-db.sh` (Fastmail upload, unused), zfs-auto-snapshot,
  the manual `external-backup-*` snapshots.

### Network and Caddy (`hosts/homebox/caddy.nix`)
- Router forwards 443 and 50300 (slskd) only. Firewall: 80, 443/tcp, 443/udp; 22 only on
  `enp4s0` and `wg0`; 50300 with slskd.
- Caddy 2.11 + `caddy-dns/cloudflare` v0.2.4 (needed for `cfut_` tokens), token from
  `secrets/caddy-homebox.age` (`CF_API_TOKEN=...`).
- `*.i.esmi.dk` (one wildcard cert) is internal only: `abort` unless `remote_ip private_ranges`.
  Apps register with `my.proxy."<name>" = { port; public; maintenance; }`.
- `esmi.dk` and the maintenance page are static files in `hosts/homebox/www/` (replaces the
  two httpd containers). The maintenance page is shown automatically on 502/503/504 for
  Jellyfin and Jellyseerr. `homebox.local.esmi.dk` is dropped.

### Containers
- Rootless quadlets via quadlet-nix in Home Manager (`home-manager.users.mikkel`), lingering
  user, one module per app. Data in bind mounts `/srv/appdata/<app>` (datasets created by a
  root service before the user manager starts; it never deletes). Postgres data dirs get their
  own datasets with `recordsize=16K`.
- **Ownership: everything on the host is `mikkel:mikkel` (1000:1000)**, no more
  `podman unshare`. Requires mikkel's primary group to be `mikkel` (1000), not `users`
  (keep-id maps the primary group). Tested with linuxserver/prowlarr:

  | Apps | Settings |
  |---|---|
  | Sonarr, Radarr, Prowlarr, Bazarr, SABnzbd, Lidarr, slskd, Aurral | `userns=keep-id`, `user=0:0`, `PUID=PGID=1000` |
  | Jellyfin, Navidrome, rsgain | `userns=keep-id`, `user=1000:1000` |
  | Jellyseerr | `userns=keep-id` (image runs as 1000) |
  | Vaultwarden, Immich, Joplin server | unchanged (container root = mikkel) |
  | Postgres (Immich, Joplin) | unchanged (files stay 100998) |

- Images: Immich pinned to the version running before the migration (upgrade afterwards),
  Immich Postgres stays on its digest, Joplin on `postgres:17`, Lidarr on `nightly`, the rest
  `latest` with Podman auto-update.
- Dropped: droppedneedle (`compose.dn.yml`), gluetun (`compose.vpn.yml`), `jellyfin_down`,
  `esmi_dk` httpd, the `dn_*` and anonymous volumes. Caches (`jellyfin_cache`,
  `immich_model-cache`) are not migrated.
- Jellyfin GPU: device passed by its fixed path `/dev/dri/by-path/pci-…-render`, mapped to
  `/dev/dri/renderD128` in the container, `keep-groups` (mikkel is in `render`). AMD iGPU
  (VAAPI) first; an **Intel Arc A380** (i915) is added after the migration: read the new PCI
  addresses, change the option, switch Jellyfin to QSV. BIOS: Above 4G Decoding + Resizable
  BAR. Host gets `intel-gpu-tools`.

| App | Host port | Container port | Name(s) |
|---|---|---|---|
| Vaultwarden | 8000 | 80 | vaultwarden.i |
| Jellyfin | 8096 | 8096 | jellyfin.i, jellyfin.esmi.dk (public), maintenance |
| Immich | 2283 | 2283 | immich.i |
| Joplin | 22300 | 22300 | joplin.i |
| Jellyseerr | 8100 | 5055 | jellyseerr.i, jellyseerr.esmi.dk (public), maintenance |
| Sonarr / Radarr / Prowlarr | 8101 / 8102 / 8103 | 8989 / 7878 / 9696 | sonarr.i / radarr.i / prowlarr.i |
| SABnzbd / Bazarr | 8104 / 8105 | 8080 / 6767 | sabnzbd.i / bazarr.i |
| slskd | 8201 (+ 50300 public) | 5030 (+ 50300) | slskd.i |
| Lidarr / Aurral / Navidrome | 8202 / 8203 / 8204 | 8686 / 3001 / 4533 | lidarr.i / aurral.i / navidrome.i |

(`.i` = `.i.esmi.dk`.) Paths inside the containers stay as today (`/media`, `/media/music`,
`/media/downloads/...`) so the apps keep their settings; only host paths change. SABnzbd's
music category moves to `/storage/music/downloads/usenet`; Lidarr's download-client path
mapping may need one update.

## Migration day (outline; the full runbook and restore script are still to be written)

Two USB sticks: the NixOS installer, and a second copy of the migration set.

1. Ubuntu: stop every compose project (volumes are kept). As root, rsync all volumes with
   `--numeric-ids` to `/storage/backup/migration/<volume>/`, plus the SSH host key, compose
   dirs and `/etc/caddy` for reference. Copy the set to the data USB stick.
2. Image `sda` to `/storage/backup/` (rollback: write it back and Ubuntu boots as before; too
   big for the USB sticks).
3. Installer: disko (wipes `sda` only), import `storage`, restore script: create the app
   datasets, rsync into `/mnt/srv/appdata/<app>` mapping owners
   (`--usermap/--groupmap 101000:1000,100910:1000,100999:1000`, databases unchanged),
   `chown -R 1000:1000` media and music, create `storage/music` and move the music folders.
   Data is in place before any container starts (an app started with an empty config would
   create a fresh one).
4. Generate `hardware-configuration.nix`, put the host key in `/mnt/etc/ssh/`,
   `nixos-install --flake .#homebox`, reboot, check every app, reboot once more.
5. Rollback: write the image back and undo the chown (`1000 → 101000` on media and music,
   not Immich); the restore script gets an `--undo`.

Cleanup on the server (the user runs it, any time): destroy `storage/joplin`, the never
pruned snapshots (`frequent` from July, the Sept hourly media run, `zfs-auto-snap-2026-01-27`)
and the `external-backup-*` snapshots. Later: the old `zfs-auto-snap_*` snapshots and
`storage/backup/homebox` (tar exports), once sanoid has history.

## Status

Done (committed): common/desktop module split; `hosts/homebox` (disko, ZFS, sanoid/syncoid,
users, Home Manager + quadlet-nix); `wg0-homebox.age` (IPv6 DNS typo fixed); Caddy.

Next:
1. Container framework (dataset service, quadlet helper with the ownership settings, proxy
   entries), Vaultwarden first, then the other apps.
2. Migration runbook + restore script (with `--undo`), VM test of the host.
3. After the migration: Arc A380, `homebox-backup` on esa, restic to Hetzner, snapshot cleanup.

Open for the user: create `secrets/caddy-homebox.age`; revoke the Fastmail app password if it
still exists.
