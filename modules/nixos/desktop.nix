{ inputs, pkgs, ... }:
{
  services.displayManager.ly = {
    enable = true;
    x11Support = false;
    settings = {
      animation = "dur_file";
      dur_file_path = "${inputs.ly-community}/animations/dur/blackhole-smooth-240x67.dur";
      dur_offset_alignment = "center";
      full_color = true;
      clear_password = true;
    };
  };

  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  security.polkit.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    # Let PipeWire switch the output rate to match the music (44.1k CD, 96k/192k
    # hi-res, ...) instead of resampling everything to 48 kHz. Only rates the
    # device supports are used.
    extraConfig.pipewire."10-allowed-rates" = {
      "context.properties"."default.clock.allowed-rates" = [
        44100
        48000
        88200
        96000
        176400
        192000
        352800
        384000
      ];
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # Keyring unlocked by ly at login. Also provides the SSH agent (gcr-ssh-agent),
  # which remembers key passphrases in the keyring.
  services.gnome.gnome-keyring.enable = true;
  services.gnome.gcr-ssh-agent.enable = true;
  services.dbus.packages = [ pkgs.gcr_4 ];
  programs.seahorse.enable = true;

  programs.gpu-screen-recorder.enable = true;

  services.udisks2.enable = true;
  services.gvfs.enable = true;
  programs.dconf.enable = true;

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      iosevka-bin
      (iosevka-bin.override { variant = "Aile"; })
      (iosevka-bin.override { variant = "Etoile"; })
      (iosevka-bin.override { variant = "Slab"; })
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      font-awesome
      nerd-fonts.symbols-only
    ];
  };
}
