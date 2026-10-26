# Installing a machine

This guide installs one of the hosts (`dongmyo`, `97`, `esa`) from the NixOS ISO.
Commands use `<host>` for the host name. For 97, every step marked **(97)** is extra.

Rough order: back up → prepare Windows (97) → install with disko → first boot →
Secure Boot → TPM + PIN → secrets/WireGuard → restore the rest.

> The repo must be pushed to GitHub before you start (`github.com/sweepline/nixos-config`),
> so the installer can clone it. It is fine for it to be public: secrets are only stored
> encrypted (`secrets/*.age`).

---

## 1. Before you wipe anything

### 1.1 Back up

From the machine that is about to be reinstalled:

```sh
cd ~/nixos-config
backup/backup.sh <host>          # e.g. backup/backup.sh 97
```

The script:

1. Warns about repos in `~/repos` that have uncommitted or unpushed work, or no remote.
   **These are not in the backup.** Push them or say no and fix them first.
2. Backs up the paths in `backup/<host>.txt` (for 97: Pictures, Videos, `~/.ssh`,
   TrackMania United Forever and Black Mesa saves).
3. Backs up the SSH **host key** `/etc/ssh/ssh_host_ed25519_key`, or generates a new one if
   the machine has none (97 had none). The new install reuses it, so agenix secrets made
   for it work on the very first boot. **Write down the public host key it prints.**
4. Encrypts everything with a passphrase (gpg, AES256), uploads it to
   `x.i.esmi.dk:/storage/backup/` and checks the checksum on the server.

On a machine already running this config, gpg, zstd and rsync are installed. On other
NixOS machines run it inside `nix-shell -p gnupg zstd rsync`.

**Also copy the `.gpg` archive to a USB stick.** During the install there is no SSH key on
the machine yet (it is inside the archive), so it is easiest to restore from USB.

**Also copy the host's WireGuard config to `<usb>/<host>/wg0.conf.gpg`**
(`sudo wg-quick show wg0 > /tmp/wg0.conf && gpg -c /tmp/wg0.conf`, or copy the existing
`/etc/wireguard/wg0.conf`): `/etc/wireguard` is deliberately **not** in the backup path
lists, so a `wg0.conf` that is not on the USB is lost with the old install (esa's was, in
October 2026, and required a new keypair plus a hub `[Peer]` swap).

Things that are not files:

- **Signal:** chats are encrypted with a key from the old keyring and cannot be copied.
  Link the new install as a new device from your phone and use Signal's transfer option.
- **Firefox:** make sure Firefox Sync or Bitwarden has your passwords and bookmarks.
  Export uBlock Origin settings (uBlock dashboard → Settings → Back up to file).
- **Tailscale (97):** remove the old `97` and `97-1` devices in the
  [Tailscale admin console](https://login.tailscale.com/admin/machines), so the new install
  gets the name `97`.

### 1.2 Windows (97)

Do this in Windows before touching Secure Boot:

1. **Save the BitLocker recovery key.** `manage-bde -protectors -get C:` in an admin terminal,
   or from https://account.microsoft.com/devices/recoverykey. Store it in Bitwarden.
2. **Make Windows use UTC for the hardware clock** (otherwise the clock is off by an hour
   after switching OS). Admin terminal:
   ```
   reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /d 1 /t REG_DWORD /f
   ```
3. **Suspend BitLocker** for the next few reboots, because enrolling new Secure Boot keys
   changes what the TPM measures:
   ```
   manage-bde -protectors -disable C: -rebootcount 3
   ```
   If you still get a BitLocker recovery screen later, type the recovery key. It happens once.

### 1.3 Firmware

- Turn **Secure Boot off** (the NixOS ISO is not signed). It is turned on again in section 5.
- **Clear the Secure Boot keys / enter Setup Mode** (the wording differs per vendor, often
  "Reset to Setup Mode", "Delete all Secure Boot keys" or "Clear Secure Boot keys").
  `nixos-install` then creates our own keys and enrolls them automatically, together with
  Microsoft's (Windows, GPU firmware).
- Make sure the **TPM** is enabled (AMD: "fTPM", Intel: "PTT").

---

## 2. Install from the ISO

Boot a recent **NixOS** ISO (graphical or minimal) from USB. The 26.05 release ISO is fine: the
system itself is built from this flake, which tracks nixos-unstable.

### 2.1 Network and repo

```sh
sudo -i
nmtui                                   # connect to Wi-Fi on the ISO (not needed on ethernet)
nix-shell -p git gnupg zstd
git clone https://github.com/sweepline/nixos-config /tmp/nixos-config
cd /tmp/nixos-config
```

### 2.2 Check the disk

The disk is chosen by its **by-id** name (model + serial). Unlike `/dev/nvme0n1` it never
changes between boots, so the right disk is always wiped.

```sh
lsblk -o NAME,SIZE,MODEL,SERIAL
ls -l /dev/disk/by-id/ | grep -v part
```

Compare with `device = ...` in `hosts/<host>/default.nix`:

- **(97)** it must be `nvme-WDC_WDS100T2B0C-00PXH0_20427P452912` (WD 1 TB, the old CachyOS
  disk). The **Force MP510** (447 GB) is the **Windows disk: never use it.**
- dongmyo / esa: replace `CHANGE-ME` with the by-id name of the disk.
- Swap is zram plus, on dongmyo (hibernate) and 97, a swapfile set with `swapDevices` in
  `hosts/<host>/default.nix`. For hibernate it must be at least the size of RAM (`free -g`).

### 2.3 Partition, encrypt and mount (disko)

**This erases the disk.** It asks for the LUKS passphrase twice. Choose a long one and
store it in Bitwarden: it is the fallback when the TPM/PIN does not work.

```sh
nix --experimental-features "nix-command flakes" \
  run github:nix-community/disko/latest -- --mode destroy,format,mount --flake .#<host>
```

Result: `/mnt/boot` (EFI, 2 GB) and `/mnt` (ext4 inside LUKS2). The swapfile is created on
the first boot.

### 2.4 Hardware config

```sh
nixos-generate-config --no-filesystems --root /mnt --show-hardware-config \
  > hosts/<host>/hardware-configuration.nix
git add -A
```

### 2.5 Restore keys and files from the backup

Plug in the USB stick with the archive and mount it (`lsblk`, then e.g.
`mount /dev/sdb1 /media`):

```sh
backup/restore.sh /media/<host>backup.tar.zst.gpg /mnt
```

This puts the SSH host key in `/mnt/etc/ssh/`, `~/.ssh` (your user key), Pictures and
Videos in `/mnt/home/mikkel/`. Everything else (game saves) stays in
`/mnt/home/mikkel/restore-<host>/` for later.

A brand-new machine without a backup skips this step.

### 2.6 Install

```sh
nixos-install --flake .#<host> --no-root-passwd
nixos-enter --root /mnt -c 'passwd mikkel'     # your login password
mkdir -p /mnt/home/mikkel
cp -a /tmp/nixos-config /mnt/home/mikkel/nixos-config
chown -R 1000:100 /mnt/home/mikkel
reboot
```

The login password also unlocks the keyring (and with it your SSH key passphrase), so pick
a good one.

---

## 3. First boot

1. Limine shows **NixOS** (and **Windows** on 97). Pick NixOS.
2. Type the **LUKS passphrase**.
3. Log in at ly. Hyprland starts.
4. On Wi-Fi (the installed system uses iwd, not NetworkManager): open kitty (`Mod+Enter`)
   and run `impala`, or click the network icon in the bar. Without a UI:
   `iwctl station wlan0 connect "<SSID>"`.
5. **SSH key.** With a backup it was restored in 2.5. On a new machine, create one:
   ```sh
   ssh-keygen -t ed25519 -C mikkel@<host>          # choose a passphrase
   cat ~/.ssh/id_ed25519.pub
   ```
   Add it to GitHub (Settings → SSH keys) and to the home server (`ssh-copy-id x.i.esmi.dk`
   if it accepts passwords, otherwise add it to `~/.ssh/authorized_keys` there from another
   machine).
6. Commit the hardware config:
   ```sh
   cd ~/nixos-config
   git remote set-url origin git@github.com:sweepline/nixos-config.git
   git add -A && git commit -m "<host>: hardware config" && git push
   ```
   The first push asks for your SSH key passphrase. Tick **"Automatically unlock this key
   whenever I'm logged in"** and it is never asked again.

---

## 4. Secrets and WireGuard (agenix)

agenix encrypts a file for a list of SSH public keys (`secrets/keys.nix`, assigned in `secrets/agenix-rules.nix`):

- the **host key** of the machine, so it can decrypt the file at boot
  (to `/run/agenix/wg0`, readable only by root, never in git or the Nix store), and
- your **user keys**, so you can edit the secrets from your machines.

Each host has its own WireGuard config: `secrets/wg0-<host>.age`.

1. Get the host's public key (for 97 it was printed by `backup.sh` and is already in
   `keys.nix`):
   ```sh
   cat /etc/ssh/ssh_host_ed25519_key.pub
   ```
   and your user key on this machine: `cat ~/.ssh/id_ed25519.pub`.
2. Add them in `secrets/keys.nix` (`hosts."<host>"` and `users.mikkel-<host>`). User keys
   there can also log in as mikkel over SSH on every host.
3. Re-encrypt the existing secrets for the new key list:
   ```sh
   cd ~/nixos-config/secrets
   agenix -r
   ```
   This must run on a machine whose key can **already** decrypt them. A brand-new machine
   cannot: push the `keys.nix` change, run `agenix -r` on one of the other machines,
   push, and `git pull` here. If there are no `.age` files yet, skip this step.
4. Create the WireGuard secret. This opens `$EDITOR`; paste the contents of the host's
   `wg0.conf` and save:
   ```sh
   agenix -e wg0-<host>.age
   ```
   From an encrypted copy on a USB stick instead:
   ```sh
   gpg -d /run/media/mikkel/<usb>/<host>/wg0.conf.gpg > /tmp/wg0.conf
   cat /tmp/wg0.conf | agenix -e wg0-<host>.age
   shred -u /tmp/wg0.conf
   ```
   Always verify the encrypted contents before rebuilding: a secret can encrypt
   *successfully* with empty input, and wg-quick then brings up a silent, empty `wg0`
   instead of failing.
   ```sh
   agenix -d wg0-<host>.age | diff - /tmp/wg0.conf   # must print nothing
   ```
   Never feed the file via `EDITOR="cp /tmp/wg0.conf" agenix -e ...` from a script:
   when stdin is not a terminal, agenix >= 0.15 ignores `$EDITOR` entirely (piped
   stdin is its documented non-interactive interface) and encrypts the empty stdin,
   exiting 0. This bit us on esa's reinstall in October 2026; the recipient list of the
   resulting file looked perfectly valid, only the diff above caught it.

   If the host's `wg0.conf` is lost (its private key exists nowhere else): generate a
   new keypair (`wg genkey`), rebuild the config around it (addresses, DNS and the hub
   `[Peer]` are unchanged), and replace that host's `[Peer]` entry in the hub config on
   wireguard.esmi.dk with the new public key — the hub is the only peer.
5. Add, rebuild, check:
   ```sh
   cd .. && git add -A
   nh os switch
   sudo wg show            # wg0 should have a recent handshake
   ```
6. Commit and push. Never commit a plain `wg0.conf` (`.gitignore` blocks `*.conf`).

The secret only becomes part of the system once `secrets/wg0-<host>.age` exists, so
installing without it works; WireGuard just stays off until this step.

For 97 the host key is known before the install (from the backup), so `wg0-97.age` can be
created on another NixOS machine (dongmyo) beforehand, and WireGuard works on the very
first boot.

---

## 5. Secure Boot

The keys were created and enrolled by `nixos-install`, and Limine is signed. Check:

```sh
sudo sbctl status
sudo sbctl verify       # the Limine .efi must be signed; kernels show "not signed", that is fine
```

- `Setup Mode: ✓ Disabled` and `Vendor Keys: microsoft` means the keys are
  enrolled. Reboot into the firmware, turn **Secure Boot on**, save and boot NixOS.
- `Setup Mode: ✗ Enabled` means enrolling did not happen (e.g. the firmware was not in Setup
  Mode during install, or `nixos-install` printed "file is immutable" / "chattr -i files in
  efivarfs"). Enroll now, then turn Secure Boot on in the firmware:
  ```sh
  sudo chattr -i /sys/firmware/efi/efivars/{PK,KEK,db}-* 2>/dev/null
  sudo sbctl enroll-keys --microsoft
  ```
  If it complains that the firmware is not in Setup Mode, clear the keys in the firmware
  first (step 1.3), boot NixOS and run it again.

Afterwards `sbctl status` should say `Secure Boot: ✓ Enabled`.

Kernels are not signed on purpose: the firmware checks Limine's signature, and Limine
checks every kernel and initrd against checksums in its config, whose own checksum is built
into the signed Limine file.

**(97)** Boot Windows once from the Limine menu to check it still works.

The keys live in `/var/lib/sbctl` and every rebuild signs Limine with them. They are not in
git; if a machine is reinstalled it gets new keys (clear the old ones in the firmware first).

---

## 6. TPM2 + PIN unlock

Only do this **after** Secure Boot is on: the TPM is bound to the Secure Boot state
(PCR 7), so turning Secure Boot on later would break the TPM unlock.

```sh
# Unlock with TPM + a PIN at boot (short is fine, the TPM limits guessing)
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 --tpm2-with-pin=yes /dev/disk/by-partlabel/disk-main-luks

# A recovery key, as a second fallback next to the passphrase. Store it in Bitwarden.
# Not needed if storing passphrase in Bitwarden
sudo systemd-cryptenroll --recovery-key /dev/disk/by-partlabel/disk-main-luks
```

Reboot: it now asks for the **PIN** instead of the passphrase. If the TPM refuses (firmware
update, Secure Boot keys changed, BIOS reset), it falls back to the passphrase. Re-enroll
with:

```sh
sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7 --tpm2-with-pin=yes /dev/disk/by-partlabel/disk-main-luks
```

What it protects: the disk cannot be read in another machine, and nobody can boot the
machine without the PIN. Once the machine is running and unlocked, the lock screen
(hyprlock) is what protects it; that is also true while it is asleep. Hibernation
writes memory into the swapfile inside LUKS, so a hibernated laptop is as safe as a powered-off one.

---

## 7. Tailscale (hosts with `my.work.enable`)

```sh
sudo tailscale up
```

Open the printed URL and log in. Check the name with `tailscale status`.

---

## 8. Restore the rest

### Game saves (97)

Steam creates a game's Proton prefix on the first start, so restore after that:

1. Install **TrackMania United Forever** and **Black Mesa** in Steam, start each once and quit.
2. Copy the saves back (they are in `~/restore-97/home/mikkel/...`):
   ```sh
   R=~/restore-97/home/mikkel/.local/share/Steam/steamapps
   S=~/.local/share/Steam/steamapps
   cp -a "$R/compatdata/7200/pfx/drive_c/users/steamuser/Documents/TrackMania/." \
         "$S/compatdata/7200/pfx/drive_c/users/steamuser/Documents/TrackMania/"
   cp -a "$R/common/Black Mesa/bms/save/." "$S/common/Black Mesa/bms/save/"
   ```
3. Start the games and check. Then delete `~/restore-97`.

### Firefox

Log in to Firefox Sync and Bitwarden, import the uBlock backup.

### Hyprland on new hardware

Monitor and keyboard names in `hosts/<host>/home.nix` were translated from the sway config
and should be checked once:

```sh
hyprctl monitors all     # "description:" is what desc:... matches
hyprctl devices          # keyboard names for hl.device
```
