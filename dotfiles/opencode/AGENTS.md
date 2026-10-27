# Environment

This machine runs NixOS with flakes, so tools not installed globally are usually one `nix shell nixpkgs#<pkg>` away.

## Missing tools

- Don't `apt`, `dnf`, `pip install --user`, `npm install -g` or `cargo install` system-wide. These don't work or don't persist on NixOS.
- For a one-off tool, use a temporary shell with the new `nix` CLI, not the legacy `nix-shell -p`:
  - `nix shell nixpkgs#<pkg> -c <cmd>` (e.g. `nix shell nixpkgs#jq -c jq . file.json`; several packages: `nix shell nixpkgs#{jq,curl} -c ...`)
  - or `nix run nixpkgs#<pkg> -- <args>`
- Find package names with `nix search nixpkgs <name>`. The package name doesn't always match the binary name (e.g. `dig` is in `dnsutils`).
- If a project has a `flake.nix`, use its dev shell (`nix develop -c <cmd>`). Fall back to `nix-shell --run '<cmd>'` only for projects that have just a `shell.nix`.

## Filesystem quirks

- No FHS: `/usr/bin`, `/usr/lib` etc. are mostly empty. Use `#!/usr/bin/env bash` in scripts, not `#!/bin/bash`.
- Prebuilt binaries from the internet (and some pip/npm packages with native code) often fail with "No such file or directory" because the dynamic linker is missing. Prefer the nixpkgs package or a dev shell.
