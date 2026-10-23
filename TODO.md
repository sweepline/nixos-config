# TODO

## Before installing

- [ ] esa: set the disk by-id in `hosts/esa/default.nix`. Check that work allows its own OS,
      Secure Boot keys and WireGuard.
- [ ] Add the user key from esa to `secrets/agenix-rules.nix`.
- [ ] Add the host keys to `secrets/agenix-rules.nix` and create `secrets/wg0-<host>.age` (docs/INSTALL.md §4).

## After the first login on each host

- [ ] Check monitor descriptions (`hyprctl monitors all`) and keyboard names (`hyprctl devices`)
      in `hosts/<host>/home.nix`. They were translated from sway and are guesses.
- [ ] esa: check that `DP-1`/`DP-2` in the workspace rules are the right outputs.
- [ ] Check that the `Mod+Space` (tiled ↔ floating focus) bind behaves like sway's `focus mode_toggle`.

## Later

- [ ] Firefox: pick **Tridactyl** (vim-like, config file fits Nix, more powerful) or
      **Vimium** (simpler, just hints and scrolling) and add it in `modules/home/firefox.nix`.
- [ ] Neovim: `sqlls` and `cssmodules_ls` were in the Mason list but are not packaged in
      nixpkgs. Install with `pnpm add -g` if needed, or drop them.
- [ ] Home folder backups to the home server with restic or borg (a systemd timer).
- [ ] CI: a GitHub Action that evaluates/builds all hosts on every push.
