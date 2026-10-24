{ pkgs, ... }:
{
  my.hyprland.hostConfig = builtins.readFile ./hyprland.lua;

  # VNC server for the work screen, reachable over Tailscale (port 5900, hosts/esa/default.nix).
  # TODO: check the output name with `hyprctl monitors` after the first login.
  home.packages = [ pkgs.wayvnc ];
  programs.bash.shellAliases.vncstart = "wayvnc -o DP-5 -g 0.0.0.0";
}
