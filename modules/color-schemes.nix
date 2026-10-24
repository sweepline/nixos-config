# The two stylix color schemes, used by modules/nixos/stylix.nix (dark is the
# default) and modules/home/theme.nix (light specialisation, GTK4 and kitty).
pkgs: {
  dark = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-medium.yaml";
  light = "${pkgs.base16-schemes}/share/themes/gruvbox-material-light-medium.yaml";
}
