# The two stylix color schemes, used by modules/nixos/desktop/stylix.nix (my.theme picks the
# default) and modules/home/theme.nix (the other one as specialisation, GTK4 and kitty).
pkgs: {
  dark = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-medium.yaml";
  light = "${pkgs.base16-schemes}/share/themes/gruvbox-material-light-medium.yaml";
}
