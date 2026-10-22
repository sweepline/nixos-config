{ pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    plugins = [ pkgs.rofi-calc ];
    terminal = "kitty";
    modes = [ "combi" ];
    extraConfig.combi-modes = [
      "window"
      "drun"
    ];
  };
}
