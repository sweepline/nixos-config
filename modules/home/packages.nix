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
}
