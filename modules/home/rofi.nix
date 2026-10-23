{ config, pkgs, ... }:
let
  inherit (config.lib.formats.rasi) mkLiteral;
  colors = config.lib.stylix.colors;
  inherit (config.stylix) fonts opacity;

  rgba =
    alpha: base:
    mkLiteral "rgba ( ${colors."${base}-rgb-r"}, ${colors."${base}-rgb-g"}, ${
      colors."${base}-rgb-b"
    }, ${toString alpha} % )";
  rgb = rgba 100;
  popupAlpha = builtins.ceil (opacity.popups * 100);
in
{
  # stylix's own rofi target is off: it still sets programs.rofi.font, which Home Manager
  # now warns about on every build. This is the same theme, from the same stylix colors.
  stylix.targets.rofi.enable = false;

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
      font = "${fonts.monospace.name} ${toString fonts.sizes.popups}";
    };

    # Border and rounding like the Hyprland windows (border_size and rounding in hyprland.lua).
    theme = {
      "*" = {
        background-color = mkLiteral "transparent";
        text-color = rgb "base05";
        border-color = rgb "base0D";
      };

      window = {
        background-color = rgba popupAlpha "base00";
        border = mkLiteral "3px";
        border-radius = mkLiteral "2px";
        padding = mkLiteral "12px";
      };

      mainbox.spacing = mkLiteral "10px";

      inputbar = {
        padding = mkLiteral "6px 8px";
        spacing = mkLiteral "8px";
        background-color = rgb "base01";
        border-radius = mkLiteral "2px";
      };
      prompt.text-color = rgb "base0D";
      "textbox-prompt-colon".text-color = rgb "base0D";

      listview = {
        spacing = mkLiteral "2px";
        padding = mkLiteral "4px 0 0 0";
        scrollbar = false;
      };

      element = {
        padding = mkLiteral "6px 8px";
        border-radius = mkLiteral "2px";
      };
      "element selected.normal" = {
        background-color = rgb "base0D";
        text-color = rgb "base00";
      };
      "element normal.active".text-color = rgb "base0D";
      "element normal.urgent".text-color = rgb "base08";
      "element selected.active" = {
        background-color = rgb "base0D";
        text-color = rgb "base00";
      };
      "element selected.urgent" = {
        background-color = rgb "base08";
        text-color = rgb "base00";
      };

      message.padding = mkLiteral "6px 8px";
      "button selected" = {
        background-color = rgb "base0D";
        text-color = rgb "base00";
      };
    };
  };
}
