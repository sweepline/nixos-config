{
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
}:
# Scalgo's simple-admin client, from the prebuilt release (the internal wiki's install guide).
# sadmin says when it is out of date; it cannot update itself (the store is read-only), so
# run pkgs/update-sadmin.sh, which sets the newest version and hash here.
stdenv.mkDerivation rec {
  pname = "sadmin";
  version = "0.1.13";

  src = fetchurl {
    url = "https://github.com/antialize/simple-admin/releases/download/v${version}/sadmin-client.zip";
    hash = "sha256-XI3lLxcnB0dwy0F+LTLtNkhf+IT4mpLu4ROh57CbBxU=";
  };
  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    unzip
  ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 sadmin $out/bin/sadmin
    runHook postInstall
  '';

  meta = {
    description = "Client for simple-admin (sadmin.scalgo.com)";
    homepage = "https://github.com/antialize/simple-admin";
    platforms = [ "x86_64-linux" ];
    mainProgram = "sadmin";
  };
}
