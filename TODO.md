# TODO

## Before installing

- [ ] esa: set the disk by-id in `hosts/esa/default.nix`. Check that work allows its own OS,
      Secure Boot keys and WireGuard.
- [ ] Add the user key from esa to `secrets/keys.nix`.
- [ ] Add the host keys to `secrets/keys.nix` and create `secrets/wg0-<host>.age` (docs/INSTALL.md §4).

## After the first login on each host

- [ ] Check monitor descriptions (`hyprctl monitors all`) and keyboard names (`hyprctl devices`)
      in `hosts/<host>/hyprland.lua`. They were translated from sway and are guesses.
- [ ] esa: check that `DP-1`/`DP-2` in the workspace rules are the right outputs, and that
      `DP-5` in `vncstart` (`hosts/esa/home.nix`) is the screen to share over VNC.
- [ ] Work hosts: `sadmin` runs, `git config user.email` in a work repo shows
      `mikkel@scalgo.com`, and `ssh ts01` (or another work host) connects.
- [ ] `ssh` between 97 and dongmyo over WireGuard works (their `wg0` addresses).
- [ ] Check that the `Mod+Space` (tiled ↔ floating focus) bind behaves like sway's `focus mode_toggle`.
- [ ] Scrolling layout: try every bind in `docs/USAGE.md` ("Hyprland"). The build check cannot
      catch typos in layout messages (`focus`, `swapcol`, `colresize`, `promote`, `consume_or_expel`, ...).
- [ ] `Mod+Shift+e` (rofi, then `hyprshutdown`) and `Mod+Shift+p` (`hyprpicker -a`) work.
- [ ] Border and group colors now come from stylix (the manual colors are gone): check them,
      also after the light/dark toggle.

## Hyprland cleanup candidates (need a running session to test)

- [ ] `systemd.variables = [ "--all" ]` in `modules/home/hyprland/default.nix` imports the whole
      environment into systemd. Home Manager's default list is smaller; try removing it and
      check that ashell, hypridle, mako and the wallpaper service still start.
- [ ] The `Open/Save` window rule was removed, since Hyprland floats dialogs that have a parent
      window by itself. Open a file dialog (Firefox: Ctrl+O, a download "Save as") and check that
      it floats and is centered. If it tiles, put the rule back in `hyprland.lua`:
      `hl.window_rule({ match = { title = "^(Open|Save) (File|Folder|As)" }, float = true, size = "1030 710", center = true })`
- [ ] kitty: new windows no longer cover the old one now that Hyprland ignores maximize requests
      (`suppress-maximize-events` in `hyprland.lua`). Check it. The root cause is that kitty
      restores a "maximized" state Hyprland reported to it; `remember_window_size no` in kitty
      would remove that, but it is deliberately not set.
- [ ] dongmyo: the laptop screen now uses the generic `preferred, auto, scale 1` everywhere
      (monitor rule, lid-open bind, hypridle). Check `hyprctl monitors all` shows 1920x1200 as the
      current mode and the laptop on the left of the external monitor; then test: lid closed
      docked (screen off), lid open (screen on), and wake from sleep.

## GPU Screen Recorder overlay on 97 (first run)

- [ ] `systemctl --user status gsr-ui` is running. Press `Mod+g`: the overlay should appear
      over the game or desktop. It is an X11-first program with a Wayland layer-shell overlay;
      check that it looks right, is not zoomed, and does not steal focus from a game.
- [ ] The overlay's settings should not ask for keyboard grabbing: `gsr-global-hotkeys` is not
      installed on purpose. Check that Caps Lock still acts as Ctrl and Alt/Win are still swapped.
- [ ] Start the replay buffer (from the overlay or `gsr-ui-cli start-replay`), play a bit, then
      `Mod+Shift+g` and check the saved clip. NVENC recording of a game works.
- [ ] Decide whether the overlay replaces `Mod+Shift+r` (`gsr-ui-cli toggle-record-region`) and
      the `gpu-screen-recorder-gtk` app on 97.
- [ ] Currently its reporting that only cpu encoding is available

## Later

- [ ] Firefox: pick **Tridactyl** (vim-like, config file fits Nix, more powerful) or
      **Vimium** (simpler, just hints and scrolling) and add it in `modules/home/firefox.nix`.
- [ ] Neovim: `sqlls` and `cssmodules_ls` were in the Mason list but are not packaged in
      nixpkgs. Install with `pnpm add -g` if needed, or drop them.
- [ ] Home folder backups to the home server with restic or borg (a systemd timer).
- [ ] CI: a GitHub Action that evaluates/builds all hosts on every push.
- [ ] 97: once NixOS/nixpkgs#575192 is fixed, remove `hardware.xpad-noone.enable = false` and the
      `load-xpad` service in `modules/nixos/gaming.nix`. Until then the stock `xpad` drives the
      wireless Xbox 360 receiver (Guitar Hero controller); check it works.
- [ ] ashell: the theme button (light/dark) showed a cogwheel after the switch to unstable.
      Check on dongmyo (`theme-toggle watch`, `fc-list | grep -i "symbols nerd"`).
- [ ] nvim we should have nix config lsp?
- [ ] nvim remove the ai cli and nes, but keep the ctrl+space completion.
