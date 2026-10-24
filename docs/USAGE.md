# Usage

## Rebuilding

The repo lives in `~/nixos-config` on every machine. `nh` knows where it is.

```sh
nh os switch            # build and switch to the config for this host
nh os boot              # build, but only switch on next boot (kernel/driver changes)
nh os test              # switch now, but do not add a boot entry
```

`nh` shows a diff of what changed. The plain equivalent is
`sudo nixos-rebuild switch --flake ~/nixos-config#<host>`.

> **Flakes only see files tracked by git.** A new file that is not `git add`-ed is invisible
> to the build and you get "file not found" errors. Run `git add -A` before rebuilding.
> Uncommitted changes are fine, untracked files are not.

Check the config without building anything (catches typos in all hosts):

```sh
nix flake check
```

## Updating

The system follows **nixos-unstable** (rolling, like Arch). Nothing updates by itself:
versions are pinned in `flake.lock`, so all machines run the same versions until you update.
nixos-unstable only moves to a new revision after its tests pass, so what you pull is
built and cached.

Once a week a notification reminds you when the inputs are older than 7 days. Then:

```sh
cd ~/nixos-config
nh os switch --update          # = nix flake update + rebuild, with a diff of what changes
```

Read the diff nh shows (new major versions, removed packages). Check that things work (reboot
if the kernel changed), then commit and push `flake.lock`:

```sh
git commit -am "flake update" && git push
```

On the other machines, just pull and rebuild (no `--update`, so they get exactly the same
versions):

```sh
git pull && nh os switch
```

Safer for big updates: `nh os boot --update` installs the new generation without switching,
and you pick it at the next boot (the old one stays in the Limine menu).

Update one input only: `nix flake update nixpkgs` (or `home-manager`, `stylix`, `opencode`, ...).

**Things that can go wrong on a rolling base, and what to do:**

- **A rebuild fails with an evaluation error** (an option was renamed or removed): the update
  stops before anything is switched. Read the message, fix the option, or go back with
  `git checkout flake.lock` and wait a few days. Renamed options print a warning first, so
  watch the output of every update.
- **A rebuild starts compiling lots of packages:** the channel moved but its binary cache is
  not complete yet. Cancel it and try again in a few hours.
- **A program broke after an update:** boot the previous generation from the Limine menu, or
  `sudo nixos-rebuild switch --rollback`, then `git checkout flake.lock` to stay on the old
  versions until it is fixed.
- **Hyprland config:** the build-time check (see "Testing changes safely") runs against the new
  Hyprland and fails the build if its Lua API changed.

**opencode** is not taken from nixpkgs (it has 2.0.x) but from upstream's flake, pinned to a
tag in `flake.nix`. For a newer one, change the tag there and run `nix flake update opencode`.
It is built from source on each machine.

**97 and the NVIDIA driver:** the kernel is `linuxPackages_latest`. Occasionally a new kernel
arrives before the NVIDIA driver supports it and the build fails. Nothing breaks, you just stay
on the current version. Wait a few days, or switch 97 to the default kernel (see the comment in
`hosts/97/default.nix`).

## Rolling back

Every rebuild is a **generation** and shows up in the Limine boot menu. If something breaks:

- **It boots:** `sudo nixos-rebuild switch --rollback` or pick the old generation at boot.
- **It does not boot:** pick an older generation in the Limine menu, then fix the config.

### Automatic cleanup of old generations

Old generations are removed so the disk does not fill up:

- A weekly timer (`nh-clean`) runs `nh clean all --keep 10 --keep-since 14d`. If the machine
  was off, it runs at the next boot.
- A generation is only deleted if it is **both** outside the newest 10 **and** older than
  14 days. Your last 10 builds and anything from the last two weeks are always kept.
- After that, packages no generation uses any more are garbage collected, which is where the
  disk space comes back.
- The Limine menu is a separate limit (`maxGenerations = 10`): it lists only the newest 10,
  even if older generations have not been cleaned yet.
- `auto-optimise-store` makes identical files in `/nix/store` share disk space. That runs on
  its own.

Settings: `modules/nixos/base.nix` (`programs.nh.clean`) and `modules/nixos/boot.nix`.

Clean by hand. A plain `nh clean all` does **not** use the timer's rules: its defaults are to
keep only the current generation, so it removes every rollback option. Pass the same limits
as the timer:

```sh
nh clean all --keep 10 --keep-since 14d    # what the timer does
nh clean all --keep 3 --keep-since 0h      # harder: frees more, fewer rollback options
nh clean all --dry                         # show what would be deleted, change nothing
```

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

`nh os switch`, `boot` and `test` already do this for you: the build includes a check that
runs `Hyprland --verify-config` on the generated config, so a broken config stops the rebuild
before anything is switched. It catches syntax errors, unknown functions and options at load
time, and API changes after a Hyprland update. It cannot catch code that only runs on a key
press, or device and monitor names that do not match the hardware. If the checker itself ever
blocks a rebuild, set `my.checkHyprland = false;` in the host's `default.nix`.

## Secrets (agenix)

Secrets are files encrypted with SSH keys. The keys are in `secrets/keys.nix`, and
`secrets/agenix-rules.nix` says which keys can decrypt which secret. Run `agenix`
from the `secrets/` folder; it uses your `~/.ssh/id_ed25519` to decrypt.

```sh
cd ~/nixos-config/secrets
agenix -e wg0-97.age       # edit (or create) a secret
agenix -r                  # re-encrypt all secrets after changing keys in keys.nix
```

Adding a new machine or a new user key: add its public key in `keys.nix`, then
`agenix -r`, commit and rebuild. See docs/INSTALL.md section 4.

On the machines the decrypted file is at `/run/agenix/wg0` (root only). WireGuard:
`sudo wg show`, `systemctl status wg-quick-wg0`.

### API tokens

Each host has its own tokens in `secrets/env-<host>.age`, as `KEY=value` lines. Make a
separate token per host at the provider, so a lost machine only means revoking its own.

```sh
cd ~/nixos-config/secrets
agenix -e env-97.age
```

```
CONTEXT7_API_KEY=...
DEEPSEEK_API_KEY=...
```

Rebuild, then open a new terminal: the file is decrypted to `/run/agenix/env` (readable only
by mikkel) and bash exports every line. Only programs started from a terminal see them, not
apps started from rofi or a keybind. opencode reads both keys from the environment.
A host without an `env-<host>.age` simply has no tokens.

## Network

- **Wi-Fi:** iwd. Use the network panel in ashell, `impala` (TUI), or
  `iwctl station wlan0 scan` / `get-networks` / `connect "<SSID>"`. Known networks are
  stored in `/var/lib/iwd/`.
- **Addresses:** systemd-networkd does DHCP on every wired and wireless interface.
  `networkctl` shows the state.
- **DNS:** systemd-resolved. `resolvectl status` shows which DNS servers are used per
  interface (Wi-Fi, Tailscale MagicDNS, WireGuard).
- **SSH between my machines:** port 22 is open on `wg0` (every host with a WireGuard secret)
  and, on work hosts, on `tailscale0`. It is closed on Wi-Fi and Ethernet.

## Work (`my.work.enable`)

Set per host in `hosts/<host>/default.nix` (all three for now). It adds, from
`modules/nixos/work.nix` and `modules/home/work.nix`:

- **Tailscale**, with only SSH (22) open on `tailscale0`. esa also opens
  5900 there for VNC (`vncstart`, used from the meeting room).
- **sadmin** with `/etc/sadmin.json` (`sadmin.scalgo.com:443`). When sadmin says it is out of
  date, run `pkgs/update-sadmin.sh` (sets the newest version and hash in `pkgs/sadmin.nix`),
  then `nh os switch`. sadmin cannot update itself, the Nix store is read-only.
- **Scalgo SSH hosts** (`ssh ts01` → `ts01.emu-buri.ts.net`, ...), the work git aliases
  (`pushmr`, `grepall`, `fixup`, `wiki`, ...), `localstack` and `findimage`.
- **Work git email:** commits use `mikkel@scalgo.com` in any repo with a remote on
  `git.i.scalgo.com` (SSH or HTTPS), wherever it is cloned; `m@esmi.dk` everywhere else.
  A new repo has no remote until `git remote add`, so check `git config user.email` before the
  first commit there.

Without it the VPN icon in ashell only looks at WireGuard.

## Light / dark theme

The sun/moon button in ashell switches between dark (default) and light. Both themes are
built in advance as a Home Manager **specialisation**, so switching takes a second or two
and needs no rebuild. kitty, GTK apps and Firefox follow along. A rebuild always goes back
to dark.

## Hyprland

The config is plain Lua: `modules/home/hyprland/hyprland.lua` (shared) and
`hosts/<host>/hyprland.lua` (monitors, keyboards, workspace rules), appended after it. It
follows https://wiki.hypr.land, so examples there can be pasted in. Colors come from stylix.

The layout is **scrolling**: windows sit in columns on an endless strip and the view scrolls
sideways. A new window opens as a new column on the right (half the screen wide by default);
a single column fills the screen. Fullscreen is layout-aware: you can scroll away from a
fullscreen window without leaving fullscreen.

`Mod` is the Super/Windows key (the key left of the space bar on keyboards where Alt and
Windows are swapped).

| Keys | Action |
|---|---|
| `Mod+Enter` | kitty |
| `Mod+d` / `Mod+c` | rofi launcher / calculator |
| `Mod+Shift+q` | close window |
| `Mod+h/l`, left/right | focus the column to the left / right (the view scrolls) |
| `Mod+j/k`, down/up | focus the window below / above in the column |
| `Mod+Shift+h/l`, left/right | move the window into the neighbouring column (a new column at the edge of the strip) |
| `Mod+Shift+j/k`, down/up | swap places with the window below / above in its column |
| `Mod+Ctrl+h/l`, left/right | move the whole column: swap places with the neighbouring column (wraps around at the ends) |
| `Mod+Ctrl+k`, up | take the focused window out of its column into a column of its own, right after it |
| `Mod+Ctrl+j`, down | the reverse: a window alone in its column joins the previous column (on a stacked window it pops out to the left instead) |
| `Mod+e` | cycle the column width: 1/3, 1/2, 2/3, full |
| `Mod+,` / `Mod+.` | scroll the view one column left / right |
| `Mod+a` | center the focused column |
| `Mod+r` | resize mode: h/l column width, j/k window height, Enter/Esc to leave |
| `Mod+f` | fullscreen |
| `Mod+Shift+Space` | toggle floating |
| `Mod+Space` | jump between tiled and floating windows |
| `Mod+1..0` / `Mod+Shift+1..0` | go to / move window to workspace 1-10 |
| `Mod+m` | move workspace to the other monitor |
| `Mod+Shift+-` / `Mod+-` | to scratchpad / show scratchpad |
| `Mod+Shift+w` | lock (and pause media) |
| `Mod+Shift+c` | reload Hyprland config |
| `Mod+Shift+e` | exit Hyprland (asks first, then `hyprshutdown`) |
| `Mod+u` / `Mod+i` / `Mod+o` | mute / volume down / volume up |
| `Mod+y` | mute microphone |
| `Mod+p`, `Mod+]`, `Mod+[` | play/pause, next, previous |
| `Mod+Shift+s`, `Print` | screenshot of an area to the clipboard |
| `Mod+Shift+p` | pick a color from the screen (copied to the clipboard) |
| `Mod+Shift+r` | start/stop recording an area (gpu-screen-recorder, saved to ~/Videos) |
| `Mod+Shift+b` | new random wallpapers |
| `Mod+n` / `Mod+Shift+n` | dismiss notification / bring back the last one |
| `Mod+Ctrl+n` | toggle Do Not Disturb |
| `Mod+Shift+v` | clipboard history (pick an entry to copy it again) |
| `Mod+Shift+x` | delete an entry from the clipboard history (pick it in the list) |
| `Mod+mouse` | left: move, right: resize |

Hyprland groups (tabs) are not bound to any key. Sway's stacking layout and `focus parent`
have no equivalent.

Layout settings (column width, scroll direction, ...) are documented at
https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout. Note that the wiki follows
Hyprland's main branch: the messages `fit_into_view` and `inhibit_scroll` it lists are newer
than older Hyprland versions. The build check cannot catch a typo in a layout
message such as `"swapcol l"`, because it is only handled when the key is pressed.

## Wallpapers

Put images in `~/Pictures/Wallpapers` (not in git). At login every monitor gets a random
one matching its orientation: portrait images on rotated monitors, landscape on the rest.
If there are no portrait images, any image is used. `Mod+Shift+b` picks new ones.

The wallpapers are drawn by hyprpaper (Hyprland's own wallpaper tool); the script
`wallpaper-random` chooses the images and sets them with `hyprctl hyprpaper wallpaper`.
There is no fade between wallpapers. `hyprctl hyprpaper listactive` shows what is set.

## Notifications

mako keeps the last 50 dismissed notifications. `Mod+Shift+n` (or `makoctl restore`) brings
back the most recent one, `makoctl history` lists them. Do Not Disturb (`Mod+Ctrl+n`)
hides new notifications; they still go to the history, so you can restore them afterwards.

## Night light

hyprsunset makes the screen warmer (4000 K) from 21:00 to 07:00. Change the times in
`modules/home/hyprland/default.nix`. Turn it off for now with `systemctl --user stop hyprsunset`.

## Laptop (dongmyo)

- **Lid:** closing it suspends (not suspend-then-hibernate: an aborted hibernate left amdgpu
  broken, see `modules/nixos/laptop.nix`). With an external monitor connected, closing the
  lid only turns off the laptop screen.
- **Power button:** hibernates. Waking from hibernate asks for the disk PIN, then shows the
  lock screen (fingerprint works there). Opening the lid of a hibernated laptop powers it on
  if the BIOS option "Flip to Start" (Config → Power) is on.
- **Battery:** charging stops at 80% to save the battery (if the laptop supports it). Change
  `my.laptop.chargeLimit` in `hosts/dongmyo/default.nix`, or set it to `null` before a trip.
- **Fingerprint:** enroll a finger once with `fprintd-enroll`. It then works for `sudo` and
  the lock screen. Logging in at ly still uses the password, because the password also
  unlocks the keyring and your SSH key.

## Files, PDFs and archives

- yazi is the file manager. Archives open/extract with `ouch` (`ouch decompress file.zip`),
  7-zip (`7zz`) and `unrar` are also installed.
- PDFs open in zathura (vim keys: `j`/`k`, `/` to search, `d` for two pages).
- Opening a folder from another app (e.g. "Show in folder" in Firefox) opens yazi in kitty.
- Clipboard history: `Mod+Shift+v`. `cliphist wipe` clears it.

## Gaming (97)

- **Proton-GE** is installed next to Valve's Proton. Pick it per game: Properties →
  Compatibility → "Force the use of a specific Steam Play compatibility tool".
- **MangoHud** (FPS, frame times, CPU/GPU load and temperatures): launch options
  `mangohud %command%`, toggle in game with `Right Shift+F12`. Combine with gamemode:
  `gamemoderun mangohud %command%`.
- **Discord** is Vesktop (Discord with Vencord). Screen sharing includes audio on Wayland.
- **GPU Screen Recorder overlay** (ShadowPlay-style, `gsr-ui`) runs in the background as a
  user service. `Mod+g` shows or hides it; from there you can record the screen, a region or a
  window, take screenshots, stream, and run a **replay buffer** (the last minutes of
  gameplay). `Mod+Shift+g` saves the replay buffer (start it from the overlay, or with
  `gsr-ui-cli start-replay`). `gsr-ui-cli --help` lists every command, so more binds can go in
  `modules/home/gaming.nix`. `Mod+Shift+r` (quick region recording) still works on its own.
  The overlay's own hotkeys (Left Alt+Z, ...) are deliberately not set up: they need the
  program to grab every keyboard and re-emit the keys through a virtual keyboard, which would
  bypass the per-keyboard options in `hosts/97/hyprland.lua` (Caps as Ctrl, Alt/Win swap).
  The overlay is X11-first with a Wayland overlay layer, so on Hyprland it may look off;
  see the TODO list. It is built against the system's
  recorder, so everything shares one version.
- **Xbox controllers** work wired, over Bluetooth, and with the wireless dongle (xone).
- **FiiO K11** (USB DAC) works out of the box. Select it as output in the ashell audio menu
  or pavucontrol; PipeWire remembers it.

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
