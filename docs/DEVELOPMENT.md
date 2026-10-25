# Development on NixOS

## The short version

Use your tools like before: `rustup`, `cargo`, `uv`, `node`, `pnpm` are installed globally
and work in any repo. For your own projects you can optionally add a Nix **devShell**, so the
exact toolchain loads automatically when you `cd` into the folder.

## Why NixOS is different

Normal Linux programs expect libraries in fixed places (`/lib64/ld-linux-x86-64.so.2`,
`/usr/lib/libssl.so`, ...). NixOS keeps everything in `/nix/store/<hash>-name/` instead, so
those paths do not exist.

Programs built by Nix know where their libraries are. But many dev tools **download
prebuilt binaries** that expect the standard paths:

- `uv` downloads Python builds (`uv python install`) and wheels with compiled code
- `pnpm`/`npm` packages with native binaries: esbuild, swc, biome, prisma, playwright, sharp
- `rustup` toolchains and some `cargo install` binaries
- random binaries from GitHub releases

Without help these fail with a confusing error like:

```
bash: ./some-binary: No such file or directory
```

even though the file is right there. The "missing file" is the dynamic loader.

## nix-ld: what makes it work

`programs.nix-ld` (in `modules/nixos/base.nix`) installs a fake `/lib64/ld-linux-x86-64.so.2`
that runs these binaries with a set of common libraries (`NIX_LD_LIBRARIES`): libc++,
zlib, openssl, curl, glib, X11/Wayland/GL, GTK and more. Most downloaded binaries just work.

If one still fails with a missing library:

```sh
ldd ./some-binary | grep "not found"     # e.g. libfoo.so.1 => not found
nix-locate libfoo.so.1                   # which package has it (needs nix-index)
```

then add that package to `programs.nix-ld.libraries` in `modules/nixos/base.nix` and rebuild.

## The global tools

| Tool | Notes |
|---|---|
| `rustup` | `rustup default stable`, then `cargo` works as usual. Binaries go to `~/.cargo/bin` (on `PATH`). |
| `uv` | `UV_PYTHON_PREFERENCE=only-managed` is set, so uv always uses its own downloaded Python (works via nix-ld) instead of the Nix one. |
| `node`, `pnpm` | `corepack` provides `pnpm`/`yarn` and automatically uses the version in `package.json`. `PNPM_HOME=~/.local/share/pnpm` is on `PATH`, so `pnpm add -g` works. |
| `gcc`, `make` | Available through Neovim's tool list. For C libraries in builds (openssl, pkg-config), use a devShell. |

Things that often need a devShell instead: crates/packages that compile against system
libraries (`openssl-sys`, `pkg-config`, `libpq`, ...), because there is no global
`/usr/include` on NixOS.

## devShells with direnv

`direnv` + `nix-direnv` are installed. A project with a `flake.nix` that defines a devShell
and an `.envrc` file containing `use flake` loads its tools automatically on `cd`:

```sh
cd my-project
echo "use flake" > .envrc
direnv allow
```

The first load builds the shell; after that it is cached and instant. `git add flake.nix`
first (flakes only see tracked files). Commit `flake.lock` so everyone gets the same versions.

If a project should not get Nix files (someone else's repo), put them outside the repo and
point to them, or skip the devShell and use the global tools.

### Node + pnpm

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = [ pkgs.nodejs_22 pkgs.pnpm ];
      };
    };
}
```

### Rust (with a pinned toolchain)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { nixpkgs, rust-overlay, ... }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ rust-overlay.overlays.default ];
      };
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = [
          # reads rust-toolchain.toml if the project has one
          (pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml)
          pkgs.pkg-config
          pkgs.openssl
        ];
      };
    };
}
```

Without a `rust-toolchain.toml`, use `pkgs.rust-bin.stable.latest.default` instead.

### Python + uv

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = [ pkgs.uv pkgs.python312 ];
        env = {
          UV_PYTHON_PREFERENCE = "only-system";   # use the Nix Python in this project
          UV_PYTHON = "${pkgs.python312}/bin/python";
        };
        # Libraries that compiled wheels (numpy, ...) need at runtime
        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib pkgs.zlib ];
      };
    };
}
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `No such file or directory` for a binary that exists | It is a prebuilt binary: check that nix-ld is enabled; `file ./binary` shows the interpreter it wants. |
| `error while loading shared libraries: libX.so` | Add the library to `programs.nix-ld.libraries`, or to the devShell. |
| `pkg-config` / `openssl-sys` build errors | Use a devShell with `pkg-config` and the library. |
| Playwright browsers fail | Use `pkgs.playwright-driver.browsers` in a devShell and set `PLAYWRIGHT_BROWSERS_PATH` to it, with `PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true`. |
| Prisma engines fail | In a devShell, use `pkgs.prisma-engines` and set `PRISMA_QUERY_ENGINE_LIBRARY` etc. to its paths. |
| A tool wants `/bin/bash` | Use `#!/usr/bin/env bash` in scripts; `/usr/bin/env` exists on NixOS. |
| Neovim LSP not found | LSPs come from Nix (`modules/home/neovim.nix`), not Mason. Add the package there. |
