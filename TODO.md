# TODO

## Before installing

- [ ] esa: set the disk by-id in `hosts/esa/default.nix`. Check that work allows its own OS,
      Secure Boot keys and WireGuard.
- [ ] Add the user key from esa to `secrets/agenix-rules.nix`.
- [ ] Add the host keys to `secrets/agenix-rules.nix` and create `secrets/wg0-<host>.age` (docs/INSTALL.md §4).

## After the first login on each host

- [ ] Check monitor descriptions (`hyprctl monitors all`) and keyboard names (`hyprctl devices`)
      in `hosts/<host>/hyprland.lua`. They were translated from sway and are guesses.
- [ ] esa: check that `DP-1`/`DP-2` in the workspace rules are the right outputs.
- [ ] Check that the `Mod+Space` (tiled ↔ floating focus) bind behaves like sway's `focus mode_toggle`.
- [ ] Scrolling layout: try every bind in `docs/USAGE.md` ("Hyprland"). The build check cannot
      catch typos in layout messages (`focus`, `swapcol`, `colresize`, `consume`, ...).
- [ ] `Mod+Shift+e` (rofi, then `hyprshutdown`) and `Mod+Shift+p` (`hyprpicker -a`) work.
- [ ] Border and group colors now come from stylix (the manual colors are gone): check them,
      also after the light/dark toggle.

## Hyprland cleanup candidates (need a running session to test)

- [ ] `systemd.variables = [ "--all" ]` in `modules/home/hyprland/default.nix` imports the whole
      environment into systemd. Home Manager's default list is smaller; try removing it and
      check that ashell, hypridle, mako and the wallpaper service still start.
- [ ] The `Open/Save` window rule in `hyprland.lua`: Hyprland floats dialogs that have a parent
      window by itself. Try removing the rule; the `xdg-desktop-portal-gtk` one is still needed.
- [ ] kitty: `remember_window_size no` would stop kitty from restoring a "maximized" state, which
      is the root cause of the covering windows. Then the `suppress-maximize-events` rule is only
      a safety net.
- [ ] dongmyo: the laptop screen is defined three times (`hosts/dongmyo/hyprland.lua`, and the
      hypridle command in `hosts/dongmyo/home.nix`).

## Later

- [ ] Firefox: pick **Tridactyl** (vim-like, config file fits Nix, more powerful) or
      **Vimium** (simpler, just hints and scrolling) and add it in `modules/home/firefox.nix`.
- [ ] Neovim: `sqlls` and `cssmodules_ls` were in the Mason list but are not packaged in
      nixpkgs. Install with `pnpm add -g` if needed, or drop them.
- [ ] Home folder backups to the home server with restic or borg (a systemd timer).
- [ ] CI: a GitHub Action that evaluates/builds all hosts on every push.
