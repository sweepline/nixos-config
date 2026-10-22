# Usage

## Rebuilding

The repo lives in `~/repos/nixos-config` on every machine. `nh` knows where it is.

```sh
nh os switch            # build and switch to the config for this host
nh os boot              # build, but only switch on next boot (kernel/driver changes)
nh os test              # switch now, but do not add a boot entry
```

`nh` shows a diff of what changed. The plain equivalent is
`sudo nixos-rebuild switch --flake ~/repos/nixos-config#<host>`.

> **Flakes only see files tracked by git.** A new file that is not `git add`-ed is invisible
> to the build and you get "file not found" errors. Run `git add -A` before rebuilding.
> Uncommitted changes are fine, untracked files are not.

Check the config without building anything (catches typos in all hosts):

```sh
nix flake check
```

## Updating

Nothing updates by itself. Versions are pinned in `flake.lock`, so all machines run the
same versions until you update.

Once a week a notification reminds you when the inputs are older than 7 days. Then:

```sh
cd ~/repos/nixos-config
nh os switch --update          # = nix flake update + rebuild, with a diff
```

Check that things work (reboot if the kernel changed), then commit and push `flake.lock`:

```sh
git commit -am "flake update" && git push
```

On the other machines, just pull and rebuild (no `--update`, so they get exactly the same
versions):

```sh
git pull && nh os switch
```

Update one input only: `nix flake update nixpkgs` (or `home-manager`, `stylix`, ...).

**97 and the NVIDIA driver:** the kernel is `linuxPackages_latest`. Very occasionally a new
kernel arrives before the NVIDIA driver supports it and the build fails. Nothing breaks, you
just stay on the current version. Wait a few days, or switch 97 to the default kernel (see
the comment in `hosts/97/default.nix`).

## Rolling back

Every rebuild is a **generation** and shows up in the Limine boot menu. If something breaks:

- **It boots:** `sudo nixos-rebuild switch --rollback` or pick the old generation at boot.
- **It does not boot:** pick an older generation in the Limine menu, then fix the config.

Old generations are cleaned up automatically (`nh clean`: keeps the last 10 and everything
from the last 14 days). Limine shows at most 10.

## Testing changes safely

Build a VM from the config and boot it, without touching the real system:

```sh
nixos-rebuild build-vm --flake .#dongmyo
./result/bin/run-dongmyo-vm
```

Disk encryption and the TPM are not used in the VM, but the desktop (ly, Hyprland, ashell,
Home Manager) is. Log in as `mikkel` / `changeme`. Hyprland in a VM can be slow or need
`WLR_RENDERER_ALLOW_SOFTWARE=1`.

Check that Hyprland accepts the config before logging in:

```sh
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
```

## Secrets (agenix)

Secrets are files encrypted with SSH keys, listed in `secrets/secrets.nix`. Run `agenix`
from the `secrets/` folder; it uses your `~/.ssh/id_ed25519` to decrypt.

```sh
cd ~/repos/nixos-config/secrets
agenix -e wg0-97.age       # edit (or create) a secret
agenix -r                  # re-encrypt all secrets after changing keys in secrets.nix
```

Adding a new machine or a new user key: add its public key in `secrets.nix`, then
`agenix -r`, commit and rebuild. See docs/INSTALL.md section 7.

On the machines the decrypted file is at `/run/agenix/wg0` (root only). WireGuard:
`sudo wg show`, `systemctl status wg-quick-wg0`.

## Network

- **Wi-Fi:** iwd. Use the network panel in ashell, `impala` (TUI), or
  `iwctl station wlan0 scan` / `get-networks` / `connect "<SSID>"`. Known networks are
  stored in `/var/lib/iwd/`.
- **Addresses:** systemd-networkd does DHCP on every wired and wireless interface.
  `networkctl` shows the state.
- **DNS:** systemd-resolved. `resolvectl status` shows which DNS servers are used per
  interface (Wi-Fi, Tailscale MagicDNS, WireGuard).

## Light / dark theme

The sun/moon button in ashell switches between dark (default) and light. Both themes are
built in advance as a Home Manager **specialisation**, so switching takes a second or two
and needs no rebuild. kitty, GTK apps and Firefox follow along. A rebuild always goes back
to dark.

## Keybinds (Hyprland)

Same as the old sway config. `Mod` is the Super/Windows key.

| Keys | Action |
|---|---|
| `Mod+Enter` | kitty |
| `Mod+d` / `Mod+c` | rofi launcher / calculator |
| `Mod+Shift+q` | close window |
| `Mod+h/j/k/l`, arrows | move focus |
| `Mod+Shift+h/j/k/l`, arrows | move window |
| `Mod+1..0` / `Mod+Shift+1..0` | go to / move window to workspace 1-10 |
| `Mod+m` | move workspace to the other monitor |
| `Mod+b` / `Mod+v` | next window opens to the right / below (sway splith/splitv) |
| `Mod+e` | toggle split direction |
| `Mod+w` | toggle tabbed group (sway's tabbed layout) |
| `Mod+s` | next tab in the group |
| `Mod+f` | fullscreen |
| `Mod+Shift+Space` | toggle floating |
| `Mod+Space` | jump between tiled and floating windows |
| `Mod+Shift+-` / `Mod+-` | to scratchpad / show scratchpad |
| `Mod+r` | resize mode (hjkl, Enter/Esc to leave) |
| `Mod+Shift+w` | lock (and pause media) |
| `Mod+Shift+c` | reload Hyprland config |
| `Mod+Shift+e` | exit Hyprland |
| `Mod+u` / `Mod+i` / `Mod+o` | mute / volume down / volume up |
| `Mod+y` | mute microphone |
| `Mod+p`, `Mod+]`, `Mod+[` | play/pause, next, previous |
| `Mod+Shift+s`, `Print` | screenshot of an area to the clipboard |
| `Mod+Shift+r` | start/stop recording an area (gpu-screen-recorder, saved to ~/Videos) |
| `Mod+Shift+b` | new random wallpapers |
| `Mod+n` / `Mod+Shift+n` | dismiss notification / bring back the last one |
| `Mod+Ctrl+n` | toggle Do Not Disturb |
| `Mod+mouse` | left: move, right: resize |

Not available in Hyprland: sway's stacking layout and `focus parent`.

## Wallpapers

Put images in `~/Pictures/Wallpapers` (not in git). At login every monitor gets a random
one matching its orientation: portrait images on rotated monitors, landscape on the rest.
If there are no portrait images, any image is used. `Mod+Shift+b` picks new ones.

## Notifications

mako keeps the last 50 dismissed notifications. `Mod+Shift+n` (or `makoctl restore`) brings
back the most recent one, `makoctl history` lists them. Do Not Disturb (`Mod+Ctrl+n`)
hides new notifications; they still go to the history, so you can restore them afterwards.

## Night light

hyprsunset makes the screen warmer (4000 K) from 21:00 to 07:00. Change the times in
`modules/home/hyprland.nix`. Turn it off for now with `systemctl --user stop hyprsunset`.

## Laptop (dongmyo)

- **Lid:** closing it suspends, and after 2 hours asleep it hibernates. With an external
  monitor connected, closing the lid only turns off the laptop screen.
- **Battery:** charging stops at 80% to save the battery (if the laptop supports it). Change
  `my.laptop.chargeLimit` in `hosts/dongmyo/default.nix`, or set it to `null` before a trip.
- **Fingerprint:** enroll a finger once with `fprintd-enroll`. It then works for `sudo` and
  the lock screen. Logging in at ly still uses the password, because the password also
  unlocks the keyring and your SSH key.

## Files, PDFs and archives

- yazi is the file manager. Archives open/extract with `ouch` (`ouch decompress file.zip`),
  7-zip (`7zz`) and `unrar` are also installed.
- PDFs open in zathura (vim keys: `j`/`k`, `/` to search, `d` for two pages).

## USB drives

Drives are mounted automatically when plugged in (udiskie), at `/run/media/mikkel/<label>`,
with a notification. Unmount/eject from the tray icon, or `udiskie-umount /run/media/mikkel/<label>`.
Encrypted (LUKS) drives ask for the passphrase.

## SSH agent

The SSH agent is part of the GNOME keyring (`gcr-ssh-agent`), which ly unlocks when you log
in. The first time a key is used you are asked for its passphrase; tick the box to remember
it and you are never asked again. `ssh-add -l` lists loaded keys.

## Backups

`backup/backup.sh <host>` backs up the paths in `backup/<host>.txt` to the home server.
See docs/INSTALL.md section 1.1.

## Windows (97)

Pick **Windows** in the Limine menu. To restart straight into Windows from Linux:

```sh
sudo efibootmgr                      # find "Windows Boot Manager", e.g. Boot0001
sudo efibootmgr --bootnext 0001 && reboot
```
