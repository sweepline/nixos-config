# homebox: migration to NixOS

Plan and decisions for moving the home server from Ubuntu + podman-compose to this flake.
Status at the bottom. See AGENTS.md for what may be run on the server.

**The new domain is a secret.** It is only stored in agenix (`DOMAIN=...`), never in Nix code,
docs or commit messages: the repo may be public, and the domain resolves to the home IP.
Below it is written as `<domain>`. Nothing may read a decrypted secret at evaluation time
(e.g. `builtins.readFile`), as that copies it into the Nix store.

## The server today (Ubuntu 26.04)

- Ryzen 5 5600GT (AMD iGPU, `/dev/dri/renderD128`, used by Jellyfin for VAAPI), 62 GB RAM,
  UEFI, NIC `enp4s0` (DHCP, LAN `192.168.10.2`), WireGuard `192.168.3.2` (client of the UniFi
  router, which is the WireGuard hub `192.168.3.1` and the DNS for `*.i.` names). ZFS hostid
  `61ba3ff7`. Dynamic public IP, kept in DNS by UniFi's DDNS (Cloudflare).
- `sda` Samsung 870 EVO 500 GB: Ubuntu (ext4 on LVM), rootless Podman storage and all named
  volumes (~11 GB app data + Postgres). **Wiped by the install.**
- Pool `storage`: raidz2 of 5x 10 TB + mirrored NVMe special vdev (`special_small_blocks=128K`,
  `recordsize=512K`). Datasets `backup`, `immich`, `joplin` (unused), `media`. Untouched by
  the install, only imported.
- System Caddy (Cloudflare DNS challenge), ufw, wg-quick `wg0`, zfs-auto-snapshot (cron),
  `~/scripts/backup.sh` (root cron: volume tar exports to `storage/backup/homebox`).
- All services under `esmi.dk` (also the email domain); `esmi.dk`, `www`, `jellyfin`,
  `jellyseerr` and `wireguard.esmi.dk` point to the home IP.

## Decisions

### OS and repo
- homebox is a host in this flake on **nixos-26.05** (`nixpkgs-stable`, `home-manager-stable`),
  without the desktop modules. Deployed from a desktop over WireGuard:
  `nh os switch -H homebox --target-host mikkel@192.168.3.2` (nh asks for the sudo password).
- The Ubuntu SSH host key is reused (`secrets/keys.nix`, `hosts.homebox`), so agenix secrets
  work on the first boot. The private key must be copied before the wipe.
- Server secrets are encrypted for the host key and all user keys (like every host). Undecided:
  a separate admin key (offline or YubiKey) instead of the desktop keys. Can be changed any
  time with `agenix -r`.

### Domains and DNS
- Everything moves from `esmi.dk` to a new `.net` on Cloudflare (registrar + DNS), internal
  names included. `esmi.dk` keeps only mail: its DNS moves to Fastmail, and the website moves
  to Fastmail's hosting (remove the A records that point home first).
- Public DNS (Cloudflare, DNS only): one inconspicuous name updated by UniFi DDNS,
  `*.<domain>` CNAME to it, and a TXT record on `i.<domain>` so the wildcard does not answer for
  the internal names. Internal `*.i.<domain>` records only on the router's DNS.
- Public names are generic: `stream.` (Jellyfin), `request.` (Jellyseerr), `photos.` (Immich
  public proxy), `vpn.` (WireGuard endpoint, DNS only). Internal names keep the product name
  (`sonarr.i.`, `navidrome.i.`, ...).
- Wildcard certificates for `*.<domain>` and `*.i.<domain>` (DNS challenge), so the CT logs
  only show the wildcards. The Cloudflare token is limited to the new zone.
- Things that contain the domain read it at runtime from agenix: Caddy (`{$DOMAIN}` in site
  addresses), Vaultwarden `DOMAIN`, Joplin `APP_BASE_URL`, Jellyfin `PublishedServerUrl`
  (container env files). Immich's external domain (`https://photos.<domain>`) is set in its UI.
- Afterwards: the WireGuard `Endpoint` in every client (the `wg0-*.age` files, phones), the
  app logins (Bitwarden, Jellyfin, Immich, Joplin) and bookmarks. Optional: ask the ISP for a
  new IP, since DNS history services already link `esmi.dk` to the current one.

### Network
- Server on its own VLAN (UniFi, done by the user): LAN/WireGuard → server allowed; server →
  LAN, other VLANs and WireGuard devices only replies; server → router only DNS and WireGuard
  (not the admin UI, also not over the tunnel); server → internet allowed. The server keeps
  its own `wg0`. IoT is already on its own VLAN; the TV is on the home LAN.
- Router forwards 443 and 50300 (slskd) only. Firewall: 80, 443/tcp, 443/udp; 22 only on the
  LAN interface and `wg0`; 50300 with slskd.

### Disks
- `sda` becomes ZFS pool `ssd` (disko, `hosts/homebox/disk-layout.nix`): `root`, `nix`, `home`,
  `appdata` (`/srv/appdata`, one child dataset per app), `cache` (`/srv/cache`, never backed
  up), `reserved` (20 GB refreservation).
- App data lives on the SSD, not on `storage`: every ZFS commit on `storage` makes the hard
  drives seek, which is audible every few seconds.
- New datasets on `storage`:
  - `storage/music` with `library/`, `unmapped/`, `downloads/` (from `media/music`,
    `media/unmapped_music`, music downloads). Library and downloads share one dataset so
    Lidarr's imports stay moves, not copies. (No separate downloads dataset for media: every
    *arr import would become a copy.)
  - `storage/git`: bare repos (below).

### Snapshots and backups
- sanoid (`hosts/homebox/zfs.nix`), every period set explicitly:
  `ssd/appdata` hourly 24 / daily 7; `storage/immich` hourly 24 / daily 31 / weekly 8 /
  monthly 12; `storage/music` daily 7 / weekly 4 / monthly 12; `storage/media` daily 7 /
  weekly 4; `storage/backup` weekly 4 / monthly 6; `storage/git` like immich (to add).
- syncoid nightly 03:30: `ssd/appdata` → `storage/backup/appdata` (unmounted copy, pruned by
  sanoid to daily 31 / weekly 8 / monthly 12).
- External drive (manual, from esa): replace the old script with a `homebox-backup` command
  in this repo: syncoid pull of `storage` with `--no-sync-snap`, excluding media, then sanoid
  pruning on the drive. Server side only needs `zfs allow mikkel send storage`.
- Later: restic to a Hetzner Storage Box (BX11, 1 TB): `immich`, `backup/appdata`,
  `music/library`, `git`, daily, from a snapshot; Storage Box snapshots on (protects against
  a compromised server).
- Retired: `backup.sh`, `joplin/backup-db.sh`, zfs-auto-snapshot, the manual
  `external-backup-*` snapshots.

### Caddy (`hosts/homebox/caddy.nix`)
- Caddy 2.11 + `caddy-dns/cloudflare` v0.2.4 (needed for `cfut_` tokens), token and domain
  from `secrets/caddy-homebox.age` (`CF_API_TOKEN=...`, `DOMAIN=...`).
- `*.i.<domain>` is internal only: `abort` unless `remote_ip private_ranges` (LAN, WireGuard,
  hairpin NAT, also the server VLAN). Apps register with
  `my.proxy."<name>" = { port; public; maintenance; }`.
- The maintenance page (`hosts/homebox/www/maintenance`) is shown on 502/503/504 for
  `stream.` and `request.` (and their internal names). The esmi.dk test page goes to Fastmail.

### Containers
- Rootless quadlets via quadlet-nix in Home Manager (`home-manager.users.mikkel`), lingering
  user, one module per app. Data in bind mounts `/srv/appdata/<app>`. A root service creates
  the datasets and sets owners and modes before the user manager starts (never deletes).
  Postgres data dirs get their own datasets with `recordsize=16K`.

#### Ownership and permissions
Two trust levels. Private apps run as mikkel, so their files are mikkel's and no
`podman unshare` is needed. The internet-facing ones run as their own user, so a container
breakout does not land as mikkel (who owns everything, Vaultwarden included).

Container UID/GID N ≥ 1001 is host 100000 + N − 1, with and without `keep-id`, so these
numbers mean the same everywhere. `keep-id` maps mikkel (1000) to 1000 and needs mikkel's
primary group to be `mikkel` (1000), not `users`. Tested with linuxserver/prowlarr.

| Apps | Container settings | Host owner |
|---|---|---|
| Sonarr, Radarr, Prowlarr, Bazarr, SABnzbd | `userns=keep-id`, `user=0:0`, `PUID=PGID=1000`, `UMASK=002` | mikkel |
| Lidarr, Aurral | same, plus `GroupAdd=2002` (music) | mikkel |
| Navidrome, rsgain | `userns=keep-id`, `user=1000:1000`, `GroupAdd=2002` | mikkel |
| Vaultwarden, Immich, Joplin server | unchanged (container root = mikkel) | mikkel |
| Postgres (Immich, Joplin) | unchanged | 100998 |
| **Jellyfin** | `user=3001:3001`, media read-only, `keep-groups` (render) | 103000 |
| **Jellyseerr** | `user=3002:3002` | 103001 |
| **Immich public proxy** | `user=3003:3003`, no files, only reaches Immich | – |
| **slskd** | `PUID=3004`, `PGID=2002` (music), `UMASK=002` | 103003 |

The public ones (bold) also get read-only mounts where possible, `NoNewPrivileges` and
dropped capabilities where the image allows, and only the network access they need.

| Path | Owner | Mode |
|---|---|---|
| `/storage/media` | `mikkel:media` (host GID 102000 = container 2001) | setgid dirs, group-writable, world-readable |
| `/storage/music` | `mikkel:music` (host GID 102001 = container 2002) | setgid dirs, group-writable, world-readable |
| `/storage/immich` | `mikkel:mikkel` | `750` on the top dir |
| `/storage/git` | `mikkel:mikkel` | `750` (cgit gets read access separately) |
| `/srv/appdata` | `mikkel:mikkel` | `750` (each app sees only its own mount) |

mikkel is a member of `media` and `music` on the host.

#### Images and apps
- Immich pinned to the version running before the migration (upgrade afterwards), Immich
  Postgres stays on its digest, Joplin on `postgres:17`, Lidarr on `nightly`, the rest
  `latest` with Podman auto-update.
- New: **immich-public-proxy** on `photos.<domain>` (only shared links are public; Immich
  itself stays internal). **cgit** on `git.i.<domain>`: lists every bare repo in
  `/storage/git`, served through Caddy via FastCGI; repos are used over SSH as mikkel
  (`mikkel@<server>:/storage/git/foo.git`), GitHub mirrors via a second push URL.
- Future: slskd behind gluetun + AirVPN (port forwarding), then the 50300 router forward and
  firewall rule go away.
- Dropped: droppedneedle, gluetun/Privado (`compose.vpn.yml`), `jellyfin_down`, the esmi.dk
  httpd, the `dn_*` and anonymous volumes. Caches (`jellyfin_cache`, `immich_model-cache`) are
  not migrated.
- Jellyfin GPU: device passed by its fixed path `/dev/dri/by-path/pci-…-render`, mapped to
  `/dev/dri/renderD128` in the container. AMD iGPU (VAAPI) first; an **Intel Arc A380**
  (i915) is added after the migration: read the new PCI addresses (they may shift), change the
  option, switch Jellyfin to QSV. BIOS: Above 4G Decoding + Resizable BAR. Host gets
  `intel-gpu-tools`.

| App | Host port | Container port | Name(s) |
|---|---|---|---|
| Vaultwarden | 8000 | 80 | vaultwarden.i |
| Jellyfin | 8096 | 8096 | jellyfin.i, stream. (public), maintenance |
| Immich | 2283 | 2283 | immich.i |
| Immich public proxy | (new) | 3000 | photos. (public) |
| Joplin | 22300 | 22300 | joplin.i |
| Jellyseerr | 8100 | 5055 | jellyseerr.i, request. (public), maintenance |
| Sonarr / Radarr / Prowlarr | 8101 / 8102 / 8103 | 8989 / 7878 / 9696 | sonarr.i / radarr.i / prowlarr.i |
| SABnzbd / Bazarr | 8104 / 8105 | 8080 / 6767 | sabnzbd.i / bazarr.i |
| slskd | 8201 (+ 50300 public) | 5030 (+ 50300) | slskd.i |
| Lidarr / Aurral / Navidrome | 8202 / 8203 / 8204 | 8686 / 3001 / 4533 | lidarr.i / aurral.i / navidrome.i |
| cgit | (new) | – | git.i |

Paths inside the containers stay as today (`/media`, `/media/music`, `/media/downloads/...`)
so the apps keep their settings; only host paths change. SABnzbd's music category moves to
`/storage/music/downloads/usenet`; Lidarr's download-client path mapping may need one update.

## Migration day (outline; the full runbook and restore script are still to be written)

Two USB sticks: the NixOS installer, and a second copy of the migration set.

1. Ubuntu: stop every compose project (volumes are kept). As root, rsync all volumes with
   `--numeric-ids` to `/storage/backup/migration/<volume>/`, plus the SSH host key, compose
   dirs and `/etc/caddy` for reference. Copy the set to the data USB stick.
2. Image `sda` to `/storage/backup/` (rollback: write it back and Ubuntu boots as before; too
   big for the USB sticks).
3. Installer: disko (wipes `sda` only), import `storage`, run the restore script:
   - create the app datasets and rsync into `/mnt/srv/appdata/<app>`, mapping owners per app
     to the table above (`--usermap/--groupmap`; databases unchanged)
   - create `storage/music` and `storage/git`, move the music folders
   - owners and modes: media `mikkel:media` + setgid + `g+w`, music `mikkel:music` likewise,
     `750` on immich, git and appdata
   Data is in place before any container starts (an app started with an empty config would
   create a fresh one).
4. Generate `hardware-configuration.nix`, put the host key in `/mnt/etc/ssh/`,
   `nixos-install --flake .#homebox`, reboot, check every app, reboot once more.
5. Rollback: write the image back and undo the ownership changes (media and music back to
   `101000`, not Immich); the restore script gets an `--undo`.

Cleanup on the server (the user runs it, any time): destroy `storage/joplin`, the never
pruned snapshots (`frequent` from July, the Sept hourly media run, `zfs-auto-snap-2026-01-27`)
and the `external-backup-*` snapshots. Later: the old `zfs-auto-snap_*` snapshots and
`storage/backup/homebox` (tar exports), once sanoid has history.

## Status

Done (committed): common/desktop module split; `hosts/homebox` (disko, ZFS, sanoid/syncoid,
users, Home Manager + quadlet-nix); `wg0-homebox.age` (IPv6 DNS typo fixed); Caddy (still with
esmi.dk names).

Next in the repo:
1. Caddy: `{$DOMAIN}` from agenix, public wildcard, generic public names; drop the esmi.dk
   site.
2. Container framework: dataset/permission service, `media`/`music` groups, a quadlet helper
   for both trust levels, proxy entries. Vaultwarden first, then the other apps,
   immich-public-proxy, cgit and `storage/git`.
3. Migration runbook + restore script (with `--undo`), VM test of the host.
4. After the migration: Arc A380, `homebox-backup` on esa, restic to Hetzner, snapshot
   cleanup, AirVPN for slskd.

Outside the repo (user): see the homebox section in TODO.md.
