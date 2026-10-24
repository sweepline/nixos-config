{ lib, osConfig, ... }:
let
  cfg = osConfig.my.laptop;
  laptopScreen = ''hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })' '';
in
lib.mkIf cfg.enable {
  # Docked (another monitor connected): turn the laptop screen off when the lid closes.
  # Not docked: do nothing here, logind suspends (modules/nixos/laptop.nix). Opening the lid
  # always turns the laptop screen back on.
  my.hyprland.hostConfig = ''
    hl.bind("switch:on:Lid Switch", function()
        for _, mon in ipairs(hl.get_monitors()) do
            if mon.name ~= "eDP-1" then
                hl.dispatch(hl.dsp.exec_cmd([[hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })']]))
                return
            end
        end
    end, { locked = true })
    hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd([[${laptopScreen}]]), { locked = true })
  '';

  # After waking up: screens on, and the laptop screen re-enabled if the lid is
  # open (in case the lid-open event was missed while asleep).
  services.hypridle.settings.general.after_sleep_cmd = lib.mkForce (
    "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'; "
    + "grep -q open /proc/acpi/button/lid/*/state && "
    + laptopScreen
  );

  # Fingerprint unlock on the lock screen (password still works)
  programs.hyprlock.settings.auth."fingerprint:enabled" = cfg.fingerprint.enable;
}
