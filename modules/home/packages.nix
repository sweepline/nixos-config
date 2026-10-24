{ inputs, pkgs, ... }:
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
    uv
    nodejs
    pnpm
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

  # Workaround for playback stalls over HTTP/2 (libsoup 3.8.0 enables h2 by
  # default and stalls streamed audio). Gelly 1.16.2 sets this itself; nixpkgs
  # currently ships 1.14.0. https://github.com/Fingel/gelly/issues/247
  home.sessionVariables.SOUP_FORCE_HTTP1 = "1";

  xdg.configFile."swayimg/init.lua".source = ./swayimg.lua;

  # GnuPG (backups, encrypted files on USB). Passphrase prompts use the GNOME
  # prompt, which also works in the terminal and under Hyprland.
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-gnome3;
  };

  # PDF viewer (vim keys, themed by stylix)
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
