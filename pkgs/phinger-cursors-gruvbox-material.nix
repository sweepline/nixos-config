{ stdenvNoCC, fetchurl }:
# Gruvbox Material fork of phinger-cursors, from its prebuilt release (the fork is not in nixpkgs).
# Provides the themes phinger-cursors-gruvbox-material (dark cursor) and
# phinger-cursors-gruvbox-material-light (light cursor).
stdenvNoCC.mkDerivation {
  pname = "phinger-cursors-gruvbox-material";
  version = "2023-04-12";

  src = fetchurl {
    url = "https://github.com/rehanzo/phinger-cursors-gruvbox-material/releases/download/3328966123/phinger-cursors-variants.tar.bz2";
    hash = "sha256-qAEGY3B0tphEwYGfhkJ555yLgAu1nflCjqCOfZ8vjIE=";
  };
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/icons
    cp -r phinger-cursors-gruvbox-material* $out/share/icons/
    runHook postInstall
  '';
}
