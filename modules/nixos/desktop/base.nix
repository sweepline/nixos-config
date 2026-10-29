{
  config,
  inputs,
  pkgs,
  ...
}:
{
  nixpkgs.overlays = [ inputs.nur.overlays.default ];

  programs.nh.flake = config.my.configDir;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Prebuilt binaries downloaded by uv, pnpm, rustup etc. See docs/DEVELOPMENT.md.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      zstd
      openssl
      curl
      glib
      libxml2
      icu
      nss
      nspr
      expat
      libGL
      libxkbcommon
      wayland
      libx11
      libxcb
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxrandr
      libxrender
      libxscrnsaver
      libxshmfence
      libxtst
      fontconfig
      freetype
      dbus
      alsa-lib
      at-spi2-atk
      cups
      gtk3
      pango
      cairo
      mesa
      libgbm
      libdrm
    ];
  };

  environment.systemPackages = [
    pkgs.sbctl
    # Secrets are edited on the desktops (`agenix -e`); hosts only decrypt them at boot.
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
