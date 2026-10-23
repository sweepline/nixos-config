{ config, pkgs, ... }:
let
  inherit (config.lib.formats.rasi) mkLiteral;
in
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

    # Added on top of the stylix colors: border and rounding like the Hyprland windows
    # (border_size and rounding in hyprland.lua), plus some padding.
    theme = {
      window = {
        border = mkLiteral "3px";
        border-color = mkLiteral "@blue";
        border-radius = mkLiteral "2px";
        padding = mkLiteral "12px";
      };
      mainbox.spacing = mkLiteral "10px";
      inputbar = {
        padding = mkLiteral "6px 8px";
        spacing = mkLiteral "8px";
      };
      listview = {
        spacing = mkLiteral "2px";
        border = mkLiteral "0";
        padding = mkLiteral "4px 0 0 0";
      };
      element = {
        padding = mkLiteral "6px 8px";
        border-radius = mkLiteral "2px";
      };
    };
  };
}
