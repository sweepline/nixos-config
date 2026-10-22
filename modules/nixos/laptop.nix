{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.my.laptop.enable {
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  environment.systemPackages = [ pkgs.brightnessctl ];

  # Sleep first, hibernate after 2 hours asleep.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandlePowerKey = "suspend-then-hibernate";
  };
  systemd.sleep.settings.Sleep.HibernateDelaySec = "2h";
}
