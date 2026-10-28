{
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  # Workaround for playback stalls over HTTP/2 (libsoup 3.8.0 enables h2 by
  # default and stalls streamed audio). Gelly 1.16.2 sets this itself; nixpkgs
  # currently ships 1.14.0, so drop this wrapper once it is updated.
  # https://github.com/Fingel/gelly/issues/247
  gelly = pkgs.symlinkJoin {
    name = "gelly";
    paths = [ pkgs.gelly ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/gelly --set SOUP_FORCE_HTTP1 1
    '';
  };
in
{
  home.packages = with pkgs; [
    # CLI
    yazi
    bottom
    ripgrep
    fd
    jq
    mpv
    python3Packages.bpython
    tmux
    pavucontrol
    impala
    # Archives (yazi uses ouch for previews/extracting)
    ouch
    _7zz
    unrar
    zstd
    rsync
    swayimg

    # Development (see docs/DEVELOPMENT.md)
    rustup
    # rustc links through `cc`; the gcc in neovim.nix is only on Neovim's PATH.
    gcc
    # Projects should still use uv-managed interpreters (UV_PYTHON_PREFERENCE below).
    # Work: mono's deploy scripts (scripts/sadmin_deploy2.py) run on this interpreter and
    # need requests and yaml; `pip install --user` doesn't work against the read-only Nix store.
    # Ships a python -> python3 symlink itself, so bare `python` works too.
    (python3.withPackages (
      ps:
      lib.optionals osConfig.my.work.enable [
        ps.pyyaml
        ps.requests
      ]
    ))
    uv
    nodejs
    # Provides pnpm/yarn shims that follow each repo's "packageManager" pin. hiPrio because
    # nodejs also ships a bin/corepack, which would otherwise conflict in the profile.
    (lib.hiPrio corepack)
    # opencode 2.1+ from upstream's flake (see flake.nix); nixpkgs has 2.0.x
    inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode

    # Apps
    vesktop # Discord with Vencord; screen share with audio on Wayland
    signal-desktop
    joplin-desktop
    gelly
    godot
    chromium
    qgis
  ];

  # uv downloads its own Python builds; they run through nix-ld.
  home.sessionVariables.UV_PYTHON_PREFERENCE = "only-managed";

  xdg.configFile."swayimg/init.lua".source = ./swayimg.lua;

  # GnuPG (backups, encrypted files on USB). Passphrase prompts use the GNOME
  # prompt, which also works in the terminal and under Hyprland.
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-gnome3;
  };

  # PDF viewer (vim keys, themed by stylix). Unlike GTK4 apps and kitty it
  # cannot follow the light/dark toggle live: restart it after toggling.
  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard";
      recolor = false;
    };
  };

  # Auto-mount USB drives under /run/media/mikkel/<label>, with a notification
  # and a tray icon (click to unmount/eject).
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "auto";
  };
}
