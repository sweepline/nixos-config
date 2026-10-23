{ lib, ... }:
{
  my.hyprland.hostConfig = builtins.readFile ./hyprland.lua;

  # Fingerprint unlock on the lock screen (password still works)
  programs.hyprlock.settings.auth."fingerprint:enabled" = true;

  # After waking up: screens on, and the laptop screen re-enabled if the lid is
  # open (in case the lid-open event was missed while asleep).
  services.hypridle.settings.general.after_sleep_cmd = lib.mkForce (
    "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'; "
    + "grep -q open /proc/acpi/button/lid/*/state && "
    + "hyprctl eval 'hl.monitor({ output = \"eDP-1\", mode = \"preferred\", position = \"auto\", scale = 1 })'"
  );
}
