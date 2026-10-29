# nixos-config

NixOS + Home Manager flake for my machines.

| Host | Machine | GPU | Extras |
|---|---|---|---|
| `dongmyo` | Laptop | AMD | power profiles, hibernate |
| `97` | Desktop (dual boot Windows) | NVIDIA | gaming (Steam, Proton-GE, Lutris, Heroic) |
| `esa` | Work PC | Intel | three monitors |

All hosts share the same desktop: **ly** (black hole animation) → **Hyprland** (scrolling layout, sway-style hjkl keys),
ashell, mako, rofi, kitty, Firefox and Neovim, themed with **stylix** (gruvbox-material, light/dark
toggle in the bar). Disks are **LUKS2** encrypted and unlocked with **TPM2 + PIN**, booted
through **Limine** with **Secure Boot**. Every host joins a **WireGuard** network
(`wg0`, config encrypted with **agenix**); hosts with `my.work.enable` also join **Tailscale**
and get the work setup (sadmin, SSH hosts, git aliases and email).

## Docs

- [docs/INSTALL.md](docs/INSTALL.md): installing a machine from the NixOS ISO (including backup and restore)
- [docs/USAGE.md](docs/USAGE.md): everyday use: rebuilding, updating, rollbacks, secrets, keybinds, testing in a VM
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md): uv, pnpm, rustup and devShells on NixOS
- [TODO.md](TODO.md): open items

## Layout

```
flake.nix                 inputs and the three hosts
hosts/<host>/             host settings, disk device, hardware config, monitors (home.nix)
hosts/disk-layout.nix     shared disko layout (EFI + LUKS2 + ext4)
modules/nixos/common/     system modules for every host (nix, locale, boot, networking, ssh, wg0, users)
modules/nixos/desktop/    desktop-only system modules (session, Home Manager, stylix, gaming, laptop, work, ...)
modules/home/             Home Manager modules (Hyprland, ashell, Firefox, ...)
modules/home/hyprland/    plain hyprland.lua; hosts/<host>/hyprland.lua holds monitors and rules
dotfiles/nvim/            Neovim Lua config (lazy.nvim), symlinked into ~/.config/nvim
dotfiles/opencode/        opencode config (opencode.json, cli.json), symlinked into ~/.config/opencode
secrets/                  agenix: keys.nix (public keys), agenix-rules.nix (who can decrypt) and *.age files
backup/                   backup/restore scripts and per-host path lists
```
