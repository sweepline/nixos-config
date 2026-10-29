{
  config,
  lib,
  pkgs,
  ...
}:
{
  # my.theme is the default. The other variant is a Home Manager specialisation,
  # switched at runtime by the theme button in ashell (see modules/home/theme.nix).
  stylix = {
    enable = true;
    polarity = config.my.theme;
    base16Scheme = (import ../../color-schemes.nix pkgs).${config.my.theme};

    fonts = {
      monospace = {
        package = pkgs.iosevka-bin;
        name = "Iosevka";
      };
      sansSerif = {
        package = pkgs.iosevka-bin.override { variant = "Aile"; };
        name = "Iosevka Aile";
      };
      serif = {
        package = pkgs.iosevka-bin.override { variant = "Etoile"; };
        name = "Iosevka Etoile";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 12;
        terminal = 14;
        desktop = 12;
        popups = 12;
      };
    };

    cursor = {
      package = pkgs.callPackage ../../../pkgs/phinger-cursors-gruvbox-material.nix { };
      name =
        "phinger-cursors-gruvbox-material" + lib.optionalString (config.my.theme == "light") "-light"; # variant matching my.theme; modules/home/theme.nix switches it
      size = 32;
    };

    icons = {
      enable = true;
      package = pkgs.gruvbox-plus-icons;
      dark = "Gruvbox-Plus-Dark";
      light = "Gruvbox-Plus-Dark";
    };
  };
}
