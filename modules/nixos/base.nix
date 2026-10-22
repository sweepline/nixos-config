{
  config,
  inputs,
  pkgs,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ inputs.nur.overlays.default ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "@wheel" ];
    auto-optimise-store = true;
  };

  programs.nh = {
    enable = true;
    flake = config.my.configDir;
    clean = {
      enable = true;
      extraArgs = "--keep 10 --keep-since 14d";
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  time.timeZone = "Europe/Copenhagen";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "da_DK.UTF-8";
      LC_MEASUREMENT = "da_DK.UTF-8";
      LC_MONETARY = "da_DK.UTF-8";
      LC_NUMERIC = "da_DK.UTF-8";
      LC_PAPER = "da_DK.UTF-8";
      LC_TELEPHONE = "da_DK.UTF-8";
      LC_TIME = "da_DK.UTF-8";
    };
  };
  console.keyMap = "us";

  zramSwap.enable = true;

  # Replaced by nix-index (Home Manager), which works with flakes.
  programs.command-not-found.enable = false;

  services.fwupd.enable = true;
  hardware.enableRedistributableFirmware = true;

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
      libxext
      libxrender
      libxi
      libxrandr
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
      libdrm
    ];
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    file
    unzip
    zip
    pciutils
    usbutils
    sbctl
    efibootmgr
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  system.stateVersion = "26.05";
}
