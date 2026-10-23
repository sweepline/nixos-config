{ pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    plugins = [ pkgs.rofi-calc ];
    settings = {
      terminal = "kitty";
      modes = [ "combi" ];
      combi-modes = [
        "window"
        "drun"
      ];
    };
  };
}
