{
  config,
  lib,
  ...
}:
let
  cfg = config.my.laptop;
in
{
  options.my.laptop = {
    chargeLimit = lib.mkOption {
      type = lib.types.nullOr (lib.types.ints.between 50 100);
      default = 80;
      description = ''
        Stop charging at this percentage to save the battery. Only works if the
        laptop exposes charge_control_end_threshold. null = always charge to 100%.
      '';
    };
    fingerprint.enable = lib.mkEnableOption "the fingerprint reader (sudo and hyprlock)";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.power-profiles-daemon.enable = true;
        services.upower.enable = true;

        # Closing the lid only sleeps. Not suspend-then-hibernate: when its hibernate step
        # was aborted, amdgpu was left broken (EGL_BAD_ALLOC) and Hyprland crashed until a
        # reboot. The power button hibernates. With an external monitor (docked), closing
        # the lid does nothing; Hyprland turns the laptop screen off.
        services.logind.settings.Login = {
          HandleLidSwitch = "suspend";
          HandleLidSwitchExternalPower = "suspend";
          HandleLidSwitchDocked = "ignore";
          HandlePowerKey = "hibernate";
        };
      }

      (lib.mkIf (cfg.chargeLimit != null) {
        # Set whenever a battery appears or changes (boot, resume, AC plug), since some
        # firmware resets it. Batteries without the attribute are skipped.
        services.udev.extraRules = ''
          SUBSYSTEM=="power_supply", KERNEL=="BAT*", ATTR{charge_control_end_threshold}=="*", ATTR{charge_control_end_threshold}="${toString cfg.chargeLimit}"
        '';
      })

      (lib.mkIf cfg.fingerprint.enable {
        services.fprintd.enable = true;
        # Login keeps the password: it also unlocks the keyring (and SSH key).
        # Ly's PAM file includes "login", so that one needs it off too (else Ly waits
        # for the fingerprint timeout before asking for the password).
        security.pam.services.ly.fprintAuth = false;
        security.pam.services.login.fprintAuth = false;
        # hyprlock does fingerprint itself, in parallel with the password.
        security.pam.services.hyprlock.fprintAuth = false;
      })
    ]
  );
}
