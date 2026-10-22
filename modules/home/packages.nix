{ pkgs, ... }:
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
    swayimg
    nh

    # Development (see docs/DEVELOPMENT.md)
    rustup
    uv
    nodejs
    pnpm
    opencode

    # Apps
    discord
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
