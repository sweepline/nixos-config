{
  inputs,
  pkgs,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  # Desktops also set programs.nh.flake (../desktop/base.nix). The server is deployed from a
  # desktop (`nh os switch -H homebox --target-host ...`), so it has no checkout to point at.
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep 10 --keep-since 14d";
    };
  };

  # Which commit of this repo a generation was built from ("-dirty": uncommitted changes).
  # `nixos-version --configuration-revision` shows the full hash; the label (shown in the
  # Limine entry's comment) gets the short one.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.nixos.tags = [ "cfg.${inputs.self.shortRev or inputs.self.dirtyShortRev or "unknown"}" ];

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
  # Console and Ly: US with Caps as Ctrl on every keyboard (Hyprland sets its own per device).
  console.useXkbConfig = true;
  services.xserver.xkb = {
    layout = "us";
    options = "ctrl:nocaps";
  };

  zramSwap.enable = true;

  # Replaced by nix-index (Home Manager), which works with flakes.
  programs.command-not-found.enable = false;

  services.fwupd.enable = true;
  hardware.enableRedistributableFirmware = true;

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
    efibootmgr
  ];

  system.stateVersion = "26.05";
}
