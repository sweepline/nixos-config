{
  config,
  lib,
  pkgs,
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

        environment.systemPackages = [ pkgs.brightnessctl ];

        # Sleep first, hibernate after 2 hours asleep. With an external monitor
        # (docked), closing the lid does nothing; Hyprland turns the laptop screen off.
        services.logind.settings.Login = {
          HandleLidSwitch = "suspend-then-hibernate";
          HandleLidSwitchExternalPower = "suspend-then-hibernate";
          HandleLidSwitchDocked = "ignore";
          HandlePowerKey = "suspend-then-hibernate";
        };
        systemd.sleep.settings.Sleep.HibernateDelaySec = "2h";
      }

      (lib.mkIf (cfg.chargeLimit != null) {
        systemd.services.battery-charge-limit = {
          description = "Limit battery charging to ${toString cfg.chargeLimit}%";
          wantedBy = [ "multi-user.target" ];
          after = [ "multi-user.target" ];
          serviceConfig.Type = "oneshot";
          script = ''
            for f in /sys/class/power_supply/BAT*/charge_control_end_threshold; do
              [ -w "$f" ] && echo ${toString cfg.chargeLimit} > "$f"
            done
          '';
        };
        # Re-apply after resume, some firmware resets it.
        powerManagement.resumeCommands = "systemctl restart battery-charge-limit.service";
      })

      (lib.mkIf cfg.fingerprint.enable {
        services.fprintd.enable = true;
        # Login keeps the password: it also unlocks the keyring (and SSH key).
        security.pam.services.ly.fprintAuth = false;
        # hyprlock does fingerprint itself, in parallel with the password.
        security.pam.services.hyprlock.fprintAuth = false;
      })
    ]
  );
}
